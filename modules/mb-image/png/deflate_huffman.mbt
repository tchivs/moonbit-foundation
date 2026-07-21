///|
priv struct PngHuffman {
  lengths : Array[Int]
  codes : Array[Int]
}

///|
fn _png_reverse_bits(value : Int, count : Int) -> Int {
  let mut result = 0
  let mut cursor = value
  for index = 0; index < count; index = index + 1 {
    result = (result << 1) | (cursor & 1)
    cursor = cursor >> 1
  }
  result
}

///|
fn _png_huffman_new(
  lengths : Array[Int],
  require_eob : Bool,
  allow_single_distance : Bool,
) -> Result[PngHuffman, @error.CoreError] {
  let counts = Array::make(16, 0)
  let mut nonzero = 0
  for length in lengths {
    if length < 0 || length > 15 { return Err(_png_error("deflate-code-length")) }
    if length > 0 { counts[length] = counts[length] + 1; nonzero = nonzero + 1 }
  }
  if nonzero == 0 { return Err(_png_error("deflate-empty-tree")) }
  if require_eob && (lengths.length() <= 256 || lengths[256] == 0) { return Err(_png_error("deflate-missing-eob")) }
  let mut code = 0
  let next = Array::make(16, 0)
  for bits = 1; bits <= 15; bits = bits + 1 {
    code = (code + counts[bits - 1]) << 1
    if code + counts[bits] > (1 << bits) { return Err(_png_error("deflate-oversubscribed-tree")) }
    next[bits] = code
  }
  // RFC 1951 permits one incomplete tree only: a distance alphabet with one
  // one-bit code.  All other dynamic alphabets must cover their whole code
  // space; accepting a residual prefix would make malformed inputs decode.
  if code + counts[15] != (1 << 15) &&
    !(allow_single_distance && nonzero == 1 && counts[1] == 1) {
    return Err(_png_error("deflate-incomplete-tree"))
  }
  let codes = Array::make(lengths.length(), 0)
  for symbol = 0; symbol < lengths.length(); symbol = symbol + 1 {
    let length = lengths[symbol]
    if length > 0 {
      codes[symbol] = _png_reverse_bits(next[length], length)
      next[length] = next[length] + 1
    }
  }
  Ok({ lengths, codes })
}

///|
fn PngHuffman::symbol(self : PngHuffman, bits : PngDeflateBits) -> Result[Int, @error.CoreError] {
  let mut code = 0
  for length = 1; length <= 15; length = length + 1 {
    let bit = match bits.read(1) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    code = code | (bit << (length - 1))
    for symbol = 0; symbol < self.lengths.length(); symbol = symbol + 1 {
      if self.lengths[symbol] == length && self.codes[symbol] == code { return Ok(symbol) }
    }
  }
  Err(_png_error("deflate-invalid-code"))
}

///|
fn _png_fixed_literal_tree() -> PngHuffman {
  let lengths = Array::make(288, 0)
  for index = 0; index <= 143; index = index + 1 { lengths[index] = 8 }
  for index = 144; index <= 255; index = index + 1 { lengths[index] = 9 }
  for index = 256; index <= 279; index = index + 1 { lengths[index] = 7 }
  for index = 280; index <= 287; index = index + 1 { lengths[index] = 8 }
  _png_huffman_new(lengths, true, false).unwrap()
}

///|
fn _png_fixed_distance_tree() -> PngHuffman {
  _png_huffman_new(Array::make(32, 5), false, false).unwrap()
}

///| Retains a partially-read canonical code across a byte pause.
priv struct PngHuffmanCursor {
  mut code : Int
  mut length : Int
}

///|
fn PngHuffmanCursor::new() -> PngHuffmanCursor { { code: 0, length: 0 } }

///|
fn PngHuffmanCursor::reset(self : PngHuffmanCursor) -> Unit {
  self.code = 0
  self.length = 0
}

///|
fn PngHuffmanCursor::symbol(
  self : PngHuffmanCursor,
  tree : PngHuffman,
  bits : PngInflateBits,
) -> Result[PngInflateRead, @error.CoreError] {
  while self.length < 15 {
    let bit = match bits.read(1) {
      Err(error) => return Err(error)
      Ok(PngInflateRead::NeedInput) => return Ok(PngInflateRead::NeedInput)
      Ok(PngInflateRead::Value(value)) => value
    }
    self.code = self.code | (bit << self.length)
    self.length = self.length + 1
    for symbol = 0; symbol < tree.lengths.length(); symbol = symbol + 1 {
      if tree.lengths[symbol] == self.length && tree.codes[symbol] == self.code {
        let result = symbol
        self.reset()
        return Ok(PngInflateRead::Value(result))
      }
    }
  }
  self.reset()
  Err(_png_error("deflate-invalid-code"))
}
