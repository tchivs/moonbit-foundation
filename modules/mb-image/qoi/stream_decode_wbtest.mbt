///|
fn qoi_stream_wb_limits() -> @codec.CodecLimits {
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
fn qoi_stream_wb_budget() -> @budget.Budget {
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
fn qoi_stream_wb_decoder(
  limits? : @codec.CodecLimits = qoi_stream_wb_limits(),
  budget? : @budget.Budget = qoi_stream_wb_budget(),
) -> QoiStreamDecoder {
  QoiStreamDecoder::new(limits, budget, @error.Diagnostics::new())
}

///|
fn qoi_stream_wb_view(value : Bytes) -> @bytes.ByteView {
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
fn qoi_stream_wb_push(
  decoder : QoiStreamDecoder,
  source : Bytes,
) -> QoiStreamPushResult {
  decoder.push(qoi_stream_wb_view(source))
}

///|
fn qoi_stream_wb_chunk(source : Bytes, start : Int, end : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = start; index < end; index = index + 1 {
    result.push(source[index])
  }
  Bytes::from_array(result)
}

///|
fn qoi_stream_vector_decode(
  source : Bytes,
  schedule : Array[UInt64],
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let decoder = qoi_stream_wb_decoder(
    limits=@codec.CodecLimits::new(
      max_probe_bytes=16UL,
      max_input_bytes=1024UL,
      max_output_bytes=512UL,
      max_width=64UL,
      max_height=64UL,
      max_pixels=128UL,
      max_work=1024UL,
    ),
    budget=@budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=512UL,
        allocations=1UL,
        allocation_size=512UL,
        width=64UL,
        height=64UL,
        pixels=128UL,
        depth=0UL,
        work=1024UL,
      ),
    ),
  )
  let mut cursor = 0
  let mut turn = 0
  while cursor < source.length() {
    let requested = schedule[turn % schedule.length()].to_int()
    let end = if cursor + requested < source.length() {
      cursor + requested
    } else {
      source.length()
    }
    let pushed = qoi_stream_wb_push(
      decoder,
      qoi_stream_wb_chunk(source, cursor, end),
    )
    if pushed.consumed() != (end - cursor).to_uint64() ||
      !(pushed.outcome() is QoiStreamPushOutcome::NeedInput) {
      return Err(
        qoi_error(
          @error.ErrorCategory::State,
          @error.ErrorCode::InvalidRange,
          "qoi-stream-vector-push",
        ),
      )
    }
    cursor = end
    turn = turn + 1
  }
  let decoded = match decoder.finish() {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if decoded.bytes_read() != source.length().to_uint64() {
    return Err(
      qoi_error(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        "qoi-stream-vector-total",
      ),
    )
  }
  let terminal = qoi_stream_wb_push(decoder, b"\x00")
  if terminal.consumed() != 0UL ||
    !(terminal.outcome() is QoiStreamPushOutcome::Failed(_)) {
    return Err(
      qoi_error(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        "qoi-stream-vector-terminal",
      ),
    )
  }
  Ok(decoded)
}

///|
test "generated QOI vectors prove hostile input progress and terminal behavior" {
  for item in _generated_qoi_cases() {
    let (id, source, expected, width, height, channels, _) = item
    for schedule_item in _generated_qoi_input_schedules() {
      let (schedule_id, schedule) = schedule_item
      let decoded = match qoi_stream_vector_decode(source, schedule) {
        Ok(value) => value
        Err(_) => fail(id + "-" + schedule_id)
      }
      inspect(decoded.descriptor().width() == width, content="true")
      inspect(decoded.descriptor().height() == height, content="true")
      inspect(
        decoded.bytes_read() == source.length().to_uint64(),
        content="true",
      )
      let view = decoded.image().view()
      for offset = 0UL
          offset < expected.length().to_uint64()
          offset = offset + 1UL {
        let pixel = offset / channels
        if view
          .get_byte(pixel % width, pixel / width, offset % channels)
          .unwrap() !=
          expected[offset.to_int()] {
          fail(id + "-" + schedule_id)
        }
      }
    }
  }
}

///|
test "QOI stream header preflight charges once and rejects before allocation" {
  let source = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00"
  let rejected_budget = qoi_stream_wb_budget()
  let before = rejected_budget.remaining()
  let rejected = qoi_stream_wb_decoder(
    limits=@codec.CodecLimits::new(
      max_probe_bytes=8UL,
      max_input_bytes=64UL,
      max_output_bytes=3UL,
      max_width=1UL,
      max_height=1UL,
      max_pixels=1UL,
      max_work=3UL,
    ),
    budget=rejected_budget,
  )
  let failed = qoi_stream_wb_push(rejected, source)
  inspect(failed.consumed(), content="14")
  inspect(failed.outcome() is QoiStreamPushOutcome::Failed(_), content="true")
  let after = rejected_budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")

  let accepted_budget = qoi_stream_wb_budget()
  let accepted = qoi_stream_wb_decoder(budget=accepted_budget)
  ignore(qoi_stream_wb_push(accepted, source))
  inspect(accepted_budget.remaining().allocations(), content="0")
  inspect(accepted_budget.remaining().work(), content="508")
  inspect(accepted.finish() is Err(_), content="true")
  inspect(accepted_budget.remaining().work(), content="508")
}

///|
test "QOI stream parser keeps bounded copied state across pending and marker phases" {
  let decoder = qoi_stream_wb_decoder()
  inspect(decoder.state is QoiStreamState::Header(_), content="true")
  ignore(
    qoi_stream_wb_push(
      decoder, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01",
    ),
  )
  match decoder.state {
    QoiStreamState::Pixels(pixels) =>
      inspect(pixels.pending is QoiStreamPending::Rgb(_), content="true")
    _ => fail("expected pending RGB")
  }
  ignore(qoi_stream_wb_push(decoder, b"\x02\x03\x00\x00\x00"))
  match decoder.state {
    QoiStreamState::Marker(_, marker) => inspect(marker.length(), content="3")
    _ => fail("expected partial marker")
  }
  let incomplete = decoder.finish().unwrap_err()
  inspect(incomplete.context() == Some("qoi-end-marker"), content="true")
}
