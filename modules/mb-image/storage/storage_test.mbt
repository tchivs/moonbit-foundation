///|
fn storage_budget(bytes : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=1UL,
      allocation_size=bytes,
      width=8UL,
      height=8UL,
      pixels=64UL,
      depth=0UL,
      work=128UL,
    ),
  )
}

///|
fn packed_descriptor() -> @model.ImageDescriptor {
  let metadata_budget = @budget.Budget::new(
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
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [],
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=1UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=0UL,
    ),
    metadata_budget,
  ).unwrap()
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    opaque,
  )
  let plane = @model.PlaneDescriptor::new(
    2UL, 22UL, 8UL, 6UL, 1UL, 1UL, 2UL, 3UL,
  ).unwrap()
  @model.ImageDescriptor::new(
    2UL,
    3UL,
    @model.ImageFormat::rgb8(),
    [plane],
    24UL,
    metadata,
  ).unwrap()
}

///|
test "owned image charges once and retains descriptor and metadata" {
  let descriptor = packed_descriptor()
  let budget = storage_budget(24UL)
  let image = @storage.OwnedImage::new(descriptor, budget).unwrap()
  inspect(image.storage_length(), content="24")
  inspect(image.descriptor().width(), content="2")
  inspect(image.metadata().profile().is_builtin_srgb(), content="true")
  inspect(budget.remaining().bytes(), content="0")
  inspect(budget.remaining().allocations(), content="0")
  inspect(budget.remaining().pixels(), content="58")
}

///|
test "immutable view retains padded rows and representable crop is zero copy" {
  let image = @storage.OwnedImage::new(
    packed_descriptor(),
    storage_budget(24UL),
  ).unwrap()
  let view = image.view()
  inspect(view.row_stride(), content="8")
  let crop = view.crop(@model.Rect::new(0UL, 0UL, 1UL, 2UL).unwrap()).unwrap()
  inspect(crop.width(), content="1")
  inspect(crop.height(), content="2")
  inspect(crop.row_stride(), content="8")
  inspect(crop.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x00', content="true")
}

///|
test "zero area immutable crops are canonical and touch no backing" {
  let image = @storage.OwnedImage::new(
    packed_descriptor(),
    storage_budget(24UL),
  ).unwrap()
  let empty = image.view().crop(
    @model.Rect::new(2UL, 3UL, 0UL, 0UL).unwrap(),
  ).unwrap()
  inspect(empty.is_empty(), content="true")
  inspect(empty.width(), content="0")
  inspect(empty.height(), content="0")
  inspect(empty.storage_length(), content="0")
  inspect(empty.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
}
