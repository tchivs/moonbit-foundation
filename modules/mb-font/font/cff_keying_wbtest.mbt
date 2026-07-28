///|
fn cff_key_wb_append(output : Array[Byte], bytes : Bytes) -> Unit {
  for byte in font_wb_bytes_array(bytes) {
    output.push(byte)
  }
}

///|
fn cff_key_wb_dict_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push(b'\x1d')
  font_wb_put_u32(output, value)
}

///|
fn cff_key_wb_index(objects : Array[Bytes]) -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u16(output, objects.length().to_uint64())
  if objects.length() == 0 {
    return Bytes::from_array(output)
  }
  output.push(b'\x01')
  let mut next = 1UL
  output.push(next.to_byte())
  for object in objects {
    next = next + object.length().to_uint64()
    output.push(next.to_byte())
  }
  for object in objects {
    cff_key_wb_append(output, object)
  }
  Bytes::from_array(output)
}

///|
fn cff_key_wb_assert_atomic_error(
  source : Bytes,
  expected_context : String,
  num_glyphs? : UInt64 = 3UL,
) -> Unit raise {
  let budget = cff_wb_budget()
  let before = budget.remaining()
  let result = admit_cff1_structure(
    font_wb_view(cff_wb_otf(source, num_glyphs~)),
    font_wb_limits(),
    budget,
    0UL,
  )
  inspect(result is Err(_), content="true")
  inspect(result.unwrap_err().context() == Some(expected_context), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}
