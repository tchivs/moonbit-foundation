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
  let machine = match PngEncodeMachine::new(
    source, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}

///|
/// Constructs a caller-buffered encoder with an explicit PNG compression strategy.
/// `Stored` and `FixedOrStored` retain frozen compatibility output. `DynamicOrFixedOrStored`
/// may choose Dynamic only for a strict complete-PNG win over unchanged FixedOrStored and
/// retains FixedOrStored on a tie. It excludes adaptive filtering, matching beyond distance
/// four, 32 KiB history, image-sized staging, length-limited optimization, FFI, host
/// streaming, APNG, colour, and metadata expansion; the legacy constructor remains Stored.
pub fn PngChunkEncoder::new_with_compression_strategy(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_compression_strategy(
    source, strategy, limits, budget, diagnostics,
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
/// Private, owned PNG output state. Stored keeps its frozen byte path; configured
/// FixedOrStored and compatibility-phase DynamicOrFixedOrStored use scalar fixed-Huffman
/// replay with no dynamic tree, adaptive filter, 32 KiB dictionary, FFI codec, host
/// adapter, caller lease, or output-sized staging.
priv struct PngEncodeMachine {
  source : @storage.ImageView
  strategy : PngCompressionStrategy
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
  mut pending_fixed : PngFixedState?
  mut fixed_state : PngFixedState?
  mut ihdr_crc : UInt64
  mut idat_crc : UInt64
  mut adler : UInt64
  mut finished : Bool
}

///| All fixed emission state is scalar and advances only when the byte preview
/// that carried it is acknowledged by the eager Writer or caller lease.
priv struct PngFixedState {
  raw_cursor : UInt64
  bit_value : UInt64
  bit_count : UInt64
  adler : UInt64
  matcher_work : UInt64
  header_written : Bool
  eob_written : Bool
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
  PngEncodeMachine::new_with_compression_strategy(
    source, PngCompressionStrategy::Stored, limits, budget, _diagnostics,
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
  let facts = match _png_encode_preflight(source, strategy, limits, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    source,
    strategy,
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
    pending_fixed: None,
    fixed_state: match facts.plan {
      PngDeflatePlan::Stored(_) => None
      PngDeflatePlan::Fixed(_) => Some({
        raw_cursor: 0UL, bit_value: 0UL, bit_count: 0UL, adler: 1UL,
        matcher_work: 0UL, header_written: false, eob_written: false,
      })
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
  let row_width = self.row_bytes + 1UL
  let in_row = index % row_width
  if in_row == 0UL {
    Ok(b'\x00')
  } else {
    let sample = in_row - 1UL
    self.source.get_byte(sample / self.channels, index / row_width, sample % self.channels)
  }
}

///|
fn PngEncodeMachine::zlib_byte(
  self : PngEncodeMachine,
  offset : UInt64,
) -> Result[Byte, @error.CoreError] {
  match self.plan {
    PngDeflatePlan::Fixed(_) => return self.fixed_zlib_byte(offset)
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
    self.scanline_byte(block_index * 65535UL + in_block - 5UL)
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
  let mut bit_value = state.bit_value
  let mut bit_count = state.bit_count
  let mut adler = state.adler
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
      let (length, distance, work) = match _png_fixed_match_at(
        self.source, self.row_bytes, self.channels, self.scanlines, raw_cursor,
      ) {
        Err(error) => return Err(error)
        Ok(value) => value
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
          let byte = match _png_fixed_scanline_byte(
            self.source, self.row_bytes, self.channels, raw_cursor + index,
          ) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
          adler = _png_adler_step(adler, byte)
          index = index + 1UL
        }
        raw_cursor = raw_cursor + length
      } else {
        let byte = match _png_fixed_scanline_byte(
          self.source, self.row_bytes, self.channels, raw_cursor,
        ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let (code, code_bits) = _png_fixed_literal_code(byte.to_uint64())
        let (next_value, next_count) = _png_fixed_put_bits(
          bit_value, bit_count, code, code_bits,
        )
        bit_value = next_value
        bit_count = next_count
        adler = _png_adler_step(adler, byte)
        raw_cursor = raw_cursor + 1UL
      }
    } else if !eob_written {
      if matcher_work != plan.matcher_work {
        return Err(_png_encode_machine_state_error("png-encode-fixed-replay-work"))
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
        raw_cursor, bit_value: 0UL, bit_count: 0UL, adler, matcher_work, eob_written,
        header_written,
      }))
    }
  }
  let byte = bit_value.to_byte()
  Ok((byte, {
    raw_cursor, bit_value: bit_value >> 8, bit_count: bit_count - 8UL,
    adler, matcher_work, header_written, eob_written,
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
    return Ok([b'\x08', if self.channels == 3UL { b'\x02' } else { b'\x06' }, b'\x00', b'\x00', b'\x00'][(payload - 8UL).to_int()])
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
        }
      }
      PngDeflatePlan::Fixed(_) => match self.pending_fixed {
        Some(next) => {
          self.adler = next.adler
          self.fixed_state = Some(next)
        }
        None => ()
      }
    }
  }
  self.pending = None
  self.pending_fixed = None
  self.emitted = self.emitted + 1UL
  if self.emitted == self.total_length_value { self.finished = true }
  Ok(())
}
