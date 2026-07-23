// Portable 2D affine geometry for MoonBit Native Foundation.
//
// This package owns typed 2D points, vectors, and affine transform matrices.
// It is consumed by mb-canvas (path transform), mb-svg (coordinate transforms),
// mb-layout (frame geometry), and mb-font (glyph positioning).
//
// All operations are pure functions: deterministic on every target
// (js, wasm, wasm-gc, native), no ambient state, no host dependency.
// Floating-point arithmetic uses MoonBit Double; callers that need exact
// integer geometry (e.g., pixel coordinates) should use mb-core/checked
// and convert at the boundary.

// ---------------------------------------------------------------------------
// Point2 — a 2D point in a coordinate system
// ---------------------------------------------------------------------------

///|
/// A 2D point in a plane, using double-precision coordinates.
pub struct Point2 {
  x_value : Double
  y_value : Double
}

///|
/// Construct a point from (x, y).
pub fn Point2::new(x : Double, y : Double) -> Point2 {
  { x_value: x, y_value: y }
}

///|
/// The x coordinate of this point.
pub fn Point2::x(self : Point2) -> Double {
  self.x_value
}

///|
/// The y coordinate of this point.
pub fn Point2::y(self : Point2) -> Double {
  self.y_value
}

///|
/// The origin point (0.0, 0.0).
pub fn Point2::origin() -> Point2 {
  Point2::new(0.0, 0.0)
}

// ---------------------------------------------------------------------------
// Vector2 — a 2D direction and magnitude
// ---------------------------------------------------------------------------

///|
/// A 2D vector, using double-precision components.
pub struct Vector2 {
  dx_value : Double
  dy_value : Double
}

///|
/// Construct a vector from (dx, dy).
pub fn Vector2::new(dx : Double, dy : Double) -> Vector2 {
  { dx_value: dx, dy_value: dy }
}

///|
/// The x-component of this vector.
pub fn Vector2::dx(self : Vector2) -> Double {
  self.dx_value
}

///|
/// The y-component of this vector.
pub fn Vector2::dy(self : Vector2) -> Double {
  self.dy_value
}

///|
/// The zero vector (0.0, 0.0).
pub fn Vector2::zero() -> Vector2 {
  Vector2::new(0.0, 0.0)
}

///|
/// Add two vectors component-wise.
pub fn Vector2::add(self : Vector2, other : Vector2) -> Vector2 {
  Vector2::new(self.dx_value + other.dx_value, self.dy_value + other.dy_value)
}

///|
/// Scale this vector by a scalar.
pub fn Vector2::scale(self : Vector2, factor : Double) -> Vector2 {
  Vector2::new(self.dx_value * factor, self.dy_value * factor)
}

///|
/// The squared length (magnitude squared) of this vector.
pub fn Vector2::length_squared(self : Vector2) -> Double {
  self.dx_value * self.dx_value + self.dy_value * self.dy_value
}

///|
/// The dot product of two vectors: `self.dx * other.dx + self.dy * other.dy`.
///
/// Positive if the angle between vectors is < 90°, negative if > 90°,
/// zero if perpendicular.
pub fn Vector2::dot(self : Vector2, other : Vector2) -> Double {
  self.dx_value * other.dx_value + self.dy_value * other.dy_value
}

///|
/// The 2D cross product (scalar) of two vectors:
/// `self.dx * other.dy - self.dy * other.dx`.
///
/// Positive if `other` is counterclockwise from `self`, negative if
/// clockwise, zero if collinear.
pub fn Vector2::cross(self : Vector2, other : Vector2) -> Double {
  self.dx_value * other.dy_value - self.dy_value * other.dx_value
}

///|
/// The perpendicular vector to this one, rotated 90° counterclockwise:
/// `(-dy, dx)`.
pub fn Vector2::perpendicular(self : Vector2) -> Vector2 {
  Vector2::new(-self.dy_value, self.dx_value)
}

///|
/// Subtract `other` from this vector component-wise.
pub fn Vector2::sub(self : Vector2, other : Vector2) -> Vector2 {
  Vector2::new(self.dx_value - other.dx_value, self.dy_value - other.dy_value)
}

///|
/// The Euclidean distance between two points.
pub fn Point2::distance_to(self : Point2, other : Point2) -> Double {
  let dx = self.x_value - other.x_value
  let dy = self.y_value - other.y_value
  @stdlib_math.pow(dx * dx + dy * dy, 0.5)
}

///|
/// The squared distance between two points (avoids sqrt for comparisons).
pub fn Point2::distance_squared_to(self : Point2, other : Point2) -> Double {
  let dx = self.x_value - other.x_value
  let dy = self.y_value - other.y_value
  dx * dx + dy * dy
}

///|
/// Linear interpolation between two points at parameter `t` in [0, 1].
///
/// `t = 0` returns `self`, `t = 1` returns `other`.
pub fn Point2::lerp(self : Point2, other : Point2, t : Double) -> Point2 {
  Point2::new(
    self.x_value + (other.x_value - self.x_value) * t,
    self.y_value + (other.y_value - self.y_value) * t,
  )
}

///|
/// Translate a point by a vector.
pub fn Point2::translate(self : Point2, offset : Vector2) -> Point2 {
  Point2::new(self.x_value + offset.dx_value, self.y_value + offset.dy_value)
}

///|
/// The vector from `self` to `other` (i.e., other - self).
pub fn Point2::vector_to(self : Point2, other : Point2) -> Vector2 {
  Vector2::new(other.x_value - self.x_value, other.y_value - self.y_value)
}

// ---------------------------------------------------------------------------
// Affine2 — a 2D affine transform matrix
// ---------------------------------------------------------------------------
//
// Represented as a 2x3 matrix:
//
//   | a c tx |     | x |     | a*x + c*y + tx |
//   | b d ty |  *  | y |  =  | b*x + d*y + ty |
//   | 0 0  1 |     | 1 |     |       1        |
//
// This is the standard SVG/Cairo 2D affine form. The last row is implicit.

///|
/// A 2D affine transform in the standard `[a b c d tx ty]` layout.
///
/// Applied to a point (x, y) produces:
/// `(a*x + c*y + tx, b*x + d*y + ty)`.
pub struct Affine2 {
  a_value : Double
  b_value : Double
  c_value : Double
  d_value : Double
  tx_value : Double
  ty_value : Double
}

///|
/// The identity transform (no change).
pub fn Affine2::identity() -> Affine2 {
  { a_value: 1.0, b_value: 0.0, c_value: 0.0, d_value: 1.0, tx_value: 0.0, ty_value: 0.0 }
}

///|
/// Construct a transform from the six standard components.
pub fn Affine2::new(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  tx : Double,
  ty : Double,
) -> Affine2 {
  { a_value: a, b_value: b, c_value: c, d_value: d, tx_value: tx, ty_value: ty }
}

///|
/// A translation by (tx, ty).
pub fn Affine2::translate(tx : Double, ty : Double) -> Affine2 {
  { a_value: 1.0, b_value: 0.0, c_value: 0.0, d_value: 1.0, tx_value: tx, ty_value: ty }
}

///|
/// A uniform + non-uniform scale by (sx, sy).
pub fn Affine2::scale(sx : Double, sy : Double) -> Affine2 {
  { a_value: sx, b_value: 0.0, c_value: 0.0, d_value: sy, tx_value: 0.0, ty_value: 0.0 }
}

///|
/// A rotation by `radians` (counterclockwise in standard math orientation).
///
/// Note: SVG and most screen coordinate systems have y pointing down, so a
/// positive angle appears clockwise on screen. The transform is mathematically
/// consistent regardless of the y-axis direction.
pub fn Affine2::rotate(radians : Double) -> Affine2 {
  let cos_r = @stdlib_math.cos(radians)
  let sin_r = @stdlib_math.sin(radians)
  { a_value: cos_r, b_value: sin_r, c_value: -sin_r, d_value: cos_r, tx_value: 0.0, ty_value: 0.0 }
}

///|
/// A shear (skew) by (shx, shy).
pub fn Affine2::skew(shx : Double, shy : Double) -> Affine2 {
  { a_value: 1.0, b_value: shy, c_value: shx, d_value: 1.0, tx_value: 0.0, ty_value: 0.0 }
}

///|
/// Apply this transform to a point.
pub fn Affine2::apply(self : Affine2, point : Point2) -> Point2 {
  let x = point.x()
  let y = point.y()
  Point2::new(
    self.a_value * x + self.c_value * y + self.tx_value,
    self.b_value * x + self.d_value * y + self.ty_value,
  )
}

///|
/// Compose two transforms: `self` then `other` (i.e., `other ∘ self`).
///
/// The result applies `self` first, then `other`, matching the convention
/// where `combined.apply(p)` equals `other.apply(self.apply(p))`.
pub fn Affine2::compose(self : Affine2, other : Affine2) -> Affine2 {
  // other * self in matrix multiplication terms.
  let a = other.a_value * self.a_value + other.c_value * self.b_value
  let b = other.b_value * self.a_value + other.d_value * self.b_value
  let c = other.a_value * self.c_value + other.c_value * self.d_value
  let d = other.b_value * self.c_value + other.d_value * self.d_value
  let tx = other.a_value * self.tx_value + other.c_value * self.ty_value + other.tx_value
  let ty = other.b_value * self.tx_value + other.d_value * self.ty_value + other.ty_value
  Affine2::new(a, b, c, d, tx, ty)
}

///|
/// The determinant of the linear part of this transform: `a*d - b*c`.
///
/// A determinant of zero means the transform is singular (non-invertible).
pub fn Affine2::determinant(self : Affine2) -> Double {
  self.a_value * self.d_value - self.b_value * self.c_value
}

///|
/// Compute the inverse of this affine transform.
///
/// Returns `None` if the transform is singular (determinant is zero or
/// near-zero within a tolerance of `1.0e-12`). The inverse satisfies
/// `self.compose(inverse) == identity` and `inverse.compose(self) == identity`.
pub fn Affine2::inverse(self : Affine2) -> Affine2? {
  let det = self.a_value * self.d_value - self.b_value * self.c_value
  if det > -1.0e-12 && det < 1.0e-12 {
    return None
  }
  let inv_det = 1.0 / det
  let a = self.d_value * inv_det
  let b = -self.b_value * inv_det
  let c = -self.c_value * inv_det
  let d = self.a_value * inv_det
  let tx = -(a * self.tx_value + c * self.ty_value)
  let ty = -(b * self.tx_value + d * self.ty_value)
  Some(Affine2::new(a, b, c, d, tx, ty))
}

// --- Accessors ---

///|
pub fn Affine2::a(self : Affine2) -> Double {
  self.a_value
}

///|
pub fn Affine2::b(self : Affine2) -> Double {
  self.b_value
}

///|
pub fn Affine2::c(self : Affine2) -> Double {
  self.c_value
}

///|
pub fn Affine2::d(self : Affine2) -> Double {
  self.d_value
}

///|
pub fn Affine2::tx(self : Affine2) -> Double {
  self.tx_value
}

///|
pub fn Affine2::ty(self : Affine2) -> Double {
  self.ty_value
}
