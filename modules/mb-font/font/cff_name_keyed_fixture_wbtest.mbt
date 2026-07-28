///|
fn cff_name_wb_top(
  charset : UInt64,
  encoding : UInt64,
  charstrings : UInt64,
  private_offset : UInt64,
  include_private? : Bool = true,
) -> Bytes {
  let output : Array[Byte] = []
  cff_key_wb_dict_u32(output, charset)
  output.push(b'\x0f')
  cff_key_wb_dict_u32(output, encoding)
  output.push(b'\x10')
  cff_key_wb_dict_u32(output, charstrings)
  output.push(b'\x11')
  if include_private {
    cff_key_wb_dict_u32(output, 2UL)
    cff_key_wb_dict_u32(output, private_offset)
    output.push(b'\x12')
  }
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
  unencoded_supplement? : Bool = false,
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
        if unencoded_supplement { b'\x01' } else { b'\x02' },
        b'\x41',
      ]
      if !unencoded_supplement {
        output.push(b'\x42')
      }
      output.push(b'\x01')
      output.push(b'\x43')
      font_wb_put_u16(
        output,
        if notdef_supplement {
          0UL
        } else if unencoded_supplement {
          1UL
        } else {
          391UL
        },
      )
      Bytes::from_array(output)
    }
    5UL => b"\x01\x01\xff\x01"
    6UL => {
      // One main code plus every remaining byte code as a supplement. Every
      // supplement resolves SID 1 to the already encoded GID 1, so the two
      // retained UInt64 arrays each reach exactly 256 entries (2048 bytes).
      let output : Array[Byte] = [b'\x80', b'\x01', b'\x00', b'\xFF']
      for code = 1; code < 256; code = code + 1 {
        output.push(code.to_byte())
        font_wb_put_u16(output, 1UL)
      }
      Bytes::from_array(output)
    }
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
  unencoded_supplement? : Bool = false,
  include_private? : Bool = true,
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
    unencoded_supplement~,
  )
  let placeholder_top = cff_name_wb_top(
    0UL,
    0UL,
    0UL,
    0UL,
    include_private~,
  )
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
    include_private~,
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
    inspect(admitted.glyphs[2].key_value, content=item.2.to_string())
    inspect(admitted.keying.charset.predefined == Some(item.0), content="true")
    inspect(admitted.keying.encoding.unwrap().predefined == Some(item.1), content="true")
    inspect(admitted.keying.encoding.unwrap().codes.length(), content="2")
    inspect(admitted.glyphs[2].environment.fd is None, content="true")
    inspect(admitted.glyphs[2].environment.private_dict.local_subrs is Some(_), content="true")
    inspect(admitted.glyphs[2].environment.local_subrs.count, content="0")
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
test "CFF allocation authority uses concrete predefined and custom Encoding maxima" {
  let predefined = cff_wb_otf(
    cff_name_wb_table(charset_mode=0UL, encoding_mode=0UL),
    num_glyphs=3UL,
  )
  let predefined_exact = cff_hostile_budget(
    predefined.length().to_uint64() + 120UL,
    64UL,
    2048UL,
    65536UL,
  )
  let admitted = admit_cff1_structure(
    font_wb_view(predefined),
    font_wb_limits(),
    predefined_exact,
    2UL,
  ).unwrap()
  inspect(admitted.charge.allocation_size, content="2048")

  let predefined_short = cff_hostile_budget(
    predefined.length().to_uint64() + 120UL,
    64UL,
    2047UL,
    65536UL,
  )
  let predefined_before = predefined_short.remaining()
  let predefined_error = admit_cff1_structure(
    font_wb_view(predefined),
    font_wb_limits(),
    predefined_short,
    2UL,
  ).unwrap_err()
  inspect(
    predefined_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    predefined_error.context() == Some("allocation_size"),
    content="true",
  )
  inspect(
    predefined_short.remaining().bytes() == predefined_before.bytes(),
    content="true",
  )
  inspect(
    predefined_short.remaining().allocations() ==
    predefined_before.allocations(),
    content="true",
  )
  inspect(
    predefined_short.remaining().allocation_size() ==
    predefined_before.allocation_size(),
    content="true",
  )
  inspect(
    predefined_short.remaining().work() == predefined_before.work(),
    content="true",
  )

  let custom = cff_wb_otf(
    cff_name_wb_table(
      charset_mode=0UL,
      encoding_mode=6UL,
      include_string=false,
    ),
    num_glyphs=3UL,
  )
  let exact = cff_hostile_budget(
    custom.length().to_uint64() + 120UL,
    64UL,
    2048UL,
    65536UL,
  )
  let custom_admitted = admit_cff1_structure(
    font_wb_view(custom),
    font_wb_limits(),
    exact,
    1UL,
  ).unwrap()
  inspect(custom_admitted.keying.encoding.unwrap().codes.length(), content="256")
  inspect(custom_admitted.charge.allocation_size, content="2048")

  let short = cff_hostile_budget(
    custom.length().to_uint64() + 120UL,
    64UL,
    2047UL,
    65536UL,
  )
  let before = short.remaining()
  let error = admit_cff1_structure(
    font_wb_view(custom),
    font_wb_limits(),
    short,
    1UL,
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.context() == Some("allocation_size"), content="true")
  inspect(short.remaining().bytes() == before.bytes(), content="true")
  inspect(short.remaining().allocations() == before.allocations(), content="true")
  inspect(short.remaining().work() == before.work(), content="true")
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
    cff_name_wb_table(encoding_mode=4UL, notdef_supplement=true),
    "font-cff-encoding-notdef",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(encoding_mode=5UL),
    "font-cff-encoding-range",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(encoding_mode=4UL, unencoded_supplement=true),
    "font-cff-encoding-supplement-gid",
  )
  cff_key_wb_assert_atomic_error(
    cff_name_wb_table(include_private=false),
    "font-cff-name-private-required",
  )
}

///|
test "CFF custom Encoding may leave trailing glyphs unencoded" {
  let admitted = admit_cff1_structure(
    font_wb_view(
      cff_wb_otf(
        cff_name_wb_table(short_cardinality=true),
        num_glyphs=3UL,
      ),
    ),
    font_wb_limits(),
    cff_wb_budget(),
    2UL,
  ).unwrap()
  inspect(admitted.keying.encoding.unwrap().codes.length(), content="1")
  inspect(admitted.keying.encoding.unwrap().gids[0], content="1")
  inspect(admitted.glyphs[2].gid, content="2")
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
