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
  dash_offset : Double
}

///|
/// Construct a stroke style with the given width, butt caps, miter joins, the
/// default miter limit of 4.0, a solid (no-dash) pattern, and zero dash offset.
pub fn StrokeStyle::new(width : Double) -> StrokeStyle {
  {
    width,
    cap: LineCap::Butt,
    join: LineJoin::Miter,
    miter_limit: 4.0,
    dash: [],
    dash_offset: 0.0,
  }
}

// ---------------------------------------------------------------------------
// FillStyle setters / accessors
//
// The base constructor pins alpha=1.0 and the Nonzero rule. These value-typed
// setters return a new FillStyle with one field overridden, so styles compose
// by chaining (FillStyle::new(r,g,b).with_alpha(0.5).with_rule(EvenOdd)). They
// fulfill the "field setters" promised by FillStyle::new's doc comment and let
// cross-package callers (e.g. mb-svg) build styles they cannot construct
// directly, since FillStyle is read-only outside this package.
// ---------------------------------------------------------------------------

///|
/// Construct a fill style with a normalized-sRGB color and straight alpha.
/// `alpha` is clamped to [0,1] (NaN clamps to 0). Uses the Nonzero rule.
pub fn FillStyle::new_with_alpha(
  r : Double,
  g : Double,
  b : Double,
  alpha : Double,
) -> FillStyle {
  FillStyle::new(r, g, b).with_alpha(alpha)
}

///|
/// Return a copy of this style with the straight-alpha component set to `a`.
/// `a` is clamped to [0,1]; NaN clamps to 0. Other fields are unchanged.
pub fn FillStyle::with_alpha(self : FillStyle, a : Double) -> FillStyle {
  { ..self, color_a: clamp_unit(a) }
}

///|
/// Return a copy of this style with the winding rule set to `rule`.
pub fn FillStyle::with_rule(self : FillStyle, rule : FillRule) -> FillStyle {
  { ..self, rule, }
}

///|
/// The straight-alpha component in [0,1].
pub fn FillStyle::alpha(self : FillStyle) -> Double {
  self.color_a
}

// ---------------------------------------------------------------------------
// StrokeStyle setters
//
// Same value-typed pattern: each returns a new StrokeStyle with one field
// overridden, so stroke configuration composes by chaining. They close the
// gap that left cross-package callers unable to set cap/join/miter/dash.
// ---------------------------------------------------------------------------

///|
/// Return a copy of this style with the stroke width set to `width`.
pub fn StrokeStyle::with_width(
  self : StrokeStyle,
  width : Double,
) -> StrokeStyle {
  { ..self, width, }
}

///|
/// Return a copy of this style with the endpoint cap set to `cap`.
pub fn StrokeStyle::with_cap(self : StrokeStyle, cap : LineCap) -> StrokeStyle {
  { ..self, cap, }
}

///|
/// Return a copy of this style with the interior join set to `join`.
pub fn StrokeStyle::with_join(
  self : StrokeStyle,
  join : LineJoin,
) -> StrokeStyle {
  { ..self, join, }
}

///|
/// Return a copy of this style with the miter limit set to `miter_limit`.
pub fn StrokeStyle::with_miter_limit(
  self : StrokeStyle,
  miter_limit : Double,
) -> StrokeStyle {
  { ..self, miter_limit, }
}

///|
/// Return a copy of this style with the dash pattern set to `dash`. The dash
/// array is taken by value (alternating on/off lengths in user units; an empty
/// array means a solid stroke).
pub fn StrokeStyle::with_dash(
  self : StrokeStyle,
  dash : Array[Double],
) -> StrokeStyle {
  { ..self, dash, }
}

///|
/// Return a copy of this style with the dash pattern's start offset set to
/// `dash_offset` (in user units). A positive value shifts the pattern start
/// forward along the path; negative shifts it backward. Values exceeding the
/// pattern total length wrap modulo that length at rasterization time.
pub fn StrokeStyle::with_dash_offset(
  self : StrokeStyle,
  dash_offset : Double,
) -> StrokeStyle {
  { ..self, dash_offset, }
}

// Clamp a double into [0.0, 1.0]. NaN clamps to 0.0.

///|
fn clamp_unit(v : Double) -> Double {
  if v.is_nan() {
    return 0.0
  }
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }
}
