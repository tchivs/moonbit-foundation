///|
/// A deterministic one-entry file-capability double. It models an injected
/// adapter without claiming access to a native filesystem.
pub struct FakeFileCapability {
  priv name : String
  priv contents : Bytes
  priv fail : Bool
}

///|
pub fn FakeFileCapability::new(name : String, contents : Bytes) -> Self {
  { name, contents, fail: false }
}

///|
/// Construct a rejecting adapter double. Foreign detail is deliberately
/// discarded at construction, just as a real adapter boundary must discard it.
pub fn FakeFileCapability::failing(_foreign_detail : String) -> Self {
  { name: "", contents: b"", fail: true }
}

///|
pub impl FileCapability for FakeFileCapability with fn read(self, name) {
  if self.fail {
    Err(@error.map_host_failure("file_read", "discarded"))
  } else if name == self.name {
    Ok(self.contents)
  } else {
    Err(capability_unavailable("file_read", name))
  }
}

///|
/// Encounter-ordered diagnostic sink with instance-local storage.
pub struct FakeDiagnosticSink {
  priv diagnostics : @error.Diagnostics
  priv fail : Bool
}

///|
pub fn FakeDiagnosticSink::new() -> Self {
  { diagnostics: @error.Diagnostics::new(), fail: false }
}

///|
pub fn FakeDiagnosticSink::failing(_foreign_detail : String) -> Self {
  { diagnostics: @error.Diagnostics::new(), fail: true }
}

///|
pub impl DiagnosticSink for FakeDiagnosticSink with fn emit(self, diagnostic) {
  if self.fail {
    Err(@error.map_host_failure("diagnostic_emit", "discarded"))
  } else {
    self.diagnostics.push(diagnostic)
    Ok(())
  }
}

///|
pub fn FakeDiagnosticSink::length(self : Self) -> Int {
  self.diagnostics.length()
}

///|
pub fn FakeDiagnosticSink::render(self : Self) -> String {
  self.diagnostics.render()
}

///|
/// Deterministic logical clock. Each instance owns its own mutable value.
pub struct FakeClock {
  priv mut current : UInt64
  priv fail : Bool
}

///|
pub fn FakeClock::new(current : UInt64) -> Self {
  { current, fail: false }
}

///|
pub fn FakeClock::failing(_foreign_detail : String) -> Self {
  { current: 0UL, fail: true }
}

///|
pub impl Clock for FakeClock with fn now_millis(self) {
  if self.fail {
    Err(@error.map_host_failure("clock_now", "discarded"))
  } else {
    Ok(self.current)
  }
}

///|
pub fn FakeClock::advance(
  self : Self,
  amount : UInt64,
) -> Result[Unit, @error.CoreError] {
  match @checked.checked_add(self.current, amount) {
    Err(error) => Err(error)
    Ok(next) => {
      self.current = next
      Ok(())
    }
  }
}

///|
/// Instance-local cooperative cancellation double.
pub struct FakeCancellation {
  priv mut cancelled : Bool
}

///|
pub fn FakeCancellation::new(cancelled : Bool) -> Self {
  { cancelled, }
}

///|
pub impl Cancellation for FakeCancellation with fn is_cancelled(self) {
  self.cancelled
}

///|
pub fn FakeCancellation::cancel(self : Self) -> Unit {
  self.cancelled = true
}

///|
pub fn FakeCancellation::reset(self : Self) -> Unit {
  self.cancelled = false
}

///|
/// Deterministic one-entry logical-resource resolver.
pub struct FakeResourceResolver {
  priv name : String
  priv contents : Bytes
  priv fail : Bool
}

///|
pub fn FakeResourceResolver::new(name : String, contents : Bytes) -> Self {
  { name, contents, fail: false }
}

///|
pub fn FakeResourceResolver::failing(_foreign_detail : String) -> Self {
  { name: "", contents: b"", fail: true }
}

///|
pub impl ResourceResolver for FakeResourceResolver with fn resolve(self, name) {
  if self.fail {
    Err(@error.map_host_failure("resource_resolve", "discarded"))
  } else if name == self.name {
    Ok(self.contents)
  } else {
    Err(capability_unavailable("resource_resolve", name))
  }
}
