///|
/// Explicit non-zero semantic ceilings for one shaping request.
pub struct ShapeLimits {
  priv max_input_scalars_value : UInt64
  priv max_output_glyphs_value : UInt64
}

///|
fn invalid_shape_limit(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="text-shape-limits-new",
    requested=0UL,
    limit=1UL,
    context~,
  )
}

///|
pub fn ShapeLimits::new(
  max_input_scalars~ : UInt64,
  max_output_glyphs~ : UInt64,
) -> Result[ShapeLimits, @error.CoreError] {
  if max_input_scalars == 0UL {
    return Err(invalid_shape_limit("max-input-scalars"))
  }
  if max_output_glyphs == 0UL {
    return Err(invalid_shape_limit("max-output-glyphs"))
  }
  Ok({
    max_input_scalars_value: max_input_scalars,
    max_output_glyphs_value: max_output_glyphs,
  })
}

///|
pub fn ShapeLimits::max_input_scalars(self : ShapeLimits) -> UInt64 {
  self.max_input_scalars_value
}

///|
pub fn ShapeLimits::max_output_glyphs(self : ShapeLimits) -> UInt64 {
  self.max_output_glyphs_value
}
