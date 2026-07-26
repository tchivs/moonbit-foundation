// Direct controls for the checked geometry seam. These exercises the private
// facts without coupling the proof to source-text implementation details.

fn assert_private_point_derived_error(
  result : Result[@math.Point2, @error.CoreError],
) -> Unit raise {
  match result {
    Ok(_) => inspect(false, content="true")
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }
}

fn assert_private_derived_error(
  result : Result[Unit, @error.CoreError],
) -> Unit raise {
  match result {
    Ok(_) => inspect(false, content="true")
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }
}

fn assert_private_path_derived_error(
  result : Result[@math.Path2, @error.CoreError],
  transform : @math.Affine2,
) -> Unit raise {
  match result {
    Ok(path) => assert_private_derived_error(checked_path_points(path, transform))
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }
}

///|
test "geometry tracer: root map group affine and rectangle parse then lower" {
  let source = "<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\"><g transform=\"translate(10,0)\"><rect width=\"1\" height=\"1\"/></g></svg>"
  match parse_svg(source) {
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="5")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "geometry facts: root map affine point and rectangle are checked" {
  let root : SvgRoot = {
    width: Some(200.0),
    height: Some(200.0),
    view_box: Some((0.0, 0.0, 100.0, 50.0)),
    preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: false },
  }
  match checked_viewbox_transform(root) {
    Ok(map) => assert_eq((map.a(), map.d(), map.tx(), map.ty()), (2.0, 2.0, 0.0, 50.0))
    Err(_) => inspect(false, content="true")
  }
  match checked_compose_affine(@math.Affine2::identity(), @math.Affine2::translate(3.0, 4.0)) {
    Ok(transform) => assert_eq((transform.tx(), transform.ty()), (3.0, 4.0))
    Err(_) => inspect(false, content="true")
  }
  match checked_transform_point(@math.Affine2::scale(0.0, 0.0), @math.Point2::new(65536.0, -65536.0)) {
    Ok(point) => assert_eq((point.x(), point.y()), (0.0, 0.0))
    Err(_) => inspect(false, content="true")
  }
  match checked_rect_path(0.0, 0.0, 10.0, 10.0, 2.0, 2.0) {
    Ok(path) => inspect(path.length(), content="10")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "geometry facts: derived overflow remains structured" {
  assert_private_point_derived_error(
    checked_transform_point(
      @math.Affine2::scale(65536.0, 1.0),
      @math.Point2::new(2.0, 0.0),
    ),
  )
}

///|
test "geometry tracer pairs derived root-map rejection with finite scale zero" {
  let unsafe_root : SvgRoot = {
    width: Some(2.0),
    height: Some(2.0),
    view_box: Some((-65536.0, 0.0, 1.0, 1.0)),
    preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: false },
  }
  match checked_viewbox_transform(unsafe_root) {
    Ok(_) => inspect(false, content="true")
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }
  match checked_transform_point(
    @math.Affine2::scale(0.0, 0.0),
    @math.Point2::new(65536.0, -65536.0),
  ) {
    Ok(point) => assert_eq((point.x(), point.y()), (0.0, 0.0))
    Err(_) => inspect(false, content="true")
  }
}

///|
test "geometry parity matrix observes every checked derived-geometry family" {
  let overflow_translate = @math.Affine2::translate(1.0, 0.0)
  let unsafe_root : SvgRoot = {
    width: Some(2.0),
    height: Some(2.0),
    view_box: Some((-65536.0, 0.0, 1.0, 1.0)),
    preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: false },
  }
  // Root map and accumulated affine are direct Result facts, not a second
  // arithmetic oracle.
  match checked_viewbox_transform(unsafe_root) {
    Ok(_) => inspect(false, content="true")
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }
  match checked_compose_affine(
    @math.Affine2::translate(65536.0, 0.0),
    overflow_translate,
  ) {
    Ok(_) => inspect(false, content="true")
    Err(error) =>
      assert_eq(error.context(), Some("svg-numeric-derived"))
  }
  assert_private_point_derived_error(
    checked_transform_point(overflow_translate, @math.Point2::new(65536.0, 0.0)),
  )

  // Primitive builders are paired with the shared path-point admission seam.
  assert_private_path_derived_error(
    checked_rect_path(65536.0, 0.0, 1.0, 1.0, 1.0, 1.0),
    @math.Affine2::identity(),
  )
  assert_private_path_derived_error(
    checked_circle_path(65536.0, 0.0, 1.0),
    @math.Affine2::identity(),
  )
  assert_private_path_derived_error(
    checked_ellipse_path(65536.0, 0.0, 1.0, 1.0),
    @math.Affine2::identity(),
  )
  assert_private_path_derived_error(
    checked_line_path(65536.0, 0.0, 0.0, 0.0),
    overflow_translate,
  )

  let boundary_points = [@math.Point2::new(65536.0, 0.0), @math.Point2::new(0.0, 0.0)]
  assert_private_path_derived_error(
    checked_polyline_path(boundary_points),
    overflow_translate,
  )
  assert_private_path_derived_error(
    checked_polygon_path(boundary_points),
    overflow_translate,
  )

  // CanvasPath traversal and post-construction Path2 points take the same
  // checked admission route without exposing a public helper.
  match parse_path_data("M 65536 0 L 0 0") {
    Ok(canvas_path) =>
      assert_private_path_derived_error(
        checked_canvas_path(canvas_path),
        overflow_translate,
      )
    Err(_) => inspect(false, content="true")
  }
  let manual_path = @math.Path2::new()
  manual_path.push(@math.PathCommand::MoveTo(@math.Point2::new(65536.0, 0.0)))
  assert_private_derived_error(checked_path_points(manual_path, overflow_translate))
}

///|
test "geometry facts: supported primitive paths preserve command forms" {
  match checked_circle_path(0.0, 0.0, 2.0) {
    Ok(path) => inspect(path.length(), content="33")
    Err(_) => inspect(false, content="true")
  }
  match checked_ellipse_path(0.0, 0.0, 2.0, 1.0) {
    Ok(path) => inspect(path.length(), content="33")
    Err(_) => inspect(false, content="true")
  }
  match checked_line_path(0.0, 0.0, 2.0, 3.0) {
    Ok(path) => inspect(path.length(), content="2")
    Err(_) => inspect(false, content="true")
  }
  let points = [@math.Point2::new(0.0, 0.0), @math.Point2::new(1.0, 1.0)]
  match (checked_polyline_path(points), checked_polygon_path(points)) {
    (Ok(polyline), Ok(polygon)) =>
      assert_eq((polyline.length(), polygon.length()), (2, 3))
    _ => inspect(false, content="true")
  }
}

///|
test "geometry facts: canvas path traversal and all shapes parse then lower" {
  match parse_path_data("M0 0 Q1 2 3 4 C5 6 7 8 9 10 Z") {
    Ok(canvas_path) =>
      match checked_canvas_path(canvas_path) {
        Ok(path) => inspect(path.length(), content="4")
        Err(_) => inspect(false, content="true")
      }
    Err(_) => inspect(false, content="true")
  }
  let source = "<svg><circle r=\"1\"/><ellipse rx=\"2\" ry=\"1\"/><line x2=\"2\" y2=\"3\"/><polyline points=\"0,0 1,1\"/><polygon points=\"0,0 1,0 1,1\"/><path d=\"M0 0 L1 1 Z\"/></svg>"
  match parse_svg(source) {
    Ok(scene) => inspect(lower_to_drawing_list(scene).length(), content="6")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "geometry lowering stays total for manually invalid root and rectangle" {
  match parse_svg("<svg><rect width=\"1\" height=\"1\"/></svg>") {
    Ok(Svg(_, [Rect(paint, _, _, _, _, _, _)])) => {
      let invalid_rect = Rect(paint, 65536.0, 0.0, 1.0, 1.0, 0.0, 0.0)
      match lower_to_drawing_list(invalid_rect).get(0) {
        Some(@canvas.DrawOp::Fill(path, _)) => inspect(path.length(), content="0")
        _ => inspect(false, content="true")
      }
      let invalid_root : SvgRoot = {
        width: Some(65536.0),
        height: Some(1.0),
        view_box: Some((2.0, 0.0, 1.0, 1.0)),
        preserve_aspect_ratio: { align_x: 1, align_y: 1, meet: true, none: true },
      }
      inspect(lower_to_drawing_list(Svg(invalid_root, [Rect(paint, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0)])).length(), content="1")
    }
    _ => inspect(false, content="true")
  }
}
