///|
fn cff_cid_wb_top(
  charset : UInt64,
  charstrings : UInt64,
  fd_array : UInt64,
  fd_select : UInt64,
  ros_operands? : UInt64 = 3UL,
  include_encoding? : Bool = false,
) -> Bytes {
  let output : Array[Byte] = []
  cff_key_wb_dict_u32(output, charset)
  output.push(b'\x0f')
  if include_encoding {
    cff_key_wb_dict_u32(output, 0UL)
    output.push(b'\x10')
  }
  let mut ros_index = 0UL
  while ros_index < ros_operands {
    cff_key_wb_dict_u32(output, if ros_index == 0UL { 1UL } else { 2UL })
    ros_index = ros_index + 1UL
  }
  output.push(b'\x0c')
  output.push(b'\x1e')
  cff_key_wb_dict_u32(output, charstrings)
  output.push(b'\x11')
  cff_key_wb_dict_u32(output, fd_array)
  output.push(b'\x0c')
  output.push(b'\x24')
  cff_key_wb_dict_u32(output, fd_select)
  output.push(b'\x0c')
  output.push(b'\x25')
  Bytes::from_array(output)
}

///|
fn cff_cid_wb_font_dict(
  private_offset : UInt64,
  custom_matrix : Bool,
) -> Bytes {
  let output : Array[Byte] = []
  cff_key_wb_dict_u32(output, 2UL)
  cff_key_wb_dict_u32(output, private_offset)
  output.push(b'\x12')
  if custom_matrix {
    for value in [2UL, 0UL, 0UL, 2UL, 0UL, 0UL] {
      cff_key_wb_dict_u32(output, value)
    }
    output.push(b'\x0c')
    output.push(b'\x07')
  }
  Bytes::from_array(output)
}

///|
fn cff_cid_wb_table(
  gid_two_fd? : UInt64 = 1UL,
  ros_operands? : UInt64 = 3UL,
  include_encoding? : Bool = false,
  predefined_charset? : Bool = false,
) -> Bytes {
  let header = b"\x01\x00\x04\x04"
  let name = cff_key_wb_index([b"CID"])
  let strings = cff_key_wb_index([])
  let global_subrs = cff_key_wb_index([])
  let charstrings = cff_key_wb_index([b"\x0e", b"\x0e", b"\x0e"])
  let charset = b"\x00\x00\x64\x00\x65"
  let fd_select = Bytes::from_array([
    b'\x00',
    b'\x00',
    b'\x00',
    gid_two_fd.to_byte(),
  ])
  let placeholder_top = cff_cid_wb_top(
    0UL,
    0UL,
    0UL,
    0UL,
    ros_operands~,
    include_encoding~,
  )
  let placeholder_top_index = cff_key_wb_index([placeholder_top])
  let after_global = header.length().to_uint64() +
    name.length().to_uint64() +
    placeholder_top_index.length().to_uint64() +
    strings.length().to_uint64() +
    global_subrs.length().to_uint64()
  let charstrings_offset = after_global
  let charset_offset = charstrings_offset + charstrings.length().to_uint64()
  let fd_select_offset = charset_offset + charset.length().to_uint64()
  let fd_array_offset = fd_select_offset + fd_select.length().to_uint64()
  let placeholder_fd_array = cff_key_wb_index([
    cff_cid_wb_font_dict(0UL, false),
    cff_cid_wb_font_dict(0UL, true),
  ])
  let private_zero_offset = fd_array_offset +
    placeholder_fd_array.length().to_uint64()
  let private_one_offset = private_zero_offset + 4UL
  let fd_array = cff_key_wb_index([
    cff_cid_wb_font_dict(private_zero_offset, false),
    cff_cid_wb_font_dict(private_one_offset, true),
  ])
  let top = cff_cid_wb_top(
    if predefined_charset { 0UL } else { charset_offset },
    charstrings_offset,
    fd_array_offset,
    fd_select_offset,
    ros_operands~,
    include_encoding~,
  )
  let output : Array[Byte] = []
  for part in [
    header,
    name,
    cff_key_wb_index([top]),
    strings,
    global_subrs,
    charstrings,
    charset,
    fd_select,
    fd_array,
    b"\x8d\x13\x00\x00",
    b"\x8d\x13\x00\x00",
  ] {
    cff_key_wb_append(output, part)
  }
  Bytes::from_array(output)
}

///|
test "CFF CID tracer resolves a nonzero GID through FDSelect format zero" {
  let admitted = admit_cff1_structure(
    font_wb_view(cff_wb_otf(cff_cid_wb_table(), num_glyphs=3UL)),
    font_wb_limits(),
    cff_wb_budget(),
    2UL,
  ).unwrap()
  inspect(admitted.glyphs.length(), content="3")
  inspect(admitted.glyph.gid, content="2")
  inspect(admitted.glyph.key_value, content="101")
  inspect(admitted.glyph.environment.fd == Some(1UL), content="true")
  inspect(admitted.glyph.environment.private_dict is Some(_), content="true")
  inspect(admitted.glyph.environment.local_subrs.count, content="0")
  inspect(
    admitted.glyph.environment.top_font_matrix[0].denominator,
    content="1000",
  )
  inspect(admitted.glyph.environment.font_matrix[0].magnitude, content="2")
  inspect(admitted.keying.ros is Some(_), content="true")
  inspect(admitted.keying.fd_count, content="2")
}

///|
test "CFF CID tracer rejects contradictory contracts atomically" {
  cff_key_wb_assert_atomic_error(
    cff_cid_wb_table(ros_operands=2UL),
    "font-cff-top-ros-arity",
  )
  cff_key_wb_assert_atomic_error(
    cff_cid_wb_table(include_encoding=true),
    "font-cff-cid-encoding",
  )
  cff_key_wb_assert_atomic_error(
    cff_cid_wb_table(predefined_charset=true),
    "font-cff-cid-charset",
  )
  cff_key_wb_assert_atomic_error(
    cff_cid_wb_table(gid_two_fd=2UL),
    "font-cff-fd-select-fd",
  )
  cff_key_wb_assert_atomic_error(
    cff_cid_wb_table(),
    "font-cff-charstrings-count",
    num_glyphs=2UL,
  )
}

///|
test "CFF CID tracer names a one-short local Subrs boundary" {
  let exact = cff_cid_wb_table()
  let truncated = Bytes::from_array(
    font_wb_bytes_array(exact)[0:exact.length() - 1],
  )
  cff_key_wb_assert_atomic_error(
    truncated,
    "font-cff-local-subrs-index",
  )
}
