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

///| Build an ordinary, stable canonical tree for an encoder.  Equal weights are
/// ordered by their smallest leaf symbol and then by creation order; this keeps
/// byte output deterministic without adding a length-limited optimiser.  `None`
/// means the ordinary merge would exceed DEFLATE's 15-bit ceiling.
fn _png_huffman_from_frequencies(
  frequencies : Array[UInt64],
  require_eob : Bool,
  allow_single_distance : Bool,
  complete_singleton : Bool,
) -> PngHuffman? {
  let leaves : Array[Int] = []
  for symbol = 0; symbol < frequencies.length(); symbol = symbol + 1 {
    if frequencies[symbol] > 0UL { leaves.push(symbol) }
  }
  if require_eob && (frequencies.length() <= 256 || frequencies[256] == 0UL) {
    return None
  }
  // Literal/code-length alphabets must be complete.  A deterministic zero-weight
  // leaf is legal and avoids accepting an incomplete non-distance tree.
  if leaves.length() == 1 && complete_singleton {
    let mut extra = 0
    while extra == leaves[0] { extra = extra + 1 }
    leaves.push(extra)
  }
  if leaves.length() == 0 { return None }
  if leaves.length() == 1 {
    let lengths = Array::make(frequencies.length(), 0)
    lengths[leaves[0]] = 1
    return match _png_huffman_new(lengths, require_eob, allow_single_distance) {
      Ok(value) => Some(value)
      Err(_) => None
    }
  }
  let maximum = leaves.length() * 2 - 1
  let weights = Array::make(maximum, 0UL)
  let minimum_symbol = Array::make(maximum, 0)
  let left = Array::make(maximum, -1)
  let right = Array::make(maximum, -1)
  for index = 0; index < leaves.length(); index = index + 1 {
    weights[index] = frequencies[leaves[index]]
    minimum_symbol[index] = leaves[index]
  }
  let mut active = leaves.length()
  let mut nodes = leaves.length()
  let order = Array::make(maximum, 0)
  for index = 0; index < active; index = index + 1 { order[index] = index }
  while active > 1 {
    // Selection sort is deliberate: the alphabet is bounded by 286 symbols.
    for index = 0; index < active; index = index + 1 {
      let mut best = index
      for candidate = index + 1; candidate < active; candidate = candidate + 1 {
        let a = order[candidate]
        let b = order[best]
        if weights[a] < weights[b] ||
          (weights[a] == weights[b] && (minimum_symbol[a] < minimum_symbol[b] ||
            (minimum_symbol[a] == minimum_symbol[b] && a < b))) {
          best = candidate
        }
      }
      let swap = order[index]
      order[index] = order[best]
      order[best] = swap
    }
    let first = order[0]
    let second = order[1]
    weights[nodes] = weights[first] + weights[second]
    minimum_symbol[nodes] = if minimum_symbol[first] < minimum_symbol[second] {
      minimum_symbol[first]
    } else { minimum_symbol[second] }
    left[nodes] = first
    right[nodes] = second
    for index = 2; index < active; index = index + 1 { order[index - 2] = order[index] }
    order[active - 2] = nodes
    active = active - 1
    nodes = nodes + 1
  }
  let lengths = Array::make(frequencies.length(), 0)
  let stack_nodes = Array::make(maximum, 0)
  let stack_depths = Array::make(maximum, 0)
  let mut stack = 0
  stack_nodes[stack] = order[0]
  stack_depths[stack] = 0
  stack = stack + 1
  while stack > 0 {
    stack = stack - 1
    let node = stack_nodes[stack]
    let depth = stack_depths[stack]
    if left[node] < 0 {
      if depth > 15 { return None }
      lengths[leaves[node]] = depth
    } else {
      stack_nodes[stack] = left[node]
      stack_depths[stack] = depth + 1
      stack = stack + 1
      stack_nodes[stack] = right[node]
      stack_depths[stack] = depth + 1
      stack = stack + 1
    }
  }
  match _png_huffman_new(lengths, require_eob, allow_single_distance) {
    Ok(value) => Some(value)
    Err(_) => None
  }
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
