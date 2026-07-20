///|
fn processing_limits(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations=1UL, allocation_size=bytes, width=16UL, height=16UL,
    pixels=256UL, depth=0UL, work~,
  ))
}

///|
fn processing_image(
  width : UInt64,
  height : UInt64,
  pixels : Array[Byte],
) -> @storage.OwnedImage {
  let length = width * height * 4UL
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight),
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    @metadata.OpaqueMetadata::from_entries([], @metadata.MetadataLimits::new(
      max_entries=0UL, max_token_bytes=16UL, max_value_bytes=0UL,
      max_total_bytes=0UL, max_disposition_fields=8UL,
    ), processing_limits(0UL, 0UL)).unwrap(),
  )
  let descriptor = @model.ImageDescriptor::new(width, height, @model.ImageFormat::rgba8(), [
    @model.PlaneDescriptor::new(0UL, length, width * 4UL, width * 4UL,
      1UL, 1UL, width, height).unwrap(),
  ], length, metadata).unwrap()
  let image = @storage.OwnedImage::new(descriptor, processing_limits(length, 0UL)).unwrap()
  image.with_mut_view(fn(view) {
    let mut index = 0
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < 4UL; channel = channel + 1UL {
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
fn processing_public_image(
  width : UInt64,
  height : UInt64,
  pixels : Array[Byte],
  orientation? : @model.Orientation = @model.Orientation::TopLeft,
  profile? : @profile.ProfileIdentity = @profile.ProfileIdentity::builtin_srgb(),
  opaque? : @metadata.OpaqueMetadata? = None,
) -> @storage.OwnedImage {
  let length = width * height * 4UL
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight), profile, orientation,
    match opaque { Some(value) => value; None => @metadata.OpaqueMetadata::from_entries([], @metadata.MetadataLimits::new(
      max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
      max_total_bytes=1UL, max_disposition_fields=8UL,
    ), processing_limits(0UL, 0UL)).unwrap() },
  )
  let descriptor = @model.ImageDescriptor::new(width, height, @model.ImageFormat::rgba8(), [
    @model.PlaneDescriptor::new(0UL, length, width * 4UL, width * 4UL, 1UL, 1UL, width, height).unwrap(),
  ], length, metadata).unwrap()
  let image = @storage.OwnedImage::new(descriptor, processing_limits(length, 0UL)).unwrap()
  image.with_mut_view(fn(view) {
    let mut index = 0
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < 4UL; channel = channel + 1UL {
          view.set_byte(x, y, channel, pixels[index]).unwrap(); index = index + 1
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
test "source-over, grayscale, and blur publish straight RGBA results" {
  let source = processing_image(1UL, 1UL, [b'\x20', b'\x40', b'\x80', b'\xff'])
  let destination = processing_image(1UL, 1UL, [b'\x01', b'\x02', b'\x03', b'\x10'])
  let composite = composite_source_over(source.view(), destination.view(), processing_limits(4UL, 1UL)).unwrap()
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(composite.image().view().get_byte(0UL, 0UL, channel).unwrap() == source.view().get_byte(0UL, 0UL, channel).unwrap(), content="true")
  }
  inspect(composite.image().storage_length(), content="4")
  inspect(composite.image().metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(composite.image().metadata().profile().is_builtin_srgb(), content="true")
  inspect(composite.disposition().transformed(0).unwrap().value(), content="color")

  let gray = grayscale(source.view(), processing_limits(4UL, 1UL)).unwrap()
  let gray_view = gray.image().view()
  inspect(gray_view.get_byte(0UL, 0UL, 0UL).unwrap() == gray_view.get_byte(0UL, 0UL, 1UL).unwrap(), content="true")
  inspect(gray_view.get_byte(0UL, 0UL, 1UL).unwrap() == gray_view.get_byte(0UL, 0UL, 2UL).unwrap(), content="true")
  inspect(gray_view.get_byte(0UL, 0UL, 3UL).unwrap() == b'\xff', content="true")

  let blurred = box_blur(source.view(), 0UL, processing_limits(4UL, 1UL)).unwrap()
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(blurred.image().view().get_byte(0UL, 0UL, channel).unwrap() == source.view().get_byte(0UL, 0UL, channel).unwrap(), content="true")
  }
}

///|
test "public processing fixed translucent vectors preserve straight owned output" {
  let source = processing_public_image(1UL, 1UL, [b'\x20', b'\x40', b'\x80', b'\x60'])
  let destination = processing_public_image(1UL, 1UL, [b'\xf0', b'\x20', b'\x10', b'\xa0'])
  let composite = composite_source_over(source.view(), destination.view(), processing_limits(4UL, 1UL)).unwrap()
  let expected_composite = [b'\xb3', b'\x33', b'\x5d', b'\xc4']
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(composite.image().view().get_byte(0UL, 0UL, channel).unwrap() == expected_composite[channel.to_int()], content="true")
  }
  inspect(composite.image().storage_length() == 4UL, content="true")
  inspect(composite.image().metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  let reversed = composite_source_over(destination.view(), source.view(), processing_limits(4UL, 1UL)).unwrap().image().view()
  inspect(reversed.get_byte(0UL, 0UL, 0UL).unwrap() != expected_composite[0], content="true")

  let gray = grayscale(processing_public_image(1UL, 1UL, [b'\x20', b'\xa0', b'\xe0', b'\x60']).view(), processing_limits(4UL, 1UL)).unwrap().image().view()
  let expected_gray = [b'\x97', b'\x97', b'\x97', b'\x60']
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(gray.get_byte(0UL, 0UL, channel).unwrap() == expected_gray[channel.to_int()], content="true")
  }

  let blur_source = processing_public_image(2UL, 1UL, [b'\xff', b'\x00', b'\x00', b'\x00', b'\x00', b'\x40', b'\xff', b'\x80'])
  let blur = box_blur(blur_source.view(), 1UL, processing_limits(8UL, 18UL)).unwrap().image().view()
  let expected_blur = [b'\x00', b'\x40', b'\xff', b'\x2b', b'\x00', b'\x40', b'\xff', b'\x55']
  for x = 0UL; x < 2UL; x = x + 1UL {
    for channel = 0UL; channel < 4UL; channel = channel + 1UL {
      inspect(blur.get_byte(x, 0UL, channel).unwrap() == expected_blur[(x * 4UL + channel).to_int()], content="true")
    }
  }
  let identity_source = processing_public_image(1UL, 1UL, [b'\x20', b'\x40', b'\x80', b'\xff'])
  let identity = box_blur(identity_source.view(), 0UL, processing_limits(4UL, 1UL)).unwrap().image().view()
  for x = 0UL; x < 1UL; x = x + 1UL {
    for channel = 0UL; channel < 4UL; channel = channel + 1UL {
      inspect(identity.get_byte(x, 0UL, channel).unwrap() == identity_source.view().get_byte(x, 0UL, channel).unwrap(), content="true")
    }
  }
}

///|
test "public composite rejects all metadata incompatibilities before charging" {
  let pixels = [b'\x20', b'\x40', b'\x80', b'\x60']
  let base = processing_public_image(1UL, 1UL, pixels)
  let custom_profile = @profile.ProfileIdentity::opaque(@profile.OpaqueProfile::from_bytes(
    @profile.ProfileFormatTag::icc(), b"x", @profile.ProfileLimits::new(1UL), processing_limits(1UL, 0UL),
  ).unwrap())
  let opaque = @metadata.OpaqueMetadata::from_entries([("png", "gamma", "u8", b"v")], @metadata.MetadataLimits::new(
    max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL, max_total_bytes=16UL, max_disposition_fields=8UL,
  ), processing_limits(1UL, 0UL)).unwrap()
  let variants = [
    processing_public_image(1UL, 1UL, pixels, orientation=@model.Orientation::TopRight),
    processing_public_image(1UL, 1UL, pixels, profile=custom_profile),
    processing_public_image(1UL, 1UL, pixels, opaque=Some(opaque)),
  ]
  for variant in variants {
    let budget = processing_limits(4UL, 1UL)
    let before = budget.remaining()
    match composite_source_over(base.view(), variant.view(), budget) {
      Err(error) => {
        inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
        inspect(error.operation() == Some("image-composite-source-over"), content="true")
        inspect(error.context() == Some("image-composite-source-over-metadata"), content="true")
      }
      Ok(_) => fail("incompatible metadata must reject")
    }
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.allocation_size() == before.allocation_size(), content="true")
    inspect(after.width() == before.width(), content="true")
    inspect(after.height() == before.height(), content="true")
    inspect(after.pixels() == before.pixels(), content="true")
    inspect(after.depth() == before.depth(), content="true")
    inspect(after.work() == before.work(), content="true")
  }
}
