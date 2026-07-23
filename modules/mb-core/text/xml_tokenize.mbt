// Bounded XML/markup tokenizer for MoonBit Native Foundation.
//
// Provides a portable lexical scanner for XML-like markup used by SVG
// documents and attribute scanning shared with PDF content/resources.
// This is intentionally not a full XML 1.0 processor: no entity expansion,
// no DTD validation, no namespace resolution. Higher layers (mb-svg, mb-pdf)
// own semantic parse trees and schema limits.
//
// All operations are pure functions of their inputs: deterministic on every
// target, with structured errors for malformed markup.

// ---------------------------------------------------------------------------
// Token model
// ---------------------------------------------------------------------------

///|
/// A single lexical token from a bounded XML-like markup stream.
pub(all) enum MarkupToken {
  /// Start-tag name after `<` (e.g. `svg` in `<svg ...>`).
  StartTag(String)
  /// End-tag name after `</` (e.g. `g` in `</g>`).
  EndTag(String)
  /// Closing `>` of a start or end tag.
  TagEnd
  /// Self-closing `/>` terminator.
  EmptyTagEnd
  /// Attribute name before `=`.
  AttributeName(String)
  /// Attribute value inside quotes (quotes themselves are not included).
  AttributeValue(String)
  /// Character data between tags (whitespace-preserving; may be empty only
  /// when the input is empty — inter-tag whitespace is still emitted).
  Text(String)
  /// XML comment body between `<!--` and `-->` (delimiters stripped).
  Comment(String)
} derive(Eq)

// ---------------------------------------------------------------------------
// Public entry
// ---------------------------------------------------------------------------

///|
/// Tokenize a bounded XML-like markup string into lexical tokens.
///
/// Accepts element tags, attributes with single- or double-quoted values,
/// character data, and comments. Rejects unterminated tags/values/comments,
/// bare `<` not starting a valid tag or comment, and attribute values without
/// surrounding quotes. Namespace prefixes (`svg:rect`) are kept as part of the
/// name string; they are not split.
///
/// On failure returns `InvalidEncoding` with a stable `context` token and
/// optional `source_offset` pointing at the first bad code unit.
pub fn tokenize_markup(
  input : String,
) -> Result[Array[MarkupToken], @error.CoreError] {
  let units = input.code_units()
  let len = units.length()
  let tokens : Array[MarkupToken] = []
  let mut i = 0
  while i < len {
    let c = units[i].to_int()
    if c == 0x3c {
      // '<'
      match tokenize_markup_tag_or_comment(units, i, len) {
        Ok((toks, next)) => {
          for j = 0; j < toks.length(); j = j + 1 {
            tokens.push(toks[j])
          }
          i = next
        }
        Err(e) => return Err(e)
      }
    } else {
      // Character data until next '<' or end.
      let start = i
      while i < len && units[i].to_int() != 0x3c {
        i = i + 1
      }
      tokens.push(Text(slice_units(units, start, i)))
    }
  }
  Ok(tokens)
}

// ---------------------------------------------------------------------------
// Tag / comment body
// ---------------------------------------------------------------------------

///|
fn tokenize_markup_tag_or_comment(
  units : ArrayView[UInt16],
  start : Int,
  len : Int,
) -> Result[(Array[MarkupToken], Int), @error.CoreError] {
  // start points at '<'
  if start + 1 >= len {
    return Err(markup_error("text-markup-truncated-tag", start))
  }
  let c1 = units[start + 1].to_int()
  // Comment: <!--
  if c1 == 0x21 {
    // '!'
    return tokenize_markup_comment(units, start, len)
  }
  // End tag: </name>
  if c1 == 0x2f {
    // '/'
    return tokenize_markup_end_tag(units, start, len)
  }
  // Start tag: <name ... > or <name ... />
  tokenize_markup_start_tag(units, start, len)
}

///|
fn tokenize_markup_comment(
  units : ArrayView[UInt16],
  start : Int,
  len : Int,
) -> Result[(Array[MarkupToken], Int), @error.CoreError] {
  // Expect <!--
  if start + 3 >= len ||
    units[start + 1].to_int() != 0x21 ||
    units[start + 2].to_int() != 0x2d ||
    units[start + 3].to_int() != 0x2d {
    return Err(markup_error("text-markup-invalid-markup-declaration", start))
  }
  let body_start = start + 4
  let mut i = body_start
  while i + 2 < len {
    if units[i].to_int() == 0x2d &&
      units[i + 1].to_int() == 0x2d &&
      units[i + 2].to_int() == 0x3e {
      let body = slice_units(units, body_start, i)
      return Ok(([Comment(body)], i + 3))
    }
    i = i + 1
  }
  Err(markup_error("text-markup-unterminated-comment", start))
}

///|
fn tokenize_markup_end_tag(
  units : ArrayView[UInt16],
  start : Int,
  len : Int,
) -> Result[(Array[MarkupToken], Int), @error.CoreError] {
  // start at '<', next is '/'
  let mut i = start + 2
  i = skip_ws(units, i, len)
  match read_name(units, i, len) {
    Err(e) => Err(e)
    Ok((name, after_name)) => {
      let j = skip_ws(units, after_name, len)
      if j >= len || units[j].to_int() != 0x3e {
        return Err(markup_error("text-markup-unterminated-end-tag", start))
      }
      Ok(([EndTag(name), TagEnd], j + 1))
    }
  }
}

///|
fn tokenize_markup_start_tag(
  units : ArrayView[UInt16],
  start : Int,
  len : Int,
) -> Result[(Array[MarkupToken], Int), @error.CoreError] {
  let mut i = start + 1
  i = skip_ws(units, i, len)
  match read_name(units, i, len) {
    Err(e) => Err(e)
    Ok((name, after_name)) => {
      let toks : Array[MarkupToken] = [StartTag(name)]
      let mut j = after_name
      while true {
        j = skip_ws(units, j, len)
        if j >= len {
          return Err(markup_error("text-markup-unterminated-start-tag", start))
        }
        let c = units[j].to_int()
        if c == 0x3e {
          // '>'
          toks.push(TagEnd)
          return Ok((toks, j + 1))
        }
        if c == 0x2f {
          // '/'
          if j + 1 < len && units[j + 1].to_int() == 0x3e {
            toks.push(EmptyTagEnd)
            return Ok((toks, j + 2))
          }
          return Err(markup_error("text-markup-invalid-empty-tag", j))
        }
        // Attribute: name = "value" | name = 'value'
        match read_name(units, j, len) {
          Err(e) => return Err(e)
          Ok((attr_name, after_attr)) => {
            toks.push(AttributeName(attr_name))
            let mut k = skip_ws(units, after_attr, len)
            if k >= len || units[k].to_int() != 0x3d {
              return Err(markup_error("text-markup-missing-attribute-equals", after_attr))
            }
            k = skip_ws(units, k + 1, len)
            match read_quoted_value(units, k, len) {
              Err(e) => return Err(e)
              Ok((value, after_value)) => {
                toks.push(AttributeValue(value))
                j = after_value
              }
            }
          }
        }
      }
      // Unreachable; loop always returns.
      Err(markup_error("text-markup-internal", start))
    }
  }
}

// ---------------------------------------------------------------------------
// Scanners
// ---------------------------------------------------------------------------

///|
fn skip_ws(units : ArrayView[UInt16], start : Int, len : Int) -> Int {
  let mut i = start
  while i < len {
    let c = units[i].to_int()
    // space, tab, LF, CR
    if c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d {
      i = i + 1
    } else {
      break
    }
  }
  i
}

///|
/// XML Name with ASCII NameStartChar / NameChar subset plus ':' and '_'.
/// Sufficient for SVG element/attribute names and prefixed names.
fn read_name(
  units : ArrayView[UInt16],
  start : Int,
  len : Int,
) -> Result[(String, Int), @error.CoreError] {
  if start >= len || !is_name_start(units[start].to_int()) {
    return Err(markup_error("text-markup-invalid-name", start))
  }
  let mut i = start + 1
  while i < len && is_name_char(units[i].to_int()) {
    i = i + 1
  }
  Ok((slice_units(units, start, i), i))
}

///|
fn read_quoted_value(
  units : ArrayView[UInt16],
  start : Int,
  len : Int,
) -> Result[(String, Int), @error.CoreError] {
  if start >= len {
    return Err(markup_error("text-markup-unterminated-attribute-value", start))
  }
  let quote = units[start].to_int()
  if quote != 0x22 && quote != 0x27 {
    // " or '
    return Err(markup_error("text-markup-unquoted-attribute-value", start))
  }
  let mut i = start + 1
  while i < len {
    let c = units[i].to_int()
    if c == quote {
      return Ok((slice_units(units, start + 1, i), i + 1))
    }
    // Reject bare '<' inside attribute values (XML well-formedness).
    if c == 0x3c {
      return Err(markup_error("text-markup-invalid-attribute-value", i))
    }
    i = i + 1
  }
  Err(markup_error("text-markup-unterminated-attribute-value", start))
}

///|
fn is_name_start(code : Int) -> Bool {
  is_ascii_alpha(code) || code == 0x5f || code == 0x3a // _ :
}

///|
fn is_name_char(code : Int) -> Bool {
  is_name_start(code) ||
  is_ascii_digit(code) ||
  code == 0x2d || // -
  code == 0x2e // .
}

///|
fn slice_units(units : ArrayView[UInt16], start : Int, end_index : Int) -> String {
  let buffer = StringBuilder::new()
  for i = start; i < end_index; i = i + 1 {
    buffer.write_char(units[i].to_int().to_char().unwrap())
  }
  buffer.to_string()
}

///|
fn markup_error(context : String, offset : Int) -> @error.CoreError {
  let source_offset = if offset < 0 {
    0UL
  } else {
    offset.to_uint64()
  }
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidEncoding,
    operation="text-markup-tokenize",
    source_offset~,
    context~,
  )
}
