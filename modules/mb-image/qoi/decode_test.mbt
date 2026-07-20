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
fn qoi_decode_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=128UL,
      allocations=1UL,
      allocation_size=128UL,
      width=16UL,
      height=16UL,
      pixels=128UL,
      depth=0UL,
      work=512UL,
    ),
  )
}

///|
fn decode_qoi(source : Bytes) -> Result[@codec.DecodeResult, @error.CoreError] {
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=source.length().to_uint64(),
        allocations=1UL,
        allocation_size=source.length().to_uint64(),
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    QoiDecoder::new(),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    qoi_probe_limits(),
    qoi_decode_budget(),
    @error.Diagnostics::new(),
  )
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

///|
test "QOI decodes RGB and RGBA headers without converting declared semantics" {
  let rgb = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01",
  ).unwrap()
  inspect(rgb.descriptor().format().channels() == @model.ChannelOrder::Rgb, content="true")
  inspect(rgb.descriptor().metadata().alpha() is None, content="true")
  inspect(rgb.descriptor().metadata().transfer() == @color.TransferIdentity::EncodedSrgb, content="true")
  inspect(rgb.image().view().get_byte(0UL, 0UL, 2UL).unwrap().to_int(), content="3")
  inspect(rgb.bytes_read(), content="26")
  let rgba = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x01\xff\x04\x05\x06\x07\x00\x00\x00\x00\x00\x00\x00\x01",
  ).unwrap()
  inspect(rgba.descriptor().format().channels() == @model.ChannelOrder::Rgba, content="true")
  inspect(rgba.descriptor().metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(rgba.descriptor().metadata().transfer() == @color.TransferIdentity::LinearSrgb, content="true")
  inspect(rgba.image().view().get_byte(0UL, 0UL, 3UL).unwrap().to_int(), content="7")
  inspect(rgba.bytes_read(), content="27")
}
