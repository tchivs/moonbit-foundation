// CanvasPath: an HTML-Canvas-style convenience builder over mb-core/math::Path2.
//
// Per RFC 0003 §4.1, canvas accepts already-parsed geometry from a caller and
// does not own SVG path syntax. CanvasPath provides ergonomic move_to/line_to/
// quad_to/cubic_to/close_path/rect/arc methods that lower to mb-core PathCommand
// values. Callers may also pass a raw mb-core Path2 directly to DrawingList.

///|
/// A path builder wrapping mb-core/math::Path2 with canvas-style methods.
pub struct CanvasPath {
  path : @math.Path2
}

///|
/// Construct an empty path.
pub fn CanvasPath::new() -> CanvasPath {
  { path: @math.Path2::new() }
}

///|
/// Begin a new subpath at `(x, y)`.
pub fn CanvasPath::move_to(self : CanvasPath, x : Double, y : Double) -> Unit {
  self.path.push(@math.PathCommand::MoveTo(@math.Point2::new(x, y)))
}

///|
/// Add a line segment to `(x, y)`.
pub fn CanvasPath::line_to(self : CanvasPath, x : Double, y : Double) -> Unit {
  self.path.push(@math.PathCommand::LineTo(@math.Point2::new(x, y)))
}

///|
/// Add a quadratic Bézier curve with control point `(cpx, cpy)` and end point
/// `(x, y)`. The start point is the current point of the path.
pub fn CanvasPath::quad_to(
  self : CanvasPath,
  cpx : Double,
  cpy : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.path.push(
    @math.PathCommand::QuadTo(
      @math.Point2::new(cpx, cpy),
      @math.Point2::new(x, y),
    ),
  )
}

///|
/// Add a cubic Bézier curve with two control points and an end point.
pub fn CanvasPath::cubic_to(
  self : CanvasPath,
  cp1x : Double,
  cp1y : Double,
  cp2x : Double,
  cp2y : Double,
  x : Double,
  y : Double,
) -> Unit {
  self.path.push(
    @math.PathCommand::CubicTo(
      @math.Point2::new(cp1x, cp1y),
      @math.Point2::new(cp2x, cp2y),
      @math.Point2::new(x, y),
    ),
  )
}

///|
/// Close the current subpath by appending a line to its start.
pub fn CanvasPath::close_path(self : CanvasPath) -> Unit {
  self.path.push(@math.PathCommand::Close)
}

///|
/// Add a closed rectangle as a subpath. Equivalent to move_to the top-left
/// corner, four line_to calls tracing the rectangle, and close_path.
pub fn CanvasPath::rect(
  self : CanvasPath,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit {
  self.path.push(@math.PathCommand::MoveTo(@math.Point2::new(x, y)))
  self.path.push(@math.PathCommand::LineTo(@math.Point2::new(x + w, y)))
  self.path.push(@math.PathCommand::LineTo(@math.Point2::new(x + w, y + h)))
  self.path.push(@math.PathCommand::LineTo(@math.Point2::new(x, y + h)))
  self.path.push(@math.PathCommand::Close)
}

///|
/// Add a circular arc to the path from angle `a0` to `a1` (radians, measured
/// from the positive x-axis) centered at `(cx, cy)` with radius `r`. The arc is
/// approximated by cubic Bézier segments (one per ≤ π/2 span) per RFC 0003 §7.1.
pub fn CanvasPath::arc(
  self : CanvasPath,
  cx : Double,
  cy : Double,
  r : Double,
  a0 : Double,
  a1 : Double,
) -> Unit {
  // Normalize so we always sweep in the positive (increasing-angle) direction.
  let (start, end) = if a0 <= a1 {
    (a0, a1)
  } else {
    (a1, a0)
  }
  let span = end - start
  // Subdivide into ≤ π/2 segments for a good cubic fit.
  let half_pi = 1.5707963267948966
  let segments = js_max(1, (span / half_pi).ceil().to_int())
  let step = span / segments.to_double()
  // Per-segment cubic tangent magnitude, scaled by the segment's angular span.
  let kappa = 0.5522847498307936 * step / half_pi
  let mut angle = start
  // Move to the arc start point.
  self.path.push(
    @math.PathCommand::MoveTo(
      @math.Point2::new(cx + r * @math.cos(angle), cy + r * @math.sin(angle)),
    ),
  )
  for i = 0; i < segments; i = i + 1 {
    let a_from = angle
    let a_to = if i == segments - 1 {
      end
    } else {
      angle + step
    }
    let p0 = @math.Point2::new(
      cx + r * @math.cos(a_from),
      cy + r * @math.sin(a_from),
    )
    let p3 = @math.Point2::new(cx + r * @math.cos(a_to), cy + r * @math.sin(a_to))
    // Tangent control points: offset along the tangent direction by kappa * r.
    let p1 = @math.Point2::new(
      p0.x() - r * kappa * @math.sin(a_from),
      p0.y() + r * kappa * @math.cos(a_from),
    )
    let p2 = @math.Point2::new(
      p3.x() + r * kappa * @math.sin(a_to),
      p3.y() - r * kappa * @math.cos(a_to),
    )
    self.path.push(@math.PathCommand::CubicTo(p1, p2, p3))
    angle = a_to
  }
}

///|
/// Return the underlying mb-core Path2. The CanvasPath continues to hold its
/// own reference; callers receive the same mutable Path2 value.
pub fn CanvasPath::to_path2(self : CanvasPath) -> @math.Path2 {
  self.path
}

// Local max helper to avoid pulling in another dependency for one call.
fn js_max(a : Int, b : Int) -> Int {
  if a >= b {
    a
  } else {
    b
  }
}
