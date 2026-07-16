///|
priv struct OperationBuiltinAllocator {}

///|
impl @bytes.Allocator for OperationBuiltinAllocator with fn approve(
  _self,
  _requested,
) {
  Ok(())
}

///|
priv enum CopyTransform {
  Identity
  Horizontal
  Vertical
}

///|
pub struct ImageOperationResult {
  priv image_value : @storage.OwnedImage
  priv disposition_value : @metadata.MetadataDisposition
}

///|
pub fn ImageOperationResult::image(
  self : ImageOperationResult,
) -> @storage.OwnedImage {
  self.image_value
}

///|
pub fn ImageOperationResult::disposition(
  self : ImageOperationResult,
) -> @metadata.MetadataDisposition {
  self.disposition_value
}

///|
fn operation_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  operation : String,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(category, code, operation~, context~)
}

///|
fn supports_copy_flip(source : @storage.ImageView) -> Bool {
  let format = source.format()
  let metadata = source.metadata()
  if format.component() != @model.ComponentType::U8 ||
    format.layout() != @model.PlaneLayout::Packed ||
    metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    metadata.transfer() != @color.TransferIdentity::EncodedSrgb {
    return false
  }
  match format.channels() {
    @model.ChannelOrder::Rgb => metadata.alpha() is None
    @model.ChannelOrder::Rgba =>
      match metadata.alpha() {
        Some(@color.AlphaMode::Straight) => true
        Some(@color.AlphaMode::Premultiplied) => true
        None => false
      }
    @model.ChannelOrder::Gray => false
  }
}

///|
fn preserve_all_disposition() -> @metadata.MetadataDisposition {
  let limits = @metadata.MetadataLimits::new(
    max_entries=0UL,
    max_token_bytes=16UL,
    max_value_bytes=0UL,
    max_total_bytes=0UL,
    max_disposition_fields=5UL,
  )
  @metadata.MetadataDisposition::new(
    [
      @metadata.DispositionField::new("alpha", limits).unwrap(),
      @metadata.DispositionField::new("color", limits).unwrap(),
      @metadata.DispositionField::new("opaque", limits).unwrap(),
      @metadata.DispositionField::new("orientation", limits).unwrap(),
      @metadata.DispositionField::new("profile", limits).unwrap(),
    ],
    [],
    [],
    false,
    limits,
  ).unwrap()
}

///|
fn operation_context(transform : CopyTransform) -> (String, String) {
  match transform {
    Identity => ("image-copy", "image-copy-format")
    Horizontal => ("image-flip-horizontal", "image-flip-horizontal-format")
    Vertical => ("image-flip-vertical", "image-flip-vertical-format")
  }
}

///|
fn tight_descriptor(
  source : @storage.ImageView,
  operation : String,
) -> Result[(@model.ImageDescriptor, UInt64, UInt64), @error.CoreError] {
  if source.is_empty() {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        operation,
        "empty-operation-source",
      ),
    )
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let pixel_bytes = match
    @checked.checked_mul(
      source.format().bytes_per_component(),
      source.format().channel_count(),
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let row_bytes = match @checked.checked_mul(source.width(), pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length = match @checked.checked_mul(row_bytes, source.height()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let plane = match
    @model.PlaneDescriptor::new(
      0UL,
      length,
      row_bytes,
      row_bytes,
      1UL,
      1UL,
      source.width(),
      source.height(),
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let descriptor = match
    @model.ImageDescriptor::new(
      source.width(),
      source.height(),
      source.format(),
      [plane],
      length,
      source.metadata(),
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok((descriptor, pixels, length))
}

///|
fn copy_with_transform(
  source : @storage.ImageView,
  budget : @budget.Budget,
  transform : CopyTransform,
) -> Result[ImageOperationResult, @error.CoreError] {
  let (operation, unsupported_context) = operation_context(transform)
  if !supports_copy_flip(source) {
    return Err(
      operation_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        operation,
        unsupported_context,
      ),
    )
  }
  let (descriptor, pixels, work) = match tight_descriptor(source, operation) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let disposition = preserve_all_disposition()
  let output = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      OperationBuiltinAllocator::{  } as &@bytes.Allocator,
      source.width(),
      source.height(),
      pixels,
      work,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let copied = output.with_mut_view(fn(destination) {
    for destination_y = 0UL
        destination_y < source.height()
        destination_y = destination_y + 1UL {
      let source_y = match transform {
        Vertical => source.height() - 1UL - destination_y
        _ => destination_y
      }
      for destination_x = 0UL
          destination_x < source.width()
          destination_x = destination_x + 1UL {
        let source_x = match transform {
          Horizontal => source.width() - 1UL - destination_x
          _ => destination_x
        }
        for channel = 0UL
            channel < source.format().channel_count()
            channel = channel + 1UL {
          let value = match source.get_byte(source_x, source_y, channel) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          match
            destination.set_byte(destination_x, destination_y, channel, value) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
        }
      }
    }
    Ok(())
  })
  match copied {
    Err(error) => Err(error)
    Ok(_) => Ok({ image_value: output, disposition_value: disposition })
  }
}

///|
pub fn copy_image(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  copy_with_transform(source, budget, CopyTransform::Identity)
}

///|
pub fn flip_horizontal(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  copy_with_transform(source, budget, CopyTransform::Horizontal)
}

///|
pub fn flip_vertical(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  copy_with_transform(source, budget, CopyTransform::Vertical)
}
