// Polygon area computation for MoonBit Native Foundation.
//
// Consumed by mb-font (glyph metric bounding areas), mb-layout (frame
// area accounting), and mb-canvas (rasterizer coverage estimation).
// Uses the shoelace formula for simple polygon area.

///|
/// Compute the signed area of a simple polygon given its vertices in order
/// (clockwise or counterclockwise).
///
/// Uses the shoelace formula:
///   A = 0.5 * |Σ (x_i * y_{i+1} - x_{i+1} * y_i)|
///
/// The result is always non-negative. Returns 0.0 for fewer than 3 vertices.
pub fn polygon_area(vertices : Array[Point2]) -> Double {
  let n = vertices.length()
  if n < 3 {
    return 0.0
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    sum = sum + vertices[i].x() * vertices[j].y() - vertices[j].x() * vertices[i].y()
  }
  if sum < 0.0 {
    -sum * 0.5
  } else {
    sum * 0.5
  }
}

///|
/// Compute the signed area of a triangle given three vertices.
///
/// Positive if the vertices are counterclockwise, negative if clockwise.
pub fn triangle_signed_area(a : Point2, b : Point2, c : Point2) -> Double {
  (b.x() - a.x()) * (c.y() - a.y()) - (c.x() - a.x()) * (b.y() - a.y())
}

///|
/// Compute the area of a triangle (always non-negative).
pub fn triangle_area(a : Point2, b : Point2, c : Point2) -> Double {
  let signed = triangle_signed_area(a, b, c)
  if signed < 0.0 {
    -signed * 0.5
  } else {
    signed * 0.5
  }
}

///|
/// Compute the perimeter (total edge length) of a polygon.
///
/// Returns 0.0 for fewer than 2 vertices. For 2 vertices, returns the
/// distance between them.
pub fn polygon_perimeter(vertices : Array[Point2]) -> Double {
  let n = vertices.length()
  if n < 2 {
    return 0.0
  }
  let mut total = 0.0
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    let v = vertices[i].vector_to(vertices[j])
    total = total + @stdlib_math.pow(v.length_squared(), 0.5)
  }
  total
}

///|
/// Compute the centroid (geometric center) of a simple polygon.
///
/// Returns `None` for fewer than 3 vertices or a zero-area polygon.
pub fn polygon_centroid(vertices : Array[Point2]) -> Point2? {
  let n = vertices.length()
  if n < 3 {
    return None
  }
  let mut cx = 0.0
  let mut cy = 0.0
  let mut area = 0.0
  for i = 0; i < n; i = i + 1 {
    let j = (i + 1) % n
    let cross = vertices[i].x() * vertices[j].y() - vertices[j].x() * vertices[i].y()
    area = area + cross
    cx = cx + (vertices[i].x() + vertices[j].x()) * cross
    cy = cy + (vertices[i].y() + vertices[j].y()) * cross
  }
  if area > -1.0e-20 && area < 1.0e-20 {
    return None
  }
  area = area * 0.5
  Some(Point2::new(cx / (6.0 * area), cy / (6.0 * area)))
}
