// Direct controls for the checked geometry seam. These exercises the private
// facts without coupling the proof to source-text implementation details.

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
    Ok(map) => inspect((map.a(), map.d(), map.tx(), map.ty()), content="(2, 2, 0, 50)")
    Err(_) => inspect(false, content="true")
  }
  match checked_compose_affine(@math.Affine2::identity(), @math.Affine2::translate(3.0, 4.0)) {
    Ok(transform) => inspect((transform.tx(), transform.ty()), content="(3, 4)")
    Err(_) => inspect(false, content="true")
  }
  match checked_transform_point(@math.Affine2::scale(0.0, 0.0), @math.Point2::new(65536.0, -65536.0)) {
    Ok(point) => inspect((point.x(), point.y()), content="(0, 0)")
    Err(_) => inspect(false, content="true")
  }
  match checked_rect_path(0.0, 0.0, 10.0, 10.0, 2.0, 2.0) {
    Ok(path) => inspect(path.length(), content="10")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "geometry facts: derived overflow remains structured" {
  match checked_transform_point(@math.Affine2::scale(65536.0, 1.0), @math.Point2::new(2.0, 0.0)) {
    Ok(_) => inspect(false, content="true")
    Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
  }
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
    (Ok(polyline), Ok(polygon)) => inspect((polyline.length(), polygon.length()), content="(2, 3)")
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
