// White-box tests for UTF-8 encoding/decoding (RFC 3629).

///|
test "utf8 encode produces correct byte sequences" {
  // ASCII: 'A' = U+0041 -> 0x41
  assert_eq(utf8_encode([0x41]).unwrap(), b"\x41".to_array())
  // 2-byte: U+00E9 ('é') -> C3 A9
  assert_eq(utf8_encode([0xe9]).unwrap(), b"\xc3\xa9".to_array())
  // 3-byte: U+4E2D ('中') -> E4 B8 AD
  assert_eq(utf8_encode([0x4e2d]).unwrap(), b"\xe4\xb8\xad".to_array())
  // 4-byte: U+1F600 -> F0 9F 98 80
  assert_eq(utf8_encode([0x1f600]).unwrap(), b"\xf0\x9f\x98\x80".to_array())
  // Empty
  assert_eq(utf8_encode([]).unwrap(), b"".to_array())
}

///|
test "utf8 decode round-trips all codepoint widths" {
  let codepoints = [0x41, 0xe9, 0x4e2d, 0x1f600]
  let encoded = utf8_encode(codepoints).unwrap()
  match utf8_decode(encoded) {
    Ok(decoded) => {
      inspect(decoded.length() == codepoints.length(), content="true")
      for i = 0; i < codepoints.length(); i = i + 1 {
        inspect(decoded[i] == codepoints[i], content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "utf8 decode handles pure ASCII" {
  let bytes = [b'H', b'e', b'l', b'l', b'o']
  match utf8_decode(bytes) {
    Ok(cps) => {
      inspect(cps.length() == 5, content="true")
      inspect(cps[0] == 0x48, content="true")
      inspect(cps[4] == 0x6f, content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "utf8 encode rejects surrogates" {
  match utf8_encode([0xd800]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() == Some("text-utf8-encode-surrogate"), content="true")
  }
}

///|
test "utf8 encode rejects out-of-range codepoints" {
  match utf8_encode([0x110000]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(
        e.context() == Some("text-utf8-encode-out-of-range"),
        content="true",
      )
  }
}

///|
test "utf8 decode rejects overlong 2-byte encoding" {
  // Overlong encoding of U+0041 ('A'): C1 81 (should be just 0x41).
  match utf8_decode([(0xc1).to_byte(), (0x81).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() == Some("text-utf8-decode-overlong"), content="true")
  }
}

///|
test "utf8 decode rejects overlong 3-byte encoding" {
  // Overlong encoding of U+007F: E0 81 BF
  match utf8_decode([(0xe0).to_byte(), (0x81).to_byte(), (0xbf).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() == Some("text-utf8-decode-overlong"), content="true")
  }
}

///|
test "utf8 decode rejects truncated sequences" {
  // 2-byte start without continuation.
  match utf8_decode([(0xc3).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() == Some("text-utf8-decode-truncated"), content="true")
  }
  // 3-byte start with only 1 continuation.
  match utf8_decode([(0xe4).to_byte(), (0xb8).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() == Some("text-utf8-decode-truncated"), content="true")
  }
}

///|
test "utf8 decode rejects invalid continuation bytes" {
  // 2-byte start followed by non-continuation byte.
  match utf8_decode([(0xc3).to_byte(), (0x41).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(
        e.context() == Some("text-utf8-decode-invalid-continuation"),
        content="true",
      )
  }
}

///|
test "utf8 decode rejects bare continuation bytes" {
  // 0x80 without a leading byte.
  match utf8_decode([(0x80).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(
        e.context() == Some("text-utf8-decode-invalid-leading"),
        content="true",
      )
  }
}

///|
test "utf8 encode then decode is identity for BMP and supplementary" {
  let codepoints = [0x0, 0x7f, 0x80, 0x7ff, 0x800, 0xffff, 0x10000, 0x10ffff]
  let encoded = utf8_encode(codepoints).unwrap()
  match utf8_decode(encoded) {
    Ok(decoded) => {
      inspect(decoded.length() == codepoints.length(), content="true")
      for i = 0; i < codepoints.length(); i = i + 1 {
        inspect(decoded[i] == codepoints[i], content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "utf8 decode rejects encoded surrogates" {
  // Encode U+D800 as if it were valid (bypass encode check) then decode.
  // EDA080 = U+D800 in UTF-8 (invalid).
  match utf8_decode([(0xed).to_byte(), (0xa0).to_byte(), (0x80).to_byte()]) {
    Ok(_) => inspect(false, content="true")
    Err(e) =>
      inspect(e.context() == Some("text-utf8-decode-surrogate"), content="true")
  }
}
