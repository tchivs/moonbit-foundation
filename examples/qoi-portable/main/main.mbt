///|
fn example_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  width : UInt64,
  height : UInt64,
  pixels : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~, allocations~, allocation_size~, width~, height~, pixels~, depth=0UL, work~,
    ),
  )
}

///|
fn codec_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=27UL,
    max_output_bytes=24UL,
    max_width=2UL,
    max_height=1UL,
    max_pixels=2UL,
    max_work=64UL,
  )
}

///|
fn digest(view : @bytes.ByteView, length : UInt64) -> UInt64 {
  let mut value = 0UL
  for index = 0UL; index < length; index = index + 1UL {
    value = (value * 257UL + view.get(index).unwrap().to_uint64()) % 1000000007UL
  }
  value
}

///|
fn matches(view : @bytes.ByteView, expected : @bytes.ByteView, length : UInt64) -> Bool {
  if view.length() != length || expected.length() != length {
    false
  } else {
    let mut matched = true
    for index = 0UL; index < length; index = index + 1UL {
      if view.get(index).unwrap() != expected.get(index).unwrap() {
        matched = false
      }
    }
    matched
  }
}

///|
fn rotate_right(value : UInt64, shift : Int) -> UInt64 {
  ((value >> shift) | (value << (32 - shift))) % 4294967296UL
}

///|
/// Compute and compare the SHA-256 digest for this example's short checked output.
fn sha256_matches(view : @bytes.ByteView, length : UInt64) -> Bool {
  if length > 55UL {
    abort("qoi portable SHA-256 input exceeds one block")
  }
  let words = Array::make(64, 0UL)
  for index = 0UL; index < length; index = index + 1UL {
    let shift = match index % 4UL {
      0UL => 24
      1UL => 16
      2UL => 8
      _ => 0
    }
    let word = index / 4UL
    words[word.to_int()] = words[word.to_int()] |
      (view.get(index).unwrap().to_uint64() << shift)
  }
  let padding_shift = match length % 4UL {
    0UL => 24
    1UL => 16
    2UL => 8
    _ => 0
  }
  let padding_word = (length / 4UL).to_int()
  words[padding_word] = words[padding_word] | (128UL << padding_shift)
  words[15] = length * 8UL
  for index = 16; index < 64; index = index + 1 {
    let left = words[index - 15]
    let right = words[index - 2]
    let small0 = rotate_right(left, 7) ^ rotate_right(left, 18) ^ (left >> 3)
    let small1 = rotate_right(right, 17) ^ rotate_right(right, 19) ^ (right >> 10)
    words[index] = (words[index - 16] + small0 + words[index - 7] + small1) %
      4294967296UL
  }
  let constants : Array[UInt64] = [
    0x428a2f98UL, 0x71374491UL, 0xb5c0fbcfUL, 0xe9b5dba5UL,
    0x3956c25bUL, 0x59f111f1UL, 0x923f82a4UL, 0xab1c5ed5UL,
    0xd807aa98UL, 0x12835b01UL, 0x243185beUL, 0x550c7dc3UL,
    0x72be5d74UL, 0x80deb1feUL, 0x9bdc06a7UL, 0xc19bf174UL,
    0xe49b69c1UL, 0xefbe4786UL, 0x0fc19dc6UL, 0x240ca1ccUL,
    0x2de92c6fUL, 0x4a7484aaUL, 0x5cb0a9dcUL, 0x76f988daUL,
    0x983e5152UL, 0xa831c66dUL, 0xb00327c8UL, 0xbf597fc7UL,
    0xc6e00bf3UL, 0xd5a79147UL, 0x06ca6351UL, 0x14292967UL,
    0x27b70a85UL, 0x2e1b2138UL, 0x4d2c6dfcUL, 0x53380d13UL,
    0x650a7354UL, 0x766a0abbUL, 0x81c2c92eUL, 0x92722c85UL,
    0xa2bfe8a1UL, 0xa81a664bUL, 0xc24b8b70UL, 0xc76c51a3UL,
    0xd192e819UL, 0xd6990624UL, 0xf40e3585UL, 0x106aa070UL,
    0x19a4c116UL, 0x1e376c08UL, 0x2748774cUL, 0x34b0bcb5UL,
    0x391c0cb3UL, 0x4ed8aa4aUL, 0x5b9cca4fUL, 0x682e6ff3UL,
    0x748f82eeUL, 0x78a5636fUL, 0x84c87814UL, 0x8cc70208UL,
    0x90befffaUL, 0xa4506cebUL, 0xbef9a3f7UL, 0xc67178f2UL,
  ]
  let h0 = 0x6a09e667UL
  let h1 = 0xbb67ae85UL
  let h2 = 0x3c6ef372UL
  let h3 = 0xa54ff53aUL
  let h4 = 0x510e527fUL
  let h5 = 0x9b05688cUL
  let h6 = 0x1f83d9abUL
  let h7 = 0x5be0cd19UL
  let mut a = h0
  let mut b = h1
  let mut c = h2
  let mut d = h3
  let mut e = h4
  let mut f = h5
  let mut g = h6
  let mut h = h7
  for index = 0; index < 64; index = index + 1 {
    let big1 = rotate_right(e, 6) ^ rotate_right(e, 11) ^ rotate_right(e, 25)
    let choice = (e & f) ^ ((e ^ 0xffffffffUL) & g)
    let temp1 = (h + big1 + choice + constants[index] + words[index]) %
      4294967296UL
    let big0 = rotate_right(a, 2) ^ rotate_right(a, 13) ^ rotate_right(a, 22)
    let majority = (a & b) ^ (a & c) ^ (b & c)
    let temp2 = (big0 + majority) % 4294967296UL
    h = g
    g = f
    f = e
    e = (d + temp1) % 4294967296UL
    d = c
    c = b
    b = a
    a = (temp1 + temp2) % 4294967296UL
  }
  let actual = [
    (h0 + a) % 4294967296UL,
    (h1 + b) % 4294967296UL,
    (h2 + c) % 4294967296UL,
    (h3 + d) % 4294967296UL,
    (h4 + e) % 4294967296UL,
    (h5 + f) % 4294967296UL,
    (h6 + g) % 4294967296UL,
    (h7 + h) % 4294967296UL,
  ]
  let expected : Array[UInt64] = [
    0x5dc3abfeUL, 0x81e722b2UL, 0x11af255fUL, 0x6f968052UL,
    0x25f98435UL, 0xf1f9525cUL, 0x46df4821UL, 0x7f858df2UL,
  ]
  for index = 0; index < 8; index = index + 1 {
    if actual[index] != expected[index] {
      return false
    }
  }
  true
}

///|
fn main {
  let source_bytes = b"\x71\x6f\x69\x66\x00\x00\x00\x02\x00\x00\x00\x01\x03\x00\xfe\xff\xff\xff\x7a\x00\x00\x00\x00\x00\x00\x00\x01"
  let expected_bytes = b"\x71\x6f\x69\x66\x00\x00\x00\x02\x00\x00\x00\x01\x03\x00\x65\x5a\x00\x00\x00\x00\x00\x00\x00\x01"
  let source = @bytes.OwnedBytes::from_bytes(
    source_bytes,
    example_budget(27UL, 1UL, 27UL, 0UL, 0UL, 0UL, 0UL),
  ).unwrap()
  let expected = @bytes.OwnedBytes::from_bytes(
    expected_bytes,
    example_budget(24UL, 1UL, 24UL, 0UL, 0UL, 0UL, 0UL),
  ).unwrap()
  let decode_diagnostics = @error.Diagnostics::new()
  let decoded = @codec.ImageDecoder::decode(
    @qoi.QoiDecoder::new(),
    @io.MemoryReader::new(source.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    example_budget(6UL, 1UL, 6UL, 2UL, 1UL, 2UL, 8UL),
    decode_diagnostics,
  ).unwrap()
  let flipped = @ops.flip_horizontal(
    decoded.image().view(),
    example_budget(6UL, 1UL, 6UL, 2UL, 1UL, 2UL, 6UL),
  ).unwrap()
  let writer = @io.MemoryWriter::new(
    24UL,
    example_budget(24UL, 1UL, 24UL, 0UL, 0UL, 0UL, 0UL),
  ).unwrap()
  let encode_diagnostics = @error.Diagnostics::new()
  let encoded = @codec.ImageEncoder::encode(
    @qoi.QoiEncoder::new(),
    flipped.image().view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    example_budget(0UL, 0UL, 0UL, 2UL, 1UL, 0UL, 24UL),
    encode_diagnostics,
  ).unwrap()
  let flipped_view = flipped.image().view()
  let valid = decoded.image().descriptor().width() == 2UL &&
    decoded.image().descriptor().height() == 1UL &&
    flipped_view.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x00' &&
    flipped_view.get_byte(0UL, 0UL, 1UL).unwrap() == b'\xff' &&
    flipped_view.get_byte(0UL, 0UL, 2UL).unwrap() == b'\xff' &&
    flipped_view.get_byte(1UL, 0UL, 0UL).unwrap() == b'\xff' &&
    flipped_view.get_byte(1UL, 0UL, 1UL).unwrap() == b'\xff' &&
    flipped_view.get_byte(1UL, 0UL, 2UL).unwrap() == b'\xff' &&
    decoded.bytes_read() == 27UL &&
    encoded.bytes_written() == 24UL &&
    writer.position() == 24UL &&
    decode_diagnostics.length() == 0 &&
    encode_diagnostics.length() == 0 &&
    matches(writer.view(), expected.view(), 24UL) &&
    digest(writer.view(), writer.position()) == 750514177UL &&
    sha256_matches(writer.view(), writer.position())
  if !valid {
    abort("qoi portable example evidence check failed")
  }
  println("example=qoi-portable bytes_read=27 bytes_written=24 width=2 height=1 flip_horizontal digest=750514177 sha256=5dc3abfe81e722b211af255f6f96805225f98435f1f9525c46df48217f858df2")
}
