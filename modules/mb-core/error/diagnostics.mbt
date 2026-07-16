///|
/// Severity for a non-fatal diagnostic.
pub(all) enum DiagnosticSeverity {
  Note
  Warning
  Error
} derive(Eq)

///|
/// One structured diagnostic.
pub struct Diagnostic {
  priv severity_value : DiagnosticSeverity
  priv error_value : CoreError
}

///|
pub fn Diagnostic::new(
  severity : DiagnosticSeverity,
  error : CoreError,
) -> Diagnostic {
  { severity_value: severity, error_value: error }
}

///|
pub fn Diagnostic::severity(self : Diagnostic) -> DiagnosticSeverity {
  self.severity_value
}

///|
pub fn Diagnostic::error(self : Diagnostic) -> CoreError {
  self.error_value
}

///|
fn DiagnosticSeverity::token(self : DiagnosticSeverity) -> String {
  match self {
    Note => "note"
    Warning => "warning"
    Error => "error"
  }
}

///|
pub fn render_diagnostic(diagnostic : Diagnostic) -> String {
  diagnostic.severity_value.token() + "|" + render_error(diagnostic.error_value)
}

///|
/// An encounter-ordered collection of diagnostics.
pub struct Diagnostics {
  priv items : Array[Diagnostic]
}

///|
pub fn Diagnostics::new() -> Diagnostics {
  { items: Array::new() }
}

///|
pub fn Diagnostics::push(self : Diagnostics, diagnostic : Diagnostic) -> Unit {
  self.items.push(diagnostic)
}

///|
pub fn Diagnostics::length(self : Diagnostics) -> Int {
  self.items.length()
}

///|
pub fn Diagnostics::render(self : Diagnostics) -> String {
  let mut result = ""
  for index = 0; index < self.items.length(); index = index + 1 {
    if index > 0 {
      result = result + "\n"
    }
    result = result + render_diagnostic(self.items[index])
  }
  result
}
