///|
fn vector_budget(
  bytes? : UInt64 = 512UL,
  allocations? : UInt64 = 8UL,
  work? : UInt64 = 1024UL,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size=bytes,
      width=64UL,
      height=64UL,
      pixels=4096UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn vector_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=16UL,
    max_input_bytes=512UL,
    max_output_bytes=512UL,
    max_width=64UL,
    max_height=64UL,
    max_pixels=4096UL,
    max_work=1024UL,
  )
}

///|
fn vector_decode(
  source : Bytes,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    vector_budget(bytes=source.length().to_uint64(), allocations=1UL, work=0UL),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    PpmDecoder::new(
      PpmParserLimits::new(
        max_header_bytes=256UL,
        max_token_bytes=20UL,
        max_comment_bytes=128UL,
        max_comments=16UL,
      ).unwrap(),
    ),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    vector_limits(),
    vector_budget(),
    @error.Diagnostics::new(),
  )
}

///|
fn vector_encode(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(
    512UL,
    vector_budget(bytes=512UL, allocations=1UL, work=0UL),
  ).unwrap()
  ignore(
    @codec.ImageEncoder::encode(
      PpmEncoder::new(),
      image.view(),
      writer as &@io.Writer,
      @codec.EncodeOptions::new(
        lossless_required=true,
        preserve_opaque_metadata=false,
      ),
      vector_limits(),
      vector_budget(),
      @error.Diagnostics::new(),
    ).unwrap(),
  )
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///|
test "generated canonical corpus proves semantic and byte round trips" {
  inspect(_generated_ppm_cases().length(), content="4")
  for item in _generated_ppm_cases() {
    let (_, canonical, payload) = item
    let decoded = vector_decode(canonical).unwrap()
    let view = decoded.image().view()
    let logical : Array[Byte] = []
    for y = 0UL; y < view.height(); y = y + 1UL {
      for x = 0UL; x < view.width(); x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          logical.push(view.get_byte(x, y, channel).unwrap())
        }
      }
    }
    inspect(Bytes::from_array(logical) == payload, content="true")
    inspect(vector_encode(decoded.image()) == canonical, content="true")
    inspect(vector_decode(canonical + b"X") is Err(_), content="true")
  }
}

///|
test "generated adversarial and chunk schedule inventories are closed" {
  inspect(_generated_ppm_adversarial_ids().length(), content="6")
  inspect(_generated_ppm_chunk_schedules().length(), content="4")
  for item in _generated_ppm_chunk_schedules() {
    let (_, chunks) = item
    inspect(chunks.length() > 0, content="true")
    for chunk in chunks {
      inspect(chunk > 0UL, content="true")
    }
  }
}

///|
test "noncanonical accepted header canonicalizes on encode" {
  let decoded = vector_decode(b"P6\n# project-derived\n1 1\n255\n\x01\x02\x03").unwrap()
  inspect(
    vector_encode(decoded.image()) == b"P6\n1 1\n255\n\x01\x02\x03",
    content="true",
  )
}
