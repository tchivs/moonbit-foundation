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
      inspect(error.operation() == Some("image-composite-source-over"), content="true")
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

///|
fn processing_wb_remaining_is_unchanged(
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
fn processing_wb_assert_rejection(
  result : Result[ImageOperationResult, @error.CoreError],
  budget : @budget.Budget,
  before : @budget.ResourceLimits,
  operation : String,
  code : @error.ErrorCode,
  context : String,
) -> Bool {
  match result {
    Err(error) =>
      error.code() == code &&
      error.operation() == Some(operation) &&
      error.context() == Some(context) &&
      processing_wb_remaining_is_unchanged(before, budget.remaining())
    Ok(_) => false
  }
}

///|
fn processing_wb_oracle_load(pixel : Array[Byte]) -> @alpha.PremultipliedNormalizedSrgba {
  let straight = @alpha.StraightNormalizedSrgba::linear(
    @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(pixel[0]))),
    @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(pixel[1]))),
    @transfer.decode_srgb(@quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(pixel[2]))),
    @quantize.dequantize_alpha(@color.EncodedAlpha8::from_byte(pixel[3])),
  )
  @alpha.premultiply_normalized(straight).unwrap()
}

///|
fn processing_wb_oracle_store(value : @alpha.PremultipliedNormalizedSrgba) -> Array[Byte] {
  let straight = @alpha.unpremultiply_normalized(value).unwrap()
  let (r, g, b) = straight.linear_rgb().unwrap()
  [
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(r)).value(),
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(g)).value(),
    @quantize.quantize_encoded_srgb(@transfer.encode_srgb(b)).value(),
    @quantize.quantize_alpha(straight.alpha()).value(),
  ]
}

///|
fn processing_wb_oracle_source_over(source : Array[Byte], destination : Array[Byte]) -> Array[Byte] {
  let s = processing_wb_oracle_load(source)
  let d = processing_wb_oracle_load(destination)
  let (sr, sg, sb) = s.linear_rgb().unwrap()
  let (dr, dg, db) = d.linear_rgb().unwrap()
  let factor = 1.0 - s.alpha().value()
  processing_wb_oracle_store(@alpha.PremultipliedNormalizedSrgba::linear(
    @color.LinearSrgbComponent::new(sr.value() + dr.value() * factor).unwrap(),
    @color.LinearSrgbComponent::new(sg.value() + dg.value() * factor).unwrap(),
    @color.LinearSrgbComponent::new(sb.value() + db.value() * factor).unwrap(),
    @color.NormalizedAlpha::new(s.alpha().value() + d.alpha().value() * factor).unwrap(),
  ).unwrap())
}

///|
fn processing_wb_oracle_grayscale(source : Array[Byte]) -> Array[Byte] {
  let value = processing_wb_oracle_load(source)
  let (r, g, b) = value.linear_rgb().unwrap()
  let luminance = r.value() * 0.2126 + g.value() * 0.7152 + b.value() * 0.0722
  processing_wb_oracle_store(@alpha.PremultipliedNormalizedSrgba::linear(
    @color.LinearSrgbComponent::new(luminance).unwrap(),
    @color.LinearSrgbComponent::new(luminance).unwrap(),
    @color.LinearSrgbComponent::new(luminance).unwrap(),
    value.alpha(),
  ).unwrap())
}

///|
fn processing_wb_variant_image(
  component : @model.ComponentType,
  channels : @model.ChannelOrder,
  layout : @model.PlaneLayout,
  transfer : @color.TransferIdentity,
  alpha : @color.AlphaMode?,
) -> @storage.OwnedImage {
  let format = @model.ImageFormat::new(component, channels, layout, @model.Endianness::Little).unwrap()
  let component_bytes = match component { @model.ComponentType::U8 => 1UL; @model.ComponentType::U16 => 2UL; @model.ComponentType::F32 => 4UL }
  let channel_count = match channels { @model.ChannelOrder::Gray => 1UL; @model.ChannelOrder::GrayAlpha => 2UL; @model.ChannelOrder::Rgb => 3UL; @model.ChannelOrder::Rgba => 4UL }
  let plane_count = if layout == @model.PlaneLayout::Packed { 1UL } else { channel_count }
  let row_bytes = if layout == @model.PlaneLayout::Packed { component_bytes * channel_count } else { component_bytes }
  let planes : Array[@model.PlaneDescriptor] = []
  for index = 0UL; index < plane_count; index = index + 1UL {
    planes.push(@model.PlaneDescriptor::new(index * row_bytes, row_bytes, row_bytes, row_bytes, 1UL, 1UL, 1UL, 1UL).unwrap())
  }
  let storage_length = plane_count * row_bytes
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, transfer, alpha, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
    @metadata.OpaqueMetadata::from_entries([], @metadata.MetadataLimits::new(max_entries=0UL, max_token_bytes=16UL, max_value_bytes=0UL, max_total_bytes=0UL, max_disposition_fields=8UL), processing_wb_limits(0UL, 0UL)).unwrap(),
  )
  @storage.OwnedImage::new(@model.ImageDescriptor::new(1UL, 1UL, format, planes, storage_length, metadata).unwrap(), processing_wb_limits(storage_length, 0UL)).unwrap()
}

///|
test "processing oracle fixes translucent linear-premultiplied byte vectors" {
  let source = [b'\x20', b'\x40', b'\x80', b'\x60']
  let destination = [b'\xf0', b'\x20', b'\x10', b'\xa0']
  let composite_expected = [b'\xb3', b'\x33', b'\x5d', b'\xc4']
  inspect(processing_wb_oracle_source_over(source, destination) == composite_expected, content="true")
  let composite = composite_source_over(
    processing_wb_image(1UL, 1UL, source).view(),
    processing_wb_image(1UL, 1UL, destination).view(),
    processing_wb_limits(4UL, 1UL),
  ).unwrap().image().view()
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(composite.get_byte(0UL, 0UL, channel).unwrap() == composite_expected[channel.to_int()], content="true")
  }

  let gray_source = [b'\x20', b'\xa0', b'\xe0', b'\x60']
  let gray_expected = [b'\x97', b'\x97', b'\x97', b'\x60']
  inspect(processing_wb_oracle_grayscale(gray_source) == gray_expected, content="true")
  let gray = grayscale(processing_wb_image(1UL, 1UL, gray_source).view(), processing_wb_limits(4UL, 1UL)).unwrap().image().view()
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(gray.get_byte(0UL, 0UL, channel).unwrap() == gray_expected[channel.to_int()], content="true")
  }

  let blur_source = processing_wb_image(2UL, 1UL, [
    b'\xff', b'\x00', b'\x00', b'\x00', b'\x00', b'\x40', b'\xff', b'\x80',
  ])
  let blurred = box_blur(blur_source.view(), 1UL, processing_wb_limits(8UL, 18UL)).unwrap().image().view()
  let blur_expected = [b'\x00', b'\x40', b'\xff', b'\x2b', b'\x00', b'\x40', b'\xff', b'\x55']
  for x = 0UL; x < 2UL; x = x + 1UL {
    for channel = 0UL; channel < 4UL; channel = channel + 1UL {
      inspect(blurred.get_byte(x, 0UL, channel).unwrap() == blur_expected[(x * 4UL + channel).to_int()], content="true")
    }
  }
}

///|
test "processing rejects capability, metadata, overflow, and every resource limit atomically" {
  let source = processing_wb_image(1UL, 1UL, [b'\x20', b'\x40', b'\x80', b'\x60'])
  let destination = processing_wb_image(1UL, 1UL, [b'\xf0', b'\x20', b'\x10', b'\xa0'])
  let unsupported = [
    processing_wb_variant_image(@model.ComponentType::U16, @model.ChannelOrder::Rgba, @model.PlaneLayout::Packed, @color.TransferIdentity::EncodedSrgb, Some(@color.AlphaMode::Straight)),
    processing_wb_variant_image(@model.ComponentType::U8, @model.ChannelOrder::Rgba, @model.PlaneLayout::Planar, @color.TransferIdentity::EncodedSrgb, Some(@color.AlphaMode::Straight)),
    processing_wb_variant_image(@model.ComponentType::U8, @model.ChannelOrder::Rgb, @model.PlaneLayout::Packed, @color.TransferIdentity::EncodedSrgb, None),
    processing_wb_variant_image(@model.ComponentType::U8, @model.ChannelOrder::Rgba, @model.PlaneLayout::Packed, @color.TransferIdentity::LinearSrgb, Some(@color.AlphaMode::Straight)),
    processing_wb_variant_image(@model.ComponentType::U8, @model.ChannelOrder::Rgba, @model.PlaneLayout::Packed, @color.TransferIdentity::EncodedSrgb, Some(@color.AlphaMode::Premultiplied)),
  ]
  for image in unsupported {
    for operation in ["composite", "grayscale", "blur"] {
      let budget = processing_wb_limits(8UL, 9UL)
      let before = budget.remaining()
      let result = if operation == "composite" { composite_source_over(image.view(), destination.view(), budget) }
        else if operation == "grayscale" { grayscale(image.view(), budget) }
        else { box_blur(image.view(), 1UL, budget) }
      let operation_name = if operation == "composite" { "image-composite-source-over" } else if operation == "grayscale" { "image-grayscale" } else { "image-box-blur" }
      inspect(processing_wb_assert_rejection(result, budget, before, operation_name, @error.ErrorCode::CapabilityUnavailable, operation_name + "-format"), content="true")
    }
  }

  let dimensions = processing_wb_image(2UL, 1UL, [b'\x00', b'\x00', b'\x00', b'\xff', b'\x00', b'\x00', b'\x00', b'\xff'])
  let dimensions_budget = processing_wb_limits(8UL, 8UL); let dimensions_before = dimensions_budget.remaining()
  inspect(processing_wb_assert_rejection(composite_source_over(source.view(), dimensions.view(), dimensions_budget), dimensions_budget, dimensions_before, "image-composite-source-over", @error.ErrorCode::InvalidDimensions, "image-composite-source-over-dimensions"), content="true")

  for radius in [9223372036854775808UL, 18446744073709551615UL] {
    let budget = processing_wb_limits(4UL, 1UL); let before = budget.remaining()
    match box_blur(source.view(), radius, budget) {
      Err(error) => { inspect(error.code() == @error.ErrorCode::ArithmeticOverflow, content="true"); inspect(error.operation() == Some("checked_add") || error.operation() == Some("checked_mul"), content="true") }
      Ok(_) => fail("overflowing blur radius must reject")
    }
    inspect(processing_wb_remaining_is_unchanged(before, budget.remaining()), content="true")
  }

  let limits = [
    (3UL, 1UL, 4UL, 1UL, 1UL, 1UL, 0UL, 1UL),
    (4UL, 0UL, 4UL, 1UL, 1UL, 1UL, 0UL, 1UL),
    (4UL, 1UL, 3UL, 1UL, 1UL, 1UL, 0UL, 1UL),
    (4UL, 1UL, 4UL, 0UL, 1UL, 1UL, 0UL, 1UL),
    (4UL, 1UL, 4UL, 1UL, 0UL, 1UL, 0UL, 1UL),
    (4UL, 1UL, 4UL, 1UL, 1UL, 0UL, 0UL, 1UL),
    (4UL, 1UL, 4UL, 1UL, 1UL, 1UL, 0UL, 0UL),
  ]
  for item in limits {
    for operation in ["composite", "grayscale", "blur"] {
      let budget = @budget.Budget::new(@budget.ResourceLimits::new(
        bytes=item.0, allocations=item.1, allocation_size=item.2,
        width=item.3, height=item.4, pixels=item.5, depth=item.6,
        work=if operation == "blur" && item.7 != 0UL { 9UL } else { item.7 },
      ))
      let before = budget.remaining()
      let result = if operation == "composite" { composite_source_over(source.view(), destination.view(), budget) }
        else if operation == "grayscale" { grayscale(source.view(), budget) }
        else { box_blur(source.view(), 1UL, budget) }
      let operation_name = if operation == "composite" { "image-composite-source-over" } else if operation == "grayscale" { "image-grayscale" } else { "image-box-blur" }
      inspect(processing_wb_assert_rejection(result, budget, before, operation_name, @error.ErrorCode::BudgetExceeded, operation_name + "-output-budget"), content="true")
    }
  }
}
