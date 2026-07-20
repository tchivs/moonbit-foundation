///|
fn geometry_wb_limits(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  width : UInt64,
  height : UInt64,
  pixels : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width~,
      height~,
      pixels~,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn geometry_wb_remaining_is_unchanged(
  before : @budget.ResourceLimits,
  after : @budget.ResourceLimits,
) -> Bool {
  before.bytes() == after.bytes() &&
  before.allocations() == after.allocations() &&
  before.allocation_size() == after.allocation_size() &&
  before.width() == after.width() &&
  before.height() == after.height() &&
  before.pixels() == after.pixels() &&
  before.depth() == after.depth() &&
  before.work() == after.work()
}

///|
fn geometry_wb_linear_srgb_image() -> @storage.OwnedImage {
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
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::LinearSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    opaque,
  )
  let descriptor = @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::rgb8(),
    [@model.PlaneDescriptor::new(0UL, 3UL, 3UL, 3UL, 1UL, 1UL, 1UL, 1UL).unwrap()],
    3UL,
    metadata,
  ).unwrap()
  @storage.OwnedImage::new(descriptor, wb_operation_limits(3UL, 0UL)).unwrap()
}

///|
test "geometry rejects checked rectangles and capability variants without charging" {
  match @model.Rect::new(18446744073709551615UL, 0UL, 1UL, 1UL) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::ArithmeticOverflow, content="true")
    }
    Ok(_) => fail("overflowing rectangle endpoint must reject")
  }

  let source = wb_resize_convert_image(2UL, 3UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
    b'\x07', b'\x08', b'\x09', b'\x0a', b'\x0b', b'\x0c',
    b'\x0d', b'\x0e', b'\x0f', b'\x10', b'\x11', b'\x12',
  ])
  let empty_budget = geometry_wb_limits(18UL, 1UL, 18UL, 3UL, 3UL, 6UL, 18UL)
  let empty_before = empty_budget.remaining()
  match crop(source.view(), @model.Rect::new(0UL, 0UL, 0UL, 1UL).unwrap(), empty_budget) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::InvalidDimensions, content="true")
      inspect(error.operation() == Some("image-crop"), content="true")
    }
    Ok(_) => fail("empty crop must reject")
  }
  inspect(geometry_wb_remaining_is_unchanged(empty_before, empty_budget.remaining()), content="true")

  let outside_budget = geometry_wb_limits(18UL, 1UL, 18UL, 3UL, 3UL, 6UL, 18UL)
  let outside_before = outside_budget.remaining()
  match crop(source.view(), @model.Rect::new(1UL, 2UL, 2UL, 1UL).unwrap(), outside_budget) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      inspect(error.context() == Some("crop-region-outside-source"), content="true")
    }
    Ok(_) => fail("outside crop must reject")
  }
  inspect(geometry_wb_remaining_is_unchanged(outside_before, outside_budget.remaining()), content="true")

  let unsupported = [
    unsupported_image(@model.ComponentType::U16, @model.ChannelOrder::Rgb, @model.PlaneLayout::Packed),
    unsupported_image(@model.ComponentType::U8, @model.ChannelOrder::Rgb, @model.PlaneLayout::Planar),
    unsupported_image(@model.ComponentType::U8, @model.ChannelOrder::Gray, @model.PlaneLayout::Packed),
    geometry_wb_linear_srgb_image(),
  ]
  for image in unsupported {
    let budget = geometry_wb_limits(18UL, 1UL, 18UL, 3UL, 3UL, 6UL, 18UL)
    let before = budget.remaining()
    match rotate_90(image.view(), budget) {
      Err(error) => {
        inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
        inspect(error.operation() == Some("image-rotate-90"), content="true")
      }
      Ok(_) => fail("unsupported geometry must reject")
    }
    inspect(geometry_wb_remaining_is_unchanged(before, budget.remaining()), content="true")
  }
}

///|
test "crop and rotations reject every output resource atomically" {
  let source = wb_resize_convert_image(2UL, 3UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
    b'\x07', b'\x08', b'\x09', b'\x0a', b'\x0b', b'\x0c',
    b'\x0d', b'\x0e', b'\x0f', b'\x10', b'\x11', b'\x12',
  ])
  let limits = [
    (17UL, 1UL, 18UL, 3UL, 3UL, 6UL, 18UL),
    (18UL, 0UL, 18UL, 3UL, 3UL, 6UL, 18UL),
    (18UL, 1UL, 17UL, 3UL, 3UL, 6UL, 18UL),
    (18UL, 1UL, 18UL, 1UL, 3UL, 6UL, 18UL),
    (18UL, 1UL, 18UL, 3UL, 1UL, 6UL, 18UL),
    (18UL, 1UL, 18UL, 3UL, 3UL, 5UL, 18UL),
    (18UL, 1UL, 18UL, 3UL, 3UL, 6UL, 17UL),
  ]
  for item in limits {
    let budget = geometry_wb_limits(item.0, item.1, item.2, item.3, item.4, item.5, item.6)
    let before = budget.remaining()
    match crop(source.view(), @model.Rect::new(0UL, 0UL, 2UL, 3UL).unwrap(), budget) {
      Err(error) => inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
      Ok(_) => fail("crop resource limit must reject")
    }
    inspect(geometry_wb_remaining_is_unchanged(before, budget.remaining()), content="true")
  }
  for operation in [rotate_90, rotate_180, rotate_270] {
    for item in limits {
      let budget = geometry_wb_limits(item.0, item.1, item.2, item.3, item.4, item.5, item.6)
      let before = budget.remaining()
      match operation(source.view(), budget) {
        Err(error) => inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
        Ok(_) => fail("rotation resource limit must reject")
      }
      inspect(geometry_wb_remaining_is_unchanged(before, budget.remaining()), content="true")
    }
  }
}

///|
test "geometry rotations exhaustively satisfy the non-square RGB and RGBA oracle" {
  for alpha in [None, Some(@color.AlphaMode::Straight)] {
    let channels = if alpha is None { 3UL } else { 4UL }
    let pixels : Array[Byte] = []
    for y = 0UL; y < 3UL; y = y + 1UL {
      for x = 0UL; x < 2UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          pixels.push((y * 32UL + x * 8UL + channel).to_byte())
        }
      }
    }
    let source = wb_resize_convert_image(2UL, 3UL, channels, alpha, pixels)
    let results = [
      rotate_90(source.view(), geometry_wb_limits(24UL, 1UL, 24UL, 3UL, 3UL, 6UL, 24UL)).unwrap(),
      rotate_180(source.view(), geometry_wb_limits(24UL, 1UL, 24UL, 3UL, 3UL, 6UL, 24UL)).unwrap(),
      rotate_270(source.view(), geometry_wb_limits(24UL, 1UL, 24UL, 3UL, 3UL, 6UL, 24UL)).unwrap(),
    ]
    for y = 0UL; y < 3UL; y = y + 1UL {
      for x = 0UL; x < 2UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          let value = source.view().get_byte(x, y, channel).unwrap()
          inspect(results[0].image().view().get_byte(2UL - y, x, channel).unwrap() == value, content="true")
          inspect(results[1].image().view().get_byte(1UL - x, 2UL - y, channel).unwrap() == value, content="true")
          inspect(results[2].image().view().get_byte(y, 1UL - x, channel).unwrap() == value, content="true")
        }
      }
    }
    for result in results {
      inspect(result.image().metadata().orientation() == @model.Orientation::TopLeft, content="true")
      inspect(result.disposition().transformed(0).unwrap().value(), content="orientation")
    }
  }
}
