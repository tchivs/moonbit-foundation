///|
fn qoi_stream_encode_owner(capacity : UInt64) -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    Bytes::from_array(Array::make(capacity.to_int(), b'\x00')),
    qoi_encode_budget(bytes=capacity, work=0UL),
  ).unwrap()
}

///|
fn qoi_stream_encoder(
  image : @storage.OwnedImage,
  limits? : @codec.CodecLimits = qoi_encode_limits(),
  budget? : @budget.Budget = qoi_encode_budget(),
) -> QoiStreamEncoder {
  QoiStreamEncoder::new(image.view(), limits, budget, @error.Diagnostics::new()).unwrap()
}

///|
test "QOI stream encoder reports zero, one-byte, and final-marker progress" {
  let image = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
  )
  let encoder = qoi_stream_encoder(image)
  let empty = qoi_stream_encode_owner(0UL)
  let zero = empty
    .with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) })
    .unwrap()
  inspect(zero.written(), content="0")
  inspect(zero.total_written(), content="0")
  inspect(zero.outcome() is QoiStreamPullOutcome::NeedOutput, content="true")

  let one = qoi_stream_encode_owner(1UL)
  let mut completed = zero
  for turn = 0; turn < 24; turn = turn + 1 {
    completed = one
      .with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) })
      .unwrap()
    inspect(completed.written(), content="1")
  }
  inspect(completed.total_written(), content="24")
  inspect(completed.outcome() is QoiStreamPullOutcome::Finished, content="true")
  let terminal = one
    .with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) })
    .unwrap()
  inspect(terminal.written(), content="0")
  inspect(terminal.outcome() is QoiStreamPullOutcome::Failed(_), content="true")
}

///|
test "QOI stream encoder preflights before caller output exists" {
  let image = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
  )
  let budget = qoi_encode_budget(work=23UL)
  let before = budget.remaining()
  let result = QoiStreamEncoder::new(
    image.view(),
    qoi_encode_limits(),
    budget,
    @error.Diagnostics::new(),
  )
  inspect(result is Err(_), content="true")
  let after = budget.remaining()
  inspect(after.work() == before.work(), content="true")
}

///|
test "QOI stream encoder retains no mutable lease and preserves eager bytes" {
  let image = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
  )
  let (_, eager_writer) = qoi_encode(image)
  let eager = qoi_writer_prefix(eager_writer)
  let encoder = qoi_stream_encoder(image)
  let owner = qoi_stream_encode_owner(eager.length().to_uint64())
  let result = owner
    .with_mut(0UL, eager.length().to_uint64(), fn(lease) {
      Ok(encoder.pull(lease))
    })
    .unwrap()
  inspect(result.written() == eager.length().to_uint64(), content="true")
  inspect(result.outcome() is QoiStreamPullOutcome::Finished, content="true")
  let output : Array[Byte] = []
  for index = 0UL; index < eager.length().to_uint64(); index = index + 1UL {
    output.push(owner.view().get(index).unwrap())
  }
  inspect(Bytes::from_array(output) == eager, content="true")
}
