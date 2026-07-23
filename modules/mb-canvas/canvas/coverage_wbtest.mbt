// White-box tests for coverage computation: known-geometry assertions on the
// nonzero/even-odd winding and supersampling coverage.
//
// LineSegment has no public constructor in mb-core/math, so we build segments
// by constructing a Path2 and flattening it — the same path the rasterizer takes.

// Flattened segments of an axis-aligned rectangle [x0,x1]×[y0,y1] as a closed
// loop of line commands.
fn wb_rect_segments(
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Array[@math.LineSegment] {
  let p = @math.Path2::new()
  p.push(@math.PathCommand::MoveTo(@math.Point2::new(x0, y0)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x1, y0)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x1, y1)))
  p.push(@math.PathCommand::LineTo(@math.Point2::new(x0, y1)))
  p.push(@math.PathCommand::Close)
  p.flattened(0.1, 16)
}

///|
test "winding_at is zero outside a rectangle and nonzero inside" {
  let segs = wb_rect_segments(2.0, 2.0, 6.0, 6.0)
  // Center is inside → nonzero winding.
  inspect(winding_at(segs, 4.0, 4.0) != 0, content="true")
  // Far outside → zero winding.
  inspect(winding_at(segs, 0.0, 0.0) == 0, content="true")
  inspect(winding_at(segs, 10.0, 10.0) == 0, content="true")
}

///|
test "point_inside matches rectangle interior for both rules" {
  let segs = wb_rect_segments(2.0, 2.0, 6.0, 6.0)
  // Inside.
  inspect(point_inside(segs, FillRule::Nonzero, 4.0, 4.0), content="true")
  inspect(point_inside(segs, FillRule::EvenOdd, 4.0, 4.0), content="true")
  // Outside.
  inspect(point_inside(segs, FillRule::Nonzero, 0.0, 0.0), content="false")
  inspect(point_inside(segs, FillRule::EvenOdd, 0.0, 0.0), content="false")
}

///|
test "pixel_coverage is 1.0 for a fully-covered pixel" {
  // Rectangle covers pixel [0,1]×[0,1] entirely (rect spans [-5,5]×[-5,5]).
  let segs = wb_rect_segments(-5.0, -5.0, 5.0, 5.0)
  let c = pixel_coverage(segs, FillRule::Nonzero, 0.0, 0.0, 4)
  inspect(c, content="1")
}

///|
test "pixel_coverage is 0.0 for a pixel fully outside" {
  let segs = wb_rect_segments(10.0, 10.0, 20.0, 20.0)
  let c = pixel_coverage(segs, FillRule::Nonzero, 0.0, 0.0, 4)
  inspect(c, content="0")
}

///|
test "pixel_coverage is fractional for an edge pixel" {
  // Rectangle right edge at x=0.5 splits pixel [0,1]×[0,1] in half.
  // With a 4×4 grid, columns 0 and 1 (x in [0,0.5)) are outside, columns 2 and 3
  // (x in [0.5,1)) are inside → 8 of 16 samples inside → coverage 0.5.
  let segs = wb_rect_segments(0.5, -5.0, 5.0, 5.0)
  let c = pixel_coverage(segs, FillRule::Nonzero, 0.0, 0.0, 4)
  inspect(c, content="0.5")
}

///|
test "even-odd vs nonzero on nested rectangles" {
  // Two nested rectangles (concentric). A point inside both has winding 2.
  let outer = wb_rect_segments(0.0, 0.0, 10.0, 10.0)
  let inner = wb_rect_segments(2.0, 2.0, 8.0, 8.0)
  let segs : Array[@math.LineSegment] = []
  for s in outer {
    segs.push(s)
  }
  for s in inner {
    segs.push(s)
  }
  // Point at (5,5) is inside both → winding 2.
  inspect(point_inside(segs, FillRule::Nonzero, 5.0, 5.0), content="true")
  inspect(point_inside(segs, FillRule::EvenOdd, 5.0, 5.0), content="false")
  // Point at (1,1) is inside outer only → winding 1.
  inspect(point_inside(segs, FillRule::EvenOdd, 1.0, 1.0), content="true")
}
