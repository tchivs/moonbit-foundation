// White-box tests for line segment intersection and clipping.

///|
fn seg(x0 : Double, y0 : Double, x1 : Double, y1 : Double) -> LineSegment {
  { start_value: Point2::new(x0, y0), end_value: Point2::new(x1, y1) }
}

///|
test "segment intersection detects crossing segments" {
  let a = seg(0.0, 0.0, 10.0, 10.0) // diagonal /
  let b = seg(0.0, 10.0, 10.0, 0.0) // diagonal \
  inspect(segments_intersect(a, b), content="true")
  match segment_intersection(a, b) {
    Some(p) => {
      inspect(approx(p.x(), 5.0), content="true")
      inspect(approx(p.y(), 5.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "segment intersection returns None for non-crossing" {
  let a = seg(0.0, 0.0, 5.0, 5.0)
  let b = seg(6.0, 6.0, 10.0, 10.0) // collinear but not overlapping
  match segment_intersection(a, b) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "segment intersection handles parallel segments" {
  let a = seg(0.0, 0.0, 10.0, 0.0) // horizontal
  let b = seg(0.0, 5.0, 10.0, 5.0) // parallel horizontal
  match segment_intersection(a, b) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "segment intersection at endpoints" {
  // Touching at (5, 5).
  let a = seg(0.0, 0.0, 5.0, 5.0)
  let b = seg(5.0, 5.0, 10.0, 0.0)
  inspect(segments_intersect(a, b), content="true")
}

///|
test "line intersection computes infinite line crossing" {
  match line_intersection(
    Point2::new(0.0, 0.0), Vector2::new(1.0, 1.0),
    Point2::new(0.0, 10.0), Vector2::new(1.0, -1.0),
  ) {
    Some(p) => {
      inspect(approx(p.x(), 5.0), content="true")
      inspect(approx(p.y(), 5.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "line intersection returns None for parallel lines" {
  match line_intersection(
    Point2::new(0.0, 0.0), Vector2::new(1.0, 0.0),
    Point2::new(0.0, 5.0), Vector2::new(1.0, 0.0),
  ) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "clip segment to rect keeps inside segment unchanged" {
  let s = seg(2.0, 2.0, 8.0, 8.0)
  let rect = Rect2::new(0.0, 0.0, 10.0, 10.0)
  match clip_segment_to_rect(s, rect) {
    Some(clipped) => {
      inspect(approx(clipped.start().x(), 2.0), content="true")
      inspect(approx(clipped.end().x(), 8.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "clip segment to rect clips partially outside segment" {
  // Segment from (-5, 5) to (15, 5) clipped to [0,10]x[0,10] should become (0,5)-(10,5).
  let s = seg(-5.0, 5.0, 15.0, 5.0)
  let rect = Rect2::new(0.0, 0.0, 10.0, 10.0)
  match clip_segment_to_rect(s, rect) {
    Some(clipped) => {
      inspect(approx(clipped.start().x(), 0.0), content="true")
      inspect(approx(clipped.end().x(), 10.0), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "clip segment to rect rejects fully outside segment" {
  let s = seg(20.0, 20.0, 30.0, 30.0)
  let rect = Rect2::new(0.0, 0.0, 10.0, 10.0)
  match clip_segment_to_rect(s, rect) {
    Some(_) => inspect(false, content="true")
    None => inspect(true, content="true")
  }
}

///|
test "clip segment to rect clips diagonal crossing corner" {
  // Segment from (-5, -5) to (15, 15) clipped to [0,10]x[0,10].
  let s = seg(-5.0, -5.0, 15.0, 15.0)
  let rect = Rect2::new(0.0, 0.0, 10.0, 10.0)
  match clip_segment_to_rect(s, rect) {
    Some(clipped) => {
      inspect(approx(clipped.start().x(), 0.0), content="true")
      inspect(approx(clipped.end().x(), 10.0), content="true")
    }
    None => inspect(false, content="true")
  }
}
