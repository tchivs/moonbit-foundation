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
//   - preserveAspectRatio is stored raw; viewport mapping belongs to lowering.
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
  stroke_cap : @canvas.LineCap
  stroke_join : @canvas.LineJoin
  stroke_miterlimit : Double
  stroke_dash : Array[Double]
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
    stroke_cap: @canvas.LineCap::Butt,
    stroke_join: @canvas.LineJoin::Miter,
    stroke_miterlimit: 4.0,
    stroke_dash: [],
  }
}

///|
/// A node in the SVG scene tree. Structure nodes carry resolved transform and
/// children; leaf shapes carry resolved geometry and paint.
pub enum SceneNode {
  Svg(SvgRoot, Array[SceneNode])
  Group(@math.Affine2, Array[SceneNode])
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
/// not <svg>, or a required attribute (e.g. <path d>) is missing.
///
/// Leading trivia (whitespace Text, Comment) before the root <svg> is
/// skipped. Trailing content after the root close is ignored.
pub fn parse_svg(source : String) -> Result[SceneNode, @error.CoreError] {
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
  skip_leading_trivia(st)
  if st.pos >= st.len {
    return Err(svg_error("svg-scene", "no root <svg> element"))
  }
  match st.tokens[st.pos] {
    StartTag(name) =>
      if name == "svg" {
        match build_svg_root(st, root_paint_context()) {
          Ok(node) => {
            ignore_trailing(st)
            Ok(node)
          }
          Err(e) => Err(e)
        }
      } else {
        Err(svg_error("svg-scene", "root element is not <svg>: " + name))
      }
    _ => Err(svg_error("svg-scene", "expected <svg> start tag"))
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

fn skip_leading_trivia(st : TokenCursor) -> Unit {
  while st.pos < st.len {
    match st.tokens[st.pos] {
      Text(_) | Comment(_) => st.pos = st.pos + 1
      _ => break
    }
  }
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
) -> Result[SceneNode, @error.CoreError] {
  // st.pos is at StartTag("svg").
  st.pos = st.pos + 1
  let (attrs, is_empty) = match build_attrs(st) {
    Ok(a) => a
    Err(e) => return Err(e)
  }
  let root = build_svg_root_attrs(attrs)
  let (_, child_ctx) = build_paint(attrs, ctx)
  if is_empty {
    return Ok(SceneNode::Svg(root, []))
  }
  match build_children(st, "svg", child_ctx) {
    Ok(children) => Ok(SceneNode::Svg(root, children))
    Err(e) => Err(e)
  }
}

// Read the attribute pairs of a start tag, then consume the tag terminator.
// Returns the (name, value) list and whether the tag was self-closing
// (EmptyTagEnd `/>`); a `>` terminator yields is_empty = false.
fn build_attrs(
  st : TokenCursor,
) -> Result[(Array[(String, String)], Bool), @error.CoreError] {
  let attrs : Array[(String, String)] = []
  while st.pos < st.len {
    match st.tokens[st.pos] {
      AttributeName(name) => {
        st.pos = st.pos + 1
        if st.pos >= st.len {
          return Err(svg_error("svg-scene", "attribute '" + name + "' has no value"))
        }
        match st.tokens[st.pos] {
          AttributeValue(v) => {
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
        st.pos = st.pos + 1
        return Ok((attrs, false))
      }
      EmptyTagEnd => {
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
// `ctx` is the inherited paint context for the children.
fn build_children(
  st : TokenCursor,
  parent : String,
  ctx : PaintContext,
) -> Result[Array[SceneNode], @error.CoreError] {
  let children : Array[SceneNode] = []
  while st.pos < st.len {
    match st.tokens[st.pos] {
      StartTag(name) =>
        match build_element(st, name, ctx) {
          Ok(Some(node)) => children.push(node)
          Ok(None) => () // skipped subtree (unknown/deferred element)
          Err(e) => return Err(e)
        }
      EndTag(n) =>
        if n == parent {
          // Consume EndTag + its TagEnd.
          st.pos = st.pos + 1
          if st.pos < st.len {
            match st.tokens[st.pos] {
              TagEnd => st.pos = st.pos + 1
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
      Text(_) | Comment(_) => st.pos = st.pos + 1 // ignore inter-element text
      TagEnd | EmptyTagEnd | AttributeName(_) | AttributeValue(_) =>
        // Stray structural token; skip defensively.
        st.pos = st.pos + 1
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
) -> Result[SceneNode?, @error.CoreError] {
  if name == "g" {
    match build_group(st, ctx) {
      Ok(node) => return Ok(Some(node))
      Err(e) => return Err(e)
    }
  }
  if name == "svg" {
    // Nested <svg> (SVG allows it). Build as Svg child.
    match build_svg_root(st, ctx) {
      Ok(node) => return Ok(Some(node))
      Err(e) => return Err(e)
    }
  }
  // Leaf shapes: read start tag + attrs + terminator, then materialize. Leaf
  // elements have no children, so for a non-self-closing form like
  // `<rect></rect>` we still need to consume the matching `</name>` end tag;
  // for a self-closing `<rect/>` there is nothing more to consume.
  st.pos = st.pos + 1 // consume StartTag
  let (attrs, is_empty) = match build_attrs(st) {
    Ok(a) => a
    Err(e) => return Err(e)
  }
  let node = match name {
    "rect" => build_rect(attrs, ctx)
    "circle" => build_circle(attrs, ctx)
    "ellipse" => build_ellipse(attrs, ctx)
    "line" => build_line(attrs, ctx)
    "polyline" => build_polyline(attrs, ctx)
    "polygon" => build_polygon(attrs, ctx)
    "path" =>
      match build_path(attrs, ctx) {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    _ =>
      // Unknown/deferred element. build_attrs already consumed up to the
      // terminator; skip the element's body up to the matching EndTag,
      // accounting for nested same-name tags.
      return skip_element_body(st, name)
  }
  if not(is_empty) {
    match consume_end_tag(st, name) {
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
) -> Result[SceneNode, @error.CoreError] {
  st.pos = st.pos + 1 // consume StartTag("g")
  let (attrs, is_empty) = match build_attrs(st) {
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
  let (_, child_ctx) = build_paint(attrs, ctx)
  if is_empty {
    return Ok(SceneNode::Group(transform, []))
  }
  match build_children(st, "g", child_ctx) {
    Ok(children) => Ok(SceneNode::Group(transform, children))
    Err(e) => Err(e)
  }
}

// Consume a matching `</name>` end tag (and its trailing TagEnd) for a leaf
// element whose start tag was non-self-closing, e.g. `<rect ...></rect>`.
// Returns Ok(()) on match, Err if the next end tag is not `</name>`.
fn consume_end_tag(st : TokenCursor, name : String) -> Result[Unit, @error.CoreError] {
  if st.pos >= st.len {
    return Err(svg_error("svg-scene", "missing </" + name + ">"))
  }
  match st.tokens[st.pos] {
    EndTag(n) =>
      if n == name {
        st.pos = st.pos + 1
        if st.pos < st.len {
          match st.tokens[st.pos] {
            TagEnd => st.pos = st.pos + 1
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
// matching </name>. Returns Ok(None) so the caller records no child.
fn skip_element_body(
  st : TokenCursor,
  name : String,
) -> Result[SceneNode?, @error.CoreError] {
  let mut depth = 1
  while st.pos < st.len {
    match st.tokens[st.pos] {
      StartTag(n) => {
        if n == name {
          depth = depth + 1
        }
        st.pos = st.pos + 1
      }
      EndTag(n) => {
        st.pos = st.pos + 1
        // consume trailing TagEnd if present
        if st.pos < st.len {
          match st.tokens[st.pos] {
            TagEnd => st.pos = st.pos + 1
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
      _ => st.pos = st.pos + 1
    }
  }
  Err(svg_error("svg-scene", "missing </" + name + "> while skipping"))
}

// ---------------------------------------------------------------------------
// SvgRoot / Paint / shape builders
// ---------------------------------------------------------------------------

fn build_svg_root_attrs(attrs : Array[(String, String)]) -> SvgRoot {
  let width = match attr_get(attrs, "width") {
    None => None
    Some(s) =>
      match parse_length(s) {
        Ok(v) => Some(v)
        Err(_) => None
      }
  }
  let height = match attr_get(attrs, "height") {
    None => None
    Some(s) =>
      match parse_length(s) {
        Ok(v) => Some(v)
        Err(_) => None
      }
  }
  let view_box = match attr_get(attrs, "viewBox") {
    None => None
    Some(s) =>
      match parse_viewbox(s) {
        Ok(vb) => Some(vb)
        Err(_) => None
      }
  }
  { width: width, height: height, view_box: view_box }
}

// Build a Paint and the child PaintContext from this element's attributes
// plus the inherited parent context. For each inherited attribute: if this
// element sets it, parse and use it (currentColor resolves against the
// inherited color); otherwise inherit the parent's resolved value. On color
// parse failure, falls back leniently (fill→black, stroke→none) as in v0.1.
// Returns the fully-resolved Paint (for the leaf) and the context to thread
// into this element's children.
fn build_paint(
  attrs : Array[(String, String)],
  parent : PaintContext,
) -> (Paint, PaintContext) {
  // currentColor source: the `color` attribute, inherited (default black).
  let color = match attr_get(attrs, "color") {
    None => parent.color
    Some(s) =>
      if is_none_color(s) {
        parent.color // "none" is not valid for color; keep inherited.
      } else {
        match parse_color(s, Some(parent.color)) {
          Ok(c) => c
          Err(_) => parent.color
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
          Err(_) => Some((0.0, 0.0, 0.0))
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
          Err(_) => None
        }
      }
  }
  let fill_opacity = inherit_double(attrs, "fill-opacity", parent.fill_opacity)
  let stroke_opacity = inherit_double(
    attrs,
    "stroke-opacity",
    parent.stroke_opacity,
  )
  let stroke_width = inherit_double(attrs, "stroke-width", parent.stroke_width)
  let stroke_cap = match attr_get(attrs, "stroke-linecap") {
    None => parent.stroke_cap
    Some(s) => parse_linecap(s)
  }
  let stroke_join = match attr_get(attrs, "stroke-linejoin") {
    None => parent.stroke_join
    Some(s) => parse_linejoin(s)
  }
  let stroke_miterlimit = inherit_double(
    attrs,
    "stroke-miterlimit",
    parent.stroke_miterlimit,
  )
  let stroke_dash = match attr_get(attrs, "stroke-dasharray") {
    None => parent.stroke_dash
    Some(s) =>
      if is_none_color(s) {
        [] // "none" dasharray = solid.
      } else {
        match parse_number_list(s) {
          Ok(nums) => nums
          Err(_) => parent.stroke_dash
        }
      }
  }
  let paint = {
    fill: fill,
    stroke: stroke,
    fill_opacity: fill_opacity,
    stroke_opacity: stroke_opacity,
    stroke_width: stroke_width,
    stroke_cap: stroke_cap,
    stroke_join: stroke_join,
    stroke_miterlimit: stroke_miterlimit,
    stroke_dash: stroke_dash,
  }
  let ctx = {
    color: color,
    fill: fill,
    stroke: stroke,
    fill_opacity: fill_opacity,
    stroke_opacity: stroke_opacity,
    stroke_width: stroke_width,
    stroke_cap: stroke_cap,
    stroke_join: stroke_join,
    stroke_miterlimit: stroke_miterlimit,
    stroke_dash: stroke_dash,
  }
  (paint, ctx)
}

// Numeric attribute: parse if present, else inherit parent value. (No SVG
// default fallback here — the context already carries the resolved value.)
fn inherit_double(
  attrs : Array[(String, String)],
  name : String,
  parent : Double,
) -> Double {
  match attr_get(attrs, name) {
    None => parent
    Some(s) =>
      match parse_length(s) {
        Ok(v) => v
        Err(_) => parent
      }
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

fn build_rect(attrs : Array[(String, String)], ctx : PaintContext) -> SceneNode {
  let x = attr_double(attrs, "x", 0.0)
  let y = attr_double(attrs, "y", 0.0)
  let w = attr_double(attrs, "width", 0.0)
  let h = attr_double(attrs, "height", 0.0)
  let rx = attr_double(attrs, "rx", 0.0)
  let ry = attr_double(attrs, "ry", 0.0)
  let (paint, _) = build_paint(attrs, ctx)
  SceneNode::Rect(paint, x, y, w, h, rx, ry)
}

fn build_circle(attrs : Array[(String, String)], ctx : PaintContext) -> SceneNode {
  let cx = attr_double(attrs, "cx", 0.0)
  let cy = attr_double(attrs, "cy", 0.0)
  let r = attr_double(attrs, "r", 0.0)
  let (paint, _) = build_paint(attrs, ctx)
  SceneNode::Circle(paint, cx, cy, r)
}

fn build_ellipse(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> SceneNode {
  let cx = attr_double(attrs, "cx", 0.0)
  let cy = attr_double(attrs, "cy", 0.0)
  let rx = attr_double(attrs, "rx", 0.0)
  let ry = attr_double(attrs, "ry", 0.0)
  let (paint, _) = build_paint(attrs, ctx)
  SceneNode::Ellipse(paint, cx, cy, rx, ry)
}

fn build_line(attrs : Array[(String, String)], ctx : PaintContext) -> SceneNode {
  let x1 = attr_double(attrs, "x1", 0.0)
  let y1 = attr_double(attrs, "y1", 0.0)
  let x2 = attr_double(attrs, "x2", 0.0)
  let y2 = attr_double(attrs, "y2", 0.0)
  let (paint, _) = build_paint(attrs, ctx)
  SceneNode::Line(paint, x1, y1, x2, y2)
}

fn build_polyline(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> SceneNode {
  let (paint, _) = build_paint(attrs, ctx)
  SceneNode::Polyline(paint, points_from_attrs(attrs))
}

fn build_polygon(
  attrs : Array[(String, String)],
  ctx : PaintContext,
) -> SceneNode {
  let (paint, _) = build_paint(attrs, ctx)
  SceneNode::Polygon(paint, points_from_attrs(attrs))
}

// Parse polyline/polygon points into Point2 pairs.
fn points_from_attrs(attrs : Array[(String, String)]) -> Array[@math.Point2] {
  match attr_get(attrs, "points") {
    None => []
    Some(s) =>
      match parse_number_list(s) {
        Err(_) => []
        Ok(nums) => pair_points(nums)
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
) -> Result[SceneNode, @error.CoreError] {
  match attr_get(attrs, "d") {
    None => Err(svg_error("svg-scene", "<path> missing required 'd' attribute"))
    Some(d) =>
      match parse_path_data(d) {
        Ok(p) =>
          match build_paint(attrs, ctx) {
            (paint, _) => Ok(SceneNode::Path(paint, p))
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

// Numeric attribute value, or `default` on missing/parse failure.
fn attr_double(
  attrs : Array[(String, String)],
  name : String,
  default : Double,
) -> Double {
  match attr_get(attrs, name) {
    None => default
    Some(s) =>
      match parse_length(s) {
        Ok(v) => v
        Err(_) => default
      }
  }
}
