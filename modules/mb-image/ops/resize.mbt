///|
priv struct ResizeBuiltinAllocator {}

///|
impl @bytes.Allocator for ResizeBuiltinAllocator with fn approve(
  _self,
  _requested,
) {
  Ok(())
}

///|
fn nearest_source_index(
  destination : UInt64,
  source_extent : UInt64,
  destination_extent : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if source_extent == 0UL || destination_extent == 0UL {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        "image-resize-nearest",
        "zero-resize-axis",
      ),
    )
  }
  let product = match @checked.checked_mul(destination, source_extent) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mapped = product / destination_extent
  Ok(if mapped < source_extent { mapped } else { source_extent - 1UL })
}

///|
fn resized_descriptor(
  source : @storage.ImageView,
  width : UInt64,
  height : UInt64,
) -> Result[(@model.ImageDescriptor, UInt64, UInt64), @error.CoreError] {
  if width == 0UL || height == 0UL {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        "image-resize-nearest",
        "zero-destination-axis",
      ),
    )
  }
  let pixels = match @checked.checked_mul(width, height) {
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
  let row_bytes = match @checked.checked_mul(width, pixel_bytes) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length = match @checked.checked_mul(row_bytes, height) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let plane = match
    @model.PlaneDescriptor::new(
      0UL, length, row_bytes, row_bytes, 1UL, 1UL, width, height,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let descriptor = match
    @model.ImageDescriptor::new(
      width,
      height,
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
pub fn resize_nearest(
  source : @storage.ImageView,
  width : UInt64,
  height : UInt64,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  if !supports_copy_flip(source) {
    return Err(
      operation_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        "image-resize-nearest",
        "image-resize-nearest-format",
      ),
    )
  }
  let (descriptor, pixels, work) = match
    resized_descriptor(source, width, height) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let output = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      ResizeBuiltinAllocator::{  } as &@bytes.Allocator,
      width,
      height,
      pixels,
      work,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let written = output.with_mut_view(fn(destination) {
    for destination_y = 0UL
        destination_y < height
        destination_y = destination_y + 1UL {
      let source_y = match
        nearest_source_index(destination_y, source.height(), height) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      for destination_x = 0UL
          destination_x < width
          destination_x = destination_x + 1UL {
        let source_x = match
          nearest_source_index(destination_x, source.width(), width) {
          Ok(value) => value
          Err(error) => return Err(error)
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
  match written {
    Err(error) => Err(error)
    Ok(_) =>
      Ok({ image_value: output, disposition_value: preserve_all_disposition() })
  }
}
