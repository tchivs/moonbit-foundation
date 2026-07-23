// White-box tests for polygon area, perimeter, and centroid.

///|
test "polygon area of unit square is 1" {
  let square = [
    Point2::new(0.0, 0.0),
    Point2::new(1.0, 0.0),
    Point2::new(1.0, 1.0),
    Point2::new(0.0, 1.0),
  ]
  inspect(approx(polygon_area(square), 1.0), content="true")
}

///|
test "polygon area of triangle is half base times height" {
  let tri = [
    Point2::new(0.0, 0.0),
    Point2::new(4.0, 0.0),
    Point2::new(0.0, 3.0),
  ]
  inspect(approx(polygon_area(tri), 6.0), content="true")
}

///|
test "polygon area handles clockwise and counterclockwise" {
  let cw = [
    Point2::new(0.0, 0.0),
    Point2::new(0.0, 1.0),
    Point2::new(1.0, 1.0),
    Point2::new(1.0, 0.0),
  ]
  let ccw = [
    Point2::new(0.0, 0.0),
    Point2::new(1.0, 0.0),
    Point2::new(1.0, 1.0),
    Point2::new(0.0, 1.0),
  ]
  inspect(approx(polygon_area(cw), polygon_area(ccw)), content="true")
}

///|
test "polygon area returns zero for degenerate" {
  inspect(approx(polygon_area([]), 0.0), content="true")
  inspect(approx(polygon_area([Point2::new(0.0, 0.0)]), 0.0), content="true")
  inspect(approx(polygon_area([Point2::new(0.0, 0.0), Point2::new(1.0, 1.0)]), 0.0), content="true")
}

///|
test "triangle area is always non-negative" {
  let a = Point2::new(0.0, 0.0)
  let b = Point2::new(1.0, 0.0)
  let c = Point2::new(0.0, 1.0)
  inspect(approx(triangle_area(a, b, c), 0.5), content="true")
  // Reversed winding: still positive.
  inspect(approx(triangle_area(a, c, b), 0.5), content="true")
}

///|
test "triangle signed area detects winding" {
  let a = Point2::new(0.0, 0.0)
  let b = Point2::new(1.0, 0.0)
  let c = Point2::new(0.0, 1.0)
  inspect(triangle_signed_area(a, b, c) > 0.0, content="true") // CCW
  inspect(triangle_signed_area(a, c, b) < 0.0, content="true") // CW
}

///|
test "polygon perimeter of unit square is 4" {
  let square = [
    Point2::new(0.0, 0.0),
    Point2::new(1.0, 0.0),
    Point2::new(1.0, 1.0),
    Point2::new(0.0, 1.0),
  ]
  inspect(approx(polygon_perimeter(square), 4.0), content="true")
}

///|
test "polygon centroid of symmetric shape is center" {
  let square = [
    Point2::new(0.0, 0.0),
    Point2::new(2.0, 0.0),
    Point2::new(2.0, 2.0),
    Point2::new(0.0, 2.0),
  ]
  match polygon_centroid(square) {
    Some(c) => {
      inspect(approx(c.x(), 1.0), content="true")
      inspect(approx(c.y(), 1.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "polygon centroid of degenerate returns None" {
  match polygon_centroid([Point2::new(0.0, 0.0)]) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
  // Zero-area (collinear) polygon.
  match polygon_centroid([Point2::new(0.0, 0.0), Point2::new(1.0, 1.0), Point2::new(2.0, 2.0)]) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}
