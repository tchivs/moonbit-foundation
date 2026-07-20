///|
fn qoi_stream_encode_wb_owner(capacity : UInt64) -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    Bytes::from_array(Array::make(capacity.to_int(), b'\x00')),
    qoi_encode_vector_budget(bytes=capacity, work=0UL),
  ).unwrap()
}

///|
fn qoi_stream_encode_vector_drain(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let encoder = QoiStreamEncoder::new(
    image.view(),
    qoi_encode_vector_limits(),
    qoi_encode_vector_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = qoi_stream_encode_wb_owner(16UL)
  let output : Array[Byte] = []
  let mut turn = 0
  while true {
    let capacity = schedule[turn % schedule.length()]
    let pull = owner
      .with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) })
      .unwrap()
    for index = 0UL; index < pull.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    if pull.total_written() != output.length().to_uint64() {
      return Err(
        qoi_encode_error(
          @error.ErrorCategory::State,
          @error.ErrorCode::InvalidRange,
          "qoi-stream-total",
        ),
      )
    }
    match pull.outcome() {
      QoiStreamPullOutcome::Finished => {
        let terminal = owner
          .with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) })
          .unwrap()
        if terminal.written() != 0UL ||
          !(terminal.outcome() is QoiStreamPullOutcome::Failed(_)) {
          return Err(
            qoi_encode_error(
              @error.ErrorCategory::State,
              @error.ErrorCode::InvalidRange,
              "qoi-stream-terminal",
            ),
          )
        }
        return Ok(Bytes::from_array(output))
      }
      QoiStreamPullOutcome::NeedOutput => turn = turn + 1
      QoiStreamPullOutcome::Failed(error) => return Err(error)
    }
  }
  Err(
    qoi_encode_error(
      @error.ErrorCategory::State,
      @error.ErrorCode::InvalidRange,
      "qoi-stream-unreachable",
    ),
  )
}

///|
test "generated QOI encoder vectors prove hostile output progress and terminal behavior" {
  for item in _generated_qoi_encode_cases() {
    let (id, pixels, width, height, channels, colorspace, expected) = item
    let image = qoi_encode_vector_image(
      width, height, channels, colorspace, pixels,
    )
    for schedule_item in _generated_qoi_output_schedules() {
      let (schedule_id, schedule) = schedule_item
      if qoi_stream_encode_vector_drain(image, schedule).unwrap() != expected {
        fail(id + "-" + schedule_id)
      }
    }
  }
}

///|
test "QOI stream encoder keeps a single private pending token across split pulls" {
  let image = qoi_encode_vector_image(1UL, 1UL, 3UL, 0UL, b"\x01\x02\x03")
  let encoder = QoiStreamEncoder::new(
    image.view(),
    qoi_encode_vector_limits(),
    qoi_encode_vector_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = qoi_stream_encode_wb_owner(15UL)
  let pull = owner
    .with_mut(0UL, 15UL, fn(lease) { Ok(encoder.pull(lease)) })
    .unwrap()
  inspect(pull.written(), content="15")
  inspect(encoder.state is QoiStreamEncodeState::Tokens(_), content="true")
  inspect(encoder.pending_offset, content="1")
  inspect(encoder.pending == b"\xa2\x79", content="true")
  let last = owner
    .with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) })
    .unwrap()
  inspect(last.written(), content="1")
  inspect(last.outcome() is QoiStreamPullOutcome::NeedOutput, content="true")
}

///|
test "QOI stream encoder charges work once before a zero-capacity pull" {
  let image = qoi_encode_vector_image(1UL, 1UL, 3UL, 0UL, b"\x01\x02\x03")
  let budget = qoi_encode_vector_budget(work=24UL)
  let before = budget.remaining()
  let encoder = QoiStreamEncoder::new(
    image.view(),
    qoi_encode_vector_limits(),
    budget,
    @error.Diagnostics::new(),
  ).unwrap()
  inspect(before.work() - budget.remaining().work(), content="24")
  let owner = qoi_stream_encode_wb_owner(0UL)
  ignore(
    owner.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap(),
  )
  inspect(before.work() - budget.remaining().work(), content="24")
}
