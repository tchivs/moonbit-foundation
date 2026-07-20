///|
priv struct GeometryBuiltinAllocator {}

///|
impl @bytes.Allocator for GeometryBuiltinAllocator with fn approve(
  _self,
  _requested,
) {
  Ok(())
}

///|
fn geometry_descriptor(
  source : @storage.ImageView,
  width : UInt64,
  height : UInt64,
  metadata : @model.ImageMetadata,
  operation : String,
) -> Result[(@model.ImageDescriptor, UInt64), @error.CoreError] {
  if width == 0UL || height == 0UL {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        operation,
        "empty-geometry-output",
      ),
    )
  }
  match @checked.checked_mul(width, height) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let pixel_bytes = match @checked.checked_mul(
    source.format().bytes_per_component(),
    source.format().channel_count(),
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let row_bytes = match @checked.checked_mul(width, pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length = match @checked.checked_mul(row_bytes, height) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let plane = match @model.PlaneDescriptor::new(
    0UL, length, row_bytes, row_bytes, 1UL, 1UL, width, height,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let descriptor = match @model.ImageDescriptor::new(
    width, height, source.format(), [plane], length, metadata,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok((descriptor, length))
}

///|
pub fn crop(
  source : @storage.ImageView,
  region : @model.Rect,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  let operation = "image-crop"
  if !supports_copy_flip(source) {
    return Err(operation_error(
      @error.ErrorCategory::Capability,
      @error.ErrorCode::CapabilityUnavailable,
      operation,
      "image-crop-format",
    ))
  }
  if region.is_empty() {
    return Err(operation_error(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidDimensions,
      operation,
      "empty-crop-region",
    ))
  }
  if region.right() > source.width() || region.bottom() > source.height() {
    return Err(operation_error(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidRange,
      operation,
      "crop-region-outside-source",
    ))
  }
  let (descriptor, work) = match geometry_descriptor(
    source, region.width(), region.height(), source.metadata(), operation,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let output = match @storage.OwnedImage::new_operation(
    descriptor,
    budget,
    GeometryBuiltinAllocator::{  } as &@bytes.Allocator,
    work,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let copied = output.with_mut_view(fn(destination) {
    for y = 0UL; y < region.height(); y = y + 1UL {
      for x = 0UL; x < region.width(); x = x + 1UL {
        for channel = 0UL
            channel < source.format().channel_count()
            channel = channel + 1UL {
          let value = match source.get_byte(region.x() + x, region.y() + y, channel) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          match destination.set_byte(x, y, channel, value) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
        }
      }
    }
    Ok(())
  })
  match copied {
    Ok(_) => Ok({ image_value: output, disposition_value: preserve_all_disposition() })
    Err(error) => Err(error)
  }
}
