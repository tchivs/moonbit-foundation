// Numeric-admission policy tracer. The public suite owns rejection assertions;
// this package-local control keeps successful parse-to-lower behavior explicit.

///|
test "numeric contract tracer: inclusive boundary and scale zero parse and lower" {
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

///|
test "numeric contract: omitted defaults and nested opacity remain lowerable" {
  match parse_svg("<svg><g transform=\"scale(0)\" opacity=\"0.5\"><rect/></g></svg>") {
    Err(_) => inspect(false, content="true")
    Ok(scene) => {
      // Parser-produced scenes are validated before the unchanged total lowerer.
      let list = lower_to_drawing_list(scene)
      inspect(list.length(), content="5")
    }
  }
}
