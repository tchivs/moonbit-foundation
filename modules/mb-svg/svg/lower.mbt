// SceneTree → mb-canvas DrawingList lowering.
//
// Walks a SceneNode tree and emits DrawOps onto an mb-canvas DrawingList:
//   - Svg       → viewBox→viewport transform honoring preserveAspectRatio
//   - Group     → PushTransform(child-transform) ... children ... PopTransform
//   - shapes    → Fill and/or Stroke of the resolved Path2, applying Paint
//
// Geometry is lowered into a fresh mb-core Path2 per shape, so
// rect/circle/ellipse/polyline/polygon all become the same Path2 + PathCommand
// representation that <path> already produces (which reuses CanvasPath.to_path2).
// The DrawingList records pure data; rasterization (color resolution, scan
// conversion) is mb-canvas's job.
//
// viewBox→viewport mapping honors preserveAspectRatio: align (xMin/Mid/Max ×
// yMin/Mid/Max), meet/slice, and none. clip-rule is not yet handled (follow-up).
//
// stroke-width/linecap/linejoin/miterlimit/dasharray/dashoffset ARE wired
// through to the StrokeStyle setters.
//
// fill-opacity/stroke-opacity ARE applied (via FillStyle::with_alpha, which
// mb-canvas now exposes).
//
// group/element `opacity` (the `opacity` attribute) IS applied via raster
// layers (RFC 0008 PushLayer/PopLayer): a group or element with opacity < 1 is
// wrapped in a layer so the whole group/element composites onto the backdrop
// at that opacity (SVG §14.4 precise semantics). This was previously deferred
// for want of an mb-canvas layer primitive; RFC 0008 (Proposed) + its
// implementation unblocked it.

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
      let map = total_viewbox_transform(root)
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
    Group(transform, opacity, children) => {
      list.push_transform(transform)
      // Group opacity (RFC 0002 §6.1): when opacity != 1, wrap the group's
      // children in a raster layer (RFC 0008) so the whole group composites
      // onto the backdrop at this opacity. Order: PushTransform, [PushLayer],
      // children, [PopLayer], PopTransform.
      let layered = opacity < 1.0
      if layered {
        list.push_layer(opacity)
      }
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], list)
      }
      if layered {
        list.pop_layer()
      }
      list.pop_transform()
    }
    Rect(paint, x, y, w, h, rx, ry) =>
      emit_shape(paint, total_rect_path(x, y, w, h, rx, ry), list)
    Circle(paint, cx, cy, r) =>
      emit_shape(paint, total_path(checked_circle_path(cx, cy, r)), list)
    Ellipse(paint, cx, cy, rx, ry) =>
      emit_shape(paint, total_path(checked_ellipse_path(cx, cy, rx, ry)), list)
    Line(paint, x1, y1, x2, y2) =>
      emit_shape(paint, total_path(checked_line_path(x1, y1, x2, y2)), list)
    Polyline(paint, pts) => emit_shape(paint, total_path(checked_polyline_path(pts)), list)
    Polygon(paint, pts) => emit_shape(paint, total_path(checked_polygon_path(pts)), list)
    Path(paint, cp) => emit_shape(paint, total_path(checked_canvas_path(cp)), list)
  }
}

// Parser-produced roots have already passed checked_viewbox_transform. A
// manually constructed invalid root keeps the public lowerer total by using
// identity instead of exposing a Result or panicking.
fn total_viewbox_transform(root : SvgRoot) -> @math.Affine2 {
  match checked_viewbox_transform(root) {
    Ok(transform) => transform
    Err(_) => @math.Affine2::identity()
  }
}

// As above, invalid manually constructed leaf geometry is recovered as an
// empty path; valid parser-produced rectangles use the shared checked fact.
fn total_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rx : Double,
  ry : Double,
) -> @math.Path2 {
  match checked_rect_path(x, y, w, h, rx, ry) {
    Ok(path) => path
    Err(_) => @math.Path2::new()
  }
}

fn total_path(result : Result[@math.Path2, @error.CoreError]) -> @math.Path2 {
  match result {
    Ok(path) => path
    Err(_) => @math.Path2::new()
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
  // Element opacity (the `opacity` attribute): when < 1, the whole element
  // (fill and stroke together) composites onto the backdrop at this opacity.
  // Wrap the fill+stroke ops in a raster layer (RFC 0008).
  let layered = paint.opacity < 1.0
  if layered {
    list.push_layer(paint.opacity)
  }
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
        .with_dash_offset(paint.stroke_dashoffset)
      // Stroke color FillStyle: its rule is unused by the rasterizer (strokes
      // fill as even-odd outlines internally), so Nonzero is passed here.
      let color = make_fill_style(r, g, b, paint.stroke_opacity, @canvas.FillRule::Nonzero)
      list.push_stroke(path, stroke, color)
    }
    None => ()
  }
  if layered {
    list.pop_layer()
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

// Compute the viewBox→viewport transform for an <svg> root, honoring the
// parsed preserveAspectRatio (align + meet/slice + none). Returns identity
// when viewBox or width/height are absent or non-positive.
//   vb = (vbx, vby, vbw, vbh), vp = (vpw, vph) (viewport at origin 0,0)
//   sx = vpw/vbw, sy = vph/vbh
// Scaling: none → non-uniform (sx, sy); meet → min(sx,sy); slice → max(sx,sy).
// Alignment offset per axis: diff = vp_len - vb_len*s, placed at
//   Min→0, Mid→diff/2, Max→diff  (align ∈ {0,1,2}).
fn viewbox_transform(root : SvgRoot) -> @math.Affine2 {
  let par = root.preserve_aspect_ratio
  match (root.view_box, root.width, root.height) {
    (Some((vbx, vby, vbw, vbh)), Some(vpw), Some(vph)) =>
      if vbw <= 0.0 || vbh <= 0.0 || vpw <= 0.0 || vph <= 0.0 {
        @math.Affine2::identity()
      } else if par.none {
        // Non-uniform: fill viewport, no centering; viewBox origin maps to
        // viewport origin.
        let sx = vpw / vbw
        let sy = vph / vbh
        @math.Affine2::new(sx, 0.0, 0.0, sy, -vbx * sx, -vby * sy)
      } else {
        let sx = vpw / vbw
        let sy = vph / vbh
        let s = if par.meet {
          if sx < sy { sx } else { sy }
        } else {
          // slice: uniform max scale (viewBox overflows viewport).
          if sx > sy { sx } else { sy }
        }
        let diff_x = vpw - vbw * s
        let diff_y = vph - vbh * s
        let offset_x = par.align_x.to_double() * diff_x / 2.0
        let offset_y = par.align_y.to_double() * diff_y / 2.0
        let tx = offset_x - vbx * s
        let ty = offset_y - vby * s
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
