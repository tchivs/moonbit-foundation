// W3C Compositing and Blending Level 1 non-separable blend modes.
//
// These operate on whole colors (not per-channel independently): Hue,
// Saturation, Color, and Luminosity. They require luminance, saturation,
// and color-clipping helpers defined by the W3C spec (Section 5.4).
//
// Like the separable modes, these operate on normalized straight (non-
// premultiplied) linear sRGB component triples. Each function takes the
// backdrop color (Cb) and source color (Cs) as (r, g, b) triples and returns
// a blended (r, g, b) triple.
//
// Reference: W3C Compositing and Blending Level 1, Section 5.4.

///|
/// W3C luminance of an sRGB color: L = 0.3*R + 0.59*G + 0.11*B.
fn lum(r : Double, g : Double, b : Double) -> Double {
  0.3 * r + 0.59 * g + 0.11 * b
}

///|
/// Set the luminance of a color to a target value, clipping to [0, 1].
fn set_lum(r : Double, g : Double, b : Double, target : Double) -> (Double, Double, Double) {
  let l = lum(r, g, b)
  let d = target - l
  let nr = r + d
  let ng = g + d
  let nb = b + d
  clip_color(nr, ng, nb)
}

///|
/// Clip a color so that its components stay in [0, 1] while preserving
/// luminance. W3C Compositing and Blending Level 1 Section 5.4:
///
///   if min < 0: C = L + (C - L) * L / (L - min)
///   if max > 1: C = L + (C - L) * (1 - L) / (max - L)
fn clip_color(r : Double, g : Double, b : Double) -> (Double, Double, Double) {
  let l = lum(r, g, b)
  let min_c = min3(r, g, b)
  let (nr, ng, nb) = if min_c < 0.0 {
    let factor = l / (l - min_c)
    (l + (r - l) * factor, l + (g - l) * factor, l + (b - l) * factor)
  } else {
    (r, g, b)
  }
  let l2 = lum(nr, ng, nb)
  let max2 = max3(nr, ng, nb)
  if max2 > 1.0 {
    let factor = (1.0 - l2) / (max2 - l2)
    (l2 + (nr - l2) * factor, l2 + (ng - l2) * factor, l2 + (nb - l2) * factor)
  } else {
    (nr, ng, nb)
  }
}

///|
/// W3C saturation of a color: S = max(R,G,B) - min(R,G,B).
fn sat(r : Double, g : Double, b : Double) -> Double {
  max3(r, g, b) - min3(r, g, b)
}

///|
/// Set the saturation of a color to a target value.
///
/// The W3C algorithm orders the components, then scales the intermediate
/// values between min and max to achieve the target saturation.
fn set_sat(r : Double, g : Double, b : Double, target : Double) -> (Double, Double, Double) {
  // Identify the component ordering (min, mid, max) while preserving which
  // channel each value belongs to.
  // W3C set_sat: find min, mid, max indices, then:
  //   if max > min: mid = (mid - min) * s / (max - min); max = s; min = 0
  //   else: mid = 0; max = 0; min = 0
  let arr = [(r, 0), (g, 1), (b, 2)]
  // Sort by value (stable insertion sort for 3 elements).
  let sorted = sort3(arr)
  let min_val = sorted[0].0
  let mid_val = sorted[1].0
  let max_val = sorted[2].0
  let min_idx = sorted[0].1
  let mid_idx = sorted[1].1
  let max_idx = sorted[2].1
  let (new_mid, new_max) = if max_val > min_val {
    ((mid_val - min_val) * target / (max_val - min_val), target)
  } else {
    (0.0, 0.0)
  }
  // Write back to the original channels.
  let results = [0.0, 0.0, 0.0]
  results[min_idx] = 0.0
  results[mid_idx] = new_mid
  results[max_idx] = new_max
  (results[0], results[1], results[2])
}

///|
/// Sort an array of (value, index) pairs by value ascending.
fn sort3(arr : Array[(Double, Int)]) -> Array[(Double, Int)] {
  let result = [(arr[0].0, arr[0].1), (arr[1].0, arr[1].1), (arr[2].0, arr[2].1)]
  // Simple insertion sort for 3 elements.
  if result[0].0 > result[1].0 {
    swap(result, 0, 1)
  }
  if result[1].0 > result[2].0 {
    swap(result, 1, 2)
  }
  if result[0].0 > result[1].0 {
    swap(result, 0, 1)
  }
  result
}

///|
fn swap(arr : Array[(Double, Int)], i : Int, j : Int) -> Unit {
  let temp = arr[i]
  arr[i] = arr[j]
  arr[j] = temp
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
/// Blend Hue: takes the hue of the source with the saturation and luminance
/// of the backdrop.
///
/// B(Cb, Cs) = SetLum(SetSat(Cs, Sat(Cb)), Lum(Cb))
pub fn blend_hue(cb_r : Double, cb_g : Double, cb_b : Double, cs_r : Double, cs_g : Double, cs_b : Double) -> (Double, Double, Double) {
  let (sr, sg, sb) = set_sat(cs_r, cs_g, cs_b, sat(cb_r, cb_g, cb_b))
  set_lum(sr, sg, sb, lum(cb_r, cb_g, cb_b))
}

///|
/// Blend Saturation: takes the saturation of the source with the hue and
/// luminance of the backdrop.
///
/// B(Cb, Cs) = SetLum(SetSat(Cb, Sat(Cs)), Lum(Cb))
pub fn blend_saturation(cb_r : Double, cb_g : Double, cb_b : Double, cs_r : Double, cs_g : Double, cs_b : Double) -> (Double, Double, Double) {
  let (sr, sg, sb) = set_sat(cb_r, cb_g, cb_b, sat(cs_r, cs_g, cs_b))
  set_lum(sr, sg, sb, lum(cb_r, cb_g, cb_b))
}

///|
/// Blend Color: takes both the hue and saturation of the source with the
/// luminance of the backdrop.
///
/// B(Cb, Cs) = SetLum(Cs, Lum(Cb))
pub fn blend_color_mode(cb_r : Double, cb_g : Double, cb_b : Double, cs_r : Double, cs_g : Double, cs_b : Double) -> (Double, Double, Double) {
  set_lum(cs_r, cs_g, cs_b, lum(cb_r, cb_g, cb_b))
}

///|
/// Blend Luminosity: takes the luminance of the source with the hue and
/// saturation of the backdrop.
///
/// B(Cb, Cs) = SetLum(Cb, Lum(Cs))
pub fn blend_luminosity(cb_r : Double, cb_g : Double, cb_b : Double, cs_r : Double, cs_g : Double, cs_b : Double) -> (Double, Double, Double) {
  set_lum(cb_r, cb_g, cb_b, lum(cs_r, cs_g, cs_b))
}
