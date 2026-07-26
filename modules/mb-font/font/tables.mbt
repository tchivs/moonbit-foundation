///|
priv struct FontHeadFacts {
  units_per_em : UInt64
  index_to_loc_format : Int
}

///|
fn font_table_source_offset(
  record : FontTableRecord,
  relative : UInt64,
) -> Result[UInt64, @error.CoreError] {
  @checked.checked_add(record.offset, relative)
}

///|
fn decode_head_table(
  record : FontTableRecord,
) -> Result[FontHeadFacts, @error.CoreError] {
  if record.length < 54UL {
    return Err(
      font_data_error(
        "font-head-length",
        source_offset=record.offset,
        requested=54UL,
        limit=record.length,
      ),
    )
  }
  let version = match read_u32(record.view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if version != 0x00010000UL {
    return Err(
      font_data_error("font-head-version", source_offset=record.offset),
    )
  }
  let magic_source_offset = match font_table_source_offset(record, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let magic = match read_u32(record.view, 12UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if magic != 0x5F0F3CF5UL {
    return Err(
      font_data_error("font-head-magic", source_offset=magic_source_offset),
    )
  }
  let units_source_offset = match font_table_source_offset(record, 18UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let units_per_em = match read_u16(record.view, 18UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if units_per_em < 16UL || units_per_em > 16384UL {
    return Err(
      font_data_error(
        "font-units-per-em",
        source_offset=units_source_offset,
        requested=units_per_em,
        limit=16384UL,
      ),
    )
  }
  let loca_source_offset = match font_table_source_offset(record, 50UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let index_to_loc_format = match read_i16(record.view, 50UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if index_to_loc_format != 0 && index_to_loc_format != 1 {
    return Err(
      font_data_error(
        "font-index-to-loc-format",
        source_offset=loca_source_offset,
      ),
    )
  }
  Ok({ units_per_em, index_to_loc_format })
}
