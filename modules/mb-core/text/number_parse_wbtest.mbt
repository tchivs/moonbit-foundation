// White-box tests for number parsing.

///|
test "parse_int handles positive and negative integers" {
  inspect(parse_int("42").unwrap(), content="42")
  inspect(parse_int("-7").unwrap(), content="-7")
  inspect(parse_int("+13").unwrap(), content="13")
  inspect(parse_int("0").unwrap(), content="0")
}

///|
test "parse_int trims whitespace" {
  inspect(parse_int("  42  ").unwrap(), content="42")
  inspect(parse_int("\t-5\n").unwrap(), content="-5")
}

///|
test "parse_int rejects non-digits and empty" {
  match parse_int("") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-parse-int-empty"), content="true")
  }
  match parse_int("abc") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-parse-int-invalid-character"), content="true")
  }
  match parse_int("12x") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
  match parse_int("-") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-parse-int-sign-only"), content="true")
  }
}

///|
test "parse_double handles decimal numbers" {
  let r = parse_double("3.14").unwrap()
  inspect(r > 3.13 && r < 3.15, content="true")
  let r2 = parse_double("-0.5").unwrap()
  inspect(r2 > -0.51 && r2 < -0.49, content="true")
  let r3 = parse_double("42").unwrap()
  inspect(r3 == 42.0, content="true")
  let r4 = parse_double(".5").unwrap()
  inspect(r4 == 0.5, content="true")
}

///|
test "parse_double handles exponents" {
  let r = parse_double("1e3").unwrap()
  inspect(r == 1000.0, content="true")
  let r2 = parse_double("2.5e-2").unwrap()
  inspect(r2 == 0.025, content="true")
  let r3 = parse_double("-1E5").unwrap()
  inspect(r3 == -100000.0, content="true")
}

///|
test "parse_double trims whitespace" {
  let r = parse_double("  3.14  ").unwrap()
  inspect(r > 3.13 && r < 3.15, content="true")
}

///|
test "parse_double rejects malformed input" {
  match parse_double("") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-parse-double-empty"), content="true")
  }
  match parse_double(".") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-parse-double-no-digits"), content="true")
  }
  match parse_double("3.14.15") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
  match parse_double("3e") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}

///|
test "parse_int rejects overflow" {
  match parse_int("2147483648") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.code() is @error.ErrorCode::ArithmeticOverflow, content="true")
  }
}
