// Portable, deterministic text encoding utilities for MoonBit Native Foundation.
//
// This package owns byte-to-text and text-to-byte encoding transformations
// that are needed across document layers (PDF hex streams, font table names,
// debug diagnostics) without depending on any higher-layer module.
//
// All operations are pure functions of their inputs: deterministic on every
// target (js, wasm, wasm-gc, native), with no ambient state or host
// dependency. Bounds are enforced through structured errors so malformed
// inputs fail rather than wrapping or truncating.

// ---------------------------------------------------------------------------
// Hexadecimal encoding
// ---------------------------------------------------------------------------

///|
/// Encode a byte slice as a lowercase hexadecimal string.
///
/// Each byte produces exactly two characters `[0-9a-f]`. The output length
/// is always `2 * bytes.length()`. An empty input produces an empty string.
pub fn hex_encode(bytes : Array[Byte]) -> String {
  let length = bytes.length()
  let buffer = StringBuilder::new()
  for i = 0; i < length; i = i + 1 {
    let b = bytes[i].to_int()
    buffer.write_char(hex_nibble((b >> 4) & 0x0f))
    buffer.write_char(hex_nibble(b & 0x0f))
  }
  buffer.to_string()
}

///|
/// Decode a hexadecimal string into bytes.
///
/// The input must have even length and contain only `[0-9a-fA-F]`. Odd-length
/// or invalid-character inputs fail with `InvalidEncoding`. Whitespace and
/// `0x` prefixes are NOT accepted; the caller must strip them first.
pub fn hex_decode(text : String) -> Result[Array[Byte], @error.CoreError] {
  let units = text.code_units()
  let len = units.length()
  if len % 2 != 0 {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidEncoding,
      operation="text-hex-decode",
      context="text-hex-decode-odd-length",
    ))
  }
  let result : Array[Byte] = []
  let half = len / 2
  for i = 0; i < half; i = i + 1 {
    let hi = hex_value(units[i * 2].to_int())
    let lo = hex_value(units[i * 2 + 1].to_int())
    match (hi, lo) {
      (Ok(h), Ok(l)) => result.push(((h << 4) | l).to_byte())
      _ => {
        return Err(@error.CoreError::new(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::InvalidEncoding,
          operation="text-hex-decode",
          context="text-hex-decode-invalid-character",
        ))
      }
    }
  }
  Ok(result)
}

///|
fn hex_nibble(n : Int) -> Char {
  if n < 10 {
    (n + 0x30).to_char().unwrap() // '0' = 0x30
  } else {
    (n - 10 + 0x61).to_char().unwrap() // 'a' = 0x61
  }
}

///|
fn hex_value(code : Int) -> Result[Int, Unit] {
  if code >= 0x30 && code <= 0x39 {
    // '0'-'9'
    Ok(code - 0x30)
  } else if code >= 0x41 && code <= 0x46 {
    // 'A'-'F'
    Ok(code - 0x41 + 10)
  } else if code >= 0x61 && code <= 0x66 {
    // 'a'-'f'
    Ok(code - 0x61 + 10)
  } else {
    Err(())
  }
}

// ---------------------------------------------------------------------------
// ASCII classification
// ---------------------------------------------------------------------------

///|
/// Returns true if the code point is an ASCII digit `[0-9]`.
pub fn is_ascii_digit(code : Int) -> Bool {
  code >= 0x30 && code <= 0x39
}

///|
/// Returns true if the code point is an ASCII uppercase letter `[A-Z]`.
pub fn is_ascii_upper(code : Int) -> Bool {
  code >= 0x41 && code <= 0x5a
}

///|
/// Returns true if the code point is an ASCII lowercase letter `[a-z]`.
pub fn is_ascii_lower(code : Int) -> Bool {
  code >= 0x61 && code <= 0x7a
}

///|
/// Returns true if the code point is an ASCII letter `[A-Za-z]`.
pub fn is_ascii_alpha(code : Int) -> Bool {
  is_ascii_upper(code) || is_ascii_lower(code)
}

///|
/// Returns true if the code point is an ASCII alphanumeric `[A-Za-z0-9]`.
pub fn is_ascii_alphanumeric(code : Int) -> Bool {
  is_ascii_alpha(code) || is_ascii_digit(code)
}

///|
/// Returns true if every code unit in the string is ASCII `[0x00-0x7f]`.
pub fn is_ascii(text : String) -> Bool {
  let units = text.code_units()
  for i = 0; i < units.length(); i = i + 1 {
    if units[i].to_int() > 0x7f {
      return false
    }
  }
  true
}
