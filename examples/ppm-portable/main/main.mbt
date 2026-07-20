///|
fn example_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  pixels : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=2UL,
      height=1UL,
      pixels~,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn codec_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=64UL,
    max_output_bytes=64UL,
    max_width=2UL,
    max_height=1UL,
    max_pixels=2UL,
    max_work=64UL,
  )
}

///|
fn parser_limits() -> @ppm.PpmParserLimits {
  @ppm.PpmParserLimits::new(
    max_header_bytes=32UL,
    max_token_bytes=4UL,
    max_comment_bytes=8UL,
    max_comments=1UL,
  ).unwrap()
}

///|
fn digest(view : @bytes.ByteView, length : UInt64) -> UInt64 {
  let mut value = 0UL
  for index = 0UL; index < length; index = index + 1UL {
    value = (value * 257UL + view.get(index).unwrap().to_uint64()) %
      1000000007UL
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
  let foreground_bytes = b"P6\n1 1\n255\n\x0c\x22\x38"
  let background_bytes = b"P6\n2 1\n255\n\x00\x7f\xff\x01\x02\x03"
  let expected_bytes = b"P6\n2 1\n255\n\x0c\x22\x38\x0c\x22\x38"
  let foreground = @bytes.OwnedBytes::from_bytes(
    foreground_bytes,
    example_budget(14UL, 1UL, 14UL, 0UL, 0UL),
  ).unwrap()
  let background = @bytes.OwnedBytes::from_bytes(
    background_bytes,
    example_budget(17UL, 1UL, 17UL, 0UL, 0UL),
  ).unwrap()
  let expected = @bytes.OwnedBytes::from_bytes(
    expected_bytes,
    example_budget(17UL, 1UL, 17UL, 0UL, 0UL),
  ).unwrap()
  let foreground_reader = @io.MemoryReader::new(foreground.view())
  let background_reader = @io.MemoryReader::new(background.view())
  let foreground_diagnostics = @error.Diagnostics::new()
  let background_diagnostics = @error.Diagnostics::new()
  let encode_diagnostics = @error.Diagnostics::new()
  let decoded_foreground = @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(parser_limits()),
    foreground_reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    example_budget(3UL, 1UL, 3UL, 1UL, 14UL),
    foreground_diagnostics,
  ).unwrap()
  let decoded_background = @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(parser_limits()),
    background_reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    example_budget(6UL, 1UL, 6UL, 2UL, 17UL),
    background_diagnostics,
  ).unwrap()
  let resized_foreground = @ops.resize_nearest(
    decoded_foreground.image().view(),
    2UL,
    1UL,
    example_budget(6UL, 1UL, 6UL, 2UL, 12UL),
  ).unwrap()
  let source_rgba = @ops.rgb8_to_straight_rgba8(
    resized_foreground.image().view(),
    example_budget(8UL, 1UL, 8UL, 2UL, 12UL),
  ).unwrap()
  let destination_rgba = @ops.rgb8_to_straight_rgba8(
    decoded_background.image().view(),
    example_budget(8UL, 1UL, 8UL, 2UL, 12UL),
  ).unwrap()
  let composited = @ops.composite_source_over(
    source_rgba.image().view(),
    destination_rgba.image().view(),
    example_budget(8UL, 1UL, 8UL, 2UL, 32UL),
  ).unwrap()
  let encodable = @ops.straight_rgba8_to_rgb8(
    composited.image().view(),
    example_budget(6UL, 1UL, 6UL, 2UL, 12UL),
  ).unwrap()
  let writer = @io.MemoryWriter::new(
    17UL,
    example_budget(17UL, 1UL, 17UL, 0UL, 0UL),
  ).unwrap()
  let encoded = @codec.ImageEncoder::encode(
    @ppm.PpmEncoder::new(),
    encodable.image().view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    example_budget(17UL, 0UL, 0UL, 2UL, 17UL),
    encode_diagnostics,
  ).unwrap()
  let valid = decoded_foreground.bytes_read() == 14UL &&
    decoded_background.bytes_read() == 17UL &&
    resized_foreground.image().descriptor().width() == 2UL &&
    resized_foreground.image().descriptor().height() == 1UL &&
    encodable.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == 0x0c &&
    encodable.image().view().get_byte(0UL, 0UL, 1UL).unwrap() == 0x22 &&
    encodable.image().view().get_byte(0UL, 0UL, 2UL).unwrap() == 0x38 &&
    encodable.image().view().get_byte(1UL, 0UL, 0UL).unwrap() == 0x0c &&
    encodable.image().view().get_byte(1UL, 0UL, 1UL).unwrap() == 0x22 &&
    encodable.image().view().get_byte(1UL, 0UL, 2UL).unwrap() == 0x38 &&
    encoded.bytes_written() == 17UL &&
    writer.position() == 17UL &&
    foreground_diagnostics.length() == 0 &&
    background_diagnostics.length() == 0 &&
    encode_diagnostics.length() == 0 &&
    matches(writer.view(), expected.view(), 17UL) &&
    digest(writer.view(), writer.position()) == 9386158UL
  if valid {
    println(
      "example=portable bytes_read=14+17 bytes_written=17 width=2 height=1 resize_nearest rgb8_to_straight_rgba8 composite_source_over straight_rgba8_to_rgb8 digest=9386158 sha256=cf8f36752d62cd88334bfa8fc45c55bdbf0f70275180bc6d2b14bf3810676464",
    )
  } else {
    println("example=portable status=failed")
  }
}
