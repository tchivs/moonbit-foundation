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
fn font_test_put_i16(output : Array[Byte], offset : Int, value : Int) -> Unit {
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
fn font_test_cmap_format4_two_segments() -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u32(output, 12UL)
  font_test_push_u16(output, 4UL)
  font_test_push_u16(output, 34UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 4UL)
  font_test_push_u16(output, 4UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0x0041UL)
  font_test_push_u16(output, 0xFFFFUL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0x0041UL)
  font_test_push_u16(output, 0xFFFFUL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 4UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_test_cmap_format12(groups : Array[(UInt64, UInt64, UInt64)]) -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 10UL)
  font_test_push_u32(output, 12UL)
  font_test_push_u16(output, 12UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u32(output, 16UL + groups.length().to_uint64() * 12UL)
  font_test_push_u32(output, 0UL)
  font_test_push_u32(output, groups.length().to_uint64())
  for group in groups {
    let (start_code, end_code, start_glyph) = group
    font_test_push_u32(output, start_code)
    font_test_push_u32(output, end_code)
    font_test_push_u32(output, start_glyph)
  }
  Bytes::from_array(output)
}

///|
fn font_test_cmap_shared_format4_records(
  first_platform : UInt64,
  first_encoding : UInt64,
  second_platform : UInt64,
  second_encoding : UInt64,
) -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, first_platform)
  font_test_push_u16(output, first_encoding)
  font_test_push_u32(output, 20UL)
  font_test_push_u16(output, second_platform)
  font_test_push_u16(output, second_encoding)
  font_test_push_u32(output, 20UL)
  let format4 = font_test_cmap_table()
  for index = 12; index < format4.length(); index = index + 1 {
    output.push(format4[index])
  }
  Bytes::from_array(output)
}

///|
fn font_test_cmap_shared_format4_two_segments() -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u32(output, 20UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u32(output, 20UL)
  let format4 = font_test_cmap_format4_two_segments()
  for index = 12; index < format4.length(); index = index + 1 {
    output.push(format4[index])
  }
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
fn font_test_maxp_table_with_glyphs(glyph_count : UInt64) -> Bytes {
  let output = font_test_maxp_table().to_array()
  font_test_put_u16(output, 4, glyph_count)
  Bytes::from_array(output)
}

///|
fn font_test_name_table() -> Bytes {
  b"\x00\x00\x00\x00\x00\x06"
}

///|
fn font_test_name_table_with_keys(
  keys : Array[(UInt64, UInt64, UInt64, UInt64)],
) -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, keys.length().to_uint64())
  font_test_push_u16(output, 6UL + keys.length().to_uint64() * 12UL)
  let mut string_offset = 0UL
  for key in keys {
    let (platform, encoding, language, name) = key
    font_test_push_u16(output, platform)
    font_test_push_u16(output, encoding)
    font_test_push_u16(output, language)
    font_test_push_u16(output, name)
    font_test_push_u16(output, 1UL)
    font_test_push_u16(output, string_offset)
    string_offset = string_offset + 1UL
  }
  for _key in keys {
    output.push(b'A')
  }
  Bytes::from_array(output)
}

///|
fn font_test_post_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  font_test_put_u32(output, 0, 0x00030000UL)
  Bytes::from_array(output)
}

///|
fn font_test_search_facts(num_tables : UInt64) -> (UInt64, UInt64, UInt64) {
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
fn font_test_build_truetype(tables : Array[FontTestTable]) -> Bytes {
  let output : Array[Byte] = []
  let num_tables = tables.length().to_uint64()
  let (search_range, selector, range_shift) = font_test_search_facts(num_tables)
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u16(output, num_tables)
  font_test_push_u16(output, search_range)
  font_test_push_u16(output, selector)
  font_test_push_u16(output, range_shift)
  let mut next_offset = 12UL + num_tables * 16UL
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
fn font_test_truetype_with_cmap(cmap : Bytes) -> Bytes {
  font_test_build_truetype([
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: cmap },
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
fn font_test_truetype_with_cmap_and_glyphs(
  cmap : Bytes,
  glyph_count : UInt64,
) -> Bytes {
  let hmtx = b"\x01\xf4\x00\x00".to_array()
  for _index = 1UL; _index < glyph_count; _index = _index + 1UL {
    font_test_push_u16(hmtx, 0UL)
  }
  let loca : Array[Byte] = []
  for _index = 0UL; _index <= glyph_count; _index = _index + 1UL {
    font_test_push_u16(loca, 0UL)
  }
  font_test_build_truetype([
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: cmap },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: font_test_head_table() },
    { tag: b"hhea", payload: font_test_hhea_table() },
    { tag: b"hmtx", payload: Bytes::from_array(hmtx) },
    { tag: b"loca", payload: Bytes::from_array(loca) },
    { tag: b"maxp", payload: font_test_maxp_table_with_glyphs(glyph_count) },
    { tag: b"name", payload: font_test_name_table() },
    { tag: b"post", payload: font_test_post_table() },
  ])
}

///|
fn font_test_truetype_with_metadata(name : Bytes, post : Bytes) -> Bytes {
  font_test_build_truetype([
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: font_test_cmap_table() },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: font_test_head_table() },
    { tag: b"hhea", payload: font_test_hhea_table() },
    { tag: b"hmtx", payload: b"\x01\xf4\x00\x00" },
    { tag: b"loca", payload: b"\x00\x00\x00\x00" },
    { tag: b"maxp", payload: font_test_maxp_table() },
    { tag: b"name", payload: name },
    { tag: b"post", payload: post },
  ])
}

///|
fn font_test_post_with_suffix(version : UInt64, suffix : Bytes) -> Bytes {
  let output = Array::make(32, b'\x00')
  font_test_put_u32(output, 0, version)
  for byte in suffix {
    output.push(byte)
  }
  Bytes::from_array(output)
}

///|
fn font_test_metric_head_table_with_format(format : Int) -> Bytes {
  let output = font_test_head_table().to_array()
  font_test_put_i16(output, 50, format)
  Bytes::from_array(output)
}

///|
fn font_test_metric_hhea_table_with_count(count : UInt64) -> Bytes {
  let output = font_test_hhea_table().to_array()
  font_test_put_u16(output, 34, count)
  Bytes::from_array(output)
}

///|
fn font_test_metric_maxp_table() -> Bytes {
  font_test_metric_maxp_table_with_count(3UL)
}

///|
fn font_test_metric_maxp_table_with_count(count : UInt64) -> Bytes {
  let output = font_test_maxp_table().to_array()
  font_test_put_u16(output, 4, count)
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
  font_test_build_metric_truetype(
    loca_format=0,
    number_of_h_metrics=2UL,
    hmtx=b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8",
    loca=b"\x00\x00\x00\x05\x00\x05\x00\x0a",
    glyf=font_test_metric_glyf_table(),
  )
}

///|
fn font_test_build_metric_truetype(
  loca_format~ : Int,
  number_of_h_metrics~ : UInt64,
  hmtx~ : Bytes,
  loca~ : Bytes,
  glyf~ : Bytes,
  optional_table? : Bool = false,
) -> Bytes {
  let tables : Array[FontTestTable] = [
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: font_test_cmap_table() },
    { tag: b"glyf", payload: glyf },
    {
      tag: b"head",
      payload: font_test_metric_head_table_with_format(loca_format),
    },
    {
      tag: b"hhea",
      payload: font_test_metric_hhea_table_with_count(number_of_h_metrics),
    },
    { tag: b"hmtx", payload: hmtx },
    { tag: b"loca", payload: loca },
    { tag: b"maxp", payload: font_test_metric_maxp_table() },
    { tag: b"name", payload: font_test_name_table() },
    { tag: b"post", payload: font_test_post_table() },
  ]
  if optional_table {
    tables.push({ tag: b"zzzz", payload: b"\x7a" })
  }
  font_test_build_truetype(tables)
}

///|
fn font_test_long_loca_metric_truetype() -> Bytes {
  font_test_build_metric_truetype(
    loca_format=1,
    number_of_h_metrics=2UL,
    hmtx=b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8",
    loca=b"\x00\x00\x00\x00\x00\x00\x00\x0a\x00\x00\x00\x0a\x00\x00\x00\x14",
    glyf=font_test_metric_glyf_table(),
  )
}

///|
fn font_test_full_hmtx_truetype() -> Bytes {
  font_test_build_metric_truetype(
    loca_format=0,
    number_of_h_metrics=3UL,
    hmtx=b"\x01\xf4\xff\xec\x02\x58\x00\x1e\x02\xbc\xff\xd8",
    loca=b"\x00\x00\x00\x05\x00\x05\x00\x0a",
    glyf=font_test_metric_glyf_table(),
  )
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
  font_test_budget_with(4096UL, 16384UL)
}

///|
fn font_test_budget_with(bytes : UInt64, work : UInt64) -> @budget.Budget {
  font_test_budget_with_dimensions(
    bytes,
    allocations=3UL,
    allocation_size=4096UL,
    work,
  )
}

///|
fn font_test_budget_with_dimensions(
  bytes : UInt64,
  allocations~ : UInt64,
  allocation_size~ : UInt64,
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
test "one scalar query maps BMP and supplementary code points with stable boundaries" {
  let source = font_test_truetype_with_cmap_and_glyphs(
    font_test_cmap_format12([
      (0x0041UL, 0x0041UL, 1UL),
      (0x1F600UL, 0x1F600UL, 2UL),
    ]),
    3UL,
  )
  let owner = font_test_owner(source)
  let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
  inspect(font.glyph_for_scalar(0x0041).unwrap().value(), content="1")
  inspect(font.glyph_for_scalar(0x1F600).unwrap().value(), content="2")
  inspect(font.glyph_for_scalar(0x0042).unwrap().value(), content="0")
  for scalar in [-1, 0xD800, 0xDFFF, 0x110000] {
    let error = font.glyph_for_scalar(scalar).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    inspect(error.operation() == Some("font-glyph-for-scalar"), content="true")
    inspect(error.context() == Some("font-unicode-scalar-range"), content="true")
  }
}

///|
test "scalar query rejects retained source mutation before publication" {
  let source = font_test_truetype_with_cmap_and_glyphs(
    font_test_cmap_format12([(0x0041UL, 0x0041UL, 1UL)]),
    2UL,
  )
  let owner = font_test_owner(source)
  let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
  let cmap = font_test_table_offset(source, b"cmap")
  let original = owner.view().get(cmap + 28UL).unwrap()
  font_test_mutate_bytes(
    owner,
    cmap + 28UL,
    Bytes::from_array([(original.to_uint64() ^ 1UL).to_byte()]),
  )
  font_test_assert_revision_drift(font.glyph_for_scalar(0x0041).unwrap_err())
}

///|
test "unsupported outline signature publishes no Font" {
  let owner = font_test_owner(font_test_minimal_truetype())
  owner
  .with_mut(0UL, 4UL, fn(lease) {
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
  })
  .unwrap()
  let error = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
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
  owner
  .with_mut(offset, replacement.length().to_uint64(), fn(lease) {
    let mut index = 0UL
    while index < replacement.length().to_uint64() {
      match lease.set(index, replacement[index.to_int()]) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      index = index + 1UL
    }
    Ok(())
  })
  .unwrap()
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
fn font_test_recompute_adjustment(owner : @bytes.OwnedBytes) -> Unit {
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
  inspect(error.context() == Some("font-source-revision-drift"), content="true")
}

///|
test "font publishes separate exact global metric sources" {
  let owner = font_test_distinct_global_metrics()
  let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
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
  let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
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
  inspect(
    boundary.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
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
  inspect(receiving.context() == Some("font-glyph-id-range"), content="true")
}

///|
test "horizontal metric queries are repeatable and order independent" {
  let owner = font_test_owner(font_test_horizontal_metric_truetype())
  let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
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
test "long loca and full hmtx preserve identical glyph semantics" {
  let long_owner = font_test_owner(font_test_long_loca_metric_truetype())
  let long_font = Font::open(
    long_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let long_tail = long_font
    .horizontal_metrics(long_font.glyph_id(2UL).unwrap())
    .unwrap()
  inspect(long_tail.advance_width(), content="600")
  inspect(long_tail.left_side_bearing(), content="-40")
  inspect(long_tail.right_side_bearing(), content="590")

  let full_owner = font_test_owner(font_test_full_hmtx_truetype())
  let full_font = Font::open(
    full_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let full = full_font
    .horizontal_metrics(full_font.glyph_id(2UL).unwrap())
    .unwrap()
  inspect(full.advance_width(), content="700")
  inspect(full.left_side_bearing(), content="-40")
  inspect(full.right_side_bearing(), content="690")
}

///|
test "metric cardinality and location hostility fail before Font publication" {
  let valid_hmtx = b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8"
  let valid_loca = b"\x00\x00\x00\x05\x00\x05\x00\x0a"
  let valid_glyf = font_test_metric_glyf_table()
  let cases : Array[Bytes] = [
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=0UL,
      hmtx=valid_hmtx,
      loca=valid_loca,
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=4UL,
      hmtx=valid_hmtx,
      loca=valid_loca,
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=2UL,
      hmtx=b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff",
      loca=valid_loca,
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=2UL,
      hmtx=b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8\x00",
      loca=valid_loca,
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=2UL,
      hmtx=valid_hmtx,
      loca=b"\x00\x00\x00\x05\x00\x05",
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=2UL,
      hmtx=valid_hmtx,
      loca=b"\x00\x00\x00\x05\x00\x04\x00\x0a",
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=0,
      number_of_h_metrics=2UL,
      hmtx=valid_hmtx,
      loca=b"\x00\x00\x00\x05\x00\x05\x00\x0b",
      glyf=valid_glyf,
    ),
    font_test_build_metric_truetype(
      loca_format=1,
      number_of_h_metrics=2UL,
      hmtx=valid_hmtx,
      loca=b"\x00\x00\x00\x00\x00\x00\x00\x09\x00\x00\x00\x09\x00\x00\x00\x09",
      glyf=b"\x00\x01\x00\x00\x00\x00\x00\x00\x00",
    ),
  ]
  for source in cases {
    inspect(
      Font::open(
        font_test_owner(source).view(),
        font_test_limits(),
        font_test_budget(),
      )
      is Err(_),
      content="true",
    )
  }
}

///|
test "glyph and work ceilings admit exact values and reject one short atomically" {
  let source = font_test_horizontal_metric_truetype()
  let source_length = source.length().to_uint64()
  let table_count = font_test_read_u16(source, 4)
  let overlap_work = table_count * (table_count - 1UL) / 2UL
  let (_, directory_selector_work, _) = font_test_search_facts(table_count)
  // loca/glyph scans (7), two cmap-record scans (2), one format-4
  // validation scan (2), and one pre-charge format-4 discovery scan (2).
  let count_driven_work = 12UL
  let lookup_work = table_count * 27UL
  let table_iteration_work = table_count * 2UL
  let directory_normalization_work = table_count
  let exact_work = source_length * 2UL +
    overlap_work +
    directory_selector_work +
    table_count +
    directory_normalization_work +
    lookup_work +
    table_iteration_work +
    count_driven_work
  let discovery_work = source_length * 2UL +
    overlap_work +
    directory_selector_work +
    table_count +
    directory_normalization_work +
    table_count * 4UL
  let directory_allocation_size = table_count * 64UL
  let exact_limits = FontLimits::new(
    max_source_bytes=source_length,
    max_tables=10UL,
    max_table_bytes=source_length,
    max_glyphs=3UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=32UL,
    max_work=exact_work,
  ).unwrap()
  let exact_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=directory_allocation_size,
    exact_work,
  )
  ignore(
    Font::open(font_test_owner(source).view(), exact_limits, exact_budget).unwrap(),
  )
  inspect(exact_budget.remaining().bytes(), content="0")
  inspect(exact_budget.remaining().allocations(), content="0")
  inspect(exact_budget.remaining().work(), content="0")

  let glyph_limits = FontLimits::new(
    max_source_bytes=source_length,
    max_tables=10UL,
    max_table_bytes=source_length,
    max_glyphs=2UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=32UL,
    max_work=exact_work,
  ).unwrap()
  let glyph_error = Font::open(
    font_test_owner(source).view(),
    glyph_limits,
    font_test_budget_with(source_length, exact_work),
  ).unwrap_err()
  inspect(
    glyph_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(glyph_error.context() == Some("max-glyphs"), content="true")
  inspect(glyph_error.requested() == Some(3UL), content="true")
  inspect(glyph_error.limit() == Some(2UL), content="true")

  let narrow_budget = font_test_budget_with(source_length, exact_work - 1UL)
  let before = narrow_budget.remaining()
  let budget_error = Font::open(
    font_test_owner(source).view(),
    exact_limits,
    narrow_budget,
  ).unwrap_err()
  inspect(
    budget_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(budget_error.context() == Some("work"), content="true")
  let after = narrow_budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.work() == before.work(), content="true")

  let discovery_budget = font_test_budget_with(
    source_length,
    discovery_work - 1UL,
  )
  let discovery_before = discovery_budget.remaining()
  let discovery_error = Font::open(
    font_test_owner(source).view(),
    exact_limits,
    discovery_budget,
  ).unwrap_err()
  inspect(discovery_error.context() == Some("work"), content="true")
  inspect(
    discovery_budget.remaining().bytes() == discovery_before.bytes(),
    content="true",
  )
  inspect(
    discovery_budget.remaining().work() == discovery_before.work(),
    content="true",
  )

  let allocation_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=2UL,
    allocation_size=directory_allocation_size,
    exact_work,
  )
  let allocation_before = allocation_budget.remaining()
  let allocation_error = Font::open(
    font_test_owner(source).view(),
    exact_limits,
    allocation_budget,
  ).unwrap_err()
  inspect(allocation_error.context() == Some("allocations"), content="true")
  inspect(
    allocation_budget.remaining().allocations() ==
    allocation_before.allocations(),
    content="true",
  )

  let size_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=directory_allocation_size - 1UL,
    exact_work,
  )
  let size_before = size_budget.remaining()
  let size_error = Font::open(
    font_test_owner(source).view(),
    exact_limits,
    size_budget,
  ).unwrap_err()
  inspect(size_error.context() == Some("allocation_size"), content="true")
  inspect(
    size_budget.remaining().allocation_size() == size_before.allocation_size(),
    content="true",
  )
}

///|
test "directory normalization copy is preflighted and charged once per table" {
  let source = font_test_horizontal_metric_truetype()
  let source_length = source.length().to_uint64()
  let table_count = font_test_read_u16(source, 4)
  let overlap_work = table_count * (table_count - 1UL) / 2UL
  let (_, directory_selector_work, _) = font_test_search_facts(table_count)
  let parsed_directory_work = source_length * 2UL +
    overlap_work +
    directory_selector_work +
    table_count
  let normalization_copy_work = table_count
  let discovery_work = parsed_directory_work +
    normalization_copy_work +
    table_count * 4UL
  let work_without_copy = parsed_directory_work +
    table_count * 27UL +
    table_count * 2UL +
    12UL
  let exact_work = work_without_copy + normalization_copy_work
  let directory_allocation_size = table_count * 64UL
  let exact_limits = FontLimits::new(
    max_source_bytes=source_length,
    max_tables=table_count,
    max_table_bytes=source_length,
    max_glyphs=3UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=32UL,
    max_work=exact_work,
  ).unwrap()

  let preflight_short = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=directory_allocation_size,
    discovery_work - 1UL,
  )
  let preflight_before = preflight_short.remaining()
  let preflight_error = Font::open(
    font_test_owner(source).view(),
    exact_limits,
    preflight_short,
  ).unwrap_err()
  inspect(preflight_error.context() == Some("work"), content="true")
  inspect(
    preflight_short.remaining().work() == preflight_before.work(),
    content="true",
  )

  let uncharged_copy_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=directory_allocation_size,
    work_without_copy,
  )
  let uncharged_copy_before = uncharged_copy_budget.remaining()
  let uncharged_copy_error = Font::open(
    font_test_owner(source).view(),
    exact_limits,
    uncharged_copy_budget,
  ).unwrap_err()
  inspect(uncharged_copy_error.context() == Some("work"), content="true")
  inspect(
    uncharged_copy_budget.remaining().bytes() == uncharged_copy_before.bytes(),
    content="true",
  )
  inspect(
    uncharged_copy_budget.remaining().work() == uncharged_copy_before.work(),
    content="true",
  )

  let exact_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=directory_allocation_size,
    exact_work,
  )
  ignore(
    Font::open(font_test_owner(source).view(), exact_limits, exact_budget).unwrap(),
  )
  inspect(exact_budget.remaining().work(), content="0")
}

///|
test "many directory records set the retained allocation-size ceiling" {
  let source = font_test_minimal_truetype()
  let source_length = source.length().to_uint64()
  let table_count = font_test_read_u16(source, 4)
  inspect(table_count, content="10")
  let budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=table_count * 64UL - 1UL,
    16384UL,
  )
  let before = budget.remaining()
  let error = Font::open(
    font_test_owner(source).view(),
    font_test_limits(),
    budget,
  ).unwrap_err()
  inspect(error.context() == Some("allocation_size"), content="true")
  inspect(
    budget.remaining().allocation_size() == before.allocation_size(),
    content="true",
  )
}

///|
test "cmap admission rejects empty aliased unsupported and short subtables" {
  let header_alias : Array[Byte] = []
  font_test_push_u16(header_alias, 0UL)
  font_test_push_u16(header_alias, 1UL)
  font_test_push_u16(header_alias, 3UL)
  font_test_push_u16(header_alias, 1UL)
  font_test_push_u32(header_alias, 0UL)

  let unsupported : Array[Byte] = []
  font_test_push_u16(unsupported, 0UL)
  font_test_push_u16(unsupported, 1UL)
  font_test_push_u16(unsupported, 3UL)
  font_test_push_u16(unsupported, 1UL)
  font_test_push_u32(unsupported, 12UL)
  font_test_push_u16(unsupported, 6UL)
  font_test_push_u16(unsupported, 10UL)
  for _index = 0; _index < 6; _index = _index + 1 {
    unsupported.push(b'\x00')
  }

  let short_format4 : Array[Byte] = []
  font_test_push_u16(short_format4, 0UL)
  font_test_push_u16(short_format4, 1UL)
  font_test_push_u16(short_format4, 3UL)
  font_test_push_u16(short_format4, 1UL)
  font_test_push_u32(short_format4, 12UL)
  font_test_push_u16(short_format4, 4UL)
  font_test_push_u16(short_format4, 15UL)
  for _index = 0; _index < 11; _index = _index + 1 {
    short_format4.push(b'\x00')
  }

  let zero_segments : Array[Byte] = []
  font_test_push_u16(zero_segments, 0UL)
  font_test_push_u16(zero_segments, 1UL)
  font_test_push_u16(zero_segments, 3UL)
  font_test_push_u16(zero_segments, 1UL)
  font_test_push_u32(zero_segments, 12UL)
  font_test_push_u16(zero_segments, 4UL)
  font_test_push_u16(zero_segments, 16UL)
  for _index = 0; _index < 12; _index = _index + 1 {
    zero_segments.push(b'\x00')
  }

  let odd_segments = zero_segments.copy()
  odd_segments[18] = b'\x00'
  odd_segments[19] = b'\x01'

  let missing_format12_group : Array[Byte] = []
  font_test_push_u16(missing_format12_group, 0UL)
  font_test_push_u16(missing_format12_group, 1UL)
  font_test_push_u16(missing_format12_group, 3UL)
  font_test_push_u16(missing_format12_group, 10UL)
  font_test_push_u32(missing_format12_group, 12UL)
  font_test_push_u16(missing_format12_group, 12UL)
  font_test_push_u16(missing_format12_group, 0UL)
  font_test_push_u32(missing_format12_group, 16UL)
  font_test_push_u32(missing_format12_group, 0UL)
  font_test_push_u32(missing_format12_group, 1UL)

  for
    cmap in [
      b"\x00\x00\x00\x00",
      Bytes::from_array(header_alias),
      Bytes::from_array(unsupported),
      Bytes::from_array(short_format4),
      Bytes::from_array(zero_segments),
      Bytes::from_array(odd_segments),
      Bytes::from_array(missing_format12_group),
    ] {
    let error = Font::open(
      font_test_owner(font_test_truetype_with_cmap(cmap)).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some("font-cmap-envelope"), content="true")
  }
}

///|
test "cmap admission rejects malformed supported bodies and record keys" {
  let invalid_search = font_test_cmap_table().to_array()
  font_test_put_u16(invalid_search, 20, 0UL)
  let decreasing_end = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(decreasing_end, 26, 0xFFFFUL)
  let reversed_segment = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(reversed_segment, 32, 0x0042UL)
  let dangling_range = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(dangling_range, 40, 6UL)
  let reversed_group = font_test_cmap_format12([(0x101UL, 0x100UL, 0UL)])
  let overlapping_groups = font_test_cmap_format12([
    (0x100UL, 0x100UL, 0UL),
    (0x100UL, 0x100UL, 0UL),
  ])
  let invalid_platform = font_test_cmap_table().to_array()
  font_test_put_u16(invalid_platform, 4, 5UL)
  let invalid_encoding = font_test_cmap_table().to_array()
  font_test_put_u16(invalid_encoding, 6, 10UL)
  for
    cmap in [
      Bytes::from_array(invalid_search),
      Bytes::from_array(decreasing_end),
      Bytes::from_array(reversed_segment),
      Bytes::from_array(dangling_range),
      reversed_group,
      overlapping_groups,
      font_test_cmap_shared_format4_records(3UL, 1UL, 0UL, 3UL),
      font_test_cmap_shared_format4_records(3UL, 1UL, 3UL, 1UL),
      Bytes::from_array(invalid_platform),
      Bytes::from_array(invalid_encoding),
    ] {
    let error = Font::open(
      font_test_owner(font_test_truetype_with_cmap(cmap)).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some("font-cmap-envelope"), content="true")
  }
}

///|
test "format 4 admission validates direct and indexed glyph cardinality" {
  let direct_invalid = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(direct_invalid, 40, 0UL)
  font_test_put_u16(direct_invalid, 36, 0UL)
  let indexed_invalid = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(indexed_invalid, 44, 1UL)
  for cmap in [
    Bytes::from_array(direct_invalid),
    Bytes::from_array(indexed_invalid),
  ] {
    let error = Font::open(
      font_test_owner(font_test_truetype_with_cmap(cmap)).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some("font-cmap-envelope"), content="true")
  }

  let terminal_direct_invalid = font_test_cmap_format4_two_segments().to_array()
  // A zero sentinel delta maps U+FFFF to glyph 65535, not the missing glyph.
  font_test_put_u16(terminal_direct_invalid, 38, 0UL)
  let terminal_indexed_invalid = font_test_cmap_format4_two_segments().to_array()
  // The terminal range-offset field at byte 42 addresses the glyph word at 44.
  font_test_put_u16(terminal_indexed_invalid, 42, 2UL)
  font_test_put_u16(terminal_indexed_invalid, 44, 1UL)
  font_test_put_u16(terminal_indexed_invalid, 38, 0UL)
  for cmap in [
    Bytes::from_array(terminal_direct_invalid),
    Bytes::from_array(terminal_indexed_invalid),
  ] {
    let error = Font::open(
      font_test_owner(font_test_truetype_with_cmap(cmap)).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some("font-cmap-envelope"), content="true")
  }

  let direct_last_valid = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(direct_last_valid, 40, 0UL)
  // U+0041 + 0xFFC0 wraps to glyph 1, the final glyph in a two-glyph font.
  font_test_put_u16(direct_last_valid, 36, 0xFFC0UL)
  ignore(
    Font::open(
      font_test_owner(
        font_test_truetype_with_cmap_and_glyphs(
          Bytes::from_array(direct_last_valid),
          2UL,
        ),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap(),
  )
  let terminal_last_valid = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(terminal_last_valid, 38, 2UL)
  ignore(
    Font::open(
      font_test_owner(
        font_test_truetype_with_cmap_and_glyphs(
          Bytes::from_array(terminal_last_valid),
          2UL,
        ),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap(),
  )
  let indexed_last_valid = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(indexed_last_valid, 44, 1UL)
  ignore(
    Font::open(
      font_test_owner(
        font_test_truetype_with_cmap_and_glyphs(
          Bytes::from_array(indexed_last_valid),
          2UL,
        ),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap(),
  )
}

///|
test "cmap body scans consume exact aggregate work and reject one short atomically" {
  let cmap = font_test_cmap_format12([
    (0x100UL, 0x100UL, 0UL),
    (0x101UL, 0x101UL, 0UL),
  ])
  let source = font_test_truetype_with_cmap(cmap)
  let source_length = source.length().to_uint64()
  let table_count = font_test_read_u16(source, 4)
  let overlap_work = table_count * (table_count - 1UL) / 2UL
  let (_, directory_selector_work, _) = font_test_search_facts(table_count)
  // loca/glyph scans (3), two cmap-record scans (2), and two format-12
  // group scans (2).
  let count_driven_work = 7UL
  let exact_work = source_length * 2UL +
    overlap_work +
    directory_selector_work +
    table_count +
    table_count +
    table_count * 27UL +
    table_count * 2UL +
    count_driven_work
  let limits = FontLimits::new(
    max_source_bytes=source_length,
    max_tables=table_count,
    max_table_bytes=source_length,
    max_glyphs=1UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=32UL,
    max_work=exact_work,
  ).unwrap()
  let exact_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=table_count * 64UL,
    exact_work,
  )
  ignore(
    Font::open(font_test_owner(source).view(), limits, exact_budget).unwrap(),
  )
  inspect(exact_budget.remaining().work(), content="0")

  let short_budget = font_test_budget_with_dimensions(
    source_length,
    allocations=3UL,
    allocation_size=table_count * 64UL,
    exact_work - 1UL,
  )
  let before = short_budget.remaining()
  let error = Font::open(font_test_owner(source).view(), limits, short_budget).unwrap_err()
  inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(error.context() == Some("work"), content="true")
  inspect(short_budget.remaining().work() == before.work(), content="true")
}

///|
test "format 4 traversal preflights and charges exact single and shared work" {
  for case in [
    // loca/glyph (3), two cmap record passes (2), segment validation (2),
    // pre-charge segment discovery (2), search helper (1), and mapping scan
    // (2, including the terminal segment).
    (font_test_cmap_format4_two_segments(), 12UL),
    // The two distinct records share one subtable, but each authorized record
    // repeats both segment/search/mapping traversals: 3 + 4 + 4 + 4 + 2 + 4.
    (font_test_cmap_shared_format4_two_segments(), 21UL),
  ] {
    let (cmap, count_driven_work) = case
    let source = font_test_truetype_with_cmap(cmap)
    let source_length = source.length().to_uint64()
    let table_count = font_test_read_u16(source, 4)
    let overlap_work = table_count * (table_count - 1UL) / 2UL
    let (_, directory_selector_work, _) = font_test_search_facts(table_count)
    let exact_work = source_length * 2UL +
      overlap_work +
      directory_selector_work +
      table_count +
      table_count +
      table_count * 27UL +
      table_count * 2UL +
      count_driven_work
    let limits = FontLimits::new(
      max_source_bytes=source_length,
      max_tables=table_count,
      max_table_bytes=source_length,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=2UL,
      max_post_name_bytes=32UL,
      max_work=exact_work,
    ).unwrap()
    let exact_budget = font_test_budget_with_dimensions(
      source_length,
      allocations=3UL,
      allocation_size=table_count * 64UL,
      exact_work,
    )
    ignore(
      Font::open(font_test_owner(source).view(), limits, exact_budget).unwrap(),
    )
    inspect(exact_budget.remaining().work(), content="0")

    let short_budget = font_test_budget_with_dimensions(
      source_length,
      allocations=3UL,
      allocation_size=table_count * 64UL,
      exact_work - 1UL,
    )
    let before = short_budget.remaining()
    let error = Font::open(
      font_test_owner(source).view(),
      limits,
      short_budget,
    ).unwrap_err()
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some("work"), content="true")
    inspect(short_budget.remaining().work() == before.work(), content="true")
  }
}

///|
test "semantic max work gates cmap discovery before attacker-driven loops" {
  let source = font_test_truetype_with_cmap(
    font_test_cmap_format4_two_segments(),
  )
  let source_length = source.length().to_uint64()
  let table_count = font_test_read_u16(source, 4)
  let overlap_work = table_count * (table_count - 1UL) / 2UL
  let (_, directory_selector_work, _) = font_test_search_facts(table_count)
  let directory_work = source_length * 2UL +
    overlap_work +
    directory_selector_work +
    table_count +
    table_count
  let discovery_base_work = directory_work + table_count * 4UL
  // One encoding record is scanned at the first boundary. Its two format-4
  // segments are scanned only after the second cumulative boundary succeeds.
  for case in [
    (discovery_base_work + 1UL, discovery_base_work),
    (discovery_base_work + 3UL, discovery_base_work + 2UL),
  ] {
    let (requested_work, max_work) = case
    let limits = FontLimits::new(
      max_source_bytes=source_length,
      max_tables=table_count,
      max_table_bytes=source_length,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=32UL,
      max_work~,
    ).unwrap()
    let ample_budget = font_test_budget_with_dimensions(
      source_length,
      allocations=3UL,
      allocation_size=table_count * 64UL,
      1000000UL,
    )
    let before = ample_budget.remaining()
    let error = Font::open(
      font_test_owner(source).view(),
      limits,
      ample_budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some("max-work"), content="true")
    inspect(error.requested() == Some(requested_work), content="true")
    inspect(error.limit() == Some(max_work), content="true")
    inspect(
      ample_budget.remaining().bytes() == before.bytes(),
      content="true",
    )
    inspect(
      ample_budget.remaining().work() == before.work(),
      content="true",
    )
  }
}

///|
test "name language tags and post name references require exact envelopes" {
  let valid_name1 = b"\x00\x01\x00\x00\x00\x0c\x00\x01\x00\x01\x00\x00A"
  let invalid_name1 = b"\x00\x01\x00\x00\x00\x0c\x00\x01\x00\x01\x00\x01"
  let dangling_language : Array[Byte] = []
  font_test_push_u16(dangling_language, 1UL)
  font_test_push_u16(dangling_language, 1UL)
  font_test_push_u16(dangling_language, 20UL)
  font_test_push_u16(dangling_language, 3UL)
  font_test_push_u16(dangling_language, 1UL)
  font_test_push_u16(dangling_language, 0x8000UL)
  font_test_push_u16(dangling_language, 1UL)
  font_test_push_u16(dangling_language, 1UL)
  font_test_push_u16(dangling_language, 0UL)
  font_test_push_u16(dangling_language, 0UL)
  dangling_language.push(b'A')
  let valid_post2 = font_test_post_with_suffix(
    0x00020000UL, b"\x00\x01\x01\x02\x01A",
  )
  let missing_post2 = font_test_post_with_suffix(
    0x00020000UL, b"\x00\x01\xff\xff",
  )
  let truncated_post2 = font_test_post_with_suffix(
    0x00020000UL, b"\x00\x01\x01\x02\x02A",
  )
  let trailing_post2 = font_test_post_with_suffix(
    0x00020000UL, b"\x00\x01\x01\x02\x01AB",
  )
  let invalid_character_post2 = font_test_post_with_suffix(
    0x00020000UL, b"\x00\x01\x01\x02\x01-",
  )
  let long_name_suffix : Array[Byte] = []
  font_test_push_u16(long_name_suffix, 1UL)
  font_test_push_u16(long_name_suffix, 258UL)
  long_name_suffix.push(b'\x40')
  for _index = 0; _index < 64; _index = _index + 1 {
    long_name_suffix.push(b'A')
  }
  let long_name_post2 = font_test_post_with_suffix(
    0x00020000UL,
    Bytes::from_array(long_name_suffix),
  )
  let valid_post25 = font_test_post_with_suffix(0x00025000UL, b"\x00\x01\x00")
  let invalid_post25 = font_test_post_with_suffix(0x00025000UL, b"\x00\x01\xff")
  let long_post25 = font_test_post_with_suffix(
    0x00025000UL, b"\x00\x01\x00\x00",
  )
  let long_post3 = font_test_post_with_suffix(0x00030000UL, b"\x00")
  let one_glyph_post1 = font_test_post_with_suffix(0x00010000UL, b"")

  inspect(
    Font::open(
      font_test_owner(
        font_test_truetype_with_metadata(valid_name1, valid_post2),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    )
    is Ok(_),
    content="true",
  )
  inspect(
    Font::open(
      font_test_owner(
        font_test_truetype_with_metadata(valid_name1, valid_post25),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    )
    is Ok(_),
    content="true",
  )
  let post_name_source = font_test_truetype_with_metadata(
    font_test_name_table(),
    valid_post2,
  )
  let post_name_length = post_name_source.length().to_uint64()
  let exact_post_name_limits = FontLimits::new(
    max_source_bytes=post_name_length,
    max_tables=10UL,
    max_table_bytes=post_name_length,
    max_glyphs=1UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=2UL,
    max_work=16384UL,
  ).unwrap()
  inspect(
    Font::open(
      font_test_owner(post_name_source).view(),
      exact_post_name_limits,
      font_test_budget_with(post_name_length, 16384UL),
    )
    is Ok(_),
    content="true",
  )
  let short_post_name_limits = FontLimits::new(
    max_source_bytes=post_name_length,
    max_tables=10UL,
    max_table_bytes=post_name_length,
    max_glyphs=1UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=1UL,
    max_work=16384UL,
  ).unwrap()
  let short_post_name_budget = font_test_budget_with(post_name_length, 16384UL)
  let short_post_name_before = short_post_name_budget.remaining()
  let short_post_name_error = Font::open(
    font_test_owner(post_name_source).view(),
    short_post_name_limits,
    short_post_name_budget,
  ).unwrap_err()
  inspect(
    short_post_name_error.context() == Some("max-post-name-bytes"),
    content="true",
  )
  inspect(short_post_name_error.requested() == Some(2UL), content="true")
  inspect(short_post_name_error.limit() == Some(1UL), content="true")
  let short_post_name_after = short_post_name_budget.remaining()
  inspect(
    short_post_name_after.bytes() == short_post_name_before.bytes(),
    content="true",
  )
  inspect(
    short_post_name_after.allocations() == short_post_name_before.allocations(),
    content="true",
  )
  inspect(
    short_post_name_after.allocation_size() ==
    short_post_name_before.allocation_size(),
    content="true",
  )
  inspect(
    short_post_name_after.work() == short_post_name_before.work(),
    content="true",
  )
  let invalid_name_error = Font::open(
    font_test_owner(
      font_test_truetype_with_metadata(invalid_name1, font_test_post_table()),
    ).view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    invalid_name_error.context() == Some("font-name-envelope"),
    content="true",
  )
  let dangling_language_error = Font::open(
    font_test_owner(
      font_test_truetype_with_metadata(
        Bytes::from_array(dangling_language),
        font_test_post_table(),
      ),
    ).view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    dangling_language_error.context() == Some("font-name-envelope"),
    content="true",
  )
  for
    post in [
      missing_post2, truncated_post2, trailing_post2, invalid_character_post2, long_name_post2,
      invalid_post25, long_post25, long_post3, one_glyph_post1,
    ] {
    let error = Font::open(
      font_test_owner(
        font_test_truetype_with_metadata(font_test_name_table(), post),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some("font-post-envelope"), content="true")
  }

  let high_index_suffix : Array[Byte] = []
  font_test_push_u16(high_index_suffix, 1UL)
  font_test_push_u16(high_index_suffix, 0xFFFFUL)
  for _index = 0UL; _index < 65278UL; _index = _index + 1UL {
    high_index_suffix.push(b'\x01')
    high_index_suffix.push(b'A')
  }
  let high_index_source = font_test_truetype_with_metadata(
    font_test_name_table(),
    font_test_post_with_suffix(
      0x00020000UL,
      Bytes::from_array(high_index_suffix),
    ),
  )
  let high_index_length = high_index_source.length().to_uint64()
  let high_index_limits = FontLimits::new(
    max_source_bytes=high_index_length,
    max_tables=10UL,
    max_table_bytes=high_index_length,
    max_glyphs=1UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_post_name_bytes=130556UL,
    max_work=1000000UL,
  ).unwrap()
  inspect(
    Font::open(
      font_test_owner(high_index_source).view(),
      high_index_limits,
      font_test_budget_with(high_index_length, 1000000UL),
    )
    is Ok(_),
    content="true",
  )
}

///|
test "name admission enforces canonical four-part record ordering" {
  let sorted = font_test_name_table_with_keys([
    (3UL, 1UL, 0UL, 1UL),
    (3UL, 1UL, 0UL, 2UL),
    (3UL, 2UL, 0UL, 1UL),
  ])
  inspect(
    Font::open(
      font_test_owner(
        font_test_truetype_with_metadata(sorted, font_test_post_table()),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    )
    is Ok(_),
    content="true",
  )
  for
    name in [
      font_test_name_table_with_keys([
        (3UL, 2UL, 0UL, 1UL),
        (3UL, 1UL, 0UL, 1UL),
      ]),
      font_test_name_table_with_keys([
        (3UL, 1UL, 0UL, 2UL),
        (3UL, 1UL, 0UL, 1UL),
      ]),
    ] {
    let error = Font::open(
      font_test_owner(
        font_test_truetype_with_metadata(name, font_test_post_table()),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some("font-name-envelope"), content="true")
  }
}

///|
test "format-0 user-defined name languages preserve the platform domain" {
  let valid_user_name0 = b"\x00\x00\x00\x01\x00\x12\x00\xf0\x00\x00\x80\x00\x00\x01\x00\x01\x00\x00A"
  let invalid_registered_name0 = b"\x00\x00\x00\x01\x00\x12\x00\x03\x00\x01\x80\x00\x00\x01\x00\x01\x00\x00A"
  inspect(
    Font::open(
      font_test_owner(
        font_test_truetype_with_metadata(
          valid_user_name0,
          font_test_post_table(),
        ),
      ).view(),
      font_test_limits(),
      font_test_budget(),
    )
    is Ok(_),
    content="true",
  )
  let error = Font::open(
    font_test_owner(
      font_test_truetype_with_metadata(
        invalid_registered_name0,
        font_test_post_table(),
      ),
    ).view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Data, content="true")
  inspect(error.context() == Some("font-name-envelope"), content="true")
}

///|
fn font_test_read_u16(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 8) | source[offset + 1].to_uint64()
}

///|
fn font_test_read_u32(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 24) |
  (source[offset + 1].to_uint64() << 16) |
  (source[offset + 2].to_uint64() << 8) |
  source[offset + 3].to_uint64()
}

///|
fn font_test_table_offset(source : Bytes, tag : Bytes) -> UInt64 {
  let count = font_test_read_u16(source, 4).to_int()
  for index = 0; index < count; index = index + 1 {
    let record = 12 + index * 16
    if source[record] == tag[0] &&
      source[record + 1] == tag[1] &&
      source[record + 2] == tag[2] &&
      source[record + 3] == tag[3] {
      return font_test_read_u32(source, record + 8)
    }
  }
  0UL
}

///|
fn font_test_assert_every_query_drift(
  font : Font,
  glyph : GlyphId,
) -> Unit raise {
  font_test_assert_revision_drift(font.units_per_em().unwrap_err())
  font_test_assert_revision_drift(font.global_bounds().unwrap_err())
  font_test_assert_revision_drift(font.hhea_line_metrics().unwrap_err())
  font_test_assert_revision_drift(font.typographic_line_metrics().unwrap_err())
  font_test_assert_revision_drift(font.glyph_id(0UL).unwrap_err())
  font_test_assert_revision_drift(font.horizontal_metrics(glyph).unwrap_err())
}

///|
test "required optional glyph unread and mutate-back changes invalidate every query" {
  let source = font_test_build_metric_truetype(
    loca_format=0,
    number_of_h_metrics=2UL,
    hmtx=b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8",
    loca=b"\x00\x00\x00\x05\x00\x05\x00\x0a",
    glyf=font_test_metric_glyf_table(),
    optional_table=true,
  )
  for tag in [b"head", b"zzzz", b"glyf", b"name"] {
    let owner = font_test_owner(source)
    let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
    let glyph = font.glyph_id(0UL).unwrap()
    let offset = font_test_table_offset(source, tag)
    let original = owner.view().get(offset).unwrap()
    font_test_mutate_bytes(
      owner,
      offset,
      Bytes::from_array([(original.to_uint64() ^ 1UL).to_byte()]),
    )
    font_test_assert_every_query_drift(font, glyph)
  }

  let restored_owner = font_test_owner(source)
  let restored = Font::open(
    restored_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let glyph = restored.glyph_id(0UL).unwrap()
  let offset = font_test_table_offset(source, b"glyf")
  let original = restored_owner.view().get(offset).unwrap()
  font_test_mutate_bytes(restored_owner, offset, b"\xff")
  font_test_mutate_bytes(restored_owner, offset, Bytes::from_array([original]))
  font_test_assert_every_query_drift(restored, glyph)
}

///|
test "interleaved independent fonts retain isolated deterministic metrics" {
  let short_owner = font_test_owner(font_test_horizontal_metric_truetype())
  let short_font = Font::open(
    short_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let long_owner = font_test_owner(font_test_full_hmtx_truetype())
  let long_font = Font::open(
    long_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let short_id = short_font.glyph_id(2UL).unwrap()
  let long_id = long_font.glyph_id(2UL).unwrap()
  inspect(
    short_font.horizontal_metrics(short_id).unwrap().advance_width(),
    content="600",
  )
  inspect(
    long_font.horizontal_metrics(long_id).unwrap().advance_width(),
    content="700",
  )
  inspect(
    short_font.horizontal_metrics(short_id).unwrap().advance_width(),
    content="600",
  )
  inspect(
    long_font.horizontal_metrics(long_id).unwrap().advance_width(),
    content="700",
  )
}

///|
test "every cached global metric rejects retained source revision drift" {
  let owner = font_test_distinct_global_metrics()
  let font = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap()
  font_test_mutate_bytes(owner, 431UL, b"\x01")
  font_test_assert_revision_drift(font.units_per_em().unwrap_err())
  font_test_assert_revision_drift(font.global_bounds().unwrap_err())
  font_test_assert_revision_drift(font.hhea_line_metrics().unwrap_err())
  font_test_assert_revision_drift(font.typographic_line_metrics().unwrap_err())
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
  inspect(
    range_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(range_error.operation() == Some("font-open"), content="true")
  inspect(range_error.context() == Some("font-table-range"), content="true")

  let missing = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_bytes(missing, 60UL, b"heaf")
  let missing_error = Font::open(
    missing.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    missing_error.category() == @error.ErrorCategory::Data,
    content="true",
  )
  inspect(
    missing_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
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
  inspect(
    length_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
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
  inspect(
    magic_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(magic_error.context() == Some("font-head-magic"), content="true")

  let bad_glyph_format = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_u16(bad_glyph_format, 340UL, 1UL)
  font_test_mutate_u32(bad_glyph_format, 296UL, 0UL)
  let glyph_format_head = bad_glyph_format.view().subview(288UL, 54UL).unwrap()
  font_test_mutate_u32(
    bad_glyph_format,
    64UL,
    font_test_checksum(font_test_view_bytes(glyph_format_head)),
  )
  font_test_recompute_adjustment(bad_glyph_format)
  let glyph_format_error = Font::open(
    bad_glyph_format.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    glyph_format_error.category() == @error.ErrorCategory::Data,
    content="true",
  )
  inspect(
    glyph_format_error.context() == Some("font-glyph-data-format"),
    content="true",
  )
  inspect(glyph_format_error.source_offset() == Some(340UL), content="true")

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
  inspect(semantic_error.context() == Some("max-source-bytes"), content="true")
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
    let error = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(error.context() == Some("font-outline-profile"), content="true")
  }
  for tag in [b"CFF ", b"CFF2", b"fvar", b"COLR", b"CBDT", b"sbix"] {
    let owner = font_test_owner(font_test_minimal_truetype())
    font_test_mutate_bytes(owner, 44UL, tag)
    let error = Font::open(owner.view(), font_test_limits(), font_test_budget()).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(error.context() == Some("font-unsupported-profile"), content="true")
  }
}
