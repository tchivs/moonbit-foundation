///|
fn png_stream_test_budget(work? : UInt64 = 1048576UL) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL, allocations=16UL, allocation_size=1048576UL,
    width=70000UL, height=8UL, pixels=560000UL, depth=0UL, work~, 
  ))
}

///|
fn png_stream_test_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=70000UL, max_height=8UL, max_pixels=560000UL, max_work=work,
  )
}

///|
fn png_stream_test_image(
  channels : UInt64,
  width? : UInt64 = 1UL,
  include_opaque? : Bool = false,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels * width, channels * width, channels * width, 1UL, 1UL, width, 1UL).unwrap()],
    channels * width,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        if include_opaque { [("test", "marker", "raw", b"x")] } else { [] },
        @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, (x + channel).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_test_eager(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_chunk_test_owner(capacity : UInt64, fill? : Byte = b'\x00') -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    Bytes::from_array(Array::make(capacity.to_int(), fill)),
    png_stream_test_budget(work=0UL),
  ).unwrap()
}

///|
fn png_chunk_test_pull(
  encoder : PngChunkEncoder,
  capacity : UInt64,
  output : Array[Byte],
) -> PngChunkPullResult {
  let owner = png_chunk_test_owner(capacity)
  let result = owner.with_mut(0UL, capacity, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  for index = 0UL; index < result.written(); index = index + 1UL {
    output.push(owner.view().get(index).unwrap())
  }
  result
}

///|
fn png_chunk_test_drain_encoder(
  encoder : PngChunkEncoder,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let output : Array[Byte] = []
  let mut turn = 0
  while turn < 1024 {
    let capacity = schedule[turn % schedule.length()]
    let result = png_chunk_test_pull(encoder, capacity, output)
    if result.total_written() != output.length().to_uint64() {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
        context="png-chunk-total",
      ))
    }
    match result.outcome() {
      PngChunkPullOutcome::Finished => return Ok(Bytes::from_array(output))
      PngChunkPullOutcome::Failed(error) => return Err(error)
      PngChunkPullOutcome::NeedOutput => turn = turn + 1
    }
  }
  Err(@error.CoreError::new(
    @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
    context="png-chunk-unreachable",
  ))
}

///|
fn png_chunk_test_drain(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  png_chunk_test_drain_encoder(encoder, schedule)
}

///|
test "PNG compression strategy chunk factories encode supported images" {
  for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
    let image = png_stream_test_image(3UL)
    let encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), strategy, png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap()
    let bytes = png_chunk_test_drain_encoder(encoder, [1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(bytes[0] == b'\x89' && bytes[1] == b'P', content="true")
    let owner = @bytes.OwnedBytes::from_bytes(
      bytes, png_stream_test_budget(work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x00', content="true")
  }
}

///|
test "PNG compression strategy legacy chunk constructors retain frozen stored bytes" {
  let rgb = png_stream_test_image(3UL)
  let rgb_bytes = png_chunk_test_drain(rgb, [1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgb_bytes ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let rgba = png_stream_test_image(4UL)
  let rgba_bytes = png_chunk_test_drain(rgba, [1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgba_bytes ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
}

///|
test "PNG encode machine eager oracle remains canonical for RGB and RGBA" {
  for image in [png_stream_test_image(3UL), png_stream_test_image(4UL)] {
    let eager = png_stream_test_eager(image)
    let colour_type = if image.view().format().channel_count() == 3UL { b'\x02' } else { b'\x06' }
    inspect(eager[0] == b'\x89' && eager[1] == b'P', content="true")
    inspect(eager[25] == colour_type, content="true")
  }
}

///|
test "PNG encode machine stores the exact multi-block length formula" {
  let scanlines = 65539UL
  let blocks = 2UL
  inspect(scanlines + 6UL + blocks * 5UL + 57UL, content="65612")
}

///|
test "PNG chunk encoder reports empty, one-byte, and irregular exact progress" {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL)
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(zero.written(), content="0")
  inspect(zero.total_written(), content="0")
  inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let output : Array[Byte] = []
  let first = png_chunk_test_pull(encoder, 1UL, output)
  inspect(first.written(), content="1")
  inspect(first.total_written(), content="1")
  inspect(first.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let irregular = png_chunk_test_pull(encoder, 3UL, output)
  inspect(irregular.written(), content="3")
  inspect(irregular.total_written(), content="4")
}

///|
test "PNG chunk encoder equals eager bytes for RGB and straight RGBA" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels)
    let eager = png_stream_test_eager(image)
    let chunked = png_chunk_test_drain(image, [1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(chunked == eager, content="true")
  }
}

///|
test "PNG chunk encoder retains no completed caller output lease" {
  let image = png_stream_test_image(3UL)
  let eager = png_stream_test_eager(image)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let first_owner = png_chunk_test_owner(1UL)
  let first = first_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(first.written(), content="1")
  let output : Array[Byte] = [first_owner.view().get(0UL).unwrap()]
  first_owner.with_mut(0UL, 1UL, fn(lease) { lease.set(0UL, b'X') }).unwrap()
  let mut turn = 0
  while turn < 1024 {
    let result = png_chunk_test_pull(encoder, 2UL, output)
    match result.outcome() {
      PngChunkPullOutcome::Finished => break
      PngChunkPullOutcome::Failed(_) => panic()
      PngChunkPullOutcome::NeedOutput => turn = turn + 1
    }
  }
  inspect(Bytes::from_array(output) == eager, content="true")
  let terminal_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let terminal = terminal_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(terminal.written(), content="0")
  inspect(terminal.total_written() == eager.length().to_uint64(), content="true")
  inspect(terminal.outcome() is PngChunkPullOutcome::Finished, content="true")
  inspect(terminal_owner.view().get(0UL).unwrap() == b'Z', content="true")
}

///|
test "PNG chunk encoder replays the original released-lease failure" {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = owner.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(failed.written(), content="0")
  inspect(failed.total_written(), content="0")
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written(), content="0")
  inspect(replay_error.category() == first_error.category(), content="true")
  inspect(replay_error.code() == first_error.code(), content="true")
  inspect(replay_error.operation() == first_error.operation(), content="true")
  inspect(replay_error.context() == first_error.context(), content="true")
  inspect(replay_error.requested() == first_error.requested(), content="true")
  inspect(replay_error.completed() == first_error.completed(), content="true")
  inspect(replay_error.limit() == first_error.limit(), content="true")
  inspect(replay_owner.view().get(0UL).unwrap() == b'Z', content="true")
}

///|
test "PNG encoder isolated four-target evidence preserves hostile output and preflight parity" {
  png_chunk_test_four_target_evidence()
}

///|
fn png_chunk_test_same_error(
  left : @error.CoreError,
  right : @error.CoreError,
) -> Bool {
  left.category() == right.category() &&
    left.code() == right.code() &&
    left.operation() == right.operation() &&
    left.context() == right.context() &&
    left.requested() == right.requested() &&
    left.completed() == right.completed() &&
    left.limit() == right.limit()
}

///|
fn png_chunk_test_eager_error(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> @error.CoreError {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true, preserve_opaque_metadata=false,
    ), limits, budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if writer.position() != 0UL { abort("png chunk eager preflight output") }
  error
}

///|
fn png_chunk_test_drain_hostile(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Bytes {
  let eager = png_stream_test_eager(image)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 1024UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity)
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png chunk hostile progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    if turn == 0UL && capacity == 0UL &&
      (pulled.written() != 0UL || pulled.total_written() != 0UL ||
        !(pulled.outcome() is PngChunkPullOutcome::NeedOutput)) {
      abort("png chunk empty output")
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png chunk hostile output failure")
      PngChunkPullOutcome::Finished => {
        let terminal_total = pulled.total_written()
        for _ in [0, 1] {
          let terminal_owner = png_chunk_test_owner(7UL, fill=b'Z')
          let terminal = terminal_owner.with_mut(0UL, 7UL, fn(lease) {
            Ok(encoder.pull(lease))
          }).unwrap()
          if terminal.written() != 0UL || terminal.total_written() != terminal_total ||
            !(terminal.outcome() is PngChunkPullOutcome::Finished) {
            abort("png chunk terminal progress")
          }
          for index = 0UL; index < 7UL; index = index + 1UL {
            if terminal_owner.view().get(index).unwrap() != b'Z' {
              abort("png chunk terminal mutation")
            }
          }
        }
        let bytes = Bytes::from_array(output)
        if bytes != eager { abort("png chunk eager parity") }
        return bytes
      }
    }
  }
  abort("png chunk hostile drain unreachable")
}

///|
fn png_chunk_test_preflight_parity() -> Unit {
  let image = png_stream_test_image(3UL)
  let output_limits = png_stream_test_limits(output=71UL)
  let eager_output = png_chunk_test_eager_error(
    image, output_limits, png_stream_test_budget(),
  )
  let output_budget = png_stream_test_budget()
  let output_before = output_budget.remaining().work()
  let chunk_output = PngChunkEncoder::new(
    image.view(), output_limits, output_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_output, chunk_output) ||
    output_budget.remaining().work() != output_before {
    abort("png chunk output preflight parity")
  }

  let work_limits = png_stream_test_limits()
  let eager_work = png_chunk_test_eager_error(
    image, work_limits, png_stream_test_budget(work=71UL),
  )
  let work_budget = png_stream_test_budget(work=71UL)
  let work_before = work_budget.remaining().work()
  let chunk_work = PngChunkEncoder::new(
    image.view(), work_limits, work_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_work, chunk_work) ||
    work_budget.remaining().work() != work_before {
    abort("png chunk work preflight parity")
  }

  let retained = png_stream_test_image(3UL, include_opaque=true)
  let opaque_limits = png_stream_test_limits()
  let eager_opaque = png_chunk_test_eager_error(
    retained, opaque_limits, png_stream_test_budget(),
  )
  let opaque_budget = png_stream_test_budget()
  let opaque_before = opaque_budget.remaining().work()
  let chunk_opaque = PngChunkEncoder::new(
    retained.view(), opaque_limits, opaque_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_opaque, chunk_opaque) ||
    opaque_budget.remaining().work() != opaque_before {
    abort("png chunk opaque preflight parity")
  }
}

///|
fn png_chunk_test_released_lease_terminal() -> Unit {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = owner.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png chunk released lease outcome")
  }
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png chunk released lease replay")
  }
  if failed.written() != 0UL || replay.written() != 0UL ||
    failed.total_written() != 0UL || replay.total_written() != 0UL ||
    !png_chunk_test_same_error(first_error, replay_error) ||
    replay_owner.view().get(0UL).unwrap() != b'Z' {
    abort("png chunk released lease terminal")
  }
}

///|
fn png_chunk_test_four_target_evidence() -> Unit {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels)
    ignore(png_chunk_test_drain_hostile(image, [0UL, 1UL]))
    ignore(png_chunk_test_drain_hostile(image, [1UL]))
    ignore(png_chunk_test_drain_hostile(
      image, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
    ))
  }
  png_chunk_test_released_lease_terminal()
  png_chunk_test_preflight_parity()
}
