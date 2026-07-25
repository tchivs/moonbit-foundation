// SVG transform attribute parsing: "translate(10,20) scale(2)" → Affine2.
//
// Supports matrix, translate, scale, rotate, skewX, skewY. Multiple transforms
// compose left-to-right (the first listed is applied first to the geometry, so
// it is the rightmost matrix in the product: result = identity * first * second).
// Parameters are comma-or-space-separated doubles inside parentheses.
//
// Per SVG 1.1, rotate/skewX/skewY take DEGREES; mb-core Affine2::rotate/skew
// take radians, so angles are converted. rotate(angle, cx, cy) rotates about
// (cx, cy); rotate(angle) about the origin. The returned Affine2 is invertible
// via Affine2::inverse (RFC 0002 §6.1 promises composition and inversion).

///|
/// Parse an SVG transform attribute into a composed Affine2. An empty or
/// whitespace-only string yields the identity transform.
pub fn parse_transform(s : String) -> Result[@math.Affine2, @error.CoreError] {
  let t = @text.trim(s).to_string()
  if t == "" {
    return Ok(@math.Affine2::identity())
  }
  let mut result = @math.Affine2::identity()
  let chars = t.to_array()
  let mut i = 0
  let n = chars.length()
  while i < n {
    // Skip whitespace.
    while i < n && is_space(chars[i]) {
      i = i + 1
    }
    if i >= n {
      break
    }
    // Read the function name (letters until '(' or whitespace).
    let name_start = i
    while i < n && chars[i] != '(' && not(is_space(chars[i])) {
      i = i + 1
    }
    let name = String::from_array(chars[name_start:i])
    // Skip whitespace before '('.
    while i < n && is_space(chars[i]) {
      i = i + 1
    }
    if i >= n || chars[i] != '(' {
      return Err(svg_error("svg-transform", "expected '(' after " + name))
    }
    i = i + 1 // consume '('
    // Read until ')'.
    let args_start = i
    while i < n && chars[i] != ')' {
      i = i + 1
    }
    if i >= n {
      return Err(svg_error("svg-transform", "unterminated '(' in " + name))
    }
    let args_str = String::from_array(chars[args_start:i])
    i = i + 1 // consume ')'
    // Parse args and build the transform. SVG applies transforms left-to-right
    // to the geometry (the leftmost is applied first), which corresponds to
    // pre-multiplying each new matrix onto the accumulating result so that
    // result.apply(p) applies the earliest transform first.
    match build_transform(name, args_str) {
      Ok(m) => result = m.compose(result)
      Err(e) => return Err(e)
    }
  }
  Ok(result)
}

// Build a single Affine2 from a transform function name and its args string.
fn build_transform(
  name : String,
  args_str : String,
) -> Result[@math.Affine2, @error.CoreError] {
  match parse_number_list(args_str) {
    Err(e) => Err(e)
    Ok(args) =>
      match name {
        "matrix" =>
          if args.length() < 6 {
            Err(svg_error("svg-transform", "matrix needs 6 args"))
          } else {
            Ok(@math.Affine2::new(args[0], args[1], args[2], args[3], args[4], args[5]))
          }
        "translate" =>
          if args.length() < 2 {
            // Single-arg translate: translate(x) = translate(x, 0).
            if args.length() == 1 {
              Ok(@math.Affine2::translate(args[0], 0.0))
            } else {
              Err(svg_error("svg-transform", "translate needs 1-2 args"))
            }
          } else {
            Ok(@math.Affine2::translate(args[0], args[1]))
          }
        "scale" =>
          if args.length() == 1 {
            Ok(@math.Affine2::scale(args[0], args[0]))
          } else if args.length() >= 2 {
            Ok(@math.Affine2::scale(args[0], args[1]))
          } else {
            Err(svg_error("svg-transform", "scale needs 1-2 args"))
          }
        "rotate" =>
          // rotate(angle) rotates about the origin. rotate(angle, cx, cy)
          // rotates about (cx, cy): translate(cx,cy) ∘ rotate(angle) ∘
          // translate(-cx,-cy), applied to a point as
          //   p ↦ translate(cx,cy)(rotate(angle)(translate(-cx,-cy)(p)))
          // Compose semantics: a.compose(b).apply(p) = b(a(p)), so the chain
          // t_neg.compose(r).compose(t_pos) yields apply = t_pos(r(t_neg(p))).
          // SVG rotate takes DEGREES; Affine2::rotate takes radians.
          if args.length() == 1 {
            Ok(@math.Affine2::rotate(degrees_to_radians(args[0])))
          } else if args.length() >= 3 {
            let t_neg = @math.Affine2::translate(-args[1], -args[2])
            let r = @math.Affine2::rotate(degrees_to_radians(args[0]))
            let t_pos = @math.Affine2::translate(args[1], args[2])
            Ok(t_neg.compose(r).compose(t_pos))
          } else {
            Err(svg_error("svg-transform", "rotate needs angle or angle,cx,cy"))
          }
        "skewX" =>
          // SVG skewX takes DEGREES; Affine2::skew takes radians.
          if args.length() >= 1 {
            Ok(@math.Affine2::skew(degrees_to_radians(args[0]), 0.0))
          } else {
            Err(svg_error("svg-transform", "skewX needs angle"))
          }
        "skewY" =>
          if args.length() >= 1 {
            Ok(@math.Affine2::skew(0.0, degrees_to_radians(args[0])))
          } else {
            Err(svg_error("svg-transform", "skewY needs angle"))
          }
        _ => Err(svg_error("svg-transform", "unknown function: " + name))
      }
  }
}

fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

// SVG transform angles are in degrees; mb-core Affine2::rotate/skew take
// radians. Convert per the SVG 1.1 transform spec.
fn degrees_to_radians(degrees : Double) -> Double {
  degrees * 0.017453292519943295 // π / 180
}

fn not(b : Bool) -> Bool {
  !b
}
