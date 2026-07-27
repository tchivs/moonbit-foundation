///|
fn font_collection_test_push_u16(
  output : Array[Byte],
  value : UInt64,
) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_collection_test_push_u32(
  output : Array[Byte],
  value : UInt64,
) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_collection_test_put_u16(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn font_collection_test_put_u32(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 24).to_byte()
  output[offset + 1] = (value >> 16).to_byte()
  output[offset + 2] = (value >> 8).to_byte()
  output[offset + 3] = value.to_byte()
}

///|
fn font_collection_test_write_directory(
  output : Array[Byte],
  start : Int,
  sfnt_version : UInt64,
  tags : Array[UInt64],
  table_offsets : Array[UInt64],
) -> Unit {
  let count = tags.length()
  font_collection_test_put_u32(output, start, sfnt_version)
  font_collection_test_put_u16(output, start + 4, count.to_uint64())
  let search_range = if count >= 2 { 32UL } else { 16UL }
  let selector = if count >= 2 { 1UL } else { 0UL }
  let range_shift = count.to_uint64() * 16UL - search_range
  font_collection_test_put_u16(output, start + 6, search_range)
  font_collection_test_put_u16(output, start + 8, selector)
  font_collection_test_put_u16(output, start + 10, range_shift)
  let mut index = 0
  while index < count {
    let record = start + 12 + index * 16
    font_collection_test_put_u32(output, record, tags[index])
    font_collection_test_put_u32(output, record + 4, 0x10203040UL)
    font_collection_test_put_u32(output, record + 8, table_offsets[index])
    font_collection_test_put_u32(output, record + 12, 4UL)
    index = index + 1
  }
}

///|
fn font_collection_test_multi_ttc() -> Bytes {
  let output = Array::make(400, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00020000UL)
  font_collection_test_put_u32(output, 8, 5UL)
  for item in [
    (12, 64UL),
    (16, 112UL),
    (20, 144UL),
    (24, 176UL),
    (28, 240UL),
  ] {
    let (field, directory) = item
    font_collection_test_put_u32(output, field, directory)
  }
  // TTC v2 DSIG tuple is all-zero: structurally absent.
  font_collection_test_write_directory(
    output,
    64,
    0x00010000UL,
    [0x676C7966UL, 0x6C6F6361UL],
    [272UL, 276UL],
  )
  font_collection_test_write_directory(
    output,
    112,
    0x4F54544FUL,
    [0x43464620UL],
    [280UL],
  )
  font_collection_test_write_directory(
    output,
    144,
    0x4F54544FUL,
    [0x43464632UL],
    [284UL],
  )
  font_collection_test_write_directory(
    output,
    176,
    0x00010000UL,
    [0x66766172UL, 0x676C7966UL, 0x6C6F6361UL],
    [288UL, 292UL, 296UL],
  )
  font_collection_test_write_directory(
    output,
    240,
    0x00010000UL,
    [0x6E616D65UL],
    [300UL],
  )
  Bytes::from_array(output)
}

///|
fn font_collection_test_wrong_rebase_ttc() -> Bytes {
  let output = Array::make(128, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 64UL)
  // Root range [20, 24) is valid. Incorrectly rebasing it at directory 64
  // yields [84, 88), an in-bounds overlap with the directory itself.
  font_collection_test_write_directory(
    output,
    64,
    0x00010000UL,
    [0x6E616D65UL],
    [20UL],
  )
  Bytes::from_array(output)
}

///|
fn font_collection_test_prefix(source : Bytes, length : Int) -> Bytes {
  let output : Array[Byte] = []
  let mut index = 0
  while index < length {
    output.push(source[index])
    index = index + 1
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_zeroes(output : Array[Byte], count : Int) -> Unit {
  let mut index = 0
  while index < count {
    output.push(b'\x00')
    index = index + 1
  }
}

///|
fn font_collection_test_ttc() -> Bytes {
  let output : Array[Byte] = []
  font_collection_test_push_u32(output, 0x74746366UL)
  font_collection_test_push_u32(output, 0x00010000UL)
  font_collection_test_push_u32(output, 1UL)
  font_collection_test_push_u32(output, 32UL)
  font_collection_test_zeroes(output, 16)
  font_collection_test_push_u32(output, 0x00010000UL)
  font_collection_test_push_u16(output, 2UL)
  font_collection_test_push_u16(output, 32UL)
  font_collection_test_push_u16(output, 1UL)
  font_collection_test_push_u16(output, 0UL)
  font_collection_test_push_u32(output, 0x676C7966UL)
  font_collection_test_push_u32(output, 0UL)
  font_collection_test_push_u32(output, 80UL)
  font_collection_test_push_u32(output, 4UL)
  font_collection_test_push_u32(output, 0x6C6F6361UL)
  font_collection_test_push_u32(output, 0UL)
  font_collection_test_push_u32(output, 84UL)
  font_collection_test_push_u32(output, 4UL)
  font_collection_test_zeroes(output, 12)
  Bytes::from_array(output)
}

///|
fn font_collection_test_zero_faces() -> Bytes {
  let output : Array[Byte] = []
  font_collection_test_push_u32(output, 0x74746366UL)
  font_collection_test_push_u32(output, 0x00010000UL)
  font_collection_test_push_u32(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_collection_test_owner(source : Bytes) -> @bytes.OwnedBytes {
  let length = source.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length,
        allocations=1UL,
        allocation_size=length,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
}

///|
fn font_collection_test_limits_with_source(
  max_source_bytes : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes~,
    max_faces=1UL,
    max_tables_per_face=2UL,
    max_table_records=2UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=184UL,
    max_work=34UL,
  ).unwrap()
}

///|
fn font_collection_test_limits() -> FontCollectionLimits {
  font_collection_test_limits_with_source(88UL)
}

///|
fn font_collection_test_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=184UL,
      allocations=2UL,
      allocation_size=48UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=34UL,
    ),
  )
}

///|
fn font_collection_test_assert_error(
  error : @error.CoreError,
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
) -> Unit raise {
  inspect(error.category() == category, content="true")
  inspect(error.code() == code, content="true")
  inspect(error.operation() == Some("font-collection-open"), content="true")
}

///|
fn font_collection_test_assert_budget_unchanged(
  before : @budget.ResourceLimits,
  budget : @budget.Budget,
) -> Unit raise {
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
fn font_collection_test_assert_invalid_limit(
  result : Result[FontCollectionLimits, @error.CoreError],
  context : String,
) -> Unit raise {
  let error = result.unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-collection-limits-new"),
    content="true",
  )
  inspect(error.requested() == Some(0UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
fn font_collection_test_mutate(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  replacement : Byte,
) -> Unit {
  owner
  .with_mut(offset, 1UL, fn(lease) { lease.set(0UL, replacement) })
  .unwrap()
}

///|
fn font_collection_test_assert_query_drift(
  error : @error.CoreError,
) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-collection-query"),
    content="true",
  )
  inspect(
    error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
}

///|
fn font_collection_test_assert_every_query_drift(
  collection : FontCollection,
) -> Unit raise {
  font_collection_test_assert_query_drift(
    collection.face_count().unwrap_err(),
  )
  font_collection_test_assert_query_drift(
    collection.face_profile(0UL).unwrap_err(),
  )
  font_collection_test_assert_query_drift(
    collection.dsig_status().unwrap_err(),
  )
}

///|
fn font_collection_test_limits_result(
  max_source_bytes : UInt64,
  max_faces : UInt64,
  max_tables_per_face : UInt64,
  max_table_records : UInt64,
  max_dsig_records : UInt64,
  max_dsig_bytes : UInt64,
  max_retained_bookkeeping_bytes : UInt64,
  max_work : UInt64,
) -> Result[FontCollectionLimits, @error.CoreError] {
  FontCollectionLimits::new(
    max_source_bytes~,
    max_faces~,
    max_tables_per_face~,
    max_table_records~,
    max_dsig_records~,
    max_dsig_bytes~,
    max_retained_bookkeeping_bytes~,
    max_work~,
  )
}

///|
test "TTC-01 tracer opens one static glyf collection atomically" {
  let owner = font_collection_test_owner(font_collection_test_ttc())
  let budget = font_collection_test_budget()
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_limits(),
    budget,
  ).unwrap()
  inspect(collection.face_count().unwrap(), content="1")
  inspect(
    collection.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  inspect(
    collection.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
  let remaining = budget.remaining()
  inspect(remaining.bytes(), content="0")
  inspect(remaining.allocations(), content="0")
  inspect(remaining.allocation_size(), content="48")
  inspect(remaining.work(), content="0")
}

///|
test "TTC-01 tracer rejects malformed envelopes without charging" {
  for source in [
    b"",
    b"\x74",
    b"\x74\x74",
    b"\x74\x74\x63",
    b"\x74\x74\x63\x66\x00\x01\x00\x00\x00\x00\x00",
    font_collection_test_zero_faces(),
  ] {
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_budget()
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_limits(),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 tracer enforces exact source authority before traversal" {
  let source = font_collection_test_ttc()
  let exact_owner = font_collection_test_owner(source)
  ignore(
    FontCollection::open(
      exact_owner.view(),
      font_collection_test_limits_with_source(88UL),
      font_collection_test_budget(),
    ).unwrap(),
  )
  let one_over_owner = font_collection_test_owner(source)
  let budget = font_collection_test_budget()
  let before = budget.remaining()
  let error = FontCollection::open(
    one_over_owner.view(),
    font_collection_test_limits_with_source(87UL),
    budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    error,
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
  )
  inspect(error.requested() == Some(88UL), content="true")
  inspect(error.limit() == Some(87UL), content="true")
  inspect(error.context() == Some("max-source-bytes"), content="true")
  font_collection_test_assert_budget_unchanged(before, budget)
}

///|
test "font collection limits preserve every explicit ceiling" {
  let limits = font_collection_test_limits_result(
    2UL,
    3UL,
    5UL,
    7UL,
    11UL,
    13UL,
    17UL,
    19UL,
  ).unwrap()
  inspect(limits.max_source_bytes(), content="2")
  inspect(limits.max_faces(), content="3")
  inspect(limits.max_tables_per_face(), content="5")
  inspect(limits.max_table_records(), content="7")
  inspect(limits.max_dsig_records(), content="11")
  inspect(limits.max_dsig_bytes(), content="13")
  inspect(limits.max_retained_bookkeeping_bytes(), content="17")
  inspect(limits.max_work(), content="19")
}

///|
test "font collection limits reject every zero ceiling in argument order" {
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(0UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL),
    "max-source-bytes",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 0UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL),
    "max-faces",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 0UL, 1UL, 1UL, 1UL, 1UL, 1UL),
    "max-tables-per-face",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 0UL, 1UL, 1UL, 1UL, 1UL),
    "max-table-records",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 0UL, 1UL, 1UL, 1UL),
    "max-dsig-records",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 1UL, 0UL, 1UL, 1UL),
    "max-dsig-bytes",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 0UL, 1UL),
    "max-retained-bookkeeping-bytes",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 0UL),
    "max-work",
  )
}

///|
test "collection queries expose exact unchanged index errors" {
  let owner = font_collection_test_owner(font_collection_test_ttc())
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  let error = collection.face_profile(1UL).unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-collection-query"),
    content="true",
  )
  inspect(error.requested() == Some(1UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(
    error.context() == Some("font-collection-face-index"),
    content="true",
  )
}

///|
test "required unrelated and restored mutations invalidate every collection query" {
  for offset in [80UL, 87UL] {
    let owner = font_collection_test_owner(font_collection_test_ttc())
    let collection = FontCollection::open(
      owner.view(),
      font_collection_test_limits(),
      font_collection_test_budget(),
    ).unwrap()
    font_collection_test_mutate(owner, offset, b'\x01')
    font_collection_test_assert_every_query_drift(collection)
  }
  let restored_owner = font_collection_test_owner(font_collection_test_ttc())
  let restored = FontCollection::open(
    restored_owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  font_collection_test_mutate(restored_owner, 80UL, b'\x01')
  font_collection_test_mutate(restored_owner, 80UL, b'\x00')
  font_collection_test_assert_every_query_drift(restored)
}

///|
test "revision drift precedes index validation and remains owner-local" {
  let drifted_owner = font_collection_test_owner(font_collection_test_ttc())
  let drifted = FontCollection::open(
    drifted_owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  let stable_owner = font_collection_test_owner(font_collection_test_ttc())
  let stable = FontCollection::open(
    stable_owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  font_collection_test_mutate(drifted_owner, 87UL, b'\x01')
  font_collection_test_assert_query_drift(
    drifted.face_profile(1UL).unwrap_err(),
  )
  inspect(stable.face_count().unwrap(), content="1")
  inspect(
    stable.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  inspect(
    stable.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
}

///|
test "TTC-01 all-face structure preserves v2 offset order and closed profiles" {
  let owner = font_collection_test_owner(font_collection_test_multi_ttc())
  let limits = FontCollectionLimits::new(
    max_source_bytes=400UL,
    max_faces=5UL,
    max_tables_per_face=3UL,
    max_table_records=8UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=440UL,
    max_work=195UL,
  ).unwrap()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=440UL,
      allocations=2UL,
      allocation_size=200UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=195UL,
    ),
  )
  let collection = FontCollection::open(owner.view(), limits, budget).unwrap()
  inspect(collection.face_count().unwrap(), content="5")
  for item in [
    (0UL, FontFaceProfile::StaticGlyf),
    (1UL, FontFaceProfile::Cff),
    (2UL, FontFaceProfile::Cff2),
    (3UL, FontFaceProfile::Variable),
    (4UL, FontFaceProfile::OtherUnsupported),
  ] {
    let (index, expected) = item
    inspect(collection.face_profile(index).unwrap() == expected, content="true")
  }
  inspect(
    collection.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
}

///|
test "TTC-01 table offsets remain collection-root relative" {
  let source = font_collection_test_wrong_rebase_ttc()
  let owner = font_collection_test_owner(source)
  let limits = FontCollectionLimits::new(
    max_source_bytes=128UL,
    max_faces=1UL,
    max_tables_per_face=1UL,
    max_table_records=1UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=184UL,
    max_work=27UL,
  ).unwrap()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=184UL,
      allocations=2UL,
      allocation_size=48UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=27UL,
    ),
  )
  let collection = FontCollection::open(owner.view(), limits, budget).unwrap()
  inspect(
    collection.face_profile(0UL).unwrap() ==
    FontFaceProfile::OtherUnsupported,
    content="true",
  )
}

///|
test "TTC-01 v2 offset array and final directory record truncate as Data" {
  let complete = font_collection_test_multi_ttc()
  for length in [15, 31, 43, 267] {
    let owner = font_collection_test_owner(
      font_collection_test_prefix(complete, length),
    )
    let budget = font_collection_test_budget()
    let before = budget.remaining()
    let limits = FontCollectionLimits::new(
      max_source_bytes=400UL,
      max_faces=5UL,
      max_tables_per_face=3UL,
      max_table_records=8UL,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=440UL,
      max_work=195UL,
    ).unwrap()
    let error = FontCollection::open(owner.view(), limits, budget).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}
