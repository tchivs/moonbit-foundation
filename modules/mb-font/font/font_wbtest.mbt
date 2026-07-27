///|
fn font_wb_view(source : Bytes) -> @bytes.ByteView {
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
fn font_wb_owner(source : Bytes) -> @bytes.OwnedBytes {
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
fn font_wb_open_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=3UL,
      allocation_size=4096UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
fn font_wb_mutate_one_byte(owner : @bytes.OwnedBytes, offset : UInt64) -> Unit {
  let original = owner.view().get(offset).unwrap()
  owner
  .with_mut(offset, 1UL, fn(lease) {
    lease.set(0UL, (original.to_uint64() ^ 1UL).to_byte())
  })
  .unwrap()
}

///|
fn font_wb_assert_revision_drift(error : @error.CoreError) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-query"), content="true")
  inspect(
    error.context() == Some("font-source-revision-drift"),
    content="true",
  )
}

///|
test "checked big endian reads accept exact fit and reject one short" {
  inspect(read_u8(font_wb_view(b"\x12"), 0UL).unwrap(), content="b'\\x12'")
  inspect(read_u8(font_wb_view(b""), 0UL) is Err(_), content="true")
  inspect(read_u16(font_wb_view(b"\x12\x34"), 0UL).unwrap(), content="4660")
  inspect(read_u16(font_wb_view(b"\x12"), 0UL) is Err(_), content="true")
  inspect(read_i16(font_wb_view(b"\xff\xfe"), 0UL).unwrap(), content="-2")
  inspect(read_i16(font_wb_view(b"\xff"), 0UL) is Err(_), content="true")
  inspect(
    read_u32(font_wb_view(b"\x12\x34\x56\x78"), 0UL).unwrap(),
    content="305419896",
  )
  inspect(
    read_u32(font_wb_view(b"\x12\x34\x56"), 0UL) is Err(_),
    content="true",
  )
}

///|
test "outline Q15 midpoint and checked overflow stay private data facts" {
  let left : OutlinePoint = {
    x_q15: -32768L,
    y_q15: 0L,
    on_curve: false,
  }
  let right : OutlinePoint = {
    x_q15: 0L,
    y_q15: 32768L,
    on_curve: false,
  }
  let midpoint = midpoint_q15(left, right).unwrap()
  inspect(midpoint.x_q15, content="-16384")
  inspect(midpoint.y_q15, content="16384")
  inspect(midpoint.on_curve, content="true")
  let overflow = outline_checked_add(9223372036854775807L, 1L).unwrap_err()
  inspect(overflow.category() == @error.ErrorCategory::Data, content="true")
  inspect(overflow.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(overflow.operation() == Some("font-outline"), content="true")
}

///|
test "directory size and table windows preserve checked boundaries" {
  inspect(font_directory_end(10UL).unwrap(), content="172")
  let overflow = font_directory_end(18446744073709551615UL).unwrap_err()
  inspect(
    overflow.code() == @error.ErrorCode::ArithmeticOverflow,
    content="true",
  )
  let source = font_wb_view(b"\x00\x01\x02\x03\x04\x05\x06\x07")
  let exact = checked_font_table_view(source, 4UL, 4UL).unwrap()
  inspect(exact.length(), content="4")
  inspect(exact.get(0UL).unwrap(), content="b'\\x04'")
  inspect(checked_font_table_view(source, 4UL, 5UL) is Err(_), content="true")
}

///|
test "directory search selector work is exact at power-of-two boundaries" {
  for
    case in [
      (1UL, 0UL),
      (2UL, 1UL),
      (3UL, 1UL),
      (4UL, 2UL),
      (7UL, 2UL),
      (8UL, 3UL),
      (9UL, 3UL),
    ] {
    let (table_count, expected_selector) = case
    let (_, selector, _) = font_directory_search_facts(table_count).unwrap()
    inspect(selector == expected_selector, content="true")
    let overlap_work = table_count * (table_count - 1UL) / 2UL
    let expected_work = overlap_work +
      table_count +
      table_count +
      expected_selector
    inspect(
      font_directory_work(0UL, table_count).unwrap() == expected_work,
      content="true",
    )
  }
}

///|
fn font_wb_cmap_format12_groups(
  groups : Array[(UInt64, UInt64, UInt64)],
) -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u16(output, 12UL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u32(output, 16UL + groups.length().to_uint64() * 12UL)
  font_wb_put_u32(output, 0UL)
  font_wb_put_u32(output, groups.length().to_uint64())
  for group in groups {
    let (start_code, end_code, start_glyph) = group
    font_wb_put_u32(output, start_code)
    font_wb_put_u32(output, end_code)
    font_wb_put_u32(output, start_glyph)
  }
  Bytes::from_array(output)
}

///|
fn font_wb_cmap_format4_range(indexed : Bool) -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, if indexed { 38UL } else { 32UL })
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 0x0043UL)
  font_wb_put_u16(output, 0xFFFFUL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 0x0041UL)
  font_wb_put_u16(output, 0xFFFFUL)
  font_wb_put_u16(output, if indexed { 1UL } else { 0xFFC0UL })
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, if indexed { 4UL } else { 0UL })
  font_wb_put_u16(output, 0UL)
  if indexed {
    font_wb_put_u16(output, 1UL)
    font_wb_put_u16(output, 0UL)
    font_wb_put_u16(output, 3UL)
  }
  Bytes::from_array(output)
}

///|
test "cmap rank and format-12 lower bound preserve canonical boundaries" {
  inspect(font_cmap_rank(0UL, 4UL, 12UL) == Some(0), content="true")
  inspect(font_cmap_rank(3UL, 10UL, 12UL) == Some(1), content="true")
  inspect(font_cmap_rank(0UL, 3UL, 4UL) == Some(2), content="true")
  inspect(font_cmap_rank(3UL, 1UL, 4UL) == Some(3), content="true")
  for
    tuple in [
      (0UL, 2UL, 4UL),
      (1UL, 0UL, 4UL),
      (3UL, 0UL, 4UL),
      (3UL, 1UL, 12UL),
    ] {
    let (platform, encoding, format) = tuple
    inspect(font_cmap_rank(platform, encoding, format) is None, content="true")
  }

  let source = font_wb_cmap_format12_groups([
    (0x0041UL, 0x0042UL, 1UL),
    (0x0100UL, 0x0100UL, 3UL),
    (0x1F600UL, 0x1F601UL, 4UL),
  ])
  let facts : CmapFormat12Facts = {
    view: font_wb_view(source),
    offset: 0UL,
    group_count: 3UL,
  }
  for
    case in [
      (0x0041UL, 1UL),
      (0x0042UL, 2UL),
      (0x0043UL, 0UL),
      (0x0100UL, 3UL),
      (0x0101UL, 0UL),
      (0x1F600UL, 4UL),
      (0x1F601UL, 5UL),
      (0x1F602UL, 0UL),
    ] {
    let (scalar, expected) = case
    inspect(
      font_lookup_cmap_format12(facts, scalar).unwrap() == expected,
      content="true",
    )
  }
}

///|
test "format-4 admitted bases and binary search cover direct and indexed edges" {
  for
    case in [
      (font_wb_cmap_format4_range(false), [1UL, 2UL, 3UL]),
      (font_wb_cmap_format4_range(true), [2UL, 0UL, 4UL]),
    ] {
    let (source, expected) = case
    let view = font_wb_view(source)
    let table : TableWindow = {
      tag: 0x636D6170UL,
      checksum: 0UL,
      offset: 0UL,
      length_value: source.length().to_uint64(),
      view,
    }
    let facts = font_cmap_format4_facts(table, 0UL, 2UL).unwrap()
    inspect(facts.end_codes, content="14")
    inspect(facts.start_codes, content="20")
    inspect(facts.id_deltas, content="24")
    inspect(facts.id_range_offsets, content="28")
    inspect(font_lookup_cmap_format4(facts, 0x0040UL).unwrap(), content="0")
    inspect(
      font_lookup_cmap_format4(facts, 0x0041UL).unwrap() == expected[0],
      content="true",
    )
    inspect(
      font_lookup_cmap_format4(facts, 0x0042UL).unwrap() == expected[1],
      content="true",
    )
    inspect(
      font_lookup_cmap_format4(facts, 0x0043UL).unwrap() == expected[2],
      content="true",
    )
    inspect(font_lookup_cmap_format4(facts, 0x0044UL).unwrap(), content="0")
    inspect(font_lookup_cmap_format4(facts, 0x1F600UL).unwrap(), content="0")
  }
}

///|
fn font_wb_kern_table(source : Bytes) -> TableWindow {
  {
    tag: 0x6B65726EUL,
    checksum: 0UL,
    offset: 0UL,
    length_value: source.length().to_uint64(),
    view: font_wb_view(source),
  }
}

///|
fn font_wb_kern_format0(pairs : Array[(UInt64, UInt64, Int)]) -> Bytes {
  let output : Array[Byte] = []
  let pair_count = pairs.length().to_uint64()
  let (search_range, selector, range_shift) = font_kern_search_facts(pair_count)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 14UL + pair_count * 6UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, pair_count)
  font_wb_put_u16(output, search_range)
  font_wb_put_u16(output, selector)
  font_wb_put_u16(output, range_shift)
  for pair in pairs {
    let (left, right, value) = pair
    font_wb_put_u16(output, left)
    font_wb_put_u16(output, right)
    font_wb_put_u16(
      output,
      if value < 0 {
        (value + 0x10000).to_uint64()
      } else {
        value.to_uint64()
      },
    )
  }
  Bytes::from_array(output)
}

///|
test "glyph_for_scalar rejects post-read revision drift" {
  let owner = font_wb_owner(generated_minimal_truetype())
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let mut callback_count = 0
  let result = font.glyph_for_scalar_after_lookup(0x0041, fn() {
    callback_count = callback_count + 1
    font_wb_mutate_one_byte(owner, 0UL)
  })
  match result {
    Ok(_) => fail("post-read revision drift must not publish a GlyphId")
    Err(error) => font_wb_assert_revision_drift(error)
  }
  inspect(callback_count, content="1")
}

///|
test "kerning rejects post-read revision drift" {
  let required = font_wb_required_tables()
  let tables : Array[GeneratedFontTable] = []
  for index, table in required {
    if index == 6 {
      tables.push(
        font_wb_table(b"kern", font_wb_kern_format0([(0UL, 0UL, -7)])),
      )
    }
    tables.push(table)
  }
  let owner = font_wb_owner(font_wb_build_sfnt(tables))
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let glyph = font.glyph_id(0UL).unwrap()
  let mut callback_count = 0
  let result = font.kerning_after_lookup(glyph, glyph, fn() {
    callback_count = callback_count + 1
    font_wb_mutate_one_byte(owner, 0UL)
  })
  match result {
    Ok(_) => fail("post-read revision drift must not publish an adjustment")
    Err(error) => font_wb_assert_revision_drift(error)
  }
  inspect(callback_count, content="1")
}

///|
test "kern helper fields keys signed values and binary search are canonical" {
  for
    case in [
      (0UL, (0UL, 0UL, 0UL)),
      (1UL, (6UL, 0UL, 0UL)),
      (3UL, (12UL, 1UL, 6UL)),
      (4UL, (24UL, 2UL, 0UL)),
    ] {
    let (count, expected) = case
    inspect(font_kern_search_facts(count) == expected, content="true")
  }
  inspect(font_kern_pair_key(1UL, 2UL), content="65538")
  inspect(read_i16(font_wb_view(b"\xff\xec"), 0UL).unwrap(), content="-20")

  let empty = font_admit_kern(
    Some(font_wb_kern_table(font_wb_kern_format0([]))),
    1UL,
  ).unwrap()
  inspect(font_lookup_kern(empty, 0UL, 0UL).unwrap(), content="0")

  let singleton = font_admit_kern(
    Some(font_wb_kern_table(font_wb_kern_format0([(0UL, 1UL, -7)]))),
    2UL,
  ).unwrap()
  inspect(font_lookup_kern(singleton, 0UL, 1UL).unwrap(), content="-7")
  inspect(font_lookup_kern(singleton, 1UL, 0UL).unwrap(), content="0")

  let three = font_admit_kern(
    Some(
      font_wb_kern_table(
        font_wb_kern_format0([(0UL, 1UL, 10), (1UL, 2UL, -20), (2UL, 3UL, 30)]),
      ),
    ),
    4UL,
  ).unwrap()
  inspect(font_lookup_kern(three, 0UL, 1UL).unwrap(), content="10")
  inspect(font_lookup_kern(three, 1UL, 2UL).unwrap(), content="-20")
  inspect(font_lookup_kern(three, 2UL, 3UL).unwrap(), content="30")
  inspect(font_lookup_kern(three, 3UL, 3UL).unwrap(), content="0")

  let source = font_wb_kern_format0([
    (0UL, 1UL, 10),
    (1UL, 2UL, -20),
    (2UL, 3UL, 30),
    (3UL, 4UL, -40),
  ])
  let state = font_admit_kern(Some(font_wb_kern_table(source)), 5UL).unwrap()
  inspect(font_lookup_kern(state, 0UL, 1UL).unwrap(), content="10")
  inspect(font_lookup_kern(state, 1UL, 2UL).unwrap(), content="-20")
  inspect(font_lookup_kern(state, 2UL, 3UL).unwrap(), content="30")
  inspect(font_lookup_kern(state, 3UL, 4UL).unwrap(), content="-40")
  inspect(font_lookup_kern(state, 1UL, 1UL).unwrap(), content="0")
  inspect(font_lookup_kern(state, 4UL, 4UL).unwrap(), content="0")
}

///|
test "kern admission rejects exact-length search order duplicate and range errors" {
  let valid = font_wb_kern_format0([(0UL, 1UL, 10), (1UL, 2UL, -20)])
  for
    malformed in [
      font_wb_put_u16_at_copy(valid, 6, 25UL),
      font_wb_put_u16_at_copy(valid, 12, 6UL),
      font_wb_put_u16_at_copy(valid, 18, 2UL),
      font_wb_put_u16_at_copy(font_wb_put_u16_at_copy(valid, 24, 0UL), 26, 1UL),
      font_wb_put_u16_at_copy(font_wb_put_u16_at_copy(valid, 24, 0UL), 26, 0UL),
      font_wb_put_u16_at_copy(valid, 20, 3UL),
    ] {
    inspect(
      font_admit_kern(Some(font_wb_kern_table(malformed)), 3UL) is Err(_),
      content="true",
    )
  }
  let apple_short = font_wb_kern_table(b"\x00\x01\x00\x00\x00\x00\x00\x01")
  inspect(font_admit_kern(Some(apple_short), 3UL) is Err(_), content="true")
}

///|
test "font error taxonomy keeps input data capability state and resource distinct" {
  let invalid_input = font_unicode_scalar_error()
  inspect(
    invalid_input.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(
    invalid_input.code() == @error.ErrorCode::InvalidRange,
    content="true",
  )
  inspect(
    invalid_input.operation() == Some("font-glyph-for-scalar"),
    content="true",
  )
  inspect(
    invalid_input.context() == Some("font-unicode-scalar-range"),
    content="true",
  )

  let data = font_data_error("font-kern-format0")
  inspect(data.category() == @error.ErrorCategory::Data, content="true")
  inspect(data.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(data.operation() == Some("font-open"), content="true")
  inspect(data.context() == Some("font-kern-format0"), content="true")

  let capability = font_kern_profile_error()
  inspect(
    capability.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    capability.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(capability.operation() == Some("font-kerning"), content="true")
  inspect(capability.context() == Some("font-kern-profile"), content="true")

  let state = font_revision_error("font-query")
  inspect(state.category() == @error.ErrorCategory::State, content="true")
  inspect(state.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(state.operation() == Some("font-query"), content="true")
  inspect(state.context() == Some("font-source-revision-drift"), content="true")

  let resource = font_limit_error("max-kern-pairs", 2UL, 1UL)
  inspect(resource.category() == @error.ErrorCategory::Resource, content="true")
  inspect(resource.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(resource.operation() == Some("font-open"), content="true")
  inspect(resource.requested() == Some(2UL), content="true")
  inspect(resource.limit() == Some(1UL), content="true")
  inspect(resource.context() == Some("max-kern-pairs"), content="true")
}

///|
fn font_wb_limits() -> FontLimits {
  FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
}

///|
test "font directory matrix enforces canonical windows and checksums" {
  let valid = generated_minimal_truetype()
  let facts = font_parse_directory(font_wb_view(valid), font_wb_limits()).unwrap()
  font_validate_profile(facts).unwrap()
  font_validate_checksums(facts).unwrap()
  let head = font_table_window(facts, 0x68656164UL).unwrap()
  inspect(head.length_value, content="54")
  inspect(
    font_sfnt_checksum(font_wb_view(b"\x01\x02\x03"), false).unwrap(),
    content="16909056",
  )

  for offset in [6, 8, 10] {
    let malformed = font_wb_put_u16_at_copy(valid, offset, 0UL)
    inspect(
      font_parse_directory(font_wb_view(malformed), font_wb_limits()) is Err(_),
      content="true",
    )
  }

  let unknown = font_wb_build_sfnt(
    font_wb_required_tables() + [font_wb_table(b"zzzz", b"\x01\x02\x03")],
  )
  let unknown_facts = font_parse_directory(
    font_wb_view(unknown),
    font_wb_limits(),
  ).unwrap()
  font_validate_checksums(unknown_facts).unwrap()
  inspect(
    font_table_window(unknown_facts, 0x7A7A7A7AUL).unwrap().length_value,
    content="3",
  )

  let unsorted = font_wb_swap_directory_records(valid, 0, 1)
  inspect(
    font_parse_directory(font_wb_view(unsorted), font_wb_limits()) is Err(_),
    content="true",
  )
  let duplicate = font_wb_copy_directory_tag(valid, 0, 1)
  inspect(
    font_parse_directory(font_wb_view(duplicate), font_wb_limits()) is Err(_),
    content="true",
  )
  let inside_directory = font_wb_set_table_record_u32(valid, b"head", 8, 12UL)
  inspect(
    font_parse_directory(font_wb_view(inside_directory), font_wb_limits())
    is Err(_),
    content="true",
  )
  let misaligned = font_wb_set_table_record_u32(valid, b"head", 8, 173UL)
  inspect(
    font_parse_directory(font_wb_view(misaligned), font_wb_limits()) is Err(_),
    content="true",
  )
  let one_past_end = font_wb_set_table_record_u32(
    valid,
    b"head",
    12,
    valid.length().to_uint64(),
  )
  inspect(
    font_parse_directory(font_wb_view(one_past_end), font_wb_limits()) is Err(_),
    content="true",
  )
  let overlap = font_wb_overlap_table_with_previous(valid, b"head")
  inspect(
    font_parse_directory(font_wb_view(overlap), font_wb_limits()) is Err(_),
    content="true",
  )

  let bad_table = font_wb_mutate_table_field(valid, b"cmap", 0, b"\x01")
  let bad_table_facts = font_parse_directory(
    font_wb_view(bad_table),
    font_wb_limits(),
  ).unwrap()
  inspect(font_validate_checksums(bad_table_facts) is Err(_), content="true")
  let repaired_table = font_wb_repair_table_checksum(bad_table, b"cmap")
  let repaired_font = font_wb_repair_checksum_adjustment(repaired_table)
  let repaired_facts = font_parse_directory(
    font_wb_view(repaired_font),
    font_wb_limits(),
  ).unwrap()
  font_validate_checksums(repaired_facts).unwrap()

  let bad_adjustment = font_wb_put_u32_at_copy(
    valid,
    font_wb_table_offset(valid, b"head") + 8,
    0UL,
  )
  let bad_adjustment_facts = font_parse_directory(
    font_wb_view(bad_adjustment),
    font_wb_limits(),
  ).unwrap()
  inspect(
    font_validate_checksums(bad_adjustment_facts) is Err(_),
    content="true",
  )
}

///|
test "font directory rejects excluded container signatures distinctly" {
  for
    signature in [
      0x4F54544FUL, 0x74746366UL, 0x774F4646UL, 0x774F4632UL, 0x74727565UL, 0x74797031UL,
    ] {
    let source = font_wb_put_u32_at_copy(
      generated_minimal_truetype(),
      0,
      signature,
    )
    let error = font_parse_directory(font_wb_view(source), font_wb_limits()).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
  }
  let unknown = font_wb_put_u32_at_copy(
    generated_minimal_truetype(),
    0,
    0xDEADBEEFUL,
  )
  let error = font_parse_directory(font_wb_view(unknown), font_wb_limits()).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Data, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
}

///|
test "font required table matrix enforces structural cardinalities" {
  let source = generated_minimal_truetype()
  let directory = font_parse_directory(font_wb_view(source), font_wb_limits()).unwrap()
  font_validate_checksums(directory).unwrap()
  let tables = font_admit_required_tables(directory, font_wb_limits()).unwrap()
  inspect(tables.head.units_per_em, content="1000")
  inspect(tables.head.x_min, content="-10")
  inspect(tables.head.y_min, content="-20")
  inspect(tables.head.x_max, content="100")
  inspect(tables.head.y_max, content="200")
  inspect(tables.maxp.num_glyphs, content="1")
  inspect(tables.hhea.ascent, content="800")
  inspect(tables.hhea.descent, content="-200")
  inspect(tables.hhea.line_gap, content="50")
  inspect(tables.hhea.number_of_h_metrics, content="1")
  inspect(tables.os2.typo_ascent, content="750")
  inspect(tables.os2.typo_descent, content="-250")
  inspect(tables.os2.typo_line_gap, content="25")
  inspect(tables.cmap.record_count, content="1")
  let index = font_admit_metric_index(
    directory,
    tables.head,
    tables.maxp,
    tables.hhea,
  ).unwrap()
  inspect(index.loca_offsets.length(), content="2")
  inspect(index.loca_offsets[0], content="0")
  inspect(index.loca_offsets[1], content="0")

  inspect(font_hmtx_required_length(1UL, 1UL).unwrap(), content="4")
  inspect(font_hmtx_required_length(3UL, 1UL).unwrap(), content="8")
  inspect(font_hmtx_required_length(3UL, 3UL).unwrap(), content="12")
  inspect(font_hmtx_required_length(1UL, 0UL) is Err(_), content="true")
  inspect(font_hmtx_required_length(1UL, 2UL) is Err(_), content="true")
  inspect(font_loca_required_length(1UL, 0).unwrap(), content="4")
  inspect(font_loca_required_length(1UL, 1).unwrap(), content="8")
  inspect(font_loca_required_length(1UL, 2) is Err(_), content="true")
  inspect(font_right_side_bearing(500UL, -20, 110UL).unwrap(), content="410")
  inspect(font_right_side_bearing(600UL, 30, 0UL).unwrap(), content="570")
  inspect(
    font_right_side_bearing(18446744073709551615UL, -1, 0UL).unwrap_err().code() ==
    @error.ErrorCode::ArithmeticOverflow,
    content="true",
  )
  inspect(
    font_right_side_bearing(18446744073709551615UL, 0, 0UL).unwrap_err().code() ==
    @error.ErrorCode::NarrowingFailed,
    content="true",
  )

  for
    tag in [
      b"OS/2", b"cmap", b"glyf", b"head", b"hhea", b"hmtx", b"loca", b"maxp", b"name",
      b"post",
    ] {
    let missing = font_wb_build_sfnt(font_wb_without_table(tag))
    let missing_directory = font_parse_directory(
      font_wb_view(missing),
      font_wb_limits(),
    ).unwrap()
    inspect(
      font_admit_required_tables(missing_directory, font_wb_limits()) is Err(_),
      content="true",
    )
  }
}

///|
test "metric admission validates short long and common glyph header ranges" {
  for
    source in [
      generated_horizontal_metric_truetype(),
      generated_long_loca_metric_truetype(),
    ] {
    let directory = font_parse_directory(font_wb_view(source), font_wb_limits()).unwrap()
    font_validate_checksums(directory).unwrap()
    let tables = font_admit_required_tables(directory, font_wb_limits()).unwrap()
    let index = font_admit_metric_index(
      directory,
      tables.head,
      tables.maxp,
      tables.hhea,
    ).unwrap()
    font_validate_glyph_headers(index).unwrap()
  }
  let short = generated_short_glyph_header_truetype()
  let directory = font_parse_directory(font_wb_view(short), font_wb_limits()).unwrap()
  font_validate_checksums(directory).unwrap()
  let tables = font_admit_required_tables(directory, font_wb_limits()).unwrap()
  inspect(
    font_admit_metric_index(directory, tables.head, tables.maxp, tables.hhea)
    is Err(_),
    content="true",
  )
}

///|
test "generated font admission cases preserve named outcomes" {
  for item in font_wb_admission_cases() {
    let directory = font_parse_directory(
      font_wb_view(item.source),
      font_wb_limits(),
    ).unwrap()
    let valid = font_validate_checksums(directory) is Ok(_)
    if valid != item.accepted {
      fail(item.id)
    }
  }
}
