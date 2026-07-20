///|
priv enum PngChunkState {
  BeforeIhdr
  BeforeIdat
  InIdat
  AfterIdat
  Finished
} derive(Eq)

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
  let channels = if ihdr[9] == 2 {
    3UL
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
  let image_bytes = match @checked.checked_mul(pixels, channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row_bytes = match @checked.checked_mul(width, channels) {
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
fn _png_read_payload_and_crc(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  length : UInt64,
  kind : Array[Byte],
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Array[Byte], UInt64), @error.CoreError] {
  let data : Array[Byte] = []
  let capture_ihdr = _png_type_is(kind, b'I', b'H', b'D', b'R')
  let mut crc = _png_crc_for_type(kind)
  let mut cursor = consumed
  let mut index = 0UL
  while index < length {
    let (byte, next) = match _png_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if capture_ihdr {
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
  match _png_read_one(reader, scratch, consumed, limits) {
    Ok(_) => Err(_png_error("png-trailing-data"))
    Err(error) =>
      if error.code() == @error.ErrorCode::UnexpectedEndOfStream {
        Ok(())
      } else {
        Err(error)
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
