///|
fn cff_name_wb_top(
  charset : UInt64,
  encoding : UInt64,
  charstrings : UInt64,
  private_offset : UInt64,
) -> Bytes {
  let output : Array[Byte] = []
  cff_key_wb_dict_u32(output, charset)
  output.push(b'\x0f')
  cff_key_wb_dict_u32(output, encoding)
  output.push(b'\x10')
  cff_key_wb_dict_u32(output, charstrings)
  output.push(b'\x11')
  cff_key_wb_dict_u32(output, 2UL)
  cff_key_wb_dict_u32(output, private_offset)
  output.push(b'\x12')
  Bytes::from_array(output)
}

///|
fn cff_name_wb_charset(mode : UInt64, duplicate? : Bool = false) -> Bytes {
  match mode {
    3UL =>
      if duplicate {
        b"\x00\x00\x01\x00\x01"
      } else {
        b"\x00\x01\x87\x00\x01"
      }
    4UL => b"\x01\x00\x01\x01"
    5UL => b"\x02\x00\x01\x00\x01"
    _ => b""
  }
}

///|
fn cff_name_wb_encoding(
  mode : UInt64,
  duplicate_codes? : Bool = false,
  short_cardinality? : Bool = false,
  notdef_supplement? : Bool = false,
) -> Bytes {
  match mode {
    2UL =>
      if short_cardinality {
        b"\x00\x01\x41"
      } else if duplicate_codes {
        b"\x00\x02\x41\x41"
      } else {
        b"\x00\x02\x41\x42"
      }
    3UL => b"\x01\x01\x41\x01"
    4UL => {
      let output : Array[Byte] = [
        b'\x80',
        b'\x02',
        b'\x41',
        b'\x42',
        b'\x01',
        b'\x43',
      ]
      font_wb_put_u16(output, if notdef_supplement { 0UL } else { 391UL })
      Bytes::from_array(output)
    }
    5UL => b"\x01\x01\xff\x01"
    _ => b""
  }
}

///|
fn cff_name_wb_table(
  charset_mode? : UInt64 = 3UL,
  encoding_mode? : UInt64 = 2UL,
  include_string? : Bool = true,
  duplicate_charset? : Bool = false,
  duplicate_codes? : Bool = false,
  short_cardinality? : Bool = false,
  notdef_supplement? : Bool = false,
) -> Bytes {
  let header = b"\x01\x00\x04\x04"
  let name = cff_key_wb_index([b"Name"])
  let strings = if include_string {
    cff_key_wb_index([b"custom"])
  } else {
    cff_key_wb_index([])
  }
  let global_subrs = cff_key_wb_index([])
  let charstrings = cff_key_wb_index([b"\x0e", b"\x0e", b"\x0e"])
  let private_data = b"\x8d\x13\x00\x00"
  let charset_data = cff_name_wb_charset(
    charset_mode,
    duplicate=duplicate_charset,
  )
  let encoding_data = cff_name_wb_encoding(
    encoding_mode,
    duplicate_codes~,
    short_cardinality~,
    notdef_supplement~,
  )
  let placeholder_top = cff_name_wb_top(0UL, 0UL, 0UL, 0UL)
  let after_global = header.length().to_uint64() +
    name.length().to_uint64() +
    cff_key_wb_index([placeholder_top]).length().to_uint64() +
    strings.length().to_uint64() +
    global_subrs.length().to_uint64()
  let charstrings_offset = after_global
  let private_offset = charstrings_offset + charstrings.length().to_uint64()
  let charset_offset = private_offset + private_data.length().to_uint64()
  let encoding_offset = charset_offset + charset_data.length().to_uint64()
  let top = cff_name_wb_top(
    if charset_mode < 3UL { charset_mode } else { charset_offset },
    if encoding_mode < 2UL { encoding_mode } else { encoding_offset },
    charstrings_offset,
    private_offset,
  )
  let output : Array[Byte] = []
  for part in [
    header,
    name,
    cff_key_wb_index([top]),
    strings,
    global_subrs,
    charstrings,
    private_data,
    charset_data,
    encoding_data,
  ] {
    cff_key_wb_append(output, part)
  }
  Bytes::from_array(output)
}

///|
test "CFF name keying resolves all predefined charset and Encoding pairs" {
  for item in [
    (0UL, 0UL, 2UL),
    (1UL, 1UL, 229UL),
    (2UL, 1UL, 231UL),
  ] {
    let admitted = admit_cff1_structure(
      font_wb_view(
        cff_wb_otf(
          cff_name_wb_table(
            charset_mode=item.0,
            encoding_mode=item.1,
          ),
          num_glyphs=3UL,
        ),
      ),
      font_wb_limits(),
      cff_wb_budget(),
      2UL,
    ).unwrap()
    inspect(admitted.glyphs.length(), content="3")
    inspect(admitted.glyph.key_value, content=item.2.to_string())
    inspect(admitted.keying.charset.predefined == Some(item.0), content="true")
    inspect(admitted.keying.encoding.unwrap().predefined == Some(item.1), content="true")
    inspect(admitted.keying.encoding.unwrap().codes.length(), content="2")
    inspect(admitted.glyph.environment.fd is None, content="true")
    inspect(admitted.glyph.environment.private_dict is Some(_), content="true")
    inspect(admitted.glyph.environment.local_subrs.count, content="0")
  }
}

///|
test "CFF name keying resolves custom charset zero one two and Encoding zero one" {
  for item in [(3UL, 2UL), (4UL, 3UL), (5UL, 2UL)] {
    let admitted = admit_cff1_structure(
      font_wb_view(
        cff_wb_otf(
          cff_name_wb_table(
            charset_mode=item.0,
            encoding_mode=item.1,
          ),
          num_glyphs=3UL,
        ),
      ),
      font_wb_limits(),
      cff_wb_budget(),
      1UL,
    ).unwrap()
    inspect(admitted.glyphs.length(), content="3")
    inspect(admitted.keying.charset.format, content=(item.0 - 3UL).to_string())
    inspect(admitted.keying.encoding.unwrap().format, content=(item.1 - 2UL).to_string())
    inspect(admitted.keying.encoding.unwrap().codes[0], content="65")
    inspect(admitted.keying.encoding.unwrap().gids[1], content="2")
  }
}

///|
test "CFF name keying validates supplements through one SID domain" {
  let admitted = admit_cff1_structure(
    font_wb_view(
      cff_wb_otf(
        cff_name_wb_table(encoding_mode=4UL),
        num_glyphs=3UL,
      ),
    ),
    font_wb_limits(),
    cff_wb_budget(),
    1UL,
  ).unwrap()
  inspect(admitted.keying.encoding.unwrap().codes.length(), content="3")
  inspect(admitted.keying.encoding.unwrap().codes[2], content="67")
  inspect(admitted.keying.encoding.unwrap().gids[2], content="1")
}

///|
test "CFF name keying rejects SID code range and cardinality faults atomically" {
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(include_string=false),
    "font-cff-charset-sid",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(duplicate_charset=true),
    "font-cff-sid-duplicate",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(duplicate_codes=true),
    "font-cff-encoding-code-duplicate",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(short_cardinality=true),
    "font-cff-encoding-cardinality",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(encoding_mode=4UL, notdef_supplement=true),
    "font-cff-encoding-notdef",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(encoding_mode=5UL),
    "font-cff-encoding-range",
  )
}

///|
test "CFF name keying reports one-short custom Encoding supplement" {
  let exact = cff_name_wb_table(encoding_mode=4UL)
  let truncated = Bytes::from_array(
    font_wb_bytes_array(exact)[0:exact.length() - 1],
  )
  cff_key_wb_assert_atomic_error(
    truncated,
    "font-cff-encoding-supplement",
  )
}
