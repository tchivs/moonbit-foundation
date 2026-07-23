// Percent-encoding (URL encoding, RFC 3986) for MoonBit Native Foundation.
//
// Consumed by data URIs, URL handling, and escaped attribute values.
// Encodes all non-unreserved characters as %XX; decodes %XX sequences
// and handles invalid input with structured errors.

///|
/// Encode a string using RFC 3986 percent-encoding.
///
/// Unreserved characters `[A-Za-z0-9-._~]` are left as-is; all other
/// characters are encoded as `%XX` using uppercase hex digits.
pub fn percent_encode(text : String) -> String {
  let units = text.code_units()
  let buffer = StringBuilder::new()
  for i = 0; i < units.length(); i = i + 1 {
    let c = units[i].to_int()
    if is_unreserved(c) {
      ignore(buffer.write_char(c.to_char().unwrap()))
    } else {
      buffer.write_char('%'.to_int().to_char().unwrap())
      buffer.write_char(hex_nibble_upper((c >> 4) & 0x0f))
      buffer.write_char(hex_nibble_upper(c & 0x0f))
    }
  }
  buffer.to_string()
}

///|
/// Decode a percent-encoded string (RFC 3986).
///
/// Converts `%XX` sequences back to bytes; passes unreserved characters
/// through unchanged. Returns `Err` for malformed `%` sequences
/// (truncated, non-hex digits).
pub fn percent_decode(text : String) -> Result[Array[Byte], @error.CoreError] {
  let units = text.code_units()
  let len = units.length()
  let result : Array[Byte] = []
  let mut i = 0
  while i < len {
    let c = units[i].to_int()
    if c == 0x25 {
      // '%'
      if i + 2 >= len {
        return Err(@error.CoreError::new(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::InvalidEncoding,
          operation="text-percent-decode",
          context="text-percent-decode-truncated",
        ))
      }
      let hi = hex_digit_value(units[i + 1].to_int())
      let lo = hex_digit_value(units[i + 2].to_int())
      match (hi, lo) {
        (Ok(h), Ok(l)) => {
          result.push(((h << 4) | l).to_byte())
          i = i + 3
        }
        _ => {
          return Err(@error.CoreError::new(
            @error.ErrorCategory::InvalidInput,
            @error.ErrorCode::InvalidEncoding,
            operation="text-percent-decode",
            context="text-percent-decode-invalid-hex",
          ))
        }
      }
    } else {
      result.push(c.to_byte())
      i = i + 1
    }
  }
  Ok(result)
}

///|
fn is_unreserved(c : Int) -> Bool {
  (c >= 0x41 && c <= 0x5a) || // A-Z
  (c >= 0x61 && c <= 0x7a) || // a-z
  (c >= 0x30 && c <= 0x39) || // 0-9
  c == 0x2d || // -
  c == 0x2e || // .
  c == 0x5f || // _
  c == 0x7e // ~
}

///|
fn hex_nibble_upper(n : Int) -> Char {
  if n < 10 {
    (n + 0x30).to_char().unwrap() // '0'
  } else {
    (n - 10 + 0x41).to_char().unwrap() // 'A'
  }
}

///|
fn hex_digit_value(c : Int) -> Result[Int, Unit] {
  if c >= 0x30 && c <= 0x39 {
    Ok(c - 0x30)
  } else if c >= 0x41 && c <= 0x46 {
    Ok(c - 0x41 + 10)
  } else if c >= 0x61 && c <= 0x66 {
    Ok(c - 0x61 + 10)
  } else {
    Err(())
  }
}
