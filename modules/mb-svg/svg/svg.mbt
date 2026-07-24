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
