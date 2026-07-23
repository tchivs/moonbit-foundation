///|
fn png_encode_budget(
  bytes? : UInt64 = 512UL,
  work? : UInt64 = 1024UL,
) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations=8UL, allocation_size=bytes, width=64UL,
    height=64UL, pixels=4096UL, depth=0UL, work~,
  ))
}

///|
fn png_encode_limits(
  output? : UInt64 = 512UL,
  work? : UInt64 = 1024UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=512UL, max_output_bytes=output,
    max_width=64UL, max_height=64UL, max_pixels=4096UL, max_work=work,
  )
}

///|
fn png_encode_image(
  channels : UInt64,
  pixels : Bytes,
  include_opaque? : Bool = false,
  width? : UInt64 = 1UL,
  height? : UInt64 = 1UL,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, height,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels * width * height, channels * width, channels * width, 1UL, 1UL, width, height).unwrap()],
    channels * width * height,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        if include_opaque { [("test", "marker", "raw", b"x")] } else { [] },
        @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ),
        png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=channels * width * height, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for index = 0UL; index < channels; index = index + 1UL {
          view.set_byte(x, y, index, pixels[((y * width + x) * channels + index).to_int()]).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| A packed one-channel U8 image using the same canonical metadata contract
/// as the public PNG profile, for the explicit Gray8 encoder route.
fn png_encode_gray8_image(
  pixels : Bytes,
  width? : UInt64 = 1UL,
  height? : UInt64 = 1UL,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, height,
    @model.ImageFormat::new(
      @model.ComponentType::U8, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(
      0UL, width * height, width, width, 1UL, 1UL, width, height,
    ).unwrap()],
    width * height,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_encode_budget(bytes=width * height, work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        view.set_byte(x, y, 0UL, pixels[(y * width + x).to_int()]).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| A compact, mixed multi-row source for public Gray8 round-trip evidence.
fn png_encode_gray8_fidelity_image() -> @storage.OwnedImage {
  png_encode_gray8_image(
    b"\x00\x7f\xff\x12\xa5\x34\xc8\x56\xe1\x09\xab\xcd\x23\x89\xfe",
    width=5UL, height=3UL,
  )
}

///|
/// Two little-endian U16 Gray samples. The encoder must emit their opposite
/// wire order because PNG stores every 16-bit sample big-endian.
fn png_encode_gray16_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
    4UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_encode_budget(bytes=4UL, work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\xcd').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xab').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| Two deliberately non-symmetric Gray+Alpha samples make the packed source
/// component order observable at the PNG raster boundary.
fn png_encode_graya8_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL, 1UL, @model.ImageFormat::graya8(),
    [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
    4UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=4UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 0UL, b'\x13').unwrap()
    view.set_byte(0UL, 0UL, 1UL, b'\xa7').unwrap()
    view.set_byte(1UL, 0UL, 0UL, b'\xd2').unwrap()
    view.set_byte(1UL, 0UL, 1UL, b'\x4c').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| A five-by-five legal GrayAlpha8 source keeps all seven Adam7 passes
/// nonempty. Gray and alpha are independently asymmetric at every coordinate
/// so either a pass traversal or component-order error is visible on the wire.
fn png_encode_graya8_adam7_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    5UL, 5UL, @model.ImageFormat::graya8(),
    [@model.PlaneDescriptor::new(0UL, 50UL, 10UL, 10UL, 1UL, 1UL, 5UL, 5UL).unwrap()],
    50UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=50UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        let sample = y * 5UL + x
        view.set_byte(x, y, 0UL, (b'\x20'.to_uint64() + sample).to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (b'\xa0'.to_uint64() + sample).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Two packed little-endian U16 Gray+Alpha samples whose four distinct wire
/// lanes make component and byte-order mistakes observable at the PNG boundary.
fn png_encode_graya16_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL, 1UL, @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(0UL, 8UL, 8UL, 8UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
    8UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=8UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xc5').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 1UL, b'\xa7').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\x0f').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xbe').unwrap()
    view.set_component_byte(1UL, 0UL, 1UL, 0UL, b'\x76').unwrap()
    view.set_component_byte(1UL, 0UL, 1UL, 1UL, b'\x5a').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| Two packed little-endian U16 RGBA samples whose eight distinct wire lanes
/// make channel order and component byte order observable at the PNG boundary.
fn png_encode_rgba16_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL, 1UL, @model.ImageFormat::rgba16(),
    [@model.PlaneDescriptor::new(0UL, 16UL, 16UL, 16UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
    16UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=16UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xc5').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 1UL, b'\xa7').unwrap()
    view.set_component_byte(0UL, 0UL, 2UL, 0UL, b'\x0f').unwrap()
    view.set_component_byte(0UL, 0UL, 2UL, 1UL, b'\xbe').unwrap()
    view.set_component_byte(0UL, 0UL, 3UL, 0UL, b'\x76').unwrap()
    view.set_component_byte(0UL, 0UL, 3UL, 1UL, b'\x5a').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\x89').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xde').unwrap()
    view.set_component_byte(1UL, 0UL, 1UL, 0UL, b'\x21').unwrap()
    view.set_component_byte(1UL, 0UL, 1UL, 1UL, b'\x43').unwrap()
    view.set_component_byte(1UL, 0UL, 2UL, 0UL, b'\x65').unwrap()
    view.set_component_byte(1UL, 0UL, 2UL, 1UL, b'\x87').unwrap()
    view.set_component_byte(1UL, 0UL, 3UL, 0UL, b'\xab').unwrap()
    view.set_component_byte(1UL, 0UL, 3UL, 1UL, b'\xcd').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| A 5x5 little-endian U16 Gray+Alpha source that gives every Adam7 pass a
/// nonempty row. Each component has distinct high and low bytes so pass order,
/// component order, and storage-to-wire byte order are independently visible.
fn png_encode_graya16_adam7_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    5UL, 5UL, @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(0UL, 100UL, 20UL, 20UL, 1UL, 1UL, 5UL, 5UL).unwrap()],
    100UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=100UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        let sample = y * 5UL + x
        view.set_component_byte(x, y, 0UL, 0UL, sample.to_byte()).unwrap()
        view.set_component_byte(x, y, 0UL, 1UL, (b'\x80'.to_uint64() + sample).to_byte()).unwrap()
        view.set_component_byte(x, y, 1UL, 0UL, (b'\x40'.to_uint64() + sample).to_byte()).unwrap()
        view.set_component_byte(x, y, 1UL, 1UL, (b'\xc0'.to_uint64() + sample).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| The Stored Adam7 payload for `png_encode_graya16_adam7_image`, written as
/// independent pass geometry so a cursor ordering regression cannot hide behind
/// the encoder implementation.
fn png_encode_graya16_adam7_expected_passes() -> Array[Byte] {
  let expected : Array[Byte] = []
  for pass in [
    (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
    (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
    (0UL, 1UL, 1UL, 2UL),
  ] {
    let (start_x, start_y, stride_x, stride_y) = pass
    for y = start_y; y < 5UL; y = y + stride_y {
      expected.push(b'\x00')
      for x = start_x; x < 5UL; x = x + stride_x {
        let sample = y * 5UL + x
        expected.push((b'\x80'.to_uint64() + sample).to_byte())
        expected.push(sample.to_byte())
        expected.push((b'\xc0'.to_uint64() + sample).to_byte())
        expected.push((b'\x40'.to_uint64() + sample).to_byte())
      }
    }
  }
  expected
}

///| The Stored Adam7 payload for `png_encode_graya8_adam7_image`, enumerated
/// independently from the encoder cursor to prove Type-4/8 G,A pass order.
fn png_encode_graya8_adam7_expected_passes() -> Array[Byte] {
  let expected : Array[Byte] = []
  for pass in [
    (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
    (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
    (0UL, 1UL, 1UL, 2UL),
  ] {
    let (start_x, start_y, stride_x, stride_y) = pass
    for y = start_y; y < 5UL; y = y + stride_y {
      expected.push(b'\x00')
      for x = start_x; x < 5UL; x = x + stride_x {
        let sample = y * 5UL + x
        expected.push((b'\x20'.to_uint64() + sample).to_byte())
        expected.push((b'\xa0'.to_uint64() + sample).to_byte())
      }
    }
  }
  expected
}

///| Repeated four-byte pixels make an incorrect two-byte Adaptive Sub stride
/// observable: only the first pixel may have nonzero residuals.
fn png_encode_graya16_repeated_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    3UL, 1UL, @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(0UL, 12UL, 12UL, 12UL, 1UL, 1UL, 3UL, 1UL).unwrap()],
    12UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=12UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < 3UL; x = x + 1UL {
      view.set_component_byte(x, 0UL, 0UL, 0UL, b'\x34').unwrap()
      view.set_component_byte(x, 0UL, 0UL, 1UL, b'\x12').unwrap()
      view.set_component_byte(x, 0UL, 1UL, 0UL, b'\xc5').unwrap()
      view.set_component_byte(x, 0UL, 1UL, 1UL, b'\xa7').unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///| The same non-symmetric samples stored big-endian. PNG wire bytes must not
/// depend on the source storage order.
fn png_encode_gray16_big_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Big,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
    4UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_encode_budget(bytes=4UL, work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x12').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x34').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\xab').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xcd').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| Three identical U16 samples make the Adaptive Sub predictor's two-byte
/// pixel stride observable in the emitted PNG scanline.
fn png_encode_gray16_repeated_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    3UL, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, 6UL, 6UL, 6UL, 1UL, 1UL, 3UL, 1UL).unwrap()],
    6UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_encode_budget(bytes=6UL, work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < 3UL; x = x + 1UL {
      view.set_component_byte(x, 0UL, 0UL, 0UL, b'\x34').unwrap()
      view.set_component_byte(x, 0UL, 0UL, 1UL, b'\x12').unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///| A compact non-symmetric Gray16 corpus whose PNG wire bytes must be stable
/// across either source-storage byte order.
fn png_encode_gray16_public_fidelity_image(
  endianness : @model.Endianness,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    3UL, 2UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, endianness,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, 12UL, 6UL, 6UL, 1UL, 1UL, 3UL, 2UL).unwrap()],
    12UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_encode_budget(bytes=12UL, work=0UL),
  ).unwrap()
  let wire = [
    [b'\x12', b'\x34'], [b'\xab', b'\xcd'], [b'\x00', b'\xff'],
    [b'\x7f', b'\x01'], [b'\x80', b'\x02'], [b'\xfe', b'\x10'],
  ]
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 2UL; y = y + 1UL {
      for x = 0UL; x < 3UL; x = x + 1UL {
        let sample = wire[(y * 3UL + x).to_int()]
        if endianness == @model.Endianness::Little {
          view.set_component_byte(x, y, 0UL, 0UL, sample[1]).unwrap()
          view.set_component_byte(x, y, 0UL, 1UL, sample[0]).unwrap()
        } else {
          view.set_component_byte(x, y, 0UL, 0UL, sample[0]).unwrap()
          view.set_component_byte(x, y, 0UL, 1UL, sample[1]).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Extract one known Stored/None IDAT stream without using the private
/// inflater. This is intentionally only a bounded stored-block parser whose
/// caller fixes the expected filtered payload size.
fn png_encode_gray16_public_stored_scanlines(
  bytes : Bytes,
  expected_scanline_length : Int,
) -> Bytes {
  if bytes.length().to_uint64() < 20UL { abort("png gray16 public png too short") }
  let idat : Array[Byte] = []
  let mut cursor = 8UL
  let mut saw_iend = false
  while cursor + 12UL <= bytes.length().to_uint64() {
    let data_length =
      (bytes[cursor.to_int()].to_uint64() << 24) |
      (bytes[(cursor + 1UL).to_int()].to_uint64() << 16) |
      (bytes[(cursor + 2UL).to_int()].to_uint64() << 8) |
      bytes[(cursor + 3UL).to_int()].to_uint64()
    if cursor + 12UL + data_length > bytes.length().to_uint64() {
      abort("png gray16 public chunk bounds")
    }
    let idat_type = bytes[(cursor + 4UL).to_int()] == b'I' &&
      bytes[(cursor + 5UL).to_int()] == b'D' &&
      bytes[(cursor + 6UL).to_int()] == b'A' &&
      bytes[(cursor + 7UL).to_int()] == b'T'
    if idat_type {
      for index = 0UL; index < data_length; index = index + 1UL {
        idat.push(bytes[(cursor + 8UL + index).to_int()])
      }
    }
    let iend_type = bytes[(cursor + 4UL).to_int()] == b'I' &&
      bytes[(cursor + 5UL).to_int()] == b'E' &&
      bytes[(cursor + 6UL).to_int()] == b'N' &&
      bytes[(cursor + 7UL).to_int()] == b'D'
    if iend_type {
      if data_length != 0UL { abort("png gray16 public iend payload") }
      saw_iend = true
      break
    }
    cursor = cursor + 12UL + data_length
  }
  let scanline_length = expected_scanline_length.to_uint64()
  if !saw_iend || idat.length() != (scanline_length + 11UL).to_int() {
    abort("png gray16 public stored idat shape")
  }
  if idat[0] != b'\x78' || idat[1] != b'\x01' || idat[2] != b'\x01' ||
    idat[3] != scanline_length.to_byte() ||
    idat[4] != (scanline_length >> 8).to_byte() ||
    idat[5] != (65535UL - scanline_length).to_byte() ||
    idat[6] != ((65535UL - scanline_length) >> 8).to_byte() {
    abort("png gray16 public stored block")
  }
  let scanlines : Array[Byte] = []
  for index = 0; index < expected_scanline_length; index = index + 1 {
    scanlines.push(idat[7 + index])
  }
  Bytes::from_array(scanlines)
}

///| The public PNG decoder intentionally exposes Gray16 as RGB8 high bytes.
fn png_encode_gray16_public_decode_is_canonical(bytes : Bytes) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  if restored.width() != 3UL || restored.height() != 2UL ||
    restored.format().component() != @model.ComponentType::U8 ||
    restored.format().channels() != @model.ChannelOrder::Rgb ||
    restored.format().channel_count() != 3UL {
    abort("png gray16 public decoded descriptor")
  }
  let high = [b'\x12', b'\xab', b'\x00', b'\x7f', b'\x80', b'\xfe']
  for y = 0UL; y < 2UL; y = y + 1UL {
    for x = 0UL; x < 3UL; x = x + 1UL {
      let sample = high[(y * 3UL + x).to_int()]
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() != sample {
          abort("png gray16 public decoded high byte")
        }
      }
    }
  }
}

///| The existing decoder canonicalizes PNG type-4 samples to straight RGBA8
/// while retaining both the grayscale value and alpha byte exactly.
fn png_encode_graya8_decode_matches_source(bytes : Bytes) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let pairs = [(b'\x13', b'\xa7'), (b'\xd2', b'\x4c')]
  if restored.width() != 2UL || restored.height() != 1UL ||
    restored.format().channels() != @model.ChannelOrder::Rgba {
    abort("png graya8 decoded descriptor")
  }
  for x = 0UL; x < 2UL; x = x + 1UL {
    let (gray, alpha) = pairs[x.to_int()]
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      if restored.get_byte(x, 0UL, channel).unwrap() != gray {
        abort("png graya8 decoded grayscale")
      }
    }
    if restored.get_byte(x, 0UL, 3UL).unwrap() != alpha {
      abort("png graya8 decoded alpha")
    }
  }
}

///| The public PNG decoder intentionally exposes legal GrayAlpha16 samples as
/// straight RGBA8 high bytes; their low bytes remain a wire-level guarantee.
fn png_encode_graya16_public_decode_is_canonical(bytes : Bytes) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let pairs = [(b'\x12', b'\xa7'), (b'\xbe', b'\x5a')]
  if restored.width() != 2UL || restored.height() != 1UL ||
    restored.format().component() != @model.ComponentType::U8 ||
    restored.format().channels() != @model.ChannelOrder::Rgba ||
    restored.format().channel_count() != 4UL {
    abort("png graya16 public decoded descriptor")
  }
  for x = 0UL; x < 2UL; x = x + 1UL {
    let (gray, alpha) = pairs[x.to_int()]
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      if restored.get_byte(x, 0UL, channel).unwrap() != gray {
        abort("png graya16 public decoded grayscale")
      }
    }
    if restored.get_byte(x, 0UL, 3UL).unwrap() != alpha {
      abort("png graya16 public decoded alpha")
    }
  }
}

///| The public PNG decoder maps the legal 5x5 Adam7 GrayAlpha16 fixture to
/// straight RGBA8 high bytes. The source formula stays independent of PNG
/// traversal so every decoded pixel remains a consumer-visible contract check.
fn png_encode_graya16_adam7_public_decode_is_canonical(bytes : Bytes) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  if restored.width() != 5UL || restored.height() != 5UL ||
    restored.format().component() != @model.ComponentType::U8 ||
    restored.format().channels() != @model.ChannelOrder::Rgba ||
    restored.format().channel_count() != 4UL {
    abort("png graya16 Adam7 public decoded descriptor")
  }
  for y = 0UL; y < 5UL; y = y + 1UL {
    for x = 0UL; x < 5UL; x = x + 1UL {
      let sample = y * 5UL + x
      let gray = (b'\x80'.to_uint64() + sample).to_byte()
      let alpha = (b'\xc0'.to_uint64() + sample).to_byte()
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() != gray {
          abort("png graya16 Adam7 public decoded grayscale")
        }
      }
      if restored.get_byte(x, y, 3UL).unwrap() != alpha {
        abort("png graya16 Adam7 public decoded alpha")
      }
    }
  }
}

///| The public PNG decoder exposes the independent 5x5 GrayAlpha8 Adam7
/// fixture as straight RGBA8. Expected samples come from source coordinates,
/// never from encoder traversal state.
fn png_encode_graya8_adam7_public_decode_is_canonical(bytes : Bytes) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  if restored.width() != 5UL || restored.height() != 5UL ||
    restored.format().component() != @model.ComponentType::U8 ||
    restored.format().channels() != @model.ChannelOrder::Rgba ||
    restored.format().channel_count() != 4UL {
    abort("png graya8 Adam7 public decoded descriptor")
  }
  for y = 0UL; y < 5UL; y = y + 1UL {
    for x = 0UL; x < 5UL; x = x + 1UL {
      let sample = y * 5UL + x
      let gray = (b'\x20'.to_uint64() + sample).to_byte()
      let alpha = (b'\xa0'.to_uint64() + sample).to_byte()
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() != gray {
          abort("png graya8 Adam7 public decoded grayscale")
        }
      }
      if restored.get_byte(x, y, 3UL).unwrap() != alpha {
        abort("png graya8 Adam7 public decoded alpha")
      }
    }
  }
}

///|
fn png_encode_prefix(writer : @io.MemoryWriter) -> Bytes {
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_encode_with(
  encoder : PngEncoder,
  image : @storage.OwnedImage,
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let result = @codec.ImageEncoder::encode(
    encoder, image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
fn png_adam7_encode_with(
  encoder : PngEncoder,
  image : @storage.OwnedImage,
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_encode_budget(bytes=1048576UL, work=0UL),
  ).unwrap()
  let result = @codec.ImageEncoder::encode(
    encoder, image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_adam7_admission_limits(), png_encode_budget(bytes=1048576UL, work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
fn png_encode(image : @storage.OwnedImage) -> (@codec.EncodeResult, @io.MemoryWriter) {
  png_encode_with(PngEncoder::new(), image)
}

///|
fn png_adam7_same_remaining(
  left : @budget.ResourceLimits,
  right : @budget.ResourceLimits,
) -> Bool {
  left.bytes() == right.bytes() &&
    left.allocations() == right.allocations() &&
    left.allocation_size() == right.allocation_size() &&
    left.width() == right.width() &&
    left.height() == right.height() &&
    left.pixels() == right.pixels() &&
    left.depth() == right.depth() &&
    left.work() == right.work()
}

///| A compact multi-pass source whose component at `(x, y, channel)` is its
/// row-major byte offset.  The same source shape is used by the chunk tests.
fn png_adam7_admission_image(
  channels : UInt64,
  include_opaque? : Bool = false,
) -> @storage.OwnedImage {
  let image = png_encode_image(
    channels, Bytes::from_array(Array::make((channels * 25UL).to_int(), b'\x00')),
    include_opaque=include_opaque, width=5UL, height=5UL,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          view.set_byte(x, y, channel, (y * channels * 5UL + x * channels + channel).to_byte()).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adam7_admission_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
  width? : UInt64 = 64UL,
  height? : UInt64 = 64UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=width, max_height=height, max_pixels=4096UL, max_work=work,
  )
}

///| Eager all-strategy Adam7 construction must leave both Writer and every
/// caller-owned budget ledger field untouched when preflight rejects it.
fn png_adam7_eager_admission_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let budget = png_encode_budget(bytes=1048576UL, work=work)
    let before = budget.remaining()
    let writer = @io.MemoryWriter::new(
      1048576UL, png_encode_budget(bytes=1048576UL, work=0UL),
    ).unwrap()
    ignore(@codec.ImageEncoder::encode(
      PngEncoder::new_with_all_strategies(
        strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      ), image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      limits, budget, @error.Diagnostics::new(),
    ).unwrap_err())
    if writer.position() != 0UL || !png_adam7_same_remaining(before, budget.remaining()) {
      abort("png adam7 eager admission atomic")
    }
  }
}

///|
fn png_filter_strategy_decode_matches_source(
  bytes : Bytes,
  source : @storage.OwnedImage,
) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=1048576UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ), png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let expected = source.view()
  if restored.width() != expected.width() || restored.height() != expected.height() ||
    restored.format().channel_count() != expected.format().channel_count() {
    abort("png filter strategy decoded descriptor")
  }
  for y = 0UL; y < expected.height(); y = y + 1UL {
    for x = 0UL; x < expected.width(); x = x + 1UL {
      for channel = 0UL; channel < expected.format().channel_count(); channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() !=
          expected.get_byte(x, y, channel).unwrap() {
          abort("png filter strategy decoded component")
        }
      }
    }
  }
}

///|
fn png_adaptive_evidence_rgb8_horizontal_candidate_image(width : UInt64) -> @storage.OwnedImage {
  let image = png_encode_image(
    3UL, Bytes::from_array(Array::make((width * 3UL).to_int(), b'\x00')),
    width=width,
  )
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      view.set_byte(x, 0UL, 0UL, x.to_byte()).unwrap()
      view.set_byte(x, 0UL, 1UL, (x + 64UL).to_byte()).unwrap()
      view.set_byte(x, 0UL, 2UL, (x + 128UL).to_byte()).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_rgb8_diagonal_image() -> @storage.OwnedImage {
  let image = png_encode_image(
    3UL, Bytes::from_array(Array::make(32 * 4 * 3, b'\x00')),
    width=32UL, height=4UL,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 4UL; y = y + 1UL {
      for x = 0UL; x < 32UL; x = x + 1UL {
        let value = x + y
        view.set_byte(x, y, 0UL, value.to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (value + 64UL).to_byte()).unwrap()
        view.set_byte(x, y, 2UL, (value + 128UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_straight_rgba8_candidate_image(
  width : UInt64,
  height : UInt64,
) -> @storage.OwnedImage {
  let image = png_encode_image(
    4UL, Bytes::from_array(Array::make((width * height * 4UL).to_int(), b'\x00')),
    width=width, height=height,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        let value = 3UL * x + y
        view.set_byte(x, y, 0UL, value.to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (value + 64UL).to_byte()).unwrap()
        view.set_byte(x, y, 2UL, (value + 128UL).to_byte()).unwrap()
        view.set_byte(x, y, 3UL, 200UL.to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_straight_rgba8_diagonal_image() -> @storage.OwnedImage {
  let image = png_encode_image(
    4UL, Bytes::from_array(Array::make(16 * 16 * 4, b'\x00')),
    width=16UL, height=16UL,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 16UL; y = y + 1UL {
      for x = 0UL; x < 16UL; x = x + 1UL {
        let value = x + y
        view.set_byte(x, y, 0UL, value.to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (value + 64UL).to_byte()).unwrap()
        view.set_byte(x, y, 2UL, (value + 128UL).to_byte()).unwrap()
        view.set_byte(x, y, 3UL, 200UL.to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_adaptive_beats_none(image : @storage.OwnedImage) -> Bytes {
  let none = png_adaptive_evidence_encode(image, PngFilterStrategy::None)
  let adaptive = png_adaptive_evidence_encode(image, PngFilterStrategy::Adaptive)
  if adaptive.length() >= none.length() {
    abort("png adaptive evidence strict win")
  }
  adaptive
}

///|
fn png_adaptive_evidence_encode(
  image : @storage.OwnedImage,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(
    4096UL, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(
      PngCompressionStrategy::FixedOrStored, filter_strategy,
    ), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap())
  png_encode_prefix(writer)
}

///|
test "PNG adaptive filter evidence candidate RGB8 R1 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_rgb8_horizontal_candidate_image(32UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate RGB8 R2 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_rgb8_horizontal_candidate_image(64UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate RGB8 R3 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(png_adaptive_evidence_rgb8_diagonal_image()))
}

///|
test "PNG adaptive filter evidence candidate straight-RGBA8 A1 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_straight_rgba8_candidate_image(16UL, 8UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate straight-RGBA8 A2 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_straight_rgba8_candidate_image(32UL, 4UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate straight-RGBA8 A3 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_straight_rgba8_diagonal_image(),
  ))
}

///| Selected CandidateSelection winner R1: 32x1 `(x, x+64, x+128)` RGB8.
fn png_adaptive_evidence_rgb8_horizontal_image() -> @storage.OwnedImage {
  png_adaptive_evidence_rgb8_horizontal_candidate_image(32UL)
}

///| Selected CandidateSelection winner A1: 16x8 `(3x+y, 3x+y+64,
///| 3x+y+128, 200)` straight-RGBA8.
fn png_adaptive_evidence_straight_rgba8_vertical_image() -> @storage.OwnedImage {
  png_adaptive_evidence_straight_rgba8_candidate_image(16UL, 8UL)
}

///|
test "PNG adaptive filter evidence RGB8 horizontal eager strictly beats None and decodes completely" {
  let source = png_adaptive_evidence_rgb8_horizontal_image()
  png_filter_strategy_decode_matches_source(
    png_adaptive_evidence_adaptive_beats_none(source), source,
  )
}

///|
test "PNG adaptive filter evidence straight-RGBA8 vertical eager strictly beats None and decodes completely" {
  let source = png_adaptive_evidence_straight_rgba8_vertical_image()
  png_filter_strategy_decode_matches_source(
    png_adaptive_evidence_adaptive_beats_none(source), source,
  )
}

///| Every public compression strategy may opt into bounded Adaptive filtering
/// while preserving complete-input RGB8 and straight-RGBA8 fidelity.
test "PNG adaptive combined eager routes" {
  let rgb = png_encode_image(
    3UL, b"\x0a\x0c\x0c\x0a\x0a\x0c\x0b\x0c\x0a\x0c\x0a\x0b",
    width=2UL, height=2UL,
  )
  let rgba = png_encode_image(
    4UL, b"\x03\x05\x07\xff\x04\x06\x08\xfe\x05\x07\x09\xfd\x06\x08\x0a\xfc",
    width=2UL, height=2UL,
  )
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for image in [rgb, rgba] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_with_strategies(strategy, PngFilterStrategy::Adaptive), image,
      )
      png_filter_strategy_decode_matches_source(png_encode_prefix(writer), image)
    }
  }
}

///|
test "PNG filter strategy eager frozen compatibility vectors" {
  let gray = png_encode_gray8_image(b"\x7f")
  let gray_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x00\x00\x00\x00\x3a\x7e\x9b\x55\x00\x00\x00\x0dIDAT\x78\x01\x01\x02\x00\xfd\xff\x00\x7f\x00\x81\x00\x80\x7c\x4b\x6c\xa3\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, gray_default_writer) = png_encode_with(PngEncoder::new_gray8(), gray)
  let (_, gray_configured_writer) = png_encode_with(
    PngEncoder::new_gray8_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    gray,
  )
  let (_, gray_adaptive_writer) = png_encode_with(
    PngEncoder::new_gray8_with_filter_strategy(PngFilterStrategy::Adaptive), gray,
  )
  for bytes in [
    png_encode_prefix(gray_default_writer), png_encode_prefix(gray_configured_writer),
    png_encode_prefix(gray_adaptive_writer),
  ] {
    inspect(bytes == gray_stored && bytes[28] == b'\x00', content="true")
  }

  let gray16 = png_encode_gray16_image()
  let gray16_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x10\x00\x00\x00\x00\x81\xd9\xfc\x15\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x12\x34\xab\xcd\x03\x0c\x01\xbf\x4c\x32\xd4\xc3\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let graya16_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x10\x04\x00\x00\x00\x0e\xbb\x6b\x42\x00\x00\x00\x14IDAT\x78\x01\x01\x09\x00\xf6\xff\x00\x12\x34\xa7\xc5\xbe\x0f\x5a\x76\x0e\x17\x03\x50\x6b\x88\xb2\x75\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, gray16_default_writer) = png_encode_with(PngEncoder::new_gray16(), gray16)
  let (_, gray16_configured_writer) = png_encode_with(
    PngEncoder::new_gray16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    gray16,
  )
  for bytes in [png_encode_prefix(gray16_default_writer), png_encode_prefix(gray16_configured_writer)] {
    inspect(bytes == gray16_stored && bytes[28] == b'\x00', content="true")
  }

  let graya16 = png_encode_graya16_image()
  let (_, graya16_default_writer) = png_encode_with(PngEncoder::new_graya16(), graya16)
  let (_, graya16_configured_writer) = png_encode_with(
    PngEncoder::new_graya16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    graya16,
  )
  for bytes in [
    png_encode_prefix(graya16_default_writer), png_encode_prefix(graya16_configured_writer),
  ] {
    inspect(bytes == graya16_stored && bytes[28] == b'\x00', content="true")
  }

  let gray_alpha = png_encode_graya8_image()
  let gray_alpha_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x08\x04\x00\x00\x00\x5e\x2b\xb7\x01\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x13\xa7\xd2\x4c\x04\x36\x01\xd9\xee\xe9\xe1\x45\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, gray_alpha_default_writer) = png_encode_with(PngEncoder::new_graya8(), gray_alpha)
  let (_, gray_alpha_configured_writer) = png_encode_with(
    PngEncoder::new_graya8_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    gray_alpha,
  )
  for bytes in [
    png_encode_prefix(gray_alpha_default_writer), png_encode_prefix(gray_alpha_configured_writer),
  ] {
    inspect(bytes == gray_alpha_stored && bytes[28] == b'\x00', content="true")
  }

  let rgb = png_encode_image(3UL, b"\x00\x01\x02")
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, rgb_default_writer) = png_encode_with(PngEncoder::new(), rgb)
  let (_, rgb_configured_writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::Stored), rgb,
  )
  let (_, rgb_adaptive_writer) = png_encode_with(
    PngEncoder::new_with_filter_strategy(PngFilterStrategy::Adaptive), rgb,
  )
  for bytes in [png_encode_prefix(rgb_default_writer), png_encode_prefix(rgb_configured_writer), png_encode_prefix(rgb_adaptive_writer)] {
    inspect(bytes == rgb_stored && bytes[28] == b'\x00', content="true")
    png_filter_strategy_decode_matches_source(bytes, rgb)
  }

  let rgba = png_encode_image(4UL, b"\x00\x01\x02\x03")
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, rgba_default_writer) = png_encode_with(PngEncoder::new(), rgba)
  let (_, rgba_configured_writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::Stored), rgba,
  )
  let (_, rgba_adaptive_writer) = png_encode_with(
    PngEncoder::new_with_filter_strategy(PngFilterStrategy::Adaptive), rgba,
  )
  for bytes in [png_encode_prefix(rgba_default_writer), png_encode_prefix(rgba_configured_writer), png_encode_prefix(rgba_adaptive_writer)] {
    inspect(bytes == rgba_stored && bytes[28] == b'\x00', content="true")
    png_filter_strategy_decode_matches_source(bytes, rgba)
  }

  for channels in [3UL, 4UL] {
    let image = png_encode_image(
      channels, Bytes::from_array(Array::make((channels * 32UL).to_int(), b'\xaa')),
      width=32UL,
    )
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let (_, fixed_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
    )
    let (_, dynamic_fallback_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored), image,
    )
    for bytes in [png_encode_prefix(fixed_writer), png_encode_prefix(dynamic_fallback_writer)] {
      inspect(bytes == fixed, content="true")
      png_filter_strategy_decode_matches_source(bytes, image)
    }
  }

}

///| Explicit Gray8 uses the real Stored byte route with PNG color type 0;
/// legacy RGB/RGBA byte fixtures above remain the compatibility baseline.
test "PNG Gray8 eager Stored output and profile admission are atomic" {
  let gray = png_encode_gray8_image(b"\x7f")
  let (_, writer) = png_encode_with(PngEncoder::new_gray8(), gray)
  let bytes = png_encode_prefix(writer)
  let expected =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x00\x00\x00\x00\x3a\x7e\x9b\x55\x00\x00\x00\x0dIDAT\x78\x01\x01\x02\x00\xfd\xff\x00\x7f\x00\x81\x00\x80\x7c\x4b\x6c\xa3\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  inspect(bytes == expected && bytes[24] == b'\x08' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")

  let rgb = png_encode_image(3UL, b"\x00\x01\x02")
  let budget = png_encode_budget()
  let before = budget.remaining()
  let rejected = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new_gray8(), rgb.view(), rejected as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(gray8-required)")
  inspect(rejected.position() == 0UL && png_adam7_same_remaining(before, budget.remaining()), content="true")
}

///|
test "PNG Gray16 eager Stored output uses type 0 big-endian samples atomically" {
  let gray = png_encode_gray16_image()
  let (_, writer) = png_encode_with(PngEncoder::new_gray16(), gray)
  let bytes = png_encode_prefix(writer)
  inspect(
    bytes[24] == b'\x10' && bytes[25] == b'\x00' && bytes[28] == b'\x00' &&
      bytes[48] == b'\x00' && bytes[49] == b'\x12' && bytes[50] == b'\x34' &&
      bytes[51] == b'\xab' && bytes[52] == b'\xcd',
    content="true",
  )
  let bad = png_encode_image(3UL, b"\x00\x01\x02")
  let budget = png_encode_budget()
  let before = budget.remaining()
  let rejected = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new_gray16(), bad.view(), rejected as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(gray16-required)")
  inspect(rejected.position(), content="0")
  inspect(
    budget.remaining().bytes() == before.bytes() &&
      budget.remaining().allocations() == before.allocations() &&
      budget.remaining().work() == before.work(),
    content="true",
  )
}

///| The default explicit Gray+Alpha8 route retains component order through
/// Stored/None output and the existing decoder path.
test "PNG GrayAlpha8 public eager evidence" {
  let gray_alpha = png_encode_graya8_image()
  let (_, writer) = png_encode_with(
    PngEncoder::new_graya8_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    gray_alpha,
  )
  let bytes = png_encode_prefix(writer)
  inspect(
    bytes[0] == b'\x89' && bytes[1] == b'P' && bytes[24] == b'\x08' &&
      bytes[25] == b'\x04' && bytes[28] == b'\x00' && bytes[48] == b'\x00' &&
      bytes[49] == b'\x13' && bytes[50] == b'\xa7' && bytes[51] == b'\xd2' &&
      bytes[52] == b'\x4c',
    content="true",
  )
  png_encode_graya8_decode_matches_source(bytes)

  let rgb = png_encode_image(3UL, b"\x00\x01\x02")
  let budget = png_encode_budget()
  let before = budget.remaining()
  let rejected = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new_graya8(), rgb.view(), rejected as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(graya8-required)")
  inspect(rejected.position() == 0UL && png_adam7_same_remaining(before, budget.remaining()), content="true")
}

///| A legal public GrayAlpha16 source proves literal Type-4/16 lane order and
/// the separate straight-RGBA8 high-byte canonicalization boundary.
test "PNG GrayAlpha16 public eager wire and decode fidelity" {
  let gray_alpha = png_encode_graya16_image()
  let (_, writer) = png_encode_with(
    PngEncoder::new_graya16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    gray_alpha,
  )
  let bytes = png_encode_prefix(writer)
  inspect(
    bytes[0] == b'\x89' && bytes[1] == b'P' && bytes[24] == b'\x10' &&
      bytes[25] == b'\x04' && bytes[28] == b'\x00' && bytes[48] == b'\x00' &&
      bytes[49] == b'\x12' && bytes[50] == b'\x34' && bytes[51] == b'\xa7' &&
      bytes[52] == b'\xc5' && bytes[53] == b'\xbe' && bytes[54] == b'\x0f' &&
      bytes[55] == b'\x5a' && bytes[56] == b'\x76',
    content="true",
  )
  png_encode_graya16_public_decode_is_canonical(bytes)
}

///| The explicit eager RGBA16 route emits Type-6/16 wire lanes in PNG byte
/// order, then the independently existing preservation decoder restores the
/// original packed little-endian component bytes.
test "PNG RGBA16 public eager wire and explicit decode fidelity" {
  let rgba = png_encode_rgba16_image()
  let (_, writer) = png_encode_with(
    PngEncoder::new_rgba16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    rgba,
  )
  let bytes = png_encode_prefix(writer)
  inspect(
    bytes[0] == b'\x89' && bytes[1] == b'P' && bytes[24] == b'\x10' &&
      bytes[25] == b'\x06' && bytes[28] == b'\x00' && bytes[48] == b'\x00' &&
      bytes[49] == b'\x12' && bytes[50] == b'\x34' && bytes[51] == b'\xa7' &&
      bytes[52] == b'\xc5' && bytes[53] == b'\xbe' && bytes[54] == b'\x0f' &&
      bytes[55] == b'\x5a' && bytes[56] == b'\x76' && bytes[57] == b'\xde' &&
      bytes[58] == b'\x89' && bytes[59] == b'\x43' && bytes[60] == b'\x21' &&
      bytes[61] == b'\x87' && bytes[62] == b'\x65' && bytes[63] == b'\xcd' &&
      bytes[64] == b'\xab',
    content="true",
  )
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  let restored = PngDecoder::decode_rgba16(
    @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  for expected in [
    (0UL, 0UL, b'\x34'), (0UL, 1UL, b'\x12'), (0UL, 2UL, b'\xc5'), (0UL, 3UL, b'\xa7'),
    (0UL, 4UL, b'\x0f'), (0UL, 5UL, b'\xbe'), (0UL, 6UL, b'\x76'), (0UL, 7UL, b'\x5a'),
    (1UL, 0UL, b'\x89'), (1UL, 1UL, b'\xde'), (1UL, 2UL, b'\x21'), (1UL, 3UL, b'\x43'),
    (1UL, 4UL, b'\x65'), (1UL, 5UL, b'\x87'), (1UL, 6UL, b'\xab'), (1UL, 7UL, b'\xcd'),
  ] {
    let (x, component_byte, value) = expected
    inspect(
      restored.get_component_byte(
        x, 0UL, component_byte / 2UL, component_byte % 2UL,
      ).unwrap() == value,
      content="true",
    )
  }
}

///| Every eager RGBA16 factory remains non-interlaced, while incompatible
/// profiles and one-byte-short output limits fail before the writer sees data.
test "PNG RGBA16 eager factories retain atomic profile and resource admission" {
  let rgba = png_encode_rgba16_image()
  for encoder in [
    PngEncoder::new_rgba16(),
    PngEncoder::new_rgba16_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    PngEncoder::new_rgba16_with_filter_strategy(PngFilterStrategy::Adaptive),
    PngEncoder::new_rgba16_with_strategies(
      PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    ),
  ] {
    let (_, writer) = png_encode_with(encoder, rgba)
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x10' && bytes[25] == b'\x06' && bytes[28] == b'\x00', content="true")
  }

  let (_, measuring_writer) = png_encode_with(PngEncoder::new_rgba16(), rgba)
  let exact_output = png_encode_prefix(measuring_writer).length().to_uint64()
  let exact_writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let exact = @codec.ImageEncoder::encode(
    PngEncoder::new_rgba16(), rgba.view(), exact_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(output=exact_output, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  inspect(exact.bytes_written() == exact_output && exact_writer.position() == exact_output, content="true")

  let one_less_writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  inspect(@codec.ImageEncoder::encode(
    PngEncoder::new_rgba16(), rgba.view(), one_less_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(output=exact_output - 1UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(one_less_writer.position(), content="0")

  let generic_writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let generic = @codec.ImageEncoder::encode(
    PngEncoder::new(), rgba.view(), generic_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(generic.context(), content="Some(component-u8-required)")
  inspect(generic_writer.position(), content="0")

  let rgb_writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let rgb = @codec.ImageEncoder::encode(
    PngEncoder::new_rgba16(), png_encode_image(3UL, b"\x00\x01\x02").view(), rgb_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(rgb.context(), content="Some(rgba16-required)")
  inspect(rgb_writer.position(), content="0")
}

///| Both explicit GrayAlpha16 Adam7 selectors emit the same Stored/None
/// seven-pass Type-4/16 stream, with each pass sample in PNG Ghi/Glo/Ahi/Alo
/// wire order rather than the little-endian storage layout.
test "PNG GrayAlpha16 Adam7 eager pass profile" {
  let expected = png_encode_graya16_adam7_expected_passes()
  let encoders = [
    PngEncoder::new_graya16_with_interlace_strategy(PngInterlaceStrategy::Adam7),
    PngEncoder::new_graya16_with_all_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    ),
  ]
  let outputs : Array[Bytes] = []
  for encoder in encoders {
    let (_, writer) = png_adam7_encode_with(encoder, png_encode_graya16_adam7_image())
    let bytes = png_encode_prefix(writer)
    outputs.push(bytes)
    inspect(
      bytes[0] == b'\x89' && bytes[1] == b'P' && bytes[24] == b'\x10' &&
        bytes[25] == b'\x04' && bytes[26] == b'\x00' && bytes[27] == b'\x00' &&
        bytes[28] == b'\x01' && bytes[41] == b'\x78' && bytes[42] == b'\x01' &&
        bytes[43] == b'\x01' && bytes[44] == b'o' && bytes[45] == b'\x00',
      content="true",
    )
    inspect(expected.length(), content="111")
    for index = 0; index < expected.length(); index = index + 1 {
      inspect(bytes[48 + index] == expected[index], content="true")
    }
  }
  inspect(outputs.length(), content="2")
  inspect(outputs[0] == outputs[1], content="true")
}

///| The narrow and independently selected GrayAlpha8 Adam7 factories must
/// agree on a Stored/None Type-4/8 raster with all seven G,A pass scanlines.
test "PNG GrayAlpha8 Adam7 eager pass profile" {
  let expected = Bytes::from_array(png_encode_graya8_adam7_expected_passes())
  let outputs : Array[Bytes] = []
  for encoder in [
    PngEncoder::new_graya8_with_interlace_strategy(PngInterlaceStrategy::Adam7),
    PngEncoder::new_graya8_with_all_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    ),
  ] {
    let (_, writer) = png_adam7_encode_with(encoder, png_encode_graya8_adam7_image())
    let bytes = png_encode_prefix(writer)
    outputs.push(bytes)
    if bytes[24] != b'\x08' || bytes[25] != b'\x04' || bytes[26] != b'\x00' ||
      bytes[27] != b'\x00' || bytes[28] != b'\x01' {
      abort("png graya8 Adam7 eager framing")
    }
    if png_encode_gray16_public_stored_scanlines(bytes, 61) != expected {
      abort("png graya8 Adam7 eager pass raster")
    }
  }
  if outputs.length() != 2 || outputs[0] != outputs[1] {
    abort("png graya8 Adam7 eager selector parity")
  }
  png_encode_graya8_adam7_public_decode_is_canonical(outputs[1])

  let (_, legacy_writer) = png_encode_with(PngEncoder::new_graya8(), png_encode_graya8_image())
  let (_, none_writer) = png_encode_with(
    PngEncoder::new_graya8_with_all_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::None,
    ),
    png_encode_graya8_image(),
  )
  let legacy = png_encode_prefix(legacy_writer)
  let explicit_none = png_encode_prefix(none_writer)
  if legacy[24] != b'\x08' || legacy[25] != b'\x04' || legacy[28] != b'\x00' ||
    legacy != explicit_none {
    abort("png graya8 legacy noninterlaced freeze")
  }
}

///| Each legal GrayAlpha8 Adam7 all-strategy selection must keep the public
/// Type-4/8 Adam7 identity supplied by the shared profile-aware encoder.
fn png_encode_graya8_adam7_eager_strategy(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Unit {
  let (_, writer) = png_adam7_encode_with(
    PngEncoder::new_graya8_with_all_strategies(
      strategy, filter_strategy, PngInterlaceStrategy::Adam7,
    ),
    png_encode_graya8_adam7_image(),
  )
  let bytes = png_encode_prefix(writer)
  if bytes[0] != b'\x89' || bytes[24] != b'\x08' || bytes[25] != b'\x04' ||
    bytes[26] != b'\x00' || bytes[27] != b'\x00' || bytes[28] != b'\x01' ||
    bytes[bytes.length() - 1] != b'\x82' {
    abort("png graya8 adam7 eager strategy framing")
  }
}

///| Every public compression/filter pair reaches the same GrayAlpha8 Adam7
/// profile, while Stored/None keeps its independent pass-raster proof above.
test "PNG GrayAlpha8 Adam7 eager all strategy framing" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      png_encode_graya8_adam7_eager_strategy(strategy, filter_strategy)
    }
  }
}

///| A public Stored/None Adam7 PNG exposes the complete Type-4/16 pass raster
/// and decodes only through the documented straight-RGBA8 high-byte boundary.
test "PNG GrayAlpha16 Adam7 public wire and decode" {
  let expected = Bytes::from_array(png_encode_graya16_adam7_expected_passes())
  let (_, writer) = png_adam7_encode_with(
    PngEncoder::new_graya16_with_all_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    ),
    png_encode_graya16_adam7_image(),
  )
  let bytes = png_encode_prefix(writer)
  if bytes[0] != b'\x89' || bytes[1] != b'P' || bytes[24] != b'\x10' ||
    bytes[25] != b'\x04' || bytes[28] != b'\x01' {
    abort("png graya16 Adam7 public framing")
  }
  if png_encode_gray16_public_stored_scanlines(bytes, 111) != expected {
    abort("png graya16 Adam7 public pass raster")
  }
  png_encode_graya16_adam7_public_decode_is_canonical(bytes)
}

///| The locked Phase-53 GrayAlpha16 identity rejects big-endian descriptors
/// before a PNG source can be admitted or traversed.
test "PNG GrayAlpha16 keeps big-endian descriptors outside the legal source contract" {
  let descriptor = @model.ImageDescriptor::new(
    1UL, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::GrayAlpha,
      @model.PlaneLayout::Packed, @model.Endianness::Big,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 1UL, 1UL).unwrap()],
    4UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  )
  inspect(descriptor is Err(_), content="true")
}

///| All explicit GrayAlpha16 factory shapes select the one non-interlaced
/// bounded profile; legal U16 GrayAlpha16 strategy and Adaptive stride stay visible.
test "PNG GrayAlpha16 eager factories preserve four-byte wire and strategy parity" {
  let gray_alpha = png_encode_graya16_image()
  for encoder in [
    PngEncoder::new_graya16(),
    PngEncoder::new_graya16_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    PngEncoder::new_graya16_with_filter_strategy(PngFilterStrategy::Adaptive),
  ] {
    let (_, writer) = png_encode_with(encoder, gray_alpha)
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x10' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
  }
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_graya16_with_strategies(strategy, filter_strategy), gray_alpha,
      )
      let bytes = png_encode_prefix(writer)
      inspect(bytes[24] == b'\x10' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
      png_encode_graya16_public_decode_is_canonical(bytes)
    }
  }
  let (_, adaptive_writer) = png_encode_with(
    PngEncoder::new_graya16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive,
    ),
    png_encode_graya16_repeated_image(),
  )
  let adaptive = png_encode_prefix(adaptive_writer)
  inspect(
    adaptive[48] == b'\x01' && adaptive[49] == b'\x12' && adaptive[50] == b'\x34' &&
      adaptive[51] == b'\xa7' && adaptive[52] == b'\xc5' && adaptive[53] == b'\x00' &&
      adaptive[54] == b'\x00' && adaptive[55] == b'\x00' && adaptive[56] == b'\x00' &&
      adaptive[57] == b'\x00' && adaptive[58] == b'\x00' && adaptive[59] == b'\x00' &&
      adaptive[60] == b'\x00',
    content="true",
  )
}

///| One legal all-strategy GrayAlpha16 Adam7 eager selection retains the
/// shared four-byte Type-4/16 profile and explicit Adam7 framing.
fn png_encode_graya16_adam7_eager_strategy(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Unit {
  let (_, writer) = png_adam7_encode_with(
    PngEncoder::new_graya16_with_all_strategies(
      strategy, filter_strategy, PngInterlaceStrategy::Adam7,
    ),
    png_encode_graya16_adam7_image(),
  )
  let bytes = png_encode_prefix(writer)
  if bytes[0] != b'\x89' || bytes[24] != b'\x10' || bytes[25] != b'\x04' ||
    bytes[26] != b'\x00' || bytes[27] != b'\x00' || bytes[28] != b'\x01' ||
    bytes[bytes.length() - 1] != b'\x82' {
    abort("png graya16 adam7 eager profile")
  }
  png_encode_graya16_adam7_public_decode_is_canonical(bytes)
}

///| Every legal all-strategy GrayAlpha16 Adam7 selection reaches the shared
/// eager profile-aware route.
test "PNG GrayAlpha16 Adam7 eager Stored None profile" {
  png_encode_graya16_adam7_eager_strategy(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

///|
test "PNG GrayAlpha16 Adam7 eager Stored Adaptive profile" {
  png_encode_graya16_adam7_eager_strategy(
    PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive,
  )
}

///|
test "PNG GrayAlpha16 Adam7 eager Fixed None profile" {
  png_encode_graya16_adam7_eager_strategy(
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None,
  )
}

///|
test "PNG GrayAlpha16 Adam7 eager Fixed Adaptive profile" {
  png_encode_graya16_adam7_eager_strategy(
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
  )
}

///|
test "PNG GrayAlpha16 Adam7 eager Dynamic None profile" {
  png_encode_graya16_adam7_eager_strategy(
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None,
  )
}

///|
test "PNG GrayAlpha16 Adam7 eager Dynamic Adaptive profile" {
  png_encode_graya16_adam7_eager_strategy(
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
  )
}

///| Every legal public GrayAlpha16 Adam7 selector retains Type-4/16 framing
/// and public straight-RGBA8 high-byte canonicalization.
test "PNG GrayAlpha16 Adam7 public eager evidence" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      png_encode_graya16_adam7_eager_strategy(strategy, filter_strategy)
    }
  }
}

///| All Gray+Alpha8 eager factory forms use the same non-interlaced bounded
/// route, including every compression/filter strategy pair.
test "PNG GrayAlpha8 eager factory strategies preserve framing" {
  let gray_alpha = png_encode_graya8_image()
  for encoder in [
    PngEncoder::new_graya8(),
    PngEncoder::new_graya8_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    PngEncoder::new_graya8_with_filter_strategy(PngFilterStrategy::Adaptive),
  ] {
    let (_, writer) = png_encode_with(encoder, gray_alpha)
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x08' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
  }
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_graya8_with_strategies(strategy, filter_strategy), gray_alpha,
      )
      let bytes = png_encode_prefix(writer)
      inspect(bytes[24] == b'\x08' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
      png_encode_graya8_decode_matches_source(bytes)
    }
  }
}

///| The Gray16 bounded strategy factories must share the public eager path;
/// repeated U16 samples expose the two-byte Adaptive Sub stride on wire bytes.
test "PNG Gray16 eager strategy factories preserve bounded wire bytes" {
  let gray = png_encode_gray16_image()
  for encoder in [
    PngEncoder::new_gray16_with_compression_strategy(PngCompressionStrategy::Stored),
    PngEncoder::new_gray16_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    PngEncoder::new_gray16_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
    PngEncoder::new_gray16_with_filter_strategy(PngFilterStrategy::None),
    PngEncoder::new_gray16_with_filter_strategy(PngFilterStrategy::Adaptive),
    PngEncoder::new_gray16_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive),
  ] {
    let (_, writer) = png_encode_with(encoder, gray)
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x10' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")
  }
  let repeated = png_encode_gray16_repeated_image()
  let (_, writer) = png_encode_with(
    PngEncoder::new_gray16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive,
    ),
    repeated,
  )
  let bytes = png_encode_prefix(writer)
  inspect(
    bytes[48] == b'\x01' && bytes[49] == b'\x12' && bytes[50] == b'\x34' &&
      bytes[51] == b'\x00' && bytes[52] == b'\x00' && bytes[53] == b'\x00' &&
      bytes[54] == b'\x00',
    content="true",
  )
}

///| The complete strategy Cartesian product preserves Gray16 framing and one
/// Stored/None stream proves both U16 source endiannesses use PNG wire order.
test "PNG Gray16 eager six-pair framing and source endianness agree" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
        png_encode_gray16_image(),
      )
      let bytes = png_encode_prefix(writer)
      inspect(bytes[24] == b'\x10' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")
    }
  }
  let (_, little_writer) = png_encode_with(
    PngEncoder::new_gray16_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::None),
    png_encode_gray16_image(),
  )
  let (_, big_writer) = png_encode_with(
    PngEncoder::new_gray16_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::None),
    png_encode_gray16_big_image(),
  )
  let little = png_encode_prefix(little_writer)
  let big = png_encode_prefix(big_writer)
  inspect(little == big, content="true")
  inspect(
    little[48] == b'\x00' && little[49] == b'\x12' && little[50] == b'\x34' &&
      little[51] == b'\xab' && little[52] == b'\xcd',
    content="true",
  )
}

///| Public Gray16 evidence must preserve the full U16 PNG wire sample while
/// documenting the RGB8 canonicalization exposed by the decoder.
test "PNG Gray16 public eager fidelity" {
  let expected = b"\x00\x12\x34\xab\xcd\x00\xff\x00\x7f\x01\x80\x02\xfe\x10"
  let (_, little_writer) = png_encode_with(
    PngEncoder::new_gray16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    png_encode_gray16_public_fidelity_image(@model.Endianness::Little),
  )
  let (_, big_writer) = png_encode_with(
    PngEncoder::new_gray16_with_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None,
    ),
    png_encode_gray16_public_fidelity_image(@model.Endianness::Big),
  )
  let little = png_encode_prefix(little_writer)
  let big = png_encode_prefix(big_writer)
  if little != big || little[24] != b'\x10' || little[25] != b'\x00' ||
    little[28] != b'\x00' || png_encode_gray16_public_stored_scanlines(little, 14) != expected {
    abort("png gray16 public eager wire")
  }
  png_encode_gray16_public_decode_is_canonical(little)

  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
        png_encode_gray16_public_fidelity_image(@model.Endianness::Little),
      )
      let bytes = png_encode_prefix(writer)
      if bytes[24] != b'\x10' || bytes[25] != b'\x00' || bytes[28] != b'\x00' {
        abort("png gray16 public eager ihdr")
      }
      png_encode_gray16_public_decode_is_canonical(bytes)
    }
  }
}

///| FixedOrStored Gray8 must use the same bounded machine rather than a
/// profile-specific output path.
test "PNG Gray8 eager FixedOrStored uses the shared bounded path" {
  let gray = png_encode_gray8_image(
    Bytes::from_array(Array::make(32, b'\xaa')), width=32UL,
  )
  let (_, writer) = png_encode_with(
    PngEncoder::new_gray8_with_compression_strategy(
      PngCompressionStrategy::FixedOrStored,
    ),
    gray,
  )
  let bytes = png_encode_prefix(writer)
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=512UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ), png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap()
  inspect(bytes[24] == b'\x08' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")
  inspect(decoded.image().view().get_byte(31UL, 0UL, 0UL).unwrap() == b'\xaa', content="true")
}

///| Every explicit Gray8 factory keeps colour type 0 and reaches the common
/// bounded encoder; only compression and filtering are selected by the caller.
test "PNG Gray8 eager strategy factories cover compression and filtering" {
  let gray = png_encode_gray8_image(b"\x10\x20\x30\x40", width=2UL, height=2UL)
  for encoder in [
    PngEncoder::new_gray8_with_compression_strategy(PngCompressionStrategy::Stored),
    PngEncoder::new_gray8_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    PngEncoder::new_gray8_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
    PngEncoder::new_gray8_with_filter_strategy(PngFilterStrategy::None),
    PngEncoder::new_gray8_with_filter_strategy(PngFilterStrategy::Adaptive),
    PngEncoder::new_gray8_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive),
    PngEncoder::new_gray8_with_strategies(PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive),
    PngEncoder::new_gray8_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive),
  ] {
    let (_, writer) = png_encode_with(encoder, gray)
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x08' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")
  }
}

///| Every public Gray8 strategy pair must preserve a generated multi-row
/// source through the complete public eager encode/decode boundary.
test "PNG Gray8 eager strategy pairs decode generated samples faithfully" {
  let gray = png_encode_gray8_fidelity_image()
  let expected = gray.view()
  inspect(
    expected.format().channels() == @model.ChannelOrder::Gray &&
      expected.format().channel_count() == 1UL,
    content="true",
  )
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_gray8_with_strategies(strategy, filter_strategy), gray,
      )
      let bytes = png_encode_prefix(writer)
      inspect(bytes[24] == b'\x08' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")
      let owner = @bytes.OwnedBytes::from_bytes(
        bytes, png_encode_budget(bytes=1048576UL, work=0UL),
      ).unwrap()
      let decoded = @codec.ImageDecoder::decode(
        PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
        @codec.DecodeOptions::new(
          require_complete_input=true, preserve_opaque_metadata=false,
        ), png_encode_limits(output=4096UL, work=1048576UL),
        png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
      ).unwrap()
      let restored = decoded.image().view()
      if restored.width() != expected.width() || restored.height() != expected.height() ||
        restored.format().channels() != @model.ChannelOrder::Rgb ||
        restored.format().channel_count() != 3UL {
        abort("png gray8 decoded descriptor")
      }
      for y = 0UL; y < expected.height(); y = y + 1UL {
        for x = 0UL; x < expected.width(); x = x + 1UL {
          let sample = expected.get_byte(x, y, 0UL).unwrap()
          if restored.get_byte(x, y, 0UL).unwrap() != sample ||
            restored.get_byte(x, y, 1UL).unwrap() != sample ||
            restored.get_byte(x, y, 2UL).unwrap() != sample {
            abort("png gray8 decoded sample")
          }
        }
      }
    }
  }
}

///|
test "PNG compression strategy eager factories encode supported images" {
  for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
    let image = png_encode_image(3UL, b"\x12\x34\x56")
    let (_, writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(strategy), image,
    )
    let bytes = png_encode_prefix(writer)
    let owner = @bytes.OwnedBytes::from_bytes(
      bytes, png_encode_budget(bytes=512UL, work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x12', content="true")
  }
}

///|
test "PNG fixed-or-stored eager selects a final fixed DEFLATE block" {
  let pixels = Bytes::from_array(Array::make(96, b'\xaa'))
  let image = png_encode_image(3UL, pixels, width=32UL)
  let (_, writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
  )
  let bytes = png_encode_prefix(writer)
  // The first DEFLATE byte follows the two-byte zlib header at the IDAT payload.
  inspect((bytes[43] & b'\x07') == b'\x03', content="true")
  let owner = @bytes.OwnedBytes::from_bytes(bytes, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap()
  inspect(decoded.image().view().get_byte(31UL, 0UL, 2UL).unwrap() == b'\xaa', content="true")
}

///| The opt-in strategy has one strict Dynamic winner and exposes final BTYPE=10
/// without changing either legacy strategy.
test "PNG dynamic eager preserves non-winning complete-PNG fallback" {
  let image = png_encode_image(3UL, Bytes::from_array(Array::make(96, b'\xaa')), width=32UL)
  let (_, writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored), image,
  )
  let bytes = png_encode_prefix(writer)
  inspect((bytes[43] & b'\x07') == b'\x03', content="true")
}

///|
test "PNG dynamic strategy eager factory freezes compatibility routes" {
  let (_, rgb_stored_writer) = png_encode(png_encode_image(3UL, b"\x12\x34\x56"))
  inspect(
    png_encode_prefix(rgb_stored_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let (_, rgba_stored_writer) = png_encode(png_encode_image(4UL, b"\x04\x05\x06\x07"))
  inspect(
    png_encode_prefix(rgba_stored_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x04\x05\x06\x07\x00\x37\x00\x17\x05\x48\x0f\xc7\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  for channels in [3UL, 4UL] {
    let image = png_encode_image(
      channels, Bytes::from_array(Array::make((channels * 32UL).to_int(), b'\xaa')),
      width=32UL,
    )
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let (_, fixed_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
    )
    let (_, dynamic_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored), image,
    )
    let dynamic = png_encode_prefix(dynamic_writer)
    inspect(png_encode_prefix(fixed_writer) == fixed, content="true")
    inspect(dynamic == fixed, content="true")
    inspect((fixed[43] & b'\x07') == b'\x03', content="true")
    let owner = @bytes.OwnedBytes::from_bytes(
      dynamic, png_encode_budget(bytes=512UL, work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(31UL, 0UL, channels - 1UL).unwrap() == b'\xaa', content="true")
  }
}

///|
test "PNG encoder emits canonical RGB and RGBA stored-deflate bytes" {
  let (rgb_result, rgb_writer) = png_encode(png_encode_image(3UL, b"\x12\x34\x56"))
  inspect(
    png_encode_prefix(rgb_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  inspect(rgb_result.bytes_written(), content="72")
  let (_, rgba_writer) = png_encode(png_encode_image(4UL, b"\x04\x05\x06\x07"))
  inspect(png_encode_prefix(rgba_writer)[25] == b'\x06', content="true")
}

///|
test "PNG compression strategy legacy eager constructors retain frozen stored bytes" {
  let (_, rgb_writer) = png_encode(png_encode_image(3UL, b"\x12\x34\x56"))
  inspect(
    png_encode_prefix(rgb_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let (_, rgba_writer) = png_encode(png_encode_image(4UL, b"\x04\x05\x06\x07"))
  inspect(
    png_encode_prefix(rgba_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x04\x05\x06\x07\x00\x37\x00\x17\x05\x48\x0f\xc7\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
}

///| Generated RGB8/RGBA8 Adam7 public encodings must round-trip exactly while
///| every legacy and explicit-None factory retains its frozen method-0 bytes.
test "PNG Adam7 public eager fidelity and frozen None compatibility" {
  let rgb = png_encode_image(3UL, b"\x12\x34\x56")
  let rgba = png_encode_image(4UL, b"\x04\x05\x06\x07")
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x04\x05\x06\x07\x00\x37\x00\x17\x05\x48\x0f\xc7\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  for image in [rgb, rgba] {
    let expected = if image.view().format().channel_count() == 3UL {
      rgb_stored
    } else {
      rgba_stored
    }
    for encoder in [
      PngEncoder::new(),
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::Stored),
      PngEncoder::new_with_filter_strategy(PngFilterStrategy::None),
      PngEncoder::new_with_filter_strategy(PngFilterStrategy::Adaptive),
      PngEncoder::new_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::None),
      PngEncoder::new_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive),
      PngEncoder::new_with_interlace_strategy(PngInterlaceStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, PngInterlaceStrategy::None),
    ] {
      let (_, writer) = png_encode_with(encoder, image)
      let bytes = png_encode_prefix(writer)
      inspect(bytes == expected && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let image = png_encode_image(
      channels, Bytes::from_array(Array::make((channels * 32UL).to_int(), b'\xaa')), width=32UL,
    )
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    for encoder in [
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
      PngEncoder::new_with_strategies(PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None),
      PngEncoder::new_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None),
    ] {
      let (_, writer) = png_encode_with(encoder, image)
      let bytes = png_encode_prefix(writer)
      inspect(bytes == fixed && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let image = png_adam7_admission_image(channels)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      let encoder = PngEncoder::new_with_all_strategies(
        strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      )
      let (_, writer) = png_adam7_encode_with(encoder, image)
      let bytes = png_encode_prefix(writer)
      inspect(bytes[28] == b'\x01' && bytes[0] == b'\x89' &&
        bytes[bytes.length() - 1] == b'\x82', content="true")
      png_filter_strategy_decode_matches_source(bytes, image)
    }
  }
}

///| Every all-strategy Adam7 eager route rejects capability, geometry, output,
/// codec-work, and caller-budget failures before its Writer becomes observable.
test "PNG Adam7 eager all-strategy admission is atomic" {
  for channels in [3UL, 4UL] {
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels, include_opaque=true),
      png_adam7_admission_limits(), 1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(width=4UL),
      1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(output=1UL),
      1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(work=1UL),
      1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(), 1UL,
    )
  }
}

///|
test "PNG encoder round trips RGB and straight RGBA pixels" {
  for image in [png_encode_image(3UL, b"\x12\x34\x56"), png_encode_image(4UL, b"\x04\x05\x06\x07")] {
    let (_, writer) = png_encode(image)
    let bytes = png_encode_prefix(writer)
    let owner = @bytes.OwnedBytes::from_bytes(bytes, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
      png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap()
    for channel = 0UL; channel < image.view().format().channel_count(); channel = channel + 1UL {
      inspect(decoded.image().view().get_byte(0UL, 0UL, channel).unwrap() == image.view().get_byte(0UL, 0UL, channel).unwrap(), content="true")
    }
  }
}

///|
test "PNG encoder rejects output and budget limits before Writer output" {
  let image = png_encode_image(3UL, b"\x12\x34\x56")
  let writer = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(output=71UL), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context() == Some("output-bytes"), content="true")
  inspect(writer.position(), content="0")
  let restricted = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  inspect(@codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), restricted as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(work=71UL), @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(restricted.position(), content="0")
  let semantic_writer = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  let semantic = @codec.ImageEncoder::encode(
    PngEncoder::new(), png_encode_image(3UL, b"\x12\x34\x56", include_opaque=true).view(),
    semantic_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(semantic.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
  inspect(semantic_writer.position(), content="0")
}

///|
test "PNG encoder rejects retained non-sRGB metadata before output" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x04gAMA\x00\x01\x86\xa0\x31\xe8\x96\x5f\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = @bytes.OwnedBytes::from_bytes(source, png_encode_budget(bytes=source.length().to_uint64(), work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(bytes=512UL), @error.Diagnostics::new(),
  ).unwrap()
  inspect(!decoded.image().descriptor().supports_reference_operations(), content="true")
  let writer = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), decoded.image().view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
  inspect(error.context() == Some("builtin-encoded-srgb-required"), content="true")
  inspect(writer.position(), content="0")
}

///|
struct PngEncodeScriptWriter {
  mut completed : UInt64
  mut calls : UInt64
  accepted : Array[Byte]
  mut one_byte_calls : Bool
  fail_at : UInt64
}

///|
impl @io.Writer for PngEncodeScriptWriter with fn write(self, source) {
  self.calls = self.calls + 1UL
  if source.length() != 1UL { self.one_byte_calls = false }
  if self.completed >= self.fail_at {
    @io.WriteOutcome::Failed(@error.CoreError::new(
      @error.ErrorCategory::Host, @error.ErrorCode::HostOperationFailed,
      operation="png-scripted-write", requested=91UL, completed=17UL,
      limit=23UL, context="scripted",
    ), 0UL)
  } else {
    self.accepted.push(source.get(0UL).unwrap())
    self.completed = self.completed + 1UL
    @io.WriteOutcome::Progress(1UL)
  }
}

///|
test "PNG encoder isolated four-target evidence preserves original Writer failure and accepted prefix" {
  let image = png_encode_image(3UL, b"\x12\x34\x56")
  let canonical = png_encode(image).1 |> png_encode_prefix
  let failed = PngEncodeScriptWriter::{
    completed: 0UL, calls: 0UL, accepted: [], one_byte_calls: true, fail_at: 43UL,
  }
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), failed as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Host, content="true")
  inspect(error.code() == @error.ErrorCode::HostOperationFailed, content="true")
  inspect(error.operation() == Some("png-scripted-write"), content="true")
  inspect(error.requested() == Some(91UL), content="true")
  inspect(error.completed() == Some(17UL), content="true")
  inspect(error.limit() == Some(23UL), content="true")
  inspect(error.context() == Some("scripted"), content="true")
  inspect(failed.completed == 43UL, content="true")
  inspect(failed.calls == 44UL, content="true")
  inspect(failed.one_byte_calls, content="true")
  let expected_prefix : Array[Byte] = []
  for index = 0; index < 43; index = index + 1 {
    expected_prefix.push(canonical[index])
  }
  inspect(Bytes::from_array(failed.accepted) == Bytes::from_array(expected_prefix), content="true")
}

///|
struct PngEncodeMalformedProgressWriter {
  progress : UInt64
  mut calls : UInt64
}

///|
impl @io.Writer for PngEncodeMalformedProgressWriter with fn write(self, _source) {
  self.calls = self.calls + 1UL
  @io.WriteOutcome::Progress(self.progress)
}

///|
test "PNG encoder rejects malformed direct one-byte Writer progress" {
  let image = png_encode_image(3UL, b"\x12\x34\x56")
  for progress in [0UL, 2UL] {
    let writer = PngEncodeMalformedProgressWriter::{ progress, calls: 0UL }
    let error = @codec.ImageEncoder::encode(
      PngEncoder::new(), image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::State, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    inspect(error.operation() == Some("png-encode-write"), content="true")
    inspect(error.requested() == Some(progress), content="true")
    inspect(error.completed() == Some(0UL), content="true")
    inspect(error.limit() == Some(1UL), content="true")
    inspect(writer.calls, content="1")
  }
}

///|
test "PNG fixed-or-stored public selected work charges once" {
  let image = png_encode_image(3UL, Bytes::from_array(Array::make(96, b'\xaa')), width=32UL)
  let generous = png_encode_budget(work=1048576UL)
  let before = generous.remaining()
  let writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(work=1048576UL), generous, @error.Diagnostics::new(),
  ).unwrap())
  let charged = before.work() - generous.remaining().work()
  inspect(charged > 0UL, content="true")
  let exact = png_encode_budget(work=charged)
  let exact_writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), exact_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(work=charged), exact, @error.Diagnostics::new(),
  ).unwrap())
  inspect(exact.remaining().work(), content="0")
  let one_less = png_encode_budget(work=charged - 1UL)
  let one_less_before = one_less.remaining()
  let rejected = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  inspect(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), rejected as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(work=charged), one_less, @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(rejected.position(), content="0")
  inspect(one_less.remaining().work() == one_less_before.work(), content="true")
}
