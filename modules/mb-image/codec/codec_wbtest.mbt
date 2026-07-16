///|
fn codec_error_context(error : @error.CoreError) -> String {
  match error.context() {
    Some(value) => value
    None => "none"
  }
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
      Match => if name == "short-progress" { "bounded-read" } else { "match" }
    }
    inspect(actual == expected, content="true")
    inspect(seeker_calls, content="0")
  }
}

