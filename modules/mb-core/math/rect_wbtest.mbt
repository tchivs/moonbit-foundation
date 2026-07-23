// White-box tests for Rect2 axis-aligned bounding boxes.

///|
test "rect construction normalizes negative dimensions" {
  let r = Rect2::new(10.0, 20.0, -5.0, -8.0)
  inspect(approx(r.min_x(), 5.0), content="true")
  inspect(approx(r.min_y(), 12.0), content="true")
  inspect(approx(r.width(), 5.0), content="true")
  inspect(approx(r.height(), 8.0), content="true")
}

///|
test "rect from corners auto-orders to canonical form" {
  // Corners given as bottom-right then top-left.
  let r = Rect2::from_corners(Point2::new(10.0, 10.0), Point2::new(0.0, 0.0))
  inspect(approx(r.min_x(), 0.0), content="true")
  inspect(approx(r.min_y(), 0.0), content="true")
  inspect(approx(r.width(), 10.0), content="true")
  inspect(approx(r.height(), 10.0), content="true")
}

///|
test "rect max_x and max_y are min + dimension" {
  let r = Rect2::new(3.0, 4.0, 5.0, 6.0)
  inspect(approx(r.max_x(), 8.0), content="true")
  inspect(approx(r.max_y(), 10.0), content="true")
}

///|
test "rect center is midpoint of dimensions" {
  let r = Rect2::new(0.0, 0.0, 10.0, 20.0)
  let c = r.center()
  inspect(approx(c.x(), 5.0), content="true")
  inspect(approx(c.y(), 10.0), content="true")
}

///|
test "rect is_empty detects zero-area" {
  inspect(Rect2::zero().is_empty(), content="true")
  inspect(Rect2::new(0.0, 0.0, 0.0, 5.0).is_empty(), content="true")
  inspect(Rect2::new(0.0, 0.0, 5.0, 0.0).is_empty(), content="true")
  inspect(Rect2::new(0.0, 0.0, 5.0, 5.0).is_empty(), content="false")
}

///|
test "rect contains includes boundary" {
  let r = Rect2::new(0.0, 0.0, 10.0, 10.0)
  inspect(r.contains(Point2::new(5.0, 5.0)), content="true")
  // Boundary points are inclusive.
  inspect(r.contains(Point2::new(0.0, 0.0)), content="true")
  inspect(r.contains(Point2::new(10.0, 10.0)), content="true")
  // Outside.
  inspect(r.contains(Point2::new(-0.1, 5.0)), content="false")
  inspect(r.contains(Point2::new(10.1, 5.0)), content="false")
}

///|
test "rect translate shifts min corner" {
  let r = Rect2::new(1.0, 2.0, 3.0, 4.0)
  let moved = r.translate(Vector2::new(10.0, 20.0))
  inspect(approx(moved.min_x(), 11.0), content="true")
  inspect(approx(moved.min_y(), 22.0), content="true")
  inspect(approx(moved.width(), 3.0), content="true")
  inspect(approx(moved.height(), 4.0), content="true")
}

///|
test "rect union produces enclosing bounds" {
  let a = Rect2::new(0.0, 0.0, 5.0, 5.0)
  let b = Rect2::new(3.0, 3.0, 5.0, 5.0)
  let u = a.union(b)
  inspect(approx(u.min_x(), 0.0), content="true")
  inspect(approx(u.min_y(), 0.0), content="true")
  inspect(approx(u.width(), 8.0), content="true")
  inspect(approx(u.height(), 8.0), content="true")
}

///|
test "rect union with empty returns non-empty" {
  let r = Rect2::new(0.0, 0.0, 5.0, 5.0)
  let u1 = r.union(Rect2::zero())
  inspect(approx(u1.width(), 5.0), content="true")
  let u2 = Rect2::zero().union(r)
  inspect(approx(u2.width(), 5.0), content="true")
}

///|
test "rect intersection of overlapping rects" {
  let a = Rect2::new(0.0, 0.0, 10.0, 10.0)
  let b = Rect2::new(5.0, 5.0, 10.0, 10.0)
  let i = a.intersection(b)
  inspect(approx(i.min_x(), 5.0), content="true")
  inspect(approx(i.min_y(), 5.0), content="true")
  inspect(approx(i.width(), 5.0), content="true")
  inspect(approx(i.height(), 5.0), content="true")
}

///|
test "rect intersection of non-overlapping rects is empty" {
  let a = Rect2::new(0.0, 0.0, 5.0, 5.0)
  let b = Rect2::new(10.0, 10.0, 5.0, 5.0)
  inspect(a.intersection(b).is_empty(), content="true")
}

///|
test "rect intersection touching at edge is empty" {
  // Touching but not overlapping (shared edge has zero area).
  let a = Rect2::new(0.0, 0.0, 5.0, 5.0)
  let b = Rect2::new(5.0, 0.0, 5.0, 5.0)
  inspect(a.intersection(b).is_empty(), content="true")
}
