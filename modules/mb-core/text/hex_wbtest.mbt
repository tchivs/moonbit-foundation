// White-box tests for text encoding utilities.
//
// Covers hex encode/decode round-trip, edge cases (empty, odd-length,
// invalid characters, uppercase/lowercase), and ASCII classification.

///|
test "hex encode produces lowercase hex from bytes" {
  inspect(hex_encode([b'\x00']), content="00")
  inspect(hex_encode([b'\xff']), content="ff")
  inspect(hex_encode([b'\x4d', b'\x5a']), content="4d5a")
  inspect(hex_encode([b'\xde', b'\xad', b'\xbe', b'\xef']), content="deadbeef")
  inspect(hex_encode([]), content="")
}

///|
test "hex decode round-trips encoded output" {
  let original = [b'\x00', b'\x01', b'\x7f', b'\x80', b'\xff', b'\xab', b'\xcd']
  let encoded = hex_encode(original)
  match hex_decode(encoded) {
    Ok(decoded) => {
      inspect(decoded.length() == original.length(), content="true")
      for i = 0; i < original.length(); i = i + 1 {
        inspect(decoded[i] == original[i], content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "hex decode accepts uppercase letters" {
  match hex_decode("4D5A") {
    Ok(bytes) => {
      inspect(bytes.length() == 2, content="true")
      inspect(bytes[0] == b'\x4d', content="true")
      inspect(bytes[1] == b'\x5a', content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "hex decode accepts mixed case" {
  match hex_decode("DeAdBeEf") {
    Ok(bytes) => {
      inspect(bytes[0] == b'\xde', content="true")
      inspect(bytes[1] == b'\xad', content="true")
      inspect(bytes[2] == b'\xbe', content="true")
      inspect(bytes[3] == b'\xef', content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "hex decode rejects odd-length input" {
  match hex_decode("abc") {
    Ok(_) => inspect(false, content="true")
    Err(e) => {
      inspect(e.operation() == Some("text-hex-decode"), content="true")
      inspect(e.context() == Some("text-hex-decode-odd-length"), content="true")
    }
  }
}

///|
test "hex decode rejects invalid characters" {
  match hex_decode("xy00") {
    Ok(_) => inspect(false, content="true")
    Err(e) => {
      inspect(e.operation() == Some("text-hex-decode"), content="true")
      inspect(e.context() == Some("text-hex-decode-invalid-character"), content="true")
    }
  }
}

///|
test "hex decode rejects embedded whitespace and 0x prefix" {
  // No whitespace tolerance.
  match hex_decode("00 11") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
  // No 0x prefix tolerance.
  match hex_decode("0xff") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}

///|
test "hex encode then decode is identity for all byte values" {
  for b = 0; b < 256; b = b + 1 {
    let encoded = hex_encode([b.to_byte()])
    match hex_decode(encoded) {
      Ok(decoded) => inspect(decoded[0] == b.to_byte(), content="true")
      Err(_) => inspect(false, content="true")
    }
  }
}

// ---------------------------------------------------------------------------
// ASCII classification
// ---------------------------------------------------------------------------

///|
test "is_ascii_digit classifies 0-9 only" {
  inspect(is_ascii_digit(0x30), content="true") // '0'
  inspect(is_ascii_digit(0x39), content="true") // '9'
  inspect(is_ascii_digit(0x2f), content="false") // '/'
  inspect(is_ascii_digit(0x3a), content="false") // ':'
}

///|
test "is_ascii_alpha classifies A-Z and a-z only" {
  inspect(is_ascii_alpha(0x41), content="true") // 'A'
  inspect(is_ascii_alpha(0x5a), content="true") // 'Z'
  inspect(is_ascii_alpha(0x61), content="true") // 'a'
  inspect(is_ascii_alpha(0x7a), content="true") // 'z'
  inspect(is_ascii_alpha(0x40), content="false") // '@'
  inspect(is_ascii_alpha(0x5b), content="false") // '['
}

///|
test "is_ascii_alphanumeric classifies letters and digits" {
  inspect(is_ascii_alphanumeric(0x30), content="true") // '0'
  inspect(is_ascii_alphanumeric(0x41), content="true") // 'A'
  inspect(is_ascii_alphanumeric(0x61), content="true") // 'a'
  inspect(is_ascii_alphanumeric(0x20), content="false") // space
  inspect(is_ascii_alphanumeric(0x2d), content="false") // '-'
}

///|
test "is_ascii detects pure ASCII and non-ASCII strings" {
  inspect(is_ascii("hello"), content="true")
  inspect(is_ascii("ABC123"), content="true")
  inspect(is_ascii(""), content="true") // empty is ASCII
  // Latin-1 supplement characters have code units > 0x7f.
  inspect(is_ascii("\u{00e9}"), content="false") // 'é'
}

///|
test "is_ascii_upper and is_ascii_lower are mutually exclusive for letters" {
  inspect(is_ascii_upper(0x41) && !is_ascii_lower(0x41), content="true") // 'A'
  inspect(is_ascii_lower(0x61) && !is_ascii_upper(0x61), content="true") // 'a'
  inspect(is_ascii_upper(0x30), content="false") // digit is neither
  inspect(is_ascii_lower(0x30), content="false")
}
