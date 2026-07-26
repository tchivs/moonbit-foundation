///|
priv struct HeadFacts {
  units_per_em : UInt64
  x_min : Int
  y_min : Int
  x_max : Int
  y_max : Int
  index_to_loc_format : Int
}

///|
priv struct MaxpFacts {
  num_glyphs : UInt64
}

///|
priv struct HheaFacts {
  ascent : Int
  descent : Int
  line_gap : Int
  number_of_h_metrics : UInt64
}

///|
priv struct Os2Facts {
  typo_ascent : Int
  typo_descent : Int
  typo_line_gap : Int
}

///|
/// Retained for Phase 98 cmap record selection.
#warnings("-7")
priv struct CmapEnvelope {
  record_count : UInt64
}

///|
/// Retains the admitted cmap envelope for Phase 98 cmap lookup.
#warnings("-7")
priv struct RequiredTableFacts {
  head : HeadFacts
  maxp : MaxpFacts
  hhea : HheaFacts
  os2 : Os2Facts
  cmap : CmapEnvelope
}

///|
fn font_admission_charge(
  directory : DirectoryFacts,
  limits : FontLimits,
) -> Result[@budget.ResourceCharge, @error.CoreError] {
  let maxp_table = match font_table_window(directory, 0x6D617870UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_table_min_length(maxp_table, 6UL, "font-maxp") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let num_glyphs = match read_u16(maxp_table.view, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if num_glyphs == 0UL {
    return Err(font_data_error("font-maxp", source_offset=maxp_table.offset))
  }
  if num_glyphs > limits.max_glyphs() {
    return Err(font_limit_error("max-glyphs", num_glyphs, limits.max_glyphs()))
  }

  let cmap_table = match font_table_window(directory, 0x636D6170UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_table_min_length(cmap_table, 4UL, "font-cmap-envelope") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let cmap_records = match read_u16(cmap_table.view, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if cmap_records > limits.max_cmap_records() {
    return Err(
      font_limit_error(
        "max-cmap-records",
        cmap_records,
        limits.max_cmap_records(),
      ),
    )
  }

  let name_table = match font_table_window(directory, 0x6E616D65UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_table_min_length(name_table, 6UL, "font-name-envelope") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let name_format = match read_u16(name_table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let name_records = match read_u16(name_table.view, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if name_format > 1UL {
    return Err(font_data_error("font-name-envelope"))
  }
  if name_records > limits.max_name_records() {
    return Err(
      font_limit_error(
        "max-name-records",
        name_records,
        limits.max_name_records(),
      ),
    )
  }
  let name_record_bytes = match @checked.checked_mul(name_records, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let name_records_end = match @checked.checked_add(6UL, name_record_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if name_records_end > name_table.length_value {
    return Err(font_data_error("font-name-envelope"))
  }
  let language_records = if name_format == 1UL {
    let language_count_end = match @checked.checked_add(name_records_end, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if language_count_end > name_table.length_value {
      return Err(font_data_error("font-name-envelope"))
    }
    let count = match read_u16(name_table.view, name_records_end) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if count > limits.max_name_records() {
      return Err(
        font_limit_error("max-name-records", count, limits.max_name_records()),
      )
    }
    count
  } else {
    0UL
  }

  let post_table = match font_table_window(directory, 0x706F7374UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_table_min_length(post_table, 4UL, "font-post-envelope") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let post_version = match read_u32(post_table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let (post_glyph_records, post_name_bytes) = if post_version == 0x00020000UL ||
    post_version == 0x00025000UL {
    let item_size = if post_version == 0x00020000UL { 2UL } else { 1UL }
    let index_bytes = match @checked.checked_mul(num_glyphs, item_size) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let names_start = match @checked.checked_add(34UL, index_bytes) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if names_start > post_table.length_value {
      return Err(font_data_error("font-post-envelope"))
    }
    let name_bytes = if post_version == 0x00020000UL {
      post_table.length_value - names_start
    } else {
      0UL
    }
    (num_glyphs, name_bytes)
  } else {
    (0UL, 0UL)
  }

  let loca_entries = match @checked.checked_add(num_glyphs, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let glyph_work = match @checked.checked_add(loca_entries, num_glyphs) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut work = directory.work
  for
    count in [
      glyph_work, cmap_records, name_records, language_records, post_glyph_records,
      post_name_bytes,
    ] {
    work = match @checked.checked_add(work, count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  if work > limits.max_work() {
    return Err(font_limit_error("max-work", work, limits.max_work()))
  }
  let loca_allocation_size = match @checked.checked_mul(loca_entries, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let directory_allocation_size = match
    font_directory_allocation_size(directory.tables.length().to_uint64()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let allocation_size = if directory_allocation_size > loca_allocation_size {
    directory_allocation_size
  } else {
    loca_allocation_size
  }
  Ok(
    @budget.ResourceCharge::new(
      bytes=directory.source.length(),
      allocations=3UL,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work~,
    ),
  )
}

///|
fn font_table_exact_length(
  table : TableWindow,
  expected : UInt64,
  context : String,
) -> Result[Unit, @error.CoreError] {
  if table.length_value != expected {
    Err(
      font_data_error(
        context,
        source_offset=table.offset,
        requested=expected,
        limit=table.length_value,
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn font_table_min_length(
  table : TableWindow,
  minimum : UInt64,
  context : String,
) -> Result[Unit, @error.CoreError] {
  if table.length_value < minimum {
    Err(
      font_data_error(
        context,
        source_offset=table.offset,
        requested=minimum,
        limit=table.length_value,
      ),
    )
  } else {
    Ok(())
  }
}

///|
fn font_decode_head(table : TableWindow) -> Result[HeadFacts, @error.CoreError] {
  match font_table_exact_length(table, 54UL, "font-head-length") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let version = match read_u32(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let magic = match read_u32(table.view, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let units_per_em = match read_u16(table.view, 18UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let x_min = match read_i16(table.view, 36UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y_min = match read_i16(table.view, 38UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let x_max = match read_i16(table.view, 40UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y_max = match read_i16(table.view, 42UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let index_to_loc_format = match read_i16(table.view, 50UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if version != 0x00010000UL {
    return Err(font_data_error("font-head-version", source_offset=table.offset))
  }
  if magic != 0x5F0F3CF5UL {
    let source_offset = match @checked.checked_add(table.offset, 12UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return Err(font_data_error("font-head-magic", source_offset~))
  }
  if units_per_em < 16UL || units_per_em > 16384UL {
    let source_offset = match @checked.checked_add(table.offset, 18UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return Err(
      font_data_error(
        "font-units-per-em",
        source_offset~,
        requested=units_per_em,
        limit=16384UL,
      ),
    )
  }
  if x_min > x_max || y_min > y_max {
    return Err(font_data_error("font-head", source_offset=table.offset))
  }
  if index_to_loc_format != 0 && index_to_loc_format != 1 {
    let source_offset = match @checked.checked_add(table.offset, 50UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return Err(font_data_error("font-index-to-loc-format", source_offset~))
  }
  Ok({ units_per_em, x_min, y_min, x_max, y_max, index_to_loc_format })
}

///|
fn font_decode_maxp(
  table : TableWindow,
  limits : FontLimits,
) -> Result[MaxpFacts, @error.CoreError] {
  match font_table_exact_length(table, 32UL, "font-maxp") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let version = match read_u32(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let num_glyphs = match read_u16(table.view, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if version != 0x00010000UL || num_glyphs == 0UL {
    return Err(font_data_error("font-maxp", source_offset=table.offset))
  }
  if num_glyphs > limits.max_glyphs() {
    return Err(font_limit_error("max-glyphs", num_glyphs, limits.max_glyphs()))
  }
  Ok({ num_glyphs, })
}

///|
fn font_decode_hhea(
  table : TableWindow,
  maxp : MaxpFacts,
) -> Result[HheaFacts, @error.CoreError] {
  match font_table_exact_length(table, 36UL, "font-hhea") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let version = match read_u32(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ascent = match read_i16(table.view, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let descent = match read_i16(table.view, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let line_gap = match read_i16(table.view, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for reserved in [24UL, 26UL, 28UL, 30UL] {
    let value = match read_i16(table.view, reserved) {
      Err(error) => return Err(error)
      Ok(result) => result
    }
    if value != 0 {
      return Err(font_data_error("font-hhea", source_offset=table.offset))
    }
  }
  let metric_data_format = match read_i16(table.view, 32UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let number_of_h_metrics = match read_u16(table.view, 34UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if version != 0x00010000UL ||
    metric_data_format != 0 ||
    number_of_h_metrics == 0UL ||
    number_of_h_metrics > maxp.num_glyphs {
    return Err(font_data_error("font-hhea", source_offset=table.offset))
  }
  Ok({ ascent, descent, line_gap, number_of_h_metrics })
}

///|
fn font_os2_required_length(
  version : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match version {
    0UL => Ok(78UL)
    1UL => Ok(86UL)
    2UL..=4UL => Ok(96UL)
    5UL => Ok(100UL)
    _ => Err(font_data_error("font-os2"))
  }
}

///|
fn font_decode_os2(table : TableWindow) -> Result[Os2Facts, @error.CoreError] {
  match font_table_min_length(table, 2UL, "font-os2") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let version = match read_u16(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let required = match font_os2_required_length(version) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_table_min_length(table, required, "font-os2") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let typo_ascent = match read_i16(table.view, 68UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let typo_descent = match read_i16(table.view, 70UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let typo_line_gap = match read_i16(table.view, 72UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ typo_ascent, typo_descent, typo_line_gap })
}

///|
fn font_cmap_subtable_length(
  table : TableWindow,
  offset : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let remaining = match @checked.checked_sub(table.length_value, offset) {
    Err(_) => return Err(font_data_error("font-cmap-envelope"))
    Ok(value) => value
  }
  if remaining < 4UL {
    return Err(font_data_error("font-cmap-envelope"))
  }
  let format = match read_u16(table.view, offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match format {
    4UL => {
      if remaining < 16UL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      let length_field = match @checked.checked_add(offset, 2UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let length = match read_u16(table.view, length_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let seg_count_field = match @checked.checked_add(offset, 6UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let seg_count_x2 = match read_u16(table.view, seg_count_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if seg_count_x2 == 0UL || seg_count_x2 % 2UL != 0UL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      let seg_count = seg_count_x2 / 2UL
      let arrays_size = match @checked.checked_mul(seg_count, 8UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let minimum = match @checked.checked_add(16UL, arrays_size) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if length < minimum || length > remaining || length % 2UL != 0UL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      let code_array_size = match @checked.checked_mul(seg_count, 2UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let reserved_delta = match @checked.checked_add(14UL, code_array_size) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let reserved_field = match @checked.checked_add(offset, reserved_delta) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let reserved = match read_u16(table.view, reserved_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let final_segment_delta = match
        @checked.checked_mul(
          match @checked.checked_sub(seg_count, 1UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
          2UL,
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let final_end_code = match
        @checked.checked_add(
          offset,
          match @checked.checked_add(14UL, final_segment_delta) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let start_codes = match @checked.checked_add(reserved_field, 2UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let final_start_code = match
        @checked.checked_add(start_codes, final_segment_delta) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let end_sentinel = match read_u16(table.view, final_end_code) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let start_sentinel = match read_u16(table.view, final_start_code) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if reserved != 0UL ||
        end_sentinel != 0xFFFFUL ||
        start_sentinel != 0xFFFFUL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      Ok(length)
    }
    12UL => {
      if remaining < 16UL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      let reserved_field = match @checked.checked_add(offset, 2UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let reserved = match read_u16(table.view, reserved_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if reserved != 0UL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      let length_field = match @checked.checked_add(offset, 4UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let length = match read_u32(table.view, length_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let groups_field = match @checked.checked_add(offset, 12UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let groups = match read_u32(table.view, groups_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let group_bytes = match @checked.checked_mul(groups, 12UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let expected = match @checked.checked_add(16UL, group_bytes) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if length != expected || length > remaining {
        return Err(font_data_error("font-cmap-envelope"))
      }
      Ok(length)
    }
    _ => return Err(font_data_error("font-cmap-envelope"))
  }
}

///|
fn font_admit_cmap_envelope(
  table : TableWindow,
  limits : FontLimits,
) -> Result[CmapEnvelope, @error.CoreError] {
  match font_table_min_length(table, 4UL, "font-cmap-envelope") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let version = match read_u16(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let record_count = match read_u16(table.view, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if version != 0UL {
    return Err(
      font_data_error("font-cmap-envelope", source_offset=table.offset),
    )
  }
  if record_count == 0UL {
    return Err(
      font_data_error("font-cmap-envelope", source_offset=table.offset),
    )
  }
  if record_count > limits.max_cmap_records() {
    return Err(
      font_limit_error(
        "max-cmap-records",
        record_count,
        limits.max_cmap_records(),
      ),
    )
  }
  let record_bytes = match @checked.checked_mul(record_count, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let records_end = match @checked.checked_add(4UL, record_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if records_end > table.length_value {
    return Err(font_data_error("font-cmap-envelope"))
  }
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
    let length = match font_cmap_subtable_length(table, subtable) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end = match @checked.checked_add(subtable, length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if end > table.length_value {
      return Err(font_data_error("font-cmap-envelope"))
    }
    index = index + 1UL
  }
  Ok({ record_count, })
}

///|
fn font_admit_name_envelope(
  table : TableWindow,
  limits : FontLimits,
) -> Result[Unit, @error.CoreError] {
  match font_table_min_length(table, 6UL, "font-name-envelope") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = match read_u16(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let record_count = match read_u16(table.view, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let storage = match read_u16(table.view, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if format > 1UL {
    return Err(font_data_error("font-name-envelope"))
  }
  if record_count > limits.max_name_records() {
    return Err(
      font_limit_error(
        "max-name-records",
        record_count,
        limits.max_name_records(),
      ),
    )
  }
  let records_bytes = match @checked.checked_mul(record_count, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let records_end = match @checked.checked_add(6UL, records_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if records_end > table.length_value ||
    storage < records_end ||
    storage > table.length_value {
    return Err(font_data_error("font-name-envelope"))
  }
  let language_count = if format == 1UL {
    let language_records_start = match @checked.checked_add(records_end, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if language_records_start > table.length_value {
      return Err(font_data_error("font-name-envelope"))
    }
    let count = match read_u16(table.view, records_end) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if count > limits.max_name_records() {
      return Err(
        font_limit_error("max-name-records", count, limits.max_name_records()),
      )
    }
    let language_bytes = match @checked.checked_mul(count, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let language_end = match
      @checked.checked_add(language_records_start, language_bytes) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if language_end > table.length_value || storage < language_end {
      return Err(font_data_error("font-name-envelope"))
    }
    count
  } else {
    0UL
  }
  let mut index = 0UL
  while index < record_count {
    let record = 6UL + index * 12UL
    let language_id = match read_u16(table.view, record + 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if language_id >= 0x8000UL {
      let language_index = match @checked.checked_sub(language_id, 0x8000UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if format == 0UL || language_index >= language_count {
        return Err(font_data_error("font-name-envelope"))
      }
    }
    let length = match read_u16(table.view, record + 8UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let relative = match read_u16(table.view, record + 10UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let start = match @checked.checked_add(storage, relative) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end = match @checked.checked_add(start, length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if end > table.length_value {
      return Err(font_data_error("font-name-envelope"))
    }
    index = index + 1UL
  }
  if format == 1UL {
    let language_records_start = match @checked.checked_add(records_end, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let mut language_index = 0UL
    while language_index < language_count {
      let record_delta = match @checked.checked_mul(language_index, 4UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let record = match
        @checked.checked_add(language_records_start, record_delta) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let length = match read_u16(table.view, record) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let relative_field = match @checked.checked_add(record, 2UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let relative = match read_u16(table.view, relative_field) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let start = match @checked.checked_add(storage, relative) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let end = match @checked.checked_add(start, length) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if end > table.length_value {
        return Err(font_data_error("font-name-envelope"))
      }
      language_index = language_index + 1UL
    }
  }
  Ok(())
}

///|
fn font_validate_post2_names(
  table : TableWindow,
  glyph_count : UInt64,
  names_start : UInt64,
) -> Result[Unit, @error.CoreError] {
  let mut custom_count = 0UL
  let mut glyph = 0UL
  while glyph < glyph_count {
    let index_delta = match @checked.checked_mul(glyph, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let field = match @checked.checked_add(34UL, index_delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let name_index = match read_u16(table.view, field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if name_index > 32767UL {
      return Err(font_data_error("font-post-envelope"))
    }
    if name_index >= 258UL {
      let referenced_count = match @checked.checked_sub(name_index, 257UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if referenced_count > custom_count {
        custom_count = referenced_count
      }
    }
    glyph = glyph + 1UL
  }
  let mut cursor = names_start
  let mut custom = 0UL
  while custom < custom_count {
    if cursor >= table.length_value {
      return Err(font_data_error("font-post-envelope"))
    }
    let length = match read_u8(table.view, cursor) {
      Err(error) => return Err(error)
      Ok(value) => value.to_uint64()
    }
    let payload_start = match @checked.checked_add(cursor, 1UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    cursor = match @checked.checked_add(payload_start, length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if cursor > table.length_value {
      return Err(font_data_error("font-post-envelope"))
    }
    custom = custom + 1UL
  }
  if cursor != table.length_value {
    Err(font_data_error("font-post-envelope"))
  } else {
    Ok(())
  }
}

///|
fn font_validate_post25_offsets(
  table : TableWindow,
  glyph_count : UInt64,
) -> Result[Unit, @error.CoreError] {
  let mut glyph = 0UL
  while glyph < glyph_count {
    let field = match @checked.checked_add(34UL, glyph) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let encoded = match read_u8(table.view, field) {
      Err(error) => return Err(error)
      Ok(value) => value.to_uint64()
    }
    let delta = if encoded >= 128UL {
      encoded.to_int() - 256
    } else {
      encoded.to_int()
    }
    let standard_index = glyph.to_int() + delta
    if standard_index < 0 || standard_index > 257 {
      return Err(font_data_error("font-post-envelope"))
    }
    glyph = glyph + 1UL
  }
  Ok(())
}

///|
fn font_admit_post_envelope(
  table : TableWindow,
  maxp : MaxpFacts,
  limits : FontLimits,
) -> Result[Unit, @error.CoreError] {
  match font_table_min_length(table, 32UL, "font-post-envelope") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let version = match read_u32(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match version {
    0x00010000UL | 0x00030000UL =>
      font_table_exact_length(table, 32UL, "font-post-envelope")
    0x00020000UL => {
      match font_table_min_length(table, 34UL, "font-post-envelope") {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      let glyph_count = match read_u16(table.view, 32UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if glyph_count != maxp.num_glyphs {
        return Err(font_data_error("font-post-envelope"))
      }
      let required = match
        @checked.checked_add(
          34UL,
          match @checked.checked_mul(glyph_count, 2UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if required > table.length_value {
        return Err(font_data_error("font-post-envelope"))
      }
      let custom_bytes = table.length_value - required
      if custom_bytes > limits.max_post_name_bytes() {
        return Err(
          font_limit_error(
            "max-post-name-bytes",
            custom_bytes,
            limits.max_post_name_bytes(),
          ),
        )
      }
      font_validate_post2_names(table, glyph_count, required)
    }
    0x00025000UL => {
      match font_table_min_length(table, 34UL, "font-post-envelope") {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      let glyph_count = match read_u16(table.view, 32UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if glyph_count != maxp.num_glyphs {
        return Err(font_data_error("font-post-envelope"))
      }
      let required = match @checked.checked_add(34UL, glyph_count) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      match font_table_exact_length(table, required, "font-post-envelope") {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      font_validate_post25_offsets(table, glyph_count)
    }
    _ => Err(font_data_error("font-post-envelope"))
  }
}

///|
fn font_admit_required_tables(
  directory : DirectoryFacts,
  limits : FontLimits,
) -> Result[RequiredTableFacts, @error.CoreError] {
  let head_table = match font_table_window(directory, 0x68656164UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let maxp_table = match font_table_window(directory, 0x6D617870UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let hhea_table = match font_table_window(directory, 0x68686561UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let os2_table = match font_table_window(directory, 0x4F532F32UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let cmap_table = match font_table_window(directory, 0x636D6170UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let name_table = match font_table_window(directory, 0x6E616D65UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let post_table = match font_table_window(directory, 0x706F7374UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for tag in [0x676C7966UL, 0x686D7478UL, 0x6C6F6361UL] {
    match font_table_window(directory, tag) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let head = match font_decode_head(head_table) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let maxp = match font_decode_maxp(maxp_table, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let hhea = match font_decode_hhea(hhea_table, maxp) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let os2 = match font_decode_os2(os2_table) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let cmap = match font_admit_cmap_envelope(cmap_table, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_admit_name_envelope(name_table, limits) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_admit_post_envelope(post_table, maxp, limits) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({ head, maxp, hhea, os2, cmap })
}
