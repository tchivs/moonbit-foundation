///|
test "validated scalar snapshot preserves values adjacency and count after caller mutation" {
  let scalars = [0x41, 0x41, 0x1F600]
  let snapshot = validate_and_snapshot_scalars_with_probe(scalars, fn() {
    scalars[0] = 0x42
    scalars[1] = 0x43
    scalars.push(0x44)
  }).unwrap()
  inspect(snapshot.length(), content="3")
  inspect(snapshot[0], content="65")
  inspect(snapshot[1], content="65")
  inspect(snapshot[2], content="128512")
  inspect(scalars.length(), content="4")
  inspect(scalars[0], content="66")
}

///|
test "private scalar validator accepts exact Unicode scalar boundaries" {
  let scalars = [0, 0xD7FF, 0xE000, 0x10FFFF]
  let snapshot = validate_and_snapshot_scalars_with_probe(scalars, fn() { () }).unwrap()
  inspect(snapshot.length(), content="4")
  inspect(snapshot[0], content="0")
  inspect(snapshot[1], content="55295")
  inspect(snapshot[2], content="57344")
  inspect(snapshot[3], content="1114111")
}

///|
struct TextWbTable {
  tag : Bytes
  payload : Bytes
}

///|
fn text_wb_push_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn text_wb_push_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn text_wb_put_u16(output : Array[Byte], offset : Int, value : UInt64) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn text_wb_put_u32(output : Array[Byte], offset : Int, value : UInt64) -> Unit {
  output[offset] = (value >> 24).to_byte()
  output[offset + 1] = (value >> 16).to_byte()
  output[offset + 2] = (value >> 8).to_byte()
  output[offset + 3] = value.to_byte()
}

///|
fn text_wb_checksum(source : Bytes) -> UInt64 {
  let mut checksum = 0UL
  let mut offset = 0
  while offset < source.length() {
    let b0 = source[offset].to_uint64()
    let b1 = if offset + 1 < source.length() {
      source[offset + 1].to_uint64()
    } else {
      0UL
    }
    let b2 = if offset + 2 < source.length() {
      source[offset + 2].to_uint64()
    } else {
      0UL
    }
    let b3 = if offset + 3 < source.length() {
      source[offset + 3].to_uint64()
    } else {
      0UL
    }
    checksum = (
        checksum +
        ((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
      ) &
      0xFFFFFFFFUL
    offset = offset + 4
  }
  checksum
}

///|
fn text_wb_head_table() -> Bytes {
  let output : Array[Byte] = []
  text_wb_push_u32(output, 0x00010000UL)
  text_wb_push_u32(output, 0x00010000UL)
  text_wb_push_u32(output, 0UL)
  text_wb_push_u32(output, 0x5F0F3CF5UL)
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 1000UL)
  for _index = 0; _index < 24; _index = _index + 1 {
    output.push(b'\x00')
  }
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 8UL)
  text_wb_push_u16(output, 2UL)
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn text_wb_cmap_table() -> Bytes {
  let output : Array[Byte] = []
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 1UL)
  text_wb_push_u16(output, 3UL)
  text_wb_push_u16(output, 1UL)
  text_wb_push_u32(output, 12UL)
  text_wb_push_u16(output, 4UL)
  text_wb_push_u16(output, 24UL)
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 2UL)
  text_wb_push_u16(output, 2UL)
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 0xFFFFUL)
  text_wb_push_u16(output, 0UL)
  text_wb_push_u16(output, 0xFFFFUL)
  text_wb_push_u16(output, 1UL)
  text_wb_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn text_wb_hhea_table() -> Bytes {
  let output = Array::make(36, b'\x00')
  text_wb_put_u32(output, 0, 0x00010000UL)
  text_wb_put_u16(output, 34, 1UL)
  Bytes::from_array(output)
}

///|
fn text_wb_maxp_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  text_wb_put_u32(output, 0, 0x00010000UL)
  text_wb_put_u16(output, 4, 2UL)
  text_wb_put_u16(output, 6, 64UL)
  text_wb_put_u16(output, 8, 16UL)
  text_wb_put_u16(output, 10, 64UL)
  text_wb_put_u16(output, 12, 16UL)
  text_wb_put_u16(output, 26, 64UL)
  text_wb_put_u16(output, 28, 16UL)
  text_wb_put_u16(output, 30, 1UL)
  Bytes::from_array(output)
}

///|
fn text_wb_post_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  text_wb_put_u32(output, 0, 0x00030000UL)
  Bytes::from_array(output)
}

///|
fn text_wb_search_facts(num_tables : UInt64) -> (UInt64, UInt64, UInt64) {
  let mut power = 1UL
  let mut selector = 0UL
  while power <= num_tables / 2UL {
    power = power * 2UL
    selector = selector + 1UL
  }
  let search_range = power * 16UL
  (search_range, selector, num_tables * 16UL - search_range)
}

///|
fn text_wb_build_truetype(tables : Array[TextWbTable]) -> Bytes {
  let output : Array[Byte] = []
  let num_tables = tables.length().to_uint64()
  let (search_range, selector, range_shift) = text_wb_search_facts(num_tables)
  text_wb_push_u32(output, 0x00010000UL)
  text_wb_push_u16(output, num_tables)
  text_wb_push_u16(output, search_range)
  text_wb_push_u16(output, selector)
  text_wb_push_u16(output, range_shift)
  let mut next_offset = 12UL + num_tables * 16UL
  let offsets : Array[UInt64] = []
  for table in tables {
    for byte in table.tag {
      output.push(byte)
    }
    text_wb_push_u32(output, text_wb_checksum(table.payload))
    text_wb_push_u32(output, next_offset)
    text_wb_push_u32(output, table.payload.length().to_uint64())
    offsets.push(next_offset)
    next_offset = (next_offset + table.payload.length().to_uint64() + 3UL) &
      0xFFFFFFFFFFFFFFFCUL
  }
  for table in tables {
    for byte in table.payload {
      output.push(byte)
    }
    while output.length() % 4 != 0 {
      output.push(b'\x00')
    }
  }
  let adjustment = (
      0xB1B0AFBAUL - text_wb_checksum(Bytes::from_array(output.copy()))
    ) &
    0xFFFFFFFFUL
  text_wb_put_u32(output, offsets[3].to_int() + 8, adjustment)
  Bytes::from_array(output)
}

///|
fn text_wb_font_bytes() -> Bytes {
  text_wb_build_truetype([
    { tag: b"OS/2", payload: Bytes::from_array(Array::make(78, b'\x00')) },
    { tag: b"cmap", payload: text_wb_cmap_table() },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: text_wb_head_table() },
    { tag: b"hhea", payload: text_wb_hhea_table() },
    { tag: b"hmtx", payload: b"\x01\xf4\x00\x00\x00\x00" },
    { tag: b"loca", payload: b"\x00\x00\x00\x00\x00\x00" },
    { tag: b"maxp", payload: text_wb_maxp_table() },
    { tag: b"name", payload: b"\x00\x00\x00\x00\x00\x06" },
    { tag: b"post", payload: text_wb_post_table() },
  ])
}

///|
fn text_wb_font_limits() -> @font.FontLimits {
  @font.FontLimits::new(
    max_source_bytes=1024UL,
    max_tables=16UL,
    max_table_bytes=256UL,
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
fn text_wb_resource_budget(work : UInt64) -> @budget.Budget {
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
fn text_wb_font() -> (@bytes.OwnedBytes, @font.Font) {
  let source = text_wb_font_bytes()
  let length = source.length().to_uint64()
  let owner = @bytes.OwnedBytes::from_bytes(
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
  let font = @font.Font::open(
    owner.view(),
    text_wb_font_limits(),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=1024UL,
        allocations=16UL,
        allocation_size=1024UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=4096UL,
      ),
    ),
  ).unwrap()
  (owner, font)
}

///|
fn text_wb_options(direction : Direction) -> ShapingOptions {
  ShapingOptions::new(
    ScriptTag::new(b"latn").unwrap(),
    LanguageChoice::Default,
    direction,
    FeaturePolicy::new(liga=true, kern=true),
  )
}

///|
fn text_wb_limits(input : UInt64, output : UInt64) -> ShapeLimits {
  ShapeLimits::new(
    max_input_scalars=input,
    max_output_glyphs=output,
  ).unwrap()
}

///|
fn text_wb_charge(work : UInt64) -> @budget.ResourceCharge {
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
fn text_wb_ab_facts(font : @font.Font) -> Array[GeneratedLogicalGlyph] {
  [
    generated_logical_glyph(
      font.glyph_id(0UL).unwrap(),
      [0UL],
      600L,
      -50L,
      20L,
      -10L,
    ),
    generated_logical_glyph(
      font.glyph_id(1UL).unwrap(),
      [1UL],
      500L,
      0L,
      -30L,
      15L,
    ),
  ]
}

///|
test "generated logical records publish exact immutable LTR and RTL runs" {
  let (_ltr_owner, ltr_font) = text_wb_font()
  let ltr_budget = text_wb_resource_budget(3UL)
  let ltr = generated_shape_contract(
    ltr_font,
    [0x41, 0x42],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(2UL, 2UL),
    ltr_budget,
    text_wb_ab_facts(ltr_font),
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(3UL),
  ).unwrap()
  inspect(ltr.len(), content="2")
  let ltr_a = ltr.glyph_at(0UL).unwrap()
  let ltr_b = ltr.glyph_at(1UL).unwrap()
  inspect(ltr_a.glyph().value(), content="0")
  inspect(ltr_a.cluster(), content="0")
  inspect(ltr_a.advance(), content="550")
  inspect(ltr_a.x_offset(), content="20")
  inspect(ltr_a.y_offset(), content="-10")
  inspect(ltr_b.glyph().value(), content="1")
  inspect(ltr_b.cluster(), content="1")
  inspect(ltr_b.advance(), content="500")
  inspect(ltr_b.x_offset(), content="-30")
  inspect(ltr_b.y_offset(), content="15")
  inspect(ltr.total_advance(), content="1050")
  inspect(ltr.units_per_em(), content="1000")
  inspect(ltr.direction() == Direction::LeftToRight, content="true")
  let one_past = ltr.glyph_at(2UL).unwrap_err()
  inspect(one_past.category() == @error.ErrorCategory::InvalidInput, content="true")
  inspect(one_past.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(one_past.operation() == Some("text-shaped-run-glyph-at"), content="true")
  inspect(one_past.requested() == Some(2UL), content="true")
  inspect(one_past.limit() == Some(2UL), content="true")
  inspect(one_past.context() == Some("run-index"), content="true")
  inspect(ltr_budget.remaining().work(), content="0")

  let (_rtl_owner, rtl_font) = text_wb_font()
  let rtl = generated_shape_contract(
    rtl_font,
    [0x41, 0x42],
    text_wb_options(Direction::RightToLeft),
    text_wb_limits(2UL, 2UL),
    text_wb_resource_budget(3UL),
    text_wb_ab_facts(rtl_font),
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(3UL),
  ).unwrap()
  let rtl_b = rtl.glyph_at(0UL).unwrap()
  let rtl_a = rtl.glyph_at(1UL).unwrap()
  inspect(rtl_b.glyph().value(), content="1")
  inspect(rtl_b.cluster(), content="1")
  inspect(rtl_b.advance(), content="-500")
  inspect(rtl_b.x_offset(), content="-30")
  inspect(rtl_b.y_offset(), content="15")
  inspect(rtl_a.glyph().value(), content="0")
  inspect(rtl_a.cluster(), content="0")
  inspect(rtl_a.advance(), content="-550")
  inspect(rtl_a.x_offset(), content="20")
  inspect(rtl_a.y_offset(), content="-10")
  inspect(rtl.total_advance(), content="-1050")
  inspect(rtl.direction() == Direction::RightToLeft, content="true")
}

///|
test "equal adjacent records stay distinct and ligatures keep minimum scalar cluster" {
  let (_owner, font) = text_wb_font()
  let equal = generated_shape_contract(
    font,
    [0x41, 0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(2UL, 2UL),
    text_wb_resource_budget(1UL),
    [
      generated_logical_glyph(font.glyph_id(0UL).unwrap(), [0UL], 1L, 0L, 0L, 0L),
      generated_logical_glyph(font.glyph_id(0UL).unwrap(), [1UL], 1L, 0L, 0L, 0L),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap()
  inspect(equal.len(), content="2")
  inspect(equal.glyph_at(0UL).unwrap().cluster(), content="0")
  inspect(equal.glyph_at(1UL).unwrap().cluster(), content="1")

  let (_lig_owner, lig_font) = text_wb_font()
  let ligature = generated_shape_contract(
    lig_font,
    [0x58, 0x66, 0x66, 0x69],
    text_wb_options(Direction::RightToLeft),
    text_wb_limits(4UL, 1UL),
    text_wb_resource_budget(1UL),
    [
      generated_logical_glyph(
        lig_font.glyph_id(1UL).unwrap(),
        [3UL, 1UL, 2UL],
        700L,
        0L,
        0L,
        0L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap()
  inspect(ligature.len(), content="1")
  inspect(ligature.glyph_at(0UL).unwrap().cluster(), content="1")
}

///|
test "run publication copies record storage before indexed access" {
  let (_owner, font) = text_wb_font()
  let records = [
    positioned_glyph(
      font.glyph_id(0UL).unwrap(),
      0UL,
      10L,
      20L,
      30L,
    ),
  ]
  let run = publish_shaped_run(
    records,
    1000UL,
    Direction::LeftToRight,
    10L,
  )
  records[0] = positioned_glyph(
    font.glyph_id(1UL).unwrap(),
    9UL,
    99L,
    99L,
    99L,
  )
  let published = run.glyph_at(0UL).unwrap()
  inspect(published.glyph().value(), content="0")
  inspect(published.cluster(), content="0")
  inspect(published.advance(), content="10")
  inspect(published.x_offset(), content="20")
  inspect(published.y_offset(), content="30")
}

///|
test "signed offset extremes remain unchanged through RTL projection" {
  let (_owner, font) = text_wb_font()
  let run = generated_shape_contract(
    font,
    [0x41],
    text_wb_options(Direction::RightToLeft),
    text_wb_limits(1UL, 1UL),
    text_wb_resource_budget(1UL),
    [
      generated_logical_glyph(
        font.glyph_id(0UL).unwrap(),
        [0UL],
        1L,
        0L,
        -9223372036854775807L - 1L,
        9223372036854775807L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap()
  let record = run.glyph_at(0UL).unwrap()
  inspect(record.advance(), content="-1")
  inspect(record.x_offset(), content="-9223372036854775808")
  inspect(record.y_offset(), content="9223372036854775807")
}

///|
test "generated exact charge commits once through every budget ancestor" {
  let (_owner, font) = text_wb_font()
  let parent = text_wb_resource_budget(2UL)
  let child = parent
    .child(
      @budget.ResourceLimits::new(
        bytes=0UL,
        allocations=0UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=2UL,
      ),
    )
    .unwrap()
  let run = generated_shape_contract(
    font,
    [0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    child,
    [
      generated_logical_glyph(
        font.glyph_id(0UL).unwrap(),
        [0UL],
        10L,
        0L,
        0L,
        0L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(2UL),
  ).unwrap()
  inspect(run.total_advance(), content="10")
  inspect(parent.remaining().work(), content="0")
  inspect(child.remaining().work(), content="0")
}

///|
test "generated scalar and output ceilings accept exact and reject one over" {
  let (_input_owner, input_font) = text_wb_font()
  let input_budget = text_wb_resource_budget(1UL)
  let input_error = generated_shape_contract(
    input_font,
    [0x41, 0x42],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 2UL),
    input_budget,
    text_wb_ab_facts(input_font),
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(input_error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(input_error.requested() == Some(2UL), content="true")
  inspect(input_error.limit() == Some(1UL), content="true")
  inspect(input_error.context() == Some("max-input-scalars"), content="true")
  inspect(input_budget.remaining().work(), content="1")

  let (_output_owner, output_font) = text_wb_font()
  let output_budget = text_wb_resource_budget(1UL)
  let output_error = generated_shape_contract(
    output_font,
    [0x41, 0x42],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(2UL, 1UL),
    output_budget,
    text_wb_ab_facts(output_font),
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(output_error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(output_error.requested() == Some(2UL), content="true")
  inspect(output_error.limit() == Some(1UL), content="true")
  inspect(output_error.context() == Some("max-output-glyphs"), content="true")
  inspect(output_budget.remaining().work(), content="1")
}

///|
test "generated projection rejects signed overflow before publication or charge" {
  let (_add_owner, add_font) = text_wb_font()
  let add_budget = text_wb_resource_budget(1UL)
  let add_error = generated_shape_contract(
    add_font,
    [0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    add_budget,
    [
      generated_logical_glyph(
        add_font.glyph_id(0UL).unwrap(),
        [0UL],
        9223372036854775807L,
        1L,
        0L,
        0L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(add_error.code() == @error.ErrorCode::ArithmeticOverflow, content="true")
  inspect(add_error.operation() == Some("text-shape-project"), content="true")
  inspect(add_error.context() == Some("advance"), content="true")
  inspect(add_budget.remaining().work(), content="1")

  let (_neg_owner, neg_font) = text_wb_font()
  let neg_error = generated_shape_contract(
    neg_font,
    [0x41],
    text_wb_options(Direction::RightToLeft),
    text_wb_limits(1UL, 1UL),
    text_wb_resource_budget(1UL),
    [
      generated_logical_glyph(
        neg_font.glyph_id(0UL).unwrap(),
        [0UL],
        -9223372036854775807L - 1L,
        0L,
        0L,
        0L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(neg_error.context() == Some("advance"), content="true")

  let (_sum_owner, sum_font) = text_wb_font()
  let sum_error = generated_shape_contract(
    sum_font,
    [0x41, 0x42],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(2UL, 2UL),
    text_wb_resource_budget(1UL),
    [
      generated_logical_glyph(
        sum_font.glyph_id(0UL).unwrap(),
        [0UL],
        9223372036854775807L,
        0L,
        0L,
        0L,
      ),
      generated_logical_glyph(
        sum_font.glyph_id(1UL).unwrap(),
        [1UL],
        1L,
        0L,
        0L,
        0L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(sum_error.context() == Some("total-advance"), content="true")
}

///|
test "generated stage precedence is input state data capability then resource" {
  let (invalid_owner, invalid_font) = text_wb_font()
  invalid_owner.with_mut(0UL, 1UL, fn(lease) {
    lease.set(0UL, b'\x01')
  }).unwrap()
  let invalid = generated_shape_contract(
    invalid_font,
    [-1],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    text_wb_resource_budget(0UL),
    [],
    structure_fault=true,
    capability_fault=true,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(invalid.category() == @error.ErrorCategory::InvalidInput, content="true")

  let (state_owner, state_font) = text_wb_font()
  state_owner.with_mut(0UL, 1UL, fn(lease) {
    lease.set(0UL, b'\x01')
  }).unwrap()
  let state = generated_shape_contract(
    state_font,
    [0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    text_wb_resource_budget(0UL),
    [],
    structure_fault=true,
    capability_fault=true,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(state.category() == @error.ErrorCategory::State, content="true")

  let (_data_owner, data_font) = text_wb_font()
  let data_budget = text_wb_resource_budget(0UL)
  let data = generated_shape_contract(
    data_font,
    [0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    data_budget,
    [],
    structure_fault=true,
    capability_fault=true,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(data.category() == @error.ErrorCategory::Data, content="true")
  inspect(data_budget.remaining().work(), content="0")

  let (_cap_owner, cap_font) = text_wb_font()
  let capability = generated_shape_contract(
    cap_font,
    [0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    text_wb_resource_budget(0UL),
    [],
    structure_fault=false,
    capability_fault=true,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(capability.category() == @error.ErrorCategory::Capability, content="true")

  let (_resource_owner, resource_font) = text_wb_font()
  let resource = generated_shape_contract(
    resource_font,
    [0x41],
    text_wb_options(Direction::LeftToRight),
    text_wb_limits(1UL, 1UL),
    text_wb_resource_budget(0UL),
    [
      generated_logical_glyph(
        resource_font.glyph_id(0UL).unwrap(),
        [0UL],
        1L,
        0L,
        0L,
        0L,
      ),
    ],
    structure_fault=false,
    capability_fault=false,
    generated_shape_noop_probes(),
    text_wb_charge(1UL),
  ).unwrap_err()
  inspect(resource.category() == @error.ErrorCategory::Resource, content="true")
}

///|
test "every generated mutation seam returns immediate state with zero charge" {
  for seam = 0; seam < 4; seam = seam + 1 {
    let (owner, font) = text_wb_font()
    let budget = text_wb_resource_budget(1UL)
    let mutate = fn() {
      owner.with_mut(0UL, 1UL, fn(lease) {
        lease.set(0UL, b'\x01')
      }).unwrap()
    }
    let noop = fn() { () }
    let probes = TextShapeContractProbes::{
      post_structure: if seam == 0 { mutate } else { noop },
      post_capability: if seam == 1 { mutate } else { noop },
      post_complete_staging: if seam == 2 { mutate } else { noop },
      before_return: if seam == 3 { mutate } else { noop },
    }
    let error = generated_shape_contract(
      font,
      [0x41],
      text_wb_options(Direction::LeftToRight),
      text_wb_limits(1UL, 1UL),
      budget,
      [
        generated_logical_glyph(
          font.glyph_id(0UL).unwrap(),
          [0UL],
          1L,
          0L,
          0L,
          0L,
        ),
      ],
      structure_fault=false,
      capability_fault=false,
      probes,
      text_wb_charge(1UL),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::State, content="true")
    inspect(
      error.context() == Some("font-source-revision-drift"),
      content="true",
    )
    inspect(budget.remaining().work(), content="1")
  }
}
