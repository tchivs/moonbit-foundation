///|
test "adapter context is bounded before rendering" {
  let long = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  inspect(bound_context(long).length(), content="96")
}

///|
test "field escaping is ordered and idempotently canonical" {
  inspect(
    escape_field("a\\b\nc\rd\te|f=\"g\""),
    content="a\\\\b\\nc\\rd\\te\\|f\\=\\\"g\\\"",
  )
}

///|
test "incomplete range context never renders a misleading range" {
  let error = CoreError::new(
    ErrorCategory::InvalidInput,
    ErrorCode::InvalidRange,
    range_start=3UL,
  )
  inspect(
    render_error(error),
    content="error|category=invalid-input|code=invalid-range",
  )
}
