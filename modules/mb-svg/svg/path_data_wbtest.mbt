// White-box tests for SVG path data parsing.

///|
test "parse_path_data M L L Z" {
  match parse_path_data("M 0 0 L 10 0 L 10 10 Z") {
    Ok(p) => {
      let path2 = p.to_path2()
      // M + L + L + Z = 4 commands.
      inspect(path2.length(), content="4")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data implicit L repeat" {
  // "L 1 1 2 2" = two line-to operations.
  match parse_path_data("M 0 0 L 1 1 2 2") {
    Ok(p) => inspect(p.to_path2().length(), content="3") // M + L + L
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data relative m l" {
  // Relative move and line: m 10 20 l 5 5 → absolute (10,20) then (15,25).
  match parse_path_data("m 10 20 l 5 5") {
    Ok(_) => inspect(true, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data H V commands" {
  match parse_path_data("M 0 0 H 10 V 10 Z") {
    Ok(p) => inspect(p.to_path2().length(), content="4") // M + H(line) + V(line) + Z
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data cubic bezier C" {
  match parse_path_data("M 0 0 C 1 1 2 2 3 3") {
    Ok(p) => inspect(p.to_path2().length(), content="2") // M + C
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data quadratic Q" {
  match parse_path_data("M 0 0 Q 1 1 2 2") {
    Ok(p) => inspect(p.to_path2().length(), content="2") // M + Q
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data comma-separated args" {
  match parse_path_data("M0,0L10,0L10,10Z") {
    Ok(p) => inspect(p.to_path2().length(), content="4")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data accepts compact sign-separated coordinates" {
  match parse_path_data("M0-10L5-3") {
    Ok(path) =>
      match (path.to_path2().get(0), path.to_path2().get(1)) {
        (Some(@math.PathCommand::MoveTo(start)), Some(@math.PathCommand::LineTo(end))) => {
          inspect((start.x(), start.y(), end.x(), end.y()), content="(0, -10, 5, -3)")
        }
        _ => inspect(false, content="true")
      }
    Err(_) => inspect(false, content="true")
  }
  // The minus following e remains part of the exponent; the next minus starts
  // the y coordinate without requiring comma or whitespace.
  match parse_path_data("M1e-3-2") {
    Ok(path) =>
      match path.to_path2().get(0) {
        Some(@math.PathCommand::MoveTo(point)) =>
          inspect((point.x() - 0.001).abs() < 1.0e-12 && point.y() == -2.0, content="true")
        _ => inspect(false, content="true")
      }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_path_data arc approximated as line" {
  // A command with 7 params; v0.1 approximates as line-to the endpoint.
  match parse_path_data("M 0 0 A 5 5 0 0 1 10 0") {
    Ok(p) => inspect(p.to_path2().length(), content="2") // M + A(line)
    Err(_) => inspect(false, content="true")
  }
}

///|
fn direct_relative_path_cases() -> Array[(String, String, Int, (Double, Double, Double, Double, Double, Double))] {
  [
    // A second relative move proves that `m` composes with its current point.
    ("m", "m 65535 65535 m 1 1", 1, (65536.0, 65536.0, 0.0, 0.0, 0.0, 0.0)),
    ("l", "M 65535 65535 l 1 1", 1, (65536.0, 65536.0, 0.0, 0.0, 0.0, 0.0)),
    ("h", "M 65535 65535 h 1", 1, (65536.0, 65535.0, 0.0, 0.0, 0.0, 0.0)),
    ("v", "M 65535 65535 v 1", 1, (65535.0, 65536.0, 0.0, 0.0, 0.0, 0.0)),
    ("c", "M 65535 65535 c 1 0 0 1 1 1", 1, (65536.0, 65535.0, 65535.0, 65536.0, 65536.0, 65536.0)),
    ("q", "M 65535 65535 q 1 0 1 1", 1, (65536.0, 65535.0, 65536.0, 65536.0, 0.0, 0.0)),
    // `a` is currently represented by its relative endpoint as a line segment.
    ("a", "M 65535 65535 a 1 2 3 0 1 1 1", 1, (65536.0, 65536.0, 0.0, 0.0, 0.0, 0.0)),
  ]
}

///|
fn direct_relative_case_matches(
  route : String,
  data : String,
  command_index : Int,
  expected : (Double, Double, Double, Double, Double, Double),
) -> Bool {
  let (x1, y1, x2, y2, x3, y3) = expected
  match parse_path_data(data) {
    Ok(path) =>
      match path.to_path2().get(command_index) {
        Some(@math.PathCommand::MoveTo(point)) =>
          route == "m" && point.x() == x1 && point.y() == y1
        Some(@math.PathCommand::LineTo(point)) =>
          (route == "l" || route == "h" || route == "v" || route == "a") &&
          point.x() == x1 && point.y() == y1
        Some(@math.PathCommand::CubicTo(cp1, cp2, endpoint)) =>
          route == "c" &&
          cp1.x() == x1 && cp1.y() == y1 &&
          cp2.x() == x2 && cp2.y() == y2 &&
          endpoint.x() == x3 && endpoint.y() == y3
        Some(@math.PathCommand::QuadTo(control, endpoint)) =>
          route == "q" &&
          control.x() == x1 && control.y() == y1 &&
          endpoint.x() == x2 && endpoint.y() == y2
        _ => false
      }
    Err(_) => false
  }
}

///|
test "numeric contract: supported direct path routes" {
  // SVG-NUM-PATH: M/L/H/V/C/Q/A source arguments remain passing evidence.
  // Smooth S/s and T/t argument admission, reflected-control derivation, and
  // relative smooth-coordinate results are unsupported pending Phase 92 parser
  // normalization; this tracer makes no coverage claim for those routes.
  match parse_path_data("M -65536 -65536 L 65536 -65536 H 65536 V 65536 C 1 2 3 4 5 6 Q 7 8 9 10 A 17 18 0 0 1 65536 65536 Z") {
    Ok(path) => inspect(path.to_path2().length(), content="8")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "numeric contract: every direct relative path route" {
  // SVG-NUM-RELATIVE: each currently supported direct relative family reaches
  // or leaves the inclusive boundary through its endpoint and, for curves,
  // every emitted control point. Smooth S/s and T/t remain intentionally
  // outside this Phase 91 public numeric-admission contract pending Phase 92.
  let cases = direct_relative_path_cases()
  let mut failures = 0
  for case in cases {
    let (route, data, command_index, expected) = case
    if !direct_relative_case_matches(route, data, command_index, expected) {
      println("direct relative path route failed: " + route)
      failures = failures + 1
    }
  }
  inspect(failures, content="0")
  inspect(cases.length(), content="7")
}

///|
test "path numeric admission rejects malformed and unsafe command groups" {
  let cases = [
    "M 0 nope",
    "M 0,,0",
    "M 0 0 L 1e999 0",
    "M 65536 0 l 1 0",
    "M 0 0 A 1 1 0 0 1 65536 0 a 1 1 0 0 1 1 0",
    "M 0 0 C 1 2 3 4 5",
    "M 0 0 S 1 2 3",
    "M 0 0 T 1",
  ]
  let mut accepted = 0
  for data in cases {
    match parse_path_data(data) {
      Ok(_) => accepted = accepted + 1
      Err(_) => ()
    }
  }
  inspect(accepted, content="0")
}

///|
test "path smooth commands use exact arity and compatible reflection" {
  match parse_path_data("M 10 10 C 11 12 13 14 15 16 S 17 18 19 20 Q 21 22 23 24 T 25 26") {
    Ok(path) => {
      let commands = path.to_path2()
      inspect(commands.length(), content="5")
      match (commands.get(2), commands.get(4)) {
        (Some(@math.PathCommand::CubicTo(cp1, cp2, endpoint)), Some(@math.PathCommand::QuadTo(control, quad_endpoint))) => {
          inspect((cp1.x(), cp1.y(), cp2.x(), cp2.y(), endpoint.x(), endpoint.y()), content="(17, 18, 17, 18, 19, 20)")
          inspect((control.x(), control.y(), quad_endpoint.x(), quad_endpoint.y()), content="(25, 26, 25, 26)")
        }
        _ => inspect(false, content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "path close restores subpath current point and clears reflections" {
  match parse_path_data("M 0 0 L 10 0 Z l 5 0") {
    Ok(path) =>
      match path.to_path2().get(3) {
        Some(@math.PathCommand::LineTo(endpoint)) => inspect((endpoint.x(), endpoint.y()), content="(5, 0)")
        _ => inspect(false, content="true")
      }
    Err(_) => inspect(false, content="true")
  }
  match parse_path_data("M 0 0 C 1 0 2 0 3 0 Z s 1 0 2 0") {
    Ok(path) =>
      match path.to_path2().get(3) {
        Some(@math.PathCommand::CubicTo(cp1, cp2, endpoint)) => {
          inspect((cp1.x(), cp1.y(), cp2.x(), cp2.y(), endpoint.x(), endpoint.y()), content="(0, 0, 1, 0, 2, 0)")
        }
        _ => inspect(false, content="true")
      }
    Err(_) => inspect(false, content="true")
  }
}
