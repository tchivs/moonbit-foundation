// White-box tests for Affine2 inverse and Path2 flattened.

///|
test "affine inverse of identity is identity" {
  let id = Affine2::identity()
  match id.inverse() {
    Some(inv) => {
      let p = Point2::new(5.0, -3.0)
      let restored = inv.apply(id.apply(p))
      inspect(restored.x() == 5.0, content="true")
      inspect(restored.y() == -3.0, content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "affine inverse of translate returns to origin" {
  let t = Affine2::translate(10.0, 20.0)
  match t.inverse() {
    Some(inv) => {
      let p = Point2::new(1.0, 2.0)
      let moved = t.apply(p)
      inspect(moved.x() == 11.0, content="true")
      let restored = inv.apply(moved)
      inspect(restored.x() == 1.0, content="true")
      inspect(restored.y() == 2.0, content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "affine inverse of rotate undoes rotation" {
  let r = Affine2::rotate(0.5)
  match r.inverse() {
    Some(inv) => {
      let p = Point2::new(3.0, 4.0)
      let rotated = r.apply(p)
      let restored = inv.apply(rotated)
      let dx = if restored.x() > 3.0 { restored.x() - 3.0 } else { 3.0 - restored.x() }
      let dy = if restored.y() > 4.0 { restored.y() - 4.0 } else { 4.0 - restored.y() }
      inspect(dx < 1.0e-9, content="true")
      inspect(dy < 1.0e-9, content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "affine inverse of scale undoes scaling" {
  let s = Affine2::scale(2.0, 4.0)
  match s.inverse() {
    Some(inv) => {
      let p = Point2::new(6.0, 8.0)
      let restored = inv.apply(s.apply(p))
      inspect(restored.x() == 6.0, content="true")
      inspect(restored.y() == 8.0, content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "affine inverse returns None for singular transform" {
  // Zero determinant: a*d - b*c = 0
  let singular = Affine2::new(2.0, 4.0, 1.0, 2.0, 5.0, 6.0)
  match singular.inverse() {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "affine determinant of scale is product" {
  let s = Affine2::scale(3.0, 5.0)
  inspect(s.determinant() == 15.0, content="true")
  let r = Affine2::rotate(0.0)
  inspect(r.determinant() == 1.0, content="true")
}
