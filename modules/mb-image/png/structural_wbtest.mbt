///|
test "PNG structural CRC uses type plus payload scope" {
  inspect(_png_crc32(b"IHDR") != _png_crc32(b""), content="true")
}

///|
fn png_decode_generated_vector(
  source : Bytes,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let length = source.length().to_uint64()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length, allocations=1UL, allocation_size=length, width=0UL,
        height=0UL, pixels=0UL, depth=0UL, work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    ),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=1024UL, allocations=1UL, allocation_size=1024UL, width=16UL,
        height=16UL, pixels=256UL, depth=0UL, work=2048UL,
      ),
    ),
    @error.Diagnostics::new(),
  )
}

///|
test "generated PNG structural vectors execute private validator branches" {
  for item in _generated_png_structural_cases() {
    let (_id, bytes, expected) = item
    let error = png_decode_generated_vector(bytes).unwrap_err()
    if expected == "unexpected-end" {
      inspect(
        error.code() == @error.ErrorCode::UnexpectedEndOfStream,
        content="true",
      )
    } else {
      inspect(error.context() == Some(expected), content="true")
    }
  }
}

///|
test "PNG opaque ancillary preservation and IHDR preflight leave caller state unchanged" {
  let (_, ancillary, _) = _generated_png_structural_cases()[12]
  let ancillary_length = ancillary.length().to_uint64()
  let ancillary_owner = @bytes.OwnedBytes::from_bytes(
    ancillary,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=ancillary_length, allocations=1UL, allocation_size=ancillary_length,
      width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let ancillary_reader = @io.MemoryReader::new(ancillary_owner.view())
  let ancillary_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1024UL, allocations=1UL, allocation_size=1024UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=2048UL,
  ))
  let diagnostics = @error.Diagnostics::new()
  let before = ancillary_budget.remaining()
  let preserved = @codec.ImageDecoder::decode(
    PngDecoder::new(), ancillary_reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=true,
    ),
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    ),
    ancillary_budget, diagnostics,
  ).unwrap_err()
  let after = ancillary_budget.remaining()
  inspect(
    preserved.context() == Some("opaque-metadata-preservation"), content="true",
  )
  inspect(before.bytes() == after.bytes(), content="true")
  inspect(before.work() == after.work(), content="true")
  inspect(diagnostics.length(), content="0")

  let (_, valid, _) = _generated_png_structural_cases()[13]
  let valid_length = valid.length().to_uint64()
  let valid_owner = @bytes.OwnedBytes::from_bytes(
    valid,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=valid_length, allocations=1UL, allocation_size=valid_length,
      width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let valid_reader = @io.MemoryReader::new(valid_owner.view())
  let limited_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=2UL, allocations=1UL, allocation_size=1024UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=2048UL,
  ))
  let limited_before = limited_budget.remaining()
  let preflight = @codec.ImageDecoder::decode(
    PngDecoder::new(), valid_reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    ),
    limited_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(preflight.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(limited_before.bytes() == limited_budget.remaining().bytes(), content="true")
}

///|
test "PNG IHDR preflight checks every codec and allocation envelope ceiling" {
  let ihdr = [
    b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01',
    b'\x08', b'\x02', b'\x00', b'\x00', b'\x00',
  ]
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1024UL, allocations=1UL, allocation_size=1024UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=2048UL,
  ))
  for item in [
    ("width", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=0UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("height", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=0UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("pixels", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=0UL, max_work=2048UL,
    )),
    ("image-bytes", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=2UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("output-bytes", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=3UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("work", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=6UL,
    )),
  ] {
    let (expected, limits) = item
    let error = _png_preflight_ihdr(ihdr, limits, budget).unwrap_err()
    inspect(error.context() == Some(expected), content="true")
  }
  let allocation_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1024UL, allocations=1UL, allocation_size=2UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=2048UL,
  ))
  let allocation = _png_preflight_ihdr(
    ihdr,
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    ),
    allocation_budget,
  ).unwrap_err()
  inspect(allocation.context() == Some("allocation_size"), content="true")
}

///|
test "PNG semantic classifier rejects every deferred semantic chunk family" {
  for kind in [
    [b'P', b'L', b'T', b'E'], [b't', b'R', b'N', b'S'],
    [b'c', b'H', b'R', b'M'], [b'g', b'A', b'M', b'A'],
    [b'i', b'C', b'C', b'P'], [b's', b'B', b'I', b'T'],
    [b's', b'R', b'G', b'B'], [b'c', b'I', b'C', b'P'],
    [b'm', b'D', b'C', b'v'], [b'c', b'L', b'L', b'i'],
    [b'a', b'c', b'T', b'L'], [b'f', b'c', b'T', b'L'],
    [b'f', b'd', b'A', b'T'],
  ] {
    inspect(_png_is_known_semantic(kind), content="true")
  }
}
