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
