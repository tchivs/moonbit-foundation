///|
fn png_stream_test_budget(work? : UInt64 = 1048576UL) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL, allocations=16UL, allocation_size=1048576UL,
    width=70000UL, height=8UL, pixels=560000UL, depth=0UL, work~, 
  ))
}

///|
fn png_stream_test_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
  width? : UInt64 = 70000UL,
  height? : UInt64 = 8UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=width, max_height=height, max_pixels=560000UL, max_work=work,
  )
}

///|
fn png_stream_test_image(
  channels : UInt64,
  width? : UInt64 = 1UL,
  include_opaque? : Bool = false,
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          view.set_byte(x, y, channel, (y * channels * width + x * channels + channel).to_byte()).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Packed one-channel Gray8 test image for the explicit caller-buffered route.
fn png_stream_gray8_image(
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
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

///| The eager and chunk Gray8 fidelity cases use the same compact multi-row source.
fn png_stream_gray8_fidelity_image() -> @storage.OwnedImage {
  png_stream_gray8_image(
    b"\x00\x7f\xff\x12\xa5\x34\xc8\x56\xe1\x09\xab\xcd\x23\x89\xfe",
    width=5UL, height=3UL,
  )
}

///|
fn png_stream_gray16_image() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
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

///| Compact packed Gray+Alpha8 source with non-symmetric component pairs.
fn png_stream_graya8_image() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 0UL, b'\x13').unwrap()
    view.set_byte(0UL, 0UL, 1UL, b'\xa7').unwrap()
    view.set_byte(1UL, 0UL, 0UL, b'\xd2').unwrap()
    view.set_byte(1UL, 0UL, 1UL, b'\x4c').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| The measured Stored corpus gives every Adam7 pass a distinct G,A sample
/// sequence with `s = 5*y + x`, `G = 0x20 + s`, and `A = 0xa0 + s`.
fn png_stream_graya8_adam7_stored_ramp_5x5() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
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

///| A five-by-five legal GrayAlpha8 source gives every Adam7 pass a distinct
/// G,A sample sequence for caller-buffered parity.
fn png_stream_graya8_adam7_image() -> @storage.OwnedImage {
  png_stream_graya8_adam7_stored_ramp_5x5()
}

///| The measured Fixed corpus is a five-by-five flat GrayAlpha8 image.
fn png_stream_graya8_adam7_fixed_flat_5x5() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        view.set_byte(x, y, 0UL, b'\x34').unwrap()
        view.set_byte(x, y, 1UL, b'\xa7').unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| The measured Dynamic corpus is a 128-by-five periodic GrayAlpha8 image.
fn png_stream_graya8_adam7_dynamic_periodic_128x5() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    128UL, 5UL, @model.ImageFormat::graya8(),
    [@model.PlaneDescriptor::new(0UL, 1280UL, 256UL, 256UL, 1UL, 1UL, 128UL, 5UL).unwrap()],
    1280UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 128UL; x = x + 1UL {
        let i = 2UL * (128UL * y + x)
        view.set_byte(x, y, 0UL, (i % 5UL).to_byte()).unwrap()
        view.set_byte(x, y, 1UL, ((i + 1UL) % 5UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Compact packed U16 Gray+Alpha source with non-symmetric component lanes.
fn png_stream_graya16_image() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
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

///| Compact packed U16 RGBA source with non-symmetric component lanes.
fn png_stream_rgba16_image() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    let lanes : Array[Byte] = [
      b'\x34', b'\x12', b'\xc5', b'\xa7', b'\x0f', b'\xbe', b'\x76', b'\x5a',
      b'\xe1', b'\x90', b'\x2d', b'\x6c', b'\xb8', b'\x03', b'\x47', b'\xfd',
    ]
    for pixel = 0UL; pixel < 2UL; pixel = pixel + 1UL {
      for component = 0UL; component < 4UL; component = component + 1UL {
        for lane = 0UL; lane < 2UL; lane = lane + 1UL {
          let index = 8UL * pixel + 2UL * component + lane
          view.set_component_byte(pixel, 0UL, component, lane, lanes[index.to_int()]).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| A five-by-five legal GrayAlpha16 source keeps all seven Adam7 passes
/// nonempty while making component and endian lanes observable during chunk
/// parity checks.
fn png_stream_graya16_adam7_image() -> @storage.OwnedImage {
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
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

///| A five-by-five packed RGBA16 Adam7 source with distinct coordinate,
/// component, and little-endian storage lanes.
fn png_stream_rgba16_adam7_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    5UL, 5UL, @model.ImageFormat::rgba16(),
    [@model.PlaneDescriptor::new(0UL, 200UL, 40UL, 40UL, 1UL, 1UL, 5UL, 5UL).unwrap()],
    200UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        let sample = y * 5UL + x
        for component = 0UL; component < 4UL; component = component + 1UL {
          view.set_component_byte(
            x, y, component, 0UL,
            (b'\x10'.to_uint64() + 32UL * component + sample).to_byte(),
          ).unwrap()
          view.set_component_byte(
            x, y, component, 1UL,
            (b'\x80'.to_uint64() + 32UL * component + sample).to_byte(),
          ).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| The caller-buffered public-evidence corpus uses every non-symmetric U16
/// sample from the eager test, stored little-endian in tightly packed rows.
fn png_stream_gray16_public_fidelity_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    3UL, 2UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  let wire = [
    [b'\x12', b'\x34'], [b'\xab', b'\xcd'], [b'\x00', b'\xff'],
    [b'\x7f', b'\x01'], [b'\x80', b'\x02'], [b'\xfe', b'\x10'],
  ]
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 2UL; y = y + 1UL {
      for x = 0UL; x < 3UL; x = x + 1UL {
        let sample = wire[(y * 3UL + x).to_int()]
        view.set_component_byte(x, y, 0UL, 0UL, sample[1]).unwrap()
        view.set_component_byte(x, y, 0UL, 1UL, sample[0]).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Gray16 corpora that force the selected DEFLATE route without retaining a
/// converted row: a flat stream has short-distance matches, while the five-byte
/// period defeats the bounded distance-1..4 matcher and favors Dynamic coding.
fn png_stream_gray16_replay_image(
  width : UInt64,
  periodic? : Bool = false,
) -> @storage.OwnedImage {
  let bytes = width * 2UL
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, bytes, bytes, bytes, 1UL, 1UL, width, 1UL).unwrap()],
    bytes,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      let low = if periodic { (x * 2UL % 5UL).to_byte() } else { b'\x34' }
      let high = if periodic { ((x * 2UL + 1UL) % 5UL).to_byte() } else { b'\x12' }
      view.set_component_byte(x, 0UL, 0UL, 0UL, low).unwrap()
      view.set_component_byte(x, 0UL, 0UL, 1UL, high).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///| GrayAlpha16 corpora force the same selected DEFLATE routes while retaining
/// packed little-endian checked components for the four-byte filter cursor.
fn png_stream_graya16_replay_image(
  width : UInt64,
  periodic? : Bool = false,
) -> @storage.OwnedImage {
  let bytes = width * 4UL
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL, @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(0UL, bytes, bytes, bytes, 1UL, 1UL, width, 1UL).unwrap()],
    bytes,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      let gray_low = if periodic { (x * 4UL % 5UL).to_byte() } else { b'\x34' }
      let gray_high = if periodic { ((x * 4UL + 1UL) % 5UL).to_byte() } else { b'\x12' }
      let alpha_low = if periodic { ((x * 4UL + 2UL) % 5UL).to_byte() } else { b'\xc5' }
      let alpha_high = if periodic { ((x * 4UL + 3UL) % 5UL).to_byte() } else { b'\xa7' }
      view.set_component_byte(x, 0UL, 0UL, 0UL, gray_low).unwrap()
      view.set_component_byte(x, 0UL, 0UL, 1UL, gray_high).unwrap()
      view.set_component_byte(x, 0UL, 1UL, 0UL, alpha_low).unwrap()
      view.set_component_byte(x, 0UL, 1UL, 1UL, alpha_high).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_test_eager(image : @storage.OwnedImage) -> Bytes {
  png_stream_test_eager_with_strategy(image, PngCompressionStrategy::Stored)
}

///|
fn png_stream_test_eager_with_strategy(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(strategy), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_test_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(strategy, filter_strategy), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_test_eager_with_all_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_all_strategies(strategy, filter_strategy, interlace_strategy), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_test_flat_image(channels : UInt64, width : UInt64) -> @storage.OwnedImage {
  let image = png_stream_test_image(channels, width=width)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, b'\xaa').unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Five periodic literal values deliberately exceed the A1 distance-1..4
/// matcher, making this a compact strict Dynamic candidate rather than a match
/// compression corpus.
fn png_stream_test_dynamic_image(width? : UInt64 = 128UL) -> @storage.OwnedImage {
  let image = png_stream_test_image(3UL, width=width)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, ((x * 3UL + channel) % 5UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Five periodic literal values deliberately exceed the retained distance-1..4
///| matcher for RGB8 and straight-RGBA8 corpus sources.
fn png_stream_test_dynamic_corpus_image(
  channels : UInt64,
  width? : UInt64 = 128UL,
) -> @storage.OwnedImage {
  let image = png_stream_test_image(channels, width=width)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, ((x * channels + channel) % 5UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_test_fixed_or_stored_corpus_decode_matches_source(
  bytes : Bytes,
  source : @storage.OwnedImage,
) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_stream_test_budget(work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let expected = source.view()
  if decoded.image().descriptor().width() != source.descriptor().width() ||
    decoded.image().descriptor().height() != source.descriptor().height() ||
    decoded.image().descriptor().format().channel_count() !=
      source.descriptor().format().channel_count() {
    abort("png fixed-or-stored corpus decoded descriptor")
  }
  for y = 0UL; y < expected.height(); y = y + 1UL {
    for x = 0UL; x < expected.width(); x = x + 1UL {
      for channel = 0UL; channel < expected.format().channel_count(); channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() !=
          expected.get_byte(x, y, channel).unwrap() {
          abort("png fixed-or-stored corpus decoded component")
        }
      }
    }
  }
}

///|
fn png_stream_test_fixed_or_stored_corpus_case(source : @storage.OwnedImage) -> Unit {
  let stored = png_stream_test_eager_with_strategy(source, PngCompressionStrategy::Stored)
  let eager_first = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::FixedOrStored,
  )
  let eager_second = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::FixedOrStored,
  )
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    source.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  if eager_first.length() > stored.length() {
    abort("png fixed-or-stored corpus never-larger")
  }
  if eager_first.length() >= stored.length() {
    abort("png fixed-or-stored corpus win")
  }
  if eager_first != eager_second || eager_first != chunked {
    abort("png fixed-or-stored corpus determinism")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_first, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_second, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(chunked, source)
}

///| Public Dynamic evidence compares all strategy routes while retaining the
///| existing complete-input descriptor-and-component decode oracle.
fn png_stream_test_dynamic_corpus_case(source : @storage.OwnedImage) -> Unit {
  let stored = png_stream_test_eager_with_strategy(source, PngCompressionStrategy::Stored)
  let fixed = png_stream_test_eager_with_strategy(source, PngCompressionStrategy::FixedOrStored)
  let eager_first = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  let eager_second = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    source.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  ignore(stored)
  if eager_first.length() > fixed.length() {
    abort("png dynamic corpus never-larger")
  }
  if eager_first.length() >= fixed.length() {
    abort("png dynamic corpus strict win")
  }
  if (eager_first[43] & b'\x07') != b'\x05' {
    abort("png dynamic corpus final dynamic block")
  }
  if eager_first != eager_second || eager_first != chunked {
    abort("png dynamic corpus determinism")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_first, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_second, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(chunked, source)
}

///|
fn png_chunk_test_owner(capacity : UInt64, fill? : Byte = b'\x00') -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    Bytes::from_array(Array::make(capacity.to_int(), fill)),
    png_stream_test_budget(work=0UL),
  ).unwrap()
}

///|
fn png_chunk_test_pull(
  encoder : PngChunkEncoder,
  capacity : UInt64,
  output : Array[Byte],
) -> PngChunkPullResult {
  let owner = png_chunk_test_owner(capacity)
  let result = owner.with_mut(0UL, capacity, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  for index = 0UL; index < result.written(); index = index + 1UL {
    output.push(owner.view().get(index).unwrap())
  }
  result
}

///|
fn png_chunk_test_drain_encoder(
  encoder : PngChunkEncoder,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let output : Array[Byte] = []
  let mut turn = 0
  while turn < 1024 {
    let capacity = schedule[turn % schedule.length()]
    let result = png_chunk_test_pull(encoder, capacity, output)
    if result.total_written() != output.length().to_uint64() {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
        context="png-chunk-total",
      ))
    }
    match result.outcome() {
      PngChunkPullOutcome::Finished => return Ok(Bytes::from_array(output))
      PngChunkPullOutcome::Failed(error) => return Err(error)
      PngChunkPullOutcome::NeedOutput => turn = turn + 1
    }
  }
  Err(@error.CoreError::new(
    @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
    context="png-chunk-unreachable",
  ))
}

///| Drain one fresh public Gray16 encoder while proving only accepted bytes
/// change caller leases and that the successful terminal state is sticky.
fn png_stream_gray16_public_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
  eager : Bytes,
) -> Unit {
  let encoder = PngChunkEncoder::new_gray16_with_strategies(
    image.view(), strategy, filter_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) {
      Ok(encoder.pull(lease))
    }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png gray16 public accepted progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png gray16 public lease tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png gray16 public chunk failure")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png gray16 public eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) {
          Ok(encoder.pull(lease))
        }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png gray16 public terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' {
            abort("png gray16 public terminal lease")
          }
        }
        return
      }
    }
  }
  abort("png gray16 public drain unreachable")
}

///| Drain one fresh public GrayAlpha8 encoder while proving only accepted
/// bytes change caller leases and that the successful terminal state is sticky.
fn png_stream_graya8_public_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
  eager : Bytes,
) -> Unit {
  let encoder = PngChunkEncoder::new_graya8_with_strategies(
    image.view(), strategy, filter_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) {
      Ok(encoder.pull(lease))
    }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png graya8 public accepted progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png graya8 public lease tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png graya8 public chunk failure")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png graya8 public eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) {
          Ok(encoder.pull(lease))
        }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png graya8 public terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' {
            abort("png graya8 public terminal lease")
          }
        }
        return
      }
    }
  }
  abort("png graya8 public drain unreachable")
}

///| Drain one fresh public GrayAlpha16 encoder while proving only accepted
/// bytes change caller leases and that the successful terminal state is sticky.
fn png_stream_graya16_public_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
  eager : Bytes,
) -> Unit {
  let encoder = PngChunkEncoder::new_graya16_with_strategies(
    image.view(), strategy, filter_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) {
      Ok(encoder.pull(lease))
    }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png graya16 public accepted progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png graya16 public lease tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png graya16 public chunk failure")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png graya16 public eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) {
          Ok(encoder.pull(lease))
        }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png graya16 public terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' {
            abort("png graya16 public terminal lease")
          }
        }
        return
      }
    }
  }
  abort("png graya16 public drain unreachable")
}

///| Drain one fresh public RGBA16 encoder while proving only accepted bytes
/// change caller leases and that the successful terminal state is sticky.
fn png_stream_rgba16_public_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
  eager : Bytes,
) -> Unit {
  let encoder = PngChunkEncoder::new_rgba16_with_strategies(
    image.view(), strategy, filter_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) {
      Ok(encoder.pull(lease))
    }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png rgba16 public accepted progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png rgba16 public lease tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png rgba16 public chunk failure")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png rgba16 public eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) {
          Ok(encoder.pull(lease))
        }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png rgba16 public terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' {
            abort("png rgba16 public terminal lease")
          }
        }
        return
      }
    }
  }
  abort("png rgba16 public drain unreachable")
}

///| Eager Gray8 output is the oracle for the caller-buffered Gray8 factory.
fn png_stream_gray8_eager(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray8(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_gray16_eager(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray16(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Combined eager Gray16 output is the caller-buffered identity oracle.
fn png_stream_gray16_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Combined eager Gray+Alpha8 output is the caller-buffered identity oracle.
fn png_stream_graya8_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya8_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Combined eager GrayAlpha16 output is the caller-buffered identity oracle.
fn png_stream_graya16_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya16_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Combined eager RGBA16 output is the caller-buffered identity oracle.
fn png_stream_rgba16_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_rgba16_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Fresh eager RGBA16 Adam7 output is the oracle for a separately constructed
/// caller-buffered encoder.
fn png_stream_rgba16_eager_with_all_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_rgba16_with_all_strategies(strategy, filter_strategy, interlace_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Explicit GrayAlpha16 interlace selection uses the same eager profile/machine
/// route as the caller-buffered factory family.
fn png_stream_graya16_eager_with_all_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya16_with_all_strategies(strategy, filter_strategy, interlace_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Narrow GrayAlpha16 interlace selection is the caller-buffered identity
/// oracle for the corresponding public factory shape.
fn png_stream_graya16_eager_with_interlace_strategy(
  image : @storage.OwnedImage,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya16_with_interlace_strategy(interlace_strategy), image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Explicit GrayAlpha8 interlace selection uses the same eager profile/machine
/// route as its caller-buffered selector family.
fn png_stream_graya8_eager_with_all_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya8_with_all_strategies(strategy, filter_strategy, interlace_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Narrow GrayAlpha8 interlace selection is the eager identity oracle for the
/// corresponding caller-buffered public factory shape.
fn png_stream_graya8_eager_with_interlace_strategy(
  image : @storage.OwnedImage,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  png_stream_graya8_eager_with_all_strategies(
    image, PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

///| FixedOrStored eager output is the chunk identity oracle for Gray8.
fn png_stream_gray8_eager_with_compression(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
) -> Bytes {
  png_stream_gray8_eager_with_strategies(image, strategy, PngFilterStrategy::None)
}

///| Combined eager output is the caller-buffered identity oracle for Gray8.
fn png_stream_gray8_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray8_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| One ordinary nonzero lease capacity is enough to prove accepted-byte
/// accounting and byte-for-byte identity with the eager Gray8 route.
test "PNG Gray8 chunk Stored output matches eager and rejects atomically" {
  let gray = png_stream_gray8_image(b"\x7f")
  let eager = png_stream_gray8_eager(gray)
  let encoder = PngChunkEncoder::new_gray8(
    gray.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [17UL]).unwrap()
  inspect(chunked == eager && chunked[24] == b'\x08' && chunked[25] == b'\x00' && chunked[28] == b'\x00', content="true")

  let rgb = png_stream_test_image(3UL)
  let budget = png_stream_test_budget()
  let before = budget.remaining()
  let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
  let error = PngChunkEncoder::new_gray8(
    rgb.view(), png_stream_test_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(gray8-required)")
  inspect(png_adam7_stream_same_remaining(before, budget.remaining()), content="true")
  for index = 0UL; index < sentinel.view().length(); index = index + 1UL {
    if sentinel.view().get(index).unwrap() != b'Z' { abort("png gray8 rejection exposed lease") }
  }
}

///|
test "PNG Gray16 chunk Stored output matches eager and rejects atomically" {
  let gray = png_stream_gray16_image()
  let eager = png_stream_gray16_eager(gray)
  let chunked = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_gray16(
      gray.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  inspect(chunked == eager, content="true")
  let rgb = png_stream_test_image(3UL)
  let budget = png_stream_test_budget()
  let before = budget.remaining()
  let error = PngChunkEncoder::new_gray16(
    rgb.view(), png_stream_test_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(gray16-required)")
  inspect(
    budget.remaining().bytes() == before.bytes() &&
      budget.remaining().allocations() == before.allocations() &&
      budget.remaining().work() == before.work(),
    content="true",
  )
}

///| Combined Gray16 factory families must preserve eager/chunk identity before
/// the bounded filter and compression implementation is added.
test "PNG Gray16 chunk strategy factories match eager" {
  let gray = png_stream_gray16_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray16_eager_with_strategies(gray, strategy, filter_strategy)
      let chunked = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray16_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [3UL, 7UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
      inspect(
        eager[24] == b'\x10' && eager[25] == b'\x00' && eager[28] == b'\x00',
        content="true",
      )
      if strategy == PngCompressionStrategy::Stored && filter_strategy == PngFilterStrategy::None {
        inspect(
          eager[48] == b'\x00' && eager[49] == b'\x12' && eager[50] == b'\x34' &&
            eager[51] == b'\xab' && eager[52] == b'\xcd',
          content="true",
        )
      }
    }
  }
  ignore(PngChunkEncoder::new_gray16_with_compression_strategy(
    gray.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  ignore(PngChunkEncoder::new_gray16_with_filter_strategy(
    gray.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
}

///| The default caller-buffered Gray+Alpha8 route is a real type-4 path whose
/// ordinary drain preserves eager bytes and source component order.
test "PNG GrayAlpha8 chunk Stored output matches eager" {
  let gray_alpha = png_stream_graya8_image()
  let eager = png_stream_graya8_eager_with_strategies(
    gray_alpha, PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
  let chunked = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya8(
      gray_alpha.view(), png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  inspect(
    chunked == eager && chunked[24] == b'\x08' && chunked[25] == b'\x04' &&
      chunked[28] == b'\x00' && chunked[48] == b'\x00' &&
      chunked[49] == b'\x13' && chunked[50] == b'\xa7' &&
      chunked[51] == b'\xd2' && chunked[52] == b'\x4c',
    content="true",
  )
}

///| The explicit GrayAlpha16 caller-buffered route drains the same Type-4/16
/// stored stream as eager encoding.
test "PNG GrayAlpha16 chunk Stored output matches eager" {
  let gray_alpha = png_stream_graya16_image()
  let eager = png_stream_graya16_eager_with_strategies(
    gray_alpha, PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
  let chunked = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya16(
      gray_alpha.view(), png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  inspect(
    chunked == eager && chunked[24] == b'\x10' && chunked[25] == b'\x04' &&
      chunked[28] == b'\x00' && chunked[48] == b'\x00' &&
      chunked[49] == b'\x12' && chunked[50] == b'\x34' &&
      chunked[51] == b'\xa7' && chunked[52] == b'\xc5' &&
      chunked[53] == b'\xbe' && chunked[54] == b'\x0f' &&
      chunked[55] == b'\x5a' && chunked[56] == b'\x76',
    content="true",
  )
}

///| The narrow and independently selected GrayAlpha16 Adam7 chunk factories
/// drain to their corresponding eager selectors and the same Stored/None
/// Type-4/16 stream.
test "PNG GrayAlpha16 Adam7 chunk parity" {
  let narrow_eager = png_stream_graya16_eager_with_interlace_strategy(
    png_stream_graya16_adam7_image(), PngInterlaceStrategy::Adam7,
  )
  let selected_eager = png_stream_graya16_eager_with_all_strategies(
    png_stream_graya16_adam7_image(), PngCompressionStrategy::Stored,
    PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  let narrow_source = png_stream_graya16_adam7_image()
  let narrow = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya16_with_interlace_strategy(
      narrow_source.view(), PngInterlaceStrategy::Adam7,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  let selected_source = png_stream_graya16_adam7_image()
  let selected = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya16_with_all_strategies(
      selected_source.view(), PngCompressionStrategy::Stored,
      PngFilterStrategy::None, PngInterlaceStrategy::Adam7, png_stream_test_limits(),
      png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  inspect(
    narrow == narrow_eager && selected == selected_eager &&
      narrow_eager == selected_eager && narrow[24] == b'\x10' &&
      narrow[25] == b'\x04' && narrow[26] == b'\x00' && narrow[27] == b'\x00' &&
      narrow[28] == b'\x01' && selected[24] == b'\x10' &&
      selected[25] == b'\x04' && selected[26] == b'\x00' && selected[27] == b'\x00' &&
      selected[28] == b'\x01',
    content="true",
  )
}

///| Narrow and all-strategy GrayAlpha8 Adam7 chunk selectors drain through the
/// ordinary schedule to fresh eager bytes and retain Type-4/8 Adam7 framing.
test "PNG GrayAlpha8 Adam7 chunk parity" {
  let narrow_eager = png_stream_graya8_eager_with_interlace_strategy(
    png_stream_graya8_adam7_image(), PngInterlaceStrategy::Adam7,
  )
  let selected_eager = png_stream_graya8_eager_with_all_strategies(
    png_stream_graya8_adam7_image(), PngCompressionStrategy::Stored,
    PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  let narrow_source = png_stream_graya8_adam7_image()
  let narrow = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya8_with_interlace_strategy(
      narrow_source.view(), PngInterlaceStrategy::Adam7,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  let selected_source = png_stream_graya8_adam7_image()
  let selected = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya8_with_all_strategies(
      selected_source.view(), PngCompressionStrategy::Stored,
      PngFilterStrategy::None, PngInterlaceStrategy::Adam7, png_stream_test_limits(),
      png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  inspect(
    narrow == narrow_eager && selected == selected_eager &&
      narrow_eager == selected_eager && narrow[24] == b'\x08' &&
      narrow[25] == b'\x04' && narrow[26] == b'\x00' && narrow[27] == b'\x00' &&
      narrow[28] == b'\x01' && selected[24] == b'\x08' &&
      selected[25] == b'\x04' && selected[26] == b'\x00' && selected[27] == b'\x00' &&
      selected[28] == b'\x01',
    content="true",
  )
}

///| One legal all-strategy GrayAlpha8 Adam7 chunk selection drains through the
/// ordinary schedule to a fresh eager peer with Type-4/8 Adam7 framing.
fn png_stream_graya8_adam7_chunk_strategy(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Unit {
  let eager = png_stream_graya8_eager_with_all_strategies(
    png_stream_graya8_adam7_image(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
  )
  let source = png_stream_graya8_adam7_image()
  let chunked = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_graya8_with_all_strategies(
      source.view(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  if chunked != eager || chunked[24] != b'\x08' || chunked[25] != b'\x04' ||
    chunked[26] != b'\x00' || chunked[27] != b'\x00' || chunked[28] != b'\x01' {
    abort("png graya8 adam7 chunk strategy parity")
  }
}

///| Every legal GrayAlpha8 Adam7 compression/filter selector drains through
/// the ordinary public schedule to matching fresh eager bytes.
test "PNG GrayAlpha8 Adam7 chunk all strategy parity" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      png_stream_graya8_adam7_chunk_strategy(strategy, filter_strategy)
    }
  }
}

///| Every GrayAlpha16 caller-buffered factory drains to its eager peer across
/// all six bounded compression/filter choices.
test "PNG GrayAlpha16 chunk factory strategies match eager" {
  let gray_alpha = png_stream_graya16_image()
  ignore(PngChunkEncoder::new_graya16_with_compression_strategy(
    gray_alpha.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  ignore(PngChunkEncoder::new_graya16_with_filter_strategy(
    gray_alpha.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_graya16_eager_with_strategies(gray_alpha, strategy, filter_strategy)
      let chunked = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_graya16_with_strategies(
          gray_alpha.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [3UL, 7UL],
      ).unwrap()
      inspect(
        chunked == eager && eager[24] == b'\x10' && eager[25] == b'\x04' &&
          eager[28] == b'\x00',
        content="true",
      )
    }
  }
}

///| Every explicit non-interlaced RGBA16 caller-buffered factory drains to its
/// fresh eager counterpart without widening the legacy generic route.
test "PNG RGBA16 chunk factory strategies match eager" {
  let rgba = png_stream_rgba16_image()
  let stored = png_stream_rgba16_eager_with_strategies(
    rgba, PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
  let default = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_rgba16(
      rgba.view(), png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  let compressed = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_rgba16_with_compression_strategy(
      rgba.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
      png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  let compressed_eager = png_stream_rgba16_eager_with_strategies(
    rgba, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None,
  )
  let filtered = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_rgba16_with_filter_strategy(
      rgba.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(),
      png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  let filtered_eager = png_stream_rgba16_eager_with_strategies(
    rgba, PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive,
  )
  let selected = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_rgba16_with_strategies(
      rgba.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  let selected_eager = png_stream_rgba16_eager_with_strategies(
    rgba, PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
  )
  inspect(
    default == stored && compressed == compressed_eager && filtered == filtered_eager &&
      selected == selected_eager && stored[24] == b'\x10' && stored[25] == b'\x06' &&
      stored[28] == b'\x00',
    content="true",
  )
}

///| Every public Gray+Alpha8 caller-buffered factory is ordinary-drain parity
/// with its eager counterpart across the full bounded strategy matrix.
test "PNG GrayAlpha8 chunk factory strategies match eager" {
  let gray_alpha = png_stream_graya8_image()
  ignore(PngChunkEncoder::new_graya8_with_compression_strategy(
    gray_alpha.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  ignore(PngChunkEncoder::new_graya8_with_filter_strategy(
    gray_alpha.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_graya8_eager_with_strategies(gray_alpha, strategy, filter_strategy)
      let chunked = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_graya8_with_strategies(
          gray_alpha.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [3UL, 7UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
      inspect(
        eager[24] == b'\x08' && eager[25] == b'\x04' && eager[28] == b'\x00',
        content="true",
      )
    }
  }
}

///| FixedOrStored Gray8 uses the same accepted-byte acknowledgement accounting
/// as the eager bounded machine.
test "PNG Gray8 chunk FixedOrStored matches eager with accepted progress" {
  let gray = png_stream_gray8_image(
    Bytes::from_array(Array::make(32, b'\xaa')), width=32UL,
  )
  let eager = png_stream_gray8_eager_with_compression(
    gray, PngCompressionStrategy::FixedOrStored,
  )
  let encoder = PngChunkEncoder::new_gray8_with_compression_strategy(
    gray.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [17UL]).unwrap()
  inspect(chunked == eager && chunked[25] == b'\x00', content="true")
}

///| Gray8 eager/chunk parity covers every public compression-only,
/// filter-only, and combined factory using ordinary positive-capacity pulls.
test "PNG Gray8 chunk strategy factories match eager" {
  let gray = png_stream_gray8_image(b"\x10\x20\x30\x40", width=2UL, height=2UL)
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let eager = png_stream_gray8_eager_with_compression(gray, strategy)
    let chunked = png_chunk_test_drain_encoder(
      PngChunkEncoder::new_gray8_with_compression_strategy(
        gray.view(), strategy, png_stream_test_limits(), png_stream_test_budget(),
        @error.Diagnostics::new(),
      ).unwrap(),
      [17UL],
    ).unwrap()
    inspect(chunked == eager, content="true")
  }
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let eager = png_stream_gray8_eager_with_strategies(
      gray, PngCompressionStrategy::Stored, filter_strategy,
    )
    let chunked = png_chunk_test_drain_encoder(
      PngChunkEncoder::new_gray8_with_filter_strategy(
        gray.view(), filter_strategy, png_stream_test_limits(), png_stream_test_budget(),
        @error.Diagnostics::new(),
      ).unwrap(),
      [17UL],
    ).unwrap()
    inspect(chunked == eager, content="true")
  }
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray8_eager_with_strategies(gray, strategy, filter_strategy)
      let chunked = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [17UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
    }
  }
}

///| Public Gray8 chunk encoders may make no progress with an empty caller
/// lease, then must reproduce eager bytes with fresh hostile-capacity drains.
test "PNG Gray8 chunk strategy pairs preserve eager bytes under hostile capacities" {
  let gray = png_stream_gray8_fidelity_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray8_eager_with_strategies(gray, strategy, filter_strategy)
      let zero_encoder = PngChunkEncoder::new_gray8_with_strategies(
        gray.view(), strategy, filter_strategy, png_stream_test_limits(),
        png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let empty = png_chunk_test_owner(0UL)
      let zero = empty.with_mut(0UL, 0UL, fn(lease) {
        Ok(zero_encoder.pull(lease))
      }).unwrap()
      inspect(zero.written(), content="0")
      inspect(zero.total_written(), content="0")
      inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")

      let zero_prefixed = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [0UL, 1UL],
      ).unwrap()
      inspect(zero_prefixed == eager, content="true")

      let one_byte = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [1UL],
      ).unwrap()
      inspect(one_byte == eager, content="true")

      let ragged = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
      ).unwrap()
      inspect(ragged == eager, content="true")
    }
  }
}

///| All public Gray16 strategy pairs must preserve eager bytes and caller
/// lease ownership under hostile capacities.
test "PNG Gray16 chunk public evidence" {
  let image = png_stream_gray16_public_fidelity_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray16_eager_with_strategies(image, strategy, filter_strategy)
      let zero_encoder = PngChunkEncoder::new_gray16_with_strategies(
        image.view(), strategy, filter_strategy,
        png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let zero_owner = png_chunk_test_owner(1UL, fill=b'Z')
      let zero = zero_owner.with_mut(0UL, 0UL, fn(lease) {
        Ok(zero_encoder.pull(lease))
      }).unwrap()
      if zero.written() != 0UL || zero.total_written() != 0UL ||
        !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
        zero_owner.view().get(0UL).unwrap() != b'Z' {
        abort("png gray16 public empty lease")
      }
      png_stream_gray16_public_drain(
        image, strategy, filter_strategy, [0UL, 1UL], eager,
      )
      png_stream_gray16_public_drain(
        image, strategy, filter_strategy, [1UL], eager,
      )
      png_stream_gray16_public_drain(
        image, strategy, filter_strategy,
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
      )
    }
  }
}

///| All public GrayAlpha8 strategy pairs must preserve eager bytes and caller
/// lease ownership under hostile capacities.
test "PNG GrayAlpha8 chunk public evidence" {
  let image = png_stream_graya8_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_graya8_eager_with_strategies(image, strategy, filter_strategy)
      let zero_encoder = PngChunkEncoder::new_graya8_with_strategies(
        image.view(), strategy, filter_strategy,
        png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let zero_owner = png_chunk_test_owner(1UL, fill=b'Z')
      let zero = zero_owner.with_mut(0UL, 0UL, fn(lease) {
        Ok(zero_encoder.pull(lease))
      }).unwrap()
      if zero.written() != 0UL || zero.total_written() != 0UL ||
        !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
        zero_owner.view().get(0UL).unwrap() != b'Z' {
        abort("png graya8 public empty lease")
      }
      png_stream_graya8_public_drain(
        image, strategy, filter_strategy, [0UL, 1UL], eager,
      )
      png_stream_graya8_public_drain(
        image, strategy, filter_strategy, [1UL], eager,
      )
      png_stream_graya8_public_drain(
        image, strategy, filter_strategy,
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
      )
    }
  }
}

///| Every public GrayAlpha16 strategy pair must preserve eager bytes and caller
/// lease ownership under zero-capacity, one-byte, and ragged schedules.
test "PNG GrayAlpha16 chunk public evidence" {
  let image = png_stream_graya16_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_graya16_eager_with_strategies(image, strategy, filter_strategy)
      let zero_encoder = PngChunkEncoder::new_graya16_with_strategies(
        image.view(), strategy, filter_strategy,
        png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let zero_owner = png_chunk_test_owner(1UL, fill=b'Z')
      let zero = zero_owner.with_mut(0UL, 0UL, fn(lease) {
        Ok(zero_encoder.pull(lease))
      }).unwrap()
      if zero.written() != 0UL || zero.total_written() != 0UL ||
        !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
        zero_owner.view().get(0UL).unwrap() != b'Z' {
        abort("png graya16 public empty lease")
      }
      png_stream_graya16_public_drain(
        image, strategy, filter_strategy, [0UL, 1UL], eager,
      )
      png_stream_graya16_public_drain(
        image, strategy, filter_strategy, [1UL], eager,
      )
      png_stream_graya16_public_drain(
        image, strategy, filter_strategy,
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
      )
    }
  }
}

///| Every public RGBA16 strategy pair preserves eager bytes and caller lease
/// ownership under zero-capacity, one-byte, and ragged schedules.
test "PNG RGBA16 chunk public evidence" {
  let image = png_stream_rgba16_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_rgba16_eager_with_strategies(image, strategy, filter_strategy)
      let zero_encoder = PngChunkEncoder::new_rgba16_with_strategies(
        image.view(), strategy, filter_strategy,
        png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let zero_owner = png_chunk_test_owner(1UL, fill=b'Z')
      let zero = zero_owner.with_mut(0UL, 0UL, fn(lease) {
        Ok(zero_encoder.pull(lease))
      }).unwrap()
      if zero.written() != 0UL || zero.total_written() != 0UL ||
        !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
        zero_owner.view().get(0UL).unwrap() != b'Z' {
        abort("png rgba16 public empty lease")
      }
      png_stream_rgba16_public_drain(image, strategy, filter_strategy, [0UL, 1UL], eager)
      png_stream_rgba16_public_drain(image, strategy, filter_strategy, [1UL], eager)
      png_stream_rgba16_public_drain(
        image, strategy, filter_strategy,
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
      )
    }
  }
}

///| Drain a fresh RGBA16 Adam7 selector while proving acknowledged-only output,
/// lease-tail isolation, and sticky successful completion.
fn png_rgba16_adam7_chunk_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
) -> Unit {
  let eager = png_stream_rgba16_eager_with_all_strategies(
    image, strategy, filter_strategy, PngInterlaceStrategy::Adam7,
  )
  let encoder = PngChunkEncoder::new_rgba16_with_all_strategies(
    image.view(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(1UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
    empty.view().get(0UL).unwrap() != b'Z' {
    abort("png rgba16 Adam7 empty lease progress")
  }
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png rgba16 Adam7 accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png rgba16 Adam7 lease tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png rgba16 Adam7 chunk drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png rgba16 Adam7 eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png rgba16 Adam7 terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' { abort("png rgba16 Adam7 terminal lease") }
        }
        return
      }
    }
  }
  abort("png rgba16 Adam7 chunk drain unreachable")
}

///| The narrow and all-strategy caller-buffered selectors match their fresh
/// eager Adam7 equivalents, then every compression/filter pair survives the
/// existing hostile caller-owned schedules.
test "PNG RGBA16 Adam7 chunk parity and hostile schedules" {
  let narrow_image = png_stream_rgba16_adam7_image()
  let narrow_eager = png_stream_rgba16_eager_with_all_strategies(
    narrow_image, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    PngInterlaceStrategy::Adam7,
  )
  let narrow = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_rgba16_with_interlace_strategy(
      narrow_image.view(), PngInterlaceStrategy::Adam7,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  if narrow != narrow_eager || narrow[24] != b'\x10' || narrow[25] != b'\x06' ||
    narrow[28] != b'\x01' {
    abort("png rgba16 Adam7 narrow selector")
  }
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      png_rgba16_adam7_chunk_drain(
        png_stream_rgba16_adam7_image(), strategy, filter_strategy, [0UL, 1UL],
      )
      png_rgba16_adam7_chunk_drain(
        png_stream_rgba16_adam7_image(), strategy, filter_strategy, [1UL],
      )
      png_rgba16_adam7_chunk_drain(
        png_stream_rgba16_adam7_image(), strategy, filter_strategy,
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
      )
    }
  }
}

///| Adam7 RGBA16 construction remains atomic and a released destination is a
/// shared zero-write typed terminal for this new selector family.
test "PNG RGBA16 Adam7 chunk admission and terminal lifecycle" {
  let eager_budget = png_stream_test_budget(work=1UL)
  let eager_before = eager_budget.remaining()
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager = @codec.ImageEncoder::encode(
    PngEncoder::new_rgba16_with_all_strategies(
      PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    ),
    png_stream_rgba16_adam7_image().view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(work=1UL), eager_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  let chunk_budget = png_stream_test_budget(work=1UL)
  let chunk_before = chunk_budget.remaining()
  let chunk = PngChunkEncoder::new_rgba16_with_all_strategies(
    png_stream_rgba16_adam7_image().view(), PngCompressionStrategy::Stored,
    PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(work=1UL), chunk_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if writer.position() != 0UL || !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) ||
    !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) ||
    !png_chunk_test_same_error(eager, chunk) {
    abort("png rgba16 Adam7 atomic admission")
  }
  let encoder = PngChunkEncoder::new_rgba16_with_all_strategies(
    png_stream_rgba16_adam7_image().view(), PngCompressionStrategy::Stored,
    PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) { lease.release(); Ok(encoder.pull(lease)) }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png rgba16 Adam7 released lease outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png rgba16 Adam7 released lease replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png rgba16 Adam7 released lease terminal")
  }
}

///| A post-construction RGBA16 Adam7 source mutation exposes no further lease
/// byte and replays the same shared typed terminal.
test "PNG RGBA16 Adam7 chunk mutation terminal is sticky" {
  let image = png_stream_rgba16_adam7_image()
  let encoder = PngChunkEncoder::new_rgba16_with_all_strategies(
    image.view(), PngCompressionStrategy::Stored,
    PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png rgba16 Adam7 mutation prefix") }
  }
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xff')
  }).unwrap()
  let accepted_total = prefix.length().to_uint64()
  let first = png_chunk_test_owner(7UL, fill=b'Z')
  let failed = first.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let error = match failed.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png rgba16 Adam7 mutation exposed output")
  }
  let later = png_chunk_test_owner(7UL, fill=b'Z')
  let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png rgba16 Adam7 mutation replay")
  }
  if failed.written() != 0UL || failed.total_written() != accepted_total ||
    replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) ||
    first.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png rgba16 Adam7 mutation sticky terminal")
  }
}

///|
fn png_chunk_test_drain(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  png_chunk_test_drain_encoder(encoder, schedule)
}

///| Combined Adaptive construction has the same accepted-prefix ownership,
/// zero-capacity turns, eager parity, and sticky terminal behavior as the
/// shared caller-buffered machine.
test "PNG adaptive combined chunk routes" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for image in [
      png_stream_test_dynamic_corpus_image(3UL, width=2UL),
      png_stream_test_dynamic_corpus_image(4UL, width=2UL),
    ] {
      let eager = png_stream_test_eager_with_strategies(
        image, strategy, PngFilterStrategy::Adaptive,
      )
      let encoder = PngChunkEncoder::new_with_strategies(
        image.view(), strategy, PngFilterStrategy::Adaptive,
        png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let chunked = png_chunk_test_drain_encoder(
        encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
      png_stream_test_fixed_or_stored_corpus_decode_matches_source(chunked, image)
    }
  }
}

test "PNG filter strategy chunk frozen compatibility vectors" {
  let gray = png_stream_gray8_image(b"\x7f")
  let gray_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x00\x00\x00\x00\x3a\x7e\x9b\x55\x00\x00\x00\x0dIDAT\x78\x01\x01\x02\x00\xfd\xff\x00\x7f\x00\x81\x00\x80\x7c\x4b\x6c\xa3\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let gray_default = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray8(
    gray.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let gray_configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray8_with_strategies(
    gray.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let gray_adaptive = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray8_with_filter_strategy(
    gray.view(), PngFilterStrategy::Adaptive,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  for bytes in [gray_default, gray_configured, gray_adaptive] {
    inspect(bytes == gray_stored && bytes[28] == b'\x00', content="true")
  }

  let gray16 = png_stream_gray16_image()
  let gray16_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x10\x00\x00\x00\x00\x81\xd9\xfc\x15\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x12\x34\xab\xcd\x03\x0c\x01\xbf\x4c\x32\xd4\xc3\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let gray16_default = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray16(
    gray16.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let gray16_configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray16_with_strategies(
    gray16.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  for bytes in [gray16_default, gray16_configured] {
    inspect(bytes == gray16_stored && bytes[28] == b'\x00', content="true")
  }

  let gray_alpha16 = png_stream_graya16_image()
  let graya16_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x10\x04\x00\x00\x00\x0e\xbbkB\x00\x00\x00\x14IDATx\x01\x01\x09\x00\xf6\xff\x00\x124\xa7\xc5\xbe\x0fZv\x0e\x17\x03Pk\x88\xb2u\x00\x00\x00\x00IEND\xaeB`\x82"
  let graya16_default = png_chunk_test_drain_encoder(PngChunkEncoder::new_graya16(
    gray_alpha16.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let graya16_configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_graya16_with_strategies(
    gray_alpha16.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  for bytes in [graya16_default, graya16_configured] {
    inspect(bytes == graya16_stored && bytes[28] == b'\x00', content="true")
  }

  let gray_alpha = png_stream_graya8_image()
  let gray_alpha_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x08\x04\x00\x00\x00\x5e\x2b\xb7\x01\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x13\xa7\xd2\x4c\x04\x36\x01\xd9\xee\xe9\xe1\x45\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let gray_alpha_default = png_chunk_test_drain_encoder(PngChunkEncoder::new_graya8(
    gray_alpha.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let gray_alpha_configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_graya8_with_strategies(
    gray_alpha.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  for bytes in [gray_alpha_default, gray_alpha_configured] {
    inspect(bytes == gray_alpha_stored && bytes[28] == b'\x00', content="true")
  }

  let rgb = png_stream_test_image(3UL)
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let default = png_chunk_test_drain_encoder(PngChunkEncoder::new(
    rgb.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_compression_strategy(
    rgb.view(), PngCompressionStrategy::Stored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let adaptive = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_filter_strategy(
    rgb.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  for bytes in [default, configured, adaptive] {
    inspect(bytes == rgb_stored && bytes[28] == b'\x00', content="true")
    png_stream_test_fixed_or_stored_corpus_decode_matches_source(bytes, rgb)
  }

  let rgba = png_stream_test_image(4UL)
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let rgba_adaptive = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_filter_strategy(
    rgba.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(rgba_adaptive == rgba_stored && rgba_adaptive[28] == b'\x00', content="true")
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(rgba_adaptive, rgba)

  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let fixed_bytes = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    let dynamic_fallback = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(fixed_bytes == fixed && dynamic_fallback == fixed, content="true")
    png_stream_test_fixed_or_stored_corpus_decode_matches_source(fixed_bytes, image)
    png_stream_test_fixed_or_stored_corpus_decode_matches_source(dynamic_fallback, image)
  }

}

///|
test "PNG compression strategy chunk factories encode supported images" {
  for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
    let image = png_stream_test_image(3UL)
    let encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), strategy, png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap()
    let bytes = png_chunk_test_drain_encoder(encoder, [1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(bytes[0] == b'\x89' && bytes[1] == b'P', content="true")
    let owner = @bytes.OwnedBytes::from_bytes(
      bytes, png_stream_test_budget(work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x00', content="true")
  }
}

///|
test "PNG fixed-or-stored configured eager and chunk output retain exact hostile-capacity parity" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let eager = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::FixedOrStored)
    let encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::FixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(chunked == eager, content="true")
    inspect((eager[43] & b'\x07') == b'\x03', content="true")
  }
}

///|
test "PNG dynamic strategy chunk factory freezes compatibility routes" {
  let rgb = png_stream_test_image(3UL)
  let rgb_stored = png_chunk_test_drain(rgb, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgb_stored ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let rgba = png_stream_test_image(4UL)
  let rgba_stored = png_chunk_test_drain(rgba, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgba_stored ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let fixed_encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::FixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let dynamic_encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let fixed_bytes = png_chunk_test_drain_encoder(fixed_encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    let dynamic_bytes = png_chunk_test_drain_encoder(dynamic_encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(fixed_bytes == fixed, content="true")
    inspect(dynamic_bytes == fixed, content="true")
    inspect((fixed[43] & b'\x07') == b'\x03', content="true")
  }
}

///| The public strict-winner evidence freezes its complete PNG bytes, checks
///| BTYPE=10 and complete-input decode, and retains hostile caller-buffer parity.
test "PNG dynamic strict winner decodes completely through public API" {
  let image = png_stream_test_dynamic_image()
  let eager = png_stream_test_eager_with_strategy(
    image, PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  inspect(
    eager ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x80\x00\x00\x00\x01\x08\x02\x00\x00\x00\x99\xb0\x31\xe1\x00\x00\x00\x91IDAT\x78\x01\x05\xc0\x01\x01\x00\x00\x00\xc1\xb0\x73\xfd\x33\x1b\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x01\x40\x1d\x02\xff\xd8\xa1\x67\x97\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  inspect((eager[43] & b'\x07') == b'\x05', content="true")
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(chunked == eager, content="true")
  let owner = @bytes.OwnedBytes::from_bytes(eager, png_stream_test_budget(work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let expected = image.view()
  inspect(restored.width() == expected.width() && restored.height() == expected.height(), content="true")
  for x = 0UL; x < expected.width(); x = x + 1UL {
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      inspect(restored.get_byte(x, 0UL, channel).unwrap() == expected.get_byte(x, 0UL, channel).unwrap(), content="true")
    }
  }
}

///| Eager and caller-buffered adapters acknowledge the same scalar Dynamic
/// machine, including zero-capacity pulls.
test "PNG dynamic eager and chunk output have exact hostile-capacity parity" {
  let image = png_stream_test_dynamic_image()
  let eager = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::DynamicOrFixedOrStored)
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 4UL, 2UL, 7UL]).unwrap()
  inspect(chunked == eager && (eager[43] & b'\x07') == b'\x05', content="true")
}

///| Finished is sticky and a subsequent zero-capacity caller lease has no work
/// to acknowledge.
test "PNG dynamic configured sticky terminals preserve leases" {
  let image = png_stream_test_dynamic_image()
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  ignore(png_chunk_test_drain_encoder(encoder, [1UL]).unwrap())
  let owner = png_chunk_test_owner(1UL, fill=b'\xaa')
  let result = owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(result.written() == 0UL && result.outcome() is PngChunkPullOutcome::Finished, content="true")
  inspect(owner.view().get(0UL).unwrap() == b'\xaa', content="true")
}

///| The 128-pixel periodic RGB8 fixture has `total_length == 202UL` and
/// `matcher_work == 4593UL` in the Task 1 white-box evidence, so its selected
/// Dynamic admission ledger is `202UL + 4593UL + 4593UL == 9388UL`.
test "PNG dynamic public exact and one-less admission is atomic" {
  let fixture_work = 9388UL
  let image = png_stream_test_dynamic_image()

  let eager_budget = png_stream_test_budget(work=fixture_work)
  let eager_before = eager_budget.remaining()
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), eager_budget, @error.Diagnostics::new(),
  ).unwrap())
  inspect(eager_budget.remaining().work(), content="0")
  inspect(
    eager_before.bytes() == eager_budget.remaining().bytes() &&
      eager_before.allocations() == eager_budget.remaining().allocations() &&
      eager_before.allocation_size() == eager_budget.remaining().allocation_size() &&
      eager_before.width() == eager_budget.remaining().width() &&
      eager_before.height() == eager_budget.remaining().height() &&
      eager_before.pixels() == eager_budget.remaining().pixels() &&
      eager_before.depth() == eager_budget.remaining().depth(), content="true",
  )

  let chunk_budget = png_stream_test_budget(work=fixture_work)
  let chunk_before = chunk_budget.remaining()
  ignore(PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), chunk_budget, @error.Diagnostics::new(),
  ).unwrap())
  inspect(chunk_budget.remaining().work(), content="0")
  inspect(
    chunk_before.bytes() == chunk_budget.remaining().bytes() &&
      chunk_before.allocations() == chunk_budget.remaining().allocations() &&
      chunk_before.allocation_size() == chunk_budget.remaining().allocation_size() &&
      chunk_before.width() == chunk_budget.remaining().width() &&
      chunk_before.height() == chunk_budget.remaining().height() &&
      chunk_before.pixels() == chunk_budget.remaining().pixels() &&
      chunk_before.depth() == chunk_budget.remaining().depth(), content="true",
  )

  let eager_one_less_budget = png_stream_test_budget(work=fixture_work - 1UL)
  let eager_one_less_before = eager_one_less_budget.remaining()
  let eager_writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager_error = @codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
    image.view(), eager_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), eager_one_less_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(eager_writer.position(), content="0")
  inspect(png_fixed_or_stored_same_remaining(eager_one_less_before, eager_one_less_budget.remaining()), content="true")

  let chunk_one_less_budget = png_stream_test_budget(work=fixture_work - 1UL)
  let chunk_one_less_before = chunk_one_less_budget.remaining()
  let candidate = png_chunk_test_owner(7UL, fill=b'Z')
  let chunk_error = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), chunk_one_less_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(png_chunk_test_same_error(eager_error, chunk_error), content="true")
  inspect(png_fixed_or_stored_same_remaining(chunk_one_less_before, chunk_one_less_budget.remaining()), content="true")
  for index = 0UL; index < 7UL; index = index + 1UL {
    inspect(candidate.view().get(index).unwrap() == b'Z', content="true")
  }
}

///| Public eager and caller-buffered Adaptive fallback routes agree on their
///| smallest admitted work budget and leave rejected construction atomic.
test "PNG adaptive Dynamic decline public admission is atomic" {
  let image = png_stream_test_flat_image(3UL, 32UL)
  let mut rejected = 0UL
  let mut exact = 1UL
  while PngChunkEncoder::new_with_strategies(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      PngFilterStrategy::Adaptive, png_stream_test_limits(),
      png_stream_test_budget(work=exact), @error.Diagnostics::new(),
    ) is Err(_) {
    rejected = exact
    exact = exact * 2UL
  }
  while rejected + 1UL < exact {
    let middle = rejected + ((exact - rejected) / 2UL)
    match PngChunkEncoder::new_with_strategies(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      PngFilterStrategy::Adaptive, png_stream_test_limits(),
      png_stream_test_budget(work=middle), @error.Diagnostics::new(),
    ) {
      Ok(_) => exact = middle
      Err(_) => rejected = middle
    }
  }
  let eager_budget = png_stream_test_budget(work=exact)
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), eager_budget, @error.Diagnostics::new(),
  ).unwrap())
  let eager_bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    eager_bytes.push(writer.view().get(index).unwrap())
  }
  let eager = Bytes::from_array(eager_bytes)
  let chunk_budget = png_stream_test_budget(work=exact)
  let encoder = PngChunkEncoder::new_with_strategies(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_stream_test_limits(), chunk_budget,
    @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 4UL, 2UL, 7UL]).unwrap()
  inspect(chunked == eager && eager_budget.remaining().work() == 0UL && chunk_budget.remaining().work() == 0UL, content="true")
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager, image)
  let rejected_budget = png_stream_test_budget(work=exact - 1UL)
  let rejected_before = rejected_budget.remaining()
  let rejected_writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager_error = @codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive),
    image.view(), rejected_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), rejected_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(rejected_writer.position() == 0UL && png_fixed_or_stored_same_remaining(rejected_before, rejected_budget.remaining()), content="true")
  let chunk_budget = png_stream_test_budget(work=exact - 1UL)
  let chunk_before = chunk_budget.remaining()
  let chunk_error = PngChunkEncoder::new_with_strategies(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_stream_test_limits(), chunk_budget,
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(png_chunk_test_same_error(eager_error, chunk_error) && png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()), content="true")
}

///|
test "PNG dynamic replay drift is sticky through chunk encoder" {
  let image = png_stream_test_dynamic_image()
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  image.with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'Z') }).unwrap()
  let scratch : Array[Byte] = []
  let mut turns = 0UL
  let mut first_error : Option[@error.CoreError] = None
  let mut first_total = 0UL
  while turns < 1024UL {
    let pulled = png_chunk_test_pull(encoder, 1UL, scratch)
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turns = turns + 1UL
      PngChunkPullOutcome::Finished => panic()
      PngChunkPullOutcome::Failed(error) => {
        first_error = Some(error)
        first_total = pulled.total_written()
        break
      }
    }
  }
  let first = match first_error {
    Some(error) => error
    None => panic()
  }
  inspect(first.category() == @error.ErrorCategory::State, content="true")
  inspect(first.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(first.context() == Some("png-encode-dynamic-replay-drift"), content="true")
  let later = png_chunk_test_owner(7UL, fill=b'Z')
  let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written() == first_total, content="true")
  inspect(png_chunk_test_same_error(first, replay_error), content="true")
  for index = 0UL; index < 7UL; index = index + 1UL {
    inspect(later.view().get(index).unwrap() == b'Z', content="true")
  }
}

///|
test "PNG fixed-or-stored corpus evidence is deterministic, valid, never-larger, and wins flat RGB8/RGBA8" {
  png_stream_test_fixed_or_stored_corpus_case(png_stream_test_flat_image(3UL, 32UL))
  png_stream_test_fixed_or_stored_corpus_case(png_stream_test_flat_image(4UL, 32UL))
}

///|
test "PNG dynamic corpus evidence is deterministic, strictly wins periodic RGB8/RGBA8, and decodes completely" {
  png_stream_test_dynamic_corpus_case(png_stream_test_dynamic_corpus_image(3UL))
  png_stream_test_dynamic_corpus_case(png_stream_test_dynamic_corpus_image(4UL))
}

///|
test "PNG compression strategy legacy chunk constructors retain frozen stored bytes" {
  let rgb = png_stream_test_image(3UL)
  let rgb_bytes = png_chunk_test_drain(rgb, [1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgb_bytes ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let rgba = png_stream_test_image(4UL)
  let rgba_bytes = png_chunk_test_drain(rgba, [1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgba_bytes ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
}

///| Public Adam7 chunk output must retain its zero-capacity no-op, agree with
///| eager bytes under one-byte and ragged drains, and decode exactly.
fn png_adam7_public_chunk_fidelity(
  source : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
) -> Unit {
  let eager = png_stream_test_eager_with_all_strategies(
    source, strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  if eager[28] != b'\x01' { abort("png adam7 eager interlace") }

  let one_byte_encoder = PngChunkEncoder::new_with_all_strategies(
    source.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) {
    Ok(one_byte_encoder.pull(lease))
  }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) {
    abort("png adam7 zero-capacity progress")
  }
  let one_byte = png_chunk_test_drain_encoder(one_byte_encoder, [1UL]).unwrap()
  if one_byte != eager || one_byte[28] != b'\x01' {
    abort("png adam7 one-byte eager identity")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(one_byte, source)

  let ragged_encoder = PngChunkEncoder::new_with_all_strategies(
    source.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let ragged = png_chunk_test_drain_encoder(
    ragged_encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
  ).unwrap()
  if ragged != eager || ragged[28] != b'\x01' {
    abort("png adam7 ragged eager identity")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(ragged, source)
}

///| Frozen legacy and explicit-None routes remain method 0 while generated
///| multi-pass Adam7 output stays byte-identical to the eager public route.
test "PNG Adam7 public chunk fidelity, hostile identity, and frozen None compatibility" {
  let rgb = png_stream_test_image(3UL)
  let rgba = png_stream_test_image(4UL)
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  for image in [rgb, rgba] {
    let expected = if image.view().format().channel_count() == 3UL {
      rgb_stored
    } else {
      rgba_stored
    }
    for encoder in [
      PngChunkEncoder::new(image.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_compression_strategy(image.view(), PngCompressionStrategy::Stored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_filter_strategy(image.view(), PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_filter_strategy(image.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_interlace_strategy(image.view(), PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
    ] {
      let bytes = png_chunk_test_drain_encoder(
        encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
      ).unwrap()
      inspect(bytes == expected && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    for encoder in [
      PngChunkEncoder::new_with_compression_strategy(image.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_compression_strategy(image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
    ] {
      let bytes = png_chunk_test_drain_encoder(
        encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
      ).unwrap()
      inspect(bytes == fixed && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let source = png_stream_test_image(channels, width=5UL, height=5UL)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      png_adam7_public_chunk_fidelity(source, strategy)
    }
  }
}

///|
test "PNG encode machine eager oracle remains canonical for RGB and RGBA" {
  for image in [png_stream_test_image(3UL), png_stream_test_image(4UL)] {
    let eager = png_stream_test_eager(image)
    let colour_type = if image.view().format().channel_count() == 3UL { b'\x02' } else { b'\x06' }
    inspect(eager[0] == b'\x89' && eager[1] == b'P', content="true")
    inspect(eager[25] == colour_type, content="true")
  }
}

///|
test "PNG encode machine stores the exact multi-block length formula" {
  let scanlines = 65539UL
  let blocks = 2UL
  inspect(scanlines + 6UL + blocks * 5UL + 57UL, content="65612")
}

///|
test "PNG chunk encoder reports empty, one-byte, and irregular exact progress" {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL)
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(zero.written(), content="0")
  inspect(zero.total_written(), content="0")
  inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let output : Array[Byte] = []
  let first = png_chunk_test_pull(encoder, 1UL, output)
  inspect(first.written(), content="1")
  inspect(first.total_written(), content="1")
  inspect(first.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let irregular = png_chunk_test_pull(encoder, 3UL, output)
  inspect(irregular.written(), content="3")
  inspect(irregular.total_written(), content="4")
}

///|
test "PNG chunk encoder equals eager bytes for RGB and straight RGBA" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels)
    let eager = png_stream_test_eager(image)
    let chunked = png_chunk_test_drain(image, [1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(chunked == eager, content="true")
  }
}

///|
test "PNG chunk encoder retains no completed caller output lease" {
  let image = png_stream_test_image(3UL)
  let eager = png_stream_test_eager(image)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let first_owner = png_chunk_test_owner(1UL)
  let first = first_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(first.written(), content="1")
  let output : Array[Byte] = [first_owner.view().get(0UL).unwrap()]
  first_owner.with_mut(0UL, 1UL, fn(lease) { lease.set(0UL, b'X') }).unwrap()
  let mut turn = 0
  while turn < 1024 {
    let result = png_chunk_test_pull(encoder, 2UL, output)
    match result.outcome() {
      PngChunkPullOutcome::Finished => break
      PngChunkPullOutcome::Failed(_) => panic()
      PngChunkPullOutcome::NeedOutput => turn = turn + 1
    }
  }
  inspect(Bytes::from_array(output) == eager, content="true")
  let terminal_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let terminal = terminal_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(terminal.written(), content="0")
  inspect(terminal.total_written() == eager.length().to_uint64(), content="true")
  inspect(terminal.outcome() is PngChunkPullOutcome::Finished, content="true")
  inspect(terminal_owner.view().get(0UL).unwrap() == b'Z', content="true")
}

///|
test "PNG chunk encoder replays the original released-lease failure" {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = owner.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(failed.written(), content="0")
  inspect(failed.total_written(), content="0")
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written(), content="0")
  inspect(replay_error.category() == first_error.category(), content="true")
  inspect(replay_error.code() == first_error.code(), content="true")
  inspect(replay_error.operation() == first_error.operation(), content="true")
  inspect(replay_error.context() == first_error.context(), content="true")
  inspect(replay_error.requested() == first_error.requested(), content="true")
  inspect(replay_error.completed() == first_error.completed(), content="true")
  inspect(replay_error.limit() == first_error.limit(), content="true")
  inspect(replay_owner.view().get(0UL).unwrap() == b'Z', content="true")
}

///|
test "PNG encoder isolated four-target evidence preserves hostile output and preflight parity" {
  png_chunk_test_four_target_evidence()
}

///|
fn png_chunk_test_same_error(
  left : @error.CoreError,
  right : @error.CoreError,
) -> Bool {
  left.category() == right.category() &&
    left.code() == right.code() &&
    left.operation() == right.operation() &&
    left.context() == right.context() &&
    left.requested() == right.requested() &&
    left.completed() == right.completed() &&
    left.limit() == right.limit()
}

///|
fn png_chunk_test_eager_error(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> @error.CoreError {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true, preserve_opaque_metadata=false,
    ), limits, budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if writer.position() != 0UL { abort("png chunk eager preflight output") }
  error
}

///|
fn png_chunk_test_drain_hostile_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
) -> Bytes {
  let eager = png_stream_test_eager_with_strategies(image, strategy, filter_strategy)
  let encoder = PngChunkEncoder::new_with_strategies(
    image.view(), strategy, filter_strategy, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 1024UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity)
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png chunk hostile progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    if turn == 0UL && capacity == 0UL &&
      (pulled.written() != 0UL || pulled.total_written() != 0UL ||
        !(pulled.outcome() is PngChunkPullOutcome::NeedOutput)) {
      abort("png chunk empty output")
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png chunk hostile output failure")
      PngChunkPullOutcome::Finished => {
        let terminal_total = pulled.total_written()
        for _ in [0, 1] {
          let terminal_owner = png_chunk_test_owner(7UL, fill=b'Z')
          let terminal = terminal_owner.with_mut(0UL, 7UL, fn(lease) {
            Ok(encoder.pull(lease))
          }).unwrap()
          if terminal.written() != 0UL || terminal.total_written() != terminal_total ||
            !(terminal.outcome() is PngChunkPullOutcome::Finished) {
            abort("png chunk terminal progress")
          }
          for index = 0UL; index < 7UL; index = index + 1UL {
            if terminal_owner.view().get(index).unwrap() != b'Z' {
              abort("png chunk terminal mutation")
            }
          }
        }
        let bytes = Bytes::from_array(output)
        if bytes != eager { abort("png chunk eager parity") }
        return bytes
      }
    }
  }
  abort("png chunk hostile drain unreachable")
}

///| Retain the legacy Stored/filter-None hostile route through the generalized
///| public-factory drain.
fn png_chunk_test_drain_hostile(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Bytes {
  png_chunk_test_drain_hostile_with_strategies(
    image, PngCompressionStrategy::Stored, PngFilterStrategy::None, schedule,
  )
}

///|
fn png_stream_adaptive_evidence_image(
  channels : UInt64,
  width : UInt64,
  height : UInt64,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, height,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(
      0UL, channels * width * height, channels * width, channels * width,
      1UL, 1UL, width, height,
    ).unwrap()],
    channels * width * height,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
}

///| CandidateSelection winner R1, duplicated locally for public chunk evidence.
fn png_stream_adaptive_evidence_rgb8_horizontal_image() -> @storage.OwnedImage {
  let image = png_stream_adaptive_evidence_image(3UL, 32UL, 1UL)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < 32UL; x = x + 1UL {
      view.set_byte(x, 0UL, 0UL, x.to_byte()).unwrap()
      view.set_byte(x, 0UL, 1UL, (x + 64UL).to_byte()).unwrap()
      view.set_byte(x, 0UL, 2UL, (x + 128UL).to_byte()).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///| CandidateSelection winner A1, duplicated locally for public chunk evidence.
fn png_stream_adaptive_evidence_straight_rgba8_vertical_image() -> @storage.OwnedImage {
  let image = png_stream_adaptive_evidence_image(4UL, 16UL, 8UL)
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 8UL; y = y + 1UL {
      for x = 0UL; x < 16UL; x = x + 1UL {
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
test "PNG adaptive filter evidence RGB8 horizontal chunk exactly matches eager and decodes completely" {
  let source = png_stream_adaptive_evidence_rgb8_horizontal_image()
  let bytes = png_chunk_test_drain_hostile_with_strategies(
    source, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  )
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(bytes, source)
}

///|
test "PNG adaptive filter evidence straight-RGBA8 vertical chunk exactly matches eager and decodes completely" {
  let source = png_stream_adaptive_evidence_straight_rgba8_vertical_image()
  let bytes = png_chunk_test_drain_hostile_with_strategies(
    source, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  )
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(bytes, source)
}

///|
fn png_chunk_test_preflight_parity() -> Unit {
  let image = png_stream_test_image(3UL)
  let output_limits = png_stream_test_limits(output=71UL)
  let eager_output = png_chunk_test_eager_error(
    image, output_limits, png_stream_test_budget(),
  )
  let output_budget = png_stream_test_budget()
  let output_before = output_budget.remaining().work()
  let chunk_output = PngChunkEncoder::new(
    image.view(), output_limits, output_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_output, chunk_output) ||
    output_budget.remaining().work() != output_before {
    abort("png chunk output preflight parity")
  }

  let work_limits = png_stream_test_limits()
  let eager_work = png_chunk_test_eager_error(
    image, work_limits, png_stream_test_budget(work=71UL),
  )
  let work_budget = png_stream_test_budget(work=71UL)
  let work_before = work_budget.remaining().work()
  let chunk_work = PngChunkEncoder::new(
    image.view(), work_limits, work_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_work, chunk_work) ||
    work_budget.remaining().work() != work_before {
    abort("png chunk work preflight parity")
  }

  let retained = png_stream_test_image(3UL, include_opaque=true)
  let opaque_limits = png_stream_test_limits()
  let eager_opaque = png_chunk_test_eager_error(
    retained, opaque_limits, png_stream_test_budget(),
  )
  let opaque_budget = png_stream_test_budget()
  let opaque_before = opaque_budget.remaining().work()
  let chunk_opaque = PngChunkEncoder::new(
    retained.view(), opaque_limits, opaque_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_opaque, chunk_opaque) ||
    opaque_budget.remaining().work() != opaque_before {
    abort("png chunk opaque preflight parity")
  }
}

///|
fn png_chunk_test_released_lease_terminal() -> Unit {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = owner.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png chunk released lease outcome")
  }
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png chunk released lease replay")
  }
  if failed.written() != 0UL || replay.written() != 0UL ||
    failed.total_written() != 0UL || replay.total_written() != 0UL ||
    !png_chunk_test_same_error(first_error, replay_error) ||
    replay_owner.view().get(0UL).unwrap() != b'Z' {
    abort("png chunk released lease terminal")
  }
}

///|
fn png_chunk_test_four_target_evidence() -> Unit {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels)
    ignore(png_chunk_test_drain_hostile(image, [0UL, 1UL]))
    ignore(png_chunk_test_drain_hostile(image, [1UL]))
    ignore(png_chunk_test_drain_hostile(
      image, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
    ))
  }
  png_chunk_test_released_lease_terminal()
  png_chunk_test_preflight_parity()
}

///|
fn png_fixed_or_stored_same_remaining(
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

///|
fn png_fixed_or_stored_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
  width? : UInt64 = 70000UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=width, max_height=8UL, max_pixels=560000UL, max_work=work,
  )
}

///|
fn png_fixed_or_stored_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  let eager_budget = png_stream_test_budget(work=work)
  let eager_before = eager_budget.remaining()
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager = @codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    limits, eager_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if writer.position() != 0UL {
    abort("png fixed-or-stored eager admission exposed output")
  }
  if !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
    abort("png fixed-or-stored eager admission changed budget")
  }
  let chunk_budget = png_stream_test_budget(work=work)
  let chunk_before = chunk_budget.remaining()
  let chunk = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    limits, chunk_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager, chunk) {
    abort("png fixed-or-stored public admission mismatch")
  }
  if !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
    abort("png fixed-or-stored chunk admission changed budget")
  }
}

///| All combined routes use the shared constructor, so every rejection remains
/// atomic before an eager writer byte or caller-owned output lease is exposed.
fn png_adaptive_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let eager_budget = png_stream_test_budget(work=work)
    let eager_before = eager_budget.remaining()
    let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
    let eager = @codec.ImageEncoder::encode(
      PngEncoder::new_with_strategies(strategy, PngFilterStrategy::Adaptive),
      image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      limits, eager_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if writer.position() != 0UL ||
      !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
      abort("png adaptive combined eager admission")
    }
    let chunk_budget = png_stream_test_budget(work=work)
    let chunk_before = chunk_budget.remaining()
    let untouched_lease = png_chunk_test_owner(7UL, fill=b'Z')
    let chunk = PngChunkEncoder::new_with_strategies(
      image.view(), strategy, PngFilterStrategy::Adaptive,
      limits, chunk_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if !png_chunk_test_same_error(eager, chunk) ||
      !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
      abort("png adaptive combined chunk admission")
    }
    for index = 0UL; index < 7UL; index = index + 1UL {
      if untouched_lease.view().get(index).unwrap() != b'Z' {
        abort("png adaptive combined admission exposed lease")
      }
    }
  }
}

///| Gray8 strategy surfaces share the same admission ledger as legacy routes;
/// every rejection occurs before either eager output or a caller lease exists.
fn png_gray8_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_gray8_with_strategies(strategy, filter_strategy),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png gray8 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_gray8_with_strategies(
        image.view(), strategy, filter_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png gray8 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png gray8 admission exposed lease")
        }
      }
    }
  }
}

///| Gray16 must use the same preflight transaction for every bounded strategy
/// pair: rejection cannot write eager bytes, reserve caller budget, or expose a
/// caller-owned lease.
fn png_gray16_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png gray16 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_gray16_with_strategies(
        image.view(), strategy, filter_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png gray16 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png gray16 admission exposed lease")
        }
      }
    }
  }
}

///| Gray+Alpha8 shares the bounded profile-aware transaction for every
/// compression/filter pair: rejection cannot expose eager output, reserve
/// caller budget, or mutate a caller-owned lease.
fn png_graya8_combined_public_reject(
  image : @storage.OwnedImage,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_graya8_with_all_strategies(
          strategy, filter_strategy, interlace_strategy,
        ),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png graya8 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_graya8_with_all_strategies(
        image.view(), strategy, filter_strategy, interlace_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png graya8 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png graya8 admission exposed lease")
        }
      }
    }
  }
}

///| GrayAlpha16 must use the same preflight transaction for every bounded
/// strategy pair: rejection cannot write eager bytes, reserve caller budget,
/// or expose a caller-owned lease.
fn png_graya16_combined_public_reject(
  image : @storage.OwnedImage,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_graya16_with_all_strategies(
          strategy, filter_strategy, interlace_strategy,
        ),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png graya16 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_graya16_with_all_strategies(
        image.view(), strategy, filter_strategy, interlace_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png graya16 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png graya16 admission exposed lease")
        }
      }
    }
  }
}

///|
fn png_fixed_or_stored_replay_image() -> @storage.OwnedImage {
  let image = png_stream_test_image(3UL, width=5UL)
  let pixels = [
    b'\x0a', b'\x0c', b'\x0c', b'\x0a', b'\x0a', b'\x0c', b'\x0b', b'\x0c', b'\x0a',
    b'\x0c', b'\x0a', b'\x0b', b'\x0a', b'\x0c', b'\x0a',
  ]
  image.with_mut_view(fn(view) {
    for index = 0UL; index < 15UL; index = index + 1UL {
      view.set_byte(index / 3UL, 0UL, index % 3UL, pixels[index.to_int()]).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
test "PNG fixed-or-stored public admission is atomic" {
  png_fixed_or_stored_public_reject(
    png_stream_test_image(3UL, include_opaque=true), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_image(3UL, width=2UL), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(), 1UL,
  )
}

///| Capability, geometry, output, work, and budget rejections match between
/// eager and caller-buffered Adaptive combined factories before output exists.
test "PNG adaptive combined admission is atomic" {
  png_adaptive_combined_public_reject(
    png_stream_test_image(3UL, include_opaque=true), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_image(3UL, width=2UL), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(), 1UL,
  )
}

///| Gray8 uses the same capability, geometry, output, work, and budget
/// rejection ordering for every compression/filter combination.
test "PNG Gray8 strategy admission is atomic" {
  png_gray8_combined_public_reject(
    png_stream_test_image(3UL), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(b"\x01\x02", width=2UL),
    png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(Bytes::from_array(Array::make(32, b'\xaa')), width=32UL),
    png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(Bytes::from_array(Array::make(32, b'\xaa')), width=32UL),
    png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(Bytes::from_array(Array::make(32, b'\xaa')), width=32UL),
    png_fixed_or_stored_limits(), 1UL,
  )
}

///| All Gray16 strategy pairs reject capability, geometry, output, work, and
/// budget failures before any observable eager or caller-buffered state.
test "PNG Gray16 strategy admission is atomic" {
  png_gray16_combined_public_reject(
    png_stream_test_image(3UL), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(), 1UL,
  )
}

///| All Gray+Alpha8 strategy pairs reject capability, geometry, output, work,
/// and budget failures before eager output or a caller-buffered lease exists.
test "PNG GrayAlpha8 strategy admission is atomic" {
  png_graya8_combined_public_reject(
    png_stream_test_image(3UL), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(), 1UL,
  )
}

///| GrayAlpha8 Adam7 admission retains the same profile-aware preflight
/// transaction for each incompatible descriptor and resource rejection.
test "PNG GrayAlpha8 Adam7 strategy admission is atomic" {
  png_graya8_combined_public_reject(
    png_stream_test_image(3UL), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_graya8_combined_public_reject(
    png_stream_graya8_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(), 1UL,
  )
}

///| All legal little-endian GrayAlpha16 strategy pairs reject capability,
/// geometry, output, work, and budget failures before observable eager or
/// caller-buffered state. Big-endian GrayAlpha16 is rejected at descriptor
/// construction and is deliberately not a PNG-admission parity case.
test "PNG GrayAlpha16 strategy admission is atomic" {
  png_graya16_combined_public_reject(
    png_stream_test_image(3UL), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_image(), PngInterlaceStrategy::None,
    png_fixed_or_stored_limits(), 1UL,
  )
}

///| The Adam7 selector remains on the same profile-aware preflight ledger:
/// all six legal strategy pairs must reject invalid admission before eager
/// output, resource charges, or a caller-owned chunk lease can be exposed.
test "PNG GrayAlpha16 Adam7 strategy admission is atomic" {
  png_graya16_combined_public_reject(
    png_stream_test_image(3UL), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_graya16_combined_public_reject(
    png_stream_graya16_adam7_image(), PngInterlaceStrategy::Adam7,
    png_fixed_or_stored_limits(), 1UL,
  )
}

///|
test "PNG fixed-or-stored public replay mismatch is sticky" {
  let image = png_fixed_or_stored_replay_image()
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let ignored : Array[Byte] = []
  let mut prefix = 0UL
  while prefix < 43UL {
    let pull = png_chunk_test_pull(encoder, 1UL, ignored)
    inspect(pull.written(), content="1")
    prefix = prefix + 1UL
  }
  let header = png_chunk_test_pull(encoder, 1UL, ignored)
  inspect(header.written(), content="1")
  inspect((ignored[43] & b'\x07') == b'\x03', content="true")
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 0UL, b'\x00')
  }).unwrap()
  let first = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = first.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(failed.written(), content="0")
  inspect(failed.total_written(), content="44")
  inspect(first_error.category() == @error.ErrorCategory::State, content="true")
  inspect(first_error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(first_error.context() == Some("png-encode-fixed-replay-drift"), content="true")
  inspect(first.view().get(0UL).unwrap() == b'Z', content="true")
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written(), content="44")
  inspect(png_chunk_test_same_error(first_error, replay_error), content="true")
  inspect(later.view().get(0UL).unwrap() == b'Z', content="true")
}

///| Gray8 fixed replay failure preserves accepted progress and repeats the
/// terminal error without touching a later caller-owned lease.
test "PNG Gray8 fixed replay mismatch is sticky" {
  let image = png_stream_gray8_image(b"\x0a\x0c\x0c\x0a\x0a", width=5UL)
  let encoder = PngChunkEncoder::new_gray8_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let accepted : Array[Byte] = []
  while accepted.length() < 43 {
    let pull = png_chunk_test_pull(encoder, 1UL, accepted)
    if pull.written() != 1UL { abort("png gray8 fixed replay prefix") }
  }
  image.with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'\x00') }).unwrap()
  let mut accepted_total = accepted.length().to_uint64()
  let mut first_error : @error.CoreError? = None
  let mut turns = 0UL
  while turns < 1024UL {
    let owner = png_chunk_test_owner(1UL, fill=b'Z')
    let pull = owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    match pull.outcome() {
      PngChunkPullOutcome::NeedOutput => {
        if pull.written() != 1UL || pull.total_written() != accepted_total + 1UL {
          abort("png gray8 fixed replay accepted progress")
        }
        accepted_total = pull.total_written()
        turns = turns + 1UL
      }
      PngChunkPullOutcome::Failed(error) => {
        if pull.written() != 0UL || pull.total_written() != accepted_total ||
          owner.view().get(0UL).unwrap() != b'Z' {
          abort("png gray8 fixed replay failure")
        }
        first_error = Some(error)
        break
      }
      PngChunkPullOutcome::Finished => abort("png gray8 fixed replay did not drift")
    }
  }
  let error = match first_error { Some(value) => value; None => abort("png gray8 fixed replay missing error") }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png gray8 fixed replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) || later.view().get(0UL).unwrap() != b'Z' {
    abort("png gray8 replay was not sticky")
  }
}

///| A Gray16 source mutation after acknowledged framing bytes must invalidate
/// the selected Fixed/Dynamic replay without exposing a terminal byte or
/// changing later caller-owned lease contents.
fn png_gray16_replay_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  expected_header : Byte,
  post_capacity : UInt64,
) -> Unit {
  let encoder = PngChunkEncoder::new_gray16_with_strategies(
    image.view(), strategy, filter_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png gray16 replay prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header {
    abort("png gray16 replay selected wrong deflate route")
  }
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\xff')
  }).unwrap()
  let accepted_total = prefix.length().to_uint64()
  let first = png_chunk_test_owner(post_capacity, fill=b'Z')
  let failed = first.with_mut(0UL, post_capacity, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  let error = match failed.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    PngChunkPullOutcome::NeedOutput => abort("png gray16 replay exposed post-mutation bytes")
    PngChunkPullOutcome::Finished => abort("png gray16 replay did not drift")
  }
  if failed.written() != 0UL || failed.total_written() != accepted_total {
    abort("png gray16 replay first terminal progress")
  }
  for index = 0UL; index < post_capacity; index = index + 1UL {
    if first.view().get(index).unwrap() != b'Z' {
      abort("png gray16 replay first terminal lease")
    }
  }
  let later = png_chunk_test_owner(post_capacity, fill=b'Z')
  let replay = later.with_mut(0UL, post_capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png gray16 replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) || later.view().get(0UL).unwrap() != b'Z' {
    abort("png gray16 replay was not sticky")
  }
}

///| Fixed and Dynamic Gray16 plans replay the same profile-aware U16 wire
/// bytes. The periodic corpus proves the Dynamic BTYPE=10 route rather than
/// silently accepting Fixed fallback.
test "PNG Gray16 Fixed and Dynamic replay mutations are sticky" {
  png_gray16_replay_mutation_is_sticky(
    png_stream_gray16_replay_image(5UL),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, b'\x03', 7UL,
  )
  png_gray16_replay_mutation_is_sticky(
    png_stream_gray16_replay_image(128UL, periodic=true),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, b'\x05', 7UL,
  )
}

///| A GrayAlpha16 source mutation after acknowledged framing bytes must
/// invalidate selected Fixed/Dynamic replay before any caller lease byte is
/// exposed, and the terminal failure must remain sticky.
fn png_graya16_replay_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  expected_header : Byte,
  post_capacity : UInt64,
) -> Unit {
  let encoder = PngChunkEncoder::new_graya16_with_all_strategies(
    image.view(), strategy, filter_strategy, interlace_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png graya16 replay prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header {
    abort("png graya16 replay selected wrong deflate route")
  }
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xff')
  }).unwrap()
  let accepted_total = prefix.length().to_uint64()
  let first = png_chunk_test_owner(post_capacity, fill=b'Z')
  let failed = first.with_mut(0UL, post_capacity, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  let error = match failed.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    PngChunkPullOutcome::NeedOutput => abort("png graya16 replay exposed post-mutation bytes")
    PngChunkPullOutcome::Finished => abort("png graya16 replay did not drift")
  }
  if failed.written() != 0UL || failed.total_written() != accepted_total {
    abort("png graya16 replay first terminal progress")
  }
  for index = 0UL; index < post_capacity; index = index + 1UL {
    if first.view().get(index).unwrap() != b'Z' {
      abort("png graya16 replay first terminal lease")
    }
  }
  let later = png_chunk_test_owner(post_capacity, fill=b'Z')
  let replay = later.with_mut(0UL, post_capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png graya16 replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) {
    abort("png graya16 replay was not sticky")
  }
  for index = 0UL; index < post_capacity; index = index + 1UL {
    if later.view().get(index).unwrap() != b'Z' {
      abort("png graya16 replay sticky terminal lease")
    }
  }
}

///| A GrayAlpha8 mutation after acknowledged framing must fail before the
/// caller's next lease can receive a replay byte.
fn png_graya8_replay_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  expected_header : Byte,
  post_capacity : UInt64,
) -> Unit {
  let encoder = PngChunkEncoder::new_graya8_with_all_strategies(
    image.view(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png graya8 replay prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header {
    abort("png graya8 replay selected wrong deflate route")
  }
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 1UL, b'\xff')
  }).unwrap()
  let accepted_total = prefix.length().to_uint64()
  let first = png_chunk_test_owner(post_capacity, fill=b'Z')
  let failed = first.with_mut(0UL, post_capacity, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  let error = match failed.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    PngChunkPullOutcome::NeedOutput => abort("png graya8 replay exposed post-mutation bytes")
    PngChunkPullOutcome::Finished => abort("png graya8 replay did not drift")
  }
  if failed.written() != 0UL || failed.total_written() != accepted_total {
    abort("png graya8 replay first terminal progress")
  }
  for index = 0UL; index < post_capacity; index = index + 1UL {
    if first.view().get(index).unwrap() != b'Z' {
      abort("png graya8 replay first terminal lease")
    }
  }
  let later = png_chunk_test_owner(post_capacity, fill=b'Z')
  let replay = later.with_mut(0UL, post_capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png graya8 replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) {
    abort("png graya8 replay was not sticky")
  }
  for index = 0UL; index < post_capacity; index = index + 1UL {
    if later.view().get(index).unwrap() != b'Z' {
      abort("png graya8 replay sticky terminal lease")
    }
  }
}

///| Every measured GrayAlpha8 Adam7 compression/filter pair must reject a
/// post-progress mutation before its next caller lease can receive a byte.
test "PNG GrayAlpha8 Adam7 replay mutations are sticky for every strategy pair" {
  png_graya8_replay_mutation_is_sticky(
    png_stream_graya8_adam7_stored_ramp_5x5(),
    PngCompressionStrategy::Stored, PngFilterStrategy::None, b'\x01', 7UL,
  )
  png_graya8_replay_mutation_is_sticky(
    png_stream_graya8_adam7_stored_ramp_5x5(),
    PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, b'\x01', 7UL,
  )
  png_graya8_replay_mutation_is_sticky(
    png_stream_graya8_adam7_fixed_flat_5x5(),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, b'\x03', 7UL,
  )
  png_graya8_replay_mutation_is_sticky(
    png_stream_graya8_adam7_fixed_flat_5x5(),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive, b'\x03', 7UL,
  )
  png_graya8_replay_mutation_is_sticky(
    png_stream_graya8_adam7_dynamic_periodic_128x5(),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, b'\x05', 7UL,
  )
  png_graya8_replay_mutation_is_sticky(
    png_stream_graya8_adam7_dynamic_periodic_128x5(),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive, b'\x05', 7UL,
  )
}

///| Fixed and Dynamic GrayAlpha16 plans validate checked U16 source revision
/// before writing a caller lease, including the four-byte Adaptive filter path.
test "PNG GrayAlpha16 Fixed and Dynamic replay mutations are sticky" {
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(5UL),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    PngInterlaceStrategy::None, b'\x03', 7UL,
  )
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(128UL, periodic=true),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    PngInterlaceStrategy::None, b'\x05', 7UL,
  )
}

///| Every legal Adam7 selector must validate checked U16 replay revisions
/// before copying into a lease. Stored is deliberately included under both
/// filters so this public matrix covers the common pre-write guard.
test "PNG GrayAlpha16 Adam7 replay mutations are sticky for every strategy pair" {
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(5UL),
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
    PngInterlaceStrategy::Adam7, b'\x01', 7UL,
  )
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(5UL),
    PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive,
    PngInterlaceStrategy::Adam7, b'\x01', 7UL,
  )
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(5UL),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None,
    PngInterlaceStrategy::Adam7, b'\x03', 7UL,
  )
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(5UL),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    PngInterlaceStrategy::Adam7, b'\x03', 7UL,
  )
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(128UL, periodic=true),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None,
    PngInterlaceStrategy::Adam7, b'\x05', 7UL,
  )
  png_graya16_replay_mutation_is_sticky(
    png_stream_graya16_replay_image(128UL, periodic=true),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    PngInterlaceStrategy::Adam7, b'\x05', 7UL,
  )
}

///|
test "PNG fixed-or-stored configured sticky terminals preserve leases" {
  let image = png_stream_test_flat_image(3UL, 32UL)
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(zero.written(), content="0")
  inspect(zero.total_written(), content="0")
  inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 1024UL {
    let pulled = png_chunk_test_pull(
      encoder, [1UL, 3UL, 2UL, 5UL][(turn % 4UL).to_int()], output,
    )
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Finished => {
        let terminal_total = pulled.total_written()
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        inspect(replay.written(), content="0")
        inspect(replay.total_written() == terminal_total, content="true")
        inspect(replay.outcome() is PngChunkPullOutcome::Finished, content="true")
        for index = 0UL; index < 7UL; index = index + 1UL {
          inspect(later.view().get(index).unwrap() == b'Z', content="true")
        }
        break
      }
      PngChunkPullOutcome::Failed(_) => panic()
    }
  }
  let failed_encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(failed_encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(failed_encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written() == first.total_written(), content="true")
  inspect(png_chunk_test_same_error(first_error, replay_error), content="true")
  inspect(later.view().get(0UL).unwrap() == b'Z', content="true")
}

///| Adaptive caller-buffered replays may accept framing bytes before a mutable
/// source changes, but must expose no terminal byte and preserve every lease.
fn png_adaptive_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  mutation_x : UInt64,
  mutation_channel : UInt64,
  mutation_value : Byte,
  expected_header : Byte,
  expected_context : String,
) -> Unit {
  let encoder = PngChunkEncoder::new_with_strategies(
    image.view(), strategy, PngFilterStrategy::Adaptive,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png adaptive mutation prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header { abort("png adaptive mutation header") }
  image.with_mut_view(fn(view) {
    view.set_byte(mutation_x, 0UL, mutation_channel, mutation_value)
  }).unwrap()
  let first = png_chunk_test_owner(1UL, fill=b'Z')
  let pull = first.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let error = match pull.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png adaptive mutation exposed post-mutation bytes")
  }
  if error.category() != @error.ErrorCategory::State ||
    error.code() != @error.ErrorCode::InvalidRange || error.context() != Some(expected_context) {
    abort("png adaptive mutation error")
  }
  let accepted_total = prefix.length().to_uint64()
  if pull.written() != 0UL || pull.total_written() != accepted_total ||
    first.view().get(0UL).unwrap() != b'Z' {
    abort("png adaptive mutation first terminal")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => panic()
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) || later.view().get(0UL).unwrap() != b'Z' {
    abort("png adaptive mutation sticky")
  }
}

///|
test "PNG adaptive FixedOrStored public replay mutation is sticky" {
  png_adaptive_mutation_is_sticky(
    png_fixed_or_stored_replay_image(), PngCompressionStrategy::FixedOrStored,
    0UL, 2UL, b'\x0a', b'\x03', "png-encode-fixed-replay-drift",
  )
}

///|
test "PNG adaptive DynamicOrFixedOrStored public replay mutation is sticky" {
  png_adaptive_mutation_is_sticky(
    png_stream_test_dynamic_image(), PngCompressionStrategy::DynamicOrFixedOrStored,
    0UL, 0UL, b'Z', b'\x05', "png-encode-dynamic-replay-drift",
  )
}

///| Adaptive selection retains the Fixed fallback and admits Dynamic only for
/// a strict complete-PNG win.
test "PNG adaptive compression selection retains Fixed equality and Dynamic strict winner" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = png_stream_test_eager_with_strategies(
      image, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    )
    let fallback = png_stream_test_eager_with_strategies(
      image, PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    )
    inspect((fixed[43] & b'\x07') == b'\x03', content="true")
    inspect(fallback == fixed, content="true")
  }
  for channels in [3UL, 4UL] {
    let image = png_stream_test_dynamic_corpus_image(channels)
    let dynamic = png_stream_test_eager_with_strategies(
      image, PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    )
    inspect((dynamic[43] & b'\x07') == b'\x05', content="true")
  }
}

///|
fn png_adam7_stream_same_remaining(
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

///| The public eager and caller-buffered all-strategy constructors must agree
/// on each preflight error, before either one exposes owned output state.
fn png_adam7_stream_admission_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let eager_budget = png_stream_test_budget(work=work)
    let eager_before = eager_budget.remaining()
    let writer = @io.MemoryWriter::new(
      1048576UL, png_stream_test_budget(work=0UL),
    ).unwrap()
    let eager = @codec.ImageEncoder::encode(
      PngEncoder::new_with_all_strategies(
        strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      ), image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      limits, eager_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if writer.position() != 0UL ||
      !png_adam7_stream_same_remaining(eager_before, eager_budget.remaining()) {
      abort("png adam7 eager admission exposed state")
    }

    let chunk_budget = png_stream_test_budget(work=work)
    let chunk_before = chunk_budget.remaining()
    let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
    let chunk = PngChunkEncoder::new_with_all_strategies(
      image.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      limits, chunk_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if !png_chunk_test_same_error(eager, chunk) ||
      !png_adam7_stream_same_remaining(chunk_before, chunk_budget.remaining()) {
      abort("png adam7 chunk admission mismatch")
    }
    for index = 0UL; index < 7UL; index = index + 1UL {
      if sentinel.view().get(index).unwrap() != b'Z' {
        abort("png adam7 chunk admission exposed lease")
      }
    }
  }
}

///| Drain a real multi-pass caller-buffered stream after first proving a zero
/// lease is a no-op.  Only bytes accepted into the lease count toward progress.
fn png_adam7_chunk_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  schedule : Array[UInt64],
) -> Unit {
  let eager = png_stream_test_eager_with_all_strategies(
    image, strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  let encoder = PngChunkEncoder::new_with_all_strategies(
    image.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) {
    abort("png adam7 empty lease progress")
  }
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 2048UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png adam7 accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png adam7 chunk drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png adam7 eager parity") }
        for _ in [0, 1] {
          let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
          let replay = sentinel.with_mut(0UL, 7UL, fn(lease) {
            Ok(encoder.pull(lease))
          }).unwrap()
          if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
            !(replay.outcome() is PngChunkPullOutcome::Finished) {
            abort("png adam7 terminal progress")
          }
          for index = 0UL; index < 7UL; index = index + 1UL {
            if sentinel.view().get(index).unwrap() != b'Z' {
              abort("png adam7 terminal lease mutation")
            }
          }
        }
        return
      }
    }
  }
  abort("png adam7 chunk drain unreachable")
}

///| Five isolated all-strategy Adam7 rejection modes preserve no chunk encoder,
/// no lease contents, and no caller budget state for both supported profiles.
test "PNG Adam7 chunk all-strategy admission is atomic" {
  for channels in [3UL, 4UL] {
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL, include_opaque=true),
      png_stream_test_limits(), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(width=4UL), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(output=1UL), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(work=1UL), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(), 1UL,
    )
  }
}

///| Multi-pass RGB8/RGBA8 Adam7 streams preserve their private preview until
/// acknowledgement, accept only leased bytes, and retain a sticky terminal.
test "PNG Adam7 multi-pass chunk replay is acknowledgement safe" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels, width=5UL, height=5UL)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      png_adam7_chunk_drain(image, strategy, [1UL])
      png_adam7_chunk_drain(image, strategy, [0UL, 1UL, 3UL, 2UL, 5UL])
    }
  }
}

///| The legal GrayAlpha16 Adam7 all-strategy route must retain the same
/// preview/acknowledgement accounting as the existing bounded machine.
fn png_graya16_adam7_chunk_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
) -> Unit {
  let eager = png_stream_graya16_eager_with_all_strategies(
    image, strategy, filter_strategy, PngInterlaceStrategy::Adam7,
  )
  let encoder = PngChunkEncoder::new_graya16_with_all_strategies(
    image.view(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(1UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
    empty.view().get(0UL).unwrap() != b'Z' {
    abort("png graya16 adam7 empty lease progress")
  }
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png graya16 adam7 accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png graya16 adam7 lease tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png graya16 adam7 chunk drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png graya16 adam7 eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png graya16 adam7 terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' {
            abort("png graya16 adam7 terminal lease")
          }
        }
        return
      }
    }
  }
  abort("png graya16 adam7 chunk drain unreachable")
}

///| One public Adaptive/Fixed GrayAlpha16 Adam7 selector preserves caller
/// ownership through direct zero-capacity, one-byte, and ragged leases.
test "PNG GrayAlpha16 Adam7 public hostile tracer" {
  png_graya16_adam7_chunk_drain(
    png_stream_graya16_adam7_image(), PngCompressionStrategy::FixedOrStored,
    PngFilterStrategy::Adaptive, [1UL],
  )
  png_graya16_adam7_chunk_drain(
    png_stream_graya16_adam7_image(), PngCompressionStrategy::FixedOrStored,
    PngFilterStrategy::Adaptive, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  )
}

///| Every legal public GrayAlpha16 Adam7 selector drains fresh chunk encoders
/// through zero, one-byte, and ragged caller-buffer schedules while retaining
/// byte identity with a separately constructed public eager encoder.
test "PNG GrayAlpha16 Adam7 public hostile schedules" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      png_graya16_adam7_chunk_drain(
        png_stream_graya16_adam7_image(), strategy, filter_strategy, [0UL, 1UL],
      )
      png_graya16_adam7_chunk_drain(
        png_stream_graya16_adam7_image(), strategy, filter_strategy, [1UL],
      )
      png_graya16_adam7_chunk_drain(
        png_stream_graya16_adam7_image(), strategy, filter_strategy,
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
      )
    }
  }
}

///| Drain a fresh all-seven-pass GrayAlpha8 source through caller-owned leases
/// while retaining public eager identity, tail ownership, and sticky completion.
fn png_graya8_adam7_chunk_drain(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
) -> Unit {
  let eager = png_stream_graya8_eager_with_all_strategies(
    png_stream_graya8_adam7_image(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
  )
  let source = png_stream_graya8_adam7_image()
  let encoder = PngChunkEncoder::new_graya8_with_all_strategies(
    source.view(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(1UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
    empty.view().get(0UL).unwrap() != b'Z' {
    abort("png graya8 adam7 empty lease progress")
  }
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png graya8 adam7 accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png graya8 adam7 lease tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png graya8 adam7 chunk drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png graya8 adam7 eager parity") }
        let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
        let later = sentinel.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if later.written() != 0UL || later.total_written() != pulled.total_written() ||
          !(later.outcome() is PngChunkPullOutcome::Finished) {
          abort("png graya8 adam7 terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if sentinel.view().get(index).unwrap() != b'Z' {
            abort("png graya8 adam7 terminal lease")
          }
        }
        return
      }
    }
  }
  abort("png graya8 adam7 chunk drain unreachable")
}

///| One public Adaptive/Fixed GrayAlpha8 Adam7 selector preserves caller
/// ownership through direct zero-capacity, one-byte, and ragged leases.
test "PNG GrayAlpha8 Adam7 public hostile tracer" {
  png_graya8_adam7_chunk_drain(
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive, [0UL, 1UL],
  )
  png_graya8_adam7_chunk_drain(
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive, [1UL],
  )
  png_graya8_adam7_chunk_drain(
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  )
}

///| Every legal public GrayAlpha8 Adam7 selector drains fresh chunk encoders
/// through zero, one-byte, and ragged caller-buffer schedules while retaining
/// byte identity with a separately constructed public eager encoder.
test "PNG GrayAlpha8 Adam7 public hostile schedules" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      png_graya8_adam7_chunk_drain(strategy, filter_strategy, [0UL, 1UL])
      png_graya8_adam7_chunk_drain(strategy, filter_strategy, [1UL])
      png_graya8_adam7_chunk_drain(
        strategy, filter_strategy, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
      )
    }
  }
}

///| RGBA16 corpora select Fixed and Dynamic DEFLATE plans without introducing
/// any alternate chunk transport or interlace API.
fn png_stream_rgba16_replay_image(
  width : UInt64,
  periodic? : Bool = false,
) -> @storage.OwnedImage {
  let bytes = width * 8UL
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL, @model.ImageFormat::rgba16(),
    [@model.PlaneDescriptor::new(0UL, bytes, bytes, bytes, 1UL, 1UL, width, 1UL).unwrap()],
    bytes,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    let lanes : Array[Byte] = [
      b'\x34', b'\x12', b'\xc5', b'\xa7', b'\x0f', b'\xbe', b'\x76', b'\x5a',
    ]
    for x = 0UL; x < width; x = x + 1UL {
      for component = 0UL; component < 4UL; component = component + 1UL {
        for lane = 0UL; lane < 2UL; lane = lane + 1UL {
          let value = if periodic {
            ((x * 8UL + component * 2UL + lane) % 5UL).to_byte()
          } else {
            lanes[(component * 2UL + lane).to_int()]
          }
          view.set_component_byte(x, 0UL, component, lane, value).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| RGBA16 rejects every incompatible profile or resource admission before
/// output, budget reservation, or a caller-owned lease can be exposed.
fn png_rgba16_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_rgba16_with_strategies(strategy, filter_strategy),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png rgba16 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_rgba16_with_strategies(
        image.view(), strategy, filter_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png rgba16 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png rgba16 admission exposed lease")
        }
      }
    }
  }
}

///| A source mutation after acknowledged RGBA16 framing bytes must expose no
/// new lease byte and cache the original typed terminal for later pulls.
fn png_rgba16_replay_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  expected_header : Byte,
) -> Unit {
  let encoder = PngChunkEncoder::new_rgba16_with_strategies(
    image.view(), strategy, PngFilterStrategy::None,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png rgba16 replay prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header {
    abort("png rgba16 replay selected wrong deflate route")
  }
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xff')
  }).unwrap()
  let accepted_total = prefix.length().to_uint64()
  let first = png_chunk_test_owner(7UL, fill=b'Z')
  let failed = first.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let error = match failed.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    PngChunkPullOutcome::NeedOutput => abort("png rgba16 replay exposed post-mutation bytes")
    PngChunkPullOutcome::Finished => abort("png rgba16 replay did not drift")
  }
  if failed.written() != 0UL || failed.total_written() != accepted_total {
    abort("png rgba16 replay first terminal progress")
  }
  for index = 0UL; index < 7UL; index = index + 1UL {
    if first.view().get(index).unwrap() != b'Z' {
      abort("png rgba16 replay first terminal lease")
    }
  }
  let later = png_chunk_test_owner(7UL, fill=b'Z')
  let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png rgba16 replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) {
    abort("png rgba16 replay was not sticky")
  }
  for index = 0UL; index < 7UL; index = index + 1UL {
    if later.view().get(index).unwrap() != b'Z' {
      abort("png rgba16 replay sticky terminal lease")
    }
  }
}

///| All explicit RGBA16 profile and resource rejections are atomic across the
/// bounded compression/filter matrix.
test "PNG RGBA16 strategy admission is atomic" {
  png_rgba16_combined_public_reject(
    png_stream_test_image(3UL), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_rgba16_combined_public_reject(
    png_stream_rgba16_image(), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_rgba16_combined_public_reject(
    png_stream_rgba16_image(), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_rgba16_combined_public_reject(
    png_stream_rgba16_image(), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_rgba16_combined_public_reject(
    png_stream_rgba16_image(), png_fixed_or_stored_limits(), 1UL,
  )
}

///| Fixed and Dynamic RGBA16 plans reject source replay drift before writing a
/// new caller lease and retain that same typed terminal.
test "PNG RGBA16 Fixed and Dynamic replay mutations are sticky" {
  png_rgba16_replay_mutation_is_sticky(
    png_stream_rgba16_replay_image(5UL), PngCompressionStrategy::FixedOrStored, b'\x03',
  )
  png_rgba16_replay_mutation_is_sticky(
    png_stream_rgba16_replay_image(128UL, periodic=true),
    PngCompressionStrategy::DynamicOrFixedOrStored, b'\x05',
  )
}

///| A released RGBA16 destination lease reports a zero-write typed terminal
/// and cannot alter a later caller-owned lease.
test "PNG RGBA16 chunk replays released lease failure" {
  let image = png_stream_rgba16_image()
  let encoder = PngChunkEncoder::new_rgba16(
    image.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png rgba16 released lease outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png rgba16 released lease replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png rgba16 released lease terminal")
  }
}

///| The legacy generic chunk constructor remains frozen on its RGB8/RGBA8
/// profile selection and must reject an explicit RGBA16 source.
test "PNG generic chunk constructor rejects RGBA16" {
  let image = png_stream_rgba16_image()
  match PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ) {
    Ok(_) => abort("png generic chunk admitted rgba16")
    Err(_) => ()
  }
}

///| Canonical odd-width Gray/U8 sources exercise each public packed selector
/// without duplicating the encoder's production packing logic in this test file.
fn png_stream_packed_gray_image(depth : UInt64) -> @storage.OwnedImage {
  if depth == 1UL {
    png_stream_gray8_image(b"\x00\xff\x00\xff\x00\xff\x00\xff\xff", width=9UL)
  } else if depth == 2UL {
    png_stream_gray8_image(b"\x00\x55\xaa\xff\x00", width=5UL)
  } else {
    png_stream_gray8_image(b"\x00\xff\x11", width=3UL)
  }
}

///| Public eager encoding is the packed-stream identity oracle.
fn png_stream_packed_eager(image : @storage.OwnedImage, depth : UInt64) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let encoder = if depth == 1UL {
    PngEncoder::new_gray1()
  } else if depth == 2UL {
    PngEncoder::new_gray2()
  } else {
    PngEncoder::new_gray4()
  }
  ignore(@codec.ImageEncoder::encode(
    encoder, image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Select only the fixed public low-bit chunk factories under test.
fn png_stream_packed_chunk(
  image : @storage.OwnedImage,
  depth : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngChunkEncoder, @error.CoreError] {
  if depth == 1UL {
    PngChunkEncoder::new_gray1(image.view(), limits, budget, @error.Diagnostics::new())
  } else if depth == 2UL {
    PngChunkEncoder::new_gray2(image.view(), limits, budget, @error.Diagnostics::new())
  } else {
    PngChunkEncoder::new_gray4(image.view(), limits, budget, @error.Diagnostics::new())
  }
}

///| Fresh encoders retain public eager parity, accepted-only accounting, and
/// caller-owned tails under zero, one-byte, and ragged leases.
fn png_stream_packed_hostile_drain(
  image : @storage.OwnedImage,
  depth : UInt64,
  schedule : Array[UInt64],
) -> Unit {
  let eager = png_stream_packed_eager(image, depth)
  let encoder = png_stream_packed_chunk(
    image, depth, png_stream_test_limits(), png_stream_test_budget(),
  ).unwrap()
  let empty = png_chunk_test_owner(1UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
    empty.view().get(0UL).unwrap() != b'Z' {
    abort("png packed empty lease progress")
  }
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png packed accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png packed lease tail changed")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png packed chunk drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png packed eager parity") }
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png packed terminal progress")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' {
            abort("png packed terminal lease changed")
          }
        }
        return ()
      }
    }
  }
  abort("png packed chunk drain unreachable")
}

///| Every low-bit selector is byte-identical to its public eager peer through
/// hostile caller-owned capacities.
test "PNG packed grayscale chunk selectors retain public hostile leases" {
  for depth in [1UL, 2UL, 4UL] {
    let image = png_stream_packed_gray_image(depth)
    png_stream_packed_hostile_drain(image, depth, [0UL, 1UL])
    png_stream_packed_hostile_drain(image, depth, [1UL])
    png_stream_packed_hostile_drain(image, depth, [0UL, 1UL, 3UL, 2UL, 5UL])
  }
}

///| Invalid levels and exhausted work reject before a chunk instance can expose
/// a lease, preserving every resource-limit field.
test "PNG packed grayscale chunk admission is atomic" {
  for depth in [1UL, 2UL, 4UL] {
    let invalid = png_stream_gray8_image(
      if depth == 4UL { b"\x02" } else { b"\x01" },
    )
    let invalid_budget = png_stream_test_budget()
    let invalid_before = invalid_budget.remaining()
    let invalid_error = png_stream_packed_chunk(
      invalid, depth, png_stream_test_limits(), invalid_budget,
    ).unwrap_err()
    let expected_context = if depth == 1UL {
      "gray1-level-required"
    } else if depth == 2UL {
      "gray2-level-required"
    } else {
      "gray4-level-required"
    }
    if invalid_error.context() != Some(expected_context) ||
      !png_adam7_stream_same_remaining(invalid_before, invalid_budget.remaining()) {
      abort("png packed invalid admission was not atomic")
    }
    let valid_budget = png_stream_test_budget(work=0UL)
    let valid_before = valid_budget.remaining()
    let work_error = png_stream_packed_chunk(
      png_stream_packed_gray_image(depth), depth, png_stream_test_limits(), valid_budget,
    ).unwrap_err()
    if work_error.context() == None ||
      !png_adam7_stream_same_remaining(valid_before, valid_budget.remaining()) {
      abort("png packed work admission was not atomic")
    }
  }
}

///| A released first lease yields a zero-write typed terminal that replays
/// identically without mutating a later caller-owned lease.
test "PNG packed grayscale chunk replays released lease failures" {
  for depth in [1UL, 2UL, 4UL] {
    let encoder = png_stream_packed_chunk(
      png_stream_packed_gray_image(depth), depth, png_stream_test_limits(),
      png_stream_test_budget(),
    ).unwrap()
    let released = png_chunk_test_owner(1UL, fill=b'Z')
    let first = released.with_mut(0UL, 1UL, fn(lease) {
      lease.release()
      Ok(encoder.pull(lease))
    }).unwrap()
    let first_error = match first.outcome() {
      PngChunkPullOutcome::Failed(error) => error
      _ => abort("png packed released lease outcome")
    }
    let later = png_chunk_test_owner(1UL, fill=b'Z')
    let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    let replay_error = match replay.outcome() {
      PngChunkPullOutcome::Failed(error) => error
      _ => abort("png packed released lease replay")
    }
    if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
      replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
      released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
      abort("png packed released lease terminal")
    }
  }
}

///| The public eager Indexed8 route is the byte-for-byte oracle for caller
/// buffered palette output.
fn png_stream_indexed_eager(source : PngIndexedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  ignore(PngEncoder::encode_indexed8(
    PngEncoder::new(), source, writer as &@io.Writer, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///| The explicit Indexed8 eager selector is the caller-buffered strategy
/// oracle, including the admitted Fixed-or-Stored plan.
fn png_stream_indexed8_eager_with_compression(
  source : PngIndexedImage,
  strategy : PngCompressionStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  ignore(PngEncoder::encode_indexed8_with_compression_strategy(
    PngEncoder::new(), source, strategy, writer as &@io.Writer,
    png_stream_test_limits(), png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///| The public eager selected-depth route is the byte-for-byte oracle for
///| caller-buffered low-bit indexed output.
fn png_stream_indexed_low_bit_eager(
  source : PngIndexedImage,
  bit_depth : PngIndexedBitDepth,
) -> Bytes {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  ignore(PngEncoder::encode_indexed(
    PngEncoder::new(), source, bit_depth, writer as &@io.Writer,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///|
fn png_stream_indexed_low_bit_eager_with_compression(
  source : PngIndexedImage,
  bit_depth : PngIndexedBitDepth,
  strategy : PngCompressionStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  ignore(PngEncoder::encode_indexed_with_compression_strategy(
    PngEncoder::new(), source, bit_depth, strategy, writer as &@io.Writer,
    png_stream_test_limits(), png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///| Caller-buffered construction traverses the same admitted selected-depth
///| machine as the eager facade under an ordinary drain schedule.
test "PNG indexed compression admission tracer chunk selector" {
  let source = png_indexed_compression_source(PngIndexedBitDepth::Two)
  let eager = png_stream_indexed_low_bit_eager_with_compression(
    source, PngIndexedBitDepth::Two, PngCompressionStrategy::FixedOrStored,
  )
  let encoder = PngChunkEncoder::new_indexed_with_compression_strategy(
    source, PngIndexedBitDepth::Two, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
  ).unwrap()
  inspect(png_chunk_test_drain_encoder(encoder, [32UL]).unwrap() == eager, content="true")
}

///| Construction consumes the chosen work once; rejected constructors return no
///| encoder and therefore cannot expose an active state or caller lease.
fn png_stream_selected_depth_compression_admission(depth : PngIndexedBitDepth) -> Unit {
  let source = png_indexed_compression_source(depth)
  let discovery_budget = png_stream_test_budget(work=4096UL)
  let discovery_before = discovery_budget.remaining()
  let discovery = PngChunkEncoder::new_indexed_with_compression_strategy(
    source, depth, PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    discovery_budget, @error.Diagnostics::new(),
  ).unwrap()
  let selected_work = discovery_before.work() - discovery_budget.remaining().work()
  let expected = png_chunk_test_drain_encoder(discovery, [32UL]).unwrap()
  let exact_limit = PngChunkEncoder::new_indexed_with_compression_strategy(
    source, depth, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(work=selected_work), png_stream_test_budget(work=4096UL),
    @error.Diagnostics::new(),
  ).unwrap()
  if png_chunk_test_drain_encoder(exact_limit, [32UL]).unwrap() != expected {
    abort("png selected exact chunk limit")
  }
  let exact_budget = png_stream_test_budget(work=selected_work)
  let exact = PngChunkEncoder::new_indexed_with_compression_strategy(
    source, depth, PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    exact_budget, @error.Diagnostics::new(),
  ).unwrap()
  if exact_budget.remaining().work() != 0UL || png_chunk_test_drain_encoder(exact, [32UL]).unwrap() != expected {
    abort("png selected exact chunk budget")
  }
  let work_budget = png_stream_test_budget(work=4096UL)
  let work_before = work_budget.remaining()
  if !(PngChunkEncoder::new_indexed_with_compression_strategy(
    source, depth, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(work=selected_work - 1UL), work_budget, @error.Diagnostics::new(),
  ) is Err(_)) || !png_adam7_stream_same_remaining(work_before, work_budget.remaining()) {
    abort("png selected one-less chunk limit")
  }
  let budget_budget = png_stream_test_budget(work=selected_work - 1UL)
  let budget_before = budget_budget.remaining()
  if !(PngChunkEncoder::new_indexed_with_compression_strategy(
    source, depth, PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    budget_budget, @error.Diagnostics::new(),
  ) is Err(_)) || !png_adam7_stream_same_remaining(budget_before, budget_budget.remaining()) {
    abort("png selected one-less chunk budget")
  }
  let output_budget = png_stream_test_budget(work=4096UL)
  let output_before = output_budget.remaining()
  if !(PngChunkEncoder::new_indexed_with_compression_strategy(
    source, depth, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(output=expected.length().to_uint64() - 1UL), output_budget,
    @error.Diagnostics::new(),
  ) is Err(_)) || !png_adam7_stream_same_remaining(output_before, output_budget.remaining()) {
    abort("png selected one-less chunk output")
  }
  let cap = match depth {
    PngIndexedBitDepth::One => 2UL
    PngIndexedBitDepth::Two => 4UL
    PngIndexedBitDepth::Four => 16UL
  }
  let oversized = PngIndexedImage::new(
    1UL, 1UL, b"\x00", Bytes::from_array(Array::make(((cap + 1UL) * 3UL).to_int(), b'\x12')),
    Bytes::from_array(Array::make((cap + 1UL).to_int(), b'\xff')), png_stream_test_budget(),
  ).unwrap()
  let cap_budget = png_stream_test_budget(work=4096UL)
  let cap_before = cap_budget.remaining()
  if !(PngChunkEncoder::new_indexed_with_compression_strategy(
    oversized, depth, PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    cap_budget, @error.Diagnostics::new(),
  ) is Err(_)) || !png_adam7_stream_same_remaining(cap_before, cap_budget.remaining()) {
    abort("png selected palette-cap chunk admission")
  }
}

///| All low-bit public chunk selectors reject selected output/work before an
///| active encoder can be returned, while exact construction drains normally.
test "PNG indexed compression ancillary admission chunk is atomic" {
  for depth in [PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four] {
    png_stream_selected_depth_compression_admission(depth)
  }
  let source = PngIndexedImage::new(
    64UL, 1UL, Bytes::from_array(Array::make(64, b'\x00')),
    b"\x12\x34\x56\xa0\xb0\xc0", b"\x00\xff", png_stream_test_budget(),
  ).unwrap()
  let discovery_budget = png_stream_test_budget(work=4096UL)
  let before = discovery_budget.remaining()
  let encoder = PngChunkEncoder::new_indexed8_with_compression_strategy(
    source, PngCompressionStrategy::FixedOrStored, png_stream_test_limits(), discovery_budget,
    @error.Diagnostics::new(),
  ).unwrap()
  let selected_work = before.work() - discovery_budget.remaining().work()
  ignore(png_chunk_test_drain_encoder(encoder, [32UL]).unwrap())
  let rejected_budget = png_stream_test_budget(work=4096UL)
  let rejected_before = rejected_budget.remaining()
  inspect(PngChunkEncoder::new_indexed8_with_compression_strategy(
    source, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(work=selected_work - 1UL), rejected_budget, @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(png_adam7_stream_same_remaining(rejected_before, rejected_budget.remaining()), content="true")
}

///| Indexed8 chunk selectors must drain exactly like their eager strategy
/// oracles and reject unavailable Dynamic output before budget admission.
test "PNG Indexed8 compression chunk selectors match eager bytes" {
  let source = PngIndexedImage::new(
    64UL, 1UL, Bytes::from_array(Array::make(64, b'\x00')),
    b"\x12\x34\x56\xa0\xb0\xc0", b"\x00\xff", png_stream_test_budget(),
  ).unwrap()
  for strategy in [
    PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored,
  ] {
    let eager = png_stream_indexed8_eager_with_compression(source, strategy)
    let encoder = PngChunkEncoder::new_indexed8_with_compression_strategy(
      source, strategy, png_stream_test_limits(), png_stream_test_budget(work=4096UL),
      @error.Diagnostics::new(),
    ).unwrap()
    inspect(
      png_chunk_test_drain_encoder(encoder, [32UL]).unwrap() == eager,
      content="true",
    )
  }
  let rejected_budget = png_stream_test_budget(work=4096UL)
  let before = rejected_budget.remaining()
  let rejected = PngChunkEncoder::new_indexed8_with_compression_strategy(
    source, PngCompressionStrategy::DynamicOrFixedOrStored, png_stream_test_limits(),
    rejected_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(rejected.context() == Some("indexed-dynamic-compression-unavailable"), content="true")
  inspect(
    png_adam7_stream_same_remaining(before, rejected_budget.remaining()), content="true",
  )
}

///| Selected-depth chunk selectors must use the same admitted plan and expose
/// no caller-buffered encoder for the unavailable Dynamic request.
test "PNG indexed compression chunk selectors match eager matrix bytes" {
  for depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    let source = png_indexed_compression_source(depth)
    let eager = png_stream_indexed_low_bit_eager_with_compression(
      source, depth, PngCompressionStrategy::FixedOrStored,
    )
    let encoder = PngChunkEncoder::new_indexed_with_compression_strategy(
      source, depth, PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
      png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
    ).unwrap()
    inspect(
      png_chunk_test_drain_encoder(encoder, [32UL]).unwrap() == eager,
      content="true",
    )
    let rejected = PngChunkEncoder::new_indexed_with_compression_strategy(
      source, depth, PngCompressionStrategy::DynamicOrFixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
    ).unwrap_err()
    inspect(rejected.context() == Some("indexed-dynamic-compression-unavailable"), content="true")
  }
}

///| The selected-depth chunk route starts with a Type-3/2 tracer so its public
///| lease lifecycle is proven against the already-qualified eager oracle.
test "PNG Indexed2 chunk tracer retains eager bytes" {
  let source = PngIndexedImage::new(
    5UL, 1UL, b"\x00\x01\x02\x03\x00",
    b"\x12\x34\x56\xa0\xb0\xc0\x11\x22\x33\x44\x55\x66",
    b"\x00\xff\x80\xff", png_stream_test_budget(),
  ).unwrap()
  let expected = png_stream_indexed_low_bit_eager(source, PngIndexedBitDepth::Two)
  let encoder = PngChunkEncoder::new_indexed(
    source, PngIndexedBitDepth::Two, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(1UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
    empty.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed2 chunk zero lease")
  }
  let output : Array[Byte] = []
  let schedule = [1UL, 3UL, 2UL, 5UL]
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png indexed2 chunk accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png indexed2 chunk tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != expected { abort("png indexed2 chunk eager parity") }
        return ()
      }
      PngChunkPullOutcome::Failed(_) => abort("png indexed2 chunk tracer failed")
    }
  }
  abort("png indexed2 chunk tracer unreachable")
}

///| The first Indexed8 streaming tracer uses a transparent palette and ragged
/// caller-owned leases, including an initial zero-capacity lease.
test "PNG Indexed8 chunk transparent tracer retains eager bytes" {
  let source = PngIndexedImage::new(
    4UL, 1UL, b"\x00\x01\x02\x03",
    b"\x12\x34\x56\xa0\xb0\xc0\x11\x22\x33\x44\x55\x66",
    b"\x00\xff\x80\xff", png_stream_test_budget(),
  ).unwrap()
  let expected = png_stream_indexed_eager(source)
  let encoder = PngChunkEncoder::new_indexed8(
    source, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(1UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
    empty.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed8 chunk zero lease")
  }
  let output : Array[Byte] = []
  let schedule = [1UL, 3UL, 2UL, 5UL]
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png indexed8 chunk accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png indexed8 chunk tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != expected { abort("png indexed8 chunk eager parity") }
        return ()
      }
      PngChunkPullOutcome::Failed(_) => abort("png indexed8 chunk tracer failed")
    }
  }
  abort("png indexed8 chunk tracer unreachable")
}

///| Builds the two public Indexed8 palette variants qualified by the chunk
/// lifecycle tests without widening the generic image model.
fn png_stream_indexed_source(transparent : Bool) -> PngIndexedImage {
  if transparent {
    PngIndexedImage::new(
      4UL, 1UL, b"\x00\x01\x02\x03",
      b"\x12\x34\x56\xa0\xb0\xc0\x11\x22\x33\x44\x55\x66",
      b"\x00\xff\x80\xff", png_stream_test_budget(),
    ).unwrap()
  } else {
    PngIndexedImage::new(
      2UL, 1UL, b"\x00\x01", b"\x12\x34\x56\xa0\xb0\xc0",
      b"\xff\xff", png_stream_test_budget(),
    ).unwrap()
  }
}

///| The new Indexed8 selector is only smoke-tested with one sufficient lease;
/// hostile lease schedules are deliberately reserved for Phase 82.
test "PNG Indexed8 Adam7 chunk selector wires the shared machine IHDR" {
  let source = PngIndexedImage::new(
    5UL, 5UL,
    b"\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00",
    b"\x12\x34\x56\xa0\xb0\xc0\xd0\xe0\xf0\x21\x43\x65", b"\x00\x80\x7f\xff",
    png_stream_test_budget(),
  ).unwrap()
  let encoder = PngChunkEncoder::new_indexed8_with_interlace_strategy(
    source, PngInterlaceStrategy::Adam7, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let bytes = png_chunk_test_drain_encoder(encoder, [256UL]).unwrap()
  inspect(bytes.length(), content="143")
  inspect(
    bytes[24] == b'\x08' && bytes[25] == b'\x03' && bytes[26] == b'\x00' &&
      bytes[27] == b'\x00' && bytes[28] == b'\x01',
    content="true",
  )
}

///| The explicit Indexed8 Adam7 chunk facade must retain accepted-only progress,
///| caller-owned tails, stream-origin framing, and the sticky completed terminal
///| under zero-capacity, one-byte, and ragged leases.
test "PNG Indexed8 Adam7 chunk hostile leases qualify stream-origin bytes" {
  png_stream_indexed8_adam7_hostile_drain([0UL, 1UL])
  png_stream_indexed8_adam7_hostile_drain([1UL])
  png_stream_indexed8_adam7_hostile_drain([0UL, 1UL, 3UL, 2UL, 5UL])
  png_stream_indexed8_adam7_hostile_drain([0UL, 1UL, 3UL, 2UL, 5UL, 7UL])
}

///| A released first Adam7 destination must become a sticky zero-write failure
///| without mutating the original or a later sentinel-filled lease.
test "PNG Indexed8 Adam7 chunk replays released lease failure" {
  png_stream_indexed8_adam7_released_failure()
}

///| Builds the literal 5x5 transparent Indexed8 Adam7 fixture with the same
///| ample caller-buffer test budget used by the stream qualification harness.
fn png_stream_indexed8_adam7_source() -> PngIndexedImage {
  PngIndexedImage::new(
    5UL, 5UL,
    b"\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00",
    b"\x12\x34\x56\xa0\xb0\xc0\xd0\xe0\xf0\x21\x43\x65", b"\x00\x80\x7f\xff",
    png_stream_test_budget(),
  ).unwrap()
}

///| Builds a fresh explicit eager Adam7 oracle for each caller-buffered run.
fn png_stream_indexed8_adam7_eager() -> Bytes {
  let writer = @io.MemoryWriter::new(
    256UL, png_stream_test_budget(),
  ).unwrap()
  ignore(PngEncoder::encode_indexed8_with_interlace_strategy(
    PngEncoder::new(), png_stream_indexed8_adam7_source(), PngInterlaceStrategy::Adam7,
    writer as &@io.Writer, png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///| Independently validates the completed caller-buffered bytes rather than
///| using eager equality as the only wire or decode evidence.
fn png_stream_indexed8_adam7_chunk_origin_qualification(bytes : Bytes) -> Unit {
  if bytes.length() != 143 {
    abort("png indexed8 Adam7 chunk length")
  }
  if png_indexed_u32(bytes, 8) != 13UL || png_indexed_slice(bytes, 12, 4) != b"IHDR" ||
    png_indexed_slice(bytes, 16, 13) != b"\x00\x00\x00\x05\x00\x00\x00\x05\x08\x03\x00\x00\x01" ||
    png_indexed_crc32(bytes, 12, 17) != png_indexed_u32(bytes, 29) {
    abort("png indexed8 Adam7 chunk IHDR")
  }
  if png_indexed_u32(bytes, 33) != 12UL || png_indexed_slice(bytes, 37, 4) != b"PLTE" ||
    png_indexed_slice(bytes, 41, 12) != b"\x12\x34\x56\xa0\xb0\xc0\xd0\xe0\xf0\x21\x43\x65" ||
    png_indexed_crc32(bytes, 37, 16) != png_indexed_u32(bytes, 53) {
    abort("png indexed8 Adam7 chunk PLTE")
  }
  if png_indexed_u32(bytes, 57) != 3UL || png_indexed_slice(bytes, 61, 4) != b"tRNS" ||
    png_indexed_slice(bytes, 65, 3) != b"\x00\x80\x7f" ||
    png_indexed_crc32(bytes, 61, 7) != png_indexed_u32(bytes, 68) {
    abort("png indexed8 Adam7 chunk tRNS")
  }
  if png_indexed_u32(bytes, 72) != 47UL || png_indexed_slice(bytes, 76, 4) != b"IDAT" ||
    png_indexed_crc32(bytes, 76, 51) != png_indexed_u32(bytes, 127) ||
    png_indexed_u32(bytes, 131) != 0UL || png_indexed_slice(bytes, 135, 4) != b"IEND" ||
    png_indexed_crc32(bytes, 135, 4) != png_indexed_u32(bytes, 139) {
    abort("png indexed8 Adam7 chunk IDAT or IEND")
  }
  if png_encode_public_stored_scanlines(bytes, 36) != png_indexed8_adam7_expected_raw() {
    abort("png indexed8 Adam7 chunk pass raster")
  }

  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_stream_test_budget(work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(output=256UL, work=1048576UL),
    png_stream_test_budget(work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  if decoded.width() != 5UL || decoded.height() != 5UL ||
    decoded.format().channels() != @model.ChannelOrder::Rgba ||
    decoded.format().channel_count() != 4UL {
    abort("png indexed8 Adam7 chunk decoded descriptor")
  }
  let expected = b"\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00"
  let palette = b"\x12\x34\x56\xa0\xb0\xc0\xd0\xe0\xf0\x21\x43\x65"
  let alpha = b"\x00\x80\x7f\xff"
  for point = 0; point < 25; point = point + 1 {
    let code = expected[point].to_int()
    let x = (point % 5).to_uint64()
    let y = (point / 5).to_uint64()
    for channel = 0; channel < 3; channel = channel + 1 {
      if decoded.get_byte(x, y, channel.to_uint64()).unwrap() != palette[code * 3 + channel] {
        abort("png indexed8 Adam7 chunk decoded palette")
      }
    }
    if decoded.get_byte(x, y, 3UL).unwrap() != alpha[code] {
      abort("png indexed8 Adam7 chunk decoded alpha")
    }
  }
}

///| Drives one fresh explicit Adam7 chunk selector through caller-owned leases,
///| validating accepted-only progress, tails, completion, and independent bytes.
fn png_stream_indexed8_adam7_hostile_drain(schedule : Array[UInt64]) -> Unit {
  let expected = png_stream_indexed8_adam7_eager()
  let encoder = PngChunkEncoder::new_indexed8_with_interlace_strategy(
    png_stream_indexed8_adam7_source(), PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(if capacity == 0UL { 1UL } else { capacity }, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png indexed8 Adam7 hostile accepted-only progress")
    }
    if capacity == 0UL {
      if pulled.written() != 0UL { abort("png indexed8 Adam7 hostile zero write") }
      if pulled.total_written() != before || (before == 0UL && pulled.total_written() != 0UL) {
        abort("png indexed8 Adam7 hostile zero total")
      }
      if !(pulled.outcome() is PngChunkPullOutcome::NeedOutput) {
        abort("png indexed8 Adam7 hostile zero outcome")
      }
      if owner.view().get(0UL).unwrap() != b'Z' {
        abort("png indexed8 Adam7 hostile zero sentinel")
      }
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png indexed8 Adam7 hostile tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png indexed8 Adam7 hostile drain failed")
      PngChunkPullOutcome::Finished => {
        let chunk_bytes = Bytes::from_array(output)
        if chunk_bytes != expected { abort("png indexed8 Adam7 hostile eager parity") }
        png_stream_indexed8_adam7_chunk_origin_qualification(chunk_bytes)
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png indexed8 Adam7 sticky completed terminal")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' {
            abort("png indexed8 Adam7 completed tail")
          }
        }
        return ()
      }
    }
  }
  abort("png indexed8 Adam7 hostile drain unreachable")
}

///| A released first Adam7 lease becomes a cached zero-write failure without
///| exposing either its original or a later caller-owned sentinel destination.
fn png_stream_indexed8_adam7_released_failure() -> Unit {
  let encoder = PngChunkEncoder::new_indexed8_with_interlace_strategy(
    png_stream_indexed8_adam7_source(), PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed8 Adam7 released lease outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed8 Adam7 released lease replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed8 Adam7 released lease terminal")
  }
}

///| Builds one bounded canonical source for each public low-bit Type-3 selector.
fn png_stream_indexed_low_bit_source(bit_depth : PngIndexedBitDepth) -> PngIndexedImage {
  match bit_depth {
    PngIndexedBitDepth::One => PngIndexedImage::new(
      9UL, 1UL, b"\x00\x01\x00\x01\x00\x01\x00\x01\x01",
      b"\x12\x34\x56\xa0\xb0\xc0", b"\xff\xff", png_stream_test_budget(),
    ).unwrap()
    PngIndexedBitDepth::Two => PngIndexedImage::new(
      5UL, 1UL, b"\x00\x01\x02\x03\x00",
      b"\x12\x34\x56\xa0\xb0\xc0\x11\x22\x33\x44\x55\x66",
      b"\x00\xff\x80\xff", png_stream_test_budget(),
    ).unwrap()
    PngIndexedBitDepth::Four => {
      let palette : Array[Byte] = []
      let alpha : Array[Byte] = []
      for entry = 0UL; entry < 16UL; entry = entry + 1UL {
        palette.push(entry.to_byte())
        palette.push((entry + 1UL).to_byte())
        palette.push((entry + 2UL).to_byte())
        alpha.push(if entry == 0UL { b'\x00' } else { b'\xff' })
      }
      PngIndexedImage::new(
        3UL, 1UL, b"\x00\x01\x02", Bytes::from_array(palette),
        Bytes::from_array(alpha), png_stream_test_budget(),
      ).unwrap()
    }
  }
}

///| Fresh selected-depth machines retain acknowledged progress, caller tails,
///| eager identity, and the sticky completed terminal under hostile leases.
fn png_stream_indexed_low_bit_hostile_drain(
  source : PngIndexedImage,
  bit_depth : PngIndexedBitDepth,
  schedule : Array[UInt64],
) -> Unit {
  let expected = png_stream_indexed_low_bit_eager(source, bit_depth)
  let encoder = PngChunkEncoder::new_indexed(
    source, bit_depth, png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png indexed low-bit hostile accepted-only progress")
    }
    if capacity == 0UL && (pulled.written() != 0UL ||
      !(pulled.outcome() is PngChunkPullOutcome::NeedOutput)) {
      abort("png indexed low-bit hostile zero lease")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png indexed low-bit hostile tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png indexed low-bit hostile drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != expected { abort("png indexed low-bit hostile eager parity") }
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png indexed low-bit sticky completed terminal")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' {
            abort("png indexed low-bit completed tail")
          }
        }
        return ()
      }
    }
  }
  abort("png indexed low-bit hostile drain unreachable")
}

///| A released selected-depth first lease becomes a sticky zero-write error and
///| cannot mutate a later caller-owned destination.
fn png_stream_indexed_low_bit_released_failure(
  source : PngIndexedImage,
  bit_depth : PngIndexedBitDepth,
) -> Unit {
  let encoder = PngChunkEncoder::new_indexed(
    source, bit_depth, png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed low-bit released lease outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed low-bit released lease replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed low-bit released lease terminal")
  }
}

///| Drain one fresh Indexed2 Fixed-or-Stored machine through a caller-owned
///| schedule. Only accepted prefixes enter the result; rejected tails remain
///| sentinel-filled and terminal pulls are zero-write/sticky.
fn png_phase87_indexed_matrix_source(
  bit_depth : PngIndexedBitDepth,
  stored_fallback : Bool,
) -> PngIndexedImage {
  let depth = png_phase87_indexed_depth(bit_depth)
  png_phase87_indexed_matrix_source_depth(depth, stored_fallback)
}

fn png_phase87_indexed_depth(bit_depth : PngIndexedBitDepth) -> UInt64 {
  match bit_depth {
    PngIndexedBitDepth::One => 1UL
    PngIndexedBitDepth::Two => 2UL
    PngIndexedBitDepth::Four => 4UL
  }
}

fn png_phase87_indexed_matrix_source_depth(
  depth : UInt64,
  stored_fallback : Bool,
) -> PngIndexedImage {
  let width = 512UL / depth
  let cap = 1UL << depth.to_int()
  let packed : Array[Byte] = []
  for index = 0; index < 64; index = index + 1 {
    packed.push(if stored_fallback { (192 + index).to_byte() } else { b'\x00' })
  }
  let codes : Array[Byte] = []
  let per_byte = 8UL / depth
  for x = 0UL; x < width; x = x + 1UL {
    let packed_byte = packed[(x / per_byte).to_int()].to_uint64()
    let shift = 8UL - depth - (x % per_byte) * depth
    codes.push(((packed_byte >> shift.to_int()) & ((1UL << depth.to_int()) - 1UL)).to_byte())
  }
  let palette : Array[Byte] = []
  let alpha : Array[Byte] = []
  for entry = 0UL; entry < cap; entry = entry + 1UL {
    palette.push(entry.to_byte())
    palette.push((entry + 1UL).to_byte())
    palette.push((entry + 2UL).to_byte())
    alpha.push(if entry == 0UL { b'\x00' } else { b'\xff' })
  }
  PngIndexedImage::new(
    width, 1UL, Bytes::from_array(codes), Bytes::from_array(palette),
    Bytes::from_array(alpha), png_stream_test_budget(),
  ).unwrap()
}

fn png_phase87_hostile_fixed_tracer(schedule : Array[UInt64]) -> Unit {
  let source = png_phase87_indexed_matrix_source(PngIndexedBitDepth::Two, false)
  let expected = png_stream_indexed_low_bit_eager_with_compression(
    source, PngIndexedBitDepth::Two, PngCompressionStrategy::FixedOrStored,
  )
  let encoder = PngChunkEncoder::new_indexed_with_compression_strategy(
    source, PngIndexedBitDepth::Two, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(work=4096UL),
    @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(if capacity == 0UL { 1UL } else { capacity }, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png phase87 fixed tracer accepted-only progress")
    }
    if capacity == 0UL && (pulled.written() != 0UL || pulled.total_written() != before ||
      !(pulled.outcome() is PngChunkPullOutcome::NeedOutput) ||
      owner.view().get(0UL).unwrap() != b'Z') {
      abort("png phase87 fixed tracer zero lease")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' {
        abort("png phase87 fixed tracer sentinel tail")
      }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png phase87 fixed tracer failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != expected {
          abort("png phase87 fixed tracer eager parity")
        }
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png phase87 fixed tracer sticky Finished")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' {
            abort("png phase87 fixed tracer terminal tail")
          }
        }
        return ()
      }
    }
  }
  abort("png phase87 fixed tracer unreachable")
}

///| Phase 87 RED/green tracer: one canonical Fixed winner survives hostile
///| leases, and a released first lease is a sticky zero-write failure.
test "PNG indexed compression hostile tracer FixedOrStored" {
  for schedule in [[0UL, 1UL], [1UL], [0UL, 1UL, 3UL, 2UL, 5UL]] {
    png_phase87_hostile_fixed_tracer(schedule)
  }
  let source = png_phase87_indexed_matrix_source(PngIndexedBitDepth::Two, false)
  let encoder = PngChunkEncoder::new_indexed_with_compression_strategy(
    source, PngIndexedBitDepth::Two, PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(work=4096UL),
    @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png phase87 fixed tracer released outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png phase87 fixed tracer released replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png phase87 fixed tracer released terminal")
  }
}

///| Independent LSB-first bit reader for the bounded Type-3 DEFLATE oracle.
struct PngPhase87Bits {
  bytes : Bytes
  mut offset : Int
  mut value : UInt64
  mut available : Int
}

fn png_phase87_bits_new(bytes : Bytes) -> PngPhase87Bits {
  { bytes, offset: 0, value: 0UL, available: 0 }
}

fn PngPhase87Bits::read(self : PngPhase87Bits, count : Int) -> Int {
  if count < 0 || count > 16 { abort("png phase87 invalid bit count") }
  while self.available < count {
    if self.offset >= self.bytes.length() { abort("png phase87 truncated deflate") }
    self.value = self.value | (self.bytes[self.offset].to_uint64() << self.available)
    self.offset = self.offset + 1
    self.available = self.available + 8
  }
  let mask = if count == 0 { 0UL } else { (1UL << count) - 1UL }
  let result = (self.value & mask).to_int()
  self.value = self.value >> count
  self.available = self.available - count
  result
}

fn PngPhase87Bits::align(self : PngPhase87Bits) -> Unit {
  self.value = 0UL
  self.available = 0
}

fn png_phase87_reverse(value : Int, width : Int) -> Int {
  let mut input = value
  let mut result = 0
  for index = 0; index < width; index = index + 1 {
    result = (result << 1) | (input & 1)
    input = input >> 1
  }
  result
}

fn png_phase87_fixed_symbol_code(symbol : Int) -> (Int, Int) {
  if symbol <= 143 {
    (png_phase87_reverse(48 + symbol, 8), 8)
  } else if symbol <= 255 {
    (png_phase87_reverse(400 + symbol - 144, 9), 9)
  } else if symbol <= 279 {
    (png_phase87_reverse(symbol - 256, 7), 7)
  } else {
    (png_phase87_reverse(192 + symbol - 280, 8), 8)
  }
}

fn png_phase87_fixed_symbol(bits : PngPhase87Bits) -> Int {
  let mut code = 0
  for width = 1; width <= 15; width = width + 1 {
    code = code | (bits.read(1) << (width - 1))
    let mut symbol = 0
    while symbol < 288 {
      let (_, symbol_width) = png_phase87_fixed_symbol_code(symbol)
      if symbol_width == width {
        let (candidate, _) = png_phase87_fixed_symbol_code(symbol)
        if candidate == code { return symbol }
      }
      symbol = symbol + 1
    }
  }
  abort("png phase87 unknown fixed symbol")
}

fn png_phase87_inflate(idat : Bytes, expect_fixed : Bool) -> Bytes {
  if idat.length() < 7 || idat[0] != b'\x78' ||
    ((idat[0].to_uint64() << 8) | idat[1].to_uint64()) % 31UL != 0UL {
    abort("png phase87 zlib header")
  }
  let compressed : Array[Byte] = []
  for index = 2; index < idat.length() - 4; index = index + 1 {
    compressed.push(idat[index])
  }
  let bits = png_phase87_bits_new(Bytes::from_array(compressed))
  let final = bits.read(1)
  let block_type = bits.read(2)
  if final != 1 || block_type != (if expect_fixed { 1 } else { 0 }) {
    abort("png phase87 deflate block type")
  }
  let output : Array[Byte] = []
  if block_type == 0 {
    bits.align()
    let length = bits.read(8) | (bits.read(8) << 8)
    let inverse = bits.read(8) | (bits.read(8) << 8)
    if (length ^ inverse) != 65535 { abort("png phase87 stored length") }
    for index = 0; index < length; index = index + 1 { output.push(bits.read(8).to_byte()) }
  } else {
    let length_base = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258]
    let length_extra = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
    let distance_base = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577]
    let distance_extra = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]
    let mut done = false
    while !done {
      let symbol = png_phase87_fixed_symbol(bits)
      if symbol < 256 {
        output.push(symbol.to_byte())
      } else if symbol == 256 {
        done = true
      } else if symbol <= 285 {
        let length_index = symbol - 257
        let length = length_base[length_index] + bits.read(length_extra[length_index])
        let distance_code = png_phase87_reverse(bits.read(5), 5)
        if distance_code < 0 || distance_code >= 30 { abort("png phase87 distance code") }
        let distance = distance_base[distance_code] + bits.read(distance_extra[distance_code])
        if distance > output.length() { abort("png phase87 distance bounds") }
        for index = 0; index < length; index = index + 1 {
          output.push(output[output.length() - distance])
        }
      } else {
        abort("png phase87 length symbol")
      }
    }
  }
  Bytes::from_array(output)
}

fn png_phase87_adler32(raw : Bytes) -> UInt64 {
  let mut a = 1UL
  let mut b = 0UL
  for byte in raw {
    a = (a + byte.to_uint64()) % 65521UL
    b = (b + a) % 65521UL
  }
  (b << 16) | a
}

fn png_phase87_crc32(value : Bytes, start : Int, length : Int) -> UInt64 {
  let mut crc = 4294967295UL
  for index = 0; index < length; index = index + 1 {
    crc = crc ^ value[start + index].to_uint64()
    for index = 0; index < 8; index = index + 1 {
      crc = if (crc & 1UL) == 1UL { (crc >> 1) ^ 3988292384UL } else { crc >> 1 }
    }
  }
  crc ^ 4294967295UL
}

fn png_phase87_u32(value : Bytes, start : Int) -> UInt64 {
  (value[start].to_uint64() << 24) | (value[start + 1].to_uint64() << 16) |
    (value[start + 2].to_uint64() << 8) | value[start + 3].to_uint64()
}

fn png_phase87_slice(value : Bytes, start : Int, length : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = 0; index < length; index = index + 1 { result.push(value[start + index]) }
  Bytes::from_array(result)
}

fn png_phase87_expected_raw(depth : UInt64, stored_fallback : Bool) -> Bytes {
  let raw : Array[Byte] = [b'\x00']
  let packed_length = 64UL
  for index = 0UL; index < packed_length; index = index + 1UL {
    raw.push(if stored_fallback { (192UL + index).to_byte() } else { b'\x00' })
  }
  Bytes::from_array(raw)
}

///| Parse both eager and caller-collected Type-3 bytes without consulting the
/// encoder's frame facts, planner, matcher, or packing helpers.
fn png_phase87_parse_indexed(
  bytes : Bytes,
  depth : UInt64,
  expect_fixed : Bool,
  stored_fallback : Bool,
) -> Unit {
  let width = 512UL / depth
  let palette_entries = 1UL << depth.to_int()
  if bytes.length() < 8 || png_phase87_slice(bytes, 0, 8) != b"\x89PNG\r\n\x1a\n" {
    abort("png phase87 signature")
  }
  let idat : Array[Byte] = []
  let mut cursor = 8
  let mut stage = 0
  let mut saw_iend = false
  while cursor + 12 <= bytes.length() {
    let length = png_phase87_u32(bytes, cursor).to_int()
    if length < 0 || cursor + 12 + length > bytes.length() { abort("png phase87 chunk bounds") }
    let kind = png_phase87_slice(bytes, cursor + 4, 4)
    if png_phase87_crc32(bytes, cursor + 4, length + 4) != png_phase87_u32(bytes, cursor + 8 + length) {
      abort("png phase87 chunk crc")
    }
    if kind == b"IHDR" {
      if stage != 0 || length != 13 || png_phase87_u32(bytes, cursor + 8) != width ||
        png_phase87_u32(bytes, cursor + 12) != 1UL || bytes[cursor + 16] != depth.to_byte() ||
        bytes[cursor + 17] != b'\x03' || bytes[cursor + 18] != b'\x00' ||
        bytes[cursor + 19] != b'\x00' || bytes[cursor + 20] != b'\x00' {
        abort("png phase87 ihdr")
      }
      stage = 1
    } else if kind == b"PLTE" {
      if stage != 1 || length != (palette_entries * 3UL).to_int() { abort("png phase87 plte shape") }
      for entry = 0UL; entry < palette_entries; entry = entry + 1UL {
        let start = cursor + 8 + (entry * 3UL).to_int()
        if bytes[start] != entry.to_byte() || bytes[start + 1] != (entry + 1UL).to_byte() ||
          bytes[start + 2] != (entry + 2UL).to_byte() { abort("png phase87 plte value") }
      }
      stage = 2
    } else if kind == b"tRNS" {
      if stage != 2 || length != 1 || bytes[cursor + 8] != b'\x00' { abort("png phase87 trns") }
      stage = 3
    } else if kind == b"IDAT" {
      if stage != 2 && stage != 3 { abort("png phase87 idat order") }
      for index = 0; index < length; index = index + 1 { idat.push(bytes[cursor + 8 + index]) }
      stage = 4
    } else if kind == b"IEND" {
      if stage != 4 || length != 0 { abort("png phase87 iend") }
      saw_iend = true
      cursor = cursor + 12
      break
    } else {
      abort("png phase87 unexpected chunk")
    }
    cursor = cursor + 12 + length
  }
  if !saw_iend || cursor != bytes.length() || idat.length() < 7 { abort("png phase87 framing") }
  let idat_bytes = Bytes::from_array(idat)
  let raw = png_phase87_inflate(idat_bytes, expect_fixed)
  let expected = png_phase87_expected_raw(depth, stored_fallback)
  if raw != expected || png_phase87_u32(idat_bytes, idat_bytes.length() - 4) != png_phase87_adler32(raw) {
    abort("png phase87 raster or adler")
  }
}

fn png_phase87_eager_indexed(
  source : PngIndexedImage,
  depth : UInt64,
  strategy : PngCompressionStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  if depth == 8UL {
    ignore(PngEncoder::encode_indexed8_with_compression_strategy(
      PngEncoder::new(), source, strategy, writer as &@io.Writer,
      png_stream_test_limits(), png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
    ).unwrap())
  } else {
    let bit_depth = if depth == 1UL {
      PngIndexedBitDepth::One
    } else if depth == 2UL {
      PngIndexedBitDepth::Two
    } else {
      PngIndexedBitDepth::Four
    }
    ignore(PngEncoder::encode_indexed_with_compression_strategy(
      PngEncoder::new(), source, bit_depth, strategy, writer as &@io.Writer,
      png_stream_test_limits(), png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
    ).unwrap())
  }
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

fn png_phase87_chunk_indexed(
  source : PngIndexedImage,
  depth : UInt64,
  strategy : PngCompressionStrategy,
) -> PngChunkEncoder {
  if depth == 8UL {
    PngChunkEncoder::new_indexed8_with_compression_strategy(
      source, strategy, png_stream_test_limits(), png_stream_test_budget(work=4096UL),
      @error.Diagnostics::new(),
    ).unwrap()
  } else {
    let bit_depth = if depth == 1UL {
      PngIndexedBitDepth::One
    } else if depth == 2UL {
      PngIndexedBitDepth::Two
    } else {
      PngIndexedBitDepth::Four
    }
    PngChunkEncoder::new_indexed_with_compression_strategy(
      source, bit_depth, strategy, png_stream_test_limits(),
      png_stream_test_budget(work=4096UL), @error.Diagnostics::new(),
    ).unwrap()
  }
}

fn png_phase87_decode_matrix(bytes : Bytes, depth : UInt64, stored_fallback : Bool) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(bytes, png_stream_test_budget(work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(output=1048576UL, work=1048576UL),
    png_stream_test_budget(work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  if decoded.width() != 512UL / depth || decoded.height() != 1UL ||
    decoded.format().channels() != @model.ChannelOrder::Rgba {
    abort("png phase87 matrix rgba descriptor")
  }
  let per_byte = 8UL / depth
  for x = 0UL; x < 512UL / depth; x = x + 1UL {
    let packed = if stored_fallback { (192UL + x / per_byte).to_byte() } else { b'\x00' }
    let shift = 8UL - depth - (x % per_byte) * depth
    let code = ((packed.to_uint64() >> shift.to_int()) & ((1UL << depth.to_int()) - 1UL)).to_byte()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      if decoded.get_byte(x, 0UL, channel).unwrap() !=
        (code.to_uint64() + channel).to_byte() {
        abort("png phase87 matrix palette decode")
      }
    }
    let expected_alpha = if code == b'\x00' { b'\x00' } else { b'\xff' }
    if decoded.get_byte(x, 0UL, 3UL).unwrap() != expected_alpha {
      abort("png phase87 matrix alpha decode")
    }
  }
}

fn png_phase87_indexed_hostile_matrix(
  depth : UInt64,
  stored_fallback : Bool,
  strategy : PngCompressionStrategy,
  schedule : Array[UInt64],
) -> Unit {
  let source = png_phase87_indexed_matrix_source_depth(depth, stored_fallback)
  let expect_fixed = strategy is PngCompressionStrategy::FixedOrStored && !stored_fallback
  let eager = png_phase87_eager_indexed(source, depth, strategy)
  png_phase87_parse_indexed(eager, depth, expect_fixed, stored_fallback)
  png_phase87_decode_matrix(eager, depth, stored_fallback)
  let encoder = png_phase87_chunk_indexed(source, depth, strategy)
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(if capacity == 0UL { 1UL } else { capacity }, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png phase87 matrix accepted-only progress")
    }
    if capacity == 0UL && (pulled.written() != 0UL || pulled.total_written() != before ||
      !(pulled.outcome() is PngChunkPullOutcome::NeedOutput) || owner.view().get(0UL).unwrap() != b'Z') {
      abort("png phase87 matrix zero capacity")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png phase87 matrix sentinel tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png phase87 matrix drain failed")
      PngChunkPullOutcome::Finished => {
        let collected = Bytes::from_array(output)
        png_phase87_parse_indexed(collected, depth, expect_fixed, stored_fallback)
        png_phase87_decode_matrix(collected, depth, stored_fallback)
        if collected != eager { abort("png phase87 matrix eager/chunk parity") }
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png phase87 matrix sticky finished")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' { abort("png phase87 matrix finished tail") }
        }
        return ()
      }
    }
  }
  abort("png phase87 matrix drain unreachable")
}

fn png_phase87_released_matrix_failure(depth : UInt64, strategy : PngCompressionStrategy) -> Unit {
  let source = png_phase87_indexed_matrix_source_depth(depth, false)
  let encoder = png_phase87_chunk_indexed(source, depth, strategy)
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png phase87 matrix released outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png phase87 matrix released replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png phase87 matrix released terminal")
  }
}

///| Explicit Stored remains byte-identical to every frozen non-interlaced
///| legacy Indexed1/2/4/8 selector, including the complete matrix corpus.
test "PNG indexed compression Stored compatibility remains byte frozen" {
  for depth in [1UL, 2UL, 4UL] {
    let source = png_phase87_indexed_matrix_source_depth(depth, false)
    let legacy = png_stream_indexed_low_bit_eager(
      source,
      if depth == 1UL { PngIndexedBitDepth::One } else if depth == 2UL {
        PngIndexedBitDepth::Two
      } else {
        PngIndexedBitDepth::Four
      },
    )
    inspect(png_phase87_eager_indexed(source, depth, PngCompressionStrategy::Stored) == legacy, content="true")
  }
  let indexed8 = png_phase87_indexed_matrix_source_depth(8UL, false)
  inspect(
    png_phase87_eager_indexed(indexed8, 8UL, PngCompressionStrategy::Stored) ==
      png_stream_indexed_eager(indexed8),
    content="true",
  )
}

///| Every admitted indexed profile turns a released lease into the same
///| sticky zero-write failure on replay.
test "PNG indexed compression matrix released leases are sticky" {
  for depth in [1UL, 2UL, 4UL, 8UL] {
    for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
      png_phase87_released_matrix_failure(depth, strategy)
    }
  }
}

fn png_phase87_narrow_source(transparent : Bool) -> PngIndexedImage {
  PngIndexedImage::new(
    5UL, 3UL,
    b"\x00\x01\x02\x03\x00\x01\x02\x03\x00\x01\x02\x03\x00\x01\x02",
    b"\x10\x20\x30\x20\x30\x40\x30\x40\x50\x40\x50\x60",
    if transparent { b"\x00\x40\x80\xff" } else { b"\xff\xff\xff\xff" },
    png_stream_test_budget(),
  ).unwrap()
}

fn png_phase87_narrow_raw(transparent : Bool) -> Bytes {
  let rows = [
    [b'\x00', b'\x01', b'\x02', b'\x03', b'\x00'],
    [b'\x01', b'\x02', b'\x03', b'\x00', b'\x01'],
    [b'\x02', b'\x03', b'\x00', b'\x01', b'\x02'],
  ]
  let raw : Array[Byte] = []
  for row in rows {
    raw.push(b'\x00')
    let packed : Array[Byte] = [b'\x00', b'\x00']
    for x = 0UL; x < 5UL; x = x + 1UL {
      let shift = 6UL - (x % 4UL) * 2UL
      packed[(x / 4UL).to_int()] = packed[(x / 4UL).to_int()] |
        ((row[x.to_int()].to_uint64() & 3UL) << shift.to_int()).to_byte()
    }
    raw.push(packed[0]); raw.push(packed[1])
  }
  ignore(transparent)
  Bytes::from_array(raw)
}

fn png_phase87_parse_narrow(bytes : Bytes, transparent : Bool) -> Unit {
  if png_phase87_slice(bytes, 0, 8) != b"\x89PNG\r\n\x1a\n" { abort("png phase87 narrow signature") }
  let idat : Array[Byte] = []
  let mut cursor = 8
  let mut saw_iend = false
  let mut saw_trns = false
  while cursor + 12 <= bytes.length() {
    let length = png_phase87_u32(bytes, cursor).to_int()
    if length < 0 || cursor + 12 + length > bytes.length() { abort("png phase87 narrow bounds") }
    let kind = png_phase87_slice(bytes, cursor + 4, 4)
    if png_phase87_crc32(bytes, cursor + 4, length + 4) != png_phase87_u32(bytes, cursor + 8 + length) {
      abort("png phase87 narrow crc")
    }
    if kind == b"IHDR" {
      if length != 13 || png_phase87_u32(bytes, cursor + 8) != 5UL ||
        png_phase87_u32(bytes, cursor + 12) != 3UL || bytes[cursor + 16] != b'\x02' ||
        bytes[cursor + 17] != b'\x03' || bytes[cursor + 18] != b'\x00' ||
        bytes[cursor + 19] != b'\x00' || bytes[cursor + 20] != b'\x00' {
        abort("png phase87 narrow ihdr")
      }
    } else if kind == b"PLTE" {
      if length != 12 || png_phase87_slice(bytes, cursor + 8, 12) !=
        b"\x10\x20\x30\x20\x30\x40\x30\x40\x50\x40\x50\x60" {
        abort("png phase87 narrow plte")
      }
    } else if kind == b"tRNS" {
      if !transparent || length != 3 || png_phase87_slice(bytes, cursor + 8, 3) != b"\x00\x40\x80" {
        abort("png phase87 narrow trns")
      }
      saw_trns = true
    } else if kind == b"IDAT" {
      for index = 0; index < length; index = index + 1 { idat.push(bytes[cursor + 8 + index]) }
    } else if kind == b"IEND" {
      if length != 0 { abort("png phase87 narrow iend") }
      saw_iend = true
      cursor = cursor + 12
      break
    } else {
      abort("png phase87 narrow chunk")
    }
    cursor = cursor + 12 + length
  }
  if !saw_iend || cursor != bytes.length() || saw_trns != transparent { abort("png phase87 narrow framing") }
  let idat_bytes = Bytes::from_array(idat)
  let raw = png_phase87_inflate(idat_bytes, false)
  if raw != png_phase87_narrow_raw(transparent) ||
    png_phase87_u32(idat_bytes, idat_bytes.length() - 4) != png_phase87_adler32(raw) {
    abort("png phase87 narrow stored raster")
  }
}

fn png_phase87_decode_narrow(bytes : Bytes, transparent : Bool) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(bytes, png_stream_test_budget(work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(output=4096UL, work=1048576UL),
    png_stream_test_budget(work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  let expected_channels = if transparent { @model.ChannelOrder::Rgba } else { @model.ChannelOrder::Rgb }
  if decoded.width() != 5UL || decoded.height() != 3UL || decoded.format().channels() != expected_channels {
    abort("png phase87 narrow decode descriptor")
  }
  let codes = b"\x00\x01\x02\x03\x00\x01\x02\x03\x00\x01\x02\x03\x00\x01\x02"
  let palette = b"\x10\x20\x30\x20\x30\x40\x30\x40\x50\x40\x50\x60"
  let alpha = if transparent { b"\x00\x40\x80\xff" } else { b"\xff\xff\xff\xff" }
  for point = 0; point < 15; point = point + 1 {
    let code = codes[point].to_int()
    let x = (point % 5).to_uint64()
    let y = (point / 5).to_uint64()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      if decoded.get_byte(x, y, channel).unwrap() != palette[code * 3 + channel.to_int()] {
        abort("png phase87 narrow palette decode")
      }
    }
    if transparent && decoded.get_byte(x, y, 3UL).unwrap() != alpha[code] {
      abort("png phase87 narrow alpha decode")
    }
  }
}

///| Odd-width packed tails remain zero and the public decoder exposes RGB8
///| for opaque palettes and RGBA8 for partial-alpha palettes.
test "PNG indexed compression narrow packed tails and public decode" {
  for transparent in [false, true] {
    let source = png_phase87_narrow_source(transparent)
    let eager = png_phase87_eager_indexed(source, 2UL, PngCompressionStrategy::Stored)
    png_phase87_parse_narrow(eager, transparent)
    png_phase87_decode_narrow(eager, transparent)
  }
}

///| All indexed depths and both admitted plans use independent eager/chunk
///| framing, DEFLATE, packed-raster, decode, and hostile-lease evidence.
test "PNG indexed compression hostile matrix independent qualification" {
  for depth in [1UL, 2UL, 4UL, 8UL] {
    for stored_fallback in [false, true] {
      for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
        for schedule in [[0UL, 1UL], [1UL], [0UL, 1UL, 3UL, 2UL, 5UL]] {
          png_phase87_indexed_hostile_matrix(depth, stored_fallback, strategy, schedule)
        }
      }
    }
  }
}

///| Every selected Type-3 depth keeps eager parity and lease ownership under
///| zero-capacity, one-byte, and ragged caller schedules.
test "PNG selected Indexed chunk hostile leases retain eager parity and sticky completion" {
  for bit_depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    png_stream_indexed_low_bit_hostile_drain(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth, [0UL, 1UL],
    )
    png_stream_indexed_low_bit_hostile_drain(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth, [1UL],
    )
    png_stream_indexed_low_bit_hostile_drain(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth,
      [0UL, 1UL, 3UL, 2UL, 5UL],
    )
  }
}

///| Phase 83 only proves that the selected low-bit Adam7 facade reaches the
/// existing machine with an ordinary sufficient-capacity lease.
test "PNG selected low-bit Adam7 chunk selector wires shared machine IHDR" {
  for bit_depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    let encoder = PngChunkEncoder::new_indexed_with_interlace_strategy(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth, PngInterlaceStrategy::Adam7,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let bytes = png_chunk_test_drain_encoder(encoder, [256UL]).unwrap()
    let depth = match bit_depth {
      PngIndexedBitDepth::One => b'\x01'
      PngIndexedBitDepth::Two => b'\x02'
      PngIndexedBitDepth::Four => b'\x04'
    }
    inspect(
      bytes[24] == depth && bytes[25] == b'\x03' && bytes[26] == b'\x00' &&
        bytes[27] == b'\x00' && bytes[28] == b'\x01',
      content="true",
    )
  }
}

///| The Phase-83 Type-3/1 fixture is deliberately independent test data: it
///| is a non-symmetric 5x5 source with a transparent palette entry.
fn png_stream_indexed_low_bit_adam7_one_source() -> PngIndexedImage {
  PngIndexedImage::new(
    5UL, 5UL,
    b"\x00\x01\x00\x01\x01\x01\x00\x01\x01\x00\x01\x01\x00\x00\x01\x00\x01\x01\x00\x00\x01\x00\x00\x01\x01",
    b"\x10\x20\x30\x40\x50\x60", b"\x00\x80", png_stream_test_budget(),
  ).unwrap()
}

///| Produces a fresh explicit Adam7 eager reference only for the lifecycle
///| parity comparison; the wire oracle below reads the collected stream bytes.
fn png_stream_indexed_low_bit_adam7_one_eager() -> Bytes {
  let writer = @io.MemoryWriter::new(
    256UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  ignore(PngEncoder::encode_indexed_with_interlace_strategy(
    PngEncoder::new(), png_stream_indexed_low_bit_adam7_one_source(),
    PngIndexedBitDepth::One, PngInterlaceStrategy::Adam7, writer as &@io.Writer,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///| Independently checks the complete collected Type-3/1 Adam7 frame, its
///| Stored pass raster, and public transparent palette decode.
fn png_stream_indexed_low_bit_adam7_one_chunk_origin_qualification(bytes : Bytes) -> Unit {
  let codes = b"\x00\x01\x00\x01\x01\x01\x00\x01\x01\x00\x01\x01\x00\x00\x01\x00\x01\x01\x00\x00\x01\x00\x00\x01\x01"
  let palette = b"\x10\x20\x30\x40\x50\x60"
  let alpha = b"\x00\x80"
  let raw = b"\x00\x00\x00\x80\x00\xc0\x00\x00\x00\x00\x00\xa0\x00\xc0\x00\x80\x00\x40\x00\xb0\x00\x60"
  if bytes.length() != 122 || png_indexed_slice(bytes, 0, 8) != b"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a" ||
    png_indexed_u32(bytes, 8) != 13UL || png_indexed_slice(bytes, 12, 4) != b"IHDR" ||
    png_indexed_slice(bytes, 16, 13) != b"\x00\x00\x00\x05\x00\x00\x00\x05\x01\x03\x00\x00\x01" ||
    png_indexed_crc32(bytes, 12, 17) != png_indexed_u32(bytes, 29) {
    abort("png selected Indexed1 Adam7 chunk IHDR")
  }
  if png_indexed_u32(bytes, 33) != 6UL || png_indexed_slice(bytes, 37, 4) != b"PLTE" ||
    png_indexed_slice(bytes, 41, 6) != palette ||
    png_indexed_crc32(bytes, 37, 10) != png_indexed_u32(bytes, 47) {
    abort("png selected Indexed1 Adam7 chunk PLTE")
  }
  if png_indexed_u32(bytes, 51) != 2UL || png_indexed_slice(bytes, 55, 4) != b"tRNS" ||
    png_indexed_slice(bytes, 59, 2) != alpha ||
    png_indexed_crc32(bytes, 55, 6) != png_indexed_u32(bytes, 61) {
    abort("png selected Indexed1 Adam7 chunk tRNS")
  }
  if png_indexed_u32(bytes, 65) != 33UL || png_indexed_slice(bytes, 69, 4) != b"IDAT" ||
    png_indexed_crc32(bytes, 69, 37) != png_indexed_u32(bytes, 106) ||
    png_indexed_u32(bytes, 110) != 0UL || png_indexed_slice(bytes, 114, 4) != b"IEND" ||
    png_indexed_crc32(bytes, 114, 4) != png_indexed_u32(bytes, 118) ||
    png_encode_public_stored_scanlines(bytes, 22) != raw {
    abort("png selected Indexed1 Adam7 chunk IDAT or IEND")
  }
  png_stream_indexed_low_bit_adam7_assert_literal_passes(
    raw, codes, PngIndexedBitDepth::One,
  )
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_stream_test_budget(work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(output=256UL, work=1048576UL),
    png_stream_test_budget(work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  if decoded.width() != 5UL || decoded.height() != 5UL ||
    decoded.format().channels() != @model.ChannelOrder::Rgba {
    abort("png selected Indexed1 Adam7 decoded descriptor")
  }
  for point = 0; point < 25; point = point + 1 {
    let code = codes[point].to_int()
    let x = (point % 5).to_uint64()
    let y = (point / 5).to_uint64()
    for channel = 0; channel < 3; channel = channel + 1 {
      if decoded.get_byte(x, y, channel.to_uint64()).unwrap() != palette[code * 3 + channel] {
        abort("png selected Indexed1 Adam7 decoded palette")
      }
    }
    if decoded.get_byte(x, y, 3UL).unwrap() != alpha[code] {
      abort("png selected Indexed1 Adam7 decoded alpha")
    }
  }
}

///| Drives the admitted selected-depth Adam7 chunk selector under a hostile
///| caller-owned schedule. A zero-capacity lease still owns one `Z` sentinel.
fn png_stream_indexed_low_bit_adam7_hostile_drain(
  bit_depth : PngIndexedBitDepth,
  schedule : Array[UInt64],
) -> Unit {
  if bit_depth != PngIndexedBitDepth::One {
    return png_stream_indexed_low_bit_adam7_full_hostile_drain(bit_depth, schedule)
  }
  let expected = png_stream_indexed_low_bit_adam7_one_eager()
  let encoder = PngChunkEncoder::new_indexed_with_interlace_strategy(
    png_stream_indexed_low_bit_adam7_one_source(), bit_depth, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(if capacity == 0UL { 1UL } else { capacity }, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png selected Indexed1 Adam7 accepted-only progress")
    }
    if capacity == 0UL && (pulled.written() != 0UL || pulled.total_written() != before ||
      !(pulled.outcome() is PngChunkPullOutcome::NeedOutput) || owner.view().get(0UL).unwrap() != b'Z') {
      abort("png selected Indexed1 Adam7 zero lease")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png selected Indexed1 Adam7 tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png selected Indexed1 Adam7 drain failed")
      PngChunkPullOutcome::Finished => {
        let collected = Bytes::from_array(output)
        if collected != expected { abort("png selected Indexed1 Adam7 eager parity") }
        png_stream_indexed_low_bit_adam7_one_chunk_origin_qualification(collected)
        png_stream_indexed_low_bit_adam7_opaque_decode(PngIndexedBitDepth::One)
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png selected Indexed1 Adam7 completed terminal")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' {
            abort("png selected Indexed1 Adam7 completed tail")
          }
        }
        return ()
      }
    }
  }
  abort("png selected Indexed1 Adam7 hostile drain unreachable")
}

///| The selected Indexed1 Adam7 stream must retain caller ownership and prove
///| its completed bytes through an independent Type-3 Adam7 wire oracle.
test "PNG selected Indexed1 Adam7 chunk hostile leases qualify stream-origin bytes" {
  png_stream_indexed_low_bit_adam7_hostile_drain(PngIndexedBitDepth::One, [0UL, 1UL])
}

///| Supplies literal Phase-83 source, palette, alpha, and raw Adam7 pass data
///| for each selected Type-3 depth without consulting production traversal.
fn png_stream_indexed_low_bit_adam7_facts(
  bit_depth : PngIndexedBitDepth,
) -> (Bytes, Bytes, Bytes, Bytes, Int) {
  match bit_depth {
    PngIndexedBitDepth::One => (
      b"\x00\x01\x00\x01\x01\x01\x00\x01\x01\x00\x01\x01\x00\x00\x01\x00\x01\x01\x00\x00\x01\x00\x00\x01\x01",
      b"\x10\x20\x30\x40\x50\x60", b"\x00\x80",
      b"\x00\x00\x00\x80\x00\xc0\x00\x00\x00\x00\x00\xa0\x00\xc0\x00\x80\x00\x40\x00\xb0\x00\x60", 122,
    )
    PngIndexedBitDepth::Two => (
      b"\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00",
      b"\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0", b"\x00\x40\x80\xc0",
      b"\x00\x00\x00\x00\x00\x00\x00\x80\x00\x80\x00\x20\x00\x70\x00\x70\x00\x70\x00\xb1\x80\x00\xb1\x80", 132,
    )
    PngIndexedBitDepth::Four => (
      b"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x00\x01\x02\x03\x04\x05\x06\x07\x08",
      b"\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0\xd0\xe0\xf0\x01\x11\x21\x31\x41\x51\x61\x71\x81\x91\xa1\xb1\xc1\xd1\xe1\xf1\x02\x12\x22\x32\x42\x52\x62\x72\x82\x92\xa2\xb2\xc2\xd2\xe2\xf2\x03",
      b"\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99\xaa\xbb\xcc\xdd\xee\x7f",
      b"\x00\x00\x00\x40\x00\x48\x00\x20\x00\x60\x00\xac\xe0\x00\x13\x00\xbd\x00\x57\x00\x56\x78\x90\x00\xf0\x12\x30", 183,
    )
  }
}

///| Builds an explicit selected-depth Adam7 source; opaque consumers receive
///| an all-opaque tRNS table while preserving the canonical index literals.
fn png_stream_indexed_low_bit_adam7_source(
  bit_depth : PngIndexedBitDepth,
  transparent : Bool,
) -> PngIndexedImage {
  let (codes, palette, alpha, _, _) = png_stream_indexed_low_bit_adam7_facts(bit_depth)
  PngIndexedImage::new(
    5UL, 5UL, codes, palette,
    if transparent { alpha } else { Bytes::from_array(Array::make(alpha.length(), b'\xff')) },
    png_stream_test_budget(),
  ).unwrap()
}

///| Fresh eager bytes remain a lifecycle parity check and are never supplied
///| to the independent stream frame, raster, or decode oracle.
fn png_stream_indexed_low_bit_adam7_eager(bit_depth : PngIndexedBitDepth) -> Bytes {
  let writer = @io.MemoryWriter::new(256UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(PngEncoder::encode_indexed_with_interlace_strategy(
    PngEncoder::new(), png_stream_indexed_low_bit_adam7_source(bit_depth, true), bit_depth,
    PngInterlaceStrategy::Adam7, writer as &@io.Writer, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///| Recomputes the 5x5 Adam7 local pass geometry and MSB-first packed bytes.
///| Partial data bytes are compared exactly, so their unused low tail bits must be zero.
fn png_stream_indexed_low_bit_adam7_assert_literal_passes(
  raw : Bytes,
  codes : Bytes,
  bit_depth : PngIndexedBitDepth,
) -> Unit {
  let depth = match bit_depth {
    PngIndexedBitDepth::One => 1UL
    PngIndexedBitDepth::Two => 2UL
    PngIndexedBitDepth::Four => 4UL
  }
  let passes = [
    (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
    (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
    (0UL, 1UL, 1UL, 2UL),
  ]
  let mut cursor = 0
  for pass in passes {
    let (start_x, start_y, step_x, step_y) = pass
    let columns = if start_x >= 5UL { 0UL } else { (4UL - start_x) / step_x + 1UL }
    let rows = if start_y >= 5UL { 0UL } else { (4UL - start_y) / step_y + 1UL }
    let row_bytes = (columns * depth + 7UL) / 8UL
    let pixels_per_byte = 8UL / depth
    for row = 0UL; row < rows; row = row + 1UL {
      if raw[cursor] != b'\x00' { abort("png selected low-bit Adam7 pass filter") }
      cursor = cursor + 1
      for byte_index = 0UL; byte_index < row_bytes; byte_index = byte_index + 1UL {
        let mut packed = 0UL
        for slot = 0UL; slot < pixels_per_byte; slot = slot + 1UL {
          let local_x = byte_index * pixels_per_byte + slot
          if local_x < columns {
            let x = start_x + local_x * step_x
            let y = start_y + row * step_y
            let code = codes[(y * 5UL + x).to_int()].to_uint64()
            packed = packed | (code << (8UL - depth * (slot + 1UL)).to_int())
          }
        }
        if raw[cursor] != packed.to_byte() {
          abort("png selected low-bit Adam7 pass packing or tail")
        }
        cursor = cursor + 1
      }
    }
  }
  if cursor != raw.length() { abort("png selected low-bit Adam7 pass length") }
}

///| Parses stream-origin chunks with local lengths and CRCs before comparing
///| test-local Stored bytes and decoding the transparent public RGBA8 result.
fn png_stream_indexed_low_bit_adam7_chunk_origin_qualification(
  bytes : Bytes,
  bit_depth : PngIndexedBitDepth,
) -> Unit {
  let (codes, palette, alpha, raw, expected_length) = png_stream_indexed_low_bit_adam7_facts(bit_depth)
  let depth = match bit_depth {
    PngIndexedBitDepth::One => b'\x01'
    PngIndexedBitDepth::Two => b'\x02'
    PngIndexedBitDepth::Four => b'\x04'
  }
  let plte_start = 33
  let trns_start = plte_start + 12 + palette.length()
  let idat_start = trns_start + 12 + alpha.length()
  let idat_length = raw.length() + 11
  let iend_start = idat_start + 12 + idat_length
  if bytes.length() != expected_length || png_indexed_slice(bytes, 0, 8) != b"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a" ||
    png_indexed_u32(bytes, 8) != 13UL || png_indexed_slice(bytes, 12, 4) != b"IHDR" ||
    png_indexed_slice(bytes, 16, 13) != Bytes::from_array([
      b'\x00', b'\x00', b'\x00', b'\x05', b'\x00', b'\x00', b'\x00', b'\x05', depth,
      b'\x03', b'\x00', b'\x00', b'\x01',
    ]) || png_indexed_crc32(bytes, 12, 17) != png_indexed_u32(bytes, 29) {
    abort("png selected low-bit Adam7 chunk IHDR")
  }
  if png_indexed_u32(bytes, plte_start) != palette.length().to_uint64() ||
    png_indexed_slice(bytes, plte_start + 4, 4) != b"PLTE" ||
    png_indexed_slice(bytes, plte_start + 8, palette.length()) != palette ||
    png_indexed_crc32(bytes, plte_start + 4, 4 + palette.length()) !=
      png_indexed_u32(bytes, plte_start + 8 + palette.length()) {
    abort("png selected low-bit Adam7 chunk PLTE")
  }
  if png_indexed_u32(bytes, trns_start) != alpha.length().to_uint64() ||
    png_indexed_slice(bytes, trns_start + 4, 4) != b"tRNS" ||
    png_indexed_slice(bytes, trns_start + 8, alpha.length()) != alpha ||
    png_indexed_crc32(bytes, trns_start + 4, 4 + alpha.length()) !=
      png_indexed_u32(bytes, trns_start + 8 + alpha.length()) {
    abort("png selected low-bit Adam7 chunk tRNS")
  }
  if png_indexed_u32(bytes, idat_start) != idat_length.to_uint64() ||
    png_indexed_slice(bytes, idat_start + 4, 4) != b"IDAT" ||
    png_indexed_crc32(bytes, idat_start + 4, 4 + idat_length) !=
      png_indexed_u32(bytes, idat_start + 8 + idat_length) ||
    png_indexed_u32(bytes, iend_start) != 0UL || png_indexed_slice(bytes, iend_start + 4, 4) != b"IEND" ||
    png_indexed_crc32(bytes, iend_start + 4, 4) != png_indexed_u32(bytes, iend_start + 8) ||
    png_encode_public_stored_scanlines(bytes, raw.length()) != raw {
    abort("png selected low-bit Adam7 chunk IDAT or IEND")
  }
  png_stream_indexed_low_bit_adam7_assert_literal_passes(raw, codes, bit_depth)
  let owner = @bytes.OwnedBytes::from_bytes(bytes, png_stream_test_budget(work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(output=256UL, work=1048576UL),
    png_stream_test_budget(work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  if decoded.format().channels() != @model.ChannelOrder::Rgba { abort("png selected low-bit Adam7 RGBA decode") }
  for point = 0; point < 25; point = point + 1 {
    let code = codes[point].to_int()
    let x = (point % 5).to_uint64()
    let y = (point / 5).to_uint64()
    for channel = 0; channel < 3; channel = channel + 1 {
      if decoded.get_byte(x, y, channel.to_uint64()).unwrap() != palette[code * 3 + channel] {
        abort("png selected low-bit Adam7 RGBA palette")
      }
    }
    if decoded.get_byte(x, y, 3UL).unwrap() != alpha[code] { abort("png selected low-bit Adam7 RGBA alpha") }
  }
}

///| The opaque caller-buffered stream proves the public decoder exposes RGB8
///| palette values rather than an artificial alpha channel.
fn png_stream_indexed_low_bit_adam7_opaque_decode(bit_depth : PngIndexedBitDepth) -> Unit {
  let (codes, palette, _, _, _) = png_stream_indexed_low_bit_adam7_facts(bit_depth)
  let encoder = PngChunkEncoder::new_indexed_with_interlace_strategy(
    png_stream_indexed_low_bit_adam7_source(bit_depth, false), bit_depth,
    PngInterlaceStrategy::Adam7, png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let bytes = png_chunk_test_drain_encoder(encoder, [256UL]).unwrap()
  let owner = @bytes.OwnedBytes::from_bytes(bytes, png_stream_test_budget(work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(output=256UL, work=1048576UL),
    png_stream_test_budget(work=1048576UL), @error.Diagnostics::new(),
  ).unwrap().image().view()
  if decoded.format().channels() != @model.ChannelOrder::Rgb { abort("png selected low-bit Adam7 RGB decode") }
  for point = 0; point < 25; point = point + 1 {
    let code = codes[point].to_int()
    let x = (point % 5).to_uint64()
    let y = (point / 5).to_uint64()
    for channel = 0; channel < 3; channel = channel + 1 {
      if decoded.get_byte(x, y, channel.to_uint64()).unwrap() != palette[code * 3 + channel] {
        abort("png selected low-bit Adam7 RGB palette")
      }
    }
  }
}

///| Runs the full caller-owned matrix for the expanded Two/Four selected-depth
///| routes, retaining the same accepted-only and sentinel contracts as the tracer.
fn png_stream_indexed_low_bit_adam7_full_hostile_drain(
  bit_depth : PngIndexedBitDepth,
  schedule : Array[UInt64],
) -> Unit {
  let expected = png_stream_indexed_low_bit_adam7_eager(bit_depth)
  let encoder = PngChunkEncoder::new_indexed_with_interlace_strategy(
    png_stream_indexed_low_bit_adam7_source(bit_depth, true), bit_depth,
    PngInterlaceStrategy::Adam7, png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(if capacity == 0UL { 1UL } else { capacity }, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png selected low-bit Adam7 accepted-only progress")
    }
    if capacity == 0UL && (pulled.written() != 0UL || pulled.total_written() != before ||
      !(pulled.outcome() is PngChunkPullOutcome::NeedOutput) || owner.view().get(0UL).unwrap() != b'Z') {
      abort("png selected low-bit Adam7 zero lease")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL { output.push(owner.view().get(index).unwrap()) }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png selected low-bit Adam7 tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png selected low-bit Adam7 drain failed")
      PngChunkPullOutcome::Finished => {
        let collected = Bytes::from_array(output)
        if collected != expected { abort("png selected low-bit Adam7 eager parity") }
        png_stream_indexed_low_bit_adam7_chunk_origin_qualification(collected, bit_depth)
        png_stream_indexed_low_bit_adam7_opaque_decode(bit_depth)
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png selected low-bit Adam7 completed terminal")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' { abort("png selected low-bit Adam7 completed tail") }
        }
        return ()
      }
    }
  }
  abort("png selected low-bit Adam7 hostile drain unreachable")
}

///| A released first selected-depth Adam7 lease must cache the same zero-write
///| failure while preserving both original and later caller-owned sentinels.
fn png_stream_indexed_low_bit_adam7_released_failure(bit_depth : PngIndexedBitDepth) -> Unit {
  let encoder = PngChunkEncoder::new_indexed_with_interlace_strategy(
    png_stream_indexed_low_bit_adam7_source(bit_depth, true), bit_depth,
    PngInterlaceStrategy::Adam7, png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) { lease.release(); Ok(encoder.pull(lease)) }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png selected low-bit Adam7 released lease outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png selected low-bit Adam7 released lease replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png selected low-bit Adam7 released lease terminal")
  }
}

///| Every selected low-bit Adam7 stream must retain hostile lease semantics
///| and independently prove the literal packed pass raster.
test "PNG selected low-bit Adam7 chunk qualifies every hostile lease schedule" {
  for bit_depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    png_stream_indexed_low_bit_adam7_hostile_drain(bit_depth, [0UL, 1UL])
    png_stream_indexed_low_bit_adam7_hostile_drain(bit_depth, [1UL])
    png_stream_indexed_low_bit_adam7_hostile_drain(bit_depth, [0UL, 1UL, 3UL, 2UL, 5UL])
  }
}

///| A released selected-depth Adam7 lease remains a sticky zero-write failure.
test "PNG selected low-bit Adam7 chunk replays released lease failures" {
  for bit_depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    png_stream_indexed_low_bit_adam7_released_failure(bit_depth)
  }
}

///| Every selected Type-3 depth replays a released first lease as the same
///| terminal failure without mutating a later caller-owned lease.
test "PNG selected Indexed chunk replays released lease failures" {
  for bit_depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    png_stream_indexed_low_bit_released_failure(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth,
    )
  }
}

///| Selected-depth construction rejects output, pixel, and work requests before
///| a lease can be exposed or any caller-supplied budget resource is charged.
test "PNG selected Indexed chunk admission is atomic" {
  for bit_depth in [
    PngIndexedBitDepth::One, PngIndexedBitDepth::Two, PngIndexedBitDepth::Four,
  ] {
    let output_budget = png_stream_test_budget()
    let output_before = output_budget.remaining()
    inspect(PngChunkEncoder::new_indexed(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth,
      png_stream_test_limits(output=1UL), output_budget, @error.Diagnostics::new(),
    ) is Err(_), content="true")
    inspect(
      png_adam7_stream_same_remaining(output_before, output_budget.remaining()), content="true",
    )
    let zero_pixels = @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=1048576UL, allocations=16UL, allocation_size=1048576UL,
      width=70000UL, height=8UL, pixels=0UL, depth=0UL, work=1048576UL,
    ))
    let pixels_before = zero_pixels.remaining()
    inspect(PngChunkEncoder::new_indexed(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth,
      png_stream_test_limits(), zero_pixels, @error.Diagnostics::new(),
    ) is Err(_), content="true")
    inspect(
      png_adam7_stream_same_remaining(pixels_before, zero_pixels.remaining()), content="true",
    )
    let work_budget = png_stream_test_budget(work=0UL)
    let work_before = work_budget.remaining()
    inspect(PngChunkEncoder::new_indexed(
      png_stream_indexed_low_bit_source(bit_depth), bit_depth,
      png_stream_test_limits(), work_budget, @error.Diagnostics::new(),
    ) is Err(_), content="true")
    inspect(
      png_adam7_stream_same_remaining(work_before, work_budget.remaining()), content="true",
    )
  }
}

///| Fresh Indexed8 machines retain accepted-only progress, caller tails, eager
/// identity, and the sticky completed terminal under hostile leases.
fn png_stream_indexed_hostile_drain(
  source : PngIndexedImage,
  schedule : Array[UInt64],
) -> Unit {
  let expected = png_stream_indexed_eager(source)
  let encoder = PngChunkEncoder::new_indexed8(
    source, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 4096UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png indexed8 hostile accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    for index = pulled.written(); index < capacity; index = index + 1UL {
      if owner.view().get(index).unwrap() != b'Z' { abort("png indexed8 hostile tail") }
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png indexed8 hostile drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != expected { abort("png indexed8 hostile eager parity") }
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
          !(replay.outcome() is PngChunkPullOutcome::Finished) {
          abort("png indexed8 sticky completed terminal")
        }
        for index = 0UL; index < 7UL; index = index + 1UL {
          if later.view().get(index).unwrap() != b'Z' { abort("png indexed8 completed tail") }
        }
        return ()
      }
    }
  }
  abort("png indexed8 hostile drain unreachable")
}

///| Opaque and transparent Indexed8 chunks must preserve zero, one-byte, and
/// ragged caller-owned lease semantics with no second encoder path.
test "PNG Indexed8 chunk hostile leases retain eager parity and sticky completion" {
  for transparent in [false, true] {
    png_stream_indexed_hostile_drain(png_stream_indexed_source(transparent), [0UL, 1UL])
    png_stream_indexed_hostile_drain(png_stream_indexed_source(transparent), [1UL])
    png_stream_indexed_hostile_drain(
      png_stream_indexed_source(transparent), [0UL, 1UL, 3UL, 2UL, 5UL],
    )
  }
}

///| A released first lease becomes a sticky zero-write error and cannot mutate
/// a later caller-owned Indexed8 destination.
test "PNG Indexed8 chunk replays released lease failures" {
  let encoder = PngChunkEncoder::new_indexed8(
    png_stream_indexed_source(true), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed8 released lease outcome")
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed8 released lease replay")
  }
  if first.written() != 0UL || first.total_written() != 0UL || replay.written() != 0UL ||
    replay.total_written() != 0UL || !png_chunk_test_same_error(first_error, replay_error) ||
    released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed8 released lease terminal")
  }
}

///| Splitting a caller lease consumes its parent without invalidating its live
/// children: an inactive parent makes the encoder terminally fail, while a
/// fresh encoder can write through a child window and releases it on return.
test "PNG Indexed8 chunk respects split lease parent and child ownership" {
  let failed_encoder = PngChunkEncoder::new_indexed8(
    png_stream_indexed_source(true), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let parent_owner = png_chunk_test_owner(3UL, fill=b'Z')
  let parent_pull = parent_owner.with_mut(0UL, 3UL, fn(parent) {
    let (_left, _right) = parent.split_mut(1UL).unwrap()
    Ok(failed_encoder.pull(parent))
  }).unwrap()
  let parent_error = match parent_pull.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed8 split parent outcome")
  }
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) { Ok(failed_encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png indexed8 split parent replay")
  }
  if parent_pull.written() != 0UL || parent_pull.total_written() != 0UL ||
    replay.written() != 0UL || replay.total_written() != 0UL ||
    !png_chunk_test_same_error(parent_error, replay_error) {
    abort("png indexed8 split parent terminal")
  }
  for index = 0UL; index < 3UL; index = index + 1UL {
    if parent_owner.view().get(index).unwrap() != b'Z' {
      abort("png indexed8 split parent changed sentinel")
    }
  }
  if replay_owner.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed8 split parent replay changed sentinel")
  }

  let encoder = PngChunkEncoder::new_indexed8(
    png_stream_indexed_source(false), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let child_owner = png_chunk_test_owner(5UL, fill=b'Z')
  let child_pull = child_owner.with_mut(0UL, 5UL, fn(parent) {
    let (_left, right) = parent.split_mut(4UL).unwrap()
    Ok(encoder.pull(right))
  }).unwrap()
  if child_pull.written() != 1UL ||
    child_pull.total_written() != child_pull.written() ||
    child_owner.view().get(0UL).unwrap() != b'Z' {
    abort("png indexed8 split child window")
  }
  let signature = b"\x89PNG\r\n\x1a\n"
  for index = 0UL; index < child_pull.written(); index = index + 1UL {
    if child_owner.view().get(4UL + index).unwrap() != signature[index.to_int()] {
      abort("png indexed8 split child PNG prefix")
    }
  }
  for index = 0UL; index < 4UL; index = index + 1UL {
    if child_owner.view().get(index).unwrap() != b'Z' {
      abort("png indexed8 split child tail")
    }
  }
  ignore(child_owner.with_mut(0UL, 5UL, fn(_lease) { Ok(()) }).unwrap())
  let next_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let next = next_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if next.written() != 1UL || next.total_written() != child_pull.written() + 1UL ||
    !(next.outcome() is PngChunkPullOutcome::NeedOutput) ||
    next_owner.view().get(0UL).unwrap() != b'P' {
    abort("png indexed8 split child encoder retained lease")
  }
}

///| Indexed8 construction rejects output, pixel, and work requests before a
/// lease can be exposed or any caller-supplied budget resource is charged.
test "PNG Indexed8 chunk admission is atomic" {
  let output_budget = png_stream_test_budget()
  let output_before = output_budget.remaining()
  inspect(PngChunkEncoder::new_indexed8(
    png_stream_indexed_source(true), png_stream_test_limits(output=111UL), output_budget,
    @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(
    png_adam7_stream_same_remaining(output_before, output_budget.remaining()), content="true",
  )
  let zero_pixels = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL, allocations=16UL, allocation_size=1048576UL,
    width=70000UL, height=8UL, pixels=0UL, depth=0UL, work=1048576UL,
  ))
  let pixels_before = zero_pixels.remaining()
  inspect(PngChunkEncoder::new_indexed8(
    png_stream_indexed_source(false), png_stream_test_limits(), zero_pixels,
    @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(
    png_adam7_stream_same_remaining(pixels_before, zero_pixels.remaining()), content="true",
  )
  let work_budget = png_stream_test_budget(work=111UL)
  let work_before = work_budget.remaining()
  inspect(PngChunkEncoder::new_indexed8(
    png_stream_indexed_source(true), png_stream_test_limits(), work_budget,
    @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(
    png_adam7_stream_same_remaining(work_before, work_budget.remaining()), content="true",
  )
}
