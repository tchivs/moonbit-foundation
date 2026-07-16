///|
priv struct OrientationBuiltinAllocator {}

///|
impl @bytes.Allocator for OrientationBuiltinAllocator with fn approve(
  _self,
  _requested,
) {
  Ok(())
}

///|
fn orientation_disposition() -> @metadata.MetadataDisposition {
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
      @metadata.DispositionField::new("profile", limits).unwrap(),
    ],
    [@metadata.DispositionField::new("orientation", limits).unwrap()],
    [],
    false,
    limits,
  ).unwrap()
}

///|
fn normalized_orientation_metadata(
  source : @model.ImageMetadata,
) -> @model.ImageMetadata {
  @model.ImageMetadata::new(
    source.space(),
    source.transfer(),
    source.alpha(),
    source.profile(),
    @model.Orientation::TopLeft,
    source.opaque_metadata(),
  )
}

///|
fn orientation_destination(
  orientation : @model.Orientation,
  source_x : UInt64,
  source_y : UInt64,
  source_width : UInt64,
  source_height : UInt64,
) -> (UInt64, UInt64) {
  match orientation {
    @model.Orientation::TopLeft => (source_x, source_y)
    @model.Orientation::TopRight => (source_width - 1UL - source_x, source_y)
    @model.Orientation::BottomRight =>
      (source_width - 1UL - source_x, source_height - 1UL - source_y)
    @model.Orientation::BottomLeft => (source_x, source_height - 1UL - source_y)
    @model.Orientation::LeftTop => (source_y, source_x)
    @model.Orientation::RightTop => (source_height - 1UL - source_y, source_x)
    @model.Orientation::RightBottom =>
      (source_height - 1UL - source_y, source_width - 1UL - source_x)
    @model.Orientation::LeftBottom => (source_y, source_width - 1UL - source_x)
  }
}

///|
fn orientation_descriptor(
  source : @storage.ImageView,
) -> Result[(@model.ImageDescriptor, UInt64, UInt64), @error.CoreError] {
  if source.is_empty() {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        "image-apply-orientation",
        "empty-operation-source",
      ),
    )
  }
  let orientation = source.metadata().orientation()
  let output_width = orientation.display_width(source.width(), source.height())
  let output_height = orientation.display_height(
    source.width(),
    source.height(),
  )
  let pixels = match @checked.checked_mul(output_width, output_height) {
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
  let row_bytes = match @checked.checked_mul(output_width, pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length = match @checked.checked_mul(row_bytes, output_height) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let plane = match
    @model.PlaneDescriptor::new(
      0UL, length, row_bytes, row_bytes, 1UL, 1UL, output_width, output_height,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let descriptor = match
    @model.ImageDescriptor::new(
      output_width,
      output_height,
      source.format(),
      [plane],
      length,
      normalized_orientation_metadata(source.metadata()),
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok((descriptor, pixels, length))
}

///|
pub fn apply_orientation(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  if !supports_copy_flip(source) {
    return Err(
      operation_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        "image-apply-orientation",
        "image-apply-orientation-format",
      ),
    )
  }
  let (descriptor, pixels, work) = match orientation_descriptor(source) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let disposition = orientation_disposition()
  let output = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      OrientationBuiltinAllocator::{  } as &@bytes.Allocator,
      descriptor.width(),
      descriptor.height(),
      pixels,
      work,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let orientation = source.metadata().orientation()
  let copied = output.with_mut_view(fn(destination) {
    for source_y = 0UL; source_y < source.height(); source_y = source_y + 1UL {
      for source_x = 0UL; source_x < source.width(); source_x = source_x + 1UL {
        let (destination_x, destination_y) = orientation_destination(
          orientation,
          source_x,
          source_y,
          source.width(),
          source.height(),
        )
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
