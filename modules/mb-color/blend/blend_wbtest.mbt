// W3C Compositing and Blending Level 1 separable blend mode verification.
//
// Each test applies the spec formula B(Cb, Cs) to known input pairs and
// asserts the result against a hand-computed expected value, using an
// absolute tolerance that accommodates IEEE-754 double precision.

///|
fn blend_close(mode : BlendMode, cb : Double, cs : Double, expected : Double) -> Bool {
  let actual = blend_separable(mode, cb, cs)
  let diff = if actual > expected {
    actual - expected
  } else {
    expected - actual
  }
  diff <= 1.0e-12
}

///|
test "multiply blend follows W3C 5.3.1 B = Cb * Cs" {
  inspect(blend_close(Multiply, 0.0, 0.5, 0.0), content="true")
  inspect(blend_close(Multiply, 1.0, 0.5, 0.5), content="true")
  inspect(blend_close(Multiply, 0.5, 0.5, 0.25), content="true")
  inspect(blend_close(Multiply, 0.8, 0.4, 0.32), content="true")
  inspect(blend_close(Multiply, 1.0, 1.0, 1.0), content="true")
}

///|
test "screen blend follows W3C 5.3.2 B = Cb + Cs - Cb*Cs" {
  inspect(blend_close(Screen, 0.0, 0.0, 0.0), content="true")
  inspect(blend_close(Screen, 1.0, 0.0, 1.0), content="true")
  inspect(blend_close(Screen, 0.0, 1.0, 1.0), content="true")
  inspect(blend_close(Screen, 0.5, 0.5, 0.75), content="true")
  inspect(blend_close(Screen, 0.8, 0.4, 0.88), content="true")
}

///|
test "overlay blend follows W3C 5.3.5 (HardLight with operands swapped)" {
  inspect(blend_close(Overlay, 0.3, 0.8, 0.48), content="true")
  inspect(blend_close(Overlay, 0.7, 0.8, 0.88), content="true")
  inspect(blend_close(Overlay, 0.0, 0.5, 0.0), content="true")
  inspect(blend_close(Overlay, 1.0, 0.5, 1.0), content="true")
}

///|
test "darken blend follows W3C 5.3.3 B = min(Cb, Cs)" {
  inspect(blend_close(Darken, 0.3, 0.7, 0.3), content="true")
  inspect(blend_close(Darken, 0.7, 0.3, 0.3), content="true")
  inspect(blend_close(Darken, 0.5, 0.5, 0.5), content="true")
  inspect(blend_close(Darken, 0.0, 0.9, 0.0), content="true")
}

///|
test "lighten blend follows W3C 5.3.4 B = max(Cb, Cs)" {
  inspect(blend_close(Lighten, 0.3, 0.7, 0.7), content="true")
  inspect(blend_close(Lighten, 0.7, 0.3, 0.7), content="true")
  inspect(blend_close(Lighten, 0.5, 0.5, 0.5), content="true")
  inspect(blend_close(Lighten, 1.0, 0.1, 1.0), content="true")
}

///|
test "color dodge blend follows W3C 5.3.6" {
  inspect(blend_close(ColorDodge, 0.5, 0.5, 1.0), content="true")
  inspect(blend_close(ColorDodge, 0.0, 0.5, 0.0), content="true")
  inspect(blend_close(ColorDodge, 0.5, 1.0, 1.0), content="true")
  inspect(blend_close(ColorDodge, 0.6, 0.25, 0.8), content="true")
  inspect(blend_close(ColorDodge, 0.3, 0.9, 1.0), content="true")
}

///|
test "color burn blend follows W3C 5.3.7" {
  inspect(blend_close(ColorBurn, 0.5, 0.5, 0.0), content="true")
  inspect(blend_close(ColorBurn, 1.0, 0.5, 1.0), content="true")
  inspect(blend_close(ColorBurn, 0.5, 0.0, 0.0), content="true")
  inspect(blend_close(ColorBurn, 0.4, 0.8, 0.25), content="true")
  inspect(blend_close(ColorBurn, 0.9, 0.1, 0.0), content="true")
}

///|
test "hard light blend follows W3C 5.3.8" {
  inspect(blend_close(HardLight, 0.8, 0.3, 0.48), content="true")
  inspect(blend_close(HardLight, 0.8, 0.7, 0.88), content="true")
  inspect(blend_close(HardLight, 0.5, 0.5, 0.5), content="true")
  // Cb=0.0, Cs=0.9: Screen(0.0, 0.8) = 0.0 + 0.8 - 0 = 0.8
  inspect(blend_close(HardLight, 0.0, 0.9, 0.8), content="true")
}

///|
test "soft light blend follows W3C 5.3.9 PegTop definition" {
  inspect(blend_close(SoftLight, 0.5, 0.3, 0.4), content="true")
  let d = @math.pow(0.5, 0.5)
  inspect(blend_close(SoftLight, 0.5, 0.7, 0.5 + 0.4 * (d - 0.5)), content="true")
  inspect(blend_close(SoftLight, 0.2, 0.3, 0.136), content="true")
}

///|
test "difference blend follows W3C 5.3.10 B = |Cb - Cs|" {
  inspect(blend_close(Difference, 0.3, 0.7, 0.4), content="true")
  inspect(blend_close(Difference, 0.7, 0.3, 0.4), content="true")
  inspect(blend_close(Difference, 0.5, 0.5, 0.0), content="true")
  inspect(blend_close(Difference, 1.0, 0.0, 1.0), content="true")
}

///|
test "exclusion blend follows W3C 5.3.11 B = Cb + Cs - 2*Cb*Cs" {
  inspect(blend_close(Exclusion, 0.3, 0.7, 0.58), content="true")
  inspect(blend_close(Exclusion, 0.5, 0.5, 0.5), content="true")
  inspect(blend_close(Exclusion, 0.0, 0.0, 0.0), content="true")
  inspect(blend_close(Exclusion, 1.0, 1.0, 0.0), content="true")
}

///|
test "blend clamps out-of-range floating results to 0..1" {
  for mode in [Multiply, Screen, Overlay, Darken, Lighten, ColorDodge, ColorBurn, HardLight, SoftLight, Difference, Exclusion] {
    for cb in [0.0, 0.25, 0.5, 0.75, 1.0] {
      for cs in [0.0, 0.25, 0.5, 0.75, 1.0] {
        let r = blend_separable(mode, cb, cs)
        inspect(r >= 0.0, content="true")
        inspect(r <= 1.0, content="true")
      }
    }
  }
}
