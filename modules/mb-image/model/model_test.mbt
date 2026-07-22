///|
fn model_budget() -> @budget.Budget {
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
  )
}

///|
fn empty_opaque_metadata() -> @metadata.OpaqueMetadata {
  @metadata.OpaqueMetadata::from_entries(
    [],
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=8UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=0UL,
    ),
    model_budget(),
  ).unwrap()
}

///|
fn image_metadata(
  alpha : @color.AlphaMode?,
  orientation : @model.Orientation,
) -> @model.ImageMetadata {
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    alpha,
    @profile.ProfileIdentity::builtin_srgb(),
    orientation,
    empty_opaque_metadata(),
  )
}

///|
fn rejects_invalid_graya(
  format : @model.ImageFormat,
  planes : Array[@model.PlaneDescriptor],
  metadata : @model.ImageMetadata,
) -> Bool {
  match @model.ImageDescriptor::new(1UL, 1UL, format, planes, 4UL, metadata) {
    Err(error) => error.code() == @error.ErrorCode::InvalidEncoding
    Ok(_) => false
  }
}

///|
test "explicit packed descriptor exposes every identity" {
  let format = @model.ImageFormat::new(
    @model.ComponentType::U8,
    @model.ChannelOrder::Rgba,
    @model.PlaneLayout::Packed,
    @model.Endianness::Little,
  ).unwrap()
  let plane = @model.PlaneDescriptor::new(
    0UL, 32UL, 16UL, 12UL, 1UL, 1UL, 3UL, 2UL,
  ).unwrap()
  let metadata = image_metadata(
    Some(@color.AlphaMode::Straight),
    @model.Orientation::TopLeft,
  )
  let descriptor = @model.ImageDescriptor::new(
    3UL,
    2UL,
    format,
    [plane],
    32UL,
    metadata,
  ).unwrap()
  inspect(descriptor.width(), content="3")
  inspect(descriptor.height(), content="2")
  inspect(descriptor.pixel_count(), content="6")
  inspect(descriptor.storage_length(), content="32")
  inspect(
    descriptor.format().component() == @model.ComponentType::U8,
    content="true",
  )
  inspect(
    descriptor.format().channels() == @model.ChannelOrder::Rgba,
    content="true",
  )
  inspect(
    descriptor.format().layout() == @model.PlaneLayout::Packed,
    content="true",
  )
  inspect(
    descriptor.format().endianness() == @model.Endianness::Little,
    content="true",
  )
  inspect(descriptor.format().channel_count(), content="4")
  inspect(descriptor.format().bytes_per_component(), content="1")
  inspect(descriptor.plane_count(), content="1")
  let exposed = descriptor.plane(0).unwrap()
  inspect(exposed.range().start(), content="0")
  inspect(exposed.range().end(), content="32")
  inspect(exposed.row_stride(), content="16")
  inspect(exposed.row_bytes(), content="12")
  inspect(exposed.subsample_x(), content="1")
  inspect(exposed.subsample_y(), content="1")
  inspect(exposed.extent_width(), content="3")
  inspect(exposed.extent_height(), content="2")
  inspect(
    descriptor.metadata().space() == @color.ColorSpaceIdentity::Srgb,
    content="true",
  )
  inspect(
    descriptor.metadata().transfer() == @color.TransferIdentity::EncodedSrgb,
    content="true",
  )
  inspect(
    descriptor.metadata().alpha() == Some(@color.AlphaMode::Straight),
    content="true",
  )
  inspect(descriptor.metadata().profile().is_builtin_srgb(), content="true")
  inspect(descriptor.metadata().opaque_metadata().length(), content="0")
  inspect(descriptor.supports_reference_operations(), content="true")
}

///|
test "general descriptors represent planar U16 and F32 but do not overclaim operation support" {
  for component in [@model.ComponentType::U16, @model.ComponentType::F32] {
    let bytes = if component == @model.ComponentType::U16 { 2UL } else { 4UL }
    let format = @model.ImageFormat::new(
      component,
      @model.ChannelOrder::Rgb,
      @model.PlaneLayout::Planar,
      @model.Endianness::Big,
    ).unwrap()
    let planes = [
      @model.PlaneDescriptor::new(
        0UL,
        bytes * 4UL,
        bytes * 2UL,
        bytes * 2UL,
        1UL,
        1UL,
        2UL,
        2UL,
      ).unwrap(),
      @model.PlaneDescriptor::new(
        bytes * 4UL,
        bytes * 4UL,
        bytes * 2UL,
        bytes * 2UL,
        1UL,
        1UL,
        2UL,
        2UL,
      ).unwrap(),
      @model.PlaneDescriptor::new(
        bytes * 8UL,
        bytes * 4UL,
        bytes * 2UL,
        bytes * 2UL,
        1UL,
        1UL,
        2UL,
        2UL,
      ).unwrap(),
    ]
    let descriptor = @model.ImageDescriptor::new(
      2UL,
      2UL,
      format,
      planes,
      bytes * 12UL,
      image_metadata(None, @model.Orientation::TopLeft),
    ).unwrap()
    inspect(descriptor.plane_count(), content="3")
    inspect(descriptor.supports_reference_operations(), content="false")
  }
}

///|
test "reference operation support is closed over RGB and alpha identity" {
  let rgb = @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(0UL, 3UL, 3UL, 3UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
    ],
    3UL,
    image_metadata(None, @model.Orientation::TopLeft),
  ).unwrap()
  inspect(rgb.supports_reference_operations(), content="true")
  let rgba_premultiplied = @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::rgba8(),
    [
      @model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
    ],
    4UL,
    image_metadata(
      Some(@color.AlphaMode::Premultiplied),
      @model.Orientation::TopLeft,
    ),
  ).unwrap()
  inspect(rgba_premultiplied.supports_reference_operations(), content="true")
  let linear_metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::LinearSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    empty_opaque_metadata(),
  )
  let linear_rgb = @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(0UL, 3UL, 3UL, 3UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
    ],
    3UL,
    linear_metadata,
  ).unwrap()
  inspect(linear_rgb.supports_reference_operations(), content="false")
}

///|
test "GrayAlpha is a packed two-component straight-alpha descriptor" {
  let descriptor = @model.ImageDescriptor::new(
    2UL,
    1UL,
    @model.ImageFormat::graya8(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL,
    ).unwrap()],
    4UL,
    image_metadata(
      Some(@color.AlphaMode::Straight),
      @model.Orientation::TopLeft,
    ),
  ).unwrap()
  inspect(
    descriptor.format().channels() == @model.ChannelOrder::GrayAlpha,
    content="true",
  )
  inspect(descriptor.format().component() == @model.ComponentType::U8, content="true")
  inspect(descriptor.format().layout() == @model.PlaneLayout::Packed, content="true")
  inspect(descriptor.format().endianness() == @model.Endianness::Little, content="true")
  inspect(descriptor.format().channel_count(), content="2")
  inspect(descriptor.plane_count(), content="1")
  inspect(descriptor.plane(0).unwrap().row_bytes(), content="4")
  inspect(descriptor.metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(descriptor.metadata().profile().is_builtin_srgb(), content="true")
  inspect(descriptor.supports_reference_operations(), content="false")
}

///|
test "GrayAlpha16 is a packed two-component straight-alpha descriptor" {
  let descriptor = @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 1UL, 1UL,
    ).unwrap()],
    4UL,
    image_metadata(
      Some(@color.AlphaMode::Straight),
      @model.Orientation::TopLeft,
    ),
  ).unwrap()
  inspect(descriptor.format().component() == @model.ComponentType::U16, content="true")
  inspect(
    descriptor.format().channels() == @model.ChannelOrder::GrayAlpha,
    content="true",
  )
  inspect(descriptor.format().layout() == @model.PlaneLayout::Packed, content="true")
  inspect(descriptor.format().endianness() == @model.Endianness::Little, content="true")
  inspect(descriptor.format().channel_count(), content="2")
  inspect(descriptor.format().bytes_per_component(), content="2")
  inspect(descriptor.plane_count(), content="1")
  inspect(descriptor.plane(0).unwrap().row_bytes(), content="4")
  inspect(descriptor.metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(descriptor.metadata().profile().is_builtin_srgb(), content="true")
  inspect(descriptor.metadata().orientation() == @model.Orientation::TopLeft, content="true")
  inspect(descriptor.supports_reference_operations(), content="false")
}

///|
test "GrayAlpha admission accepts canonical identities and rejects unsupported identity" {
  let packed = [@model.PlaneDescriptor::new(
    0UL, 2UL, 2UL, 2UL, 1UL, 1UL, 1UL, 1UL,
  ).unwrap()]
  let straight = image_metadata(
    Some(@color.AlphaMode::Straight),
    @model.Orientation::TopLeft,
  )
  let missing_alpha = image_metadata(None, @model.Orientation::TopLeft)
  let premultiplied = image_metadata(
    Some(@color.AlphaMode::Premultiplied),
    @model.Orientation::TopLeft,
  )
  let linear = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::LinearSrgb,
    Some(@color.AlphaMode::Straight),
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    empty_opaque_metadata(),
  )
  let profile_budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=1UL,
      allocations=1UL,
      allocation_size=1UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
  let custom_profile = @profile.ProfileIdentity::opaque(
    @profile.OpaqueProfile::from_bytes(
      @profile.ProfileFormatTag::icc(),
      b"x",
      @profile.ProfileLimits::new(1UL),
      profile_budget,
    ).unwrap(),
  )
  let non_builtin = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight),
    custom_profile,
    @model.Orientation::TopLeft,
    empty_opaque_metadata(),
  )
  let rotated = image_metadata(
    Some(@color.AlphaMode::Straight),
    @model.Orientation::TopRight,
  )
  inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, missing_alpha), content="true")
  inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, premultiplied), content="true")
  inspect(@model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 1UL, 1UL,
    ).unwrap()],
    4UL,
    straight,
  ) is Ok(_), content="true")
  inspect(rejects_invalid_graya(
    @model.ImageFormat::new(
      @model.ComponentType::U8,
      @model.ChannelOrder::GrayAlpha,
      @model.PlaneLayout::Planar,
      @model.Endianness::Little,
    ).unwrap(),
    [
      @model.PlaneDescriptor::new(0UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
      @model.PlaneDescriptor::new(1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL).unwrap(),
    ],
    straight,
  ), content="true")
  inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, linear), content="true")
  inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, non_builtin), content="true")
  inspect(rejects_invalid_graya(@model.ImageFormat::graya8(), packed, rotated), content="true")
}

///|
test "eight orientations expose stored and display dimensions" {
  let orientations = [
    @model.Orientation::TopLeft,
    @model.Orientation::TopRight,
    @model.Orientation::BottomRight,
    @model.Orientation::BottomLeft,
    @model.Orientation::LeftTop,
    @model.Orientation::RightTop,
    @model.Orientation::RightBottom,
    @model.Orientation::LeftBottom,
  ]
  for index = 0; index < orientations.length(); index = index + 1 {
    let orientation = orientations[index]
    inspect(orientation.code() == index + 1, content="true")
    if index < 4 {
      inspect(orientation.display_width(7UL, 5UL), content="7")
      inspect(orientation.display_height(7UL, 5UL), content="5")
    } else {
      inspect(orientation.display_width(7UL, 5UL), content="5")
      inspect(orientation.display_height(7UL, 5UL), content="7")
    }
  }
}

///|
test "checked half-open rectangles permit empty ranges" {
  let empty = @model.Rect::new(9UL, 7UL, 0UL, 0UL).unwrap()
  inspect(empty.x(), content="9")
  inspect(empty.y(), content="7")
  inspect(empty.width(), content="0")
  inspect(empty.height(), content="0")
  inspect(empty.right(), content="9")
  inspect(empty.bottom(), content="7")
  inspect(empty.is_empty(), content="true")
}
