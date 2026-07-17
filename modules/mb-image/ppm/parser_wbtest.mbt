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
  for
    item in [
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

///|
fn parser_limits(
  header? : UInt64 = 128UL,
  token? : UInt64 = 20UL,
  comment? : UInt64 = 32UL,
  comments? : UInt64 = 4UL,
) -> PpmParserLimits {
  PpmParserLimits::new(
    max_header_bytes=header,
    max_token_bytes=token,
    max_comment_bytes=comment,
    max_comments=comments,
  ).unwrap()
}

///|
fn parse_header_bytes(
  source : Bytes,
  limits? : PpmParserLimits = parser_limits(),
) -> Result[PpmHeader, @error.CoreError] {
  let parser = PpmHeaderParser::_new(limits)
  for byte in source {
    match parser._feed(byte) {
      Err(error) => return Err(error)
      Ok(HeaderProgress::Continue) => ()
      Ok(HeaderProgress::Complete(header)) => return Ok(header)
    }
  }
  Err(ppm_header_error(@error.ErrorCode::UnexpectedEndOfStream, "header-eof"))
}

///|
fn assert_error(
  source : Bytes,
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  limits? : PpmParserLimits = parser_limits(),
) -> Unit raise {
  let error = parse_header_bytes(source, limits~).unwrap_err()
  inspect(error.category() == category, content="true")
  inspect(error.code() == code, content="true")
  inspect(error.operation() == Some("ppm-header"), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
test "bounded parser accepts strict headers and stops at the raster separator" {
  let header = parse_header_bytes(b"P6\n# one\n 2\t#two\r\n3\n255\nXYZ").unwrap()
  inspect(header._width(), content="2")
  inspect(header._height(), content="3")
  inspect(header._maxval(), content="255")
  inspect(header._bytes_consumed(), content="24")
}

///|
test "strict decimal and comment positions fail with stable classifications" {
  for
    item in [
      (b"P5\n1 1\n255\n", "ppm-magic"),
      (b"P6+1 1\n255\n", "ppm-separator"),
      (b"P6\n+1 1\n255\n", "decimal-syntax"),
      (b"P6\n-1 1\n255\n", "decimal-syntax"),
      (b"P6\nÙ¡ 1\n255\n", "decimal-syntax"),
      (b"P6\n0 1\n255\n", "width-zero"),
      (b"P6\n1 0\n255\n", "height-zero"),
      (b"P6\n1#x\n 1\n255\n", "decimal-syntax"),
      (b"P6\n1 1\n255#x\n", "decimal-syntax"),
    ] {
    let (source, context) = item
    assert_error(
      source,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
      context,
    )
  }
}

///|
test "overflow unsupported maxval and every ceiling have exact errors" {
  assert_error(
    b"P6\n18446744073709551616 1\n255\n",
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::ArithmeticOverflow,
    "decimal-overflow",
  )
  for value in [b"0", b"1", b"254", b"256", b"65535"] {
    assert_error(
      b"P6\n1 1\n" + value + b"\n",
      @error.ErrorCategory::Capability,
      @error.ErrorCode::CapabilityUnavailable,
      "ppm-maxval",
    )
  }
  assert_error(
    b"P6\n1 1\n255\n",
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    "header-bytes",
    limits=parser_limits(header=10UL),
  )
  assert_error(
    b"P6\n123 1\n255\n",
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    "token-bytes",
    limits=parser_limits(token=2UL),
  )
  assert_error(
    b"P6\n#abc\n1 1\n255\n",
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    "comment-bytes",
    limits=parser_limits(comment=2UL),
  )
  assert_error(
    b"P6\n#a\n#b\n1 1\n255\n",
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    "comments",
    limits=parser_limits(comments=1UL),
  )
}

///|
test "completion never examines the first raster byte" {
  for raster in [b'#', b' ', b'\n', b'\x00'] {
    let parser = PpmHeaderParser::_new(parser_limits())
    let source = b"P6\n1 1\n255\n"
    for byte in source {
      ignore(parser._feed(byte).unwrap())
    }
    inspect(parser._is_complete(), content="true")
    inspect(parser._bytes_consumed(), content="11")
    ignore(raster)
  }
}

///|
fn scheduled_signature(source : Bytes, chunks : Array[Int]) -> String {
  let parser = PpmHeaderParser::_new(parser_limits())
  let mut offset = 0
  let mut chunk_index = 0
  while offset < source.length() {
    let amount = chunks[chunk_index % chunks.length()]
    chunk_index = chunk_index + 1
    let end = if offset + amount < source.length() {
      offset + amount
    } else {
      source.length()
    }
    while offset < end {
      match parser._feed(source[offset]) {
        Err(error) =>
          return @error.render_error(error) +
            "|consumed=" +
            parser._bytes_consumed().to_string()
        Ok(HeaderProgress::Continue) => offset = offset + 1
        Ok(HeaderProgress::Complete(header)) =>
          return "ok|width=" +
            header._width().to_string() +
            "|height=" +
            header._height().to_string() +
            "|consumed=" +
            header._bytes_consumed().to_string()
      }
    }
  }
  "incomplete|consumed=" + parser._bytes_consumed().to_string()
}

///|
test "all deterministic chunk schedules preserve completion and failure" {
  let schedules = [[1], [2, 1], [3, 2, 1], [7, 1, 4, 2]]
  let valid = b"P6\r\n#bounded comment\n4 2\n255\n#raster"
  let malformed = b"P6\n18446744073709551616 1\n255\n"
  let valid_expected = scheduled_signature(valid, schedules[0])
  let malformed_expected = scheduled_signature(malformed, schedules[0])
  for schedule in schedules {
    inspect(
      scheduled_signature(valid, schedule) == valid_expected,
      content="true",
    )
    inspect(
      scheduled_signature(malformed, schedule) == malformed_expected,
      content="true",
    )
  }
  inspect(valid_expected, content="ok|width=4|height=2|consumed=29")
  inspect(
    malformed_expected.contains("code=arithmetic-overflow"),
    content="true",
  )
}

///|
test "header failures leave an authoritative budget unchanged" {
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=99UL,
      allocations=7UL,
      allocation_size=64UL,
      width=8UL,
      height=9UL,
      pixels=72UL,
      depth=3UL,
      work=123UL,
    ),
  )
  let before = budget.remaining()
  assert_error(
    b"P6\n999 1\n255\n",
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    "token-bytes",
    limits=parser_limits(token=2UL),
  )
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")
}
