// SVG path data parsing: the `d` attribute of a <path> element.
//
// All lexical path scalars are admitted before they become geometry. Relative
// and smooth commands also admit their derived coordinates before appending a
// CanvasPath command, so callers never receive a partial path on numeric error.

///|
pub fn parse_path_data(
  s : String,
) -> Result[@canvas.CanvasPath, @error.CoreError] {
  parse_path_data_with_budget(s, default_path_budget())
}

///|
pub fn parse_path_data_with_budget(
  s : String,
  budget : @budget.Budget,
) -> Result[@canvas.CanvasPath, @error.CoreError] {
  // Admit caller-provided source before allocating a path or converting it to
  // a character array. This matches document parsing: source admission is a
  // non-consuming byte-limit check, while command parsing charges work below.
  match admit_source_bytes(s, budget) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let path = @canvas.CanvasPath::new()
  let chars = s.to_array()
  let n = chars.length()
  let mut i = 0
  let mut cur_x = 0.0
  let mut cur_y = 0.0
  let mut subpath_start_x = 0.0
  let mut subpath_start_y = 0.0
  let mut last_cmd : Char = ' '
  let mut last_ctrl_x = 0.0
  let mut last_ctrl_y = 0.0
  // `C` covers C/c/S/s and `Q` covers Q/q/T/t. No other command may reflect.
  let mut last_curve : Char = ' '
  while i < n {
    match
      budget.charge(
        @budget.ResourceCharge::new(
          bytes=0UL,
          allocations=0UL,
          allocation_size=0UL,
          width=0UL,
          height=0UL,
          pixels=0UL,
          work=1UL,
        ),
      ) {
      Ok(_) => ()
      Err(_) =>
        return Err(svg_error("svg-budget", "path command limit exceeded"))
    }
    while i < n && is_path_space(chars[i]) {
      i = i + 1
    }
    if i >= n {
      break
    }
    if is_alpha_char(chars[i]) {
      last_cmd = chars[i]
      i = i + 1
    }
    match to_upper_char(last_cmd) {
      'M' => {
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        if is_upper_char(last_cmd) {
          cur_x = x
          cur_y = y
        } else {
          cur_x = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          cur_y = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        }
        path.move_to(cur_x, cur_y)
        subpath_start_x = cur_x
        subpath_start_y = cur_y
        last_cmd = if is_upper_char(last_cmd) { 'L' } else { 'l' }
        last_curve = ' '
      }
      'L' => {
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        if is_upper_char(last_cmd) {
          cur_x = x
          cur_y = y
        } else {
          cur_x = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          cur_y = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        }
        path.line_to(cur_x, cur_y)
        last_curve = ' '
      }
      'H' => {
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        cur_x = if is_upper_char(last_cmd) {
          x
        } else {
          match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        }
        path.line_to(cur_x, cur_y)
        last_curve = ' '
      }
      'V' => {
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        cur_y = if is_upper_char(last_cmd) {
          y
        } else {
          match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        }
        path.line_to(cur_x, cur_y)
        last_curve = ' '
      }
      'C' => {
        let cp1x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cp1y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cp2x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cp2y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let (a, b, cc, d, ex, ey) = if is_upper_char(last_cmd) {
          (cp1x, cp1y, cp2x, cp2y, x, y)
        } else {
          let a = match checked_add(cur_x, cp1x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let b = match checked_add(cur_y, cp1y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let cc = match checked_add(cur_x, cp2x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let d = match checked_add(cur_y, cp2y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ex = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ey = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          (a, b, cc, d, ex, ey)
        }
        path.cubic_to(a, b, cc, d, ex, ey)
        last_ctrl_x = cc
        last_ctrl_y = d
        cur_x = ex
        cur_y = ey
        last_curve = 'C'
      }
      'Q' => {
        let cpx = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cpy = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let (a, b, ex, ey) = if is_upper_char(last_cmd) {
          (cpx, cpy, x, y)
        } else {
          let a = match checked_add(cur_x, cpx) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let b = match checked_add(cur_y, cpy) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ex = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ey = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          (a, b, ex, ey)
        }
        path.quad_to(a, b, ex, ey)
        last_ctrl_x = a
        last_ctrl_y = b
        cur_x = ex
        cur_y = ey
        last_curve = 'Q'
      }
      'S' => {
        // Exact SVG grammar: cp2x cp2y x y.
        let cp2x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cp2y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cp1x = if last_curve == 'C' {
          match checked_reflect(cur_x, last_ctrl_x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        } else {
          cur_x
        }
        let cp1y = if last_curve == 'C' {
          match checked_reflect(cur_y, last_ctrl_y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        } else {
          cur_y
        }
        let (cc, d, ex, ey) = if is_upper_char(last_cmd) {
          (cp2x, cp2y, x, y)
        } else {
          let cc = match checked_add(cur_x, cp2x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let d = match checked_add(cur_y, cp2y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ex = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ey = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          (cc, d, ex, ey)
        }
        path.cubic_to(cp1x, cp1y, cc, d, ex, ey)
        last_ctrl_x = cc
        last_ctrl_y = d
        cur_x = ex
        cur_y = ey
        last_curve = 'C'
      }
      'T' => {
        // Exact SVG grammar: x y.
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let cpx = if last_curve == 'Q' {
          match checked_reflect(cur_x, last_ctrl_x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        } else {
          cur_x
        }
        let cpy = if last_curve == 'Q' {
          match checked_reflect(cur_y, last_ctrl_y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        } else {
          cur_y
        }
        let (ex, ey) = if is_upper_char(last_cmd) {
          (x, y)
        } else {
          let ex = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let ey = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          (ex, ey)
        }
        path.quad_to(cpx, cpy, ex, ey)
        last_ctrl_x = cpx
        last_ctrl_y = cpy
        cur_x = ex
        cur_y = ey
        last_curve = 'Q'
      }
      'A' => {
        // Arc remains line approximated, but all seven source scalars and its
        // endpoint are checked before the path receives its line segment.
        let _rx = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let _ry = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let _rotation = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let _large_arc = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let _sweep = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let x = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        let y = match read_number(chars, i, n) {
          Ok((value, next)) => {
            i = next
            value
          }
          Err(error) => return Err(error)
        }
        if is_upper_char(last_cmd) {
          cur_x = x
          cur_y = y
        } else {
          cur_x = match checked_add(cur_x, x) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          cur_y = match checked_add(cur_y, y) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
        }
        path.line_to(cur_x, cur_y)
        last_curve = ' '
      }
      'Z' => {
        path.close_path()
        cur_x = subpath_start_x
        cur_y = subpath_start_y
        last_ctrl_x = cur_x
        last_ctrl_y = cur_y
        // Close has no implicit argument form; a following scalar must start
        // with an explicit command rather than repeating Z indefinitely.
        last_cmd = ' '
        last_curve = ' '
      }
      _ => return Err(path_source_error())
    }
  }
  Ok(path)
}

///|
fn checked_add(a : Double, b : Double) -> Result[Double, @error.CoreError] {
  admit_derived(a + b)
}

///|
fn checked_reflect(
  current : Double,
  control : Double,
) -> Result[Double, @error.CoreError] {
  match admit_derived(2.0 * current) {
    Ok(twice_current) => admit_derived(twice_current - control)
    Err(error) => Err(error)
  }
}

///|
fn path_source_error() -> @error.CoreError {
  svg_numeric_error(@error.ErrorCode::InvalidEncoding, "svg-numeric-source")
}

///|
fn is_alpha_char(c : Char) -> Bool {
  let v = c.to_int()
  (v >= 65 && v <= 90) || (v >= 97 && v <= 122)
}

///|
fn is_path_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
fn is_upper_char(c : Char) -> Bool {
  let v = c.to_int()
  v >= 65 && v <= 90
}

///|
fn to_upper_char(c : Char) -> Char {
  let v = c.to_int()
  if v >= 97 && v <= 122 {
    Int::unsafe_to_char(v - 32)
  } else {
    c
  }
}

///|
fn read_number(
  chars : Array[Char],
  start : Int,
  n : Int,
) -> Result[(Double, Int), @error.CoreError] {
  let mut i = start
  let mut comma_count = 0
  while i < n && (is_path_space(chars[i]) || chars[i] == ',') {
    if chars[i] == ',' {
      comma_count = comma_count + 1
    }
    i = i + 1
  }
  if comma_count > 1 ||
    (comma_count > 0 && !has_path_value_before(chars, start)) {
    return Err(path_source_error())
  }
  if i >= n || is_alpha_char(chars[i]) {
    return Err(path_source_error())
  }
  let tok : Array[Char] = []
  while i < n {
    let c = chars[i]
    if is_path_space(c) ||
      c == ',' ||
      (is_alpha_char(c) && c != 'e' && c != 'E') {
      break
    }
    // SVG numbers may be adjacent when a sign starts the next scalar, but a
    // sign immediately after an exponent marker remains part of that scalar.
    if (c == '+' || c == '-') && tok.length() > 0 {
      let previous = tok[tok.length() - 1]
      if previous != 'e' && previous != 'E' {
        break
      }
    }
    tok.push(c)
    i = i + 1
  }
  if tok.length() == 0 {
    return Err(path_source_error())
  }
  match @text.parse_double(String::from_array(tok)) {
    Ok(value) =>
      match admit_svg_numeric_source(value) {
        Ok(admitted) => Ok((admitted, i))
        Err(error) => Err(error)
      }
    Err(_) => Err(path_source_error())
  }
}

///|
fn has_path_value_before(chars : Array[Char], start : Int) -> Bool {
  let mut i = start - 1
  while i >= 0 && is_path_space(chars[i]) {
    i = i - 1
  }
  i >= 0 && !is_alpha_char(chars[i])
}

///|
fn default_path_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=8388608UL,
      allocations=131072UL,
      allocation_size=8388608UL,
      width=65536UL,
      height=65536UL,
      pixels=0UL,
      depth=64UL,
      work=100000UL,
    ),
  )
}
