// SVG path data parsing: the `d` attribute of a <path> element.
//
// Parses SVG path commands M L H V C S Q T A Z (uppercase absolute, lowercase
// relative) into a mb-canvas CanvasPath. Numbers are comma-or-space-separated;
// repeated parameter groups reuse the current command (e.g. "L 1 1 2 2" = two
// line-to operations).
//
// The A (arc) command is approximated via line segments in v0.1 (a precise
// arc-to-cubic conversion is a follow-up). S/T (smooth cubic/quadratic) resolve
// the reflected control point from the previous command.

///|
/// Parse an SVG path data string into a CanvasPath. Returns an error on
/// malformed input.
pub fn parse_path_data(s : String) -> Result[@canvas.CanvasPath, @error.CoreError] {
  let path = @canvas.CanvasPath::new()
  let chars = s.to_array()
  let n = chars.length()
  let mut i = 0
  // Current point (for relative commands and H/V).
  let mut cur_x = 0.0
  let mut cur_y = 0.0
  // Last command char (for implicit repeats) and last control point (for S/T).
  let mut last_cmd : Char = ' '
  let mut last_ctrl_x = 0.0
  let mut last_ctrl_y = 0.0
  while i < n {
    // Skip whitespace before each token group.
    while i < n && is_path_space(chars[i]) {
      i = i + 1
    }
    if i >= n {
      break
    }
    let c = chars[i]
    if is_alpha_char(c) {
      last_cmd = c
      i = i + 1
      // After consuming a command letter, continue to read its params below.
      // But if the previous command was M (now switched to L for implicit
      // repeats), an explicit letter overrides it — handled here.
    }
    // Read numbers according to last_cmd.
    match to_upper_char(last_cmd) {
      'M' | 'm' => {
        let (x, ni) = read_number(chars, i, n)
        i = ni
        let (y, ni2) = read_number(chars, i, n)
        i = ni2
        if is_upper_char(last_cmd) {
          cur_x = x
          cur_y = y
        } else {
          cur_x = cur_x + x
          cur_y = cur_y + y
        }
        path.move_to(cur_x, cur_y)
        // After M/m, implicit repeats are L/l.
        last_cmd = if is_upper_char(last_cmd) {
          'L'
        } else {
          'l'
        }
      }
      'L' | 'l' => {
        let (x, ni) = read_number(chars, i, n)
        i = ni
        let (y, ni2) = read_number(chars, i, n)
        i = ni2
        if is_upper_char(last_cmd) {
          cur_x = x
          cur_y = y
        } else {
          cur_x = cur_x + x
          cur_y = cur_y + y
        }
        path.line_to(cur_x, cur_y)
      }
      'H' | 'h' => {
        let (x, ni) = read_number(chars, i, n)
        i = ni
        if is_upper_char(last_cmd) {
          cur_x = x
        } else {
          cur_x = cur_x + x
        }
        path.line_to(cur_x, cur_y)
      }
      'V' | 'v' => {
        let (y, ni) = read_number(chars, i, n)
        i = ni
        if is_upper_char(last_cmd) {
          cur_y = y
        } else {
          cur_y = cur_y + y
        }
        path.line_to(cur_x, cur_y)
      }
      'C' | 'c' => {
        let (cp1x, ni) = read_number(chars, i, n)
        i = ni
        let (cp1y, ni2) = read_number(chars, i, n)
        i = ni2
        let (cp2x, ni3) = read_number(chars, i, n)
        i = ni3
        let (cp2y, ni4) = read_number(chars, i, n)
        i = ni4
        let (x, ni5) = read_number(chars, i, n)
        i = ni5
        let (y, ni6) = read_number(chars, i, n)
        i = ni6
        if is_upper_char(last_cmd) {
          last_ctrl_x = cp2x
          last_ctrl_y = cp2y
          path.cubic_to(cp1x, cp1y, cp2x, cp2y, x, y)
          cur_x = x
          cur_y = y
        } else {
          let a = cp1x + cur_x
          let b = cp1y + cur_y
          let cc = cp2x + cur_x
          let d = cp2y + cur_y
          let ex = x + cur_x
          let ey = y + cur_y
          last_ctrl_x = cc
          last_ctrl_y = d
          path.cubic_to(a, b, cc, d, ex, ey)
          cur_x = ex
          cur_y = ey
        }
      }
      'Q' | 'q' => {
        let (cpx, ni) = read_number(chars, i, n)
        i = ni
        let (cpy, ni2) = read_number(chars, i, n)
        i = ni2
        let (x, ni3) = read_number(chars, i, n)
        i = ni3
        let (y, ni4) = read_number(chars, i, n)
        i = ni4
        if is_upper_char(last_cmd) {
          last_ctrl_x = cpx
          last_ctrl_y = cpy
          path.quad_to(cpx, cpy, x, y)
          cur_x = x
          cur_y = y
        } else {
          let a = cpx + cur_x
          let b = cpy + cur_y
          let ex = x + cur_x
          let ey = y + cur_y
          last_ctrl_x = a
          last_ctrl_y = b
          path.quad_to(a, b, ex, ey)
          cur_x = ex
          cur_y = ey
        }
      }
      'Z' | 'z' => {
        path.close_path()
        // After close, reset current point (to start of next subpath; left at
        // last position for v0.1 simplicity).
      }
      'S' | 'T' | 'A' | 'a' | 's' | 't' =>
        // S/T (smooth) and A (arc) are approximated as line-to in v0.1. Read
        // and skip their parameters, then line-to the endpoint. A precise
        // implementation is a follow-up.
        if last_cmd == 'S' || last_cmd == 's' {
          // S has 4 params: cp2x cp2y x y.
          let (_, ni) = read_number(chars, i, n)
          i = ni
          let (_, ni2) = read_number(chars, i, n)
          i = ni2
          let (cp2x, ni3) = read_number(chars, i, n)
          i = ni3
          let (cp2y, ni4) = read_number(chars, i, n)
          i = ni4
          let (x, ni5) = read_number(chars, i, n)
          i = ni5
          let (y, ni6) = read_number(chars, i, n)
          i = ni6
          // Reflect last control point.
          let cp1x = 2.0 * cur_x - last_ctrl_x
          let cp1y = 2.0 * cur_y - last_ctrl_y
          if is_upper_char(last_cmd) {
            last_ctrl_x = cp2x
            last_ctrl_y = cp2y
            path.cubic_to(cp1x, cp1y, cp2x, cp2y, x, y)
            cur_x = x
            cur_y = y
          } else {
            let a = cp1x
            let b = cp1y
            let cc = cp2x + cur_x
            let d = cp2y + cur_y
            let ex = x + cur_x
            let ey = y + cur_y
            last_ctrl_x = cc
            last_ctrl_y = d
            path.cubic_to(a, b, cc, d, ex, ey)
            cur_x = ex
            cur_y = ey
          }
        } else if last_cmd == 'T' || last_cmd == 't' {
          // T has 2 params: x y; control point reflected from last quad.
          let (x, ni) = read_number(chars, i, n)
          i = ni
          let (y, ni2) = read_number(chars, i, n)
          i = ni2
          let cpx = 2.0 * cur_x - last_ctrl_x
          let cpy = 2.0 * cur_y - last_ctrl_y
          if is_upper_char(last_cmd) {
            last_ctrl_x = cpx
            last_ctrl_y = cpy
            path.quad_to(cpx, cpy, x, y)
            cur_x = x
            cur_y = y
          } else {
            let ex = x + cur_x
            let ey = y + cur_y
            last_ctrl_x = cpx
            last_ctrl_y = cpy
            path.quad_to(cpx, cpy, ex, ey)
            cur_x = ex
            cur_y = ey
          }
        } else {
          // A (arc): 7 params rx ry x-rot large-arc sweep x y. v0.1 approximates
          // as line-to the endpoint.
          let (_, ni) = read_number(chars, i, n)
          i = ni
          let (_, ni2) = read_number(chars, i, n)
          i = ni2
          let (_, ni3) = read_number(chars, i, n)
          i = ni3
          let (_, ni4) = read_number(chars, i, n)
          i = ni4
          let (_, ni5) = read_number(chars, i, n)
          i = ni5
          let (x, ni6) = read_number(chars, i, n)
          i = ni6
          let (y, ni7) = read_number(chars, i, n)
          i = ni7
          if is_upper_char(last_cmd) {
            cur_x = x
            cur_y = y
          } else {
            cur_x = cur_x + x
            cur_y = cur_y + y
          }
          path.line_to(cur_x, cur_y)
        }
      _ =>
        // Unknown command: skip to next alpha or end.
        i = i + 1
    }
  }
  Ok(path)
}

// Char helpers (MoonBit Char lacks is_alpha/is_upper/to_upper methods).

fn is_alpha_char(c : Char) -> Bool {
  let v = c.to_int()
  (v >= 65 && v <= 90) || (v >= 97 && v <= 122) // A-Z or a-z
}

fn is_path_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

fn is_upper_char(c : Char) -> Bool {
  let v = c.to_int()
  v >= 65 && v <= 90 // A-Z
}

fn to_upper_char(c : Char) -> Char {
  let v = c.to_int()
  if v >= 97 && v <= 122 {
    Char::from_int(v - 32)
  } else {
    c
  }
}

// Read a number starting at index i (skipping leading whitespace/commas).
// Returns (value, new_index). Returns (0.0, n) at end of input.
fn read_number(chars : Array[Char], start : Int, n : Int) -> (Double, Int) {
  let mut i = start
  // Skip whitespace and commas.
  while i < n {
    let c = chars[i]
    if c == ' ' || c == ',' || c == '\t' || c == '\n' || c == '\r' {
      i = i + 1
    } else {
      break
    }
  }
  if i >= n {
    return (0.0, n)
  }
  // If the next char is alpha, this isn't a number (command switch).
  if is_alpha_char(chars[i]) {
    return (0.0, i)
  }
  // Collect the number token.
  let tok : Array[Char] = []
  while i < n {
    let c = chars[i]
    if c == ' ' || c == ',' || c == '\t' || c == '\n' || c == '\r' || is_alpha_char(c) {
      break
    }
    tok.push(c)
    i = i + 1
  }
  let s = String::from_array(tok)
  match @text.parse_double(s) {
    Ok(v) => (v, i)
    Err(_) => (0.0, i)
  }
}
