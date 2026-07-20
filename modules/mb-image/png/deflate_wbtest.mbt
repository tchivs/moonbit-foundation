///|
test "PNG private zlib inflater accepts stored blocks and verifies Adler" {
  let output = _png_inflate_zlib(
    b"\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d",
    64UL,
  ).unwrap()
  inspect(output[0] == b'\x00', content="true")
  inspect(output[1] == b'\x12', content="true")
  inspect(output[2] == b'\x34', content="true")
  inspect(output[3] == b'\x56', content="true")
  let checksum = _png_inflate_zlib(
    b"\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9c",
    64UL,
  ).unwrap_err()
  inspect(checksum.context() == Some("zlib-adler"), content="true")
}

///|
test "PNG private zlib inflater rejects wrapper and output expansion" {
  let header = _png_inflate_zlib(b"\x78\x00\x00\x00\x00\x00", 64UL).unwrap_err()
  inspect(header.context() == Some("zlib-header"), content="true")
  let limited = _png_inflate_zlib(
    b"\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d",
    3UL,
  ).unwrap_err()
  inspect(limited.context() == Some("output-bytes"), content="true")
}
