// RGB ↔ HSL/HSV color space conversion for MoonBit Native Foundation.
//
// Consumed by SVG/CSS color parsing (hsl(), hsv() functions), mb-color/blend
// (the non-separable modes internally use luminance which is related to HSL
// lightness), and mb-canvas (gradient color interpolation).
//
// All conversions operate on normalized sRGB component values in [0, 1].
// HSL: Hue [0, 360), Saturation [0, 1], Lightness [0, 1].
// HSV: Hue [0, 360), Saturation [0, 1], Value [0, 1].

// ---------------------------------------------------------------------------
// HSL (Hue, Saturation, Lightness)
// ---------------------------------------------------------------------------

///|
/// Convert normalized sRGB to HSL.
///
/// Returns `(hue, saturation, lightness)` where hue is in [0, 360),
/// saturation and lightness are in [0, 1].
///
/// - `r`, `g`, `b`: normalized sRGB component values in [0, 1].
pub fn rgb_to_hsl(r : Double, g : Double, b : Double) -> (Double, Double, Double) {
  let max_c = max3(r, g, b)
  let min_c = min3(r, g, b)
  let delta = max_c - min_c
  let l = (max_c + min_c) / 2.0
  if delta < 1.0e-12 {
    // Achromatic (gray): hue and saturation are 0.
    return (0.0, 0.0, l)
  }
  let s = if l > 0.5 {
    delta / (2.0 - max_c - min_c)
  } else {
    delta / (max_c + min_c)
  }
  // Hue calculation.
  let h = if max_c == r {
    ((g - b) / delta) % 6.0
  } else if max_c == g {
    (b - r) / delta + 2.0
  } else {
    (r - g) / delta + 4.0
  }
  let hue = h * 60.0
  (if hue < 0.0 { hue + 360.0 } else { hue }, s, l)
}

///|
/// Convert HSL to normalized sRGB.
///
/// - `h`: hue in [0, 360)
/// - `s`: saturation in [0, 1]
/// - `l`: lightness in [0, 1]
///
/// Returns `(r, g, b)` in [0, 1].
pub fn hsl_to_rgb(h : Double, s : Double, l : Double) -> (Double, Double, Double) {
  if s < 1.0e-12 {
    // Achromatic: all channels equal lightness.
    return (l, l, l)
  }
  let c = (1.0 - (2.0 * l - 1.0).abs()) * s
  let hp = h / 60.0
  let x = c * (1.0 - (hp % 2.0 - 1.0).abs())
  let (r1, g1, b1) = if hp < 1.0 {
    (c, x, 0.0)
  } else if hp < 2.0 {
    (x, c, 0.0)
  } else if hp < 3.0 {
    (0.0, c, x)
  } else if hp < 4.0 {
    (0.0, x, c)
  } else if hp < 5.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  let m = l - c / 2.0
  (r1 + m, g1 + m, b1 + m)
}

// ---------------------------------------------------------------------------
// HSV (Hue, Saturation, Value)
// ---------------------------------------------------------------------------

///|
/// Convert normalized sRGB to HSV.
///
/// Returns `(hue, saturation, value)` where hue is in [0, 360),
/// saturation and value are in [0, 1].
pub fn rgb_to_hsv(r : Double, g : Double, b : Double) -> (Double, Double, Double) {
  let max_c = max3(r, g, b)
  let min_c = min3(r, g, b)
  let delta = max_c - min_c
  let v = max_c
  if delta < 1.0e-12 {
    return (0.0, 0.0, v)
  }
  let s = delta / max_c
  let h = if max_c == r {
    ((g - b) / delta) % 6.0
  } else if max_c == g {
    (b - r) / delta + 2.0
  } else {
    (r - g) / delta + 4.0
  }
  let hue = h * 60.0
  (if hue < 0.0 { hue + 360.0 } else { hue }, s, v)
}

///|
/// Convert HSV to normalized sRGB.
///
/// - `h`: hue in [0, 360)
/// - `s`: saturation in [0, 1]
/// - `v`: value in [0, 1]
///
/// Returns `(r, g, b)` in [0, 1].
pub fn hsv_to_rgb(h : Double, s : Double, v : Double) -> (Double, Double, Double) {
  if s < 1.0e-12 {
    return (v, v, v)
  }
  let c = v * s
  let hp = h / 60.0
  let x = c * (1.0 - (hp % 2.0 - 1.0).abs())
  let (r1, g1, b1) = if hp < 1.0 {
    (c, x, 0.0)
  } else if hp < 2.0 {
    (x, c, 0.0)
  } else if hp < 3.0 {
    (0.0, c, x)
  } else if hp < 4.0 {
    (0.0, x, c)
  } else if hp < 5.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  let m = v - c
  (r1 + m, g1 + m, b1 + m)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

///|
fn max3(a : Double, b : Double, c : Double) -> Double {
  if a >= b {
    if a >= c {
      a
    } else {
      c
    }
  } else if b >= c {
    b
  } else {
    c
  }
}

///|
fn min3(a : Double, b : Double, c : Double) -> Double {
  if a <= b {
    if a <= c {
      a
    } else {
      c
    }
  } else if b <= c {
    b
  } else {
    c
  }
}
