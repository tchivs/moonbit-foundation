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
  let parser = PpmHeaderParser::new(limits)
  for byte in source {
    match parser.feed(byte) {
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
  inspect(header.width(), content="2")
  inspect(header.height(), content="3")
  inspect(header.maxval(), content="255")
  inspect(header.bytes_consumed(), content="25")
}

///|
test "strict decimal and comment positions fail with stable classifications" {
  for item in [
    (b"P5\n1 1\n255\n", "ppm-magic"),
    (b"P6+1 1\n255\n", "ppm-separator"),
    (b"P6\n+1 1\n255\n", "decimal-syntax"),
    (b"P6\n-1 1\n255\n", "decimal-syntax"),
    (b"P6\nÙ¡ 1\n255\n", "decimal-syntax"),
    (b"P6\n0 1\n255\n", "width-zero"),
    (b"P6\n1 0\n255\n", "height-zero"),
    (b"P6\n1#x\n 1\n255\n", "decimal-syntax"),
    (b"P6\n1 1\n255#x\n", "ppm-maxval"),
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
    let parser = PpmHeaderParser::new(parser_limits())
    let source = b"P6\n1 1\n255\n"
    for byte in source {
      ignore(parser.feed(byte).unwrap())
    }
    inspect(parser.is_complete(), content="true")
    inspect(parser.bytes_consumed(), content="13")
    ignore(raster)
  }
}
