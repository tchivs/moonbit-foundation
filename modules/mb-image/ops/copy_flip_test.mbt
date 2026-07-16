///|
fn operation_limits(bytes : UInt64, work : UInt64) -> @budget.Budget {
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
fn operation_metadata(
  alpha : @color.AlphaMode?,
  orientation : @model.Orientation,
) -> @model.ImageMetadata {
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [("test", "marker", "raw", b"kept")],
    @metadata.MetadataLimits::new(
      max_entries=1UL,
      max_token_bytes=16UL,
      max_value_bytes=4UL,
      max_total_bytes=32UL,
      max_disposition_fields=8UL,
    ),
    operation_limits(4UL, 0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    alpha,
    @profile.ProfileIdentity::builtin_srgb(),
    orientation,
    opaque,
  )
}

///|
fn padded_image(
  channels : UInt64,
  alpha : @color.AlphaMode?,
  orientation : @model.Orientation,
) -> @storage.OwnedImage {
  let width = 2UL
  let height = 2UL
  let row_bytes = width * channels
  let stride = row_bytes + 2UL
  let start = 1UL
  let plane_length = stride + row_bytes
  let storage_length = start + plane_length + 1UL
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
        start,
        plane_length,
        stride,
        row_bytes,
        1UL,
        1UL,
        width,
        height,
      ).unwrap(),
    ],
    storage_length,
    operation_metadata(alpha, orientation),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    operation_limits(storage_length, 0UL),
  ).unwrap()
  image
    .with_mut_view(fn(view) {
      for y = 0UL; y < height; y = y + 1UL {
        for x = 0UL; x < width; x = x + 1UL {
          for channel = 0UL; channel < channels; channel = channel + 1UL {
            let value = ((y * width + x) * channels + channel + 1UL).to_byte()
            match view.set_byte(x, y, channel, value) {
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
test "copy packs logical rows for every supported U8 format" {
  for alpha in [
    None,
    Some(@color.AlphaMode::Straight),
    Some(@color.AlphaMode::Premultiplied),
  ] {
    let channels = if alpha is None { 3UL } else { 4UL }
    let source = padded_image(channels, alpha, @model.Orientation::RightBottom)
    let result = @ops.copy_image(
      source.view(),
      operation_limits(2UL * 2UL * channels, 2UL * 2UL * channels),
    ).unwrap()
    let output = result.image()
    inspect(output.storage_length() == 4UL * channels, content="true")
    inspect(output.view().row_stride() == 2UL * channels, content="true")
    inspect(
      output.metadata().orientation() == @model.Orientation::RightBottom,
      content="true",
    )
    inspect(output.metadata().opaque_metadata().length(), content="1")
    inspect(result.disposition().preserved_length(), content="5")
    inspect(result.disposition().transformed_length(), content="0")
    inspect(result.disposition().discarded_length(), content="0")
    inspect(result.disposition().is_lossy(), content="false")
    for y = 0UL; y < 2UL; y = y + 1UL {
      for x = 0UL; x < 2UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          inspect(
            output.view().get_byte(x, y, channel).unwrap() ==
            source.view().get_byte(x, y, channel).unwrap(),
            content="true",
          )
        }
      }
    }
  }
}

///|
test "horizontal and vertical flips are exact stored-coordinate permutations" {
  let source = padded_image(3UL, None, @model.Orientation::BottomLeft)
  let horizontal = @ops.flip_horizontal(
    source.view(),
    operation_limits(12UL, 12UL),
  ).unwrap()
  let vertical = @ops.flip_vertical(
    source.view(),
    operation_limits(12UL, 12UL),
  ).unwrap()
  for y = 0UL; y < 2UL; y = y + 1UL {
    for x = 0UL; x < 2UL; x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        inspect(
          horizontal.image().view().get_byte(x, y, channel).unwrap() ==
          source.view().get_byte(1UL - x, y, channel).unwrap(),
          content="true",
        )
        inspect(
          vertical.image().view().get_byte(x, y, channel).unwrap() ==
          source.view().get_byte(x, 1UL - y, channel).unwrap(),
          content="true",
        )
      }
    }
  }
  inspect(
    horizontal.image().metadata().orientation() == @model.Orientation::BottomLeft,
    content="true",
  )
  inspect(horizontal.disposition().preserved_length(), content="5")
  inspect(vertical.disposition().preserved_length(), content="5")
}

///|
test "fresh output does not alias source backing" {
  let source = padded_image(3UL, None, @model.Orientation::TopLeft)
  let result = @ops.copy_image(
    source.view(),
    operation_limits(12UL, 12UL),
  ).unwrap()
  source
    .with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'Z') })
    .unwrap()
  inspect(source.view().get_byte(0UL, 0UL, 0UL).unwrap() == b'Z', content="true")
  inspect(result.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x01', content="true")
}
