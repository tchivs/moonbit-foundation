///|
fn processing_pipeline_public_rgb_image(
  width : UInt64,
  height : UInt64,
  pixels : Array[Byte],
) -> @storage.OwnedImage {
  let length = width * height * 3UL
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    @metadata.OpaqueMetadata::from_entries(
      [],
      @metadata.MetadataLimits::new(
        max_entries=0UL,
        max_token_bytes=16UL,
        max_value_bytes=0UL,
        max_total_bytes=0UL,
        max_disposition_fields=8UL,
      ),
      processing_limits(0UL, 0UL),
    ).unwrap(),
  )
  let descriptor = @model.ImageDescriptor::new(
    width,
    height,
    @model.ImageFormat::rgb8(),
    [@model.PlaneDescriptor::new(
      0UL, length, width * 3UL, width * 3UL, 1UL, 1UL, width, height,
    ).unwrap()],
    length,
    metadata,
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    processing_limits(length, 0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    let mut index = 0
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          view.set_byte(x, y, channel, pixels[index]).unwrap()
          index = index + 1
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
test "public processing pipeline resize-composite opaque PPM vector" {
  let foreground = processing_pipeline_public_rgb_image(1UL, 1UL, [
    b'\x0c', b'\x22', b'\x38',
  ])
  let destination = processing_pipeline_public_rgb_image(2UL, 1UL, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
  ])
  let resized = @ops.resize_nearest(
    foreground.view(),
    2UL,
    1UL,
    resize_convert_limits(6UL, 6UL),
  ).unwrap()
  let source_rgba = @ops.rgb8_to_straight_rgba8(
    resized.image().view(),
    resize_convert_limits(8UL, 8UL),
  ).unwrap()
  let destination_rgba = @ops.rgb8_to_straight_rgba8(
    destination.view(),
    resize_convert_limits(8UL, 8UL),
  ).unwrap()
  let composite = @ops.composite_source_over(
    source_rgba.image().view(),
    destination_rgba.image().view(),
    processing_limits(8UL, 2UL),
  ).unwrap()
  let output = @ops.straight_rgba8_to_rgb8(
    composite.image().view(),
    resize_convert_limits(6UL, 6UL),
  ).unwrap()
  let view = output.image().view()
  inspect(output.image().descriptor().width(), content="2")
  inspect(output.image().descriptor().height(), content="1")
  inspect(output.image().metadata().alpha() is None, content="true")
  inspect(composite.image().metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(composite.disposition().transformed(0).unwrap().value(), content="color")
  inspect(output.disposition().transformed(0).unwrap().value(), content="alpha")
  for x = 0UL; x < 2UL; x = x + 1UL {
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      inspect(
        view.get_byte(x, 0UL, channel).unwrap() == [b'\x0c', b'\x22', b'\x38'][channel.to_int()],
        content="true",
      )
    }
  }
  let reversed = @ops.composite_source_over(
    destination_rgba.image().view(),
    source_rgba.image().view(),
    processing_limits(8UL, 2UL),
  ).unwrap().image().view()
  inspect(reversed.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x01', content="true")
}

///|
test "public processing pipeline conversion boundary is typed" {
  let incompatible = resize_convert_image(
    1UL,
    1UL,
    4UL,
    Some(@color.AlphaMode::Straight),
    [b'\x0c', b'\x22', b'\x38', b'\xff'],
  )
  let budget = resize_convert_limits(4UL, 4UL)
  let before = budget.remaining()
  match @ops.rgb8_to_straight_rgba8(incompatible.view(), budget) {
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::Capability, content="true")
      inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
      inspect(error.operation() == Some("image-convert-rgb8-to-straight-rgba8"), content="true")
      inspect(error.context() == Some("image-convert-rgb8-to-straight-rgba8-format"), content="true")
    }
    Ok(_) => fail("RGBA input must not use the RGB conversion route")
  }
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "public processing pipeline crop-rotate-grayscale-blur-source-over vector" {
  let foreground = processing_pipeline_public_rgb_image(3UL, 3UL, [
    b'\x01', b'\x02', b'\x03', b'\x00', b'\x00', b'\x00', b'\xff', b'\xff', b'\xff',
    b'\x04', b'\x05', b'\x06', b'\x40', b'\x40', b'\x40', b'\xc0', b'\xc0', b'\xc0',
    b'\x07', b'\x08', b'\x09', b'\x80', b'\x80', b'\x80', b'\x20', b'\x20', b'\x20',
  ])
  let destination = processing_pipeline_public_rgb_image(3UL, 2UL, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06', b'\x07', b'\x08', b'\x09',
    b'\x0a', b'\x0b', b'\x0c', b'\x0d', b'\x0e', b'\x0f', b'\x10', b'\x11', b'\x12',
  ])
  let cropped = @ops.crop(
    foreground.view(), @model.Rect::new(1UL, 0UL, 2UL, 3UL).unwrap(), processing_limits(18UL, 18UL),
  ).unwrap()
  let rotated = @ops.rotate_90(cropped.image().view(), processing_limits(18UL, 18UL)).unwrap()
  let rotated_view = rotated.image().view()
  inspect(rotated.image().descriptor().width(), content="3")
  inspect(rotated.image().descriptor().height(), content="2")
  inspect(rotated_view.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x80', content="true")
  inspect(rotated_view.get_byte(2UL, 0UL, 0UL).unwrap() == b'\x00', content="true")
  inspect(rotated_view.get_byte(0UL, 1UL, 0UL).unwrap() == b'\x20', content="true")
  inspect(rotated_view.get_byte(2UL, 1UL, 0UL).unwrap() == b'\xff', content="true")
  let source_rgba = @ops.rgb8_to_straight_rgba8(rotated_view, processing_limits(24UL, 24UL)).unwrap()
  let grayscale = @ops.grayscale(source_rgba.image().view(), processing_limits(24UL, 6UL)).unwrap()
  let grayscale_view = grayscale.image().view()
  inspect(grayscale_view.get_byte(0UL, 0UL, 0UL).unwrap() == grayscale_view.get_byte(0UL, 0UL, 1UL).unwrap(), content="true")
  inspect(grayscale_view.get_byte(0UL, 0UL, 1UL).unwrap() == grayscale_view.get_byte(0UL, 0UL, 2UL).unwrap(), content="true")
  inspect(grayscale_view.get_byte(0UL, 0UL, 3UL).unwrap() == b'\xff', content="true")
  let blurred = @ops.box_blur(grayscale_view, 1UL, processing_limits(24UL, 54UL)).unwrap()
  let blurred_view = blurred.image().view()
  for channel = 0UL; channel < 3UL; channel = channel + 1UL {
    inspect(blurred_view.get_byte(0UL, 0UL, channel).unwrap() == b'\x72', content="true")
    inspect(blurred_view.get_byte(2UL, 1UL, channel).unwrap() == b'\xc6', content="true")
  }
  for x = 0UL; x < 3UL; x = x + 2UL {
    let y = if x == 0UL { 0UL } else { 1UL }
    inspect(blurred_view.get_byte(x, y, 3UL).unwrap() == b'\xff', content="true")
  }
  let destination_rgba = @ops.rgb8_to_straight_rgba8(destination.view(), processing_limits(24UL, 24UL)).unwrap()
  let composite = @ops.composite_source_over(blurred_view, destination_rgba.image().view(), processing_limits(24UL, 6UL)).unwrap()
  let output = @ops.straight_rgba8_to_rgb8(composite.image().view(), processing_limits(18UL, 18UL)).unwrap()
  inspect(composite.image().metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(output.image().metadata().alpha() is None, content="true")
  inspect(output.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x72', content="true")
  inspect(output.image().view().get_byte(2UL, 1UL, 0UL).unwrap() == b'\xc6', content="true")
}
