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
  lower_node(root, @math.Affine2::identity(), list)
  list
}

// Recursively lower one node, carrying the admitted effective affine that is
// already represented by ancestor DrawOps.

///|
fn lower_node(
  node : SceneNode,
  current : @math.Affine2,
  list : @canvas.DrawingList,
) -> Unit {
  match node {
    Svg(root, children) => {
      // viewBox → viewport mapping (SVG default preserveAspectRatio=
      // "xMidYMid meet"). If viewBox is absent, or width/height are absent,
      // no mapping is applied (identity). meet keeps aspect ratio by using
      // the smaller scale and centers the content (xMid/YMid).
      let map = total_viewbox_transform(root)
      let (local_map, child_current) = match
        checked_compose_affine(current, map) {
        Ok(composed) => (map, composed)
        // A manually assembled nested Svg can make an otherwise valid root map
        // unsafe when combined with its inherited state. Keep total lowering
        // deterministic by omitting that local contribution.
        Err(_) => (@math.Affine2::identity(), current)
      }
      let mapped = not(
        local_map.a() == 1.0 &&
        local_map.d() == 1.0 &&
        local_map.tx() == 0.0 &&
        local_map.ty() == 0.0,
      )
      if mapped {
        list.push_transform(local_map)
      }
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], child_current, list)
      }
      if mapped {
        list.pop_transform()
      }
    }
    Group(transform, opacity, children) => {
      let (local_transform, child_current) = match
        checked_compose_affine(current, transform) {
        Ok(composed) => (transform, composed)
        // Public SceneNode values can bypass parser preflight. Keep the total
        // lowerer safe by recording identity and preserving the prior admitted
        // effective transform for descendants.
        Err(_) => (@math.Affine2::identity(), current)
      }
      list.push_transform(local_transform)
      // Group opacity (RFC 0002 §6.1): when opacity != 1, wrap the group's
      // children in a raster layer (RFC 0008) so the whole group composites
      // onto the backdrop at this opacity. Order: PushTransform, [PushLayer],
      // children, [PopLayer], PopTransform.
      let layered = opacity < 1.0
      if layered {
        list.push_layer(opacity)
      }
      for i = 0; i < children.length(); i = i + 1 {
        lower_node(children[i], child_current, list)
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
    Polyline(paint, pts) =>
      emit_shape(paint, total_path(checked_polyline_path(pts)), list)
    Polygon(paint, pts) =>
      emit_shape(paint, total_path(checked_polygon_path(pts)), list)
    Path(paint, cp) =>
      emit_shape(paint, total_path(checked_canvas_path(cp)), list)
  }
}

// Parser-produced roots have already passed checked_viewbox_transform. A
// manually constructed invalid root keeps the public lowerer total by using
// identity instead of exposing a Result or panicking.

///|
fn total_viewbox_transform(root : SvgRoot) -> @math.Affine2 {
  match checked_viewbox_transform(root) {
    Ok(transform) => transform
    Err(_) => @math.Affine2::identity()
  }
}

// As above, invalid manually constructed leaf geometry is recovered as an
// empty path; valid parser-produced rectangles use the shared checked fact.

///|
fn total_rect_path(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rx : Double,
  ry : Double,
) -> @math.Path2 {
  match checked_rect_path(x, y, w, h, rx, ry) {
    Ok(path) => total_checked_path(path)
    Err(_) => @math.Path2::new()
  }
}

///|
fn total_path(result : Result[@math.Path2, @error.CoreError]) -> @math.Path2 {
  match result {
    Ok(path) => total_checked_path(path)
    Err(_) => @math.Path2::new()
  }
}

///|
fn total_checked_path(path : @math.Path2) -> @math.Path2 {
  match checked_path_points(path, @math.Affine2::identity()) {
    Ok(_) => path
    Err(_) => @math.Path2::new()
  }
}

// Emit fill and (if any) stroke ops for a shape. Applies to both closed
// shapes (rect/circle/ellipse/polygon/path) and open ones (polyline): SVG
// permits filling open paths, so the same emission is used for both.

///|
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
      let color = make_fill_style(
        r,
        g,
        b,
        paint.stroke_opacity,
        @canvas.FillRule::Nonzero,
      )
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

///|
fn make_fill_style(
  r : Double,
  g : Double,
  b : Double,
  alpha : Double,
  rule : @canvas.FillRule,
) -> @canvas.FillStyle {
  @canvas.FillStyle::new(r, g, b).with_alpha(alpha).with_rule(rule)
}
