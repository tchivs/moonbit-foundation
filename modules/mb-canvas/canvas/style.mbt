// Fill and stroke style for mb-canvas drawing operations.
//
// Colors are normalized sRGB component values in [0, 1] in the encoded-sRGB
// domain (no transfer function applied). They are resolved through mb-color at
// rasterization time. The drawing list carries style as pure data; color
// resolution happens in the rasterizer, consistent with RFC 0003 §4.1.

///|
/// Winding rule for path fills.
pub(all) enum FillRule {
  Nonzero
  EvenOdd
} derive(Eq)

///|
/// Cap style for stroked path endpoints.
pub(all) enum LineCap {
  Butt
  Round
  Square
} derive(Eq)

///|
/// Join style for stroked path interior vertices.
pub(all) enum LineJoin {
  Miter
  Round
  Bevel
} derive(Eq)

///|
/// Fill style: a resolved normalized-sRGB color plus a winding rule.
///
/// `color_r`, `color_g`, `color_b` are encoded-sRGB components in [0, 1].
/// `color_a` is the alpha component in [0, 1] (straight alpha).
pub struct FillStyle {
  color_r : Double
  color_g : Double
  color_b : Double
  color_a : Double
  rule : FillRule
}

///|
/// Construct a fill style with an opaque normalized-sRGB color and the nonzero
/// winding rule. Use the field setters to override alpha or rule.
pub fn FillStyle::new(r : Double, g : Double, b : Double) -> FillStyle {
  { color_r: r, color_g: g, color_b: b, color_a: 1.0, rule: FillRule::Nonzero }
}

///|
/// Stroke style: geometric properties of a stroked path.
///
/// `width` is the stroke width in user units (must be > 0). `miter_limit` bounds
/// the miter join ratio (default 4.0, matching common 2D APIs); miters exceeding
/// it fall back to bevel. `dash` is an optional dash pattern as alternating
/// on/off lengths; an empty array means a solid stroke.
pub struct StrokeStyle {
  width : Double
  cap : LineCap
  join : LineJoin
  miter_limit : Double
  dash : Array[Double]
}

///|
/// Construct a stroke style with the given width, butt caps, miter joins, the
/// default miter limit of 4.0, and a solid (no-dash) pattern.
pub fn StrokeStyle::new(width : Double) -> StrokeStyle {
  {
    width,
    cap: LineCap::Butt,
    join: LineJoin::Miter,
    miter_limit: 4.0,
    dash: [],
  }
}
