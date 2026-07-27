///|
priv struct OutlinePoint {
  x_q15 : Int64
  y_q15 : Int64
  on_curve : Bool
}

///|
priv struct OutlineGeometry {
  points : Array[OutlinePoint]
  endpoints : Array[UInt64]
}

///|
priv struct F2Dot14Matrix {
  xscale_raw : Int64
  scale01_raw : Int64
  scale10_raw : Int64
  yscale_raw : Int64
}

///|
priv struct OutlineWork {
  mut used : UInt64
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
  if (right > 0L && left > max - right) || (right < 0L && left < min - right) {
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
    if right > 0L {
      left > max / right
    } else {
      right < min / left
    }
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
fn outline_checked_subtract(
  left : Int64,
  right : Int64,
) -> Result[Int64, @error.CoreError] {
  let min = -9223372036854775807L - 1L
  if right == min {
    if left >= 0L {
      Err(font_outline_data_error("font-outline-arithmetic"))
    } else {
      Ok(left - right)
    }
  } else {
    outline_checked_add(left, -right)
  }
}

///|
fn outline_checked_sum_of_products(
  left_a : Int64,
  left_b : Int64,
  right_a : Int64,
  right_b : Int64,
) -> Result[Int64, @error.CoreError] {
  let left = match outline_checked_mul(left_a, left_b) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let right = match outline_checked_mul(right_a, right_b) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  outline_checked_add(left, right)
}

///|
fn transform_q15(
  point : OutlinePoint,
  matrix : F2Dot14Matrix,
) -> Result[OutlinePoint, @error.CoreError] {
  let x_num = match
    outline_checked_sum_of_products(
      matrix.xscale_raw,
      point.x_q15,
      matrix.scale10_raw,
      point.y_q15,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y_num = match
    outline_checked_sum_of_products(
      matrix.scale01_raw,
      point.x_q15,
      matrix.yscale_raw,
      point.y_q15,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    x_q15: x_num / 16384L,
    y_q15: y_num / 16384L,
    on_curve: point.on_curve,
  })
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
  ledger : OutlineWork,
  budget : @budget.Budget,
  max_work : UInt64,
  work : UInt64,
) -> Result[Unit, @error.CoreError] {
  let total = match @checked.checked_add(ledger.used, work) {
    Err(_) => return Err(font_outline_data_error("font-outline-work"))
    Ok(value) => value
  }
  if total > max_work {
    return Err(font_outline_limit_error("max-work", total, max_work))
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
  match budget.charge(charge) {
    Err(error) => Err(error)
    Ok(_) => {
      ledger.used = total
      Ok(())
    }
  }
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
  ledger : OutlineWork,
  max_work : UInt64,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  let contour_commands = match
    @checked.checked_mul(endpoints.length().to_uint64(), 2UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-command-bound"))
    Ok(value) => value
  }
  let command_bound = match
    @checked.checked_add(points.length().to_uint64(), contour_commands) {
    Err(_) => return Err(font_outline_data_error("font-outline-command-bound"))
    Ok(value) => value
  }
  match font_outline_charge_work(ledger, budget, max_work, command_bound) {
    Err(error) => return Err(error)
    Ok(_) => ()
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
fn font_decode_simple_geometry(
  source : @bytes.ByteView,
  contour_count : UInt64,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[OutlineGeometry, @error.CoreError] {
  if contour_count > maxp.max_contours {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-contours",
        requested=contour_count,
        limit=maxp.max_contours,
      ),
    )
  }
  if contour_count > limits.max_outline_contours() {
    return Err(
      font_outline_limit_error(
        "max-outline-contours",
        contour_count,
        limits.max_outline_contours(),
      ),
    )
  }
  match
    font_outline_charge_work(ledger, budget, limits.max_work(), contour_count) {
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
        Err(_) =>
          return Err(font_outline_data_error("font-outline-point-count"))
        Ok(result) => result
      }
  }
  if point_count > maxp.max_points {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-points",
        requested=point_count,
        limit=maxp.max_points,
      ),
    )
  }
  if point_count > limits.max_outline_points() {
    return Err(
      font_outline_limit_error(
        "max-outline-points",
        point_count,
        limits.max_outline_points(),
      ),
    )
  }
  let instruction_length = match read_u16(source, endpoints_end) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  let instruction_start = match @checked.checked_add(endpoints_end, 2UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  if instruction_length > maxp.max_size_of_instructions {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-instructions",
        requested=instruction_length,
        limit=maxp.max_size_of_instructions,
      ),
    )
  }
  if instruction_length > limits.max_outline_instruction_bytes() {
    return Err(
      font_outline_limit_error(
        "max-outline-instruction-bytes",
        instruction_length,
        limits.max_outline_instruction_bytes(),
      ),
    )
  }
  match
    font_outline_charge_work(
      ledger,
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
  match
    font_outline_charge_work(ledger, budget, limits.max_work(), point_work) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_outline_charge_allocation(budget, point_count * 32UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let flags : Array[UInt64] = []
  let mut stored_flag_index = 0UL
  while flags.length().to_uint64() < point_count {
    let flag = match read_u8(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-flags"))
      Ok(value) => value.to_uint64()
    }
    if (flag & 0x80UL) != 0UL ||
      ((flag & 0x40UL) != 0UL && stored_flag_index != 0UL) {
      return Err(font_outline_data_error("font-outline-flags"))
    }
    cursor = cursor + 1UL
    let repeat = if (flag & 0x08UL) != 0UL {
      let value = match read_u8(source, cursor) {
        Err(_) => return Err(font_outline_data_error("font-outline-flags"))
        Ok(byte) => byte.to_uint64()
      }
      cursor = cursor + 1UL
      value
    } else {
      0UL
    }
    let expansion = match @checked.checked_add(repeat, 1UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-flags"))
      Ok(value) => value
    }
    let expanded = match
      @checked.checked_add(flags.length().to_uint64(), expansion) {
      Err(_) => return Err(font_outline_data_error("font-outline-flags"))
      Ok(value) => value
    }
    if expanded > point_count {
      return Err(
        font_outline_data_error(
          "font-outline-flags",
          requested=expanded,
          limit=point_count,
        ),
      )
    }
    for _copy = 0UL; _copy < expansion; _copy = _copy + 1UL {
      flags.push(flag & 0x3FUL)
    }
    stored_flag_index = stored_flag_index + 1UL
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
  let x_min = match read_i16(source, 2UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value.to_int64()
  }
  let y_min = match read_i16(source, 4UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value.to_int64()
  }
  let x_max = match read_i16(source, 6UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value.to_int64()
  }
  let y_max = match read_i16(source, 8UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value.to_int64()
  }
  let mut actual_x_min = x_values[0]
  let mut actual_x_max = x_values[0]
  let mut actual_y_min = points[0].y_q15 / 32768L
  let mut actual_y_max = actual_y_min
  for index = 0; index < points.length(); index = index + 1 {
    let point_x = x_values[index]
    let point_y = points[index].y_q15 / 32768L
    if point_x < actual_x_min {
      actual_x_min = point_x
    }
    if point_x > actual_x_max {
      actual_x_max = point_x
    }
    if point_y < actual_y_min {
      actual_y_min = point_y
    }
    if point_y > actual_y_max {
      actual_y_max = point_y
    }
  }
  if actual_x_min != x_min ||
    actual_y_min != y_min ||
    actual_x_max != x_max ||
    actual_y_max != y_max {
    return Err(font_outline_data_error("font-outline-bounds"))
  }
  Ok({ points, endpoints })
}

///|
fn font_decode_simple_outline(
  source : @bytes.ByteView,
  contour_count : UInt64,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  let geometry = match
    font_decode_simple_geometry(
      source,
      contour_count,
      maxp,
      limits,
      ledger,
      budget,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  font_outline_lower_contours(
    geometry.points,
    geometry.endpoints,
    ledger,
    limits.max_work(),
    budget,
  )
}

///|
fn font_decode_zero_contour_outline(
  source : @bytes.ByteView,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  if source.length() == 10UL {
    return Ok(@math.Path2::new())
  }
  let instruction_length = match read_u16(source, 10UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
    Ok(value) => value
  }
  if instruction_length > maxp.max_size_of_instructions {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-instructions",
        requested=instruction_length,
        limit=maxp.max_size_of_instructions,
      ),
    )
  }
  if instruction_length > limits.max_outline_instruction_bytes() {
    return Err(
      font_outline_limit_error(
        "max-outline-instruction-bytes",
        instruction_length,
        limits.max_outline_instruction_bytes(),
      ),
    )
  }
  match
    font_outline_charge_work(
      ledger,
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
fn font_outline_read_i8(
  source : @bytes.ByteView,
  offset : UInt64,
) -> Result[Int64, @error.CoreError] {
  let value = match read_u8(source, offset) {
    Err(_) => return Err(font_outline_data_error("font-outline-component-args"))
    Ok(byte) => byte.to_int()
  }
  Ok((if value >= 128 { value - 256 } else { value }).to_int64())
}

///|
fn font_decode_tracer_composite_outline(
  source : @bytes.ByteView,
  index : MetricIndexFacts,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  if maxp.max_component_depth < 1UL {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-component-depth",
        requested=1UL,
        limit=maxp.max_component_depth,
      ),
    )
  }
  if maxp.max_component_elements < 1UL {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-components",
        requested=1UL,
        limit=maxp.max_component_elements,
      ),
    )
  }
  if limits.max_outline_components() < 1UL {
    return Err(
      font_outline_limit_error(
        "max-outline-components",
        1UL,
        limits.max_outline_components(),
      ),
    )
  }
  match font_outline_charge_work(ledger, budget, limits.max_work(), 1UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let flags = match read_u16(source, 10UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-component"))
    Ok(value) => value
  }
  let child_index = match read_u16(source, 12UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-component"))
    Ok(value) => value
  }
  if child_index >= index.num_glyphs {
    return Err(
      font_outline_data_error(
        "font-outline-component-glyph",
        requested=child_index,
        limit=index.num_glyphs,
      ),
    )
  }
  if (flags & 0xE010UL) != 0UL {
    return Err(font_outline_data_error("font-outline-component-flags"))
  }
  if (flags & 0x0004UL) != 0UL {
    return Err(font_outline_capability_error("font-outline-grid-rounding"))
  }
  if (flags & 0x0020UL) != 0UL {
    return Err(font_outline_capability_error("font-outline-components"))
  }
  if (flags & 0x0002UL) == 0UL {
    return Err(font_outline_data_error("font-outline-first-component-xy"))
  }
  if (flags & 0x1800UL) == 0x1800UL {
    return Err(font_outline_data_error("font-outline-component-offset-flags"))
  }
  let transform_count = (if (flags & 0x0008UL) != 0UL { 1 } else { 0 }) +
    (if (flags & 0x0040UL) != 0UL { 1 } else { 0 }) +
    (if (flags & 0x0080UL) != 0UL { 1 } else { 0 })
  if transform_count > 1 {
    return Err(font_outline_data_error("font-outline-component-transform"))
  }
  let words = (flags & 0x0001UL) != 0UL
  let (arg1, arg2, start_cursor) = if words {
    let first = match read_i16(source, 14UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-args"))
      Ok(value) => value.to_int64()
    }
    let second = match read_i16(source, 16UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-args"))
      Ok(value) => value.to_int64()
    }
    (first, second, 18UL)
  } else {
    let first = match font_outline_read_i8(source, 14UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let second = match font_outline_read_i8(source, 15UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    (first, second, 16UL)
  }
  let mut cursor = start_cursor
  let mut matrix : F2Dot14Matrix = {
    xscale_raw: 16384L,
    scale01_raw: 0L,
    scale10_raw: 0L,
    yscale_raw: 16384L,
  }
  if (flags & 0x0008UL) != 0UL {
    let scale = match read_i16(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    matrix = {
      xscale_raw: scale,
      scale01_raw: 0L,
      scale10_raw: 0L,
      yscale_raw: scale,
    }
    cursor = cursor + 2UL
  } else if (flags & 0x0040UL) != 0UL {
    let xscale = match read_i16(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    let yscale = match read_i16(source, cursor + 2UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    matrix = {
      xscale_raw: xscale,
      scale01_raw: 0L,
      scale10_raw: 0L,
      yscale_raw: yscale,
    }
    cursor = cursor + 4UL
  } else if (flags & 0x0080UL) != 0UL {
    let xscale = match read_i16(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    let scale01 = match read_i16(source, cursor + 2UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    let scale10 = match read_i16(source, cursor + 4UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    let yscale = match read_i16(source, cursor + 6UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component-transform"))
      Ok(value) => value.to_int64()
    }
    matrix = { xscale_raw: xscale, scale01_raw: scale01, scale10_raw: scale10, yscale_raw: yscale }
    cursor = cursor + 8UL
  }
  if (flags & 0x0100UL) != 0UL {
    let instruction_length = match read_u16(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
      Ok(value) => value
    }
    if instruction_length > maxp.max_size_of_instructions {
      return Err(
        font_outline_data_error(
          "font-outline-maxp-instructions",
          requested=instruction_length,
          limit=maxp.max_size_of_instructions,
        ),
      )
    }
    if instruction_length > limits.max_outline_instruction_bytes() {
      return Err(
        font_outline_limit_error(
          "max-outline-instruction-bytes",
          instruction_length,
          limits.max_outline_instruction_bytes(),
        ),
      )
    }
    match
      font_outline_charge_work(
        ledger,
        budget,
        limits.max_work(),
        instruction_length,
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    cursor = cursor + 2UL
    match require_read_window(source, cursor, instruction_length) {
      Err(_) => return Err(font_outline_data_error("font-outline-instructions"))
      Ok(_) => ()
    }
    cursor = cursor + instruction_length
  }
  match font_outline_validate_trailing(source, cursor) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let child = match font_glyph_window(index, child_index) {
    Err(_) => return Err(font_outline_data_error("font-outline-component-glyph"))
    Ok(None) =>
      return font_outline_lower_contours(
        [],
        [],
        ledger,
        limits.max_work(),
        budget,
      )
    Ok(Some(value)) => value
  }
  if child.length() < 10UL {
    return Err(font_outline_data_error("font-outline-glyph-header"))
  }
  let contour_count = match read_i16(child, 0UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value
  }
  if contour_count < 0 {
    return Err(font_outline_capability_error("font-outline-nested-composite"))
  }
  let geometry = if contour_count == 0 {
    match
      font_decode_zero_contour_outline(
        child,
        maxp,
        limits,
        ledger,
        budget,
      ) {
      Err(error) => return Err(error)
      Ok(_) => { points: [], endpoints: [] }
    }
  } else {
    match
      font_decode_simple_geometry(
        child,
        contour_count.to_uint64(),
        maxp,
        limits,
        ledger,
        budget,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let point_count = geometry.points.length().to_uint64()
  let contour_total = geometry.endpoints.length().to_uint64()
  if point_count > maxp.max_composite_points {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-composite-points",
        requested=point_count,
        limit=maxp.max_composite_points,
      ),
    )
  }
  if contour_total > maxp.max_composite_contours {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-composite-contours",
        requested=contour_total,
        limit=maxp.max_composite_contours,
      ),
    )
  }
  match font_outline_charge_allocation(budget, point_count * 32UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let raw_offset : OutlinePoint = {
    x_q15: match outline_checked_mul(arg1, 32768L) {
      Err(error) => return Err(error)
      Ok(value) => value
    },
    y_q15: match outline_checked_mul(arg2, 32768L) {
      Err(error) => return Err(error)
      Ok(value) => value
    },
    on_curve: true,
  }
  let offset = if (flags & 0x0800UL) != 0UL {
    match transform_q15(raw_offset, matrix) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  } else {
    raw_offset
  }
  let placed : Array[OutlinePoint] = []
  for point in geometry.points {
    let transformed = match transform_q15(point, matrix) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    placed.push({
      x_q15: match outline_checked_add(transformed.x_q15, offset.x_q15) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
      y_q15: match outline_checked_add(transformed.y_q15, offset.y_q15) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
      on_curve: transformed.on_curve,
    })
  }
  font_outline_lower_contours(
    placed,
    geometry.endpoints,
    ledger,
    limits.max_work(),
    budget,
  )
}

///|
fn font_decode_outline(
  index : MetricIndexFacts,
  maxp : MaxpFacts,
  limits : FontLimits,
  glyph_index : UInt64,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  let ledger : OutlineWork = { used: 0UL }
  let glyph = match font_glyph_window(index, glyph_index) {
    Err(error) => return Err(error)
    Ok(None) => return Ok(@math.Path2::new())
    Ok(Some(value)) => value
  }
  if glyph.length() < 10UL {
    return Err(font_outline_data_error("font-outline-glyph-header"))
  }
  let contour_count = match read_i16(glyph, 0UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
    Ok(value) => value
  }
  if contour_count < 0 {
    return font_decode_tracer_composite_outline(
      glyph,
      index,
      maxp,
      limits,
      ledger,
      budget,
    )
  }
  if contour_count == 0 {
    font_decode_zero_contour_outline(glyph, maxp, limits, ledger, budget)
  } else {
    font_decode_simple_outline(
      glyph,
      contour_count.to_uint64(),
      maxp,
      limits,
      ledger,
      budget,
    )
  }
}
