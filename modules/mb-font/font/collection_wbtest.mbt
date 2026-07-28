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
fn font_collection_wb_assert_budget_unchanged(
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
fn font_collection_wb_read_u32(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 24) |
  (source[offset + 1].to_uint64() << 16) |
  (source[offset + 2].to_uint64() << 8) |
  source[offset + 3].to_uint64()
}

///|
fn font_collection_wb_selected_ttc() -> Bytes {
  let standalone = generated_minimal_truetype()
  let directory_start = 256
  let output = Array::make(directory_start + standalone.length(), b'\x00')
  font_collection_wb_put_u32(output, 0, 0x74746366UL)
  font_collection_wb_put_u32(output, 4, 0x00010000UL)
  font_collection_wb_put_u32(output, 8, 1UL)
  font_collection_wb_put_u32(output, 12, directory_start.to_uint64())
  for index, byte in standalone {
    output[directory_start + index] = byte
  }
  for index = 0; index < 10; index = index + 1 {
    let record = 12 + index * 16
    let old_offset = font_collection_wb_read_u32(standalone, record + 8)
    let new_offset = if index == 6 { 20UL } else {
      old_offset + directory_start.to_uint64()
    }
    font_collection_wb_put_u32(
      output,
      directory_start + record + 8,
      new_offset,
    )
  }
  let loca_offset = font_collection_wb_read_u32(standalone, 12 + 6 * 16 + 8)
  let loca_length = font_collection_wb_read_u32(standalone, 12 + 6 * 16 + 12)
  for index = 0; index < loca_length.to_int(); index = index + 1 {
    output[20 + index] = standalone[loca_offset.to_int() + index]
  }
  Bytes::from_array(output)
}

///|
fn font_collection_wb_selected_collection_limits(
  source_length : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=source_length,
    max_faces=1UL,
    max_tables_per_face=10UL,
    max_table_records=10UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=4096UL,
    max_work=65536UL,
  ).unwrap()
}

///|
fn font_collection_wb_selected_font_limits(
  source_length : UInt64,
) -> FontLimits {
  FontLimits::new(
    max_source_bytes=source_length,
    max_tables=10UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_outline_points=4096UL,
    max_outline_contours=256UL,
    max_outline_components=256UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
}

///|
fn font_collection_wb_selected_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=65536UL,
      allocations=16UL,
      allocation_size=65536UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=65536UL,
    ),
  )
}

///|
fn font_collection_wb_selected_work_budget(work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=65536UL,
      allocations=16UL,
      allocation_size=65536UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
test "selected final revision hook is atomic and successful Font retains root identity" {
  let source = font_collection_wb_selected_ttc()
  let owner = font_collection_wb_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_wb_selected_collection_limits(source.length().to_uint64()),
    font_collection_wb_selected_budget(),
  ).unwrap()
  let directory = font_parse_directory_at(
    owner.view(),
    256UL,
    Some(10UL),
    font_collection_wb_selected_font_limits(source.length().to_uint64()),
    FontChecksumMode::Collection,
  ).unwrap()
  let mut table_bytes = 0UL
  for table in directory.tables {
    table_bytes = table_bytes + table.length_value
  }
  inspect(
    font_collection_selected_extent_bytes(directory).unwrap() ==
    172UL + table_bytes,
    content="true",
  )
  let budget = font_collection_wb_selected_budget()
  let before = budget.remaining()
  let mut callback_count = 0
  let error = collection
    .open_face_after_admit(
      0UL,
      font_collection_wb_selected_font_limits(source.length().to_uint64()),
      budget,
      fn() {
        callback_count = callback_count + 1
        font_collection_wb_mutate_restore(owner, 20UL)
      },
    )
    .unwrap_err()
  inspect(callback_count, content="1")
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(
    error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
  inspect(error.source_offset() is None, content="true")
  inspect(error.requested() is None, content="true")
  inspect(error.limit() is None, content="true")
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(
    after.allocation_size() == before.allocation_size(),
    content="true",
  )
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")

  let stable_source = font_collection_wb_selected_ttc()
  let stable_owner = font_collection_wb_owner(stable_source)
  let stable_collection = FontCollection::open(
    stable_owner.view(),
    font_collection_wb_selected_collection_limits(
      stable_source.length().to_uint64(),
    ),
    font_collection_wb_selected_budget(),
  ).unwrap()
  let font = stable_collection
    .open_face(
      0UL,
      font_collection_wb_selected_font_limits(
        stable_source.length().to_uint64(),
      ),
      font_collection_wb_selected_budget(),
    )
    .unwrap()
  let second_font = stable_collection
    .open_face(
      0UL,
      font_collection_wb_selected_font_limits(
        stable_source.length().to_uint64(),
      ),
      font_collection_wb_selected_budget(),
    )
    .unwrap()
  inspect(font.source.length() == stable_collection.source.length(), content="true")
  inspect(font.opening_revision == stable_collection.opening_revision, content="true")
  inspect(
    second_font.opening_revision == stable_collection.opening_revision,
    content="true",
  )
  inspect(
    font.source.mutation_revision() ==
    stable_collection.source.mutation_revision(),
    content="true",
  )
  inspect(
    second_font.source.mutation_revision() ==
    stable_collection.source.mutation_revision(),
    content="true",
  )
  inspect(second_font.source.length() == font.source.length(), content="true")
}

///|
test "selected caller and ancestor authority precede every dependent loop family" {
  let source = font_collection_wb_selected_ttc()
  let owner = font_collection_wb_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_wb_selected_collection_limits(source.length().to_uint64()),
    font_collection_wb_selected_budget(),
  ).unwrap()
  let limits = font_collection_wb_selected_font_limits(source.length().to_uint64())
  let directory = font_parse_directory_at(
    owner.view(),
    256UL,
    Some(10UL),
    limits,
    FontChecksumMode::Collection,
  ).unwrap()
  let directory_prefix = font_collection_directory_structural_work(10UL).unwrap()
  let profile_checksum_prefix = directory.work + 10UL * 12UL

  let exact = font_collection_wb_selected_budget()
  let exact_before = exact.remaining()
  let mut exact_directory = 0
  let mut exact_profile_checksum = 0
  let mut exact_semantic = 0
  ignore(
    collection
    .open_face_after_preflights(
      0UL,
      limits,
      exact,
      fn(stage) {
        match stage {
          "directory" => exact_directory = exact_directory + 1
          "profile-checksum" =>
            exact_profile_checksum = exact_profile_checksum + 1
          "semantic" => exact_semantic = exact_semantic + 1
          _ => ()
        }
      },
      fn() { () },
    )
    .unwrap(),
  )
  let exact_work = exact_before.work() - exact.remaining().work()
  inspect(exact_directory, content="1")
  inspect(exact_profile_checksum, content="1")
  inspect(exact_semantic, content="1")

  let directory_short = font_collection_wb_selected_work_budget(
    directory_prefix - 1UL,
  )
  let directory_short_before = directory_short.remaining()
  let mut directory_entries = 0
  let directory_error = collection
  .open_face_after_preflights(
    0UL,
    limits,
    directory_short,
    fn(_stage) { directory_entries = directory_entries + 1 },
    fn() { () },
  )
  .unwrap_err()
  inspect(directory_error.context() == Some("work"), content="true")
  inspect(directory_entries, content="0")
  inspect(
    directory_short.remaining().work() == directory_short_before.work(),
    content="true",
  )

  let profile_short = font_collection_wb_selected_work_budget(
    profile_checksum_prefix - 1UL,
  )
  let profile_short_before = profile_short.remaining()
  let mut profile_directory = 0
  let mut profile_later = 0
  let profile_error = collection
  .open_face_after_preflights(
    0UL,
    limits,
    profile_short,
    fn(stage) {
      if stage == "directory" {
        profile_directory = profile_directory + 1
      } else {
        profile_later = profile_later + 1
      }
    },
    fn() { () },
  )
  .unwrap_err()
  inspect(profile_error.context() == Some("work"), content="true")
  inspect(profile_directory, content="1")
  inspect(profile_later, content="0")
  inspect(
    profile_short.remaining().work() == profile_short_before.work(),
    content="true",
  )

  let semantic_short = font_collection_wb_selected_work_budget(exact_work - 1UL)
  let semantic_short_before = semantic_short.remaining()
  let mut semantic_prefixes = 0
  let semantic_error = collection
  .open_face_after_preflights(
    0UL,
    limits,
    semantic_short,
    fn(_stage) { semantic_prefixes = semantic_prefixes + 1 },
    fn() { () },
  )
  .unwrap_err()
  inspect(semantic_error.context() == Some("work"), content="true")
  inspect(semantic_error.requested() == Some(exact_work), content="true")
  inspect(semantic_prefixes, content="2")
  inspect(
    semantic_short.remaining().work() == semantic_short_before.work(),
    content="true",
  )

  let ancestor = font_collection_wb_selected_work_budget(exact_work)
  let child = ancestor.child(ancestor.remaining()).unwrap()
  ancestor.charge(font_collection_wb_work_charge(1UL)).unwrap()
  let ancestor_before = ancestor.remaining()
  let child_before = child.remaining()
  let mut ancestor_prefixes = 0
  let ancestor_error = collection
  .open_face_after_preflights(
    0UL,
    limits,
    child,
    fn(_stage) { ancestor_prefixes = ancestor_prefixes + 1 },
    fn() { () },
  )
  .unwrap_err()
  inspect(ancestor_error.context() == Some("work"), content="true")
  inspect(ancestor_error.requested() == Some(exact_work), content="true")
  inspect(ancestor_prefixes, content="2")
  inspect(
    ancestor.remaining().work() == ancestor_before.work(),
    content="true",
  )
  inspect(child.remaining().work() == child_before.work(), content="true")
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
  // Deferred stages preflight their exact cumulative staged prefix. Leave
  // four units at the live ancestor so the first three-unit loop is
  // authorized and the second loop fails before entry.
  root.charge(font_collection_wb_work_charge(16UL)).unwrap()
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
test "admission plan reports exact work without double counting staged scans" {
  let source = generated_minimal_truetype()
  let directory = font_parse_directory(
    font_wb_view(source),
    font_wb_limits(),
  ).unwrap()

  let standalone_budget = font_wb_open_budget()
  let standalone_before = standalone_budget.remaining()
  let standalone = font_admission_charge(
    directory,
    font_wb_limits(),
    standalone_budget,
    FontAdmissionCommitMode::StandaloneIncremental,
  ).unwrap()
  let staged = standalone_before.work() -
    standalone_budget.remaining().work()
  inspect(
    standalone.exact_work ==
    standalone.standalone_remaining_work + staged,
    content="true",
  )

  let deferred_budget = font_wb_open_budget()
  let deferred_before = deferred_budget.remaining()
  let deferred = font_admission_charge(
    directory,
    font_wb_limits(),
    deferred_budget,
    FontAdmissionCommitMode::CollectionDeferred,
  ).unwrap()
  inspect(deferred.exact_work == standalone.exact_work, content="true")
  inspect(
    deferred_budget.remaining().work() == deferred_before.work(),
    content="true",
  )

  let malformed = font_wb_mutate_table_field(
    source,
    b"cmap",
    8,
    b"\x00\x00\x00\x00",
  )
  let malformed_directory = font_parse_directory(
    font_wb_view(malformed),
    font_wb_limits(),
  ).unwrap()
  let failed_budget = font_wb_open_budget()
  let failed_before = failed_budget.remaining()
  inspect(
    font_admission_charge(
      malformed_directory,
      font_wb_limits(),
      failed_budget,
      FontAdmissionCommitMode::CollectionDeferred,
    ) is Err(_),
    content="true",
  )
  inspect(
    failed_budget.remaining().work() == failed_before.work(),
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
  inspect(overflow.operation() == Some("font-collection-open"), content="true")
  inspect(overflow.context() == Some("max-work"), content="true")
  inspect(
    overflow.requested() == Some(18446744073709551615UL),
    content="true",
  )
  inspect(overflow.limit() == Some(48UL), content="true")
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

///|
test "collection qualification preserves mid-operation mutation atomicity" {
  let open_owner = font_collection_wb_owner(font_collection_wb_two_face_v2())
  let open_budget = @budget.Budget::new(
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
  let open_before = open_budget.remaining()
  let mut open_callbacks = 0
  let open_error = FontCollection::open_after_normalize(
    open_owner.view(),
    font_collection_wb_limits(),
    open_budget,
    fn() {
      open_callbacks = open_callbacks + 1
      font_collection_wb_mutate_restore(open_owner, 132UL)
    },
  ).unwrap_err()
  inspect(open_callbacks, content="1")
  inspect(open_error.category() == @error.ErrorCategory::State, content="true")
  inspect(open_error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    open_error.operation() == Some("font-collection-open"),
    content="true",
  )
  inspect(
    open_error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
  inspect(open_error.source_offset() is None, content="true")
  inspect(open_error.requested() is None, content="true")
  inspect(open_error.limit() is None, content="true")
  font_collection_wb_assert_budget_unchanged(open_before, open_budget)

  let select_source = font_collection_wb_selected_ttc()
  let select_owner = font_collection_wb_owner(select_source)
  let collection = FontCollection::open(
    select_owner.view(),
    font_collection_wb_selected_collection_limits(
      select_source.length().to_uint64(),
    ),
    font_collection_wb_selected_budget(),
  ).unwrap()
  let select_budget = font_collection_wb_selected_budget()
  let select_before = select_budget.remaining()
  let mut select_callbacks = 0
  let select_error = collection
    .open_face_after_admit(
      0UL,
      font_collection_wb_selected_font_limits(
        select_source.length().to_uint64(),
      ),
      select_budget,
      fn() {
        select_callbacks = select_callbacks + 1
        font_collection_wb_mutate_restore(select_owner, 20UL)
      },
    )
    .unwrap_err()
  inspect(select_callbacks, content="1")
  inspect(
    select_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  inspect(
    select_error.code() == @error.ErrorCode::InvalidRange,
    content="true",
  )
  inspect(
    select_error.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(
    select_error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
  inspect(select_error.source_offset() is None, content="true")
  inspect(select_error.requested() is None, content="true")
  inspect(select_error.limit() is None, content="true")
  font_collection_wb_assert_budget_unchanged(select_before, select_budget)
}

///|
/// Two non-zero collection directories share the same root-relative CFF,
/// head, and maxp table ranges. The copied standalone directory at `payload`
/// is deliberately unreachable; it keeps the generated table bytes and
/// checksums intact while both selected faces exercise root-relative records.
fn font_collection_wb_shared_cff_ttc_from_standalone(
  standalone : Bytes,
) -> Bytes {
  let table_count = 9
  let directory_bytes = 12 + table_count * 16
  let first_directory = 32
  let second_directory = first_directory + directory_bytes
  let payload = second_directory + directory_bytes
  let output : Array[Byte] = []
  let mut index = 0
  while index < payload + standalone.length() {
    output.push(b'\x00')
    index = index + 1
  }
  font_collection_wb_put_u32(output, 0, 0x74746366UL)
  font_collection_wb_put_u32(output, 4, 0x00010000UL)
  font_collection_wb_put_u32(output, 8, 2UL)
  font_collection_wb_put_u32(output, 12, first_directory.to_uint64())
  font_collection_wb_put_u32(output, 16, second_directory.to_uint64())
  let standalone_bytes = font_wb_bytes_array(standalone)
  index = 0
  while index < standalone.length() {
    output[payload + index] = standalone_bytes[index]
    index = index + 1
  }
  for directory in [first_directory, second_directory] {
    index = 0
    while index < directory_bytes {
      output[directory + index] = standalone_bytes[index]
      index = index + 1
    }
    index = 0
    while index < table_count {
      let record = 12 + index * 16
      let old_offset = font_collection_wb_read_u32(standalone, record + 8)
      font_collection_wb_put_u32(
        output,
        directory + record + 8,
        payload.to_uint64() + old_offset,
      )
      index = index + 1
    }
  }
  Bytes::from_array(output)
}

///|
fn font_collection_wb_shared_cff_ttc() -> Bytes {
  font_collection_wb_shared_cff_ttc_from_standalone(
    cff_wb_otf(cff_name_wb_table(), num_glyphs=3UL),
  )
}

///|
fn font_collection_wb_shared_cff_path_ttc() -> Bytes {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  font_collection_wb_shared_cff_ttc_from_standalone(
    cff_wb_otf(
      cff_wb_name_table_with_programs([b"\x0e", cubic, b"\x0e"]),
      num_glyphs=3UL,
    ),
  )
}

///|
fn font_collection_wb_cff_budget(
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
test "selected collection CFF1 facts use one bounded atomic shared-table transaction" {
  let source = font_collection_wb_shared_cff_ttc()
  let owner = font_collection_wb_owner(source)
  let admitted = admit_cff1_collection_structure(
    owner.view(),
    188UL,
    9UL,
    font_wb_limits(),
    cff_wb_budget(),
    2UL,
  ).unwrap()
  inspect(admitted.directory_start, content="188")
  inspect(admitted.cff_table_offset > admitted.directory_start, content="true")
  inspect(admitted.glyphs.length(), content="3")
  inspect(admitted.glyphs[2].gid, content="2")
  inspect(admitted.charge.work, content="526")
  inspect(admitted.charge.retained_bytes > 0UL, content="true")
  inspect(admitted.combined_charge.bytes, content="615")
  inspect(admitted.combined_charge.allocations, content="25")
  inspect(admitted.combined_charge.allocation_size, content="8192")
  inspect(admitted.combined_charge.work, content="529")

  let exact_budget = font_collection_wb_cff_budget(
    615UL,
    25UL,
    8192UL,
    529UL,
  )
  admit_cff1_collection_structure(
    owner.view(),
    188UL,
    9UL,
    font_wb_limits(),
    exact_budget,
    2UL,
  ) |> ignore
  let exact_after = exact_budget.remaining()
  inspect(exact_after.bytes(), content="0")
  inspect(exact_after.allocations(), content="0")
  inspect(exact_after.work(), content="0")

  for short_dimension in [0, 1, 2, 3] {
    let short_budget = font_collection_wb_cff_budget(
      if short_dimension == 0 {
        614UL
      } else {
        615UL
      },
      if short_dimension == 1 {
        24UL
      } else {
        25UL
      },
      if short_dimension == 2 {
        8191UL
      } else {
        8192UL
      },
      if short_dimension == 3 {
        528UL
      } else {
        529UL
      },
    )
    let before = short_budget.remaining()
    let error = admit_cff1_collection_structure(
      owner.view(),
      188UL,
      9UL,
      font_wb_limits(),
      short_budget,
      2UL,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    font_collection_wb_assert_budget_unchanged(before, short_budget)
  }

  let mutation_budget = font_collection_wb_cff_budget(
    615UL,
    25UL,
    8192UL,
    529UL,
  )
  let mutation_before = mutation_budget.remaining()
  let mutation_error = admit_cff1_collection_structure_after_preflight(
    owner.view(),
    188UL,
    9UL,
    font_wb_limits(),
    mutation_budget,
    2UL,
    fn() { font_collection_wb_mutate_restore(owner, admitted.cff_table_offset) },
  ).unwrap_err()
  inspect(
    mutation_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  inspect(
    mutation_error.context() == Some("font-cff-source-revision-drift"),
    content="true",
  )
  font_collection_wb_assert_budget_unchanged(
    mutation_before,
    mutation_budget,
  )
}

///|
test "Phase 106 selected CFF1 retains collection root and opening revision authority" {
  let source = font_collection_wb_shared_cff_ttc()
  let owner = font_collection_wb_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    FontCollectionLimits::new(
      max_source_bytes=source.length().to_uint64(),
      max_faces=2UL,
      max_tables_per_face=9UL,
      max_table_records=18UL,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=16384UL,
      max_work=262144UL,
    ).unwrap(),
    font_collection_wb_selected_budget(),
  ).unwrap()
  let selected = collection
    .open_face(1UL, font_wb_limits(), cff_wb_budget())
    .unwrap()
  inspect(selected.source.length() == collection.source.length(), content="true")
  inspect(selected.opening_revision == collection.opening_revision, content="true")
  inspect(
    selected.source.mutation_revision() ==
    collection.source.mutation_revision(),
    content="true",
  )
  match selected.outline_source {
    FontOutlineSource::Cff1(admitted) => {
      inspect(admitted.directory_start, content="188")
      inspect(admitted.cff_table_offset > admitted.directory_start, content="true")
      inspect(
        admitted.opening_revision == collection.opening_revision,
        content="true",
      )
    }
    FontOutlineSource::Glyf(_) => fail("selected OTTO face must retain CFF facts")
  }

  font_collection_wb_mutate_restore(owner, 0UL)
  let stale_budget = cff_wb_budget()
  let stale_before = stale_budget.remaining()
  let stale_error = font_open_cff_collection_face(
    owner.view(),
    collection.opening_revision,
    collection.faces[1],
    font_wb_limits(),
    stale_budget,
    fn(_stage) { () },
    fn() { () },
  ).unwrap_err()
  inspect(stale_error.category() == @error.ErrorCategory::State, content="true")
  inspect(
    stale_error.context() == Some("font-cff-source-revision-drift"),
    content="true",
  )
  font_collection_wb_assert_budget_unchanged(stale_before, stale_budget)
}

///|
fn font_collection_wb_cff_collection_limits(
  source_length : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=source_length,
    max_faces=2UL,
    max_tables_per_face=9UL,
    max_table_records=18UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=16384UL,
    max_work=262144UL,
  ).unwrap()
}

///|
fn font_collection_wb_cff_path_limits(
  charge : CffPathCharge,
) -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes=charge.bytes,
    allocations=charge.allocations,
    allocation_size=charge.allocation_size,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=charge.work,
  )
}

///|
test "Phase 106 preserves selected CFF admission outline and mutation authority" {
  let source = font_collection_wb_shared_cff_path_ttc()
  let owner = font_collection_wb_owner(source)
  let direct = match
    admit_cff1_collection_structure(
      owner.view(),
      188UL,
      9UL,
      font_wb_limits(),
      cff_wb_budget(),
      2UL,
    ) {
    Ok(value) => value
    Err(_) => fail("direct selected CFF admission must succeed")
  }
  let collection = match
    FontCollection::open(
      owner.view(),
      font_collection_wb_cff_collection_limits(source.length().to_uint64()),
      font_collection_wb_selected_budget(),
    ) {
    Ok(value) => value
    Err(_) => fail("shared CFF collection admission must succeed")
  }
  inspect(direct.combined_charge.bytes, content="626")
  inspect(direct.combined_charge.allocations, content="26")
  inspect(direct.combined_charge.allocation_size, content="8192")
  inspect(direct.combined_charge.work, content="569")
  let exact_limits = @budget.ResourceLimits::new(
    bytes=626UL,
    allocations=26UL,
    allocation_size=8192UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=569UL,
  )
  let exact = @budget.Budget::new(exact_limits)
  let selected = match collection.open_face(1UL, font_wb_limits(), exact) {
    Ok(value) => value
    Err(_) => fail("selected CFF exact admission must succeed")
  }
  inspect(exact.remaining().bytes(), content="0")
  inspect(exact.remaining().allocations(), content="0")
  inspect(exact.remaining().work(), content="0")

  let admission_short = [
    @budget.ResourceLimits::new(
      bytes=625UL,
      allocations=26UL,
      allocation_size=8192UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=569UL,
    ),
    @budget.ResourceLimits::new(
      bytes=626UL,
      allocations=25UL,
      allocation_size=8192UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=569UL,
    ),
    @budget.ResourceLimits::new(
      bytes=626UL,
      allocations=26UL,
      allocation_size=8191UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=569UL,
    ),
    @budget.ResourceLimits::new(
      bytes=626UL,
      allocations=26UL,
      allocation_size=8192UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=568UL,
    ),
  ]
  for limits in admission_short {
    let caller = @budget.Budget::new(limits)
    let caller_before = caller.remaining()
    let caller_error = collection
      .open_face(1UL, font_wb_limits(), caller)
      .unwrap_err()
    inspect(
      caller_error.category() == @error.ErrorCategory::Resource,
      content="true",
    )
    font_collection_wb_assert_budget_unchanged(caller_before, caller)

    let ancestor = @budget.Budget::new(limits)
    let child = ancestor.child(limits).unwrap()
    let ancestor_before = ancestor.remaining()
    let child_before = child.remaining()
    let ancestor_error = collection
      .open_face(1UL, font_wb_limits(), child)
      .unwrap_err()
    inspect(
      ancestor_error.category() == @error.ErrorCategory::Resource,
      content="true",
    )
    font_collection_wb_assert_budget_unchanged(ancestor_before, ancestor)
    font_collection_wb_assert_budget_unchanged(child_before, child)
  }
  let glyph = selected.glyph_id(1UL).unwrap()
  let path_charge = font_wb_cff_cubic_path_charge()
  let path_limits = font_collection_wb_cff_path_limits(path_charge)
  let path_exact = @budget.Budget::new(path_limits)
  match selected.outline(glyph, path_exact) {
    Ok(_) => ()
    Err(_) => fail("exact selected CFF outline must succeed")
  }
  inspect(path_exact.remaining().bytes(), content="0")
  inspect(path_exact.remaining().allocations(), content="0")
  inspect(path_exact.remaining().work(), content="0")
  let path_short = [
    (
      "selected CFF bytes one-short must fail",
      @budget.ResourceLimits::new(
        bytes=path_charge.bytes - 1UL,
        allocations=path_charge.allocations,
        allocation_size=path_charge.allocation_size,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=path_charge.work,
      ),
    ),
    (
      "selected CFF allocations one-short must fail",
      @budget.ResourceLimits::new(
        bytes=path_charge.bytes,
        allocations=path_charge.allocations - 1UL,
        allocation_size=path_charge.allocation_size,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=path_charge.work,
      ),
    ),
    (
      "selected CFF allocation size one-short must fail",
      @budget.ResourceLimits::new(
        bytes=path_charge.bytes,
        allocations=path_charge.allocations,
        allocation_size=path_charge.allocation_size - 1UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=path_charge.work,
      ),
    ),
    (
      "selected CFF work one-short must fail",
      @budget.ResourceLimits::new(
        bytes=path_charge.bytes,
        allocations=path_charge.allocations,
        allocation_size=path_charge.allocation_size,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=path_charge.work - 1UL,
      ),
    ),
  ]
  for item in path_short {
    let limits = item.1
    let caller = @budget.Budget::new(limits)
    let caller_before = caller.remaining()
    let caller_error = match selected.outline(glyph, caller) {
      Err(error) => error
      Ok(_) => fail(item.0)
    }
    inspect(
      caller_error.category() == @error.ErrorCategory::Resource,
      content="true",
    )
    font_collection_wb_assert_budget_unchanged(caller_before, caller)

    let ancestor = @budget.Budget::new(limits)
    let child = ancestor.child(limits).unwrap()
    let ancestor_before = ancestor.remaining()
    let child_before = child.remaining()
    let ancestor_error = match selected.outline(glyph, child) {
      Err(error) => error
      Ok(_) => fail(item.0)
    }
    inspect(
      ancestor_error.category() == @error.ErrorCategory::Resource,
      content="true",
    )
    font_collection_wb_assert_budget_unchanged(ancestor_before, ancestor)
    font_collection_wb_assert_budget_unchanged(child_before, child)
  }
  let execution_source = font_collection_wb_shared_cff_path_ttc()
  let execution_owner = font_collection_wb_owner(execution_source)
  let execution_revision = execution_owner.view().mutation_revision()
  let execution_budget = @budget.Budget::new(exact_limits)
  let execution_before = execution_budget.remaining()
  let execution_error = admit_cff1_structure_at_after_preflight_with_glyph_probe(
    execution_owner.view(),
    188UL,
    Some(9UL),
    FontChecksumMode::Collection,
    true,
    font_wb_limits(),
    execution_budget,
    2UL,
    fn() { () },
    fn() { () },
    fn() { () },
    fn(gid) {
      if gid == 1UL {
        font_collection_wb_mutate_restore(execution_owner, 0UL)
      }
    },
    authoritative_opening_revision=execution_revision,
  ).unwrap_err()
  inspect(
    execution_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  font_collection_wb_assert_budget_unchanged(
    execution_before,
    execution_budget,
  )

  let commit_source = font_collection_wb_shared_cff_path_ttc()
  let commit_owner = font_collection_wb_owner(commit_source)
  let commit_revision = commit_owner.view().mutation_revision()
  let commit_budget = @budget.Budget::new(exact_limits)
  let commit_before = commit_budget.remaining()
  let mut guards = 0
  let commit_error = admit_cff1_structure_at_after_preflight(
    commit_owner.view(),
    188UL,
    Some(9UL),
    FontChecksumMode::Collection,
    true,
    font_wb_limits(),
    commit_budget,
    2UL,
    fn() {
      guards = guards + 1
      if guards == 2 {
        font_collection_wb_mutate_restore(commit_owner, 0UL)
      }
    },
    fn() { () },
    fn() { () },
    authoritative_opening_revision=commit_revision,
  ).unwrap_err()
  inspect(guards, content="2")
  inspect(
    commit_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  font_collection_wb_assert_budget_unchanged(commit_before, commit_budget)

  let outline_budget = @budget.Budget::new(path_limits)
  let outline_before = outline_budget.remaining()
  let outline_error = selected
    .outline_after_decode(
      glyph,
      outline_budget,
      fn() { font_collection_wb_mutate_restore(owner, 0UL) },
    )
    .unwrap_err()
  inspect(
    outline_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  font_collection_wb_assert_budget_unchanged(outline_before, outline_budget)
}
