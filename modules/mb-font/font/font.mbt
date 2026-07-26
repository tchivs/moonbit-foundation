///|
/// An atomically admitted font over retained caller-provided bytes.
///
/// The representation is private. Queries guard the retained source revision
/// before returning immutable admitted facts.
pub struct Font {
  priv source : @bytes.ByteView
  priv opening_revision : UInt64
  priv units_per_em_value : UInt64
  priv global_bounds_value : FontBounds
  priv hhea_line_metrics_value : FontLineMetrics
  priv typographic_line_metrics_value : FontLineMetrics
  priv directory : DirectoryFacts
  priv tables : RequiredTableFacts
  priv metric_index : MetricIndexFacts
}

///|
/// Signed global glyph bounding box facts admitted from `head`.
pub struct FontBounds {
  priv x_min_value : Int
  priv y_min_value : Int
  priv x_max_value : Int
  priv y_max_value : Int
}

///|
/// Signed line-metric triplet admitted from either `hhea` or `OS/2`.
pub struct FontLineMetrics {
  priv ascent_value : Int
  priv descent_value : Int
  priv line_gap_value : Int
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
fn Font::require_revision(
  self : Font,
  operation : String,
) -> Result[Unit, @error.CoreError] {
  if self.source.mutation_revision() != self.opening_revision {
    Err(font_revision_error(operation))
  } else {
    Ok(())
  }
}

///|
fn font_require_table_presence(
  directory : DirectoryFacts,
) -> Result[Unit, @error.CoreError] {
  for
    tag in [
      0x4F532F32UL, 0x636D6170UL, 0x676C7966UL, 0x68656164UL, 0x68686561UL, 0x686D7478UL,
      0x6C6F6361UL, 0x6D617870UL, 0x6E616D65UL, 0x706F7374UL,
    ] {
    match font_table_window(directory, tag) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(())
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
  let directory = match font_parse_directory(source, limits) {
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
  match font_validate_profile(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_require_table_presence(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_validate_checksums(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let tables = match font_admit_required_tables(directory, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let metric_index = match
    font_admit_metric_index(directory, tables.head, tables.maxp, tables.hhea) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source.mutation_revision() != opening_revision {
    return Err(font_revision_error("font-open"))
  }
  Ok(
    {
      source,
      opening_revision,
      units_per_em_value: tables.head.units_per_em,
      global_bounds_value: {
        x_min_value: tables.head.x_min,
        y_min_value: tables.head.y_min,
        x_max_value: tables.head.x_max,
        y_max_value: tables.head.y_max,
      },
      hhea_line_metrics_value: {
        ascent_value: tables.hhea.ascent,
        descent_value: tables.hhea.descent,
        line_gap_value: tables.hhea.line_gap,
      },
      typographic_line_metrics_value: {
        ascent_value: tables.os2.typo_ascent,
        descent_value: tables.os2.typo_descent,
        line_gap_value: tables.os2.typo_line_gap,
      },
      directory,
      tables,
      metric_index,
    },
  )
}

///|
/// Return the immutable admitted units-per-em fact after rejecting any source
/// revision drift. Sequential queries over unchanged bytes are deterministic
/// and do not retain or mutate the caller's admission budget.
pub fn Font::units_per_em(self : Font) -> Result[UInt64, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.units_per_em_value)
  }
}

///|
/// Return the admitted head global bounds without selecting any other metric source.
pub fn Font::global_bounds(self : Font) -> Result[FontBounds, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.global_bounds_value)
  }
}

///|
/// Return the admitted `hhea` ascent/descent/lineGap triplet.
pub fn Font::hhea_line_metrics(
  self : Font,
) -> Result[FontLineMetrics, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.hhea_line_metrics_value)
  }
}

///|
/// Return the admitted `OS/2` typographic ascent/descent/lineGap triplet.
pub fn Font::typographic_line_metrics(
  self : Font,
) -> Result[FontLineMetrics, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => Err(error)
    Ok(_) => Ok(self.typographic_line_metrics_value)
  }
}

///|
pub fn FontBounds::x_min(self : FontBounds) -> Int {
  self.x_min_value
}

///|
pub fn FontBounds::y_min(self : FontBounds) -> Int {
  self.y_min_value
}

///|
pub fn FontBounds::x_max(self : FontBounds) -> Int {
  self.x_max_value
}

///|
pub fn FontBounds::y_max(self : FontBounds) -> Int {
  self.y_max_value
}

///|
pub fn FontLineMetrics::ascent(self : FontLineMetrics) -> Int {
  self.ascent_value
}

///|
pub fn FontLineMetrics::descent(self : FontLineMetrics) -> Int {
  self.descent_value
}

///|
pub fn FontLineMetrics::line_gap(self : FontLineMetrics) -> Int {
  self.line_gap_value
}
