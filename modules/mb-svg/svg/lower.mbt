// SceneTree → mb-canvas DrawingList lowering.
//
// Walks a SceneNode tree and emits DrawOps onto an mb-canvas DrawingList:
//   - Svg       → emit children (viewport/aspectRatio mapping is a follow-up)
//   - Group     → PushTransform(child-transform) ... children ... PopTransform
//   - shapes    → Fill and/or Stroke of the resolved Path2, applying Paint
//
// Geometry is lowered into a fresh mb-core Path2 per shape, so
// rect/circle/ellipse/polyline/polygon all become the same Path2 + PathCommand
// representation that <path> already produces (which reuses CanvasPath.to_path2).
// The DrawingList records pure data; rasterization (color resolution, scan
// conversion) is mb-canvas's job.
//
// Known v0.1 limitations (flagged inline, deferred per RFC 0002 §6.2):
//   - viewBox → viewport scale/translate mapping is not applied (identity).
//   - preserveAspectRatio is ignored.
//   - StrokeStyle cap/join/miter/dash use canvas defaults (no SVG attr wiring).
//   - fill-rule / clip-rule attributes are not read; fills default to Nonzero.
//   - rx/ry rounded corners on <rect> are ignored (treated as sharp).
//
// fill-opacity/stroke-opacity ARE applied (via FillStyle::with_alpha, which
// mb-canvas now exposes). group/element `opacity` (separate from paint
// opacity) is a follow-up.

///|
/// Lower a scene tree into a drawing list. Returns a fresh DrawingList with
/// fill/stroke/transform operations recorded in document order.
pub fn lower_to_drawing_list(root : SceneNode) -> @canvas.DrawingList {
  let list = @canvas.DrawingList::new()
  lower_node(root, list)
  list
}

// Recursively lower one node, appending its ops to `list`.
fn lower_node(node : SceneNode, list : @canvas.DrawingList) -> Unit {
  match node {
    Svg(_, children) => {
      // v0.1: no viewport mapping. viewBox scale/translate and
      // preserveAspectRatio are follow-ups.
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], list)
      }
    }
    Group(transform, children) => {
      list.push_transform(transform)
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], list)
      }
      list.pop_transform()
    }
    Rect(paint, x, y, w, h, _rx, _ry) =>
      // rx/ry rounded corners are ignored in v0.1 (sharp rectangle).
      emit_shape(paint, rect_path(x, y, w, h), list)
    Circle(paint, cx, cy, r) =>
      emit_shape(paint, circle_path(cx, cy, r), list)
    Ellipse(paint, cx, cy, rx, ry) =>
      emit_shape(paint, ellipse_path(cx, cy, rx, ry), list)
    Line(paint, x1, y1, x2, y2) =>
      emit_shape(paint, line_path(x1, y1, x2, y2), list)
    Polyline(paint, pts) => emit_shape(paint, polyline_path(pts), list)
    Polygon(paint, pts) => emit_shape(paint, polygon_path(pts), list)
    Path(paint, cp) => emit_shape(paint, cp.to_path2(), list)
  }
}

// Emit fill and (if any) stroke ops for a shape. Applies to both closed
// shapes (rect/circle/ellipse/polygon/path) and open ones (polyline): SVG
// permits filling open paths, so the same emission is used for both.
fn emit_shape(
  paint : Paint,
  path : @math.Path2,
  list : @canvas.DrawingList,
) -> Unit {
  match paint.fill {
    Some((r, g, b)) =>
      list.push_fill(path, make_fill_style(r, g, b, paint.fill_opacity))
    None => ()
  }
  match paint.stroke {
    Some((r, g, b)) => {
      let stroke = @canvas.StrokeStyle::new(paint.stroke_width)
      let color = make_fill_style(r, g, b, paint.stroke_opacity)
      list.push_stroke(path, stroke, color)
    }
    None => ()
  }
}

// ---------------------------------------------------------------------------
// Style helpers
// ---------------------------------------------------------------------------

// Build a FillStyle from normalized sRGB components + straight alpha. Alpha
// comes from the resolved fill-opacity/stroke-opacity (default 1.0) and is
// applied via mb-canvas's with_alpha (clamped to [0,1] there). The Nonzero
// winding rule is the SVG default; EvenOdd is a follow-up via fill-rule.
fn make_fill_style(
  r : Double,
  g : Double,
  b : Double,
  alpha : Double,
) -> @canvas.FillStyle {
  @canvas.FillStyle::new(r, g, b).with_alpha(alpha)
}

// ---------------------------------------------------------------------------
// Shape → Path2 geometry
// ---------------------------------------------------------------------------

// Closed rectangle as a subpath (matches CanvasPath::rect semantics).
fn rect_path(x : Double, y : Double, w : Double, h : Double) -> @math.Path2 {
  let p = @math.Path2::new()
  p.push(@math.PathCommand::MoveTo(@math.Point2::new(x, y)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x + w, y)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x + w, y + h)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x, y + h)))
  p.push(@math.PathCommand::Close)
  p
}

// Circle approximated as a closed polygon. The segment count gives sub-pixel
// accuracy for typical radii; a precise tessellation is a follow-up. 32
// segments is a fixed v0.1 default (no quality knob yet).
fn circle_path(cx : Double, cy : Double, r : Double) -> @math.Path2 {
  polygon_ellipse_path(cx, cy, r, r, 32)
}

// Ellipse approximated as a closed polygon with 32 segments per axis-mapped
// circle.
fn ellipse_path(cx : Double, cy : Double, rx : Double, ry : Double) -> @math.Path2 {
  polygon_ellipse_path(cx, cy, rx, ry, 32)
}

// Shared polygonal approximation for circle/ellipse: sample `segs` points
// around the ellipse and close.
fn polygon_ellipse_path(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  segs : Int,
) -> @math.Path2 {
  let p = @math.Path2::new()
  let two_pi = 6.283185307179586
  let step = two_pi / segs.to_double()
  for i = 0; i < segs; i = i + 1 {
    let a = step * i.to_double()
    let x = cx + rx * @math.cos(a)
    let y = cy + ry * @math.sin(a)
    let cmd = if i == 0 {
      @math.PathCommand::MoveTo(@math.Point2::new(x, y))
    } else {
      @math.PathCommand::LineTo(@math.Point2::new(x, y))
    }
    p.push(cmd)
  }
  p.push(@math.PathCommand::Close)
  p
}

// A line is a single open subpath: move to one endpoint, line to the other.
fn line_path(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> @math.Path2 {
  let p = @math.Path2::new()
  p.push(@math.PathCommand::MoveTo(@math.Point2::new(x1, y1)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x2, y2)))
  p
}

// Polyline: open chain through the points.
fn polyline_path(pts : Array[@math.Point2]) -> @math.Path2 {
  let p = @math.Path2::new()
  for i = 0; i < pts.length(); i = i + 1 {
    let cmd = if i == 0 {
      @math.PathCommand::MoveTo(pts[i])
    } else {
      @math.PathCommand::LineTo(pts[i])
    }
    p.push(cmd)
  }
  p
}

// Polygon: closed chain through the points.
fn polygon_path(pts : Array[@math.Point2]) -> @math.Path2 {
  let p = polyline_path(pts)
  p.push(@math.PathCommand::Close)
  p
}
