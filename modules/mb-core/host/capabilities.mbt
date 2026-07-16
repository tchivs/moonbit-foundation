///|
/// Read bytes from an explicitly supplied file-like capability. This contract
/// does not discover or open an ambient filesystem.
pub(open) trait FileCapability {
  fn read(Self, String) -> Result[Bytes, @error.CoreError]
}

///|
/// Receive structured diagnostics in encounter order.
pub(open) trait DiagnosticSink {
  fn emit(Self, @error.Diagnostic) -> Result[Unit, @error.CoreError]
}

///|
/// Supply a logical millisecond value without consulting an ambient clock.
pub(open) trait Clock {
  fn now_millis(Self) -> Result[UInt64, @error.CoreError]
}

///|
/// Report cooperative cancellation through an explicitly supplied instance.
pub(open) trait Cancellation {
  fn is_cancelled(Self) -> Bool
}

///|
/// Resolve a logical resource name without prescribing filesystem, network,
/// process, or registry behavior.
pub(open) trait ResourceResolver {
  fn resolve(Self, String) -> Result[Bytes, @error.CoreError]
}

///|
fn capability_unavailable(
  operation : String,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation~,
    context~,
  )
}
