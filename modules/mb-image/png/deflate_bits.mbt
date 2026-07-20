///| 
/// LSB-first DEFLATE bit reader.  The input is the concatenation of IDAT
/// payloads; chunk boundaries therefore have no semantic effect here.
priv struct PngDeflateBits {
  bytes : Bytes
  mut offset : Int
  mut value : UInt64
  mut available : Int
}

///|
fn _png_deflate_bits_new(bytes : Bytes, offset : Int) -> PngDeflateBits {
  { bytes, offset, value: 0UL, available: 0 }
}

///|
fn PngDeflateBits::read(self : PngDeflateBits, count : Int) -> Result[Int, @error.CoreError] {
  if count < 0 || count > 16 { return Err(_png_error("deflate-bit-count")) }
  while self.available < count {
    if self.offset >= self.bytes.length() { return Err(_png_error("deflate-truncated")) }
    self.value = self.value | (self.bytes[self.offset].to_int().to_uint64() << self.available)
    self.offset = self.offset + 1
    self.available = self.available + 8
  }
  let mask = if count == 0 { 0UL } else { (1UL << count) - 1UL }
  let result = (self.value & mask).to_int()
  self.value = self.value >> count
  self.available = self.available - count
  Ok(result)
}

///|
fn PngDeflateBits::align(self : PngDeflateBits) -> Unit {
  self.value = 0UL
  self.available = 0
}

///|
fn PngDeflateBits::read_aligned_byte(self : PngDeflateBits) -> Result[Byte, @error.CoreError] {
  self.align()
  if self.offset >= self.bytes.length() { return Err(_png_error("deflate-truncated")) }
  let byte = self.bytes[self.offset]
  self.offset = self.offset + 1
  Ok(byte)
}
