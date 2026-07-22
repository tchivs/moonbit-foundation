///|
priv enum PngChunkEncoderState {
  Active(PngEncodeMachine)
  Finished
  Failed(@error.CoreError)
}

///|
pub fn PngChunkEncoder::new(
  source : @storage.ImageView,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_with_all_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    PngInterlaceStrategy::None, limits, budget, diagnostics,
  )
}

///| Constructs the explicit Gray8 caller-buffered route: 8-bit grayscale,
/// Stored DEFLATE, filter None, and no interlace.
pub fn PngChunkEncoder::new_gray8(
  source : @storage.ImageView,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_gray8_with_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    limits, budget, diagnostics,
  )
}

///| Constructs a Gray8 caller-buffered encoder with an explicit compression
/// strategy and the filter-None route. Gray8 remains intentionally
/// non-interlaced.
pub fn PngChunkEncoder::new_gray8_with_compression_strategy(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_gray8_with_strategies(
    source, strategy, PngFilterStrategy::None, limits, budget, diagnostics,
  )
}

///| Constructs a Gray8 caller-buffered encoder with an explicit filter
/// strategy and Stored compression. Gray8 remains intentionally non-interlaced.
pub fn PngChunkEncoder::new_gray8_with_filter_strategy(
  source : @storage.ImageView,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_gray8_with_strategies(
    source, PngCompressionStrategy::Stored, filter_strategy, limits, budget, diagnostics,
  )
}

///| Constructs a Gray8 caller-buffered encoder with explicit compression and
/// filter strategies. Its profile fixes PNG colour type 0 and excludes Adam7.
pub fn PngChunkEncoder::new_gray8_with_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::Gray8, strategy, filter_strategy,
    PngInterlaceStrategy::None, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}

///|
/// Constructs a caller-buffered encoder with an explicit PNG compression strategy
/// and the explicit filter-None route. `Stored` and `FixedOrStored` retain frozen
/// compatibility output. `DynamicOrFixedOrStored` may choose Dynamic only for a
/// strict complete-PNG win over unchanged FixedOrStored and retains FixedOrStored on a tie.
pub fn PngChunkEncoder::new_with_compression_strategy(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_with_all_strategies(
    source, strategy, PngFilterStrategy::None, PngInterlaceStrategy::None,
    limits, budget, diagnostics,
  )
}

///|
/// Constructs a caller-buffered encoder with an explicit PNG filter selection
/// and the Stored compression route. `new_with_filter_strategy(Adaptive)` remains
/// Stored plus Adaptive; use `new_with_strategies` to combine Adaptive with a
/// different compression strategy.
pub fn PngChunkEncoder::new_with_filter_strategy(
  source : @storage.ImageView,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_with_all_strategies(
    source, PngCompressionStrategy::Stored, filter_strategy, PngInterlaceStrategy::None,
    limits, budget, diagnostics,
  )
}

///|
/// Constructs a caller-buffered encoder with explicit PNG compression and filter
/// strategies. With `Adaptive`, the shared machine evaluates method-0 candidates
/// in None, Sub, Up, Average, Paeth order, scores signed-absolute residual
/// magnitudes, and replaces the winner only for a strictly lower score.
pub fn PngChunkEncoder::new_with_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_with_all_strategies(
    source, strategy, filter_strategy, PngInterlaceStrategy::None,
    limits, budget, diagnostics,
  )
}

///| Constructs a caller-buffered encoder with explicit interlace selection and
/// the frozen Stored/filter-None route.
pub fn PngChunkEncoder::new_with_interlace_strategy(
  source : @storage.ImageView,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_with_all_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    interlace_strategy, limits, budget, diagnostics,
  )
}

///| Constructs a caller-buffered encoder with independently selected
/// compression, filter, and interlace strategies.
pub fn PngChunkEncoder::new_with_all_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_all_strategies(
    source, strategy, filter_strategy, interlace_strategy, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}

///|
pub fn PngChunkEncoder::pull(
  self : PngChunkEncoder,
  destination : @bytes.MutByteLease,
) -> PngChunkPullResult {
  match self.state {
    PngChunkEncoderState::Finished => return {
      written_value: 0UL,
      total_written_value: self.total_written,
      outcome_value: PngChunkPullOutcome::Finished,
    }
    PngChunkEncoderState::Failed(error) => return {
      written_value: 0UL,
      total_written_value: self.total_written,
      outcome_value: PngChunkPullOutcome::Failed(error),
    }
    PngChunkEncoderState::Active(machine) => {
      let mut written = 0UL
      while written < destination.length() {
        let byte = match machine.present() {
          Err(error) => {
            self.state = PngChunkEncoderState::Failed(error)
            return {
              written_value: 0UL,
              total_written_value: self.total_written,
              outcome_value: PngChunkPullOutcome::Failed(error),
            }
          }
          Ok(None) => {
            self.state = PngChunkEncoderState::Finished
            return {
              written_value: written,
              total_written_value: self.total_written,
              outcome_value: PngChunkPullOutcome::Finished,
            }
          }
          Ok(Some(value)) => value
        }
        match destination.set(written, byte) {
          Err(error) => {
            self.state = PngChunkEncoderState::Failed(error)
            return {
              written_value: 0UL,
              total_written_value: self.total_written,
              outcome_value: PngChunkPullOutcome::Failed(error),
            }
          }
          Ok(_) => ()
        }
        match machine.acknowledge(byte) {
          Err(error) => {
            self.state = PngChunkEncoderState::Failed(error)
            return {
              written_value: 0UL,
              total_written_value: self.total_written,
              outcome_value: PngChunkPullOutcome::Failed(error),
            }
          }
          Ok(_) => ()
        }
        written = written + 1UL
        self.total_written = machine.completed()
        if self.total_written == machine.total_length() {
          self.state = PngChunkEncoderState::Finished
          return {
            written_value: written,
            total_written_value: self.total_written,
            outcome_value: PngChunkPullOutcome::Finished,
          }
        }
      }
      {
        written_value: written,
        total_written_value: self.total_written,
        outcome_value: PngChunkPullOutcome::NeedOutput,
      }
    }
  }
}

///|
/// Private, owned PNG output state. Stored keeps its frozen byte path; FixedOrStored uses
/// scalar fixed-Huffman replay. DynamicOrFixedOrStored plans a Dynamic DEFLATE block and
/// replays it with owned PngDynamicState. None retains the frozen filter-None provider;
/// Adaptive uses bounded method-0 row selection and replay cursors. A 32 KiB dictionary,
/// FFI codec, host adapters, and output-sized staging remain excluded.
priv struct PngEncodeMachine {
  source : @storage.ImageView
  profile : PngEncodeProfile
  strategy : PngCompressionStrategy
  filter_strategy : PngFilterStrategy
  interlace_strategy : PngInterlaceStrategy
  width : UInt64
  height : UInt64
  channels : UInt64
  row_bytes : UInt64
  scanlines : UInt64
  blocks : UInt64
  idat_length : UInt64
  total_length_value : UInt64
  plan : PngDeflatePlan
  disposition : @metadata.MetadataDisposition
  mut emitted : UInt64
  mut pending : Byte?
  mut pending_stored : PngFilteredMatchCursor?
  mut pending_fixed : PngFixedState?
  mut pending_dynamic : PngDynamicState?
  mut stored_cursor : PngFilteredMatchCursor?
  mut fixed_state : PngFixedState?
  mut dynamic_state : PngDynamicState?
  mut ihdr_crc : UInt64
  mut idat_crc : UInt64
  mut adler : UInt64
  mut finished : Bool
}

///| All fixed emission state is scalar and advances only when the byte preview
/// that carried it is acknowledged by the eager Writer or caller lease.
priv struct PngFixedState {
  raw_cursor : UInt64
  filtered_cursor : PngFilteredMatchCursor?
  bit_value : UInt64
  bit_count : UInt64
  adler : UInt64
  fingerprint : UInt64
  matcher_work : UInt64
  header_written : Bool
  eob_written : Bool
}

///| Dynamic replay retains only cursors, a bit accumulator, and scalar
/// integrity/work facts.  It regenerates tokens from the caller image and does
/// not retain scanlines, a history buffer, output, or a caller lease.
priv struct PngDynamicState {
  phase : Int
  header_cursor : UInt64
  code_length_cursor : UInt64
  rle_cursor : UInt64
  raw_cursor : UInt64
  filtered_cursor : PngFilteredMatchCursor?
  bit_value : UInt64
  bit_count : UInt64
  adler : UInt64
  matcher_work : UInt64
}

///|
fn _png_encode_machine_state_error(context : String) -> @error.CoreError {
  _png_encode_error(
    @error.ErrorCategory::State, @error.ErrorCode::InvalidRange, context,
  )
}

///|
fn PngEncodeMachine::new(
  source : @storage.ImageView,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  _diagnostics : @error.Diagnostics,
) -> Result[PngEncodeMachine, @error.CoreError] {
  PngEncodeMachine::new_with_all_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    PngInterlaceStrategy::None, limits, budget, _diagnostics,
  )
}

///|
fn PngEncodeMachine::new_with_compression_strategy(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  _diagnostics : @error.Diagnostics,
) -> Result[PngEncodeMachine, @error.CoreError] {
  PngEncodeMachine::new_with_all_strategies(
    source, strategy, PngFilterStrategy::None, PngInterlaceStrategy::None,
    limits, budget, _diagnostics,
  )
}

///|
fn PngEncodeMachine::new_with_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  _diagnostics : @error.Diagnostics,
) -> Result[PngEncodeMachine, @error.CoreError] {
  PngEncodeMachine::new_with_all_strategies(
    source, strategy, filter_strategy, PngInterlaceStrategy::None,
    limits, budget, _diagnostics,
  )
}

///| The one private construction seam retains the selected interlace intent and
/// admits it atomically before source traversal, budget charging, or output state.
fn PngEncodeMachine::new_with_all_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  _diagnostics : @error.Diagnostics,
) -> Result[PngEncodeMachine, @error.CoreError] {
  PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::LegacyRgbOrRgba, strategy, filter_strategy,
    interlace_strategy, limits, budget, _diagnostics,
  )
}

///| The profile-aware construction seam keeps Gray8 source admission atomic and
/// keeps unsupported Gray strategy combinations private and unavailable.
fn PngEncodeMachine::new_with_profile(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  _diagnostics : @error.Diagnostics,
) -> Result[PngEncodeMachine, @error.CoreError] {
  let facts = match _png_encode_preflight_with_interlace_profile(
    source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    source,
    profile: facts.profile,
    strategy,
    filter_strategy,
    interlace_strategy,
    width: source.width(),
    height: source.height(),
    channels: facts.channels,
    row_bytes: facts.row_bytes,
    scanlines: facts.scanlines,
    blocks: facts.blocks,
    idat_length: facts.idat_length,
    total_length_value: facts.total_length,
    plan: facts.plan,
    disposition: facts.disposition,
    emitted: 0UL,
    pending: None,
    pending_stored: None,
    pending_fixed: None,
    pending_dynamic: None,
    stored_cursor: if interlace_strategy == PngInterlaceStrategy::Adam7 ||
      filter_strategy == PngFilterStrategy::Adaptive {
      Some(PngFilteredMatchCursor::new_with_interlace(
        source, facts.row_bytes, facts.channels, filter_strategy, interlace_strategy,
      ))
    } else { None },
    fixed_state: match facts.plan {
      PngDeflatePlan::Stored(_) => None
      PngDeflatePlan::Fixed(_) => Some({
        raw_cursor: 0UL,
        filtered_cursor: if interlace_strategy == PngInterlaceStrategy::Adam7 ||
          filter_strategy == PngFilterStrategy::Adaptive {
          Some(PngFilteredMatchCursor::new_with_interlace(
            source, facts.row_bytes, facts.channels, filter_strategy, interlace_strategy,
          ))
        } else { None },
        bit_value: 0UL, bit_count: 0UL, adler: 1UL,
        fingerprint: 1UL, matcher_work: 0UL, header_written: false, eob_written: false,
      })
      PngDeflatePlan::Dynamic(_) => None
    },
    dynamic_state: match facts.plan {
      PngDeflatePlan::Dynamic(_) => Some({ phase: 0, header_cursor: 0UL,
        code_length_cursor: 0UL, rle_cursor: 0UL, raw_cursor: 0UL,
        filtered_cursor: if interlace_strategy == PngInterlaceStrategy::Adam7 ||
          filter_strategy == PngFilterStrategy::Adaptive {
          Some(PngFilteredMatchCursor::new_with_interlace(
            source, facts.row_bytes, facts.channels, filter_strategy, interlace_strategy,
          ))
        } else { None },
        bit_value: 0UL, bit_count: 0UL, adler: 1UL, matcher_work: 0UL })
      _ => None
    },
    ihdr_crc: _png_crc_for_type([b'I', b'H', b'D', b'R']),
    idat_crc: _png_crc_for_type([b'I', b'D', b'A', b'T']),
    adler: 1UL,
    finished: false,
  })
}

///|
fn PngEncodeMachine::total_length(self : PngEncodeMachine) -> UInt64 {
  self.total_length_value
}

///|
fn PngEncodeMachine::completed(self : PngEncodeMachine) -> UInt64 {
  self.emitted
}

///|
fn PngEncodeMachine::disposition(self : PngEncodeMachine) -> @metadata.MetadataDisposition {
  self.disposition
}

///|
fn _png_encode_machine_u32_byte(value : UInt64, offset : UInt64) -> Byte {
  ((value >> ((3UL - offset) * 8UL).to_int()) & 255UL).to_byte()
}

///|
fn PngEncodeMachine::scanline_byte(
  self : PngEncodeMachine,
  index : UInt64,
) -> Result[Byte, @error.CoreError] {
  _png_filtered_scanline_byte(
    self.source, self.row_bytes, self.channels, self.filter_strategy, index,
  )
}

///|
fn PngEncodeMachine::zlib_byte(
  self : PngEncodeMachine,
  offset : UInt64,
) -> Result[Byte, @error.CoreError] {
  match self.plan {
    PngDeflatePlan::Fixed(_) => return self.fixed_zlib_byte(offset)
    PngDeflatePlan::Dynamic(_) => return self.dynamic_zlib_byte(offset)
    PngDeflatePlan::Stored(_) => ()
  }
  if offset == 0UL { return Ok(b'\x78') }
  if offset == 1UL { return Ok(b'\x01') }
  let relative = offset - 2UL
  let stored_length = self.idat_length - 6UL
  if relative >= stored_length {
    let adler_offset = relative - stored_length
    if adler_offset < 4UL {
      return Ok(_png_encode_machine_u32_byte(self.adler, adler_offset))
    }
    return Err(_png_encode_machine_state_error("png-encode-zlib-cursor"))
  }
  let block_index = relative / 65540UL
  let in_block = relative % 65540UL
  let payload = if block_index + 1UL == self.blocks {
    self.scanlines - (self.blocks - 1UL) * 65535UL
  } else {
    65535UL
  }
  if in_block == 0UL {
    Ok(if block_index + 1UL == self.blocks { b'\x01' } else { b'\x00' })
  } else if in_block == 1UL {
    Ok(payload.to_byte())
  } else if in_block == 2UL {
    Ok((payload >> 8).to_byte())
  } else if in_block == 3UL {
    Ok((65535UL - payload).to_byte())
  } else if in_block == 4UL {
    Ok(((65535UL - payload) >> 8).to_byte())
  } else if in_block < payload + 5UL {
    match self.stored_cursor {
      Some(cursor) => {
        let (byte, next) = match cursor.next() {
          Err(error) => return Err(error); Ok(value) => value
        }
        self.pending_stored = Some(next)
        Ok(byte)
      }
      None => self.scanline_byte(block_index * 65535UL + in_block - 5UL)
    }
  } else {
    Err(_png_encode_machine_state_error("png-encode-stored-cursor"))
  }
}

///|
fn _png_fixed_put_bits(
  value : UInt64,
  count : UInt64,
  bits : UInt64,
  width : UInt64,
) -> (UInt64, UInt64) {
  (value | (bits << count.to_int()), count + width)
}

///| Simulate exactly one fixed DEFLATE byte without mutating the committed
/// machine. The returned scalar state becomes visible only in acknowledge.
fn PngEncodeMachine::fixed_preview_byte(
  self : PngEncodeMachine,
) -> Result[(Byte, PngFixedState), @error.CoreError] {
  let plan = match self.plan {
    PngDeflatePlan::Fixed(value) => value
    _ => return Err(_png_encode_machine_state_error("png-encode-fixed-plan"))
  }
  let state = match self.fixed_state {
    Some(value) => value
    None => return Err(_png_encode_machine_state_error("png-encode-fixed-state"))
  }
  let mut raw_cursor = state.raw_cursor
  let mut filtered_cursor = state.filtered_cursor
  let mut bit_value = state.bit_value
  let mut bit_count = state.bit_count
  let mut adler = state.adler
  let mut fingerprint = state.fingerprint
  let mut matcher_work = state.matcher_work
  let mut header_written = state.header_written
  let mut eob_written = state.eob_written
  while bit_count < 8UL {
    if !header_written {
      let (next_value, next_count) = _png_fixed_put_bits(
        bit_value, bit_count, 3UL, 3UL,
      )
      bit_value = next_value
      bit_count = next_count
      header_written = true
    } else if raw_cursor < self.scanlines {
      let (length, distance, work) = match filtered_cursor {
        Some(cursor) => {
          let (length, distance, work, next) = match _png_filtered_match_at(
            cursor, self.scanlines,
          ) { Err(error) => return Err(error); Ok(value) => value }
          filtered_cursor = Some(next)
          (length, distance, work)
        }
        None => match _png_fixed_match_at(
          self.source, self.row_bytes, self.channels, self.scanlines, raw_cursor,
        ) { Err(error) => return Err(error); Ok(value) => value }
      }
      matcher_work = match _png_fixed_add(matcher_work, work) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      if length >= 3UL {
        let (symbol, extra, extra_bits) = _png_fixed_length_code(length)
        let (code, code_bits) = _png_fixed_literal_code(symbol)
        let (next_value, next_count) = _png_fixed_put_bits(
          bit_value, bit_count, code, code_bits,
        )
        bit_value = next_value
        bit_count = next_count
        if extra_bits > 0UL {
          let (next_value, next_count) = _png_fixed_put_bits(
            bit_value, bit_count, extra, extra_bits,
          )
          bit_value = next_value
          bit_count = next_count
        }
        let (distance_code, distance_bits) = _png_fixed_distance_code(distance)
        let (next_value, next_count) = _png_fixed_put_bits(
          bit_value, bit_count, distance_code, distance_bits,
        )
        bit_value = next_value
        bit_count = next_count
        let mut index = 0UL
        while index < length {
          let byte = match filtered_cursor {
            Some(cursor) => {
              let (value, next) = match cursor.next() {
                Err(error) => return Err(error); Ok(value) => value
              }
              filtered_cursor = Some(next)
              value
            }
            None => match _png_fixed_scanline_byte(
              self.source, self.row_bytes, self.channels, raw_cursor + index,
            ) { Err(error) => return Err(error); Ok(value) => value }
          }
          adler = _png_adler_step(adler, byte)
          fingerprint = _png_adler_step(fingerprint, byte)
          index = index + 1UL
        }
        raw_cursor = raw_cursor + length
      } else {
        let byte = match filtered_cursor {
          Some(cursor) => {
            let (value, next) = match cursor.next() {
              Err(error) => return Err(error); Ok(value) => value
            }
            filtered_cursor = Some(next)
            value
          }
          None => match _png_fixed_scanline_byte(
            self.source, self.row_bytes, self.channels, raw_cursor,
          ) { Err(error) => return Err(error); Ok(value) => value }
        }
        let (code, code_bits) = _png_fixed_literal_code(byte.to_uint64())
        let (next_value, next_count) = _png_fixed_put_bits(
          bit_value, bit_count, code, code_bits,
        )
        bit_value = next_value
        bit_count = next_count
        adler = _png_adler_step(adler, byte)
        fingerprint = _png_adler_step(fingerprint, byte)
        raw_cursor = raw_cursor + 1UL
      }
    } else if !eob_written {
      if matcher_work != plan.matcher_work {
        return Err(_png_encode_machine_state_error("png-encode-fixed-replay-work"))
      }
      if fingerprint != plan.fingerprint {
        return Err(_png_encode_machine_state_error("png-encode-fixed-replay-drift"))
      }
      let (eob, eob_bits) = _png_fixed_literal_code(256UL)
      let (next_value, next_count) = _png_fixed_put_bits(
        bit_value, bit_count, eob, eob_bits,
      )
      bit_value = next_value
      bit_count = next_count
      eob_written = true
    } else {
      let byte = bit_value.to_byte()
      return Ok((byte, {
        raw_cursor, filtered_cursor, bit_value: 0UL, bit_count: 0UL, adler, fingerprint, matcher_work, eob_written,
        header_written,
      }))
    }
  }
  let byte = bit_value.to_byte()
  Ok((byte, {
    raw_cursor, filtered_cursor, bit_value: bit_value >> 8, bit_count: bit_count - 8UL,
    adler, fingerprint, matcher_work, header_written, eob_written,
  }))
}

///|
fn PngEncodeMachine::fixed_zlib_byte(
  self : PngEncodeMachine,
  offset : UInt64,
) -> Result[Byte, @error.CoreError] {
  let plan = match self.plan {
    PngDeflatePlan::Fixed(value) => value
    _ => return Err(_png_encode_machine_state_error("png-encode-fixed-plan"))
  }
  if offset == 0UL { return Ok(b'\x78') }
  if offset == 1UL { return Ok(b'\x01') }
  if offset < plan.deflate_bytes + 2UL {
    let (byte, next) = match self.fixed_preview_byte() {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    self.pending_fixed = Some(next)
    return Ok(byte)
  }
  let adler_offset = offset - plan.deflate_bytes - 2UL
  if adler_offset < 4UL {
    let state = match self.fixed_state {
      Some(value) => value
      None => return Err(_png_encode_machine_state_error("png-encode-fixed-state"))
    }
    return Ok(_png_encode_machine_u32_byte(state.adler, adler_offset))
  }
  Err(_png_encode_machine_state_error("png-encode-fixed-cursor"))
}

///| Put a dynamic canonical code into the LSB-first DEFLATE accumulator.
fn _png_dynamic_put_code(
  value : UInt64, count : UInt64, tree : PngHuffman, symbol : Int,
) -> (UInt64, UInt64) {
  _png_fixed_put_bits(value, count, tree.codes[symbol].to_uint64(), tree.lengths[symbol].to_uint64())
}

///| Preview one Dynamic DEFLATE byte.  Every returned state is private until the
/// byte is acknowledged, which makes repeated `present` calls observational.
fn PngEncodeMachine::dynamic_preview_byte(
  self : PngEncodeMachine,
) -> Result[(Byte, PngDynamicState), @error.CoreError] {
  let plan = match self.plan {
    PngDeflatePlan::Dynamic(value) => value
    _ => return Err(_png_encode_machine_state_error("png-encode-dynamic-plan"))
  }
  let state = match self.dynamic_state {
    Some(value) => value
    None => return Err(_png_encode_machine_state_error("png-encode-dynamic-state"))
  }
  let mut phase = state.phase
  let mut header_cursor = state.header_cursor
  let mut code_length_cursor = state.code_length_cursor
  let mut rle_cursor = state.rle_cursor
  let mut raw_cursor = state.raw_cursor
  let mut filtered_cursor = state.filtered_cursor
  let mut bit_value = state.bit_value
  let mut bit_count = state.bit_count
  let mut adler = state.adler
  let mut matcher_work = state.matcher_work
  while bit_count < 8UL {
    if phase == 0 {
      let (value, count) = _png_fixed_put_bits(bit_value, bit_count, 5UL, 3UL)
      bit_value = value; bit_count = count; phase = 1
    } else if phase == 1 {
      let value = if header_cursor == 0UL { plan.hlit - 257UL } else if header_cursor == 1UL {
        plan.hdist - 1UL
      } else { plan.hclen - 4UL }
      let width = if header_cursor < 2UL { 5UL } else { 4UL }
      let (next_value, next_count) = _png_fixed_put_bits(bit_value, bit_count, value, width)
      bit_value = next_value; bit_count = next_count; header_cursor = header_cursor + 1UL
      if header_cursor == 3UL { phase = 2 }
    } else if phase == 2 {
      let order = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15]
      if code_length_cursor < plan.hclen {
        let length = plan.code_lengths.lengths[order[code_length_cursor.to_int()]].to_uint64()
        let (next_value, next_count) = _png_fixed_put_bits(bit_value, bit_count, length, 3UL)
        bit_value = next_value; bit_count = next_count; code_length_cursor = code_length_cursor + 1UL
      } else { phase = 3 }
    } else if phase == 3 {
      if rle_cursor < plan.rle_count {
        let symbol = plan.rle_symbols[rle_cursor.to_int()]
        let (next_value, next_count) = _png_dynamic_put_code(bit_value, bit_count, plan.code_lengths, symbol)
        bit_value = next_value; bit_count = next_count
        let width = plan.rle_extra_bits[rle_cursor.to_int()]
        if width > 0UL {
          let (extra_value, extra_count) = _png_fixed_put_bits(bit_value, bit_count, plan.rle_extras[rle_cursor.to_int()], width)
          bit_value = extra_value; bit_count = extra_count
        }
        rle_cursor = rle_cursor + 1UL
      } else { phase = 4 }
    } else if phase == 4 {
      if raw_cursor < self.scanlines {
        let (length, distance, work) = match filtered_cursor {
          Some(cursor) => {
            let (length, distance, work, next) = match _png_filtered_match_at(
              cursor, self.scanlines,
            ) { Err(error) => return Err(error); Ok(value) => value }
            filtered_cursor = Some(next)
            (length, distance, work)
          }
          None => match _png_fixed_match_at(
            self.source, self.row_bytes, self.channels, self.scanlines, raw_cursor,
          ) { Err(error) => return Err(error); Ok(value) => value }
        }
        matcher_work = match _png_fixed_add(matcher_work, work) { Err(error) => return Err(error); Ok(value) => value }
        if length >= 3UL {
          let (symbol, extra, extra_bits) = _png_fixed_length_code(length)
          let (next_value, next_count) = _png_dynamic_put_code(bit_value, bit_count, plan.literals, symbol.to_int())
          bit_value = next_value; bit_count = next_count
          if extra_bits > 0UL {
            let (extra_value, extra_count) = _png_fixed_put_bits(bit_value, bit_count, extra, extra_bits)
            bit_value = extra_value; bit_count = extra_count
          }
          let (distance_value, distance_count) = _png_dynamic_put_code(bit_value, bit_count, plan.distances, (distance - 1UL).to_int())
          bit_value = distance_value; bit_count = distance_count
          for index = 0UL; index < length; index = index + 1UL {
            let byte = match filtered_cursor {
              Some(cursor) => {
                let (value, next) = match cursor.next() {
                  Err(error) => return Err(error); Ok(value) => value
                }
                filtered_cursor = Some(next)
                value
              }
              None => match _png_fixed_scanline_byte(
                self.source, self.row_bytes, self.channels, raw_cursor + index,
              ) { Err(error) => return Err(error); Ok(value) => value }
            }
            adler = _png_adler_step(adler, byte)
          }
          raw_cursor = raw_cursor + length
        } else {
          let byte = match filtered_cursor {
            Some(cursor) => {
              let (value, next) = match cursor.next() {
                Err(error) => return Err(error); Ok(value) => value
              }
              filtered_cursor = Some(next)
              value
            }
            None => match _png_fixed_scanline_byte(
              self.source, self.row_bytes, self.channels, raw_cursor,
            ) { Err(error) => return Err(error); Ok(value) => value }
          }
          let (next_value, next_count) = _png_dynamic_put_code(bit_value, bit_count, plan.literals, byte.to_int())
          bit_value = next_value; bit_count = next_count; adler = _png_adler_step(adler, byte); raw_cursor = raw_cursor + 1UL
        }
      } else { phase = 5 }
    } else if phase == 5 {
      if matcher_work != plan.matcher_work || adler != plan.fingerprint {
        return Err(_png_encode_machine_state_error("png-encode-dynamic-replay-drift"))
      }
      let (next_value, next_count) = _png_dynamic_put_code(bit_value, bit_count, plan.literals, 256)
      bit_value = next_value; bit_count = next_count; phase = 6
    } else if phase == 6 {
      let byte = bit_value.to_byte()
      return Ok((byte, { phase: 7, header_cursor, code_length_cursor, rle_cursor, raw_cursor, filtered_cursor,
        bit_value: 0UL, bit_count: 0UL, adler, matcher_work }))
    } else {
      return Err(_png_encode_machine_state_error("png-encode-dynamic-cursor"))
    }
  }
  let byte = bit_value.to_byte()
  Ok((byte, { phase, header_cursor, code_length_cursor, rle_cursor, raw_cursor, filtered_cursor,
    bit_value: bit_value >> 8, bit_count: bit_count - 8UL, adler, matcher_work }))
}

///|
fn PngEncodeMachine::dynamic_zlib_byte(
  self : PngEncodeMachine, offset : UInt64,
) -> Result[Byte, @error.CoreError] {
  let plan = match self.plan { PngDeflatePlan::Dynamic(value) => value; _ => return Err(_png_encode_machine_state_error("png-encode-dynamic-plan")) }
  if offset == 0UL { return Ok(b'\x78') }
  if offset == 1UL { return Ok(b'\x01') }
  if offset < plan.deflate_bytes + 2UL {
    let (byte, next) = match self.dynamic_preview_byte() { Err(error) => return Err(error); Ok(value) => value }
    self.pending_dynamic = Some(next)
    return Ok(byte)
  }
  let adler_offset = offset - plan.deflate_bytes - 2UL
  if adler_offset < 4UL {
    let state = match self.dynamic_state { Some(value) => value; None => return Err(_png_encode_machine_state_error("png-encode-dynamic-state")) }
    return Ok(_png_encode_machine_u32_byte(state.adler, adler_offset))
  }
  Err(_png_encode_machine_state_error("png-encode-dynamic-cursor"))
}

///|
fn PngEncodeMachine::byte_at(
  self : PngEncodeMachine,
  offset : UInt64,
) -> Result[Byte, @error.CoreError] {
  if offset < 8UL {
    return Ok([b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'][offset.to_int()])
  }
  if offset < 12UL { return Ok(_png_encode_machine_u32_byte(13UL, offset - 8UL)) }
  if offset < 16UL { return Ok([b'I', b'H', b'D', b'R'][(offset - 12UL).to_int()]) }
  if offset < 29UL {
    let payload = offset - 16UL
    if payload < 4UL { return Ok(_png_encode_machine_u32_byte(self.width, payload)) }
    if payload < 8UL { return Ok(_png_encode_machine_u32_byte(self.height, payload - 4UL)) }
    let colour_type = match self.profile {
      PngEncodeProfile::Gray8 => b'\x00'
      PngEncodeProfile::LegacyRgbOrRgba => if self.channels == 3UL { b'\x02' } else { b'\x06' }
    }
    return Ok([b'\x08', colour_type, b'\x00', b'\x00', if self.interlace_strategy == PngInterlaceStrategy::Adam7 { b'\x01' } else { b'\x00' }][(payload - 8UL).to_int()])
  }
  if offset < 33UL { return Ok(_png_encode_machine_u32_byte(self.ihdr_crc ^ 4294967295UL, offset - 29UL)) }
  if offset < 37UL { return Ok(_png_encode_machine_u32_byte(self.idat_length, offset - 33UL)) }
  if offset < 41UL { return Ok([b'I', b'D', b'A', b'T'][(offset - 37UL).to_int()]) }
  if offset < 41UL + self.idat_length {
    return self.zlib_byte(offset - 41UL)
  }
  if offset < 45UL + self.idat_length {
    return Ok(_png_encode_machine_u32_byte(self.idat_crc ^ 4294967295UL, offset - 41UL - self.idat_length))
  }
  let iend = offset - 45UL - self.idat_length
  if iend < 4UL { return Ok(b'\x00') }
  if iend < 8UL { return Ok([b'I', b'E', b'N', b'D'][(iend - 4UL).to_int()]) }
  if iend < 12UL { return Ok(_png_encode_machine_u32_byte(_png_crc_for_type([b'I', b'E', b'N', b'D']) ^ 4294967295UL, iend - 8UL)) }
  Err(_png_encode_machine_state_error("png-encode-total-cursor"))
}

///|
fn PngEncodeMachine::present(self : PngEncodeMachine) -> Result[Byte?, @error.CoreError] {
  match self.pending {
    Some(byte) => Ok(Some(byte))
    None => {
      if self.finished { return Ok(None) }
      if self.emitted == self.total_length_value {
        self.finished = true
        return Ok(None)
      }
      let byte = match self.byte_at(self.emitted) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      self.pending = Some(byte)
      Ok(Some(byte))
    }
  }
}

///|
fn PngEncodeMachine::acknowledge(
  self : PngEncodeMachine,
  accepted : Byte,
) -> Result[Unit, @error.CoreError] {
  let pending = match self.pending {
    None => return Err(_png_encode_machine_state_error("png-encode-no-pending-byte"))
    Some(value) => value
  }
  if pending != accepted {
    return Err(_png_encode_machine_state_error("png-encode-acknowledgement"))
  }
  let offset = self.emitted
  if offset >= 16UL && offset < 29UL {
    self.ihdr_crc = _png_crc_step(self.ihdr_crc, accepted)
  }
  if offset >= 41UL && offset < 41UL + self.idat_length {
    self.idat_crc = _png_crc_step(self.idat_crc, accepted)
    let zlib_offset = offset - 41UL
    match self.plan {
      PngDeflatePlan::Stored(_) => {
        let stored_end = self.idat_length - 4UL
        if zlib_offset >= 2UL && zlib_offset < stored_end && (zlib_offset - 2UL) % 65540UL >= 5UL {
          self.adler = _png_adler_step(self.adler, accepted)
          match self.pending_stored {
            Some(next) => self.stored_cursor = Some(next)
            None => ()
          }
        }
      }
      PngDeflatePlan::Fixed(_) => match self.pending_fixed {
        Some(next) => {
          self.adler = next.adler
          self.fixed_state = Some(next)
        }
        None => ()
      }
      PngDeflatePlan::Dynamic(_) => match self.pending_dynamic {
        Some(next) => {
          self.adler = next.adler
          self.dynamic_state = Some(next)
        }
        None => ()
      }
    }
  }
  self.pending = None
  self.pending_stored = None
  self.pending_fixed = None
  self.pending_dynamic = None
  self.emitted = self.emitted + 1UL
  if self.emitted == self.total_length_value { self.finished = true }
  Ok(())
}
