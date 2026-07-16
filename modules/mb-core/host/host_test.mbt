///|
test "file and resource capabilities are independently injectable" {
  let files = @host.FakeFileCapability::new("asset.bin", b"file")
  let resources = @host.FakeResourceResolver::new("logo", b"resource")
  inspect(files.read("asset.bin").unwrap() == b"file", content="true")
  inspect(resources.resolve("logo").unwrap() == b"resource", content="true")
  inspect(files.read("missing").unwrap_err().code() == @error.ErrorCode::CapabilityUnavailable, content="true")
}

///|
test "diagnostics clock and cancellation compose without an aggregate host" {
  let diagnostics = @host.FakeDiagnosticSink::new()
  let clock = @host.FakeClock::new(40UL)
  let cancellation = @host.FakeCancellation::new(false)
  diagnostics.emit(@error.Diagnostic::new(
    @error.DiagnosticSeverity::Warning,
    @error.CoreError::new(
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
      operation="header",
    ),
  )).unwrap()
  inspect(diagnostics.length(), content="1")
  inspect(clock.now_millis().unwrap(), content="40")
  clock.advance(2UL).unwrap()
  inspect(clock.now_millis().unwrap(), content="42")
  inspect(cancellation.is_cancelled(), content="false")
  cancellation.cancel()
  inspect(cancellation.is_cancelled(), content="true")
}

///|
test "portable doubles keep interleaved state instance local" {
  let first = @host.FakeClock::new(1UL)
  let second = @host.FakeClock::new(100UL)
  first.advance(2UL).unwrap()
  second.advance(5UL).unwrap()
  first.advance(3UL).unwrap()
  inspect(first.now_millis().unwrap(), content="6")
  inspect(second.now_millis().unwrap(), content="105")
}

///|
test "fake adapter failures discard foreign platform details" {
  let files = @host.FakeFileCapability::failing(
    "C:\\secret\\asset.bin: Win32Exception 5",
  )
  let error = files.read("asset.bin").unwrap_err()
  inspect(
    @error.render_error(error),
    content="error|category=host|code=host-operation-failed|operation=\"file_read\"",
  )
}
