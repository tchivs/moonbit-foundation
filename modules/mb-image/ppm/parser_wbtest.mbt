///|
fn test_prefix(value : Bytes) -> @bytes.ByteView {
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=value.length().to_uint64(),
      allocations=1UL,
      allocation_size=value.length().to_uint64(),
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
  @bytes.OwnedBytes::from_bytes(value, budget).unwrap().view()
}

///|
test "strict P6 prefix probe is pure and closed" {
  inspect(
    _probe_ppm_prefix(test_prefix(b"")) == @codec.ProbeOutcome::NeedMore(2UL),
    content="true",
  )
  inspect(
    _probe_ppm_prefix(test_prefix(b"P")) == @codec.ProbeOutcome::NeedMore(2UL),
    content="true",
  )
  inspect(
    _probe_ppm_prefix(test_prefix(b"P6")) == @codec.ProbeOutcome::Match,
    content="true",
  )
  inspect(
    _probe_ppm_prefix(test_prefix(b"P5")) == @codec.ProbeOutcome::NoMatch,
    content="true",
  )
  inspect(
    _probe_ppm_prefix(test_prefix(b"XP")) == @codec.ProbeOutcome::NoMatch,
    content="true",
  )
}

///|
test "parser limits are explicit and reject every zero ceiling" {
  let limits = PpmParserLimits::new(
    max_header_bytes=32UL,
    max_token_bytes=8UL,
    max_comment_bytes=12UL,
    max_comments=2UL,
  ).unwrap()
  inspect(limits.max_header_bytes(), content="32")
  inspect(limits.max_token_bytes(), content="8")
  inspect(limits.max_comment_bytes(), content="12")
  inspect(limits.max_comments(), content="2")
  for item in [
    (0UL, 8UL, 12UL, 2UL, "header-bytes"),
    (32UL, 0UL, 12UL, 2UL, "token-bytes"),
    (32UL, 8UL, 0UL, 2UL, "comment-bytes"),
    (32UL, 8UL, 12UL, 0UL, "comments"),
  ] {
    let (header, token, comment, comments, context) = item
    let error = PpmParserLimits::new(
      max_header_bytes=header,
      max_token_bytes=token,
      max_comment_bytes=comment,
      max_comments=comments,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.operation() == Some("ppm-limits"), content="true")
    inspect(error.context() == Some(context), content="true")
  }
}

///|
test "decoder and encoder values have no behavior stubs" {
  let limits = PpmParserLimits::new(
    max_header_bytes=32UL,
    max_token_bytes=8UL,
    max_comment_bytes=12UL,
    max_comments=2UL,
  ).unwrap()
  let _decoder = PpmDecoder::new(limits)
  let _encoder = PpmEncoder::new()
}
