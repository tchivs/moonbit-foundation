///|
fn mutable_test_image() -> OwnedImage {
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
  let descriptor = @model.ImageDescriptor::new(
    3UL,
    2UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(1UL, 23UL, 12UL, 9UL, 1UL, 1UL, 3UL, 2UL).unwrap(),
    ],
    24UL,
    metadata,
  ).unwrap()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=24UL,
      allocations=1UL,
      allocation_size=24UL,
      width=3UL,
      height=2UL,
      pixels=6UL,
      depth=0UL,
      work=0UL,
    ),
  )
  OwnedImage::new(descriptor, budget).unwrap()
}

///|
test "mutable descendants are stale after normal exit and owner reacquires" {
  let image = mutable_test_image()
  let mut retained : MutImageView? = None
  let result = image.with_mut_view(fn(parent) {
    let child = parent
      .crop(@model.Rect::new(0UL, 0UL, 1UL, 1UL).unwrap())
      .unwrap()
    retained = Some(child)
    child.set_byte(0UL, 0UL, 0UL, b'A')
  })
  inspect(result is Ok(_), content="true")
  let stale = retained.unwrap()
  inspect(stale.get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
  inspect(stale.set_byte(0UL, 0UL, 0UL, b'X') is Err(_), content="true")
  inspect(
    image.with_mut_view(fn(next) { next.set_byte(2UL, 1UL, 2UL, b'Z') })
    is Ok(_),
    content="true",
  )
}

///|
test "mutable descendants are stale after error and original error survives" {
  let image = mutable_test_image()
  let mut retained : MutImageView? = None
  let result : Result[Unit, @error.CoreError] = image.with_mut_view(fn(parent) {
    retained = Some(parent)
    Err(
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="mutable-callback",
        context="preserved",
      ),
    )
  })
  inspect(result.unwrap_err().context() == Some("preserved"), content="true")
  inspect(retained.unwrap().get_byte(0UL, 0UL, 0UL) is Err(_), content="true")
  inspect(image.with_mut_view(fn(_next) { Ok(()) }) is Ok(_), content="true")
}

///|
test "proved disjoint logical split mutates only selected bytes" {
  let image = mutable_test_image()
  let left_rect = @model.Rect::new(0UL, 0UL, 1UL, 2UL).unwrap()
  let right_rect = @model.Rect::new(2UL, 0UL, 1UL, 2UL).unwrap()
  let mut sentinel_unchanged = false
  image
  .with_mut_view(fn(parent) {
    let (left, right) = match parent.split_disjoint(left_rect, right_rect) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match left.set_byte(0UL, 0UL, 0UL, b'L') {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    match right.set_byte(0UL, 1UL, 2UL, b'R') {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    match parent.get_byte(1UL, 0UL, 0UL) {
      Err(error) => Err(error)
      Ok(value) => {
        sentinel_unchanged = value == b'\x00'
        Ok(())
      }
    }
  })
  .unwrap()
  inspect(sentinel_unchanged, content="true")
  inspect(image.view().get_byte(0UL, 0UL, 0UL).unwrap() == b'L', content="true")
  inspect(image.view().get_byte(2UL, 1UL, 2UL).unwrap() == b'R', content="true")
  inspect(
    image.view().get_byte(1UL, 0UL, 0UL).unwrap() == b'\x00',
    content="true",
  )
}

///|
test "empty and overlapping mutable views reject before mutation" {
  let image = mutable_test_image()
  let empty = @model.Rect::new(0UL, 0UL, 0UL, 1UL).unwrap()
  let left = @model.Rect::new(0UL, 0UL, 2UL, 1UL).unwrap()
  let overlap = @model.Rect::new(1UL, 0UL, 2UL, 1UL).unwrap()
  let mut empty_rejected = false
  let mut overlap_rejected = false
  let mut sentinel_unchanged = false
  image
  .with_mut_view(fn(parent) {
    empty_rejected = parent.crop(empty) is Err(_)
    overlap_rejected = parent.split_disjoint(left, overlap) is Err(_)
    match parent.get_byte(0UL, 0UL, 0UL) {
      Err(error) => Err(error)
      Ok(value) => {
        sentinel_unchanged = value == b'\x00'
        Ok(())
      }
    }
  })
  .unwrap()
  inspect(empty_rejected, content="true")
  inspect(overlap_rejected, content="true")
  inspect(sentinel_unchanged, content="true")
}

///|
test "generated storage case IDs are owned by behavioral tests" {
  inspect(generated_storage_case_ids().length(), content="4")
}
