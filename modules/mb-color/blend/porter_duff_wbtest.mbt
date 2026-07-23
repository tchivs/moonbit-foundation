// White-box tests for Porter-Duff compositing operators.

///|
fn approx4(a : (Double, Double, Double, Double), b : (Double, Double, Double, Double)) -> Bool {
  let tol = 1.0e-10
  let (ar, ag, ab, aa) = a
  let (br, bg, bb, ba) = b
  let dr = if ar > br { ar - br } else { br - ar }
  let dg = if ag > bg { ag - bg } else { bg - ag }
  let db = if ab > bb { ab - bb } else { bb - ab }
  let da = if aa > ba { aa - ba } else { ba - aa }
  dr <= tol && dg <= tol && db <= tol && da <= tol
}

///|
test "porter-duff source-over matches expected alpha blending" {
  // Opaque source over opaque backdrop: result = source.
  let r = porter_duff_composite(
    SourceOver,
    (1.0, 0.0, 0.0), 1.0,
    (0.0, 0.0, 1.0), 1.0,
  )
  inspect(approx4(r, (1.0, 0.0, 0.0, 1.0)), content="true")
}

///|
test "porter-duff clear removes everything" {
  let r = porter_duff_composite(
    Clear,
    (1.0, 0.0, 0.0), 1.0,
    (0.0, 0.0, 1.0), 1.0,
  )
  inspect(approx4(r, (0.0, 0.0, 0.0, 0.0)), content="true")
}

///|
test "porter-duff source keeps only source" {
  let r = porter_duff_composite(
    Source,
    (0.5, 0.5, 0.5), 0.8,
    (1.0, 0.0, 0.0), 1.0,
  )
  inspect(approx4(r, (0.5, 0.5, 0.5, 0.8)), content="true")
}

///|
test "porter-duff destination keeps only backdrop" {
  let r = porter_duff_composite(
    Destination,
    (0.5, 0.5, 0.5), 0.8,
    (1.0, 0.0, 0.0), 0.6,
  )
  inspect(approx4(r, (1.0, 0.0, 0.0, 0.6)), content="true")
}

///|
test "porter-duff source-in only where overlap" {
  // Source alpha 0.5, dest alpha 0.8: result alpha = 0.5*0.8 = 0.4
  let r = porter_duff_composite(
    SourceIn,
    (1.0, 0.0, 0.0), 0.5,
    (0.0, 0.0, 1.0), 0.8,
  )
  // Fa = dst_a = 0.8, Fb = 0 → αr = 0.5*0.8 = 0.4
  inspect(approx4(r, (1.0, 0.0, 0.0, 0.4)), content="true")
}

///|
test "porter-duff source-out only where no backdrop" {
  // Fa = 1 - dst_a, Fb = 0
  let r = porter_duff_composite(
    SourceOut,
    (1.0, 0.0, 0.0), 0.5,
    (0.0, 0.0, 1.0), 0.8,
  )
  // αr = 0.5 * (1 - 0.8) = 0.5 * 0.2 = 0.1
  inspect(approx4(r, (1.0, 0.0, 0.0, 0.1)), content="true")
}

///|
test "porter-duff xor shows source where no backdrop and vice versa" {
  let r = porter_duff_composite(
    Xor,
    (1.0, 0.0, 0.0), 0.5,
    (0.0, 0.0, 1.0), 0.8,
  )
  // Fa = 1 - 0.8 = 0.2, Fb = 1 - 0.5 = 0.5
  // αr = 0.5*0.2 + 0.8*0.5 = 0.1 + 0.4 = 0.5
  // Cr = (0.5*0.2*1 + 0.8*0.5*0) / 0.5 = 0.1/0.5 = 0.2
  inspect(approx4(r, (0.2, 0.0, 0.8, 0.5)), content="true")
}

///|
test "porter-duff source-atop composites correctly" {
  // Fa = dst_a = 0.8, Fb = 1 - src_a = 0.5
  // αr = 0.5*0.8 + 0.8*0.5 = 0.4 + 0.4 = 0.8
  let r = porter_duff_composite(
    SourceAtop,
    (1.0, 0.0, 0.0), 0.5,
    (0.0, 0.0, 1.0), 0.8,
  )
  // Cr = (0.5*0.8*1 + 0.8*0.5*0) / 0.8 = 0.4/0.8 = 0.5
  // Cg = 0, Cb = (0 + 0.8*0.5*1) / 0.8 = 0.4/0.8 = 0.5
  inspect(approx4(r, (0.5, 0.0, 0.5, 0.8)), content="true")
}

///|
test "porter-duff handles zero alpha source" {
  // Source fully transparent: SourceOver should show only backdrop.
  let r = porter_duff_composite(
    SourceOver,
    (1.0, 0.0, 0.0), 0.0,
    (0.0, 0.0, 1.0), 0.8,
  )
  inspect(approx4(r, (0.0, 0.0, 1.0, 0.8)), content="true")
}

///|
test "porter-duff handles both fully transparent" {
  let r = porter_duff_composite(
    SourceOver,
    (1.0, 0.0, 0.0), 0.0,
    (0.0, 0.0, 1.0), 0.0,
  )
  inspect(approx4(r, (0.0, 0.0, 0.0, 0.0)), content="true")
}

///|
test "porter-duff destination-over is correct" {
  // Destination-over: Fa = 1 - dst_a = 0.2, Fb = 1
  // Fa = 1 - dst_a = 0.2, Fb = 1
  // αr = 0.5*0.2 + 0.8*1 = 0.1 + 0.8 = 0.9
  // Cr = (0.5*0.2*1 + 0.8*1*0) / 0.9 = 0.1/0.9 ≈ 0.1111
  // Cb = (0.5*0.2*0 + 0.8*1*1) / 0.9 = 0.8/0.9 ≈ 0.8889
  let r = porter_duff_composite(
    DestinationOver,
    (1.0, 0.0, 0.0), 0.5,
    (0.0, 0.0, 1.0), 0.8,
  )
  inspect(approx4(r, (0.1 / 0.9, 0.0, 0.8 / 0.9, 0.9)), content="true")
}

///|
test "porter-duff all operators produce valid alpha 0..1" {
  let ops = [Clear, Source, Destination, SourceOver, DestinationOver, SourceIn, DestinationIn, SourceOut, DestinationOut, SourceAtop, DestinationAtop, Xor]
  for op in ops {
    let (_, _, _, a) = porter_duff_composite(op, (0.5, 0.3, 0.7), 0.6, (0.2, 0.8, 0.4), 0.4)
    inspect(a >= 0.0, content="true")
    inspect(a <= 1.0, content="true")
  }
}
