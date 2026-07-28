///|
fn cff_wb_maxp_table(num_glyphs : UInt64) -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u32(output, 0x00005000UL)
  font_wb_put_u16(output, num_glyphs)
  Bytes::from_array(output)
}

///|
fn cff_wb_table(
  charstring_type? : UInt64 = 2UL,
  omit_type? : Bool = true,
) -> Bytes {
  let dict_length = if omit_type { 5UL } else { 8UL }
  let charstrings_offset = 22UL + dict_length
  let private_offset = charstrings_offset + 6UL
  let output : Array[Byte] = [
    b'\x01',
    b'\x00',
    b'\x04',
    b'\x04',
    b'\x00',
    b'\x01',
    b'\x01',
    b'\x01',
    b'\x05',
    b'T',
    b'e',
    b's',
    b't',
    b'\x00',
    b'\x01',
    b'\x01',
    b'\x01',
    (dict_length + 1UL).to_byte(),
  ]
  if !omit_type {
    output.push((charstring_type + 139UL).to_byte())
    output.push(b'\x0c')
    output.push(b'\x06')
  }
  output.push((charstrings_offset + 139UL).to_byte())
  output.push(b'\x11')
  output.push(b'\x8d')
  output.push((private_offset + 139UL).to_byte())
  output.push(b'\x12')
  output.push(b'\x00')
  output.push(b'\x00')
  output.push(b'\x00')
  output.push(b'\x00')
  output.push(b'\x00')
  output.push(b'\x01')
  output.push(b'\x01')
  output.push(b'\x01')
  output.push(b'\x02')
  output.push(b'\x0e')
  output.push(b'\x8d')
  output.push(b'\x13')
  output.push(b'\x00')
  output.push(b'\x00')
  Bytes::from_array(output)
}

///|
fn cff_wb_otf_tables(tables : Array[GeneratedFontTable]) -> Bytes {
  let sfnt = font_wb_build_sfnt(tables)
  let patched = font_wb_put_u32_at_copy(sfnt, 0, 0x4F54544FUL)
  let output = font_wb_bytes_array(patched)
  let head_offset = font_wb_table_offset(patched, b"head")
  generated_put_u32_at(output, head_offset + 8, 0UL)
  let adjustment = (
      0xB1B0AFBAUL - generated_checksum(Bytes::from_array(output.copy()))
    ) &
    0xFFFFFFFFUL
  generated_put_u32_at(output, head_offset + 8, adjustment)
  Bytes::from_array(output)
}

///|
fn cff_wb_otf(cff : Bytes, num_glyphs? : UInt64 = 1UL) -> Bytes {
  cff_wb_otf_with_cmap(cff, generated_cmap_table(), num_glyphs~)
}

///|
fn cff_wb_otf_with_cmap(
  cff : Bytes,
  cmap : Bytes,
  num_glyphs? : UInt64 = 1UL,
) -> Bytes {
  let hmtx = Array::make(
    (4UL + (num_glyphs - 1UL) * 2UL).to_int(),
    b'\x00',
  )
  cff_wb_otf_tables([
    font_wb_table(b"CFF ", cff),
    font_wb_table(b"OS/2", generated_os2_table()),
    font_wb_table(b"cmap", cmap),
    font_wb_table(b"head", generated_head_table()),
    font_wb_table(b"hhea", generated_hhea_table()),
    font_wb_table(b"hmtx", Bytes::from_array(hmtx)),
    font_wb_table(b"maxp", cff_wb_maxp_table(num_glyphs)),
    font_wb_table(b"name", b"\x00\x00\x00\x00\x00\x06"),
    font_wb_table(b"post", generated_post_table()),
  ])
}

///|
fn cff_wb_cmap_format4_two_segments() -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, 3UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u32(output, 12UL)
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, 34UL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 0x0041UL)
  font_wb_put_u16(output, 0xFFFFUL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 0x0041UL)
  font_wb_put_u16(output, 0xFFFFUL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 1UL)
  font_wb_put_u16(output, 4UL)
  font_wb_put_u16(output, 0UL)
  font_wb_put_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn cff_wb_otf_without_common(tag : Bytes) -> Bytes {
  let tables : Array[GeneratedFontTable] = []
  for table in [
    font_wb_table(b"CFF ", cff_wb_table()),
    font_wb_table(b"OS/2", generated_os2_table()),
    font_wb_table(b"cmap", generated_cmap_table()),
    font_wb_table(b"head", generated_head_table()),
    font_wb_table(b"hhea", generated_hhea_table()),
    font_wb_table(b"hmtx", b"\x00\x00\x00\x00"),
    font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
    font_wb_table(b"name", b"\x00\x00\x00\x00\x00\x06"),
    font_wb_table(b"post", generated_post_table()),
  ] {
    if table.tag != tag {
      tables.push(table)
    }
  }
  cff_wb_otf_tables(tables)
}

///|
fn cff_wb_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=32UL,
      allocation_size=16384UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
test "CFF1 tracer admits default and explicit Type 2 then resolves GID zero" {
  for
    item in [
      (cff_wb_table(), false),
      (cff_wb_table(charstring_type=2UL, omit_type=false), true),
    ] {
    let admitted = admit_cff1_structure(
      font_wb_view(cff_wb_otf(item.0)),
      font_wb_limits(),
      cff_wb_budget(),
      0UL,
    ).unwrap()
    inspect(admitted.top.charstring_type.magnitude, content="2")
    inspect(admitted.top.charstring_type.negative, content="false")
    inspect(admitted.top.charstring_type_explicit, content=item.1.to_string())
    inspect(admitted.charstrings.count, content="1")
    inspect(admitted.glyph.gid, content="0")
    inspect(admitted.glyph.charstring.view.length(), content="1")
    inspect(
      admitted.glyph.charstring.view.get(0UL).unwrap(),
      content="b'\\x0E'",
    )
    inspect(admitted.glyph.environment.private_dict.local_subrs is Some(_), content="true")
    inspect(admitted.glyph.environment.local_subrs.count, content="0")
    inspect(admitted.glyph.environment.font_matrix.length(), content="6")
  }
}

///|
test "CFF1 tracer rejects non-Type-2 before publication or budget charge" {
  let budget = cff_wb_budget()
  let before = budget.remaining()
  let result = admit_cff1_structure(
    font_wb_view(cff_wb_otf(cff_wb_table(charstring_type=1UL, omit_type=false))),
    font_wb_limits(),
    budget,
    0UL,
  )
  inspect(result is Err(_), content="true")
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(error.context() == Some("font-cff-charstring-type"), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(
    budget.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "CFF1 admission requires every validated common OpenType table" {
  for tag in [
    b"OS/2", b"cmap", b"head", b"hhea", b"hmtx", b"name", b"post",
  ] {
    let budget = cff_wb_budget()
    let before = budget.remaining()
    let result = admit_cff1_structure(
      font_wb_view(cff_wb_otf_without_common(tag)),
      font_wb_limits(),
      budget,
      0UL,
    )
    inspect(result is Err(_), content="true")
    inspect(budget.remaining().bytes() == before.bytes(), content="true")
    inspect(budget.remaining().work() == before.work(), content="true")
  }
}

///|
test "CFF1 tracer freezes profile capability precedence before CFF traversal" {
  let malformed_cff = b"\x01"
  let cases = [
    cff_wb_otf_tables([
      font_wb_table(b"CFF ", malformed_cff),
      font_wb_table(b"glyf", b""),
      font_wb_table(b"head", generated_head_table()),
      font_wb_table(b"loca", b""),
      font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
    ]),
    cff_wb_otf_tables([
      font_wb_table(b"CFF ", malformed_cff),
      font_wb_table(b"CFF2", b""),
      font_wb_table(b"head", generated_head_table()),
      font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
    ]),
    cff_wb_otf_tables([
      font_wb_table(b"CFF ", malformed_cff),
      font_wb_table(b"CFF ", malformed_cff),
      font_wb_table(b"head", generated_head_table()),
      font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
    ]),
    cff_wb_otf_tables([
      font_wb_table(b"CFF ", malformed_cff),
      font_wb_table(b"fvar", b""),
      font_wb_table(b"head", generated_head_table()),
      font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
    ]),
  ]
  for source in cases {
    let error = admit_cff1_structure(
      font_wb_view(source),
      font_wb_limits(),
      cff_wb_budget(),
      0UL,
    ).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
    inspect(error.context() == Some("font-cff-profile"), content="true")
  }
  let wrong_maxp = cff_wb_otf_tables([
    font_wb_table(b"CFF ", malformed_cff),
    font_wb_table(b"head", generated_head_table()),
    font_wb_table(b"maxp", generated_maxp_table()),
  ])
  let error = admit_cff1_structure(
    font_wb_view(wrong_maxp),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(error.context() == Some("font-cff-maxp-profile"), content="true")
}

///|
test "CFF1 tracer reports exact stage on one-short structure and charges nothing" {
  let exact = cff_wb_table()
  for
    item in [
      (3, "font-cff-header"),
      (12, "font-cff-name-index-terminal-extent"),
      (22, "font-cff-top-index-terminal-extent"),
      (24, "font-cff-string-index"),
      (26, "font-cff-global-subrs-index"),
      (32, "font-cff-charstrings-index-terminal-extent"),
      (34, "font-cff-private-range"),
      (36, "font-cff-local-subrs-index"),
    ] {
    let truncated = Bytes::from_array(font_wb_bytes_array(exact)[0:item.0])
    let budget = cff_wb_budget()
    let before = budget.remaining()
    let error = admit_cff1_structure(
      font_wb_view(cff_wb_otf(truncated)),
      font_wb_limits(),
      budget,
      0UL,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.context() == Some(item.1), content="true")
    inspect(budget.remaining().bytes() == before.bytes(), content="true")
    inspect(budget.remaining().work() == before.work(), content="true")
  }
}
