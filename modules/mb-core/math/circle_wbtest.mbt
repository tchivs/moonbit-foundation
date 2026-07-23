// White-box tests for circle and ellipse geometry.

///|
test "circle area is pi r squared" {
  let c = Circle::new(Point2::new(0.0, 0.0), 2.0)
  inspect(approx(c.area(), 12.566370614359172), content="true") // 4*pi
}

///|
test "circle circumference is 2 pi r" {
  let c = Circle::new(Point2::new(0.0, 0.0), 3.0)
  inspect(approx(c.circumference(), 18.84955592153876), content="true") // 6*pi
}

///|
test "circle bounds is centered square" {
  let c = Circle::new(Point2::new(5.0, 5.0), 3.0)
  let b = c.bounds()
  inspect(approx(b.min_x(), 2.0), content="true")
  inspect(approx(b.width(), 6.0), content="true")
}

///|
test "circle contains detects inside and outside" {
  let c = Circle::new(Point2::new(0.0, 0.0), 5.0)
  inspect(c.contains(Point2::new(3.0, 4.0)), content="true") // distance = 5
  inspect(c.contains(Point2::new(1.0, 1.0)), content="true")
  inspect(c.contains(Point2::new(4.0, 4.0)), content="false") // distance > 5
}

///|
test "circle point at angle" {
  let c = Circle::new(Point2::new(0.0, 0.0), 1.0)
  let east = c.point_at(0.0)
  inspect(approx(east.x(), 1.0), content="true")
  inspect(approx(east.y(), 0.0), content="true")
  let north = c.point_at(1.5707963267948966)
  inspect(approx(north.x(), 0.0), content="true")
  inspect(approx(north.y(), 1.0), content="true")
}

///|
test "circle to polygon produces correct vertex count" {
  let c = Circle::new(Point2::new(0.0, 0.0), 5.0)
  let poly = c.to_polygon(8)
  inspect(poly.length(), content="8")
  // All vertices should be at distance r from center.
  for p in poly {
    let d = Point2::new(0.0, 0.0).distance_to(p)
    inspect(approx(d, 5.0), content="true")
  }
}

///|
test "ellipse area is pi a b" {
  let e = Ellipse::new(Point2::new(0.0, 0.0), 3.0, 4.0)
  inspect(approx(e.area(), 37.69911184307752), content="true") // 12*pi
}

///|
test "ellipse contains detects inside and outside" {
  let e = Ellipse::new(Point2::new(0.0, 0.0), 4.0, 2.0)
  inspect(e.contains(Point2::new(2.0, 1.0)), content="true") // 0.25 + 0.25 = 0.5 < 1
  inspect(e.contains(Point2::new(4.0, 0.0)), content="true") // on boundary
  inspect(e.contains(Point2::new(5.0, 0.0)), content="false") // outside
}

///|
test "ellipse bounds" {
  let e = Ellipse::new(Point2::new(10.0, 20.0), 5.0, 3.0)
  let b = e.bounds()
  inspect(approx(b.min_x(), 5.0), content="true")
  inspect(approx(b.width(), 10.0), content="true")
  inspect(approx(b.height(), 6.0), content="true")
}

///|
test "ellipse to polygon vertex count" {
  let e = Ellipse::new(Point2::new(0.0, 0.0), 5.0, 3.0)
  inspect(e.to_polygon(16).length(), content="16")
}
