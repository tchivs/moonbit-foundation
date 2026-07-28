///|
test "CFF DICT decodes integer real and escaped structural operands exactly" {
  for
    item in [
      (b"\x8B", false, 0UL, 1UL),
      (b"\xEF", false, 100UL, 1UL),
      (b"\x27", true, 100UL, 1UL),
      (b"\xF7\x00", false, 108UL, 1UL),
      (b"\xFB\x00", true, 108UL, 1UL),
      (b"\x1C\x00\x2A", false, 42UL, 1UL),
      (b"\x1C\xFF\xD6", true, 42UL, 1UL),
      (b"\x1D\x00\x00\x00\x2A", false, 42UL, 1UL),
      (b"\x1D\xFF\xFF\xFF\xD6", true, 42UL, 1UL),
      (b"\x1E\x1A\x5F", false, 15UL, 10UL),
    ] {
    let decoded = cff_decode_dict_number(
        font_wb_view(item.0),
        0UL,
        "cff-dict-number-test",
      ).unwrap().0
    inspect(decoded.negative == item.1, content="true")
    inspect(decoded.magnitude == item.2, content="true")
    inspect(decoded.denominator == item.3, content="true")
  }
  let top = cff_decode_top_dict(font_wb_view(b"\x8D\x0C\x06\x8C\x11")).unwrap()
  inspect(top.charstring_type.magnitude, content="2")
  inspect(top.charstring_type_explicit, content="true")
  inspect(top.charstrings.value, content="1")
}

///|
test "CFF typed DICT schemas apply defaults and preserve named offset bases" {
  let top = cff_decode_top_dict(font_wb_view(b"\x95\x11\x8D\xA0\x12")).unwrap()
  inspect(top.charstring_type.magnitude, content="2")
  inspect(top.charstring_type_explicit, content="false")
  inspect(top.charstrings.value, content="10")
  inspect(top.private_range.unwrap().size, content="2")
  inspect(top.private_range.unwrap().offset.value, content="21")
  inspect(top.font_matrix.length(), content="6")
  inspect(top.font_matrix[0].magnitude, content="1")
  inspect(top.font_matrix[0].denominator, content="1000")

  let font = cff_decode_font_dict(
    font_wb_view(b"\x8D\xA0\x12\x8C\x8B\x8B\x8C\x8B\x8B\x0C\x07"),
  ).unwrap()
  inspect(font.private_range.unwrap().offset.value, content="21")
  inspect(font.font_matrix.unwrap().length(), content="6")

  let inherited = cff_decode_font_dict(
    font_wb_view(b"\x8D\xA0\x12"),
  ).unwrap()
  inspect(inherited.font_matrix is None, content="true")

  let private = cff_decode_private_dict(
    font_wb_view(b"\x8D\x13\xEF\x14\x27\x15"),
  ).unwrap()
  inspect(private.local_subrs.unwrap().value, content="2")
  inspect(private.default_width_x.magnitude, content="100")
  inspect(private.nominal_width_x.negative, content="true")
  inspect(private.nominal_width_x.magnitude, content="100")
  inspect(private.initial_random_seed.raw, content="0")
}

///|
test "CFF Private DICT retains checked initialRandomSeed integer and real facts" {
  for item in [
    (b"\x8D\x0C\x13", 131072L),
    (b"\x1E\x1A\x5F\x0C\x13", 98304L),
    (b"\x27\x0C\x13", -6553600L),
  ] {
    let private = cff_decode_private_dict(font_wb_view(item.0)).unwrap()
    inspect(private.initial_random_seed.raw, content=item.1.to_string())
  }
  for item in [
    (
      b"\x8C\x0C\x13\x8D\x0C\x13",
      "font-cff-private-initial-random-seed-duplicate",
    ),
    (
      b"\x1D\x00\x00\x80\x00\x0C\x13",
      "font-cff-private-initial-random-seed",
    ),
  ] {
    let error = cff_decode_private_dict(font_wb_view(item.0)).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some(item.1), content="true")
  }
}

///|
test "CFF Top DICT retains CID INDEX offsets without decoding their keying model" {
  let top = cff_decode_top_dict(
    font_wb_view(b"\x8B\x8C\x8B\x0C\x1E\x95\x0C\x24\x9F\x0C\x25\xA9\x11"),
  ).unwrap()
  inspect(top.ros.unwrap().registry_sid, content="0")
  inspect(top.ros.unwrap().ordering_sid, content="1")
  inspect(top.ros.unwrap().supplement, content="0")
  inspect(top.fd_array.unwrap().value, content="10")
  inspect(top.fd_select.unwrap().value, content="20")
  inspect(top.charstrings.value, content="30")

  let fd_array = cff_decode_index(
      font_wb_view(cff_index_wb_single(2UL, b"\x8D\xA0\x12")),
      0UL,
      4UL,
      "font-cff-fd-array-index",
    ).unwrap().0
  let font_dict = cff_decode_font_dict(
    cff_index_object(fd_array, 0UL, "font-cff-fd-array-index").unwrap().view,
  ).unwrap()
  inspect(font_dict.private_range.unwrap().size, content="2")
  inspect(font_dict.private_range.unwrap().offset.value, content="21")
}

///|
test "CFF typed DICT rejects wrong arity duplicate reserved and truncated forms" {
  inspect(
    cff_decode_top_dict(font_wb_view(b"\x8B\x8C\x00\x8C\x11")) is Err(_),
    content="true",
  )
  inspect(
    cff_decode_top_dict(font_wb_view(b"\x8C\x11\x8D\x11")) is Err(_),
    content="true",
  )
  inspect(
    cff_decode_private_dict(font_wb_view(b"\x8C\x13\x8D\x13")) is Err(_),
    content="true",
  )
  inspect(
    cff_decode_top_dict(
      font_wb_view(b"\x8B\x8C\x8B\x0C\x1E\x8C\x8D\x8C\x0C\x1E\x8C\x11"),
    )
    is Err(_),
    content="true",
  )
  for malformed in [b"\xFF", b"\x1C\x00", b"\x1D\x00\x00", b"\x1E\x1A"] {
    inspect(
      cff_parse_dict(font_wb_view(malformed), "cff-dict-test") is Err(_),
      content="true",
    )
  }
}

///|
test "CFF DICT rejects malformed real grammar and non-FF terminator padding" {
  for malformed in [
    b"\x1E\x1B\xFF",
    b"\x1E\x1C\xFF",
    b"\x1E\x1E\x2F",
    b"\x1E\x1A\xEF",
    b"\x1E\x10\xF0",
  ] {
    inspect(
      cff_parse_dict(font_wb_view(malformed), "cff-dict-real-test") is Err(_),
      content="true",
    )
  }
}

///|
test "CFF DICT enforces the 48 operand stack limit before allocation growth" {
  let accepted : Array[Byte] = []
  for index = 0; index < 48; index = index + 1 {
    accepted.push(b'\x8B')
  }
  accepted.push(b'\x05')
  inspect(
    cff_parse_dict(
      font_wb_view(Bytes::from_array(accepted)),
      "cff-dict-stack-test",
    )
    is Ok(_),
    content="true",
  )

  let rejected : Array[Byte] = []
  for index = 0; index < 49; index = index + 1 {
    rejected.push(b'\x8B')
  }
  rejected.push(b'\x05')
  inspect(
    cff_parse_dict(
      font_wb_view(Bytes::from_array(rejected)),
      "cff-dict-stack-test",
    )
    is Err(_),
    content="true",
  )
}

///|
test "CFF typed DICT rejects invalid SID and boolean domains" {
  for malformed in [
    b"\x8A\x02\x8C\x11",
    b"\x1E\x1A\x5F\x02\x8C\x11",
    b"\x8D\x0C\x01\x8C\x11",
  ] {
    inspect(
      cff_decode_top_dict(font_wb_view(malformed)) is Err(_),
      content="true",
    )
  }
  inspect(
    cff_decode_font_dict(font_wb_view(b"\x8A\x0C\x26")) is Err(_),
    content="true",
  )
  inspect(
    cff_decode_private_dict(font_wb_view(b"\x8D\x0C\x0E")) is Err(_),
    content="true",
  )
  inspect(
    cff_decode_top_dict(
      font_wb_view(b"\x1D\x00\x00\xFD\xE8\x02\x8C\x11"),
    )
    is Err(_),
    content="true",
  )
  inspect(
    cff_decode_top_dict(
      font_wb_view(b"\x1D\x00\x00\xFD\xE8\x8B\x8B\x0C\x1E\x8C\x11"),
    )
    is Err(_),
    content="true",
  )
}

///|
test "CFF Top DICT rejects unsupported semantic operators as capabilities" {
  for operator in [b'\x14', b'\x15', b'\x16', b'\x17'] {
    let source : Array[Byte] = [b'\x8B', b'\x0C', operator, b'\x8C', b'\x11']
    let error = cff_decode_top_dict(
      font_wb_view(Bytes::from_array(source)),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Capability, content="true")
    inspect(
      error.context() == Some("font-cff-top-operator-unsupported"),
      content="true",
    )
  }
}

///|
fn cff_dict_wb_assert_top_error(
  source : Bytes,
  category : @error.ErrorCategory,
  context : String,
) -> Unit raise {
  let result = cff_decode_top_dict(font_wb_view(source))
  inspect(result is Err(_), content="true")
  let error = result.unwrap_err()
  inspect(error.category() == category, content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
test "CFF Top DICT closes PaintType and StrokeWidth profile" {
  let required = b"\x8C\x11"
  for supported in [
    required,
    b"\x8B\x0C\x05\x8C\x11",
    b"\x1E\x0F\x0C\x05\x8C\x11",
    b"\x1E\xE0\xFF\x0C\x05\x8C\x11",
    b"\x8B\x0C\x08\x8C\x11",
    b"\x1E\x0F\x0C\x08\x8C\x11",
    b"\x1E\xE0\xFF\x0C\x08\x8C\x11",
    b"\x8B\x0C\x05\x1E\x0F\x0C\x08\x8C\x11",
  ] {
    inspect(cff_decode_top_dict(font_wb_view(supported)) is Ok(_), content="true")
  }

  for unsupported in [
    b"\x8D\x0C\x05\x8C\x11",
    b"\x1E\x2A\x0F\x0C\x05\x8C\x11",
    b"\x8C\x0C\x05\x8C\x11",
    b"\x8A\x0C\x05\x8C\x11",
    b"\x1E\x0A\x5F\x0C\x05\x8C\x11",
    b"\x1E\xE0\xA5\xFF\x0C\x05\x8C\x11",
  ] {
    cff_dict_wb_assert_top_error(
      unsupported,
      @error.ErrorCategory::Capability,
      "font-cff-paint-type-unsupported",
    )
  }
  for unsupported in [
    b"\x8D\x0C\x08\x8C\x11",
    b"\x1E\x2A\x0F\x0C\x08\x8C\x11",
    b"\x8C\x0C\x08\x8C\x11",
    b"\x8A\x0C\x08\x8C\x11",
    b"\x1E\x0A\x5F\x0C\x08\x8C\x11",
    b"\x1E\xE0\xA5\xFF\x0C\x08\x8C\x11",
    b"\x8B\x0C\x05\x8D\x0C\x08\x8C\x11",
  ] {
    cff_dict_wb_assert_top_error(
      unsupported,
      @error.ErrorCategory::Capability,
      "font-cff-stroke-width-unsupported",
    )
  }

  for item in [
    (b"\x0C\x05", "font-cff-top-dict-arity"),
    (b"\x1C\x00", "font-cff-top-dict"),
    (b"\x8B\x0C", "font-cff-top-dict-operator"),
    (b"\x16", "font-cff-top-dict-reserved"),
    (b"\x1E\xAF", "font-cff-top-dict-real"),
    (b"\x1E\x0D", "font-cff-top-dict-real-reserved"),
    (b"\x1E\x0A\xF0", "font-cff-top-dict-real-padding"),
    (
      b"\x1E\x1B\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x99\x9F",
      "font-cff-top-dict-real-range",
    ),
    (b"\x8B", "font-cff-top-dict-truncated"),
  ] {
    cff_dict_wb_assert_top_error(
      item.0,
      @error.ErrorCategory::Data,
      item.1,
    )
  }

  for item in [
    (
      b"\x8B\x8B\x0C\x05\x8C\x11",
      "font-cff-top-paint-type-arity",
    ),
    (
      b"\x8B\x8B\x0C\x08\x8C\x11",
      "font-cff-top-stroke-width-arity",
    ),
    (
      b"\x8B\x0C\x05\x8B\x0C\x05\x8C\x11",
      "font-cff-top-paint-type-duplicate",
    ),
    (
      b"\x8B\x0C\x08\x8B\x0C\x08\x8C\x11",
      "font-cff-top-stroke-width-duplicate",
    ),
  ] {
    cff_dict_wb_assert_top_error(
      item.0,
      @error.ErrorCategory::Data,
      item.1,
    )
  }

  for malformed_suffix in [b"\x1C\x00", b"\x8B\x0C", b"\x16"] {
    let paint : Array[Byte] = [
      b'\x8D', b'\x0C', b'\x05',
    ]
    let stroke : Array[Byte] = [
      b'\x8D', b'\x0C', b'\x08',
    ]
    for byte in font_wb_bytes_array(malformed_suffix) {
      paint.push(byte)
      stroke.push(byte)
    }
    cff_dict_wb_assert_top_error(
      Bytes::from_array(paint),
      @error.ErrorCategory::Capability,
      "font-cff-paint-type-unsupported",
    )
    cff_dict_wb_assert_top_error(
      Bytes::from_array(stroke),
      @error.ErrorCategory::Capability,
      "font-cff-stroke-width-unsupported",
    )
  }

  for item in [
    (
      b"\x16\x8D\x0C\x05",
      "font-cff-top-dict-reserved",
    ),
    (
      b"\x1E\x0D\x8D\x0C\x08",
      "font-cff-top-dict-real-reserved",
    ),
    (
      b"\x1E\x0A\xF0\x8D\x0C\x05",
      "font-cff-top-dict-real-padding",
    ),
  ] {
    cff_dict_wb_assert_top_error(
      item.0,
      @error.ErrorCategory::Data,
      item.1,
    )
  }
}

///|
test "CFF typed DICT resolves retained SIDs against String INDEX domain" {
  let top = cff_decode_top_dict(
    font_wb_view(b"\x1C\x01\x87\x02\x8C\x11"),
  ).unwrap()
  let strings = cff_decode_index(
      font_wb_view(b"\x00\x00"),
      0UL,
      1UL,
      "cff-dict-string-test",
    ).unwrap().0
  inspect(top.sid_operands.length(), content="1")
  inspect(
    cff_validate_sid(top.sid_operands[0], strings, "font-cff-top-sid") is Err(_),
    content="true",
  )
}

///|
test "CFF Private DICT distinguishes paired blue zones from StemSnap deltas" {
  let blue : Array[Byte] = []
  for index = 0; index < 16; index = index + 1 {
    blue.push(b'\x8B')
  }
  blue.push(b'\x06')
  inspect(
    cff_decode_private_dict(font_wb_view(Bytes::from_array(blue))) is Err(_),
    content="true",
  )

  for accepted_count in [1, 11, 12] {
    let stems : Array[Byte] = []
    for index = 0; index < accepted_count; index = index + 1 {
      stems.push(b'\x8B')
    }
    stems.push(b'\x0C')
    stems.push(b'\x0C')
    inspect(
      cff_decode_private_dict(font_wb_view(Bytes::from_array(stems))) is Ok(_),
      content="true",
    )
  }

  let stems : Array[Byte] = []
  for index = 0; index < 13; index = index + 1 {
    stems.push(b'\x8B')
  }
  stems.push(b'\x0C')
  stems.push(b'\x0C')
  inspect(
    cff_decode_private_dict(font_wb_view(Bytes::from_array(stems))) is Err(_),
    content="true",
  )
}
