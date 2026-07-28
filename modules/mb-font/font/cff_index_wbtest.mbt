///|
fn cff_index_wb_put_offset(
  output : Array[Byte],
  width : UInt64,
  value : UInt64,
) -> Unit {
  if width == 4UL {
    output.push((value >> 24).to_byte())
  }
  if width >= 3UL {
    output.push((value >> 16).to_byte())
  }
  if width >= 2UL {
    output.push((value >> 8).to_byte())
  }
  output.push(value.to_byte())
}

///|
fn cff_index_wb_single(width : UInt64, payload : Bytes) -> Bytes {
  let output : Array[Byte] = [b'\x00', b'\x01', width.to_byte()]
  cff_index_wb_put_offset(output, width, 1UL)
  cff_index_wb_put_offset(output, width, payload.length().to_uint64() + 1UL)
  for byte in payload {
    output.push(byte)
  }
  Bytes::from_array(output)
}

///|
test "CFF INDEX accepts empty and offSize one through four with exact windows" {
  let empty = cff_decode_index(
    font_wb_view(b"\x00\x00"),
    0UL,
    8UL,
    "cff-index-test",
  ).unwrap()
  inspect(empty.0.count, content="0")
  inspect(empty.0.off_size, content="0")
  inspect(empty.1, content="2")
  for width in [1UL, 2UL, 3UL, 4UL] {
    let encoded = cff_index_wb_single(width, b"\xAA\xBB")
    let decoded = cff_decode_index(
      font_wb_view(encoded),
      0UL,
      8UL,
      "cff-index-test",
    ).unwrap()
    inspect(decoded.0.count, content="1")
    inspect(decoded.0.off_size == width, content="true")
    inspect(decoded.1, content=encoded.length().to_string())
    let object = cff_index_object(decoded.0, 0UL, "cff-index-test").unwrap()
    inspect(object.offset, content="0")
    inspect(object.length, content="2")
    inspect(object.view.get(0UL).unwrap(), content="b'\\xAA'")
    inspect(object.view.get(1UL).unwrap(), content="b'\\xBB'")
  }
}

///|
test "CFF INDEX rejects offset width first offset order extent count and object violations" {
  for malformed in [
    b"\x00\x01\x00",
    b"\x00\x01\x05",
    b"\x00\x01\x01\x02\x02\xAA",
    b"\x00\x02\x01\x01\x03\x02\xAA\xBB",
    b"\x00\x01\x01\x01\x04\xAA\xBB",
  ] {
    inspect(
      cff_decode_index(
        font_wb_view(malformed),
        0UL,
        8UL,
        "cff-index-test",
      ) is Err(_),
      content="true",
    )
  }
  inspect(
    cff_decode_index(
      font_wb_view(cff_index_wb_single(1UL, b"\xAA")),
      0UL,
      0UL,
      "cff-index-test",
    ) is Err(_),
    content="true",
  )
  let exact = cff_decode_index(
    font_wb_view(cff_index_wb_single(1UL, b"\xAA")),
    0UL,
    1UL,
    "cff-index-test",
  ).unwrap().0
  inspect(cff_index_object(exact, 1UL, "cff-index-test") is Err(_), content="true")
}
