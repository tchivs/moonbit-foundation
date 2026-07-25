// Public SVG parser contract tests. These use only exported parser, lowerer,
// and CoreError accessors so callers can rely on the same fail-closed result.

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
  match parse_svg(
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
test "public parse rejects explicit paint scalar routes before a scene exists" {
  let cases = [
    ("<svg><rect opacity=\"bad\"/></svg>", @error.ErrorCode::InvalidEncoding, "svg-numeric-source"),
    ("<svg><rect stroke-dasharray=\"1,1e999\"/></svg>", @error.ErrorCode::InvalidEncoding, "svg-numeric-nonfinite"),
    ("<svg><rect fill=\"rgb(65537,0,0)\"/></svg>", @error.ErrorCode::InvalidRange, "svg-numeric-range"),
    ("<svg><rect fill=\"hsl(0,65537%,0%)\"/></svg>", @error.ErrorCode::InvalidRange, "svg-numeric-range"),
  ]
  for case in cases {
    let (source, code, context) = case
    assert_public_numeric_error(parse_svg(source), code, context)
  }
}

///|
test "public parse rejects unsafe group transforms before a group exists" {
  assert_public_numeric_error(
    parse_svg("<svg><g transform=\"scale(65536) scale(2)\"><rect width=\"1\" height=\"1\"/></g></svg>"),
    @error.ErrorCode::InvalidRange,
    "svg-numeric-derived",
  )
  assert_public_numeric_error(
    parse_svg("<svg><g transform=\"translate(1,2,3)\"><rect width=\"1\" height=\"1\"/></g></svg>"),
    @error.ErrorCode::InvalidEncoding,
    "svg-numeric-source",
  )
}
