// Public entry points for mb-svg: parse SVG source into a scene tree and lower
// it onto a mb-canvas drawing list.

///|
/// Construct a CoreError for an SVG parse/lower failure.
fn svg_error(context : String, message : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="svg",
    context=context + ": " + message,
  )
}

// Shared numeric-admission contract for SVG source and derived scalar routes.
// Context tokens are stable public diagnostics; the message is intentionally
// not part of the contract.

///|
fn svg_numeric_error(
  code : @error.ErrorCode,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    code,
    operation="svg",
    context~,
  )
}

///|
fn admit_svg_numeric_source(value : Double) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() {
    Err(
      svg_numeric_error(
        @error.ErrorCode::InvalidEncoding,
        "svg-numeric-nonfinite",
      ),
    )
  } else if value.abs() > 65536.0 {
    Err(svg_numeric_error(@error.ErrorCode::InvalidRange, "svg-numeric-range"))
  } else {
    Ok(value)
  }
}
