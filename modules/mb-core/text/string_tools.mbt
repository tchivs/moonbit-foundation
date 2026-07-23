// String splitting and trimming utilities for MoonBit Native Foundation.
//
// Consumed by SVG path data parsing (comma/space-separated numbers), PDF
// array parsing (whitespace-separated tokens), and font table parsing.
// These are deterministic, allocation-bounded operations that complement
// the existing hex/base64/UTF-8/number-parsing functions.

///|
/// Split a string by a single delimiter character, returning non-empty
/// segments. Consecutive delimiters produce no empty segments.
///
/// Example: `split_on("a,,b,c", ',')` returns `["a", "b", "c"]`.
pub fn split_on(text : String, delimiter : Int) -> Array[String] {
  let units = text.code_units()
  let result : Array[String] = []
  let mut start = 0
  let mut i = 0
  while i < units.length() {
    if units[i].to_int() == delimiter {
      if i > start {
        result.push(substring_from_units(units, start, i))
      }
      start = i + 1
    }
    i = i + 1
  }
  if start < units.length() {
    result.push(substring_from_units(units, start, units.length()))
  }
  result
}

///|
/// Split a string by any of the given delimiter characters (whitespace
/// and/or punctuation), returning non-empty segments.
///
/// Example: `split_any("0,0 10,0", [',', ' '])` returns `["0", "0", "10", "0"]`.
pub fn split_any(text : String, delimiters : Array[Int]) -> Array[String] {
  let units = text.code_units()
  let result : Array[String] = []
  let mut start = -1
  let mut i = 0
  while i < units.length() {
    let c = units[i].to_int()
    if is_delimiter(c, delimiters) {
      if start >= 0 {
        result.push(substring_from_units(units, start, i))
        start = -1
      }
    } else {
      if start < 0 {
        start = i
      }
    }
    i = i + 1
  }
  if start >= 0 {
    result.push(substring_from_units(units, start, units.length()))
  }
  result
}

///|
/// Split a string on whitespace (space, tab, newline), returning non-empty
/// segments. This is equivalent to `split_any` with standard whitespace.
pub fn split_whitespace(text : String) -> Array[String] {
  split_any(text, [0x20, 0x09, 0x0a, 0x0d, 0x0b, 0x0c])
}

///|
/// Trim leading and trailing whitespace from a string.
///
/// Whitespace characters: space (0x20), tab (0x09), newline (0x0a),
/// carriage return (0x0d).
pub fn trim(text : String) -> String {
  let units = text.code_units()
  let len = units.length()
  let mut start = 0
  let mut end = len
  while start < end && is_ws_code(units[start].to_int()) {
    start = start + 1
  }
  while end > start && is_ws_code(units[end - 1].to_int()) {
    end = end - 1
  }
  substring_from_units(units, start, end)
}

///|
fn is_ws_code(c : Int) -> Bool {
  c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d || c == 0x0b || c == 0x0c
}

///|
fn is_delimiter(c : Int, delimiters : Array[Int]) -> Bool {
  for d in delimiters {
    if c == d {
      return true
    }
  }
  false
}

///|
/// Extract a substring from a code_units array view range [start, end).
fn substring_from_units(units : ArrayView[UInt16], start : Int, end : Int) -> String {
  let buffer = StringBuilder::new()
  for i = start; i < end; i = i + 1 {
    ignore(buffer.write_char(units[i].to_int().to_char().unwrap()))
  }
  buffer.to_string()
}
