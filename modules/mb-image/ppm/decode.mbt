///|
priv struct PpmBuiltinAllocator {}

///|
impl @bytes.Allocator for PpmBuiltinAllocator with fn approve(_self, _length) {
  Ok(())
}

///|
fn private_budget(length : UInt64) -> @budget.Budget {
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
  )
}

///|
fn decode_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  requested? : UInt64,
  completed? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    category,
    code,
    operation="ppm-decode",
    requested?,
    completed?,
    limit?,
    context~,
  )
}

///|
fn decode_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(
      decode_error(
        @error.ErrorCategory::Resource,
        @error.ErrorCode::BudgetExceeded,
        context,
        requested~,
        limit~,
      ),
    )
  } else {
    Ok(())
  }
}

///|
/// Read exactly one byte without seeking or retaining input.
fn read_one(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
) -> Result[Byte, @error.CoreError] {
  match
    scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Err(error) => Err(error)
    Ok(_) => scratch.view().get(0UL)
  }
}

///|
fn remap_payload_error(
  error : @error.CoreError,
  requested : UInt64,
  completed : UInt64,
) -> @error.CoreError {
  let call_completed = match error.completed() {
    Some(value) => value
    None => 0UL
  }
  let total = match @checked.checked_add(completed, call_completed) {
    Ok(value) => value
    Err(_) => completed
  }
  @error.CoreError::new(
    error.category(),
    error.code(),
    operation="ppm-payload",
    requested~,
    completed=total,
    context?=error.context(),
  )
}

///|
fn empty_metadata() -> Result[@model.ImageMetadata, @error.CoreError] {
  let limits = @metadata.MetadataLimits::new(
    max_entries=0UL,
    max_token_bytes=1UL,
    max_value_bytes=0UL,
    max_total_bytes=0UL,
    max_disposition_fields=0UL,
  )
  match
    @metadata.OpaqueMetadata::from_entries([], limits, private_budget(0UL)) {
    Err(error) => Err(error)
    Ok(metadata_value) =>
      Ok(
        @model.ImageMetadata::new(
          @color.ColorSpaceIdentity::Srgb,
          @color.TransferIdentity::EncodedSrgb,
          None,
          @profile.ProfileIdentity::builtin_srgb(),
          @model.Orientation::TopLeft,
          metadata_value,
        ),
      )
  }
}

///|
fn empty_disposition() -> Result[
  @metadata.MetadataDisposition,
  @error.CoreError,
] {
  @metadata.MetadataDisposition::new(
    [],
    [],
    [],
    false,
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=1UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=0UL,
    ),
  )
}

///|
fn tight_rgb_descriptor(
  width : UInt64,
  height : UInt64,
  payload : UInt64,
) -> Result[@model.ImageDescriptor, @error.CoreError] {
  let row_bytes = match @checked.checked_mul(width, 3UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let plane = match
    @model.PlaneDescriptor::new(
      0UL, payload, row_bytes, row_bytes, 1UL, 1UL, width, height,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let metadata = match empty_metadata() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @model.ImageDescriptor::new(
    width,
    height,
    @model.ImageFormat::rgb8(),
    [plane],
    payload,
    metadata,
  )
}

///|
fn parse_stream_header(
  decoder : PpmDecoder,
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  limits : @codec.CodecLimits,
) -> Result[PpmHeader, @error.CoreError] {
  let parser = PpmHeaderParser::_new(decoder._parser_limits)
  while !parser._is_complete() {
    let next_count = match @checked.checked_add(parser._bytes_consumed(), 1UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match decode_limit("input-bytes", next_count, limits.max_input_bytes()) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let byte = match read_one(reader, scratch) {
      Err(error) => {
        if error.code() == @error.ErrorCode::UnexpectedEndOfStream {
          return Err(
            ppm_header_error(
              @error.ErrorCode::UnexpectedEndOfStream,
              "header-eof",
            ),
          )
        }
        return Err(error)
      }
      Ok(value) => value
    }
    match parser._feed(byte) {
      Err(error) => return Err(error)
      Ok(HeaderProgress::Continue) => ()
      Ok(HeaderProgress::Complete(header)) => return Ok(header)
    }
  }
  Err(ppm_header_error(@error.ErrorCode::InvalidEncoding, "header-complete"))
}

///|
pub impl @codec.ImageDecoder for PpmDecoder with fn probe(
  _self,
  prefix,
  limits,
  _diagnostics,
) {
  if prefix.length() > limits.max_probe_bytes() {
    return Err(
      decode_error(
        @error.ErrorCategory::Resource,
        @error.ErrorCode::BudgetExceeded,
        "probe-bytes",
        requested=prefix.length(),
        limit=limits.max_probe_bytes(),
      ),
    )
  }
  Ok(_probe_ppm_prefix(prefix))
}

///|
pub impl @codec.ImageDecoder for PpmDecoder with fn decode(
  self,
  reader,
  _options,
  limits,
  budget,
  _diagnostics,
) {
  let scratch = match @bytes.OwnedBytes::new(1UL, private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let header = match parse_stream_header(self, reader, scratch, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pixels = match @checked.checked_mul(header._width(), header._height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let payload = match @checked.checked_mul(pixels, 3UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let input = match @checked.checked_add(header._bytes_consumed(), payload) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = input
  for
    item in [
      ("input-bytes", input, limits.max_input_bytes()),
      ("output-bytes", payload, limits.max_output_bytes()),
      ("width", header._width(), limits.max_width()),
      ("height", header._height(), limits.max_height()),
      ("pixels", pixels, limits.max_pixels()),
      ("work", work, limits.max_work()),
    ] {
    let (context, requested, limit) = item
    match decode_limit(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let descriptor = match
    tight_rgb_descriptor(header._width(), header._height(), payload) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let image = match
    @storage.OwnedImage::new_operation(
      descriptor,
      budget,
      PpmBuiltinAllocator::{  } as &@bytes.Allocator,
      work,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filled = image.with_mut_view(fn(view) {
    let mut completed = 0UL
    while completed < payload {
      let byte = match read_one(reader, scratch) {
        Err(error) => return Err(remap_payload_error(error, payload, completed))
        Ok(value) => value
      }
      let pixel = completed / 3UL
      let x = pixel % header._width()
      let y = pixel / header._width()
      let channel = completed % 3UL
      match view.set_byte(x, y, channel, byte) {
        Err(error) => return Err(error)
        Ok(_) => completed = completed + 1UL
      }
    }
    Ok(completed)
  })
  match filled {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match read_one(reader, scratch) {
    Ok(_) =>
      return Err(
        decode_error(
          @error.ErrorCategory::Data,
          @error.ErrorCode::InvalidEncoding,
          "ppm-trailing-data",
          requested=1UL,
          completed=0UL,
        ),
      )
    Err(error) =>
      if error.code() != @error.ErrorCode::UnexpectedEndOfStream {
        return Err(error)
      }
  }
  let disposition = match empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@codec.DecodeResult::new(image, disposition, input))
}
