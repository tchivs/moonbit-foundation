///|
fn qoi_probe_limits() -> @codec.CodecLimits {
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
fn qoi_prefix_view(value : Bytes) -> @bytes.ByteView {
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
  ).unwrap().view()
}

///|
test "QOI probe classifies only caller-owned prefixes" {
  let decoder = QoiDecoder::new()
  let diagnostics = @error.Diagnostics::new()
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b""),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() == @codec.ProbeOutcome::NeedMore(4UL),
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b"qoi"),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() == @codec.ProbeOutcome::NeedMore(4UL),
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b"qoif"),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() == @codec.ProbeOutcome::Match,
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b"nope"),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() == @codec.ProbeOutcome::NoMatch,
    content="true",
  )
}
