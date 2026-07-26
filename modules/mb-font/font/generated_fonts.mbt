///|
priv struct GeneratedFontTable {
  tag : Bytes
  payload : Bytes
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
fn generated_checksum(source : Bytes) -> UInt64 {
  let mut checksum = 0UL
  let mut offset = 0
  while offset < source.length() {
    let mut word = 0UL
    for delta in [0, 1, 2, 3] {
      let index = offset + delta
      let byte = if index < source.length() {
        source[index]
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
  for value in [0, 0, 0, 0] {
    generated_put_i16(output, value)
  }
  generated_put_u16(output, 0UL)
  generated_put_u16(output, 8UL)
  generated_put_i16(output, 2)
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
fn generated_minimal_truetype() -> Bytes {
  let tables : Array[GeneratedFontTable] = [
    { tag: b"OS/2", payload: Bytes::from_array(Array::make(78, b'\x00')) },
    { tag: b"cmap", payload: generated_cmap_table() },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: generated_head_table() },
    { tag: b"hhea", payload: generated_hhea_table() },
    { tag: b"hmtx", payload: b"\x01\xf4\x00\x00" },
    { tag: b"loca", payload: b"\x00\x00\x00\x00" },
    { tag: b"maxp", payload: generated_maxp_table() },
    { tag: b"name", payload: b"\x00\x00\x00\x00\x00\x06" },
    { tag: b"post", payload: generated_post_table() },
  ]
  let output : Array[Byte] = []
  generated_put_u32(output, 0x00010000UL)
  generated_put_u16(output, 10UL)
  generated_put_u16(output, 128UL)
  generated_put_u16(output, 3UL)
  generated_put_u16(output, 32UL)
  let offsets : Array[UInt64] = []
  let mut next_offset = 172UL
  for table in tables {
    for byte in table.tag {
      output.push(byte)
    }
    generated_put_u32(output, generated_checksum(table.payload))
    generated_put_u32(output, next_offset)
    generated_put_u32(output, table.payload.length().to_uint64())
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
    0xB1B0AFBAUL - generated_checksum(Bytes::from_array(output.copy()))
  ) &
    0xFFFFFFFFUL
  generated_put_u32_at(output, offsets[3].to_int() + 8, adjustment)
  Bytes::from_array(output)
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
