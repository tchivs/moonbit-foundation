// Coverage computation for path fills: nonzero/even-odd winding via ray casting,
// with supersampling antialiasing.
//
// Given a set of flattened line segments (the output of mb-core/math's
// Path2::flattened) and a pixel center, we compute the fill coverage by casting
// a horizontal ray and counting signed crossings. For antialiasing we subsample
// each pixel on an N×N grid and average the inside/outside results.
//
// This is the pure-algorithm core of the rasterizer (RFC 0003 §6.1, §7.1). It
// has no image dependency and is tested directly with known geometry.

///|
/// Compute the winding number contribution at sample point `(px, py)` against
/// the closed segments. Returns the signed crossing count (positive for
/// downward-crossing edges, negative for upward), which is nonzero inside a
/// nonzero-rule fill and whose parity (odd/even) determines even-odd fills.
fn winding_at(
  segments : Array[@math.LineSegment],
  px : Double,
  py : Double,
) -> Int {
  let mut winding = 0
  for seg in segments {
    let (x0, y0) = (seg.start().x(), seg.start().y())
    let (x1, y1) = (seg.end().x(), seg.end().y())
    // Standard ray-crossing test with half-open y-interval to avoid double-
    // counting shared vertices. We treat an edge as crossing the horizontal
    // ray at height py when one endpoint is at or below py and the other is
    // strictly above.
    if (y0 <= py && y1 > py) || (y1 <= py && y0 > py) {
      // x-coordinate where the edge crosses y = py, by linear interpolation.
      let cross_x = x0 + (py - y0) / (y1 - y0) * (x1 - x0)
      if cross_x > px {
        // The crossing is to the right of the sample point.
        if y0 < y1 {
          winding += 1 // downward edge (increasing y) contributes +1
        } else {
          winding -= 1 // upward edge contributes -1
        }
      }
    }
  }
  winding
}

///|
/// True if the sample point is inside the fill under the given rule.
fn point_inside(
  segments : Array[@math.LineSegment],
  rule : FillRule,
  px : Double,
  py : Double,
) -> Bool {
  let w = winding_at(segments, px, py)
  match rule {
    Nonzero => w != 0
    EvenOdd => w % 2 != 0
  }
}

///|
/// Compute the coverage (fraction of subsample points inside the fill) for the
/// pixel whose top-left corner is at `(px, py)`, using an `n`×`n` supersampling
/// grid. Coverage is in [0, 1]; 0 means fully outside, 1 means fully inside.
///
/// The pixel covers the unit square [px, px+1) × [py, py+1). Subsample points
/// are placed at the centers of the n×n cells: (px + (j+0.5)/n, py + (i+0.5)/n).
fn pixel_coverage(
  segments : Array[@math.LineSegment],
  rule : FillRule,
  px : Double,
  py : Double,
  n : Int,
) -> Double {
  let mut hits = 0
  let total = n * n
  let inv_n = 1.0 / n.to_double()
  for i = 0; i < n; i = i + 1 {
    let sy = py + (i.to_double() + 0.5) * inv_n
    for j = 0; j < n; j = j + 1 {
      let sx = px + (j.to_double() + 0.5) * inv_n
      if point_inside(segments, rule, sx, sy) {
        hits += 1
      }
    }
  }
  hits.to_double() / total.to_double()
}

///|
/// The default supersampling factor (4×4 = 16 samples per pixel) per RFC 0003
/// §7.1's "declared sample count".
let default_samples : Int = 4
