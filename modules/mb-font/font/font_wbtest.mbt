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
  for case in [
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
fn font_wb_limits() -> FontLimits {
  FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
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
