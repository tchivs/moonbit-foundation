///|
fn font_collection_test_push_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_collection_test_push_u32(output : Array[Byte], value : UInt64) -> Unit {
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
  for item in [(12, 64UL), (16, 112UL), (20, 144UL), (24, 176UL), (28, 240UL)] {
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
fn font_collection_test_pair_ttc(
  left_tag : UInt64,
  left_checksum : UInt64,
  left_offset : UInt64,
  left_length : UInt64,
  right_tag : UInt64,
  right_checksum : UInt64,
  right_offset : UInt64,
  right_length : UInt64,
) -> Bytes {
  let output = Array::make(160, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 2UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_put_u32(output, 16, 64UL)
  for
    item in [
      (32, left_tag, left_checksum, left_offset, left_length),
      (64, right_tag, right_checksum, right_offset, right_length),
    ] {
    let (start, tag, checksum, offset, length) = item
    font_collection_test_put_u32(output, start, 0x00010000UL)
    font_collection_test_put_u16(output, start + 4, 1UL)
    font_collection_test_put_u16(output, start + 6, 16UL)
    font_collection_test_put_u32(output, start + 12, tag)
    font_collection_test_put_u32(output, start + 16, checksum)
    font_collection_test_put_u32(output, start + 20, offset)
    font_collection_test_put_u32(output, start + 24, length)
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_same_face_overlap_ttc() -> Bytes {
  let output = Array::make(128, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_write_directory(
    output,
    32,
    0x00010000UL,
    [0x676C7966UL, 0x6C6F6361UL],
    [96UL, 96UL],
  )
  Bytes::from_array(output)
}

///|
fn font_collection_test_pair_limits(
  max_retained : UInt64,
  max_work : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=160UL,
    max_faces=2UL,
    max_tables_per_face=1UL,
    max_table_records=2UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=max_retained,
    max_work~,
  ).unwrap()
}

///|
fn font_collection_test_pair_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  work : UInt64,
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
      work~,
    ),
  )
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
  inspect(error.operation() == Some("font-collection-query"), content="true")
  inspect(
    error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
}

///|
fn font_collection_test_assert_every_query_drift(
  collection : FontCollection,
) -> Unit raise {
  font_collection_test_assert_query_drift(collection.face_count().unwrap_err())
  font_collection_test_assert_query_drift(
    collection.face_profile(0UL).unwrap_err(),
  )
  font_collection_test_assert_query_drift(collection.dsig_status().unwrap_err())
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
  for
    source in [
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
    2UL, 3UL, 5UL, 7UL, 11UL, 13UL, 17UL, 19UL,
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
  inspect(error.operation() == Some("font-collection-query"), content="true")
  inspect(error.requested() == Some(1UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some("font-collection-face-index"), content="true")
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
  for
    item in [
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
    collection.face_profile(0UL).unwrap() == FontFaceProfile::OtherUnsupported,
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

///|
test "TTC-01 exact sharing and touching pass while every overlap conflict fails" {
  let name = 0x6E616D65UL
  for
    source in [
      font_collection_test_pair_ttc(name, 7UL, 96UL, 4UL, name, 7UL, 96UL, 4UL),
      font_collection_test_pair_ttc(name, 7UL, 96UL, 4UL, name, 9UL, 100UL, 4UL),
      font_collection_test_pair_ttc(name, 7UL, 96UL, 0UL, name, 9UL, 96UL, 0UL),
    ] {
    let owner = font_collection_test_owner(source)
    ignore(
      FontCollection::open(
        owner.view(),
        font_collection_test_pair_limits(248UL, 48UL),
        font_collection_test_pair_budget(248UL, 2UL, 80UL, 48UL),
      ).unwrap(),
    )
  }
  for
    source in [
      font_collection_test_pair_ttc(name, 7UL, 96UL, 8UL, name, 7UL, 100UL, 8UL),
      font_collection_test_pair_ttc(name, 7UL, 96UL, 4UL, name, 8UL, 96UL, 4UL),
      font_collection_test_pair_ttc(name, 7UL, 64UL, 4UL, name, 9UL, 100UL, 4UL),
    ] {
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 48UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(248UL, 48UL),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let same_face_owner = font_collection_test_owner(
    font_collection_test_same_face_overlap_ttc(),
  )
  let same_face_budget = font_collection_test_pair_budget(
    184UL, 2UL, 48UL, 34UL,
  )
  let before = same_face_budget.remaining()
  let limits = FontCollectionLimits::new(
    max_source_bytes=128UL,
    max_faces=1UL,
    max_tables_per_face=2UL,
    max_table_records=2UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=184UL,
    max_work=34UL,
  ).unwrap()
  let error = FontCollection::open(
    same_face_owner.view(),
    limits,
    same_face_budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    error,
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
  )
  font_collection_test_assert_budget_unchanged(before, same_face_budget)
  let duplicate_directory = font_collection_test_pair_ttc(
    name, 7UL, 96UL, 4UL, name, 9UL, 100UL, 4UL,
  ).to_array()
  font_collection_test_put_u32(duplicate_directory, 16, 32UL)
  let duplicate_owner = font_collection_test_owner(
    Bytes::from_array(duplicate_directory),
  )
  let duplicate_budget = font_collection_test_pair_budget(
    248UL, 2UL, 80UL, 48UL,
  )
  let duplicate_before = duplicate_budget.remaining()
  let duplicate_error = FontCollection::open(
    duplicate_owner.view(),
    font_collection_test_pair_limits(248UL, 48UL),
    duplicate_budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    duplicate_error,
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
  )
  font_collection_test_assert_budget_unchanged(
    duplicate_before, duplicate_budget,
  )
}

///|
test "TTC-01 compact charge exact fit succeeds and every one-short is atomic" {
  let shared = font_collection_test_pair_ttc(
    0x6E616D65UL, 7UL, 96UL, 4UL, 0x6E616D65UL, 7UL, 96UL, 4UL,
  )
  let exact_owner = font_collection_test_owner(shared)
  let exact_budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 48UL)
  ignore(
    FontCollection::open(
      exact_owner.view(),
      font_collection_test_pair_limits(248UL, 48UL),
      exact_budget,
    ).unwrap(),
  )
  inspect(exact_budget.remaining().bytes(), content="0")
  inspect(exact_budget.remaining().allocations(), content="0")
  inspect(exact_budget.remaining().allocation_size(), content="80")
  inspect(exact_budget.remaining().work(), content="0")
  for
    item in [
      (247UL, 2UL, 80UL, 48UL),
      (248UL, 1UL, 80UL, 48UL),
      (248UL, 2UL, 79UL, 48UL),
      (248UL, 2UL, 80UL, 47UL),
    ] {
    let (bytes, allocations, allocation_size, work) = item
    let owner = font_collection_test_owner(shared)
    let budget = font_collection_test_pair_budget(
      bytes, allocations, allocation_size, work,
    )
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(248UL, 48UL),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  for item in [(247UL, 48UL), (248UL, 47UL)] {
    let (retained, work) = item
    let owner = font_collection_test_owner(shared)
    let budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 48UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(retained, work),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Resource,
      @error.ErrorCode::BudgetExceeded,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 declaration ceilings fail before dependent structural work" {
  let source = font_collection_test_multi_ttc()
  for
    item in [
      (4UL, 3UL, 8UL, "max-faces"),
      (5UL, 2UL, 8UL, "max-tables-per-face"),
      (5UL, 3UL, 7UL, "max-table-records"),
    ] {
    let (faces, per_face, records, context) = item
    let owner = font_collection_test_owner(source)
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
    let before = budget.remaining()
    let limits = FontCollectionLimits::new(
      max_source_bytes=400UL,
      max_faces=faces,
      max_tables_per_face=per_face,
      max_table_records=records,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=440UL,
      max_work=195UL,
    ).unwrap()
    let error = FontCollection::open(owner.view(), limits, budget).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Resource,
      @error.ErrorCode::BudgetExceeded,
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
fn font_collection_test_dsig_ttc() -> Bytes {
  let output = Array::make(100, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00020000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_put_u32(output, 16, 0x44534947UL)
  font_collection_test_put_u32(output, 20, 32UL)
  font_collection_test_put_u32(output, 24, 68UL)
  font_collection_test_write_directory(
    output,
    32,
    0x00010000UL,
    [0x6E616D65UL],
    [64UL],
  )
  // DSIG v1 header and one format-1 signature record.
  font_collection_test_put_u32(output, 68, 1UL)
  font_collection_test_put_u16(output, 72, 1UL)
  font_collection_test_put_u16(output, 74, 1UL)
  font_collection_test_put_u32(output, 76, 1UL)
  font_collection_test_put_u32(output, 80, 12UL)
  font_collection_test_put_u32(output, 84, 20UL)
  // Signature block: two reserved UInt16 values, length, opaque payload.
  font_collection_test_put_u32(output, 92, 4UL)
  output[96] = b'\xde'
  output[97] = b'\xad'
  output[98] = b'\xbe'
  output[99] = b'\xef'
  Bytes::from_array(output)
}

///|
fn font_collection_test_dsig_limits(
  max_records : UInt64,
  max_bytes : UInt64,
  max_work : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=100UL,
    max_faces=1UL,
    max_tables_per_face=1UL,
    max_table_records=1UL,
    max_dsig_records=max_records,
    max_dsig_bytes=max_bytes,
    max_retained_bookkeeping_bytes=208UL,
    max_work~,
  ).unwrap()
}

///|
fn font_collection_test_dsig_budget(work : UInt64) -> @budget.Budget {
  font_collection_test_pair_budget(208UL, 2UL, 72UL, work)
}

///|
test "TTC-01 DSIG tuple and supported envelope remain explicitly unverified" {
  let source = font_collection_test_dsig_ttc()
  let owner = font_collection_test_owner(source)
  let budget = font_collection_test_dsig_budget(48UL)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_dsig_limits(1UL, 32UL, 48UL),
    budget,
  ).unwrap()
  inspect(
    collection.dsig_status().unwrap() ==
    FontCollectionDsigStatus::PresentUnverified,
    content="true",
  )
  inspect(budget.remaining().work(), content="0")

  for
    item in [
      (16, 0UL, "font-collection-dsig-tuple"),
      (20, 0UL, "font-collection-dsig-tuple"),
      (24, 0UL, "font-collection-dsig-tuple"),
    ] {
    let (field, value, context) = item
    let malformed = source.to_array()
    font_collection_test_put_u32(malformed, field, value)
    let malformed_owner = font_collection_test_owner(
      Bytes::from_array(malformed),
    )
    let malformed_budget = font_collection_test_dsig_budget(48UL)
    let before = malformed_budget.remaining()
    let error = FontCollection::open(
      malformed_owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 48UL),
      malformed_budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, malformed_budget)
  }
}

///|
test "TTC-01 DSIG body rejects malformed and complete unsupported facts" {
  let source = font_collection_test_dsig_ttc()
  for
    item in [
      (
        68,
        2UL,
        @error.ErrorCategory::Capability,
        "font-collection-dsig-version",
      ),
      (76, 2UL, @error.ErrorCategory::Capability, "font-collection-dsig-format"),
      (72, 0UL, @error.ErrorCategory::Data, "font-collection-dsig-count"),
      (74, 2UL, @error.ErrorCategory::Data, "font-collection-dsig-flags"),
      (
        80,
        11UL,
        @error.ErrorCategory::Data,
        "font-collection-dsig-block-length",
      ),
      (84, 8UL, @error.ErrorCategory::Data, "font-collection-dsig-block-range"),
      (88, 1UL, @error.ErrorCategory::Data, "font-collection-dsig-reserved"),
      (
        92,
        0UL,
        @error.ErrorCategory::Data,
        "font-collection-dsig-payload-length",
      ),
    ] {
    let (field, value, category, context) = item
    let malformed = source.to_array()
    if field == 72 || field == 74 {
      font_collection_test_put_u16(malformed, field, value)
    } else {
      font_collection_test_put_u32(malformed, field, value)
    }
    let owner = font_collection_test_owner(Bytes::from_array(malformed))
    let budget = font_collection_test_dsig_budget(48UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 48UL),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      category,
      if category == @error.ErrorCategory::Capability {
        @error.ErrorCode::CapabilityUnavailable
      } else {
        @error.ErrorCode::InvalidEncoding
      },
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 DSIG record and work ceilings are exact and atomic" {
  let source = font_collection_test_dsig_ttc()
  for
    item in [
      (0UL, 32UL, 48UL, "max-dsig-records"),
      (1UL, 31UL, 48UL, "max-dsig-bytes"),
      (1UL, 32UL, 47UL, "max-work"),
    ] {
    let (records, bytes, work, context) = item
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_dsig_budget(48UL)
    let before = budget.remaining()
    let limits = if records == 0UL {
      // Public constructors reject zero, so prove the one-over declaration by
      // declaring two records under an exact one-record ceiling.
      font_collection_test_dsig_limits(1UL, bytes, work)
    } else {
      font_collection_test_dsig_limits(records, bytes, work)
    }
    let candidate = if records == 0UL {
      let bytes = source.to_array()
      font_collection_test_put_u16(bytes, 72, 2UL)
      Bytes::from_array(bytes)
    } else {
      source
    }
    let candidate_owner = font_collection_test_owner(candidate)
    let error = FontCollection::open(candidate_owner.view(), limits, budget).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Resource,
      @error.ErrorCode::BudgetExceeded,
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
    ignore(owner)
  }
}
