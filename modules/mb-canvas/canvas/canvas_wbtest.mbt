// White-box tests for the mb-canvas data layer: style construction, drawing
// list building, and CanvasPath geometry lowering.

///|
test "FillStyle::new produces opaque nonzero default" {
  let s = FillStyle::new(0.5, 0.25, 0.0)
  inspect(s.color_r, content="0.5")
  inspect(s.color_g, content="0.25")
  inspect(s.color_b, content="0")
  inspect(s.color_a, content="1")
  inspect(s.rule == FillRule::Nonzero, content="true")
}

///|
test "StrokeStyle::new produces butt/miter/solid default" {
  let s = StrokeStyle::new(3.0)
  inspect(s.width, content="3")
  inspect(s.cap == LineCap::Butt, content="true")
  inspect(s.join == LineJoin::Miter, content="true")
  inspect(s.miter_limit, content="4")
  inspect(s.dash.length(), content="0")
}

///|
test "DrawingList records operations in order" {
  let list = DrawingList::new()
  inspect(list.length(), content="0")
  let path = @math.Path2::new()
  list.push_fill(path, FillStyle::new(1.0, 0.0, 0.0))
  list.push_transform(@math.Affine2::translate(1.0, 2.0))
  list.pop_transform()
  inspect(list.length(), content="3")
  match list.get(0) {
    Some(DrawOp::Fill(_, style)) => inspect(style.color_r, content="1")
    _ => inspect(false, content="true") // fail: expected Fill
  }
  match list.get(1) {
    Some(DrawOp::PushTransform(t)) => inspect(t.tx(), content="1")
    _ => inspect(false, content="true") // fail: expected PushTransform
  }
  match list.get(2) {
    Some(DrawOp::PopTransform) => inspect(true, content="true")
    _ => inspect(false, content="true") // fail: expected PopTransform
  }
  inspect(list.get(99) is None, content="true")
}

///|
test "CanvasPath::rect lowers to 5 commands (move + 3 lines + close)" {
  let p = CanvasPath::new()
  p.rect(0.0, 0.0, 10.0, 20.0)
  let path2 = p.to_path2()
  inspect(path2.length(), content="5")
}

///|
test "CanvasPath line and quad and cubic lower correctly" {
  let p = CanvasPath::new()
  p.move_to(0.0, 0.0)
  p.line_to(1.0, 2.0)
  p.quad_to(3.0, 4.0, 5.0, 6.0)
  p.cubic_to(7.0, 8.0, 9.0, 10.0, 11.0, 12.0)
  p.close_path()
  inspect(p.to_path2().length(), content="5")
}

///|
test "CanvasPath::arc produces at least one move and cubic segments" {
  // A full circle (2π) subdivides into 4 quarter-turn segments.
  let p = CanvasPath::new()
  p.arc(0.0, 0.0, 5.0, 0.0, 6.283185307179586)
  // 1 move + 4 cubics.
  inspect(p.to_path2().length(), content="5")
}

///|
test "DrawingList push_clip and push_stroke record ops" {
  let list = DrawingList::new()
  let path = @math.Path2::new()
  list.push_clip(@math.Rect2::new(0.0, 0.0, 10.0, 10.0))
  list.push_stroke(path, StrokeStyle::new(2.0), FillStyle::new(0.0, 0.0, 1.0))
  list.pop_clip()
  match list.get(0) {
    Some(DrawOp::PushClip(r)) => inspect(r.width(), content="10")
    _ => inspect(false, content="true")
  }
  match list.get(1) {
    Some(DrawOp::Stroke(_, stroke, color)) => {
      inspect(stroke.width, content="2")
      inspect(color.color_b, content="1")
    }
    _ => inspect(false, content="true")
  }
  match list.get(2) {
    Some(DrawOp::PopClip) => inspect(true, content="true")
    _ => inspect(false, content="true")
  }
}
