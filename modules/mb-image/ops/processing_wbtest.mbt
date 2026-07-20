///|
fn processing_wb_limits(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations=1UL, allocation_size=bytes, width=16UL, height=16UL,
    pixels=256UL, depth=0UL, work~,
  ))
}

///|
fn processing_wb_image(width : UInt64, height : UInt64, pixels : Array[Byte]) -> @storage.OwnedImage {
  let length = width * height * 4UL
  let descriptor = @model.ImageDescriptor::new(width, height, @model.ImageFormat::rgba8(), [
    @model.PlaneDescriptor::new(0UL, length, width * 4UL, width * 4UL, 1UL, 1UL, width, height).unwrap(),
  ], length, @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft, @metadata.OpaqueMetadata::from_entries([], @metadata.MetadataLimits::new(
      max_entries=0UL, max_token_bytes=16UL, max_value_bytes=0UL, max_total_bytes=0UL,
      max_disposition_fields=8UL,
    ), processing_wb_limits(0UL, 0UL)).unwrap(),
  )).unwrap()
  let image = @storage.OwnedImage::new(descriptor, processing_wb_limits(length, 0UL)).unwrap()
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
test "processing rejects incompatible dimensions before budget charge" {
  let one = processing_wb_image(1UL, 1UL, [b'\xff', b'\x00', b'\x00', b'\x80'])
  let two = processing_wb_image(2UL, 1UL, [b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'])
  let budget = processing_wb_limits(8UL, 8UL)
  let before = budget.remaining()
  match composite_source_over(one.view(), two.view(), budget) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::InvalidDimensions, content="true")
      inspect(error.operation() == "image-composite-source-over", content="true")
    }
    Ok(_) => fail("incompatible dimensions must reject")
  }
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
test "alpha-aware blur removes transparent saturated halo" {
  let source = processing_wb_image(2UL, 1UL, [b'\xff', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\xff'])
  let result = box_blur(source.view(), 1UL, processing_wb_limits(8UL, 18UL)).unwrap()
  let view = result.image().view()
  inspect(view.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x00', content="true")
  inspect(view.get_byte(0UL, 0UL, 1UL).unwrap() == b'\x00', content="true")
  inspect(view.get_byte(0UL, 0UL, 2UL).unwrap() == b'\x00', content="true")
}
