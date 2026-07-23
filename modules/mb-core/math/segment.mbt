// Line segment intersection and clipping for MoonBit Native Foundation.
//
// Consumed by mb-canvas (rasterizer edge intersection, fill-rule resolution),
// mb-layout (float wrap-around geometry), and mb-svg (path boolean ops).
// Uses parametric line intersection for accuracy and determinism.

///|
/// Check whether two line segments intersect (including touching at endpoints).
///
/// Returns `true` if the segments share any point.
pub fn segments_intersect(a : LineSegment, b : LineSegment) -> Bool {
  segment_intersection(a, b) is Some(_)
}

///|
/// Compute the intersection point of two line segments, if any.
///
/// Returns `Some(point)` if the segments cross (including at endpoints),
/// `None` if they do not intersect or are collinear-overlapping.
///
/// Uses the parametric method: segment A = P0 + t*(P1-P0) for t in [0,1].
pub fn segment_intersection(a : LineSegment, b : LineSegment) -> Point2? {
  let p0 = a.start()
  let p1 = a.end()
  let p2 = b.start()
  let p3 = b.end()
  let d1 = p0.vector_to(p1) // direction of segment A
  let d2 = p2.vector_to(p3) // direction of segment B
  // Cross product of directions: if zero, segments are parallel.
  let denom = d1.cross(d2)
  if denom > -1.0e-12 && denom < 1.0e-12 {
    // Parallel or collinear: return None (collinear overlap not handled).
    return None
  }
  let diff = p0.vector_to(p2)
  let t = diff.cross(d2) / denom
  let u = diff.cross(d1) / denom
  // Both parameters must be in [0, 1] for the intersection to lie on both segments.
  if t >= 0.0 && t <= 1.0 && u >= 0.0 && u <= 1.0 {
    Some(Point2::new(p0.x() + d1.dx() * t, p0.y() + d1.dy() * t))
  } else {
    None
  }
}

///|
/// Find the intersection point of two infinite lines (not segments).
///
/// Returns `None` if the lines are parallel.
pub fn line_intersection(
  origin_a : Point2,
  direction_a : Vector2,
  origin_b : Point2,
  direction_b : Vector2,
) -> Point2? {
  let denom = direction_a.cross(direction_b)
  if denom > -1.0e-12 && denom < 1.0e-12 {
    return None
  }
  let diff = origin_a.vector_to(origin_b)
  let t = diff.cross(direction_b) / denom
  Some(
    Point2::new(
      origin_a.x() + direction_a.dx() * t,
      origin_a.y() + direction_a.dy() * t,
    ),
  )
}

// ---------------------------------------------------------------------------
// Cohen-Sutherland line clipping against an axis-aligned rectangle
// ---------------------------------------------------------------------------

///|
/// Clip a line segment to a rectangular region using the Cohen-Sutherland
/// algorithm. Returns `None` if the segment is entirely outside the rect.
///
/// Consumed by mb-canvas (clip region enforcement) and mb-svg (viewport
/// clipping).
pub fn clip_segment_to_rect(segment : LineSegment, rect : Rect2) -> LineSegment? {
  let mut x0 = segment.start().x()
  let mut y0 = segment.start().y()
  let mut x1 = segment.end().x()
  let mut y1 = segment.end().y()
  let min_x = rect.min_x()
  let max_x = rect.max_x()
  let min_y = rect.min_y()
  let max_y = rect.max_y()
  let mut code0 = compute_outcode(x0, y0, min_x, max_x, min_y, max_y)
  let mut code1 = compute_outcode(x1, y1, min_x, max_x, min_y, max_y)
  let mut accept = false
  let mut done = false
  while !done {
    if (code0 | code1) == 0 {
      // Both endpoints inside: trivially accept.
      accept = true
      done = true
    } else if (code0 & code1) != 0 {
      // Both endpoints share an outside region: trivially reject.
      done = true
    } else {
      // Pick an endpoint that is outside.
      let code_out = if code0 != 0 { code0 } else { code1 }
      let dx = x1 - x0
      let dy = y1 - y0
      let mut x = 0.0
      let mut y = 0.0
      if (code_out & INSIDE_TOP) != 0 {
        // Point is above the clip rectangle.
        x = x0 + dx * (max_y - y0) / dy
        y = max_y
      } else if (code_out & INSIDE_BOTTOM) != 0 {
        // Point is below.
        x = x0 + dx * (min_y - y0) / dy
        y = min_y
      } else if (code_out & INSIDE_RIGHT) != 0 {
        // Point is to the right.
        y = y0 + dy * (max_x - x0) / dx
        x = max_x
      } else if (code_out & INSIDE_LEFT) != 0 {
        // Point is to the left.
        y = y0 + dy * (min_x - x0) / dx
        x = min_x
      }
      // Move the outside endpoint to the intersection point.
      if code_out == code0 {
        x0 = x
        y0 = y
        code0 = compute_outcode(x0, y0, min_x, max_x, min_y, max_y)
      } else {
        x1 = x
        y1 = y
        code1 = compute_outcode(x1, y1, min_x, max_x, min_y, max_y)
      }
    }
  }
  if accept {
    Some({ start_value: Point2::new(x0, y0), end_value: Point2::new(x1, y1) })
  } else {
    None
  }
}

// Outcode bit flags for Cohen-Sutherland.
const INSIDE_LEFT : Int = 1
const INSIDE_RIGHT : Int = 2
const INSIDE_BOTTOM : Int = 4
const INSIDE_TOP : Int = 8

fn compute_outcode(
  x : Double,
  y : Double,
  min_x : Double,
  max_x : Double,
  min_y : Double,
  max_y : Double,
) -> Int {
  let mut code = 0
  if x < min_x {
    code = code | INSIDE_LEFT
  } else if x > max_x {
    code = code | INSIDE_RIGHT
  }
  if y < min_y {
    code = code | INSIDE_BOTTOM
  } else if y > max_y {
    code = code | INSIDE_TOP
  }
  code
}
