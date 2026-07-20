///|
fn png_test_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=128UL,
    max_output_bytes=64UL,
    max_width=4UL,
    max_height=4UL,
    max_pixels=16UL,
    max_work=128UL,
  )
}

///|
test "PNG probe requires an eight-byte caller-owned signature" {
  let decoder = PngDecoder::new()
  let owner = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n",
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=8UL,
        allocations=1UL,
        allocation_size=8UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      owner.view(),
      png_test_limits(),
      @error.Diagnostics::new(),
    ).unwrap() ==
    @codec.ProbeOutcome::Match,
    content="true",
  )
}

///|
test "PNG decoder rejects a signature-only forward reader before capability" {
  let source = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n",
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=8UL,
        allocations=1UL,
        allocation_size=8UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(source.view())
  let error = @codec.ImageDecoder::decode(
    PngDecoder::new(),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    png_test_limits(),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=128UL,
        allocations=1UL,
        allocation_size=64UL,
        width=4UL,
        height=4UL,
        pixels=16UL,
        depth=0UL,
        work=128UL,
      ),
    ),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(
    error.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
}

///|
test "PNG public decoder reaches capability only after complete structural transport" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x00IDAT\x35\xaf\x06\x1e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=source.length().to_uint64(), allocations=1UL,
        allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
        pixels=0UL, depth=0UL, work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    ),
  )
  let before = budget.remaining()
  let diagnostics = @error.Diagnostics::new()
  let error = @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    png_test_limits(), budget, diagnostics,
  ).unwrap_err()
  inspect(
    error.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(error.context() == Some("deflate-and-raster-pending"), content="true")
  inspect(before.bytes() == budget.remaining().bytes(), content="true")
  inspect(diagnostics.length(), content="0")
}

///|
test "PNG exact input ceiling permits EOF but an actual trailing byte is limited" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x00IDAT\x35\xaf\x06\x1e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  inspect(source.length(), content="57")
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=57UL, max_output_bytes=64UL,
    max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=128UL,
  )
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
    height=4UL, pixels=16UL, depth=0UL, work=128UL,
  ))
  let diagnostics = @error.Diagnostics::new()
  let before = budget.remaining()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=57UL, allocations=1UL, allocation_size=57UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  let exact = @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    limits, budget, diagnostics,
  ).unwrap_err()
  inspect(exact.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
  inspect(exact.context() == Some("deflate-and-raster-pending"), content="true")
  let after = budget.remaining()
  inspect(before.bytes() == after.bytes(), content="true")
  inspect(before.allocations() == after.allocations(), content="true")
  inspect(before.allocation_size() == after.allocation_size(), content="true")
  inspect(before.width() == after.width(), content="true")
  inspect(before.height() == after.height(), content="true")
  inspect(before.pixels() == after.pixels(), content="true")
  inspect(before.work() == after.work(), content="true")
  inspect(diagnostics.length(), content="0")

  let trailing_owner = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x00IDAT\x35\xaf\x06\x1e\x00\x00\x00\x00IEND\xae\x42\x60\x82\x00",
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=58UL, allocations=1UL, allocation_size=58UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let trailing_reader = @io.MemoryReader::new(trailing_owner.view())
  let limited = @codec.ImageDecoder::decode(
    PngDecoder::new(), trailing_reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    limits,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(limited.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(limited.context() == Some("input-bytes"), content="true")
}

///|
test "generated PNG public cases use only the PngDecoder trait boundary" {
  for item in _generated_png_public_cases() {
    let (_id, source, expected, preserve_opaque_metadata, limits_profile, _budget, immutable) = item
    let length = source.length().to_uint64()
    let owner = @bytes.OwnedBytes::from_bytes(
      source,
      @budget.Budget::new(@budget.ResourceLimits::new(
        bytes=length, allocations=1UL, allocation_size=length, width=0UL,
        height=0UL, pixels=0UL, depth=0UL, work=0UL,
      )),
    ).unwrap()
    let reader = @io.MemoryReader::new(owner.view())
    let budget = @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=1024UL, allocations=1UL, allocation_size=1024UL, width=16UL,
      height=16UL, pixels=256UL, depth=0UL, work=2048UL,
    ))
    let before = budget.remaining()
    let diagnostics = @error.Diagnostics::new()
    let error = @codec.ImageDecoder::decode(
      PngDecoder::new(), reader as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=preserve_opaque_metadata,
      ),
      if limits_profile == "input-57" {
        @codec.CodecLimits::new(
          max_probe_bytes=8UL, max_input_bytes=57UL, max_output_bytes=1024UL,
          max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
        )
      } else {
        @codec.CodecLimits::new(
          max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
          max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
        )
      },
      budget, diagnostics,
    ).unwrap_err()
    if expected == "unexpected-end" {
      inspect(error.code() == @error.ErrorCode::UnexpectedEndOfStream, content="true")
    } else {
      inspect(error.context() == Some(expected), content="true")
    }
    if immutable {
      inspect(before.bytes() == budget.remaining().bytes(), content="true")
      inspect(before.work() == budget.remaining().work(), content="true")
      inspect(diagnostics.length(), content="0")
    }
  }
}
