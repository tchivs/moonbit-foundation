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
priv struct KernAdmissionFacts {
  state : KernState
  subtable_work : UInt64
  pair_work : UInt64
}

///|
priv struct KernClassicProfile {
  subtable_start : UInt64
  subtable_length : UInt64
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
fn font_kern_classic_envelope(
  table : TableWindow,
  subtable_count : UInt64,
) -> Result[KernClassicProfile?, @error.CoreError] {
  let mut cursor = 4UL
  let mut profile : KernClassicProfile? = None
  for _index = 0UL; _index < subtable_count; _index = _index + 1UL {
    let header_end = match @checked.checked_add(cursor, 6UL) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if header_end > table.length_value {
      return Err(font_data_error("font-kern-envelope"))
    }
    let version = match read_u16(table.view, cursor) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    let length = match read_u16(table.view, cursor + 2UL) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    let coverage = match read_u16(table.view, cursor + 4UL) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if length < 6UL {
      return Err(font_data_error("font-kern-envelope"))
    }
    let end = match @checked.checked_add(cursor, length) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if end > table.length_value {
      return Err(font_data_error("font-kern-envelope"))
    }
    if subtable_count == 1UL && version == 0UL && coverage == 0x0001UL {
      profile = Some({ subtable_start: cursor, subtable_length: length })
    }
    cursor = end
  }
  if cursor != table.length_value {
    return Err(font_data_error("font-kern-envelope"))
  }
  Ok(profile)
}

///|
fn font_kern_apple_envelope(
  table : TableWindow,
  subtable_count : UInt64,
) -> Result[Unit, @error.CoreError] {
  let mut cursor = 8UL
  for _index = 0UL; _index < subtable_count; _index = _index + 1UL {
    let header_end = match @checked.checked_add(cursor, 8UL) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if header_end > table.length_value {
      return Err(font_data_error("font-kern-envelope"))
    }
    let length = match read_u32(table.view, cursor) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if length < 8UL {
      return Err(font_data_error("font-kern-envelope"))
    }
    let end = match @checked.checked_add(cursor, length) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if end > table.length_value {
      return Err(font_data_error("font-kern-envelope"))
    }
    cursor = end
  }
  if cursor != table.length_value {
    return Err(font_data_error("font-kern-envelope"))
  }
  Ok(())
}

///|
fn font_kern_format0_pair_count(
  table : TableWindow,
  profile : KernClassicProfile,
) -> Result[UInt64, @error.CoreError] {
  if profile.subtable_length < 14UL {
    return Err(font_data_error("font-kern-format0"))
  }
  match read_u16(table.view, profile.subtable_start + 6UL) {
    Err(_) => Err(font_data_error("font-kern-format0"))
    Ok(value) => Ok(value)
  }
}

///|
fn font_kern_format0_facts(
  table : TableWindow,
  profile : KernClassicProfile,
  pair_count : UInt64,
  num_glyphs : UInt64,
) -> Result[KernFormat0Facts, @error.CoreError] {
  font_kern_format0_facts_with_probe(
    table,
    profile,
    pair_count,
    num_glyphs,
    fn() { () },
  )
}

///|
fn font_kern_format0_facts_with_probe(
  table : TableWindow,
  profile : KernClassicProfile,
  pair_count : UInt64,
  num_glyphs : UInt64,
  pair_probe : () -> Unit,
) -> Result[KernFormat0Facts, @error.CoreError] {
  let pair_bytes = match @checked.checked_mul(pair_count, 6UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let expected_length = match @checked.checked_add(14UL, pair_bytes) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  if profile.subtable_length != expected_length {
    return Err(font_data_error("font-kern-format0"))
  }
  let search_range = match read_u16(table.view, profile.subtable_start + 8UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let entry_selector = match
    read_u16(table.view, profile.subtable_start + 10UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let range_shift = match read_u16(table.view, profile.subtable_start + 12UL) {
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
  let pairs_start = match
    @checked.checked_add(profile.subtable_start, 14UL) {
    Err(_) => return Err(font_data_error("font-kern-format0"))
    Ok(value) => value
  }
  let mut previous_key : UInt64? = None
  for index = 0UL; index < pair_count; index = index + 1UL {
    pair_probe()
    let record_offset = match @checked.checked_mul(index, 6UL) {
      Err(_) => return Err(font_data_error("font-kern-format0"))
      Ok(value) => value
    }
    let offset = match @checked.checked_add(pairs_start, record_offset) {
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
  Ok({ view: table.view, pairs_start, pair_count })
}

///|
fn font_kern_classify(
  table : TableWindow,
  num_glyphs : UInt64,
) -> Result[KernState, @error.CoreError] {
  if table.length_value < 4UL {
    return Err(font_data_error("font-kern-envelope"))
  }
  let prefix = match read_u32(table.view, 0UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  let classic_version = prefix >> 16
  if classic_version == 0UL {
    let subtable_count = prefix & 0xFFFFUL
    let profile = match font_kern_classic_envelope(table, subtable_count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return match profile {
      None => Ok(Unsupported)
      Some(value) => {
        let pair_count = match font_kern_format0_pair_count(table, value) {
          Err(error) => return Err(error)
          Ok(count) => count
        }
        match font_kern_format0_facts(table, value, pair_count, num_glyphs) {
          Err(error) => Err(error)
          Ok(facts) => Ok(Supported(facts))
        }
      }
    }
  }
  if prefix == 0x00010000UL {
    if table.length_value < 8UL {
      return Err(font_data_error("font-kern-envelope"))
    }
    let subtable_count = match read_u32(table.view, 4UL) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    match font_kern_apple_envelope(table, subtable_count) {
      Err(error) => return Err(error)
      Ok(_) => return Ok(Unsupported)
    }
  }
  Ok(Unsupported)
}

///|
fn font_admit_kern(
  table : TableWindow?,
  num_glyphs : UInt64,
) -> Result[KernState, @error.CoreError] {
  match table {
    None => Ok(Absent)
    Some(value) => font_kern_classify(value, num_glyphs)
  }
}

///|
fn font_admit_kern_bounded(
  table : TableWindow?,
  num_glyphs : UInt64,
  limits : FontLimits,
  ledger : FontAdmissionLedger,
  base_work : UInt64,
  base_budget_work : UInt64,
) -> Result[KernAdmissionFacts, @error.CoreError] {
  font_admit_kern_bounded_with_probe(
    table,
    num_glyphs,
    limits,
    ledger,
    base_work,
    base_budget_work,
    fn() { () },
  )
}

///|
fn font_admit_kern_bounded_with_probe(
  table : TableWindow?,
  num_glyphs : UInt64,
  limits : FontLimits,
  ledger : FontAdmissionLedger,
  base_work : UInt64,
  base_budget_work : UInt64,
  pair_probe : () -> Unit,
) -> Result[KernAdmissionFacts, @error.CoreError] {
  let table = match table {
    None =>
      return Ok({ state: Absent, subtable_work: 0UL, pair_work: 0UL })
    Some(value) => value
  }
  if table.length_value < 4UL {
    return Err(font_data_error("font-kern-envelope"))
  }
  let prefix = match read_u32(table.view, 0UL) {
    Err(_) => return Err(font_data_error("font-kern-envelope"))
    Ok(value) => value
  }
  let classic_version = prefix >> 16
  if classic_version == 0UL {
    let subtable_count = prefix & 0xFFFFUL
    if subtable_count > limits.max_kern_subtables() {
      return Err(
        font_limit_error(
          "max-kern-subtables",
          subtable_count,
          limits.max_kern_subtables(),
        ),
      )
    }
    let subtable_work = match @checked.checked_add(base_work, subtable_count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if subtable_work > limits.max_work() {
      return Err(
        font_limit_error("max-work", subtable_work, limits.max_work()),
      )
    }
    match
      ledger.admit_stage(
        limits.max_work(),
        subtable_work,
        base_budget_work,
        subtable_count,
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let profile = match font_kern_classic_envelope(table, subtable_count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return match profile {
      None =>
        Ok({
          state: Unsupported,
          subtable_work: subtable_count,
          pair_work: 0UL,
        })
      Some(value) => {
        let pair_count = match font_kern_format0_pair_count(table, value) {
          Err(error) => return Err(error)
          Ok(count) => count
        }
        if pair_count > limits.max_kern_pairs() {
          return Err(
            font_limit_error(
              "max-kern-pairs",
              pair_count,
              limits.max_kern_pairs(),
            ),
          )
        }
        let pair_work = match @checked.checked_add(subtable_work, pair_count) {
          Err(error) => return Err(error)
          Ok(result) => result
        }
        if pair_work > limits.max_work() {
          return Err(
            font_limit_error("max-work", pair_work, limits.max_work()),
          )
        }
        match
          ledger.admit_stage(
            limits.max_work(),
            pair_work,
            base_budget_work,
            pair_count,
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        let facts = match
          font_kern_format0_facts_with_probe(
            table,
            value,
            pair_count,
            num_glyphs,
            pair_probe,
          ) {
          Err(error) => return Err(error)
          Ok(result) => result
        }
        Ok({
          state: Supported(facts),
          subtable_work: subtable_count,
          pair_work: pair_count,
        })
      }
    }
  }
  if prefix == 0x00010000UL {
    if table.length_value < 8UL {
      return Err(font_data_error("font-kern-envelope"))
    }
    let subtable_count = match read_u32(table.view, 4UL) {
      Err(_) => return Err(font_data_error("font-kern-envelope"))
      Ok(value) => value
    }
    if subtable_count > limits.max_kern_subtables() {
      return Err(
        font_limit_error(
          "max-kern-subtables",
          subtable_count,
          limits.max_kern_subtables(),
        ),
      )
    }
    let subtable_work = match @checked.checked_add(base_work, subtable_count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if subtable_work > limits.max_work() {
      return Err(
        font_limit_error("max-work", subtable_work, limits.max_work()),
      )
    }
    match
      ledger.admit_stage(
        limits.max_work(),
        subtable_work,
        base_budget_work,
        subtable_count,
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    match font_kern_apple_envelope(table, subtable_count) {
      Err(error) => return Err(error)
      Ok(_) =>
        return Ok({
          state: Unsupported,
          subtable_work: subtable_count,
          pair_work: 0UL,
        })
    }
  }
  Ok({ state: Unsupported, subtable_work: 0UL, pair_work: 0UL })
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
