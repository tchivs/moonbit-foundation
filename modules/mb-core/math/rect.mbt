// 2D axis-aligned rectangles (bounding boxes) for MoonBit Native Foundation.
//
// Consumed by mb-canvas (clip regions), mb-layout (frame geometry), mb-svg
// (viewBox), and mb-font (glyph bounds). Rectangles are axis-aligned (AABB),
// defined by an origin (min-x, min-y) and a size (width, height). Negative
// dimensions are normalized to positive on construction.

///|
/// An axis-aligned 2D rectangle, using double-precision coordinates.
pub struct Rect2 {
  min_x_value : Double
  min_y_value : Double
  width_value : Double
  height_value : Double
}

///|
/// Construct a rectangle from (min_x, min_y, width, height).
/// Negative width or height are normalized so the result always stores
/// non-negative dimensions.
pub fn Rect2::new(min_x : Double, min_y : Double, width : Double, height : Double) -> Rect2 {
  let (nx, nw) = if width < 0.0 {
    (min_x + width, -width)
  } else {
    (min_x, width)
  }
  let (ny, nh) = if height < 0.0 {
    (min_y + height, -height)
  } else {
    (min_y, height)
  }
  { min_x_value: nx, min_y_value: ny, width_value: nw, height_value: nh }
}

///|
/// The zero-area rectangle at the origin.
pub fn Rect2::zero() -> Rect2 {
  { min_x_value: 0.0, min_y_value: 0.0, width_value: 0.0, height_value: 0.0 }
}

///|
/// Construct a rectangle from two corner points, automatically ordering
/// them so the result is canonical (min is top-left, dimensions positive).
pub fn Rect2::from_corners(corner_a : Point2, corner_b : Point2) -> Rect2 {
  let min_x = if corner_a.x() < corner_b.x() {
    corner_a.x()
  } else {
    corner_b.x()
  }
  let max_x = if corner_a.x() > corner_b.x() {
    corner_a.x()
  } else {
    corner_b.x()
  }
  let min_y = if corner_a.y() < corner_b.y() {
    corner_a.y()
  } else {
    corner_b.y()
  }
  let max_y = if corner_a.y() > corner_b.y() {
    corner_a.y()
  } else {
    corner_b.y()
  }
  Rect2::new(min_x, min_y, max_x - min_x, max_y - min_y)
}

// --- Accessors ---

///|
pub fn Rect2::min_x(self : Rect2) -> Double {
  self.min_x_value
}

///|
pub fn Rect2::min_y(self : Rect2) -> Double {
  self.min_y_value
}

///|
pub fn Rect2::width(self : Rect2) -> Double {
  self.width_value
}

///|
pub fn Rect2::height(self : Rect2) -> Double {
  self.height_value
}

///|
/// The maximum x coordinate (min_x + width).
pub fn Rect2::max_x(self : Rect2) -> Double {
  self.min_x_value + self.width_value
}

///|
/// The maximum y coordinate (min_y + height).
pub fn Rect2::max_y(self : Rect2) -> Double {
  self.min_y_value + self.height_value
}

///|
/// The top-left corner of this rectangle.
pub fn Rect2::origin(self : Rect2) -> Point2 {
  Point2::new(self.min_x_value, self.min_y_value)
}

///|
/// The center point of this rectangle.
pub fn Rect2::center(self : Rect2) -> Point2 {
  Point2::new(
    self.min_x_value + self.width_value / 2.0,
    self.min_y_value + self.height_value / 2.0,
  )
}

// --- Queries ---

///|
/// True if both dimensions are zero (no area).
pub fn Rect2::is_empty(self : Rect2) -> Bool {
  self.width_value <= 0.0 || self.height_value <= 0.0
}

///|
/// True if `point` lies inside or on the boundary of this rectangle.
pub fn Rect2::contains(self : Rect2, point : Point2) -> Bool {
  point.x() >= self.min_x_value &&
  point.x() <= self.max_x() &&
  point.y() >= self.min_y_value &&
  point.y() <= self.max_y()
}

// --- Operations ---

///|
/// Translate this rectangle by a vector.
pub fn Rect2::translate(self : Rect2, offset : Vector2) -> Rect2 {
  Rect2::new(
    self.min_x_value + offset.dx(),
    self.min_y_value + offset.dy(),
    self.width_value,
    self.height_value,
  )
}

///|
/// Compute the smallest rectangle that contains both `self` and `other`.
/// If either rectangle is empty, the other is returned unchanged.
pub fn Rect2::union(self : Rect2, other : Rect2) -> Rect2 {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  let min_x = if self.min_x_value < other.min_x_value {
    self.min_x_value
  } else {
    other.min_x_value
  }
  let min_y = if self.min_y_value < other.min_y_value {
    self.min_y_value
  } else {
    other.min_y_value
  }
  let max_x = if self.max_x() > other.max_x() {
    self.max_x()
  } else {
    other.max_x()
  }
  let max_y = if self.max_y() > other.max_y() {
    self.max_y()
  } else {
    other.max_y()
  }
  Rect2::new(min_x, min_y, max_x - min_x, max_y - min_y)
}

///|
/// Compute the intersection of two rectangles. If they do not overlap,
/// the result is a zero-area (empty) rectangle.
pub fn Rect2::intersection(self : Rect2, other : Rect2) -> Rect2 {
  let min_x = if self.min_x_value > other.min_x_value {
    self.min_x_value
  } else {
    other.min_x_value
  }
  let min_y = if self.min_y_value > other.min_y_value {
    self.min_y_value
  } else {
    other.min_y_value
  }
  let max_x = if self.max_x() < other.max_x() {
    self.max_x()
  } else {
    other.max_x()
  }
  let max_y = if self.max_y() < other.max_y() {
    self.max_y()
  } else {
    other.max_y()
  }
  if max_x <= min_x || max_y <= min_y {
    return Rect2::zero()
  }
  Rect2::new(min_x, min_y, max_x - min_x, max_y - min_y)
}
