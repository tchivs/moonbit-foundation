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
        bytes=8UL, allocations=1UL, allocation_size=8UL, width=0UL,
        height=0UL, pixels=0UL, depth=0UL, work=0UL,
      ),
    ),
  ).unwrap()
  inspect(
    @codec.ImageDecoder::probe(
      decoder, owner.view(), png_test_limits(), @error.Diagnostics::new(),
    ).unwrap() == @codec.ProbeOutcome::Match,
    content="true",
  )
}
