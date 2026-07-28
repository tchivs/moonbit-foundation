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
fn font_wb_outline_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=32UL,
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
test "outline accepts only zero padding within four-byte glyph alignment" {
  for padding in [b"", b"\x00", b"\x00\x00", b"\x00\x00\x00"] {
    inspect(
      font_outline_validate_trailing(font_wb_view(padding), 0UL) is Ok(_),
      content="true",
    )
  }
  for padding in [b"\x01", b"\x00\x01", b"\x00\x00\x01"] {
    let error = font_outline_validate_trailing(
      font_wb_view(padding),
      0UL,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
    inspect(error.context() == Some("font-outline-trailing"), content="true")
    inspect(
      error.requested() == Some(padding.length().to_uint64()),
      content="true",
    )
    inspect(error.limit() == Some(3UL), content="true")
  }
  let over_aligned = font_outline_validate_trailing(
    font_wb_view(b"\x00\x00\x00\x00"),
    0UL,
  ).unwrap_err()
  inspect(over_aligned.category() == @error.ErrorCategory::Data, content="true")
  inspect(over_aligned.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(
    over_aligned.context() == Some("font-outline-trailing"),
    content="true",
  )
  inspect(over_aligned.requested() == Some(4UL), content="true")
  inspect(over_aligned.limit() == Some(3UL), content="true")
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
  inspect(error.context() == Some("font-source-revision-drift"), content="true")
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
  let left : OutlinePoint = { x_q15: -32768L, y_q15: 0L, on_curve: false }
  let right : OutlinePoint = { x_q15: 0L, y_q15: 32768L, on_curve: false }
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
test "outline Q15 matrix order and signed attachment subtraction are exact" {
  let point : OutlinePoint = { x_q15: 32768L, y_q15: 65536L, on_curve: true }
  let matrix : F2Dot14Matrix = {
    xscale_raw: 16384L,
    scale01_raw: -8192L,
    scale10_raw: 8192L,
    yscale_raw: 16384L,
  }
  let transformed = transform_q15(point, matrix).unwrap()
  inspect(transformed.x_q15, content="65536")
  inspect(transformed.y_q15, content="49152")
  inspect(outline_checked_subtract(32768L, -16384L).unwrap(), content="49152")
}

///|
test "generated composite fixtures reach the private full placement seam" {
  let first = generated_composite_component(0x0023UL, 0UL, 10, 0, [])
  let second = generated_composite_component(0x0009UL, 0UL, 2, 0, [8192])
  let parent = generated_composite_glyph(-32768, -32768, 32767, 32767, [
    first, second,
  ])
  let owner = font_wb_owner(
    generated_outline_graph_truetype([generated_simple_outline_body(), parent]),
  )
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let path = font
    .outline(font.glyph_id(1UL).unwrap(), font_wb_outline_budget())
    .unwrap()
  inspect(path.length(), content="8")
}

///|
test "portable outline fixture freezes expanded points descriptors and graph" {
  let owner = font_wb_owner(generated_portable_outline_matrix_truetype())
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let simple_source = font_glyph_window(font.glyf_metric_index(), 1UL)
    .unwrap()
    .unwrap()
  let simple_ledger : OutlineWork = { used: 0UL }
  let geometry = font_decode_simple_geometry(
    simple_source,
    1UL,
    font.tables.maxp,
    font.limits,
    simple_ledger,
    font_wb_outline_budget(),
  ).unwrap()
  inspect(geometry.points.length(), content="5")
  inspect(geometry.endpoints.length(), content="1")
  inspect(geometry.endpoints[0], content="4")
  inspect(geometry.points[0].on_curve, content="true")
  inspect(geometry.points[1].on_curve, content="false")
  inspect(geometry.points[2].on_curve, content="false")
  inspect(geometry.points[3].on_curve, content="true")
  inspect(geometry.points[4].on_curve, content="true")
  inspect(geometry.points[1].x_q15, content="1638400")
  inspect(geometry.points[2].x_q15, content="3276800")
  inspect(geometry.points[3].y_q15, content="3276800")

  let composite_source = font_glyph_window(font.glyf_metric_index(), 2UL)
    .unwrap()
    .unwrap()
  let parse_ledger : OutlineWork = { used: 0UL }
  let parsed = font_parse_composite_descriptors(
    composite_source,
    font.tables.maxp,
    font.limits,
    parse_ledger,
    font_wb_outline_budget(),
  ).unwrap()
  inspect(parsed.descriptors.length(), content="2")
  inspect(parsed.descriptors[0].flags, content="43")
  inspect(parsed.descriptors[0].glyph_index, content="1")
  inspect(parsed.descriptors[0].matrix.xscale_raw, content="8192")
  inspect(parsed.descriptors[0].matrix.yscale_raw, content="8192")
  match parsed.descriptors[0].placement {
    ComponentXY(x, y) => {
      inspect(x, content="10")
      inspect(y, content="-4")
    }
    _ => fail("expected first descriptor XY placement")
  }
  match parsed.descriptors[1].placement {
    ComponentPoints(parent, child) => {
      inspect(parent, content="3")
      inspect(child, content="0")
    }
    _ => fail("expected second descriptor real-point placement")
  }
  let graph_ledger : OutlineWork = { used: 0UL }
  let classification = font_classify_composite_graph(
    2UL,
    composite_source,
    font.glyf_metric_index(),
    font.tables.maxp,
    font.limits,
    graph_ledger,
    font_wb_outline_budget(),
  ).unwrap()
  inspect(classification.root_descriptors.length(), content="2")
  inspect(classification.saw_deeper, content="false")
  inspect(classification.saw_grid_rounding, content="false")
}

///|
test "composite graph state allocation enforces exact portable slot bytes" {
  let parent = generated_composite_glyph(-32768, -32768, 32767, 32767, [
    generated_composite_component(0x0003UL, 0UL, 0, 0, []),
  ])
  let glyphs : Array[Bytes] = []
  for _glyph = 0; _glyph < 10; _glyph = _glyph + 1 {
    glyphs.push(b"")
  }
  glyphs.push(parent)
  let owner = font_wb_owner(
    generated_outline_graph_truetype(
      glyphs,
      max_composite_points=0UL,
      max_composite_contours=0UL,
      max_component_elements=1UL,
      max_component_depth=1UL,
    ),
  )
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let root_source = font_glyph_window(font.glyf_metric_index(), 10UL).unwrap().unwrap()
  let exact = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=3UL,
      allocation_size=88UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
  let exact_ledger : OutlineWork = { used: 0UL }
  let classification = font_classify_composite_graph(
    10UL,
    root_source,
    font.glyf_metric_index(),
    font.tables.maxp,
    font.limits,
    exact_ledger,
    exact,
  ).unwrap()
  inspect(classification.root_descriptors.length(), content="1")
  inspect(exact.remaining().allocations(), content="0")

  let one_short = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=3UL,
      allocation_size=87UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
  let one_short_ledger : OutlineWork = { used: 0UL }
  let one_short_error = font_classify_composite_graph(
    10UL,
    root_source,
    font.glyf_metric_index(),
    font.tables.maxp,
    font.limits,
    one_short_ledger,
    one_short,
  ).unwrap_err()
  inspect(
    one_short_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    one_short_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(one_short_error.context() == Some("allocation_size"), content="true")
  inspect(one_short_error.requested() == Some(88UL), content="true")
  inspect(one_short_error.limit() == Some(87UL), content="true")
  inspect(one_short.remaining().allocations(), content="3")

  let overflow_index : MetricIndexFacts = {
    hmtx: font.glyf_metric_index().hmtx,
    glyf: font.glyf_metric_index().glyf,
    loca_offsets: font.glyf_metric_index().loca_offsets,
    num_glyphs: 18446744073709551615UL,
    number_of_h_metrics: font.glyf_metric_index().number_of_h_metrics,
  }
  let overflow_ledger : OutlineWork = { used: 0UL }
  let overflow = font_classify_composite_graph(
    10UL,
    root_source,
    overflow_index,
    font.tables.maxp,
    font.limits,
    overflow_ledger,
    font_wb_outline_budget(),
  ).unwrap_err()
  inspect(overflow.category() == @error.ErrorCategory::Data, content="true")
  inspect(overflow.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(
    overflow.context() == Some("font-outline-composite-state"),
    content="true",
  )
}

///|
test "uniform composite public production path remains directly verified" {
  let parent = generated_composite_glyph(
    10,
    -4,
    60,
    46,
    [generated_composite_component(0x000BUL, 0UL, 10, -4, [8192])],
  )
  let owner = font_wb_owner(
    generated_outline_graph_truetype([
      generated_simple_outline_body(),
      parent,
    ]),
  )
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let path = font
    .outline(font.glyph_id(1UL).unwrap(), font_wb_outline_budget())
    .unwrap()
  inspect(path.length(), content="4")
  match path.get(0) {
    Some(@math.PathCommand::MoveTo(point)) => {
      inspect(point.x(), content="10")
      inspect(point.y(), content="-4")
    }
    _ => fail("expected production composite MoveTo")
  }
}

///|
test "outline max_work charges completed stages before transactional failure" {
  let maxp : MaxpFacts = {
    num_glyphs: 1UL,
    max_points: 3UL,
    max_contours: 1UL,
    max_composite_points: 0UL,
    max_composite_contours: 0UL,
    max_size_of_instructions: 0UL,
    max_component_elements: 0UL,
    max_component_depth: 0UL,
  }
  let limits = FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_outline_points=3UL,
    max_outline_contours=1UL,
    max_outline_components=1UL,
    max_outline_instruction_bytes=1UL,
    max_post_name_bytes=256UL,
    max_work=17UL,
  ).unwrap()
  let budget = font_wb_outline_budget()
  let before = budget.remaining().work()
  let ledger : OutlineWork = { used: 0UL }
  let error = font_decode_simple_outline(
    font_wb_view(
      b"\x00\x01\x00\x00\x00\x00\x00\x64\x00\x64\x00\x02\x00\x00\x31\x33\x34\x64\x64\x00",
    ),
    1UL,
    maxp,
    limits,
    ledger,
    budget,
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(error.operation() == Some("font-outline"), content="true")
  inspect(error.context() == Some("max-work"), content="true")
  inspect(error.requested() == Some(18UL), content="true")
  inspect(error.limit() == Some(17UL), content="true")
  inspect(ledger.used, content="13")
  inspect(budget.remaining().work() == before - 13UL, content="true")
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
test "format-6 coexistence is bounded without supported body work" {
  let source : Array[Byte] = []
  font_wb_put_u16(source, 0UL)
  font_wb_put_u16(source, 1UL)
  font_wb_put_u16(source, 1UL)
  font_wb_put_u16(source, 0UL)
  font_wb_put_u32(source, 12UL)
  font_wb_put_u16(source, 6UL)
  font_wb_put_u16(source, 12UL)
  font_wb_put_u16(source, 0UL)
  font_wb_put_u16(source, 0UL)
  font_wb_put_u16(source, 1UL)
  font_wb_put_u16(source, 0UL)
  let bytes = Bytes::from_array(source)
  let table : TableWindow = {
    tag: 0x636D6170UL,
    checksum: 0UL,
    offset: 0UL,
    length_value: bytes.length().to_uint64(),
    view: font_wb_view(bytes),
  }
  let envelope = font_cmap_subtable_envelope(table, 12UL).unwrap()
  inspect(envelope.format, content="6")
  inspect(envelope.length, content="12")
  inspect(font_cmap_recognized_nonselected(1UL, 0UL, 6UL), content="true")
  for tuple in [(0UL, 0UL, 6UL), (1UL, 1UL, 6UL), (1UL, 0UL, 4UL)] {
    let (platform, encoding, format) = tuple
    inspect(
      !font_cmap_recognized_nonselected(platform, encoding, format),
      content="true",
    )
  }
  let budget = font_wb_open_budget()
  let before = budget.remaining()
  let work = font_cmap_declared_work(table, 1UL, budget, 1UL, 0UL).unwrap()
  inspect(work.body_records, content="0")
  inspect(work.format4_discovery_work, content="0")
  inspect(work.search_work, content="0")
  inspect(work.mapping_work, content="0")
  inspect(budget.remaining().work() == before.work() - 1UL, content="true")
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
fn font_wb_work_budget(work : UInt64) -> @budget.Budget {
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
test "seeded CFF kern authority rejects cumulative work before pair traversal" {
  let table = Some(
    font_wb_kern_table(font_wb_kern_format0([(0UL, 1UL, 10)])),
  )
  let caller = font_wb_work_budget(8UL)
  let ledger = FontAdmissionLedger::new_with_staged_work(
    caller,
    FontAdmissionCommitMode::CollectionDeferred,
    7UL,
  )
  let mut caller_pair_visits = 0
  let caller_error = font_admit_kern_bounded_with_probe(
    table,
    2UL,
    font_wb_limits(),
    ledger,
    7UL,
    0UL,
    fn() { caller_pair_visits = caller_pair_visits + 1 },
  ).unwrap_err()
  inspect(
    caller_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(caller_error.context() == Some("work"), content="true")
  inspect(caller_pair_visits, content="0")
  inspect(caller.remaining().work(), content="8")

  let parent = font_wb_work_budget(9UL)
  let child = parent.child(parent.remaining()).unwrap()
  parent
  .charge(
    @budget.ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=1UL,
    ),
  )
  .unwrap()
  let child_ledger = FontAdmissionLedger::new_with_staged_work(
    child,
    FontAdmissionCommitMode::CollectionDeferred,
    7UL,
  )
  let mut ancestor_pair_visits = 0
  let ancestor_error = font_admit_kern_bounded_with_probe(
    table,
    2UL,
    font_wb_limits(),
    child_ledger,
    7UL,
    0UL,
    fn() { ancestor_pair_visits = ancestor_pair_visits + 1 },
  ).unwrap_err()
  inspect(
    ancestor_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(ancestor_error.context() == Some("work"), content="true")
  inspect(ancestor_pair_visits, content="0")
  inspect(parent.remaining().work(), content="8")
  inspect(child.remaining().work(), content="9")
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
test "outline rejects post-decode revision drift without path publication" {
  let owner = font_wb_owner(generated_simple_outline_truetype())
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let glyph = font.glyph_id(0UL).unwrap()
  let mut callback_count = 0
  let result = font.outline_after_decode(glyph, font_wb_outline_budget(), fn() {
    callback_count = callback_count + 1
    font_wb_mutate_one_byte(owner, 0UL)
  })
  match result {
    Ok(_) => fail("post-decode revision drift must not publish a Path2")
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::State, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      inspect(error.operation() == Some("font-outline"), content="true")
      inspect(
        error.context() == Some("font-source-revision-drift"),
        content="true",
      )
    }
  }
  inspect(callback_count, content="1")
}

///|
test "composite outline rejects post-decode revision drift without publication" {
  let parent = generated_composite_glyph(-32768, -32768, 32767, 32767, [
    generated_composite_component(0x0003UL, 0UL, 0, 0, []),
  ])
  let owner = font_wb_owner(
    generated_outline_graph_truetype([generated_simple_outline_body(), parent]),
  )
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  let glyph = font.glyph_id(1UL).unwrap()
  let mut callback_count = 0
  let result = font.outline_after_decode(glyph, font_wb_outline_budget(), fn() {
    callback_count = callback_count + 1
    font_wb_mutate_one_byte(owner, 0UL)
  })
  match result {
    Ok(_) =>
      fail("post-decode revision drift must not publish a composite Path2")
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::State, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      inspect(error.operation() == Some("font-outline"), content="true")
      inspect(
        error.context() == Some("font-source-revision-drift"),
        content="true",
      )
    }
  }
  inspect(callback_count, content="1")
}

///|
test "outline generated zero and degenerate glyphs remain observable" {
  let zero_owner = font_wb_owner(generated_zero_contour_outline_truetype())
  let zero = Font::open(
    zero_owner.view(),
    font_wb_limits(),
    font_wb_open_budget(),
  ).unwrap()
  inspect(
    zero
    .outline(zero.glyph_id(0UL).unwrap(), font_wb_outline_budget())
    .unwrap()
    .length(),
    content="0",
  )

  let degenerate_owner = font_wb_owner(generated_degenerate_outline_truetype())
  let degenerate = Font::open(
    degenerate_owner.view(),
    font_wb_limits(),
    font_wb_open_budget(),
  ).unwrap()
  let path = degenerate
    .outline(degenerate.glyph_id(0UL).unwrap(), font_wb_outline_budget())
    .unwrap()
  inspect(path.length(), content="2")
  inspect(path.get(0) is Some(@math.PathCommand::MoveTo(_)), content="true")
  inspect(path.get(1) is Some(@math.PathCommand::Close), content="true")
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
    max_outline_points=4096UL,
    max_outline_contours=256UL,
    max_outline_components=256UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
}

///|
test "private outline source accepts complete CFF facts and no partial or mixed state" {
  let admitted = admit_cff1_structure(
    font_wb_view(
      cff_wb_otf(
        cff_name_wb_table(),
        num_glyphs=3UL,
      ),
    ),
    font_wb_limits(),
    cff_wb_budget(),
    1UL,
  ).unwrap()
  match font_outline_source_from_cff(admitted) {
    FontOutlineSource::Cff1(value) => {
      inspect(value.glyphs.length(), content="3")
      inspect(value.glyphs[1].gid, content="1")
      inspect(value.bounds.length(), content="3")
    }
    _ => fail("complete admitted CFF facts must promote as Cff1")
  }

  let glyf_owner = font_wb_owner(generated_minimal_truetype())
  let glyf_font = Font::open(
    glyf_owner.view(),
    font_wb_limits(),
    font_wb_open_budget(),
  ).unwrap()
  match glyf_font.outline_source {
    FontOutlineSource::Glyf(_) => ()
    _ => fail("existing public static glyf opening must remain Glyf")
  }

  let malformed = admit_cff1_structure(
    font_wb_view(cff_wb_otf(b"\x01")),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  )
  inspect(malformed is Err(_), content="true")
  let mixed = admit_cff1_structure(
    font_wb_view(
      cff_wb_otf_tables([
        font_wb_table(b"CFF ", b"\x01"),
        font_wb_table(b"glyf", b""),
        font_wb_table(b"head", generated_head_table()),
        font_wb_table(b"loca", b""),
        font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
      ]),
    ),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  )
  inspect(mixed is Err(_), content="true")
}

///|
fn font_wb_shared_cff_face_local_hmtx_ttc() -> Bytes {
  let output = font_wb_bytes_array(font_collection_wb_shared_cff_ttc())
  let second_hmtx = b"\x02\x58\x00\x0a\x00\x14\x00\x1e"
  let second_hmtx_offset = output.length().to_uint64()
  for byte in font_wb_bytes_array(second_hmtx) {
    output.push(byte)
  }
  // The generated standalone directory is tag-sorted; hmtx is record five.
  let second_hmtx_record = 188 + 12 + 5 * 16
  font_collection_wb_put_u32(
    output,
    second_hmtx_record + 4,
    generated_checksum(second_hmtx),
  )
  font_collection_wb_put_u32(
    output,
    second_hmtx_record + 8,
    second_hmtx_offset,
  )
  Bytes::from_array(output)
}

///|
fn font_wb_cff_cubic_path_charge() -> CffPathCharge {
  {
    resource: @budget.ResourceCharge::new(
      bytes=192UL,
      allocations=5UL,
      allocation_size=384UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=19UL,
    ),
    bytes: 192UL,
    allocations: 5UL,
    allocation_size: 384UL,
    work: 19UL,
    command_capacity: 3UL,
  }
}

///|
fn font_wb_budget_for_cff_charge(
  charge : CffPathCharge,
  allocation_size : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=charge.bytes,
      allocations=charge.allocations,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=charge.work,
    ),
  )
}

///|
test "shared CFF collection faces retain identical bounds and face-local hmtx" {
  let owner = font_wb_owner(font_wb_shared_cff_face_local_hmtx_ttc())
  let first = admit_cff1_collection_structure(
    owner.view(),
    32UL,
    9UL,
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap()
  let second = admit_cff1_collection_structure(
    owner.view(),
    188UL,
    9UL,
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap()
  inspect(first.cff_table_offset == second.cff_table_offset, content="true")
  inspect(first.bounds.length(), content="3")
  inspect(second.bounds.length(), content="3")
  for gid = 0; gid < 3; gid = gid + 1 {
    inspect(first.bounds[gid] is None, content="true")
    inspect(second.bounds[gid] is None, content="true")
  }
  let first_metric = cff_read_hmtx_metric(first.metrics, 0UL).unwrap()
  let second_metric = cff_read_hmtx_metric(second.metrics, 0UL).unwrap()
  inspect(first_metric.0, content="0")
  inspect(first_metric.1, content="0")
  inspect(second_metric.0, content="600")
  inspect(second_metric.1, content="10")
}

///|
test "CFF outline exact path charge tracer rejects post-stage mutation atomically" {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  let owner = font_wb_owner(
    cff_wb_otf_with_cmap(
      cff_wb_name_table_with_programs([b"\x0e", cubic, b"\x0e"]),
      cff_wb_cmap_format4_two_segments(),
      num_glyphs=3UL,
    ),
  )
  let font = Font::open(
    owner.view(),
    font_wb_limits(),
    cff_wb_budget(),
  ).unwrap()
  let glyph = font.glyph_id(1UL).unwrap()
  let charge = font_wb_cff_cubic_path_charge()
  inspect(charge.command_capacity, content="3")
  inspect(charge.allocation_size, content="384")

  let exact_parent = font_wb_budget_for_cff_charge(
    charge,
    charge.allocation_size,
  )
  let exact_child = exact_parent
    .child(exact_parent.remaining())
    .unwrap()
  let exact_path = font.outline(glyph, exact_child).unwrap()
  inspect(exact_path.length(), content="3")
  inspect(exact_parent.remaining().bytes(), content="0")
  inspect(exact_parent.remaining().allocations(), content="0")
  inspect(exact_parent.remaining().work(), content="0")
  inspect(exact_child.remaining().bytes(), content="0")
  inspect(exact_child.remaining().allocations(), content="0")
  inspect(exact_child.remaining().work(), content="0")

  let short_parent = font_wb_budget_for_cff_charge(
    charge,
    charge.allocation_size,
  )
  let short_child = short_parent
    .child(
      @budget.ResourceLimits::new(
        bytes=charge.bytes,
        allocations=charge.allocations,
        allocation_size=charge.allocation_size - 1UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=charge.work,
      ),
    )
    .unwrap()
  let short_parent_before = short_parent.remaining()
  let short_before = short_child.remaining()
  let short_result = font.outline(glyph, short_child)
  inspect(short_result is Err(_), content="true")
  let short_error = short_result.unwrap_err()
  inspect(
    short_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(short_error.context() == Some("allocation_size"), content="true")
  inspect(
    short_parent.remaining().bytes() == short_parent_before.bytes(),
    content="true",
  )
  inspect(
    short_child.remaining().bytes() == short_before.bytes(),
    content="true",
  )

  let mutation_parent = font_wb_budget_for_cff_charge(
    charge,
    charge.allocation_size,
  )
  let mutation_budget = mutation_parent
    .child(mutation_parent.remaining())
    .unwrap()
  let parent_before = mutation_parent.remaining()
  let before = mutation_budget.remaining()
  let result = font.outline_after_decode(glyph, mutation_budget, fn() {
    font_wb_mutate_one_byte(owner, 0)
  })
  inspect(result is Err(_), content="true")
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.context() == Some("font-source-revision-drift"), content="true")
  let after = mutation_budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(
    after.allocation_size() == before.allocation_size(),
    content="true",
  )
  inspect(after.work() == before.work(), content="true")
  let parent_after = mutation_parent.remaining()
  inspect(parent_after.bytes() == parent_before.bytes(), content="true")
  inspect(
    parent_after.allocations() == parent_before.allocations(),
    content="true",
  )
  inspect(parent_after.work() == parent_before.work(), content="true")
}

///|
test "CFF outline atomic mutation probes preserve every budget window" {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"

  let (before_owner, before_font) = cff_path_wb_owner_and_font([
    b"\x0e",
    cubic,
    b"\x0e",
  ])
  let before_glyph = before_font.glyph_id(1UL).unwrap()
  let before_charge = font_wb_cff_cubic_path_charge()
  let before_parent = @budget.Budget::new(
    cff_path_wb_exact_limits(before_charge),
  )
  let before_child = before_parent
    .child(cff_path_wb_exact_limits(before_charge))
    .unwrap()
  let before_parent_remaining = before_parent.remaining()
  let before_child_remaining = before_child.remaining()
  let mut before_probes = 0
  let before_error = cff_decode_outline_atomic_with_probes(
    before_font.source,
    cff_path_wb_admitted(before_font),
    before_glyph.value(),
    before_font.limits,
    before_child,
    fn() {
      before_probes = before_probes + 1
      font_collection_wb_mutate_restore(before_owner, 0UL)
    },
    fn() { () },
  ).unwrap_err()
  inspect(before_probes, content="1")
  inspect(
    before_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  inspect(
    before_error.context() == Some("font-source-revision-drift"),
    content="true",
  )
  cff_path_wb_assert_limits_equal(
    before_parent_remaining,
    before_parent.remaining(),
  )
  cff_path_wb_assert_limits_equal(
    before_child_remaining,
    before_child.remaining(),
  )

  let (after_owner, after_font) = cff_path_wb_owner_and_font([
    b"\x0e",
    cubic,
    b"\x0e",
  ])
  let after_glyph = after_font.glyph_id(1UL).unwrap()
  let after_charge = font_wb_cff_cubic_path_charge()
  let after_parent = @budget.Budget::new(
    cff_path_wb_exact_limits(after_charge),
  )
  let after_child = after_parent
    .child(cff_path_wb_exact_limits(after_charge))
    .unwrap()
  let after_parent_remaining = after_parent.remaining()
  let after_child_remaining = after_child.remaining()
  let after_error = cff_decode_outline_atomic_with_probes(
    after_font.source,
    cff_path_wb_admitted(after_font),
    after_glyph.value(),
    after_font.limits,
    after_child,
    fn() { () },
    fn() { font_collection_wb_mutate_restore(after_owner, 0UL) },
  ).unwrap_err()
  inspect(
    after_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  inspect(
    after_error.context() == Some("font-source-revision-drift"),
    content="true",
  )
  cff_path_wb_assert_limits_equal(
    after_parent_remaining,
    after_parent.remaining(),
  )
  cff_path_wb_assert_limits_equal(
    after_child_remaining,
    after_child.remaining(),
  )
}

///|
test "CFF outline atomic multi-fault precedence is State Resource Capability Data" {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  let (owner, font) = cff_path_wb_owner_and_font([b"\x0e", cubic, b"\x0e"])
  let glyph = font.glyph_id(1UL).unwrap()
  let charge = font_wb_cff_cubic_path_charge()
  let admitted = cff_path_wb_admitted(font)
  let (capability_descriptors, _capability_subrs, _capability_authority) =
    type2_fixture_descriptors([b"\x8b\x8b\x8b\x8b\x0e"], [0L])
  admitted.glyphs[1] = capability_descriptors[0]

  let short_limits = cff_path_wb_limits(
    charge.bytes - 1UL,
    charge.allocations,
    charge.allocation_size,
    charge.work,
  )
  let state_parent = @budget.Budget::new(short_limits)
  let state_child = state_parent.child(short_limits).unwrap()
  let state_parent_before = state_parent.remaining()
  let state_child_before = state_child.remaining()
  let state = cff_decode_outline_atomic_with_probes(
    font.source,
    admitted,
    glyph.value(),
    font.limits,
    state_child,
    fn() { font_collection_wb_mutate_restore(owner, 0UL) },
    fn() { () },
  ).unwrap_err()
  inspect(state.category() == @error.ErrorCategory::State, content="true")
  cff_path_wb_assert_limits_equal(
    state_parent_before,
    state_parent.remaining(),
  )
  cff_path_wb_assert_limits_equal(
    state_child_before,
    state_child.remaining(),
  )

  let (_resource_owner, resource_font) = cff_path_wb_owner_and_font([
    b"\x0e",
    cubic,
    b"\x0e",
  ])
  let resource_glyph = resource_font.glyph_id(1UL).unwrap()
  let resource_charge = font_wb_cff_cubic_path_charge()
  let resource_admitted = cff_path_wb_admitted(resource_font)
  resource_admitted.glyphs[1] = capability_descriptors[0]
  let resource_budget = @budget.Budget::new(
    cff_path_wb_limits(
      resource_charge.bytes - 1UL,
      resource_charge.allocations,
      resource_charge.allocation_size,
      resource_charge.work,
    ),
  )
  let resource_before = resource_budget.remaining()
  let resource = cff_decode_outline_atomic(
    resource_font.source,
    resource_admitted,
    resource_glyph.value(),
    resource_font.limits,
    resource_budget,
    fn() { () },
  ).unwrap_err()
  inspect(
    resource.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(resource.context() == Some("bytes"), content="true")
  cff_path_wb_assert_limits_equal(resource_before, resource_budget.remaining())

  let capability_budget = @budget.Budget::new(
    cff_path_wb_exact_limits(resource_charge),
  )
  let capability_before = capability_budget.remaining()
  let capability = cff_decode_outline_atomic(
    resource_font.source,
    resource_admitted,
    resource_glyph.value(),
    resource_font.limits,
    capability_budget,
    fn() { () },
  ).unwrap_err()
  inspect(
    capability.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  cff_path_wb_assert_limits_equal(
    capability_before,
    capability_budget.remaining(),
  )

  let (_data_owner, data_font) = cff_path_wb_owner_and_font([
    b"\x0e",
    cubic,
    b"\x0e",
  ])
  let data_glyph = data_font.glyph_id(1UL).unwrap()
  let data_charge = font_wb_cff_cubic_path_charge()
  let data_admitted = cff_path_wb_admitted(data_font)
  let (data_descriptors, _data_subrs, _data_authority) =
    type2_fixture_descriptors([b"\x00"], [0L])
  data_admitted.glyphs[1] = data_descriptors[0]
  let data_budget = @budget.Budget::new(cff_path_wb_exact_limits(data_charge))
  let data_before = data_budget.remaining()
  let data = cff_decode_outline_atomic(
    data_font.source,
    data_admitted,
    data_glyph.value(),
    data_font.limits,
    data_budget,
    fn() { () },
  ).unwrap_err()
  inspect(data.category() == @error.ErrorCategory::Data, content="true")
  cff_path_wb_assert_limits_equal(data_before, data_budget.remaining())
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
  inspect(tables.maxp.max_points, content="64")
  inspect(tables.maxp.max_contours, content="16")
  inspect(tables.maxp.max_composite_points, content="64")
  inspect(tables.maxp.max_composite_contours, content="16")
  inspect(tables.maxp.max_size_of_instructions, content="64")
  inspect(tables.maxp.max_component_elements, content="16")
  inspect(tables.maxp.max_component_depth, content="1")
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
