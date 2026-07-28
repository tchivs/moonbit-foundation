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
) -> Result[Unit, @error.CoreError] {
  match cff_require_window(source, 0UL, 12UL, "font-cff-sfnt-header") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let signature = match read_u32(source, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if signature != 0x4F54544FUL {
    return Err(cff_capability_error("font-cff-profile"))
  }
  let table_count = match read_u16(source, 4UL) {
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
  match
    cff_require_window(source, 12UL, record_bytes, "font-cff-directory-range") {
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
    let record = 12UL + index * 16UL
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
  source : @bytes.ByteView,
  directory : DirectoryFacts,
  cff : TableWindow,
  indexes : Array[CffIndex],
  descriptor_count : UInt64,
  fd_count : UInt64,
  limits : FontLimits,
) -> Result[@budget.ResourceCharge, @error.CoreError] {
  let mut retained_offsets = 0UL
  for index in indexes {
    retained_offsets = match
      @checked.checked_add(retained_offsets, index.offsets.length().to_uint64()) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
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
  let structural_bytes = match
    @checked.checked_add(offset_bytes, descriptor_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let retained_bytes = match @checked.checked_add(structural_bytes, fd_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let allocation_size = match
    @checked.checked_add(cff.length_value, retained_bytes) {
    Err(error) => return Err(error)
    Ok(value) => value
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
  let work = match
    @checked.checked_add(structural_work, complete_keying_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if work > limits.max_work() {
    return Err(font_limit_error("max-work", work, limits.max_work()))
  }
  Ok(
    @budget.ResourceCharge::new(
      bytes=source.length(),
      allocations=12UL + indexes.length().to_uint64(),
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work~,
    ),
  )
}

///|
#warnings("-1")
fn admit_cff1_structure(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
  gid : UInt64,
) -> Result[AdmittedCff1, @error.CoreError] {
  let opening_revision = source.mutation_revision()
  if source.length() > limits.max_source_bytes() {
    return Err(
      font_limit_error(
        "max-source-bytes",
        source.length(),
        limits.max_source_bytes(),
      ),
    )
  }
  match cff_preclassify_static_profile(source) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let directory = match font_parse_cff1_directory(source, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_validate_checksums(directory) {
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
  let keying = match
    cff_resolve_keying(cff, top, strings, charstrings, num_glyphs, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let indexes = [name, top_index, strings, global_subrs, charstrings]
  for index in keying.retained_indexes {
    indexes.push(index)
  }
  let charge = match
    cff_admission_charge(
      source,
      directory,
      cff,
      indexes,
      keying.glyphs.length().to_uint64(),
      keying.keying.fd_count,
      limits,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.preflight(charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if source.mutation_revision() != opening_revision {
    return Err(font_revision_error("font-cff-admit"))
  }
  match budget.charge(charge) {
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
  })
}
