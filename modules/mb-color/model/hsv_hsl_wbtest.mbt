// White-box tests for RGB ↔ HSL/HSV color conversions.

///|
fn approx3(a : (Double, Double, Double), b : (Double, Double, Double)) -> Bool {
  let tol = 1.0e-10
  let (a1, a2, a3) = a
  let (b1, b2, b3) = b
  let d1 = if a1 > b1 { a1 - b1 } else { b1 - a1 }
  let d2 = if a2 > b2 { a2 - b2 } else { b2 - a2 }
  let d3 = if a3 > b3 { a3 - b3 } else { b3 - a3 }
  d1 <= tol && d2 <= tol && d3 <= tol
}

///|
test "rgb_to_hsl of pure red is (0, 1, 0.5)" {
  inspect(approx3(rgb_to_hsl(1.0, 0.0, 0.0), (0.0, 1.0, 0.5)), content="true")
}

///|
test "rgb_to_hsl of pure green is (120, 1, 0.5)" {
  inspect(approx3(rgb_to_hsl(0.0, 1.0, 0.0), (120.0, 1.0, 0.5)), content="true")
}

///|
test "rgb_to_hsl of pure blue is (240, 1, 0.5)" {
  inspect(approx3(rgb_to_hsl(0.0, 0.0, 1.0), (240.0, 1.0, 0.5)), content="true")
}

///|
test "rgb_to_hsl of gray has zero saturation" {
  let (h, s, l) = rgb_to_hsl(0.5, 0.5, 0.5)
  inspect(s == 0.0, content="true")
  inspect(l == 0.5, content="true")
  let _ = h
}

///|
test "rgb_to_hsl of white and black" {
  let (_, s_w, l_w) = rgb_to_hsl(1.0, 1.0, 1.0)
  inspect(l_w == 1.0, content="true")
  let (_, s_b, l_b) = rgb_to_hsl(0.0, 0.0, 0.0)
  inspect(l_b == 0.0, content="true")
  let _ = s_w
  let _ = s_b
}

///|
test "hsl_to_rgb round-trips through rgb_to_hsl" {
  let cases = [(0.3, 0.6, 0.9), (0.1, 0.2, 0.3), (0.8, 0.1, 0.5), (1.0, 1.0, 0.0)]
  for c in cases {
    let (h, s, l) = rgb_to_hsl(c.0, c.1, c.2)
    let (r2, g2, b2) = hsl_to_rgb(h, s, l)
    inspect(approx3(c, (r2, g2, b2)), content="true")
  }
}

///|
test "rgb_to_hsv of pure red is (0, 1, 1)" {
  inspect(approx3(rgb_to_hsv(1.0, 0.0, 0.0), (0.0, 1.0, 1.0)), content="true")
}

///|
test "rgb_to_hsv of gray has zero saturation" {
  let (_, s, v) = rgb_to_hsv(0.5, 0.5, 0.5)
  inspect(s == 0.0, content="true")
  inspect(v == 0.5, content="true")
}

///|
test "hsv_to_rgb round-trips through rgb_to_hsv" {
  let cases = [(0.3, 0.6, 0.9), (0.1, 0.2, 0.3), (0.8, 0.1, 0.5), (0.0, 1.0, 0.0)]
  for c in cases {
    let (h, s, v) = rgb_to_hsv(c.0, c.1, c.2)
    let (r2, g2, b2) = hsv_to_rgb(h, s, v)
    inspect(approx3(c, (r2, g2, b2)), content="true")
  }
}

///|
test "hsl and hsv produce values in valid ranges" {
  let cases = [(0.0, 0.0, 0.0), (1.0, 1.0, 1.0), (0.3, 0.6, 0.9), (0.5, 0.5, 0.5)]
  for c in cases {
    let (h_hsl, s_hsl, l) = rgb_to_hsl(c.0, c.1, c.2)
    inspect(h_hsl >= 0.0 && h_hsl < 360.0, content="true")
    inspect(s_hsl >= 0.0 && s_hsl <= 1.0, content="true")
    inspect(l >= 0.0 && l <= 1.0, content="true")
    let (h_hsv, s_hsv, v) = rgb_to_hsv(c.0, c.1, c.2)
    inspect(h_hsv >= 0.0 && h_hsv < 360.0, content="true")
    inspect(s_hsv >= 0.0 && s_hsv <= 1.0, content="true")
    inspect(v >= 0.0 && v <= 1.0, content="true")
  }
}
