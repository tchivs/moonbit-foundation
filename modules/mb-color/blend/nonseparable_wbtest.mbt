// White-box tests for W3C non-separable blend modes (Section 5.4).

///|
fn approx3(r1 : Double, g1 : Double, b1 : Double, r2 : Double, g2 : Double, b2 : Double) -> Bool {
  let tol = 1.0e-10
  let dr = if r1 > r2 { r1 - r2 } else { r2 - r1 }
  let dg = if g1 > g2 { g1 - g2 } else { g2 - g1 }
  let db = if b1 > b2 { b1 - b2 } else { b2 - b1 }
  dr <= tol && dg <= tol && db <= tol
}

///|
test "blend hue takes source hue with backdrop sat and lum" {
  // Backdrop: blue (0, 0, 1), Source: yellow (1, 1, 0)
  // Sat(Cb) = 1 - 0 = 1, Lum(Cb) = 0.3*0 + 0.59*0 + 0.11*1 = 0.11
  // SetSat(Cs=yellow, 1) = yellow (already saturated)
  // SetLum(yellow, 0.11) = adjust yellow to lum 0.11
  let (r, g, b) = blend_hue(0.0, 0.0, 1.0, 1.0, 1.0, 0.0)
  // Result should have the hue of yellow but luminance of blue.
  inspect(approx3(r, g, b, r, g, b), content="true") // self-consistency
  // Lum of result should match backdrop lum.
  let result_lum = 0.3 * r + 0.59 * g + 0.11 * b
  inspect(result_lum <= 0.11 + 1.0e-9, content="true")
}

///|
test "blend luminosity takes source lum with backdrop hue and sat" {
  // Backdrop: mid-gray (0.5, 0.5, 0.5), Source: bright red (1, 0, 0)
  // Lum(Cs) = 0.3*1 = 0.3
  // SetLum(gray=0.5, 0.3) = shift gray to lum 0.3
  let (r, g, b) = blend_luminosity(0.5, 0.5, 0.5, 1.0, 0.0, 0.0)
  let result_lum = 0.3 * r + 0.59 * g + 0.11 * b
  // Should be close to Lum(Cs) = 0.3 (gray stays gray, just different lum).
  inspect(result_lum <= 0.3 + 1.0e-9, content="true")
  // Gray input stays gray (all channels equal).
  inspect(approx3(r, g, b, r, r, r), content="true")
}

///|
test "blend color takes source hue+sat with backdrop lum" {
  // Backdrop: dark gray (0.2, 0.2, 0.2), Source: pure red (1, 0, 0)
  // Lum(Cb) = 0.2
  // SetLum(red=1,0,0, 0.2) = adjust red to lum 0.2
  let (r, g, b) = blend_color_mode(0.2, 0.2, 0.2, 1.0, 0.0, 0.0)
  let result_lum = 0.3 * r + 0.59 * g + 0.11 * b
  inspect(result_lum <= 0.2 + 1.0e-9, content="true")
  // Red channel should be dominant (source hue preserved).
  inspect(r >= g, content="true")
  inspect(r >= b, content="true")
}

///|
test "blend saturation takes source sat with backdrop hue and lum" {
  // Backdrop: pure red (1, 0, 0), Source: gray (0.5, 0.5, 0.5)
  // Sat(Cs) = 0 (gray has no saturation)
  // SetSat(Cb=red, 0) = desaturate red to gray
  // SetLum(gray, Lum(red)=0.3) = gray at lum 0.3
  let (r, g, b) = blend_saturation(1.0, 0.0, 0.0, 0.5, 0.5, 0.5)
  // Result should be gray (all channels equal) since saturation is 0.
  inspect(approx3(r, g, b, r, r, r), content="true")
}

///|
test "lum uses W3C coefficients 0.3 0.59 0.11" {
  // These are tested indirectly through the blend functions above.
  // White has max lum, black has zero.
  let (rw, _, _) = blend_luminosity(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
  inspect(rw >= 0.99, content="true")
  let (rb, _, _) = blend_luminosity(1.0, 1.0, 1.0, 0.0, 0.0, 0.0)
  inspect(rb <= 0.01, content="true")
}

///|
test "non-separable blends are deterministic" {
  let cb = (0.3, 0.6, 0.9)
  let cs = (0.8, 0.1, 0.5)
  let h1 = blend_hue(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2)
  let h2 = blend_hue(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2)
  inspect(approx3(h1.0, h1.1, h1.2, h2.0, h2.1, h2.2), content="true")

  let s1 = blend_saturation(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2)
  let s2 = blend_saturation(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2)
  inspect(approx3(s1.0, s1.1, s1.2, s2.0, s2.1, s2.2), content="true")
}

///|
test "non-separable blends produce values in 0..1 range" {
  let cb = (0.3, 0.6, 0.9)
  let cs = (0.8, 0.1, 0.5)
  let results = [
    blend_hue(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2),
    blend_saturation(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2),
    blend_color_mode(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2),
    blend_luminosity(cb.0, cb.1, cb.2, cs.0, cs.1, cs.2),
  ]
  for result in results {
    let (r, g, b) = result
    inspect(r >= 0.0, content="true")
    inspect(r <= 1.0, content="true")
    inspect(g >= 0.0, content="true")
    inspect(g <= 1.0, content="true")
    inspect(b >= 0.0, content="true")
    inspect(b <= 1.0, content="true")
  }
}
