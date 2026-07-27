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
priv struct CollectionTableRecord {
  face_index : UInt64
  tag : UInt64
  checksum : UInt64
  start : UInt64
  end : UInt64
  length : UInt64
}

///|
priv struct CollectionDsigRecord {
  format : UInt64
  start : UInt64
  end : UInt64
}

///|
priv struct CollectionDsigFacts {
  record_count : UInt64
  record_array_end : UInt64
}

///|
priv struct CollectionDeclarationFacts {
  version : UInt64
  face_count : UInt64
  header_end : UInt64
  table_records : UInt64
  dsig_present : Bool
  dsig_start : UInt64
  dsig_end : UInt64
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
fn font_collection_work_charge(work : UInt64) -> @budget.ResourceCharge {
  @budget.ResourceCharge::new(
    bytes=0UL,
    allocations=0UL,
    allocation_size=0UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work~,
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
fn font_collection_directory_range(
  source : @bytes.ByteView,
  directory_start : UInt64,
  table_count : UInt64,
) -> Result[@checked.CheckedRange, @error.CoreError] {
  let end = match
    font_collection_directory_end(directory_start, table_count) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if end > source.length() {
    return Err(
      font_collection_data_error(
        "font-collection-directory-range",
        source_offset=directory_start,
        requested=end - directory_start,
        limit=source.length(),
      ),
    )
  }
  match
    @checked.CheckedRange::from_start_length(
      directory_start,
      end - directory_start,
    ) {
    Ok(value) => Ok(value)
    Err(_) => Err(font_collection_data_error("font-collection-directory-range"))
  }
}

///|
fn font_collection_table_range(
  source : @bytes.ByteView,
  table_start : UInt64,
  table_length : UInt64,
) -> Result[@checked.CheckedRange, @error.CoreError] {
  let root = match
    @checked.CheckedRange::from_start_length(0UL, source.length()) {
    Ok(value) => value
    Err(_) => return Err(font_collection_data_error("font-collection-source-range"))
  }
  match root.subrange(table_start, table_length) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(
        font_collection_data_error(
          "font-collection-table-range",
          source_offset=table_start,
          requested=table_length,
          limit=source.length(),
        ),
      )
  }
}

///|
fn font_collection_dsig_range(
  source : @bytes.ByteView,
  start : UInt64,
  length : UInt64,
) -> Result[@checked.CheckedRange, @error.CoreError] {
  let root = match
    @checked.CheckedRange::from_start_length(0UL, source.length()) {
    Ok(value) => value
    Err(_) =>
      return Err(font_collection_data_error("font-collection-source-range"))
  }
  match root.subrange(start, length) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(
        font_collection_data_error(
          "font-collection-dsig-range",
          source_offset=start,
          requested=length,
          limit=source.length(),
        ),
      )
  }
}

///|
fn font_collection_dsig_block_range(
  declaration : CollectionDeclarationFacts,
  relative_start : UInt64,
  length : UInt64,
) -> Result[@checked.CheckedRange, @error.CoreError] {
  let dsig_length = declaration.dsig_end - declaration.dsig_start
  let outer = match
    @checked.CheckedRange::from_start_length(
      declaration.dsig_start,
      dsig_length,
    ) {
    Ok(value) => value
    Err(_) =>
      return Err(
        font_collection_data_error("font-collection-dsig-block-range"),
      )
  }
  match outer.subrange(relative_start, length) {
    Ok(value) => Ok(value)
    Err(_) =>
      Err(
        font_collection_data_error(
          "font-collection-dsig-block-range",
          source_offset=declaration.dsig_start,
          requested=length,
          limit=dsig_length,
        ),
      )
  }
}

///|
fn font_collection_dsig_record(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
  record_array_end : UInt64,
  index : UInt64,
) -> Result[CollectionDsigRecord, @error.CoreError] {
  let delta = match
    font_collection_data_mul(
      index,
      12UL,
      "font-collection-dsig-record-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let record_start = match
    font_collection_data_add(
      declaration.dsig_start + 8UL,
      delta,
      "font-collection-dsig-record-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let format = match
    font_collection_read_u32(
      source,
      record_start,
      "font-collection-dsig-record",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length = match
    font_collection_read_u32(
      source,
      record_start + 4UL,
      "font-collection-dsig-record",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let relative_start = match
    font_collection_read_u32(
      source,
      record_start + 8UL,
      "font-collection-dsig-record",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if length < 8UL {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-block-length",
        source_offset=record_start + 4UL,
        requested=length,
        limit=8UL,
      ),
    )
  }
  let block = match
    font_collection_dsig_block_range(
      declaration,
      relative_start,
      length,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if block.start() < record_array_end {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-block-range",
        source_offset=block.start(),
        requested=length,
        limit=record_array_end,
      ),
    )
  }
  let reserved_one = match
    font_collection_read_u16(
      source,
      block.start(),
      "font-collection-dsig-reserved",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let reserved_two = match
    font_collection_read_u16(
      source,
      block.start() + 2UL,
      "font-collection-dsig-reserved",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if reserved_one != 0UL || reserved_two != 0UL {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-reserved",
        source_offset=block.start(),
      ),
    )
  }
  let payload_length = match
    font_collection_read_u32(
      source,
      block.start() + 4UL,
      "font-collection-dsig-payload-length",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if payload_length == 0UL {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-payload-length",
        source_offset=block.start() + 4UL,
      ),
    )
  }
  let exact_length = match
    font_collection_data_add(
      8UL,
      payload_length,
      "font-collection-dsig-block-length",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if exact_length != length {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-block-length",
        source_offset=block.start(),
        requested=exact_length,
        limit=length,
      ),
    )
  }
  Ok({ format, start: block.start(), end: block.end() })
}

///|
fn font_collection_validate_dsig_blocks(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
  record_count : UInt64,
  record_array_end : UInt64,
) -> Result[Unit, @error.CoreError] {
  let mut final_end = record_array_end
  let mut current_index = 0UL
  while current_index < record_count {
    let current = match
      font_collection_dsig_record(
        source,
        declaration,
        record_array_end,
        current_index,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let mut earlier_index = 0UL
    while earlier_index < current_index {
      let earlier = match
        font_collection_dsig_record(
          source,
          declaration,
          record_array_end,
          earlier_index,
        ) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if font_collection_ranges_overlap(
        earlier.start,
        earlier.end,
        current.start,
        current.end,
      ) {
        return Err(
          font_collection_data_error(
            "font-collection-dsig-block-overlap",
            source_offset=current.start,
            requested=current.end - current.start,
          ),
        )
      }
      earlier_index = earlier_index + 1UL
    }
    if current.end > final_end {
      final_end = current.end
    }
    if current.format != 1UL {
      return Err(
        font_collection_capability_error("font-collection-dsig-format"),
      )
    }
    current_index = current_index + 1UL
  }
  if final_end != declaration.dsig_end {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-outer-length",
        source_offset=final_end,
        requested=declaration.dsig_end - final_end,
        limit=declaration.dsig_end,
      ),
    )
  }
  Ok(())
}

///|
fn font_collection_discover_dsig_record_count(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
  limits : FontCollectionLimits,
) -> Result[UInt64, @error.CoreError] {
  if !declaration.dsig_present {
    return Ok(0UL)
  }
  let length = declaration.dsig_end - declaration.dsig_start
  if length < 8UL {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-header",
        source_offset=declaration.dsig_start,
        requested=8UL,
        limit=length,
      ),
    )
  }
  let record_count = match
    font_collection_read_u16(
      source,
      declaration.dsig_start + 4UL,
      "font-collection-dsig-count",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if record_count > limits.max_dsig_records() {
    return Err(
      font_collection_limit_error(
        "max-dsig-records",
        record_count,
        limits.max_dsig_records(),
      ),
    )
  }
  Ok(record_count)
}

///|
fn font_collection_validate_dsig_declaration(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
  record_count : UInt64,
) -> Result[CollectionDsigFacts, @error.CoreError] {
  if !declaration.dsig_present {
    return Ok({ record_count: 0UL, record_array_end: 0UL })
  }
  let length = declaration.dsig_end - declaration.dsig_start
  let version = match
    font_collection_read_u32(
      source,
      declaration.dsig_start,
      "font-collection-dsig-version",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let flags = match
    font_collection_read_u16(
      source,
      declaration.dsig_start + 6UL,
      "font-collection-dsig-flags",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if version != 1UL {
    return Err(
      font_collection_capability_error("font-collection-dsig-version"),
    )
  }
  if record_count == 0UL {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-count",
        source_offset=declaration.dsig_start + 4UL,
      ),
    )
  }
  if (flags & 0xFFFEUL) != 0UL {
    return Err(
      font_collection_data_error(
        "font-collection-dsig-flags",
        source_offset=declaration.dsig_start + 6UL,
      ),
    )
  }
  let record_bytes = match
    font_collection_data_mul(
      record_count,
      12UL,
      "font-collection-dsig-record-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let record_array_length = match
    font_collection_data_add(
      8UL,
      record_bytes,
      "font-collection-dsig-record-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let record_array = match
    font_collection_dsig_block_range(
      declaration,
      0UL,
      record_array_length,
    ) {
    Ok(value) => value
    Err(_) =>
      return Err(
        font_collection_data_error(
          "font-collection-dsig-record-array",
          source_offset=declaration.dsig_start,
          requested=record_array_length,
          limit=length,
        ),
      )
  }
  Ok({ record_count, record_array_end: record_array.end() })
}

///|
fn font_collection_validate_dsig_envelope(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
  dsig : CollectionDsigFacts,
) -> Result[Unit, @error.CoreError] {
  if !declaration.dsig_present {
    return Ok(())
  }
  font_collection_validate_dsig_blocks(
    source,
    declaration,
    dsig.record_count,
    dsig.record_array_end,
  )
}

///|
fn font_collection_table_record(
  source : @bytes.ByteView,
  face_index : UInt64,
  table_index : UInt64,
) -> Result[CollectionTableRecord, @error.CoreError] {
  let directory_start = match
    font_collection_directory_offset(source, face_index) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let delta = match
    font_collection_data_mul(
      table_index,
      16UL,
      "font-collection-directory-record",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let record_start = match
    font_collection_data_add(
      directory_start,
      12UL,
      "font-collection-directory-record",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let record_offset = match
    font_collection_data_add(
      record_start,
      delta,
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
  let checksum = match
    font_collection_read_u32(
      source,
      record_offset + 4UL,
      "font-collection-table-checksum",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let start = match
    font_collection_read_u32(
      source,
      record_offset + 8UL,
      "font-collection-table-range",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length = match
    font_collection_read_u32(
      source,
      record_offset + 12UL,
      "font-collection-table-range",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let range = match font_collection_table_range(source, start, length) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    face_index,
    tag,
    checksum,
    start: range.start(),
    end: range.end(),
    length,
  })
}

///|
fn font_collection_protected_count(
  declaration : CollectionDeclarationFacts,
) -> UInt64 {
  let dsig_count = if declaration.dsig_present { 1UL } else { 0UL }
  1UL + declaration.face_count + dsig_count
}

///|
fn font_collection_protected_range_at(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
  index : UInt64,
) -> Result[CollectionProtectedRange, @error.CoreError] {
  if index == 0UL {
    return Ok({
      start: 0UL,
      end: declaration.header_end,
      kind: 0UL,
      owner: 0UL,
    })
  }
  if index <= declaration.face_count {
    let face_index = index - 1UL
    let directory_start = match
      font_collection_directory_offset(source, face_index) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let table_count = match
      font_collection_read_u16(
        source,
        directory_start + 4UL,
        "font-collection-table-count",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let range = match
      font_collection_directory_range(source, directory_start, table_count) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    return Ok({
      start: range.start(),
      end: range.end(),
      kind: 1UL,
      owner: face_index,
    })
  }
  if declaration.dsig_present && index == declaration.face_count + 1UL {
    return Ok({
      start: declaration.dsig_start,
      end: declaration.dsig_end,
      kind: 2UL,
      owner: 0UL,
    })
  }
  Err(font_collection_data_error("font-collection-protected-index"))
}

///|
fn font_collection_validate_protected_ranges(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
) -> Result[Unit, @error.CoreError] {
  let count = font_collection_protected_count(declaration)
  let mut current_index = 0UL
  while current_index < count {
    let current = match
      font_collection_protected_range_at(
        source,
        declaration,
        current_index,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let mut earlier_index = 0UL
    while earlier_index < current_index {
      let earlier = match
        font_collection_protected_range_at(
          source,
          declaration,
          earlier_index,
        ) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if font_collection_ranges_overlap(
        current.start,
        current.end,
        earlier.start,
        earlier.end,
      ) {
        return Err(
          font_collection_data_error(
            "font-collection-protected-overlap",
            source_offset=current.start,
            requested=current.end - current.start,
          ),
        )
      }
      earlier_index = earlier_index + 1UL
    }
    current_index = current_index + 1UL
  }
  Ok(())
}

///|
fn font_collection_validate_table_protected_ranges(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
) -> Result[Unit, @error.CoreError] {
  let protected_count = font_collection_protected_count(declaration)
  let mut face_index = 0UL
  while face_index < declaration.face_count {
    let directory_start = match
      font_collection_directory_offset(source, face_index) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let table_count = match
      font_collection_read_u16(
        source,
        directory_start + 4UL,
        "font-collection-table-count",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let mut table_index = 0UL
    while table_index < table_count {
      let record = match
        font_collection_table_record(source, face_index, table_index) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if record.length > 0UL {
        let mut protected_index = 0UL
        while protected_index < protected_count {
          let protected_range = match
            font_collection_protected_range_at(
              source,
              declaration,
              protected_index,
            ) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          if font_collection_ranges_overlap(
            record.start,
            record.end,
            protected_range.start,
            protected_range.end,
          ) {
            return Err(
              font_collection_data_error(
                "font-collection-table-protected-overlap",
                source_offset=record.start,
                requested=record.length,
              ),
            )
          }
          protected_index = protected_index + 1UL
        }
      }
      table_index = table_index + 1UL
    }
    face_index = face_index + 1UL
  }
  Ok(())
}

///|
fn font_collection_validate_record_pair(
  earlier : CollectionTableRecord,
  current : CollectionTableRecord,
) -> Result[Unit, @error.CoreError] {
  if earlier.length == 0UL || current.length == 0UL {
    return Ok(())
  }
  if !font_collection_ranges_overlap(
    earlier.start,
    earlier.end,
    current.start,
    current.end,
  ) {
    return Ok(())
  }
  if earlier.face_index == current.face_index {
    return Err(
      font_collection_data_error(
        "font-collection-same-face-overlap",
        source_offset=current.start,
        requested=current.length,
      ),
    )
  }
  let exact_range = earlier.start == current.start &&
    earlier.end == current.end
  let exact_metadata = earlier.tag == current.tag &&
    earlier.length == current.length &&
    earlier.checksum == current.checksum
  if exact_range && exact_metadata {
    Ok(())
  } else {
    Err(
      font_collection_data_error(
        if exact_range {
          "font-collection-shared-metadata"
        } else {
          "font-collection-cross-face-overlap"
        },
        source_offset=current.start,
        requested=current.length,
      ),
    )
  }
}

///|
fn font_collection_validate_aliases(
  source : @bytes.ByteView,
  declaration : CollectionDeclarationFacts,
) -> Result[Unit, @error.CoreError] {
  let mut current_face = 0UL
  while current_face < declaration.face_count {
    let current_directory = match
      font_collection_directory_offset(source, current_face) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let current_count = match
      font_collection_read_u16(
        source,
        current_directory + 4UL,
        "font-collection-table-count",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let mut current_table = 0UL
    while current_table < current_count {
      let current = match
        font_collection_table_record(
          source,
          current_face,
          current_table,
        ) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let mut earlier_face = 0UL
      while earlier_face <= current_face {
        let earlier_directory = match
          font_collection_directory_offset(source, earlier_face) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let earlier_count = match
          font_collection_read_u16(
            source,
            earlier_directory + 4UL,
            "font-collection-table-count",
          ) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let stop = if earlier_face == current_face {
          current_table
        } else {
          earlier_count
        }
        let mut earlier_table = 0UL
        while earlier_table < stop {
          let earlier = match
            font_collection_table_record(
              source,
              earlier_face,
              earlier_table,
            ) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          match font_collection_validate_record_pair(earlier, current) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
          earlier_table = earlier_table + 1UL
        }
        earlier_face = earlier_face + 1UL
      }
      current_table = current_table + 1UL
    }
    current_face = current_face + 1UL
  }
  Ok(())
}

///|
fn font_collection_declaration_facts(
  source : @bytes.ByteView,
  limits : FontCollectionLimits,
  budget : @budget.Budget,
) -> Result[CollectionDeclarationFacts, @error.CoreError] {
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
  if version != 0x00010000UL && version != 0x00020000UL {
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
  let offset_array_end = match
    font_collection_data_add(
      12UL,
      offset_bytes,
      "font-collection-offset-array",
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let header_end = if version == 0x00020000UL {
    match
      font_collection_data_add(
        offset_array_end,
        12UL,
        "font-collection-v2-header",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  } else {
    offset_array_end
  }
  if header_end > source.length() {
    return Err(
      font_collection_data_error(
        "font-collection-offset-array",
        source_offset=12UL,
        requested=header_end - 12UL,
        limit=source.length(),
      ),
    )
  }
  let mut dsig_present = false
  let mut dsig_start = 0UL
  let mut dsig_end = 0UL
  if version == 0x00020000UL {
    let tag = match
      font_collection_read_u32(
        source,
        offset_array_end,
        "font-collection-dsig-tuple",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let length = match
      font_collection_read_u32(
        source,
        offset_array_end + 4UL,
        "font-collection-dsig-tuple",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let offset = match
      font_collection_read_u32(
        source,
        offset_array_end + 8UL,
        "font-collection-dsig-tuple",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if tag == 0UL && length == 0UL && offset == 0UL {
      ()
    } else if tag == 0UL || length == 0UL || offset == 0UL {
      return Err(font_collection_data_error("font-collection-dsig-tuple"))
    } else {
      if tag != 0x44534947UL {
        return Err(font_collection_data_error("font-collection-dsig-tag"))
      }
      if offset % 4UL != 0UL {
        return Err(
          font_collection_data_error(
            "font-collection-dsig-alignment",
            source_offset=offset_array_end + 8UL,
          ),
        )
      }
      if length > limits.max_dsig_bytes() {
        return Err(
          font_collection_limit_error(
            "max-dsig-bytes",
            length,
            limits.max_dsig_bytes(),
          ),
        )
      }
      let range = match font_collection_dsig_range(source, offset, length) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if range.end() != source.length() {
        return Err(
          font_collection_data_error(
            "font-collection-dsig-range",
            source_offset=offset,
            requested=length,
            limit=source.length(),
          ),
        )
      }
      dsig_present = true
      dsig_start = range.start()
      dsig_end = range.end()
    }
  }
  let work_limit = limits.max_work()
  let declaration_work = match
    font_collection_declaration_work(
      face_count,
      if version == 0x00020000UL { 1UL } else { 0UL },
      if dsig_present { 1UL } else { 0UL },
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if declaration_work > work_limit {
    return Err(
      font_collection_limit_error(
        "max-work",
        declaration_work,
        work_limit,
      ),
    )
  }
  match budget.preflight(font_collection_work_charge(declaration_work)) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let mut table_records = 0UL
  let mut face_index = 0UL
  while face_index < face_count {
    let directory_start = match
      font_collection_directory_offset(source, face_index) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if directory_start == 0UL {
      return Err(
        font_collection_data_error(
          "font-collection-directory-offset",
          source_offset=12UL + face_index * 4UL,
        ),
      )
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
    let table_count = match
      font_collection_read_u16(
        source,
        directory_start + 4UL,
        "font-collection-table-count",
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if table_count == 0UL {
      return Err(
        font_collection_data_error(
          "font-collection-table-count",
          source_offset=directory_start + 4UL,
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
    table_records = match
      font_collection_resource_add(
        table_records,
        table_count,
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
  Ok({
    version,
    face_count,
    header_end,
    table_records,
    dsig_present,
    dsig_start,
    dsig_end,
  })
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
    if table_offset % 4UL != 0UL {
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
  } else if
    sfnt_version == 0x4F54544FUL &&
    has_cff2 &&
    !has_cff &&
    !has_glyf &&
    !has_loca {
    FontFaceProfile::Cff2
  } else if
    sfnt_version == 0x4F54544FUL &&
    has_cff &&
    !has_cff2 &&
    !has_glyf &&
    !has_loca {
    FontFaceProfile::Cff
  } else if
    sfnt_version == 0x00010000UL &&
    has_glyf &&
    has_loca &&
    !has_cff &&
    !has_cff2 {
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
fn font_collection_declaration_work(
  face_count : UInt64,
  version_two : UInt64,
  dsig_present : UInt64,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let face_twice = match
    font_collection_resource_mul(face_count, 2UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let version_reads = match
    font_collection_resource_mul(version_two, 3UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dsig_declaration = match
    font_collection_resource_mul(dsig_present, 3UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut declaration_reads = 3UL
  for term in [face_twice, version_reads, dsig_declaration] {
    declaration_reads = match
      font_collection_resource_add(
        declaration_reads,
        term,
        "max-work",
        limit,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  }
  Ok(declaration_reads)
}

///|
fn font_collection_measured_work(
  face_count : UInt64,
  table_records : UInt64,
  protected_count : UInt64,
  version_two : UInt64,
  dsig_present : UInt64,
  dsig_records : UInt64,
  include_normalization : Bool,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let version_reads = match
    font_collection_resource_mul(version_two, 3UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let declaration_reads = match
    font_collection_declaration_work(
      face_count,
      version_two,
      dsig_present,
      limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let structural_face = match
    font_collection_resource_mul(face_count, 5UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let structural_records = match
    font_collection_resource_mul(table_records, 4UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut structural_reads = 3UL
  for term in [
    face_count,
    version_reads,
    structural_face,
    structural_records,
  ] {
    structural_reads = match
      font_collection_resource_add(
        structural_reads,
        term,
        "max-work",
        limit,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  }
  let protected_pairs = match
    font_collection_choose_two(protected_count, limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let table_protected = match
    font_collection_resource_mul(
      table_records,
      protected_count,
      "max-work",
      limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_work = match
    font_collection_resource_add(
      protected_pairs,
      table_protected,
      "max-work",
      limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let alias_work = match
    font_collection_choose_two(table_records, limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dsig_record_fields = match
    font_collection_resource_mul(dsig_records, 6UL, "max-work", limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dsig_pairs = match font_collection_choose_two(dsig_records, limit) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut dsig_body = 3UL
  for term in [dsig_record_fields, dsig_pairs] {
    dsig_body = match
      font_collection_resource_add(dsig_body, term, "max-work", limit) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  }
  let dsig_work = match
    font_collection_resource_mul(
      dsig_present,
      dsig_body,
      "max-work",
      limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let normalization = if include_normalization {
    let normalization_base = match
      font_collection_resource_add(1UL, face_count, "max-work", limit) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let retained_facts = match
      font_collection_resource_add(
        normalization_base,
        protected_count,
        "max-work",
        limit,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let normalization_faces = match
      font_collection_resource_add(
        structural_face,
        structural_records,
        "max-work",
        limit,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match
      font_collection_resource_add(
        retained_facts,
        normalization_faces,
        "max-work",
        limit,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  } else {
    0UL
  }
  let mut work = declaration_reads
  for term in [
    structural_reads,
    table_records,
    protected_work,
    alias_work,
    dsig_work,
    normalization,
  ] {
    work = match
      font_collection_resource_add(work, term, "max-work", limit) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
  }
  Ok(work)
}

///|
fn font_collection_structural_work(
  face_count : UInt64,
  table_records : UInt64,
  protected_count : UInt64,
  version_two : UInt64,
  dsig_present : UInt64,
  dsig_records : UInt64,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  font_collection_measured_work(
    face_count,
    table_records,
    protected_count,
    version_two,
    dsig_present,
    dsig_records,
    false,
    limit,
  )
}

///|
fn font_collection_exact_work(
  face_count : UInt64,
  table_records : UInt64,
  protected_count : UInt64,
  version_two : UInt64,
  dsig_present : UInt64,
  dsig_records : UInt64,
  limit : UInt64,
) -> Result[UInt64, @error.CoreError] {
  font_collection_measured_work(
    face_count,
    table_records,
    protected_count,
    version_two,
    dsig_present,
    dsig_records,
    true,
    limit,
  )
}

///|
fn font_collection_retained_charge(
  face_count : UInt64,
  table_records : UInt64,
  version : UInt64,
  dsig_present : Bool,
  dsig_records : UInt64,
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
  let dsig_count = if dsig_present { 1UL } else { 0UL }
  let base_protected = match
    font_collection_resource_add(
      1UL,
      face_count,
      "max-retained-bookkeeping-bytes",
      retained_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_count = match
    font_collection_resource_add(
      base_protected,
      dsig_count,
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
  let work = match
    font_collection_exact_work(
      face_count,
      table_records,
      protected_count,
      if version == 0x00020000UL { 1UL } else { 0UL },
      dsig_count,
      dsig_records,
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
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
  let declaration = match
    font_collection_declaration_facts(source, limits, budget) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let dsig_record_count = match
    font_collection_discover_dsig_record_count(source, declaration, limits) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let protected_count = font_collection_protected_count(declaration)
  let work_limit = limits.max_work()
  let structural_work = match
    font_collection_structural_work(
      declaration.face_count,
      declaration.table_records,
      protected_count,
      if declaration.version == 0x00020000UL { 1UL } else { 0UL },
      if declaration.dsig_present { 1UL } else { 0UL },
      dsig_record_count,
      work_limit,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if structural_work > work_limit {
    return Err(
      font_collection_limit_error("max-work", structural_work, work_limit),
    )
  }
  // The staged work-only preflight establishes exact authority for the
  // allocation-free structural traversal. The complete retained charge is
  // checked only after structural facts, preserving D-18 precedence.
  match
    budget.preflight(font_collection_work_charge(structural_work)) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let mut face_index = 0UL
  while face_index < declaration.face_count {
    match
      font_collection_scan_face(
        source,
        declaration.header_end,
        face_index,
        limits,
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    face_index = face_index + 1UL
  }
  match font_collection_validate_protected_ranges(source, declaration) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match
    font_collection_validate_table_protected_ranges(source, declaration) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match font_collection_validate_aliases(source, declaration) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let dsig = match
    font_collection_validate_dsig_declaration(
      source,
      declaration,
      dsig_record_count,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match font_collection_validate_dsig_envelope(source, declaration, dsig) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let charge = match
    font_collection_retained_charge(
      declaration.face_count,
      declaration.table_records,
      declaration.version,
      declaration.dsig_present,
      dsig.record_count,
      limits,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match budget.preflight(charge) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let faces : Array[CollectionFaceFacts] = []
  face_index = 0UL
  while face_index < declaration.face_count {
    let face = match
      font_collection_scan_face(
        source,
        declaration.header_end,
        face_index,
        limits,
      ) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    faces.push(face)
    face_index = face_index + 1UL
  }
  let protected_ranges : Array[CollectionProtectedRange] = [
    { start: 0UL, end: declaration.header_end, kind: 0UL, owner: 0UL },
  ]
  let mut retained_face_index = 0
  while retained_face_index < faces.length() {
    let face = faces[retained_face_index]
    protected_ranges.push({
      start: face.directory_start,
      end: face.directory_end,
      kind: 1UL,
      owner: retained_face_index.to_uint64(),
    })
    retained_face_index = retained_face_index + 1
  }
  if declaration.dsig_present {
    protected_ranges.push({
      start: declaration.dsig_start,
      end: declaration.dsig_end,
      kind: 2UL,
      owner: 0UL,
    })
  }
  Ok({
    faces,
    protected_ranges,
    dsig_status: if declaration.dsig_present {
      FontCollectionDsigStatus::PresentUnverified
    } else {
      FontCollectionDsigStatus::Absent
    },
    charge,
  })
}
