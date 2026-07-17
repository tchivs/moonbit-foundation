///|
fn append_decimal(output : Array[Byte], value : UInt64) -> Unit {
  if value == 0UL {
    output.push(b'0')
    return
  }
  let reversed : Array[Byte] = []
  let mut remaining = value
  while remaining > 0UL {
    reversed.push((48UL + remaining % 10UL).to_byte())
    remaining = remaining / 10UL
  }
  for index = reversed.length() - 1; index >= 0; index = index - 1 {
    output.push(reversed[index])
  }
}

///|
fn ppm_bytes(width : UInt64, height : UInt64, flipped : Bool) -> Bytes {
  let output : Array[Byte] = [b'P', b'6', b'\n']
  append_decimal(output, width)
  output.push(b' ')
  append_decimal(output, height)
  output.push(b'\n')
  output.push(b'2')
  output.push(b'5')
  output.push(b'5')
  output.push(b'\n')
  for y = 0UL; y < height; y = y + 1UL {
    for x = 0UL; x < width; x = x + 1UL {
      let source_x = if flipped { width - 1UL - x } else { x }
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        let index = (y * width + source_x) * 3UL + channel
        output.push(((index * 17UL + 31UL) % 256UL).to_byte())
      }
    }
  }
  Bytes::from_array(output)
}

///|
fn evidence_budget(width : UInt64, height : UInt64) -> @budget.Budget {
  let pixels = width * height
  let payload = pixels * 3UL
  let ceiling = payload * 4UL + 4096UL
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=ceiling,
      allocations=16UL,
      allocation_size=ceiling,
      width~,
      height~,
      pixels=pixels * 4UL,
      depth=0UL,
      work=ceiling * 4UL,
    ),
  )
}

///|
fn evidence_limits(width : UInt64, height : UInt64) -> @codec.CodecLimits {
  let payload = width * height * 3UL
  let ceiling = payload + 4096UL
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=ceiling,
    max_output_bytes=ceiling,
    max_width=width,
    max_height=height,
    max_pixels=width * height,
    max_work=ceiling,
  )
}

///|
fn parser_limits() -> @ppm.PpmParserLimits {
  @ppm.PpmParserLimits::new(
    max_header_bytes=256UL,
    max_token_bytes=16UL,
    max_comment_bytes=64UL,
    max_comments=4UL,
  ).unwrap()
}

///|
fn own_source(bytes : Bytes) -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    bytes,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=bytes.length().to_uint64(),
        allocations=1UL,
        allocation_size=bytes.length().to_uint64(),
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
fn decode_public(
  source : @bytes.OwnedBytes,
  width : UInt64,
  height : UInt64,
) -> @codec.DecodeResult {
  let reader = @io.MemoryReader::new(source.view())
  @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(parser_limits()),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    evidence_limits(width, height),
    evidence_budget(width, height),
    @error.Diagnostics::new(),
  ).unwrap()
}

///|
fn rolling257(view : @bytes.ByteView, length : UInt64) -> UInt64 {
  let mut digest = 0UL
  for index = 0UL; index < length; index = index + 1UL {
    digest = (digest * 257UL + view.get(index).unwrap().to_uint64()) %
      1000000007UL
  }
  digest
}

///|
fn image_rolling257(view : @storage.ImageView) -> UInt64 {
  let mut digest = 0UL
  for y = 0UL; y < view.height(); y = y + 1UL {
    for x = 0UL; x < view.width(); x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        digest = (
            digest * 257UL + view.get_byte(x, y, channel).unwrap().to_uint64()
          ) %
          1000000007UL
      }
    }
  }
  digest
}

///|
fn expected_pixel_digest(
  width : UInt64,
  height : UInt64,
  flipped : Bool,
) -> UInt64 {
  let mut digest = 0UL
  for y = 0UL; y < height; y = y + 1UL {
    for x = 0UL; x < width; x = x + 1UL {
      let source_x = if flipped { width - 1UL - x } else { x }
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        let index = (y * width + source_x) * 3UL + channel
        digest = (digest * 257UL + (index * 17UL + 31UL) % 256UL) % 1000000007UL
      }
    }
  }
  digest
}

///|
fn require_benchmark(condition : Bool, label : String) -> Unit {
  if !condition {
    abort("benchmark correctness failed: \{label}")
  }
}

///|
fn check_decode(
  source : @bytes.OwnedBytes,
  width : UInt64,
  height : UInt64,
) -> Unit {
  let decoded = decode_public(source, width, height)
  let view = decoded.image().view()
  require_benchmark(view.width() == width, "decode-width")
  require_benchmark(view.height() == height, "decode-height")
  require_benchmark(
    image_rolling257(view) == expected_pixel_digest(width, height, false),
    "decode-digest",
  )
}

///|
fn encode_public(
  image : @storage.OwnedImage,
  width : UInt64,
  height : UInt64,
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let capacity = width * height * 3UL + 4096UL
  let writer = @io.MemoryWriter::new(capacity, evidence_budget(width, height)).unwrap()
  let result = @codec.ImageEncoder::encode(
    @ppm.PpmEncoder::new(),
    image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    evidence_limits(width, height),
    evidence_budget(width, height),
    @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
fn decode_benchmark(it : @bench.T, width : UInt64, height : UInt64) -> Unit {
  let source = own_source(ppm_bytes(width, height, false))
  check_decode(source, width, height)
  it.bench(fn() { it.keep(decode_public(source, width, height)) }, count=1)
}

///|
fn encode_benchmark(it : @bench.T, width : UInt64, height : UInt64) -> Unit {
  let source = own_source(ppm_bytes(width, height, false))
  let image = decode_public(source, width, height).image()
  let (checked, writer) = encode_public(image, width, height)
  require_benchmark(
    checked.bytes_written() == source.length(),
    "encode-byte-count",
  )
  require_benchmark(
    rolling257(writer.view(), writer.position()) ==
    rolling257(source.view(), source.length()),
    "encode-digest",
  )
  it.bench(fn() { it.keep(encode_public(image, width, height)) }, count=1)
}

///|
test "ppm/decode/64x64" (it : @bench.T) {
  decode_benchmark(it, 64UL, 64UL)
}

///|
test "ppm/decode/256x256" (it : @bench.T) {
  decode_benchmark(it, 256UL, 256UL)
}

///|
test "ppm/decode/1024x1024" (it : @bench.T) {
  decode_benchmark(it, 1024UL, 1024UL)
}

///|
test "ppm/encode/64x64" (it : @bench.T) {
  encode_benchmark(it, 64UL, 64UL)
}

///|
test "ppm/encode/256x256" (it : @bench.T) {
  encode_benchmark(it, 256UL, 256UL)
}

///|
test "ppm/encode/1024x1024" (it : @bench.T) {
  encode_benchmark(it, 1024UL, 1024UL)
}

///|
fn reject_public(source : @bytes.OwnedBytes) -> @error.CoreError {
  let reader = @io.MemoryReader::new(source.view())
  @codec.ImageDecoder::decode(
    @ppm.PpmDecoder::new(
      @ppm.PpmParserLimits::new(
        max_header_bytes=64UL,
        max_token_bytes=4UL,
        max_comment_bytes=8UL,
        max_comments=1UL,
      ).unwrap(),
    ),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    evidence_limits(12345UL, 1UL),
    evidence_budget(12345UL, 1UL),
    @error.Diagnostics::new(),
  ).unwrap_err()
}

///|
test "ppm/reject/header-token-limit" (it : @bench.T) {
  let source = own_source(b"P6\n12345 1\n255\n")
  let checked = reject_public(source)
  require_benchmark(
    checked.code() == @error.ErrorCode::BudgetExceeded,
    "rejection-code",
  )
  it.bench(fn() { it.keep(reject_public(source)) }, count=1)
}

///|
fn pipeline_public(
  source : @bytes.OwnedBytes,
  width : UInt64,
  height : UInt64,
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let decoded = decode_public(source, width, height)
  let transformed = @ops.flip_horizontal(
    decoded.image().view(),
    evidence_budget(width, height),
  ).unwrap()
  encode_public(transformed.image(), width, height)
}

///|
test "ppm/pipeline/decode-flip-encode/256x256" (it : @bench.T) {
  let width = 256UL
  let height = 256UL
  let source = own_source(ppm_bytes(width, height, false))
  let expected = own_source(ppm_bytes(width, height, true))
  let (checked, writer) = pipeline_public(source, width, height)
  require_benchmark(
    checked.bytes_written() == expected.length(),
    "pipeline-byte-count",
  )
  require_benchmark(
    rolling257(writer.view(), writer.position()) ==
    rolling257(expected.view(), expected.length()),
    "pipeline-digest",
  )
  it.bench(fn() { it.keep(pipeline_public(source, width, height)) }, count=1)
}
