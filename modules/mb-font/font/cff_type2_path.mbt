///|
/// Private exact-capacity output sink for selected Type 2 execution.
priv struct Type2PathSink {
  path : @math.Path2
  matrix : Type2Matrix
}

///|
fn type2_rational_to_double(
  value : Type2Rational,
) -> Result[Double, @error.CoreError] {
  if value.denominator <= 0L {
    return Err(type2_data_error("font-cff-type2-path-coordinate"))
  }
  let whole = value.numerator / value.denominator
  let remainder = value.numerator % value.denominator
  let converted = whole.to_double() +
    remainder.to_double() / value.denominator.to_double()
  if converted.is_nan() || converted.is_inf() {
    Err(type2_data_error("font-cff-type2-path-coordinate"))
  } else {
    Ok(converted)
  }
}

///|
fn Type2PathSink::new(capacity : Int, matrix : Type2Matrix) -> Type2PathSink {
  { path: @math.Path2::with_capacity(capacity), matrix }
}

///|
fn Type2PathSink::point(
  self : Type2PathSink,
  x : Type2Fixed,
  y : Type2Fixed,
) -> Result[@math.Point2, @error.CoreError] {
  let transformed = match type2_matrix_apply(self.matrix, x, y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let converted_x = match type2_rational_to_double(transformed.0) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let converted_y = match type2_rational_to_double(transformed.1) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@math.Point2::new(converted_x, converted_y))
}

///|
fn Type2PathSink::move_to(
  self : Type2PathSink,
  x : Type2Fixed,
  y : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let point = match self.point(x, y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.path.push(@math.PathCommand::MoveTo(point))
  Ok(())
}

///|
fn Type2PathSink::line_to(
  self : Type2PathSink,
  x : Type2Fixed,
  y : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let point = match self.point(x, y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.path.push(@math.PathCommand::LineTo(point))
  Ok(())
}

///|
fn Type2PathSink::cubic_to(
  self : Type2PathSink,
  control1_x : Type2Fixed,
  control1_y : Type2Fixed,
  control2_x : Type2Fixed,
  control2_y : Type2Fixed,
  end_x : Type2Fixed,
  end_y : Type2Fixed,
) -> Result[Unit, @error.CoreError] {
  let control1 = match self.point(control1_x, control1_y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let control2 = match self.point(control2_x, control2_y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let end = match self.point(end_x, end_y) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  self.path.push(@math.PathCommand::CubicTo(control1, control2, end))
  Ok(())
}

///|
fn Type2PathSink::close(self : Type2PathSink) -> Unit {
  self.path.push(@math.PathCommand::Close)
}

///|
/// Exact authority facts for one selected CFF outline transaction.
priv struct CffPathCharge {
  resource : @budget.ResourceCharge
  bytes : UInt64
  allocations : UInt64
  allocation_size : UInt64
  work : UInt64
  command_capacity : UInt64
}

///|
fn cff_path_charge(
  limits : Type2Limits,
  command_capacity : UInt64,
  work : UInt64,
) -> Result[CffPathCharge, @error.CoreError] {
  let bytes = match @checked.checked_mul(command_capacity, 64UL) {
    Err(_) =>
      return Err(
        type2_resource_error(
          "font-cff-type2-path-bytes",
          command_capacity,
          18446744073709551615UL,
        ),
      )
    Ok(value) => value
  }
  let allocations = match
    @checked.checked_add(
      limits.scratch_allocations,
      if command_capacity == 0UL { 0UL } else { 1UL },
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let allocation_size = if bytes > limits.scratch_allocation_size {
    bytes
  } else {
    limits.scratch_allocation_size
  }
  Ok({
    resource: @budget.ResourceCharge::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work~,
    ),
    bytes,
    allocations,
    allocation_size,
    work,
    command_capacity,
  })
}

///|
fn cff_decode_outline_atomic(
  source : @bytes.ByteView,
  admitted : AdmittedCff1,
  glyph : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
  after_stage : () -> Unit,
) -> Result[@math.Path2, @error.CoreError] {
  cff_decode_outline_atomic_with_probes(
    source,
    admitted,
    glyph,
    limits,
    budget,
    fn() { () },
    after_stage,
  )
}

///|
/// White-box query probes are restricted to authorized pre-commit seams.
///
/// Production callers use `cff_decode_outline_atomic`, which supplies no-op
/// probes. The complete path remains private until the final revision guard
/// and the sole budget commit.
fn cff_decode_outline_atomic_with_probes(
  source : @bytes.ByteView,
  admitted : AdmittedCff1,
  glyph : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
  before_execute : () -> Unit,
  after_stage : () -> Unit,
) -> Result[@math.Path2, @error.CoreError] {
  if source.mutation_revision() != admitted.opening_revision {
    return Err(font_revision_error("font-outline"))
  }
  let index = match @checked.checked_narrow_int(glyph) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if index < 0 ||
    index >= admitted.glyphs.length() ||
    index >= admitted.path_command_counts.length() {
    return Err(
      font_glyph_id_error("font-outline", glyph, admitted.num_glyphs),
    )
  }
  before_execute()
  if source.mutation_revision() != admitted.opening_revision {
    return Err(font_revision_error("font-outline"))
  }
  let vm_limits = match type2_limits(limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let command_capacity = admitted.path_command_counts[index]
  let capacity = match @checked.checked_narrow_int(command_capacity) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let fixed_charge = match
    cff_path_charge(vm_limits, command_capacity, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.preflight(fixed_charge.resource) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let executed = match
    type2_execute_glyph_with_path_capacity(
      admitted.glyphs[index],
      admitted.global_subrs,
      admitted.metrics.units_per_em,
      vm_limits,
      admitted.opening_revision,
      Some(capacity),
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if executed.geometry.path_commands != command_capacity {
    return Err(type2_data_error("font-cff-type2-path-command-count"))
  }
  let path = match executed.geometry.path {
    None => return Err(type2_data_error("font-cff-type2-path-missing"))
    Some(value) => value
  }
  if path.length().to_uint64() != command_capacity {
    return Err(type2_data_error("font-cff-type2-path-command-count"))
  }
  let path_work = match
    @checked.checked_add(
      executed.geometry.points,
      executed.geometry.path_commands,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(executed.ledger.work, path_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let exact_charge = match cff_path_charge(vm_limits, command_capacity, work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.preflight(exact_charge.resource) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  after_stage()
  if source.mutation_revision() != admitted.opening_revision {
    return Err(font_revision_error("font-outline"))
  }
  match budget.charge(exact_charge.resource) {
    Err(error) => return Err(error)
    Ok(_) => Ok(path)
  }
}
