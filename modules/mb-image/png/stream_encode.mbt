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
  let machine = match PngEncodeMachine::new(source, limits, budget, diagnostics) {
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
/// Private, owned PNG output state. It retains the immutable source and scalar
/// cursors only: no destination lease and no output-sized staging buffer.
priv struct PngEncodeMachine {
  source : @storage.ImageView
  width : UInt64
  height : UInt64
  channels : UInt64
  row_bytes : UInt64
  scanlines : UInt64
  blocks : UInt64
  idat_length : UInt64
  total_length_value : UInt64
  disposition : @metadata.MetadataDisposition
  mut emitted : UInt64
  mut pending : Byte?
  mut ihdr_crc : UInt64
  mut idat_crc : UInt64
  mut adler : UInt64
  mut finished : Bool
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
  let facts = match _png_encode_preflight(source, limits, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    source,
    width: source.width(),
    height: source.height(),
    channels: facts.channels,
    row_bytes: facts.row_bytes,
    scanlines: facts.scanlines,
    blocks: facts.blocks,
    idat_length: facts.idat_length,
    total_length_value: facts.total_length,
    disposition: facts.disposition,
    emitted: 0UL,
    pending: None,
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
    let stored_end = self.idat_length - 4UL
    if zlib_offset >= 2UL && zlib_offset < stored_end && (zlib_offset - 2UL) % 65540UL >= 5UL {
      self.adler = _png_adler_step(self.adler, accepted)
    }
  }
  self.pending = None
  self.emitted = self.emitted + 1UL
  if self.emitted == self.total_length_value { self.finished = true }
  Ok(())
}
