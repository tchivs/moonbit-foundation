// Public SVG parser contract tests. These use only exported parser, lowerer,
// and CoreError accessors so callers can rely on the same fail-closed result.

///|
fn assert_public_numeric_error(
  result : Result[SceneNode, @error.CoreError],
  code : @error.ErrorCode,
  context : String,
) -> Unit raise {
  match result {
    Ok(_) => inspect(false, content="true")
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
      inspect(error.code() == code, content="true")
      inspect(error.operation() == Some("svg"), content="true")
      inspect(error.context() == Some(context), content="true")
    }
  }
}

///|
test "public parse rejects numeric input before a scene exists" {
  let cases = [
    (
      "malformed-root-width",
      "<svg width=\"not-a-number\"/>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "nonfinite-geometry",
      "<svg><rect x=\"1e999\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-nonfinite",
    ),
    (
      "out-of-range-viewbox",
      "<svg viewBox=\"0 0 65537 1\"/>",
      @error.ErrorCode::InvalidRange,
      "svg-numeric-range",
    ),
  ]
  for case in cases {
    let (_, source, code, context) = case
    // Err is the proof that no SceneNode exists, so lowering is impossible.
    assert_public_numeric_error(parse_svg(source), code, context)
  }
}

///|
test "public parse keeps finite boundary and singular transform drawable" {
  match
    parse_svg(
      "<svg width=\"65536\" height=\"65536\"><g transform=\"scale(0)\"><rect x=\"65536\" y=\"-65536\" width=\"1\" height=\"1\"/></g></svg>",
    ) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      inspect(list.length() > 0, content="true")
    }
  }
}

///|
test "public parse and lower retain compact supported SVG geometry" {
  // This intentionally uses only exported parser/lowerer APIs. It combines
  // root viewBox mapping, finite scale(0), omitted defaults, and all supported
  // shape/path families so consumers retain one usable DrawingList contract.
  let source = "<svg viewBox=\"0 0 4 2\" width=\"8\" height=\"8\"><g transform=\"scale(0)\"><rect width=\"1\" height=\"1\"/><circle r=\"1\"/><ellipse rx=\"1\" ry=\"0.5\"/><line x2=\"1\" y2=\"1\"/><polyline points=\"0,0 1,1\"/><polygon points=\"0,0 1,0 1,1\"/><path d=\"M0 0 L1 1 Z\"/></g></svg>"
  match parse_svg(source) {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      let list = lower_to_drawing_list(scene)
      // Root map, group transform, seven shapes, group pop, root pop.
      inspect(list.length(), content="11")
      match (list.get(0), list.get(1), list.get(9), list.get(10)) {
        (
          Some(PushTransform(root_map)),
          Some(PushTransform(scale)),
          Some(PopTransform),
          Some(PopTransform),
        ) => {
          assert_eq(
            (root_map.a(), root_map.d(), root_map.ty()),
            (2.0, 2.0, 2.0),
          )
          assert_eq((scale.a(), scale.d()), (0.0, 0.0))
        }
        _ => inspect(false, content="true")
      }
      for index = 2; index < 9; index = index + 1 {
        match list.get(index) {
          Some(Fill(_, _)) => ()
          _ => inspect(false, content="true")
        }
      }
    }
  }
}

///|
test "public parse rejects explicit paint scalar routes before a scene exists" {
  let cases = [
    (
      "<svg><rect fill=\"#ggg\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect stroke=\"#12\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect color=\"#12\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect opacity=\"bad\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect stroke-dasharray=\"1,1e999\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-nonfinite",
    ),
    (
      "<svg><rect fill=\"rgb(65537,0,0)\"/></svg>",
      @error.ErrorCode::InvalidRange,
      "svg-numeric-range",
    ),
    (
      "<svg><rect fill=\"hsl(0,65537%,0%)\"/></svg>",
      @error.ErrorCode::InvalidRange,
      "svg-numeric-range",
    ),
    (
      "<svg><rect fill=\"rgb(1,2)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect stroke=\"hsl(1,2%)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect color=\"rgb(1,2)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect fill=\"rgb(1,2,3,garbage)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect fill=\"hsl(1,2%,3%,garbage)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect fill=\"rgb(0,1%%,0)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect fill=\"rgb(0,1%2,0)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
    (
      "<svg><rect fill=\"hsl(0,1,0%)\"/></svg>",
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ),
  ]
  for case in cases {
    let (source, code, context) = case
    assert_public_numeric_error(parse_svg(source), code, context)
  }
}

///|
test "public parse rejects malformed numeric-list commas before a scene exists" {
  let cases = [
    "<svg viewBox=\"0,,0,1,1\"/>", "<svg><g transform=\"translate(1,,2)\"/></svg>",
    "<svg><rect stroke-dasharray=\"1,,2\"/></svg>", "<svg><path d=\"M0,,0\"/></svg>",
  ]
  for source in cases {
    assert_public_numeric_error(
      parse_svg(source),
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    )
  }
}

///|
test "public parse rejects scalars after path close before a scene exists" {
  for
    source in [
      "<svg><path d=\"M0 0 Z 1 1\"/></svg>", "<svg><path d=\"M0 0 Z,1\"/></svg>",
    ] {
    assert_public_numeric_error(
      parse_svg(source),
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    )
  }
}

///|
test "public parse rejects unsafe group transforms before a group exists" {
  assert_public_numeric_error(
    parse_svg(
      "<svg><g transform=\"scale(65536) scale(2)\"><rect width=\"1\" height=\"1\"/></g></svg>",
    ),
    @error.ErrorCode::InvalidRange,
    "svg-numeric-derived",
  )
  assert_public_numeric_error(
    parse_svg(
      "<svg><g transform=\"translate(1,2,3)\"><rect width=\"1\" height=\"1\"/></g></svg>",
    ),
    @error.ErrorCode::InvalidEncoding,
    "svg-numeric-source",
  )
}

///|
test "public parse rejects unsafe derived geometry before lowering" {
  let cases = [
    // viewBox translation is -min_x * scale = 131072.
    (
      "viewbox-root-map", "<svg viewBox=\"-65536 0 1 1\" width=\"2\" height=\"2\"><rect width=\"1\" height=\"1\"/></svg>",
    ),
    // A source-valid group transform carries this coordinate out of range.
    (
      "group-affine-child", "<svg><g transform=\"translate(65536,0)\"><rect x=\"1\" width=\"1\" height=\"1\"/></g></svg>",
    ),
    // Two valid group transforms overflow when accumulated.
    (
      "nested-group-affine", "<svg><g transform=\"translate(65536,0)\"><g transform=\"translate(1,0)\"><rect width=\"1\" height=\"1\"/></g></g></svg>",
    ),
    // Rounded-rect edge construction calculates x + width = 65537.
    (
      "rounded-rect-edge", "<svg><rect x=\"65536\" width=\"1\" height=\"1\" rx=\"1\"/></svg>",
    ),
    // Circle and ellipse extrema become unsafe before a scene can publish.
    ("circle-extremum", "<svg><circle cx=\"65536\" cy=\"0\" r=\"1\"/></svg>"),
    // Ellipse sampling calculates cx + rx at its first point.
    (
      "ellipse-extremum", "<svg><ellipse cx=\"65536\" cy=\"0\" rx=\"1\" ry=\"1\"/></svg>",
    ),
    // Endpoint and point-list families cross the envelope after a valid affine.
    (
      "line-endpoint", "<svg><g transform=\"translate(1,0)\"><line x1=\"65536\" y1=\"0\" x2=\"0\" y2=\"0\"/></g></svg>",
    ),
    (
      "polyline-point", "<svg><g transform=\"translate(1,0)\"><polyline points=\"65536,0 0,0\"/></g></svg>",
    ),
    (
      "polygon-point", "<svg><g transform=\"translate(1,0)\"><polygon points=\"65536,0 0,0\"/></g></svg>",
    ),
    // Relative CanvasPath commands and transformed post-construction points.
    ("canvas-path-command", "<svg><path d=\"M 65536 0 l 1 0\"/></svg>"),
    (
      "path-point-transform", "<svg><g transform=\"translate(1,0)\"><path d=\"M 65536 0 L 0 0\"/></g></svg>",
    ),
  ]
  for case in cases {
    let (_, source) = case
    // Err establishes that there is no parser-produced SceneNode to lower.
    assert_public_numeric_error(
      parse_svg(source),
      @error.ErrorCode::InvalidRange,
      "svg-numeric-derived",
    )
  }
}
