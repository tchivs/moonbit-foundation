///|
/// Compact retained facts for one admitted format-12 Unicode mapping.
priv struct CmapFormat12Facts {
  view : @bytes.ByteView
  offset : UInt64
  group_count : UInt64
}

///|
/// The single mapping selected during atomic cmap admission.
priv enum CmapLookupFacts {
  Format12(CmapFormat12Facts)
}

///|
/// Return the canonical priority for the format-12 tracer mappings.
///
/// Lower numeric values have higher priority. Phase 98's expansion adds the
/// two canonical format-4 ranks without changing this ordering.
fn font_cmap_rank(
  platform : UInt64,
  encoding : UInt64,
  format : UInt64,
) -> Int? {
  if platform == 0UL && encoding == 4UL && format == 12UL {
    Some(0)
  } else if platform == 3UL && encoding == 10UL && format == 12UL {
    Some(1)
  } else {
    None
  }
}

///|
/// Validate every supported record and retain the highest-ranked format-12
/// mapping without exposing any raw cmap state.
fn font_admit_cmap_lookup(
  table : TableWindow,
  record_count : UInt64,
  records_end : UInt64,
  maxp : MaxpFacts,
) -> Result[CmapLookupFacts?, @error.CoreError] {
  let mut has_previous = false
  let mut previous_platform = 0UL
  let mut previous_encoding = 0UL
  let mut previous_language = 0UL
  let mut selected : CmapLookupFacts? = None
  let mut selected_rank = 0
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
    let facts = match
      font_validate_cmap_subtable(table, subtable, maxp.num_glyphs) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if !font_cmap_domain_supported(platform, encoding, facts.format) ||
      (platform != 1UL && facts.language != 0UL) {
      return Err(font_data_error("font-cmap-envelope"))
    }
    if has_previous &&
      (
        platform < previous_platform ||
        (
          platform == previous_platform &&
          (
            encoding < previous_encoding ||
            (
              encoding == previous_encoding &&
              facts.language <= previous_language
            )
          )
        )
      ) {
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
      Some(rank) =>
        if selected is None || rank < selected_rank {
          selected = Some(
            CmapLookupFacts::Format12({
              view: table.view,
              offset: subtable,
              group_count: facts.body_records,
            }),
          )
          selected_rank = rank
        }
      None => ()
    }
    has_previous = true
    previous_platform = platform
    previous_encoding = encoding
    previous_language = facts.language
    index = index + 1UL
  }
  Ok(selected)
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
    let end_code = match read_u32(facts.view, group + 4UL) {
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
  let start_glyph = match read_u32(facts.view, group + 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @checked.checked_add(start_glyph, scalar - start_code)
}

///|
fn font_lookup_cmap(
  facts : CmapLookupFacts,
  scalar : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match facts {
    Format12(value) => font_lookup_cmap_format12(value, scalar)
  }
}
