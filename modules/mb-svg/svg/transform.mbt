// SVG transform attribute parsing: "translate(10,20) scale(2)" → Affine2.
//
// Supports matrix, translate, scale, rotate, skewX, skewY. Multiple transforms
// compose left-to-right (the first listed is applied first to the geometry, so
// it is the rightmost matrix in the product: result = identity * first * second).
// Parameters are comma-or-space-separated doubles inside parentheses.
//
// Per SVG 1.1, rotate/skewX/skewY take DEGREES. Affine2::rotate takes radians;
// Affine2::skew takes raw tangent shear coefficients. rotate(angle, cx, cy) rotates about
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
      Ok(m) =>
        match compose_transforms(m, result) {
          Ok(composed) => result = composed
          Err(error) => return Err(error)
        }
      Err(e) => return Err(e)
    }
  }
  Ok(result)
}

// Build a single Affine2 from a transform function name and its args string.

///|
fn build_transform(
  name : String,
  args_str : String,
) -> Result[@math.Affine2, @error.CoreError] {
  match parse_number_list(args_str) {
    Err(e) => Err(e)
    Ok(args) =>
      match name {
        "matrix" =>
          if args.length() != 6 {
            Err(transform_source_error())
          } else {
            admit_affine(
              @math.Affine2::new(
                args[0],
                args[1],
                args[2],
                args[3],
                args[4],
                args[5],
              ),
            )
          }
        "translate" =>
          if args.length() == 1 {
            // Single-arg translate: translate(x) = translate(x, 0).
            admit_affine(@math.Affine2::translate(args[0], 0.0))
          } else if args.length() == 2 {
            admit_affine(@math.Affine2::translate(args[0], args[1]))
          } else {
            Err(transform_source_error())
          }
        "scale" =>
          if args.length() == 1 {
            admit_affine(@math.Affine2::scale(args[0], args[0]))
          } else if args.length() == 2 {
            admit_affine(@math.Affine2::scale(args[0], args[1]))
          } else {
            Err(transform_source_error())
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
            let radians = match degrees_to_radians(args[0]) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            admit_affine(@math.Affine2::rotate(radians))
          } else if args.length() == 3 {
            let radians = match degrees_to_radians(args[0]) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let t_neg = match
              admit_affine(@math.Affine2::translate(-args[1], -args[2])) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let r = match admit_affine(@math.Affine2::rotate(radians)) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let t_pos = match
              admit_affine(@math.Affine2::translate(args[1], args[2])) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let rotated = match compose_transforms(t_neg, r) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            compose_transforms(rotated, t_pos)
          } else {
            Err(transform_source_error())
          }
        "skewX" =>
          // SVG skewX takes degrees, while Affine2::skew stores the raw
          // matrix shear coefficient. That coefficient is tan(angle).
          if args.length() == 1 {
            let radians = match degrees_to_radians(args[0]) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let shear = match admit_derived(@math.tan(radians)) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            admit_affine(@math.Affine2::skew(shear, 0.0))
          } else {
            Err(transform_source_error())
          }
        "skewY" =>
          if args.length() == 1 {
            let radians = match degrees_to_radians(args[0]) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            let shear = match admit_derived(@math.tan(radians)) {
              Ok(value) => value
              Err(error) => return Err(error)
            }
            admit_affine(@math.Affine2::skew(0.0, shear))
          } else {
            Err(transform_source_error())
          }
        _ => Err(svg_error("svg-transform", "unknown function: " + name))
      }
  }
}

///|
fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

// SVG transform angles are in degrees; Affine2::rotate takes radians. Convert
// per the SVG 1.1 transform spec before rotation or tangent calculation.

///|
fn degrees_to_radians(degrees : Double) -> Result[Double, @error.CoreError] {
  admit_derived(degrees * 0.017453292519943295) // π / 180
}

///|
fn transform_source_error() -> @error.CoreError {
  svg_numeric_error(@error.ErrorCode::InvalidEncoding, "svg-numeric-source")
}

///|
fn admit_derived(value : Double) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() || value.abs() > 65536.0 {
    Err(
      svg_numeric_error(@error.ErrorCode::InvalidRange, "svg-numeric-derived"),
    )
  } else {
    Ok(value)
  }
}

///|
fn admit_affine(m : @math.Affine2) -> Result[@math.Affine2, @error.CoreError] {
  let components = [m.a(), m.b(), m.c(), m.d(), m.tx(), m.ty()]
  for value in components {
    match admit_derived(value) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(m)
}

///|
fn compose_transforms(
  first : @math.Affine2,
  second : @math.Affine2,
) -> Result[@math.Affine2, @error.CoreError] {
  admit_affine(first.compose(second))
}

///|
fn not(b : Bool) -> Bool {
  !b
}
