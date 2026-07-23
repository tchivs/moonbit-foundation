// UTF-8 encoding and decoding for MoonBit Native Foundation.
//
// Provides portable, deterministic byte↔codepoint conversion. Consumed by
// mb-text (Unicode string processing), mb-font (cmap resolution), mb-svg
// (text element parsing), and mb-pdf (string object encoding).
//
// Implements RFC 3629 UTF-8: rejects overlong encodings, surrogate codepoints
// (U+D800-U+DFFF), and codepoints above U+10FFFF. All operations are pure
// functions with structured error reporting.

///|
/// Encode a sequence of Unicode codepoints as UTF-8 bytes.
///
/// Codepoints above U+10FFFF and surrogate codepoints (U+D800-U+DFFF) are
/// rejected with `InvalidEncoding`. Each valid codepoint produces 1-4 bytes
/// per RFC 3629.
pub fn utf8_encode(codepoints : Array[Int]) -> Result[Array[Byte], @error.CoreError] {
  let result : Array[Byte] = []
  for i = 0; i < codepoints.length(); i = i + 1 {
    let cp = codepoints[i]
    if cp < 0 || cp > 0x10ffff {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidEncoding,
        operation="text-utf8-encode",
        context="text-utf8-encode-out-of-range",
      ))
    }
    if cp >= 0xd800 && cp <= 0xdfff {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidEncoding,
        operation="text-utf8-encode",
        context="text-utf8-encode-surrogate",
      ))
    }
    if cp <= 0x7f {
      // 1 byte: 0xxxxxxx
      result.push(cp.to_byte())
    } else if cp <= 0x7ff {
      // 2 bytes: 110xxxxx 10xxxxxx
      result.push((0xc0 | (cp >> 6)).to_byte())
      result.push((0x80 | (cp & 0x3f)).to_byte())
    } else if cp <= 0xffff {
      // 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx
      result.push((0xe0 | (cp >> 12)).to_byte())
      result.push((0x80 | ((cp >> 6) & 0x3f)).to_byte())
      result.push((0x80 | (cp & 0x3f)).to_byte())
    } else {
      // 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      result.push((0xf0 | (cp >> 18)).to_byte())
      result.push((0x80 | ((cp >> 12) & 0x3f)).to_byte())
      result.push((0x80 | ((cp >> 6) & 0x3f)).to_byte())
      result.push((0x80 | (cp & 0x3f)).to_byte())
    }
  }
  Ok(result)
}

///|
/// Decode UTF-8 bytes into Unicode codepoints.
///
/// Rejects incomplete sequences, invalid continuation bytes, overlong
/// encodings, surrogate codepoints, and codepoints above U+10FFFF with
/// `InvalidEncoding`.
pub fn utf8_decode(bytes : Array[Byte]) -> Result[Array[Int], @error.CoreError] {
  let result : Array[Int] = []
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let b0 = bytes[i].to_int()
    if b0 <= 0x7f {
      // 1 byte: ASCII
      result.push(b0)
      i = i + 1
    } else if b0 >= 0xc0 && b0 <= 0xdf {
      // 2 bytes
      if i + 1 >= len {
        return Err(utf8_error("text-utf8-decode-truncated"))
      }
      let b1 = bytes[i + 1].to_int()
      if (b1 & 0xc0) != 0x80 {
        return Err(utf8_error("text-utf8-decode-invalid-continuation"))
      }
      let cp = ((b0 & 0x1f) << 6) | (b1 & 0x3f)
      // Reject overlong (must be >= 0x80 for 2-byte).
      if cp < 0x80 {
        return Err(utf8_error("text-utf8-decode-overlong"))
      }
      result.push(cp)
      i = i + 2
    } else if b0 >= 0xe0 && b0 <= 0xef {
      // 3 bytes
      if i + 2 >= len {
        return Err(utf8_error("text-utf8-decode-truncated"))
      }
      let b1 = bytes[i + 1].to_int()
      let b2 = bytes[i + 2].to_int()
      if (b1 & 0xc0) != 0x80 || (b2 & 0xc0) != 0x80 {
        return Err(utf8_error("text-utf8-decode-invalid-continuation"))
      }
      let cp = ((b0 & 0x0f) << 12) | ((b1 & 0x3f) << 6) | (b2 & 0x3f)
      // Reject overlong (must be >= 0x800 for 3-byte).
      if cp < 0x800 {
        return Err(utf8_error("text-utf8-decode-overlong"))
      }
      // Reject surrogates.
      if cp >= 0xd800 && cp <= 0xdfff {
        return Err(utf8_error("text-utf8-decode-surrogate"))
      }
      result.push(cp)
      i = i + 3
    } else if b0 >= 0xf0 && b0 <= 0xf7 {
      // 4 bytes
      if i + 3 >= len {
        return Err(utf8_error("text-utf8-decode-truncated"))
      }
      let b1 = bytes[i + 1].to_int()
      let b2 = bytes[i + 2].to_int()
      let b3 = bytes[i + 3].to_int()
      if (b1 & 0xc0) != 0x80 || (b2 & 0xc0) != 0x80 || (b3 & 0xc0) != 0x80 {
        return Err(utf8_error("text-utf8-decode-invalid-continuation"))
      }
      let cp = ((b0 & 0x07) << 18) | ((b1 & 0x3f) << 12) | ((b2 & 0x3f) << 6) | (b3 & 0x3f)
      // Reject overlong (must be >= 0x10000 for 4-byte).
      if cp < 0x10000 {
        return Err(utf8_error("text-utf8-decode-overlong"))
      }
      // Above U+10FFFF already excluded by 4-byte range (max 0x1FFFFF),
      // but check explicitly for safety.
      if cp > 0x10ffff {
        return Err(utf8_error("text-utf8-decode-out-of-range"))
      }
      result.push(cp)
      i = i + 4
    } else {
      // Invalid leading byte (0x80-0xBF continuation without start,
      // or 0xF8-0xFF which are illegal in RFC 3629).
      return Err(utf8_error("text-utf8-decode-invalid-leading"))
    }
  }
  Ok(result)
}

///|
fn utf8_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidEncoding,
    operation="text-utf8-decode",
    context~,
  )
}
