///| A hostile but valid caller-owned schedule: each Reader transition exposes
/// exactly one byte.  This is a black-box check that the eager facade never
/// assumes a coalesced transport buffer before Phase 27 makes the chunk API
/// public.
struct PngOneByteScheduleReader {
  source : Bytes
  mut cursor : Int
}

///|
impl @io.Reader for PngOneByteScheduleReader with fn read(self, destination) {
  if destination.length() == 0UL { return @io.ReadOutcome::Progress(0UL) }
  if self.cursor == self.source.length() { return @io.ReadOutcome::EndOfStream }
  match destination.set(0UL, self.source[self.cursor]) {
    Err(error) => @io.ReadOutcome::Failed(error, 0UL)
    Ok(_) => { self.cursor = self.cursor + 1; @io.ReadOutcome::Progress(1UL) }
  }
}

///| Compare every public success field without relying on test-package access
/// to implementation records.  The generated vector corpus supplies expected
/// pixels separately; this comparator makes scheduled and normal readers
/// agree on their complete observable image contract.
fn png_scheduled_result_matches(
  left : @codec.DecodeResult,
  right : @codec.DecodeResult,
) -> Bool {
  let left_descriptor = left.descriptor()
  let right_descriptor = right.descriptor()
  if left.bytes_read() != right.bytes_read() ||
    left_descriptor.width() != right_descriptor.width() ||
    left_descriptor.height() != right_descriptor.height() ||
    left_descriptor.format().channel_count() != right_descriptor.format().channel_count() ||
    left_descriptor.storage_length() != right_descriptor.storage_length() ||
    left_descriptor.plane_count() != right_descriptor.plane_count() ||
    left.disposition().preserved_length() != right.disposition().preserved_length() ||
    left.disposition().transformed_length() != right.disposition().transformed_length() ||
    left.disposition().discarded_length() != right.disposition().discarded_length() ||
    left.disposition().is_lossy() != right.disposition().is_lossy() {
    return false
  }
  for index = 0; index < left_descriptor.plane_count(); index = index + 1 {
    let left_plane = left_descriptor.plane(index).unwrap()
    let right_plane = right_descriptor.plane(index).unwrap()
    if left_plane.range().start() != right_plane.range().start() ||
      left_plane.range().end() != right_plane.range().end() ||
      left_plane.row_stride() != right_plane.row_stride() {
      return false
    }
  }
  let left_metadata = left_descriptor.metadata()
  let right_metadata = right_descriptor.metadata()
  if left_metadata.space() != right_metadata.space() ||
    left_metadata.transfer() != right_metadata.transfer() ||
    left_metadata.alpha() != right_metadata.alpha() ||
    left_metadata.orientation() != right_metadata.orientation() ||
    left_metadata.profile().is_builtin_srgb() != right_metadata.profile().is_builtin_srgb() {
    return false
  }
  let left_entries = left_metadata.opaque_metadata()
  let right_entries = right_metadata.opaque_metadata()
  if left_entries.length() != right_entries.length() { return false }
  for index = 0; index < left_entries.length(); index = index + 1 {
    let left_entry = left_entries.entry(index).unwrap()
    let right_entry = right_entries.entry(index).unwrap()
    if left_entry.canonical_key() != right_entry.canonical_key() ||
      left_entry.value().length() != right_entry.value().length() {
      return false
    }
    for value_index = 0UL; value_index < left_entry.value().length(); value_index = value_index + 1UL {
      if left_entry.value().get(value_index).unwrap() != right_entry.value().get(value_index).unwrap() {
        return false
      }
    }
  }
  let left_view = left.image().view()
  let right_view = right.image().view()
  for y = 0UL; y < left_descriptor.height(); y = y + 1UL {
    for x = 0UL; x < left_descriptor.width(); x = x + 1UL {
      for channel = 0UL; channel < left_descriptor.format().channel_count(); channel = channel + 1UL {
        if left_view.get_byte(x, y, channel).unwrap() !=
          right_view.get_byte(x, y, channel).unwrap() {
          return false
        }
      }
    }
  }
  true
}

fn png_decode_one_byte_schedule(item : PngDecodeVector) -> Result[@codec.DecodeResult, @error.CoreError] {
  let reader = PngOneByteScheduleReader::{ source: item.bytes, cursor: 0 }
  @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL,
      max_output_bytes=item.max_output, max_width=64UL,
      max_height=16UL, max_pixels=1024UL, max_work=item.max_work,
    ),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=item.budget_bytes, allocations=item.budget_allocations,
      allocation_size=item.budget_allocation_size, width=64UL,
      height=16UL, pixels=1024UL, depth=0UL, work=item.max_work,
    )),
    @error.Diagnostics::new(),
  )
}

test "PNG eager facade preserves generated successes at one-byte reader boundaries" {
  for item in _generated_png_decode_cases() {
    if item.outcome == "accepted" {
      match (png_test_decode_vector(item), png_decode_one_byte_schedule(item)) {
        (Ok(left), Ok(right)) => if !png_scheduled_result_matches(left, right) {
          fail("generated PNG one-byte facade mismatch: " + item.id)
        }
        (Err(error), _) => fail("generated PNG normal oracle failed: " + item.id + ": " + error.context().unwrap())
        (_, Err(error)) => fail("generated PNG one-byte reader failed: " + item.id + ": " + error.context().unwrap())
      }
    }
  }
}
///|
/// The caller-buffered decoder deliberately has no implicit EOF: an empty
/// chunk is ordinary progress and a result may only leave the private machine
/// after `finish`.
test "PNG chunk decoder API has strict explicit finish" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=128UL,
    max_output_bytes=64UL,
    max_width=4UL,
    max_height=4UL,
    max_pixels=16UL,
    max_work=128UL,
  )
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=128UL, allocations=8UL, allocation_size=64UL, width=4UL,
    height=4UL, pixels=16UL, depth=0UL, work=128UL,
  ))
  let decoder = PngChunkDecoder::new(limits, budget, @error.Diagnostics::new())
  let owner = @bytes.OwnedBytes::from_bytes(
    b"",
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=0UL, allocations=1UL, allocation_size=1UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let pushed = decoder.push(owner.view())
  inspect(pushed.consumed() == 0UL, content="true")
  inspect(pushed.outcome() is PngChunkPushOutcome::NeedInput, content="true")
  inspect(decoder.finish().unwrap_err().code() == @error.ErrorCode::UnexpectedEndOfStream, content="true")
}

///|
/// Pushing a complete transport is still non-terminal: the owned image remains
/// private through IEND until the caller supplies the separate EOF transition.
test "PNG chunk decoder transfers one result and preserves terminal errors" {
  let data = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let source = @bytes.OwnedBytes::from_bytes(
    data,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=data.length().to_uint64(), allocations=1UL,
      allocation_size=data.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=256UL, max_output_bytes=64UL,
    max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=256UL,
  )
  let decoder = PngChunkDecoder::new(
    limits,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=256UL, allocations=8UL, allocation_size=128UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=256UL,
    )),
    @error.Diagnostics::new(),
  )
  let pushed = decoder.push(source.view())
  inspect(pushed.consumed() == data.length().to_uint64(), content="true")
  inspect(pushed.outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let result = decoder.finish().unwrap()
  inspect(result.bytes_read() == data.length().to_uint64(), content="true")
  inspect(result.image().view().get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x12'")
  inspect(decoder.finish().unwrap_err().category() == @error.ErrorCategory::State, content="true")
  let after_finish = decoder.push(source.view())
  inspect(after_finish.consumed() == 0UL, content="true")
  inspect(after_finish.outcome() is PngChunkPushOutcome::Failed(_), content="true")

  let malformed = @bytes.OwnedBytes::from_bytes(
    b"X",
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=1UL, allocations=1UL, allocation_size=1UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let failed = PngChunkDecoder::new(
    limits,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=256UL, allocations=8UL, allocation_size=128UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=256UL,
    )),
    @error.Diagnostics::new(),
  )
  let first = failed.push(malformed.view())
  inspect(first.consumed() == 1UL, content="true")
  match first.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(error.context() == Some("png-signature"), content="true")
    _ => fail("malformed PNG must fail during push")
  }
  let replay = failed.push(source.view())
  inspect(replay.consumed() == 0UL, content="true")
  match replay.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(error.context() == Some("png-signature"), content="true")
    _ => fail("first PNG error must be sticky")
  }
  inspect(failed.finish().unwrap_err().context() == Some("png-signature"), content="true")
}

///| Build a fresh caller-owned suffix.  The chunk API must never retain the
/// previous owner's view, so each scheduled push can use an independently
/// owned slice.
fn png_chunk_bytes(source : Bytes, start : Int, end : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = start; index < end; index = index + 1 {
    result.push(source[index])
  }
  Bytes::from_array(result)
}

///|
fn png_chunk_source(source : Bytes) -> @bytes.OwnedBytes {
  let length = source.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=length, allocations=1UL, allocation_size=length, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
}

///|
fn png_chunk_vector_limits(item : PngDecodeVector) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL,
    max_output_bytes=item.max_output, max_width=64UL,
    max_height=16UL, max_pixels=1024UL, max_work=item.max_work,
  )
}

///|
fn png_chunk_vector_budget(item : PngDecodeVector) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=item.budget_bytes, allocations=item.budget_allocations,
    allocation_size=item.budget_allocation_size, width=64UL,
    height=16UL, pixels=1024UL, depth=0UL, work=item.max_work,
  ))
}

///| Compare the full typed shape retained by sticky chunk failures.  Error
/// prose is intentionally not part of the public contract.
fn png_chunk_error_matches(left : @error.CoreError, right : @error.CoreError) -> Bool {
  left.category() == right.category() &&
  left.code() == right.code() &&
  left.operation() == right.operation() &&
  left.context() == right.context() &&
  left.requested() == right.requested() &&
  left.completed() == right.completed() &&
  left.limit() == right.limit()
}

///| The terminal byte is observable at the public boundary.  A source error
/// has a concrete admitted prefix; an EOF-only error has no source terminal.
struct PngChunkScheduleRun {
  source_terminal : UInt64?
  result : Result[@codec.DecodeResult, @error.CoreError]
}

///| Drive the published chunk decoder with fresh caller allocations on every
/// turn.  The zero-length call is deliberately part of every schedule: it is
/// ordinary progress, never an implicit EOF declaration.
fn png_chunk_public_schedule(
  item : PngDecodeVector,
  lane : String,
  packets : Array[UInt64],
  expected_source_terminal : UInt64?,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> PngChunkScheduleRun {
  let decoder = PngChunkDecoder::new(png_chunk_vector_limits(item), budget, diagnostics)
  let empty = png_chunk_source(b"")
  let zero = decoder.push(empty.view())
  if zero.consumed() != 0UL || !(zero.outcome() is PngChunkPushOutcome::NeedInput) {
    fail("PNG " + lane + " empty push must be active: " + item.id)
  }
  let length = item.bytes.length().to_uint64()
  let mut offset = 0UL
  let mut turn = 0
  let mut terminal : @error.CoreError? = None
  while offset < length && terminal is None {
    let requested = min(packets[turn % packets.length()], length - offset)
    let owner = png_chunk_source(png_chunk_bytes(
      item.bytes, offset.to_int(), (offset + requested).to_int(),
    ))
    let pushed = decoder.push(owner.view())
    match pushed.outcome() {
      PngChunkPushOutcome::NeedInput => {
        if pushed.consumed() != requested {
          fail("PNG " + lane + " active progress mismatch: " + item.id)
        }
        match expected_source_terminal {
          Some(expected) => if offset + requested >= expected {
            fail("PNG " + lane + " missed source terminal: " + item.id)
          }
          None => ()
        }
        offset = offset + requested
      }
      PngChunkPushOutcome::Failed(error) => {
        if pushed.consumed() == 0UL || pushed.consumed() > requested {
          fail("PNG " + lane + " terminal admission mismatch: " + item.id)
        }
        offset = offset + pushed.consumed()
        match expected_source_terminal {
          Some(expected) => if offset != expected {
            fail("PNG " + lane + " terminal prefix mismatch: " + item.id)
          }
          None => fail("PNG " + lane + " unexpectedly failed in push: " + item.id)
        }
        terminal = Some(error)
      }
    }
    turn = turn + 1
  }
  match terminal {
    Some(error) => {
      let replay_owner = png_chunk_source(b"")
      let replay = decoder.push(replay_owner.view())
      if replay.consumed() != 0UL {
        fail("PNG " + lane + " sticky push consumed bytes: " + item.id)
      }
      match replay.outcome() {
        PngChunkPushOutcome::Failed(value) => if !png_chunk_error_matches(value, error) {
          fail("PNG " + lane + " sticky push error mismatch: " + item.id)
        }
        _ => fail("PNG " + lane + " sticky push lost error: " + item.id)
      }
      let finished = decoder.finish().unwrap_err()
      if !png_chunk_error_matches(finished, error) {
        fail("PNG " + lane + " sticky finish error mismatch: " + item.id)
      }
      PngChunkScheduleRun::{ source_terminal: Some(offset), result: Err(error) }
    }
    None => {
      match expected_source_terminal {
        Some(_) => fail("PNG " + lane + " source ended before terminal: " + item.id)
        None => PngChunkScheduleRun::{ source_terminal: None, result: decoder.finish() }
      }
    }
  }
}

///| Compare one public schedule with an independently initialized eager
/// facade, including the caller-visible resource and diagnostic state.
fn png_chunk_schedule_matches_eager(
  item : PngDecodeVector,
  lane : String,
  scheduled : Result[@codec.DecodeResult, @error.CoreError],
  scheduled_budget : @budget.Budget,
  scheduled_diagnostics : @error.Diagnostics,
) -> Unit {
  let eager_budget = png_chunk_vector_budget(item)
  let eager_diagnostics = @error.Diagnostics::new()
  let eager = png_chunk_eager_vector(item, eager_budget, eager_diagnostics)
  match (eager, scheduled) {
    (Ok(left), Ok(right)) => if !png_scheduled_result_matches(left, right) {
      fail("PNG " + lane + " eager result mismatch: " + item.id)
    }
    (Err(left), Err(right)) => if !png_chunk_error_matches(left, right) {
      fail("PNG " + lane + " eager error mismatch: " + item.id)
    }
    (Ok(_), Err(error)) => fail("PNG " + lane + " unexpectedly failed: " + item.id + ": " + error.context().unwrap())
    (Err(error), Ok(_)) => fail("PNG " + lane + " unexpectedly succeeded: " + item.id + ": " + error.context().unwrap())
  }
  if !png_test_remaining_unchanged(eager_budget.remaining(), scheduled_budget.remaining()) {
    fail("PNG " + lane + " eager budget mismatch: " + item.id)
  }
  if eager_diagnostics.length() != scheduled_diagnostics.length() ||
    eager_diagnostics.render() != scheduled_diagnostics.render() {
    fail("PNG " + lane + " eager diagnostics mismatch: " + item.id)
  }
}

///| The complete generated corpus proves only public PngChunkDecoder calls:
/// every record begins empty, then crosses all byte boundaries and a mixed
/// ragged caller schedule before explicit finish determines completion.
test "PNG chunk decoder proves generated corpus through hostile public schedules" {
  for item in _generated_png_decode_cases() {
    let one_byte_budget = png_chunk_vector_budget(item)
    let one_byte_diagnostics = @error.Diagnostics::new()
    let one_byte = png_chunk_public_schedule(
      item, "empty-then-one-byte", [1UL], None,
      one_byte_budget, one_byte_diagnostics,
    )
    png_chunk_schedule_matches_eager(
      item, "empty-then-one-byte", one_byte.result,
      one_byte_budget, one_byte_diagnostics,
    )
    let ragged_budget = png_chunk_vector_budget(item)
    let ragged_diagnostics = @error.Diagnostics::new()
    let ragged = png_chunk_public_schedule(
      item, "ragged-public-packets", [8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
      one_byte.source_terminal, ragged_budget, ragged_diagnostics,
    )
    if ragged.source_terminal != one_byte.source_terminal {
      fail("PNG ragged terminal prefix differs from one-byte: " + item.id)
    }
    png_chunk_schedule_matches_eager(
      item, "ragged-public-packets", ragged.result,
      ragged_budget, ragged_diagnostics,
    )
  }
}

///| Every accepted generated profile crosses the public chunk facade one
/// caller byte at a time.  This exercises signature, chunk framing, IDAT,
/// DEFLATE, filters, IEND, and the final pre-finish state without relying on
/// Reader EOF semantics.
test "PNG chunk decoder preserves every accepted generated profile at one-byte caller boundaries" {
  for item in _generated_png_decode_cases() {
    if item.outcome == "accepted" {
      let budget = png_chunk_vector_budget(item)
      let diagnostics = @error.Diagnostics::new()
      let decoder = PngChunkDecoder::new(png_chunk_vector_limits(item), budget, diagnostics)
      let source = png_chunk_source(item.bytes)
      for index = 0UL; index < source.length(); index = index + 1UL {
        let pushed = decoder.push(source.view().subview(index, 1UL).unwrap())
        inspect(pushed.consumed() == 1UL, content="true")
        inspect(pushed.outcome() is PngChunkPushOutcome::NeedInput, content="true")
      }
      let decoded = decoder.finish().unwrap()
      let eager = png_test_decode_vector(item).unwrap()
      if !png_scheduled_result_matches(decoded, eager) {
        fail("generated PNG chunk one-byte facade mismatch: " + item.id)
      }
      inspect(diagnostics.length() == 0, content="true")
    }
  }
}

///| A successful partial push has synchronously handed bytes to the private
/// machine.  Reusing the caller allocation after return must not change the
/// future raster produced from an independent suffix.
test "PNG chunk decoder does not retain a caller ByteView after partial push" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = png_chunk_source(source)
  let decoder = PngChunkDecoder::new(
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=256UL, max_output_bytes=64UL, max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=256UL),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=256UL, allocations=8UL, allocation_size=128UL, width=4UL, height=4UL, pixels=16UL, depth=0UL, work=256UL)),
    @error.Diagnostics::new(),
  )
  let first = decoder.push(owner.view().subview(0UL, 48UL).unwrap())
  inspect(first.consumed() == 48UL, content="true")
  inspect(first.outcome() is PngChunkPushOutcome::NeedInput, content="true")
  ignore(owner.with_mut(47UL, 1UL, fn(lease) { lease.set(0UL, b'X') }).unwrap())
  let suffix = png_chunk_source(png_chunk_bytes(source, 48, source.length()))
  let second = decoder.push(suffix.view())
  inspect(second.consumed() == suffix.length(), content="true")
  inspect(second.outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let decoded = decoder.finish().unwrap()
  inspect(decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x12', content="true")
}

///| Parser-dispatched malformed bytes count in their call, while a byte
/// refused by the public input ceiling does not.  Both terminals replay the
/// original typed error through later push and finish calls.
test "PNG chunk decoder reports exact terminal consumption and sticky typed errors" {
  let malformed = PngChunkDecoder::new(
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=128UL, allocations=8UL, allocation_size=64UL, width=4UL, height=4UL, pixels=16UL, depth=0UL, work=128UL)),
    @error.Diagnostics::new(),
  )
  let first_owner = png_chunk_source(b"X")
  let first = malformed.push(first_owner.view())
  let expected = match first.outcome() {
    PngChunkPushOutcome::Failed(error) => error
    _ => fail("malformed signature must terminate during push")
  }
  inspect(first.consumed() == 1UL, content="true")
  let later_owner = png_chunk_source(b"Y")
  let later = malformed.push(later_owner.view())
  inspect(later.consumed() == 0UL, content="true")
  match later.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(png_chunk_error_matches(error, expected), content="true")
    _ => fail("first malformed error must stay sticky")
  }
  inspect(png_chunk_error_matches(malformed.finish().unwrap_err(), expected), content="true")

  let limited = PngChunkDecoder::new(
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=0UL, max_output_bytes=64UL, max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=128UL),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=128UL, allocations=8UL, allocation_size=64UL, width=4UL, height=4UL, pixels=16UL, depth=0UL, work=128UL)),
    @error.Diagnostics::new(),
  )
  let rejected_owner = png_chunk_source(b"\x89")
  let rejected = limited.push(rejected_owner.view())
  inspect(rejected.consumed() == 0UL, content="true")
  match rejected.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(error.context() == Some("input-bytes"), content="true")
    _ => fail("input ceiling must reject before dispatch")
  }
}

///| Run the eager facade with externally visible accounting objects so the
/// public chunk route can compare diagnostics and every budget dimension.
fn png_chunk_eager_vector(
  item : PngDecodeVector,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let source = png_chunk_source(item.bytes)
  @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(source.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_chunk_vector_limits(item), budget, diagnostics,
  )
}

///| The generated corpus includes stored, fixed, dynamic, indexed, alpha,
/// 16-bit, Adam7, sRGB, legacy, ICC, structural, DEFLATE, raster, resource,
/// allocation, and budget paths.  Route each one through independent eager
/// and one-byte caller-owned decoders and compare all observable outcomes.
test "PNG chunk decoder matches eager errors diagnostics and budget remainders for generated corpus" {
  for item in _generated_png_decode_cases() {
    let chunk_budget = png_chunk_vector_budget(item)
    let chunk_diagnostics = @error.Diagnostics::new()
    let decoder = PngChunkDecoder::new(
      png_chunk_vector_limits(item), chunk_budget, chunk_diagnostics,
    )
    let source = png_chunk_source(item.bytes)
    let mut terminal : @error.CoreError? = None
    for index = 0UL; index < source.length(); index = index + 1UL {
      if terminal is None {
        let pushed = decoder.push(source.view().subview(index, 1UL).unwrap())
        match pushed.outcome() {
          PngChunkPushOutcome::NeedInput => inspect(pushed.consumed() == 1UL, content="true")
          PngChunkPushOutcome::Failed(error) => {
            inspect(pushed.consumed() == 1UL, content="true")
            terminal = Some(error)
          }
        }
      }
    }
    let chunk = match terminal {
      Some(error) => Err(error)
      None => decoder.finish()
    }
    let eager_budget = png_chunk_vector_budget(item)
    let eager_diagnostics = @error.Diagnostics::new()
    let eager = png_chunk_eager_vector(item, eager_budget, eager_diagnostics)
    match (eager, chunk) {
      (Ok(left), Ok(right)) => if !png_scheduled_result_matches(left, right) {
        fail("generated PNG eager/chunk result mismatch: " + item.id)
      }
      (Err(left), Err(right)) => if !png_chunk_error_matches(left, right) {
        fail("generated PNG eager/chunk error mismatch: " + item.id)
      }
      (Ok(_), Err(error)) => fail("generated PNG chunk unexpectedly failed: " + item.id + ": " + error.context().unwrap())
      (Err(error), Ok(_)) => fail("generated PNG chunk unexpectedly succeeded: " + item.id + ": " + error.context().unwrap())
    }
    if !png_test_remaining_unchanged(eager_budget.remaining(), chunk_budget.remaining()) {
      fail("generated PNG eager/chunk budget mismatch: " + item.id)
    }
    if eager_diagnostics.length() != chunk_diagnostics.length() ||
      eager_diagnostics.render() != chunk_diagnostics.render() {
      fail("generated PNG eager/chunk diagnostics mismatch: " + item.id)
    }
  }
}

///| Mixed caller partitions deliberately end at PNG framing boundaries and
/// keep a complete IEND non-terminal until the separate EOF declaration.
test "PNG chunk decoder mixed structural partitions keep IEND pending until finish" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let decoder = PngChunkDecoder::new(
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=256UL, max_output_bytes=64UL, max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=256UL),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=256UL, allocations=8UL, allocation_size=128UL, width=4UL, height=4UL, pixels=16UL, depth=0UL, work=256UL)),
    @error.Diagnostics::new(),
  )
  let mut offset = 0
  for boundary in [8, 12, 16, 29, 33, 37, 41, 43, 48, 56, 60, 64, 68, source.length()] {
    let owner = png_chunk_source(png_chunk_bytes(source, offset, boundary))
    let pushed = decoder.push(owner.view())
    inspect(pushed.consumed() == (boundary - offset).to_uint64(), content="true")
    inspect(pushed.outcome() is PngChunkPushOutcome::NeedInput, content="true")
    offset = boundary
  }
  let result = decoder.finish().unwrap()
  inspect(result.bytes_read() == source.length().to_uint64(), content="true")
}

///| Trailing input is parser-dispatched and therefore belongs to the call
/// that supplies it.  Its exact first error remains ahead of later EOF logic.
test "PNG chunk decoder counts trailing bytes and replays their first error" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let decoder = PngChunkDecoder::new(
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=256UL, max_output_bytes=64UL, max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=256UL),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=256UL, allocations=8UL, allocation_size=128UL, width=4UL, height=4UL, pixels=16UL, depth=0UL, work=256UL)),
    @error.Diagnostics::new(),
  )
  let owner = png_chunk_source(source)
  inspect(decoder.push(owner.view()).outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let trailing = png_chunk_source(b"X")
  let failed = decoder.push(trailing.view())
  let error = match failed.outcome() {
    PngChunkPushOutcome::Failed(value) => value
    _ => fail("trailing byte must fail during push")
  }
  inspect(failed.consumed() == 1UL, content="true")
  inspect(error.context() == Some("png-trailing-data"), content="true")
  let replay = decoder.push(trailing.view())
  inspect(replay.consumed() == 0UL, content="true")
  inspect(png_chunk_error_matches(decoder.finish().unwrap_err(), error), content="true")
}
