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
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations~, allocation_size~, width~, height~, pixels~, depth=0UL, work~,
  ))
}

///|
fn codec_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=75UL, max_output_bytes=128UL,
    max_width=3UL, max_height=1UL, max_pixels=3UL, max_work=256UL,
  )
}

///|
fn matches(left : @bytes.ByteView, right : @bytes.ByteView, length : UInt64) -> Bool {
  if left.length() < length || right.length() < length {
    false
  } else {
    let mut equal = true
    for index = 0UL; index < length; index = index + 1UL {
      if left.get(index).unwrap() != right.get(index).unwrap() { equal = false }
    }
    equal
  }
}

///|
fn digest(view : @bytes.ByteView, length : UInt64) -> UInt64 {
  let mut value = 0UL
  for index = 0UL; index < length; index = index + 1UL {
    value = (value * 257UL + view.get(index).unwrap().to_int().to_uint64()) % 1000000007UL
  }
  value
}

///|
fn main {
  let source_bytes = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x08\x02\x00\x00\x00\x7b\x40\xe8\xdd\x00\x00\x00\x12IDAT\x78\x01\x01\x07\x00\xf8\xff\x00\x12\x34\x56\xab\xcd\xef\x07\x59\x03\x04\x84\xb0\x16\xcc\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let expected_bytes = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x03\x00\x00\x00\x01\x08\x02\x00\x00\x00\x94\x82\x83\xe3\x00\x00\x00\x15IDAT\x78\x01\x01\x0a\x00\xf5\xff\x00\x12\x34\x56\x8f\xad\xcc\xab\xcd\xef\x13\x1b\x05\x0c\x65\x64\x26\xa8\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let source = @bytes.OwnedBytes::from_bytes(
    source_bytes, example_budget(75UL, 1UL, 75UL, 0UL, 0UL, 0UL, 0UL),
  ).unwrap()
  let expected = @bytes.OwnedBytes::from_bytes(
    expected_bytes, example_budget(78UL, 1UL, 78UL, 0UL, 0UL, 0UL, 0UL),
  ).unwrap()
  let reader = @io.MemoryReader::new(source.view())
  let decoded = @codec.ImageDecoder::decode(
    @png.PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    codec_limits(), example_budget(256UL, 8UL, 128UL, 2UL, 1UL, 2UL, 256UL),
    @error.Diagnostics::new(),
  ).unwrap()
  let resized = @ops.flip_horizontal(
    decoded.image().view(), example_budget(6UL, 1UL, 6UL, 2UL, 1UL, 2UL, 6UL),
  ).unwrap()
  let writer = @io.MemoryWriter::new(
    128UL, example_budget(128UL, 1UL, 128UL, 0UL, 0UL, 0UL, 0UL),
  ).unwrap()
  let encoded = @codec.ImageEncoder::encode(
    @png.PngEncoder::new(), resized.image().view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    codec_limits(), example_budget(0UL, 0UL, 0UL, 3UL, 1UL, 0UL, 78UL),
    @error.Diagnostics::new(),
  ).unwrap()
  if decoded.descriptor().width() != 2UL || decoded.descriptor().height() != 1UL { abort("png portable dimensions") }
  if decoded.bytes_read() != 75UL { abort("png portable read length") }
  if resized.image().view().get_byte(0UL, 0UL, 0UL).unwrap() != b'\x12' ||
    resized.image().view().get_byte(1UL, 0UL, 0UL).unwrap() != b'\x8f' ||
    resized.image().view().get_byte(2UL, 0UL, 0UL).unwrap() != b'\xab' { abort("png portable bilinear pixels") }
  if resized.image().view().get_byte(0UL, 0UL, 1UL).unwrap() != b'\x34' ||
    resized.image().view().get_byte(1UL, 0UL, 1UL).unwrap() != b'\xad' ||
    resized.image().view().get_byte(2UL, 0UL, 1UL).unwrap() != b'\xcd' { abort("png portable bilinear pixels") }
  if resized.image().view().get_byte(0UL, 0UL, 2UL).unwrap() != b'\x56' ||
    resized.image().view().get_byte(1UL, 0UL, 2UL).unwrap() != b'\xcc' ||
    resized.image().view().get_byte(2UL, 0UL, 2UL).unwrap() != b'\xef' { abort("png portable bilinear pixels") }
  if encoded.bytes_written() != 78UL { abort("png portable write length") }
  if !matches(writer.view(), expected.view(), 78UL) { abort("png portable exact bytes") }
  if digest(writer.view(), 78UL) != 626208771UL { abort("png portable digest") }
  println("example=png-portable bytes_read=75 bytes_written=78 width=3 height=1 resize_bilinear digest=626208771")
}
