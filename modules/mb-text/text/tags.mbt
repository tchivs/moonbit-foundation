///|
/// A checked four-byte OpenType script tag.
pub struct ScriptTag {
  priv bytes_value : Bytes
} derive(Eq)

///|
/// A checked four-byte OpenType language tag.
pub struct LanguageTag {
  priv bytes_value : Bytes
} derive(Eq)

///|
fn text_tag_error(operation : String, context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation~,
    context~,
  )
}

///|
fn validate_tag_bytes(
  value : Bytes,
  operation : String,
  context : String,
) -> Result[Unit, @error.CoreError] {
  if value.length() != 4 {
    return Err(text_tag_error(operation, context))
  }
  for byte in value {
    if byte < b'\x20' || byte > b'\x7e' {
      return Err(text_tag_error(operation, context))
    }
  }
  Ok(())
}

///|
pub fn ScriptTag::new(value : Bytes) -> Result[ScriptTag, @error.CoreError] {
  match validate_tag_bytes(value, "text-script-tag-new", "script-tag") {
    Err(error) => Err(error)
    Ok(_) => Ok({ bytes_value: value })
  }
}

///|
pub fn ScriptTag::bytes(self : ScriptTag) -> Bytes {
  self.bytes_value
}

///|
fn ScriptTag::validate(self : ScriptTag) -> Result[Unit, @error.CoreError] {
  validate_tag_bytes(self.bytes_value, "text-shape", "script-tag")
}

///|
pub fn LanguageTag::new(value : Bytes) -> Result[LanguageTag, @error.CoreError] {
  match validate_tag_bytes(value, "text-language-tag-new", "language-tag") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if value == b"dflt" || value == b"DFLT" {
    return Err(text_tag_error("text-language-tag-new", "language-default"))
  }
  Ok({ bytes_value: value })
}

///|
pub fn LanguageTag::bytes(self : LanguageTag) -> Bytes {
  self.bytes_value
}

///|
fn LanguageTag::validate(self : LanguageTag) -> Result[Unit, @error.CoreError] {
  match validate_tag_bytes(self.bytes_value, "text-shape", "language-tag") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if self.bytes_value == b"dflt" || self.bytes_value == b"DFLT" {
    Err(text_tag_error("text-shape", "language-default"))
  } else {
    Ok(())
  }
}
