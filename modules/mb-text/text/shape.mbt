///|
fn text_shape_invalid_scalar(index : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="text-shape",
    requested=index,
    context="unicode-scalar",
  )
}

///|
fn text_shape_layout_unavailable() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="text-shape",
    context="layout-unavailable",
  )
}

///|
fn validate_and_snapshot_scalars(
  scalars : Array[Int],
) -> Result[Array[Int], @error.CoreError] {
  let mut index = 0UL
  for scalar in scalars {
    if scalar < 0 || scalar > 0x10FFFF || (scalar >= 0xD800 && scalar <= 0xDFFF) {
      return Err(text_shape_invalid_scalar(index))
    }
    index = index + 1UL
  }
  Ok(scalars.copy())
}

///|
/// Shape one bounded scalar array through the retained-font transaction.
///
/// Phase 108 publishes the production empty tracer. Non-empty requests fail
/// closed until selected layout authority is admitted by the following phase.
pub fn shape(
  font : @font.Font,
  scalars : Array[Int],
  options : ShapingOptions,
  limits : ShapeLimits,
  budget : @budget.Budget,
) -> Result[ShapedRun, @error.CoreError] {
  match options.validate() {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let snapshot = match validate_and_snapshot_scalars(scalars) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  font.with_shape_transaction(budget, fn(scope) {
    let units_per_em = match scope.units_per_em() {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if snapshot.length() != 0 {
      return Err(text_shape_layout_unavailable())
    }
    if snapshot.length().to_uint64() > limits.max_input_scalars() {
      return Err(
        @error.CoreError::new(
          @error.ErrorCategory::Resource,
          @error.ErrorCode::BudgetExceeded,
          operation="text-shape",
          requested=snapshot.length().to_uint64(),
          limit=limits.max_input_scalars(),
          context="max-input-scalars",
        ),
      )
    }
    let run = empty_shaped_run(units_per_em, options.direction())
    let charge = @budget.ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=1UL,
    )
    Ok((run, charge))
  })
}
