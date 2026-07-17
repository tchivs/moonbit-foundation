///|
pub(all) enum TransformSelection {
  FlipHorizontal
} derive(Eq)

///|
pub struct TranscodeResult {
  bytes_read : UInt64
  bytes_written : UInt64
  disposition_fields : Int
}

///|
pub fn TranscodeResult::bytes_read(self : TranscodeResult) -> UInt64 {
  self.bytes_read
}

///|
pub fn TranscodeResult::bytes_written(self : TranscodeResult) -> UInt64 {
  self.bytes_written
}

///|
pub fn TranscodeResult::disposition_fields(self : TranscodeResult) -> Int {
  self.disposition_fields
}

///|
fn adapter_parser_limits() -> @ppm.PpmParserLimits {
  @ppm.PpmParserLimits::new(
    max_header_bytes=32UL,
    max_token_bytes=4UL,
    max_comment_bytes=8UL,
    max_comments=1UL,
  ).unwrap()
}

///|
pub fn transcode(
  reader : &@io.Reader,
  writer : &@io.Writer,
  decode_options : @codec.DecodeOptions,
  encode_options : @codec.EncodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
  transform : TransformSelection,
) -> Result[TranscodeResult, @error.CoreError] {
  let decoded = match
    @codec.ImageDecoder::decode(
      @ppm.PpmDecoder::new(adapter_parser_limits()),
      reader,
      decode_options,
      limits,
      budget,
      diagnostics,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let transformed = match transform {
    FlipHorizontal =>
      match @ops.flip_horizontal(decoded.image().view(), budget) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
  }
  let encoded = match
    @codec.ImageEncoder::encode(
      @ppm.PpmEncoder::new(),
      transformed.image().view(),
      writer,
      encode_options,
      limits,
      budget,
      diagnostics,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    bytes_read: decoded.bytes_read(),
    bytes_written: encoded.bytes_written(),
    disposition_fields: transformed.disposition().preserved_length(),
  })
}
