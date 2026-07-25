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
test "parse_path_data arc approximated as line" {
  // A command with 7 params; v0.1 approximates as line-to the endpoint.
  match parse_path_data("M 0 0 A 5 5 0 0 1 10 0") {
    Ok(p) => inspect(p.to_path2().length(), content="2") // M + A(line)
    Err(_) => inspect(false, content="true")
  }
}

///|
test "numeric contract: path source and relative controls" {
  // SVG-NUM-PATH: direct-command finite source controls remain passing evidence.
  // Smooth cubic `S` is intentionally excluded until Phase 92 corrects its
  // parameter consumption and verifies its emitted controls and endpoint.
  match parse_path_data("M -65536 -65536 L 65536 -65536 H 65536 V 65536 C 1 2 3 4 5 6 Q 7 8 9 10 A 17 18 0 0 1 65536 65536 Z") {
    Ok(path) => inspect(path.to_path2().length(), content="8")
    Err(_) => inspect(false, content="true")
  }
  // SVG-NUM-RELATIVE: finite relative arithmetic reaches the inclusive boundary.
  match parse_path_data("m 65535 65535 l 1 1") {
    Ok(path) =>
      match path.to_path2().get(1) {
        Some(@math.PathCommand::LineTo(point)) =>
          inspect((point.x(), point.y()), content="(65536, 65536)")
        _ => inspect(false, content="true")
      }
    Err(_) => inspect(false, content="true")
  }
}
