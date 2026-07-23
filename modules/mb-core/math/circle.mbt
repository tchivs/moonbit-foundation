// Circle and ellipse geometry for MoonBit Native Foundation.
//
// Consumed by mb-svg (<circle>, <ellipse> element evaluation), mb-canvas
// (arc rasterization), and mb-font (circular glyph bounds).

///|
/// A circle defined by center and radius.
pub struct Circle {
  center_value : Point2
  radius_value : Double
}

///|
pub fn Circle::new(center : Point2, radius : Double) -> Circle {
  { center_value: center, radius_value: radius }
}

///|
pub fn Circle::center(self : Circle) -> Point2 {
  self.center_value
}

///|
pub fn Circle::radius(self : Circle) -> Double {
  self.radius_value
}

///|
/// The bounding box of this circle.
pub fn Circle::bounds(self : Circle) -> Rect2 {
  let r = self.radius_value
  Rect2::new(
    self.center_value.x() - r,
    self.center_value.y() - r,
    r * 2.0,
    r * 2.0,
  )
}

///|
/// The area of this circle: π·r².
pub fn Circle::area(self : Circle) -> Double {
  3.141592653589793 * self.radius_value * self.radius_value
}

///|
/// The circumference of this circle: 2·π·r.
pub fn Circle::circumference(self : Circle) -> Double {
  2.0 * 3.141592653589793 * self.radius_value
}

///|
/// Check whether a point is inside or on the circle.
pub fn Circle::contains(self : Circle, point : Point2) -> Bool {
  self.center_value.distance_squared_to(point) <= self.radius_value * self.radius_value
}

///|
/// Evaluate a point on the circle at angle `radians` (0 = east, CCW).
pub fn Circle::point_at(self : Circle, radians : Double) -> Point2 {
  Point2::new(
    self.center_value.x() + self.radius_value * @stdlib_math.cos(radians),
    self.center_value.y() + self.radius_value * @stdlib_math.sin(radians),
  )
}

///|
/// Approximate this circle as a polygon with `segments` vertices.
pub fn Circle::to_polygon(self : Circle, segments : Int) -> Array[Point2] {
  let result : Array[Point2] = []
  for i = 0; i < segments; i = i + 1 {
    let angle = 2.0 * 3.141592653589793 * i.to_double() / segments.to_double()
    result.push(self.point_at(angle))
  }
  result
}

// ---------------------------------------------------------------------------
// Ellipse
// ---------------------------------------------------------------------------

///|
/// An ellipse defined by center and two radii (x and y axes).
pub struct Ellipse {
  center_value : Point2
  radius_x_value : Double
  radius_y_value : Double
}

///|
pub fn Ellipse::new(center : Point2, radius_x : Double, radius_y : Double) -> Ellipse {
  { center_value: center, radius_x_value: radius_x, radius_y_value: radius_y }
}

///|
pub fn Ellipse::center(self : Ellipse) -> Point2 {
  self.center_value
}

///|
pub fn Ellipse::radius_x(self : Ellipse) -> Double {
  self.radius_x_value
}

///|
pub fn Ellipse::radius_y(self : Ellipse) -> Double {
  self.radius_y_value
}

///|
/// The bounding box of this ellipse.
pub fn Ellipse::bounds(self : Ellipse) -> Rect2 {
  Rect2::new(
    self.center_value.x() - self.radius_x_value,
    self.center_value.y() - self.radius_y_value,
    self.radius_x_value * 2.0,
    self.radius_y_value * 2.0,
  )
}

///|
/// The area of this ellipse: π·a·b.
pub fn Ellipse::area(self : Ellipse) -> Double {
  3.141592653589793 * self.radius_x_value * self.radius_y_value
}

///|
/// Check whether a point is inside or on the ellipse.
pub fn Ellipse::contains(self : Ellipse, point : Point2) -> Bool {
  let dx = point.x() - self.center_value.x()
  let dy = point.y() - self.center_value.y()
  let nx = dx / self.radius_x_value
  let ny = dy / self.radius_y_value
  nx * nx + ny * ny <= 1.0
}

///|
/// Evaluate a point on the ellipse at angle `radians`.
pub fn Ellipse::point_at(self : Ellipse, radians : Double) -> Point2 {
  Point2::new(
    self.center_value.x() + self.radius_x_value * @stdlib_math.cos(radians),
    self.center_value.y() + self.radius_y_value * @stdlib_math.sin(radians),
  )
}

///|
/// Approximate this ellipse as a polygon with `segments` vertices.
pub fn Ellipse::to_polygon(self : Ellipse, segments : Int) -> Array[Point2] {
  let result : Array[Point2] = []
  for i = 0; i < segments; i = i + 1 {
    let angle = 2.0 * 3.141592653589793 * i.to_double() / segments.to_double()
    result.push(self.point_at(angle))
  }
  result
}
