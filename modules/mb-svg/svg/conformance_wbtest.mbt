// Conformance white-box tests against fixtures/svg/cases.json.
//
// Repository convention: wbtests use INLINE data (no test in the repo reads
// fixtures/*.json at runtime — those JSON files are the normative reference
// with provenance/license metadata in fixtures/manifest.json). The cases here
// mirror fixtures/svg/cases.json's canonical/edge/adversarial cases; the
// comment on each marks its fixture id so the two stay traceable.
//
// Layer split: unit wbtests (scene_wbtest/lower_wbtest) assert internal
// details; this file asserts the black-box conformance boundary —
// parse_svg + lower_to_drawing_list produce Ok and a usable DrawingList for
// valid/edge inputs, and Err for malformed adversarial inputs.

// A canonical/edge case: (fixture_id, svg_source, expect_shape_op). For
// "ok" cases that contain at least one shape, expect_shape_op is true (the
// lowered DrawingList has ≥1 op). For pure-structure "ok" cases (empty svg,
// comment-only, group with no shapes) it is false.
fn ok_cases() -> Array[(String, String, Bool)] {
  [
    // canonical_cases from fixtures/svg/cases.json
    ("empty-svg", "<svg/>", false),
    ("rect-default-fill", "<svg><rect width=\"10\" height=\"10\"/></svg>", true),
    ("rect-fill-named", "<svg><rect width=\"10\" height=\"10\" fill=\"red\"/></svg>", true),
    ("rect-fill-hex", "<svg><rect width=\"10\" height=\"10\" fill=\"#00ff00\"/></svg>", true),
    ("rect-fill-rgb", "<svg><rect width=\"10\" height=\"10\" fill=\"rgb(0,0,255)\"/></svg>", true),
    ("rect-rounded-rx-ry", "<svg><rect width=\"10\" height=\"10\" rx=\"2\" ry=\"2\"/></svg>", true),
    ("circle", "<svg><circle cx=\"5\" cy=\"5\" r=\"4\" fill=\"blue\"/></svg>", true),
    ("ellipse", "<svg><ellipse cx=\"5\" cy=\"5\" rx=\"4\" ry=\"2\"/></svg>", true),
    ("line", "<svg><line x1=\"0\" y1=\"0\" x2=\"10\" y2=\"10\" stroke=\"black\"/></svg>", true),
    ("polyline", "<svg><polyline points=\"0,0 5,5 10,0\"/></svg>", true),
    ("polygon", "<svg><polygon points=\"0,0 10,0 10,10\" fill=\"green\"/></svg>", true),
    ("path-moveto-lineto-close", "<svg><path d=\"M0 0 L5 5 Z\"/></svg>", true),
    ("path-cubic", "<svg><path d=\"M0 0 C1 1 2 2 3 3\"/></svg>", true),
    ("path-quad", "<svg><path d=\"M0 0 Q1 2 3 3\"/></svg>", true),
    (
      "stroke-width-opacity",
      "<svg><rect width=\"10\" height=\"10\" fill=\"red\" stroke=\"blue\" stroke-width=\"2\" fill-opacity=\"0.5\" stroke-opacity=\"0.25\"/></svg>",
      true,
    ),
    (
      "stroke-dasharray-offset",
      "<svg><rect width=\"10\" height=\"10\" stroke=\"black\" stroke-dasharray=\"2 1\" stroke-dashoffset=\"5\"/></svg>",
      true,
    ),
    (
      "stroke-linecap-linejoin",
      "<svg><rect width=\"10\" height=\"10\" stroke=\"black\" stroke-linecap=\"round\" stroke-linejoin=\"bevel\" stroke-miterlimit=\"6\"/></svg>",
      true,
    ),
    (
      "fill-rule-evenodd",
      "<svg><path d=\"M0 0 L10 0 L10 10 Z\" fill-rule=\"evenodd\"/></svg>",
      true,
    ),
    (
      "group-transform",
      "<svg><g transform=\"translate(10,0) scale(2)\"><rect width=\"1\" height=\"1\"/></g></svg>",
      true,
    ),
    (
      "paint-inheritance-fill",
      "<svg><g fill=\"red\"><rect width=\"1\" height=\"1\"/></g></svg>",
      true,
    ),
    (
      "paint-inheritance-currentcolor",
      "<svg><g color=\"blue\"><rect fill=\"currentColor\" width=\"1\" height=\"1\"/></g></svg>",
      true,
    ),
    (
      "nested-groups-inheritance",
      "<svg><g fill=\"red\"><g><rect width=\"1\" height=\"1\"/></g></g></svg>",
      true,
    ),
    (
      "viewbox-mapping",
      "<svg viewBox=\"0 0 100 100\" width=\"200\" height=\"200\"><rect width=\"1\" height=\"1\"/></svg>",
      true,
    ),
    (
      "preserve-aspect-ratio-meet",
      "<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"xMidYMid meet\"><rect width=\"1\" height=\"1\"/></svg>",
      true,
    ),
    (
      "preserve-aspect-ratio-slice",
      "<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"xMidYMid slice\"><rect width=\"1\" height=\"1\"/></svg>",
      true,
    ),
    (
      "preserve-aspect-ratio-none",
      "<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"none\"><rect width=\"1\" height=\"1\"/></svg>",
      true,
    ),
    (
      "rotate-with-center",
      "<svg><g transform=\"rotate(90, 5, 5)\"><rect width=\"1\" height=\"1\"/></g></svg>",
      true,
    ),
    (
      "group-opacity",
      "<svg><g opacity=\"0.5\"><rect width=\"1\" height=\"1\"/></g></svg>",
      true,
    ),
    (
      "element-opacity",
      "<svg><rect width=\"1\" height=\"1\" opacity=\"0.5\"/></svg>",
      true,
    ),
    ("self-closed-vs-paired", "<svg><rect width=\"1\" height=\"1\"></rect></svg>", true),
    (
      "unknown-element-skipped",
      "<svg><defs><linearGradient id=\"g\"/></defs><rect width=\"1\" height=\"1\"/></svg>",
      true,
    ),
    ("comment-ignored", "<svg><!-- note --><rect width=\"1\" height=\"1\"/></svg>", true),
    // edge_cases
    ("root-only-no-children", "<svg></svg>", false),
    ("zero-size-rect", "<svg><rect width=\"0\" height=\"0\"/></svg>", true),
    ("single-point-polyline", "<svg><polyline points=\"0,0\"/></svg>", true),
    ("empty-path-d", "<svg><path d=\"\"/></svg>", true),
    (
      "negative-coordinates",
      "<svg><rect x=\"-5\" y=\"-5\" width=\"10\" height=\"10\"/></svg>",
      true,
    ),
    (
      "viewbox-without-width-height",
      "<svg viewBox=\"0 0 100 100\"><rect width=\"1\" height=\"1\"/></svg>",
      true,
    ),
  ]
}

fn adversarial_cases() -> Array[(String, String)] {
  [
    ("non-svg-root", "<rect/>"),
    ("unquoted-attribute", "<svg><g id=x></g></svg>"),
    ("unterminated-tag", "<svg><rect"),
    ("unterminated-comment", "<svg><!-- oops</svg>"),
    ("bare-less-than", "<"),
    ("path-missing-d", "<svg><path fill=\"red\"/></svg>"),
    ("truncated-attribute-value", "<svg><rect fill=\"red/></svg>"),
  ]
}

///|
test "conformance: every canonical/edge case parses and lowers without error" {
  let cases = ok_cases()
  let mut failures = 0
  for case in cases {
    let (id, svg, expect_shape_op) = case
    match parse_svg(svg) {
      Err(_) => {
        // Surface which fixture id failed for triage.
        println("conformance parse failed: " + id)
        failures = failures + 1
      }
      Ok(scene) => {
        let list = lower_to_drawing_list(scene)
        let has_ops = list.length() > 0
        if has_ops != expect_shape_op {
          println(
            "conformance op-count mismatch: " +
            id +
            " expected_ops=" +
            expect_shape_op.to_string() +
            " got=" +
            has_ops.to_string(),
          )
          failures = failures + 1
        }
      }
    }
  }
  // All cases must pass: zero failures, and the suite is non-empty.
  inspect(failures, content="0")
  inspect(cases.length() > 0, content="true")
}

///|
test "conformance: every adversarial case is rejected" {
  let cases = adversarial_cases()
  let mut failures = 0
  for case in cases {
    let (id, svg) = case
    match parse_svg(svg) {
      Ok(_) => {
        println("conformance should-have-errored: " + id)
        failures = failures + 1
      }
      Err(_) => () // expected
    }
  }
  inspect(failures, content="0")
  inspect(cases.length() > 0, content="true")
}
