///|
struct ShortReader {
  source : @bytes.ByteView
  mut cursor : UInt64
}

///|
impl @io.Reader for ShortReader with fn read(self, destination) {
  if self.cursor == self.source.length() {
    return @io.ReadOutcome::EndOfStream
  }
  match destination.set(0UL, self.source.get(self.cursor).unwrap()) {
    Ok(_) => {
      self.cursor = self.cursor + 1UL
      @io.ReadOutcome::Progress(1UL)
    }
    Err(error) => @io.ReadOutcome::Failed(error, 0UL)
  }
}

///|
struct ShortWriter {
  destination : @bytes.OwnedBytes
  mut cursor : UInt64
}

///|
fn ShortWriter::new(capacity : UInt64, budget : @budget.Budget) -> ShortWriter {
  {
    destination: @bytes.OwnedBytes::new(capacity, budget).unwrap(),
    cursor: 0UL,
  }
}

///|
fn ShortWriter::position(self : ShortWriter) -> UInt64 {
  self.cursor
}

///|
fn ShortWriter::view(self : ShortWriter) -> @bytes.ByteView {
  self.destination.view()
}

///|
impl @io.Writer for ShortWriter with fn write(self, source) {
  if self.cursor == self.destination.length() {
    return @io.WriteOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        operation="short-write",
        requested=source.length(),
        completed=0UL,
        limit=0UL,
      ),
      0UL,
    )
  }
  let value = source.get(0UL).unwrap()
  match
    self.destination.with_mut(self.cursor, 1UL, fn(destination) {
      destination.set(0UL, value)
    }) {
    Ok(_) => {
      self.cursor = self.cursor + 1UL
      @io.WriteOutcome::Progress(1UL)
    }
    Err(error) => @io.WriteOutcome::Failed(error, 0UL)
  }
}

///|
fn native_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  pixels : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=2UL,
      height=1UL,
      pixels~,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn native_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=64UL,
    max_output_bytes=64UL,
    max_width=2UL,
    max_height=1UL,
    max_pixels=2UL,
    max_work=64UL,
  )
}

///|
fn native_digest(view : @bytes.ByteView, length : UInt64) -> UInt64 {
  let mut value = 0UL
  for index = 0UL; index < length; index = index + 1UL {
    value = (value * 257UL + view.get(index).unwrap().to_uint64()) %
      1000000007UL
  }
  value
}

///|
fn main {
  let source = @bytes.OwnedBytes::from_bytes(
    b"P6\n2 1\n255\n\x00\x7f\xff\x01\x02\x03",
    native_budget(17UL, 1UL, 17UL, 0UL, 0UL),
  ).unwrap()
  let reader = ShortReader::{ source: source.view(), cursor: 0UL }
  let writer = ShortWriter::new(17UL, native_budget(17UL, 1UL, 17UL, 0UL, 0UL))
  let diagnostics = @error.Diagnostics::new()
  let result = transcode(
    reader as &@io.Reader,
    writer as &@io.Writer,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    native_limits(),
    native_budget(12UL, 2UL, 6UL, 4UL, 40UL),
    diagnostics,
    TransformSelection::FlipHorizontal,
  ).unwrap()
  let valid = result.bytes_read() == 17UL &&
    result.bytes_written() == 17UL &&
    result.disposition_fields() == 5 &&
    writer.position() == 17UL &&
    native_digest(writer.view(), writer.position()) == 806175100UL &&
    diagnostics.length() == 0
  if valid {
    println(
      "example=native bytes_read=17 bytes_written=17 transform=flip_horizontal disposition=5 digest=806175100 short_progress=pass",
    )
  } else {
    println("example=native status=failed")
  }
}
