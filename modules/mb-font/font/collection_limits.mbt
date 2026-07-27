///|
/// Explicit caller-owned ceilings for one font collection admission.
pub struct FontCollectionLimits {
  priv max_source_bytes_value : UInt64
  priv max_faces_value : UInt64
  priv max_tables_per_face_value : UInt64
  priv max_table_records_value : UInt64
  priv max_dsig_records_value : UInt64
  priv max_dsig_bytes_value : UInt64
  priv max_retained_bookkeeping_bytes_value : UInt64
  priv max_work_value : UInt64
}

///|
fn invalid_font_collection_limit(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="font-collection-limits-new",
    requested=0UL,
    limit=1UL,
    context~,
  )
}

///|
/// Construct the eight non-zero collection authority ceilings.
pub fn FontCollectionLimits::new(
  max_source_bytes~ : UInt64,
  max_faces~ : UInt64,
  max_tables_per_face~ : UInt64,
  max_table_records~ : UInt64,
  max_dsig_records~ : UInt64,
  max_dsig_bytes~ : UInt64,
  max_retained_bookkeeping_bytes~ : UInt64,
  max_work~ : UInt64,
) -> Result[FontCollectionLimits, @error.CoreError] {
  if max_source_bytes == 0UL {
    return Err(invalid_font_collection_limit("max-source-bytes"))
  }
  if max_faces == 0UL {
    return Err(invalid_font_collection_limit("max-faces"))
  }
  if max_tables_per_face == 0UL {
    return Err(invalid_font_collection_limit("max-tables-per-face"))
  }
  if max_table_records == 0UL {
    return Err(invalid_font_collection_limit("max-table-records"))
  }
  if max_dsig_records == 0UL {
    return Err(invalid_font_collection_limit("max-dsig-records"))
  }
  if max_dsig_bytes == 0UL {
    return Err(invalid_font_collection_limit("max-dsig-bytes"))
  }
  if max_retained_bookkeeping_bytes == 0UL {
    return Err(
      invalid_font_collection_limit("max-retained-bookkeeping-bytes"),
    )
  }
  if max_work == 0UL {
    return Err(invalid_font_collection_limit("max-work"))
  }
  Ok({
    max_source_bytes_value: max_source_bytes,
    max_faces_value: max_faces,
    max_tables_per_face_value: max_tables_per_face,
    max_table_records_value: max_table_records,
    max_dsig_records_value: max_dsig_records,
    max_dsig_bytes_value: max_dsig_bytes,
    max_retained_bookkeeping_bytes_value: max_retained_bookkeeping_bytes,
    max_work_value: max_work,
  })
}

///|
pub fn FontCollectionLimits::max_source_bytes(
  self : FontCollectionLimits,
) -> UInt64 {
  self.max_source_bytes_value
}

///|
pub fn FontCollectionLimits::max_faces(self : FontCollectionLimits) -> UInt64 {
  self.max_faces_value
}

///|
pub fn FontCollectionLimits::max_tables_per_face(
  self : FontCollectionLimits,
) -> UInt64 {
  self.max_tables_per_face_value
}

///|
pub fn FontCollectionLimits::max_table_records(
  self : FontCollectionLimits,
) -> UInt64 {
  self.max_table_records_value
}

///|
pub fn FontCollectionLimits::max_dsig_records(
  self : FontCollectionLimits,
) -> UInt64 {
  self.max_dsig_records_value
}

///|
pub fn FontCollectionLimits::max_dsig_bytes(
  self : FontCollectionLimits,
) -> UInt64 {
  self.max_dsig_bytes_value
}

///|
pub fn FontCollectionLimits::max_retained_bookkeeping_bytes(
  self : FontCollectionLimits,
) -> UInt64 {
  self.max_retained_bookkeeping_bytes_value
}

///|
pub fn FontCollectionLimits::max_work(self : FontCollectionLimits) -> UInt64 {
  self.max_work_value
}
