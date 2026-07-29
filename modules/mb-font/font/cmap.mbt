///|
/// Compact retained facts for one admitted format-12 Unicode mapping.
priv struct CmapFormat12Facts {
  view : @bytes.ByteView
  offset : UInt64
  group_count : UInt64
}

///|
/// Compact retained array bases for one admitted format-4 Unicode mapping.
priv struct CmapFormat4Facts {
  view : @bytes.ByteView
  segment_count : UInt64
  end_codes : UInt64
  start_codes : UInt64
  id_deltas : UInt64
  id_range_offsets : UInt64
}

///|
/// The single mapping selected during atomic cmap admission.
priv enum CmapLookupFacts {
  Format12(CmapFormat12Facts)
  Format4(CmapFormat4Facts)
}

///|
/// Return the frozen canonical Unicode mapping priority.
///
/// Lower numeric values have higher priority and every other tuple is
/// deliberately non-canonical.
fn font_cmap_rank(
  platform : UInt64,
  encoding : UInt64,
  format : UInt64,
) -> Int? {
  if platform == 0UL && encoding == 4UL && format == 12UL {
    Some(0)
  } else if platform == 3UL && encoding == 10UL && format == 12UL {
    Some(1)
  } else if platform == 0UL && encoding == 3UL && format == 4UL {
    Some(2)
  } else if platform == 3UL && encoding == 1UL && format == 4UL {
    Some(3)
  } else {
    None
  }
}

///|
/// Recognize bounded nonselected coexistence records.
fn font_cmap_recognized_nonselected(
  platform : UInt64,
  encoding : UInt64,
  format : UInt64,
) -> Bool {
  (platform == 1UL &&
    (encoding == 0UL || encoding == 1UL) &&
    format == 6UL) ||
  (platform == 0UL && encoding == 5UL && format == 14UL)
}

///|
fn font_cmap_format4_facts(
  table : TableWindow,
  offset : UInt64,
  segment_count : UInt64,
) -> Result[CmapFormat4Facts, @error.CoreError] {
  let code_array_size = match @checked.checked_mul(segment_count, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let end_codes = match @checked.checked_add(offset, 14UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let reserved = match @checked.checked_add(end_codes, code_array_size) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let start_codes = match @checked.checked_add(reserved, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let id_deltas = match @checked.checked_add(start_codes, code_array_size) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let id_range_offsets = match
    @checked.checked_add(id_deltas, code_array_size) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    view: table.view,
    segment_count,
    end_codes,
    start_codes,
    id_deltas,
    id_range_offsets,
  })
}

///|
fn font_cmap_lookup_facts(
  table : TableWindow,
  subtable : UInt64,
  facts : CmapSubtableFacts,
) -> Result[CmapLookupFacts, @error.CoreError] {
  match facts.format {
    12UL =>
      Ok(
        CmapLookupFacts::Format12({
          view: table.view,
          offset: subtable,
          group_count: facts.body_records,
        }),
      )
    4UL =>
      match font_cmap_format4_facts(table, subtable, facts.body_records) {
        Err(error) => Err(error)
        Ok(value) => Ok(CmapLookupFacts::Format4(value))
      }
    _ => Err(font_data_error("font-cmap-envelope"))
  }
}

///|
fn font_cmap_duplicate_rank(
  rank : Int,
  seen0 : Bool,
  seen1 : Bool,
  seen2 : Bool,
  seen3 : Bool,
) -> Bool {
  match rank {
    0 => seen0
    1 => seen1
    2 => seen2
    3 => seen3
    _ => false
  }
}

///|
/// Validate every supported record and retain the highest-ranked mapping
/// independent of record order. Canonical record keys are unique; lower-ranked
/// records are structurally checked but never compared or queried.
fn font_admit_cmap_lookup(
  table : TableWindow,
  record_count : UInt64,
  records_end : UInt64,
  maxp : MaxpFacts,
) -> Result[CmapLookupFacts, @error.CoreError] {
  let mut selected : CmapLookupFacts? = None
  let mut selected_rank = 0
  let mut seen0 = false
  let mut seen1 = false
  let mut seen2 = false
  let mut seen3 = false
  let mut index = 0UL
  while index < record_count {
    let record = match
      @checked.checked_add(
        4UL,
        match @checked.checked_mul(index, 8UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        },
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let platform = match read_u16(table.view, record) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let encoding = match read_u16(table.view, record + 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let subtable_field = match @checked.checked_add(record, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let subtable = match read_u32(table.view, subtable_field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if subtable < records_end {
      return Err(font_data_error("font-cmap-envelope"))
    }
    let envelope = match font_cmap_subtable_envelope(table, subtable) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if font_cmap_recognized_nonselected(
      platform,
      encoding,
      envelope.format,
    ) {
      index = index + 1UL
      continue
    }
    if envelope.format != 4UL && envelope.format != 12UL {
      return Err(font_data_error("font-cmap-envelope"))
    }
    let facts = match
      font_validate_cmap_subtable(table, subtable, maxp.num_glyphs) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if !font_cmap_domain_supported(platform, encoding, facts.format) ||
      (platform != 1UL && facts.language != 0UL) {
      return Err(font_data_error("font-cmap-envelope"))
    }
    let end = match @checked.checked_add(subtable, facts.length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if end > table.length_value {
      return Err(font_data_error("font-cmap-envelope"))
    }
    match font_cmap_rank(platform, encoding, facts.format) {
      Some(rank) => {
        if font_cmap_duplicate_rank(rank, seen0, seen1, seen2, seen3) {
          return Err(font_data_error("font-cmap-record-key"))
        }
        match rank {
          0 => seen0 = true
          1 => seen1 = true
          2 => seen2 = true
          3 => seen3 = true
          _ => ()
        }
        if selected is None || rank < selected_rank {
          selected = Some(
            match font_cmap_lookup_facts(table, subtable, facts) {
              Err(error) => return Err(error)
              Ok(value) => value
            },
          )
          selected_rank = rank
        }
      }
      None => ()
    }
    index = index + 1UL
  }
  match selected {
    Some(value) => Ok(value)
    None => Err(font_capability_error("font-cmap-unicode"))
  }
}

///|
/// Allocation-free lower-bound lookup over admitted format-12 groups.
fn font_lookup_cmap_format12(
  facts : CmapFormat12Facts,
  scalar : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let groups = match @checked.checked_add(facts.offset, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut low = 0UL
  let mut high = facts.group_count
  while low < high {
    let middle = low + (high - low) / 2UL
    let group = match
      @checked.checked_add(
        groups,
        match @checked.checked_mul(middle, 12UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        },
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end_field = match @checked.checked_add(group, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end_code = match read_u32(facts.view, end_field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if end_code < scalar {
      low = middle + 1UL
    } else {
      high = middle
    }
  }
  if low >= facts.group_count {
    return Ok(0UL)
  }
  let group = match
    @checked.checked_add(
      groups,
      match @checked.checked_mul(low, 12UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let start_code = match read_u32(facts.view, group) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if scalar < start_code {
    return Ok(0UL)
  }
  let start_glyph_field = match @checked.checked_add(group, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let start_glyph = match read_u32(facts.view, start_glyph_field) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @checked.checked_add(start_glyph, scalar - start_code)
}

///|
/// Allocation-free lower-bound lookup over admitted format-4 segments.
fn font_lookup_cmap_format4(
  facts : CmapFormat4Facts,
  scalar : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if scalar > 0xFFFFUL {
    return Ok(0UL)
  }
  let mut low = 0UL
  let mut high = facts.segment_count
  while low < high {
    let middle = low + (high - low) / 2UL
    let delta = match @checked.checked_mul(middle, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end_field = match @checked.checked_add(facts.end_codes, delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end_code = match read_u16(facts.view, end_field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if end_code < scalar {
      low = middle + 1UL
    } else {
      high = middle
    }
  }
  if low >= facts.segment_count {
    return Ok(0UL)
  }
  let delta = match @checked.checked_mul(low, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let start_field = match @checked.checked_add(facts.start_codes, delta) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let start_code = match read_u16(facts.view, start_field) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if scalar < start_code {
    return Ok(0UL)
  }
  let id_delta_field = match @checked.checked_add(facts.id_deltas, delta) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let id_delta = match read_u16(facts.view, id_delta_field) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let range_field = match @checked.checked_add(facts.id_range_offsets, delta) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let range_offset = match read_u16(facts.view, range_field) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if range_offset == 0UL {
    return Ok((scalar + id_delta) & 0xFFFFUL)
  }
  let first_glyph = match @checked.checked_add(range_field, range_offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let glyph_delta = match
    @checked.checked_mul(
      match @checked.checked_sub(scalar, start_code) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
      2UL,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let glyph = match @checked.checked_add(first_glyph, glyph_delta) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let raw = match read_u16(facts.view, glyph) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if raw == 0UL {
    Ok(0UL)
  } else {
    Ok((raw + id_delta) & 0xFFFFUL)
  }
}

///|
fn font_lookup_cmap(
  facts : CmapLookupFacts,
  scalar : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match facts {
    Format12(value) => font_lookup_cmap_format12(value, scalar)
    Format4(value) => font_lookup_cmap_format4(value, scalar)
  }
}
