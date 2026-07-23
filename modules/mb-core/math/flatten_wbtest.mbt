// White-box tests for Path2::flattened.

///|
test "path2 flattened of a triangle produces closed segments" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(LineTo(Point2::new(10.0, 0.0)))
  path.push(LineTo(Point2::new(5.0, 8.0)))
  path.push(Close)
  let segments = path.flattened(0.5, 20)
  // 2 line segments + 1 close segment = 3.
  inspect(segments.length(), content="3")
  inspect(segments[0].start().x() == 0.0, content="true")
  inspect(segments[0].end().x() == 10.0, content="true")
  // Close goes from last point back to subpath start.
  inspect(segments[2].end().x() == 0.0, content="true")
}

///|
test "path2 flattened with quadratic bezier produces multiple segments" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(QuadTo(Point2::new(50.0, 100.0), Point2::new(100.0, 0.0)))
  let segments = path.flattened(0.5, 20)
  // Should be more than 1 segment (curve is not flat).
  inspect(segments.length() > 1, content="true")
  // First segment starts at MoveTo point.
  inspect(segments[0].start().x() == 0.0, content="true")
  // Last segment ends at the curve endpoint.
  inspect(segments[segments.length() - 1].end().x() == 100.0, content="true")
}

///|
test "path2 flattened with cubic bezier produces multiple segments" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(CubicTo(Point2::new(0.0, 100.0), Point2::new(100.0, 100.0), Point2::new(100.0, 0.0)))
  let segments = path.flattened(0.5, 20)
  inspect(segments.length() > 1, content="true")
  inspect(segments[0].start().x() == 0.0, content="true")
  inspect(segments[segments.length() - 1].end().x() == 100.0, content="true")
}

///|
test "path2 flattened of flat curve produces single segment" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  // Control points on the chord → flat curve.
  path.push(QuadTo(Point2::new(5.0, 0.0), Point2::new(10.0, 0.0)))
  let segments = path.flattened(0.1, 20)
  inspect(segments.length(), content="1")
}

///|
test "path2 flattened of empty path produces no segments" {
  let path = Path2::new()
  let segments = path.flattened(0.5, 20)
  inspect(segments.length(), content="0")
}

///|
test "path2 flattened segments are connected" {
  let path = Path2::new()
  path.push(MoveTo(Point2::new(0.0, 0.0)))
  path.push(QuadTo(Point2::new(50.0, 100.0), Point2::new(100.0, 0.0)))
  path.push(LineTo(Point2::new(100.0, 50.0)))
  let segments = path.flattened(0.5, 20)
  let connected = {
    let mut ok = true
    for i = 1; i < segments.length(); i = i + 1 {
      if segments[i - 1].end().x() != segments[i].start().x() || segments[i - 1].end().y() != segments[i].start().y() {
        ok = false
        break
      }
    }
    ok
  }
  inspect(connected, content="true")
}
