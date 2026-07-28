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
#warnings("-7")
priv struct MaxpFacts {
  num_glyphs : UInt64
  max_points : UInt64
  max_contours : UInt64
  max_composite_points : UInt64
  max_composite_contours : UInt64
  max_size_of_instructions : UInt64
  max_component_elements : UInt64
  max_component_depth : UInt64
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
  lookup : CmapLookupFacts
}

///|
priv struct CmapSubtableFacts {
  format : UInt64
  length : UInt64
  language : UInt64
  body_records : UInt64
}

///|
/// Checked common facts for every cmap record before format-specific decoding.
priv struct CmapSubtableEnvelope {
  format : UInt64
  length : UInt64
}

///|
priv struct CmapAdmissionWork {
  body_records : UInt64
  format4_discovery_work : UInt64
  search_work : UInt64
  mapping_work : UInt64
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
  kern : KernState
}

///|
#warnings("-7")
priv struct FontAdmissionPlan {
  charge : @budget.ResourceCharge
  kern : KernState
  exact_work : UInt64
  standalone_remaining_work : UInt64
}

///|
#warnings("-6")
priv enum FontAdmissionCommitMode {
  StandaloneIncremental
  CollectionDeferred
}

///|
priv struct FontAdmissionLedger {
  caller : @budget.Budget
  mode : FontAdmissionCommitMode
  mut staged_work : UInt64
}

///|
fn FontAdmissionLedger::new(
  caller : @budget.Budget,
  mode : FontAdmissionCommitMode,
) -> FontAdmissionLedger {
  { caller, mode, staged_work: 0UL }
}

///|
fn FontAdmissionLedger::admit_stage(
  self : FontAdmissionLedger,
  max_work : UInt64,
  semantic_work : UInt64,
  budget_base_work : UInt64,
  stage_work : UInt64,
) -> Result[Unit, @error.CoreError] {
  if semantic_work > max_work {
    return Err(font_limit_error("max-work", semantic_work, max_work))
  }
  let next_staged = match @checked.checked_add(self.staged_work, stage_work) {
    Err(_) =>
      return Err(
        font_limit_error(
          "max-work",
          18446744073709551615UL,
          max_work,
        ),
      )
    Ok(value) => value
  }
  let requested_work = match self.mode {
    FontAdmissionCommitMode::StandaloneIncremental =>
      match @checked.checked_add(budget_base_work, stage_work) {
        Err(_) =>
          return Err(
            font_limit_error(
              "max-work",
              18446744073709551615UL,
              max_work,
            ),
          )
        Ok(value) => value
      }
    FontAdmissionCommitMode::CollectionDeferred =>
      match @checked.checked_add(budget_base_work, next_staged) {
        Err(_) =>
          return Err(
            font_limit_error(
              "max-work",
              18446744073709551615UL,
              max_work,
            ),
          )
        Ok(value) => value
      }
  }
  match
    self.caller.preflight(
      @budget.ResourceCharge::new(
        bytes=0UL,
        allocations=0UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        work=requested_work,
      ),
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match self.mode {
    FontAdmissionCommitMode::StandaloneIncremental =>
      match
        self.caller.charge(
          @budget.ResourceCharge::new(
            bytes=0UL,
            allocations=0UL,
            allocation_size=0UL,
            width=0UL,
            height=0UL,
            pixels=0UL,
            work=stage_work,
          ),
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    FontAdmissionCommitMode::CollectionDeferred => ()
  }
  self.staged_work = next_staged
  Ok(())
}

///|
fn font_admission_charge(
  directory : DirectoryFacts,
  limits : FontLimits,
  budget : @budget.Budget,
  commit_mode : FontAdmissionCommitMode,
) -> Result[FontAdmissionPlan, @error.CoreError] {
  let ledger = FontAdmissionLedger::new(budget, commit_mode)
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
  let table_count = directory.tables.length().to_uint64()
  // The initial preflight authorizes the directory work plus four required
  // count lookups and the optional kern lookup. Carry that exact prefix into
  // the cumulative declared-work preflights below.
  let precharge_lookup_work = match @checked.checked_mul(table_count, 5UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let cmap_discovery_base_work = match
    @checked.checked_add(directory.work, precharge_lookup_work) {
    Err(error) => return Err(error)
    Ok(value) => value
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
  // Count discovery is intentionally separate from semantic validation: it
  // determines the exact later scan work before the one authoritative charge.
  let cmap_work = match
    font_cmap_declared_work_with_ledger(
      cmap_table,
      cmap_records,
      ledger,
      limits.max_work(),
      cmap_discovery_base_work,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }

  let kern_base_work = match
    @checked.checked_add(
      cmap_discovery_base_work,
      match
        @checked.checked_add(cmap_records, cmap_work.format4_discovery_work) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // Cmap record and format-4 discovery scans have already consumed their
  // declared work. Only the uncharged discovery prefix remains relevant to
  // the shared budget, while kern still compares its cumulative work against
  // the full semantic max_work total.
  let kern_budget_base_work = cmap_discovery_base_work
  let kern = match
    font_admit_kern_bounded(
      font_optional_table_window(directory, 0x6B65726EUL),
      num_glyphs,
      limits,
      ledger,
      kern_base_work,
      kern_budget_base_work,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
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
  if post_name_bytes > limits.max_post_name_bytes() {
    return Err(
      font_limit_error(
        "max-post-name-bytes",
        post_name_bytes,
        limits.max_post_name_bytes(),
      ),
    )
  }

  let loca_entries = match @checked.checked_add(num_glyphs, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let glyph_work = match @checked.checked_add(loca_entries, num_glyphs) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // Five count-discovery lookups, ten presence lookups, ten table-admission
  // lookups, and three metric-index lookups each scan at most every record.
  let lookup_work = match @checked.checked_mul(table_count, 28UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // Profile validation and the per-table checksum loop each visit every table.
  let table_iteration_work = match @checked.checked_mul(table_count, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut work = directory.work
  for
    count in [
      lookup_work,
      table_iteration_work,
      glyph_work,
      cmap_records,
      name_records,
      // The first cmap count covers the pre-charge subtable-count discovery;
      // the second covers the post-charge encoding-record validation loop.
      cmap_records,
      cmap_work.body_records,
      cmap_work.format4_discovery_work,
      cmap_work.search_work,
      cmap_work.mapping_work,
      language_records,
      post_glyph_records,
      post_name_bytes,
      kern.subtable_work,
      kern.pair_work,
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
    font_directory_allocation_size(table_count) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let allocation_size = if directory_allocation_size > loca_allocation_size {
    directory_allocation_size
  } else {
    loca_allocation_size
  }
  let remaining_work = match @checked.checked_sub(work, ledger.staged_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charge_work = match commit_mode {
    FontAdmissionCommitMode::StandaloneIncremental => remaining_work
    FontAdmissionCommitMode::CollectionDeferred => work
  }
  Ok({
    charge: @budget.ResourceCharge::new(
      bytes=directory.source.length(),
      allocations=3UL,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=charge_work,
    ),
    kern: kern.state,
    exact_work: work,
    standalone_remaining_work: remaining_work,
  })
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
  let glyph_data_format = match read_i16(table.view, 52UL) {
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
  if glyph_data_format != 0 {
    let source_offset = match @checked.checked_add(table.offset, 52UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    return Err(font_data_error("font-glyph-data-format", source_offset~))
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
  let max_points = match read_u16(table.view, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_contours = match read_u16(table.view, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_composite_points = match read_u16(table.view, 10UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_composite_contours = match read_u16(table.view, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_size_of_instructions = match read_u16(table.view, 26UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_component_elements = match read_u16(table.view, 28UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_component_depth = match read_u16(table.view, 30UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    num_glyphs,
    max_points,
    max_contours,
    max_composite_points,
    max_composite_contours,
    max_size_of_instructions,
    max_component_elements,
    max_component_depth,
  })
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
fn font_cmap_subtable_envelope(
  table : TableWindow,
  offset : UInt64,
) -> Result[CmapSubtableEnvelope, @error.CoreError] {
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
      if length < 16UL || length > remaining || length % 2UL != 0UL {
        return Err(font_data_error("font-cmap-envelope"))
      }
      Ok({ format, length })
    }
    6UL => {
      if remaining < 10UL {
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
      let entry_count_field = match @checked.checked_add(offset, 8UL) {
        Err(_) => return Err(font_data_error("font-cmap-envelope"))
        Ok(value) => value
      }
      let entry_count = match read_u16(table.view, entry_count_field) {
        Err(_) => return Err(font_data_error("font-cmap-envelope"))
        Ok(value) => value
      }
      let glyph_bytes = match @checked.checked_mul(entry_count, 2UL) {
        Err(_) => return Err(font_data_error("font-cmap-envelope"))
        Ok(value) => value
      }
      let expected_length = match @checked.checked_add(10UL, glyph_bytes) {
        Err(_) => return Err(font_data_error("font-cmap-envelope"))
        Ok(value) => value
      }
      if length != expected_length || length > remaining {
        return Err(font_data_error("font-cmap-envelope"))
      }
      Ok({ format, length })
    }
    12UL => {
      if remaining < 16UL {
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
      if length < 16UL || length > remaining {
        return Err(font_data_error("font-cmap-envelope"))
      }
      Ok({ format, length })
    }
    _ => Err(font_data_error("font-cmap-envelope"))
  }
}

///|
fn font_cmap_subtable_facts(
  table : TableWindow,
  offset : UInt64,
) -> Result[CmapSubtableFacts, @error.CoreError] {
  let envelope = match font_cmap_subtable_envelope(table, offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let format = envelope.format
  let length = envelope.length
  match format {
    4UL => {
      let language_field = match @checked.checked_add(offset, 4UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let language = match read_u16(table.view, language_field) {
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
      if length < minimum {
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
      Ok({ format, length, language, body_records: seg_count })
    }
    12UL => {
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
      let language_field = match @checked.checked_add(offset, 8UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let language = match read_u32(table.view, language_field) {
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
      if length != expected {
        return Err(font_data_error("font-cmap-envelope"))
      }
      Ok({ format, length, language, body_records: groups })
    }
    _ => return Err(font_data_error("font-cmap-envelope"))
  }
}

///|
fn font_cmap_search_selector(seg_count : UInt64) -> UInt64 {
  if seg_count >= 16384UL {
    14UL
  } else if seg_count >= 8192UL {
    13UL
  } else if seg_count >= 4096UL {
    12UL
  } else if seg_count >= 2048UL {
    11UL
  } else if seg_count >= 1024UL {
    10UL
  } else if seg_count >= 512UL {
    9UL
  } else if seg_count >= 256UL {
    8UL
  } else if seg_count >= 128UL {
    7UL
  } else if seg_count >= 64UL {
    6UL
  } else if seg_count >= 32UL {
    5UL
  } else if seg_count >= 16UL {
    4UL
  } else if seg_count >= 8UL {
    3UL
  } else if seg_count >= 4UL {
    2UL
  } else if seg_count >= 2UL {
    1UL
  } else {
    0UL
  }
}

///|
fn font_cmap_format4_mapping_work(
  table : TableWindow,
  offset : UInt64,
  facts : CmapSubtableFacts,
) -> Result[UInt64, @error.CoreError] {
  let code_array_size = match @checked.checked_mul(facts.body_records, 2UL) {
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
  let mut mapping_work = 0UL
  let mut previous_end = 0UL
  let mut index = 0UL
  while index < facts.body_records {
    let delta = match @checked.checked_mul(index, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end_code = match read_u16(table.view, end_codes + delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let start_code = match read_u16(table.view, start_codes + delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if start_code > end_code ||
      (index > 0UL && (end_code <= previous_end || start_code <= previous_end)) {
      return Err(font_data_error("font-cmap-envelope"))
    }
    let span = match
      @checked.checked_add(
        match @checked.checked_sub(end_code, start_code) {
          Err(_) => return Err(font_data_error("font-cmap-envelope"))
          Ok(value) => value
        },
        1UL,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    mapping_work = match @checked.checked_add(mapping_work, span) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    previous_end = end_code
    index = index + 1UL
  }
  Ok(mapping_work)
}

///|
fn font_cmap_declared_work_with_ledger(
  table : TableWindow,
  record_count : UInt64,
  ledger : FontAdmissionLedger,
  max_work : UInt64,
  discovery_base_work : UInt64,
) -> Result[CmapAdmissionWork, @error.CoreError] {
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
  let record_discovery_work = match
    @checked.checked_add(discovery_base_work, record_count) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match
    ledger.admit_stage(
      max_work,
      record_discovery_work,
      discovery_base_work,
      record_count,
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut body_records = 0UL
  let mut format4_discovery_work = 0UL
  let mut search_work = 0UL
  let mut mapping_work = 0UL
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
    let envelope = match font_cmap_subtable_envelope(table, subtable) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let end = match @checked.checked_add(subtable, envelope.length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if end > table.length_value {
      return Err(font_data_error("font-cmap-envelope"))
    }
    if envelope.format == 4UL || envelope.format == 12UL {
      let facts = match font_cmap_subtable_facts(table, subtable) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      body_records = match
        @checked.checked_add(body_records, facts.body_records) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if facts.format == 4UL {
        let next_discovery_work = match
          @checked.checked_add(format4_discovery_work, facts.body_records) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let preflight_work = match
          @checked.checked_add(record_discovery_work, next_discovery_work) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        if preflight_work > max_work {
          return Err(font_limit_error("max-work", preflight_work, max_work))
        }
        match
          ledger.admit_stage(
            max_work,
            preflight_work,
            discovery_base_work,
            facts.body_records,
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        format4_discovery_work = next_discovery_work
        search_work = match
          @checked.checked_add(
            search_work,
            font_cmap_search_selector(facts.body_records),
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        mapping_work = match
          @checked.checked_add(
            mapping_work,
            match font_cmap_format4_mapping_work(table, subtable, facts) {
              Err(error) => return Err(error)
              Ok(value) => value
            },
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      }
    }
    index = index + 1UL
  }
  Ok({ body_records, format4_discovery_work, search_work, mapping_work })
}

///|
#warnings("-1")
fn font_cmap_declared_work(
  table : TableWindow,
  record_count : UInt64,
  budget : @budget.Budget,
  max_work : UInt64,
  discovery_base_work : UInt64,
) -> Result[CmapAdmissionWork, @error.CoreError] {
  font_cmap_declared_work_with_ledger(
    table,
    record_count,
    FontAdmissionLedger::new(
      budget,
      FontAdmissionCommitMode::StandaloneIncremental,
    ),
    max_work,
    discovery_base_work,
  )
}

///|
fn font_cmap_search_facts(seg_count : UInt64) -> (UInt64, UInt64, UInt64) {
  let mut power = 1UL
  let mut selector = 0UL
  while power <= seg_count / 2UL {
    power = power * 2UL
    selector = selector + 1UL
  }
  let search_range = power * 2UL
  (search_range, selector, seg_count * 2UL - search_range)
}

///|
fn font_validate_cmap_subtable(
  table : TableWindow,
  offset : UInt64,
  glyph_count : UInt64,
) -> Result[CmapSubtableFacts, @error.CoreError] {
  let facts = match font_cmap_subtable_facts(table, offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let subtable_end = match @checked.checked_add(offset, facts.length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match facts.format {
    4UL => {
      let search_range = match read_u16(table.view, offset + 8UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let entry_selector = match read_u16(table.view, offset + 10UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let range_shift = match read_u16(table.view, offset + 12UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let (expected_search, expected_selector, expected_shift) = font_cmap_search_facts(
        facts.body_records,
      )
      if search_range != expected_search ||
        entry_selector != expected_selector ||
        range_shift != expected_shift {
        return Err(font_data_error("font-cmap-envelope"))
      }
      let code_array_size = match
        @checked.checked_mul(facts.body_records, 2UL) {
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
      let glyph_array_start = match
        @checked.checked_add(id_range_offsets, code_array_size) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let mut previous_end = 0UL
      let mut index = 0UL
      while index < facts.body_records {
        let delta = match @checked.checked_mul(index, 2UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let end_code = match read_u16(table.view, end_codes + delta) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let start_code = match read_u16(table.view, start_codes + delta) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        if start_code > end_code ||
          (
            index > 0UL &&
            (end_code <= previous_end || start_code <= previous_end)
          ) {
          return Err(font_data_error("font-cmap-envelope"))
        }
        let range_field = id_range_offsets + delta
        let range_offset = match read_u16(table.view, range_field) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let id_delta = match read_u16(table.view, id_deltas + delta) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        if range_offset == 0UL {
          let mut code = start_code
          while code <= end_code {
            let mapped = (code + id_delta) & 0xFFFFUL
            if mapped != 0UL && mapped >= glyph_count {
              return Err(font_data_error("font-cmap-envelope"))
            }
            code = code + 1UL
          }
        } else {
          if range_offset % 2UL != 0UL {
            return Err(font_data_error("font-cmap-envelope"))
          }
          let first_glyph = match
            @checked.checked_add(range_field, range_offset) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
          let range_length = match @checked.checked_sub(end_code, start_code) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
          let range_bytes = match @checked.checked_mul(range_length, 2UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
          let last_glyph_end = match
            @checked.checked_add(
              match @checked.checked_add(first_glyph, range_bytes) {
                Err(error) => return Err(error)
                Ok(value) => value
              },
              2UL,
            ) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
          if first_glyph < glyph_array_start || last_glyph_end > subtable_end {
            return Err(font_data_error("font-cmap-envelope"))
          }
          let mut code = start_code
          while code <= end_code {
            let glyph_delta = match
              @checked.checked_mul(
                match @checked.checked_sub(code, start_code) {
                  Err(error) => return Err(error)
                  Ok(value) => value
                },
                2UL,
              ) {
              Err(error) => return Err(error)
              Ok(value) => value
            }
            let raw = match read_u16(table.view, first_glyph + glyph_delta) {
              Err(error) => return Err(error)
              Ok(value) => value
            }
            let mapped = if raw == 0UL {
              0UL
            } else {
              (raw + id_delta) & 0xFFFFUL
            }
            if mapped != 0UL && mapped >= glyph_count {
              return Err(font_data_error("font-cmap-envelope"))
            }
            code = code + 1UL
          }
        }
        previous_end = end_code
        index = index + 1UL
      }
    }
    12UL => {
      let groups_start = match @checked.checked_add(offset, 16UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let mut previous_end = 0UL
      let mut index = 0UL
      while index < facts.body_records {
        let group = match
          @checked.checked_add(
            groups_start,
            match @checked.checked_mul(index, 12UL) {
              Err(error) => return Err(error)
              Ok(value) => value
            },
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let start_code = match read_u32(table.view, group) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let end_code = match read_u32(table.view, group + 4UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let start_glyph = match read_u32(table.view, group + 8UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        if start_code > end_code ||
          end_code > 0x10FFFFUL ||
          (index > 0UL && start_code <= previous_end) {
          return Err(font_data_error("font-cmap-envelope"))
        }
        let final_glyph = match
          @checked.checked_add(
            start_glyph,
            match @checked.checked_sub(end_code, start_code) {
              Err(error) => return Err(error)
              Ok(value) => value
            },
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        if final_glyph >= glyph_count {
          return Err(font_data_error("font-cmap-envelope"))
        }
        previous_end = end_code
        index = index + 1UL
      }
    }
    _ => return Err(font_data_error("font-cmap-envelope"))
  }
  Ok(facts)
}

///|
fn font_cmap_domain_supported(
  _platform : UInt64,
  _encoding : UInt64,
  format : UInt64,
) -> Bool {
  format == 4UL || format == 12UL
}

///|
fn font_admit_cmap_envelope(
  table : TableWindow,
  maxp : MaxpFacts,
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
  let lookup = match
    font_admit_cmap_lookup(table, record_count, records_end, maxp) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ record_count, lookup })
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
  // The selected static profile permits duplicate logical keys, but every
  // record must preserve the canonical four-part nondecreasing order.
  let mut has_previous = false
  let mut previous_platform = 0UL
  let mut previous_encoding = 0UL
  let mut previous_language = 0UL
  let mut previous_name = 0UL
  let mut index = 0UL
  while index < record_count {
    let record = 6UL + index * 12UL
    let platform_id = match read_u16(table.view, record) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let encoding_id = match read_u16(table.view, record + 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let language_id = match read_u16(table.view, record + 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let name_id = match read_u16(table.view, record + 6UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if has_previous &&
      (
        platform_id < previous_platform ||
        (
          platform_id == previous_platform &&
          (
            encoding_id < previous_encoding ||
            (
              encoding_id == previous_encoding &&
              (
                language_id < previous_language ||
                (language_id == previous_language && name_id < previous_name)
              )
            )
          )
        )
      ) {
      return Err(font_data_error("font-name-envelope"))
    }
    if language_id >= 0x8000UL {
      if format == 1UL {
        let language_index = match @checked.checked_sub(language_id, 0x8000UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        if language_index >= language_count {
          return Err(font_data_error("font-name-envelope"))
        }
      } else if platform_id < 240UL || platform_id > 255UL {
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
    has_previous = true
    previous_platform = platform_id
    previous_encoding = encoding_id
    previous_language = language_id
    previous_name = name_id
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
    if length > 63UL {
      return Err(font_data_error("font-post-envelope"))
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
    let mut character = payload_start
    while character < cursor {
      let value = match read_u8(table.view, character) {
        Err(error) => return Err(error)
        Ok(byte) => byte.to_uint64()
      }
      if !((value >= 0x41UL && value <= 0x5AUL) ||
        (value >= 0x61UL && value <= 0x7AUL) ||
        (value >= 0x30UL && value <= 0x39UL) ||
        value == 0x2EUL ||
        value == 0x5FUL) {
        return Err(font_data_error("font-post-envelope"))
      }
      character = character + 1UL
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
    0x00010000UL => {
      if maxp.num_glyphs != 258UL {
        return Err(font_data_error("font-post-envelope"))
      }
      font_table_exact_length(table, 32UL, "font-post-envelope")
    }
    0x00030000UL => font_table_exact_length(table, 32UL, "font-post-envelope")
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
fn font_admit_required_tables_impl(
  directory : DirectoryFacts,
  limits : FontLimits,
  retained_kern : KernState?,
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
  let cmap = match font_admit_cmap_envelope(cmap_table, maxp, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let kern = match retained_kern {
    Some(value) => value
    None =>
      match
        font_admit_kern(
          font_optional_table_window(directory, 0x6B65726EUL),
          maxp.num_glyphs,
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
  }
  match font_admit_name_envelope(name_table, limits) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_admit_post_envelope(post_table, maxp, limits) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({ head, maxp, hhea, os2, cmap, kern })
}

///|
#warnings("-1")
fn font_admit_required_tables(
  directory : DirectoryFacts,
  limits : FontLimits,
) -> Result[RequiredTableFacts, @error.CoreError] {
  font_admit_required_tables_impl(directory, limits, None)
}

///|
fn font_admit_required_tables_with_kern(
  directory : DirectoryFacts,
  limits : FontLimits,
  kern : KernState,
) -> Result[RequiredTableFacts, @error.CoreError] {
  font_admit_required_tables_impl(directory, limits, Some(kern))
}
