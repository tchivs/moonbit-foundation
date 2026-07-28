///|
priv struct Type2GeometryFacts {
  current_x : Type2Fixed
  current_y : Type2Fixed
  points : UInt64
  contours : UInt64
  commands : UInt64
  has_segments : Bool
  min_x : Type2Fixed
  min_y : Type2Fixed
  max_x : Type2Fixed
  max_y : Type2Fixed
  bounds : GlyphBoundsFacts?
}

///|
priv struct Type2BoundsSink {
  mut current_x : Type2Fixed
  mut current_y : Type2Fixed
  mut contour_start_x : Type2Fixed
  mut contour_start_y : Type2Fixed
  mut contour_open : Bool
  mut points : UInt64
  mut contours : UInt64
  mut commands : UInt64
  mut has_segments : Bool
  mut min_x : Type2Fixed
  mut min_y : Type2Fixed
  mut max_x : Type2Fixed
  mut max_y : Type2Fixed
  mut transformed_min_x : Type2Rational
  mut transformed_min_y : Type2Rational
  mut transformed_max_x : Type2Rational
  mut transformed_max_y : Type2Rational
  matrix : Type2Matrix
  limits : Type2Limits
}

///|
fn type2_identity_matrix() -> Type2Matrix {
  let zero : Type2Rational = { numerator: 0L, denominator: 1L }
  let one : Type2Rational = { numerator: 1L, denominator: 1L }
  { a: one, b: zero, c: zero, d: one, tx: zero, ty: zero }
}

///|
fn Type2BoundsSink::new(
  matrix : Type2Matrix,
  limits : Type2Limits,
) -> Type2BoundsSink {
  let zero : Type2Fixed = { raw: 0L }
  let rational_zero : Type2Rational = { numerator: 0L, denominator: 1L }
  {
    current_x: zero,
    current_y: zero,
    contour_start_x: zero,
    contour_start_y: zero,
    contour_open: false,
    points: 0UL,
    contours: 0UL,
    commands: 0UL,
    has_segments: false,
    min_x: zero,
    min_y: zero,
    max_x: zero,
    max_y: zero,
    transformed_min_x: rational_zero,
    transformed_min_y: rational_zero,
    transformed_max_x: rational_zero,
    transformed_max_y: rational_zero,
    matrix,
    limits,
  }
}

///|
fn Type2BoundsSink::snapshot(self : Type2BoundsSink) -> Type2BoundsSink {
  {
    current_x: self.current_x,
    current_y: self.current_y,
    contour_start_x: self.contour_start_x,
    contour_start_y: self.contour_start_y,
    contour_open: self.contour_open,
    points: self.points,
    contours: self.contours,
    commands: self.commands,
    has_segments: self.has_segments,
    min_x: self.min_x,
    min_y: self.min_y,
    max_x: self.max_x,
    max_y: self.max_y,
    transformed_min_x: self.transformed_min_x,
    transformed_min_y: self.transformed_min_y,
    transformed_max_x: self.transformed_max_x,
    transformed_max_y: self.transformed_max_y,
    matrix: self.matrix,
    limits: self.limits,
  }
}

///|
fn type2_geometry_checked_total(
  current : UInt64,
  added : UInt64,
  limit : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  type2_checked_counter_add(current, added, limit, context)
}

///|
fn Type2BoundsSink::preflight(
  self : Type2BoundsSink,
  points : UInt64,
  contours : UInt64,
  commands : UInt64,
) -> Result[(UInt64, UInt64, UInt64), @error.CoreError] {
  let next_points = match
    type2_geometry_checked_total(
      self.points,
      points,
      self.limits.max_points,
      "font-cff-type2-points",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next_contours = match
    type2_geometry_checked_total(
      self.contours,
      contours,
      self.limits.max_contours,
      "font-cff-type2-contours",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next_commands = match
    type2_geometry_checked_total(
      self.commands,
      commands,
      self.limits.max_commands,
      "font-cff-type2-commands",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok((next_points, next_contours, next_commands))
}

///|
fn type2_geometry_coordinate_add(
  current : Type2Fixed,
  delta : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  match type2_fixed_add(current, delta) {
    Err(_) => Err(type2_data_error("font-cff-type2-coordinate"))
    Ok(value) => Ok(value)
  }
}

///|
fn type2_rational_less(
  left : Type2Rational,
  right : Type2Rational,
) -> Result[Bool, @error.CoreError] {
  let left_scaled = match
    type2_checked_i64_mul(left.numerator, right.denominator) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let right_scaled = match
    type2_checked_i64_mul(right.numerator, left.denominator) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(left_scaled < right_scaled)
}

///|
fn Type2BoundsSink::include_point(
  self : Type2BoundsSink,
  x : Type2Fixed,
  y : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let transformed = match type2_matrix_apply(self.matrix, x, y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if !self.has_segments {
    self.min_x = x
    self.min_y = y
    self.max_x = x
    self.max_y = y
    self.transformed_min_x = transformed.0
    self.transformed_min_y = transformed.1
    self.transformed_max_x = transformed.0
    self.transformed_max_y = transformed.1
  } else {
    if x.raw < self.min_x.raw {
      self.min_x = x
    }
    if y.raw < self.min_y.raw {
      self.min_y = y
    }
    if x.raw > self.max_x.raw {
      self.max_x = x
    }
    if y.raw > self.max_y.raw {
      self.max_y = y
    }
    let less_x = match
      type2_rational_less(transformed.0, self.transformed_min_x) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if less_x {
      self.transformed_min_x = transformed.0
    }
    let less_y = match
      type2_rational_less(transformed.1, self.transformed_min_y) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if less_y {
      self.transformed_min_y = transformed.1
    }
    let greater_x = match
      type2_rational_less(self.transformed_max_x, transformed.0) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if greater_x {
      self.transformed_max_x = transformed.0
    }
    let greater_y = match
      type2_rational_less(self.transformed_max_y, transformed.1) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if greater_y {
      self.transformed_max_y = transformed.1
    }
  }
  self.has_segments = true
  Ok(())
}

///|
fn Type2BoundsSink::move_relative(
  self : Type2BoundsSink,
  dx : Type2Fixed,
  dy : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let closing = if self.contour_open { 1UL } else { 0UL }
  let totals = match self.preflight(1UL, 1UL, 1UL + closing) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let x = match type2_geometry_coordinate_add(self.current_x, dx) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y = match type2_geometry_coordinate_add(self.current_y, dy) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.current_x = x
  self.current_y = y
  self.contour_start_x = x
  self.contour_start_y = y
  self.contour_open = true
  self.points = totals.0
  self.contours = totals.1
  self.commands = totals.2
  Ok(())
}

///|
fn Type2BoundsSink::preflight_segments(
  self : Type2BoundsSink,
  points : UInt64,
  commands : UInt64,
) -> Result[Unit, @error.CoreError] {
  if !self.contour_open {
    return Err(type2_data_error("font-cff-type2-no-current-contour"))
  }
  let totals = match self.preflight(points, 0UL, commands) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.points = totals.0
  self.contours = totals.1
  self.commands = totals.2
  Ok(())
}

///|
fn Type2BoundsSink::line_relative_unchecked(
  self : Type2BoundsSink,
  dx : Type2Fixed,
  dy : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let start_x = self.current_x
  let start_y = self.current_y
  let x = match type2_geometry_coordinate_add(start_x, dx) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let y = match type2_geometry_coordinate_add(start_y, dy) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if !self.has_segments {
    match self.include_point(start_x, start_y) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match self.include_point(x, y) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.current_x = x
  self.current_y = y
  Ok(())
}

///|
fn Type2BoundsSink::cubic_relative_unchecked(
  self : Type2BoundsSink,
  dx1 : Type2Fixed,
  dy1 : Type2Fixed,
  dx2 : Type2Fixed,
  dy2 : Type2Fixed,
  dx3 : Type2Fixed,
  dy3 : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let start_x = self.current_x
  let start_y = self.current_y
  let control1_x = match type2_geometry_coordinate_add(start_x, dx1) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let control1_y = match type2_geometry_coordinate_add(start_y, dy1) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let control2_x = match type2_geometry_coordinate_add(control1_x, dx2) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let control2_y = match type2_geometry_coordinate_add(control1_y, dy2) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let end_x = match type2_geometry_coordinate_add(control2_x, dx3) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let end_y = match type2_geometry_coordinate_add(control2_y, dy3) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if !self.has_segments {
    match self.include_point(start_x, start_y) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  for point in [
    (control1_x, control1_y),
    (control2_x, control2_y),
    (end_x, end_y),
  ] {
    match self.include_point(point.0, point.1) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  self.current_x = end_x
  self.current_y = end_y
  Ok(())
}

///|
fn Type2BoundsSink::close(
  self : Type2BoundsSink,
) -> Result[Unit, @error.CoreError] {
  if !self.contour_open {
    return Ok(())
  }
  let totals = match self.preflight(0UL, 0UL, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.commands = totals.2
  self.contour_open = false
  Ok(())
}

///|
fn Type2BoundsSink::facts(
  self : Type2BoundsSink,
) -> Result[Type2GeometryFacts, @error.CoreError] {
  let bounds = if self.has_segments {
    Some({
      x_min: match type2_rational_floor(self.transformed_min_x) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
      y_min: match type2_rational_floor(self.transformed_min_y) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
      x_max: match type2_rational_ceil(self.transformed_max_x) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
      y_max: match type2_rational_ceil(self.transformed_max_y) {
        Err(error) => return Err(error)
        Ok(value) => value
      },
    })
  } else {
    None
  }
  Ok({
    current_x: self.current_x,
    current_y: self.current_y,
    points: self.points,
    contours: self.contours,
    commands: self.commands,
    has_segments: self.has_segments,
    min_x: self.min_x,
    min_y: self.min_y,
    max_x: self.max_x,
    max_y: self.max_y,
    bounds,
  })
}
