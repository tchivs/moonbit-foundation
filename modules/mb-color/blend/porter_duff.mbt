// Porter-Duff alpha compositing operators for MoonBit Native Foundation.
//
// Complements the W3C separable and non-separable blend modes. These
// operators define how two layers' alpha channels interact, independent of
// any blend mode. The W3C Compositing and Blending Level 1 specification
// defines 13 Porter-Duff operators; this file implements the full set.
//
// Each operator takes straight (non-premultiplied) source and backdrop
// color + alpha, and returns the composited straight color + alpha.
// All math operates in normalized straight color space per the W3C spec.
//
// Reference: W3C Compositing and Blending Level 1, Section 5.1-5.2.

///|
/// Porter-Duff compositing operator. Controls how source and backdrop
/// alpha channels combine to produce the output alpha and color.
pub(all) enum CompositeOp {
  /// No pixels: both source and backdrop are cleared.
  Clear
  /// Only source pixels survive.
  Source
  /// Only backdrop pixels survive.
  Destination
  /// Source-over (the default normal compositing).
  SourceOver
  /// Destination-over: backdrop drawn on top of source.
  DestinationOver
  /// Source-in: only where source and backdrop overlap, show source.
  SourceIn
  /// Destination-in: only where they overlap, show backdrop.
  DestinationIn
  /// Source-out: source where there is no backdrop.
  SourceOut
  /// Destination-out: backdrop where there is no source.
  DestinationOut
  /// Source-atop: source where backdrop exists, plus backdrop elsewhere.
  SourceAtop
  /// Destination-atop: backdrop where source exists, plus source elsewhere.
  DestinationAtop
  /// XOR: source where no backdrop, backdrop where no source.
  Xor
} derive(Eq)

///|
/// Composite a source color over a backdrop using a Porter-Duff operator.
///
/// All inputs are straight (non-premultiplied) normalized values in [0, 1].
/// Returns `(r, g, b, alpha)` of the composited result.
///
/// - `src_rgb`: (r, g, b) of the source color
/// - `src_a`: alpha of the source
/// - `dst_rgb`: (r, g, b) of the backdrop color
/// - `dst_a`: alpha of the backdrop
pub fn porter_duff_composite(
  op : CompositeOp,
  src_rgb : (Double, Double, Double),
  src_a : Double,
  dst_rgb : (Double, Double, Double),
  dst_a : Double,
) -> (Double, Double, Double, Double) {
  let (sr, sg, sb) = src_rgb
  let (dr, dg, db) = dst_rgb
  // Compute the coverage factors for source (Fa) and backdrop (Fb).
  let (fa, fb) = porter_duff_factors(op, src_a, dst_a)
  // Result alpha: αr = αs·Fa + αb·Fb
  let result_a = src_a * fa + dst_a * fb
  if result_a <= 0.0 {
    return (0.0, 0.0, 0.0, 0.0)
  }
  // Result color: Cr = (αs·Fa·Cs + αb·Fb·Cb) / αr
  let inv_a = 1.0 / result_a
  let cr = (src_a * fa * sr + dst_a * fb * dr) * inv_a
  let cg = (src_a * fa * sg + dst_a * fb * dg) * inv_a
  let cb = (src_a * fa * sb + dst_a * fb * db) * inv_a
  (cr, cg, cb, result_a)
}

///|
/// Compute the Porter-Duff coverage factors (Fa, Fb) for source and backdrop.
///
/// Per W3C Table 5.1: each operator defines how much of the source (Fa)
/// and backdrop (Fb) contribute based on their alphas.
fn porter_duff_factors(op : CompositeOp, src_a : Double, dst_a : Double) -> (Double, Double) {
  match op {
    Clear => (0.0, 0.0)
    Source => (1.0, 0.0)
    Destination => (0.0, 1.0)
    SourceOver => (1.0, 1.0 - src_a)
    DestinationOver => (1.0 - dst_a, 1.0)
    SourceIn => (dst_a, 0.0)
    DestinationIn => (0.0, src_a)
    SourceOut => (1.0 - dst_a, 0.0)
    DestinationOut => (0.0, 1.0 - src_a)
    SourceAtop => (dst_a, 1.0 - src_a)
    DestinationAtop => (1.0 - dst_a, src_a)
    Xor => (1.0 - dst_a, 1.0 - src_a)
  }
}
