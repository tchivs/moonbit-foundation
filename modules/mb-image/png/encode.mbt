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
fn _png_encode_source(source : @storage.ImageView) -> Result[UInt64, @error.CoreError] {
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
  if format.component() != @model.ComponentType::U8 {
    return Err(_png_encode_capability("component-u8-required"))
  }
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
  let channels = match format.channels() {
    @model.ChannelOrder::Rgb =>
      if metadata.alpha() is Some(_) {
        return Err(_png_encode_capability("rgb-alpha-unsupported"))
      } else {
        3UL
      }
    @model.ChannelOrder::Rgba =>
      match metadata.alpha() {
        Some(@color.AlphaMode::Straight) => 4UL
        _ => return Err(_png_encode_capability("straight-rgba-required"))
      }
    _ => return Err(_png_encode_capability("rgb-or-rgba-required"))
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
  channels : UInt64
  row_bytes : UInt64
  scanlines : UInt64
  blocks : UInt64
  idat_length : UInt64
  total_length : UInt64
  plan : PngDeflatePlan
  disposition : @metadata.MetadataDisposition
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
  idat_length : UInt64
  total_length : UInt64
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
enum PngRowFilter {
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
  if channels != 3UL && channels != 4UL { return Err(_png_encode_capability("png-filter-channels")) }
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

///| Return a scanline byte without materialising a filter-None scanline.
fn _png_fixed_scanline_byte(
  source : @storage.ImageView,
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
    source.get_byte(sample / channels, index / row_width, sample % channels)
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
  row : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  source.get_byte(position / channels, row, position % channels)
}

///| Apply a method-0 candidate directly to one ImageView row. This keeps the
/// adaptive source bounded to scalar coordinates and pixel reads.
fn _png_filter_image_candidate_byte(
  filter : PngRowFilter,
  source : @storage.ImageView,
  row : UInt64,
  row_bytes : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  if position >= row_bytes { return Err(_png_encode_capability("png-filter-row-access")) }
  let sample = match _png_filter_image_raw_byte(source, row, channels, position) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let left = if position < channels { b'\x00' } else {
    match _png_filter_image_raw_byte(source, row, channels, position - channels) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let up = if row == 0UL { b'\x00' } else {
    match _png_filter_image_raw_byte(source, row - 1UL, channels, position) {
      Err(error) => return Err(error); Ok(value) => value
    }
  }
  let upper_left = if row == 0UL || position < channels { b'\x00' } else {
    match _png_filter_image_raw_byte(source, row - 1UL, channels, position - channels) {
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
        candidate, source, row, row_bytes, channels, position,
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

///| The common logical filtered stream. None keeps its legacy provider exactly;
/// Adaptive derives one tag and residual payload from the fixed scorer.
fn _png_filtered_scanline_byte(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  index : UInt64,
) -> Result[Byte, @error.CoreError] {
  match filter_strategy {
    PngFilterStrategy::None => _png_fixed_scanline_byte(source, row_bytes, channels, index)
    PngFilterStrategy::Adaptive => {
      let row_width = match @checked.checked_add(row_bytes, 1UL) {
        Err(error) => return Err(error); Ok(value) => value
      }
      let row = index / row_width
      let in_row = index % row_width
      let winner = match _png_filter_image_row_winner(source, row, row_bytes, channels) {
        Err(error) => return Err(error); Ok(value) => value
      }
      if in_row == 0UL { Ok(_png_filter_tag(winner)) } else {
        _png_filter_image_candidate_byte(
          winner, source, row, row_bytes, channels, in_row - 1UL,
        )
      }
    }
  }
}

///| The bounded DEFLATE matcher over the selected logical filter stream.
fn _png_filtered_match_at(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
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
      work = match _png_fixed_add(work, 3UL) { Err(error) => return Err(error); Ok(value) => value }
      let current = match _png_filtered_scanline_byte(source, row_bytes, channels, filter_strategy, position + length) {
        Err(error) => return Err(error); Ok(value) => value
      }
      let prior = match _png_filtered_scanline_byte(source, row_bytes, channels, filter_strategy, position + length - distance) {
        Err(error) => return Err(error); Ok(value) => value
      }
      if current != prior { break }
      length = length + 1UL
    }
    if length >= 3UL && length > best_length { best_length = length; best_distance = distance }
    distance = distance + 1UL
  }
  Ok((best_length, best_distance, work))
}

///| A1: scan only distances 1 through 4 in ascending order. Strictly replacing
/// the best length intentionally retains the smaller distance on ties.
fn _png_fixed_match_at(
  source : @storage.ImageView,
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
        source, row_bytes, channels, position + length,
      ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let prior = match _png_fixed_scanline_byte(
        source, row_bytes, channels, position + length - distance,
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
) -> Result[(Array[UInt64], Array[UInt64], UInt64, UInt64), @error.CoreError] {
  let literals = Array::make(286, 0UL)
  let distances = Array::make(30, 0UL)
  let mut position = 0UL
  let mut work = 0UL
  let mut fingerprint = 1UL
  while position < scanlines {
    let (length, distance, match_work) = match _png_filtered_match_at(
      source, row_bytes, channels, filter_strategy, scanlines, position,
    ) { Err(error) => return Err(error); Ok(value) => value }
    work = match _png_fixed_add(work, match_work) { Err(error) => return Err(error); Ok(value) => value }
    if length >= 3UL {
      let (symbol, _, _) = _png_fixed_length_code(length)
      literals[symbol.to_int()] = literals[symbol.to_int()] + 1UL
      distances[(distance - 1UL).to_int()] = distances[(distance - 1UL).to_int()] + 1UL
      for offset = 0UL; offset < length; offset = offset + 1UL {
        let byte = match _png_filtered_scanline_byte(source, row_bytes, channels, filter_strategy, position + offset) {
          Err(error) => return Err(error); Ok(value) => value
        }
        fingerprint = _png_adler_step(fingerprint, byte)
      }
      position = position + length
    } else {
      let byte = match _png_filtered_scanline_byte(source, row_bytes, channels, filter_strategy, position) {
        Err(error) => return Err(error); Ok(value) => value
      }
      literals[byte.to_int()] = literals[byte.to_int()] + 1UL
      fingerprint = _png_adler_step(fingerprint, byte)
      position = position + 1UL
    }
  }
  literals[256] = literals[256] + 1UL
  Ok((literals, distances, work, fingerprint))
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
) -> Result[PngDynamicPlan?, @error.CoreError] {
  let (literal_frequencies, distance_frequencies, matcher_work, fingerprint) =
    match _png_dynamic_frequencies(source, row_bytes, channels, filter_strategy, scanlines) {
      Err(error) => return Err(error); Ok(value) => value
    }
  let literals = match _png_huffman_from_frequencies(literal_frequencies, true, false, true) {
    Some(value) => value; None => return Ok(None)
  }
  let mut has_distance = false
  for frequency in distance_frequencies { if frequency > 0UL { has_distance = true } }
  if !has_distance { distance_frequencies[0] = 1UL }
  let distances = match _png_huffman_from_frequencies(distance_frequencies, false, true, false) {
    Some(value) => value; None => return Ok(None)
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
    Some(value) => value; None => return Ok(None)
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
  let mut position = 0UL
  while position < scanlines {
    let (length, distance, _) = match _png_filtered_match_at(source, row_bytes, channels, filter_strategy, scanlines, position) {
      Err(error) => return Err(error); Ok(value) => value
    }
    if length >= 3UL {
      let (symbol, _, extra_bits) = _png_fixed_length_code(length)
      let distance_symbol = (distance - 1UL).to_int()
      bits = match _png_fixed_add(bits, literals.lengths[symbol.to_int()].to_uint64() + extra_bits + distances.lengths[distance_symbol].to_uint64()) {
        Err(error) => return Err(error); Ok(value) => value
      }
      position = position + length
    } else {
      let byte = match _png_filtered_scanline_byte(source, row_bytes, channels, filter_strategy, position) { Err(error) => return Err(error); Ok(value) => value }
      bits = match _png_fixed_add(bits, literals.lengths[byte.to_int()].to_uint64()) { Err(error) => return Err(error); Ok(value) => value }
      position = position + 1UL
    }
  }
  bits = match _png_fixed_add(bits, literals.lengths[256].to_uint64()) { Err(error) => return Err(error); Ok(value) => value }
  let deflate_bytes = match _png_fixed_add(bits, 7UL) { Err(error) => return Err(error); Ok(value) => value / 8UL }
  let idat_length = match _png_fixed_add(deflate_bytes, 6UL) { Err(error) => return Err(error); Ok(value) => value }
  if idat_length > 4294967295UL { return Ok(None) }
  let total_length = match _png_fixed_add(idat_length, 57UL) { Err(error) => return Err(error); Ok(value) => value }
  Ok(Some({ literals, distances, code_lengths, rle_symbols, rle_extras, rle_extra_bits, rle_count,
    hlit: hlit.to_uint64(), hdist: hdist.to_uint64(), hclen: hclen.to_uint64(), deflate_bits: bits,
    deflate_bytes, matcher_work, fingerprint, idat_length, total_length }))
}

///| Walk the bounded matcher once to calculate exact fixed DEFLATE bits.
fn _png_fixed_plan(
  source : @storage.ImageView,
  row_bytes : UInt64,
  channels : UInt64,
  filter_strategy : PngFilterStrategy,
  scanlines : UInt64,
) -> Result[PngFixedPlan, @error.CoreError] {
  let mut position = 0UL
  let mut bits = 3UL
  let mut matcher_work = 0UL
  while position < scanlines {
    let (length, distance, work) = match _png_filtered_match_at(
      source, row_bytes, channels, filter_strategy, scanlines, position,
    ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
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
      position = position + length
      ignore(distance)
    } else {
      let byte = match _png_filtered_scanline_byte(source, row_bytes, channels, filter_strategy, position) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let (_, literal_bits) = _png_fixed_literal_code(byte.to_uint64())
      bits = match _png_fixed_add(bits, literal_bits) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      position = position + 1UL
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
  Ok({ deflate_bits: bits, deflate_bytes, matcher_work, idat_length, total_length })
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
  let channels = match _png_encode_source(source) {
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
  let scanline_width = match @checked.checked_add(row_bytes, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let scanlines = match @checked.checked_mul(scanline_width, source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
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
  let plan = match strategy {
    PngCompressionStrategy::Stored => PngDeflatePlan::Stored(stored)
    PngCompressionStrategy::FixedOrStored => {
      let fixed = match _png_fixed_plan(source, row_bytes, channels, filter_strategy, scanlines) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
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
      let fixed = match _png_fixed_plan(source, row_bytes, channels, filter_strategy, scanlines) {
        Err(error) => return Err(error); Ok(value) => value
      }
      if fixed.idat_length > 4294967295UL { return Err(_png_encode_capability("png-idat-length")) }
      let winner = if fixed.total_length <= stored.total_length {
        PngDeflatePlan::Fixed(fixed)
      } else { PngDeflatePlan::Stored(stored) }
      let winner_length = match winner {
        PngDeflatePlan::Stored(value) => value.total_length
        PngDeflatePlan::Fixed(value) => value.total_length
        PngDeflatePlan::Dynamic(value) => value.total_length
      }
      match _png_dynamic_plan(source, row_bytes, channels, filter_strategy, scanlines) {
        Err(error) => return Err(error)
        Ok(Some(dynamic)) => if dynamic.total_length < winner_length {
          PngDeflatePlan::Dynamic(dynamic)
        } else { winner }
        Ok(None) => winner
      }
    }
  }
  let candidate_score_work_per_row = match @checked.checked_mul(5UL, row_bytes) {
    Err(error) => return Err(error); Ok(value) => value
  }
  let adaptive_filter_work = match filter_strategy {
    PngFilterStrategy::None => 0UL
    PngFilterStrategy::Adaptive => {
      let planning = match @checked.checked_mul(source.height(), candidate_score_work_per_row) {
        Err(error) => return Err(error); Ok(value) => value
      }
      match @checked.checked_add(planning, planning) {
        Err(error) => return Err(error); Ok(value) => value
      }
    }
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
  Ok({ channels, row_bytes, scanlines, blocks, idat_length, total_length, plan, disposition })
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
  let machine = match PngEncodeMachine::new_with_strategies(
    source, _self.strategy, _self.filter_strategy, limits, budget, _diagnostics,
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
