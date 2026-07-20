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
