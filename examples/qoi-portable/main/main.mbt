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
    digest(writer.view(), writer.position()) == 750514177UL
  if !valid {
    abort("qoi portable example evidence check failed")
  }
  println("example=qoi-portable bytes_read=27 bytes_written=24 width=2 height=1 flip_horizontal digest=750514177 sha256=f6767a56873b631989d02e2cfef3baef2900ef40dc74e7bcf236b51d27095138")
}
