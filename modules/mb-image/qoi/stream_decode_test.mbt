///|
fn qoi_stream_decoder(
  limits? : @codec.CodecLimits = qoi_probe_limits(),
  budget? : @budget.Budget = qoi_decode_budget(),
) -> QoiStreamDecoder {
  QoiStreamDecoder::new(limits, budget, @error.Diagnostics::new())
}

///|
fn qoi_stream_push(
  decoder : QoiStreamDecoder,
  source : Bytes,
) -> QoiStreamPushResult {
  decoder.push(qoi_prefix_view(source))
}

///|
fn qoi_stream_chunk(source : Bytes, start : Int, end : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = start; index < end; index = index + 1 {
    result.push(source[index])
  }
  Bytes::from_array(result)
}

///|
test "QOI stream pushes report caller-chunk progress until explicit finish" {
  let source = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01"
  let decoder = qoi_stream_decoder()
  for offset = 0; offset < source.length(); offset = offset + 1 {
    let pushed = qoi_stream_push(decoder, Bytes::from_array([source[offset]]))
    inspect(pushed.consumed() == 1UL, content="true")
    inspect(pushed.outcome() is QoiStreamPushOutcome::NeedInput, content="true")
  }
  let decoded = decoder.finish().unwrap()
  inspect(decoded.bytes_read(), content="26")
  inspect(
    decoded.image().view().get_byte(0UL, 0UL, 2UL).unwrap().to_int(),
    content="3",
  )
}

///|
test "QOI stream finish is strict and terminal results are sticky" {
  let truncated = qoi_stream_decoder()
  let pushed = qoi_stream_push(
    truncated, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01",
  )
  inspect(pushed.outcome() is QoiStreamPushOutcome::NeedInput, content="true")
  let incomplete = truncated.finish().unwrap_err()
  inspect(
    incomplete.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
  let later = qoi_stream_push(truncated, b"\x02")
  inspect(later.consumed(), content="0")
  inspect(later.outcome() is QoiStreamPushOutcome::Failed(_), content="true")
  inspect(truncated.finish() is Err(_), content="true")

  let complete = qoi_stream_decoder()
  ignore(
    qoi_stream_push(
      complete, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc0\x00\x00\x00\x00\x00\x00\x00\x01",
    ),
  )
  ignore(complete.finish().unwrap())
  let after_complete = qoi_stream_push(complete, b"\x00")
  inspect(after_complete.consumed(), content="0")
  inspect(
    after_complete.outcome() is QoiStreamPushOutcome::Failed(_),
    content="true",
  )
}

///|
test "QOI stream finish rejects incomplete, malformed, and trailing markers" {
  let incomplete_marker = qoi_stream_decoder()
  let incomplete_push = qoi_stream_push(
    incomplete_marker, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc0\x00\x00\x00",
  )
  inspect(incomplete_push.consumed(), content="18")
  inspect(
    incomplete_push.outcome() is QoiStreamPushOutcome::NeedInput,
    content="true",
  )
  let incomplete_error = incomplete_marker.finish().unwrap_err()
  inspect(
    incomplete_error.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
  inspect(incomplete_error.context() == Some("qoi-end-marker"), content="true")
  let incomplete_later = qoi_stream_push(incomplete_marker, b"\x00")
  inspect(incomplete_later.consumed(), content="0")
  match incomplete_later.outcome() {
    QoiStreamPushOutcome::Failed(error) =>
      inspect(error.context() == Some("qoi-stream-terminal"), content="true")
    NeedInput => fail("incomplete marker must be terminal")
  }

  let malformed_marker = qoi_stream_decoder()
  let malformed_push = qoi_stream_push(
    malformed_marker, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc0\x00\x00\x00\x00\x00\x00\x00\x02",
  )
  inspect(malformed_push.consumed(), content="23")
  inspect(
    malformed_push.outcome() is QoiStreamPushOutcome::NeedInput,
    content="true",
  )
  let malformed_error = malformed_marker.finish().unwrap_err()
  inspect(
    malformed_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(malformed_error.context() == Some("qoi-end-marker"), content="true")
  inspect(qoi_stream_push(malformed_marker, b"\x00").consumed(), content="0")

  let trailing = qoi_stream_decoder()
  let trailing_push = qoi_stream_push(
    trailing, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc0\x00\x00\x00\x00\x00\x00\x00\x01X",
  )
  inspect(trailing_push.consumed(), content="24")
  inspect(
    trailing_push.outcome() is QoiStreamPushOutcome::NeedInput,
    content="true",
  )
  let trailing_error = trailing.finish().unwrap_err()
  inspect(
    trailing_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(trailing_error.context() == Some("qoi-trailing-data"), content="true")
  inspect(trailing_error.requested() == Some(1UL), content="true")
  inspect(trailing_error.completed() == Some(0UL), content="true")
  inspect(qoi_stream_push(trailing, b"\x00").consumed(), content="0")
}

///|
test "QOI stream matches eager decode for RGB and RGBA vectors" {
  for
    source in [
      b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01",
      b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x01\xff\x04\x05\x06\x07\x00\x00\x00\x00\x00\x00\x00\x01",
    ] {
    let stream = qoi_stream_decoder()
    let first = qoi_stream_push(stream, qoi_stream_chunk(source, 0, 14))
    inspect(first.consumed(), content="14")
    inspect(first.outcome() is QoiStreamPushOutcome::NeedInput, content="true")
    let rest = qoi_stream_push(
      stream,
      qoi_stream_chunk(source, 14, source.length()),
    )
    inspect(
      rest.consumed() == (source.length() - 14).to_uint64(),
      content="true",
    )
    inspect(rest.outcome() is QoiStreamPushOutcome::NeedInput, content="true")
    let decoded = stream.finish().unwrap()
    let eager = decode_qoi(source).unwrap()
    inspect(
      decoded.descriptor().width() == eager.descriptor().width(),
      content="true",
    )
    inspect(
      decoded.descriptor().height() == eager.descriptor().height(),
      content="true",
    )
    inspect(
      decoded.descriptor().metadata().transfer() ==
      eager.descriptor().metadata().transfer(),
      content="true",
    )
    inspect(decoded.bytes_read() == eager.bytes_read(), content="true")
    for channel = 0UL
        channel < decoded.descriptor().format().channel_count()
        channel = channel + 1UL {
      inspect(
        decoded.image().view().get_byte(0UL, 0UL, channel).unwrap() ==
        eager.image().view().get_byte(0UL, 0UL, channel).unwrap(),
        content="true",
      )
    }
  }
}

///|
test "QOI stream copies pending token bytes and reports terminal push consumption" {
  let source = b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xfe\x01\x02\x03\x00\x00\x00\x00\x00\x00\x00\x01"
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=26UL,
        allocations=1UL,
        allocation_size=26UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  let decoder = qoi_stream_decoder()
  let first = decoder.push(owner.view().subview(0UL, 15UL).unwrap())
  inspect(first.consumed(), content="15")
  ignore(
    owner.with_mut(14UL, 1UL, fn(lease) { lease.set(0UL, b'\x63') }).unwrap(),
  )
  ignore(
    qoi_stream_push(decoder, qoi_stream_chunk(source, 15, source.length())),
  )
  let decoded = decoder.finish().unwrap()
  inspect(
    decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap().to_int(),
    content="1",
  )

  let overrun = qoi_stream_decoder()
  let run = qoi_stream_push(
    overrun, b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\xc1",
  )
  inspect(run.consumed(), content="15")
  match run.outcome() {
    QoiStreamPushOutcome::Failed(error) =>
      inspect(error.context() == Some("qoi-run-overrun"), content="true")
    NeedInput => fail("run must fail")
  }
  let sticky = qoi_stream_push(overrun, b"\x00")
  inspect(sticky.consumed(), content="0")

  let input_limited = qoi_stream_decoder(
    limits=@codec.CodecLimits::new(
      max_probe_bytes=8UL,
      max_input_bytes=14UL,
      max_output_bytes=128UL,
      max_width=16UL,
      max_height=16UL,
      max_pixels=128UL,
      max_work=512UL,
    ),
  )
  let limited = qoi_stream_push(input_limited, source)
  inspect(limited.consumed(), content="14")
  match limited.outcome() {
    QoiStreamPushOutcome::Failed(error) =>
      inspect(error.context() == Some("input-bytes"), content="true")
    NeedInput => fail("input ceiling must fail")
  }
}
