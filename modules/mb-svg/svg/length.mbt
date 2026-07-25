// SVG length and numeric parsing: user units, viewBox dimensions.
//
// SVG user units are unitless numbers. Length strings like "100" or "100px" are
// parsed as user-space doubles. Unit suffixes (px/pt/mm/cm/in) are stripped;
// absolute units map 1:1 to user units in v0.1 (a precise DPI-aware mapping is
// a follow-up).

///|
/// Parse an SVG length string into user units. "100" → 100.0, "100px" → 100.0.
/// Percentage lengths are not handled here (caller resolves against a reference).
pub fn parse_length(s : String) -> Result[Double, @error.CoreError] {
  let t = strip_unit_suffix(@text.trim(s).to_string())
  match @text.parse_double(t) {
    Ok(value) => admit_svg_numeric_source(value)
    Err(_) => Err(svg_numeric_error(
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ))
  }
}

// Strip a trailing unit suffix (px/pt/mm/cm/in) if present. Returns the
// numeric portion as a String.
fn strip_unit_suffix(t : String) -> String {
  let suffixes = ["px", "pt", "mm", "cm", "in"]
  for sf in suffixes {
    if t.has_suffix(sf) {
      // Remove the suffix: take everything before it.
      return t.substring(end=t.length() - sf.length())
    }
  }
  t
}

///|
/// Parse a viewBox string "min-x min-y width height" into four doubles.
pub fn parse_viewbox(s : String) -> Result[(Double, Double, Double, Double), @error.CoreError] {
  let nums = parse_number_list(s)
  match nums {
    Err(e) => return Err(e)
    Ok(arr) =>
      if arr.length() != 4 {
        return Err(svg_numeric_error(
          @error.ErrorCode::InvalidEncoding,
          "svg-numeric-source",
        ))
      } else {
        Ok((arr[0], arr[1], arr[2], arr[3]))
      }
  }
}

///|
/// Parse a comma-or-space-separated list of doubles. Returns an array of doubles.
pub fn parse_number_list(s : String) -> Result[Array[Double], @error.CoreError] {
  let chars = s.to_array()
  let nums : Array[Double] = []
  let token : Array[Char] = []
  for c in chars {
    if c == ' ' || c == ',' || c == '\t' || c == '\n' {
      if token.length() > 0 {
        match parse_token(token) {
          Ok(v) => nums.push(v)
          Err(e) => return Err(e)
        }
        token.clear()
      }
    } else {
      token.push(c)
    }
  }
  // Flush trailing token.
  if token.length() > 0 {
    match parse_token(token) {
      Ok(v) => nums.push(v)
      Err(e) => return Err(e)
    }
  }
  Ok(nums)
}

fn parse_token(token : Array[Char]) -> Result[Double, @error.CoreError] {
  match @text.parse_double(String::from_array(token)) {
    Ok(value) => admit_svg_numeric_source(value)
    Err(_) => Err(svg_numeric_error(
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ))
  }
}
