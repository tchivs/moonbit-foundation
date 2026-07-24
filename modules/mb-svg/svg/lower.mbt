// SceneTree → mb-canvas DrawingList lowering.
//
// Walks a SceneNode tree and emits DrawOps onto an mb-canvas DrawingList:
//   - Svg       → viewBox→viewport transform (xMidYMid meet) wraps children
//   - Group     → PushTransform(child-transform) ... children ... PopTransform
//   - shapes    → Fill and/or Stroke of the resolved Path2, applying Paint
//
// Geometry is lowered into a fresh mb-core Path2 per shape, so
// rect/circle/ellipse/polyline/polygon all become the same Path2 + PathCommand
// representation that <path> already produces (which reuses CanvasPath.to_path2).
// The DrawingList records pure data; rasterization (color resolution, scan
// conversion) is mb-canvas's job.
//
// viewBox→viewport mapping uses the SVG default preserveAspectRatio
// ("xMidYMid meet"); other aspect-ratio modes and explicit preserveAspectRatio
// values are a follow-up. clip-rule is not yet handled (follow-up).
//
// stroke-width/linecap/linejoin/miterlimit/dasharray ARE wired through to the
// StrokeStyle setters. stroke-dashoffset is not yet handled (follow-up).
//
// fill-opacity/stroke-opacity ARE applied (via FillStyle::with_alpha, which
// mb-canvas now exposes).
//
// DEFERRED — group/element `opacity` (the opacity attribute on <g>/<svg>):
// SVG 1.1 §14.4 requires the group to render as if opacity=1, then the whole
// group result is composited onto the backdrop at the given opacity. This
// needs an offscreen layer (begin group → rasterize children → end group →
// composite), but mb-canvas's DrawOp has no PushLayer/PopLayer (RFC 0003 §6
// delegates raster-raster compositing to mb-image/ops, and §7 scopes the
// drawing list to geometry+style+transform+clip — no layer state). A naive
// approximation (multiplying opacity into each child's paint alpha) diverges
// from the spec whenever semi-transparent shapes overlap inside the group, so
// it is rejected here rather than shipping a wrong-but-cheap version. Group
// opacity is deferred until mb-canvas gains a layer abstraction; this is a
// cross-module decision, not something mb-svg can resolve alone.

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
    Svg(root, children) => {
      // viewBox → viewport mapping (SVG default preserveAspectRatio=
      // "xMidYMid meet"). If viewBox is absent, or width/height are absent,
      // no mapping is applied (identity). meet keeps aspect ratio by using
      // the smaller scale and centers the content (xMid/YMid).
      let map = viewbox_transform(root)
      let mapped = not(map.a() == 1.0 && map.d() == 1.0 && map.tx() == 0.0 && map.ty() == 0.0)
      if mapped {
        list.push_transform(map)
      }
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], list)
      }
      if mapped {
        list.pop_transform()
      }
    }
    Group(transform, children) => {
      list.push_transform(transform)
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], list)
      }
      list.pop_transform()
    }
    Rect(paint, x, y, w, h, rx, ry) =>
      emit_shape(paint, rect_path(x, y, w, h, rx, ry), list)
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
      list.push_fill(
        path,
        make_fill_style(r, g, b, paint.fill_opacity, paint.fill_rule),
      )
    None => ()
  }
  match paint.stroke {
    Some((r, g, b)) => {
      let stroke = @canvas.StrokeStyle::new(paint.stroke_width)
        .with_cap(paint.stroke_cap)
        .with_join(paint.stroke_join)
        .with_miter_limit(paint.stroke_miterlimit)
        .with_dash(paint.stroke_dash)
      // Stroke color FillStyle: its rule is unused by the rasterizer (strokes
      // fill as even-odd outlines internally), so Nonzero is passed here.
      let color = make_fill_style(r, g, b, paint.stroke_opacity, @canvas.FillRule::Nonzero)
      list.push_stroke(path, stroke, color)
    }
    None => ()
  }
}

// ---------------------------------------------------------------------------
// Style helpers
// ---------------------------------------------------------------------------

// Build a FillStyle from normalized sRGB components + straight alpha + winding
// rule. Alpha comes from the resolved fill-opacity/stroke-opacity (default
// 1.0); rule comes from the resolved fill-rule (default Nonzero). Both applied
// via the mb-canvas value setters.
fn make_fill_style(
  r : Double,
  g : Double,
  b : Double,
  alpha : Double,
  rule : @canvas.FillRule,
) -> @canvas.FillStyle {
  @canvas.FillStyle::new(r, g, b).with_alpha(alpha).with_rule(rule)
}

// Compute the viewBox→viewport transform for an <svg> root (preserveAspectRatio
// = "xMidYMid meet", the SVG default). Returns identity when viewBox or
// width/height are absent. meet scales uniformly by min(scale_x, scale_y) so
// the whole viewBox fits inside the viewport; xMid/YMid center the result.
//   vb = (vbx, vby, vbw, vbh), vp = (vpw, vph) (viewport at origin 0,0)
//   s   = min(vpw/vbw, vph/vbh)
//   tx  = (vpw - vbw*s)/2 - vbx*s
//   ty  = (vph - vbh*s)/2 - vby*s
fn viewbox_transform(root : SvgRoot) -> @math.Affine2 {
  match (root.view_box, root.width, root.height) {
    (Some((vbx, vby, vbw, vbh)), Some(vpw), Some(vph)) =>
      if vbw <= 0.0 || vbh <= 0.0 || vpw <= 0.0 || vph <= 0.0 {
        @math.Affine2::identity()
      } else {
        let sx = vpw / vbw
        let sy = vph / vbh
        let s = if sx < sy { sx } else { sy }
        let tx = (vpw - vbw * s) / 2.0 - vbx * s
        let ty = (vph - vbh * s) / 2.0 - vby * s
        @math.Affine2::new(s, 0.0, 0.0, s, tx, ty)
      }
    _ => @math.Affine2::identity()
  }
}

// ---------------------------------------------------------------------------
// Shape → Path2 geometry
// ---------------------------------------------------------------------------

// Closed rectangle as a subpath. rx/ry > 0 produce rounded corners; both 0
// yield a sharp rectangle. SVG rules: if only one of rx/ry is set, the other
// defaults to it; both are clamped to half the shorter side. Each corner is a
// quarter-ellipse approximated by a single cubic Bézier (kappa=0.5522...,
// the standard circle-approximation constant).
fn rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rx_in : Double,
  ry_in : Double,
) -> @math.Path2 {
  let p = @math.Path2::new()
  // Sharp rectangle fast path.
  if rx_in <= 0.0 && ry_in <= 0.0 {
    p.push(@math.PathCommand::MoveTo(@math.Point2::new(x, y)))
    p.push(@math.PathCommand::LineTo(@math.Point2::new(x + w, y)))
    p.push(@math.PathCommand::LineTo(@math.Point2::new(x + w, y + h)))
    p.push(@math.PathCommand::LineTo(@math.Point2::new(x, y + h)))
    p.push(@math.PathCommand::Close)
    return p
  }
  // Resolve rx/ry per SVG: one missing → equals the other; clamp to half-size.
  let rx0 = if rx_in <= 0.0 { ry_in } else { rx_in }
  let ry0 = if ry_in <= 0.0 { rx_in } else { ry_in }
  let max_rx = w / 2.0
  let max_ry = h / 2.0
  let mut rx = if rx0 > max_rx { max_rx } else { rx0 }
  let mut ry = if ry0 > max_ry { max_ry } else { ry0 }
  // If clamping made rx exceed the ellipse bound for the other axis, scale
  // proportionally (SVG: if rx > half-width, ry scales by (half-width/rx)).
  if rx > 0.0 {
    let ratio = max_rx / rx
    if ratio < 1.0 {
      ry = ry * ratio
    }
    let ratio_y = max_ry / ry
    if ratio_y < 1.0 {
      rx = rx * ratio_y
    }
  }
  let kappa = 0.5522847498307936
  let kx = rx * kappa
  let ky = ry * kappa
  let x0 = x
  let y0 = y
  let x1 = x + w
  let y1 = y + h
  // Start at the top edge, just after the top-right corner's curve start.
  p.push(@math.PathCommand::MoveTo(@math.Point2::new(x + rx, y0)))
  // Top edge → top-right corner.
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x1 - rx, y0)))
  p.push(
    @math.PathCommand::CubicTo(
      @math.Point2::new(x1 - kx, y0),
      @math.Point2::new(x1, y0 + ky),
      @math.Point2::new(x1, y0 + ry),
    ),
  )
  // Right edge → bottom-right corner.
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x1, y1 - ry)))
  p.push(
    @math.PathCommand::CubicTo(
      @math.Point2::new(x1, y1 - ky),
      @math.Point2::new(x1 - kx, y1),
      @math.Point2::new(x1 - rx, y1),
    ),
  )
  // Bottom edge → bottom-left corner.
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x0 + rx, y1)))
  p.push(
    @math.PathCommand::CubicTo(
      @math.Point2::new(x0 + kx, y1),
      @math.Point2::new(x0, y1 - ky),
      @math.Point2::new(x0, y1 - ry),
    ),
  )
  // Left edge → top-left corner.
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x0, y0 + ry)))
  p.push(
    @math.PathCommand::CubicTo(
      @math.Point2::new(x0, y0 + ky),
      @math.Point2::new(x0 + kx, y0),
      @math.Point2::new(x0 + rx, y0),
    ),
  )
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
