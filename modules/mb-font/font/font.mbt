///|
/// An atomically admitted font over retained caller-provided bytes.
///
/// The representation is private. Queries guard the retained source revision
/// before returning immutable admitted facts.
/// Phase 98 consumes the retained directory and required-table state for cmap
/// lookup and kerning.
#warnings("-7")
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
  priv limits : FontLimits
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
/// An opaque glyph identity admitted by `Font::glyph_id`.
///
/// A receiving `Font` still validates the numeric value because an identifier
/// may have originated from a different font.
pub struct GlyphId {
  priv value_value : UInt64
}

///|
/// Exact integer horizontal metrics for one admitted glyph.
pub struct GlyphHorizontalMetrics {
  priv advance_width_value : UInt64
  priv left_side_bearing_value : Int
  priv bounds_value : FontBounds?
  priv right_side_bearing_value : Int
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
fn font_from_admitted_facts(
  source : @bytes.ByteView,
  opening_revision : UInt64,
  directory : DirectoryFacts,
  tables : RequiredTableFacts,
  metric_index : MetricIndexFacts,
  limits : FontLimits,
) -> Font {
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
    limits,
  }
}

///|
fn font_open_collection_face(
  source : @bytes.ByteView,
  opening_revision : UInt64,
  face : CollectionFaceFacts,
  limits : FontLimits,
  budget : @budget.Budget,
  before_final_guard : () -> Unit,
) -> Result[Font, @error.CoreError] {
  let directory = match
    font_parse_directory_at(
      source,
      face.directory_start,
      Some(face.table_count),
      limits,
      FontChecksumMode::Collection,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match font_validate_profile(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match font_require_table_presence(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match
    font_validate_checksums_with_mode(directory, FontChecksumMode::Collection) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let admission = match
    font_admission_charge(
      directory,
      limits,
      budget,
      FontAdmissionCommitMode::CollectionDeferred,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tables = match
    font_admit_required_tables_with_kern(directory, limits, admission.kern) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let metric_index = match
    font_admit_metric_index(directory, tables.head, tables.maxp, tables.hhea) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.preflight(admission.charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  before_final_guard()
  if source.mutation_revision() != opening_revision {
    return Err(font_collection_revision_error("font-collection-open-face"))
  }
  match budget.charge(admission.charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(
    font_from_admitted_facts(
      source,
      opening_revision,
      directory,
      tables,
      metric_index,
      limits,
    ),
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
  let discovery_charge = match font_directory_discovery_charge(source, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.preflight(discovery_charge) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let directory = match font_parse_directory(source, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let admission = match
    font_admission_charge(
      directory,
      limits,
      budget,
      FontAdmissionCommitMode::StandaloneIncremental,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.charge(admission.charge) {
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
  let tables = match
    font_admit_required_tables_with_kern(directory, limits, admission.kern) {
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
    font_from_admitted_facts(
      source,
      opening_revision,
      directory,
      tables,
      metric_index,
      limits,
    ),
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
fn font_glyph_id_error(
  operation : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation~,
    requested~,
    limit~,
    context="font-glyph-id-range",
  )
}

///|
fn font_unicode_scalar_error() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="font-glyph-for-scalar",
    context="font-unicode-scalar-range",
  )
}

///|
/// Map one signed Unicode scalar through the single mapping selected at open.
///
/// Valid misses produce glyph zero. The retained source revision is checked
/// before validation and again immediately before the opaque result is
/// published.
pub fn Font::glyph_for_scalar(
  self : Font,
  scalar : Int,
) -> Result[GlyphId, @error.CoreError] {
  self.glyph_for_scalar_after_lookup(scalar, fn() { () })
}

///|
fn Font::glyph_for_scalar_after_lookup(
  self : Font,
  scalar : Int,
  after_lookup : () -> Unit,
) -> Result[GlyphId, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if scalar < 0 || scalar > 0x10FFFF || (scalar >= 0xD800 && scalar <= 0xDFFF) {
    return Err(font_unicode_scalar_error())
  }
  let value = match
    font_lookup_cmap(self.tables.cmap.lookup, scalar.to_uint64()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  after_lookup()
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({ value_value: value })
}

///|
/// Construct an opaque glyph identity after validating it against this font.
pub fn Font::glyph_id(
  self : Font,
  value : UInt64,
) -> Result[GlyphId, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if value >= self.metric_index.num_glyphs {
    Err(
      font_glyph_id_error("font-glyph-id", value, self.metric_index.num_glyphs),
    )
  } else {
    Ok({ value_value: value })
  }
}

///|
/// Return exact per-glyph horizontal metrics from admitted table-local views.
///
/// The identifier is revalidated against this receiving font before any table
/// read. Retained-source revision is checked both before lookup and immediately
/// before publishing the result.
pub fn Font::horizontal_metrics(
  self : Font,
  glyph : GlyphId,
) -> Result[GlyphHorizontalMetrics, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if glyph.value_value >= self.metric_index.num_glyphs {
    return Err(
      font_glyph_id_error(
        "font-horizontal-metrics",
        glyph.value_value,
        self.metric_index.num_glyphs,
      ),
    )
  }
  let facts = match
    font_lookup_horizontal_metrics(self.metric_index, glyph.value_value) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({
    advance_width_value: facts.advance_width,
    left_side_bearing_value: facts.left_side_bearing,
    bounds_value: facts.bounds.map(fn(bounds) {
      FontBounds::{
        x_min_value: bounds.x_min,
        y_min_value: bounds.y_min,
        x_max_value: bounds.x_max,
        y_max_value: bounds.y_max,
      }
    }),
    right_side_bearing_value: facts.right_side_bearing,
  })
}

///|
/// Return the exact signed legacy horizontal adjustment for one glyph pair.
///
/// Both opaque identifiers are revalidated against this receiving font before
/// pair-key construction. Absence and a supported-table miss return zero.
pub fn Font::kerning(
  self : Font,
  left : GlyphId,
  right : GlyphId,
) -> Result[Int, @error.CoreError] {
  self.kerning_after_lookup(left, right, fn() { () })
}

///|
fn Font::kerning_after_lookup(
  self : Font,
  left : GlyphId,
  right : GlyphId,
  after_lookup : () -> Unit,
) -> Result[Int, @error.CoreError] {
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if left.value_value >= self.metric_index.num_glyphs {
    return Err(
      font_glyph_id_error(
        "font-kerning",
        left.value_value,
        self.metric_index.num_glyphs,
      ),
    )
  }
  if right.value_value >= self.metric_index.num_glyphs {
    return Err(
      font_glyph_id_error(
        "font-kerning",
        right.value_value,
        self.metric_index.num_glyphs,
      ),
    )
  }
  let adjustment = match
    font_lookup_kern(self.tables.kern, left.value_value, right.value_value) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  after_lookup()
  match self.require_revision("font-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(adjustment)
}

///|
/// Decode one complete unhinted TrueType outline with caller-authorized work.
///
/// The opaque glyph belongs to the receiving font, and no path is published
/// until the retained source has passed both revision guards.
pub fn Font::outline(
  self : Font,
  glyph : GlyphId,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  self.outline_after_decode(glyph, budget, fn(_path) { () })
}

///|
fn Font::outline_after_decode(
  self : Font,
  glyph : GlyphId,
  budget : @budget.Budget,
  after_decode : (@math.Path2) -> Unit,
) -> Result[@math.Path2, @error.CoreError] {
  match self.require_revision("font-outline") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if glyph.value_value >= self.metric_index.num_glyphs {
    return Err(
      font_glyph_id_error(
        "font-outline",
        glyph.value_value,
        self.metric_index.num_glyphs,
      ),
    )
  }
  let path = match
    font_decode_outline(
      self.metric_index,
      self.tables.maxp,
      self.limits,
      glyph.value_value,
      budget,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  after_decode(path)
  match self.require_revision("font-outline") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(path)
}

///|
pub fn GlyphId::value(self : GlyphId) -> UInt64 {
  self.value_value
}

///|
pub fn GlyphHorizontalMetrics::advance_width(
  self : GlyphHorizontalMetrics,
) -> UInt64 {
  self.advance_width_value
}

///|
pub fn GlyphHorizontalMetrics::left_side_bearing(
  self : GlyphHorizontalMetrics,
) -> Int {
  self.left_side_bearing_value
}

///|
pub fn GlyphHorizontalMetrics::bounds(
  self : GlyphHorizontalMetrics,
) -> FontBounds? {
  self.bounds_value
}

///|
pub fn GlyphHorizontalMetrics::right_side_bearing(
  self : GlyphHorizontalMetrics,
) -> Int {
  self.right_side_bearing_value
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
