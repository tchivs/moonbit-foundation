///|
fn cff_wb_maxp_table(num_glyphs : UInt64) -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u32(output, 0x00005000UL)
  font_wb_put_u16(output, num_glyphs)
  Bytes::from_array(output)
}

///|
fn cff_wb_table(charstring_type? : UInt64 = 2UL, omit_type? : Bool = true) -> Bytes {
  let dict_length = if omit_type { 5UL } else { 8UL }
  let charstrings_offset = 22UL + dict_length
  let private_offset = charstrings_offset + 6UL
  let output : Array[Byte] = [
    b'\x01', b'\x00', b'\x04', b'\x04',
    b'\x00', b'\x01', b'\x01', b'\x01', b'\x05',
    b'T', b'e', b's', b't',
    b'\x00', b'\x01', b'\x01', b'\x01',
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
fn cff_wb_otf(cff : Bytes, num_glyphs? : UInt64 = 1UL) -> Bytes {
  let sfnt = font_wb_build_sfnt([
    font_wb_table(b"CFF ", cff),
    font_wb_table(b"maxp", cff_wb_maxp_table(num_glyphs)),
  ])
  font_wb_put_u32_at_copy(sfnt, 0, 0x4F54544FUL)
}

///|
fn cff_wb_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=32UL,
      allocation_size=4096UL,
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
  for item in [
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
    inspect(admitted.glyph.charstring.view.get(0UL).unwrap(), content="b'\\x0e'")
    inspect(admitted.glyph.environment.private_dict is Some(_), content="true")
    inspect(admitted.glyph.environment.local_subrs.count, content="0")
    inspect(admitted.glyph.environment.font_matrix.length(), content="6")
  }
}

///|
test "CFF1 tracer rejects non-Type-2 before publication or budget charge" {
  let budget = cff_wb_budget()
  let before = budget.remaining()
  let result = admit_cff1_structure(
    font_wb_view(
      cff_wb_otf(cff_wb_table(charstring_type=1UL, omit_type=false)),
    ),
    font_wb_limits(),
    budget,
    0UL,
  )
  inspect(result is Err(_), content="true")
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(error.context() == Some("font-cff-charstring-type"), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}
