///|
priv struct GeneratedFontTable {
  tag : Bytes
  payload : Bytes
}

///|
priv struct FontAdmissionCase {
  id : String
  source : Bytes
  accepted : Bool
}

///|
fn generated_put_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn generated_put_i16(output : Array[Byte], value : Int) -> Unit {
  let encoded = if value < 0 {
    (value + 0x10000).to_uint64()
  } else {
    value.to_uint64()
  }
  generated_put_u16(output, encoded)
}

///|
fn generated_put_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn generated_put_u32_at(
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
fn generated_put_u16_at(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn generated_put_i16_at(
  output : Array[Byte],
  offset : Int,
  value : Int,
) -> Unit {
  let encoded = if value < 0 {
    (value + 0x10000).to_uint64()
  } else {
    value.to_uint64()
  }
  generated_put_u16_at(output, offset, encoded)
}

///|
fn font_wb_put_u16(output : Array[Byte], value : UInt64) -> Unit {
  generated_put_u16(output, value)
}

///|
fn font_wb_put_i16(output : Array[Byte], value : Int) -> Unit {
  generated_put_i16(output, value)
}

///|
fn font_wb_put_u32(output : Array[Byte], value : UInt64) -> Unit {
  generated_put_u32(output, value)
}

///|
fn font_wb_bytes_array(source : Bytes) -> Array[Byte] {
  let output : Array[Byte] = []
  for byte in source {
    output.push(byte)
  }
  output
}

///|
fn font_wb_read_u16(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 8) | source[offset + 1].to_uint64()
}

///|
fn font_wb_read_u32(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 24) |
  (source[offset + 1].to_uint64() << 16) |
  (source[offset + 2].to_uint64() << 8) |
  source[offset + 3].to_uint64()
}

///|
fn font_wb_put_u16_at_copy(
  source : Bytes,
  offset : Int,
  value : UInt64,
) -> Bytes {
  let output = font_wb_bytes_array(source)
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
  Bytes::from_array(output)
}

///|
fn font_wb_put_u32_at_copy(
  source : Bytes,
  offset : Int,
  value : UInt64,
) -> Bytes {
  let output = font_wb_bytes_array(source)
  generated_put_u32_at(output, offset, value)
  Bytes::from_array(output)
}

///|
fn generated_checksum(source : Bytes) -> UInt64 {
  let mut checksum = 0UL
  let mut offset = 0
  while offset < source.length() {
    let mut word = 0UL
    for delta in [0, 1, 2, 3] {
      let index = offset + delta
      let byte = if index < source.length() { source[index] } else { b'\x00' }
      word = (word << 8) | byte.to_uint64()
    }
    checksum = (checksum + word) & 0xFFFFFFFFUL
    offset = offset + 4
  }
  checksum
}

///|
fn generated_head_table() -> Bytes {
  let output : Array[Byte] = []
  generated_put_u32(output, 0x00010000UL)
  generated_put_u32(output, 0x00010000UL)
  generated_put_u32(output, 0UL)
  generated_put_u32(output, 0x5F0F3CF5UL)
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 1000UL)
  for index = 0; index < 16; index = index + 1 {
    output.push(b'\x00')
  }
  for value in [-10, -20, 100, 200] {
    generated_put_i16(output, value)
  }
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 8UL)
  generated_put_i16(output, 0)
  generated_put_i16(output, 0)
  generated_put_i16(output, 0)
  Bytes::from_array(output)
}

///|
fn generated_cmap_table() -> Bytes {
  let output : Array[Byte] = []
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 1UL)
  generated_put_u16(output, 3UL)
  generated_put_u16(output, 1UL)
  generated_put_u32(output, 12UL)
  generated_put_u16(output, 4UL)
  generated_put_u16(output, 24UL)
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 2UL)
  generated_put_u16(output, 2UL)
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 0xFFFFUL)
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 0xFFFFUL)
  generated_put_u16(output, 1UL)
  generated_put_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn generated_hhea_table() -> Bytes {
  let output = Array::make(36, b'\x00')
  generated_put_u32_at(output, 0, 0x00010000UL)
  generated_put_i16_at(output, 4, 800)
  generated_put_i16_at(output, 6, -200)
  generated_put_i16_at(output, 8, 50)
  output[35] = b'\x01'
  Bytes::from_array(output)
}

///|
fn generated_maxp_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  generated_put_u32_at(output, 0, 0x00010000UL)
  output[5] = b'\x01'
  Bytes::from_array(output)
}

///|
fn generated_post_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  generated_put_u32_at(output, 0, 0x00030000UL)
  Bytes::from_array(output)
}

///|
fn generated_os2_table() -> Bytes {
  let output = Array::make(78, b'\x00')
  generated_put_i16_at(output, 68, 750)
  generated_put_i16_at(output, 70, -250)
  generated_put_i16_at(output, 72, 25)
  Bytes::from_array(output)
}

///|
fn font_wb_table(tag : Bytes, payload : Bytes) -> GeneratedFontTable {
  { tag, payload }
}

///|
fn font_wb_required_tables() -> Array[GeneratedFontTable] {
  [
    font_wb_table(b"OS/2", generated_os2_table()),
    font_wb_table(b"cmap", generated_cmap_table()),
    font_wb_table(b"glyf", b""),
    font_wb_table(b"head", generated_head_table()),
    font_wb_table(b"hhea", generated_hhea_table()),
    font_wb_table(b"hmtx", b"\x01\xf4\x00\x00"),
    font_wb_table(b"loca", b"\x00\x00\x00\x00"),
    font_wb_table(b"maxp", generated_maxp_table()),
    font_wb_table(b"name", b"\x00\x00\x00\x00\x00\x06"),
    font_wb_table(b"post", generated_post_table()),
  ]
}

///|
fn font_wb_without_table(tag : Bytes) -> Array[GeneratedFontTable] {
  let tables : Array[GeneratedFontTable] = []
  for table in font_wb_required_tables() {
    if table.tag != tag {
      tables.push(table)
    }
  }
  tables
}

///|
fn font_wb_search_facts(num_tables : UInt64) -> (UInt64, UInt64, UInt64) {
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
fn font_wb_build_sfnt(tables : Array[GeneratedFontTable]) -> Bytes {
  let output : Array[Byte] = []
  let num_tables = tables.length().to_uint64()
  let (search_range, selector, range_shift) = font_wb_search_facts(num_tables)
  font_wb_put_u32(output, 0x00010000UL)
  font_wb_put_u16(output, num_tables)
  font_wb_put_u16(output, search_range)
  font_wb_put_u16(output, selector)
  font_wb_put_u16(output, range_shift)
  let offsets : Array[UInt64] = []
  let mut next_offset = 12UL + num_tables * 16UL
  for table in tables {
    for byte in table.tag {
      output.push(byte)
    }
    font_wb_put_u32(output, generated_checksum(table.payload))
    font_wb_put_u32(output, next_offset)
    font_wb_put_u32(output, table.payload.length().to_uint64())
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
  let mut head_index = -1
  for index, table in tables {
    if table.tag == b"head" {
      head_index = index
    }
  }
  if head_index >= 0 {
    let adjustment = (
        0xB1B0AFBAUL - generated_checksum(Bytes::from_array(output.copy()))
      ) &
      0xFFFFFFFFUL
    generated_put_u32_at(output, offsets[head_index].to_int() + 8, adjustment)
  }
  Bytes::from_array(output)
}

///|
fn font_wb_record_index(source : Bytes, tag : Bytes) -> Int {
  let num_tables = font_wb_read_u16(source, 4).to_int()
  for index = 0; index < num_tables; index = index + 1 {
    let record = 12 + index * 16
    let mut matches = true
    for delta = 0; delta < 4; delta = delta + 1 {
      if source[record + delta] != tag[delta] {
        matches = false
      }
    }
    if matches {
      return index
    }
  }
  -1
}

///|
fn font_wb_table_offset(source : Bytes, tag : Bytes) -> Int {
  let index = font_wb_record_index(source, tag)
  if index < 0 {
    return -1
  }
  font_wb_read_u32(source, 12 + index * 16 + 8).to_int()
}

///|
fn font_wb_set_table_record_u32(
  source : Bytes,
  tag : Bytes,
  field_offset : Int,
  value : UInt64,
) -> Bytes {
  let index = font_wb_record_index(source, tag)
  if index < 0 {
    return source
  }
  font_wb_put_u32_at_copy(source, 12 + index * 16 + field_offset, value)
}

///|
fn font_wb_swap_directory_records(
  source : Bytes,
  left : Int,
  right : Int,
) -> Bytes {
  let output = font_wb_bytes_array(source)
  for delta = 0; delta < 16; delta = delta + 1 {
    let left_index = 12 + left * 16 + delta
    let right_index = 12 + right * 16 + delta
    let value = output[left_index]
    output[left_index] = output[right_index]
    output[right_index] = value
  }
  Bytes::from_array(output)
}

///|
fn font_wb_copy_directory_tag(source : Bytes, from : Int, to : Int) -> Bytes {
  let output = font_wb_bytes_array(source)
  for delta = 0; delta < 4; delta = delta + 1 {
    output[12 + to * 16 + delta] = output[12 + from * 16 + delta]
  }
  Bytes::from_array(output)
}

///|
fn font_wb_overlap_table_with_previous(source : Bytes, tag : Bytes) -> Bytes {
  let index = font_wb_record_index(source, tag)
  if index <= 0 {
    return source
  }
  let mut previous = index - 1
  while previous >= 0 &&
        font_wb_read_u32(source, 12 + previous * 16 + 12) == 0UL {
    previous = previous - 1
  }
  if previous < 0 {
    return source
  }
  let previous_offset = font_wb_read_u32(source, 12 + previous * 16 + 8)
  font_wb_set_table_record_u32(source, tag, 8, previous_offset)
}

///|
fn font_wb_mutate_table_field(
  source : Bytes,
  tag : Bytes,
  field_offset : Int,
  replacement : Bytes,
) -> Bytes {
  let table_offset = font_wb_table_offset(source, tag)
  if table_offset < 0 {
    return source
  }
  let output = font_wb_bytes_array(source)
  for index, byte in replacement {
    output[table_offset + field_offset + index] = byte
  }
  Bytes::from_array(output)
}

///|
fn font_wb_table_checksum(source : Bytes, tag : Bytes) -> UInt64 {
  let index = font_wb_record_index(source, tag)
  let table_offset = font_wb_read_u32(source, 12 + index * 16 + 8).to_int()
  let table_length = font_wb_read_u32(source, 12 + index * 16 + 12).to_int()
  let mut checksum = 0UL
  let mut offset = 0
  while offset < table_length {
    let mut word = 0UL
    for delta = 0; delta < 4; delta = delta + 1 {
      let local_offset = offset + delta
      let byte = if tag == b"head" && local_offset >= 8 && local_offset < 12 {
        b'\x00'
      } else if local_offset < table_length {
        source[table_offset + local_offset]
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
fn font_wb_repair_table_checksum(source : Bytes, tag : Bytes) -> Bytes {
  let index = font_wb_record_index(source, tag)
  if index < 0 {
    return source
  }
  font_wb_put_u32_at_copy(
    source,
    12 + index * 16 + 4,
    font_wb_table_checksum(source, tag),
  )
}

///|
fn font_wb_repair_checksum_adjustment(source : Bytes) -> Bytes {
  let head_offset = font_wb_table_offset(source, b"head")
  if head_offset < 0 {
    return source
  }
  let zeroed = font_wb_put_u32_at_copy(source, head_offset + 8, 0UL)
  let adjustment = (0xB1B0AFBAUL - generated_checksum(zeroed)) & 0xFFFFFFFFUL
  font_wb_put_u32_at_copy(zeroed, head_offset + 8, adjustment)
}

///|
fn font_wb_admission_cases() -> Array[FontAdmissionCase] {
  let valid = font_wb_build_sfnt(font_wb_required_tables())
  let unknown = font_wb_build_sfnt(
    font_wb_required_tables() + [font_wb_table(b"zzzz", b"\x01\x02\x03")],
  )
  let bad_checksum = font_wb_mutate_table_field(
    valid,
    b"cmap",
    0,
    b"\x01",
  )
  [
    { id: "valid", source: valid, accepted: true },
    { id: "unknown-optional", source: unknown, accepted: true },
    { id: "bad-table-checksum", source: bad_checksum, accepted: false },
  ]
}

///|
fn generated_minimal_truetype() -> Bytes {
  font_wb_build_sfnt(font_wb_required_tables())
}

///|
fn generated_horizontal_metric_truetype() -> Bytes {
  let head = font_wb_bytes_array(generated_head_table())
  generated_put_i16_at(head, 50, 0)
  let hhea = font_wb_bytes_array(generated_hhea_table())
  generated_put_u16_at(hhea, 34, 2UL)
  let maxp = font_wb_bytes_array(generated_maxp_table())
  generated_put_u16_at(maxp, 4, 3UL)
  let glyf : Array[Byte] = []
  for value in [1, -10, -20, 100, 200, 1, 5, -6, 55, 70] {
    generated_put_i16(glyf, value)
  }
  font_wb_build_sfnt([
    font_wb_table(b"OS/2", generated_os2_table()),
    font_wb_table(b"cmap", generated_cmap_table()),
    font_wb_table(b"glyf", Bytes::from_array(glyf)),
    font_wb_table(b"head", Bytes::from_array(head)),
    font_wb_table(b"hhea", Bytes::from_array(hhea)),
    font_wb_table(
      b"hmtx",
      b"\x01\xf4\xff\xec\x02\x58\x00\x1e\xff\xd8",
    ),
    font_wb_table(b"loca", b"\x00\x00\x00\x05\x00\x05\x00\x0a"),
    font_wb_table(b"maxp", Bytes::from_array(maxp)),
    font_wb_table(b"name", b"\x00\x00\x00\x00\x00\x06"),
    font_wb_table(b"post", generated_post_table()),
  ])
}

///|
fn generated_font_owner(source : Bytes) -> @bytes.OwnedBytes {
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
test "generated micro-font has a valid whole-font adjustment" {
  let source = generated_minimal_truetype()
  inspect(generated_checksum(source), content="2981146554")
  let owner = generated_font_owner(source)
  let limits = FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
  let budget = @budget.Budget::new(
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
  let font = Font::open(owner.view(), limits, budget).unwrap()
  inspect(font.units_per_em().unwrap(), content="1000")
}
