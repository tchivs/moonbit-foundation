// White-box tests for base64 encoding/decoding (RFC 4648).
//
// Uses RFC 4648 section 10 test vectors plus round-trip and edge cases.

///|
test "base64 encode follows RFC 4648 test vectors" {
  // RFC 4648 section 10 standard alphabet vectors.
  inspect(base64_encode([]), content="")
  inspect(base64_encode([b'\x66']), content="Zg==")
  inspect(base64_encode([b'\x66', b'\x6f']), content="Zm8=")
  inspect(base64_encode([b'\x66', b'\x6f', b'\x6f']), content="Zm9v")
  inspect(base64_encode([b'\x66', b'\x6f', b'\x6f', b'\x62']), content="Zm9vYg==")
  inspect(base64_encode([b'\x66', b'\x6f', b'\x6f', b'\x62', b'\x61']), content="Zm9vYmE=")
  inspect(base64_encode([b'\x66', b'\x6f', b'\x6f', b'\x62', b'\x61', b'\x72']), content="Zm9vYmFy")
}

///|
test "base64 decode round-trips RFC 4648 vectors" {
  let original = [b'\x66', b'\x6f', b'\x6f', b'\x62', b'\x61', b'\x72']
  match base64_decode("Zm9vYmFy") {
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
test "base64 decode handles padding correctly" {
  // Two-pad case (1 byte out).
  match base64_decode("Zg==") {
    Ok(bytes) => {
      inspect(bytes.length() == 1, content="true")
      inspect(bytes[0] == b'\x66', content="true")
    }
    Err(_) => inspect(false, content="true")
  }
  // One-pad case (2 bytes out).
  match base64_decode("Zm8=") {
    Ok(bytes) => {
      inspect(bytes.length() == 2, content="true")
      inspect(bytes[0] == b'\x66', content="true")
      inspect(bytes[1] == b'\x6f', content="true")
    }
    Err(_) => inspect(false, content="true")
  }
  // No-pad case (3 bytes out).
  match base64_decode("Zm9v") {
    Ok(bytes) => inspect(bytes.length() == 3, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "base64 decode rejects non-multiple-of-4 length" {
  match base64_decode("Zm9vY") {
    Ok(_) => inspect(false, content="true")
    Err(e) => {
      inspect(e.operation() == Some("text-base64-decode"), content="true")
      inspect(e.context() == Some("text-base64-decode-invalid-length"), content="true")
    }
  }
}

///|
test "base64 decode rejects invalid characters" {
  match base64_decode("Zm9!Yg==") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-base64-decode-invalid-character"), content="true")
  }
}

///|
test "base64 decode rejects misplaced padding" {
  // Pad in first position of a group is structurally invalid.
  match base64_decode("=m9vYg==") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-base64-decode-invalid-character"), content="true")
  }
  // One pad then data in the same group is invalid padding.
  match base64_decode("Zg=v") {
    Ok(_) => inspect(false, content="true")
    Err(e) => {
      inspect(e.context() == Some("text-base64-decode-invalid-padding"), content="true")
    }
  }
}

///|
test "base64 encode then decode is identity for all byte counts 0-6" {
  for count = 0; count <= 6; count = count + 1 {
    let original : Array[Byte] = []
    for j = 0; j < count; j = j + 1 {
      original.push((j * 37 + 1).to_byte())
    }
    let encoded = base64_encode(original)
    match base64_decode(encoded) {
      Ok(decoded) => {
        inspect(decoded.length() == original.length(), content="true")
        for i = 0; i < original.length(); i = i + 1 {
          inspect(decoded[i] == original[i], content="true")
        }
      }
      Err(_) => inspect(false, content="true")
    }
  }
}

///|
test "base64 encode handles all 256 byte values in a round-trip" {
  let original : Array[Byte] = []
  for b = 0; b < 256; b = b + 1 {
    original.push(b.to_byte())
  }
  let encoded = base64_encode(original)
  match base64_decode(encoded) {
    Ok(decoded) => {
      inspect(decoded.length() == 256, content="true")
      for i = 0; i < 256; i = i + 1 {
        inspect(decoded[i] == original[i], content="true")
      }
    }
    Err(_) => inspect(false, content="true")
  }
}
