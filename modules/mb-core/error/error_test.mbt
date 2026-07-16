///|
test "stable category and code pairs remain machine-readable" {
  let error = @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="slice",
  )
  inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
}

///|
test "typed context fields are available without parsing prose" {
  let error = @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::UnexpectedEndOfStream,
    operation="read_exact",
    requested=12UL,
    completed=5UL,
    range_start=2UL,
    range_end=14UL,
    source_offset=7UL,
    limit=64UL,
    context="header",
  )
  inspect(error.operation(), content="Some(read_exact)")
  inspect(error.requested(), content="Some(12)")
  inspect(error.completed(), content="Some(5)")
  inspect(error.range_start(), content="Some(2)")
  inspect(error.range_end(), content="Some(14)")
  inspect(error.source_offset(), content="Some(7)")
  inspect(error.limit(), content="Some(64)")
  inspect(error.context(), content="Some(header)")
}

///|
test "canonical rendering uses fixed order and stable escaping" {
  let error = @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::UnexpectedEndOfStream,
    operation="read\nexact",
    requested=12UL,
    completed=5UL,
    range_start=2UL,
    range_end=14UL,
    source_offset=7UL,
    limit=64UL,
    context="head|er=\"x\"\\tail",
  )
  inspect(
    @error.render_error(error),
    content="error|category=data|code=unexpected-end-of-stream|operation=\"read\\nexact\"|requested=12|completed=5|range=2..14|source_offset=7|limit=64|context=\"head\\|er\\=\\\"x\\\"\\\\tail\"",
  )
}

///|
test "host mapping excludes foreign exception and platform prose" {
  let error = @error.map_host_failure(
    "resource_open",
    "C:\\secret\\asset.bin: Win32Exception 0x00000005 at 2026-07-16",
  )
  inspect(
    @error.render_error(error),
    content="error|category=host|code=host-operation-failed|operation=\"resource_open\"",
  )
}

///|
test "diagnostics preserve encounter order" {
  let diagnostics = @error.Diagnostics::new()
  diagnostics.push(
    @error.Diagnostic::new(
      @error.DiagnosticSeverity::Warning,
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="first",
      ),
    ),
  )
  diagnostics.push(
    @error.Diagnostic::new(
      @error.DiagnosticSeverity::Note,
      @error.CoreError::new(
        @error.ErrorCategory::State,
        @error.ErrorCode::NoProgress,
        operation="second",
      ),
    ),
  )
  inspect(diagnostics.length(), content="2")
  inspect(
    diagnostics.render(),
    content="warning|error|category=data|code=invalid-encoding|operation=\"first\"\nnote|error|category=state|code=no-progress|operation=\"second\"",
  )
}
