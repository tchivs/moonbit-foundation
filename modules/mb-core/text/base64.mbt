// Base64 encoding/decoding (RFC 4648) for portable text-byte transformations.
//
// Used by PDF streams, data URIs, and font embedding. The standard alphabet
// is `[A-Za-z0-9+/]` with `=` padding. URL-safe alphabet (`-` and `_`) is
// NOT provided here; add it when a consumer requires it.

///|
/// The Base64 alphabet in standard RFC 4648 order.
let base64_alphabet : Array[Char] = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/',
]

///|
/// Encode a byte slice as a standard Base64 string with `=` padding.
///
/// Empty input produces an empty string. The output length is always a
/// multiple of 4.
pub fn base64_encode(bytes : Array[Byte]) -> String {
  let length = bytes.length()
  if length == 0 {
    return ""
  }
  let buffer = StringBuilder::new()
  let full_groups = length / 3
  let remainder = length % 3
  // Process complete 3-byte groups.
  for i = 0; i < full_groups; i = i + 1 {
    let offset = i * 3
    let b0 = bytes[offset].to_int()
    let b1 = bytes[offset + 1].to_int()
    let b2 = bytes[offset + 2].to_int()
    let triple = (b0 << 16) | (b1 << 8) | b2
    buffer.write_char(base64_alphabet[(triple >> 18) & 0x3f])
    buffer.write_char(base64_alphabet[(triple >> 12) & 0x3f])
    buffer.write_char(base64_alphabet[(triple >> 6) & 0x3f])
    buffer.write_char(base64_alphabet[triple & 0x3f])
  }
  // Process the final partial group with padding.
  if remainder == 1 {
    let b0 = bytes[full_groups * 3].to_int()
    let pair = b0 << 16
    buffer.write_char(base64_alphabet[(pair >> 18) & 0x3f])
    buffer.write_char(base64_alphabet[(pair >> 12) & 0x3f])
    buffer.write_char('=')
    buffer.write_char('=')
  } else if remainder == 2 {
    let b0 = bytes[full_groups * 3].to_int()
    let b1 = bytes[full_groups * 3 + 1].to_int()
    let pair = (b0 << 16) | (b1 << 8)
    buffer.write_char(base64_alphabet[(pair >> 18) & 0x3f])
    buffer.write_char(base64_alphabet[(pair >> 12) & 0x3f])
    buffer.write_char(base64_alphabet[(pair >> 6) & 0x3f])
    buffer.write_char('=')
  }
  buffer.to_string()
}

///|
/// Decode a standard Base64 string into bytes.
///
/// Rejects inputs whose length is not a multiple of 4, contains invalid
/// characters (outside `[A-Za-z0-9+/=]`), or has padding in non-terminal
/// positions. Whitespace is NOT accepted; the caller must strip it first.
pub fn base64_decode(text : String) -> Result[Array[Byte], @error.CoreError] {
  let units = text.code_units()
  let len = units.length()
  if len == 0 {
    return Ok([])
  }
  if len % 4 != 0 {
    return Err(@error.CoreError::new(
      @error.ErrorCategory::InvalidInput,
      @error.ErrorCode::InvalidEncoding,
      operation="text-base64-decode",
      context="text-base64-decode-invalid-length",
    ))
  }
  let result : Array[Byte] = []
  let groups = len / 4
  for i = 0; i < groups; i = i + 1 {
    let offset = i * 4
    // Unwrap the Result layer: any Err means an invalid character.
    let r0 = base64_char_value(units[offset])
    let r1 = base64_char_value(units[offset + 1])
    let r2 = base64_char_value(units[offset + 2])
    let r3 = base64_char_value(units[offset + 3])
    if r0 is Err(_) || r1 is Err(_) || r2 is Err(_) || r3 is Err(_) {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidEncoding,
        operation="text-base64-decode",
        context="text-base64-decode-invalid-character",
      ))
    }
    // Now safe to unwrap: data chars are Some(n), pad is None.
    let c0 = r0.unwrap()
    let c1 = r1.unwrap()
    let c2 = r2.unwrap()
    let c3 = r3.unwrap()
    // First two characters of any group must be non-pad data.
    match (c0, c1) {
      (Some(v0), Some(v1)) => {
        let triple = (v0 << 18) | (v1 << 12)
        match (c2, c3) {
          (Some(v2), Some(v3)) => {
            // No padding: emit 3 bytes.
            let full = triple | (v2 << 6) | v3
            result.push(((full >> 16) & 0xff).to_byte())
            result.push(((full >> 8) & 0xff).to_byte())
            result.push((full & 0xff).to_byte())
          }
          (Some(v2), None) => {
            // One pad: emit 2 bytes.
            let full = triple | (v2 << 6)
            result.push(((full >> 16) & 0xff).to_byte())
            result.push(((full >> 8) & 0xff).to_byte())
          }
          (None, None) => {
            // Two pads: emit 1 byte.
            result.push(((triple >> 16) & 0xff).to_byte())
          }
          _ => {
            return Err(@error.CoreError::new(
              @error.ErrorCategory::InvalidInput,
              @error.ErrorCode::InvalidEncoding,
              operation="text-base64-decode",
              context="text-base64-decode-invalid-padding",
            ))
          }
        }
      }
      _ => {
        return Err(@error.CoreError::new(
          @error.ErrorCategory::InvalidInput,
          @error.ErrorCode::InvalidEncoding,
          operation="text-base64-decode",
          context="text-base64-decode-invalid-character",
        ))
      }
    }
  }
  Ok(result)
}

///|
/// Resolve a single Base64 character to its 6-bit value, padding, or error.
///
/// Returns `Ok(Some(n))` for data, `Ok(None)` for `=` padding, and `Err(())`
/// for any character outside `[A-Za-z0-9+/=]`. The caller distinguishes
/// padding from error structurally.
fn base64_char_value(code : UInt16) -> Result[Int?, Unit] {
  let c = code.to_int()
  if c == 0x3d {
    // '=' padding
    Ok(None)
  } else if c >= 0x41 && c <= 0x5a {
    // 'A'-'Z' = 0-25
    Ok(Some(c - 0x41))
  } else if c >= 0x61 && c <= 0x7a {
    // 'a'-'z' = 26-51
    Ok(Some(c - 0x61 + 26))
  } else if c >= 0x30 && c <= 0x39 {
    // '0'-'9' = 52-61
    Ok(Some(c - 0x30 + 52))
  } else if c == 0x2b {
    // '+' = 62
    Ok(Some(62))
  } else if c == 0x2f {
    // '/' = 63
    Ok(Some(63))
  } else {
    Err(())
  }
}
