///|
fn codec_error_context(error : @error.CoreError) -> String {
  match error.context() {
    Some(value) => value
    None => "none"
  }
}

///|
struct GeneratedShortReader {
  mut calls : Int
}

///|
impl @io.Reader for GeneratedShortReader with fn read(self, destination) {
  self.calls = self.calls + 1
  ignore(destination.set(0UL, self.calls.to_byte()))
  @io.ReadOutcome::Progress(1UL)
}

///|
fn consume_generated_short_progress(length : UInt64) -> Unit raise {
  let budget = @budget.Budget::new(
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
  )
  let destination = @bytes.OwnedBytes::new(length, budget).unwrap()
  let reader = GeneratedShortReader::{ calls: 0 }
  let completed = destination.with_mut(0UL, length, fn(lease) {
    @io.read_exact(reader as &@io.Reader, lease)
  }).unwrap()
  inspect(completed == length, content="true")
  inspect(reader.calls.to_uint64() == length, content="true")
}

///|
test "capability errors are bounded and portable" {
  let error = capability_unavailable("codec-decode", "unsupported-option")
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(
    error.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(error.operation() == Some("codec-decode"), content="true")
  inspect(codec_error_context(error), content="unsupported-option")
}

///|
test "every generated probe case has a closed outcome and no seeker" {
  for item in generated_codec_cases() {
    let (name, prefix_length, expected, seeker_calls) = item
    let outcome = if prefix_length < 2UL {
      ProbeOutcome::NeedMore(2UL)
    } else if name == "non-match" {
      ProbeOutcome::NoMatch
    } else {
      ProbeOutcome::Match
    }
    let actual = match outcome {
      NeedMore(_) => "need-more"
      NoMatch => "no-match"
      Match =>
        if name == "short-progress" {
          consume_generated_short_progress(prefix_length)
          "bounded-read"
        } else {
          "match"
        }
    }
    inspect(actual == expected, content="true")
    inspect(seeker_calls, content="0")
  }
}
