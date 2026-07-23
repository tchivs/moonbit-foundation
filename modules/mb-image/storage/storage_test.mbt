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
struct RejectingImageAllocator {}

///|
impl @bytes.Allocator for RejectingImageAllocator with fn approve(
  _self,
  requested,
) {
  Err(
    @error.CoreError::new(
      @error.ErrorCategory::Resource,
      @error.ErrorCode::AllocationFailed,
      operation="reject-image-allocation",
      requested~,
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
fn gray16_descriptor() -> @model.ImageDescriptor {
  @model.ImageDescriptor::new(
    2UL,
    1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16,
      @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed,
      @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL,
    ).unwrap()],
    4UL,
    packed_descriptor().metadata(),
  ).unwrap()
}

///|
fn graya8_descriptor() -> @model.ImageDescriptor {
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight),
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    packed_descriptor().metadata().opaque_metadata(),
  )
  @model.ImageDescriptor::new(
    2UL,
    1UL,
    @model.ImageFormat::graya8(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL,
    ).unwrap()],
    4UL,
    metadata,
  ).unwrap()
}

///|
fn graya16_descriptor() -> @model.ImageDescriptor {
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight),
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    packed_descriptor().metadata().opaque_metadata(),
  )
  @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(
      0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 1UL, 1UL,
    ).unwrap()],
    4UL,
    metadata,
  ).unwrap()
}

///|
fn rgba16_descriptor() -> @model.ImageDescriptor {
  let metadata = @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight),
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    packed_descriptor().metadata().opaque_metadata(),
  )
  @model.ImageDescriptor::new(
    1UL,
    1UL,
    @model.ImageFormat::rgba16(),
    [@model.PlaneDescriptor::new(
      0UL, 8UL, 8UL, 8UL, 1UL, 1UL, 1UL, 1UL,
    ).unwrap()],
    8UL,
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
test "packed component-byte access constructs and observes U16 storage order" {
  let image = @storage.OwnedImage::new(
    gray16_descriptor(),
    storage_budget(4UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\xcd').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xab').unwrap()
    Ok(())
  }).unwrap()
  let view = image.view()
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 0UL).unwrap(), content="b'\\x34'")
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 1UL).unwrap(), content="b'\\x12'")
  inspect(view.get_component_byte(1UL, 0UL, 0UL, 0UL).unwrap(), content="b'\\xCD'")
  inspect(view.get_component_byte(1UL, 0UL, 0UL, 1UL).unwrap(), content="b'\\xAB'")
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 2UL) is Err(_), content="true")
  inspect(view.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
  let u8 = @storage.OwnedImage::new(packed_descriptor(), storage_budget(24UL)).unwrap()
  inspect(
    u8.view().get_component_byte(0UL, 0UL, 0UL, 0UL).unwrap() ==
      u8.view().get_byte(0UL, 0UL, 0UL).unwrap(),
    content="true",
  )
}

///|
test "checked packed views retain distinct GrayAlpha components" {
  let image = @storage.OwnedImage::new(graya8_descriptor(), storage_budget(4UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 0UL, b'\x13').unwrap()
    view.set_byte(0UL, 0UL, 1UL, b'\xe7').unwrap()
    view.set_byte(1UL, 0UL, 0UL, b'\xc1').unwrap()
    view.set_byte(1UL, 0UL, 1UL, b'\x2a').unwrap()
    Ok(())
  }).unwrap()
  let view = image.view()
  inspect(view.get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x13'")
  inspect(view.get_byte(0UL, 0UL, 1UL).unwrap(), content="b'\\xE7'")
  inspect(view.get_byte(1UL, 0UL, 0UL).unwrap(), content="b'\\xC1'")
  inspect(view.get_byte(1UL, 0UL, 1UL).unwrap(), content="b'\\x2A'")
  inspect(view.get_byte(0UL, 0UL, 2UL) is Err(_), content="true")
}

///|
test "checked packed views retain both GrayAlpha16 component byte pairs" {
  let image = @storage.OwnedImage::new(graya16_descriptor(), storage_budget(4UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xc5').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 1UL, b'\xa7').unwrap()
    Ok(())
  }).unwrap()
  let view = image.view()
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 0UL).unwrap(), content="b'\\x34'")
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 1UL).unwrap(), content="b'\\x12'")
  inspect(view.get_component_byte(0UL, 0UL, 1UL, 0UL).unwrap(), content="b'\\xC5'")
  inspect(view.get_component_byte(0UL, 0UL, 1UL, 1UL).unwrap(), content="b'\\xA7'")
  inspect(view.get_component_byte(0UL, 0UL, 2UL, 0UL) is Err(_), content="true")
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 2UL) is Err(_), content="true")
  inspect(view.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
}

///|
test "checked packed views retain all rgba16 component byte pairs" {
  let image = @storage.OwnedImage::new(rgba16_descriptor(), storage_budget(8UL)).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xc5').unwrap()
    view.set_component_byte(0UL, 0UL, 1UL, 1UL, b'\xa7').unwrap()
    view.set_component_byte(0UL, 0UL, 2UL, 0UL, b'\x5e').unwrap()
    view.set_component_byte(0UL, 0UL, 2UL, 1UL, b'\x9d').unwrap()
    view.set_component_byte(0UL, 0UL, 3UL, 0UL, b'\x2b').unwrap()
    view.set_component_byte(0UL, 0UL, 3UL, 1UL, b'\xf0').unwrap()
    Ok(())
  }).unwrap()
  let view = image.view()
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 0UL).unwrap(), content="b'\\x34'")
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 1UL).unwrap(), content="b'\\x12'")
  inspect(view.get_component_byte(0UL, 0UL, 1UL, 0UL).unwrap(), content="b'\\xC5'")
  inspect(view.get_component_byte(0UL, 0UL, 1UL, 1UL).unwrap(), content="b'\\xA7'")
  inspect(view.get_component_byte(0UL, 0UL, 2UL, 0UL).unwrap(), content="b'\\x5E'")
  inspect(view.get_component_byte(0UL, 0UL, 2UL, 1UL).unwrap(), content="b'\\x9D'")
  inspect(view.get_component_byte(0UL, 0UL, 3UL, 0UL).unwrap(), content="b'\\x2B'")
  inspect(view.get_component_byte(0UL, 0UL, 3UL, 1UL).unwrap(), content="b'\\xF0'")
  inspect(view.get_component_byte(0UL, 0UL, 4UL, 0UL) is Err(_), content="true")
  inspect(view.get_component_byte(0UL, 0UL, 0UL, 2UL) is Err(_), content="true")
  inspect(view.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
}

///|
test "zero area immutable crops are canonical and touch no backing" {
  let image = @storage.OwnedImage::new(
    packed_descriptor(),
    storage_budget(24UL),
  ).unwrap()
  let empty = image
    .view()
    .crop(@model.Rect::new(2UL, 3UL, 0UL, 0UL).unwrap())
    .unwrap()
  inspect(empty.is_empty(), content="true")
  inspect(empty.width(), content="0")
  inspect(empty.height(), content="0")
  inspect(empty.storage_length(), content="0")
  inspect(empty.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
}

///|
test "allocator and operation budget failures are atomic" {
  let descriptor = packed_descriptor()
  let allocator_budget = storage_budget(24UL)
  let rejected = @storage.OwnedImage::new_with_allocator(
    descriptor,
    allocator_budget,
    RejectingImageAllocator::{  } as &@bytes.Allocator,
  )
  inspect(rejected is Err(_), content="true")
  inspect(allocator_budget.remaining().bytes(), content="24")
  inspect(allocator_budget.remaining().allocations(), content="1")
  inspect(allocator_budget.remaining().pixels(), content="64")
  let work_budget = storage_budget(24UL)
  let failed = @storage.OwnedImage::new_operation(
    descriptor,
    work_budget,
    ImageTestAllocator::{  } as &@bytes.Allocator,
    129UL,
  )
  inspect(failed is Err(_), content="true")
  inspect(work_budget.remaining().bytes(), content="24")
  inspect(work_budget.remaining().allocations(), content="1")
  inspect(work_budget.remaining().pixels(), content="64")
  inspect(work_budget.remaining().work(), content="128")
}

///|
fn reordered_planar_descriptor() -> @model.ImageDescriptor {
  let metadata = packed_descriptor().metadata()
  let format = @model.ImageFormat::new(
    @model.ComponentType::U8,
    @model.ChannelOrder::Rgb,
    @model.PlaneLayout::Planar,
    @model.Endianness::Little,
  ).unwrap()
  @model.ImageDescriptor::new(
    2UL,
    1UL,
    format,
    [
      @model.PlaneDescriptor::new(4UL, 2UL, 2UL, 2UL, 1UL, 1UL, 2UL, 1UL).unwrap(),
      @model.PlaneDescriptor::new(0UL, 2UL, 2UL, 2UL, 1UL, 1UL, 2UL, 1UL).unwrap(),
      @model.PlaneDescriptor::new(2UL, 2UL, 2UL, 2UL, 1UL, 1UL, 2UL, 1UL).unwrap(),
    ],
    6UL,
    metadata,
  ).unwrap()
}

///|
test "reordered planar full view is inspectable but grants no byte or mutable authority" {
  let descriptor = reordered_planar_descriptor()
  let budget = storage_budget(6UL)
  let image = @storage.OwnedImage::new(descriptor, budget).unwrap()
  let before = budget.remaining()
  let view = image.view()
  inspect(view.width(), content="2")
  inspect(view.height(), content="1")
  inspect(view.format().layout() == @model.PlaneLayout::Planar, content="true")
  inspect(view.metadata().profile().is_builtin_srgb(), content="true")
  match view.get_byte(0UL, 0UL, 0UL) {
    Err(error) => {
      inspect(
        error.code() == @error.ErrorCode::CapabilityUnavailable,
        content="true",
      )
      inspect(
        error.context() == Some("packed-u8-byte-access-required"),
        content="true",
      )
    }
    Ok(_) => fail("planar full view must not fabricate packed byte offsets")
  }
  match image.with_mut_view(fn(_view) { Ok(()) }) {
    Err(error) => {
      inspect(
        error.code() == @error.ErrorCode::CapabilityUnavailable,
        content="true",
      )
      inspect(
        error.context() == Some("packed-u8-mut-view-required"),
        content="true",
      )
    }
    Ok(_) => fail("planar image must reject before acquiring a mutable lease")
  }
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
test "nonempty planar immutable crop reports stable unsupported capability" {
  let metadata = packed_descriptor().metadata()
  let format = @model.ImageFormat::new(
    @model.ComponentType::U8,
    @model.ChannelOrder::Rgb,
    @model.PlaneLayout::Planar,
    @model.Endianness::Little,
  ).unwrap()
  let descriptor = @model.ImageDescriptor::new(
    2UL,
    3UL,
    format,
    [
      @model.PlaneDescriptor::new(0UL, 6UL, 2UL, 2UL, 1UL, 1UL, 2UL, 3UL).unwrap(),
      @model.PlaneDescriptor::new(6UL, 6UL, 2UL, 2UL, 1UL, 1UL, 2UL, 3UL).unwrap(),
      @model.PlaneDescriptor::new(12UL, 6UL, 2UL, 2UL, 1UL, 1UL, 2UL, 3UL).unwrap(),
    ],
    18UL,
    metadata,
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, storage_budget(18UL)).unwrap()
  match image.view().crop(@model.Rect::new(0UL, 0UL, 1UL, 1UL).unwrap()) {
    Err(error) => {
      inspect(
        error.code() == @error.ErrorCode::CapabilityUnavailable,
        content="true",
      )
      inspect(error.context() == Some("planar-crop"), content="true")
    }
    Ok(_) => fail("planar crop must not claim a zero-copy representation")
  }
}

///|
struct ImageTestAllocator {}

///|
impl @bytes.Allocator for ImageTestAllocator with fn approve(_self, _requested) {
  Ok(())
}
