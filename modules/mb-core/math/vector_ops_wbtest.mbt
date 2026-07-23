// White-box tests for Vector2 dot/cross/perpendicular and Point2 distance/lerp.

///|
test "vector dot product" {
  let v = Vector2::new(3.0, 4.0)
  let w = Vector2::new(2.0, -1.0)
  inspect(v.dot(w) == 2.0, content="true") // 3*2 + 4*(-1) = 2
  // Perpendicular vectors have zero dot.
  let east = Vector2::new(1.0, 0.0)
  let north = Vector2::new(0.0, 1.0)
  inspect(east.dot(north) == 0.0, content="true")
  // Same direction has positive dot.
  inspect(east.dot(east) == 1.0, content="true")
}

///|
test "vector cross product detects winding" {
  let east = Vector2::new(1.0, 0.0)
  let north = Vector2::new(0.0, 1.0)
  // east × north = 1*1 - 0*0 = 1 (CCW, positive)
  inspect(east.cross(north) == 1.0, content="true")
  // north × east = 0*0 - 1*1 = -1 (CW, negative)
  inspect(north.cross(east) == -1.0, content="true")
  // Collinear vectors have zero cross.
  inspect(east.cross(east) == 0.0, content="true")
}

///|
test "vector perpendicular rotates 90 degrees CCW" {
  let east = Vector2::new(1.0, 0.0)
  let p = east.perpendicular()
  inspect(p.dx() == 0.0, content="true")
  inspect(p.dy() == 1.0, content="true") // (-0, 1) = north
  let north = Vector2::new(0.0, 1.0)
  let p2 = north.perpendicular()
  inspect(p2.dx() == -1.0, content="true") // (-1, 0) = west
  inspect(p2.dy() == 0.0, content="true")
}

///|
test "vector subtract" {
  let v = Vector2::new(5.0, 10.0)
  let w = Vector2::new(2.0, 3.0)
  let d = v.sub(w)
  inspect(d.dx() == 3.0, content="true")
  inspect(d.dy() == 7.0, content="true")
}

///|
test "point distance computes Euclidean distance" {
  let a = Point2::new(0.0, 0.0)
  let b = Point2::new(3.0, 4.0)
  inspect(a.distance_to(b) == 5.0, content="true")
  // Same point.
  inspect(a.distance_to(a) == 0.0, content="true")
}

///|
test "point distance squared avoids sqrt" {
  let a = Point2::new(0.0, 0.0)
  let b = Point2::new(3.0, 4.0)
  inspect(a.distance_squared_to(b) == 25.0, content="true")
}

///|
test "point lerp interpolates at parameter t" {
  let a = Point2::new(0.0, 0.0)
  let b = Point2::new(10.0, 20.0)
  let mid = a.lerp(b, 0.5)
  inspect(mid.x() == 5.0, content="true")
  inspect(mid.y() == 10.0, content="true")
  // t=0 returns a.
  let start = a.lerp(b, 0.0)
  inspect(start.x() == 0.0, content="true")
  // t=1 returns b.
  let end = a.lerp(b, 1.0)
  inspect(end.x() == 10.0, content="true")
}
