///| 
/// LSB-first DEFLATE bit reader over a forward-only sequence of IDAT payloads.
/// Chunk boundaries have no semantic effect and no compressed byte array is
/// retained by the decoder.
priv struct PngDeflateBits {
  source : PngIdatSource
  mut value : UInt64
  mut available : Int
}

///|
fn _png_deflate_bits_new(source : PngIdatSource) -> PngDeflateBits {
  { source, value: 0UL, available: 0 }
}

///|
fn PngDeflateBits::read(self : PngDeflateBits, count : Int) -> Result[Int, @error.CoreError] {
  if count < 0 || count > 16 { return Err(_png_error("deflate-bit-count")) }
  while self.available < count {
    let byte = match self.source.next_byte() {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    self.value = self.value | (byte.to_int().to_uint64() << self.available)
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
  self.source.next_byte()
}
