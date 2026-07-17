///|
/// Independent ceilings for the forward-only strict P6 header parser.
/// Image, stream, and work ceilings remain owned by `CodecLimits`.
pub struct PpmParserLimits {
  priv max_header_bytes_value : UInt64
  priv max_token_bytes_value : UInt64
  priv max_comment_bytes_value : UInt64
  priv max_comments_value : UInt64
}

///|
fn parser_limit_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="ppm-limits",
    requested=0UL,
    limit=0UL,
    context~,
  )
}

///|
pub fn PpmParserLimits::new(
  max_header_bytes~ : UInt64,
  max_token_bytes~ : UInt64,
  max_comment_bytes~ : UInt64,
  max_comments~ : UInt64,
) -> Result[PpmParserLimits, @error.CoreError] {
  if max_header_bytes == 0UL {
    return Err(parser_limit_error("header-bytes"))
  }
  if max_token_bytes == 0UL {
    return Err(parser_limit_error("token-bytes"))
  }
  if max_comment_bytes == 0UL {
    return Err(parser_limit_error("comment-bytes"))
  }
  if max_comments == 0UL {
    return Err(parser_limit_error("comments"))
  }
  Ok({
    max_header_bytes_value: max_header_bytes,
    max_token_bytes_value: max_token_bytes,
    max_comment_bytes_value: max_comment_bytes,
    max_comments_value: max_comments,
  })
}

///|
pub fn PpmParserLimits::max_header_bytes(self : PpmParserLimits) -> UInt64 {
  self.max_header_bytes_value
}

///|
pub fn PpmParserLimits::max_token_bytes(self : PpmParserLimits) -> UInt64 {
  self.max_token_bytes_value
}

///|
pub fn PpmParserLimits::max_comment_bytes(self : PpmParserLimits) -> UInt64 {
  self.max_comment_bytes_value
}

///|
pub fn PpmParserLimits::max_comments(self : PpmParserLimits) -> UInt64 {
  self.max_comments_value
}

///|
/// A strict P6 decoder value. Complete `ImageDecoder` behavior is added only
/// with the decode plan; retaining limits here makes parser policy explicit.
pub struct PpmDecoder {
  priv _parser_limits : PpmParserLimits
}

///|
pub fn PpmDecoder::new(parser_limits : PpmParserLimits) -> PpmDecoder {
  { _parser_limits: parser_limits }
}

///|
/// A canonical strict P6 encoder value. Its complete `ImageEncoder` behavior
/// belongs to the encode plan.
pub struct PpmEncoder {}

///|
pub fn PpmEncoder::new() -> PpmEncoder {
  PpmEncoder::{  }
}

///|
/// Inspect only caller-owned prefix bytes. The helper neither reads nor seeks.
fn _probe_ppm_prefix(prefix : @bytes.ByteView) -> @codec.ProbeOutcome {
  if prefix.length() < 2UL {
    @codec.ProbeOutcome::NeedMore(2UL)
  } else if prefix.get(0UL).unwrap() == b'P' &&
    prefix.get(1UL).unwrap() == b'6' {
    @codec.ProbeOutcome::Match
  } else {
    @codec.ProbeOutcome::NoMatch
  }
}
