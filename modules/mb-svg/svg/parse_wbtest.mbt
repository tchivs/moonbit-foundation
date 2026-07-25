// White-box tests for color and length parsing. Results are unwrapped before
// inspect because CoreError does not implement Show.

fn unwrap_rgb(r : Result[(Double, Double, Double), @error.CoreError]) -> (Double, Double, Double) {
  match r {
    Ok(v) => v
    Err(_) => abort("expected Ok")
  }
}

fn approx_eq(a : (Double, Double, Double), b : (Double, Double, Double)) -> Bool {
  let tol = 1.0e-9
  let (a1, a2, a3) = a
  let (b1, b2, b3) = b
  (a1 - b1).abs() < tol && (a2 - b2).abs() < tol && (a3 - b3).abs() < tol
}

///|
test "parse_color named colors" {
  inspect(approx_eq(unwrap_rgb(parse_color("red", None)), (1.0, 0.0, 0.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("blue", None)), (0.0, 0.0, 1.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("white", None)), (1.0, 1.0, 1.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("black", None)), (0.0, 0.0, 0.0)), content="true")
}

///|
test "parse_color hex short and long" {
  inspect(approx_eq(unwrap_rgb(parse_color("#f00", None)), (1.0, 0.0, 0.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("#ff0000", None)), (1.0, 0.0, 0.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("#00ff00", None)), (0.0, 1.0, 0.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("#0000ff", None)), (0.0, 0.0, 1.0)), content="true")
}

///|
test "parse_color rgb decimal" {
  inspect(approx_eq(unwrap_rgb(parse_color("rgb(255,0,0)", None)), (1.0, 0.0, 0.0)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("rgb(0,255,0)", None)), (0.0, 1.0, 0.0)), content="true")
}

///|
test "parse_color currentColor resolves from context" {
  inspect(approx_eq(unwrap_rgb(parse_color("currentColor", Some((0.2, 0.4, 0.6)))), (0.2, 0.4, 0.6)), content="true")
  inspect(approx_eq(unwrap_rgb(parse_color("currentColor", None)), (0.0, 0.0, 0.0)), content="true")
}

///|
test "is_none_color and is_current_color sentinels" {
  inspect(is_none_color("none"), content="true")
  inspect(is_none_color(" none "), content="true")
  inspect(is_none_color("red"), content="false")
  inspect(is_current_color("currentColor"), content="true")
}

///|
test "parse_length plain and unit-suffixed" {
  match parse_length("100") {
    Ok(v) => inspect(v, content="100")
    Err(_) => inspect(false, content="true")
  }
  match parse_length("100px") {
    Ok(v) => inspect(v, content="100")
    Err(_) => inspect(false, content="true")
  }
  match parse_length("50.5pt") {
    Ok(v) => inspect(v, content="50.5")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_viewbox four numbers" {
  match parse_viewbox("0 0 100 100") {
    Ok((x, y, w, h)) => inspect((x, y, w, h), content="(0, 0, 100, 100)")
    Err(_) => inspect(false, content="true")
  }
  match parse_viewbox("10 20 200 150") {
    Ok((x, y, w, h)) => inspect((x, y, w, h), content="(10, 20, 200, 150)")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "parse_number_list space and comma separated" {
  match parse_number_list("1 2 3") {
    Ok(arr) => inspect(arr, content="[1, 2, 3]")
    Err(_) => inspect(false, content="true")
  }
  match parse_number_list("1,2,3") {
    Ok(arr) => inspect(arr, content="[1, 2, 3]")
    Err(_) => inspect(false, content="true")
  }
  match parse_number_list("1.5, 2.5 3.5") {
    Ok(arr) => inspect(arr.length(), content="3")
    Err(e) => {
      let _ = e
      inspect(false, content="true")
    }
  }
}
