// W3C Compositing and Blending Level 1 separable blend functions.
//
// These operate on normalized straight (non-premultiplied) sRGB component
// values in [0, 1]. The caller is responsible for premultiplying around the
// blend call: unpremultiply the backdrop and source, apply B(Cb, Cs) per
// channel, then premultiply the result. This matches the W3C spec, which
// defines B(Cb, Cs) on straight color regardless of alpha.
//
// Reference: W3C Compositing and Blending Level 1, Section 5.3 (Separable
// blend modes) and the per-mode formulas in 5.3.1 through 5.3.11.

///|
/// W3C separable blend modes (Compositing and Blending Level 1, Section 5.3).
/// Each variant selects the per-channel blend function B(Cb, Cs) applied to
/// the backdrop (destination) and source color channels.
pub(all) enum BlendMode {
  // Separable modes (per-channel independent)
  Multiply
  Screen
  Overlay
  Darken
  Lighten
  ColorDodge
  ColorBurn
  HardLight
  SoftLight
  Difference
  Exclusion
} derive(Eq)

///|
///
/// Apply a separable W3C blend function B(Cb, Cs) to a single normalized
/// channel pair. Both inputs must be in [0, 1]; the result is clamped to
/// [0, 1] so the caller can safely construct a validated component.
///
/// - `cb`: backdrop (destination) channel value
/// - `cs`: source channel value
pub fn blend_separable(mode : BlendMode, cb : Double, cs : Double) -> Double {
  let result = match mode {
    Multiply => blend_multiply(cb, cs)
    Screen => blend_screen(cb, cs)
    Overlay => blend_overlay(cb, cs)
    Darken => blend_darken(cb, cs)
    Lighten => blend_lighten(cb, cs)
    ColorDodge => blend_color_dodge(cb, cs)
    ColorBurn => blend_color_burn(cb, cs)
    HardLight => blend_hard_light(cb, cs)
    SoftLight => blend_soft_light(cb, cs)
    Difference => blend_difference(cb, cs)
    Exclusion => blend_exclusion(cb, cs)
  }
  // Clamp to [0, 1] to guard floating-point edge cases (e.g. ColorDodge
  // division producing values just above 1.0). W3C defines each B as
  // producing values in [0, 1].
  if result < 0.0 {
    0.0
  } else if result > 1.0 {
    1.0
  } else {
    result
  }
}

// --- Separable blend formulas (W3C 5.3.x) ---

///|
fn blend_multiply(cb : Double, cs : Double) -> Double {
  cb * cs
}

///|
fn blend_screen(cb : Double, cs : Double) -> Double {
  cb + cs - (cb * cs)
}

///|
fn blend_overlay(cb : Double, cs : Double) -> Double {
  // Overlay is HardLight with backdrop and source swapped (W3C 5.3.5).
  blend_hard_light(cs, cb)
}

///|
fn blend_darken(cb : Double, cs : Double) -> Double {
  if cb < cs {
    cb
  } else {
    cs
  }
}

///|
fn blend_lighten(cb : Double, cs : Double) -> Double {
  if cb > cs {
    cb
  } else {
    cs
  }
}

///|
fn blend_color_dodge(cb : Double, cs : Double) -> Double {
  if cs >= 1.0 {
    1.0
  } else if cb <= 0.0 {
    0.0
  } else {
    let v = cb / (1.0 - cs)
    if v > 1.0 {
      1.0
    } else {
      v
    }
  }
}

///|
fn blend_color_burn(cb : Double, cs : Double) -> Double {
  if cs <= 0.0 {
    0.0
  } else if cb >= 1.0 {
    1.0
  } else {
    let v = 1.0 - ((1.0 - cb) / cs)
    if v < 0.0 {
      0.0
    } else {
      v
    }
  }
}

///|
fn blend_hard_light(cb : Double, cs : Double) -> Double {
  // W3C 5.3.8: if Cs <= 0.5, Multiply × 2; otherwise Screen × 2.
  if cs <= 0.5 {
    blend_multiply(cb, cs * 2.0)
  } else {
    blend_screen(cb, 2.0 * cs - 1.0)
  }
}

///|
fn blend_soft_light(cb : Double, cs : Double) -> Double {
  // W3C 5.3.9 (PegTop / W3C canonical definition).
  let d = if cb <= 0.25 {
    ((16.0 * cb - 12.0) * cb + 4.0) * cb
  } else {
    // sqrt(cb) expressed as pow(cb, 0.5) to match the existing @math.pow
    // convention used by mb-color/transfer, avoiding a separate sqrt import.
    @math.pow(cb, 0.5)
  }
  if cs <= 0.5 {
    cb - (1.0 - 2.0 * cs) * cb * (1.0 - cb)
  } else {
    cb + (2.0 * cs - 1.0) * (d - cb)
  }
}

///|
fn blend_difference(cb : Double, cs : Double) -> Double {
  if cb > cs {
    cb - cs
  } else {
    cs - cb
  }
}

///|
fn blend_exclusion(cb : Double, cs : Double) -> Double {
  cb + cs - 2.0 * cb * cs
}
