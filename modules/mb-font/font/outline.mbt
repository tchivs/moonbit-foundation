///|
priv struct OutlinePoint {
  x_q15 : Int64
  y_q15 : Int64
  on_curve : Bool
}

///|
fn font_outline_data_error(
  context : String,
  requested? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-outline",
    requested?,
    limit?,
    context~,
  )
}

///|
fn font_outline_capability_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-outline",
    context~,
  )
}

///|
fn font_outline_limit_error(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="font-outline",
    requested~,
    limit~,
    context~,
  )
}

///|
fn outline_checked_add(
  left : Int64,
  right : Int64,
) -> Result[Int64, @error.CoreError] {
  let max = 9223372036854775807L
  let min = -9223372036854775807L - 1L
  if (right > 0L && left > max - right) ||
    (right < 0L && left < min - right) {
    Err(font_outline_data_error("font-outline-arithmetic"))
  } else {
    Ok(left + right)
  }
}

///|
fn outline_checked_mul(
  left : Int64,
  right : Int64,
) -> Result[Int64, @error.CoreError] {
  let max = 9223372036854775807L
  let min = -9223372036854775807L - 1L
  if left == 0L || right == 0L {
    return Ok(0L)
  }
  if (left == -1L && right == min) || (right == -1L && left == min) {
    return Err(font_outline_data_error("font-outline-arithmetic"))
  }
  let overflow = if left > 0L {
    if right > 0L { left > max / right } else { right < min / left }
  } else if right > 0L {
    left < min / right
  } else {
    left < max / right
  }
  if overflow {
    Err(font_outline_data_error("font-outline-arithmetic"))
  } else {
    Ok(left * right)
  }
}

///|
fn midpoint_q15(
  a : OutlinePoint,
  b : OutlinePoint,
) -> Result[OutlinePoint, @error.CoreError] {
  let x = match outline_checked_add(a.x_q15, b.x_q15) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y = match outline_checked_add(a.y_q15, b.y_q15) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ x_q15: x / 2L, y_q15: y / 2L, on_curve: true })
}

///|
fn contour_start(
  first : OutlinePoint,
  last : OutlinePoint,
) -> Result[OutlinePoint, @error.CoreError] {
  if first.on_curve {
    Ok(first)
  } else if last.on_curve {
    Ok(last)
  } else {
    midpoint_q15(last, first)
  }
}

///|
fn font_outline_point(point : OutlinePoint) -> @math.Point2 {
  @math.Point2::new(
    point.x_q15.to_double() / 32768.0,
    point.y_q15.to_double() / 32768.0,
  )
}

///|
fn font_outline_charge_work(
  budget : @budget.Budget,
  max_work : UInt64,
  work : UInt64,
) -> Result[Unit, @error.CoreError] {
  if work > max_work {
    return Err(font_outline_limit_error("max-work", work, max_work))
  }
  let charge = @budget.ResourceCharge::new(
    bytes=0UL,
    allocations=0UL,
    allocation_size=0UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work~,
  )
  match budget.preflight(charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  budget.charge(charge)
}

///|
fn font_outline_charge_allocation(
  budget : @budget.Budget,
  allocation_size : UInt64,
) -> Result[Unit, @error.CoreError] {
  let charge = @budget.ResourceCharge::new(
    bytes=0UL,
    allocations=1UL,
    allocation_size~,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=0UL,
  )
  match budget.preflight(charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  budget.charge(charge)
}

///|
fn font_outline_glyph_view(
  index : MetricIndexFacts,
  glyph_index : UInt64,
) -> Result[@bytes.ByteView?, @error.CoreError] {
  let current = match @checked.checked_narrow_int(glyph_index) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-window"))
    Ok(value) => value
  }
  let next = match @checked.checked_add(glyph_index, 1UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-window"))
    Ok(value) => value
  }
  let following = match @checked.checked_narrow_int(next) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-window"))
    Ok(value) => value
  }
  let start = index.loca_offsets[current]
  let end = index.loca_offsets[following]
  if start == end {
    return Ok(None)
  }
  let length = match @checked.checked_sub(end, start) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-window"))
    Ok(value) => value
  }
  if length < 10UL {
    return Err(
      font_outline_data_error(
        "font-outline-glyph-header",
        requested=length,
        limit=10UL,
      ),
    )
  }
  match index.glyf.view.subview(start, length) {
    Err(_) => Err(font_outline_data_error("font-outline-glyph-window"))
    Ok(value) => Ok(Some(value))
  }
}

///|
fn font_outline_read_delta(
  source : @bytes.ByteView,
  cursor : UInt64,
  short : Bool,
  same_or_positive : Bool,
) -> Result[(Int64, UInt64), @error.CoreError] {
  if short {
    let magnitude = match read_u8(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-coordinate"))
      Ok(value) => value.to_int64()
    }
    let next = match @checked.checked_add(cursor, 1UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-coordinate"))
      Ok(value) => value
    }
    Ok((if same_or_positive { magnitude } else { -magnitude }, next))
  } else if same_or_positive {
    Ok((0L, cursor))
  } else {
    let value = match read_i16(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-coordinate"))
      Ok(result) => result.to_int64()
    }
    let next = match @checked.checked_add(cursor, 2UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-coordinate"))
      Ok(result) => result
    }
    Ok((value, next))
  }
}

///|
fn font_outline_validate_trailing(
  source : @bytes.ByteView,
  cursor : UInt64,
) -> Result[Unit, @error.CoreError] {
  if cursor == source.length() {
    return Ok(())
  }
  let remaining = match @checked.checked_sub(source.length(), cursor) {
    Err(_) => return Err(font_outline_data_error("font-outline-trailing"))
    Ok(value) => value
  }
  if remaining == 1UL {
    let padding = match read_u8(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-trailing"))
      Ok(value) => value
    }
    if padding == b'\x00' {
      return Ok(())
    }
  }
  Err(
    font_outline_data_error(
      "font-outline-trailing",
      requested=remaining,
      limit=1UL,
    ),
  )
}

///|
fn font_outline_lower_contours(
  points : Array[OutlinePoint],
  endpoints : Array[UInt64],
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  let command_bound = match
    @checked.checked_add(
      points.length().to_uint64(),
      endpoints.length().to_uint64() * 2UL,
    ) {
    Err(_) => return Err(font_outline_data_error("font-outline-command-bound"))
    Ok(value) => value
  }
  match font_outline_charge_allocation(budget, command_bound * 32UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let path = @math.Path2::new()
  let mut contour_start_index = 0
  for endpoint in endpoints {
    let contour_end_index = match @checked.checked_narrow_int(endpoint) {
      Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
      Ok(value) => value
    }
    let first = points[contour_start_index]
    let last = points[contour_end_index]
    let start = match contour_start(first, last) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    path.push(@math.PathCommand::MoveTo(font_outline_point(start)))
    let mut index = if first.on_curve {
      contour_start_index + 1
    } else {
      contour_start_index
    }
    let traversal_end = if !first.on_curve && last.on_curve {
      contour_end_index - 1
    } else {
      contour_end_index
    }
    let mut control : OutlinePoint? = None
    while index <= traversal_end {
      let point = points[index]
      if point.on_curve {
        match control {
          None =>
            path.push(@math.PathCommand::LineTo(font_outline_point(point)))
          Some(value) => {
            path.push(
              @math.PathCommand::QuadTo(
                font_outline_point(value),
                font_outline_point(point),
              ),
            )
            control = None
          }
        }
      } else {
        match control {
          None => control = Some(point)
          Some(value) => {
            let implied = match midpoint_q15(value, point) {
              Err(error) => return Err(error)
              Ok(result) => result
            }
            path.push(
              @math.PathCommand::QuadTo(
                font_outline_point(value),
                font_outline_point(implied),
              ),
            )
            control = Some(point)
          }
        }
      }
      index = index + 1
    }
    match control {
      None => ()
      Some(value) =>
        path.push(
          @math.PathCommand::QuadTo(
            font_outline_point(value),
            font_outline_point(start),
          ),
        )
    }
    path.push(@math.PathCommand::Close)
    contour_start_index = contour_end_index + 1
  }
  Ok(path)
}

///|
fn font_decode_simple_outline(
  source : @bytes.ByteView,
  contour_count : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  match font_outline_charge_work(budget, limits.max_work(), contour_count) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let endpoint_bytes = match @checked.checked_mul(contour_count, 2UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
    Ok(value) => value
  }
  let endpoints_end = match @checked.checked_add(10UL, endpoint_bytes) {
    Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
    Ok(value) => value
  }
  match require_read_window(source, 10UL, endpoint_bytes) {
    Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
    Ok(_) => ()
  }
  let endpoints : Array[UInt64] = []
  let mut previous : UInt64? = None
  for contour = 0UL; contour < contour_count; contour = contour + 1UL {
    let offset = 10UL + contour * 2UL
    let endpoint = match read_u16(source, offset) {
      Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
      Ok(value) => value
    }
    match previous {
      Some(value) =>
        if endpoint <= value {
          return Err(font_outline_data_error("font-outline-endpoints"))
        }
      None => ()
    }
    endpoints.push(endpoint)
    previous = Some(endpoint)
  }
  let point_count = match previous {
    None => 0UL
    Some(value) =>
      match @checked.checked_add(value, 1UL) {
        Err(_) => return Err(font_outline_data_error("font-outline-point-count"))
        Ok(result) => result
      }
  }
  let instruction_length = match read_u16(source, endpoints_end) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  let instruction_start = match @checked.checked_add(endpoints_end, 2UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  match font_outline_charge_work(
    budget,
    limits.max_work(),
    instruction_length,
  ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match require_read_window(source, instruction_start, instruction_length) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(_) => ()
  }
  let mut cursor = match
    @checked.checked_add(instruction_start, instruction_length) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  let point_work = match @checked.checked_mul(point_count, 4UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-point-count"))
    Ok(value) => value
  }
  match font_outline_charge_work(budget, limits.max_work(), point_work) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_outline_charge_allocation(budget, point_count * 32UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let flags : Array[UInt64] = []
  for _point = 0UL; _point < point_count; _point = _point + 1UL {
    let flag = match read_u8(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-flags"))
      Ok(value) => value.to_uint64()
    }
    if (flag & 0x80UL) != 0UL || (flag & 0x08UL) != 0UL {
      return Err(font_outline_data_error("font-outline-flags"))
    }
    flags.push(flag)
    cursor = cursor + 1UL
  }
  let x_values : Array[Int64] = []
  let mut x = 0L
  for flag in flags {
    let (delta, next) = match
      font_outline_read_delta(
        source,
        cursor,
        (flag & 0x02UL) != 0UL,
        (flag & 0x10UL) != 0UL,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    x = match outline_checked_add(x, delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    x_values.push(x)
    cursor = next
  }
  let points : Array[OutlinePoint] = []
  let mut y = 0L
  for index = 0; index < flags.length(); index = index + 1 {
    let flag = flags[index]
    let (delta, next) = match
      font_outline_read_delta(
        source,
        cursor,
        (flag & 0x04UL) != 0UL,
        (flag & 0x20UL) != 0UL,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    y = match outline_checked_add(y, delta) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let x_q15 = match outline_checked_mul(x_values[index], 32768L) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let y_q15 = match outline_checked_mul(y, 32768L) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    points.push({ x_q15, y_q15, on_curve: (flag & 0x01UL) != 0UL })
    cursor = next
  }
  match font_outline_validate_trailing(source, cursor) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  font_outline_lower_contours(points, endpoints, budget)
}

///|
fn font_decode_zero_contour_outline(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  if source.length() == 10UL {
    return Ok(@math.Path2::new())
  }
  let instruction_length = match read_u16(source, 10UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  match font_outline_charge_work(
    budget,
    limits.max_work(),
    instruction_length,
  ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let cursor = match @checked.checked_add(12UL, instruction_length) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  match require_read_window(source, 12UL, instruction_length) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(_) => ()
  }
  match font_outline_validate_trailing(source, cursor) {
    Err(error) => return Err(error)
    Ok(_) => Ok(@math.Path2::new())
  }
}

///|
fn font_decode_outline(
  index : MetricIndexFacts,
  _maxp : MaxpFacts,
  limits : FontLimits,
  glyph_index : UInt64,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  let glyph = match font_outline_glyph_view(index, glyph_index) {
    Err(error) => return Err(error)
    Ok(None) => return Ok(@math.Path2::new())
    Ok(Some(value)) => value
  }
  let contour_count = match read_i16(glyph, 0UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value
  }
  if contour_count < 0 {
    return Err(font_outline_capability_error("font-outline-composite"))
  }
  if contour_count == 0 {
    font_decode_zero_contour_outline(glyph, limits, budget)
  } else {
    font_decode_simple_outline(
      glyph,
      contour_count.to_uint64(),
      limits,
      budget,
    )
  }
}
