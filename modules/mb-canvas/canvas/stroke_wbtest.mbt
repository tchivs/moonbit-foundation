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
