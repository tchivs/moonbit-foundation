// White-box tests for quantitative parse bounds (RFC 0002 §8 "Bounded input").
// Each case builds a tight budget and verifies parse_svg_with_budget /
// parse_path_data_with_budget reject inputs that exceed the depth or work
// ceilings, while the default parse_svg accepts reasonable inputs.

// A budget with tight limits for exercising the bounds. depth=3, work=20.
fn tight_budget(depth : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL,
    allocations=4096UL,
    allocation_size=1048576UL,
    width=256UL,
    height=256UL,
    pixels=0UL,
    depth~,
    work~,
  ))
}

// Build a deeply nested SVG: <svg><g>...<g><rect/></g>...</g></svg> with
// `levels` nested <g> elements.
fn nested_svg(levels : Int) -> String {
  let s = StringBuilder::new()
  s.write_string("<svg>")
  for i = 0; i < levels; i = i + 1 {
    s.write_string("<g>")
  }
  s.write_string("<rect width=\"1\" height=\"1\"/>")
  for i = 0; i < levels; i = i + 1 {
    s.write_string("</g>")
  }
  s.write_string("</svg>")
  s.to_string()
}

///|
test "bounds: nesting depth limit rejects deeply nested groups" {
  // 5 nested <g> under a depth=3 budget → exceeds the depth ceiling.
  match parse_svg_with_budget(nested_svg(5), tight_budget(3UL, 1000UL)) {
    Ok(_) => inspect("ok", content="err")
    Err(_) => inspect("err", content="err")
  }
}

///|
test "bounds: shallow nesting passes under adequate depth budget" {
  // 2 nested <g> under depth=3 → fits.
  match parse_svg_with_budget(nested_svg(2), tight_budget(3UL, 1000UL)) {
    Ok(_) => inspect("ok", content="ok")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "bounds: work/token limit rejects a large document" {
  // A document with many tokens under work=20 should be rejected.
  let s = StringBuilder::new()
  s.write_string("<svg>")
  for i = 0; i < 30; i = i + 1 {
    s.write_string("<rect width=\"1\" height=\"1\"/>")
  }
  s.write_string("</svg>")
  match parse_svg_with_budget(s.to_string(), tight_budget(64UL, 20UL)) {
    Ok(_) => inspect("ok", content="err")
    Err(_) => inspect("err", content="err")
  }
}

///|
test "bounds: small document passes under adequate work budget" {
  match parse_svg_with_budget(
    "<svg><rect width=\"1\" height=\"1\"/></svg>",
    tight_budget(64UL, 1000UL),
  ) {
    Ok(_) => inspect("ok", content="ok")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "bounds: path command limit rejects a pathological d" {
  // Many line-to pairs under work=10 → rejected.
  let s = StringBuilder::new()
  s.write_string("M0 0")
  for i = 0; i < 50; i = i + 1 {
    s.write_string(" L")
    s.write_string(i.to_string())
    s.write_string(" ")
    s.write_string(i.to_string())
  }
  match parse_path_data_with_budget(s.to_string(), tight_budget(64UL, 10UL)) {
    Ok(_) => inspect("ok", content="err")
    Err(_) => inspect("err", content="err")
  }
}

///|
test "bounds: default parse_svg accepts normal nested documents" {
  // The default budget must not reject reasonable inputs. 20 nested groups
  // and several shapes — well within the default depth=64 / work=2,000,000.
  match parse_svg(nested_svg(20)) {
    Ok(_) => inspect("ok", content="ok")
    Err(_) => inspect("err", content="ok")
  }
}

///|
test "bounds: default parse_path_data accepts a normal path" {
  match parse_path_data("M0 0 L1 1 L2 2 L3 3 Z") {
    Ok(_) => inspect("ok", content="ok")
    Err(_) => inspect("err", content="ok")
  }
}
