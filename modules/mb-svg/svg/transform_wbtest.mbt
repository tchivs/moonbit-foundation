// White-box tests for transform attribute parsing.

fn tx(m : @math.Affine2) -> Double {
  m.tx()
}

fn ty(m : @math.Affine2) -> Double {
  m.ty()
}

///|
test "parse_transform empty is identity" {
  match parse_transform("") {
    Ok(m) => inspect(tx(m), content="0")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform translate" {
  match parse_transform("translate(10,20)") {
    Ok(m) => inspect((tx(m), ty(m)), content="(10, 20)")
    Err(_) => inspect(false, content="true")
  }
  // Single-arg translate: translate(x) → (x, 0).
  match parse_transform("translate(5)") {
    Ok(m) => inspect((tx(m), ty(m)), content="(5, 0)")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform scale" {
  match parse_transform("scale(2)") {
    Ok(m) => inspect((m.a(), m.d()), content="(2, 2)")
    Err(_) => inspect(false, content="true")
  }
  match parse_transform("scale(2,3)") {
    Ok(m) => inspect((m.a(), m.d()), content="(2, 3)")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform matrix" {
  match parse_transform("matrix(1,2,3,4,5,6)") {
    Ok(m) => inspect((m.a(), m.b(), m.c(), m.d(), tx(m), ty(m)), content="(1, 2, 3, 4, 5, 6)")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform multiple transforms compose" {
  // translate(10,0) then scale(2): point (1,0) → scale → (2,0) → translate → (12,0).
  // compose order: result = identity * translate * scale, so a point is
  // transformed as scale first then translate: (1,0).apply(scale) = (2,0),
  // then .apply(translate-composed) ... Actually Affine2::compose semantics:
  // a.compose(b).apply(p) = a.apply(b.apply(p)). So identity.compose(translate).compose(scale)
  // applies scale first, then translate. (1,0) → scale(2,2) → (2,0) → translate(10,0) → (12,0).
  match parse_transform("translate(10,0) scale(2)") {
    Ok(m) => {
      let p = m.apply(@math.Point2::new(1.0, 0.0))
      inspect((p.x(), p.y()), content="(12, 0)")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform skewX and skewY" {
  match parse_transform("skewX(0)") {
    Ok(_) => inspect(true, content="true")
    Err(_) => inspect(false, content="true")
  }
  match parse_transform("skewY(0)") {
    Ok(_) => inspect(true, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform unknown function errors" {
  match parse_transform("foo(1,2)") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}

///|
test "parse_transform rotate uses degrees (rotate(90) maps (1,0)→(0,1))" {
  // SVG rotate takes degrees; 90° must send (1,0) to (0,1), not 90 radians.
  match parse_transform("rotate(90)") {
    Ok(m) => {
      let p = m.apply(@math.Point2::new(1.0, 0.0))
      // Allow tiny float error around the expected (0,1).
      inspect((p.x().abs() < 1.0e-9, (p.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform rotate with center keeps the center fixed" {
  // rotate(90, 1, 1): the point AT the center (1,1) must stay at (1,1).
  match parse_transform("rotate(90, 1, 1)") {
    Ok(m) => {
      let p = m.apply(@math.Point2::new(1.0, 1.0))
      inspect(((p.x() - 1.0).abs() < 1.0e-9, (p.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
      // A point one unit to the right of the center, (2,1), rotates 90° about
      // (1,1) to one unit above: (1,2).
      let q = m.apply(@math.Point2::new(2.0, 1.0))
      inspect(((q.x() - 1.0).abs() < 1.0e-9, (q.y() - 2.0).abs() < 1.0e-9), content="(true, true)")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform result is invertible (T ∘ T⁻¹ = identity)" {
  // RFC 0002 §6.1 promises transform composition AND inversion. parse_transform
  // returns an Affine2 whose inverse() composes back to identity.
  match parse_transform("translate(10,20) scale(2) rotate(45)") {
    Ok(m) =>
      match m.inverse() {
        None => inspect(false, content="true") // non-invertible transform
        Some(inv) => {
          let id = m.compose(inv)
          // identity has a=d=1, b=c=tx=ty=0.
          inspect(
            ((id.a() - 1.0).abs() < 1.0e-9 && (id.d() - 1.0).abs() < 1.0e-9 && id.tx().abs() < 1.0e-9 && id.ty().abs() < 1.0e-9),
            content="true",
          )
        }
      }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_transform rotate needs angle or angle,cx,cy (2 args errors)" {
  match parse_transform("rotate(90, 1)") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}

///|
test "numeric contract: affine and trigonometric controls" {
  // SVG-NUM-TRANSFORM / SVG-NUM-AFFINE: each constructor remains finite at the boundary.
  match parse_transform("matrix(1,0,0,1,65536,-65536)") {
    Ok(m) => inspect((m.a(), m.d(), tx(m), ty(m)), content="(1, 1, 65536, -65536)")
    Err(_) => inspect(false, content="true")
  }
  match parse_transform("translate(65536,-65536)") {
    Ok(m) => inspect((tx(m), ty(m)), content="(65536, -65536)")
    Err(_) => inspect(false, content="true")
  }
  // D-05: finite singular transforms remain valid even though inverse() is None.
  match parse_transform("scale(0,65536)") {
    Ok(m) => {
      inspect((m.a(), m.d()), content="(0, 65536)")
      match m.inverse() {
        None => inspect(true, content="true")
        Some(_) => inspect(false, content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
  // SVG-NUM-TRIG: degree conversion and both skew constructors retain finite outputs.
  match parse_transform("rotate(90)") {
    Ok(m) => {
      let point = m.apply(@math.Point2::new(1.0, 0.0))
      inspect((point.x().abs() < 1.0e-9, (point.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
    }
    Err(_) => inspect(false, content="true")
  }
  match parse_transform("skewX(45)") {
    Ok(m) => {
      let point = m.apply(@math.Point2::new(0.0, 1.0))
      inspect(((point.x() - 0.7853981633974483).abs() < 1.0e-9, (point.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
    }
    Err(_) => inspect(false, content="true")
  }
  match parse_transform("skewY(45)") {
    Ok(m) => {
      let point = m.apply(@math.Point2::new(1.0, 0.0))
      inspect(((point.x() - 1.0).abs() < 1.0e-9, (point.y() - 0.7853981633974483).abs() < 1.0e-9), content="(true, true)")
    }
    Err(_) => inspect(false, content="true")
  }
  // SVG-NUM-AFFINE: composition preserves the documented finite endpoint.
  match parse_transform("translate(65535,0) scale(0.5)") {
    Ok(m) => {
      let point = m.apply(@math.Point2::new(2.0, 0.0))
      inspect((point.x(), point.y()), content="(65536, 0)")
    }
    Err(_) => inspect(false, content="true")
  }
}
