// SVG color string parsing: named colors, hex, rgb(), hsl(), currentColor.
//
// Returns normalized sRGB components in [0,1] (the encoded-sRGB domain that
// mb-canvas FillStyle consumes). hsl() is converted via mb-color's hsl_to_rgb.
// "currentColor" resolves through an explicit context. String content is
// accessed via to_array() to avoid borrow-reference indexing limitations.

///|
/// Sentinel for the "none" paint value.
pub fn is_none_color(s : String) -> Bool {
  @text.trim(s) == "none"
}

///|
/// Sentinel for the "currentColor" keyword.
pub fn is_current_color(s : String) -> Bool {
  @text.trim(s) == "currentColor"
}

///|
/// Parse an SVG color string into normalized sRGB components (r, g, b) in
/// [0,1]. `current` is the inherited currentColor value (None if unspecified).
pub fn parse_color(
  s : String,
  current : (Double, Double, Double)?,
) -> Result[(Double, Double, Double), @error.CoreError] {
  let t = @text.trim(s).to_string()
  if t == "currentColor" {
    match current {
      Some(c) => return Ok(c)
      None => return Ok((0.0, 0.0, 0.0))
    }
  }
  if t.has_prefix("#") {
    return parse_hex_color(t)
  }
  if t.has_prefix("rgb(") {
    return parse_func_color(t, false, false)
  }
  if t.has_prefix("rgba(") {
    // The scene model consumes only RGB. Preserve its established ignored-alpha
    // compatibility boundary rather than admitting alpha as a new scalar route.
    return parse_func_color(t, false, true)
  }
  if t.has_prefix("hsl(") {
    return parse_func_color(t, true, false)
  }
  if t.has_prefix("hsla(") {
    return parse_func_color(t, true, true)
  }
  match lookup_named_color(t) {
    Some(c) => Ok(c)
    None => Err(svg_error("svg-color", "unknown color: " + t))
  }
}

fn parse_hex_color(t : String) -> Result[(Double, Double, Double), @error.CoreError] {
  let chars = t.to_array()
  match chars.length() {
    4 => {
      let r = match hex_digit(chars[1]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let g = match hex_digit(chars[2]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let b = match hex_digit(chars[3]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      Ok((byte_to_norm(r * 16 + r), byte_to_norm(g * 16 + g), byte_to_norm(b * 16 + b)))
    }
    7 => {
      let r1 = match hex_digit(chars[1]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let r2 = match hex_digit(chars[2]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let g1 = match hex_digit(chars[3]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let g2 = match hex_digit(chars[4]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let b1 = match hex_digit(chars[5]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let b2 = match hex_digit(chars[6]) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let r = r1 * 16 + r2
      let g = g1 * 16 + g2
      let b = b1 * 16 + b2
      Ok((byte_to_norm(r), byte_to_norm(g), byte_to_norm(b)))
    }
    _ => Err(color_source_error())
  }
}

fn hex_digit(c : Char) -> Result[Int, @error.CoreError] {
  let v = c.to_int()
  if v >= 48 && v <= 57 {
    Ok(v - 48) // '0'-'9'
  } else if v >= 97 && v <= 102 {
    Ok(v - 87) // 'a'-'f'
  } else if v >= 65 && v <= 70 {
    Ok(v - 55) // 'A'-'F'
  } else {
    Err(color_source_error())
  }
}

fn byte_to_norm(v : Int) -> Double {
  v.to_double() / 255.0
}

// Parse rgb()/rgba() or hsl()/hsla(): extract the content between the first '('
// and the last ')', split on ',', parse each component.
fn parse_func_color(
  t : String,
  is_hsl : Bool,
  allows_ignored_alpha : Bool,
) -> Result[(Double, Double, Double), @error.CoreError] {
  let chars = t.to_array()
  // Find '(' and ')'.
  let mut open = -1
  let mut close = -1
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == '(' && open == -1 {
      open = i
    }
    if chars[i] == ')' {
      close = i
    }
  }
  if open == -1 || close == -1 || close <= open || close != chars.length() - 1 {
    return Err(color_source_error())
  }
  // Extract inner content as a String.
  let inner_chars : Array[Char] = []
  for i = open + 1; i < close; i = i + 1 {
    inner_chars.push(chars[i])
  }
  let inner = String::from_array(inner_chars)
  // Split on ',' and parse.
  let parts = split_on_comma(inner)
  if parts.length() < 3 || (!allows_ignored_alpha && parts.length() != 3) {
    return Err(color_source_error())
  }
  let c0 = @text.trim(parts[0]).to_string()
  let c1 = @text.trim(parts[1]).to_string()
  let c2 = @text.trim(parts[2]).to_string()
  if is_hsl {
    let h = match parse_color_scalar(c0) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let s = match parse_percent(c1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let l = match parse_percent(c2) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let (r, g, b) = @color.hsl_to_rgb(h, s, l)
    Ok((r, g, b))
  } else {
    let r = match parse_component(c0) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let g = match parse_component(c1) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let b = match parse_component(c2) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    Ok((r, g, b))
  }
}

fn parse_component(s : String) -> Result[Double, @error.CoreError] {
  if s.contains("%") {
    parse_percent(s)
  } else {
    match parse_color_scalar(s) {
      Ok(value) => Ok(value / 255.0)
      Err(error) => Err(error)
    }
  }
}

fn parse_percent(s : String) -> Result[Double, @error.CoreError] {
  // Percent components require exactly one trailing '%'. Removing every '%'
  // would otherwise accept malformed forms such as "1%%" and "1%2".
  let chars = @text.trim(s).to_string().to_array()
  if chars.length() == 0 || chars[chars.length() - 1] != '%' {
    return Err(color_source_error())
  }
  let scalar_chars : Array[Char] = []
  for i = 0; i < chars.length() - 1; i = i + 1 {
    if chars[i] == '%' {
      return Err(color_source_error())
    }
    scalar_chars.push(chars[i])
  }
  match parse_color_scalar(String::from_array(scalar_chars)) {
    Ok(value) => Ok(value / 100.0)
    Err(error) => Err(error)
  }
}

fn color_source_error() -> @error.CoreError {
  svg_numeric_error(@error.ErrorCode::InvalidEncoding, "svg-numeric-source")
}

fn parse_color_scalar(s : String) -> Result[Double, @error.CoreError] {
  match @text.parse_double(@text.trim(s).to_string()) {
    Ok(value) => admit_svg_numeric_source(value)
    Err(_) => Err(svg_numeric_error(
      @error.ErrorCode::InvalidEncoding,
      "svg-numeric-source",
    ))
  }
}

// Split a string on ',' keeping non-empty trimmed parts.
fn split_on_comma(s : String) -> Array[String] {
  let parts = s.split(",")
  let result : Array[String] = []
  for p in parts {
    result.push(p.to_owned())
  }
  result
}

// Lookup a CSS/SVG named color.
fn lookup_named_color(name : String) -> (Double, Double, Double)? {
  match name {
    "black" => Some((0.0, 0.0, 0.0))
    "white" => Some((1.0, 1.0, 1.0))
    "red" => Some((1.0, 0.0, 0.0))
    "green" => Some((0.0, 0.5019607843137255, 0.0))
    "blue" => Some((0.0, 0.0, 1.0))
    "yellow" => Some((1.0, 1.0, 0.0))
    "cyan" | "aqua" => Some((0.0, 1.0, 1.0))
    "magenta" | "fuchsia" => Some((1.0, 0.0, 1.0))
    "silver" => Some((0.7529411764705882, 0.7529411764705882, 0.7529411764705882))
    "gray" | "grey" => Some((0.5019607843137255, 0.5019607843137255, 0.5019607843137255))
    "maroon" => Some((0.5019607843137255, 0.0, 0.0))
    "purple" => Some((0.5019607843137255, 0.0, 0.5019607843137255))
    "lime" => Some((0.0, 1.0, 0.0))
    "olive" => Some((0.5019607843137255, 0.5019607843137255, 0.0))
    "navy" => Some((0.0, 0.0, 0.5019607843137255))
    "teal" => Some((0.0, 0.5019607843137255, 0.5019607843137255))
    "orange" => Some((1.0, 0.6470588235294118, 0.0))
    "transparent" => Some((0.0, 0.0, 0.0))
    _ => None
  }
}
