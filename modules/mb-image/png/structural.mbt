///|
priv enum PngChunkState {
  BeforeIhdr
  BeforeIdat
  InIdat
  AfterIdat
  Finished
} derive(Eq)

///|
priv enum PngTransparency {
  Opaque
  Grayscale(Byte)
  Rgb(Byte, Byte, Byte)
  Indexed(Bytes)
}

///|
fn _png_private_budget(length : UInt64) -> @budget.Budget {
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
fn _png_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="png-decode",
    context~,
  )
}

///|
fn _png_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="png-decode",
    requested~,
    limit~,
    context~,
  )
}

///|
fn _png_read_one(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Byte, UInt64), @error.CoreError] {
  let next = match @checked.checked_add(consumed, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if next > limits.max_input_bytes() {
    return Err(_png_limit("input-bytes", next, limits.max_input_bytes()))
  }
  match
    scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Ok(_) => Ok((scratch.view().get(0UL).unwrap(), next))
    Err(error) => Err(error)
  }
}

///|
fn _png_read_u32(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(UInt64, UInt64), @error.CoreError] {
  let mut value = 0UL
  let mut cursor = consumed
  for index = 0; index < 4; index = index + 1 {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    value = (value << 8) | byte.to_int().to_uint64()
    cursor = next
  }
  Ok((value, cursor))
}

///|
fn _png_read_type(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Array[Byte], UInt64), @error.CoreError] {
  let bytes : Array[Byte] = []
  let mut cursor = consumed
  for index = 0; index < 4; index = index + 1 {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    bytes.push(byte)
    cursor = next
  }
  Ok((bytes, cursor))
}

///|
fn _png_is_ascii_letter(byte : Byte) -> Bool {
  let value = byte.to_int()
  (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

///|
fn _png_is_uppercase_ascii(byte : Byte) -> Bool {
  let value = byte.to_int()
  value >= 65 && value <= 90
}

///|
fn _png_validate_type_form(
  kind : Array[Byte],
) -> Result[Unit, @error.CoreError] {
  if kind.length() != 4 ||
    !_png_is_ascii_letter(kind[0]) ||
    !_png_is_ascii_letter(kind[1]) ||
    !_png_is_ascii_letter(kind[2]) ||
    !_png_is_ascii_letter(kind[3]) {
    return Err(_png_error("png-chunk-type"))
  }
  if !_png_is_uppercase_ascii(kind[2]) {
    return Err(_png_error("png-reserved-bit"))
  }
  Ok(())
}

///|
fn _png_type_is(
  kind : Array[Byte],
  a : Byte,
  b : Byte,
  c : Byte,
  d : Byte,
) -> Bool {
  kind[0] == a && kind[1] == b && kind[2] == c && kind[3] == d
}

///|
fn _png_is_known_semantic(kind : Array[Byte]) -> Bool {
  _png_type_is(kind, b'P', b'L', b'T', b'E') ||
  _png_type_is(kind, b't', b'R', b'N', b'S') ||
  _png_type_is(kind, b'c', b'H', b'R', b'M') ||
  _png_type_is(kind, b'g', b'A', b'M', b'A') ||
  _png_type_is(kind, b'i', b'C', b'C', b'P') ||
  _png_type_is(kind, b's', b'B', b'I', b'T') ||
  _png_type_is(kind, b's', b'R', b'G', b'B') ||
  _png_type_is(kind, b'c', b'I', b'C', b'P') ||
  _png_type_is(kind, b'm', b'D', b'C', b'v') ||
  _png_type_is(kind, b'c', b'L', b'L', b'i') ||
  _png_type_is(kind, b'a', b'c', b'T', b'L') ||
  _png_type_is(kind, b'f', b'c', b'T', b'L') ||
  _png_type_is(kind, b'f', b'd', b'A', b'T')
}

///|
fn _png_is_critical(kind : Array[Byte]) -> Bool {
  _png_is_uppercase_ascii(kind[0])
}

///|
fn _png_crc_step(crc : UInt64, byte : Byte) -> UInt64 {
  let mut value = crc ^ byte.to_int().to_uint64()
  let mut index = 0
  while index < 8 {
    value = if (value & 1UL) == 1UL {
      (value >> 1) ^ 3988292384UL
    } else {
      value >> 1
    }
    index = index + 1
  }
  value
}

///|
fn _png_crc32(value : Bytes) -> UInt64 {
  let mut crc = 4294967295UL
  let mut index = 0
  while index < value.length() {
    crc = _png_crc_step(crc, value[index])
    index = index + 1
  }
  crc ^ 4294967295UL
}

///|
fn _png_crc_for_type(kind : Array[Byte]) -> UInt64 {
  let mut crc = 4294967295UL
  for byte in kind {
    crc = _png_crc_step(crc, byte)
  }
  crc
}

///|
fn _png_limit_value(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(_png_limit(context, requested, limit))
  } else {
    Ok(())
  }
}

///|
fn _png_preflight_ihdr(
  ihdr : Array[Byte],
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let width = (ihdr[0].to_int().to_uint64() << 24) |
    (ihdr[1].to_int().to_uint64() << 16) |
    (ihdr[2].to_int().to_uint64() << 8) |
    ihdr[3].to_int().to_uint64()
  let height = (ihdr[4].to_int().to_uint64() << 24) |
    (ihdr[5].to_int().to_uint64() << 16) |
    (ihdr[6].to_int().to_uint64() << 8) |
    ihdr[7].to_int().to_uint64()
  if width == 0UL || height == 0UL {
    return Err(_png_error("png-dimensions"))
  }
  if ihdr[8] != 8 {
    return Err(_png_error("png-bit-depth"))
  }
  let source_channels = if ihdr[9] == 0 {
    1UL
  } else if ihdr[9] == 2 {
    3UL
  } else if ihdr[9] == 3 {
    1UL
  } else if ihdr[9] == 6 {
    4UL
  } else {
    return Err(_png_error("png-colour-type"))
  }
  if ihdr[10] != 0 || ihdr[11] != 0 || ihdr[12] != 0 {
    return Err(_png_error("png-ihdr-method"))
  }
  let pixels = match @checked.checked_mul(width, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // PNG grayscale has one filtered source sample but is exposed as RGB8.
  let output_channels = if ihdr[9] == 6 { 4UL } else { 3UL }
  let image_bytes = match @checked.checked_mul(pixels, output_channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row_bytes = match @checked.checked_mul(width, source_channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filtered_row = match @checked.checked_add(row_bytes, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filtered_output = match @checked.checked_mul(filtered_row, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(filtered_output, image_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for
    item in [
      ("width", width, limits.max_width()),
      ("height", height, limits.max_height()),
      ("pixels", pixels, limits.max_pixels()),
      ("image-bytes", image_bytes, limits.max_output_bytes()),
      ("output-bytes", filtered_output, limits.max_output_bytes()),
      ("work", work, limits.max_work()),
    ] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match
    budget.child(
      @budget.ResourceLimits::new(
        bytes=image_bytes,
        allocations=1UL,
        allocation_size=image_bytes,
        width~,
        height~,
        pixels~,
        depth=0UL,
        work~,
      ),
    ) {
    Ok(_) => Ok(())
    Err(error) => Err(error)
  }
}

///|
fn _png_indexed_decode_budget(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let image_bytes = match @checked.checked_mul(pixels, channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let index_rows = match @checked.checked_mul(width, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let bytes = match @checked.checked_add(image_bytes, index_rows) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  budget.child(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=3UL,
      allocation_size=image_bytes,
      width~,
      height~,
      pixels~,
      depth=0UL,
      work=limits.max_work(),
    ),
  )
}

///| The transparent profiles retain the encoded row width while reserving RGBA8.
fn _png_transparent_decode_budget(
  width : UInt64,
  height : UInt64,
  source_channels : UInt64,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[@budget.Budget, @error.CoreError] {
  let pixels = match @checked.checked_mul(width, height) { Err(error) => return Err(error); Ok(value) => value }
  let image_bytes = match @checked.checked_mul(pixels, 4UL) { Err(error) => return Err(error); Ok(value) => value }
  let row_bytes = match @checked.checked_mul(width, source_channels) { Err(error) => return Err(error); Ok(value) => value }
  let filtered = match @checked.checked_mul(row_bytes + 1UL, height) { Err(error) => return Err(error); Ok(value) => value }
  let work = match @checked.checked_add(image_bytes, filtered) { Err(error) => return Err(error); Ok(value) => value }
  for item in [("image-bytes", image_bytes, limits.max_output_bytes()), ("output-bytes", filtered, limits.max_output_bytes()), ("work", work, limits.max_work())] {
    let (context, requested, limit) = item
    match _png_limit_value(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  budget.child(@budget.ResourceLimits::new(
    bytes=image_bytes, allocations=1UL, allocation_size=image_bytes,
    width~, height~, pixels~, depth=0UL, work=limits.max_work(),
  ))
}

///|
fn _png_read_payload_and_crc(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  length : UInt64,
  kind : Array[Byte],
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Array[Byte], UInt64), @error.CoreError] {
  let data : Array[Byte] = []
  let capture_payload = _png_type_is(kind, b'I', b'H', b'D', b'R') ||
    _png_type_is(kind, b'P', b'L', b'T', b'E') ||
    _png_type_is(kind, b't', b'R', b'N', b'S')
  let mut crc = _png_crc_for_type(kind)
  let mut cursor = consumed
  let mut index = 0UL
  while index < length {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if capture_payload {
      data.push(byte)
    }
    crc = _png_crc_step(crc, byte)
    cursor = next
    index = index + 1UL
  }
  let (stored, next) = match _png_read_u32(reader, scratch, cursor, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if (crc ^ 4294967295UL) != stored {
    return Err(_png_error("png-crc"))
  }
  Ok((data, next))
}

///|
fn _png_require_eof(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[Unit, @error.CoreError] {
  match scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Err(error) =>
      if error.code() == @error.ErrorCode::UnexpectedEndOfStream {
        Ok(())
      } else {
        Err(error)
      }
    Ok(_) => {
      let next = match @checked.checked_add(consumed, 1UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if next > limits.max_input_bytes() {
        Err(_png_limit("input-bytes", next, limits.max_input_bytes()))
      } else {
        Err(_png_error("png-trailing-data"))
      }
    }
  }
}

///|
fn _png_validate_transport(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    let (actual, next) = match
      _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if actual != expected {
      return Err(_png_error("png-signature"))
    }
    consumed = next
  }
  let mut state = PngChunkState::BeforeIhdr
  while true {
    let (length, after_length) = match
      _png_read_u32(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if length > 2147483647UL {
      return Err(_png_error("png-chunk-length"))
    }
    let (kind, after_type) = match
      _png_read_type(reader, scratch, after_length, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match _png_validate_type_form(kind) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let (payload, next) = match
      _png_read_payload_and_crc(
        reader, scratch, length, kind, after_type, limits,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    consumed = next
    let is_ihdr = _png_type_is(kind, b'I', b'H', b'D', b'R')
    let is_idat = _png_type_is(kind, b'I', b'D', b'A', b'T')
    let is_iend = _png_type_is(kind, b'I', b'E', b'N', b'D')
    if is_ihdr {
      if state != PngChunkState::BeforeIhdr {
        return Err(_png_error("png-ihdr-order"))
      }
      if length != 13UL {
        return Err(_png_error("png-ihdr-length"))
      }
      match _png_preflight_ihdr(payload, limits, budget) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      state = PngChunkState::BeforeIdat
    } else {
      if state == PngChunkState::BeforeIhdr {
        return Err(_png_error("png-ihdr-first"))
      }
      if is_iend {
        if state != PngChunkState::InIdat && state != PngChunkState::AfterIdat {
          return Err(_png_error("png-iend-order"))
        }
        if length != 0UL {
          return Err(_png_error("png-iend-length"))
        }
        state = PngChunkState::Finished
        return _png_require_eof(reader, scratch, consumed, limits)
      } else if is_idat {
        if state == PngChunkState::AfterIdat {
          return Err(_png_error("png-idat-contiguous"))
        }
        if state != PngChunkState::BeforeIdat && state != PngChunkState::InIdat {
          return Err(_png_error("png-idat-order"))
        }
        state = PngChunkState::InIdat
      } else {
        if _png_is_known_semantic(kind) {
          return Err(_png_error("png-semantic-chunk"))
        }
        if _png_is_critical(kind) {
          return Err(_png_error("png-unknown-critical"))
        }
        if options.preserve_opaque_metadata() {
          return Err(
            @codec.capability_unavailable(
              "png-decode", "opaque-metadata-preservation",
            ),
          )
        }
        if state == PngChunkState::InIdat {
          state = PngChunkState::AfterIdat
        }
      }
    }
  } nobreak {
    Ok(())
  }
}

///| 
/// Private decode transport.  It deliberately keeps the framing checks in this
/// package: callers never observe a compressed stream or an image before the
/// physical PNG stream (including IEND and EOF) has been authenticated.
priv struct PngTransport {
  width : UInt64
  height : UInt64
  source_channels : UInt64
  channels : UInt64
  transparency : PngTransparency
  idat : Bytes
  consumed : UInt64
}

///|
fn _png_read_transport(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngTransport, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    let (actual, next) = match _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if actual != expected { return Err(_png_error("png-signature")) }
    consumed = next
  }
  let mut state = PngChunkState::BeforeIhdr
  let mut width = 0UL
  let mut height = 0UL
  let mut source_channels = 0UL
  let mut channels = 0UL
  let idat : Array[Byte] = []
  while true {
    let (length, after_length) = match _png_read_u32(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, after_type) = match _png_read_type(reader, scratch, after_length, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match _png_validate_type_form(kind) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let is_ihdr = _png_type_is(kind, b'I', b'H', b'D', b'R')
    let is_idat = _png_type_is(kind, b'I', b'D', b'A', b'T')
    let is_iend = _png_type_is(kind, b'I', b'E', b'N', b'D')
    let payload : Array[Byte] = []
    let mut crc = _png_crc_for_type(kind)
    let mut cursor = after_type
    let mut index = 0UL
    while index < length {
      let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if is_ihdr || is_idat { payload.push(byte) }
      crc = _png_crc_step(crc, byte)
      cursor = next
      index = index + 1UL
    }
    let (stored_crc, next) = match _png_read_u32(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if (crc ^ 4294967295UL) != stored_crc { return Err(_png_error("png-crc")) }
    consumed = next
    if is_ihdr {
      if state != PngChunkState::BeforeIhdr { return Err(_png_error("png-ihdr-order")) }
      if length != 13UL { return Err(_png_error("png-ihdr-length")) }
      match _png_preflight_ihdr(payload, limits, budget) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      width = (payload[0].to_int().to_uint64() << 24) | (payload[1].to_int().to_uint64() << 16) | (payload[2].to_int().to_uint64() << 8) | payload[3].to_int().to_uint64()
      height = (payload[4].to_int().to_uint64() << 24) | (payload[5].to_int().to_uint64() << 16) | (payload[6].to_int().to_uint64() << 8) | payload[7].to_int().to_uint64()
      source_channels = if payload[9] == 0 { 1UL } else if payload[9] == 2 { 3UL } else { 4UL }
      channels = if payload[9] == 6 { 4UL } else { 3UL }
      state = PngChunkState::BeforeIdat
    } else {
      if state == PngChunkState::BeforeIhdr { return Err(_png_error("png-ihdr-first")) }
      if is_iend {
        if state != PngChunkState::InIdat && state != PngChunkState::AfterIdat { return Err(_png_error("png-iend-order")) }
        if length != 0UL { return Err(_png_error("png-iend-length")) }
        match _png_require_eof(reader, scratch, consumed, limits) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        return Ok({ width, height, source_channels, channels, transparency: PngTransparency::Opaque, idat: Bytes::from_array(idat), consumed })
      } else if is_idat {
        if state == PngChunkState::AfterIdat { return Err(_png_error("png-idat-contiguous")) }
        if state != PngChunkState::BeforeIdat && state != PngChunkState::InIdat { return Err(_png_error("png-idat-order")) }
        for byte in payload { idat.push(byte) }
        state = PngChunkState::InIdat
      } else {
        if _png_is_known_semantic(kind) { return Err(_png_error("png-semantic-chunk")) }
        if _png_is_critical(kind) { return Err(_png_error("png-unknown-critical")) }
        if options.preserve_opaque_metadata() { return Err(@codec.capability_unavailable("png-decode", "opaque-metadata-preservation")) }
        if state == PngChunkState::InIdat { state = PngChunkState::AfterIdat }
      }
    }
  } nobreak { Err(_png_error("png-finished")) }
}

///|
/// The active decoder uses this forward-only IDAT reader.  It never owns an
/// IDAT payload: bytes are CRC-authenticated as they are handed to DEFLATE.
priv struct PngIdatSource {
  reader : &@io.Reader
  scratch : @bytes.OwnedBytes
  limits : @codec.CodecLimits
  options : @codec.DecodeOptions
  mut consumed : UInt64
  mut remaining : UInt64
  mut crc : UInt64
  mut crc_pending : Bool
}

///|
priv struct PngStreamTransport {
  width : UInt64
  height : UInt64
  source_channels : UInt64
  channels : UInt64
  indexed : Bool
  palette : Bytes
  palette_entries : UInt64
  transparency : PngTransparency
  budget : @budget.Budget
  source : PngIdatSource
}

///|
fn _png_read_stream_transport(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngStreamTransport, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    let (actual, next) = match _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if actual != expected { return Err(_png_error("png-signature")) }
    consumed = next
  }
  let (ihdr_length, after_length) = match _png_read_u32(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
  let (ihdr_kind, after_type) = match _png_read_type(reader, scratch, after_length, limits) { Err(error) => return Err(error); Ok(value) => value }
  if !_png_type_is(ihdr_kind, b'I', b'H', b'D', b'R') { return Err(_png_error("png-ihdr-first")) }
  if ihdr_length != 13UL { return Err(_png_error("png-ihdr-length")) }
  let (ihdr, after_ihdr) = match _png_read_payload_and_crc(reader, scratch, ihdr_length, ihdr_kind, after_type, limits) { Err(error) => return Err(error); Ok(value) => value }
  match _png_preflight_ihdr(ihdr, limits, budget) { Err(error) => return Err(error); Ok(_) => () }
  consumed = after_ihdr
  let indexed = ihdr[9] == 3
  let palette : Array[Byte] = []
  let mut palette_entries = 0UL
  let mut saw_palette = false
  let mut transparency = PngTransparency::Opaque
  let mut saw_transparency = false
  while true {
    let (length, next_length) = match _png_read_u32(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, next_type) = match _png_read_type(reader, scratch, next_length, limits) { Err(error) => return Err(error); Ok(value) => value }
    match _png_validate_type_form(kind) { Err(error) => return Err(error); Ok(_) => () }
    if _png_type_is(kind, b'I', b'D', b'A', b'T') {
      if indexed && !saw_palette { return Err(_png_error("png-plte-required")) }
      let channels = match transparency { PngTransparency::Opaque => if ihdr[9] == 6 { 4UL } else { 3UL }; _ => 4UL }
      let output_budget = if indexed {
        match _png_indexed_decode_budget(
          (ihdr[0].to_int().to_uint64() << 24) | (ihdr[1].to_int().to_uint64() << 16) | (ihdr[2].to_int().to_uint64() << 8) | ihdr[3].to_int().to_uint64(),
          (ihdr[4].to_int().to_uint64() << 24) | (ihdr[5].to_int().to_uint64() << 16) | (ihdr[6].to_int().to_uint64() << 8) | ihdr[7].to_int().to_uint64(),
          channels, limits, budget,
        ) { Err(error) => return Err(error); Ok(value) => value }
      } else if channels == 4UL && ihdr[9] != 6 {
        match _png_transparent_decode_budget(
          (ihdr[0].to_int().to_uint64() << 24) | (ihdr[1].to_int().to_uint64() << 16) | (ihdr[2].to_int().to_uint64() << 8) | ihdr[3].to_int().to_uint64(),
          (ihdr[4].to_int().to_uint64() << 24) | (ihdr[5].to_int().to_uint64() << 16) | (ihdr[6].to_int().to_uint64() << 8) | ihdr[7].to_int().to_uint64(),
          if ihdr[9] == 0 { 1UL } else { 3UL }, limits, budget,
        ) { Err(error) => return Err(error); Ok(value) => value }
      } else { budget }
      return Ok({
        width: (ihdr[0].to_int().to_uint64() << 24) | (ihdr[1].to_int().to_uint64() << 16) | (ihdr[2].to_int().to_uint64() << 8) | ihdr[3].to_int().to_uint64(),
        height: (ihdr[4].to_int().to_uint64() << 24) | (ihdr[5].to_int().to_uint64() << 16) | (ihdr[6].to_int().to_uint64() << 8) | ihdr[7].to_int().to_uint64(),
        source_channels: if ihdr[9] == 0 || ihdr[9] == 3 { 1UL } else if ihdr[9] == 2 { 3UL } else { 4UL },
        channels,
        indexed,
        palette: Bytes::from_array(palette),
        palette_entries,
        transparency,
        budget: output_budget,
        source: { reader, scratch, limits, options, consumed: next_type, remaining: length, crc: _png_crc_for_type(kind), crc_pending: true },
      })
    }
    if _png_type_is(kind, b't', b'R', b'N', b'S') {
      if saw_transparency { return Err(_png_error("png-trns-order")) }
      let (payload, next) = match _png_read_payload_and_crc(reader, scratch, length, kind, next_type, limits) { Err(error) => return Err(error); Ok(value) => value }
      if ihdr[9] == 0 {
        if length != 2UL { return Err(_png_error("png-trns-length")) }
        if payload[0] != b'\x00' { return Err(_png_error("png-trns-sample")) }
        transparency = PngTransparency::Grayscale(payload[1])
      } else if ihdr[9] == 2 {
        if length != 6UL { return Err(_png_error("png-trns-length")) }
        if payload[0] != b'\x00' || payload[2] != b'\x00' || payload[4] != b'\x00' { return Err(_png_error("png-trns-sample")) }
        transparency = PngTransparency::Rgb(payload[1], payload[3], payload[5])
      } else if ihdr[9] == 3 {
        if !saw_palette { return Err(_png_error("png-trns-order")) }
        if length > palette_entries { return Err(_png_error("png-trns-length")) }
        transparency = PngTransparency::Indexed(Bytes::from_array(payload))
      } else { return Err(_png_error("png-semantic-chunk")) }
      saw_transparency = true
      consumed = next
      continue
    }
    if _png_type_is(kind, b'P', b'L', b'T', b'E') {
      if !indexed { return Err(_png_error("png-semantic-chunk")) }
      if saw_palette { return Err(_png_error("png-plte-order")) }
      if length < 3UL || length > 768UL || length % 3UL != 0UL {
        return Err(_png_error("png-plte-length"))
      }
      let (payload, next) = match _png_read_payload_and_crc(reader, scratch, length, kind, next_type, limits) { Err(error) => return Err(error); Ok(value) => value }
      for byte in payload { palette.push(byte) }
      palette_entries = length / 3UL
      saw_palette = true
      consumed = next
      continue
    }
    if _png_type_is(kind, b'I', b'E', b'N', b'D') { return Err(_png_error("png-iend-order")) }
    if _png_is_known_semantic(kind) { return Err(_png_error("png-semantic-chunk")) }
    if _png_is_critical(kind) { return Err(_png_error("png-unknown-critical")) }
    if options.preserve_opaque_metadata() { return Err(@codec.capability_unavailable("png-decode", "opaque-metadata-preservation")) }
    let (_, next) = match _png_read_payload_and_crc(reader, scratch, length, kind, next_type, limits) { Err(error) => return Err(error); Ok(value) => value }
    consumed = next
  } nobreak { Err(_png_error("png-idat-order")) }
}

///|
fn PngIdatSource::next_byte(self : PngIdatSource) -> Result[Byte, @error.CoreError] {
  if self.remaining == 0UL && self.crc_pending {
    let (stored, after_crc) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if (self.crc ^ 4294967295UL) != stored { return Err(_png_error("png-crc")) }
    self.consumed = after_crc
    self.crc_pending = false
  }
  while self.remaining == 0UL {
    let (length, after_length) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, after_type) = match _png_read_type(self.reader, self.scratch, after_length, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    match _png_validate_type_form(kind) { Err(error) => return Err(error); Ok(_) => () }
    if !_png_type_is(kind, b'I', b'D', b'A', b'T') {
      if _png_type_is(kind, b'P', b'L', b'T', b'E') { return Err(_png_error("png-plte-order")) }
      return Err(_png_error("zlib-truncated"))
    }
    self.consumed = after_type
    self.remaining = length
    self.crc = _png_crc_for_type(kind)
    self.crc_pending = true
    if self.remaining == 0UL {
      let (stored, after_crc) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
      if (self.crc ^ 4294967295UL) != stored { return Err(_png_error("png-crc")) }
      self.consumed = after_crc
      self.crc_pending = false
    }
  }
  let (byte, next) = match _png_read_one(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
  self.consumed = next
  self.remaining = self.remaining - 1UL
  self.crc = _png_crc_step(self.crc, byte)
  Ok(byte)
}

///|
fn PngIdatSource::finish(self : PngIdatSource) -> Result[UInt64, @error.CoreError] {
  if self.remaining != 0UL { return Err(_png_error("zlib-trailing")) }
  if self.crc_pending {
    let (stored, after_crc) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if (self.crc ^ 4294967295UL) != stored { return Err(_png_error("png-crc")) }
    self.consumed = after_crc
    self.crc_pending = false
  }
  while true {
    let (length, after_length) = match _png_read_u32(self.reader, self.scratch, self.consumed, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    if length > 2147483647UL { return Err(_png_error("png-chunk-length")) }
    let (kind, after_type) = match _png_read_type(self.reader, self.scratch, after_length, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    match _png_validate_type_form(kind) { Err(error) => return Err(error); Ok(_) => () }
    if _png_type_is(kind, b'I', b'D', b'A', b'T') { return Err(_png_error("png-idat-contiguous")) }
    if _png_type_is(kind, b'I', b'E', b'N', b'D') {
      if length != 0UL { return Err(_png_error("png-iend-length")) }
      let (_, next) = match _png_read_payload_and_crc(self.reader, self.scratch, length, kind, after_type, self.limits) { Err(error) => return Err(error); Ok(value) => value }
      match _png_require_eof(self.reader, self.scratch, next, self.limits) { Err(error) => return Err(error); Ok(_) => return Ok(next) }
    }
    if _png_type_is(kind, b't', b'R', b'N', b'S') { return Err(_png_error("png-trns-order")) }
    if _png_type_is(kind, b'P', b'L', b'T', b'E') { return Err(_png_error("png-plte-order")) }
    if _png_is_known_semantic(kind) { return Err(_png_error("png-semantic-chunk")) }
    if _png_is_critical(kind) { return Err(_png_error("png-unknown-critical")) }
    if self.options.preserve_opaque_metadata() { return Err(@codec.capability_unavailable("png-decode", "opaque-metadata-preservation")) }
    let (_, next) = match _png_read_payload_and_crc(self.reader, self.scratch, length, kind, after_type, self.limits) { Err(error) => return Err(error); Ok(value) => value }
    self.consumed = next
  } nobreak { Err(_png_error("png-finished")) }
}
