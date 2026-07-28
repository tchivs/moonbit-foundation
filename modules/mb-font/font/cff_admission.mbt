///|
#warnings("-7")
priv struct AdmittedCff1 {
  top : CffTopDict
  name : CffIndex
  strings : CffIndex
  global_subrs : CffIndex
  charstrings : CffIndex
  keying : CffKeying
  glyphs : Array[CffGlyphDescriptor]
  glyph : CffGlyphDescriptor
  num_glyphs : UInt64
  charge : CffStructuralCharge
  directory_start : UInt64
  cff_table_offset : UInt64
}

///|
/// Exact retained and caller-authority facts for one CFF1 structural
/// transaction. Keeping the dimensions beside the opaque ResourceCharge lets
/// white-box qualification prove every exact/one-less boundary independently.
#warnings("-7")
priv struct CffStructuralCharge {
  resource : @budget.ResourceCharge
  bytes : UInt64
  allocations : UInt64
  allocation_size : UInt64
  retained_bytes : UInt64
  header_bytes : UInt64
  index_offsets : UInt64
  index_objects : UInt64
  dict_units : UInt64
  charset_entries : UInt64
  encoding_entries : UInt64
  fd_ranges : UInt64
  sid_cid_lookups : UInt64
  descriptors : UInt64
  fd_environments : UInt64
  work : UInt64
}

///|
priv struct CffAuthorityLedger {
  caller : @budget.Budget
  bytes : UInt64
  mut work : UInt64
  mut allocations : UInt64
  mut allocation_size : UInt64
}

///|
fn CffAuthorityLedger::new(
  caller : @budget.Budget,
  bytes : UInt64,
  base_work : UInt64,
) -> Result[CffAuthorityLedger, @error.CoreError] {
  let ledger : CffAuthorityLedger = {
    caller,
    bytes,
    work: base_work,
    allocations: 0UL,
    allocation_size: 0UL,
  }
  match ledger.preflight(0UL, 0UL, 0UL) {
    Err(error) => Err(error)
    Ok(_) => Ok(ledger)
  }
}

///|
fn CffAuthorityLedger::preflight(
  self : CffAuthorityLedger,
  work : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
) -> Result[Unit, @error.CoreError] {
  let next_work = match @checked.checked_add(self.work, work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next_allocations = match
    @checked.checked_add(self.allocations, allocations) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next_size = if allocation_size > self.allocation_size {
    allocation_size
  } else {
    self.allocation_size
  }
  match
    self.caller.preflight(
      @budget.ResourceCharge::new(
        bytes=self.bytes,
        allocations=next_allocations,
        allocation_size=next_size,
        width=0UL,
        height=0UL,
        pixels=0UL,
        work=next_work,
      ),
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.work = next_work
  self.allocations = next_allocations
  self.allocation_size = next_size
  Ok(())
}

///|
fn CffAuthorityLedger::preflight_index(
  self : CffAuthorityLedger,
  source : @bytes.ByteView,
  start : UInt64,
  max_count : UInt64,
  context : String,
) -> Result[Unit, @error.CoreError] {
  match cff_require_window(source, start, 2UL, context) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = match read_u16(source, start) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if count > max_count {
    return Err(cff_data_error(context, requested=count, limit=max_count))
  }
  if count == 0UL {
    return Ok(())
  }
  let offset_count = match @checked.checked_add(count, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let allocation_size = match @checked.checked_mul(offset_count, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(offset_count, count) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.preflight(work, 1UL, allocation_size)
}

///|
fn cff_empty_index(
  source : @bytes.ByteView,
) -> Result[CffIndex, @error.CoreError] {
  let empty = match source.subview(0UL, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    count: 0UL,
    off_size: 0UL,
    offsets: [],
    object_data: empty,
    encoded_length: 2UL,
  })
}

///|
fn cff_preclassify_static_profile(
  source : @bytes.ByteView,
  directory_start : UInt64,
) -> Result[Unit, @error.CoreError] {
  match
    cff_require_window(
      source,
      directory_start,
      12UL,
      "font-cff-sfnt-header",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let signature = match read_u32(source, directory_start) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if signature != 0x4F54544FUL {
    return Err(cff_capability_error("font-cff-profile"))
  }
  let count_offset = match @checked.checked_add(directory_start, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let table_count = match read_u16(source, count_offset) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if table_count == 0UL {
    return Err(cff_data_error("font-cff-table-count"))
  }
  let record_bytes = match @checked.checked_mul(table_count, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let records_start = match @checked.checked_add(directory_start, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match
    cff_require_window(
      source,
      records_start,
      record_bytes,
      "font-cff-directory-range",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut cff_count = 0UL
  let mut has_cff2 = false
  let mut has_glyf = false
  let mut has_loca = false
  let mut has_variable = false
  let mut has_maxp = false
  let mut index = 0UL
  while index < table_count {
    let record = records_start + index * 16UL
    let tag = match read_u32(source, record) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if tag == 0x43464620UL {
      cff_count = cff_count + 1UL
    } else if tag == 0x43464632UL {
      has_cff2 = true
    } else if tag == 0x676C7966UL {
      has_glyf = true
    } else if tag == 0x6C6F6361UL {
      has_loca = true
    } else if tag == 0x6D617870UL {
      has_maxp = true
    }
    if tag == 0x66766172UL ||
      tag == 0x67766172UL ||
      tag == 0x61766172UL ||
      tag == 0x48564152UL ||
      tag == 0x4D564152UL ||
      tag == 0x63766172UL {
      has_variable = true
    }
    index = index + 1UL
  }
  if cff_count != 1UL ||
    has_cff2 ||
    has_glyf ||
    has_loca ||
    has_variable ||
    !has_maxp {
    Err(cff_capability_error("font-cff-profile"))
  } else {
    Ok(())
  }
}

///|
fn cff_decode_maxp05(
  table : TableWindow,
  limits : FontLimits,
) -> Result[UInt64, @error.CoreError] {
  if table.length_value != 6UL {
    return Err(cff_capability_error("font-cff-maxp-profile"))
  }
  let version = match read_u32(table.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let num_glyphs = match read_u16(table.view, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if version != 0x00005000UL {
    return Err(cff_capability_error("font-cff-maxp-profile"))
  }
  if num_glyphs == 0UL {
    return Err(cff_data_error("font-cff-maxp-glyph-count"))
  }
  if num_glyphs > limits.max_glyphs() {
    return Err(font_limit_error("max-glyphs", num_glyphs, limits.max_glyphs()))
  }
  Ok(num_glyphs)
}

///|
fn cff_validate_common_tables(
  directory : DirectoryFacts,
  num_glyphs : UInt64,
  limits : FontLimits,
) -> Result[Unit, @error.CoreError] {
  match font_require_common_table_presence(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_decode_head(font_table_window(directory, 0x68656164UL).unwrap()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let maxp : MaxpFacts = {
    num_glyphs,
    max_points: 0UL,
    max_contours: 0UL,
    max_composite_points: 0UL,
    max_composite_contours: 0UL,
    max_size_of_instructions: 0UL,
    max_component_elements: 0UL,
    max_component_depth: 0UL,
  }
  let hhea = match
    font_decode_hhea(
      font_table_window(directory, 0x68686561UL).unwrap(),
      maxp,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let hmtx = font_table_window(directory, 0x686D7478UL).unwrap()
  let hmtx_required = match
    font_hmtx_required_length(num_glyphs, hhea.number_of_h_metrics) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if hmtx.length_value != hmtx_required {
    return Err(
      font_data_error(
        "font-hmtx-cardinality",
        requested=hmtx_required,
        limit=hmtx.length_value,
      ),
    )
  }
  match
    font_decode_os2(font_table_window(directory, 0x4F532F32UL).unwrap()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match
    font_admit_cmap_envelope(
      font_table_window(directory, 0x636D6170UL).unwrap(),
      maxp,
      limits,
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match
    font_admit_name_envelope(
      font_table_window(directory, 0x6E616D65UL).unwrap(),
      limits,
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match
    font_admit_post_envelope(
      font_table_window(directory, 0x706F7374UL).unwrap(),
      maxp,
      limits,
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(())
}

///|
fn cff_table_subview(
  table : TableWindow,
  offset : UInt64,
  length : UInt64,
  context : String,
) -> Result[@bytes.ByteView, @error.CoreError] {
  let end = match @checked.checked_add(offset, length) {
    Err(_) =>
      return Err(
        cff_data_error(
          context,
          source_offset=offset,
          requested=length,
          limit=table.length_value,
        ),
      )
    Ok(value) => value
  }
  if end > table.length_value {
    return Err(
      cff_data_error(
        context,
        source_offset=offset,
        requested=length,
        limit=table.length_value,
      ),
    )
  }
  match table.view.subview(offset, length) {
    Err(_) =>
      Err(
        cff_data_error(
          context,
          source_offset=offset,
          requested=length,
          limit=table.length_value,
        ),
      )
    Ok(value) => Ok(value)
  }
}

///|
fn cff_admission_charge(
  charge_bytes : UInt64,
  directory : DirectoryFacts,
  cff : TableWindow,
  indexes : Array[CffIndex],
  dict_units : UInt64,
  charset_entries : UInt64,
  encoding_entries : UInt64,
  fd_ranges : UInt64,
  fd_selector_entries : UInt64,
  sid_cid_lookups : UInt64,
  descriptor_count : UInt64,
  fd_count : UInt64,
  header_bytes : UInt64,
  scratch_allocation_size : UInt64,
  cid_keyed : Bool,
  limits : FontLimits,
) -> Result[CffStructuralCharge, @error.CoreError] {
  let structural_limits = match cff_structural_limits(limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut retained_offsets = 0UL
  let mut index_objects = 0UL
  for index in indexes {
    retained_offsets = match
      @checked.checked_add(retained_offsets, index.offsets.length().to_uint64()) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    index_objects = match @checked.checked_add(index_objects, index.count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  if retained_offsets > structural_limits.max_index_entries {
    return Err(
      font_limit_error(
        "max-cff-index-entries",
        retained_offsets,
        structural_limits.max_index_entries,
      ),
    )
  }
  let offset_bytes = match @checked.checked_mul(retained_offsets, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let descriptor_bytes = match
    @checked.checked_mul(descriptor_count, 96UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let fd_bytes = match @checked.checked_mul(fd_count, 64UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charset_bytes = match @checked.checked_mul(charset_entries, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let encoding_bytes = match @checked.checked_mul(encoding_entries, 16UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let fd_selector_bytes = match @checked.checked_mul(fd_selector_entries, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut retained_bytes = 0UL
  for size in [
    offset_bytes,
    descriptor_bytes,
    fd_bytes,
    charset_bytes,
    encoding_bytes,
    fd_selector_bytes,
  ] {
    retained_bytes = match @checked.checked_add(retained_bytes, size) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  if retained_bytes > structural_limits.max_retained_bytes {
    return Err(
      font_limit_error(
        "max-cff-retained-bytes",
        retained_bytes,
        structural_limits.max_retained_bytes,
      ),
    )
  }
  if dict_units > structural_limits.max_dict_units {
    return Err(
      font_limit_error(
        "max-cff-dict-units",
        dict_units,
        structural_limits.max_dict_units,
      ),
    )
  }
  if charset_entries > structural_limits.max_charset_entries {
    return Err(
      font_limit_error(
        "max-cff-charset-entries",
        charset_entries,
        structural_limits.max_charset_entries,
      ),
    )
  }
  if encoding_entries > structural_limits.max_encoding_entries {
    return Err(
      font_limit_error(
        "max-cff-encoding-entries",
        encoding_entries,
        structural_limits.max_encoding_entries,
      ),
    )
  }
  if fd_ranges > structural_limits.max_fd_ranges {
    return Err(
      font_limit_error(
        "max-cff-fd-ranges",
        fd_ranges,
        structural_limits.max_fd_ranges,
      ),
    )
  }
  if sid_cid_lookups > structural_limits.max_sid_cid_lookups {
    return Err(
      font_limit_error(
        "max-cff-sid-cid-lookups",
        sid_cid_lookups,
        structural_limits.max_sid_cid_lookups,
      ),
    )
  }
  let mut allocation_size = 0UL
  for size in [
    offset_bytes,
    descriptor_bytes,
    fd_bytes,
    charset_bytes,
    encoding_bytes / 2UL,
    fd_selector_bytes,
    scratch_allocation_size,
  ] {
    if size > allocation_size {
      allocation_size = size
    }
  }
  let structural_work = match
    @checked.checked_add(directory.work, cff.length_value) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let keying_work = match
    @checked.checked_add(retained_offsets, descriptor_count) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let complete_keying_work = match @checked.checked_add(keying_work, fd_count) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let named_structural_work = match
    @checked.checked_add(
      header_bytes,
      match @checked.checked_add(index_objects, dict_units) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let named_keying_work = match
    @checked.checked_add(
      charset_entries,
      match
        @checked.checked_add(
          encoding_entries,
          match @checked.checked_add(fd_ranges, sid_cid_lookups) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match
    @checked.checked_add(
      structural_work,
      match
        @checked.checked_add(
          complete_keying_work,
          match @checked.checked_add(named_structural_work, named_keying_work) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if work > structural_limits.max_work {
    return Err(font_limit_error("max-work", work, structural_limits.max_work))
  }
  let mut allocations = 0UL
  for index in indexes {
    if index.offsets.length() > 0 {
      allocations = allocations + 1UL
    }
  }
  if descriptor_count > 0UL {
    allocations = allocations + 1UL
  }
  if charset_entries > 0UL {
    allocations = allocations + 2UL
  }
  if encoding_entries > 0UL {
    allocations = allocations + 3UL
  }
  if cid_keyed && fd_count > 0UL {
    allocations = allocations + 1UL
  }
  if fd_selector_entries > 0UL {
    allocations = allocations + 1UL
  }
  let resource = @budget.ResourceCharge::new(
      bytes=charge_bytes,
      allocations~,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work~,
    )
  Ok({
    resource,
    bytes: charge_bytes,
    allocations,
    allocation_size,
    retained_bytes,
    header_bytes,
    index_offsets: retained_offsets,
    index_objects,
    dict_units,
    charset_entries,
    encoding_entries,
    fd_ranges,
    sid_cid_lookups,
    descriptors: descriptor_count,
    fd_environments: fd_count,
    work,
  })
}

///|
#warnings("-1")
fn admit_cff1_structure_at_after_preflight(
  source : @bytes.ByteView,
  directory_start : UInt64,
  expected_table_count : UInt64?,
  checksum_mode : FontChecksumMode,
  collection_charge : Bool,
  limits : FontLimits,
  budget : @budget.Budget,
  gid : UInt64,
  before_final_guard : () -> Unit,
) -> Result[AdmittedCff1, @error.CoreError] {
  let opening_revision = source.mutation_revision()
  // Test and selected-face adapters place their mutation hook immediately
  // after the opening revision capture. Any already-observed revision drift
  // therefore has precedence over caller/resource/profile/data outcomes.
  before_final_guard()
  if source.mutation_revision() != opening_revision {
    return Err(
      @error.CoreError::new(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        operation="font-cff-admit",
        context="font-cff-source-revision-drift",
      ),
    )
  }
  if source.length() > limits.max_source_bytes() {
    return Err(
      font_limit_error(
        "max-source-bytes",
        source.length(),
        limits.max_source_bytes(),
      ),
    )
  }
  // Caller byte authority is known without touching attacker-controlled CFF
  // structure. It therefore precedes capability classification and malformed
  // supported-profile traversal for standalone admission.
  if !collection_charge {
    match
      budget.preflight(
        @budget.ResourceCharge::new(
          bytes=source.length(),
          allocations=0UL,
          allocation_size=0UL,
          width=0UL,
          height=0UL,
          pixels=0UL,
          work=0UL,
        ),
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match cff_preclassify_static_profile(source, directory_start) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let directory = match
    font_parse_cff1_directory_at(
      source,
      directory_start,
      expected_table_count,
      limits,
      checksum_mode,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_validate_checksums_with_mode(directory, checksum_mode) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let cff = match font_table_window(directory, 0x43464620UL) {
    Err(_) => return Err(cff_capability_error("font-cff-profile"))
    Ok(value) => value
  }
  let maxp = match font_table_window(directory, 0x6D617870UL) {
    Err(_) => return Err(cff_capability_error("font-cff-profile"))
    Ok(value) => value
  }
  let num_glyphs = match cff_decode_maxp05(maxp, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charge_bytes = if collection_charge {
    match font_collection_selected_extent_bytes(directory) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  } else {
    source.length()
  }
  let base_authority_work = match @checked.checked_add(directory.work, cff.length_value) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match cff_validate_common_tables(directory, num_glyphs, limits) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let authority = match
    CffAuthorityLedger::new(budget, charge_bytes, base_authority_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match cff_require_window(cff.view, 0UL, 4UL, "font-cff-header") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let major = cff.view.get(0UL).unwrap().to_uint64()
  let minor = cff.view.get(1UL).unwrap().to_uint64()
  let header_size = cff.view.get(2UL).unwrap().to_uint64()
  let header_off_size = cff.view.get(3UL).unwrap().to_uint64()
  if major != 1UL || minor != 0UL {
    return Err(cff_capability_error("font-cff-version"))
  }
  if header_size < 4UL || header_size > cff.length_value {
    return Err(cff_data_error("font-cff-header-size"))
  }
  if header_off_size < 1UL || header_off_size > 4UL {
    return Err(cff_data_error("font-cff-header-off-size"))
  }
  match
    authority.preflight_index(
      cff.view,
      header_size,
      limits.max_name_records(),
      "font-cff-name-index",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let (name, after_name) = match
    cff_decode_index(
      cff.view,
      header_size,
      limits.max_name_records(),
      "font-cff-name-index",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match
    authority.preflight_index(
      cff.view,
      after_name,
      1UL,
      "font-cff-top-index",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if name.count != 1UL {
    return Err(
      cff_data_error("font-cff-name-count", requested=name.count, limit=1UL),
    )
  }
  let (top_index, after_top) = match
    cff_decode_index(cff.view, after_name, 1UL, "font-cff-top-index") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if top_index.count != 1UL {
    return Err(
      cff_data_error("font-cff-top-count", requested=top_index.count, limit=1UL),
    )
  }
  let top_object = match
    cff_index_object(top_index, 0UL, "font-cff-top-index") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let top_dict_allocation = match
    @checked.checked_mul(top_object.view.length(), 32UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match authority.preflight(0UL, 0UL, top_dict_allocation) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let top = match cff_decode_top_dict(top_object.view) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let type_value = match
    cff_number_nonnegative_integer(
      top.charstring_type,
      "font-cff-charstring-type",
    ) {
    Err(_) => return Err(cff_capability_error("font-cff-charstring-type"))
    Ok(value) => value
  }
  match
    authority.preflight_index(
      cff.view,
      after_top,
      limits.max_name_records(),
      "font-cff-string-index",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if type_value != 2UL {
    return Err(cff_capability_error("font-cff-charstring-type"))
  }
  let (strings, after_strings) = match
    cff_decode_index(
      cff.view,
      after_top,
      limits.max_name_records(),
      "font-cff-string-index",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for sid in top.sid_operands {
    match cff_validate_sid(sid, strings, "font-cff-top-sid") {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match
    authority.preflight_index(
      cff.view,
      after_strings,
      limits.max_work(),
      "font-cff-global-subrs-index",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let (global_subrs, _) = match
    cff_decode_index(
      cff.view,
      after_strings,
      limits.max_work(),
      "font-cff-global-subrs-index",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match
    authority.preflight_index(
      cff.view,
      top.charstrings.value,
      limits.max_glyphs(),
      "font-cff-charstrings-index",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let (charstrings, _) = match
    cff_decode_index(
      cff.view,
      top.charstrings.value,
      limits.max_glyphs(),
      "font-cff-charstrings-index",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if charstrings.count != num_glyphs {
    return Err(
      cff_data_error(
        "font-cff-charstrings-count",
        requested=charstrings.count,
        limit=num_glyphs,
      ),
    )
  }
  if gid >= num_glyphs {
    return Err(cff_data_error("font-cff-gid", requested=gid, limit=num_glyphs))
  }
  let descriptor_allocation = match @checked.checked_mul(num_glyphs, 96UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charset_allocation = match @checked.checked_mul(num_glyphs, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charset_scratch = if top.charset is Some(value) && value.value >= 3UL {
    8192UL
  } else {
    3032UL
  }
  let charset_max = if charset_allocation > charset_scratch {
    charset_allocation
  } else {
    charset_scratch
  }
  match authority.preflight(num_glyphs, 2UL, charset_max) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match top.ros {
    None => {
      let encoding_scratch = if top.encoding is Some(value) && value.value >= 2UL {
        256UL
      } else {
        2048UL
      }
      let encoding_size = if charset_allocation > encoding_scratch {
        charset_allocation
      } else {
        encoding_scratch
      }
      match authority.preflight(num_glyphs, 3UL, encoding_size) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    }
    Some(_) => ()
  }
  match authority.preflight(num_glyphs, 1UL, descriptor_allocation) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let keying = match
    cff_resolve_keying(
      cff,
      top,
      strings,
      charstrings,
      num_glyphs,
      limits,
      authority,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let indexes = [name, top_index, strings, global_subrs, charstrings]
  for index in keying.retained_indexes {
    indexes.push(index)
  }
  let encoding_entries = match keying.keying.encoding {
    None => 0UL
    Some(value) => value.codes.length().to_uint64()
  }
  let fd_ranges = match keying.keying.fd_select {
    None => 0UL
    Some(value) => value.range_count
  }
  let fd_selector_entries = match keying.keying.fd_select {
    None => 0UL
    Some(value) => value.selectors.length().to_uint64()
  }
  let charset_entries = keying.keying.charset.values.length().to_uint64()
  let sid_cid_lookups = match
    @checked.checked_add(
      charset_entries,
      match
        @checked.checked_add(
          encoding_entries,
          if keying.keying.cid_keyed { 2UL } else { 0UL },
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let dict_units = match
    @checked.checked_add(top.dict_units, keying.dict_units) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scratch_allocation_size = if keying.keying.charset.predefined is None {
    8192UL
  } else {
    3032UL
  }
  let scratch_allocation_size = match keying.keying.encoding {
    Some(value) if value.predefined is Some(_) =>
      if scratch_allocation_size > 2048UL {
        scratch_allocation_size
      } else {
        2048UL
      }
    Some(_) =>
      if scratch_allocation_size > 256UL {
        scratch_allocation_size
      } else {
        256UL
      }
    None => scratch_allocation_size
  }
  let charge = match
    cff_admission_charge(
      charge_bytes,
      directory,
      cff,
      indexes,
      dict_units,
      charset_entries,
      encoding_entries,
      fd_ranges,
      fd_selector_entries,
      sid_cid_lookups,
      keying.glyphs.length().to_uint64(),
      keying.keying.fd_count,
      header_size,
      scratch_allocation_size,
      keying.keying.cid_keyed,
      limits,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ledger = FontAdmissionLedger::new(
    budget,
    FontAdmissionCommitMode::CollectionDeferred,
  )
  match
    ledger.preflight_atomic(
      limits.max_work(),
      charge.work,
      charge.resource,
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if source.mutation_revision() != opening_revision {
    return Err(
      @error.CoreError::new(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        operation="font-cff-admit",
        context="font-cff-source-revision-drift",
      ),
    )
  }
  match ledger.commit_atomic(charge.resource) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({
    top,
    name,
    strings,
    global_subrs,
    charstrings,
    keying: keying.keying,
    glyphs: keying.glyphs,
    glyph: keying.glyphs[gid.to_int()],
    num_glyphs,
    charge,
    directory_start,
    cff_table_offset: cff.offset,
  })
}

///|
#warnings("-1")
fn admit_cff1_structure(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
  gid : UInt64,
) -> Result[AdmittedCff1, @error.CoreError] {
  admit_cff1_structure_at_after_preflight(
    source,
    0UL,
    None,
    FontChecksumMode::Standalone,
    false,
    limits,
    budget,
    gid,
    fn() { () },
  )
}

///|
fn admit_cff1_collection_structure_after_preflight(
  source : @bytes.ByteView,
  directory_start : UInt64,
  expected_table_count : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
  gid : UInt64,
  before_final_guard : () -> Unit,
) -> Result[AdmittedCff1, @error.CoreError] {
  admit_cff1_structure_at_after_preflight(
    source,
    directory_start,
    Some(expected_table_count),
    FontChecksumMode::Collection,
    true,
    limits,
    budget,
    gid,
    before_final_guard,
  )
}

///|
#warnings("-1")
fn admit_cff1_collection_structure(
  source : @bytes.ByteView,
  directory_start : UInt64,
  expected_table_count : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
  gid : UInt64,
) -> Result[AdmittedCff1, @error.CoreError] {
  admit_cff1_collection_structure_after_preflight(
    source,
    directory_start,
    expected_table_count,
    limits,
    budget,
    gid,
    fn() { () },
  )
}
