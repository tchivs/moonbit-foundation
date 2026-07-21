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

///| A read from the byte-fed inflater. `NeedInput` is a normal continuation
/// boundary, never a truncated-zlib error: the caller may supply exactly one
/// more authenticated IDAT byte and continue from the retained accumulator.
priv enum PngInflateRead {
  Value(Int)
  NeedInput
}

///| Bit state used by the private byte-fed continuation. It deliberately owns
/// only a single unconsumed compressed byte in addition to the LSB accumulator.
priv struct PngInflateBits {
  mut value : UInt64
  mut available : Int
  mut pending : Byte?
}

///|
fn PngInflateBits::new() -> PngInflateBits {
  { value: 0UL, available: 0, pending: None }
}

///|
fn PngInflateBits::supply(self : PngInflateBits, byte : Byte) -> Result[Unit, @error.CoreError] {
  match self.pending {
    Some(_) => Err(_png_error("deflate-input-state"))
    None => { self.pending = Some(byte); Ok(()) }
  }
}

///|
fn PngInflateBits::read(self : PngInflateBits, count : Int) -> Result[PngInflateRead, @error.CoreError] {
  if count < 0 || count > 16 { return Err(_png_error("deflate-bit-count")) }
  if self.available < count {
    match self.pending {
      None => return Ok(PngInflateRead::NeedInput)
      Some(byte) => {
        self.value = self.value | (byte.to_int().to_uint64() << self.available)
        self.available = self.available + 8
        self.pending = None
      }
    }
  }
  if self.available < count { return Ok(PngInflateRead::NeedInput) }
  let mask = if count == 0 { 0UL } else { (1UL << count) - 1UL }
  let result = (self.value & mask).to_int()
  self.value = self.value >> count
  self.available = self.available - count
  Ok(PngInflateRead::Value(result))
}

///|
fn PngInflateBits::align(self : PngInflateBits) -> Unit {
  self.value = 0UL
  self.available = 0
}
