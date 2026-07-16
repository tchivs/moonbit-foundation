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
fn wb_resize_convert_image(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  alpha : @color.AlphaMode?,
  pixels : Array[Byte],
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
    @profile.ProfileIdentity::builtin_srgb(),
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
    inspect(budget.remaining().bytes() == before.bytes(), content="true")
    inspect(budget.remaining().work() == before.work(), content="true")
  }
  let budget = wb_resize_convert_limits(12UL, 11UL)
  let before = budget.remaining()
  inspect(
    resize_nearest(source.view(), 2UL, 2UL, budget) is Err(_),
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
