// White-box tests for percent-encoding/decoding.

///|
test "percent encode leaves unreserved characters unchanged" {
  inspect(percent_encode("hello") == "hello", content="true")
  inspect(percent_encode("ABC123-_.~") == "ABC123-_.~", content="true")
  inspect(percent_encode("") == "", content="true")
}

///|
test "percent encode encodes special characters" {
  // space = %20
  inspect(percent_encode(" ") == "%20", content="true")
  // '/' = %2F
  inspect(percent_encode("/") == "%2F", content="true")
  // '<' = %3C
  inspect(percent_encode("<") == "%3C", content="true")
}

///|
test "percent encode encodes full URL path" {
  let encoded = percent_encode("hello world/test")
  inspect(encoded == "hello%20world%2Ftest", content="true")
}

///|
test "percent decode reverses encoding" {
  match percent_decode("hello%20world%2Ftest") {
    Ok(bytes) => {
      inspect(bytes.length() == 16, content="true")
      inspect(bytes[5] == b' ', content="true")
      inspect(bytes[11] == b'/', content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "percent decode passes through unreserved" {
  match percent_decode("hello123") {
    Ok(bytes) => inspect(bytes.length() == 8, content="true")
    Err(_) => inspect(false, content="true")
  }
}

///|
test "percent encode then decode is identity" {
  let original = "Hello, World! 123"
  let encoded = percent_encode(original)
  match percent_decode(encoded) {
    Ok(bytes) => {
      // Reconstruct string from bytes.
      let buffer = StringBuilder::new()
      for b in bytes {
        ignore(buffer.write_char(b.to_int().to_char().unwrap()))
      }
      inspect(buffer.to_string() == original, content="true")
    }
    Err(_) => inspect(false, content="true")
  }
}

///|
test "percent decode rejects truncated percent" {
  match percent_decode("abc%2") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-percent-decode-truncated"), content="true")
  }
  match percent_decode("abc%") {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}

///|
test "percent decode rejects invalid hex" {
  match percent_decode("abc%XY") {
    Ok(_) => inspect(false, content="true")
    Err(e) => inspect(e.context() == Some("text-percent-decode-invalid-hex"), content="true")
  }
}
