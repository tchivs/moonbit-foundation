///|
/// An atomically admitted font over retained caller-provided bytes.
///
/// The representation is private. Queries added by the admission tracer guard
/// the retained source revision before returning immutable admitted facts.
pub struct Font {
  priv source : @bytes.ByteView
  priv opening_revision : UInt64
  priv units_per_em_value : UInt64
}

///|
fn font_revision_error(operation : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation~,
    context="font-source-revision-drift",
  )
}

///|
/// Admit one standalone TrueType-outline SFNT under explicit semantic limits
/// and one caller-owned authoritative budget transaction.
pub fn Font::open(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError] {
  let opening_revision = source.mutation_revision()
  let directory = match parse_font_directory(source, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match
    budget.charge(
      @budget.ResourceCharge::new(
        bytes=source.length(),
        allocations=0UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        work=directory.work,
      ),
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let head_record = match validate_tracer_tables(directory) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let head = match decode_head_table(head_record) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  ignore(head.index_to_loc_format)
  if source.mutation_revision() != opening_revision {
    return Err(font_revision_error("font-open"))
  }
  Ok({
    source,
    opening_revision,
    units_per_em_value: head.units_per_em,
  })
}

///|
/// Return the immutable admitted units-per-em fact after rejecting any source
/// revision drift. Sequential queries over unchanged bytes are deterministic
/// and do not retain or mutate the caller's admission budget.
pub fn Font::units_per_em(self : Font) -> Result[UInt64, @error.CoreError] {
  if self.source.mutation_revision() != self.opening_revision {
    Err(font_revision_error("font-query"))
  } else {
    Ok(self.units_per_em_value)
  }
}
