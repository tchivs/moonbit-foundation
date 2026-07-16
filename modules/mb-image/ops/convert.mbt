///|
priv struct ConvertBuiltinAllocator {}

///|
impl @bytes.Allocator for ConvertBuiltinAllocator with fn approve(
  _self,
  _requested,
) {
  Ok(())
}

///|
priv enum PixelConversion {
  RgbToStraight
  StraightToRgbStrict
  StraightToRgbLossy
  StraightToPremultiplied
  PremultipliedToStraight
}

///|
fn conversion_operation(conversion : PixelConversion) -> String {
  match conversion {
    RgbToStraight => "image-convert-rgb8-to-straight-rgba8"
    StraightToRgbStrict => "image-convert-straight-rgba8-to-rgb8"
    StraightToRgbLossy => "image-drop-straight-rgba8-alpha"
    StraightToPremultiplied => "image-convert-straight-to-premultiplied"
    PremultipliedToStraight => "image-convert-premultiplied-to-straight"
  }
}

///|
fn conversion_supported(
  source : @storage.ImageView,
  conversion : PixelConversion,
) -> Bool {
  if !supports_copy_flip(source) {
    return false
  }
  match (source.format().channels(), source.metadata().alpha(), conversion) {
    (@model.ChannelOrder::Rgb, None, RgbToStraight) => true
    (
      @model.ChannelOrder::Rgba,
      Some(@color.AlphaMode::Straight),
      StraightToRgbStrict,
    ) => true
    (
      @model.ChannelOrder::Rgba,
      Some(@color.AlphaMode::Straight),
      StraightToRgbLossy,
    ) => true
    (
      @model.ChannelOrder::Rgba,
      Some(@color.AlphaMode::Straight),
      StraightToPremultiplied,
    ) => true
    (
      @model.ChannelOrder::Rgba,
      Some(@color.AlphaMode::Premultiplied),
      PremultipliedToStraight,
    ) => true
    _ => false
  }
}

///|
fn conversion_disposition(lossy : Bool) -> @metadata.MetadataDisposition {
  let limits = @metadata.MetadataLimits::new(
    max_entries=0UL,
    max_token_bytes=16UL,
    max_value_bytes=0UL,
    max_total_bytes=0UL,
    max_disposition_fields=5UL,
  )
  let preserved = [
    @metadata.DispositionField::new("color", limits).unwrap(),
    @metadata.DispositionField::new("opaque", limits).unwrap(),
    @metadata.DispositionField::new("orientation", limits).unwrap(),
    @metadata.DispositionField::new("profile", limits).unwrap(),
  ]
  if lossy {
    @metadata.MetadataDisposition::new(
      preserved,
      [],
      [@metadata.DispositionField::new("alpha", limits).unwrap()],
      true,
      limits,
    ).unwrap()
  } else {
    @metadata.MetadataDisposition::new(
      preserved,
      [@metadata.DispositionField::new("alpha", limits).unwrap()],
      [],
      false,
      limits,
    ).unwrap()
  }
}

///|
fn conversion_metadata(
  source : @storage.ImageView,
  alpha : @color.AlphaMode?,
) -> @model.ImageMetadata {
  let metadata = source.metadata()
  @model.ImageMetadata::new(
    metadata.space(),
    metadata.transfer(),
    alpha,
    metadata.profile(),
    metadata.orientation(),
    metadata.opaque_metadata(),
  )
}

///|
fn conversion_descriptor(
  source : @storage.ImageView,
  format : @model.ImageFormat,
  alpha : @color.AlphaMode?,
) -> Result[(@model.ImageDescriptor, UInt64, UInt64), @error.CoreError] {
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let row_bytes = match
    @checked.checked_mul(source.width(), format.channel_count()) {
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
      format,
      [plane],
      length,
      conversion_metadata(source, alpha),
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok((descriptor, pixels, length))
}

///|
fn require_opaque_alpha(
  source : @storage.ImageView,
) -> Result[Unit, @error.CoreError] {
  for y = 0UL; y < source.height(); y = y + 1UL {
    for x = 0UL; x < source.width(); x = x + 1UL {
      let alpha = match source.get_byte(x, y, 3UL) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if alpha != b'\xff' {
        return Err(
          operation_error(
            @error.ErrorCategory::InvalidInput,
            @error.ErrorCode::InvalidRange,
            "image-convert-straight-rgba8-to-rgb8",
            "nonopaque-alpha-requires-explicit-drop",
          ),
        )
      }
    }
  }
  Ok(())
}

///|
fn require_valid_premultiplied(
  source : @storage.ImageView,
) -> Result[Unit, @error.CoreError] {
  for y = 0UL; y < source.height(); y = y + 1UL {
    for x = 0UL; x < source.width(); x = x + 1UL {
      let alpha = match source.get_byte(x, y, 3UL) {
        Ok(value) => value.to_uint64()
        Err(error) => return Err(error)
      }
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        let component = match source.get_byte(x, y, channel) {
          Ok(value) => value.to_uint64()
          Err(error) => return Err(error)
        }
        if component > alpha {
          return Err(
            operation_error(
              @error.ErrorCategory::InvalidInput,
              @error.ErrorCode::InvalidRange,
              "image-convert-premultiplied-to-straight",
              "premultiplied-component-exceeds-alpha",
            ),
          )
        }
      }
    }
  }
  Ok(())
}

///|
fn preflight_conversion_budget(
  budget : @budget.Budget,
  width : UInt64,
  height : UInt64,
  pixels : UInt64,
  length : UInt64,
  operation : String,
) -> Result[Unit, @error.CoreError] {
  let remaining = budget.remaining()
  if remaining.bytes() < length ||
    remaining.allocations() < 1UL ||
    remaining.allocation_size() < length ||
    remaining.width() < width ||
    remaining.height() < height ||
    remaining.pixels() < pixels ||
    remaining.work() < length {
    Err(
      operation_error(
        @error.ErrorCategory::Resource,
        @error.ErrorCode::BudgetExceeded,
        operation,
        "conversion-output-budget",
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn convert_pixel_image(
  source : @storage.ImageView,
  budget : @budget.Budget,
  conversion : PixelConversion,
) -> Result[ImageOperationResult, @error.CoreError] {
  let operation = conversion_operation(conversion)
  if !conversion_supported(source, conversion) {
    return Err(
      operation_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        operation,
        operation + "-format",
      ),
    )
  }
  let (format, target_alpha) = match conversion {
    RgbToStraight =>
      (@model.ImageFormat::rgba8(), Some(@color.AlphaMode::Straight))
    StraightToRgbStrict | StraightToRgbLossy =>
      (@model.ImageFormat::rgb8(), None)
    StraightToPremultiplied =>
      (@model.ImageFormat::rgba8(), Some(@color.AlphaMode::Premultiplied))
    PremultipliedToStraight =>
      (@model.ImageFormat::rgba8(), Some(@color.AlphaMode::Straight))
  }
  let (descriptor, pixels, work) = match
    conversion_descriptor(source, format, target_alpha) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if conversion is StraightToRgbStrict || conversion is PremultipliedToStraight {
    match
      preflight_conversion_budget(
        budget,
        source.width(),
        source.height(),
        pixels,
        work,
        operation,
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  if conversion is StraightToRgbStrict {
    match require_opaque_alpha(source) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  } else if conversion is PremultipliedToStraight {
    match require_valid_premultiplied(source) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let output = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      ConvertBuiltinAllocator::{  } as &@bytes.Allocator,
      source.width(),
      source.height(),
      pixels,
      work,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let written = output.with_mut_view(fn(destination) {
    for y = 0UL; y < source.height(); y = y + 1UL {
      for x = 0UL; x < source.width(); x = x + 1UL {
        let r = match source.get_byte(x, y, 0UL) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let g = match source.get_byte(x, y, 1UL) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let b = match source.get_byte(x, y, 2UL) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let (out_r, out_g, out_b, out_alpha) = match conversion {
          RgbToStraight => (r, g, b, Some(b'\xff'))
          StraightToRgbStrict | StraightToRgbLossy => (r, g, b, None)
          StraightToPremultiplied => {
            let a = match source.get_byte(x, y, 3UL) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let value = @alpha.StraightEncodedSrgba8::new(
              @color.EncodedSrgb8Component::from_byte(r),
              @color.EncodedSrgb8Component::from_byte(g),
              @color.EncodedSrgb8Component::from_byte(b),
              @color.EncodedAlpha8::from_byte(a),
            )
            let converted = match @alpha.premultiply_encoded(value) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            (
              converted.r().value(),
              converted.g().value(),
              converted.b().value(),
              Some(converted.a().value()),
            )
          }
          PremultipliedToStraight => {
            let a = match source.get_byte(x, y, 3UL) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let value = match
              @alpha.PremultipliedEncodedSrgba8::new(
                @color.EncodedSrgb8Component::from_byte(r),
                @color.EncodedSrgb8Component::from_byte(g),
                @color.EncodedSrgb8Component::from_byte(b),
                @color.EncodedAlpha8::from_byte(a),
              ) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let converted = match @alpha.unpremultiply_encoded(value) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            (
              converted.r().value(),
              converted.g().value(),
              converted.b().value(),
              Some(converted.a().value()),
            )
          }
        }
        for item in [(0UL, out_r), (1UL, out_g), (2UL, out_b)] {
          match destination.set_byte(x, y, item.0, item.1) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
        }
        match out_alpha {
          Some(alpha) =>
            match destination.set_byte(x, y, 3UL, alpha) {
              Ok(_) => ()
              Err(error) => return Err(error)
            }
          None => ()
        }
      }
    }
    Ok(())
  })
  match written {
    Err(error) => Err(error)
    Ok(_) =>
      Ok({
        image_value: output,
        disposition_value: conversion_disposition(
          conversion is StraightToRgbLossy,
        ),
      })
  }
}

///|
pub fn rgb8_to_straight_rgba8(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  convert_pixel_image(source, budget, PixelConversion::RgbToStraight)
}

///|
pub fn straight_rgba8_to_rgb8(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  convert_pixel_image(source, budget, PixelConversion::StraightToRgbStrict)
}

///|
pub fn drop_straight_rgba8_alpha(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  convert_pixel_image(source, budget, PixelConversion::StraightToRgbLossy)
}

///|
pub fn straight_rgba8_to_premultiplied(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  convert_pixel_image(source, budget, PixelConversion::StraightToPremultiplied)
}

///|
pub fn premultiplied_rgba8_to_straight(
  source : @storage.ImageView,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError] {
  convert_pixel_image(source, budget, PixelConversion::PremultipliedToStraight)
}
