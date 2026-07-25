// White-box tests for stroke join geometry: miter_length at known angles.

///|
test "miter_length is exactly half for a straight-through vertex" {
  // Collinear tangents (straight line): θ=0, sin(θ/2)=0 → miter = half.
  let m = miter_length(1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 2.0, StrokeStyle::new(4.0))
  inspect(m, content="2")
}

///|
test "miter_length is half*sqrt(2) at a right-angle corner" {
  // 90° turn: t_in=(1,0), t_out=(0,1). θ=90°, sin(45°)=√2/2, miter=half/(√2/2)=half*√2.
  let half = 2.0
  let m = miter_length(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, half, StrokeStyle::new(half * 2.0))
  let expected = half * 1.4142135623730951
  inspect((m - expected).abs() < 1.0e-9, content="true")
}

///|
test "miter_length falls back to bevel beyond miter_limit" {
  // A 90° corner gives miter = half*√2 ≈ 1.414*half. With miter_limit=1.0,
  // limit = half*1.0 = half, so 1.414*half > half → fallback to half.
  let sharp = { ..StrokeStyle::new(4.0), miter_limit: 1.0 }
  let m = miter_length(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 2.0, sharp)
  inspect(m, content="2")
}

///|
test "bevel and round joins always use plain half offset" {
  let bevel = { ..StrokeStyle::new(4.0), join: LineJoin::Bevel }
  let round = { ..StrokeStyle::new(4.0), join: LineJoin::Round }
  // Right-angle corner: bevel/round ignore miter geometry, return half.
  inspect(miter_length(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 2.0, bevel), content="2")
  inspect(miter_length(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 2.0, round), content="2")
}

///|
test "miter_length handles degenerate (coincident) tangents" {
  // Zero-length tangent (coincident points) → plain half, no blow-up.
  inspect(miter_length(0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 2.0, StrokeStyle::new(4.0)), content="2")
  inspect(miter_length(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, StrokeStyle::new(4.0)), content="2")
}

// ---------------------------------------------------------------------------
// stroke-dashoffset: apply_dash offset preprocessing
//
// A horizontal line from (0,0) to (10,0), pattern [5,5] (on 5, off 5). The
// number and extent of "on" output polylines depends on the dash offset.
// ---------------------------------------------------------------------------

// Build a straight polyline from (0,0) to (len,0): a single horizontal segment.
fn dash_line(len : Double) -> Polyline {
  {
    points: [@math.Point2::new(0.0, 0.0), @math.Point2::new(len, 0.0)],
    closed: false,
  }
}

///|
test "apply_dash offset=0 yields one on-segment covering [0,5]" {
  // Pattern [5,5] over a length-10 line: on [0,5], off [5,10] → 1 on polyline.
  let subs = apply_dash(dash_line(10.0), [5.0, 5.0], 0.0)
  inspect(subs.length(), content="1")
  // The on-segment spans x in [0,5].
  let s0 = subs[0]
  inspect(s0.points[0].x(), content="0")
  inspect(s0.points[1].x(), content="5")
}

///|
test "apply_dash offset shifts the pattern into the off segment" {
  // offset=5 lands at the start of the off entry: off [0,5], on [5,10].
  let subs = apply_dash(dash_line(10.0), [5.0, 5.0], 5.0)
  inspect(subs.length(), content="1")
  let s0 = subs[0]
  inspect(s0.points[0].x(), content="5")
  inspect(s0.points[1].x(), content="10")
}

///|
test "apply_dash offset inside an on entry splits the output" {
  // offset=2.5 lands mid-on: remaining on = 2.5 → on [0,2.5]; then off
  // [2.5,7.5]; then on [7.5,10]. Two on polylines.
  let subs = apply_dash(dash_line(10.0), [5.0, 5.0], 2.5)
  inspect(subs.length(), content="2")
  inspect(subs[0].points[0].x(), content="0")
  inspect(subs[0].points[1].x(), content="2.5")
  inspect(subs[1].points[0].x(), content="7.5")
  inspect(subs[1].points[1].x(), content="10")
}

///|
test "apply_dash offset wraps modulo the pattern total length" {
  // Pattern total = 10. offset=12 ≡ offset=2 (12 % 10). So offset=12 and
  // offset=2 must produce the same first on-segment start.
  let a = apply_dash(dash_line(10.0), [5.0, 5.0], 12.0)
  let b = apply_dash(dash_line(10.0), [5.0, 5.0], 2.0)
  // offset=2 → on entry remaining = 3 → on [0,3], off [3,8], on [8,10] (2 runs).
  inspect(a.length(), content="2")
  inspect(b.length(), content="2")
  inspect(a[0].points[1].x() == b[0].points[1].x(), content="true")
}

///|
test "apply_dash negative offset normalizes forward" {
  // offset=-5 over pattern [5,5] (total 10): -5 % 10 = -5 → +10 = 5.
  // Equivalent to offset=5 (lands at start of off entry).
  let neg = apply_dash(dash_line(10.0), [5.0, 5.0], -5.0)
  let pos = apply_dash(dash_line(10.0), [5.0, 5.0], 5.0)
  inspect(neg.length(), content="1")
  inspect(neg[0].points[0].x() == pos[0].points[0].x(), content="true")
}
