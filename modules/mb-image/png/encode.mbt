///|
fn _png_encode_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  requested? : UInt64,
  completed? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    category, code, operation="png-encode", requested?, completed?, limit?, context~,
  )
}

///|
fn _png_encode_capability(context : String) -> @error.CoreError {
  @codec.capability_unavailable("png-encode", context)
}

///|
fn _png_encode_invalid_writer_progress(progress : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
    operation="png-encode-write", requested=progress, completed=0UL, limit=1UL,
  )
}

///|
fn _png_encode_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(_png_encode_error(
      @error.ErrorCategory::Resource, @error.ErrorCode::BudgetExceeded,
      context, requested~, limit~, 
    ))
  } else {
    Ok(())
  }
}

///|
fn _png_encode_u32(value : UInt64) -> Result[UInt64, @error.CoreError] {
  if value == 0UL || value > 4294967295UL {
    Err(_png_encode_capability("png-u32-dimensions"))
  } else {
    Ok(value)
  }
}

///|
/// Validate every semantic and physical property before pixels are read or the
/// caller budget is charged. The canonical layout contains no padding rows.
fn _png_encode_source(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
) -> Result[UInt64, @error.CoreError] {
  if source.is_empty() {
    return Err(_png_encode_capability("empty-image"))
  }
  match _png_encode_u32(source.width()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match _png_encode_u32(source.height()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = source.format()
  let metadata = source.metadata()
  if format.layout() != @model.PlaneLayout::Packed {
    return Err(_png_encode_capability("packed-required"))
  }
  if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    metadata.transfer() != @color.TransferIdentity::EncodedSrgb ||
    !metadata.profile().is_builtin_srgb() {
    return Err(_png_encode_capability("builtin-encoded-srgb-required"))
  }
  if metadata.orientation() != @model.Orientation::TopLeft {
    return Err(_png_encode_capability("top-left-required"))
  }
  if metadata.opaque_metadata().length() != 0 {
    return Err(_png_encode_capability("opaque-metadata-unsupported"))
  }
  let channels = match profile {
    PngEncodeProfile::LegacyRgbOrRgba => match format.channels() {
      @model.ChannelOrder::Rgb =>
        if format.component() != @model.ComponentType::U8 {
          return Err(_png_encode_capability("component-u8-required"))
        } else if metadata.alpha() is Some(_) {
          return Err(_png_encode_capability("rgb-alpha-unsupported"))
        } else {
          3UL
        }
      @model.ChannelOrder::Rgba =>
        if format.component() != @model.ComponentType::U8 {
          return Err(_png_encode_capability("component-u8-required"))
        } else {
          match metadata.alpha() {
            Some(@color.AlphaMode::Straight) => 4UL
            _ => return Err(_png_encode_capability("straight-rgba-required"))
          }
        }
      _ => return Err(_png_encode_capability("rgb-or-rgba-required"))
    }
    PngEncodeProfile::Gray8 => match format.channels() {
      @model.ChannelOrder::Gray =>
        if format.component() != @model.ComponentType::U8 {
          return Err(_png_encode_capability("component-u8-required"))
        } else if metadata.alpha() is Some(_) {
          return Err(_png_encode_capability("gray-alpha-unsupported"))
        } else {
          1UL
        }
      _ => return Err(_png_encode_capability("gray8-required"))
    }
    PngEncodeProfile::Gray16 => match format.channels() {
      @model.ChannelOrder::Gray =>
        if metadata.alpha() is Some(_) {
          return Err(_png_encode_capability("gray-alpha-unsupported"))
        } else if format.component() != @model.ComponentType::U16 {
          return Err(_png_encode_capability("component-u16-required"))
        } else {
          2UL
        }
      _ => return Err(_png_encode_capability("gray16-required"))
    }
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source.row_bytes() != row_bytes || source.row_stride() != row_bytes {
    return Err(_png_encode_capability("tightly-packed-rows-required"))
  }
  Ok(channels)
}

///|
priv struct PngEncodePreflight {
  profile : PngEncodeProfile
  channels : UInt64
  row_bytes : UInt64
  scanlines : UInt64
  blocks : UInt64
  idat_length : UInt64
  total_length : UInt64
  plan : PngDeflatePlan
  disposition : @metadata.MetadataDisposition
  selected_work : UInt64
  adaptive_planning_facts : PngFilteredTraversalFacts
  adaptive_replay_facts : PngFilteredTraversalFacts
}

///| The adaptive ledger records executed row selection and residual work.  It
/// deliberately does not count byte lookups: a bounded replay may revisit a
/// buffered byte without rescoring the source row.
priv struct PngFilteredTraversalFacts {
  resolved_rows : UInt64
  candidate_residuals : UInt64
  selected_residuals : UInt64
}

///|
fn PngFilteredTraversalFacts::work(
  self : PngFilteredTraversalFacts,
) -> Result[UInt64, @error.CoreError] {
  _png_fixed_add(self.candidate_residuals, self.selected_residuals)
}

///|
fn _png_filtered_facts_add(
  left : PngFilteredTraversalFacts,
  right : PngFilteredTraversalFacts,
) -> Result[PngFilteredTraversalFacts, @error.CoreError] {
  let resolved_rows = match _png_fixed_add(left.resolved_rows, right.resolved_rows) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let candidate_residuals = match _png_fixed_add(
    left.candidate_residuals, right.candidate_residuals,
  ) { Err(error) => return Err(error); Ok(value) => value }
  let selected_residuals = match _png_fixed_add(
    left.selected_residuals, right.selected_residuals,
  ) { Err(error) => return Err(error); Ok(value) => value }
  Ok({ resolved_rows, candidate_residuals, selected_residuals })
}

///| The explicit Stored plan preserves the historical emission arithmetic.
priv struct PngStoredPlan {
  blocks : UInt64
  idat_length : UInt64
  total_length : UInt64
}

///| The selected fixed plan keeps only scalar replay facts; it never stores
/// tokens, scanlines, or compressed output.
priv struct PngFixedPlan {
  deflate_bits : UInt64
  deflate_bytes : UInt64
  matcher_work : UInt64
  fingerprint : UInt64
  traversal_facts : PngFilteredTraversalFacts
  idat_length : UInt64
  total_length : UInt64
}

///| A dynamic plan is deliberately bounded by DEFLATE's alphabets.  The RLE
/// arrays have their RFC maximum (286 + 30); no image-sized token/output buffer
/// crosses the planning/replay boundary.
priv struct PngDynamicPlan {
  literals : PngHuffman
  distances : PngHuffman
  code_lengths : PngHuffman
  rle_symbols : Array[Int]
  rle_extras : Array[UInt64]
  rle_extra_bits : Array[UInt64]
  rle_count : UInt64
  hlit : UInt64
  hdist : UInt64
  hclen : UInt64
  deflate_bits : UInt64
  deflate_bytes : UInt64
  matcher_work : UInt64
  fingerprint : UInt64
  frequency_facts : PngFilteredTraversalFacts
  bit_facts : PngFilteredTraversalFacts
  idat_length : UInt64
  total_length : UInt64
}

///| Dynamic planning returns cursor facts even when the ordinary bounded
///| Huffman builder declines a candidate.
priv struct PngDynamicPlanOutcome {
  plan : PngDynamicPlan?
  frequency_facts : PngFilteredTraversalFacts
  bit_facts : PngFilteredTraversalFacts
}

///|
priv enum PngDeflatePlan {
  Stored(PngStoredPlan)
  Fixed(PngFixedPlan)
  Dynamic(PngDynamicPlan)
}

///|
fn _png_fixed_add(left : UInt64, right : UInt64) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_add(left, right) {
    Ok(value) => Ok(value)
    Err(error) => Err(error)
  }
}

///| Checked work composition keeps resource admission independent of target
/// integer overflow behaviour.
fn _png_encode_selected_work(
  total_length : UInt64,
  matcher_work : UInt64,
  adaptive_filter_work : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let with_planning = match _png_fixed_add(total_length, matcher_work) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let with_replay = match _png_fixed_add(with_planning, matcher_work) {
    Err(error) => return Err(error); Ok(value) => value
  }
  _png_fixed_add(with_replay, adaptive_filter_work)
}

///| PNG method-0 filter candidates remain in their mandated stable order.
priv enum PngRowFilter {
  None
  Sub
  Up
  Average
  Paeth
} derive(Eq)

///|
fn _png_filter_raw_byte(row : Bytes, position : UInt64) -> Result[Byte, @error.CoreError] {
  if position >= row.length().to_uint64() {
    Err(_png_encode_capability("png-filter-row-access"))
  } else {
    Ok(row[position.to_int()])
  }
}

///|
fn _png_filter_above_byte(above : Bytes?, position : UInt64) -> Result[Byte, @error.CoreError] {
  match above {
    None => Ok(b'\x00')
    Some(row) => _png_filter_raw_byte(row, position)
  }
}

///| The predictor's bounded Int arithmetic cannot overflow for Byte samples.
fn _png_filter_paeth_predictor(left : Byte, above : Byte, upper_left : Byte) -> Byte {
  let prediction = left.to_int() + above.to_int() - upper_left.to_int()
  let pa = if prediction >= left.to_int() { prediction - left.to_int() } else { left.to_int() - prediction }
  let pb = if prediction >= above.to_int() { prediction - above.to_int() } else { above.to_int() - prediction }
  let pc = if prediction >= upper_left.to_int() { prediction - upper_left.to_int() } else { upper_left.to_int() - prediction }
  if pa <= pb && pa <= pc { left } else if pb <= pc { above } else { upper_left }
}

///| Return one PNG method-0 residual from original source-row samples.
fn _png_filter_candidate_byte(
  filter : PngRowFilter,
  source : Bytes,
  above : Bytes?,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  if channels != 1UL && channels != 3UL && channels != 4UL { return Err(_png_encode_capability("png-filter-channels")) }
  if source.length().to_uint64() % channels != 0UL { return Err(_png_encode_capability("png-filter-row-bytes")) }
  match above {
    Some(row) if row.length() != source.length() => return Err(_png_encode_capability("png-filter-above-row-bytes"))
    _ => ()
  }
  let sample = match _png_filter_raw_byte(source, position) { Err(error) => return Err(error); Ok(value) => value }
  let left = if position < channels {
    b'\x00'
  } else {
    match _png_filter_raw_byte(source, position - channels) { Err(error) => return Err(error); Ok(value) => value }
  }
  let up = match _png_filter_above_byte(above, position) { Err(error) => return Err(error); Ok(value) => value }
  let upper_left = if position < channels {
    b'\x00'
  } else {
    match _png_filter_above_byte(above, position - channels) { Err(error) => return Err(error); Ok(value) => value }
  }
  let predictor = match filter {
    PngRowFilter::None => b'\x00'
    PngRowFilter::Sub => left
    PngRowFilter::Up => up
    PngRowFilter::Average => ((left.to_uint64() + up.to_uint64()) / 2UL).to_byte()
    PngRowFilter::Paeth => _png_filter_paeth_predictor(left, up, upper_left)
  }
  Ok(sample - predictor)
}

///|
fn _png_filter_signed_magnitude(residual : Byte) -> UInt64 {
  let value = residual.to_uint64()
  if value <= 127UL { value } else { 256UL - value }
}

///| Score a complete candidate row with PNG's signed-residual heuristic.
fn _png_filter_candidate_score(
  filter : PngRowFilter,
  source : Bytes,
  above : Bytes?,
  channels : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let mut score = 0UL
  for position = 0UL; position < source.length().to_uint64(); position = position + 1UL {
    let residual = match _png_filter_candidate_byte(filter, source, above, channels, position) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    score = match _png_fixed_add(score, _png_filter_signed_magnitude(residual)) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  Ok(score)
}

///| Select the first minimum-scoring method-0 candidate in PNG's fixed order.
fn _png_filter_row_winner(
  source : Bytes,
  above : Bytes?,
  channels : UInt64,
) -> Result[(PngRowFilter, UInt64), @error.CoreError] {
  let mut winner = PngRowFilter::None
  let mut winner_score = match _png_filter_candidate_score(winner, source, above, channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for candidate in [PngRowFilter::Sub, PngRowFilter::Up, PngRowFilter::Average, PngRowFilter::Paeth] {
    let score = match _png_filter_candidate_score(candidate, source, above, channels) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if score < winner_score {
      winner = candidate
      winner_score = score
    }
  }
  Ok((winner, winner_score))
}

///| Read one scalar PNG wire byte. Gray16 maps storage-order component bytes to
/// the mandatory big-endian wire order before every filter, planner, and replay.
fn _png_wire_byte(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  match profile {
    PngEncodeProfile::Gray16 => {
      let wire_byte = position % 2UL
      let storage_byte = match source.format().endianness() {
        @model.Endianness::Little => 1UL - wire_byte
        @model.Endianness::Big => wire_byte
      }
      source.get_component_byte(position / 2UL, row, 0UL, storage_byte)
    }
    _ => source.get_byte(position / channels, row, position % channels)
  }
}

///| Return a scanline byte without materialising a filter-None scanline.
fn _png_fixed_scanline_byte(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row_bytes : UInt64,
  channels : UInt64,
  index : UInt64,
) -> Result[Byte, @error.CoreError] {
  let row_width = row_bytes + 1UL
  let in_row = index % row_width
  if in_row == 0UL {
    Ok(b'\x00')
  } else {
    let sample = in_row - 1UL
    _png_wire_byte(source, profile, index / row_width, channels, sample)
  }
}

///| Convert the stable method-0 row selection to its on-wire filter tag.
fn _png_filter_tag(filter : PngRowFilter) -> Byte {
  match filter {
    PngRowFilter::None => b'\x00'
    PngRowFilter::Sub => b'\x01'
    PngRowFilter::Up => b'\x02'
    PngRowFilter::Average => b'\x03'
    PngRowFilter::Paeth => b'\x04'
  }
}

///| Read a raw source row without materialising source or residual bytes.
fn _png_filter_image_raw_byte(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  _png_wire_byte(source, profile, row, channels, position)
}

///| Apply a method-0 candidate directly to one ImageView row. This keeps the
/// adaptive source bounded to scalar coordinates and pixel reads.
fn _png_filter_image_candidate_byte(
  filter : PngRowFilter,
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row : UInt64,
  row_bytes : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  if position >= row_bytes { return Err(_png_encode_capability("png-filter-row-access")) }
  let sample = match _png_filter_image_raw_byte(source, profile, row, channels, position) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let left = if position < channels { b'\x00' } else {
    match _png_filter_image_raw_byte(source, profile, row, channels, position - channels) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let up = if row == 0UL { b'\x00' } else {
    match _png_filter_image_raw_byte(source, profile, row - 1UL, channels, position) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let upper_left = if row == 0UL || position < channels { b'\x00' } else {
    match _png_filter_image_raw_byte(source, profile, row - 1UL, channels, position - channels) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let predictor = match filter {
    PngRowFilter::None => b'\x00'
    PngRowFilter::Sub => left
    PngRowFilter::Up => up
    PngRowFilter::Average => ((left.to_uint64() + up.to_uint64()) / 2UL).to_byte()
    PngRowFilter::Paeth => _png_filter_paeth_predictor(left, up, upper_left)
  }
  Ok(sample - predictor)
}

///| Select one row's first minimum candidate using only scalar positions.
fn _png_filter_image_row_winner(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row : UInt64,
  row_bytes : UInt64,
  channels : UInt64,
) -> Result[PngRowFilter, @error.CoreError] {
  let mut winner = PngRowFilter::None
  let mut winner_score = 0UL
  for candidate in [PngRowFilter::None, PngRowFilter::Sub, PngRowFilter::Up, PngRowFilter::Average, PngRowFilter::Paeth] {
    let mut score = 0UL
    for position = 0UL; position < row_bytes; position = position + 1UL {
      let residual = match _png_filter_image_candidate_byte(
        candidate, source, profile, row, row_bytes, channels, position,
      ) { Err(error) => return Err(error); Ok(value) => value }
      score = match _png_fixed_add(score, _png_filter_signed_magnitude(residual)) {
        Err(error) => return Err(error); Ok(value) => value
      }
    }
    if candidate == PngRowFilter::None || score < winner_score {
      winner = candidate
      winner_score = score
    }
  }
  Ok(winner)
}

///| Resolve one Adam7 logical byte from the checked structural pass records.
/// The cursor retains no pass collection: every lookup obtains geometry from
/// the sole authority and keeps only its scalar logical position.
fn _png_adam7_cursor_location(
  source : @storage.ImageView,
  channels : UInt64,
  index : UInt64,
) -> Result[(PngAdam7Pass, UInt64, UInt64), @error.CoreError] {
  let passes = match _png_adam7_passes(source.width(), source.height(), channels, 8) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let mut offset = 0UL
  for pass in passes {
    if pass.width == 0UL || pass.height == 0UL { continue }
    let row_width = match @checked.checked_add(pass.row_bytes, 1UL) {
      Err(error) => return Err(error); Ok(value) => value
    }
    let bytes = match @checked.checked_mul(row_width, pass.height) {
      Err(error) => return Err(error); Ok(value) => value
    }
    let end = match @checked.checked_add(offset, bytes) {
      Err(error) => return Err(error); Ok(value) => value
    }
    if index < end {
      let relative = index - offset
      return Ok((pass, relative / row_width, relative % row_width))
    }
    offset = end
  }
  Err(_png_encode_capability("png-adam7-cursor-end"))
}

///| Pass-local raw sample lookup.  `row` is deliberately the row within the
/// selected pass, so Up/Average/Paeth never cross a pass boundary.
fn _png_adam7_raw_byte(
  source : @storage.ImageView,
  pass : PngAdam7Pass,
  row : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  source.get_byte(
    pass.x + (position / channels) * pass.dx,
    pass.y + row * pass.dy,
    position % channels,
  )
}

///| Apply a filter candidate without materialising an Adam7 pass row.
fn _png_adam7_candidate_byte(
  filter : PngRowFilter,
  source : @storage.ImageView,
  pass : PngAdam7Pass,
  row : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  if position >= pass.row_bytes { return Err(_png_encode_capability("png-adam7-row-access")) }
  let sample = match _png_adam7_raw_byte(source, pass, row, channels, position) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let left = if position < channels { b'\x00' } else {
    match _png_adam7_raw_byte(source, pass, row, channels, position - channels) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let up = if row == 0UL { b'\x00' } else {
    match _png_adam7_raw_byte(source, pass, row - 1UL, channels, position) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let upper_left = if row == 0UL || position < channels { b'\x00' } else {
    match _png_adam7_raw_byte(source, pass, row - 1UL, channels, position - channels) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let predictor = match filter {
    PngRowFilter::None => b'\x00'
    PngRowFilter::Sub => left
    PngRowFilter::Up => up
    PngRowFilter::Average => ((left.to_uint64() + up.to_uint64()) / 2UL).to_byte()
    PngRowFilter::Paeth => _png_filter_paeth_predictor(left, up, upper_left)
  }
  Ok(sample - predictor)
}

///| Choose a method-0 filter for one local Adam7 row with scalar pixel reads.
fn _png_adam7_row_winner(
  source : @storage.ImageView,
  pass : PngAdam7Pass,
  row : UInt64,
  channels : UInt64,
) -> Result[PngRowFilter, @error.CoreError] {
  let mut winner = PngRowFilter::None
  let mut winner_score = 0UL
  for candidate in [PngRowFilter::None, PngRowFilter::Sub, PngRowFilter::Up, PngRowFilter::Average, PngRowFilter::Paeth] {
    let mut score = 0UL
    for position = 0UL; position < pass.row_bytes; position = position + 1UL {
      let residual = match _png_adam7_candidate_byte(candidate, source, pass, row, channels, position) {
        Err(error) => return Err(error); Ok(value) => value
      }
      score = match _png_fixed_add(score, _png_filter_signed_magnitude(residual)) {
        Err(error) => return Err(error); Ok(value) => value
      }
    }
    if candidate == PngRowFilter::None || score < winner_score {
      winner = candidate
      winner_score = score
    }
  }
  Ok(winner)
}

///| A forward-only logical filter stream.  Adaptive resolves a row only when
/// its tag is first entered, retains that winner for its payload, and carries
/// only scalar row state across the caller-owned replay boundary.
priv struct PngFilteredCursor {
  source : @storage.ImageView
  profile : PngEncodeProfile
  row_bytes : UInt64
  channels : UInt64
  filter_strategy : PngFilterStrategy
  interlace_strategy : PngInterlaceStrategy
  index : UInt64
  winner : PngRowFilter?
  traversal_facts : PngFilteredTraversalFacts
}

///|
fn PngFilteredCursor::new(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> PngFilteredCursor {
  PngFilteredCursor::new_with_interlace(
    source, row_bytes, channels, filter_strategy, PngInterlaceStrategy::None, profile=profile,
  )
}

///|
fn PngFilteredCursor::new_with_interlace(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> PngFilteredCursor {
  {
    source, profile, row_bytes, channels, filter_strategy, interlace_strategy, index: 0UL, winner: None,
    traversal_facts: {
      resolved_rows: 0UL, candidate_residuals: 0UL, selected_residuals: 0UL,
    },
  }
}

///|
fn PngFilteredCursor::facts(
  self : PngFilteredCursor,
) -> PngFilteredTraversalFacts {
  self.traversal_facts
}

///| Return the next logical filtered byte and an uncommitted successor.  This
/// persistent form lets `present` keep a preview private until acknowledgement.
fn PngFilteredCursor::next(
  self : PngFilteredCursor,
) -> Result[(Byte, PngFilteredCursor), @error.CoreError] {
  if self.interlace_strategy == PngInterlaceStrategy::Adam7 {
    let (pass, row, in_row) = match _png_adam7_cursor_location(
      self.source, self.channels, self.index,
    ) { Err(error) => return Err(error); Ok(value) => value }
    if in_row == 0UL {
      let winner = match self.filter_strategy {
        PngFilterStrategy::None => PngRowFilter::None
        PngFilterStrategy::Adaptive => match _png_adam7_row_winner(
          self.source, pass, row, self.channels,
        ) { Err(error) => return Err(error); Ok(value) => value }
      }
      let candidate_residuals = match self.filter_strategy {
        PngFilterStrategy::None => self.traversal_facts.candidate_residuals
        PngFilterStrategy::Adaptive => match _png_fixed_add(self.traversal_facts.candidate_residuals, 5UL * pass.row_bytes) {
          Err(error) => return Err(error); Ok(value) => value
        }
      }
      let resolved_rows = match self.filter_strategy {
        PngFilterStrategy::None => self.traversal_facts.resolved_rows
        PngFilterStrategy::Adaptive => match _png_fixed_add(self.traversal_facts.resolved_rows, 1UL) {
          Err(error) => return Err(error); Ok(value) => value
        }
      }
      return Ok((_png_filter_tag(winner), { ..self, index: self.index + 1UL,
        winner: Some(winner), traversal_facts: {
          resolved_rows, candidate_residuals,
          selected_residuals: self.traversal_facts.selected_residuals,
        } }))
    }
    let winner = match self.winner {
      Some(value) => value
      None => return Err(_png_encode_capability("png-adam7-cursor-winner"))
    }
    let byte = match _png_adam7_candidate_byte(
      winner, self.source, pass, row, self.channels, in_row - 1UL,
    ) { Err(error) => return Err(error); Ok(value) => value }
    let selected_residuals = match self.filter_strategy {
      PngFilterStrategy::None => self.traversal_facts.selected_residuals
      PngFilterStrategy::Adaptive => match _png_fixed_add(self.traversal_facts.selected_residuals, 1UL) {
        Err(error) => return Err(error); Ok(value) => value
      }
    }
    return Ok((byte, { ..self, index: self.index + 1UL, traversal_facts: {
      resolved_rows: self.traversal_facts.resolved_rows,
      candidate_residuals: self.traversal_facts.candidate_residuals, selected_residuals,
    } }))
  }
  let row_width = match @checked.checked_add(self.row_bytes, 1UL) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let scanlines = match @checked.checked_mul(row_width, self.source.height()) {
    Err(error) => return Err(error); Ok(value) => value
  }
  if self.index >= scanlines {
    return Err(_png_encode_capability("png-filter-cursor-end"))
  }
  match self.filter_strategy {
    PngFilterStrategy::None => {
      let byte = match _png_fixed_scanline_byte(
        self.source, self.profile, self.row_bytes, self.channels, self.index,
      ) { Err(error) => return Err(error); Ok(value) => value }
      Ok((byte, { ..self, index: self.index + 1UL }))
    }
    PngFilterStrategy::Adaptive => {
      let row = self.index / row_width
      let in_row = self.index % row_width
      if in_row == 0UL {
        let winner = match _png_filter_image_row_winner(
          self.source, self.profile, row, self.row_bytes, self.channels,
        ) { Err(error) => return Err(error); Ok(value) => value }
        let candidate_residuals = match _png_fixed_add(
          self.traversal_facts.candidate_residuals, 5UL * self.row_bytes,
        ) { Err(error) => return Err(error); Ok(value) => value }
        let resolved_rows = match _png_fixed_add(
          self.traversal_facts.resolved_rows, 1UL,
        ) { Err(error) => return Err(error); Ok(value) => value }
        Ok((_png_filter_tag(winner), {
          ..self,
          index: self.index + 1UL,
          winner: Some(winner),
          traversal_facts: {
            resolved_rows, candidate_residuals,
            selected_residuals: self.traversal_facts.selected_residuals,
          },
        }))
      } else {
        let winner = match self.winner {
          Some(value) => value
          None => return Err(_png_encode_capability("png-filter-cursor-winner"))
        }
        let byte = match _png_filter_image_candidate_byte(
          winner, self.source, self.profile, row, self.row_bytes, self.channels, in_row - 1UL,
        ) { Err(error) => return Err(error); Ok(value) => value }
        let selected_residuals = match _png_fixed_add(
          self.traversal_facts.selected_residuals, 1UL,
        ) { Err(error) => return Err(error); Ok(value) => value }
        Ok((byte, {
          ..self, index: self.index + 1UL,
          traversal_facts: {
            resolved_rows: self.traversal_facts.resolved_rows,
            candidate_residuals: self.traversal_facts.candidate_residuals,
            selected_residuals,
          },
        }))
      }
    }
  }
}

///| Execute one bounded forward traversal.  Each caller gets fresh scalar
/// state, making the preflight ledger a sum of real planning/replay passes.
fn _png_filtered_traverse(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
) -> Result[PngFilteredTraversalFacts, @error.CoreError] {
  let mut cursor = PngFilteredCursor::new(
    source, row_bytes, channels, filter_strategy, profile=profile,
  )
  while cursor.index < scanlines {
    let (_, next) = match cursor.next() {
      Err(error) => return Err(error); Ok(value) => value
    }
    cursor = next
  }
  Ok(cursor.facts())
}

///|
fn _png_adaptive_traverse(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
) -> Result[PngFilteredTraversalFacts, @error.CoreError] {
  match filter_strategy {
    PngFilterStrategy::None => Ok({
      resolved_rows: 0UL, candidate_residuals: 0UL, selected_residuals: 0UL,
    })
    PngFilterStrategy::Adaptive => _png_filtered_traverse(
      source, profile, row_bytes, channels, filter_strategy, scanlines,
    )
  }
}

///| The common logical filtered stream. None keeps its legacy provider exactly;
/// Adaptive derives one tag and residual payload from the fixed scorer.
fn _png_filtered_scanline_byte(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  index : UInt64,
) -> Result[Byte, @error.CoreError] {
  match filter_strategy {
    PngFilterStrategy::None => _png_fixed_scanline_byte(source, profile, row_bytes, channels, index)
    PngFilterStrategy::Adaptive => {
      let row_width = match @checked.checked_add(row_bytes, 1UL) {
        Err(error) => return Err(error); Ok(value) => value
      }
      let row = index / row_width
      let in_row = index % row_width
      let winner = match _png_filter_image_row_winner(source, profile, row, row_bytes, channels) {
        Err(error) => return Err(error); Ok(value) => value
      }
      if in_row == 0UL { Ok(_png_filter_tag(winner)) } else {
        _png_filter_image_candidate_byte(
          winner, source, profile, row, row_bytes, channels, in_row - 1UL,
        )
      }
    }
  }
}

///| A match cursor deliberately separates the byte producer from logical
/// DEFLATE consumption. Probes may move `produced_exclusive` ahead, but only
/// the token that is emitted may advance `logical_position`.
priv struct PngFilteredMatchCursor {
  producer : PngFilteredCursor
  logical_position : UInt64
  produced_exclusive : UInt64
  retained_start : UInt64
  window : Array[Byte]
}

///|
fn PngFilteredMatchCursor::new(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> PngFilteredMatchCursor {
  PngFilteredMatchCursor::new_with_interlace(
    source, row_bytes, channels, filter_strategy, PngInterlaceStrategy::None, profile=profile,
  )
}

///|
fn PngFilteredMatchCursor::new_with_interlace(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> PngFilteredMatchCursor {
  { producer: PngFilteredCursor::new_with_interlace(source, row_bytes, channels, filter_strategy, interlace_strategy, profile=profile),
    logical_position: 0UL, produced_exclusive: 0UL, retained_start: 0UL,
    window: Array::make(262, b'\x00') }
}

///|
fn PngFilteredMatchCursor::facts(self : PngFilteredMatchCursor) -> PngFilteredTraversalFacts {
  self.producer.facts()
}

///|
fn _png_filtered_match_window_copy(window : Array[Byte]) -> Array[Byte] {
  let copied = Array::make(262, b'\x00')
  for index = 0; index < 262; index = index + 1 { copied[index] = window[index] }
  copied
}

///| Produce through the requested exclusive position without consuming it.
fn PngFilteredMatchCursor::ensure(
  self : PngFilteredMatchCursor,
  exclusive_position : UInt64,
) -> Result[PngFilteredMatchCursor, @error.CoreError] {
  let mut producer = self.producer
  let mut produced_exclusive = self.produced_exclusive
  let mut retained_start = self.retained_start
  let window = _png_filtered_match_window_copy(self.window)
  while produced_exclusive < exclusive_position {
    let (byte, next) = match producer.next() {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    window[(produced_exclusive % 262UL).to_int()] = byte
    producer = next
    produced_exclusive = produced_exclusive + 1UL
    if produced_exclusive - retained_start > 262UL {
      retained_start = produced_exclusive - 262UL
    }
  }
  Ok({ producer, logical_position: self.logical_position, produced_exclusive,
    retained_start, window })
}

///| Read only a byte that remains in the fixed retained window.
fn PngFilteredMatchCursor::read(
  self : PngFilteredMatchCursor,
  absolute_position : UInt64,
) -> Result[Byte, @error.CoreError] {
  if absolute_position < self.retained_start || absolute_position >= self.produced_exclusive {
    return Err(_png_encode_machine_state_error("png-filter-match-retained"))
  }
  Ok(self.window[(absolute_position % 262UL).to_int()])
}

///| Commit logical consumption only after the corresponding token is emitted.
fn PngFilteredMatchCursor::consume(
  self : PngFilteredMatchCursor,
  count : UInt64,
) -> Result[PngFilteredMatchCursor, @error.CoreError] {
  let logical_position = match _png_fixed_add(self.logical_position, count) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if logical_position > self.produced_exclusive {
    return Err(_png_encode_machine_state_error("png-filter-match-consume"))
  }
  Ok({ ..self, logical_position })
}

///| Read and commit one logical byte. This is the only convenience operation
/// used by emitters; matcher probes use `ensure` and `read` directly.
fn PngFilteredMatchCursor::next(
  self : PngFilteredMatchCursor,
) -> Result[(Byte, PngFilteredMatchCursor), @error.CoreError] {
  let produced = match self.ensure(self.logical_position + 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let byte = match produced.read(produced.logical_position) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let next = match produced.consume(1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok((byte, next))
}

///| The bounded DEFLATE matcher over one owned selected-filter stream.
fn _png_filtered_match_at(
  cursor : PngFilteredMatchCursor,
  scanlines : UInt64,
) -> Result[(UInt64, UInt64, UInt64, PngFilteredMatchCursor), @error.CoreError] {
  let position = cursor.logical_position
  let remaining = scanlines - position
  let mut best_length = 0UL
  let mut best_distance = 0UL
  let mut work = 0UL
  let mut cursor = cursor
  let mut distance = 1UL
  while distance <= 4UL && distance <= position {
    let mut length = 0UL
    while length < 258UL && length < remaining {
      work = match _png_fixed_add(work, 3UL) { Err(error) => return Err(error); Ok(value) => value }
      cursor = match cursor.ensure(position + length + 1UL) {
        Err(error) => return Err(error); Ok(value) => value
      }
      let current = match cursor.read(position + length) {
        Err(error) => return Err(error); Ok(value) => value
      }
      let prior = match cursor.read(position + length - distance) {
        Err(error) => return Err(error); Ok(value) => value
      }
      if current != prior { break }
      length = length + 1UL
    }
    if length >= 3UL && length > best_length { best_length = length; best_distance = distance }
    distance = distance + 1UL
  }
  Ok((best_length, best_distance, work, cursor))
}

///| Consume one complete cursor traversal for Stored planning or replay.
fn _png_filtered_match_traverse(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngFilteredTraversalFacts, @error.CoreError] {
  _png_filtered_match_traverse_with_interlace(
    source, row_bytes, channels, filter_strategy, scanlines, PngInterlaceStrategy::None, profile=profile,
  )
}

///| The selected layout is recreated for every planner/replay walk.
fn _png_filtered_match_traverse_with_interlace(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  interlace_strategy : PngInterlaceStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngFilteredTraversalFacts, @error.CoreError] {
  let mut cursor = PngFilteredMatchCursor::new_with_interlace(
    source, row_bytes, channels, filter_strategy, interlace_strategy, profile=profile,
  )
  while cursor.logical_position < scanlines {
    cursor = match cursor.ensure(cursor.logical_position + 1UL) {
      Err(error) => return Err(error); Ok(value) => value
    }
    cursor = match cursor.consume(1UL) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  Ok(cursor.facts())
}

///| A1: scan only distances 1 through 4 in ascending order. Strictly replacing
/// the best length intentionally retains the smaller distance on ties.
fn _png_fixed_match_at(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row_bytes : UInt64,
  channels : UInt64,
  scanlines : UInt64,
  position : UInt64,
) -> Result[(UInt64, UInt64, UInt64), @error.CoreError] {
  let remaining = scanlines - position
  let mut best_length = 0UL
  let mut best_distance = 0UL
  let mut work = 0UL
  let mut distance = 1UL
  while distance <= 4UL && distance <= position {
    let mut length = 0UL
    while length < 258UL && length < remaining {
      work = match _png_fixed_add(work, 3UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let current = match _png_fixed_scanline_byte(
        source, profile, row_bytes, channels, position + length,
      ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let prior = match _png_fixed_scanline_byte(
        source, profile, row_bytes, channels, position + length - distance,
      ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if current != prior { break }
      length = length + 1UL
    }
    if length >= 3UL && length > best_length {
      best_length = length
      best_distance = distance
    }
    distance = distance + 1UL
  }
  Ok((best_length, best_distance, work))
}

///| Fixed literal/length canonical codes, reversed for DEFLATE's LSB stream.
fn _png_fixed_literal_code(symbol : UInt64) -> (UInt64, UInt64) {
  let (canonical, bits) = if symbol <= 143UL {
    (48UL + symbol, 8UL)
  } else if symbol <= 255UL {
    (400UL + symbol - 144UL, 9UL)
  } else if symbol <= 279UL {
    (symbol - 256UL, 7UL)
  } else {
    (192UL + symbol - 280UL, 8UL)
  }
  (_png_reverse_bits(canonical.to_int(), bits.to_int()).to_uint64(), bits)
}

///| Translate a valid DEFLATE match length to its fixed literal/length symbol.
fn _png_fixed_length_code(length : UInt64) -> (UInt64, UInt64, UInt64) {
  let bases = [3UL, 4UL, 5UL, 6UL, 7UL, 8UL, 9UL, 10UL, 11UL, 13UL, 15UL, 17UL, 19UL, 23UL, 27UL, 31UL, 35UL, 43UL, 51UL, 59UL, 67UL, 83UL, 99UL, 115UL, 131UL, 163UL, 195UL, 227UL, 258UL]
  let extras = [0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 1UL, 1UL, 1UL, 1UL, 2UL, 2UL, 2UL, 2UL, 3UL, 3UL, 3UL, 3UL, 4UL, 4UL, 4UL, 4UL, 5UL, 5UL, 5UL, 5UL, 0UL]
  let mut index = 0
  while index + 1 < bases.length() && length >= bases[index + 1] { index = index + 1 }
  (257UL + index.to_uint64(), length - bases[index], extras[index])
}

///|
fn _png_fixed_distance_code(distance : UInt64) -> (UInt64, UInt64) {
  (_png_reverse_bits((distance - 1UL).to_int(), 5).to_uint64(), 5UL)
}

///| Count a dynamic token walk while retaining only the bounded alphabets.
fn _png_dynamic_frequencies(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[(Array[UInt64], Array[UInt64], UInt64, UInt64, PngFilteredTraversalFacts), @error.CoreError] {
  _png_dynamic_frequencies_with_interlace(
    source, row_bytes, channels, filter_strategy, scanlines, PngInterlaceStrategy::None, profile=profile,
  )
}

///|
fn _png_dynamic_frequencies_with_interlace(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  interlace_strategy : PngInterlaceStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[(Array[UInt64], Array[UInt64], UInt64, UInt64, PngFilteredTraversalFacts), @error.CoreError] {
  let literals = Array::make(286, 0UL)
  let distances = Array::make(30, 0UL)
  let mut cursor = PngFilteredMatchCursor::new_with_interlace(
    source, row_bytes, channels, filter_strategy, interlace_strategy, profile=profile,
  )
  let mut work = 0UL
  let mut fingerprint = 1UL
  while cursor.logical_position < scanlines {
    let (length, distance, match_work, matched) = match _png_filtered_match_at(cursor, scanlines) {
      Err(error) => return Err(error); Ok(value) => value }
    cursor = matched
    work = match _png_fixed_add(work, match_work) { Err(error) => return Err(error); Ok(value) => value }
    if length >= 3UL {
      let (symbol, _, _) = _png_fixed_length_code(length)
      literals[symbol.to_int()] = literals[symbol.to_int()] + 1UL
      distances[(distance - 1UL).to_int()] = distances[(distance - 1UL).to_int()] + 1UL
      for offset = 0UL; offset < length; offset = offset + 1UL {
        let byte = match cursor.read(cursor.logical_position + offset) {
          Err(error) => return Err(error); Ok(value) => value
        }
        fingerprint = _png_adler_step(fingerprint, byte)
      }
      cursor = match cursor.consume(length) { Err(error) => return Err(error); Ok(value) => value }
    } else {
      cursor = match cursor.ensure(cursor.logical_position + 1UL) { Err(error) => return Err(error); Ok(value) => value }
      let byte = match cursor.read(cursor.logical_position) {
        Err(error) => return Err(error); Ok(value) => value
      }
      literals[byte.to_int()] = literals[byte.to_int()] + 1UL
      fingerprint = _png_adler_step(fingerprint, byte)
      cursor = match cursor.consume(1UL) { Err(error) => return Err(error); Ok(value) => value }
    }
  }
  literals[256] = literals[256] + 1UL
  Ok((literals, distances, work, fingerprint, cursor.facts()))
}

///| Encode a trimmed literal/distance length stream using RFC 1951 symbols.
fn _png_dynamic_rle(lengths : Array[Int]) -> (Array[Int], Array[UInt64], Array[UInt64], UInt64) {
  let symbols = Array::make(316, 0)
  let extras = Array::make(316, 0UL)
  let extra_bits = Array::make(316, 0UL)
  let mut count = 0UL
  let mut cursor = 0
  while cursor < lengths.length() {
    let value = lengths[cursor]
    let mut run = 1
    while cursor + run < lengths.length() && lengths[cursor + run] == value { run = run + 1 }
    if value == 0 {
      let mut remaining = run
      while remaining > 0 {
        if remaining >= 11 {
          let take = if remaining > 138 { 138 } else { remaining }
          symbols[count.to_int()] = 18; extras[count.to_int()] = (take - 11).to_uint64(); extra_bits[count.to_int()] = 7UL
          count = count + 1UL; remaining = remaining - take
        } else if remaining >= 3 {
          let take = if remaining > 10 { 10 } else { remaining }
          symbols[count.to_int()] = 17; extras[count.to_int()] = (take - 3).to_uint64(); extra_bits[count.to_int()] = 3UL
          count = count + 1UL; remaining = remaining - take
        } else {
          symbols[count.to_int()] = 0; count = count + 1UL; remaining = remaining - 1
        }
      }
    } else {
      symbols[count.to_int()] = value; count = count + 1UL
      let mut remaining = run - 1
      while remaining > 0 {
        if remaining >= 3 {
          let take = if remaining > 6 { 6 } else { remaining }
          symbols[count.to_int()] = 16; extras[count.to_int()] = (take - 3).to_uint64(); extra_bits[count.to_int()] = 2UL
          count = count + 1UL; remaining = remaining - take
        } else {
          symbols[count.to_int()] = value; count = count + 1UL; remaining = remaining - 1
        }
      }
    }
    cursor = cursor + run
  }
  (symbols, extras, extra_bits, count)
}

///| Make one exact RFC dynamic candidate, or decline it without a length-limited
/// algorithm when the ordinary builder cannot satisfy the 15-bit limit.
fn _png_dynamic_plan(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngDynamicPlanOutcome, @error.CoreError] {
  _png_dynamic_plan_with_idat_limit(
    source, row_bytes, channels, filter_strategy, scanlines, 4294967295UL, profile=profile,
  )
}

///| The private bound directly exercises a post-bit-count decline without
///| widening the public encoder surface.
fn _png_dynamic_plan_with_idat_limit(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  max_idat_length : UInt64,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngDynamicPlanOutcome, @error.CoreError] {
  _png_dynamic_plan_with_interlace_idat_limit(
    source, row_bytes, channels, filter_strategy, scanlines, max_idat_length,
    PngInterlaceStrategy::None, profile=profile,
  )
}

///|
fn _png_dynamic_plan_with_interlace_idat_limit(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  max_idat_length : UInt64,
  interlace_strategy : PngInterlaceStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngDynamicPlanOutcome, @error.CoreError] {
  let (literal_frequencies, distance_frequencies, matcher_work, fingerprint, frequency_facts) =
    match _png_dynamic_frequencies_with_interlace(source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile) {
      Err(error) => return Err(error); Ok(value) => value
    }
  let literals = match _png_huffman_from_frequencies(literal_frequencies, true, false, true) {
    Some(value) => value; None => return Ok({
      plan: None, frequency_facts,
      bit_facts: { resolved_rows: 0UL, candidate_residuals: 0UL, selected_residuals: 0UL },
    })
  }
  let mut has_distance = false
  for frequency in distance_frequencies { if frequency > 0UL { has_distance = true } }
  if !has_distance { distance_frequencies[0] = 1UL }
  let distances = match _png_huffman_from_frequencies(distance_frequencies, false, true, false) {
    Some(value) => value; None => return Ok({
      plan: None, frequency_facts,
      bit_facts: { resolved_rows: 0UL, candidate_residuals: 0UL, selected_residuals: 0UL },
    })
  }
  let mut hlit = 286
  while hlit > 257 && literals.lengths[hlit - 1] == 0 { hlit = hlit - 1 }
  let mut hdist = 30
  while hdist > 1 && distances.lengths[hdist - 1] == 0 { hdist = hdist - 1 }
  let combined = Array::make(hlit + hdist, 0)
  for index = 0; index < hlit; index = index + 1 { combined[index] = literals.lengths[index] }
  for index = 0; index < hdist; index = index + 1 { combined[hlit + index] = distances.lengths[index] }
  let (rle_symbols, rle_extras, rle_extra_bits, rle_count) = _png_dynamic_rle(combined)
  let code_frequencies = Array::make(19, 0UL)
  for index = 0UL; index < rle_count; index = index + 1 {
    code_frequencies[rle_symbols[index.to_int()]] = code_frequencies[rle_symbols[index.to_int()]] + 1UL
  }
  let code_lengths = match _png_huffman_from_frequencies(code_frequencies, false, false, true) {
    Some(value) => value; None => return Ok({
      plan: None, frequency_facts,
      bit_facts: { resolved_rows: 0UL, candidate_residuals: 0UL, selected_residuals: 0UL },
    })
  }
  let order = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15]
  let mut hclen = 19
  while hclen > 4 && code_lengths.lengths[order[hclen - 1]] == 0 { hclen = hclen - 1 }
  let mut bits = 3UL + 5UL + 5UL + 4UL + (hclen.to_uint64() * 3UL)
  for index = 0UL; index < rle_count; index = index + 1 {
    let symbol = rle_symbols[index.to_int()]
    bits = match _png_fixed_add(bits, code_lengths.lengths[symbol].to_uint64() + rle_extra_bits[index.to_int()]) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let mut cursor = PngFilteredMatchCursor::new_with_interlace(
    source, row_bytes, channels, filter_strategy, interlace_strategy, profile=profile,
  )
  while cursor.logical_position < scanlines {
    let (length, distance, _, matched) = match _png_filtered_match_at(cursor, scanlines) {
      Err(error) => return Err(error); Ok(value) => value }
    cursor = matched
    if length >= 3UL {
      let (symbol, _, extra_bits) = _png_fixed_length_code(length)
      let distance_symbol = (distance - 1UL).to_int()
      bits = match _png_fixed_add(bits, literals.lengths[symbol.to_int()].to_uint64() + extra_bits + distances.lengths[distance_symbol].to_uint64()) {
        Err(error) => return Err(error); Ok(value) => value
      }
      cursor = match cursor.consume(length) { Err(error) => return Err(error); Ok(value) => value }
    } else {
      cursor = match cursor.ensure(cursor.logical_position + 1UL) { Err(error) => return Err(error); Ok(value) => value }
      let byte = match cursor.read(cursor.logical_position) { Err(error) => return Err(error); Ok(value) => value }
      bits = match _png_fixed_add(bits, literals.lengths[byte.to_int()].to_uint64()) { Err(error) => return Err(error); Ok(value) => value }
      cursor = match cursor.consume(1UL) { Err(error) => return Err(error); Ok(value) => value }
    }
  }
  bits = match _png_fixed_add(bits, literals.lengths[256].to_uint64()) { Err(error) => return Err(error); Ok(value) => value }
  let deflate_bytes = match _png_fixed_add(bits, 7UL) { Err(error) => return Err(error); Ok(value) => value / 8UL }
  let idat_length = match _png_fixed_add(deflate_bytes, 6UL) { Err(error) => return Err(error); Ok(value) => value }
  if idat_length > max_idat_length {
    return Ok({ plan: None, frequency_facts, bit_facts: cursor.facts() })
  }
  let total_length = match _png_fixed_add(idat_length, 57UL) { Err(error) => return Err(error); Ok(value) => value }
  Ok({
    plan: Some({ literals, distances, code_lengths, rle_symbols, rle_extras, rle_extra_bits, rle_count,
      hlit: hlit.to_uint64(), hdist: hdist.to_uint64(), hclen: hclen.to_uint64(), deflate_bits: bits,
      deflate_bytes, matcher_work, fingerprint, frequency_facts, bit_facts: cursor.facts(), idat_length, total_length }),
    frequency_facts, bit_facts: cursor.facts(),
  })
}

///| Walk the bounded matcher once to calculate exact fixed DEFLATE bits.
fn _png_fixed_plan(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngFixedPlan, @error.CoreError] {
  _png_fixed_plan_with_interlace(
    source, row_bytes, channels, filter_strategy, scanlines, PngInterlaceStrategy::None, profile=profile,
  )
}

///|
fn _png_fixed_plan_with_interlace(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
  interlace_strategy : PngInterlaceStrategy,
  profile? : PngEncodeProfile = PngEncodeProfile::LegacyRgbOrRgba,
) -> Result[PngFixedPlan, @error.CoreError] {
  let mut cursor = PngFilteredMatchCursor::new_with_interlace(
    source, row_bytes, channels, filter_strategy, interlace_strategy, profile=profile,
  )
  let mut bits = 3UL
  let mut matcher_work = 0UL
  let mut fingerprint = 1UL
  while cursor.logical_position < scanlines {
    let (length, distance, work, matched) = match _png_filtered_match_at(cursor, scanlines) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    cursor = matched
    matcher_work = match _png_fixed_add(matcher_work, work) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if length >= 3UL {
      let (symbol, _, extra_bits) = _png_fixed_length_code(length)
      let (_, symbol_bits) = _png_fixed_literal_code(symbol)
      bits = match _png_fixed_add(bits, symbol_bits + extra_bits + 5UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      for offset = 0UL; offset < length; offset = offset + 1UL {
        let byte = match cursor.read(cursor.logical_position + offset) {
          Err(error) => return Err(error); Ok(value) => value
        }
        fingerprint = _png_adler_step(fingerprint, byte)
      }
      cursor = match cursor.consume(length) { Err(error) => return Err(error); Ok(value) => value }
      ignore(distance)
    } else {
      cursor = match cursor.ensure(cursor.logical_position + 1UL) { Err(error) => return Err(error); Ok(value) => value }
      let byte = match cursor.read(cursor.logical_position) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let (_, literal_bits) = _png_fixed_literal_code(byte.to_uint64())
      bits = match _png_fixed_add(bits, literal_bits) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      fingerprint = _png_adler_step(fingerprint, byte)
      cursor = match cursor.consume(1UL) { Err(error) => return Err(error); Ok(value) => value }
    }
  }
  let (_, eob_bits) = _png_fixed_literal_code(256UL)
  bits = match _png_fixed_add(bits, eob_bits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let deflate_bytes = match _png_fixed_add(bits, 7UL) {
    Err(error) => return Err(error)
    Ok(value) => value / 8UL
  }
  let idat_length = match _png_fixed_add(deflate_bytes, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let total_length = match _png_fixed_add(idat_length, 57UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ deflate_bits: bits, deflate_bytes, matcher_work, fingerprint,
    traversal_facts: cursor.facts(), idat_length, total_length })
}

///|
/// The one authoritative, atomic admission path for eager and caller-buffered
/// output. FixedOrStored completes its frozen bounded choice first; the dynamic
/// opt-in can replace that winner only for a strictly smaller complete PNG.
fn _png_encode_preflight(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngEncodePreflight, @error.CoreError] {
  _png_encode_preflight_with_filter(
    source, strategy, PngFilterStrategy::None, limits, budget,
  )
}

///| The filter-aware atomic admission path. Every candidate and later replay
/// observes this same logical byte stream before any output can be exposed.
fn _png_encode_preflight_with_filter(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngEncodePreflight, @error.CoreError] {
  _png_encode_preflight_with_filter_idat_limit(
    source, strategy, filter_strategy, limits, budget, 4294967295UL,
  )
}

///| Interlace selection is admitted before the filter-aware preflight can read
/// source pixels, plan compression, reserve budget, or create output state.
fn _png_encode_preflight_with_interlace(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngEncodePreflight, @error.CoreError] {
  _png_encode_preflight_with_interlace_profile(
    source, PngEncodeProfile::LegacyRgbOrRgba, strategy, filter_strategy,
    interlace_strategy, limits, budget,
  )
}

///| Profile-aware entry point for the private machine construction seam.
fn _png_encode_preflight_with_interlace_profile(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[PngEncodePreflight, @error.CoreError] {
  match profile {
    PngEncodeProfile::Gray8 if interlace_strategy != PngInterlaceStrategy::None =>
      return Err(_png_encode_capability("gray8-noninterlaced-required"))
    PngEncodeProfile::Gray16 if interlace_strategy != PngInterlaceStrategy::None =>
      return Err(_png_encode_capability("gray16-noninterlaced-required"))
    _ => ()
  }
  _png_encode_preflight_with_filter_layout_idat_limit_profile(
    source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
    4294967295UL,
  )
}

///| The test-only bound takes the same atomic ledger path as production.
fn _png_encode_preflight_with_filter_idat_limit(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  dynamic_max_idat_length : UInt64,
) -> Result[PngEncodePreflight, @error.CoreError] {
  _png_encode_preflight_with_filter_layout_idat_limit_profile(
    source, PngEncodeProfile::LegacyRgbOrRgba, strategy, filter_strategy,
    PngInterlaceStrategy::None, limits, budget, dynamic_max_idat_length,
  )
}

///| One atomic ledger parameterized only by the scalar raster layout.  Adam7
/// pass totals come from `_png_adam7_passes`; every planner and replay pass is
/// a fresh traversal of that same bounded producer before the single charge.
fn _png_encode_preflight_with_filter_layout_idat_limit(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  dynamic_max_idat_length : UInt64,
) -> Result[PngEncodePreflight, @error.CoreError] {
  _png_encode_preflight_with_filter_layout_idat_limit_profile(
    source, PngEncodeProfile::LegacyRgbOrRgba, strategy, filter_strategy,
    interlace_strategy, limits, budget, dynamic_max_idat_length,
  )
}

///| One atomic ledger parameterized by profile and scalar raster layout.
fn _png_encode_preflight_with_filter_layout_idat_limit_profile(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  dynamic_max_idat_length : UInt64,
) -> Result[PngEncodePreflight, @error.CoreError] {
  let channels = match _png_encode_source(source, profile) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scanlines = match interlace_strategy {
    PngInterlaceStrategy::None => {
      let scanline_width = match @checked.checked_add(row_bytes, 1UL) {
        Err(error) => return Err(error); Ok(value) => value
      }
      match @checked.checked_mul(scanline_width, source.height()) {
        Err(error) => return Err(error); Ok(value) => value
      }
    }
    PngInterlaceStrategy::Adam7 => {
      let passes = match _png_adam7_passes(source.width(), source.height(), channels, 8) {
        Err(error) => return Err(error); Ok(value) => value
      }
      let mut total = 0UL
      for pass in passes {
        if pass.width == 0UL || pass.height == 0UL { continue }
        let per_row = match @checked.checked_add(pass.row_bytes, 1UL) {
          Err(error) => return Err(error); Ok(value) => value
        }
        let bytes = match @checked.checked_mul(per_row, pass.height) {
          Err(error) => return Err(error); Ok(value) => value
        }
        total = match @checked.checked_add(total, bytes) {
          Err(error) => return Err(error); Ok(value) => value
        }
      }
      total
    }
  }
  let blocks = match @checked.checked_add((scanlines - 1UL) / 65535UL, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let payload_and_adler = match @checked.checked_add(scanlines, 6UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let block_headers = match @checked.checked_mul(blocks, 5UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let stored_idat_length = match @checked.checked_add(payload_and_adler, block_headers) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let stored_total_length = match @checked.checked_add(stored_idat_length, 57UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let stored = PngStoredPlan::{
    blocks, idat_length: stored_idat_length, total_length: stored_total_length,
  }
  let mut adaptive_planning_facts = PngFilteredTraversalFacts::{
    resolved_rows: 0UL, candidate_residuals: 0UL, selected_residuals: 0UL,
  }
  let plan = match strategy {
    PngCompressionStrategy::Stored => {
      let pass = match _png_filtered_match_traverse_with_interlace(
        source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile,
      ) { Err(error) => return Err(error); Ok(value) => value }
      adaptive_planning_facts = match _png_filtered_facts_add(
        adaptive_planning_facts, pass,
      ) { Err(error) => return Err(error); Ok(value) => value }
      PngDeflatePlan::Stored(stored)
    }
    PngCompressionStrategy::FixedOrStored => {
      let pass = match _png_filtered_match_traverse_with_interlace(
        source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile,
      ) { Err(error) => return Err(error); Ok(value) => value }
      adaptive_planning_facts = match _png_filtered_facts_add(
        adaptive_planning_facts, pass,
      ) { Err(error) => return Err(error); Ok(value) => value }
      let fixed = match _png_fixed_plan_with_interlace(source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      adaptive_planning_facts = match _png_filtered_facts_add(
        adaptive_planning_facts, fixed.traversal_facts,
      ) { Err(error) => return Err(error); Ok(value) => value }
      if fixed.idat_length > 4294967295UL {
        return Err(_png_encode_capability("png-idat-length"))
      }
      if fixed.total_length <= stored.total_length {
        PngDeflatePlan::Fixed(fixed)
      } else {
        PngDeflatePlan::Stored(stored)
      }
    }
    PngCompressionStrategy::DynamicOrFixedOrStored => {
      let stored_pass = match _png_filtered_match_traverse_with_interlace(
        source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile,
      ) { Err(error) => return Err(error); Ok(value) => value }
      adaptive_planning_facts = match _png_filtered_facts_add(
        adaptive_planning_facts, stored_pass,
      ) { Err(error) => return Err(error); Ok(value) => value }
      let fixed = match _png_fixed_plan_with_interlace(source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile) {
        Err(error) => return Err(error); Ok(value) => value
      }
      adaptive_planning_facts = match _png_filtered_facts_add(
        adaptive_planning_facts, fixed.traversal_facts,
      ) { Err(error) => return Err(error); Ok(value) => value }
      if fixed.idat_length > 4294967295UL { return Err(_png_encode_capability("png-idat-length")) }
      let winner = if fixed.total_length <= stored.total_length {
        PngDeflatePlan::Fixed(fixed)
      } else { PngDeflatePlan::Stored(stored) }
      let winner_length = match winner {
        PngDeflatePlan::Stored(value) => value.total_length
        PngDeflatePlan::Fixed(value) => value.total_length
        PngDeflatePlan::Dynamic(value) => value.total_length
      }
      match _png_dynamic_plan_with_interlace_idat_limit(
        source, row_bytes, channels, filter_strategy, scanlines, dynamic_max_idat_length, interlace_strategy, profile=profile,
      ) {
        Err(error) => return Err(error)
        Ok(dynamic_outcome) => {
          adaptive_planning_facts = match _png_filtered_facts_add(
            adaptive_planning_facts, dynamic_outcome.frequency_facts,
          ) { Err(error) => return Err(error); Ok(value) => value }
          adaptive_planning_facts = match _png_filtered_facts_add(
            adaptive_planning_facts, dynamic_outcome.bit_facts,
          ) { Err(error) => return Err(error); Ok(value) => value }
          match dynamic_outcome.plan {
            Some(dynamic) => if dynamic.total_length < winner_length {
              PngDeflatePlan::Dynamic(dynamic)
            } else { winner }
            None => winner
          }
        }
      }
    }
  }
  let adaptive_replay_facts = match _png_filtered_match_traverse_with_interlace(
    source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile,
  ) { Err(error) => return Err(error); Ok(value) => value }
  let adaptive_filter_work = match _png_filtered_facts_add(
    adaptive_planning_facts, adaptive_replay_facts,
  ) { Err(error) => return Err(error); Ok(value) => value }
  let adaptive_filter_work = match adaptive_filter_work.work() {
    Err(error) => return Err(error); Ok(value) => value
  }
  let (blocks, idat_length, total_length, selected_work) = match plan {
    PngDeflatePlan::Stored(value) => (
      value.blocks, value.idat_length, value.total_length,
      match _png_fixed_add(value.total_length, adaptive_filter_work) { Err(error) => return Err(error); Ok(value) => value },
    )
    PngDeflatePlan::Fixed(value) => (
      0UL, value.idat_length, value.total_length,
      match _png_encode_selected_work(value.total_length, value.matcher_work, adaptive_filter_work) {
        Err(error) => return Err(error); Ok(value) => value
      },
    )
    // The exact ledger is selected bytes + planning matcher walk + replay
    // matcher walk; header/tree work is fixed by the RFC alphabet bounds.
    PngDeflatePlan::Dynamic(value) => (
      0UL, value.idat_length, value.total_length,
      match _png_encode_selected_work(value.total_length, value.matcher_work, adaptive_filter_work) {
        Err(error) => return Err(error); Ok(value) => value
      },
    )
  }
  for item in [
    ("width", source.width(), limits.max_width()),
    ("height", source.height(), limits.max_height()),
    ("pixels", pixels, limits.max_pixels()),
    ("output-bytes", total_length, limits.max_output_bytes()),
    ("work", selected_work, limits.max_work()),
  ] {
    let (context, requested, limit) = item
    match _png_encode_limit(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  let disposition = match _png_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match budget.charge(@budget.ResourceCharge::new(
    bytes=0UL, allocations=0UL, allocation_size=0UL, width=source.width(),
    height=source.height(), pixels=0UL, work=selected_work,
  )) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok({
    profile, channels, row_bytes, scanlines, blocks, idat_length, total_length, plan,
    disposition, selected_work, adaptive_planning_facts, adaptive_replay_facts,
  })
}

///|
pub impl @codec.ImageEncoder for PngEncoder with fn encode(
  _self,
  source,
  writer,
  _options,
  limits,
  budget,
  _diagnostics,
) {
  let machine = match PngEncodeMachine::new_with_profile(
    source, _self.profile, _self.strategy, _self.filter_strategy,
    _self.interlace_strategy, limits, budget, _diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  while true {
    let byte = match machine.present() {
      Err(error) => return Err(error)
      Ok(None) => break
      Ok(Some(value)) => value
    }
    let owner = match @bytes.OwnedBytes::from_bytes(
      Bytes::from_array([byte]), _png_private_budget(1UL),
    ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match writer.write(owner.view()) {
      @io.WriteOutcome::Progress(1UL) => ()
      @io.WriteOutcome::Progress(progress) => {
        return Err(_png_encode_invalid_writer_progress(progress))
      }
      @io.WriteOutcome::Failed(error, _) => return Err(error)
    }
    match machine.acknowledge(byte) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(@codec.EncodeResult::new(machine.disposition(), machine.completed()))
}
