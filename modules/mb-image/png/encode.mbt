///|
fn _png_encode_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  requested? : UInt64,
  completed? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    category, code, operation="png-encode", requested?, completed?, limit?, context~,
  )
}

///|
fn _png_encode_capability(context : String) -> @error.CoreError {
  @codec.capability_unavailable("png-encode", context)
}

///|
fn _png_encode_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(_png_encode_error(
      @error.ErrorCategory::Resource, @error.ErrorCode::BudgetExceeded,
      context, requested~, limit~, 
    ))
  } else {
    Ok(())
  }
}

///|
fn _png_encode_u32(value : UInt64) -> Result[UInt64, @error.CoreError] {
  if value == 0UL || value > 4294967295UL {
    Err(_png_encode_capability("png-u32-dimensions"))
  } else {
    Ok(value)
  }
}

///|
/// Validate every semantic and physical property before pixels are read or the
/// caller budget is charged. The canonical layout contains no padding rows.
fn _png_encode_source(source : @storage.ImageView) -> Result[UInt64, @error.CoreError] {
  if source.is_empty() {
    return Err(_png_encode_capability("empty-image"))
  }
  match _png_encode_u32(source.width()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match _png_encode_u32(source.height()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = source.format()
  let metadata = source.metadata()
  if format.component() != @model.ComponentType::U8 {
    return Err(_png_encode_capability("component-u8-required"))
  }
  if format.layout() != @model.PlaneLayout::Packed {
    return Err(_png_encode_capability("packed-required"))
  }
  if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    metadata.transfer() != @color.TransferIdentity::EncodedSrgb ||
    !metadata.profile().is_builtin_srgb() {
    return Err(_png_encode_capability("builtin-encoded-srgb-required"))
  }
  if metadata.orientation() != @model.Orientation::TopLeft {
    return Err(_png_encode_capability("top-left-required"))
  }
  if metadata.opaque_metadata().length() != 0 {
    return Err(_png_encode_capability("opaque-metadata-unsupported"))
  }
  let channels = match format.channels() {
    @model.ChannelOrder::Rgb =>
      if metadata.alpha() is Some(_) {
        return Err(_png_encode_capability("rgb-alpha-unsupported"))
      } else {
        3UL
      }
    @model.ChannelOrder::Rgba =>
      match metadata.alpha() {
        Some(@color.AlphaMode::Straight) => 4UL
        _ => return Err(_png_encode_capability("straight-rgba-required"))
      }
    _ => return Err(_png_encode_capability("rgb-or-rgba-required"))
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source.row_bytes() != row_bytes || source.row_stride() != row_bytes {
    return Err(_png_encode_capability("tightly-packed-rows-required"))
  }
  Ok(channels)
}

///|
fn _png_encode_push_u32(destination : Array[Byte], value : UInt64) -> Unit {
  destination.push((value >> 24).to_byte())
  destination.push((value >> 16).to_byte())
  destination.push((value >> 8).to_byte())
  destination.push(value.to_byte())
}

///|
fn _png_encode_chunk(destination : Array[Byte], kind : Array[Byte], payload : Bytes) -> Unit {
  _png_encode_push_u32(destination, payload.length().to_uint64())
  for byte in kind { destination.push(byte) }
  for byte in payload { destination.push(byte) }
  let mut crc = _png_crc_for_type(kind)
  for byte in payload { crc = _png_crc_step(crc, byte) }
  _png_encode_push_u32(destination, crc ^ 4294967295UL)
}

///|
/// Construct all source scanlines before Writer access so a malformed view
/// cannot produce a partial PNG. Filter zero is the sole canonical choice.
fn _png_encode_scanlines(
  source : @storage.ImageView,
  channels : UInt64,
  row_bytes : UInt64,
) -> Result[Bytes, @error.CoreError] {
  let bytes : Array[Byte] = []
  for y = 0UL; y < source.height(); y = y + 1UL {
    bytes.push(b'\x00')
    for x = 0UL; x < source.width(); x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        match source.get_byte(x, y, channel) {
          Err(error) => return Err(error)
          Ok(value) => bytes.push(value)
        }
      }
    }
  }
  let expected = match @checked.checked_add(row_bytes, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => match @checked.checked_mul(value, source.height()) {
      Err(error) => return Err(error)
      Ok(total) => total
    }
  }
  if bytes.length().to_uint64() != expected {
    return Err(_png_encode_capability("scanline-layout-required"))
  }
  Ok(Bytes::from_array(bytes))
}

///|
fn _png_encode_zlib_stored(scanlines : Bytes) -> Result[Bytes, @error.CoreError] {
  let length = scanlines.length().to_uint64()
  if length == 0UL { return Err(_png_encode_capability("empty-scanlines")) }
  let blocks = match @checked.checked_add((length - 1UL) / 65535UL, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let bytes : Array[Byte] = [b'\x78', b'\x01']
  let mut offset = 0UL
  let mut adler = 1UL
  while offset < length {
    let remaining = length - offset
    let block_length = if remaining > 65535UL { 65535UL } else { remaining }
    bytes.push(if offset + block_length == length { b'\x01' } else { b'\x00' })
    bytes.push(block_length.to_byte())
    bytes.push((block_length >> 8).to_byte())
    let complement = 65535UL - block_length
    bytes.push(complement.to_byte())
    bytes.push((complement >> 8).to_byte())
    for index = 0UL; index < block_length; index = index + 1UL {
      let value = scanlines[(offset + index).to_int()]
      bytes.push(value)
      adler = _png_adler_step(adler, value)
    }
    offset = offset + block_length
  }
  _png_encode_push_u32(bytes, adler)
  let expected = match @checked.checked_add(length, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => match @checked.checked_add(value, blocks * 5UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  if bytes.length().to_uint64() != expected {
    return Err(_png_encode_capability("stored-deflate-length"))
  }
  Ok(Bytes::from_array(bytes))
}

///|
fn _png_encode_png(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  idat : Bytes,
) -> Bytes {
  let bytes : Array[Byte] = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let ihdr : Array[Byte] = []
  _png_encode_push_u32(ihdr, width)
  _png_encode_push_u32(ihdr, height)
  ihdr.push(b'\x08')
  ihdr.push(if channels == 3UL { b'\x02' } else { b'\x06' })
  ihdr.push(b'\x00')
  ihdr.push(b'\x00')
  ihdr.push(b'\x00')
  _png_encode_chunk(bytes, [b'I', b'H', b'D', b'R'], Bytes::from_array(ihdr))
  _png_encode_chunk(bytes, [b'I', b'D', b'A', b'T'], idat)
  _png_encode_chunk(bytes, [b'I', b'E', b'N', b'D'], b"")
  Bytes::from_array(bytes)
}

///|
fn _png_encode_write_error(
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
    error.category(), error.code(), operation="png-encode", requested~, completed~,
    context?=error.context(),
  )
}

///|
fn _png_encode_write(
  writer : &@io.Writer,
  bytes : Bytes,
  requested : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let owner = match @bytes.OwnedBytes::from_bytes(bytes, _png_private_budget(bytes.length().to_uint64())) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match @io.write_all(writer, owner.view()) {
    Err(error) => Err(_png_encode_write_error(error, requested, 0UL))
    Ok(count) => Ok(count)
  }
}

///|
pub impl @codec.ImageEncoder for PngEncoder with fn encode(
  _self,
  source,
  writer,
  _options,
  limits,
  budget,
  _diagnostics,
) {
  let channels = match _png_encode_source(source) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scanlines = match _png_encode_scanlines(source, channels, row_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let idat = match _png_encode_zlib_stored(scanlines) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let png = _png_encode_png(source.width(), source.height(), channels, idat)
  let total = png.length().to_uint64()
  for item in [
    ("width", source.width(), limits.max_width()),
    ("height", source.height(), limits.max_height()),
    ("pixels", pixels, limits.max_pixels()),
    ("output-bytes", total, limits.max_output_bytes()),
    ("work", total, limits.max_work()),
  ] {
    let (context, requested, limit) = item
    match _png_encode_limit(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match budget.charge(@budget.ResourceCharge::new(
    bytes=0UL, allocations=0UL, allocation_size=0UL, width=source.width(),
    height=source.height(), pixels=0UL, work=total,
  )) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let completed = match _png_encode_write(writer, png, total) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let disposition = match _png_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@codec.EncodeResult::new(disposition, completed))
}
