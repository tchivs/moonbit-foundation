///|
fn resize_convert_limits(bytes : UInt64, work : UInt64) -> @budget.Budget {
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
fn resize_convert_metadata(alpha : @color.AlphaMode?) -> @model.ImageMetadata {
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [("test", "resize-convert", "raw", b"kept")],
    @metadata.MetadataLimits::new(
      max_entries=1UL,
      max_token_bytes=20UL,
      max_value_bytes=4UL,
      max_total_bytes=32UL,
      max_disposition_fields=8UL,
    ),
    resize_convert_limits(4UL, 0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    alpha,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::RightBottom,
    opaque,
  )
}

///|
fn resize_convert_image(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  alpha : @color.AlphaMode?,
  pixels : Array[Byte],
) -> @storage.OwnedImage {
  let length = width * height * channels
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
    resize_convert_metadata(alpha),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    resize_convert_limits(length, 0UL),
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
test "nearest resize uses integer floor and fresh tight output" {
  let source = resize_convert_image(2UL, 1UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
  ])
  let result = @ops.resize_nearest(
    source.view(),
    5UL,
    1UL,
    resize_convert_limits(15UL, 15UL),
  ).unwrap()
  let output = result.image()
  inspect(output.storage_length(), content="15")
  inspect(output.view().row_stride(), content="15")
  inspect(
    output.metadata().orientation() == @model.Orientation::RightBottom,
    content="true",
  )
  for x = 0UL; x < 5UL; x = x + 1UL {
    let source_x = [0UL, 0UL, 0UL, 1UL, 1UL][x.to_int()]
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      inspect(
        output.view().get_byte(x, 0UL, channel).unwrap() ==
        source.view().get_byte(source_x, 0UL, channel).unwrap(),
        content="true",
      )
    }
  }
  inspect(result.disposition().preserved_length(), content="5")
}

///|
test "RGB and straight RGBA conversion contracts are explicit" {
  let rgb = resize_convert_image(1UL, 1UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03',
  ])
  let rgba = @ops.rgb8_to_straight_rgba8(
    rgb.view(),
    resize_convert_limits(4UL, 4UL),
  ).unwrap()
  inspect(
    rgba.image().view().get_byte(0UL, 0UL, 3UL).unwrap(),
    content="b'\\xFF'",
  )
  inspect(
    rgba.image().metadata().alpha() == Some(@color.AlphaMode::Straight),
    content="true",
  )
  inspect(rgba.disposition().transformed(0).unwrap().value(), content="alpha")

  let opaque = resize_convert_image(
    1UL,
    1UL,
    4UL,
    Some(@color.AlphaMode::Straight),
    [b'\x04', b'\x05', b'\x06', b'\xff'],
  )
  let strict = @ops.straight_rgba8_to_rgb8(
    opaque.view(),
    resize_convert_limits(3UL, 3UL),
  ).unwrap()
  inspect(
    strict.image().view().get_byte(0UL, 0UL, 2UL).unwrap(),
    content="b'\\x06'",
  )
  inspect(strict.disposition().is_lossy(), content="false")

  let translucent = resize_convert_image(
    1UL,
    1UL,
    4UL,
    Some(@color.AlphaMode::Straight),
    [b'\x07', b'\x08', b'\x09', b'\x0a'],
  )
  let budget = resize_convert_limits(3UL, 3UL)
  let before = budget.remaining()
  inspect(
    @ops.straight_rgba8_to_rgb8(translucent.view(), budget) is Err(_),
    content="true",
  )
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  let lossy = @ops.drop_straight_rgba8_alpha(
    translucent.view(),
    resize_convert_limits(3UL, 3UL),
  ).unwrap()
  inspect(
    lossy.image().view().get_byte(0UL, 0UL, 2UL).unwrap(),
    content="b'\\x09'",
  )
  inspect(lossy.disposition().discarded(0).unwrap().value(), content="alpha")
  inspect(lossy.disposition().is_lossy(), content="true")
}

///|
test "straight and premultiplied conversion delegates encoded alpha semantics" {
  let straight = resize_convert_image(
    2UL,
    1UL,
    4UL,
    Some(@color.AlphaMode::Straight),
    [b'\xff', b'\x80', b'\x01', b'\x80', b'\xff', b'\xff', b'\xff', b'\x00'],
  )
  let premultiplied = @ops.straight_rgba8_to_premultiplied(
    straight.view(),
    resize_convert_limits(8UL, 8UL),
  ).unwrap()
  inspect(
    premultiplied.image().view().get_byte(0UL, 0UL, 0UL).unwrap(),
    content="b'\\x80'",
  )
  inspect(
    premultiplied.image().view().get_byte(0UL, 0UL, 1UL).unwrap(),
    content="b'\\x40'",
  )
  inspect(
    premultiplied.image().view().get_byte(1UL, 0UL, 0UL).unwrap(),
    content="b'\\x00'",
  )
  let restored = @ops.premultiplied_rgba8_to_straight(
    premultiplied.image().view(),
    resize_convert_limits(8UL, 8UL),
  ).unwrap()
  inspect(
    restored.image().view().get_byte(1UL, 0UL, 0UL).unwrap(),
    content="b'\\x00'",
  )
  inspect(
    restored.image().metadata().profile().is_builtin_srgb(),
    content="true",
  )
}

///|
test "bilinear resize filters RGB8 in linear light" {
  let source = resize_convert_image(2UL, 1UL, 3UL, None, [
    b'\x00', b'\x00', b'\x00', b'\xff', b'\xff', b'\xff',
  ])
  let result = @ops.resize_bilinear(
    source.view(), 3UL, 1UL, resize_convert_limits(9UL, 12UL),
  ).unwrap()
  let output = result.image()
  inspect(
    output.view().format().channels() == @model.ChannelOrder::Rgb,
    content="true",
  )
  inspect(output.metadata().alpha() == None, content="true")
  for channel = 0UL; channel < 3UL; channel = channel + 1UL {
    inspect(output.view().get_byte(0UL, 0UL, channel).unwrap(), content="b'\\x00'")
    inspect(output.view().get_byte(1UL, 0UL, channel).unwrap(), content="b'\\xD5'")
    inspect(output.view().get_byte(2UL, 0UL, channel).unwrap(), content="b'\\xFF'")
  }
}

///|
test "bilinear resize preserves opaque RGB8 and straight RGBA8 identity and parity" {
  let expected_rgb = [b'\x12', b'\x34', b'\x56']
  let rgb_identity = resize_convert_image(1UL, 1UL, 3UL, None, expected_rgb)
  let rgba_identity = resize_convert_image(
    1UL,
    1UL,
    4UL,
    Some(@color.AlphaMode::Straight),
    [b'\x12', b'\x34', b'\x56', b'\xff'],
  )
  for dimensions in [(1UL, 1UL), (2UL, 3UL), (4UL, 2UL)] {
    let pixels = dimensions.0 * dimensions.1
    let rgb_output = @ops.resize_bilinear(
      rgb_identity.view(),
      dimensions.0,
      dimensions.1,
      resize_convert_limits(pixels * 3UL, pixels * 4UL),
    ).unwrap().image().view()
    let rgba_output = @ops.resize_bilinear(
      rgba_identity.view(),
      dimensions.0,
      dimensions.1,
      resize_convert_limits(pixels * 4UL, pixels * 4UL),
    ).unwrap().image().view()
    for y = 0UL; y < dimensions.1; y = y + 1UL {
      for x = 0UL; x < dimensions.0; x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          let expected = expected_rgb[channel.to_int()]
          inspect(rgb_output.get_byte(x, y, channel).unwrap() == expected, content="true")
          inspect(rgba_output.get_byte(x, y, channel).unwrap() == expected, content="true")
          inspect(
            rgb_output.get_byte(x, y, channel).unwrap() ==
            rgba_output.get_byte(x, y, channel).unwrap(),
            content="true",
          )
        }
        inspect(rgba_output.get_byte(x, y, 3UL).unwrap(), content="b'\\xFF'")
      }
    }
  }

  let rgb_interpolation = resize_convert_image(2UL, 2UL, 3UL, None, [
    b'\x10', b'\x20', b'\x30', b'\x40', b'\x50', b'\x60',
    b'\x70', b'\x80', b'\x90', b'\xa0', b'\xb0', b'\xc0',
  ])
  let rgba_interpolation = resize_convert_image(
    2UL,
    2UL,
    4UL,
    Some(@color.AlphaMode::Straight),
    [
      b'\x10', b'\x20', b'\x30', b'\xff', b'\x40', b'\x50', b'\x60', b'\xff',
      b'\x70', b'\x80', b'\x90', b'\xff', b'\xa0', b'\xb0', b'\xc0', b'\xff',
    ],
  )
  let rgb_output = @ops.resize_bilinear(
    rgb_interpolation.view(), 3UL, 4UL, resize_convert_limits(36UL, 48UL),
  ).unwrap().image().view()
  let rgba_output = @ops.resize_bilinear(
    rgba_interpolation.view(), 3UL, 4UL, resize_convert_limits(48UL, 48UL),
  ).unwrap().image().view()
  for y = 0UL; y < 4UL; y = y + 1UL {
    for x = 0UL; x < 3UL; x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        inspect(
          rgb_output.get_byte(x, y, channel).unwrap() ==
          rgba_output.get_byte(x, y, channel).unwrap(),
          content="true",
        )
      }
      inspect(rgba_output.get_byte(x, y, 3UL).unwrap(), content="b'\\xFF'")
    }
  }
}

///|
test "bilinear resize filters straight RGBA without transparent colour fringes" {
  let source = resize_convert_image(
    2UL, 1UL, 4UL, Some(@color.AlphaMode::Straight), [
      b'\xff', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\xff',
    ],
  )
  let output = @ops.resize_bilinear(
    source.view(), 3UL, 1UL, resize_convert_limits(12UL, 12UL),
  ).unwrap().image()
  inspect(
    output.view().format().channels() == @model.ChannelOrder::Rgba,
    content="true",
  )
  inspect(
    output.metadata().alpha() == Some(@color.AlphaMode::Straight),
    content="true",
  )
  for channel = 0UL; channel < 3UL; channel = channel + 1UL {
    inspect(output.view().get_byte(1UL, 0UL, channel).unwrap(), content="b'\\x00'")
  }
  inspect(output.view().get_byte(1UL, 0UL, 3UL).unwrap(), content="b'\\xAA'")

  let subquantum = resize_convert_image(
    2UL, 1UL, 4UL, Some(@color.AlphaMode::Straight), [
      b'\xff', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x00',
    ],
  )
  let subquantum_output = @ops.resize_bilinear(
    subquantum.view(), 3UL, 1UL, resize_convert_limits(12UL, 12UL),
  ).unwrap().image().view()
  for channel = 0UL; channel < 4UL; channel = channel + 1UL {
    inspect(subquantum_output.get_byte(1UL, 0UL, channel).unwrap(), content="b'\\x00'")
  }

  let transparent = resize_convert_image(
    1UL, 1UL, 4UL, Some(@color.AlphaMode::Straight),
    [b'\xff', b'\x00', b'\x00', b'\x00'],
  )
  let expanded = @ops.resize_bilinear(
    transparent.view(), 2UL, 3UL, resize_convert_limits(24UL, 24UL),
  ).unwrap().image().view()
  for y = 0UL; y < 3UL; y = y + 1UL {
    for x = 0UL; x < 2UL; x = x + 1UL {
      for channel = 0UL; channel < 4UL; channel = channel + 1UL {
        inspect(expanded.get_byte(x, y, channel).unwrap(), content="b'\\x00'")
      }
    }
  }
}
