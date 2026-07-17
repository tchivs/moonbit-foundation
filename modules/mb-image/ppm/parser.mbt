///|
priv enum HeaderState {
  MagicP
  Magic6
  MagicSeparator
  BeforeWidth
  Width
  BeforeHeight
  Height
  BeforeMaxval
  Maxval
  Comment(CommentResume)
  Complete
}

///|
priv enum CommentResume {
  ResumeWidth
  ResumeHeight
  ResumeMaxval
}

///|
priv struct PpmHeader {
  width_value : UInt64
  height_value : UInt64
  maxval_value : UInt64
  bytes_consumed_value : UInt64
}

///|
fn PpmHeader::_width(self : PpmHeader) -> UInt64 {
  self.width_value
}

///|
fn PpmHeader::_height(self : PpmHeader) -> UInt64 {
  self.height_value
}

///|
fn PpmHeader::_maxval(self : PpmHeader) -> UInt64 {
  self.maxval_value
}

///|
fn PpmHeader::_bytes_consumed(self : PpmHeader) -> UInt64 {
  self.bytes_consumed_value
}

///|
priv enum HeaderProgress {
  Continue
  Complete(PpmHeader)
}

///|
fn _header_progress_is_complete(progress : HeaderProgress) -> Bool {
  match progress {
    Continue => false
    Complete(header) => header._bytes_consumed() >= 0UL
  }
}

///|
priv struct PpmHeaderParser {
  limits : PpmParserLimits
  mut state : HeaderState
  mut total_bytes : UInt64
  mut token_bytes : UInt64
  mut comment_bytes : UInt64
  mut comment_count : UInt64
  mut value : UInt64
  mut width_value : UInt64
  mut height_value : UInt64
}

///|
fn PpmHeaderParser::_new(limits : PpmParserLimits) -> PpmHeaderParser {
  {
    limits,
    state: MagicP,
    total_bytes: 0UL,
    token_bytes: 0UL,
    comment_bytes: 0UL,
    comment_count: 0UL,
    value: 0UL,
    width_value: 0UL,
    height_value: 0UL,
  }
}

///|
fn ppm_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    category,
    code,
    operation="ppm-header",
    requested?,
    limit?,
    context~,
  )
}

///|
fn ppm_header_error(
  code : @error.ErrorCode,
  context : String,
) -> @error.CoreError {
  ppm_error(@error.ErrorCategory::Data, code, context)
}

///|
fn ppm_limit_error(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  ppm_error(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    context,
    requested~,
    limit~,
  )
}

///|
fn is_ppm_whitespace(byte : Byte) -> Bool {
  byte == b' ' ||
  byte == b'\t' ||
  byte == b'\n' ||
  byte == b'\x0b' ||
  byte == b'\x0c' ||
  byte == b'\r'
}

///|
fn is_ascii_digit(byte : Byte) -> Bool {
  byte >= b'0' && byte <= b'9'
}

///|
fn digit_value(byte : Byte) -> UInt64 {
  (byte.to_int() - b'0'.to_int()).to_uint64()
}

///|
fn PpmHeaderParser::charge_header_byte(
  self : PpmHeaderParser,
) -> Result[Unit, @error.CoreError] {
  let requested = match @checked.checked_add(self.total_bytes, 1UL) {
    Err(_) =>
      return Err(
        ppm_error(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::ArithmeticOverflow,
          "header-overflow",
        ),
      )
    Ok(value) => value
  }
  if requested > self.limits.max_header_bytes() {
    return Err(
      ppm_limit_error("header-bytes", requested, self.limits.max_header_bytes()),
    )
  }
  self.total_bytes = requested
  Ok(())
}

///|
fn PpmHeaderParser::begin_comment(
  self : PpmHeaderParser,
  next_state : CommentResume,
) -> Result[HeaderProgress, @error.CoreError] {
  let requested = match @checked.checked_add(self.comment_count, 1UL) {
    Err(_) =>
      return Err(
        ppm_error(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::ArithmeticOverflow,
          "comment-overflow",
        ),
      )
    Ok(value) => value
  }
  if requested > self.limits.max_comments() {
    return Err(
      ppm_limit_error("comments", requested, self.limits.max_comments()),
    )
  }
  self.comment_count = requested
  self.comment_bytes = 0UL
  self.state = Comment(next_state)
  Ok(Continue)
}

///|
fn PpmHeaderParser::consume_comment_byte(
  self : PpmHeaderParser,
  byte : Byte,
  next_state : CommentResume,
) -> Result[HeaderProgress, @error.CoreError] {
  if byte == b'\n' || byte == b'\r' {
    self.comment_bytes = 0UL
    self.state = match next_state {
      ResumeWidth => BeforeWidth
      ResumeHeight => BeforeHeight
      ResumeMaxval => BeforeMaxval
    }
    return Ok(Continue)
  }
  let requested = match @checked.checked_add(self.comment_bytes, 1UL) {
    Err(_) =>
      return Err(
        ppm_error(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::ArithmeticOverflow,
          "comment-overflow",
        ),
      )
    Ok(value) => value
  }
  if requested > self.limits.max_comment_bytes() {
    return Err(
      ppm_limit_error(
        "comment-bytes",
        requested,
        self.limits.max_comment_bytes(),
      ),
    )
  }
  self.comment_bytes = requested
  Ok(Continue)
}

///|
fn PpmHeaderParser::begin_digit(
  self : PpmHeaderParser,
  byte : Byte,
  next : HeaderState,
) -> Result[HeaderProgress, @error.CoreError] {
  self.token_bytes = 0UL
  self.value = 0UL
  self.state = next
  self.consume_digit(byte)
}

///|
fn PpmHeaderParser::consume_digit(
  self : PpmHeaderParser,
  byte : Byte,
) -> Result[HeaderProgress, @error.CoreError] {
  let requested = match @checked.checked_add(self.token_bytes, 1UL) {
    Err(_) =>
      return Err(
        ppm_error(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::ArithmeticOverflow,
          "token-overflow",
        ),
      )
    Ok(value) => value
  }
  if requested > self.limits.max_token_bytes() {
    return Err(
      ppm_limit_error("token-bytes", requested, self.limits.max_token_bytes()),
    )
  }
  let multiplied = match @checked.checked_mul(self.value, 10UL) {
    Err(_) =>
      return Err(
        ppm_error(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::ArithmeticOverflow,
          "decimal-overflow",
        ),
      )
    Ok(value) => value
  }
  self.value = match @checked.checked_add(multiplied, digit_value(byte)) {
    Err(_) =>
      return Err(
        ppm_error(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::ArithmeticOverflow,
          "decimal-overflow",
        ),
      )
    Ok(value) => value
  }
  self.token_bytes = requested
  Ok(Continue)
}

///|
fn PpmHeaderParser::complete_width(
  self : PpmHeaderParser,
) -> Result[HeaderProgress, @error.CoreError] {
  if self.value == 0UL {
    return Err(
      ppm_header_error(@error.ErrorCode::InvalidEncoding, "width-zero"),
    )
  }
  self.width_value = self.value
  self.state = BeforeHeight
  Ok(Continue)
}

///|
fn PpmHeaderParser::complete_height(
  self : PpmHeaderParser,
) -> Result[HeaderProgress, @error.CoreError] {
  if self.value == 0UL {
    return Err(
      ppm_header_error(@error.ErrorCode::InvalidEncoding, "height-zero"),
    )
  }
  self.height_value = self.value
  self.state = BeforeMaxval
  Ok(Continue)
}

///|
fn PpmHeaderParser::complete_maxval(
  self : PpmHeaderParser,
) -> Result[HeaderProgress, @error.CoreError] {
  if self.value != 255UL {
    return Err(
      ppm_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        "ppm-maxval",
        requested=self.value,
        limit=255UL,
      ),
    )
  }
  self.state = Complete
  Ok(
    Complete({
      width_value: self.width_value,
      height_value: self.height_value,
      maxval_value: self.value,
      bytes_consumed_value: self.total_bytes,
    }),
  )
}

///|
fn PpmHeaderParser::before_token(
  self : PpmHeaderParser,
  byte : Byte,
  next_state : CommentResume,
  next : HeaderState,
) -> Result[HeaderProgress, @error.CoreError] {
  if is_ppm_whitespace(byte) {
    Ok(Continue)
  } else if byte == b'#' {
    self.begin_comment(next_state)
  } else if is_ascii_digit(byte) {
    self.begin_digit(byte, next)
  } else {
    Err(ppm_header_error(@error.ErrorCode::InvalidEncoding, "decimal-syntax"))
  }
}

///|
fn PpmHeaderParser::_feed(
  self : PpmHeaderParser,
  byte : Byte,
) -> Result[HeaderProgress, @error.CoreError] {
  if self.state is Complete {
    return Err(
      ppm_header_error(@error.ErrorCode::InvalidEncoding, "header-complete"),
    )
  }
  match self.charge_header_byte() {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match self.state {
    MagicP =>
      if byte == b'P' {
        self.state = Magic6
        Ok(Continue)
      } else {
        Err(ppm_header_error(@error.ErrorCode::InvalidEncoding, "ppm-magic"))
      }
    Magic6 =>
      if byte == b'6' {
        self.state = MagicSeparator
        Ok(Continue)
      } else {
        Err(ppm_header_error(@error.ErrorCode::InvalidEncoding, "ppm-magic"))
      }
    MagicSeparator =>
      if is_ppm_whitespace(byte) {
        self.state = BeforeWidth
        Ok(Continue)
      } else {
        Err(
          ppm_header_error(@error.ErrorCode::InvalidEncoding, "ppm-separator"),
        )
      }
    BeforeWidth => self.before_token(byte, ResumeWidth, Width)
    Width =>
      if is_ascii_digit(byte) {
        self.consume_digit(byte)
      } else if is_ppm_whitespace(byte) {
        self.complete_width()
      } else {
        Err(
          ppm_header_error(@error.ErrorCode::InvalidEncoding, "decimal-syntax"),
        )
      }
    BeforeHeight => self.before_token(byte, ResumeHeight, Height)
    Height =>
      if is_ascii_digit(byte) {
        self.consume_digit(byte)
      } else if is_ppm_whitespace(byte) {
        self.complete_height()
      } else {
        Err(
          ppm_header_error(@error.ErrorCode::InvalidEncoding, "decimal-syntax"),
        )
      }
    BeforeMaxval => self.before_token(byte, ResumeMaxval, Maxval)
    Maxval =>
      if is_ascii_digit(byte) {
        self.consume_digit(byte)
      } else if is_ppm_whitespace(byte) {
        self.complete_maxval()
      } else {
        Err(
          ppm_header_error(@error.ErrorCode::InvalidEncoding, "decimal-syntax"),
        )
      }
    Comment(next_state) => self.consume_comment_byte(byte, next_state)
    Complete => abort("complete parser state handled before charging")
  }
}

///|
fn PpmHeaderParser::_is_complete(self : PpmHeaderParser) -> Bool {
  self.state is Complete
}

///|
fn PpmHeaderParser::_bytes_consumed(self : PpmHeaderParser) -> UInt64 {
  self.total_bytes
}
