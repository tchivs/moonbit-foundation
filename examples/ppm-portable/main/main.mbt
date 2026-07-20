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
    max_input_bytes=64UL,
    max_output_bytes=64UL,
    max_width=3UL,
    max_height=3UL,
    max_pixels=9UL,
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
  let foreground_bytes = b"P6\n3 3\n255\n\x01\x02\x03\x00\x00\x00\xff\xff\xff\x04\x05\x06\x40\x40\x40\xc0\xc0\xc0\x07\x08\x09\x80\x80\x80\x20\x20\x20"
  let background_bytes = b"P6\n3 2\n255\n\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12"
  let expected_bytes = b"P6\n3 2\n255\n\x72\x72\x72\x84\x84\x84\x93\x93\x93\x75\x75\x75\xa4\xa4\xa4\xc6\xc6\xc6"
  let foreground = @bytes.OwnedBytes::from_bytes(foreground_bytes, example_budget(38UL, 1UL, 38UL, 0UL, 0UL, 0UL, 0UL)).unwrap()
  let background = @bytes.OwnedBytes::from_bytes(background_bytes, example_budget(29UL, 1UL, 29UL, 0UL, 0UL, 0UL, 0UL)).unwrap()
  let expected = @bytes.OwnedBytes::from_bytes(expected_bytes, example_budget(29UL, 1UL, 29UL, 0UL, 0UL, 0UL, 0UL)).unwrap()
  let foreground_diagnostics = @error.Diagnostics::new()
  let background_diagnostics = @error.Diagnostics::new()
  let encode_diagnostics = @error.Diagnostics::new()
  let decoded_foreground = @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(parser_limits()),
    @io.MemoryReader::new(foreground.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    codec_limits(), example_budget(27UL, 1UL, 27UL, 3UL, 3UL, 9UL, 38UL), foreground_diagnostics,
  ).unwrap()
  let decoded_background = @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(parser_limits()),
    @io.MemoryReader::new(background.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    codec_limits(), example_budget(18UL, 1UL, 18UL, 3UL, 2UL, 6UL, 29UL), background_diagnostics,
  ).unwrap()
  let cropped = @ops.crop(decoded_foreground.image().view(), @model.Rect::new(1UL, 0UL, 2UL, 3UL).unwrap(), example_budget(18UL, 1UL, 18UL, 2UL, 3UL, 6UL, 18UL)).unwrap()
  let rotated = @ops.rotate_90(cropped.image().view(), example_budget(18UL, 1UL, 18UL, 3UL, 2UL, 6UL, 18UL)).unwrap()
  let source_rgba = @ops.rgb8_to_straight_rgba8(rotated.image().view(), example_budget(24UL, 1UL, 24UL, 3UL, 2UL, 6UL, 24UL)).unwrap()
  let grayscale = @ops.grayscale(source_rgba.image().view(), example_budget(24UL, 1UL, 24UL, 3UL, 2UL, 6UL, 6UL)).unwrap()
  let blurred = @ops.box_blur(grayscale.image().view(), 1UL, example_budget(24UL, 1UL, 24UL, 3UL, 2UL, 6UL, 54UL)).unwrap()
  let background_rgba = @ops.rgb8_to_straight_rgba8(decoded_background.image().view(), example_budget(24UL, 1UL, 24UL, 3UL, 2UL, 6UL, 24UL)).unwrap()
  let composited = @ops.composite_source_over(blurred.image().view(), background_rgba.image().view(), example_budget(24UL, 1UL, 24UL, 3UL, 2UL, 6UL, 6UL)).unwrap()
  let encodable = @ops.straight_rgba8_to_rgb8(composited.image().view(), example_budget(18UL, 1UL, 18UL, 3UL, 2UL, 6UL, 18UL)).unwrap()
  let writer = @io.MemoryWriter::new(29UL, example_budget(29UL, 1UL, 29UL, 0UL, 0UL, 0UL, 0UL)).unwrap()
  let encoded = @codec.ImageEncoder::encode(
    @ppm.PpmEncoder::new(), encodable.image().view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    codec_limits(), example_budget(29UL, 0UL, 0UL, 3UL, 2UL, 6UL, 29UL), encode_diagnostics,
  ).unwrap()
  let rotated_view = rotated.image().view()
  let grayscale_view = grayscale.image().view()
  let blurred_view = blurred.image().view()
  let valid = decoded_foreground.bytes_read() == 38UL && decoded_background.bytes_read() == 29UL &&
    rotated.image().descriptor().width() == 3UL && rotated.image().descriptor().height() == 2UL &&
    rotated_view.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x80' && rotated_view.get_byte(2UL, 1UL, 0UL).unwrap() == b'\xff' &&
    grayscale_view.get_byte(0UL, 0UL, 0UL).unwrap() == grayscale_view.get_byte(0UL, 0UL, 1UL).unwrap() &&
    grayscale_view.get_byte(0UL, 0UL, 1UL).unwrap() == grayscale_view.get_byte(0UL, 0UL, 2UL).unwrap() && grayscale_view.get_byte(0UL, 0UL, 3UL).unwrap() == b'\xff' &&
    blurred_view.get_byte(0UL, 0UL, 0UL).unwrap() == b'\x72' && blurred_view.get_byte(0UL, 0UL, 1UL).unwrap() == b'\x72' && blurred_view.get_byte(0UL, 0UL, 2UL).unwrap() == b'\x72' && blurred_view.get_byte(0UL, 0UL, 3UL).unwrap() == b'\xff' &&
    blurred_view.get_byte(2UL, 1UL, 0UL).unwrap() == b'\xc6' && blurred_view.get_byte(2UL, 1UL, 1UL).unwrap() == b'\xc6' && blurred_view.get_byte(2UL, 1UL, 2UL).unwrap() == b'\xc6' && blurred_view.get_byte(2UL, 1UL, 3UL).unwrap() == b'\xff' &&
    encoded.bytes_written() == 29UL && writer.position() == 29UL && foreground_diagnostics.length() == 0 && background_diagnostics.length() == 0 && encode_diagnostics.length() == 0 &&
    matches(writer.view(), expected.view(), 29UL) && digest(writer.view(), writer.position()) == 714923673UL
  if valid {
    println("example=portable bytes_read=38+29 bytes_written=29 width=3 height=2 crop rotate_90 rgb8_to_straight_rgba8 grayscale box_blur composite_source_over straight_rgba8_to_rgb8 digest=714923673 sha256=005700d6602b144bafcf3d869deee85619c8279c749bf33ca6fea8b43dbe78bf")
  } else {
    println("example=portable status=failed")
  }
}
