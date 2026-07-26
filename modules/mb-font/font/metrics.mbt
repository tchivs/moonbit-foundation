///|
priv struct MetricIndexFacts {
  hmtx : TableWindow
  glyf : TableWindow
  loca_offsets : Array[UInt64]
  num_glyphs : UInt64
  number_of_h_metrics : UInt64
}

///|
fn font_metric_cardinality_error(
  context : String,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  font_data_error(context, requested?, limit?)
}

///|
fn font_hmtx_required_length(
  num_glyphs : UInt64,
  number_of_h_metrics : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if num_glyphs == 0UL ||
    number_of_h_metrics == 0UL ||
    number_of_h_metrics > num_glyphs {
    return Err(
      font_metric_cardinality_error(
        "font-hmtx-cardinality",
        requested=number_of_h_metrics,
        limit=num_glyphs,
      ),
    )
  }
  let long_bytes = match @checked.checked_mul(number_of_h_metrics, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tail_count = match
    @checked.checked_sub(num_glyphs, number_of_h_metrics) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tail_bytes = match @checked.checked_mul(tail_count, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @checked.checked_add(long_bytes, tail_bytes)
}

///|
fn font_loca_required_length(
  num_glyphs : UInt64,
  index_to_loc_format : Int,
) -> Result[UInt64, @error.CoreError] {
  let entries = match @checked.checked_add(num_glyphs, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let width = match index_to_loc_format {
    0 => 2UL
    1 => 4UL
    _ =>
      return Err(
        font_metric_cardinality_error(
          "font-loca-cardinality",
          requested=index_to_loc_format.to_uint64(),
        ),
      )
  }
  @checked.checked_mul(entries, width)
}

///|
fn font_normalize_loca_offsets(
  loca : TableWindow,
  num_glyphs : UInt64,
  index_to_loc_format : Int,
  glyf_length : UInt64,
) -> Result[Array[UInt64], @error.CoreError] {
  let required = match
    font_loca_required_length(num_glyphs, index_to_loc_format) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if loca.length_value != required {
    return Err(
      font_metric_cardinality_error(
        "font-loca-cardinality",
        requested=required,
        limit=loca.length_value,
      ),
    )
  }
  let entries = match @checked.checked_add(num_glyphs, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let offsets : Array[UInt64] = []
  let mut previous = 0UL
  let mut index = 0UL
  while index < entries {
    let value = if index_to_loc_format == 0 {
      let field = match @checked.checked_mul(index, 2UL) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
      let encoded = match read_u16(loca.view, field) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
      match @checked.checked_mul(encoded, 2UL) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
    } else {
      let field = match @checked.checked_mul(index, 4UL) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
      match read_u32(loca.view, field) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
    }
    if value < previous || value > glyf_length {
      return Err(
        font_metric_cardinality_error(
          "font-loca-cardinality",
          requested=value,
          limit=glyf_length,
        ),
      )
    }
    offsets.push(value)
    previous = value
    index = index + 1UL
  }
  Ok(offsets)
}

///|
fn font_admit_metric_index(
  directory : DirectoryFacts,
  head : HeadFacts,
  maxp : MaxpFacts,
  hhea : HheaFacts,
) -> Result[MetricIndexFacts, @error.CoreError] {
  let hmtx = match font_table_window(directory, 0x686D7478UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let loca = match font_table_window(directory, 0x6C6F6361UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let glyf = match font_table_window(directory, 0x676C7966UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let hmtx_required = match
    font_hmtx_required_length(maxp.num_glyphs, hhea.number_of_h_metrics) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if hmtx.length_value != hmtx_required {
    return Err(
      font_metric_cardinality_error(
        "font-hmtx-cardinality",
        requested=hmtx_required,
        limit=hmtx.length_value,
      ),
    )
  }
  let loca_offsets = match
    font_normalize_loca_offsets(
      loca,
      maxp.num_glyphs,
      head.index_to_loc_format,
      glyf.length_value,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    hmtx,
    glyf,
    loca_offsets,
    num_glyphs: maxp.num_glyphs,
    number_of_h_metrics: hhea.number_of_h_metrics,
  })
}
