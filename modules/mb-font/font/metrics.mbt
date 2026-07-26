///|
priv struct MetricIndexFacts {
  hmtx : TableWindow
  glyf : TableWindow
  loca_offsets : Array[UInt64]
  num_glyphs : UInt64
  number_of_h_metrics : UInt64
}

///|
priv struct GlyphBoundsFacts {
  x_min : Int
  y_min : Int
  x_max : Int
  y_max : Int
}

///|
priv struct GlyphHorizontalMetricFacts {
  advance_width : UInt64
  left_side_bearing : Int
  bounds : GlyphBoundsFacts?
  right_side_bearing : Int
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

///|
fn font_glyph_header_error(
  context : String,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-horizontal-metrics",
    requested?,
    limit?,
    context~,
  )
}

///|
fn font_signed_extent(
  lower : Int,
  upper : Int,
) -> Result[UInt64, @error.CoreError] {
  if upper < lower {
    return Err(
      font_glyph_header_error(
        "font-glyf-bounds",
        requested=lower.to_uint64(),
        limit=upper.to_uint64(),
      ),
    )
  }
  if lower >= 0 {
    @checked.checked_sub(upper.to_uint64(), lower.to_uint64())
  } else if upper < 0 {
    @checked.checked_sub((-lower).to_uint64(), (-upper).to_uint64())
  } else {
    @checked.checked_add((-lower).to_uint64(), upper.to_uint64())
  }
}

///|
fn font_signed_difference(
  left : UInt64,
  right : UInt64,
) -> Result[Int, @error.CoreError] {
  if left >= right {
    match @checked.checked_sub(left, right) {
      Err(error) => Err(error)
      Ok(value) => @checked.checked_narrow_int(value)
    }
  } else {
    let magnitude = match @checked.checked_sub(right, left) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match @checked.checked_narrow_int(magnitude) {
      Err(error) => Err(error)
      Ok(value) => Ok(-value)
    }
  }
}

///|
fn font_right_side_bearing(
  advance_width : UInt64,
  left_side_bearing : Int,
  extent : UInt64,
) -> Result[Int, @error.CoreError] {
  if left_side_bearing >= 0 {
    let occupied = match
      @checked.checked_add(left_side_bearing.to_uint64(), extent) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    font_signed_difference(advance_width, occupied)
  } else {
    let advance_plus_bearing = match
      @checked.checked_add(advance_width, (-left_side_bearing).to_uint64()) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    font_signed_difference(advance_plus_bearing, extent)
  }
}

///|
fn font_read_hmtx_metric(
  index : MetricIndexFacts,
  glyph : UInt64,
) -> Result[(UInt64, Int), @error.CoreError] {
  if glyph < index.number_of_h_metrics {
    let offset = match @checked.checked_mul(glyph, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let bearing_offset = match @checked.checked_add(offset, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let advance = match read_u16(index.hmtx.view, offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let bearing = match read_i16(index.hmtx.view, bearing_offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    Ok((advance, bearing))
  } else {
    let final_metric = match
      @checked.checked_sub(index.number_of_h_metrics, 1UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let final_offset = match @checked.checked_mul(final_metric, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let advance = match read_u16(index.hmtx.view, final_offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let tail_index = match
      @checked.checked_sub(glyph, index.number_of_h_metrics) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let tail_bytes = match @checked.checked_mul(tail_index, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let long_bytes = match
      @checked.checked_mul(index.number_of_h_metrics, 4UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let bearing_offset = match @checked.checked_add(long_bytes, tail_bytes) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let bearing = match read_i16(index.hmtx.view, bearing_offset) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    Ok((advance, bearing))
  }
}

///|
fn font_read_glyph_bounds(
  index : MetricIndexFacts,
  glyph : UInt64,
) -> Result[GlyphBoundsFacts?, @error.CoreError] {
  let glyph_index = match @checked.checked_narrow_int(glyph) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next_index = match @checked.checked_add(glyph, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next_glyph_index = match @checked.checked_narrow_int(next_index) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let start = index.loca_offsets[glyph_index]
  let end = index.loca_offsets[next_glyph_index]
  if start == end {
    return Ok(None)
  }
  let length = match @checked.checked_sub(end, start) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if length < 10UL {
    return Err(
      font_glyph_header_error(
        "font-glyf-header",
        requested=length,
        limit=10UL,
      ),
    )
  }
  let glyph_view = match index.glyf.view.subview(start, length) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let _number_of_contours = match read_i16(glyph_view, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let x_min = match read_i16(glyph_view, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y_min = match read_i16(glyph_view, 4UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let x_max = match read_i16(glyph_view, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y_max = match read_i16(glyph_view, 8UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if x_min > x_max || y_min > y_max {
    return Err(font_glyph_header_error("font-glyf-bounds"))
  }
  Ok(Some({ x_min, y_min, x_max, y_max }))
}

///|
fn font_lookup_horizontal_metrics(
  index : MetricIndexFacts,
  glyph : UInt64,
) -> Result[GlyphHorizontalMetricFacts, @error.CoreError] {
  let (advance_width, left_side_bearing) = match
    font_read_hmtx_metric(index, glyph) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let bounds = match font_read_glyph_bounds(index, glyph) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let extent = match bounds {
    None => 0UL
    Some(value) =>
      match font_signed_extent(value.x_min, value.x_max) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
  }
  let right_side_bearing = match
    font_right_side_bearing(advance_width, left_side_bearing, extent) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    advance_width,
    left_side_bearing,
    bounds,
    right_side_bearing,
  })
}
