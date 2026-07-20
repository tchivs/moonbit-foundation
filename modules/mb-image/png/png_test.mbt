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
test "PNG public probe matrix is caller-owned and bounded" {
  let decoder = PngDecoder::new()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=8UL, allocations=1UL, allocation_size=8UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    ),
  )
  let owner = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n",
    budget,
  ).unwrap()
  inspect(
    @codec.ImageDecoder::probe(
      decoder, owner.view().slice_to(4UL).unwrap(), png_test_limits(),
      @error.Diagnostics::new(),
    ).unwrap() == @codec.ProbeOutcome::NeedMore(8UL),
    content="true",
  )
  let non_png = @bytes.OwnedBytes::from_bytes(
    b"\x00PNG\r\n\x1a\n",
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
  inspect(@codec.ImageDecoder::probe(decoder, non_png.view(), png_test_limits(), @error.Diagnostics::new()).unwrap() == @codec.ProbeOutcome::NoMatch, content="true")
  inspect(@codec.ImageDecoder::probe(decoder, owner.view(), png_test_limits(), @error.Diagnostics::new()).unwrap() == @codec.ProbeOutcome::Match, content="true")
  let limited = @codec.ImageDecoder::probe(
    decoder, owner.view(),
    @codec.CodecLimits::new(max_probe_bytes=7UL, max_input_bytes=128UL, max_output_bytes=64UL, max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=128UL),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(limited.category() == @error.ErrorCategory::Resource, content="true")
  inspect(limited.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(limited.context() == Some("probe-bytes"), content="true")
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
fn png_test_remaining_unchanged(
  before : @budget.ResourceLimits,
  after : @budget.ResourceLimits,
) -> Bool {
  before.bytes() == after.bytes() &&
  before.allocations() == after.allocations() &&
  before.allocation_size() == after.allocation_size() &&
  before.width() == after.width() &&
  before.height() == after.height() &&
  before.pixels() == after.pixels() &&
  before.depth() == after.depth() &&
  before.work() == after.work()
}

///|
fn png_test_limits_from_generated(item : PngGeneratedCase) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=item.limits.probe,
    max_input_bytes=item.limits.input,
    max_output_bytes=item.limits.output,
    max_width=item.limits.width,
    max_height=item.limits.height,
    max_pixels=item.limits.pixels,
    max_work=item.limits.work,
  )
}

///|
fn png_test_budget_from_generated(item : PngGeneratedCase) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=item.budget.bytes, allocations=item.budget.allocations,
    allocation_size=item.budget.allocation_size, width=item.budget.width,
    height=item.budget.height, pixels=item.budget.pixels,
    depth=item.budget.depth, work=item.budget.work,
  ))
}

///|
test "generated PNG public cases use only the PngDecoder trait boundary" {
  for item in _generated_png_public_cases() {
    let length = item.bytes.length().to_uint64()
    let owner = @bytes.OwnedBytes::from_bytes(
      item.bytes,
      @budget.Budget::new(@budget.ResourceLimits::new(
        bytes=length, allocations=1UL, allocation_size=length, width=0UL,
        height=0UL, pixels=0UL, depth=0UL, work=0UL,
      )),
    ).unwrap()
    let reader = @io.MemoryReader::new(owner.view())
    let budget = png_test_budget_from_generated(item)
    let before = budget.remaining()
    let diagnostics = @error.Diagnostics::new()
    let error = @codec.ImageDecoder::decode(
      PngDecoder::new(), reader as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=item.preserve_opaque_metadata,
      ),
      png_test_limits_from_generated(item),
      budget, diagnostics,
    ).unwrap_err()
    if item.code == "unexpected-end" {
      inspect(error.category() == @error.ErrorCategory::IO, content="true")
      inspect(error.code() == @error.ErrorCode::UnexpectedEndOfStream, content="true")
    } else if item.code == "budget-exceeded" {
      inspect(error.category() == @error.ErrorCategory::Resource, content="true")
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    } else if item.code == "capability-unavailable" {
      inspect(error.category() == @error.ErrorCategory::Capability, content="true")
      inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
    } else {
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
    }
    inspect(error.context() == Some(item.context), content="true")
    if item.immutable_caller_state {
      inspect(png_test_remaining_unchanged(before, budget.remaining()), content="true")
      inspect(diagnostics.length(), content="0")
    }
  }
}
