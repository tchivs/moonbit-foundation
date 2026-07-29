///|
#warnings("-1")
fn text_test_truncated_font_bytes() -> Bytes {
  let output = b"\x00\x01\x00\x00\x00\x0a\x00\x80\x00\x03\x00\x20\x4f\x53\x2f\x32\x00\x00\x00\x00\x00\x00\x00\xac\x00\x00\x00\x4e\x63\x6d\x61\x70\x00\x0c\x00\x26\x00\x00\x00\xfc\x00\x00\x00\x24\x67\x6c\x79\x66\x00\x00\x00\x00\x00\x00\x01\x20\x00\x00\x00\x00\x68\x65\x61\x64\x5f\x13\x40\xe5\x00\x00\x01\x20\x00\x00\x00\x36\x68\x68\x65\x61\x00\x01\x00\x01\x00\x00\x01\x58\x00\x00\x00\x24\x68\x6d\x74\x78\x01\xf4\x00\x00\x00\x00\x01\x7c\x00\x00\x00\x04\x6c\x6f\x63\x61\x00\x00\x00\x00\x00\x00\x01\x80\x00\x00\x00\x04\x6d\x61\x78\x70\x00\x32\x00\xc1\x00\x00\x01\x84\x00\x00\x00\x20\x6e\x61\x6d\x65\x00\x06\x00\x00\x00\x00\x01\xa4\x00\x00\x00\x06\x70\x6f\x73\x74\x00\x03\x00\x00\x00\x00\x01\xac\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x03\x00\x01\x00\x00\x00\x0c\x00\x04\x00\x18\x00\x00\x00\x02\x00\x02\x00\x00\x00\x00\xff\xff\x00\x00\xff\xff\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\xe2\xfa\x1b\x67\x5f\x0f\x3c\xf5\x00\x00\x03\xe8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x02\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\xf4\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x40\x00\x10\x00\x40\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x10\x00\x01\x00\x00\x00\x00\x00\x06\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00".to_array()
  for _index = 0; _index < 9; _index = _index + 1 {
    output.push(b'\x00')
  }
  Bytes::from_array(output)
}

///|
struct TextTestTable {
  tag : Bytes
  payload : Bytes
}

///|
fn text_test_push_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn text_test_push_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn text_test_put_u16(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn text_test_put_u32(
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
fn text_test_checksum(source : Bytes) -> UInt64 {
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
    let word = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    checksum = (checksum + word) & 0xFFFFFFFFUL
    offset = offset + 4
  }
  checksum
}

///|
fn text_test_head_table() -> Bytes {
  let output : Array[Byte] = []
  text_test_push_u32(output, 0x00010000UL)
  text_test_push_u32(output, 0x00010000UL)
  text_test_push_u32(output, 0UL)
  text_test_push_u32(output, 0x5F0F3CF5UL)
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 1000UL)
  for _index = 0; _index < 24; _index = _index + 1 {
    output.push(b'\x00')
  }
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 8UL)
  text_test_push_u16(output, 2UL)
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn text_test_cmap_table() -> Bytes {
  let output : Array[Byte] = []
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 1UL)
  text_test_push_u16(output, 3UL)
  text_test_push_u16(output, 1UL)
  text_test_push_u32(output, 12UL)
  text_test_push_u16(output, 4UL)
  text_test_push_u16(output, 24UL)
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 2UL)
  text_test_push_u16(output, 2UL)
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 0xFFFFUL)
  text_test_push_u16(output, 0UL)
  text_test_push_u16(output, 0xFFFFUL)
  text_test_push_u16(output, 1UL)
  text_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn text_test_hhea_table() -> Bytes {
  let output = Array::make(36, b'\x00')
  text_test_put_u32(output, 0, 0x00010000UL)
  text_test_put_u32(output, 32, 1UL)
  output[34] = b'\x00'
  output[35] = b'\x01'
  Bytes::from_array(output)
}

///|
fn text_test_maxp_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  text_test_put_u32(output, 0, 0x00010000UL)
  text_test_put_u16(output, 4, 1UL)
  text_test_put_u16(output, 6, 64UL)
  text_test_put_u16(output, 8, 16UL)
  text_test_put_u16(output, 10, 64UL)
  text_test_put_u16(output, 12, 16UL)
  text_test_put_u16(output, 26, 64UL)
  text_test_put_u16(output, 28, 16UL)
  text_test_put_u16(output, 30, 1UL)
  Bytes::from_array(output)
}

///|
fn text_test_post_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  text_test_put_u32(output, 0, 0x00030000UL)
  Bytes::from_array(output)
}

///|
fn text_test_search_facts(num_tables : UInt64) -> (UInt64, UInt64, UInt64) {
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
fn text_test_build_truetype(tables : Array[TextTestTable]) -> Bytes {
  let output : Array[Byte] = []
  let num_tables = tables.length().to_uint64()
  let (search_range, selector, range_shift) = text_test_search_facts(num_tables)
  text_test_push_u32(output, 0x00010000UL)
  text_test_push_u16(output, num_tables)
  text_test_push_u16(output, search_range)
  text_test_push_u16(output, selector)
  text_test_push_u16(output, range_shift)
  let mut next_offset = 12UL + num_tables * 16UL
  let offsets : Array[UInt64] = []
  for table in tables {
    for byte in table.tag {
      output.push(byte)
    }
    text_test_push_u32(output, text_test_checksum(table.payload))
    text_test_push_u32(output, next_offset)
    text_test_push_u32(output, table.payload.length().to_uint64())
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
      0xB1B0AFBAUL - text_test_checksum(Bytes::from_array(output.copy()))
    ) &
    0xFFFFFFFFUL
  text_test_put_u32(output, offsets[3].to_int() + 8, adjustment)
  Bytes::from_array(output)
}

///|
fn text_test_font_bytes() -> Bytes {
  text_test_build_truetype([
    { tag: b"OS/2", payload: Bytes::from_array(Array::make(78, b'\x00')) },
    { tag: b"cmap", payload: text_test_cmap_table() },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: text_test_head_table() },
    { tag: b"hhea", payload: text_test_hhea_table() },
    { tag: b"hmtx", payload: b"\x01\xf4\x00\x00" },
    { tag: b"loca", payload: b"\x00\x00\x00\x00" },
    { tag: b"maxp", payload: text_test_maxp_table() },
    { tag: b"name", payload: b"\x00\x00\x00\x00\x00\x06" },
    { tag: b"post", payload: text_test_post_table() },
  ])
}

///|
fn text_test_font_limits() -> @font.FontLimits {
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
fn text_test_budget(work : UInt64) -> @budget.Budget {
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
fn text_test_font() -> (@bytes.OwnedBytes, @font.Font) {
  let source = text_test_font_bytes()
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
    text_test_font_limits(),
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
fn text_test_options(direction : Direction) -> ShapingOptions {
  ShapingOptions::new(
    ScriptTag::new(b"latn").unwrap(),
    LanguageChoice::Default,
    direction,
    FeaturePolicy::new(liga=true, kern=true),
  )
}

///|
fn text_test_limits() -> ShapeLimits {
  ShapeLimits::new(max_input_scalars=16UL, max_output_glyphs=16UL).unwrap()
}

///|
test "shape limits preserve exact values and reject input zero first" {
  let limits = ShapeLimits::new(max_input_scalars=7UL, max_output_glyphs=9UL).unwrap()
  inspect(limits.max_input_scalars(), content="7")
  inspect(limits.max_output_glyphs(), content="9")
  let input = ShapeLimits::new(max_input_scalars=0UL, max_output_glyphs=0UL).unwrap_err()
  inspect(
    input.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(input.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(input.operation() == Some("text-shape-limits-new"), content="true")
  inspect(input.context() == Some("max-input-scalars"), content="true")
  let output = ShapeLimits::new(max_input_scalars=1UL, max_output_glyphs=0UL).unwrap_err()
  inspect(output.context() == Some("max-output-glyphs"), content="true")
}

///|
test "tags language direction and feature policy remain closed and explicit" {
  let script = ScriptTag::new(b"latn").unwrap()
  let language = LanguageTag::new(b"ENG ").unwrap()
  inspect(script.bytes() == b"latn", content="true")
  inspect(language.bytes() == b"ENG ", content="true")
  inspect(ScriptTag::new(b"lat") is Err(_), content="true")
  inspect(ScriptTag::new(b"la\x00n") is Err(_), content="true")
  inspect(LanguageTag::new(b"dflt") is Err(_), content="true")
  inspect(LanguageTag::new(b"DFLT") is Err(_), content="true")
  let features = FeaturePolicy::new(liga=false, kern=true)
  inspect(features.liga(), content="false")
  inspect(features.kern(), content="true")
  let options = ShapingOptions::new(
    script,
    LanguageChoice::Exact(language),
    Direction::RightToLeft,
    features,
  )
  inspect(options.script().bytes() == b"latn", content="true")
  inspect(options.language() == LanguageChoice::Exact(language), content="true")
  inspect(options.direction() == Direction::RightToLeft, content="true")
  inspect(options.features().kern(), content="true")
}

///|
test "empty shape traverses one transaction and charges work exactly once" {
  let (_owner, font) = text_test_font()
  let parent = text_test_budget(1UL)
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
        work=1UL,
      ),
    )
    .unwrap()
  let run = shape(
    font,
    [],
    text_test_options(Direction::LeftToRight),
    text_test_limits(),
    child,
  ).unwrap()
  inspect(run.len(), content="0")
  inspect(run.units_per_em(), content="1000")
  inspect(run.direction() == Direction::LeftToRight, content="true")
  inspect(run.total_advance(), content="0")
  inspect(run.glyph_at(0UL) is Err(_), content="true")
  inspect(parent.remaining().work(), content="0")
  inspect(child.remaining().work(), content="0")
}

///|
test "empty shape one-short and revision failures publish nothing and charge nothing" {
  let (_owner, font) = text_test_font()
  let empty = text_test_budget(0UL)
  let budget_error = shape(
    font,
    [],
    text_test_options(Direction::RightToLeft),
    text_test_limits(),
    empty,
  ).unwrap_err()
  inspect(
    budget_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    budget_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(empty.remaining().work(), content="0")

  let (drift_owner, drift_font) = text_test_font()
  drift_owner.with_mut(0UL, 1UL, fn(lease) { lease.set(0UL, b'\x01') }).unwrap()
  let exact = text_test_budget(1UL)
  let state_error = shape(
    drift_font,
    [],
    text_test_options(Direction::LeftToRight),
    text_test_limits(),
    exact,
  ).unwrap_err()
  inspect(state_error.category() == @error.ErrorCategory::State, content="true")
  inspect(
    state_error.context() == Some("font-source-revision-drift"),
    content="true",
  )
  inspect(exact.remaining().work(), content="1")
}

///|
test "caller invalid input wins drift and nonempty requests fail closed" {
  let (owner, font) = text_test_font()
  owner.with_mut(0UL, 1UL, fn(lease) { lease.set(0UL, b'\x01') }).unwrap()
  let invalid_budget = text_test_budget(1UL)
  let invalid = shape(
    font,
    [-1],
    text_test_options(Direction::LeftToRight),
    text_test_limits(),
    invalid_budget,
  ).unwrap_err()
  inspect(
    invalid.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(invalid.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(invalid.operation() == Some("text-shape"), content="true")
  inspect(invalid.context() == Some("unicode-scalar"), content="true")
  inspect(invalid_budget.remaining().work(), content="1")

  let (_owner, valid_font) = text_test_font()
  let nonempty_budget = text_test_budget(1UL)
  let capability = shape(
    valid_font,
    [0x41],
    text_test_options(Direction::LeftToRight),
    text_test_limits(),
    nonempty_budget,
  ).unwrap_err()
  inspect(
    capability.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    capability.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(capability.operation() == Some("text-shape"), content="true")
  inspect(capability.context() == Some("layout-unavailable"), content="true")
  inspect(nonempty_budget.remaining().work(), content="1")
}
