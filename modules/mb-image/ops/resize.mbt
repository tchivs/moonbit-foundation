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
  operation : String,
) -> Result[(@model.ImageDescriptor, UInt64, UInt64), @error.CoreError] {
  if width == 0UL || height == 0UL {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        operation,
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
  let (descriptor, _pixels, work) = match
    resized_descriptor(source, width, height, "image-resize-nearest") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match @checked.checked_mul(width - 1UL, source.width()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match @checked.checked_mul(height - 1UL, source.height()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let output = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      ResizeBuiltinAllocator::{  } as &@bytes.Allocator,
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

///|
fn bilinear_source_coordinate(
  destination : UInt64,
  source_extent : UInt64,
  destination_extent : UInt64,
) -> Result[(UInt64, UInt64, UInt64), @error.CoreError] {
  if source_extent == 0UL || destination_extent == 0UL {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidDimensions,
        "image-resize-bilinear",
        "zero-resize-axis",
      ),
    )
  }
  let product = match @checked.checked_mul(destination, source_extent) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let low = product / destination_extent
  let remainder = product % destination_extent
  let high = if low < source_extent - 1UL { low + 1UL } else { low }
  Ok((low, high, remainder))
}

///|
fn supports_bilinear_format(source : @storage.ImageView) -> Bool {
  source.format().component() == @model.ComponentType::U8 &&
  source.format().layout() == @model.PlaneLayout::Packed &&
  ((source.format().channels() == @model.ChannelOrder::Rgb &&
    source.metadata().alpha() == None) ||
    (source.format().channels() == @model.ChannelOrder::Rgba &&
      source.metadata().alpha() == Some(@color.AlphaMode::Straight)))
}

///|
fn supports_bilinear_metadata(source : @storage.ImageView) -> Bool {
  source.metadata().space() == @color.ColorSpaceIdentity::Srgb &&
  source.metadata().transfer() == @color.TransferIdentity::EncodedSrgb &&
  source.metadata().profile().is_builtin_srgb()
}

///|
fn bilinear_interpolate(
  a : @alpha.PremultipliedNormalizedSrgba,
  b : @alpha.PremultipliedNormalizedSrgba,
  c : @alpha.PremultipliedNormalizedSrgba,
  d : @alpha.PremultipliedNormalizedSrgba,
  x_fraction : Double,
  y_fraction : Double,
) -> @alpha.PremultipliedNormalizedSrgba {
  let (ar, ag, ab) = a.linear_rgb().unwrap()
  let (br, bg, bb) = b.linear_rgb().unwrap()
  let (cr, cg, cb) = c.linear_rgb().unwrap()
  let (dr, dg, db) = d.linear_rgb().unwrap()
  let top_r = ar.value() + (br.value() - ar.value()) * x_fraction
  let top_g = ag.value() + (bg.value() - ag.value()) * x_fraction
  let top_b = ab.value() + (bb.value() - ab.value()) * x_fraction
  let top_a = a.alpha().value() + (b.alpha().value() - a.alpha().value()) * x_fraction
  let bottom_r = cr.value() + (dr.value() - cr.value()) * x_fraction
  let bottom_g = cg.value() + (dg.value() - cg.value()) * x_fraction
  let bottom_b = cb.value() + (db.value() - cb.value()) * x_fraction
  let bottom_a = c.alpha().value() + (d.alpha().value() - c.alpha().value()) * x_fraction
  @alpha.PremultipliedNormalizedSrgba::linear(
    @color.LinearSrgbComponent::new(top_r + (bottom_r - top_r) * y_fraction).unwrap(),
    @color.LinearSrgbComponent::new(top_g + (bottom_g - top_g) * y_fraction).unwrap(),
    @color.LinearSrgbComponent::new(top_b + (bottom_b - top_b) * y_fraction).unwrap(),
    @color.NormalizedAlpha::new(top_a + (bottom_a - top_a) * y_fraction).unwrap(),
  ).unwrap()
}

///|
pub fn resize_bilinear(
  source : @storage.ImageView,
  width : UInt64,
  height : UInt64,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  let operation = "image-resize-bilinear"
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
  if !supports_bilinear_format(source) {
    return Err(
      operation_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        operation,
        "image-resize-bilinear-format",
      ),
    )
  }
  if !supports_bilinear_metadata(source) {
    return Err(
      operation_error(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        operation,
        "image-resize-bilinear-metadata",
      ),
    )
  }
  let (descriptor, pixels, _length) = match
    resized_descriptor(source, width, height, operation) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match @checked.checked_mul(width - 1UL, source.width()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match @checked.checked_mul(height - 1UL, source.height()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let work = match @checked.checked_mul(pixels, 4UL) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let output = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      ResizeBuiltinAllocator::{  } as &@bytes.Allocator,
      work,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rgb_output = source.format().channels() == @model.ChannelOrder::Rgb
  let written = output.with_mut_view(fn(destination) {
    for destination_y = 0UL
        destination_y < height
        destination_y = destination_y + 1UL {
      let (low_y, high_y, remainder_y) = match
        bilinear_source_coordinate(destination_y, source.height(), height) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let y_fraction = remainder_y.to_double() / height.to_double()
      for destination_x = 0UL
          destination_x < width
          destination_x = destination_x + 1UL {
        let (low_x, high_x, remainder_x) = match
          bilinear_source_coordinate(destination_x, source.width(), width) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let x_fraction = remainder_x.to_double() / width.to_double()
        let a = if rgb_output {
          load_linear_premultiplied_rgb8(source, low_x, low_y)
        } else {
          load_linear_premultiplied(source, low_x, low_y)
        }
        let b = if rgb_output {
          load_linear_premultiplied_rgb8(source, high_x, low_y)
        } else {
          load_linear_premultiplied(source, high_x, low_y)
        }
        let c = if rgb_output {
          load_linear_premultiplied_rgb8(source, low_x, high_y)
        } else {
          load_linear_premultiplied(source, low_x, high_y)
        }
        let d = if rgb_output {
          load_linear_premultiplied_rgb8(source, high_x, high_y)
        } else {
          load_linear_premultiplied(source, high_x, high_y)
        }
        let aa = match a {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let bb = match b {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let cc = match c {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let dd = match d {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        let value = bilinear_interpolate(aa, bb, cc, dd, x_fraction, y_fraction)
        if rgb_output {
          match store_linear_premultiplied_rgb8(destination, destination_x, destination_y, value) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
        } else {
          match store_linear_premultiplied(destination, destination_x, destination_y, value) {
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
