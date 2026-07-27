///|
#warnings("-7")
priv struct CollectionFaceFacts {
  directory_start : UInt64
  directory_end : UInt64
  table_count : UInt64
  sfnt_version : UInt64
  profile : FontFaceProfile
}

///|
#warnings("-7")
priv struct CollectionProtectedRange {
  start : UInt64
  end : UInt64
  kind : UInt64
  owner : UInt64
}

///|
priv struct CollectionParseFacts {
  faces : Array[CollectionFaceFacts]
  protected_ranges : Array[CollectionProtectedRange]
  dsig_status : FontCollectionDsigStatus
  charge : @budget.ResourceCharge
}

///|
fn font_collection_data_error(
  context : String,
  source_offset? : UInt64,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-collection-open",
    source_offset?,
    requested?,
    limit?,
    context~,
  )
}

///|
fn font_collection_capability_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-collection-open",
    context~,
  )
}

///|
fn font_collection_limit_error(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="font-collection-open",
    requested~,
    limit~,
    context~,
  )
}

///|
fn font_collection_read_u16(
  source : @bytes.ByteView,
  offset : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  match read_u16(source, offset) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(
        font_collection_data_error(
          context,
          source_offset=offset,
          requested=2UL,
          limit=source.length(),
        ),
      )
  }
}

///|
fn font_collection_read_u32(
  source : @bytes.ByteView,
  offset : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  match read_u32(source, offset) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(
        font_collection_data_error(
          context,
          source_offset=offset,
          requested=4UL,
          limit=source.length(),
        ),
      )
  }
}

///|
fn font_collection_data_add(
  left : UInt64,
  right : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_add(left, right) {
    Ok(value) => Ok(value)
    Err(_) => Err(font_collection_data_error(context))
  }
}

///|
fn font_collection_data_mul(
  left : UInt64,
  right : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_mul(left, right) {
    Ok(value) => Ok(value)
    Err(_) => Err(font_collection_data_error(context))
  }
}

///|
fn font_collection_resource_add(
  left : UInt64,
  right : UInt64,
  context : String,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_add(left, right) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(font_collection_limit_error(context, 18446744073709551615UL, limit))
  }
}

///|
fn font_collection_resource_mul(
  left : UInt64,
  right : UInt64,
  context : String,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_mul(left, right) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(font_collection_limit_error(context, 18446744073709551615UL, limit))
  }
}

///|
fn font_collection_choose_two(
  value : UInt64,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if value < 2UL {
    return Ok(0UL)
  }
  let previous = value - 1UL
  match font_collection_resource_mul(value, previous, "max-work", limit) {
    Err(error) => Err(error)
    Ok(product) => Ok(product / 2UL)
  }
}

///|
fn font_collection_ranges_overlap(
  left_start : UInt64,
  left_end : UInt64,
  right_start : UInt64,
  right_end : UInt64,
) -> Bool {
  left_start < left_end &&
  right_start < right_end &&
  left_start < right_end &&
  right_start < left_end
}

///|
fn font_collection_directory_offset(
  source : @bytes.ByteView,
  face_index : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let delta = match
    font_collection_data_mul(face_index, 4UL, "font-collection-offset-array") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let field = match
    font_collection_data_add(12UL, delta, "font-collection-offset-array") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  font_collection_read_u32(
    source,
    field,
    "font-collection-directory-offset",
  )
}

///|
fn font_collection_directory_end(
  directory_start : UInt64,
  table_count : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let record_bytes = match
    font_collection_data_mul(
      table_count,
      16UL,
      "font-collection-directory-range",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let directory_length = match
    font_collection_data_add(
      12UL,
      record_bytes,
      "font-collection-directory-range",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  font_collection_data_add(
    directory_start,
    directory_length,
    "font-collection-directory-range",
  )
}

///|
fn font_collection_variation_tag(tag : UInt64) -> Bool {
  tag == 0x66766172UL ||
  tag == 0x67766172UL ||
  tag == 0x63766172UL ||
  tag == 0x61766172UL ||
  tag == 0x48564152UL ||
  tag == 0x4D564152UL ||
  tag == 0x56564152UL
}

///|
fn font_collection_scan_face(
  source : @bytes.ByteView,
  header_end : UInt64,
  face_index : UInt64,
  limits : FontCollectionLimits,
) -> Result[CollectionFaceFacts, @error.CoreError] {
  let directory_start = match
    font_collection_directory_offset(source, face_index) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let minimum_end = match
    font_collection_data_add(
      directory_start,
      12UL,
      "font-collection-directory-range",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if minimum_end > source.length() {
    return Err(
      font_collection_data_error(
        "font-collection-directory-range",
        source_offset=directory_start,
        requested=12UL,
        limit=source.length(),
      ),
    )
  }
  let sfnt_version = match
    font_collection_read_u32(
      source,
      directory_start,
      "font-collection-sfnt-version",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let table_count_field = directory_start + 4UL
  let table_count = match
    font_collection_read_u16(
      source,
      table_count_field,
      "font-collection-table-count",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if table_count == 0UL {
    return Err(
      font_collection_data_error(
        "font-collection-table-count",
        source_offset=table_count_field,
      ),
    )
  }
  if table_count > limits.max_tables_per_face() {
    return Err(
      font_collection_limit_error(
        "max-tables-per-face",
        table_count,
        limits.max_tables_per_face(),
      ),
    )
  }
  let directory_end = match
    font_collection_directory_end(directory_start, table_count) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if directory_end > source.length() {
    return Err(
      font_collection_data_error(
        "font-collection-directory-range",
        source_offset=directory_start,
        requested=directory_end - directory_start,
        limit=source.length(),
      ),
    )
  }
  let (expected_search, expected_selector, expected_shift) = match
    font_directory_search_facts(table_count) {
    Ok(value) => value
    Err(_) => return Err(font_collection_data_error("font-collection-search-facts"))
  }
  let stored_search = match
    font_collection_read_u16(
      source,
      directory_start + 6UL,
      "font-collection-search-facts",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let stored_selector = match
    font_collection_read_u16(
      source,
      directory_start + 8UL,
      "font-collection-search-facts",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let stored_shift = match
    font_collection_read_u16(
      source,
      directory_start + 10UL,
      "font-collection-search-facts",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if stored_search != expected_search ||
    stored_selector != expected_selector ||
    stored_shift != expected_shift {
    return Err(font_collection_data_error("font-collection-search-facts"))
  }
  let mut has_glyf = false
  let mut has_loca = false
  let mut has_cff = false
  let mut has_cff2 = false
  let mut has_variation = false
  let mut previous_tag : UInt64? = None
  let mut table_index = 0UL
  while table_index < table_count {
    let record_delta = match
      font_collection_data_mul(
        table_index,
        16UL,
        "font-collection-directory-record",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let record_offset = match
      font_collection_data_add(
        directory_start + 12UL,
        record_delta,
        "font-collection-directory-record",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let tag = match
      font_collection_read_u32(
        source,
        record_offset,
        "font-collection-table-tag",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match previous_tag {
      Some(previous) =>
        if tag <= previous {
          return Err(
            font_collection_data_error(
              "font-collection-table-tag-order",
              source_offset=record_offset,
            ),
          )
        }
      None => ()
    }
    let table_offset = match
      font_collection_read_u32(
        source,
        record_offset + 8UL,
        "font-collection-table-range",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let table_length = match
      font_collection_read_u32(
        source,
        record_offset + 12UL,
        "font-collection-table-range",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if table_length > 0UL && table_offset % 4UL != 0UL {
      return Err(
        font_collection_data_error(
          "font-collection-table-alignment",
          source_offset=record_offset + 8UL,
        ),
      )
    }
    let table_end = match
      font_collection_data_add(
        table_offset,
        table_length,
        "font-collection-table-range",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if table_end > source.length() {
      return Err(
        font_collection_data_error(
          "font-collection-table-range",
          source_offset=table_offset,
          requested=table_length,
          limit=source.length(),
        ),
      )
    }
    if font_collection_ranges_overlap(
      table_offset,
      table_end,
      0UL,
      header_end,
    ) ||
      font_collection_ranges_overlap(
        table_offset,
        table_end,
        directory_start,
        directory_end,
      ) {
      return Err(
        font_collection_data_error(
          "font-collection-table-protected-overlap",
          source_offset=table_offset,
          requested=table_length,
        ),
      )
    }
    if tag == 0x676C7966UL {
      has_glyf = true
    } else if tag == 0x6C6F6361UL {
      has_loca = true
    } else if tag == 0x43464620UL {
      has_cff = true
    } else if tag == 0x43464632UL {
      has_cff2 = true
    }
    if font_collection_variation_tag(tag) {
      has_variation = true
    }
    previous_tag = Some(tag)
    table_index = table_index + 1UL
  }
  let profile = if has_variation {
    FontFaceProfile::Variable
  } else if sfnt_version == 0x4F54544FUL && has_cff2 {
    FontFaceProfile::Cff2
  } else if sfnt_version == 0x4F54544FUL && has_cff {
    FontFaceProfile::Cff
  } else if
    sfnt_version == 0x00010000UL && has_glyf && has_loca {
    FontFaceProfile::StaticGlyf
  } else {
    FontFaceProfile::OtherUnsupported
  }
  Ok({
    directory_start,
    directory_end,
    table_count,
    sfnt_version,
    profile,
  })
}

///|
fn font_collection_retained_charge(
  face_count : UInt64,
  table_records : UInt64,
  limits : FontCollectionLimits,
) -> Result[@budget.ResourceCharge, @error.CoreError] {
  let retained_limit = limits.max_retained_bookkeeping_bytes()
  let face_bytes = match
    font_collection_resource_mul(
      face_count,
      40UL,
      "max-retained-bookkeeping-bytes",
      retained_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_count = match
    font_collection_resource_add(
      1UL,
      face_count,
      "max-retained-bookkeeping-bytes",
      retained_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_bytes = match
    font_collection_resource_mul(
      protected_count,
      24UL,
      "max-retained-bookkeeping-bytes",
      retained_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let array_bytes = match
    font_collection_resource_add(
      face_bytes,
      protected_bytes,
      "max-retained-bookkeeping-bytes",
      retained_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let retained_bytes = match
    font_collection_resource_add(
      96UL,
      array_bytes,
      "max-retained-bookkeeping-bytes",
      retained_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if retained_bytes > retained_limit {
    return Err(
      font_collection_limit_error(
        "max-retained-bookkeeping-bytes",
        retained_bytes,
        retained_limit,
      ),
    )
  }
  let work_limit = limits.max_work()
  let declaration_reads = match
    font_collection_resource_add(
      3UL,
      face_count + face_count,
      "max-work",
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let structural_face = match
    font_collection_resource_mul(face_count, 5UL, "max-work", work_limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let structural_records = match
    font_collection_resource_mul(table_records, 4UL, "max-work", work_limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let structural_reads = match
    font_collection_resource_add(
      3UL + face_count,
      structural_face,
      "max-work",
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let structural_reads = match
    font_collection_resource_add(
      structural_reads,
      structural_records,
      "max-work",
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_pairs = match
    font_collection_choose_two(protected_count, work_limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let table_protected = match
    font_collection_resource_mul(
      table_records,
      protected_count,
      "max-work",
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_work = match
    font_collection_resource_add(
      protected_pairs,
      table_protected,
      "max-work",
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let alias_work = match
    font_collection_choose_two(table_records, work_limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let normalization = match
    font_collection_resource_add(
      1UL + face_count,
      protected_count,
      "max-work",
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut work = declaration_reads
  for term in [
    structural_reads,
    table_records,
    protected_work,
    alias_work,
    normalization,
  ] {
    work = match
      font_collection_resource_add(work, term, "max-work", work_limit) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  }
  if work > work_limit {
    return Err(font_collection_limit_error("max-work", work, work_limit))
  }
  Ok(
    @budget.ResourceCharge::new(
      bytes=retained_bytes,
      allocations=2UL,
      allocation_size=if face_bytes > protected_bytes {
        face_bytes
      } else {
        protected_bytes
      },
      width=0UL,
      height=0UL,
      pixels=0UL,
      work~,
    ),
  )
}

///|
fn font_collection_parse(
  source : @bytes.ByteView,
  limits : FontCollectionLimits,
  budget : @budget.Budget,
) -> Result[CollectionParseFacts, @error.CoreError] {
  if source.length() > limits.max_source_bytes() {
    return Err(
      font_collection_limit_error(
        "max-source-bytes",
        source.length(),
        limits.max_source_bytes(),
      ),
    )
  }
  if source.length() < 4UL {
    return Err(
      font_collection_data_error(
        "font-collection-header",
        requested=4UL,
        limit=source.length(),
      ),
    )
  }
  let signature = match
    font_collection_read_u32(source, 0UL, "font-collection-signature") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if signature != 0x74746366UL {
    return Err(
      font_collection_data_error(
        "font-collection-signature",
        source_offset=0UL,
      ),
    )
  }
  if source.length() < 12UL {
    return Err(
      font_collection_data_error(
        "font-collection-header",
        requested=12UL,
        limit=source.length(),
      ),
    )
  }
  let version = match
    font_collection_read_u32(source, 4UL, "font-collection-version") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if version != 0x00010000UL {
    return Err(font_collection_capability_error("font-collection-version"))
  }
  let face_count = match
    font_collection_read_u32(source, 8UL, "font-collection-face-count") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if face_count == 0UL {
    return Err(
      font_collection_data_error(
        "font-collection-face-count",
        source_offset=8UL,
      ),
    )
  }
  if face_count > limits.max_faces() {
    return Err(
      font_collection_limit_error(
        "max-faces",
        face_count,
        limits.max_faces(),
      ),
    )
  }
  let offset_bytes = match
    font_collection_data_mul(
      face_count,
      4UL,
      "font-collection-offset-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let header_end = match
    font_collection_data_add(
      12UL,
      offset_bytes,
      "font-collection-offset-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if header_end > source.length() {
    return Err(
      font_collection_data_error(
        "font-collection-offset-array",
        source_offset=12UL,
        requested=offset_bytes,
        limit=source.length(),
      ),
    )
  }
  let mut table_records = 0UL
  let mut face_index = 0UL
  while face_index < face_count {
    let face = match
      font_collection_scan_face(source, header_end, face_index, limits) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    table_records = match
      font_collection_resource_add(
        table_records,
        face.table_count,
        "max-table-records",
        limits.max_table_records(),
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if table_records > limits.max_table_records() {
      return Err(
        font_collection_limit_error(
          "max-table-records",
          table_records,
          limits.max_table_records(),
        ),
      )
    }
    face_index = face_index + 1UL
  }
  let charge = match
    font_collection_retained_charge(face_count, table_records, limits) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match budget.preflight(charge) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let faces : Array[CollectionFaceFacts] = []
  let protected_ranges : Array[CollectionProtectedRange] = [
    { start: 0UL, end: header_end, kind: 0UL, owner: 0UL },
  ]
  face_index = 0UL
  while face_index < face_count {
    let face = match
      font_collection_scan_face(source, header_end, face_index, limits) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    protected_ranges.push({
      start: face.directory_start,
      end: face.directory_end,
      kind: 1UL,
      owner: face_index,
    })
    faces.push(face)
    face_index = face_index + 1UL
  }
  Ok({
    faces,
    protected_ranges,
    dsig_status: FontCollectionDsigStatus::Absent,
    charge,
  })
}
