///|
fn wb_resize_convert_limits(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=1UL,
      allocation_size=bytes,
      width=16UL,
      height=16UL,
      pixels=256UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn wb_resize_convert_remaining_is_unchanged(
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
fn wb_resize_convert_image(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  alpha : @color.AlphaMode?,
  pixels : Array[Byte],
  profile? : @profile.ProfileIdentity = @profile.ProfileIdentity::builtin_srgb(),
) -> @storage.OwnedImage {
  let length = width * height * channels
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [],
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=16UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=8UL,
    ),
    wb_resize_convert_limits(0UL, 0UL),
  ).unwrap()
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    alpha,
    profile,
    @model.Orientation::TopLeft,
    opaque,
  )
  let format = if channels == 3UL {
    @model.ImageFormat::rgb8()
  } else {
    @model.ImageFormat::rgba8()
  }
  let descriptor = @model.ImageDescriptor::new(
    width,
    height,
    format,
    [
      @model.PlaneDescriptor::new(
        0UL,
        length,
        width * channels,
        width * channels,
        1UL,
        1UL,
        width,
        height,
      ).unwrap(),
    ],
    length,
    metadata,
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    wb_resize_convert_limits(length, 0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    let mut index = 0
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          match view.set_byte(x, y, channel, pixels[index]) {
            Err(error) => return Err(error)
            Ok(_) => index = index + 1
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
test "generated nearest axes consume every coordinate case" {
  for item in generated_resize_axis_vectors() {
    let (source_extent, destination_extent, expected) = item
    inspect(expected.length().to_uint64() == destination_extent, content="true")
    for destination = 0UL
        destination < destination_extent
        destination = destination + 1UL {
      inspect(
        nearest_source_index(destination, source_extent, destination_extent).unwrap() ==
        expected[destination.to_int()],
        content="true",
      )
    }
  }
}

///|
test "nearest resize applies the documented two-dimensional integer-floor mapping" {
  let source = wb_resize_convert_image(3UL, 2UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06', b'\x07', b'\x08', b'\x09',
    b'\x10', b'\x11', b'\x12', b'\x13', b'\x14', b'\x15', b'\x16', b'\x17', b'\x18',
  ])
  let output = resize_nearest(
    source.view(), 5UL, 4UL, wb_resize_convert_limits(60UL, 60UL),
  ).unwrap().image().view()
  for destination_y = 0UL; destination_y < 4UL; destination_y = destination_y + 1UL {
    let source_y = (destination_y * 2UL) / 4UL
    for destination_x = 0UL; destination_x < 5UL; destination_x = destination_x + 1UL {
      let source_x = (destination_x * 3UL) / 5UL
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        inspect(
          output.get_byte(destination_x, destination_y, channel).unwrap() ==
          source.view().get_byte(source_x, source_y, channel).unwrap(),
          content="true",
        )
      }
    }
  }
}

///|
test "nearest resize applies the documented two-dimensional mapping to every RGBA channel" {
  let source = wb_resize_convert_image(2UL, 3UL, 4UL, Some(@color.AlphaMode::Straight), [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x11', b'\x12', b'\x13', b'\x14',
    b'\x21', b'\x22', b'\x23', b'\x24', b'\x31', b'\x32', b'\x33', b'\x34',
    b'\x41', b'\x42', b'\x43', b'\x44', b'\x51', b'\x52', b'\x53', b'\x54',
  ])
  let output = resize_nearest(
    source.view(), 5UL, 4UL, wb_resize_convert_limits(80UL, 80UL),
  ).unwrap().image().view()
  for destination_y = 0UL; destination_y < 4UL; destination_y = destination_y + 1UL {
    let source_y = (destination_y * 3UL) / 4UL
    for destination_x = 0UL; destination_x < 5UL; destination_x = destination_x + 1UL {
      let source_x = (destination_x * 2UL) / 5UL
      for channel = 0UL; channel < 4UL; channel = channel + 1UL {
        inspect(
          output.get_byte(destination_x, destination_y, channel).unwrap() ==
          source.view().get_byte(source_x, source_y, channel).unwrap(),
          content="true",
        )
      }
    }
  }
}

///|
test "nearest resize rejects zero axes and insufficient work atomically" {
  let source = wb_resize_convert_image(1UL, 1UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03',
  ])
  for dimensions in [(0UL, 1UL), (1UL, 0UL)] {
    let budget = wb_resize_convert_limits(3UL, 3UL)
    let before = budget.remaining()
    inspect(
      resize_nearest(source.view(), dimensions.0, dimensions.1, budget)
      is Err(_),
      content="true",
    )
    inspect(
      wb_resize_convert_remaining_is_unchanged(before, budget.remaining()),
      content="true",
    )
  }
  let budget = wb_resize_convert_limits(12UL, 11UL)
  let before = budget.remaining()
  inspect(
    resize_nearest(source.view(), 2UL, 2UL, budget) is Err(_),
    content="true",
  )
  inspect(
    wb_resize_convert_remaining_is_unchanged(before, budget.remaining()),
    content="true",
  )
}

///|
test "nearest resize capability rejection is typed and leaves the full budget unchanged" {
  let source = unsupported_image(
    @model.ComponentType::U16,
    @model.ChannelOrder::Rgb,
    @model.PlaneLayout::Packed,
  )
  let budget = wb_resize_convert_limits(12UL, 12UL)
  let before = budget.remaining()
  match resize_nearest(source.view(), 2UL, 2UL, budget) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
      inspect(error.operation() == Some("image-resize-nearest"), content="true")
      inspect(error.context() == Some("image-resize-nearest-format"), content="true")
    }
    Ok(_) => fail("unsupported resize must reject")
  }
  inspect(
    wb_resize_convert_remaining_is_unchanged(before, budget.remaining()),
    content="true",
  )
}

///|
test "generated RGB RGBA conversion vectors are behaviorally consumed" {
  for item in generated_conversion_vectors() {
    let (source, expected, lossy) = item
    let source_bytes : Array[Byte] = []
    for value in source {
      source_bytes.push(value.to_byte())
    }
    let input = if source.length() == 3 {
      wb_resize_convert_image(1UL, 1UL, 3UL, None, source_bytes)
    } else {
      wb_resize_convert_image(
        1UL,
        1UL,
        4UL,
        Some(@color.AlphaMode::Straight),
        source_bytes,
      )
    }
    let result_result = if source.length() == 3 {
      rgb8_to_straight_rgba8(input.view(), wb_resize_convert_limits(4UL, 4UL))
    } else if lossy {
      drop_straight_rgba8_alpha(
        input.view(),
        wb_resize_convert_limits(3UL, 3UL),
      )
    } else {
      straight_rgba8_to_rgb8(input.view(), wb_resize_convert_limits(3UL, 3UL))
    }
    let result = result_result.unwrap()
    let output = result.image().view()
    for index = 0; index < expected.length(); index = index + 1 {
      inspect(
        output.get_byte(0UL, 0UL, index.to_uint64()).unwrap() ==
        expected[index].to_byte(),
        content="true",
      )
    }
    inspect(result.disposition().is_lossy() == lossy, content="true")
  }
}

///|
test "unsupported conversion fails before authoritative charge" {
  let rgb = wb_resize_convert_image(1UL, 1UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03',
  ])
  let budget = wb_resize_convert_limits(4UL, 4UL)
  let before = budget.remaining()
  inspect(
    straight_rgba8_to_premultiplied(rgb.view(), budget) is Err(_),
    content="true",
  )
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(
    budget.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "invalid premultiplied pixels reject before authoritative charge" {
  let invalid = wb_resize_convert_image(
    1UL,
    1UL,
    4UL,
    Some(@color.AlphaMode::Premultiplied),
    [b'\x11', b'\x00', b'\x00', b'\x10'],
  )
  let budget = wb_resize_convert_limits(4UL, 4UL)
  let before = budget.remaining()
  inspect(
    premultiplied_rgba8_to_straight(invalid.view(), budget) is Err(_),
    content="true",
  )
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "bilinear coordinates retain nearest bases and clamp only high neighbours" {
  let first = bilinear_source_coordinate(0UL, 2UL, 3UL).unwrap()
  inspect(first.0 == 0UL && first.1 == 1UL && first.2 == 0UL, content="true")
  let middle = bilinear_source_coordinate(1UL, 2UL, 3UL).unwrap()
  inspect(middle.0 == 0UL && middle.1 == 1UL && middle.2 == 2UL, content="true")
  let edge = bilinear_source_coordinate(2UL, 2UL, 3UL).unwrap()
  inspect(edge.0 == 1UL && edge.1 == 1UL && edge.2 == 1UL, content="true")
  let downscaled = bilinear_source_coordinate(0UL, 2UL, 1UL).unwrap()
  inspect(
    downscaled.0 == 0UL && downscaled.1 == 1UL && downscaled.2 == 0UL,
    content="true",
  )
}

///|
test "bilinear failures are typed and preserve the complete budget snapshot" {
  let source = wb_resize_convert_image(1UL, 1UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03',
  ])
  for dimensions in [(0UL, 1UL), (1UL, 0UL)] {
    let budget = wb_resize_convert_limits(12UL, 48UL)
    let before = budget.remaining()
    match resize_bilinear(source.view(), dimensions.0, dimensions.1, budget) {
      Err(error) => {
        inspect(error.operation() == Some("image-resize-bilinear"), content="true")
        inspect(error.context() == Some("zero-destination-axis"), content="true")
      }
      Ok(_) => fail("zero destination axis must reject")
    }
    inspect(
      wb_resize_convert_remaining_is_unchanged(before, budget.remaining()),
      content="true",
    )
  }
  let unsupported = unsupported_image(
    @model.ComponentType::U16,
    @model.ChannelOrder::Rgb,
    @model.PlaneLayout::Packed,
  )
  let budget = wb_resize_convert_limits(12UL, 48UL)
  let before = budget.remaining()
  match resize_bilinear(unsupported.view(), 2UL, 2UL, budget) {
    Err(error) => {
      inspect(error.operation() == Some("image-resize-bilinear"), content="true")
      inspect(error.context() == Some("image-resize-bilinear-format"), content="true")
    }
    Ok(_) => fail("unsupported bilinear input must reject")
  }
  inspect(
    wb_resize_convert_remaining_is_unchanged(before, budget.remaining()),
    content="true",
  )
}

///|
test "bilinear rejects empty metadata overflow and each output charge boundary atomically" {
  let source = wb_resize_convert_image(1UL, 1UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03',
  ])
  let empty = source.view().crop(
    @model.Rect::new(0UL, 0UL, 0UL, 1UL).unwrap(),
  ).unwrap()
  let empty_budget = wb_resize_convert_limits(3UL, 4UL)
  let empty_before = empty_budget.remaining()
  match resize_bilinear(empty, 1UL, 1UL, empty_budget) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::InvalidDimensions, content="true")
      inspect(error.operation() == Some("image-resize-bilinear"), content="true")
      inspect(error.context() == Some("empty-operation-source"), content="true")
    }
    Ok(_) => fail("empty bilinear source must reject")
  }
  inspect(
    wb_resize_convert_remaining_is_unchanged(empty_before, empty_budget.remaining()),
    content="true",
  )

  let custom_profile = @profile.ProfileIdentity::opaque(
    @profile.OpaqueProfile::from_bytes(
      @profile.ProfileFormatTag::icc(),
      b"x",
      @profile.ProfileLimits::new(1UL),
      wb_resize_convert_limits(1UL, 0UL),
    ).unwrap(),
  )
  let metadata_rejected = [
    processing_wb_variant_image(
      @model.ComponentType::U8,
      @model.ChannelOrder::Rgb,
      @model.PlaneLayout::Packed,
      @color.TransferIdentity::LinearSrgb,
      None,
    ),
    wb_resize_convert_image(
      1UL,
      1UL,
      3UL,
      None,
      [b'\x01', b'\x02', b'\x03'],
      profile=custom_profile,
    ),
  ]
  for rejected in metadata_rejected {
    let metadata_budget = wb_resize_convert_limits(3UL, 4UL)
    let metadata_before = metadata_budget.remaining()
    match resize_bilinear(rejected.view(), 1UL, 1UL, metadata_budget) {
      Err(error) => {
        inspect(error.category() == @error.ErrorCategory::Capability, content="true")
        inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
        inspect(error.operation() == Some("image-resize-bilinear"), content="true")
        inspect(error.context() == Some("image-resize-bilinear-metadata"), content="true")
      }
      Ok(_) => fail("non-sRGB bilinear metadata must reject")
    }
    inspect(
      wb_resize_convert_remaining_is_unchanged(metadata_before, metadata_budget.remaining()),
      content="true",
    )
  }

  let overflow_budget = wb_resize_convert_limits(3UL, 4UL)
  let overflow_before = overflow_budget.remaining()
  inspect(
    resize_bilinear(source.view(), 18446744073709551615UL, 1UL, overflow_budget) is Err(_),
    content="true",
  )
  inspect(
    wb_resize_convert_remaining_is_unchanged(overflow_before, overflow_budget.remaining()),
    content="true",
  )

  for limit in [
    (2UL, 1UL, 3UL, 1UL, 1UL, 1UL, 4UL),
    (3UL, 0UL, 3UL, 1UL, 1UL, 1UL, 4UL),
    (3UL, 1UL, 2UL, 1UL, 1UL, 1UL, 4UL),
    (3UL, 1UL, 3UL, 0UL, 1UL, 1UL, 4UL),
    (3UL, 1UL, 3UL, 1UL, 0UL, 1UL, 4UL),
    (3UL, 1UL, 3UL, 1UL, 1UL, 0UL, 4UL),
    (3UL, 1UL, 3UL, 1UL, 1UL, 1UL, 3UL),
  ] {
    let budget = @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=limit.0,
      allocations=limit.1,
      allocation_size=limit.2,
      width=limit.3,
      height=limit.4,
      pixels=limit.5,
      depth=0UL,
      work=limit.6,
    ))
    let before = budget.remaining()
    inspect(resize_bilinear(source.view(), 1UL, 1UL, budget) is Err(_), content="true")
    inspect(
      wb_resize_convert_remaining_is_unchanged(before, budget.remaining()),
      content="true",
    )
  }
}
