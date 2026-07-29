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
fn validate_and_snapshot_scalars_with_probe(
  scalars : Array[Int],
  after_snapshot : () -> Unit,
) -> Result[Array[Int], @error.CoreError] {
  let mut index = 0UL
  for scalar in scalars {
    if scalar < 0 || scalar > 0x10FFFF || (scalar >= 0xD800 && scalar <= 0xDFFF) {
      return Err(text_shape_invalid_scalar(index))
    }
    index = index + 1UL
  }
  let snapshot = scalars.copy()
  after_snapshot()
  Ok(snapshot)
}

///|
fn validate_and_snapshot_scalars(
  scalars : Array[Int],
) -> Result[Array[Int], @error.CoreError] {
  validate_and_snapshot_scalars_with_probe(scalars, fn() { () })
}

///|
priv struct GeneratedLogicalGlyph {
  glyph : @font.GlyphId
  consumed_scalar_indices : Array[UInt64]
  base_advance : Int64
  adjustment : Int64
  x_offset : Int64
  y_offset : Int64
}

///|
#warnings("-1")
fn generated_logical_glyph(
  glyph : @font.GlyphId,
  consumed_scalar_indices : Array[UInt64],
  base_advance : Int64,
  adjustment : Int64,
  x_offset : Int64,
  y_offset : Int64,
) -> GeneratedLogicalGlyph {
  {
    glyph,
    consumed_scalar_indices: consumed_scalar_indices.copy(),
    base_advance,
    adjustment,
    x_offset,
    y_offset,
  }
}

///|
priv struct TextShapeContractProbes {
  post_structure : () -> Unit
  post_capability : () -> Unit
  post_complete_staging : () -> Unit
  before_return : () -> Unit
}

///|
#warnings("-1")
fn generated_shape_noop_probes() -> TextShapeContractProbes {
  {
    post_structure: fn() { () },
    post_capability: fn() { () },
    post_complete_staging: fn() { () },
    before_return: fn() { () },
  }
}

///|
fn text_shape_structure_error() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="text-shape",
    context="generated-structure",
  )
}

///|
fn text_shape_resource_error(
  requested : UInt64,
  limit : UInt64,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="text-shape",
    requested~,
    limit~,
    context~,
  )
}

///|
fn text_shape_project_error(
  error : @error.CoreError,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    error.category(),
    error.code(),
    operation="text-shape-project",
    requested?=error.requested(),
    completed?=error.completed(),
    range_start?=error.range_start(),
    range_end?=error.range_end(),
    source_offset?=error.source_offset(),
    limit?=error.limit(),
    context~,
  )
}

///|
fn generated_cluster(
  consumed_scalar_indices : Array[UInt64],
  input_count : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if consumed_scalar_indices.length() == 0 {
    return Err(
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="text-shape-project",
        requested=0UL,
        limit=1UL,
        context="cluster-source",
      ),
    )
  }
  let mut cluster = consumed_scalar_indices[0]
  for index in consumed_scalar_indices {
    if index >= input_count {
      return Err(
        @error.CoreError::new(
          @error.ErrorCategory::Data,
          @error.ErrorCode::InvalidEncoding,
          operation="text-shape-project",
          requested=index,
          limit=input_count,
          context="cluster-source",
        ),
      )
    }
    if index < cluster {
      cluster = index
    }
  }
  Ok(cluster)
}

///|
fn project_generated_run(
  font : @font.Font,
  logical : Array[GeneratedLogicalGlyph],
  input_count : UInt64,
  units_per_em : UInt64,
  direction : Direction,
) -> Result[ShapedRun, @error.CoreError] {
  let logical_records : Array[PositionedGlyph] = []
  for fact in logical {
    match font.horizontal_metrics(fact.glyph) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let adjusted = match
      @checked.checked_add_int64(fact.base_advance, fact.adjustment) {
      Err(error) => return Err(text_shape_project_error(error, "advance"))
      Ok(value) => value
    }
    let advance = match direction {
      Direction::LeftToRight => adjusted
      Direction::RightToLeft =>
        match @checked.checked_neg_int64(adjusted) {
          Err(error) => return Err(text_shape_project_error(error, "advance"))
          Ok(value) => value
        }
    }
    let cluster = match
      generated_cluster(fact.consumed_scalar_indices, input_count) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    logical_records.push(
      positioned_glyph(
        fact.glyph,
        cluster,
        advance,
        fact.x_offset,
        fact.y_offset,
      ),
    )
  }
  let published : Array[PositionedGlyph] = []
  match direction {
    Direction::LeftToRight =>
      for record in logical_records {
        published.push(record)
      }
    Direction::RightToLeft => {
      let mut remaining = logical_records.length()
      while remaining > 0 {
        remaining = remaining - 1
        published.push(logical_records[remaining])
      }
    }
  }
  let mut total = 0L
  for record in published {
    total = match @checked.checked_add_int64(total, record.advance()) {
      Err(error) =>
        return Err(text_shape_project_error(error, "total-advance"))
      Ok(value) => value
    }
  }
  Ok(publish_shaped_run(published, units_per_em, direction, total))
}

///|
#warnings("-1")
fn generated_shape_contract(
  font : @font.Font,
  scalars : Array[Int],
  options : ShapingOptions,
  limits : ShapeLimits,
  budget : @budget.Budget,
  logical : Array[GeneratedLogicalGlyph],
  structure_fault~ : Bool,
  capability_fault~ : Bool,
  probes : TextShapeContractProbes,
  charge : @budget.ResourceCharge,
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
    if structure_fault {
      return Err(text_shape_structure_error())
    }
    (probes.post_structure)()
    match scope.units_per_em() {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    if capability_fault {
      return Err(text_shape_layout_unavailable())
    }
    (probes.post_capability)()
    match scope.units_per_em() {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let input_count = snapshot.length().to_uint64()
    let run = match project_generated_run(
      font,
      logical,
      input_count,
      units_per_em,
      options.direction(),
    ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    (probes.post_complete_staging)()
    match scope.units_per_em() {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    if input_count > limits.max_input_scalars() {
      return Err(
        text_shape_resource_error(
          input_count,
          limits.max_input_scalars(),
          "max-input-scalars",
        ),
      )
    }
    if run.len() > limits.max_output_glyphs() {
      return Err(
        text_shape_resource_error(
          run.len(),
          limits.max_output_glyphs(),
          "max-output-glyphs",
        ),
      )
    }
    (probes.before_return)()
    match scope.units_per_em() {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    Ok((run, charge))
  })
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
