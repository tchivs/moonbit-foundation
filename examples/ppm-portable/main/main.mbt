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
fn main {
  let source_bytes = b"P6\n2 1\n255\n\x00\x7f\xff\x01\x02\x03"
  let source = @bytes.OwnedBytes::from_bytes(
    source_bytes,
    example_budget(17UL, 1UL, 17UL, 0UL, 0UL),
  ).unwrap()
  let reader = @io.MemoryReader::new(source.view())
  let processing_budget = example_budget(12UL, 2UL, 6UL, 4UL, 40UL)
  let diagnostics = @error.Diagnostics::new()
  let decoded = @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(parser_limits()),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    processing_budget,
    diagnostics,
  ).unwrap()
  let transformed = @ops.flip_horizontal(
    decoded.image().view(),
    processing_budget,
  ).unwrap()
  let writer = @io.MemoryWriter::new(
    17UL,
    example_budget(17UL, 1UL, 17UL, 0UL, 0UL),
  ).unwrap()
  let encoded = @codec.ImageEncoder::encode(
    @ppm.PpmEncoder::new(),
    transformed.image().view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    codec_limits(),
    processing_budget,
    diagnostics,
  ).unwrap()
  let valid = decoded.bytes_read() == 17UL &&
    decoded.descriptor().width() == 2UL &&
    decoded.descriptor().height() == 1UL &&
    transformed.disposition().preserved_length() == 5 &&
    encoded.bytes_written() == 17UL &&
    writer.position() == 17UL &&
    diagnostics.length() == 0 &&
    digest(writer.view(), writer.position()) == 806175100UL
  if valid {
    println(
      "example=portable bytes_read=17 bytes_written=17 width=2 height=1 transform=flip_horizontal disposition=5 digest=806175100",
    )
  } else {
    println("example=portable status=failed")
  }
}
