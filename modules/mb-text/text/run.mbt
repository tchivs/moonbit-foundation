///|
/// One immutable positioned same-font glyph record.
#warnings("-9")
pub struct PositionedGlyph {
  priv glyph_value : @font.GlyphId
  priv cluster_value : UInt64
  priv advance_value : Int64
  priv x_offset_value : Int64
  priv y_offset_value : Int64
}

///|
fn positioned_glyph(
  glyph : @font.GlyphId,
  cluster : UInt64,
  advance : Int64,
  x_offset : Int64,
  y_offset : Int64,
) -> PositionedGlyph {
  {
    glyph_value: glyph,
    cluster_value: cluster,
    advance_value: advance,
    x_offset_value: x_offset,
    y_offset_value: y_offset,
  }
}

///|
pub fn PositionedGlyph::glyph(self : PositionedGlyph) -> @font.GlyphId {
  self.glyph_value
}

///|
pub fn PositionedGlyph::cluster(self : PositionedGlyph) -> UInt64 {
  self.cluster_value
}

///|
pub fn PositionedGlyph::advance(self : PositionedGlyph) -> Int64 {
  self.advance_value
}

///|
pub fn PositionedGlyph::x_offset(self : PositionedGlyph) -> Int64 {
  self.x_offset_value
}

///|
pub fn PositionedGlyph::y_offset(self : PositionedGlyph) -> Int64 {
  self.y_offset_value
}

///|
/// An opaque immutable shaped run. The private record array is never returned
/// or exposed through a mutable view.
pub struct ShapedRun {
  priv records : Array[PositionedGlyph]
  priv units_per_em_value : UInt64
  priv direction_value : Direction
  priv total_advance_value : Int64
}

///|
fn publish_shaped_run(
  records : Array[PositionedGlyph],
  units_per_em : UInt64,
  direction : Direction,
  total_advance : Int64,
) -> ShapedRun {
  {
    records: records.copy(),
    units_per_em_value: units_per_em,
    direction_value: direction,
    total_advance_value: total_advance,
  }
}

///|
fn empty_shaped_run(units_per_em : UInt64, direction : Direction) -> ShapedRun {
  publish_shaped_run([], units_per_em, direction, 0L)
}

///|
pub fn ShapedRun::len(self : ShapedRun) -> UInt64 {
  self.records.length().to_uint64()
}

///|
fn shaped_run_index_error(index : UInt64, count : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="text-shaped-run-glyph-at",
    requested=index,
    limit=count,
    context="run-index",
  )
}

///|
pub fn ShapedRun::glyph_at(
  self : ShapedRun,
  index : UInt64,
) -> Result[PositionedGlyph, @error.CoreError] {
  let count = self.records.length().to_uint64()
  if index >= count {
    return Err(shaped_run_index_error(index, count))
  }
  let narrowed = match @checked.checked_narrow_int(index) {
    Err(_) => return Err(shaped_run_index_error(index, count))
    Ok(value) => value
  }
  Ok(self.records[narrowed])
}

///|
pub fn ShapedRun::units_per_em(self : ShapedRun) -> UInt64 {
  self.units_per_em_value
}

///|
pub fn ShapedRun::direction(self : ShapedRun) -> Direction {
  self.direction_value
}

///|
pub fn ShapedRun::total_advance(self : ShapedRun) -> Int64 {
  self.total_advance_value
}
