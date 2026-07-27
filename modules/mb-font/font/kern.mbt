///|
/// Compact retained facts for one admitted OpenType version-0 format-0 table.
priv struct KernFormat0Facts {
  view : @bytes.ByteView
  pairs_start : UInt64
  pair_count : UInt64
}

///|
/// Optional kern admission retains absence, the one supported profile, or a
/// structurally valid profile which this package does not implement.
priv enum KernState {
  Absent
  Supported(KernFormat0Facts)
  Unsupported
}

///|
fn font_kern_pair_key(left : UInt64, right : UInt64) -> UInt64 {
  (left << 16) | right
}

///|
fn font_kern_search_facts(pair_count : UInt64) -> (UInt64, UInt64, UInt64) {
  if pair_count == 0UL {
    return (0UL, 0UL, 0UL)
  }
  let mut power = 1UL
  let mut selector = 0UL
  while power <= pair_count / 2UL {
    power = power * 2UL
    selector = selector + 1UL
  }
  let search_range = power * 6UL
  (search_range, selector, pair_count * 6UL - search_range)
}

///|
fn font_kern_profile_error() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-kerning",
    context="font-kern-profile",
  )
}

///|
fn font_admit_kern(
  table : TableWindow?,
  num_glyphs : UInt64,
) -> Result[KernState, @error.CoreError] {
  let table = match table {
    None => return Ok(Absent)
    Some(value) => value
  }
  if table.length_value < 4UL {
    return Err(font_data_error("font-kern-envelope"))
  }
  let version = match read_u16(table.view, 0UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  let subtable_count = match read_u16(table.view, 2UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  if version != 0UL || subtable_count != 1UL {
    return Ok(Unsupported)
  }
  if table.length_value < 18UL {
    return Err(font_data_error("font-kern-envelope"))
  }
  let subtable_version = match read_u16(table.view, 4UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  let subtable_length = match read_u16(table.view, 6UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  let coverage = match read_u16(table.view, 8UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  if subtable_length < 6UL {
    return Err(font_data_error("font-kern-envelope"))
  }
  let table_end = match @checked.checked_add(4UL, subtable_length) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  if table_end != table.length_value {
    return Err(font_data_error("font-kern-envelope"))
  }
  if subtable_version != 0UL || coverage != 0x0001UL {
    return Ok(Unsupported)
  }
  let pair_count = match read_u16(table.view, 10UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let pair_bytes = match @checked.checked_mul(pair_count, 6UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let expected_subtable_length = match @checked.checked_add(14UL, pair_bytes) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  if subtable_length != expected_subtable_length {
    return Err(font_data_error("font-kern-format0"))
  }
  let search_range = match read_u16(table.view, 12UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let entry_selector = match read_u16(table.view, 14UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let range_shift = match read_u16(table.view, 16UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let (expected_search, expected_selector, expected_shift) = font_kern_search_facts(
    pair_count,
  )
  if search_range != expected_search ||
    entry_selector != expected_selector ||
    range_shift != expected_shift {
    return Err(font_data_error("font-kern-search"))
  }
  let mut previous_key : UInt64? = None
  for index = 0UL; index < pair_count; index = index + 1UL {
    let record_offset = match @checked.checked_mul(index, 6UL) {
      Err(_) => return Err(font_data_error("font-kern-format0"))
      Ok(value) => value
    }
    let offset = match @checked.checked_add(18UL, record_offset) {
      Err(_) => return Err(font_data_error("font-kern-format0"))
      Ok(value) => value
    }
    let left = match read_u16(table.view, offset) {
      Err(_) => return Err(font_data_error("font-kern-format0"))
      Ok(value) => value
    }
    let right = match read_u16(table.view, offset + 2UL) {
      Err(_) => return Err(font_data_error("font-kern-format0"))
      Ok(value) => value
    }
    if left >= num_glyphs || right >= num_glyphs {
      return Err(font_data_error("font-kern-glyph-range"))
    }
    let key = font_kern_pair_key(left, right)
    match previous_key {
      Some(previous) =>
        if key <= previous {
          return Err(font_data_error("font-kern-pair-order"))
        }
      None => ()
    }
    match read_i16(table.view, offset + 4UL) {
      Err(_) => return Err(font_data_error("font-kern-format0"))
      Ok(_) => ()
    }
    previous_key = Some(key)
  }
  Ok(Supported({ view: table.view, pairs_start: 18UL, pair_count }))
}

///|
fn font_lookup_kern(
  state : KernState,
  left : UInt64,
  right : UInt64,
) -> Result[Int, @error.CoreError] {
  let facts = match state {
    Absent => return Ok(0)
    Unsupported => return Err(font_kern_profile_error())
    Supported(value) => value
  }
  let wanted = font_kern_pair_key(left, right)
  let mut low = 0UL
  let mut high = facts.pair_count
  while low < high {
    let mid = low + (high - low) / 2UL
    let record_offset = match @checked.checked_mul(mid, 6UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let offset = match @checked.checked_add(facts.pairs_start, record_offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let pair_left = match read_u16(facts.view, offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let pair_right = match read_u16(facts.view, offset + 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let key = font_kern_pair_key(pair_left, pair_right)
    if key < wanted {
      low = mid + 1UL
    } else {
      high = mid
    }
  }
  if low >= facts.pair_count {
    return Ok(0)
  }
  let record_offset = match @checked.checked_mul(low, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let offset = match @checked.checked_add(facts.pairs_start, record_offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pair_left = match read_u16(facts.view, offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pair_right = match read_u16(facts.view, offset + 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if font_kern_pair_key(pair_left, pair_right) != wanted {
    return Ok(0)
  }
  read_i16(facts.view, offset + 4UL)
}
