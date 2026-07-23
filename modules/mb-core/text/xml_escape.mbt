// XML/HTML text escaping for MoonBit Native Foundation.
//
// Consumed by mb-svg (text content and attribute output), mb-pdf (string
// escaping in content streams), and any XML-generating tool. Escapes the
// five predefined XML entities and optionally quotes.

///|
/// Escape a string for safe inclusion in XML text content.
///
/// Replaces `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`. Does not escape
/// quotes (use `escape_xml_attribute` for attribute values).
pub fn escape_xml_text(text : String) -> String {
  let units = text.code_units()
  let buffer = StringBuilder::new()
  for i = 0; i < units.length(); i = i + 1 {
    let c = units[i].to_int()
    match c {
      0x26 => append_str(buffer, "&amp;") // &
      0x3c => append_str(buffer, "&lt;") // <
      0x3e => append_str(buffer, "&gt;") // >
      _ => ignore(buffer.write_char(c.to_char().unwrap()))
    }
  }
  buffer.to_string()
}

///|
/// Escape a string for safe inclusion in XML attribute values.
///
/// In addition to the text-content escapes, also replaces `"` → `&quot;`
/// and `'` → `&apos;`.
pub fn escape_xml_attribute(text : String) -> String {
  let units = text.code_units()
  let buffer = StringBuilder::new()
  for i = 0; i < units.length(); i = i + 1 {
    let c = units[i].to_int()
    match c {
      0x26 => append_str(buffer, "&amp;") // &
      0x3c => append_str(buffer, "&lt;") // <
      0x3e => append_str(buffer, "&gt;") // >
      0x22 => append_str(buffer, "&quot;") // "
      0x27 => append_str(buffer, "&apos;") // '
      _ => ignore(buffer.write_char(c.to_char().unwrap()))
    }
  }
  buffer.to_string()
}

///|
/// Unescape XML entities back to raw characters.
///
/// Reverses `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&apos;`, and numeric
/// entities `&#NN;` / `&#xHH;`. Returns the input unchanged (without the
/// unescaped portion) if an unrecognized entity is encountered.
pub fn unescape_xml(text : String) -> String {
  let units = text.code_units()
  let len = units.length()
  let buffer = StringBuilder::new()
  let mut i = 0
  while i < len {
    let c = units[i].to_int()
    if c == 0x26 {
      // '&' — look for entity
      match find_entity_end(units, i) {
        Some(end) => {
          let entity = substring(units, i, end + 1)
          match decode_entity(entity) {
            Some(ch) => ignore(buffer.write_char(ch))
            None => append_str(buffer, entity)
          }
          i = end + 1
        }
        None => {
          ignore(buffer.write_char('&'.to_int().to_char().unwrap()))
          i = i + 1
        }
      }
    } else {
      ignore(buffer.write_char(c.to_char().unwrap()))
      i = i + 1
    }
  }
  buffer.to_string()
}

///|
fn append_str(buffer : StringBuilder, s : String) -> Unit {
  for ch in s.code_units() {
    ignore(buffer.write_char(ch.to_int().to_char().unwrap()))
  }
}

///|
/// Find the ';' that ends an entity starting at position `start` (the '&').
/// Returns the index of ';' or None if no ';' is found within 12 chars.
fn find_entity_end(units : ArrayView[UInt16], start : Int) -> Int? {
  let limit = if start + 12 < units.length() {
    start + 12
  } else {
    units.length() - 1
  }
  for i = start + 1; i <= limit; i = i + 1 {
    if units[i].to_int() == 0x3b {
      // ';'
      return Some(i)
    }
  }
  None
}

///|
fn substring(units : ArrayView[UInt16], start : Int, end : Int) -> String {
  let buffer = StringBuilder::new()
  for i = start; i < end; i = i + 1 {
    ignore(buffer.write_char(units[i].to_int().to_char().unwrap()))
  }
  buffer.to_string()
}

///|
fn decode_entity(entity : String) -> Char? {
  // Named entities.
  match entity {
    "&amp;" => Some('&'.to_int().to_char().unwrap())
    "&lt;" => Some('<'.to_int().to_char().unwrap())
    "&gt;" => Some('>'.to_int().to_char().unwrap())
    "&quot;" => Some('"'.to_int().to_char().unwrap())
    "&apos;" => Some('\''.to_int().to_char().unwrap())
    _ => {
      // Numeric: &#NN; or &#xHH;
      let inner = entity.substring(start=2, end=entity.length() - 1)
      if entity.length() > 3 && entity.code_units()[1].to_int() == 0x23 {
        // '#'
        if inner.length() > 0 && (inner.code_units()[0].to_int() == 0x78 || inner.code_units()[0].to_int() == 0x58) {
          // 'x' or 'X' — hex
          let hex_str = inner.substring(start=1)
          match parse_hex_int(hex_str) {
            Some(v) => v.to_char()
            None => None
          }
        } else {
          // Decimal
          match parse_dec_int(inner) {
            Some(v) => v.to_char()
            None => None
          }
        }
      } else {
        None
      }
    }
  }
}

///|
fn parse_hex_int(s : String) -> Int? {
  let units = s.code_units()
  let mut result = 0
  for i = 0; i < units.length(); i = i + 1 {
    let c = units[i].to_int()
    let digit = if c >= 0x30 && c <= 0x39 {
      c - 0x30
    } else if c >= 0x41 && c <= 0x46 {
      c - 0x41 + 10
    } else if c >= 0x61 && c <= 0x66 {
      c - 0x61 + 10
    } else {
      return None
    }
    result = result * 16 + digit
  }
  Some(result)
}

///|
fn parse_dec_int(s : String) -> Int? {
  let units = s.code_units()
  let mut result = 0
  for i = 0; i < units.length(); i = i + 1 {
    let c = units[i].to_int()
    if c < 0x30 || c > 0x39 {
      return None
    }
    result = result * 10 + (c - 0x30)
  }
  Some(result)
}
