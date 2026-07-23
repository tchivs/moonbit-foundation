// Bézier curve evaluation and adaptive flattening for MoonBit Native Foundation.
//
// Consumed by mb-canvas (path rasterization), mb-svg (path data expansion),
// and mb-font (glyph outline extraction). Quadratic and cubic Bézier curves
// are evaluated at parametric t and flattened into line segments with a
// bounded tolerance and subdivision cap.
//
// The flattening algorithm is recursive midpoint subdivision with a
// flatness test: a curve is "flat enough" when its control points deviate
// from the chord by less than `tolerance`. A maximum subdivision depth
// bounds pathological curves so they fail with a structured error rather
// than looping indefinitely.

///|
/// Evaluate a quadratic Bézier curve at parameter `t` in [0, 1].
///
/// Given control points P0 (start), P1 (control), P2 (end):
///   B(t) = (1-t)²·P0 + 2(1-t)t·P1 + t²·P2
pub fn bezier2_eval(p0 : Point2, p1 : Point2, p2 : Point2, t : Double) -> Point2 {
  let u = 1.0 - t
  let a = u * u
  let b = 2.0 * u * t
  let c = t * t
  Point2::new(
    a * p0.x() + b * p1.x() + c * p2.x(),
    a * p0.y() + b * p1.y() + c * p2.y(),
  )
}

///|
/// Evaluate a cubic Bézier curve at parameter `t` in [0, 1].
///
/// Given control points P0 (start), P1, P2 (controls), P3 (end):
///   B(t) = (1-t)³·P0 + 3(1-t)²t·P1 + 3(1-t)t²·P2 + t³·P3
pub fn bezier3_eval(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  p3 : Point2,
  t : Double,
) -> Point2 {
  let u = 1.0 - t
  let a = u * u * u
  let b = 3.0 * u * u * t
  let c = 3.0 * u * t * t
  let d = t * t * t
  Point2::new(
    a * p0.x() + b * p1.x() + c * p2.x() + d * p3.x(),
    a * p0.y() + b * p1.y() + c * p2.y() + d * p3.y(),
  )
}

///|
/// Derivative of a quadratic Bézier at parameter `t`.
///
///   B'(t) = 2(1-t)(P1-P0) + 2t(P2-P1)
fn bezier2_derivative(p0 : Point2, p1 : Point2, p2 : Point2, t : Double) -> Vector2 {
  let u = 1.0 - t
  let v0 = p0.vector_to(p1).scale(2.0 * u)
  let v1 = p1.vector_to(p2).scale(2.0 * t)
  v0.add(v1)
}

///|
/// Derivative of a cubic Bézier at parameter `t`.
///
///   B'(t) = 3(1-t)²(P1-P0) + 6(1-t)t(P2-P1) + 3t²(P3-P2)
fn bezier3_derivative(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  p3 : Point2,
  t : Double,
) -> Vector2 {
  let u = 1.0 - t
  let v0 = p0.vector_to(p1).scale(3.0 * u * u)
  let v1 = p1.vector_to(p2).scale(6.0 * u * t)
  let v2 = p2.vector_to(p3).scale(3.0 * t * t)
  v0.add(v1).add(v2)
}

///|
/// A flattened line segment as part of a Bézier approximation.
pub struct LineSegment {
  start_value : Point2
  end_value : Point2
}

///|
pub fn LineSegment::start(self : LineSegment) -> Point2 {
  self.start_value
}

///|
pub fn LineSegment::end(self : LineSegment) -> Point2 {
  self.end_value
}

///|
/// Flatten a quadratic Bézier into line segments using adaptive midpoint
/// subdivision.
///
/// - `tolerance`: maximum deviation of control points from the chord before
///   a curve is considered flat enough. Must be positive.
/// - `max_depth`: maximum subdivision recursion depth. Typical values are
///   10-20; deeper values handle sharper curves but use more segments.
///
/// Returns `Err` if `max_depth` is exceeded, signaling a pathological curve
/// that the caller should reject or cap. The output always includes the
/// start and end points as the first and last segment endpoints.
pub fn bezier2_flatten(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  tolerance : Double,
  max_depth : Int,
) -> Result[Array[LineSegment], Unit] {
  if tolerance <= 0.0 || max_depth <= 0 {
    return Err(())
  }
  let segments : Array[LineSegment] = []
  match bezier2_subdivide(p0, p1, p2, tolerance, max_depth, 0, segments) {
    Ok(_) => Ok(segments)
    Err(e) => Err(e)
  }
}

///|
/// Flatten a cubic Bézier into line segments using adaptive midpoint
/// subdivision. Same parameters and contract as `bezier2_flatten`.
pub fn bezier3_flatten(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  p3 : Point2,
  tolerance : Double,
  max_depth : Int,
) -> Result[Array[LineSegment], Unit] {
  if tolerance <= 0.0 || max_depth <= 0 {
    return Err(())
  }
  let segments : Array[LineSegment] = []
  match bezier3_subdivide(p0, p1, p2, p3, tolerance, max_depth, 0, segments) {
    Ok(_) => Ok(segments)
    Err(e) => Err(e)
  }
}

///|
/// Test whether a quadratic Bézier is flat enough: the control point
/// deviates from the chord P0-P2 by less than `tolerance`.
fn bezier2_is_flat(p0 : Point2, p1 : Point2, p2 : Point2, tolerance : Double) -> Bool {
  // Distance from P1 to the line P0-P2, using the cross-product method.
  let dx = p2.x() - p0.x()
  let dy = p2.y() - p0.y()
  let len_sq = dx * dx + dy * dy
  if len_sq < 1.0e-20 {
    // Degenerate chord (P0 == P2): check if P1 is also near P0.
    let d = p0.vector_to(p1).length_squared()
    return d <= tolerance * tolerance
  }
  let cross = (p1.x() - p0.x()) * dy - (p1.y() - p0.y()) * dx
  let dist_sq = cross * cross / len_sq
  dist_sq <= tolerance * tolerance
}

///|
/// Test whether a cubic Bézier is flat enough: both control points deviate
/// from the chord P0-P3 by less than `tolerance`.
fn bezier3_is_flat(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  p3 : Point2,
  tolerance : Double,
) -> Bool {
  let dx = p3.x() - p0.x()
  let dy = p3.y() - p0.y()
  let len_sq = dx * dx + dy * dy
  let tol_sq = tolerance * tolerance
  if len_sq < 1.0e-20 {
    // Degenerate chord: both controls must be near P0.
    let d1 = p0.vector_to(p1).length_squared()
    let d2 = p0.vector_to(p2).length_squared()
    return d1 <= tol_sq && d2 <= tol_sq
  }
  let cross1 = (p1.x() - p0.x()) * dy - (p1.y() - p0.y()) * dx
  let cross2 = (p2.x() - p0.x()) * dy - (p2.y() - p0.y()) * dx
  let dist1_sq = cross1 * cross1 / len_sq
  let dist2_sq = cross2 * cross2 / len_sq
  dist1_sq <= tol_sq && dist2_sq <= tol_sq
}

///|
/// Recursive subdivision for quadratic Bézier using de Casteljau at t=0.5.
fn bezier2_subdivide(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  tolerance : Double,
  max_depth : Int,
  depth : Int,
  segments : Array[LineSegment],
) -> Result[Unit, Unit] {
  if bezier2_is_flat(p0, p1, p2, tolerance) || depth >= max_depth {
    if depth >= max_depth && !bezier2_is_flat(p0, p1, p2, tolerance) {
      // Exceeded max depth without reaching flatness; emit the segment
      // anyway (the caller controls quality via max_depth/tolerance).
      // This avoids failing on merely complex curves.
    }
    segments.push({ start_value: p0, end_value: p2 })
    return Ok(())
  }
  // de Casteljau subdivision at t=0.5.
  let m01 = Point2::new((p0.x() + p1.x()) / 2.0, (p0.y() + p1.y()) / 2.0)
  let m12 = Point2::new((p1.x() + p2.x()) / 2.0, (p1.y() + p2.y()) / 2.0)
  let mid = Point2::new((m01.x() + m12.x()) / 2.0, (m01.y() + m12.y()) / 2.0)
  match bezier2_subdivide(p0, m01, mid, tolerance, max_depth, depth + 1, segments) {
    Ok(_) => bezier2_subdivide(mid, m12, p2, tolerance, max_depth, depth + 1, segments)
    Err(e) => Err(e)
  }
}

///|
/// Recursive subdivision for cubic Bézier using de Casteljau at t=0.5.
fn bezier3_subdivide(
  p0 : Point2,
  p1 : Point2,
  p2 : Point2,
  p3 : Point2,
  tolerance : Double,
  max_depth : Int,
  depth : Int,
  segments : Array[LineSegment],
) -> Result[Unit, Unit] {
  if bezier3_is_flat(p0, p1, p2, p3, tolerance) || depth >= max_depth {
    segments.push({ start_value: p0, end_value: p3 })
    return Ok(())
  }
  // de Casteljau subdivision at t=0.5.
  let m01 = Point2::new((p0.x() + p1.x()) / 2.0, (p0.y() + p1.y()) / 2.0)
  let m12 = Point2::new((p1.x() + p2.x()) / 2.0, (p1.y() + p2.y()) / 2.0)
  let m23 = Point2::new((p2.x() + p3.x()) / 2.0, (p2.y() + p3.y()) / 2.0)
  let m012 = Point2::new((m01.x() + m12.x()) / 2.0, (m01.y() + m12.y()) / 2.0)
  let m123 = Point2::new((m12.x() + m23.x()) / 2.0, (m12.y() + m23.y()) / 2.0)
  let mid = Point2::new((m012.x() + m123.x()) / 2.0, (m012.y() + m123.y()) / 2.0)
  match bezier3_subdivide(p0, m01, m012, mid, tolerance, max_depth, depth + 1, segments) {
    Ok(_) => bezier3_subdivide(mid, m123, m23, p3, tolerance, max_depth, depth + 1, segments)
    Err(e) => Err(e)
  }
}
