///|
fn decode_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=256UL,
    max_output_bytes=128UL,
    max_width=16UL,
    max_height=16UL,
    max_pixels=128UL,
    max_work=512UL,
  )
}

///|
fn decode_limits_with(
  input? : UInt64 = 256UL,
  output? : UInt64 = 128UL,
  width? : UInt64 = 16UL,
  height? : UInt64 = 16UL,
  pixels? : UInt64 = 128UL,
  work? : UInt64 = 512UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=input,
    max_output_bytes=output,
    max_width=width,
    max_height=height,
    max_pixels=pixels,
    max_work=work,
  )
}

///|
fn decode_parser_limits() -> PpmParserLimits {
  PpmParserLimits::new(
    max_header_bytes=128UL,
    max_token_bytes=20UL,
    max_comment_bytes=64UL,
    max_comments=8UL,
  ).unwrap()
}

///|
fn decode_source(value : Bytes) -> @bytes.OwnedBytes {
  let length = value.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    value,
    @budget.Budget::new(
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
    ),
  ).unwrap()
}

///|
fn decode_budget(
  bytes? : UInt64 = 128UL,
  allocations? : UInt64 = 1UL,
  allocation_size? : UInt64 = 128UL,
  width? : UInt64 = 16UL,
  height? : UInt64 = 16UL,
  pixels? : UInt64 = 128UL,
  work? : UInt64 = 512UL,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width~,
      height~,
      pixels~,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn decode_ppm(
  source : Bytes,
  budget? : @budget.Budget = decode_budget(),
  limits? : @codec.CodecLimits = decode_limits(),
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let owner = decode_source(source)
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    PpmDecoder::new(decode_parser_limits()),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    limits,
    budget,
    @error.Diagnostics::new(),
  )
}

///|
struct DecodeScriptReader {
  source : Bytes
  mut cursor : Int
  fail_at : Int
  no_progress_at : Int
}

///|
impl @io.Reader for DecodeScriptReader with fn read(self, destination) {
  if self.cursor == self.no_progress_at {
    return @io.ReadOutcome::Progress(0UL)
  }
  if self.cursor == self.fail_at {
    return @io.ReadOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::Host,
        @error.ErrorCode::HostOperationFailed,
        operation="scripted-read",
        context="scripted",
      ),
      0UL,
    )
  }
  if self.cursor == self.source.length() {
    return @io.ReadOutcome::EndOfStream
  }
  match destination.set(0UL, self.source[self.cursor]) {
    Err(error) => @io.ReadOutcome::Failed(error, 0UL)
    Ok(_) => {
      self.cursor = self.cursor + 1
      @io.ReadOutcome::Progress(1UL)
    }
  }
}

///|
fn decode_scripted(
  source : Bytes,
  fail_at? : Int = -1,
  no_progress_at? : Int = -1,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let reader = DecodeScriptReader::{ source, cursor: 0, fail_at, no_progress_at }
  @codec.ImageDecoder::decode(
    PpmDecoder::new(decode_parser_limits()),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    decode_limits(),
    decode_budget(),
    @error.Diagnostics::new(),
  )
}

///|
test "strict P6 decoder returns one tight sRGB image" {
  let result = decode_ppm(b"P6\n2 1\n255\n\x00\x7f\xff\x01\x02\x03").unwrap()
  let descriptor = result.descriptor()
  inspect(descriptor.width(), content="2")
  inspect(descriptor.height(), content="1")
  inspect(descriptor.storage_length(), content="6")
  inspect(
    descriptor.format().channels() == @model.ChannelOrder::Rgb,
    content="true",
  )
  inspect(
    descriptor.metadata().orientation() == @model.Orientation::TopLeft,
    content="true",
  )
  inspect(result.bytes_read(), content="17")
  let view = result.image().view()
  inspect(view.get_byte(0UL, 0UL, 0UL).unwrap().to_int(), content="0")
  inspect(view.get_byte(0UL, 0UL, 1UL).unwrap().to_int(), content="127")
  inspect(view.get_byte(0UL, 0UL, 2UL).unwrap().to_int(), content="255")
  inspect(view.get_byte(1UL, 0UL, 2UL).unwrap().to_int(), content="3")
}

///|
test "strict P6 decoder rejects truncation and every trailing byte" {
  let truncated = decode_ppm(b"P6\n1 1\n255\n\x01\x02").unwrap_err()
  inspect(
    truncated.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
  inspect(truncated.requested() == Some(3UL), content="true")
  inspect(truncated.completed() == Some(2UL), content="true")
  for suffix in [b"X", b"P6\n1 1\n255\n\x00\x00\x00"] {
    let trailing = decode_ppm(b"P6\n1 1\n255\n\x01\x02\x03" + suffix).unwrap_err()
    inspect(trailing.category() == @error.ErrorCategory::Data, content="true")
    inspect(
      trailing.code() == @error.ErrorCode::InvalidEncoding,
      content="true",
    )
    inspect(trailing.context() == Some("ppm-trailing-data"), content="true")
  }
}

///|
test "payload no-progress and backend failures preserve exact completed count" {
  let source = b"P6\n1 1\n255\n\x01\x02\x03"
  let no_progress = decode_scripted(source, no_progress_at=12).unwrap_err()
  inspect(no_progress.code() == @error.ErrorCode::NoProgress, content="true")
  inspect(no_progress.operation() == Some("ppm-payload"), content="true")
  inspect(no_progress.requested() == Some(3UL), content="true")
  inspect(no_progress.completed() == Some(1UL), content="true")
  let failed = decode_scripted(source, fail_at=13).unwrap_err()
  inspect(failed.category() == @error.ErrorCategory::Host, content="true")
  inspect(
    failed.code() == @error.ErrorCode::HostOperationFailed,
    content="true",
  )
  inspect(failed.operation() == Some("ppm-payload"), content="true")
  inspect(failed.requested() == Some(3UL), content="true")
  inspect(failed.completed() == Some(2UL), content="true")
}

///|
test "comment boundaries and every raster byte value remain payload" {
  for first in [b'#', b' ', b'\n', b'\x00'] {
    let source = match first {
      b'#' => b"P6\n# split\r\n1 1\n255\n#\x02\x03"
      b' ' => b"P6\n# split\r\n1 1\n255\n \x02\x03"
      b'\n' => b"P6\n# split\r\n1 1\n255\n\n\x02\x03"
      _ => b"P6\n# split\r\n1 1\n255\n\x00\x02\x03"
    }
    let result = decode_ppm(source).unwrap()
    inspect(
      result.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == first,
      content="true",
    )
  }
}

///|
test "all authoritative output ceilings reject atomically" {
  for
    budget in [
      decode_budget(bytes=5UL),
      decode_budget(allocations=0UL),
      decode_budget(allocation_size=5UL),
      decode_budget(width=1UL),
      decode_budget(height=0UL),
      decode_budget(pixels=1UL),
      decode_budget(work=16UL),
    ] {
    let before = budget.remaining()
    ignore(
      decode_ppm(b"P6\n2 1\n255\n\x00\x01\x02\x03\x04\x05", budget~).unwrap_err(),
    )
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.pixels() == before.pixels(), content="true")
    inspect(after.work() == before.work(), content="true")
  }
}

///|
test "every codec ceiling rejects before the authoritative output charge" {
  for
    item in [
      (decode_limits_with(input=16UL), "input-bytes"),
      (decode_limits_with(output=5UL), "output-bytes"),
      (decode_limits_with(width=1UL), "width"),
      (decode_limits_with(height=0UL), "height"),
      (decode_limits_with(pixels=1UL), "pixels"),
      (decode_limits_with(work=16UL), "work"),
    ] {
    let (limits, context) = item
    let budget = decode_budget()
    let before = budget.remaining()
    let error = decode_ppm(
      b"P6\n2 1\n255\n\x00\x01\x02\x03\x04\x05",
      budget~,
      limits~,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some(context), content="true")
    let after = budget.remaining()
    inspect(after.bytes() == before.bytes(), content="true")
    inspect(after.allocations() == before.allocations(), content="true")
    inspect(after.pixels() == before.pixels(), content="true")
    inspect(after.work() == before.work(), content="true")
  }
}
