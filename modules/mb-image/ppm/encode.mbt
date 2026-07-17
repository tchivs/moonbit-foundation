///|
fn encode_error(
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
    operation="ppm-encode",
    requested?,
    completed?,
    limit?,
    context~,
  )
}

///|
fn encode_capability(context : String) -> @error.CoreError {
  @codec.capability_unavailable("ppm-encode", context)
}

///|
fn encode_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(
      encode_error(
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
/// Validate the entire codec capability before producing any output.
fn validate_encode_source(
  source : @storage.ImageView,
) -> Result[Unit, @error.CoreError] {
  if source.is_empty() {
    return Err(encode_capability("empty-image"))
  }
  let format = source.format()
  let metadata = source.metadata()
  if format.component() != @model.ComponentType::U8 {
    return Err(encode_capability("component-u8-required"))
  }
  if format.channels() != @model.ChannelOrder::Rgb {
    return Err(encode_capability("rgb-required"))
  }
  if format.layout() != @model.PlaneLayout::Packed {
    return Err(encode_capability("packed-required"))
  }
  if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    metadata.transfer() != @color.TransferIdentity::EncodedSrgb {
    return Err(encode_capability("encoded-srgb-required"))
  }
  if metadata.alpha() is Some(_) {
    return Err(encode_capability("alpha-unsupported"))
  }
  if !metadata.profile().is_builtin_srgb() {
    return Err(encode_capability("builtin-srgb-profile-required"))
  }
  if metadata.orientation() != @model.Orientation::TopLeft {
    return Err(encode_capability("top-left-required"))
  }
  if metadata.opaque_metadata().length() != 0 {
    return Err(encode_capability("opaque-metadata-unsupported"))
  }
  let expected_row = match @checked.checked_mul(source.width(), 3UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source.row_bytes() != expected_row || source.row_stride() < expected_row {
    return Err(encode_capability("rgb-row-layout-required"))
  }
  Ok(())
}

///|
fn remap_encode_write_error(
  error : @error.CoreError,
  requested : UInt64,
  completed_before : UInt64,
) -> @error.CoreError {
  let call_completed = match error.completed() {
    Some(value) => value
    None => 0UL
  }
  let completed = match @checked.checked_add(completed_before, call_completed) {
    Ok(value) => value
    Err(_) => completed_before
  }
  @error.CoreError::new(
    error.category(),
    error.code(),
    operation="ppm-encode",
    requested~,
    completed~,
    context?=error.context(),
  )
}

///|
fn write_encode_part(
  writer : &@io.Writer,
  bytes : Bytes,
  requested : UInt64,
  completed : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let owner = match
    @bytes.OwnedBytes::from_bytes(
      bytes,
      private_budget(bytes.length().to_uint64()),
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match @io.write_all(writer, owner.view()) {
    Err(error) => Err(remap_encode_write_error(error, requested, completed))
    Ok(count) => @checked.checked_add(completed, count)
  }
}

///|
fn append_ascii_decimal(destination : Array[Byte], value : UInt64) -> Unit {
  if value == 0UL {
    destination.push(b'0')
    return
  }
  let reversed : Array[Byte] = []
  let mut remaining = value
  while remaining > 0UL {
    reversed.push((48UL + remaining % 10UL).to_byte())
    remaining = remaining / 10UL
  }
  for index = reversed.length() - 1; index >= 0; index = index - 1 {
    destination.push(reversed[index])
  }
}

///|
fn canonical_header(width : UInt64, height : UInt64) -> Bytes {
  let bytes : Array[Byte] = [b'P', b'6', b'\n']
  append_ascii_decimal(bytes, width)
  bytes.push(b' ')
  append_ascii_decimal(bytes, height)
  bytes.push(b'\n')
  bytes.push(b'2')
  bytes.push(b'5')
  bytes.push(b'5')
  bytes.push(b'\n')
  Bytes::from_array(bytes)
}

///|
pub impl @codec.ImageEncoder for PpmEncoder with fn encode(
  _self,
  source,
  writer,
  _options,
  limits,
  budget,
  _diagnostics,
) {
  match validate_encode_source(source) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let payload = match @checked.checked_mul(pixels, 3UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let header = canonical_header(source.width(), source.height())
  let total = match @checked.checked_add(header.length().to_uint64(), payload) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for
    item in [
      ("output-bytes", total, limits.max_output_bytes()),
      ("width", source.width(), limits.max_width()),
      ("height", source.height(), limits.max_height()),
      ("pixels", pixels, limits.max_pixels()),
      ("work", total, limits.max_work()),
    ] {
    let (context, requested, limit) = item
    match encode_limit(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match
    budget.charge(
      @budget.ResourceCharge::new(
        bytes=0UL,
        allocations=0UL,
        allocation_size=0UL,
        width=source.width(),
        height=source.height(),
        pixels=0UL,
        work=total,
      ),
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut completed = match write_encode_part(writer, header, total, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for y = 0UL; y < source.height(); y = y + 1UL {
    let row : Array[Byte] = []
    for x = 0UL; x < source.width(); x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        match source.get_byte(x, y, channel) {
          Err(error) => return Err(error)
          Ok(value) => row.push(value)
        }
      }
    }
    completed = match
      write_encode_part(writer, Bytes::from_array(row), total, completed) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let disposition = match empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@codec.EncodeResult::new(disposition, completed))
}
