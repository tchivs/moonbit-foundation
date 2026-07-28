///|
fn font_collection_wb_put_u16(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn font_collection_wb_put_u32(
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
fn font_collection_wb_view(source : Bytes) -> @bytes.ByteView {
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
  )
  .unwrap()
  .view()
}

///|
fn font_collection_wb_owner(source : Bytes) -> @bytes.OwnedBytes {
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
fn font_collection_wb_mutate_restore(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
) -> Unit {
  let original = owner.view().get(offset).unwrap()
  owner
  .with_mut(offset, 1UL, fn(lease) {
    lease.set(0UL, (original.to_uint64() ^ 1UL).to_byte())
  })
  .unwrap()
  owner
  .with_mut(offset, 1UL, fn(lease) { lease.set(0UL, original) })
  .unwrap()
}

///|
fn font_collection_wb_font_limits(source_length : UInt64) -> FontLimits {
  FontLimits::new(
    max_source_bytes=source_length,
    max_tables=4UL,
    max_table_bytes=64UL,
    max_glyphs=4UL,
    max_name_records=4UL,
    max_cmap_records=4UL,
    max_kern_subtables=4UL,
    max_kern_pairs=4UL,
    max_outline_points=64UL,
    max_outline_contours=16UL,
    max_outline_components=16UL,
    max_outline_instruction_bytes=64UL,
    max_post_name_bytes=64UL,
    max_work=4096UL,
  ).unwrap()
}

///|
fn font_collection_wb_checksum(
  source : Array[Byte],
  start : Int,
  length : Int,
  zero_head_adjustment : Bool,
) -> UInt64 {
  let mut checksum = 0UL
  let mut offset = 0
  while offset < length {
    let mut word = 0UL
    for delta in [0, 1, 2, 3] {
      let index = offset + delta
      let byte = if
        zero_head_adjustment && index >= 8 && index < 12 {
        b'\x00'
      } else if index < length {
        source[start + index]
      } else {
        b'\x00'
      }
      word = (word << 8) | byte.to_uint64()
    }
    checksum = (checksum + word) & 0xFFFFFFFFUL
    offset = offset + 4
  }
  checksum
}

///|
fn font_collection_wb_offset_directory(
  head_offset : UInt64,
  head_length : UInt64,
  name_offset : UInt64,
  name_length : UInt64,
  bad_head_checksum? : Bool = false,
) -> Bytes {
  let output = Array::make(160, b'\x00')
  let directory_start = 64
  let head_start = head_offset.to_int()
  let head_size = head_length.to_int()
  for index = 0; index < head_size; index = index + 1 {
    output[head_start + index] = (index + 1).to_byte()
  }
  if head_size >= 12 {
    output[head_start + 8] = b'\xaa'
    output[head_start + 9] = b'\xbb'
    output[head_start + 10] = b'\xcc'
    output[head_start + 11] = b'\xdd'
  }
  let name_start = name_offset.to_int()
  let name_size = name_length.to_int()
  for index = 0; index < name_size; index = index + 1 {
    output[name_start + index] = (0x40 + index).to_byte()
  }

  font_collection_wb_put_u32(output, directory_start, 0x00010000UL)
  font_collection_wb_put_u16(output, directory_start + 4, 2UL)
  font_collection_wb_put_u16(output, directory_start + 6, 32UL)
  font_collection_wb_put_u16(output, directory_start + 8, 1UL)
  font_collection_wb_put_u16(output, directory_start + 10, 0UL)
  font_collection_wb_put_u32(output, directory_start + 12, 0x68656164UL)
  let head_checksum = font_collection_wb_checksum(
    output,
    head_start,
    head_size,
    true,
  )
  font_collection_wb_put_u32(
    output,
    directory_start + 16,
    if bad_head_checksum { head_checksum ^ 1UL } else { head_checksum },
  )
  font_collection_wb_put_u32(output, directory_start + 20, head_offset)
  font_collection_wb_put_u32(output, directory_start + 24, head_length)

  font_collection_wb_put_u32(output, directory_start + 28, 0x6E616D65UL)
  font_collection_wb_put_u32(
    output,
    directory_start + 32,
    font_collection_wb_checksum(output, name_start, name_size, false),
  )
  font_collection_wb_put_u32(output, directory_start + 36, name_offset)
  font_collection_wb_put_u32(output, directory_start + 40, name_length)
  Bytes::from_array(output)
}

///|
test "selected directory reads absolute fields and keeps table offsets root relative" {
  let source = font_collection_wb_offset_directory(32UL, 12UL, 112UL, 4UL)
  let view = font_collection_wb_view(source)
  let directory = font_parse_directory_at(
    view,
    64UL,
    Some(2UL),
    font_collection_wb_font_limits(view.length()),
    FontChecksumMode::Collection,
  ).unwrap()
  inspect(directory.tables.length(), content="2")
  inspect(directory.tables[0].offset, content="32")
  inspect(
    directory.tables[0].view.get(0UL).unwrap().to_uint64(),
    content="1",
  )
  inspect(directory.tables[1].offset, content="112")
  inspect(
    directory.tables[1].view.get(0UL).unwrap().to_uint64(),
    content="64",
  )
}

///|
test "selected directory permits touching tables and rejects intersections" {
  let touching = font_collection_wb_view(
    font_collection_wb_offset_directory(52UL, 12UL, 108UL, 4UL),
  )
  inspect(
    font_parse_directory_at(
      touching,
      64UL,
      Some(2UL),
      font_collection_wb_font_limits(touching.length()),
      FontChecksumMode::Collection,
    ) is Ok(_),
    content="true",
  )

  let intersecting = font_collection_wb_view(
    font_collection_wb_offset_directory(60UL, 8UL, 112UL, 4UL),
  )
  let overlap = font_parse_directory_at(
    intersecting,
    64UL,
    Some(2UL),
    font_collection_wb_font_limits(intersecting.length()),
    FontChecksumMode::Collection,
  ).unwrap_err()
  inspect(overlap.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    overlap.context() == Some("font-table-directory-overlap"),
    content="true",
  )
}

///|
test "selected directory cached count and checked base fail before record traversal" {
  let source = font_collection_wb_view(
    font_collection_wb_offset_directory(32UL, 12UL, 112UL, 4UL),
  )
  let count_error = font_parse_directory_at(
    source,
    64UL,
    Some(1UL),
    font_collection_wb_font_limits(source.length()),
    FontChecksumMode::Collection,
  ).unwrap_err()
  inspect(count_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(count_error.context() == Some("font-table-count"), content="true")

  let base_error = font_parse_directory_at(
    source,
    18446744073709551615UL,
    None,
    font_collection_wb_font_limits(source.length()),
    FontChecksumMode::Collection,
  ).unwrap_err()
  inspect(base_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(base_error.context() == Some("font-sfnt-header"), content="true")
}

///|
test "collection checksum mode keeps table integrity and skips only root adjustment" {
  let source = font_collection_wb_view(
    font_collection_wb_offset_directory(32UL, 12UL, 112UL, 4UL),
  )
  let directory = font_parse_directory_at(
    source,
    64UL,
    Some(2UL),
    font_collection_wb_font_limits(source.length()),
    FontChecksumMode::Collection,
  ).unwrap()
  inspect(
    font_validate_checksums_with_mode(
      directory,
      FontChecksumMode::Collection,
    ) is Ok(_),
    content="true",
  )
  let standalone = font_validate_checksums_with_mode(
    directory,
    FontChecksumMode::Standalone,
  ).unwrap_err()
  inspect(
    standalone.context() == Some("font-checksum-adjustment"),
    content="true",
  )

  let bad_source = font_collection_wb_view(
    font_collection_wb_offset_directory(
      32UL,
      12UL,
      112UL,
      4UL,
      bad_head_checksum=true,
    ),
  )
  let bad_directory = font_parse_directory_at(
    bad_source,
    64UL,
    Some(2UL),
    font_collection_wb_font_limits(bad_source.length()),
    FontChecksumMode::Collection,
  ).unwrap()
  let bad_checksum = font_validate_checksums_with_mode(
    bad_directory,
    FontChecksumMode::Collection,
  ).unwrap_err()
  inspect(
    bad_checksum.context() == Some("font-table-checksum"),
    content="true",
  )
}

///|
fn font_collection_wb_work_budget(work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn font_collection_wb_work_charge(work : UInt64) -> @budget.ResourceCharge {
  @budget.ResourceCharge::new(
    bytes=0UL,
    allocations=0UL,
    allocation_size=0UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work~,
  )
}

///|
test "deferred admission ledger cumulatively preflights ancestors without charging" {
  let exact = font_collection_wb_work_budget(15UL)
  let exact_before = exact.remaining()
  let exact_ledger = FontAdmissionLedger::new(
    exact,
    FontAdmissionCommitMode::CollectionDeferred,
  )
  exact_ledger.admit_stage(15UL, 13UL, 10UL, 3UL).unwrap()
  exact_ledger.admit_stage(15UL, 15UL, 10UL, 2UL).unwrap()
  inspect(exact_ledger.staged_work, content="5")
  inspect(exact.remaining().work() == exact_before.work(), content="true")

  let root = font_collection_wb_work_budget(20UL)
  let child = root.child(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=20UL,
    ),
  ).unwrap()
  root.charge(font_collection_wb_work_charge(6UL)).unwrap()
  let root_before = root.remaining()
  let child_before = child.remaining()
  let ledger = FontAdmissionLedger::new(
    child,
    FontAdmissionCommitMode::CollectionDeferred,
  )
  ledger.admit_stage(20UL, 13UL, 10UL, 3UL).unwrap()
  let error = ledger.admit_stage(20UL, 15UL, 10UL, 2UL).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.context() == Some("work"), content="true")
  inspect(ledger.staged_work, content="3")
  inspect(root.remaining().work() == root_before.work(), content="true")
  inspect(child.remaining().work() == child_before.work(), content="true")
}

///|
test "admission ledger preserves standalone increments and rejects overflow atomically" {
  let standalone_budget = font_collection_wb_work_budget(15UL)
  let standalone = FontAdmissionLedger::new(
    standalone_budget,
    FontAdmissionCommitMode::StandaloneIncremental,
  )
  standalone.admit_stage(15UL, 13UL, 10UL, 3UL).unwrap()
  inspect(standalone_budget.remaining().work(), content="12")
  standalone.admit_stage(15UL, 15UL, 10UL, 2UL).unwrap()
  inspect(standalone_budget.remaining().work(), content="10")
  inspect(standalone.staged_work, content="5")

  let overflow_budget = font_collection_wb_work_budget(
    18446744073709551615UL,
  )
  let overflow = FontAdmissionLedger::new(
    overflow_budget,
    FontAdmissionCommitMode::CollectionDeferred,
  )
  overflow
  .admit_stage(
    18446744073709551615UL,
    18446744073709551615UL,
    0UL,
    18446744073709551615UL,
  )
  .unwrap()
  let before = overflow_budget.remaining()
  let error = overflow
  .admit_stage(
    18446744073709551615UL,
    18446744073709551615UL,
    0UL,
    1UL,
  )
  .unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.context() == Some("max-work"), content="true")
  inspect(
    overflow_budget.remaining().work() == before.work(),
    content="true",
  )
}

///|
fn font_collection_wb_two_face_v2() -> Bytes {
  let output = Array::make(160, b'\x00')
  font_collection_wb_put_u32(output, 0, 0x74746366UL)
  font_collection_wb_put_u32(output, 4, 0x00020000UL)
  font_collection_wb_put_u32(output, 8, 2UL)
  font_collection_wb_put_u32(output, 12, 48UL)
  font_collection_wb_put_u32(output, 16, 80UL)
  // v2 DSIG tuple at [20, 32) remains all-zero.
  font_collection_wb_put_u32(output, 48, 0x4F54544FUL)
  font_collection_wb_put_u16(output, 52, 1UL)
  font_collection_wb_put_u16(output, 54, 16UL)
  font_collection_wb_put_u32(output, 60, 0x43464620UL)
  font_collection_wb_put_u32(output, 64, 7UL)
  font_collection_wb_put_u32(output, 68, 132UL)
  font_collection_wb_put_u32(output, 72, 4UL)
  font_collection_wb_put_u32(output, 80, 0x00010000UL)
  font_collection_wb_put_u16(output, 84, 2UL)
  font_collection_wb_put_u16(output, 86, 32UL)
  font_collection_wb_put_u16(output, 88, 1UL)
  font_collection_wb_put_u32(output, 92, 0x676C7966UL)
  font_collection_wb_put_u32(output, 96, 11UL)
  font_collection_wb_put_u32(output, 100, 136UL)
  font_collection_wb_put_u32(output, 104, 4UL)
  font_collection_wb_put_u32(output, 108, 0x6C6F6361UL)
  font_collection_wb_put_u32(output, 112, 13UL)
  font_collection_wb_put_u32(output, 116, 140UL)
  font_collection_wb_put_u32(output, 120, 4UL)
  Bytes::from_array(output)
}

///|
fn font_collection_wb_limits() -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=160UL,
    max_faces=2UL,
    max_tables_per_face=2UL,
    max_table_records=3UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=248UL,
    max_work=86UL,
  ).unwrap()
}

///|
test "collection structural pass keeps root ranges and face order" {
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=248UL,
      allocations=2UL,
      allocation_size=80UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=86UL,
    ),
  )
  let facts = font_collection_parse(
    font_collection_wb_view(font_collection_wb_two_face_v2()),
    font_collection_wb_limits(),
    budget,
  ).unwrap()
  inspect(facts.faces.length(), content="2")
  inspect(facts.faces[0].directory_start, content="48")
  inspect(facts.faces[0].directory_end, content="76")
  inspect(facts.faces[0].table_count, content="1")
  inspect(facts.faces[0].profile == FontFaceProfile::Cff, content="true")
  inspect(facts.faces[1].directory_start, content="80")
  inspect(facts.faces[1].directory_end, content="124")
  inspect(facts.faces[1].table_count, content="2")
  inspect(facts.faces[1].profile == FontFaceProfile::StaticGlyf, content="true")
  inspect(facts.protected_ranges.length(), content="3")
  inspect(facts.protected_ranges[0].end, content="32")
  inspect(facts.protected_ranges[1].start, content="48")
  inspect(facts.protected_ranges[2].start, content="80")
}

///|
test "collection accounting formula includes every protected and alias pair" {
  inspect(font_collection_choose_two(0UL, 48UL).unwrap(), content="0")
  inspect(font_collection_choose_two(3UL, 48UL).unwrap(), content="3")
  inspect(
    font_collection_exact_work(2UL, 2UL, 3UL, 0UL, 0UL, 0UL, 66UL).unwrap(),
    content="66",
  )
  let overflow = font_collection_choose_two(18446744073709551615UL, 48UL).unwrap_err()
  inspect(overflow.category() == @error.ErrorCategory::Resource, content="true")
  inspect(overflow.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(overflow.context() == Some("max-work"), content="true")
}

///|
test "collection DSIG work includes header records and block pairs exactly" {
  inspect(
    font_collection_structural_work(
      1UL, 1UL, 3UL, 1UL, 1UL, 1UL, 43UL,
    ).unwrap(),
    content="43",
  )
  inspect(
    font_collection_exact_work(1UL, 1UL, 3UL, 1UL, 1UL, 1UL, 57UL).unwrap(),
    content="57",
  )
  // The helper's limit bounds arithmetic overflow; retained-charge performs
  // the final semantic one-short comparison.
  inspect(
    font_collection_exact_work(1UL, 1UL, 3UL, 1UL, 1UL, 1UL, 56UL).unwrap(),
    content="57",
  )
  inspect(
    font_collection_exact_work(1UL, 1UL, 3UL, 1UL, 1UL, 2UL, 64UL).unwrap(),
    content="64",
  )
}

///|
test "collection final revision guard rejects mutate-restoration atomically" {
  let owner = font_collection_wb_owner(font_collection_wb_two_face_v2())
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=248UL,
      allocations=2UL,
      allocation_size=80UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=86UL,
    ),
  )
  let before = budget.remaining()
  let mut callback_count = 0
  let result = FontCollection::open_after_normalize(
    owner.view(),
    font_collection_wb_limits(),
    budget,
    fn() {
      callback_count = callback_count + 1
      font_collection_wb_mutate_restore(owner, 132UL)
    },
  )
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-collection-open"),
    content="true",
  )
  inspect(
    error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
  inspect(callback_count, content="1")
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.work() == before.work(), content="true")
}
