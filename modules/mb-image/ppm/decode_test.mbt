///|
fn decode_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=256UL,
    max_output_bytes=128UL,
    max_width=16UL,
    max_height=16UL,
    max_pixels=128UL,
    max_work=512UL,
  )
}

///|
fn decode_parser_limits() -> PpmParserLimits {
  PpmParserLimits::new(
    max_header_bytes=128UL,
    max_token_bytes=20UL,
    max_comment_bytes=64UL,
    max_comments=8UL,
  ).unwrap()
}

///|
fn decode_source(value : Bytes) -> @bytes.OwnedBytes {
  let length = value.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    value,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length,
        allocations=1UL,
        allocation_size=length,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
}

///|
fn decode_budget(
  bytes? : UInt64 = 128UL,
  allocations? : UInt64 = 1UL,
  allocation_size? : UInt64 = 128UL,
  width? : UInt64 = 16UL,
  height? : UInt64 = 16UL,
  pixels? : UInt64 = 128UL,
  work? : UInt64 = 512UL,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width~,
      height~,
      pixels~,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn decode_ppm(
  source : Bytes,
  budget? : @budget.Budget = decode_budget(),
  limits? : @codec.CodecLimits = decode_limits(),
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let owner = decode_source(source)
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    PpmDecoder::new(decode_parser_limits()),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    limits,
    budget,
    @error.Diagnostics::new(),
  )
}

///|
test "strict P6 decoder returns one tight sRGB image" {
  let result = decode_ppm(b"P6\n2 1\n255\n\x00\x7f\xff\x01\x02\x03").unwrap()
  let descriptor = result.descriptor()
  inspect(descriptor.width(), content="2")
  inspect(descriptor.height(), content="1")
  inspect(descriptor.storage_length(), content="6")
  inspect(
    descriptor.format().channels() == @model.ChannelOrder::Rgb,
    content="true",
  )
  inspect(
    descriptor.metadata().orientation() == @model.Orientation::TopLeft,
    content="true",
  )
  inspect(result.bytes_read(), content="17")
  let view = result.image().view()
  inspect(view.get_byte(0UL, 0UL, 0UL).unwrap().to_int(), content="0")
  inspect(view.get_byte(0UL, 0UL, 1UL).unwrap().to_int(), content="127")
  inspect(view.get_byte(0UL, 0UL, 2UL).unwrap().to_int(), content="255")
  inspect(view.get_byte(1UL, 0UL, 2UL).unwrap().to_int(), content="3")
}

///|
test "strict P6 decoder rejects truncation and every trailing byte" {
  let truncated = decode_ppm(b"P6\n1 1\n255\n\x01\x02").unwrap_err()
  inspect(
    truncated.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
  inspect(truncated.requested() == Some(3UL), content="true")
  inspect(truncated.completed() == Some(2UL), content="true")
  for suffix in [b"X", b"P6\n1 1\n255\n\x00\x00\x00"] {
    let trailing = decode_ppm(b"P6\n1 1\n255\n\x01\x02\x03" + suffix).unwrap_err()
    inspect(trailing.category() == @error.ErrorCategory::Data, content="true")
    inspect(trailing.code() == @error.ErrorCode::InvalidEncoding, content="true")
    inspect(trailing.context() == Some("ppm-trailing-data"), content="true")
  }
}

///|
test "all authoritative output ceilings reject atomically" {
  for budget in [
    decode_budget(bytes=5UL),
    decode_budget(allocations=0UL),
    decode_budget(allocation_size=5UL),
    decode_budget(width=1UL),
    decode_budget(height=0UL),
    decode_budget(pixels=1UL),
    decode_budget(work=16UL),
  ] {
    let before = budget.remaining()
    ignore(decode_ppm(b"P6\n2 1\n255\n\x00\x01\x02\x03\x04\x05", budget~).unwrap_err())
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.pixels() == before.pixels(), content="true")
    inspect(after.work() == before.work(), content="true")
  }
}
