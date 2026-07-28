///|
priv struct CffIndexObject {
  offset : UInt64
  length : UInt64
  view : @bytes.ByteView
}

///|
priv struct CffIndex {
  count : UInt64
  off_size : UInt64
  offsets : Array[UInt64]
  object_data : @bytes.ByteView
  encoded_length : UInt64
}

///|
fn cff_data_error(
  context : String,
  source_offset? : UInt64,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-cff-admit",
    source_offset?,
    requested?,
    limit?,
    context~,
  )
}

///|
fn cff_capability_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-cff-admit",
    context~,
  )
}

///|
fn cff_require_window(
  source : @bytes.ByteView,
  offset : UInt64,
  width : UInt64,
  context : String,
) -> Result[Unit, @error.CoreError] {
  let end = match @checked.checked_add(offset, width) {
    Err(_) =>
      return Err(
        cff_data_error(
          context,
          source_offset=offset,
          requested=width,
          limit=source.length(),
        ),
      )
    Ok(value) => value
  }
  if end > source.length() {
    Err(
      cff_data_error(
        context,
        source_offset=offset,
        requested=width,
        limit=source.length(),
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn cff_read_offset(
  source : @bytes.ByteView,
  offset : UInt64,
  width : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  match cff_require_window(source, offset, width, context) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut value = 0UL
  let mut index = 0UL
  while index < width {
    let position = match @checked.checked_add(offset, index) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let byte = match source.get(position) {
      Err(_) =>
        return Err(
          cff_data_error(
            context,
            source_offset=position,
            requested=1UL,
            limit=source.length(),
          ),
        )
      Ok(value) => value
    }
    value = (value << 8) | byte.to_uint64()
    index = index + 1UL
  }
  Ok(value)
}

///|
fn cff_decode_index(
  source : @bytes.ByteView,
  start : UInt64,
  max_count : UInt64,
  context : String,
) -> Result[(CffIndex, UInt64), @error.CoreError] {
  match cff_require_window(source, start, 2UL, context) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = match read_u16(source, start) {
    Err(_) =>
      return Err(
        cff_data_error(
          context,
          source_offset=start,
          requested=2UL,
          limit=source.length(),
        ),
      )
    Ok(value) => value
  }
  if count > max_count {
    return Err(
      cff_data_error(context, source_offset=start, requested=count, limit=max_count),
    )
  }
  if count == 0UL {
    let empty = match source.subview(start + 2UL, 0UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return Ok(({
      count: 0UL,
      off_size: 0UL,
      offsets: [],
      object_data: empty,
      encoded_length: 2UL,
    }, start + 2UL))
  }
  let off_size_offset = start + 2UL
  match cff_require_window(source, off_size_offset, 1UL, context) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let off_size = match source.get(off_size_offset) {
    Err(error) => return Err(error)
    Ok(value) => value.to_uint64()
  }
  if off_size < 1UL || off_size > 4UL {
    return Err(
      cff_data_error(
        context,
        source_offset=off_size_offset,
        requested=off_size,
        limit=4UL,
      ),
    )
  }
  let offset_count = match @checked.checked_add(count, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let offset_bytes = match @checked.checked_mul(offset_count, off_size) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let offset_start = start + 3UL
  match cff_require_window(source, offset_start, offset_bytes, context) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let offsets : Array[UInt64] = []
  let mut previous = 0UL
  let mut index = 0UL
  while index < offset_count {
    let delta = match @checked.checked_mul(index, off_size) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let value = match
      cff_read_offset(source, offset_start + delta, off_size, context) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if index == 0UL {
      if value != 1UL {
        return Err(
          cff_data_error(
            context + "-first-offset",
            source_offset=offset_start,
            requested=value,
            limit=1UL,
          ),
        )
      }
    } else if value < previous {
      return Err(
        cff_data_error(
          context + "-offset-order",
          source_offset=offset_start + delta,
          requested=value,
          limit=previous,
        ),
      )
    }
    offsets.push(value)
    previous = value
    index = index + 1UL
  }
  let object_data_start = match @checked.checked_add(offset_start, offset_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let terminal = offsets[offsets.length() - 1]
  if terminal == 0UL {
    return Err(cff_data_error(context + "-terminal-offset"))
  }
  let object_bytes = terminal - 1UL
  match cff_require_window(source, object_data_start, object_bytes, context) {
    Err(_) =>
      return Err(
        cff_data_error(
          context + "-terminal-extent",
          source_offset=object_data_start,
          requested=object_bytes,
          limit=source.length(),
        ),
      )
    Ok(_) => ()
  }
  let object_data = match source.subview(object_data_start, object_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let encoded_length = 3UL + offset_bytes + object_bytes
  Ok(({
    count,
    off_size,
    offsets,
    object_data,
    encoded_length,
  }, start + encoded_length))
}

///|
fn cff_index_object(
  index : CffIndex,
  object_index : UInt64,
  context : String,
) -> Result[CffIndexObject, @error.CoreError] {
  if object_index >= index.count {
    return Err(
      cff_data_error(
        context + "-object-index",
        requested=object_index,
        limit=index.count,
      ),
    )
  }
  let position = object_index.to_int()
  let first = index.offsets[position]
  let terminal = index.offsets[position + 1]
  if first == 0UL || terminal < first {
    return Err(cff_data_error(context + "-object-window"))
  }
  let offset = first - 1UL
  let length = terminal - first
  let view = match index.object_data.subview(offset, length) {
    Err(_) =>
      return Err(
        cff_data_error(
          context + "-object-window",
          source_offset=offset,
          requested=length,
          limit=index.object_data.length(),
        ),
      )
    Ok(value) => value
  }
  Ok({ offset, length, view })
}
