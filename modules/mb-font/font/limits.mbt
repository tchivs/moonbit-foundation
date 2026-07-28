///|
/// Explicit caller-owned ceilings for one font admission operation.
///
/// These semantic limits intersect the authoritative caller-owned `Budget`;
/// they do not replace it. Callers must not concurrently mutate one shared
/// `Budget` and expect this value to provide synchronization.
pub struct FontLimits {
  priv max_source_bytes_value : UInt64
  priv max_tables_value : UInt64
  priv max_table_bytes_value : UInt64
  priv max_glyphs_value : UInt64
  priv max_name_records_value : UInt64
  priv max_cmap_records_value : UInt64
  priv max_kern_subtables_value : UInt64
  priv max_kern_pairs_value : UInt64
  priv max_outline_points_value : UInt64
  priv max_outline_contours_value : UInt64
  priv max_outline_components_value : UInt64
  priv max_outline_instruction_bytes_value : UInt64
  priv max_post_name_bytes_value : UInt64
  priv max_work_value : UInt64
}

///|
fn invalid_font_limit(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="font-limits-new",
    requested=0UL,
    limit=1UL,
    context~,
  )
}

///|
/// Construct explicit non-zero semantic ceilings for one admission operation.
pub fn FontLimits::new(
  max_source_bytes~ : UInt64,
  max_tables~ : UInt64,
  max_table_bytes~ : UInt64,
  max_glyphs~ : UInt64,
  max_name_records~ : UInt64,
  max_cmap_records~ : UInt64,
  max_kern_subtables~ : UInt64,
  max_kern_pairs~ : UInt64,
  max_outline_points~ : UInt64,
  max_outline_contours~ : UInt64,
  max_outline_components~ : UInt64,
  max_outline_instruction_bytes~ : UInt64,
  max_post_name_bytes~ : UInt64,
  max_work~ : UInt64,
) -> Result[FontLimits, @error.CoreError] {
  if max_source_bytes == 0UL {
    return Err(invalid_font_limit("max-source-bytes"))
  }
  if max_tables == 0UL {
    return Err(invalid_font_limit("max-tables"))
  }
  if max_table_bytes == 0UL {
    return Err(invalid_font_limit("max-table-bytes"))
  }
  if max_glyphs == 0UL {
    return Err(invalid_font_limit("max-glyphs"))
  }
  if max_name_records == 0UL {
    return Err(invalid_font_limit("max-name-records"))
  }
  if max_cmap_records == 0UL {
    return Err(invalid_font_limit("max-cmap-records"))
  }
  if max_kern_subtables == 0UL {
    return Err(invalid_font_limit("max-kern-subtables"))
  }
  if max_kern_pairs == 0UL {
    return Err(invalid_font_limit("max-kern-pairs"))
  }
  if max_outline_points == 0UL {
    return Err(invalid_font_limit("max-outline-points"))
  }
  if max_outline_contours == 0UL {
    return Err(invalid_font_limit("max-outline-contours"))
  }
  if max_outline_components == 0UL {
    return Err(invalid_font_limit("max-outline-components"))
  }
  if max_outline_instruction_bytes == 0UL {
    return Err(invalid_font_limit("max-outline-instruction-bytes"))
  }
  if max_post_name_bytes == 0UL {
    return Err(invalid_font_limit("max-post-name-bytes"))
  }
  if max_work == 0UL {
    return Err(invalid_font_limit("max-work"))
  }
  Ok({
    max_source_bytes_value: max_source_bytes,
    max_tables_value: max_tables,
    max_table_bytes_value: max_table_bytes,
    max_glyphs_value: max_glyphs,
    max_name_records_value: max_name_records,
    max_cmap_records_value: max_cmap_records,
    max_kern_subtables_value: max_kern_subtables,
    max_kern_pairs_value: max_kern_pairs,
    max_outline_points_value: max_outline_points,
    max_outline_contours_value: max_outline_contours,
    max_outline_components_value: max_outline_components,
    max_outline_instruction_bytes_value: max_outline_instruction_bytes,
    max_post_name_bytes_value: max_post_name_bytes,
    max_work_value: max_work,
  })
}

///|
pub fn FontLimits::max_source_bytes(self : FontLimits) -> UInt64 {
  self.max_source_bytes_value
}

///|
pub fn FontLimits::max_tables(self : FontLimits) -> UInt64 {
  self.max_tables_value
}

///|
pub fn FontLimits::max_table_bytes(self : FontLimits) -> UInt64 {
  self.max_table_bytes_value
}

///|
pub fn FontLimits::max_glyphs(self : FontLimits) -> UInt64 {
  self.max_glyphs_value
}

///|
pub fn FontLimits::max_name_records(self : FontLimits) -> UInt64 {
  self.max_name_records_value
}

///|
pub fn FontLimits::max_cmap_records(self : FontLimits) -> UInt64 {
  self.max_cmap_records_value
}

///|
pub fn FontLimits::max_kern_subtables(self : FontLimits) -> UInt64 {
  self.max_kern_subtables_value
}

///|
pub fn FontLimits::max_kern_pairs(self : FontLimits) -> UInt64 {
  self.max_kern_pairs_value
}

///|
pub fn FontLimits::max_outline_points(self : FontLimits) -> UInt64 {
  self.max_outline_points_value
}

///|
pub fn FontLimits::max_outline_contours(self : FontLimits) -> UInt64 {
  self.max_outline_contours_value
}

///|
pub fn FontLimits::max_outline_components(self : FontLimits) -> UInt64 {
  self.max_outline_components_value
}

///|
pub fn FontLimits::max_outline_instruction_bytes(self : FontLimits) -> UInt64 {
  self.max_outline_instruction_bytes_value
}

///|
pub fn FontLimits::max_post_name_bytes(self : FontLimits) -> UInt64 {
  self.max_post_name_bytes_value
}

///|
pub fn FontLimits::max_work(self : FontLimits) -> UInt64 {
  self.max_work_value
}

///|
/// Private structural ceilings for one static CFF1 admission transaction.
///
/// These values are derived only from the already-compatible, non-zero
/// `FontLimits` contract and closed CFF1 format maxima. They intentionally do
/// not add a second public limits surface.
#warnings("-7")
priv struct CffStructuralLimits {
  max_index_entries : UInt64
  max_dict_units : UInt64
  max_charset_entries : UInt64
  max_encoding_entries : UInt64
  max_fd_ranges : UInt64
  max_sid_cid_lookups : UInt64
  max_retained_bytes : UInt64
  max_work : UInt64
}

///|
fn cff_structural_limits(
  limits : FontLimits,
) -> Result[CffStructuralLimits, @error.CoreError] {
  let max_index_entries = if limits.max_glyphs() > limits.max_name_records() {
    limits.max_glyphs()
  } else {
    limits.max_name_records()
  }
  // One byte code can name at most 256 Encoding entries. Supplements remain
  // bounded by the glyph/SID domain and are charged as SID lookups.
  let max_encoding_entries = if limits.max_glyphs() > 256UL {
    256UL
  } else {
    limits.max_glyphs()
  }
  let retained_descriptors = match
    @checked.checked_mul(limits.max_glyphs(), 96UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let retained_ranges = match
    @checked.checked_mul(limits.max_glyphs(), 64UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let retained_offsets = match
    @checked.checked_mul(max_index_entries, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let max_retained_bytes = match
    @checked.checked_add(
      retained_descriptors,
      match @checked.checked_add(retained_ranges, retained_offsets) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    max_index_entries,
    max_dict_units: limits.max_work(),
    max_charset_entries: limits.max_glyphs(),
    max_encoding_entries,
    max_fd_ranges: limits.max_glyphs(),
    max_sid_cid_lookups: limits.max_work(),
    max_retained_bytes,
    max_work: limits.max_work(),
  })
}
