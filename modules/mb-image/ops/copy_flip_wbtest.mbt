///|
fn unsupported_metadata() -> @model.ImageMetadata {
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [],
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=16UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=8UL,
    ),
    wb_operation_limits(0UL, 0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    opaque,
  )
}

///|
fn wb_operation_limits(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=1UL,
      allocation_size=bytes,
      width=8UL,
      height=8UL,
      pixels=64UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn wb_padded_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL,
    2UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(1UL, 14UL, 8UL, 6UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
    ],
    16UL,
    unsupported_metadata(),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    wb_operation_limits(16UL, 0UL),
  ).unwrap()
  image
    .with_mut_view(fn(view) {
      for y = 0UL; y < 2UL; y = y + 1UL {
        for x = 0UL; x < 2UL; x = x + 1UL {
          for channel = 0UL; channel < 3UL; channel = channel + 1UL {
            match
              view.set_byte(
                x,
                y,
                channel,
                ((y * 2UL + x) * 3UL + channel + 1UL).to_byte(),
              ) {
              Err(error) => return Err(error)
              Ok(_) => ()
            }
          }
        }
      }
      Ok(())
    })
    .unwrap()
  image
}

///|
fn unsupported_planar_image() -> @storage.OwnedImage {
  let format = @model.ImageFormat::new(
    @model.ComponentType::U16,
    @model.ChannelOrder::Rgb,
    @model.PlaneLayout::Planar,
    @model.Endianness::Little,
  ).unwrap()
  let descriptor = @model.ImageDescriptor::new(
    1UL,
    1UL,
    format,
    [
      @model.PlaneDescriptor::new(0UL, 2UL, 2UL, 2UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
      @model.PlaneDescriptor::new(2UL, 2UL, 2UL, 2UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
      @model.PlaneDescriptor::new(4UL, 2UL, 2UL, 2UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
    ],
    6UL,
    unsupported_metadata(),
  ).unwrap()
  @storage.OwnedImage::new(descriptor, wb_operation_limits(6UL, 0UL)).unwrap()
}

///|
test "unsupported formats reject before output charge with operation token" {
  let source = unsupported_planar_image()
  let operations = [
    ("image-copy-format", copy_image),
    ("image-flip-horizontal-format", flip_horizontal),
    ("image-flip-vertical-format", flip_vertical),
  ]
  for item in operations {
    let (token, operation) = item
    let budget = wb_operation_limits(6UL, 6UL)
    let before = budget.remaining()
    match operation(source.view(), budget) {
      Err(error) => {
        inspect(
          error.code() == @error.ErrorCode::CapabilityUnavailable,
          content="true",
        )
        inspect(error.context() == Some(token), content="true")
      }
      Ok(_) => fail("unsupported operation must reject")
    }
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.pixels() == before.pixels(), content="true")
    inspect(after.work() == before.work(), content="true")
  }
}

///|
test "work rejection is atomic and precedes allocation" {
  let source = wb_padded_image()
  let budget = wb_operation_limits(12UL, 11UL)
  let before = budget.remaining()
  inspect(copy_image(source.view(), budget) is Err(_), content="true")
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
test "single-axis flips preserve exact pixels" {
  let one_by_two = wb_padded_image()
    .view()
    .crop(@model.Rect::new(0UL, 0UL, 1UL, 2UL).unwrap())
    .unwrap()
  let horizontal = flip_horizontal(
    one_by_two,
    wb_operation_limits(6UL, 6UL),
  ).unwrap()
  inspect(horizontal.image().view().get_byte(0UL, 1UL, 0UL).unwrap() == b'\x07', content="true")
  let two_by_one = wb_padded_image()
    .view()
    .crop(@model.Rect::new(0UL, 0UL, 2UL, 1UL).unwrap())
    .unwrap()
  let vertical = flip_vertical(
    two_by_one,
    wb_operation_limits(6UL, 6UL),
  ).unwrap()
  inspect(vertical.image().view().get_byte(1UL, 0UL, 2UL).unwrap() == b'\x06', content="true")
}
