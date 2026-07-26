///|
priv struct FontTableRecord {
  tag : UInt64
  checksum : UInt64
  offset : UInt64
  length : UInt64
  view : @bytes.ByteView
}

///|
priv struct FontDirectory {
  source : @bytes.ByteView
  records : Array[FontTableRecord]
  work : UInt64
}

///|
priv struct TableWindow {
  tag : UInt64
  checksum : UInt64
  offset : UInt64
  length_value : UInt64
  view : @bytes.ByteView
}

///|
priv struct DirectoryFacts {
  source : @bytes.ByteView
  tables : Array[TableWindow]
  work : UInt64
}

///|
fn font_data_error(
  context : String,
  source_offset? : UInt64,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-open",
    source_offset?,
    requested?,
    limit?,
    context~,
  )
}

///|
fn font_capability_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-open",
    context~,
  )
}

///|
fn font_limit_error(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="font-open",
    requested~,
    limit~,
    context~,
  )
}

///|
fn font_directory_search_facts(
  num_tables : UInt64,
) -> Result[(UInt64, UInt64, UInt64), @error.CoreError] {
  let mut power = 1UL
  let mut selector = 0UL
  while power <= num_tables / 2UL {
    power = match @checked.checked_mul(power, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    selector = match @checked.checked_add(selector, 1UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let search_range = match @checked.checked_mul(power, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let table_bytes = match @checked.checked_mul(num_tables, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let range_shift = match @checked.checked_sub(table_bytes, search_range) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok((search_range, selector, range_shift))
}

///|
fn font_directory_end(num_tables : UInt64) -> Result[UInt64, @error.CoreError] {
  let record_bytes = match @checked.checked_mul(num_tables, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @checked.checked_add(12UL, record_bytes)
}

///|
fn font_directory_overlap_work(
  num_tables : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let earlier_tables = match @checked.checked_sub(num_tables, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ordered_pairs = match @checked.checked_mul(num_tables, earlier_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(ordered_pairs / 2UL)
}

///|
fn font_directory_work(
  source_length : UInt64,
  num_tables : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let checksum_work = match @checked.checked_mul(source_length, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let overlap_work = match font_directory_overlap_work(num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let record_scan_work = match @checked.checked_add(num_tables, overlap_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // `font_parse_directory` normalizes every parsed record into the retained
  // `TableWindow` array. Keep that copy pass in the shared directory total so
  // both discovery preflight and the final atomic charge account it exactly
  // once.
  let directory_work = match @checked.checked_add(record_scan_work, num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @checked.checked_add(checksum_work, directory_work)
}

///|
fn font_directory_allocation_size(
  num_tables : UInt64,
) -> Result[UInt64, @error.CoreError] {
  // Both retained directory representations contain four UInt64 facts plus a
  // ByteView (backing, start, length, revision). Eight 64-bit accounting slots
  // per entry are a stable, conservative portable budget model.
  @checked.checked_mul(num_tables, 64UL)
}

///|
fn font_directory_discovery_charge(
  source : @bytes.ByteView,
  limits : FontLimits,
) -> Result[@budget.ResourceCharge, @error.CoreError] {
  if source.length() > limits.max_source_bytes() {
    return Err(
      font_limit_error(
        "max-source-bytes",
        source.length(),
        limits.max_source_bytes(),
      ),
    )
  }
  if source.length() < 4UL {
    return Err(
      font_data_error("font-sfnt-header", requested=4UL, limit=source.length()),
    )
  }
  let signature = match read_u32(source, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if signature != 0x00010000UL {
    if font_unsupported_signature(signature) {
      return Err(font_capability_error("font-outline-profile"))
    }
    return Err(font_data_error("font-sfnt-signature", source_offset=0UL))
  }
  if source.length() < 12UL {
    return Err(
      font_data_error("font-sfnt-header", requested=12UL, limit=source.length()),
    )
  }
  let num_tables = match read_u16(source, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if num_tables == 0UL {
    return Err(font_data_error("font-table-count", source_offset=4UL))
  }
  if num_tables > limits.max_tables() {
    return Err(font_limit_error("max-tables", num_tables, limits.max_tables()))
  }
  let directory_end = match font_directory_end(num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if directory_end > source.length() {
    return Err(
      font_data_error(
        "font-directory-range",
        source_offset=12UL,
        requested=directory_end - 12UL,
        limit=source.length(),
      ),
    )
  }
  let directory_work = match font_directory_work(source.length(), num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // Admission discovers four count-bearing required tables before it can form
  // the final atomic charge. Authorize the worst-case linear scans here so a
  // budget that cannot afford discovery fails before any of those lookups.
  let precharge_lookup_work = match @checked.checked_mul(num_tables, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(directory_work, precharge_lookup_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let allocation_size = match font_directory_allocation_size(num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if work > limits.max_work() {
    return Err(font_limit_error("max-work", work, limits.max_work()))
  }
  Ok(
    @budget.ResourceCharge::new(
      bytes=source.length(),
      allocations=2UL,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work~,
    ),
  )
}

///|
fn checked_font_table_view(
  source : @bytes.ByteView,
  offset : UInt64,
  length : UInt64,
) -> Result[@bytes.ByteView, @error.CoreError] {
  let source_range = match
    @checked.CheckedRange::from_start_length(0UL, source.length()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let table_range = match source_range.subrange(offset, length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  source.subview(table_range.start(), table_range.length())
}

///|
fn font_unsupported_table_tag(tag : UInt64) -> Bool {
  tag == 0x43464620UL ||
  tag == 0x43464632UL ||
  tag == 0x66766172UL ||
  tag == 0x67766172UL ||
  tag == 0x61766172UL ||
  tag == 0x48564152UL ||
  tag == 0x4D564152UL ||
  tag == 0x63766172UL ||
  tag == 0x434F4C52UL ||
  tag == 0x4350414CUL ||
  tag == 0x53564720UL ||
  tag == 0x43424454UL ||
  tag == 0x43424C43UL ||
  tag == 0x73626978UL ||
  tag == 0x45424454UL ||
  tag == 0x45424C43UL ||
  tag == 0x45425343UL
}

///|
fn font_unsupported_signature(signature : UInt64) -> Bool {
  signature == 0x4F54544FUL ||
  signature == 0x74746366UL ||
  signature == 0x774F4646UL ||
  signature == 0x774F4632UL ||
  signature == 0x74727565UL ||
  signature == 0x74797031UL
}

///|
fn font_records_overlap(
  records : Array[FontTableRecord],
  offset : UInt64,
  length : UInt64,
) -> Result[Bool, @error.CoreError] {
  let candidate = match
    @checked.CheckedRange::from_start_length(offset, length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for record in records {
    let existing = match
      @checked.CheckedRange::from_start_length(record.offset, record.length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if candidate.overlaps(existing) {
      return Ok(true)
    }
  }
  Ok(false)
}

///|
fn parse_font_directory(
  source : @bytes.ByteView,
  limits : FontLimits,
) -> Result[FontDirectory, @error.CoreError] {
  if source.length() > limits.max_source_bytes() {
    return Err(
      font_limit_error(
        "max-source-bytes",
        source.length(),
        limits.max_source_bytes(),
      ),
    )
  }
  if source.length() < 4UL {
    return Err(
      font_data_error("font-sfnt-header", requested=4UL, limit=source.length()),
    )
  }
  let signature = match read_u32(source, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if signature != 0x00010000UL {
    if font_unsupported_signature(signature) {
      return Err(font_capability_error("font-outline-profile"))
    }
    return Err(font_data_error("font-sfnt-signature", source_offset=0UL))
  }
  if source.length() < 12UL {
    return Err(
      font_data_error("font-sfnt-header", requested=12UL, limit=source.length()),
    )
  }
  let num_tables = match read_u16(source, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if num_tables == 0UL {
    return Err(font_data_error("font-table-count", source_offset=4UL))
  }
  if num_tables > limits.max_tables() {
    return Err(font_limit_error("max-tables", num_tables, limits.max_tables()))
  }
  let record_bytes = match @checked.checked_mul(num_tables, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let directory_end = match font_directory_end(num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if directory_end > source.length() {
    return Err(
      font_data_error(
        "font-directory-range",
        source_offset=12UL,
        requested=record_bytes,
        limit=source.length(),
      ),
    )
  }
  let (expected_search, expected_selector, expected_shift) = match
    font_directory_search_facts(num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let stored_search = match read_u16(source, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let stored_selector = match read_u16(source, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let stored_shift = match read_u16(source, 10UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if stored_search != expected_search ||
    stored_selector != expected_selector ||
    stored_shift != expected_shift {
    return Err(font_data_error("font-directory-search-facts"))
  }
  let records : Array[FontTableRecord] = []
  let mut previous_tag : UInt64? = None
  let mut index = 0UL
  while index < num_tables {
    let record_delta = match @checked.checked_mul(index, 16UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let record_offset = match @checked.checked_add(12UL, record_delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let tag = match read_u32(source, record_offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if font_unsupported_table_tag(tag) {
      return Err(font_capability_error("font-unsupported-profile"))
    }
    match previous_tag {
      Some(previous) =>
        if tag <= previous {
          return Err(
            font_data_error(
              "font-directory-tag-order",
              source_offset=record_offset,
            ),
          )
        }
      None => ()
    }
    let checksum_offset = match @checked.checked_add(record_offset, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let table_offset_field = match @checked.checked_add(record_offset, 8UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let table_length_field = match @checked.checked_add(record_offset, 12UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let checksum = match read_u32(source, checksum_offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let table_offset = match read_u32(source, table_offset_field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let table_length = match read_u32(source, table_length_field) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if table_offset % 4UL != 0UL {
      return Err(
        font_data_error(
          "font-table-alignment",
          source_offset=table_offset_field,
        ),
      )
    }
    if table_length > limits.max_table_bytes() {
      return Err(
        font_limit_error(
          "max-table-bytes",
          table_length,
          limits.max_table_bytes(),
        ),
      )
    }
    let table_end = match @checked.checked_add(table_offset, table_length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if table_end > source.length() {
      return Err(
        font_data_error(
          "font-table-range",
          source_offset=table_offset,
          requested=table_length,
          limit=source.length(),
        ),
      )
    }
    if table_length > 0UL && table_offset < directory_end {
      return Err(
        font_data_error(
          "font-table-directory-overlap",
          source_offset=table_offset,
          requested=table_length,
          limit=directory_end,
        ),
      )
    }
    match font_records_overlap(records, table_offset, table_length) {
      Err(error) => return Err(error)
      Ok(true) =>
        return Err(
          font_data_error(
            "font-table-overlap",
            source_offset=table_offset,
            requested=table_length,
          ),
        )
      Ok(false) => ()
    }
    let table_view = match
      checked_font_table_view(source, table_offset, table_length) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    records.push({
      tag,
      checksum,
      offset: table_offset,
      length: table_length,
      view: table_view,
    })
    previous_tag = Some(tag)
    index = match @checked.checked_add(index, 1UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let work = match font_directory_work(source.length(), num_tables) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if work > limits.max_work() {
    return Err(font_limit_error("max-work", work, limits.max_work()))
  }
  Ok({ source, records, work })
}

///|
fn font_parse_directory(
  source : @bytes.ByteView,
  limits : FontLimits,
) -> Result[DirectoryFacts, @error.CoreError] {
  let legacy = match parse_font_directory(source, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tables : Array[TableWindow] = []
  for record in legacy.records {
    tables.push({
      tag: record.tag,
      checksum: record.checksum,
      offset: record.offset,
      length_value: record.length,
      view: record.view,
    })
  }
  Ok({ source: legacy.source, tables, work: legacy.work })
}

///|
fn font_table_window(
  directory : DirectoryFacts,
  tag : UInt64,
) -> Result[TableWindow, @error.CoreError] {
  for table in directory.tables {
    if table.tag == tag {
      return Ok(table)
    }
  }
  Err(font_data_error("font-required-table"))
}

///|
fn font_sfnt_checksum(
  source : @bytes.ByteView,
  zero_head_adjustment : Bool,
) -> Result[UInt64, @error.CoreError] {
  let mut checksum = 0UL
  let mut offset = 0UL
  while offset < source.length() {
    let mut word = 0UL
    for delta in [0UL, 1UL, 2UL, 3UL] {
      let index = match @checked.checked_add(offset, delta) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let byte = if zero_head_adjustment && index >= 8UL && index < 12UL {
        b'\x00'
      } else if index < source.length() {
        match source.get(index) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      } else {
        b'\x00'
      }
      word = (word << 8) | byte.to_uint64()
    }
    checksum = (checksum + word) & 0xFFFFFFFFUL
    offset = match @checked.checked_add(offset, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  Ok(checksum)
}

///|
fn font_validate_profile(
  directory : DirectoryFacts,
) -> Result[Unit, @error.CoreError] {
  for table in directory.tables {
    if font_unsupported_table_tag(table.tag) {
      return Err(font_capability_error("font-profile-table"))
    }
  }
  Ok(())
}

///|
fn font_validate_checksums(
  directory : DirectoryFacts,
) -> Result[Unit, @error.CoreError] {
  for table in directory.tables {
    let computed = match
      font_sfnt_checksum(table.view, table.tag == 0x68656164UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if computed != table.checksum {
      return Err(
        font_data_error(
          "font-table-checksum",
          source_offset=table.offset,
          requested=table.length_value,
        ),
      )
    }
  }
  let source_checksum = match font_sfnt_checksum(directory.source, false) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source_checksum != 0xB1B0AFBAUL {
    return Err(font_data_error("font-checksum-adjustment"))
  }
  Ok(())
}
