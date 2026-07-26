///|
fn font_read_error(
  offset : UInt64,
  width : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-read",
    requested=width,
    source_offset=offset,
    limit~,
    context="font-table-window",
  )
}

///|
fn require_read_window(
  source : @bytes.ByteView,
  offset : UInt64,
  width : UInt64,
) -> Result[Unit, @error.CoreError] {
  let end = match @checked.checked_add(offset, width) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if end > source.length() {
    Err(font_read_error(offset, width, source.length()))
  } else {
    Ok(())
  }
}

///|
fn read_u8(
  source : @bytes.ByteView,
  offset : UInt64,
) -> Result[Byte, @error.CoreError] {
  match require_read_window(source, offset, 1UL) {
    Err(error) => Err(error)
    Ok(_) => source.get(offset)
  }
}

///|
fn read_u16(
  source : @bytes.ByteView,
  offset : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match require_read_window(source, offset, 2UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let high = match read_u8(source, offset) {
    Err(error) => return Err(error)
    Ok(value) => value.to_uint64()
  }
  let low_offset = match @checked.checked_add(offset, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let low = match read_u8(source, low_offset) {
    Err(error) => return Err(error)
    Ok(value) => value.to_uint64()
  }
  Ok((high << 8) | low)
}

///|
fn read_i16(
  source : @bytes.ByteView,
  offset : UInt64,
) -> Result[Int, @error.CoreError] {
  match read_u16(source, offset) {
    Err(error) => Err(error)
    Ok(value) =>
      if value >= 0x8000UL {
        Ok(value.to_int() - 0x10000)
      } else {
        Ok(value.to_int())
      }
  }
}

///|
fn read_u32(
  source : @bytes.ByteView,
  offset : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match require_read_window(source, offset, 4UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut value = 0UL
  for delta in [0UL, 1UL, 2UL, 3UL] {
    let index = match @checked.checked_add(offset, delta) {
      Err(error) => return Err(error)
      Ok(result) => result
    }
    let byte = match source.get(index) {
      Err(error) => return Err(error)
      Ok(result) => result
    }
    value = (value << 8) | byte.to_uint64()
  }
  Ok(value)
}
