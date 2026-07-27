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
priv enum CompositePlacement {
  ComponentXY(Int64, Int64)
  ComponentPoints(UInt64, UInt64)
}

///|
priv struct CompositeDescriptor {
  flags : UInt64
  glyph_index : UInt64
  placement : CompositePlacement
  matrix : F2Dot14Matrix
}

///|
priv struct CompositeParse {
  descriptors : Array[CompositeDescriptor]
  saw_grid_rounding : Bool
}

///|
priv struct CompositeFrame {
  glyph_index : UInt64
  descriptors : Array[CompositeDescriptor]
  mut next : Int
  depth : UInt64
}

///|
priv struct CompositeClassification {
  root_descriptors : Array[CompositeDescriptor]
  saw_deeper : Bool
  saw_grid_rounding : Bool
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
  Ok({ x_q15: x_num / 16384L, y_q15: y_num / 16384L, on_curve: point.on_curve })
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
fn font_outline_charge_allocations(
  budget : @budget.Budget,
  allocations : UInt64,
  allocation_size : UInt64,
) -> Result[Unit, @error.CoreError] {
  let charge = @budget.ResourceCharge::new(
    bytes=0UL,
    allocations~,
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
fn font_outline_charge_allocation(
  budget : @budget.Budget,
  allocation_size : UInt64,
) -> Result[Unit, @error.CoreError] {
  font_outline_charge_allocations(budget, 1UL, allocation_size)
}

///|
fn font_outline_empty_path(
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  match font_outline_charge_allocation(budget, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => Ok(@math.Path2::new())
  }
}

///|
fn font_outline_empty_geometry(
  budget : @budget.Budget,
) -> Result[OutlineGeometry, @error.CoreError] {
  match font_outline_charge_allocations(budget, 2UL, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => Ok({ points: [], endpoints: [] })
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
  if remaining <= 3UL {
    for offset = 0UL; offset < remaining; offset = offset + 1UL {
      let padding = match read_u8(source, cursor + offset) {
        Err(_) => return Err(font_outline_data_error("font-outline-trailing"))
        Ok(value) => value
      }
      if padding != b'\x00' {
        return Err(
          font_outline_data_error(
            "font-outline-trailing",
            requested=remaining,
            limit=3UL,
          ),
        )
      }
    }
    return Ok(())
  }
  Err(
    font_outline_data_error(
      "font-outline-trailing",
      requested=remaining,
      limit=3UL,
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
  let point_allocation_size = match @checked.checked_mul(point_count, 32UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-point-count"))
    Ok(value) => value
  }
  let endpoint_allocation_size = match
    @checked.checked_mul(contour_count, 8UL) {
    Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
    Ok(value) => value
  }
  let scratch_allocation_size = if point_allocation_size >
    endpoint_allocation_size {
    point_allocation_size
  } else {
    endpoint_allocation_size
  }
  match font_outline_charge_allocations(budget, 4UL, scratch_allocation_size) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let endpoints : Array[UInt64] = []
  for contour = 0UL; contour < contour_count; contour = contour + 1UL {
    let endpoint = match read_u16(source, 10UL + contour * 2UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-endpoints"))
      Ok(value) => value
    }
    endpoints.push(endpoint)
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
      source, contour_count, maxp, limits, ledger, budget,
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
    return font_outline_empty_path(budget)
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
    Ok(_) => font_outline_empty_path(budget)
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
fn font_parse_composite_descriptors(
  source : @bytes.ByteView,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[CompositeParse, @error.CoreError] {
  match
    font_outline_charge_allocation(budget, maxp.max_component_elements * 80UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let descriptors : Array[CompositeDescriptor] = []
  let mut cursor = 10UL
  let mut more = true
  let mut saw_grid_rounding = false
  let mut saw_instructions = false
  let mut metrics_components = 0UL
  while more {
    let component_count = descriptors.length().to_uint64() + 1UL
    if component_count > maxp.max_component_elements {
      return Err(
        font_outline_data_error(
          "font-outline-maxp-components",
          requested=component_count,
          limit=maxp.max_component_elements,
        ),
      )
    }
    if component_count > limits.max_outline_components() {
      return Err(
        font_outline_limit_error(
          "max-outline-components",
          component_count,
          limits.max_outline_components(),
        ),
      )
    }
    match font_outline_charge_work(ledger, budget, limits.max_work(), 1UL) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let flags = match read_u16(source, cursor) {
      Err(_) => return Err(font_outline_data_error("font-outline-component"))
      Ok(value) => value
    }
    let glyph_index = match read_u16(source, cursor + 2UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-component"))
      Ok(value) => value
    }
    cursor = cursor + 4UL
    if (flags & 0xE010UL) != 0UL {
      return Err(font_outline_data_error("font-outline-component-flags"))
    }
    if (flags & 0x0400UL) != 0UL && descriptors.length() != 0 {
      return Err(font_outline_data_error("font-outline-overlap-compound"))
    }
    if (flags & 0x0100UL) != 0UL {
      saw_instructions = true
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
    let xy = (flags & 0x0002UL) != 0UL
    if descriptors.length() == 0 && !xy {
      return Err(font_outline_data_error("font-outline-first-component-xy"))
    }
    if xy && (flags & 0x0004UL) != 0UL {
      saw_grid_rounding = true
    }
    if (flags & 0x0200UL) != 0UL {
      metrics_components = metrics_components + 1UL
      if metrics_components > 1UL {
        return Err(font_outline_data_error("font-outline-use-my-metrics"))
      }
    }
    let words = (flags & 0x0001UL) != 0UL
    let placement = if xy {
      let first = if words {
        match read_i16(source, cursor) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-component-args"))
          Ok(value) => value.to_int64()
        }
      } else {
        match font_outline_read_i8(source, cursor) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      }
      let second_offset = cursor + (if words { 2UL } else { 1UL })
      let second = if words {
        match read_i16(source, second_offset) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-component-args"))
          Ok(value) => value.to_int64()
        }
      } else {
        match font_outline_read_i8(source, second_offset) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      }
      ComponentXY(first, second)
    } else {
      let first = if words {
        match read_u16(source, cursor) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-component-args"))
          Ok(value) => value
        }
      } else {
        match read_u8(source, cursor) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-component-args"))
          Ok(value) => value.to_uint64()
        }
      }
      let second_offset = cursor + (if words { 2UL } else { 1UL })
      let second = if words {
        match read_u16(source, second_offset) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-component-args"))
          Ok(value) => value
        }
      } else {
        match read_u8(source, second_offset) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-component-args"))
          Ok(value) => value.to_uint64()
        }
      }
      ComponentPoints(first, second)
    }
    cursor = cursor + (if words { 4UL } else { 2UL })
    let mut matrix : F2Dot14Matrix = {
      xscale_raw: 16384L,
      scale01_raw: 0L,
      scale10_raw: 0L,
      yscale_raw: 16384L,
    }
    if (flags & 0x0008UL) != 0UL {
      let scale = match read_i16(source, cursor) {
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
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
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
        Ok(value) => value.to_int64()
      }
      let yscale = match read_i16(source, cursor + 2UL) {
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
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
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
        Ok(value) => value.to_int64()
      }
      let scale01 = match read_i16(source, cursor + 2UL) {
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
        Ok(value) => value.to_int64()
      }
      let scale10 = match read_i16(source, cursor + 4UL) {
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
        Ok(value) => value.to_int64()
      }
      let yscale = match read_i16(source, cursor + 6UL) {
        Err(_) =>
          return Err(
            font_outline_data_error("font-outline-component-transform"),
          )
        Ok(value) => value.to_int64()
      }
      matrix = {
        xscale_raw: xscale,
        scale01_raw: scale01,
        scale10_raw: scale10,
        yscale_raw: yscale,
      }
      cursor = cursor + 8UL
    }
    descriptors.push({ flags, glyph_index, placement, matrix })
    more = (flags & 0x0020UL) != 0UL
  }
  if saw_instructions {
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
    Ok(_) => Ok({ descriptors, saw_grid_rounding })
  }
}

///|
fn font_classify_composite_graph(
  root_glyph : UInt64,
  root_source : @bytes.ByteView,
  index : MetricIndexFacts,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[CompositeClassification, @error.CoreError] {
  if maxp.max_component_depth == 0UL {
    return Err(
      font_outline_data_error(
        "font-outline-maxp-component-depth",
        requested=1UL,
        limit=0UL,
      ),
    )
  }
  // Account for each Array[Int] entry as a conservative eight-byte portable slot.
  let state_allocation_size = match
    @checked.checked_mul(index.num_glyphs, 8UL) {
    Err(_) =>
      return Err(font_outline_data_error("font-outline-composite-state"))
    Ok(value) => value
  }
  match font_outline_charge_allocation(budget, state_allocation_size) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match
    font_outline_charge_allocation(budget, maxp.max_component_depth * 64UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let root = match
    font_parse_composite_descriptors(root_source, maxp, limits, ledger, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let states : Array[Int] = Array::make(index.num_glyphs.to_int(), 0)
  let root_index = root_glyph.to_int()
  states[root_index] = 1
  let stack : Array[CompositeFrame] = [
    {
      glyph_index: root_glyph,
      descriptors: root.descriptors,
      next: 0,
      depth: 1UL,
    },
  ]
  let mut total_components = root.descriptors.length().to_uint64()
  let mut saw_deeper = false
  let mut saw_grid_rounding = root.saw_grid_rounding
  while stack.length() > 0 {
    let frame = stack.pop().unwrap()
    if frame.next >= frame.descriptors.length() {
      states[frame.glyph_index.to_int()] = 2
      continue
    }
    let descriptor = frame.descriptors[frame.next]
    frame.next = frame.next + 1
    let parent_depth = frame.depth
    stack.push(frame)
    if descriptor.glyph_index >= index.num_glyphs {
      return Err(
        font_outline_data_error(
          "font-outline-component-glyph",
          requested=descriptor.glyph_index,
          limit=index.num_glyphs,
        ),
      )
    }
    let child = match font_glyph_window(index, descriptor.glyph_index) {
      Err(_) =>
        return Err(font_outline_data_error("font-outline-component-glyph"))
      Ok(None) => continue
      Ok(Some(value)) => value
    }
    if child.length() < 10UL {
      return Err(font_outline_data_error("font-outline-glyph-header"))
    }
    let contour_count = match read_i16(child, 0UL) {
      Err(_) => return Err(font_outline_data_error("font-outline-glyph-header"))
      Ok(value) => value
    }
    if contour_count >= 0 {
      continue
    }
    saw_deeper = true
    let child_state = states[descriptor.glyph_index.to_int()]
    if child_state == 1 {
      return Err(font_outline_data_error("font-outline-composite-cycle"))
    }
    if child_state == 2 {
      continue
    }
    let depth = parent_depth + 1UL
    if depth > maxp.max_component_depth {
      return Err(
        font_outline_data_error(
          "font-outline-maxp-component-depth",
          requested=depth,
          limit=maxp.max_component_depth,
        ),
      )
    }
    let parsed = match
      font_parse_composite_descriptors(child, maxp, limits, ledger, budget) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    total_components = match
      @checked.checked_add(
        total_components,
        parsed.descriptors.length().to_uint64(),
      ) {
      Err(_) => return Err(font_outline_data_error("font-outline-components"))
      Ok(value) => value
    }
    if total_components > limits.max_outline_components() {
      return Err(
        font_outline_limit_error(
          "max-outline-components",
          total_components,
          limits.max_outline_components(),
        ),
      )
    }
    if parsed.saw_grid_rounding {
      saw_grid_rounding = true
    }
    states[descriptor.glyph_index.to_int()] = 1
    stack.push({
      glyph_index: descriptor.glyph_index,
      descriptors: parsed.descriptors,
      next: 0,
      depth,
    })
  }
  Ok({ root_descriptors: root.descriptors, saw_deeper, saw_grid_rounding })
}

///|
fn font_outline_point_index(
  index : UInt64,
  real_count : UInt64,
  context : String,
) -> Result[Int, @error.CoreError] {
  if index < real_count {
    match @checked.checked_narrow_int(index) {
      Err(_) => Err(font_outline_data_error(context))
      Ok(value) => Ok(value)
    }
  } else if index < real_count + 4UL {
    Err(font_outline_capability_error("font-outline-phantom-point"))
  } else {
    Err(
      font_outline_data_error(context, requested=index, limit=real_count + 4UL),
    )
  }
}

///|
fn font_decode_composite_outline(
  root_glyph : UInt64,
  source : @bytes.ByteView,
  index : MetricIndexFacts,
  maxp : MaxpFacts,
  limits : FontLimits,
  ledger : OutlineWork,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  let graph = match
    font_classify_composite_graph(
      root_glyph, source, index, maxp, limits, ledger, budget,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if graph.saw_deeper {
    return Err(font_outline_capability_error("font-outline-nested-composite"))
  }
  if graph.saw_grid_rounding {
    return Err(font_outline_capability_error("font-outline-grid-rounding"))
  }
  let point_allocation_size = match
    @checked.checked_mul(maxp.max_composite_points, 32UL) {
    Err(_) =>
      return Err(font_outline_data_error("font-outline-composite-points"))
    Ok(value) => value
  }
  let endpoint_allocation_size = match
    @checked.checked_mul(maxp.max_composite_contours, 8UL) {
    Err(_) =>
      return Err(font_outline_data_error("font-outline-composite-contours"))
    Ok(value) => value
  }
  let scratch_allocation_size = if point_allocation_size >
    endpoint_allocation_size {
    point_allocation_size
  } else {
    endpoint_allocation_size
  }
  match font_outline_charge_allocations(budget, 2UL, scratch_allocation_size) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let parent_points : Array[OutlinePoint] = []
  let parent_endpoints : Array[UInt64] = []
  for descriptor_index = 0
      descriptor_index < graph.root_descriptors.length()
      descriptor_index = descriptor_index + 1 {
    let descriptor = graph.root_descriptors[descriptor_index]
    let child = match font_glyph_window(index, descriptor.glyph_index) {
      Err(_) =>
        return Err(font_outline_data_error("font-outline-component-glyph"))
      Ok(None) => None
      Ok(Some(value)) => Some(value)
    }
    let geometry : OutlineGeometry = match child {
      None =>
        match font_outline_empty_geometry(budget) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      Some(value) => {
        if value.length() < 10UL {
          return Err(font_outline_data_error("font-outline-glyph-header"))
        }
        let contour_count = match read_i16(value, 0UL) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-glyph-header"))
          Ok(result) => result
        }
        if contour_count < 0 {
          return Err(
            font_outline_capability_error("font-outline-nested-composite"),
          )
        }
        if contour_count == 0 {
          match
            font_decode_zero_contour_outline(
              value, maxp, limits, ledger, budget,
            ) {
            Err(error) => return Err(error)
            Ok(_) =>
              match font_outline_empty_geometry(budget) {
                Err(error) => return Err(error)
                Ok(result) => result
              }
          }
        } else {
          match
            font_decode_simple_geometry(
              value,
              contour_count.to_uint64(),
              maxp,
              limits,
              ledger,
              budget,
            ) {
            Err(error) => return Err(error)
            Ok(result) => result
          }
        }
      }
    }
    let child_points = geometry.points.length().to_uint64()
    let child_contours = geometry.endpoints.length().to_uint64()
    let total_points = match
      @checked.checked_add(parent_points.length().to_uint64(), child_points) {
      Err(_) =>
        return Err(font_outline_data_error("font-outline-composite-points"))
      Ok(value) => value
    }
    let total_contours = match
      @checked.checked_add(
        parent_endpoints.length().to_uint64(),
        child_contours,
      ) {
      Err(_) =>
        return Err(font_outline_data_error("font-outline-composite-contours"))
      Ok(value) => value
    }
    if total_points > maxp.max_composite_points {
      return Err(
        font_outline_data_error(
          "font-outline-maxp-composite-points",
          requested=total_points,
          limit=maxp.max_composite_points,
        ),
      )
    }
    if total_contours > maxp.max_composite_contours {
      return Err(
        font_outline_data_error(
          "font-outline-maxp-composite-contours",
          requested=total_contours,
          limit=maxp.max_composite_contours,
        ),
      )
    }
    if total_points > limits.max_outline_points() {
      return Err(
        font_outline_limit_error(
          "max-outline-points",
          total_points,
          limits.max_outline_points(),
        ),
      )
    }
    if total_contours > limits.max_outline_contours() {
      return Err(
        font_outline_limit_error(
          "max-outline-contours",
          total_contours,
          limits.max_outline_contours(),
        ),
      )
    }
    match
      font_outline_charge_work(
        ledger,
        budget,
        limits.max_work(),
        child_points * 2UL,
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    match font_outline_charge_allocation(budget, child_points * 32UL) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let transformed : Array[OutlinePoint] = []
    for point in geometry.points {
      transformed.push(
        match transform_q15(point, descriptor.matrix) {
          Err(error) => return Err(error)
          Ok(value) => value
        },
      )
    }
    let (translate_x, translate_y) = match descriptor.placement {
      ComponentXY(dx, dy) => {
        let raw : OutlinePoint = {
          x_q15: match outline_checked_mul(dx, 32768L) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
          y_q15: match outline_checked_mul(dy, 32768L) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
          on_curve: true,
        }
        let offset = if (descriptor.flags & 0x0800UL) != 0UL {
          match transform_q15(raw, descriptor.matrix) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
        } else {
          raw
        }
        (offset.x_q15, offset.y_q15)
      }
      ComponentPoints(parent_index, child_index) => {
        let parent = match
          font_outline_point_index(
            parent_index,
            parent_points.length().to_uint64(),
            "font-outline-parent-point",
          ) {
          Err(error) => return Err(error)
          Ok(value) => parent_points[value]
        }
        let child_point = match
          font_outline_point_index(
            child_index,
            transformed.length().to_uint64(),
            "font-outline-child-point",
          ) {
          Err(error) => return Err(error)
          Ok(value) => transformed[value]
        }
        let x = match
          outline_checked_subtract(parent.x_q15, child_point.x_q15) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let y = match
          outline_checked_subtract(parent.y_q15, child_point.y_q15) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        (x, y)
      }
    }
    let base = parent_points.length().to_uint64()
    for point in transformed {
      parent_points.push({
        x_q15: match outline_checked_add(point.x_q15, translate_x) {
          Err(error) => return Err(error)
          Ok(value) => value
        },
        y_q15: match outline_checked_add(point.y_q15, translate_y) {
          Err(error) => return Err(error)
          Ok(value) => value
        },
        on_curve: point.on_curve,
      })
    }
    for endpoint in geometry.endpoints {
      parent_endpoints.push(
        match @checked.checked_add(base, endpoint) {
          Err(_) =>
            return Err(font_outline_data_error("font-outline-endpoints"))
          Ok(value) => value
        },
      )
    }
  }
  font_outline_lower_contours(
    parent_points,
    parent_endpoints,
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
    Ok(None) => return font_outline_empty_path(budget)
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
    return font_decode_composite_outline(
      glyph_index, glyph, index, maxp, limits, ledger, budget,
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
