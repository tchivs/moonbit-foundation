// Numeric-admission policy tracer. Phase 91 deliberately exercises only the
// documented valid boundary; Phase 92 owns rejection assertions.

///|
test "numeric contract tracer: inclusive boundary parses and lowers" {
  let cases = [
    (
      "inclusive-boundary-with-finite-singular-transform",
      "<svg><g transform=\"scale(0)\"><rect x=\"65536\" y=\"-65536\" width=\"1\" height=\"1\"/></g></svg>",
    ),
  ]
  let mut failures = 0
  for case in cases {
    let (id, source) = case
    match parse_svg(source) {
      Err(_) => {
        println("numeric contract parse failed: " + id)
        failures = failures + 1
      }
      Ok(scene) => {
        let list = lower_to_drawing_list(scene)
        if list.length() == 0 {
          println("numeric contract lowering produced no operations: " + id)
          failures = failures + 1
        }
      }
    }
  }
  inspect(failures, content="0")
  inspect(cases.length() > 0, content="true")
}
