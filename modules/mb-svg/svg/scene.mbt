// SVG scene tree construction: markup token stream → typed SceneNode tree.
//
// Sits on top of the four leaf parsers (parse_color / parse_length /
// parse_viewbox / parse_transform / parse_path_data) and the bounded XML
// tokenizer in mb-core/text (tokenize_markup). This is the combinator layer
// that turns a flat MarkupToken stream into a recursive scene representation.
//
// Representation choice (RFC 0002 §6.1): structure nodes (svg, g) keep their
// structural attributes resolved (transform, viewBox); leaf shape nodes
// (rect, circle, ellipse, line, polyline, polygon, path) carry their geometry
// and a resolved Paint (fill/stroke already in normalized sRGB). lower.mbt
// therefore only has to apply transforms and emit DrawOps.
//
// Element names not in the §6.1 subset (text, defs, linearGradient, use, ...)
// are RFC §6.2 deferred. They are skipped together with their whole subtree:
// skipping is not implementation, so the deferral boundary stays intact.
//
// Paint inheritance and currentColor ARE implemented: a PaintContext of
// resolved values is threaded down the build functions; each element merges
// its own presentation attributes (fill, stroke, color, opacity, stroke-style
// family) against the inherited context. currentColor resolves against the
// inherited `color` attribute (default black). See build_paint.
//
// Known follow-ups (deliberately out of v0.1 scope, flagged inline):
//   - clip-rule is not parsed (follow-up; lower assumes Nonzero for clips).
//
// Error handling follows the rest of mb-svg: CoreError is a plain struct, so
// plain Result + match / return Err is used throughout (no raise/try!).

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

///|
/// Document-level attributes captured from the root <svg> element.
/// Width/height default to None when absent (sized by consumer); viewBox is
/// the parsed "min-x min-y width height" tuple when present.
pub struct SvgRoot {
  width : Double?
  height : Double?
  view_box : (Double, Double, Double, Double)?
  preserve_aspect_ratio : PreserveAspectRatio
}

///|
/// Resolved `preserveAspectRatio` value. `align_x`/`align_y` are Min=0,
/// Mid=1, Max=2; `meet` is true for "meet" (whole viewBox fits, default),
/// false for "slice" (viewBox fills viewport, overflow clipped). When align
/// is "none", both align fields are Mid and uniform scaling is disabled
/// (signaled by the separate `none` flag).
pub struct PreserveAspectRatio {
  align_x : Int
  align_y : Int
  meet : Bool // true=meet, false=slice
  none : Bool // align="none": non-uniform scaling, fill viewport
}

///|
/// Resolved fill/stroke paint for a shape. Color components are normalized
/// sRGB in [0,1] (the domain mb-canvas FillStyle consumes); None means "none".
pub struct Paint {
  fill : (Double, Double, Double)?
  stroke : (Double, Double, Double)?
  fill_opacity : Double
  stroke_opacity : Double
  stroke_width : Double
  stroke_cap : @canvas.LineCap
  stroke_join : @canvas.LineJoin
  stroke_miterlimit : Double
  stroke_dash : Array[Double]
  // Element-level opacity (the `opacity` attribute): the whole element (fill
  // and stroke together) is composited onto the backdrop at this opacity. 1.0
  // = no effect. Distinct from fill_opacity/stroke_opacity (per-paint).
  opacity : Double
  stroke_dashoffset : Double
  fill_rule : @canvas.FillRule
}

// ---------------------------------------------------------------------------
// Paint inheritance context
//
// SVG presentation attributes (fill, stroke, color, the opacity/stroke-style
// family) are *inherited*: a child that does not set an attribute takes the
// nearest ancestor's value, falling back to the SVG default only when no
// ancestor sets it. Paint stores fully-resolved values, so inheritance is
// resolved at build time by threading a PaintContext down the build functions.
//
// PaintContext holds RESOLVED values (the cumulative result from the root to
// this element). build_paint merges each attribute: if the element sets it,
// parse and use it; otherwise inherit the context value; if neither, use the
// SVG default. The "explicit none" case (`fill="none"`) is carried as a
// resolved Option=None and IS inherited as-is, which is correct: a child that
// does not set fill inherits the ancestor's none. (SVG `fill="none"` on a
// group makes the whole group unfilled unless a descendant re-specifies fill.)
// ---------------------------------------------------------------------------

// Resolved inherited values threaded through the build. `color` is the
// currentColor source (the `color` attribute); fill/stroke use Option where
// None = paint "none".
struct PaintContext {
  color : (Double, Double, Double)
  fill : (Double, Double, Double)?
  stroke : (Double, Double, Double)?
  fill_opacity : Double
  stroke_opacity : Double
  stroke_width : Double
  fill_rule : @canvas.FillRule
  stroke_cap : @canvas.LineCap
  stroke_join : @canvas.LineJoin
  stroke_miterlimit : Double
  stroke_dash : Array[Double]
  stroke_dashoffset : Double
}

// Root context: SVG defaults. color (currentColor) defaults to black; fill to
// black; stroke to none; opacity 1.0; width 1.0; butt/miter/4/solid.
fn root_paint_context() -> PaintContext {
  {
    color: (0.0, 0.0, 0.0),
    fill: Some((0.0, 0.0, 0.0)),
    stroke: None,
    fill_opacity: 1.0,
    stroke_opacity: 1.0,
    stroke_width: 1.0,
    fill_rule: @canvas.FillRule::Nonzero,
    stroke_cap: @canvas.LineCap::Butt,
    stroke_join: @canvas.LineJoin::Miter,
    stroke_miterlimit: 4.0,
    stroke_dash: [],
    stroke_dashoffset: 0.0,
  }
}

///|
/// A node in the SVG scene tree. Structure nodes carry resolved transform and
/// children; leaf shapes carry resolved geometry and paint.
pub enum SceneNode {
  Svg(SvgRoot, Array[SceneNode])
  Group(@math.Affine2, Double, Array[SceneNode]) // transform, opacity, children
  Rect(
    Paint,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
  ) // paint, x, y, w, h, rx, ry
  Circle(Paint, Double, Double, Double) // paint, cx, cy, r
  Ellipse(Paint, Double, Double, Double, Double) // paint, cx, cy, rx, ry
  Line(Paint, Double, Double, Double, Double) // paint, x1, y1, x2, y2
  Polyline(Paint, Array[@math.Point2])
  Polygon(Paint, Array[@math.Point2])
  Path(Paint, @canvas.CanvasPath)
}

///|
/// Parse an SVG source string into a scene tree rooted at a single <svg>
/// element. Returns an error if the markup is malformed, the root element is
/// not <svg>, a required attribute (e.g. <path d>) is missing, or the input
/// exceeds the default resource budget (depth, token/work count).
///
/// Leading trivia (whitespace Text, Comment) before the root <svg> is
/// skipped. Trailing content after the root close is ignored.
pub fn parse_svg(source : String) -> Result[SceneNode, @error.CoreError] {
  parse_svg_with_budget(source, default_parse_budget())
}

///|
/// Parse with a caller-supplied resource budget. Use this for untrusted input
/// to enforce document-size, nesting-depth, path-command, and attribute-count
/// ceilings (per RFC 0002 §8 "Bounded input"). A budget whose work dimension
/// is exhausted, or whose depth limit is exceeded by nested groups, yields a
/// structured error instead of unbounded allocation/recursion.
pub fn parse_svg_with_budget(
  source : String,
  budget : @budget.Budget,
) -> Result[SceneNode, @error.CoreError] {
  let tokens = match @text.tokenize_markup(source) {
    Ok(t) => t
    Err(e) => return Err(e)
  }
  let st : TokenCursor = {
    tokens: tokens,
    pos: 0,
    len: tokens.length(),
  }
  // Skip leading Text/Comment trivia until the root start tag.
  match skip_leading_trivia(st, budget) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  if st.pos >= st.len {
    return Err(svg_error("svg-scene", "no root <svg> element"))
  }
  match st.tokens[st.pos] {
    StartTag(name) =>
      if name == "svg" {
        match build_svg_root(st, root_paint_context(), budget) {
          Ok(node) => {
            // `SceneNode` is the public parser boundary. Validate every
            // deterministic lowering derivation before exposing it; the total
            // lowerer intentionally remains a consumer, not an error source.
            match preflight_scene(node) {
              Ok(_) => {
                ignore_trailing(st)
                Ok(node)
              }
              Err(error) => Err(error)
            }
          }
          Err(e) => Err(e)
        }
      } else {
        Err(svg_error("svg-scene", "root element is not <svg>: " + name))
      }
    _ => Err(svg_error("svg-scene", "expected <svg> start tag"))
  }
}

// Default budget for parse_svg: depth 64, work 2,000,000 (covers token count,
// path commands, and attribute pairs), plus modest byte/allocation headroom
// for scene construction. These are conservative ceilings far above any
// reasonable SVG document; callers handling hostile input may pass tighter
// limits via parse_svg_with_budget.
fn default_parse_budget() -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=16777216UL, // 16 MiB ceiling for scene allocations
    allocations=262144UL,
    allocation_size=16777216UL,
    width=65536UL,
    height=65536UL,
    pixels=0UL,
    depth=64UL,
    work=2000000UL,
  ))
}

// ---------------------------------------------------------------------------
// Parser-side derived geometry preflight
// ---------------------------------------------------------------------------
//
// These calculations mirror lower.mbt without allocating a DrawingList. They
// admit every source-combination seam before parse_svg publishes SceneNode;
// manually constructed SceneNode values deliberately keep the public total
// lower_to_drawing_list contract.

fn preflight_scene(node : SceneNode) -> Result[Unit, @error.CoreError] {
  preflight_node(node, @math.Affine2::identity())
}

fn preflight_node(
  node : SceneNode,
  current : @math.Affine2,
) -> Result[Unit, @error.CoreError] {
  match node {
    Svg(root, children) => {
      let map = match preflight_viewbox_transform(root) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let next = match preflight_compose(current, map) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      preflight_children(children, next)
    }
    Group(transform, _, children) => {
      let next = match preflight_compose(current, transform) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      preflight_children(children, next)
    }
    Rect(_, x, y, w, h, rx, ry) => {
      match preflight_rect(x, y, w, h, rx, ry) {
        Ok(_) => preflight_path_points(rect_path(x, y, w, h, rx, ry), current)
        Err(error) => Err(error)
      }
    }
    Circle(_, cx, cy, r) => {
      match preflight_ellipse(cx, cy, r, r) {
        Ok(_) => preflight_path_points(circle_path(cx, cy, r), current)
        Err(error) => Err(error)
      }
    }
    Ellipse(_, cx, cy, rx, ry) => {
      match preflight_ellipse(cx, cy, rx, ry) {
        Ok(_) => preflight_path_points(ellipse_path(cx, cy, rx, ry), current)
        Err(error) => Err(error)
      }
    }
    Line(_, x1, y1, x2, y2) => {
      match preflight_point(current, @math.Point2::new(x1, y1)) {
        Ok(_) => preflight_point(current, @math.Point2::new(x2, y2))
        Err(error) => Err(error)
      }
    }
    Polyline(_, points) | Polygon(_, points) => preflight_points(points, current)
    Path(_, path) => preflight_path_points(path.to_path2(), current)
  }
}

fn preflight_children(
  children : Array[SceneNode],
  current : @math.Affine2,
) -> Result[Unit, @error.CoreError] {
  for child in children {
    match preflight_node(child, current) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

fn scene_derived_add(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a + b)
}

fn scene_derived_sub(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a - b)
}

fn scene_derived_mul(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a * b)
}

fn scene_derived_div(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a / b)
}

fn scene_product_sum(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
) -> Result[Double, @error.CoreError] {
  let left = match scene_derived_mul(a, b) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let right = match scene_derived_mul(c, d) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  scene_derived_add(left, right)
}

// Mirrors Affine2::compose: current first, then `other`, exactly as the
// canvas transform stack combines successive PushTransform operations.
fn preflight_compose(
  current : @math.Affine2,
  other : @math.Affine2,
) -> Result[@math.Affine2, @error.CoreError] {
  let a = match scene_product_sum(other.a(), current.a(), other.c(), current.b()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let b = match scene_product_sum(other.b(), current.a(), other.d(), current.b()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let c = match scene_product_sum(other.a(), current.c(), other.c(), current.d()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let d = match scene_product_sum(other.b(), current.c(), other.d(), current.d()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let tx_base = match scene_product_sum(other.a(), current.tx(), other.c(), current.ty()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ty_base = match scene_product_sum(other.b(), current.tx(), other.d(), current.ty()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let tx = match scene_derived_add(tx_base, other.tx()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ty = match scene_derived_add(ty_base, other.ty()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(@math.Affine2::new(a, b, c, d, tx, ty))
}

fn preflight_viewbox_transform(root : SvgRoot) -> Result[@math.Affine2, @error.CoreError] {
  let par = root.preserve_aspect_ratio
  match (root.view_box, root.width, root.height) {
    (Some((vbx, vby, vbw, vbh)), Some(vpw), Some(vph)) =>
      if vbw <= 0.0 || vbh <= 0.0 || vpw <= 0.0 || vph <= 0.0 {
        Ok(@math.Affine2::identity())
      } else {
        let sx = match scene_derived_div(vpw, vbw) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let sy = match scene_derived_div(vph, vbh) {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        if par.none {
          let tx = match scene_derived_mul(-vbx, sx) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ty = match scene_derived_mul(-vby, sy) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          Ok(@math.Affine2::new(sx, 0.0, 0.0, sy, tx, ty))
        } else {
          let scale = if par.meet {
            if sx < sy { sx } else { sy }
          } else if sx > sy {
            sx
          } else {
            sy
          }
          let width_scaled = match scene_derived_mul(vbw, scale) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let height_scaled = match scene_derived_mul(vbh, scale) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let diff_x = match scene_derived_sub(vpw, width_scaled) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let diff_y = match scene_derived_sub(vph, height_scaled) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let offset_x_product = match scene_derived_mul(par.align_x.to_double(), diff_x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let offset_y_product = match scene_derived_mul(par.align_y.to_double(), diff_y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let offset_x = match scene_derived_div(offset_x_product, 2.0) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let offset_y = match scene_derived_div(offset_y_product, 2.0) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let vbx_scaled = match scene_derived_mul(vbx, scale) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let vby_scaled = match scene_derived_mul(vby, scale) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let tx = match scene_derived_sub(offset_x, vbx_scaled) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ty = match scene_derived_sub(offset_y, vby_scaled) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          Ok(@math.Affine2::new(scale, 0.0, 0.0, scale, tx, ty))
        }
      }
    _ => Ok(@math.Affine2::identity())
  }
}

fn preflight_rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rx_in : Double,
  ry_in : Double,
) -> Result[Unit, @error.CoreError] {
  if rx_in <= 0.0 && ry_in <= 0.0 {
    return Ok(())
  }
  let rx0 = if rx_in <= 0.0 { ry_in } else { rx_in }
  let ry0 = if ry_in <= 0.0 { rx_in } else { ry_in }
  let max_rx = match scene_derived_div(w, 2.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let max_ry = match scene_derived_div(h, 2.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let mut rx = if rx0 > max_rx { max_rx } else { rx0 }
  let mut ry = if ry0 > max_ry { max_ry } else { ry0 }
  if rx > 0.0 {
    let ratio = match scene_derived_div(max_rx, rx) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if ratio < 1.0 {
      ry = match scene_derived_mul(ry, ratio) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
    }
    let ratio_y = match scene_derived_div(max_ry, ry) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if ratio_y < 1.0 {
      rx = match scene_derived_mul(rx, ratio_y) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
    }
  }
  match scene_derived_mul(rx, 0.5522847498307936) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match scene_derived_mul(ry, 0.5522847498307936) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  // The path-point pass below admits every x±radius/y±radius construction.
  let _ = x
  let _ = y
  Ok(())
}

fn preflight_ellipse(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
) -> Result[Unit, @error.CoreError] {
  let step = match scene_derived_div(6.283185307179586, 32.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  for i = 0; i < 32; i = i + 1 {
    let angle = match scene_derived_mul(step, i.to_double()) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let cos_angle = match admit_derived(@math.cos(angle)) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let sin_angle = match admit_derived(@math.sin(angle)) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let x_delta = match scene_derived_mul(rx, cos_angle) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let y_delta = match scene_derived_mul(ry, sin_angle) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match scene_derived_add(cx, x_delta) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    match scene_derived_add(cy, y_delta) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

fn preflight_points(
  points : Array[@math.Point2],
  transform : @math.Affine2,
) -> Result[Unit, @error.CoreError] {
  for point in points {
    match preflight_point(transform, point) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

fn preflight_path_points(
  path : @math.Path2,
  transform : @math.Affine2,
) -> Result[Unit, @error.CoreError] {
  for i = 0; i < path.length(); i = i + 1 {
    match path.get(i) {
      Some(@math.PathCommand::MoveTo(point)) | Some(@math.PathCommand::LineTo(point)) =>
        match preflight_point(transform, point) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      Some(@math.PathCommand::QuadTo(control, endpoint)) => {
        match preflight_point(transform, control) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
        match preflight_point(transform, endpoint) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      }
      Some(@math.PathCommand::CubicTo(control1, control2, endpoint)) => {
        match preflight_point(transform, control1) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
        match preflight_point(transform, control2) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
        match preflight_point(transform, endpoint) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      }
      Some(@math.PathCommand::Close) | None => ()
    }
  }
  Ok(())
}

fn preflight_point(
  transform : @math.Affine2,
  point : @math.Point2,
) -> Result[Unit, @error.CoreError] {
  let x = match preflight_component(transform.a(), point.x(), transform.c(), point.y(), transform.tx()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y = match preflight_component(transform.b(), point.x(), transform.d(), point.y(), transform.ty()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match admit_derived(x) {
    Ok(_) => admit_derived(y).map(fn(_) { () })
    Err(error) => Err(error)
  }
}

fn preflight_component(
  a : Double,
  x : Double,
  c : Double,
  y : Double,
  translation : Double,
) -> Result[Double, @error.CoreError] {
  let linear = match scene_product_sum(a, x, c, y) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  scene_derived_add(linear, translation)
}

// Charge one unit of work for consuming a token. Returns Err on budget
// exhaustion (work dimension). Centralizes the per-token bound.
fn charge_token(budget : @budget.Budget) -> Result[Unit, @error.CoreError] {
  match budget.charge(@budget.ResourceCharge::new(
    bytes=0UL,
    allocations=0UL,
    allocation_size=0UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=1UL,
  )) {
    Ok(_) => Ok(())
    Err(_) => Err(svg_error("svg-budget", "work limit exceeded"))
  }
}

// ---------------------------------------------------------------------------
// Internal: cursor over the flat MarkupToken stream
// ---------------------------------------------------------------------------

priv struct TokenCursor {
  tokens : Array[@text.MarkupToken]
  mut pos : Int
  len : Int
}

fn skip_leading_trivia(
  st : TokenCursor,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  while st.pos < st.len {
    match st.tokens[st.pos] {
      Text(_) | Comment(_) => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
      }
      _ => break
    }
  }
  Ok(())
}

fn ignore_trailing(st : TokenCursor) -> Unit {
  st.pos = st.len
}

// Build the Svg node: read the root <svg ...> start tag, its children, and
// the matching </svg>. Returns the Svg SceneNode. The root's own presentation
// attributes (color, fill, ...) merge into the inherited context and thread
// down to children.
fn build_svg_root(
  st : TokenCursor,
  ctx : PaintContext,
  budget : @budget.Budget,
) -> Result[SceneNode, @error.CoreError] {
  // st.pos is at StartTag("svg"). Charge for the start tag token.
  match charge_token(budget) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  st.pos = st.pos + 1
  let (attrs, is_empty) = match build_attrs(st, budget) {
    Ok(a) => a
    Err(e) => return Err(e)
  }
  let root = match build_svg_root_attrs(attrs) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (_, child_ctx) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if is_empty {
    return Ok(SceneNode::Svg(root, []))
  }
  match build_children(st, "svg", child_ctx, budget) {
    Ok(children) => Ok(SceneNode::Svg(root, children))
    Err(e) => Err(e)
  }
}

// Read the attribute pairs of a start tag, then consume the tag terminator.
// Returns the (name, value) list and whether the tag was self-closing
// (EmptyTagEnd `/>`); a `>` terminator yields is_empty = false. Each consumed
// token (AttributeName, AttributeValue, terminator) is charged against the
// budget's work dimension, bounding per-element attribute count and total
// token volume.
fn build_attrs(
  st : TokenCursor,
  budget : @budget.Budget,
) -> Result[(Array[(String, String)], Bool), @error.CoreError] {
  let attrs : Array[(String, String)] = []
  while st.pos < st.len {
    match st.tokens[st.pos] {
      AttributeName(name) => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
        if st.pos >= st.len {
          return Err(svg_error("svg-scene", "attribute '" + name + "' has no value"))
        }
        match st.tokens[st.pos] {
          AttributeValue(v) => {
            match charge_token(budget) {
              Ok(_) => ()
              Err(e) => return Err(e)
            }
            attrs.push((name, v))
            st.pos = st.pos + 1
          }
          _ =>
            return Err(svg_error(
              "svg-scene",
              "expected value for attribute '" + name + "'",
            ))
        }
      }
      TagEnd => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
        return Ok((attrs, false))
      }
      EmptyTagEnd => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
        return Ok((attrs, true))
      }
      _ => return Err(svg_error("svg-scene", "unexpected token in start tag"))
    }
  }
  Err(svg_error("svg-scene", "unterminated start tag"))
}

// Read children of the element named `parent` until its matching EndTag.
// Dispatches known §6.1 elements to their builders; skips unknown subtrees.
// `ctx` is the inherited paint context for the children. Each consumed token
// is charged, bounding document size.
fn build_children(
  st : TokenCursor,
  parent : String,
  ctx : PaintContext,
  budget : @budget.Budget,
) -> Result[Array[SceneNode], @error.CoreError] {
  let children : Array[SceneNode] = []
  while st.pos < st.len {
    match st.tokens[st.pos] {
      StartTag(name) =>
        match build_element(st, name, ctx, budget) {
          Ok(Some(node)) => children.push(node)
          Ok(None) => () // skipped subtree (unknown/deferred element)
          Err(e) => return Err(e)
        }
      EndTag(n) =>
        if n == parent {
          // Consume EndTag + its TagEnd.
          match charge_token(budget) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
          st.pos = st.pos + 1
          if st.pos < st.len {
            match st.tokens[st.pos] {
              TagEnd => {
                match charge_token(budget) {
                  Ok(_) => ()
                  Err(e) => return Err(e)
                }
                st.pos = st.pos + 1
              }
              _ => ()
            }
          }
          return Ok(children)
        } else {
          // Stray end tag: treat as error to surface malformed markup.
          return Err(svg_error(
            "svg-scene",
            "unexpected </" + n + "> inside <" + parent + ">",
          ))
        }
      Text(_) | Comment(_) => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1 // ignore inter-element text
      }
      TagEnd | EmptyTagEnd | AttributeName(_) | AttributeValue(_) => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        // Stray structural token; skip defensively.
        st.pos = st.pos + 1
      }
    }
  }
  Err(svg_error("svg-scene", "missing </" + parent + ">"))
}

// Build one element subtree whose start tag is at st.pos. Returns:
//   Ok(Some(node))  — a known §6.1 element was built
//   Ok(None)        — the element was unknown/deferred; its subtree was skipped
// `ctx` is the inherited paint context.
fn build_element(
  st : TokenCursor,
  name : String,
  ctx : PaintContext,
  budget : @budget.Budget,
) -> Result[SceneNode?, @error.CoreError] {
  if name == "g" {
    match build_group(st, ctx, budget) {
      Ok(node) => return Ok(Some(node))
      Err(e) => return Err(e)
    }
  }
  if name == "svg" {
    // Nested <svg> (SVG allows it). Build as Svg child.
    match build_svg_root(st, ctx, budget) {
      Ok(node) => return Ok(Some(node))
      Err(e) => return Err(e)
    }
  }
  // Leaf shapes: read start tag + attrs + terminator, then materialize. Leaf
  // elements have no children, so for a non-self-closing form like
  // `<rect></rect>` we still need to consume the matching `</name>` end tag;
  // for a self-closing `<rect/>` there is nothing more to consume.
  match charge_token(budget) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  st.pos = st.pos + 1 // consume StartTag
  let (attrs, is_empty) = match build_attrs(st, budget) {
    Ok(a) => a
    Err(e) => return Err(e)
  }
  let node = match name {
    "rect" =>
      match build_rect(attrs, ctx) {
        Ok(node) => node
        Err(error) => return Err(error)
      }
    "circle" =>
      match build_circle(attrs, ctx) {
        Ok(node) => node
        Err(error) => return Err(error)
      }
    "ellipse" =>
      match build_ellipse(attrs, ctx) {
        Ok(node) => node
        Err(error) => return Err(error)
      }
    "line" =>
      match build_line(attrs, ctx) {
        Ok(node) => node
        Err(error) => return Err(error)
      }
    "polyline" =>
      match build_polyline(attrs, ctx) {
        Ok(node) => node
        Err(error) => return Err(error)
      }
    "polygon" =>
      match build_polygon(attrs, ctx) {
        Ok(node) => node
        Err(error) => return Err(error)
      }
    "path" =>
      match build_path(attrs, ctx, budget) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    _ =>
      // Unknown/deferred element. build_attrs already consumed up to the
      // terminator; skip the element's body up to the matching EndTag,
      // accounting for nested same-name tags.
      return skip_element_body(st, name, budget)
  }
  if not(is_empty) {
    match consume_end_tag(st, name, budget) {
      Ok(_) => ()
      Err(e) => return Err(e)
    }
  }
  Ok(Some(node))
}

// Build a <g> group: resolve transform (default identity), merge this group's
// presentation attributes into the inherited context, and recurse with the
// merged context so children inherit the group's fill/stroke/color/etc.
fn build_group(
  st : TokenCursor,
  ctx : PaintContext,
  budget : @budget.Budget,
) -> Result[SceneNode, @error.CoreError] {
  match charge_token(budget) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  st.pos = st.pos + 1 // consume StartTag("g")
  let (attrs, is_empty) = match build_attrs(st, budget) {
    Ok(a) => a
    Err(e) => return Err(e)
  }
  let transform = match attr_get(attrs, "transform") {
    None => @math.Affine2::identity()
    Some(s) =>
      match parse_transform(s) {
        Ok(m) => m
        Err(e) => return Err(e)
      }
  }
  // Group `opacity` (the `opacity` attribute) is NOT inherited and defaults to 1.0.
  let group_opacity = match attr_double(attrs, "opacity", 1.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (_, child_ctx) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if is_empty {
    return Ok(SceneNode::Group(transform, group_opacity, []))
  }
  // Enter a depth lease for the group's children; this is the nesting-depth
  // bound (RFC §8). The scope MUST be left on every return path below.
  let scope = match budget.enter_depth() {
    Ok(s) => s
    Err(_) => return Err(svg_error("svg-budget", "nesting depth exceeded"))
  }
  let child_budget = scope.budget()
  let result = build_children(st, "g", child_ctx, child_budget)
  scope.leave()
  match result {
    Ok(children) => Ok(SceneNode::Group(transform, group_opacity, children))
    Err(e) => Err(e)
  }
}

// Consume a matching `</name>` end tag (and its trailing TagEnd) for a leaf
// element whose start tag was non-self-closing, e.g. `<rect ...></rect>`.
// Returns Ok(()) on match, Err if the next end tag is not `</name>`.
fn consume_end_tag(
  st : TokenCursor,
  name : String,
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  if st.pos >= st.len {
    return Err(svg_error("svg-scene", "missing </" + name + ">"))
  }
  match st.tokens[st.pos] {
    EndTag(n) =>
      if n == name {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
        if st.pos < st.len {
          match st.tokens[st.pos] {
            TagEnd => {
              match charge_token(budget) {
                Ok(_) => ()
                Err(e) => return Err(e)
              }
              st.pos = st.pos + 1
            }
            _ => ()
          }
        }
        Ok(())
      } else {
        Err(svg_error("svg-scene", "expected </" + name + ">, got </" + n + ">"))
      }
    _ => Err(svg_error("svg-scene", "expected </" + name + "> end tag"))
  }
}

// Skip the body of an unknown element named `name`. Assumes the start tag and
// its terminator have already been consumed. Consumes up to and including the
// matching </name>. Returns Ok(None) so the caller records no child. Each
// consumed token is charged, bounding the skipped subtree's size.
fn skip_element_body(
  st : TokenCursor,
  name : String,
  budget : @budget.Budget,
) -> Result[SceneNode?, @error.CoreError] {
  let mut depth = 1
  while st.pos < st.len {
    match st.tokens[st.pos] {
      StartTag(n) => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        if n == name {
          depth = depth + 1
        }
        st.pos = st.pos + 1
      }
      EndTag(n) => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
        // consume trailing TagEnd if present
        if st.pos < st.len {
          match st.tokens[st.pos] {
            TagEnd => {
              match charge_token(budget) {
                Ok(_) => ()
                Err(e) => return Err(e)
              }
              st.pos = st.pos + 1
            }
            _ => ()
          }
        }
        if n == name {
          depth = depth - 1
          if depth == 0 {
            return Ok(None)
          }
        }
      }
      _ => {
        match charge_token(budget) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
        st.pos = st.pos + 1
      }
    }
  }
  Err(svg_error("svg-scene", "missing </" + name + "> while skipping"))
}

// ---------------------------------------------------------------------------
// SvgRoot / Paint / shape builders
// ---------------------------------------------------------------------------

fn build_svg_root_attrs(
  attrs : Array[(String, String)],
) -> Result[SvgRoot, @error.CoreError] {
  let width = match attr_get(attrs, "width") {
    None => None
    Some(s) =>
      match parse_length(s) {
        Ok(v) => Some(v)
        Err(error) => return Err(error)
      }
  }
  let height = match attr_get(attrs, "height") {
    None => None
    Some(s) =>
      match parse_length(s) {
        Ok(v) => Some(v)
        Err(error) => return Err(error)
      }
  }
  let view_box = match attr_get(attrs, "viewBox") {
    None => None
    Some(s) =>
      match parse_viewbox(s) {
        Ok(vb) => Some(vb)
        Err(error) => return Err(error)
      }
  }
  let preserve_aspect_ratio = match attr_get(attrs, "preserveAspectRatio") {
    None => default_preserve_aspect_ratio()
    Some(s) => parse_preserve_aspect_ratio(s)
  }
  Ok({
    width: width,
    height: height,
    view_box: view_box,
    preserve_aspect_ratio: preserve_aspect_ratio,
  })
}

// Default preserveAspectRatio per SVG 1.1: "xMidYMid meet".
fn default_preserve_aspect_ratio() -> PreserveAspectRatio {
  { align_x: 1, align_y: 1, meet: true, none: false }
}

// Parse a preserveAspectRatio attribute. Accepts "<align> [meet|slice]" where
// align is one of xMinYMin/xMidYMin/.../xMaxYMax/none. Unknown tokens fall
// back to the SVG default (xMidYMid meet); "none" disables uniform scaling.
fn parse_preserve_aspect_ratio(s : String) -> PreserveAspectRatio {
  let parts = @text.split_whitespace(s)
  let mut par = default_preserve_aspect_ratio()
  for p in parts {
    let token = p.to_string()
    match token {
      "xMinYMin" => { par = { ..par, align_x: 0, align_y: 0, none: false } }
      "xMidYMin" => { par = { ..par, align_x: 1, align_y: 0, none: false } }
      "xMaxYMin" => { par = { ..par, align_x: 2, align_y: 0, none: false } }
      "xMinYMid" => { par = { ..par, align_x: 0, align_y: 1, none: false } }
      "xMidYMid" => { par = { ..par, align_x: 1, align_y: 1, none: false } }
      "xMaxYMid" => { par = { ..par, align_x: 2, align_y: 1, none: false } }
      "xMinYMax" => { par = { ..par, align_x: 0, align_y: 2, none: false } }
      "xMidYMax" => { par = { ..par, align_x: 1, align_y: 2, none: false } }
      "xMaxYMax" => { par = { ..par, align_x: 2, align_y: 2, none: false } }
      "none" => { par = { ..par, none: true } }
      "meet" => { par = { ..par, meet: true } }
      "slice" => { par = { ..par, meet: false } }
      _ => () // unknown token ignored, keep current
    }
  }
  par
}

// Build a Paint and the child PaintContext from this element's attributes
// plus the inherited parent context. For each inherited attribute: if this
// element sets it, parse and use it (currentColor resolves against the
// inherited color); otherwise inherit the parent's resolved value. On color
// parse failure, nonnumeric color forms retain v0.1 fallbacks (fill→black,
// stroke→none); numeric source failures are propagated.
// Returns the fully-resolved Paint (for the leaf) and the context to thread
// into this element's children.
fn build_paint(
  attrs : Array[(String, String)],
  parent : PaintContext,
) -> Result[(Paint, PaintContext), @error.CoreError] {
  // currentColor source: the `color` attribute, inherited (default black).
  let color = match attr_get(attrs, "color") {
    None => parent.color
    Some(s) =>
      if is_none_color(s) {
        parent.color // "none" is not valid for color; keep inherited.
      } else {
        match parse_color(s, Some(parent.color)) {
          Ok(c) => c
          Err(error) =>
            if is_svg_numeric_error(error) {
              return Err(error)
            } else {
              parent.color
            }
        }
      }
  }
  // fill: explicit (incl. none) else inherit.
  let fill = match attr_get(attrs, "fill") {
    None => parent.fill
    Some(s) =>
      if is_none_color(s) {
        None
      } else {
        match parse_color(s, Some(color)) {
          Ok(c) => Some(c)
          Err(error) =>
            if is_svg_numeric_error(error) {
              return Err(error)
            } else {
              Some((0.0, 0.0, 0.0))
            }
        }
      }
  }
  let stroke = match attr_get(attrs, "stroke") {
    None => parent.stroke
    Some(s) =>
      if is_none_color(s) {
        None
      } else {
        match parse_color(s, Some(color)) {
          Ok(c) => Some(c)
          Err(error) =>
            if is_svg_numeric_error(error) {
              return Err(error)
            } else {
              None
            }
        }
      }
  }
  let fill_opacity = match inherit_double(attrs, "fill-opacity", parent.fill_opacity) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let stroke_opacity = match inherit_double(
    attrs,
    "stroke-opacity",
    parent.stroke_opacity,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let stroke_width = match inherit_double(attrs, "stroke-width", parent.stroke_width) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let fill_rule = match attr_get(attrs, "fill-rule") {
    None => parent.fill_rule
    Some(s) => parse_fillrule(s)
  }
  let stroke_cap = match attr_get(attrs, "stroke-linecap") {
    None => parent.stroke_cap
    Some(s) => parse_linecap(s)
  }
  let stroke_join = match attr_get(attrs, "stroke-linejoin") {
    None => parent.stroke_join
    Some(s) => parse_linejoin(s)
  }
  let stroke_miterlimit = match inherit_double(
    attrs,
    "stroke-miterlimit",
    parent.stroke_miterlimit,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let stroke_dash = match attr_get(attrs, "stroke-dasharray") {
    None => parent.stroke_dash
    Some(s) =>
      if is_none_color(s) {
        [] // "none" dasharray = solid.
      } else {
        match parse_number_list(s) {
          Ok(nums) => nums
          Err(error) => return Err(error)
        }
      }
  }
  let stroke_dashoffset = match inherit_double(
    attrs,
    "stroke-dashoffset",
    parent.stroke_dashoffset,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  // Element `opacity` is NOT inherited (per SVG spec); default 1.0.
  let opacity = match attr_double(attrs, "opacity", 1.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let paint = {
    fill: fill,
    stroke: stroke,
    fill_opacity: fill_opacity,
    stroke_opacity: stroke_opacity,
    stroke_width: stroke_width,
    fill_rule: fill_rule,
    stroke_cap: stroke_cap,
    stroke_join: stroke_join,
    stroke_miterlimit: stroke_miterlimit,
    stroke_dash: stroke_dash,
    stroke_dashoffset: stroke_dashoffset,
    opacity: opacity,
  }
  let ctx = {
    color: color,
    fill: fill,
    stroke: stroke,
    fill_opacity: fill_opacity,
    stroke_opacity: stroke_opacity,
    stroke_width: stroke_width,
    fill_rule: fill_rule,
    stroke_cap: stroke_cap,
    stroke_join: stroke_join,
    stroke_miterlimit: stroke_miterlimit,
    stroke_dash: stroke_dash,
    stroke_dashoffset: stroke_dashoffset,
  }
  Ok((paint, ctx))
}

// Numeric attribute: parse if present, else inherit parent value. (No SVG
// default fallback here — the context already carries the resolved value.)
fn inherit_double(
  attrs : Array[(String, String)],
  name : String,
  parent : Double,
) -> Result[Double, @error.CoreError] {
  match attr_get(attrs, name) {
    None => Ok(parent)
    Some(s) => parse_length(s)
  }
}

fn is_svg_numeric_error(error : @error.CoreError) -> Bool {
  match error.context() {
    Some("svg-numeric-source") | Some("svg-numeric-nonfinite") | Some("svg-numeric-range") => true
    _ => false
  }
}

// Parse an SVG stroke-linecap value; unknown values fall back to the SVG
// default (Butt).
fn parse_linecap(s : String) -> @canvas.LineCap {
  match @text.trim(s) {
    "butt" => @canvas.LineCap::Butt
    "round" => @canvas.LineCap::Round
    "square" => @canvas.LineCap::Square
    _ => @canvas.LineCap::Butt
  }
}

// Parse an SVG stroke-linejoin value; unknown values fall back to the SVG
// default (Miter).
fn parse_linejoin(s : String) -> @canvas.LineJoin {
  match @text.trim(s) {
    "miter" => @canvas.LineJoin::Miter
    "round" => @canvas.LineJoin::Round
    "bevel" => @canvas.LineJoin::Bevel
    _ => @canvas.LineJoin::Miter
  }
}

// Parse an SVG fill-rule value; unknown values fall back to the SVG default
// (Nonzero). SVG accepts "nonzero"/"evenodd" (and SVG 2 "nozero" alias is not
// handled here).
fn parse_fillrule(s : String) -> @canvas.FillRule {
  match @text.trim(s) {
    "evenodd" => @canvas.FillRule::EvenOdd
    _ => @canvas.FillRule::Nonzero
  }
}

fn build_rect(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> Result[SceneNode, @error.CoreError] {
  let x = match attr_double(attrs, "x", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y = match attr_double(attrs, "y", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let w = match attr_double(attrs, "width", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let h = match attr_double(attrs, "height", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rx = match attr_double(attrs, "rx", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ry = match attr_double(attrs, "ry", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (paint, _) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(SceneNode::Rect(paint, x, y, w, h, rx, ry))
}

fn build_circle(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> Result[SceneNode, @error.CoreError] {
  let cx = match attr_double(attrs, "cx", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let cy = match attr_double(attrs, "cy", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let r = match attr_double(attrs, "r", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (paint, _) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(SceneNode::Circle(paint, cx, cy, r))
}

fn build_ellipse(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> Result[SceneNode, @error.CoreError] {
  let cx = match attr_double(attrs, "cx", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let cy = match attr_double(attrs, "cy", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let rx = match attr_double(attrs, "rx", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let ry = match attr_double(attrs, "ry", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (paint, _) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(SceneNode::Ellipse(paint, cx, cy, rx, ry))
}

fn build_line(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> Result[SceneNode, @error.CoreError] {
  let x1 = match attr_double(attrs, "x1", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y1 = match attr_double(attrs, "y1", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let x2 = match attr_double(attrs, "x2", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let y2 = match attr_double(attrs, "y2", 0.0) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (paint, _) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(SceneNode::Line(paint, x1, y1, x2, y2))
}

fn build_polyline(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> Result[SceneNode, @error.CoreError] {
  let (paint, _) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let points = match points_from_attrs(attrs) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(SceneNode::Polyline(paint, points))
}

fn build_polygon(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> Result[SceneNode, @error.CoreError] {
  let (paint, _) = match build_paint(attrs, ctx) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let points = match points_from_attrs(attrs) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(SceneNode::Polygon(paint, points))
}

// Parse polyline/polygon points into Point2 pairs.
fn points_from_attrs(
  attrs : Array[(String, String)],
) -> Result[Array[@math.Point2], @error.CoreError] {
  match attr_get(attrs, "points") {
    None => Ok([])
    Some(s) =>
      match parse_number_list(s) {
        Err(error) => Err(error)
        Ok(nums) => Ok(pair_points(nums))
      }
  }
}

fn pair_points(nums : Array[Double]) -> Array[@math.Point2] {
  let pts : Array[@math.Point2] = []
  let n = nums.length()
  let mut i = 0
  while i + 1 < n {
    pts.push(@math.Point2::new(nums[i], nums[i + 1]))
    i = i + 2
  }
  pts
}

fn build_path(
  attrs : Array[(String, String)],
  ctx : PaintContext,
  budget : @budget.Budget,
) -> Result[SceneNode, @error.CoreError] {
  match attr_get(attrs, "d") {
    None => Err(svg_error("svg-scene", "<path> missing required 'd' attribute"))
    Some(d) =>
      match parse_path_data_with_budget(d, budget) {
        Ok(p) =>
          match build_paint(attrs, ctx) {
            Ok((paint, _)) => Ok(SceneNode::Path(paint, p))
            Err(error) => Err(error)
          }
        Err(e) => Err(e)
      }
  }
}

// ---------------------------------------------------------------------------
// Attribute helpers
// ---------------------------------------------------------------------------

// First value for a given attribute name, or None.
fn attr_get(attrs : Array[(String, String)], name : String) -> String? {
  for i = 0; i < attrs.length(); i = i + 1 {
    let (k, v) = attrs[i]
    if k == name {
      return Some(v)
    }
  }
  None
}

// Numeric attribute value, or `default` only when the attribute is absent.
fn attr_double(
  attrs : Array[(String, String)],
  name : String,
  default : Double,
) -> Result[Double, @error.CoreError] {
  match attr_get(attrs, name) {
    None => Ok(default)
    Some(s) => parse_length(s)
  }
}
