// White-box tests for string splitting and trimming.

///|
test "split_on splits by single delimiter skipping empties" {
  let r = split_on("a,b,c", 0x2c)
  inspect(r.length(), content="3")
  inspect(r[0] == "a", content="true")
  inspect(r[2] == "c", content="true")
  // Consecutive delimiters.
  let r2 = split_on("a,,b", 0x2c)
  inspect(r2.length(), content="2")
  inspect(r2[0] == "a", content="true")
}

///|
test "split_on handles no delimiter found" {
  let r = split_on("hello", 0x2c)
  inspect(r.length(), content="1")
  inspect(r[0] == "hello", content="true")
}

///|
test "split_any splits by multiple delimiters" {
  // "0,0 10,0" with comma and space.
  let r = split_any("0,0 10,0", [0x2c, 0x20])
  inspect(r.length(), content="4")
  inspect(r[0] == "0", content="true")
  inspect(r[3] == "0", content="true")
}

///|
test "split_whitespace splits on all whitespace" {
  let r = split_whitespace("  hello\tworld\n ")
  inspect(r.length(), content="2")
  inspect(r[0] == "hello", content="true")
  inspect(r[1] == "world", content="true")
}

///|
test "trim removes leading and trailing whitespace" {
  inspect(trim("  hello  ") == "hello", content="true")
  inspect(trim("\tworld\n") == "world", content="true")
  inspect(trim("no trim") == "no trim", content="true")
  inspect(trim("   ") == "", content="true")
  inspect(trim("") == "", content="true")
}

///|
test "split_on empty string returns empty array" {
  let r = split_on("", 0x2c)
  inspect(r.length(), content="0")
}

///|
test "split_whitespace on SVG path numbers" {
  let r = split_whitespace("1.5 2.0 -3e2 0")
  inspect(r.length(), content="4")
  // Verify parseable as doubles.
  inspect(parse_double(r[0]).unwrap() == 1.5, content="true")
  inspect(parse_double(r[2]).unwrap() == -300.0, content="true")
}

///|
test "split_any handles trailing delimiters" {
  let r = split_any("a,b,", [0x2c])
  inspect(r.length(), content="2")
  inspect(r[1] == "b", content="true")
}
