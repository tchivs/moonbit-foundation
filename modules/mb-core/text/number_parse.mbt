// Portable number parsing for MoonBit Native Foundation.
//
// Parses numeric strings from SVG attributes, PDF objects, and font tables
// into typed values. All functions are deterministic and reject malformed
// input with structured errors rather than returning garbage.
//
// Supports:
// - Integer parsing with optional sign: "-42", "+7", "0"
// - Floating-point parsing with sign, decimal, and exponent: "3.14", "-1e5", "+2.5e-3"
// - Whitespace trimming (leading/trailing spaces only)

///|
/// Parse a string as a signed integer.
///
/// Accepts an optional leading `+` or `-` followed by ASCII digits `[0-9]`.
/// Leading/trailing whitespace is trimmed. Returns `Err` for empty input,
/// non-digit characters, or overflow.
pub fn parse_int(text : String) -> Result[Int, @error.CoreError] {
  let trimmed = text.trim()
  let units = trimmed.code_units()
  if units.length() == 0 {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidEncoding,
      operation="text-parse-int",
      context="text-parse-int-empty",
    ))
  }
  let mut i = 0
  let mut negative = false
  if units[0].to_int() == 0x2d {
    // '-'
    negative = true
    i = 1
  } else if units[0].to_int() == 0x2b {
    // '+'
    i = 1
  }
  if i >= units.length() {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidEncoding,
      operation="text-parse-int",
      context="text-parse-int-sign-only",
    ))
  }
  let mut result = 0
  while i < units.length() {
    let c = units[i].to_int()
    if c < 0x30 || c > 0x39 {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidEncoding,
        operation="text-parse-int",
        context="text-parse-int-invalid-character",
      ))
    }
    let digit = c - 0x30
    // Check overflow: if result > max/10, or result == max/10 and digit > max%10
    let max_div_10 = 214748364
    let max_mod_10 = 7
    if result > max_div_10 || (result == max_div_10 && digit > max_mod_10) {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::ArithmeticOverflow,
        operation="text-parse-int",
        context="text-parse-int-overflow",
      ))
    }
    result = result * 10 + digit
    i = i + 1
  }
  Ok(if negative {
    -result
  } else {
    result
  })
}

///|
/// Parse a string as a double-precision floating-point number.
///
/// Accepts an optional sign, integer part, optional decimal part, and
/// optional exponent: `[-+]?digits[.digits][[eE][-+]?digits]`.
/// Leading/trailing whitespace is trimmed. Returns `Err` for malformed input.
pub fn parse_double(text : String) -> Result[Double, @error.CoreError] {
  let trimmed = text.trim()
  let units = trimmed.code_units()
  let len = units.length()
  if len == 0 {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidEncoding,
      operation="text-parse-double",
      context="text-parse-double-empty",
    ))
  }
  let mut i = 0
  let mut negative = false
  // Sign.
  if units[i].to_int() == 0x2d {
    // '-'
    negative = true
    i = i + 1
  } else if units[i].to_int() == 0x2b {
    // '+'
    i = i + 1
  }
  if i >= len {
    return Err(double_error("text-parse-double-sign-only"))
  }
  // Integer part.
  let mut int_part = 0.0
  let mut has_digits = false
  while i < len {
    let c = units[i].to_int()
    if c >= 0x30 && c <= 0x39 {
      int_part = int_part * 10.0 + (c - 0x30).to_double()
      has_digits = true
      i = i + 1
    } else {
      break
    }
  }
  // Fractional part.
  let mut frac_part = 0.0
  let mut frac_divisor = 1.0
  if i < len && units[i].to_int() == 0x2e {
    // '.'
    i = i + 1
    while i < len {
      let c = units[i].to_int()
      if c >= 0x30 && c <= 0x39 {
        frac_divisor = frac_divisor * 10.0
        frac_part = frac_part + (c - 0x30).to_double() / frac_divisor
        has_digits = true
        i = i + 1
      } else {
        break
      }
    }
  }
  if !has_digits {
    return Err(double_error("text-parse-double-no-digits"))
  }
  // Exponent.
  let mut exponent = 0.0
  if i < len && (units[i].to_int() == 0x65 || units[i].to_int() == 0x45) {
    // 'e' or 'E'
    i = i + 1
    if i >= len {
      return Err(double_error("text-parse-double-exponent-empty"))
    }
    let mut exp_negative = false
    if units[i].to_int() == 0x2d {
      exp_negative = true
      i = i + 1
    } else if units[i].to_int() == 0x2b {
      i = i + 1
    }
    if i >= len {
      return Err(double_error("text-parse-double-exponent-sign-only"))
    }
    let mut exp_digits = 0
    while i < len {
      let c = units[i].to_int()
      if c >= 0x30 && c <= 0x39 {
        exp_digits = exp_digits * 10 + (c - 0x30)
        i = i + 1
      } else {
        return Err(double_error("text-parse-double-exponent-invalid"))
      }
    }
    exponent = if exp_negative {
      -exp_digits.to_double()
    } else {
      exp_digits.to_double()
    }
  }
  // Check for trailing characters.
  if i < len {
    return Err(double_error("text-parse-double-trailing"))
  }
  let mantissa = int_part + frac_part
  let result = if exponent != 0.0 {
    mantissa * pow10(exponent)
  } else {
    mantissa
  }
  Ok(if negative {
    -result
  } else {
    result
  })
}

///|
/// Compute 10^n for integer-valued n (positive or negative).
fn pow10(n : Double) -> Double {
  let int_n = n.to_int()
  if int_n >= 0 {
    let mut result = 1.0
    for _i = 0; _i < int_n; _i = _i + 1 {
      result = result * 10.0
    }
    result
  } else {
    let mut result = 1.0
    for _i = 0; _i < -int_n; _i = _i + 1 {
      result = result / 10.0
    }
    result
  }
}

///|
fn double_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidEncoding,
    operation="text-parse-double",
    context~,
  )
}
