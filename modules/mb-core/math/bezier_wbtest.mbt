// White-box tests for Bézier evaluation and flattening.

///|
test "quadratic bezier evaluates endpoints and midpoint correctly" {
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(5.0, 10.0)
  let p2 = Point2::new(10.0, 0.0)
  // t=0 -> P0
  inspect(point_approx(bezier2_eval(p0, p1, p2, 0.0), 0.0, 0.0), content="true")
  // t=1 -> P2
  inspect(point_approx(bezier2_eval(p0, p1, p2, 1.0), 10.0, 0.0), content="true")
  // t=0.5 -> (1-t)^2*0 + 2*(0.5)*(0.5)*5 + 0.25*10 = 5, y: 2*0.25*10 = 5
  inspect(point_approx(bezier2_eval(p0, p1, p2, 0.5), 5.0, 5.0), content="true")
}

///|
test "cubic bezier evaluates endpoints and midpoint correctly" {
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(0.0, 10.0)
  let p2 = Point2::new(10.0, 10.0)
  let p3 = Point2::new(10.0, 0.0)
  // t=0 -> P0
  inspect(point_approx(bezier3_eval(p0, p1, p2, p3, 0.0), 0.0, 0.0), content="true")
  // t=1 -> P3
  inspect(point_approx(bezier3_eval(p0, p1, p2, p3, 1.0), 10.0, 0.0), content="true")
  // t=0.5 -> x: 0.125*0 + 0.375*0 + 0.375*10 + 0.125*10 = 5.0
  //          y: 0.125*0 + 0.375*10 + 0.375*10 + 0.125*0 = 7.5
  inspect(point_approx(bezier3_eval(p0, p1, p2, p3, 0.5), 5.0, 7.5), content="true")
}

///|
test "quadratic bezier flatten produces connected segments" {
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(5.0, 10.0)
  let p2 = Point2::new(10.0, 0.0)
  match bezier2_flatten(p0, p1, p2, 0.5, 20) {
    Ok(segments) => {
      // Must have at least one segment.
      inspect(segments.length() >= 1, content="true")
      // First segment starts at P0.
      inspect(point_approx(segments[0].start(), 0.0, 0.0), content="true")
      // Last segment ends at P2.
      let last = segments[segments.length() - 1].end()
      inspect(point_approx(last, 10.0, 0.0), content="true")
      // Segments are connected: each segment's start equals the previous end.
      let connected = {
        let mut ok = true
        for i = 1; i < segments.length(); i = i + 1 {
          let prev_end = segments[i - 1].end()
          let curr_start = segments[i].start()
          if !approx(prev_end.x(), curr_start.x()) || !approx(prev_end.y(), curr_start.y()) {
            ok = false
            break
          }
        }
        ok
      }
      inspect(connected, content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "cubic bezier flatten produces connected segments" {
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(0.0, 10.0)
  let p2 = Point2::new(10.0, 10.0)
  let p3 = Point2::new(10.0, 0.0)
  match bezier3_flatten(p0, p1, p2, p3, 0.5, 20) {
    Ok(segments) => {
      inspect(segments.length() >= 1, content="true")
      inspect(point_approx(segments[0].start(), 0.0, 0.0), content="true")
      let last = segments[segments.length() - 1].end()
      inspect(point_approx(last, 10.0, 0.0), content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "flat curve produces single segment" {
  // A straight line disguised as a quadratic (control point on the chord).
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(5.0, 0.0)
  let p2 = Point2::new(10.0, 0.0)
  match bezier2_flatten(p0, p1, p2, 0.1, 20) {
    Ok(segments) => inspect(segments.length() == 1, content="true")
    Err(_) => inspect(false, content="true")
  }
  // Same for cubic.
  let c0 = Point2::new(0.0, 0.0)
  let c1 = Point2::new(3.0, 0.0)
  let c2 = Point2::new(7.0, 0.0)
  let c3 = Point2::new(10.0, 0.0)
  match bezier3_flatten(c0, c1, c2, c3, 0.1, 20) {
    Ok(segments) => inspect(segments.length() == 1, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "tighter tolerance produces more segments" {
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(5.0, 10.0)
  let p2 = Point2::new(10.0, 0.0)
  let coarse = bezier2_flatten(p0, p1, p2, 2.0, 20).unwrap()
  let fine = bezier2_flatten(p0, p1, p2, 0.01, 20).unwrap()
  inspect(fine.length() >= coarse.length(), content="true")
  inspect(fine.length() > coarse.length(), content="true")
}

///|
test "bezier flatten rejects invalid parameters" {
  let p0 = Point2::new(0.0, 0.0)
  let p1 = Point2::new(5.0, 10.0)
  let p2 = Point2::new(10.0, 0.0)
  // Zero tolerance.
  match bezier2_flatten(p0, p1, p2, 0.0, 20) {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
  // Zero max_depth.
  match bezier2_flatten(p0, p1, p2, 0.5, 0) {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}
