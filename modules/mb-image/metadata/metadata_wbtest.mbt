///|
fn internal_metadata_budget(bytes : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=1UL,
      allocation_size=bytes,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
fn tight_limits() -> MetadataLimits {
  MetadataLimits::new(
    max_entries=2UL,
    max_token_bytes=4UL,
    max_value_bytes=3UL,
    max_total_bytes=12UL,
    max_disposition_fields=3UL,
  )
}

///|
test "all metadata caller limits reject atomically" {
  let cases : Array[(Array[(String, String, String, Bytes)], String)] = [
    (
      [
        ("a", "b", "raw", b"1"),
        ("c", "d", "raw", b"2"),
        ("e", "f", "raw", b"3"),
      ],
      "metadata-entry-count",
    ),
    ([("abcde", "b", "raw", b"1")], "metadata-token"),
    ([("a", "b", "raw", b"1234")], "metadata-value"),
    ([("a", "b", "raw", b"123"), ("c", "d", "raw", b"456")], "metadata-total"),
  ]
  for case in cases {
    let (entries, context) = case
    let budget = internal_metadata_budget(16UL)
    let before = budget.remaining()
    match OpaqueMetadata::from_entries(entries, tight_limits(), budget) {
      Err(error) => inspect(error.context() == Some(context), content="true")
      Ok(_) => fail("caller limit must reject")
    }
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
  }
}

///|
test "metadata values are never interpreted" {
  let metadata = OpaqueMetadata::from_entries(
    [("icc", "profile", "blob", b"not-an-icc-header")],
    MetadataLimits::new(
      max_entries=1UL,
      max_token_bytes=16UL,
      max_value_bytes=17UL,
      max_total_bytes=32UL,
      max_disposition_fields=1UL,
    ),
    internal_metadata_budget(17UL),
  ).unwrap()
  let value = metadata.entry(0).unwrap().value()
  inspect(value.length(), content="17")
  inspect(value.get(0UL).unwrap() == b'n', content="true")
}

///|
test "storage budget rejection remains atomic after validation" {
  let limits = MetadataLimits::new(
    max_entries=1UL,
    max_token_bytes=8UL,
    max_value_bytes=4UL,
    max_total_bytes=16UL,
    max_disposition_fields=1UL,
  )
  let budgets = [
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=3UL,
        allocations=1UL,
        allocation_size=4UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=4UL,
        allocations=0UL,
        allocation_size=4UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=4UL,
        allocations=1UL,
        allocation_size=3UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ]
  for budget in budgets {
    let before = budget.remaining()
    match
      OpaqueMetadata::from_entries(
        [("ns", "key", "raw", b"data")],
        limits,
        budget,
      ) {
      Err(error) =>
        inspect(
          error.code() == @error.ErrorCode::BudgetExceeded,
          content="true",
        )
      Ok(_) => fail("underfunded storage must reject")
    }
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.allocation_size() == before.allocation_size(), content="true")
  }
}

///|
test "metadata tokens reject empty non-ASCII and invalid-leading spellings" {
  for namespace in ["", "-bad", "méta"] {
    match
      OpaqueMetadata::from_entries(
        [(namespace, "key", "raw", b"")],
        tight_limits(),
        internal_metadata_budget(0UL),
      ) {
      Err(error) => {
        inspect(
          error.code() == @error.ErrorCode::InvalidEncoding,
          content="true",
        )
        inspect(error.context() == Some("metadata-token"), content="true")
      }
      Ok(_) => fail("invalid metadata token must reject")
    }
  }
}

///|
test "disposition rejects duplicate and over-count fields" {
  let limits = tight_limits()
  let duplicate = DispositionField::new("same", limits).unwrap()
  match MetadataDisposition::new([duplicate], [duplicate], [], false, limits) {
    Err(error) =>
      inspect(error.context() == Some("disposition-duplicate"), content="true")
    Ok(_) => fail("a field cannot have two dispositions")
  }
  let a = DispositionField::new("a", limits).unwrap()
  let b = DispositionField::new("b", limits).unwrap()
  let c = DispositionField::new("c", limits).unwrap()
  let d = DispositionField::new("d", limits).unwrap()
  match MetadataDisposition::new([a, b], [c], [d], false, limits) {
    Err(error) =>
      inspect(error.context() == Some("disposition-count"), content="true")
    Ok(_) => fail("disposition field count must be bounded")
  }
}
