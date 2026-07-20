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
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=length, allocations=1UL, allocation_size=length, width=0UL,
    height=0UL, pixels=0UL, depth=0UL, work=0UL,
  ))
}

///|
fn _png_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding,
    operation="png-decode", context~,)
}

///|
fn _png_limit(context : String, requested : UInt64, limit : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource, @error.ErrorCode::BudgetExceeded,
    operation="png-decode", requested~, limit~, context~,)
}

///|
fn _png_read_one(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Byte, UInt64), @error.CoreError] {
  let next = match @checked.checked_add(consumed, 1UL) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if next > limits.max_input_bytes() {
    return Err(_png_limit("input-bytes", next, limits.max_input_bytes()))
  }
  match scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Ok(_) => Ok((scratch.view().get(0UL).unwrap(), next))
    Err(error) => Err(error)
  }
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
fn _png_validate_transport(
  reader : &@io.Reader,
  _options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  _budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
  let mut consumed = 0UL
  for expected in signature {
    match _png_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok((actual, next)) => {
        if actual != expected { return Err(_png_error("png-signature")) }
        consumed = next
      }
    }
  }
  // The full private chunk-state machine is deliberately retained behind this
  // Phase-20 seam; no image or caller-budget mutation can occur here.
  let _state = PngChunkState::BeforeIhdr
  Ok(())
}
