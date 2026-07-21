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
