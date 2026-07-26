// White-box tests for quantitative parse bounds (RFC 0002 §8 "Bounded input").
// Each case builds a tight budget and verifies parse_svg_with_budget /
// parse_path_data_with_budget reject inputs that exceed the depth or work
// ceilings, while the default parse_svg accepts reasonable inputs.

// A budget with tight limits for exercising the bounds. depth=3, work=20.

///|
fn bounded_budget(
  bytes : UInt64,
  depth : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=4096UL,
      allocation_size=1048576UL,
      width=256UL,
      height=256UL,
      pixels=0UL,
      depth~,
      work~,
    ),
  )
}

///|
fn tight_budget(depth : UInt64, work : UInt64) -> @budget.Budget {
  bounded_budget(1048576UL, depth, work)
}

// Build a deeply nested SVG: <svg><g>...<g><rect/></g>...</g></svg> with
// `levels` nested <g> elements.

///|
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

// Build a deeply nested document using supported nested <svg> elements.

///|
fn nested_supported_svg(levels : Int) -> String {
  let s = StringBuilder::new()
  s.write_string("<svg>")
  for i = 0; i < levels; i = i + 1 {
    s.write_string("<svg>")
  }
  s.write_string("<rect width=\"1\" height=\"1\"/>")
  for i = 0; i < levels; i = i + 1 {
    s.write_string("</svg>")
  }
  s.write_string("</svg>")
  s.to_string()
}

///|
fn assert_svg_budget_error(
  result : Result[SceneNode, @error.CoreError],
) -> Unit raise {
  match result {
    Ok(_) => inspect(false, content="true")
    Err(error) => {
      inspect(error.operation() == Some("svg"), content="true")
      match error.context() {
        Some(context) =>
          inspect(context.has_prefix("svg-budget:"), content="true")
        None => inspect(false, content="true")
      }
    }
  }
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
test "bounds: nested supported svg consumes the depth lease" {
  // The root does not consume a lease; five non-empty nested <svg> elements
  // must still exceed depth=3 before recursive scene construction continues.
  assert_svg_budget_error(
    parse_svg_with_budget(nested_supported_svg(5), tight_budget(3UL, 1000UL)),
  )
}

///|
test "bounds: shallow nested supported svg releases the depth lease" {
  match
    parse_svg_with_budget(nested_supported_svg(2), tight_budget(3UL, 1000UL)) {
    Ok(Svg(_, children)) => inspect(children.length(), content="1")
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(false, content="true")
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
test "bounds: oversized source fails before markup tokenization" {
  // This is many valid tags, so a late work-limit check would first construct
  // the full token array. The byte admission check rejects it while leaving
  // work untouched, before normal scene construction can begin.
  let s = StringBuilder::new()
  s.write_string("<svg>")
  for i = 0; i < 30; i = i + 1 {
    s.write_string("<rect width=\"1\" height=\"1\"/>")
  }
  s.write_string("</svg>")
  let budget = bounded_budget(256UL, 64UL, 1000UL)
  let result = parse_svg_with_budget(s.to_string(), budget)
  assert_svg_budget_error(result)
  inspect(budget.remaining().work(), content="1000")
}

///|
test "bounds: small document passes under adequate work budget" {
  match
    parse_svg_with_budget(
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
test "bounds: direct path source admission rejects oversized input and accepts its boundary" {
  // `source` is exactly nine portable code units. A smaller byte budget must
  // fail before command parsing consumes work; the inclusive boundary remains
  // valid for a normal direct path parse.
  let source = "M0 0 L1 1"
  let oversized_budget = bounded_budget(8UL, 64UL, 1000UL)
  match parse_path_data_with_budget(source, oversized_budget) {
    Ok(_) => inspect(false, content="true")
    Err(error) => {
      inspect(error.operation() == Some("svg"), content="true")
      match error.context() {
        Some(context) =>
          inspect(context.has_prefix("svg-budget:"), content="true")
        None => inspect(false, content="true")
      }
    }
  }
  inspect(oversized_budget.remaining().work(), content="1000")
  match parse_path_data_with_budget(source, bounded_budget(9UL, 64UL, 1000UL)) {
    Ok(_) => inspect(true, content="true")
    Err(_) => inspect(false, content="true")
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
