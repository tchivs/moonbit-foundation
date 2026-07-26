///|
fn assert_invalid_font_limit(
  result : Result[FontLimits, @error.CoreError],
  context : String,
) -> Unit raise {
  let error = result.unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-limits-new"), content="true")
  inspect(error.requested() == Some(0UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
test "font limits preserve every explicit semantic ceiling" {
  let limits = FontLimits::new(
    max_source_bytes=1024UL,
    max_tables=10UL,
    max_table_bytes=256UL,
    max_glyphs=4UL,
    max_name_records=3UL,
    max_cmap_records=2UL,
    max_post_name_bytes=64UL,
    max_work=4096UL,
  ).unwrap()
  inspect(limits.max_source_bytes(), content="1024")
  inspect(limits.max_tables(), content="10")
  inspect(limits.max_table_bytes(), content="256")
  inspect(limits.max_glyphs(), content="4")
  inspect(limits.max_name_records(), content="3")
  inspect(limits.max_cmap_records(), content="2")
  inspect(limits.max_post_name_bytes(), content="64")
  inspect(limits.max_work(), content="4096")
}

///|
test "font limits reject every zero semantic ceiling" {
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=0UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-source-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=0UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-tables",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=0UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-table-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=0UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-glyphs",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=0UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-name-records",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=0UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-cmap-records",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=0UL,
      max_work=1UL,
    ),
    "max-post-name-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=0UL,
    ),
    "max-work",
  )
}

///|
struct FontTestTable {
  tag : Bytes
  payload : Bytes
}

///|
fn font_test_push_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_test_push_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_test_put_u32(
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
fn font_test_put_u16(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn font_test_put_i16(
  output : Array[Byte],
  offset : Int,
  value : Int,
) -> Unit {
  let encoded = if value < 0 {
    (value + 0x10000).to_uint64()
  } else {
    value.to_uint64()
  }
  font_test_put_u16(output, offset, encoded)
}

///|
fn font_test_checksum(source : Bytes) -> UInt64 {
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
fn font_test_head_table() -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u32(output, 0UL)
  font_test_push_u32(output, 0x5F0F3CF5UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1000UL)
  for index = 0; index < 16; index = index + 1 {
    output.push(b'\x00')
  }
  for index = 0; index < 8; index = index + 1 {
    output.push(b'\x00')
  }
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 8UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_test_cmap_table() -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u32(output, 12UL)
  font_test_push_u16(output, 4UL)
  font_test_push_u16(output, 24UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0xFFFFUL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0xFFFFUL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_test_fixed_table(length : Int) -> Bytes {
  Bytes::from_array(Array::make(length, b'\x00'))
}

///|
fn font_test_hhea_table() -> Bytes {
  let output = Array::make(36, b'\x00')
  font_test_put_u32(output, 0, 0x00010000UL)
  font_test_put_u32(output, 32, 1UL)
  output[34] = b'\x00'
  output[35] = b'\x01'
  Bytes::from_array(output)
}

///|
fn font_test_maxp_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  font_test_put_u32(output, 0, 0x00010000UL)
  output[4] = b'\x00'
  output[5] = b'\x01'
  Bytes::from_array(output)
}

///|
fn font_test_name_table() -> Bytes {
  b"\x00\x00\x00\x00\x00\x06"
}

///|
fn font_test_post_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  font_test_put_u32(output, 0, 0x00030000UL)
  Bytes::from_array(output)
}

///|
fn font_test_build_truetype(tables : Array[FontTestTable]) -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u16(output, tables.length().to_uint64())
  font_test_push_u16(output, 128UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 32UL)
  let mut next_offset = 12UL + tables.length().to_uint64() * 16UL
  let offsets : Array[UInt64] = []
  for table in tables {
    for byte in table.tag {
      output.push(byte)
    }
    font_test_push_u32(output, font_test_checksum(table.payload))
    font_test_push_u32(output, next_offset)
    font_test_push_u32(output, table.payload.length().to_uint64())
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
  let zero_adjustment = Bytes::from_array(output.copy())
  let adjustment = (0xB1B0AFBAUL - font_test_checksum(zero_adjustment)) &
    0xFFFFFFFFUL
  font_test_put_u32(output, offsets[3].to_int() + 8, adjustment)
  Bytes::from_array(output)
}

///|
fn font_test_minimal_truetype() -> Bytes {
  font_test_build_truetype([
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: font_test_cmap_table() },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: font_test_head_table() },
    { tag: b"hhea", payload: font_test_hhea_table() },
    { tag: b"hmtx", payload: b"\x01\xf4\x00\x00" },
    { tag: b"loca", payload: b"\x00\x00\x00\x00" },
    { tag: b"maxp", payload: font_test_maxp_table() },
    { tag: b"name", payload: font_test_name_table() },
    { tag: b"post", payload: font_test_post_table() },
  ])
}

///|
fn font_test_metric_head_table() -> Bytes {
  let output = font_test_head_table().to_array()
  font_test_put_i16(output, 50, 0)
  Bytes::from_array(output)
}

///|
fn font_test_metric_hhea_table() -> Bytes {
  let output = font_test_hhea_table().to_array()
  font_test_put_u16(output, 34, 2UL)
  Bytes::from_array(output)
}

///|
fn font_test_metric_maxp_table() -> Bytes {
  let output = font_test_maxp_table().to_array()
  font_test_put_u16(output, 4, 3UL)
  Bytes::from_array(output)
}

///|
fn font_test_metric_glyf_table() -> Bytes {
  let output : Array[Byte] = []
  for value in [1, -10, -20, 100, 200, 1, 5, -6, 55, 70] {
    let encoded = if value < 0 {
      (value + 0x10000).to_uint64()
    } else {
      value.to_uint64()
    }
    font_test_push_u16(output, encoded)
  }
  Bytes::from_array(output)
}

///|
fn font_test_horizontal_metric_truetype() -> Bytes {
  font_test_build_truetype([
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: font_test_cmap_table() },
    { tag: b"glyf", payload: font_test_metric_glyf_table() },
    { tag: b"head", payload: font_test_metric_head_table() },
    { tag: b"hhea", payload: font_test_metric_hhea_table() },
    {
      tag: b"hmtx",
      payload: b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8",
    },
    { tag: b"loca", payload: b"\x00\x00\x00\x05\x00\x05\x00\x0a" },
    { tag: b"maxp", payload: font_test_metric_maxp_table() },
    { tag: b"name", payload: font_test_name_table() },
    { tag: b"post", payload: font_test_post_table() },
  ])
}

///|
fn font_test_owner(source : Bytes) -> @bytes.OwnedBytes {
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
fn font_test_limits() -> FontLimits {
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
fn font_test_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
test "generated standalone TrueType opens and returns exact units per em" {
  let owner = font_test_owner(font_test_minimal_truetype())
  let budget = font_test_budget()
  let font = Font::open(owner.view(), font_test_limits(), budget).unwrap()
  let after_open = budget.remaining()
  inspect(font.units_per_em().unwrap(), content="1000")
  inspect(font.units_per_em().unwrap(), content="1000")
  let after_queries = budget.remaining()
  inspect(after_queries.bytes() == after_open.bytes(), content="true")
  inspect(after_queries.work() == after_open.work(), content="true")
}

///|
test "unsupported outline signature publishes no Font" {
  let owner = font_test_owner(font_test_minimal_truetype())
  owner.with_mut(
    0UL,
    4UL,
    fn(lease) {
      match lease.set(0UL, b'O') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match lease.set(1UL, b'T') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match lease.set(2UL, b'T') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match lease.set(3UL, b'O') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      Ok(())
    },
  ).unwrap()
  let error = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    error.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(error.operation() == Some("font-open"), content="true")
  inspect(error.context() == Some("font-outline-profile"), content="true")
}

///|
fn font_test_mutate_bytes(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  replacement : Bytes,
) -> Unit {
  owner.with_mut(
    offset,
    replacement.length().to_uint64(),
    fn(lease) {
      let mut index = 0UL
      while index < replacement.length().to_uint64() {
        match lease.set(index, replacement[index.to_int()]) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + 1UL
      }
      Ok(())
    },
  ).unwrap()
}

///|
fn font_test_mutate_u32(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  value : UInt64,
) -> Unit {
  let replacement : Array[Byte] = []
  font_test_push_u32(replacement, value)
  font_test_mutate_bytes(owner, offset, Bytes::from_array(replacement))
}

///|
fn font_test_mutate_u16(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  value : UInt64,
) -> Unit {
  let replacement : Array[Byte] = []
  font_test_push_u16(replacement, value)
  font_test_mutate_bytes(owner, offset, Bytes::from_array(replacement))
}

///|
fn font_test_view_bytes(source : @bytes.ByteView) -> Bytes {
  let output : Array[Byte] = []
  let mut offset = 0UL
  while offset < source.length() {
    output.push(source.get(offset).unwrap())
    offset = offset + 1UL
  }
  Bytes::from_array(output)
}

///|
fn font_test_recompute_adjustment(
  owner : @bytes.OwnedBytes,
) -> Unit {
  font_test_mutate_u32(owner, 296UL, 0UL)
  let adjustment = (
    0xB1B0AFBAUL - font_test_checksum(font_test_view_bytes(owner.view()))
  ) &
    0xFFFFFFFFUL
  font_test_mutate_u32(owner, 296UL, adjustment)
}

///|
fn font_test_distinct_global_metrics() -> @bytes.OwnedBytes {
  let owner = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_u16(owner, 324UL, 0xFF88UL)
  font_test_mutate_u16(owner, 326UL, 0xFF10UL)
  font_test_mutate_u16(owner, 328UL, 700UL)
  font_test_mutate_u16(owner, 330UL, 900UL)
  font_test_mutate_u16(owner, 348UL, 800UL)
  font_test_mutate_u16(owner, 350UL, 0xFF38UL)
  font_test_mutate_u16(owner, 352UL, 90UL)
  font_test_mutate_u16(owner, 240UL, 760UL)
  font_test_mutate_u16(owner, 242UL, 0xFF10UL)
  font_test_mutate_u16(owner, 244UL, 40UL)
  font_test_mutate_u32(owner, 296UL, 0UL)
  let os2 = owner.view().subview(172UL, 78UL).unwrap()
  font_test_mutate_u32(
    owner,
    16UL,
    font_test_checksum(font_test_view_bytes(os2)),
  )
  let head = owner.view().subview(288UL, 54UL).unwrap()
  font_test_mutate_u32(
    owner,
    64UL,
    font_test_checksum(font_test_view_bytes(head)),
  )
  let hhea = owner.view().subview(344UL, 36UL).unwrap()
  font_test_mutate_u32(
    owner,
    80UL,
    font_test_checksum(font_test_view_bytes(hhea)),
  )
  font_test_recompute_adjustment(owner)
  owner
}

///|
fn font_test_assert_revision_drift(error : @error.CoreError) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-query"), content="true")
  inspect(
    error.context() == Some("font-source-revision-drift"),
    content="true",
  )
}

///|
test "font publishes separate exact global metric sources" {
  let owner = font_test_distinct_global_metrics()
  let font = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  inspect(font.units_per_em().unwrap(), content="1000")
  let bounds = font.global_bounds().unwrap()
  inspect(bounds.x_min(), content="-120")
  inspect(bounds.y_min(), content="-240")
  inspect(bounds.x_max(), content="700")
  inspect(bounds.y_max(), content="900")
  let hhea = font.hhea_line_metrics().unwrap()
  inspect(hhea.ascent(), content="800")
  inspect(hhea.descent(), content="-200")
  inspect(hhea.line_gap(), content="90")
  let typographic = font.typographic_line_metrics().unwrap()
  inspect(typographic.ascent(), content="760")
  inspect(typographic.descent(), content="-240")
  inspect(typographic.line_gap(), content="40")
  inspect(hhea.ascent() != typographic.ascent(), content="true")
  inspect(hhea.descent() != typographic.descent(), content="true")
  inspect(hhea.line_gap() != typographic.line_gap(), content="true")
}

///|
test "font publishes opaque direct tail and empty horizontal metrics" {
  let owner = font_test_owner(font_test_horizontal_metric_truetype())
  let font = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let glyph0 = font.glyph_id(0UL).unwrap()
  let glyph1 = font.glyph_id(1UL).unwrap()
  let glyph2 = font.glyph_id(2UL).unwrap()
  inspect(glyph0.value(), content="0")
  inspect(glyph2.value(), content="2")

  let direct = font.horizontal_metrics(glyph0).unwrap()
  inspect(direct.advance_width(), content="500")
  inspect(direct.left_side_bearing(), content="-20")
  let direct_bounds = direct.bounds().unwrap()
  inspect(direct_bounds.x_min(), content="-10")
  inspect(direct_bounds.y_min(), content="-20")
  inspect(direct_bounds.x_max(), content="100")
  inspect(direct_bounds.y_max(), content="200")
  inspect(direct.right_side_bearing(), content="410")

  let empty = font.horizontal_metrics(glyph1).unwrap()
  inspect(empty.advance_width(), content="600")
  inspect(empty.left_side_bearing(), content="30")
  inspect(empty.bounds() is None, content="true")
  inspect(empty.right_side_bearing(), content="570")

  let tail = font.horizontal_metrics(glyph2).unwrap()
  inspect(tail.advance_width(), content="600")
  inspect(tail.left_side_bearing(), content="-40")
  let tail_bounds = tail.bounds().unwrap()
  inspect(tail_bounds.x_min(), content="5")
  inspect(tail_bounds.y_min(), content="-6")
  inspect(tail_bounds.x_max(), content="55")
  inspect(tail_bounds.y_max(), content="70")
  inspect(tail.right_side_bearing(), content="590")
}

///|
test "glyph IDs are range checked by construction and receiving Font" {
  let large_owner = font_test_owner(font_test_horizontal_metric_truetype())
  let large = Font::open(
    large_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let boundary = large.glyph_id(3UL).unwrap_err()
  inspect(boundary.category() == @error.ErrorCategory::InvalidInput, content="true")
  inspect(boundary.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(boundary.operation() == Some("font-glyph-id"), content="true")
  inspect(boundary.requested() == Some(3UL), content="true")
  inspect(boundary.limit() == Some(3UL), content="true")
  inspect(boundary.context() == Some("font-glyph-id-range"), content="true")

  let glyph = large.glyph_id(2UL).unwrap()
  let small_owner = font_test_owner(font_test_minimal_truetype())
  let small = Font::open(
    small_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let receiving = small.horizontal_metrics(glyph).unwrap_err()
  inspect(
    receiving.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(receiving.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    receiving.operation() == Some("font-horizontal-metrics"),
    content="true",
  )
  inspect(receiving.requested() == Some(2UL), content="true")
  inspect(receiving.limit() == Some(1UL), content="true")
  inspect(
    receiving.context() == Some("font-glyph-id-range"),
    content="true",
  )
}

///|
test "horizontal metric queries are repeatable and order independent" {
  let owner = font_test_owner(font_test_horizontal_metric_truetype())
  let font = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let glyph0 = font.glyph_id(0UL).unwrap()
  let glyph2 = font.glyph_id(2UL).unwrap()
  let tail_first = font.horizontal_metrics(glyph2).unwrap()
  let direct = font.horizontal_metrics(glyph0).unwrap()
  let tail_second = font.horizontal_metrics(glyph2).unwrap()
  inspect(tail_first.advance_width(), content="600")
  inspect(direct.advance_width(), content="500")
  inspect(tail_second.advance_width(), content="600")
  inspect(tail_first.left_side_bearing(), content="-40")
  inspect(tail_second.left_side_bearing(), content="-40")
  inspect(tail_first.right_side_bearing(), content="590")
  inspect(tail_second.right_side_bearing(), content="590")
}

///|
test "every cached global metric rejects retained source revision drift" {
  let owner = font_test_distinct_global_metrics()
  let font = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(owner, 431UL, b"\x01")
  font_test_assert_revision_drift(font.units_per_em().unwrap_err())
  font_test_assert_revision_drift(font.global_bounds().unwrap_err())
  font_test_assert_revision_drift(font.hhea_line_metrics().unwrap_err())
  font_test_assert_revision_drift(
    font.typographic_line_metrics().unwrap_err(),
  )
}

///|
test "required unrelated and mutate-back source changes invalidate every query" {
  let required_owner = font_test_owner(font_test_minimal_truetype())
  let required_font = Font::open(
    required_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(required_owner, 306UL, b"\x04")
  font_test_assert_revision_drift(required_font.units_per_em().unwrap_err())
  font_test_assert_revision_drift(required_font.units_per_em().unwrap_err())

  let unrelated_owner = font_test_owner(font_test_minimal_truetype())
  let unrelated_font = Font::open(
    unrelated_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(unrelated_owner, 431UL, b"\x01")
  font_test_assert_revision_drift(unrelated_font.units_per_em().unwrap_err())

  let restored_owner = font_test_owner(font_test_minimal_truetype())
  let original = restored_owner.view().get(306UL).unwrap()
  let restored_font = Font::open(
    restored_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(restored_owner, 306UL, b"\x04")
  font_test_mutate_bytes(restored_owner, 306UL, Bytes::from_array([original]))
  font_test_assert_revision_drift(restored_font.units_per_em().unwrap_err())
}

///|
test "directory table escape and missing head publish no Font" {
  let escaped = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_u32(escaped, 68UL, 0xFFFFFFFCUL)
  let range_error = Font::open(
    escaped.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(range_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(range_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(range_error.operation() == Some("font-open"), content="true")
  inspect(range_error.context() == Some("font-table-range"), content="true")

  let missing = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_bytes(missing, 60UL, b"heaf")
  let missing_error = Font::open(
    missing.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(missing_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(missing_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(missing_error.operation() == Some("font-open"), content="true")
  inspect(
    missing_error.context() == Some("font-required-table"),
    content="true",
  )
}

///|
test "head length magic and font adjustment fail at stable semantic gates" {
  let short_head = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_u32(short_head, 64UL, 0UL)
  font_test_mutate_u32(short_head, 72UL, 0UL)
  font_test_recompute_adjustment(short_head)
  let length_error = Font::open(
    short_head.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(length_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(length_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(length_error.context() == Some("font-head-length"), content="true")

  let bad_magic = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_bytes(bad_magic, 300UL, b"\x00")
  font_test_mutate_u32(bad_magic, 296UL, 0UL)
  let head = bad_magic.view().subview(288UL, 54UL).unwrap()
  font_test_mutate_u32(
    bad_magic,
    64UL,
    font_test_checksum(font_test_view_bytes(head)),
  )
  font_test_recompute_adjustment(bad_magic)
  let magic_error = Font::open(
    bad_magic.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(magic_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(magic_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(magic_error.context() == Some("font-head-magic"), content="true")

  let bad_adjustment = font_test_owner(font_test_minimal_truetype())
  let original_adjustment_byte = bad_adjustment.view().get(296UL).unwrap()
  font_test_mutate_bytes(
    bad_adjustment,
    296UL,
    Bytes::from_array([(original_adjustment_byte.to_uint64() ^ 1UL).to_byte()]),
  )
  let adjustment_error = Font::open(
    bad_adjustment.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    adjustment_error.category() == @error.ErrorCategory::Data,
    content="true",
  )
  inspect(
    adjustment_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(
    adjustment_error.context() == Some("font-checksum-adjustment"),
    content="true",
  )
}

///|
test "semantic source ceiling and atomic budget charge reject before publication" {
  let source = font_test_minimal_truetype()
  let length = source.length().to_uint64()
  let semantic_budget = font_test_budget()
  let semantic_before = semantic_budget.remaining()
  let semantic_limits = FontLimits::new(
    max_source_bytes=length - 1UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
  let semantic_error = Font::open(
    font_test_owner(source).view(),
    semantic_limits,
    semantic_budget,
  ).unwrap_err()
  inspect(
    semantic_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    semantic_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(
    semantic_error.context() == Some("max-source-bytes"),
    content="true",
  )
  let semantic_after = semantic_budget.remaining()
  inspect(semantic_after.bytes() == semantic_before.bytes(), content="true")
  inspect(semantic_after.work() == semantic_before.work(), content="true")

  let narrow_budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=length - 1UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
  let narrow_before = narrow_budget.remaining()
  let budget_error = Font::open(
    font_test_owner(source).view(),
    font_test_limits(),
    narrow_budget,
  ).unwrap_err()
  inspect(
    budget_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    budget_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(budget_error.operation() == Some("budget_charge"), content="true")
  inspect(budget_error.context() == Some("bytes"), content="true")
  let narrow_after = narrow_budget.remaining()
  inspect(narrow_after.bytes() == narrow_before.bytes(), content="true")
  inspect(narrow_after.work() == narrow_before.work(), content="true")
}

///|
test "unsupported containers outlines variations color and bitmap profiles are capabilities" {
  for signature in [b"ttcf", b"wOFF", b"wOF2", b"OTTO"] {
    let owner = font_test_owner(font_test_minimal_truetype())
    font_test_mutate_bytes(owner, 0UL, signature)
    let error = Font::open(
      owner.view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Capability, content="true")
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(error.context() == Some("font-outline-profile"), content="true")
  }
  for tag in [b"CFF ", b"CFF2", b"fvar", b"COLR", b"CBDT", b"sbix"] {
    let owner = font_test_owner(font_test_minimal_truetype())
    font_test_mutate_bytes(owner, 44UL, tag)
    let error = Font::open(
      owner.view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Capability, content="true")
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(
      error.context() == Some("font-unsupported-profile"),
      content="true",
    )
  }
}
