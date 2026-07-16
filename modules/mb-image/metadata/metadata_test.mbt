///|
fn metadata_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
fn metadata_limits() -> @metadata.MetadataLimits {
  @metadata.MetadataLimits::new(
    max_entries=4UL,
    max_token_bytes=16UL,
    max_value_bytes=8UL,
    max_total_bytes=32UL,
    max_disposition_fields=8UL,
  )
}

///|
test "metadata canonicalizes keys and preserves exact opaque values" {
  let metadata = @metadata.OpaqueMetadata::from_entries(
    [
      ("png", "gamma", "u32", b"\x00\x00\xb1\x8f"),
      ("exif", "maker", "blob", b"\x00\xff"),
    ],
    metadata_limits(),
    metadata_budget(6UL, 1UL, 6UL),
  ).unwrap()
  inspect(metadata.length(), content="2")
  inspect(metadata.storage_length(), content="6")
  let first = metadata.entry(0).unwrap()
  inspect(first.namespace(), content="exif")
  inspect(first.key(), content="maker")
  inspect(first.tag(), content="blob")
  inspect(first.value().length(), content="2")
  inspect(first.value().get(0UL).unwrap() == b'\x00', content="true")
  inspect(first.value().get(1UL).unwrap() == b'\xff', content="true")
  let second = metadata.entry(1).unwrap()
  inspect(second.namespace(), content="png")
  inspect(second.key(), content="gamma")
}

///|
test "metadata permutations expose one canonical order" {
  let limits = metadata_limits()
  let left = @metadata.OpaqueMetadata::from_entries(
    [("z", "k", "raw", b"z"), ("a", "k", "raw", b"a")],
    limits,
    metadata_budget(2UL, 1UL, 2UL),
  ).unwrap()
  let right = @metadata.OpaqueMetadata::from_entries(
    [("a", "k", "raw", b"a"), ("z", "k", "raw", b"z")],
    limits,
    metadata_budget(2UL, 1UL, 2UL),
  ).unwrap()
  for index = 0; index < 2; index = index + 1 {
    inspect(
      left.entry(index).unwrap().canonical_key() ==
      right.entry(index).unwrap().canonical_key(),
      content="true",
    )
  }
}

///|
test "metadata rejects duplicate canonical keys before budget charge" {
  let budget = metadata_budget(2UL, 1UL, 2UL)
  let before = budget.remaining()
  match
    @metadata.OpaqueMetadata::from_entries(
      [("png", "gamma", "raw", b"a"), ("png", "gamma", "raw", b"b")],
      metadata_limits(),
      budget,
    ) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
      inspect(error.context() == Some("metadata-duplicate"), content="true")
    }
    Ok(_) => fail("duplicate metadata key must reject")
  }
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
}

///|
test "metadata disposition is canonical bounded and machine readable" {
  let limits = metadata_limits()
  let disposition = @metadata.MetadataDisposition::new(
    [
      @metadata.DispositionField::new("orientation", limits).unwrap(),
      @metadata.DispositionField::new("opaque", limits).unwrap(),
    ],
    [@metadata.DispositionField::new("alpha", limits).unwrap()],
    [@metadata.DispositionField::new("thumbnail", limits).unwrap()],
    true,
    limits,
  ).unwrap()
  inspect(disposition.preserved_length(), content="2")
  inspect(disposition.preserved(0).unwrap().value(), content="opaque")
  inspect(disposition.preserved(1).unwrap().value(), content="orientation")
  inspect(disposition.transformed(0).unwrap().value(), content="alpha")
  inspect(disposition.discarded(0).unwrap().value(), content="thumbnail")
  inspect(disposition.is_lossy(), content="true")
}
