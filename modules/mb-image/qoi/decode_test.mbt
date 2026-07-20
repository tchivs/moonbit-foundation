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
  )
  .unwrap()
  .view()
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
fn decode_qoi_with(
  source : Bytes,
  budget? : @budget.Budget = qoi_decode_budget(),
  limits? : @codec.CodecLimits = qoi_probe_limits(),
  complete? : Bool = true,
) -> Result[@codec.DecodeResult, @error.CoreError] {
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
      require_complete_input=complete,
      preserve_opaque_metadata=false,
    ),
    limits,
    budget,
    @error.Diagnostics::new(),
  )
}

///|
fn decode_qoi(source : Bytes) -> Result[@codec.DecodeResult, @error.CoreError] {
  decode_qoi_with(source)
}

///|
struct QoiScriptReader {
  source : Bytes
  mut cursor : Int
  fail_at : Int
  no_progress_at : Int
}

///|
impl @io.Reader for QoiScriptReader with fn read(self, destination) {
  if self.cursor == self.no_progress_at {
    return @io.ReadOutcome::Progress(0UL)
  }
  if self.cursor == self.fail_at {
    return @io.ReadOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::Host,
        @error.ErrorCode::HostOperationFailed,
        operation="qoi-scripted-read",
        context="scripted",
      ),
      0UL,
    )
  }
  if self.cursor == self.source.length() {
    return @io.ReadOutcome::EndOfStream
  }
  match destination.set(0UL, self.source[self.cursor]) {
    Err(error) => @io.ReadOutcome::Failed(error, 0UL)
    Ok(_) => {
      self.cursor = self.cursor + 1
      @io.ReadOutcome::Progress(1UL)
    }
  }
}

///|
fn decode_qoi_scripted(
  source : Bytes,
  fail_at? : Int = -1,
  no_progress_at? : Int = -1,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let reader = QoiScriptReader::{ source, cursor: 0, fail_at, no_progress_at }
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
    ).unwrap() ==
    @codec.ProbeOutcome::NeedMore(4UL),
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b"qoi"),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::NeedMore(4UL),
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b"qoif"),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::Match,
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      qoi_prefix_view(b"nope"),
      qoi_probe_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::NoMatch,
    content="true",
  )
}

///|
test "QOI forward-only reader failures retain structured payload progress" {
  let source = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01"
  inspect(decode_qoi_scripted(source) is Ok(_), content="true")
  let no_progress = decode_qoi_scripted(source, no_progress_at=14).unwrap_err()
  inspect(no_progress.code() == @error.ErrorCode::NoProgress, content="true")
  inspect(no_progress.operation() == Some("qoi-decode"), content="true")
  inspect(no_progress.context() == Some("qoi-payload"), content="true")
  inspect(no_progress.requested() == Some(1UL), content="true")
  inspect(no_progress.completed() == Some(0UL), content="true")
  let failed = decode_qoi_scripted(source, fail_at=15).unwrap_err()
  inspect(failed.category() == @error.ErrorCategory::Host, content="true")
  inspect(
    failed.code() == @error.ErrorCode::HostOperationFailed,
    content="true",
  )
  inspect(failed.context() == Some("qoi-payload"), content="true")
}

///|
test "QOI strict completion rejects malformed endings and relaxed completion stops at pixels" {
  let source = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01X"
  let strict = decode_qoi(source).unwrap_err()
  inspect(strict.context() == Some("qoi-trailing-data"), content="true")
  let relaxed = decode_qoi_with(source, complete=false).unwrap()
  inspect(relaxed.bytes_read(), content="18")
  let bad_marker = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc0\x00\x00\x00\x00\x00\x00\x00\x02",
  ).unwrap_err()
  inspect(bad_marker.context() == Some("qoi-end-marker"), content="true")
}

///|
test "QOI rejects malformed headers, truncation, and runs beyond output" {
  let bad_channels = decode_qoi(b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x02\x00").unwrap_err()
  inspect(bad_channels.context() == Some("qoi-channels"), content="true")
  let truncated = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01",
  ).unwrap_err()
  inspect(
    truncated.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
  let run_overrun = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc1\x00\x00\x00\x00\x00\x00\x00\x01",
  ).unwrap_err()
  inspect(run_overrun.context() == Some("qoi-run-overrun"), content="true")
}

///|
test "QOI header work preflight is exact and leaves rejected budgets unchanged" {
  let source = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01"
  let exact_limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=64UL,
    max_output_bytes=3UL,
    max_width=1UL,
    max_height=1UL,
    max_pixels=1UL,
    max_work=4UL,
  )
  let exact_budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=3UL,
      allocations=1UL,
      allocation_size=3UL,
      width=1UL,
      height=1UL,
      pixels=1UL,
      depth=0UL,
      work=4UL,
    ),
  )
  ignore(
    decode_qoi_with(source, budget=exact_budget, limits=exact_limits).unwrap(),
  )
  inspect(exact_budget.remaining().work(), content="0")
  let rejected_budget = qoi_decode_budget()
  let before = rejected_budget.remaining()
  let rejected_limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=64UL,
    max_output_bytes=3UL,
    max_width=1UL,
    max_height=1UL,
    max_pixels=1UL,
    max_work=3UL,
  )
  let rejected = decode_qoi_with(
    source,
    budget=rejected_budget,
    limits=rejected_limits,
  ).unwrap_err()
  inspect(rejected.context() == Some("work"), content="true")
  let after = rejected_budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
test "QOI decodes RGB and RGBA headers without converting declared semantics" {
  let rgb = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01",
  ).unwrap()
  inspect(
    rgb.descriptor().format().channels() == @model.ChannelOrder::Rgb,
    content="true",
  )
  inspect(rgb.descriptor().metadata().alpha() is None, content="true")
  inspect(
    rgb.descriptor().metadata().transfer() ==
    @color.TransferIdentity::EncodedSrgb,
    content="true",
  )
  inspect(
    rgb.image().view().get_byte(0UL, 0UL, 2UL).unwrap().to_int(),
    content="3",
  )
  inspect(rgb.bytes_read(), content="26")
  let rgba = decode_qoi(
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x01\xff\x04\x05\x06\x07\x00\x00\x00\x00\x00\x00\x00\x01",
  ).unwrap()
  inspect(
    rgba.descriptor().format().channels() == @model.ChannelOrder::Rgba,
    content="true",
  )
  inspect(
    rgba.descriptor().metadata().alpha() == Some(@color.AlphaMode::Straight),
    content="true",
  )
  inspect(
    rgba.descriptor().metadata().transfer() ==
    @color.TransferIdentity::LinearSrgb,
    content="true",
  )
  inspect(
    rgba.image().view().get_byte(0UL, 0UL, 3UL).unwrap().to_int(),
    content="7",
  )
  inspect(rgba.bytes_read(), content="27")
}
