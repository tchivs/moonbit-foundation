///|
test "PNG structural CRC uses type plus payload scope" {
  inspect(_png_crc32(b"IHDR") != _png_crc32(b""), content="true")
}
