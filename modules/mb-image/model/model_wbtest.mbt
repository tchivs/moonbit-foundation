///|
fn internal_metadata(alpha : @color.AlphaMode?) -> ImageMetadata {
  let opaque_metadata = @metadata.OpaqueMetadata::from_entries(
    [],
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=1UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=0UL,
    ),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=0UL,
        allocations=1UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    alpha,
    @profile.ProfileIdentity::builtin_srgb(),
    Orientation::TopLeft,
    opaque_metadata,
  )
}

///|
fn expect_descriptor_error(
  width : UInt64,
  height : UInt64,
  format : ImageFormat,
  planes : Array[PlaneDescriptor],
  storage_length : UInt64,
  context : String,
) -> Unit raise {
  match
    ImageDescriptor::new(
      width,
      height,
      format,
      planes,
      storage_length,
      internal_metadata(None),
    ) {
    Err(error) => inspect(error.context() == Some(context), content="true")
    Ok(_) => fail("invalid descriptor must reject")
  }
}

///|
test "owned image dimensions reject zero axes and overflow" {
  let plane = PlaneDescriptor::new(0UL, 3UL, 3UL, 3UL, 1UL, 1UL, 1UL, 1UL).unwrap()
  for dimensions in [(0UL, 1UL), (1UL, 0UL)] {
    expect_descriptor_error(
      dimensions.0,
      dimensions.1,
      ImageFormat::rgb8(),
      [plane],
      3UL,
      "image-dimensions",
    )
  }
  match
    ImageDescriptor::new(
      18446744073709551615UL,
      2UL,
      ImageFormat::rgb8(),
      [plane],
      3UL,
      internal_metadata(None),
    ) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::InvalidDimensions,
        content="true",
      )
    Ok(_) => fail("pixel-count overflow must reject")
  }
}

///|
test "plane construction rejects stride and extent arithmetic failures" {
  match PlaneDescriptor::new(0UL, 4UL, 3UL, 4UL, 1UL, 1UL, 1UL, 1UL) {
    Err(error) =>
      inspect(error.context() == Some("plane-row-stride"), content="true")
    Ok(_) => fail("short stride must reject")
  }
  match
    PlaneDescriptor::new(
      0UL, 18446744073709551615UL, 18446744073709551615UL, 1UL, 1UL, 1UL, 1UL, 3UL,
    ) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("plane extent overflow must reject")
  }
  match PlaneDescriptor::new(0UL, 1UL, 1UL, 1UL, 0UL, 1UL, 1UL, 1UL) {
    Err(error) =>
      inspect(error.context() == Some("plane-subsampling"), content="true")
    Ok(_) => fail("zero subsampling must reject")
  }
  match PlaneDescriptor::new(0UL, 5UL, 4UL, 2UL, 1UL, 1UL, 2UL, 2UL) {
    Err(error) =>
      inspect(error.context() == Some("plane-length"), content="true")
    Ok(_) => fail("one-byte-short plane must reject")
  }
  match
    PlaneDescriptor::new(
      18446744073709551615UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL,
    ) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    Ok(_) => fail("plane range overflow must reject")
  }
}

///|
test "descriptor rejects plane count row shape containment and overlap" {
  let rgb8 = ImageFormat::rgb8()
  expect_descriptor_error(1UL, 1UL, rgb8, [], 3UL, "image-plane-count")
  let short_row = PlaneDescriptor::new(0UL, 2UL, 2UL, 2UL, 1UL, 1UL, 1UL, 1UL).unwrap()
  expect_descriptor_error(1UL, 1UL, rgb8, [short_row], 2UL, "image-row-bytes")
  let outside = PlaneDescriptor::new(2UL, 3UL, 3UL, 3UL, 1UL, 1UL, 1UL, 1UL).unwrap()
  expect_descriptor_error(1UL, 1UL, rgb8, [outside], 4UL, "image-plane-storage")

  let planar = ImageFormat::new(
    ComponentType::U8,
    ChannelOrder::Rgb,
    PlaneLayout::Planar,
    Endianness::Little,
  ).unwrap()
  let overlap = [
    PlaneDescriptor::new(0UL, 4UL, 2UL, 2UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
    PlaneDescriptor::new(3UL, 4UL, 2UL, 2UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
    PlaneDescriptor::new(7UL, 4UL, 2UL, 2UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
  ]
  expect_descriptor_error(
    2UL, 2UL, planar, overlap, 11UL, "image-plane-overlap",
  )
}

///|
test "touching planar ranges and padded rows are valid" {
  let format = ImageFormat::new(
    ComponentType::U8,
    ChannelOrder::Rgb,
    PlaneLayout::Planar,
    Endianness::Little,
  ).unwrap()
  let descriptor = ImageDescriptor::new(
    2UL,
    2UL,
    format,
    [
      PlaneDescriptor::new(0UL, 6UL, 4UL, 2UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
      PlaneDescriptor::new(6UL, 6UL, 4UL, 2UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
      PlaneDescriptor::new(12UL, 6UL, 4UL, 2UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
    ],
    18UL,
    internal_metadata(None),
  ).unwrap()
  inspect(descriptor.plane(0).unwrap().range().end(), content="6")
  inspect(descriptor.plane(1).unwrap().range().start(), content="6")
}

///|
test "format and alpha combinations reject before operation support" {
  let invalid_rgba = ImageDescriptor::new(
    1UL,
    1UL,
    ImageFormat::rgba8(),
    [PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 1UL, 1UL).unwrap()],
    4UL,
    internal_metadata(None),
  )
  match invalid_rgba {
    Err(error) =>
      inspect(error.context() == Some("image-alpha-mode"), content="true")
    Ok(_) => fail("RGBA without alpha identity must reject")
  }
  let invalid_rgb = ImageDescriptor::new(
    1UL,
    1UL,
    ImageFormat::rgb8(),
    [PlaneDescriptor::new(0UL, 3UL, 3UL, 3UL, 1UL, 1UL, 1UL, 1UL).unwrap()],
    3UL,
    internal_metadata(Some(@color.AlphaMode::Straight)),
  )
  match invalid_rgb {
    Err(error) =>
      inspect(error.context() == Some("image-alpha-mode"), content="true")
    Ok(_) => fail("RGB with alpha identity must reject")
  }
}

///|
test "rect endpoints reject overflow" {
  match Rect::new(18446744073709551615UL, 0UL, 1UL, 0UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("rectangle endpoint overflow must reject")
  }
}

///|
test "generated model case IDs are owned by behavioral tests" {
  inspect(generated_model_case_ids().length(), content="3")
}
