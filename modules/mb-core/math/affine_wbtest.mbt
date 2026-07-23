// White-box tests for 2D affine geometry.
//
// Uses exact double comparisons with small tolerance for trig operations.

let math_tolerance : Double = 1.0e-10

///|
fn approx(a : Double, b : Double) -> Bool {
  let diff = if a > b {
    a - b
  } else {
    b - a
  }
  diff <= math_tolerance
}

///|
fn point_approx(p : Point2, x : Double, y : Double) -> Bool {
  approx(p.x(), x) && approx(p.y(), y)
}

///|
test "point translate and vector_to are inverses" {
  let p = Point2::new(3.0, 4.0)
  let q = Point2::new(10.0, 20.0)
  let v = p.vector_to(q)
  inspect(approx(v.dx(), 7.0), content="true")
  inspect(approx(v.dy(), 16.0), content="true")
  // Translating p by v should land at q.
  inspect(point_approx(p.translate(v), 10.0, 20.0), content="true")
}

///|
test "vector add and scale follow component-wise arithmetic" {
  let v = Vector2::new(1.0, 2.0)
  let w = Vector2::new(3.0, 4.0)
  let sum = v.add(w)
  inspect(approx(sum.dx(), 4.0), content="true")
  inspect(approx(sum.dy(), 6.0), content="true")
  let scaled = v.scale(2.5)
  inspect(approx(scaled.dx(), 2.5), content="true")
  inspect(approx(scaled.dy(), 5.0), content="true")
}

///|
test "vector length_squared matches Pythagoras" {
  inspect(approx(Vector2::new(3.0, 4.0).length_squared(), 25.0), content="true")
  inspect(approx(Vector2::zero().length_squared(), 0.0), content="true")
}

///|
test "identity transform leaves points unchanged" {
  let id = Affine2::identity()
  let p = Point2::new(5.0, -3.0)
  inspect(point_approx(id.apply(p), 5.0, -3.0), content="true")
}

///|
test "translate transform shifts coordinates" {
  let t = Affine2::translate(10.0, 20.0)
  let p = Point2::new(1.0, 2.0)
  inspect(point_approx(t.apply(p), 11.0, 22.0), content="true")
}

///|
test "scale transform multiplies coordinates" {
  let s = Affine2::scale(2.0, 3.0)
  let p = Point2::new(4.0, 5.0)
  inspect(point_approx(s.apply(p), 8.0, 15.0), content="true")
}

///|
test "rotate transform by 90 degrees maps x to y" {
  // 90 degrees = pi/2 radians; cos=0, sin=1.
  let r = Affine2::rotate(1.5707963267948966)
  let p = Point2::new(1.0, 0.0)
  // After 90deg CCW rotation: (0, 1).
  inspect(point_approx(r.apply(p), 0.0, 1.0), content="true")
}

///|
test "skew transform shears coordinates" {
  let s = Affine2::skew(0.5, 0.0)
  let p = Point2::new(2.0, 4.0)
  // x' = x + shx*y = 2 + 0.5*4 = 4, y' = y + shy*x = 4.
  inspect(point_approx(s.apply(p), 4.0, 4.0), content="true")
}

///|
test "compose translate then scale applies in order" {
  // First translate by (10, 20), then scale by (2, 2).
  let combined = Affine2::translate(10.0, 20.0).compose(Affine2::scale(2.0, 2.0))
  let p = Point2::new(1.0, 1.0)
  // scale(translate(1,1)) = scale(11,21) = (22,42).
  inspect(point_approx(combined.apply(p), 22.0, 42.0), content="true")
}

///|
test "compose is associative with identity" {
  let t = Affine2::translate(5.0, 5.0)
  let id = Affine2::identity()
  let p = Point2::new(3.0, 7.0)
  // t ∘ id == t.
  inspect(point_approx(t.compose(id).apply(p), 8.0, 12.0), content="true")
  // id ∘ t == t.
  inspect(point_approx(id.compose(t).apply(p), 8.0, 12.0), content="true")
}

///|
test "rotate then rotate by 180 is negation" {
  let r90 = Affine2::rotate(1.5707963267948966)
  let r180 = r90.compose(r90)
  let p = Point2::new(3.0, 4.0)
  // Two 90deg rotations = 180deg: (-3, -4).
  inspect(point_approx(r180.apply(p), -3.0, -4.0), content="true")
}

///|
test "affine accessors return stored components" {
  let m = Affine2::new(1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
  inspect(approx(m.a(), 1.0), content="true")
  inspect(approx(m.b(), 2.0), content="true")
  inspect(approx(m.c(), 3.0), content="true")
  inspect(approx(m.d(), 4.0), content="true")
  inspect(approx(m.tx(), 5.0), content="true")
  inspect(approx(m.ty(), 6.0), content="true")
}
