///|
/// The byte boundary owned by the private PNG decoder.  This deliberately
/// contains no `ByteView`: callers may release or mutate their source as soon
/// as `accept` returns.
priv enum PngDecodeMachineState {
  Signature(Int)
  Length(Array[Byte])
  Type(UInt64, Array[Byte])
  Payload(UInt64, Array[Byte], UInt64)
  Crc(Array[Byte], UInt64)
  Failed(@error.CoreError)
}

///|
/// Owned continuation for one IDAT chunk.  Header fields, payload accounting,
/// and the four CRC bytes are copied here one byte at a time; no source lease
/// or complete IDAT payload is retained.
priv struct PngIdatState {
  type_bytes : Array[Byte]
  length_bytes : Array[Byte]
  crc_bytes : Array[Byte]
  mut remaining : UInt64
  mut crc : UInt64
  mut header_ready : Bool
  mut complete : Bool
}

///|
fn PngIdatState::new() -> PngIdatState {
  { type_bytes: [], length_bytes: [], crc_bytes: [], remaining: 0UL, crc: 0UL, header_ready: false, complete: false }
}

///|
fn PngIdatState::accept_type_byte(self : PngIdatState, byte : Byte) -> Result[Unit, @error.CoreError] {
  if self.header_ready || self.type_bytes.length() == 4 { return Err(_png_error("png-idat-state")) }
  self.type_bytes.push(byte)
  if self.type_bytes.length() == 4 {
    if !_png_type_is(self.type_bytes, b'I', b'D', b'A', b'T') { return Err(_png_error("png-idat-order")) }
    self.crc = _png_crc_for_type(self.type_bytes)
    if self.length_bytes.length() == 4 {
      self.remaining = (self.length_bytes[0].to_int().to_uint64() << 24) | (self.length_bytes[1].to_int().to_uint64() << 16) | (self.length_bytes[2].to_int().to_uint64() << 8) | self.length_bytes[3].to_int().to_uint64()
      self.header_ready = true
    }
  }
  Ok(())
}

///|
fn PngIdatState::accept_length_byte(self : PngIdatState, byte : Byte) -> Result[Unit, @error.CoreError] {
  if self.header_ready || self.length_bytes.length() == 4 { return Err(_png_error("png-idat-state")) }
  self.length_bytes.push(byte)
  if self.length_bytes.length() == 4 && self.type_bytes.length() == 4 {
    self.remaining = (self.length_bytes[0].to_int().to_uint64() << 24) | (self.length_bytes[1].to_int().to_uint64() << 16) | (self.length_bytes[2].to_int().to_uint64() << 8) | self.length_bytes[3].to_int().to_uint64()
    self.header_ready = true
  }
  Ok(())
}

///|
fn PngIdatState::accept_payload_byte(self : PngIdatState, byte : Byte) -> Result[Unit, @error.CoreError] {
  if !self.header_ready || self.remaining == 0UL { return Err(_png_error("png-idat-state")) }
  self.crc = _png_crc_step(self.crc, byte)
  self.remaining = self.remaining - 1UL
  Ok(())
}

///|
fn PngIdatState::remaining_bytes(self : PngIdatState) -> UInt64 { self.remaining }

///|
fn PngIdatState::awaiting_crc(self : PngIdatState) -> Bool { self.header_ready && self.remaining == 0UL && !self.complete }

///|
fn PngIdatState::expected_crc(self : PngIdatState) -> UInt64 { self.crc ^ 4294967295UL }

///|
fn PngIdatState::accept_crc_byte(self : PngIdatState, byte : Byte) -> Result[Unit, @error.CoreError] {
  if !self.awaiting_crc() || self.crc_bytes.length() == 4 { return Err(_png_error("png-idat-state")) }
  self.crc_bytes.push(byte)
  if self.crc_bytes.length() == 4 {
    let stored = (self.crc_bytes[0].to_int().to_uint64() << 24) | (self.crc_bytes[1].to_int().to_uint64() << 16) | (self.crc_bytes[2].to_int().to_uint64() << 8) | self.crc_bytes[3].to_int().to_uint64()
    if stored != self.expected_crc() { return Err(_png_error("png-crc")) }
    self.complete = true
  }
  Ok(())
}

///|
fn PngIdatState::chunk_complete(self : PngIdatState) -> Bool { self.complete }

///|
fn _png_new_idat_state(
  length : UInt64,
  kind : Array[Byte],
) -> Result[PngIdatState, @error.CoreError] {
  let state = PngIdatState::new()
  for shift in [24, 16, 8, 0] {
    match state.accept_length_byte((length >> shift).to_byte()) { Err(error) => return Err(error); Ok(_) => () }
  }
  for byte in kind {
    match state.accept_type_byte(byte) { Err(error) => return Err(error); Ok(_) => () }
  }
  Ok(state)
}

///|
/// Private continuation substrate for the PNG decoder.  Phase 26 keeps this
/// type package-private; the public eager facade remains `PngDecoder`.
priv struct PngDecodeMachine {
  options : @codec.DecodeOptions
  limits : @codec.CodecLimits
  budget : @budget.Budget
  mut state : PngDecodeMachineState
  mut accepted : UInt64
  mut last_chunk_complete : Bool
}

///|
fn PngDecodeMachine::new(
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> PngDecodeMachine {
  { options, limits, budget, state: PngDecodeMachineState::Signature(0), accepted: 0UL, last_chunk_complete: false }
}

///|
fn PngDecodeMachine::accepted_bytes(self : PngDecodeMachine) -> UInt64 {
  self.accepted
}

///|
fn PngDecodeMachine::has_result(_self : PngDecodeMachine) -> Bool {
  // An image/result is intentionally not constructed by the framing substrate.
  // The completed machine transfers it only after IDAT, IEND, and EOF checks.
  false
}

///|
fn PngDecodeMachine::framing_chunk_complete(self : PngDecodeMachine) -> Bool {
  self.last_chunk_complete
}

///|
fn PngDecodeMachine::accept(
  self : PngDecodeMachine,
  byte : Byte,
) -> Result[Unit, @error.CoreError] {
  let next = match @checked.checked_add(self.accepted, 1UL) {
    Ok(value) => value
    Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
  }
  if next > self.limits.max_input_bytes() {
    let error = _png_limit("input-bytes", next, self.limits.max_input_bytes())
    self.state = PngDecodeMachineState::Failed(error)
    return Err(error)
  }
  match self.state {
    PngDecodeMachineState::Signature(index) => {
      let signature = [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n']
      if byte != signature[index] {
        let error = _png_error("png-signature")
        self.state = PngDecodeMachineState::Failed(error)
        return Err(error)
      }
      self.state = if index + 1 == signature.length() { PngDecodeMachineState::Length([]) } else { PngDecodeMachineState::Signature(index + 1) }
    }
    PngDecodeMachineState::Length(bytes) => {
      bytes.push(byte)
      self.last_chunk_complete = false
      if bytes.length() == 4 {
        let length = (bytes[0].to_int().to_uint64() << 24) | (bytes[1].to_int().to_uint64() << 16) | (bytes[2].to_int().to_uint64() << 8) | bytes[3].to_int().to_uint64()
        if length > 2147483647UL {
          let error = _png_error("png-chunk-length")
          self.state = PngDecodeMachineState::Failed(error)
          return Err(error)
        }
        self.state = PngDecodeMachineState::Type(length, [])
      }
    }
    PngDecodeMachineState::Type(length, kind) => {
      kind.push(byte)
      if kind.length() == 4 {
        match _png_validate_type_form(kind) {
          Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
          Ok(_) => ()
        }
        if _png_type_is(kind, b'I', b'E', b'N', b'D') && length != 0UL {
          let error = _png_error("png-iend-length")
          self.state = PngDecodeMachineState::Failed(error)
          return Err(error)
        }
        let crc = _png_crc_for_type(kind)
        self.state = if length == 0UL { PngDecodeMachineState::Crc([], crc) } else { PngDecodeMachineState::Payload(length, kind, crc) }
      }
    }
    PngDecodeMachineState::Payload(remaining, kind, crc) => {
      let next_crc = _png_crc_step(crc, byte)
      if remaining == 1UL { self.state = PngDecodeMachineState::Crc([], next_crc) } else { self.state = PngDecodeMachineState::Payload(remaining - 1UL, kind, next_crc) }
    }
    PngDecodeMachineState::Crc(bytes, crc) => {
      bytes.push(byte)
      if bytes.length() == 4 {
        let stored = (bytes[0].to_int().to_uint64() << 24) | (bytes[1].to_int().to_uint64() << 16) | (bytes[2].to_int().to_uint64() << 8) | bytes[3].to_int().to_uint64()
        if stored != (crc ^ 4294967295UL) {
          let error = _png_error("png-crc")
          self.state = PngDecodeMachineState::Failed(error)
          return Err(error)
        }
        self.last_chunk_complete = true
        self.state = PngDecodeMachineState::Length([])
      }
    }
    PngDecodeMachineState::Failed(error) => return Err(error)
  }
  self.accepted = next
  Ok(())
}

///|
/// Drive the existing eager Reader contract through the machine-owned decode
/// configuration.  The public facade delegates here so its options, limits,
/// budget, diagnostics boundary, and final-result visibility have one owner.
fn PngDecodeMachine::decode_reader(
  self : PngDecodeMachine,
  reader : &@io.Reader,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let stream = match _png_read_stream_transport(reader, self.options, self.limits, self.budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let transport = PngTransport::{ width: stream.width, height: stream.height, bit_depth: stream.bit_depth, source_channels: stream.source_channels, source_bytes_per_pixel: stream.source_bytes_per_pixel, channels: stream.channels, indexed: stream.indexed, palette: stream.palette, palette_entries: stream.palette_entries, transparency: stream.transparency, idat: b"", consumed: 0UL }
  let metadata = match stream.colour_declaration {
    PngColourDeclaration::Srgb(intent) => match stream.metadata_budget { Some(metadata_budget) => match _png_srgb_metadata(stream.channels, intent, metadata_budget) { Err(error) => return Err(error); Ok(value) => value }; None => return Err(_png_error("png-srgb-budget")) }
    PngColourDeclaration::Legacy(gamma, chrm) => match stream.metadata_budget { Some(metadata_budget) => match _png_legacy_metadata(stream.channels, gamma, chrm, metadata_budget) { Err(error) => return Err(error); Ok(value) => value }; None => return Err(_png_error("png-legacy-budget")) }
    PngColourDeclaration::Icc(name, profile) => match stream.metadata_budget { Some(metadata_budget) => match _png_iccp_metadata(stream.channels, name, profile, metadata_budget) { Err(error) => return Err(error); Ok(value) => value }; None => return Err(_png_error("png-iccp-budget")) }
    PngColourDeclaration::Default => match _png_empty_metadata(stream.channels) { Err(error) => return Err(error); Ok(value) => value }
  }
  let descriptor = match _png_descriptor_with_metadata(transport, metadata) { Err(error) => return Err(error); Ok(value) => value }
  let index_rows = if stream.indexed && !stream.interlaced {
    let row_bytes = match _png_grayscale_row_bytes(stream.width, stream.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
    match _png_new_packed_rows(row_bytes, stream.budget) { Err(error) => return Err(error); Ok(value) => Some(value) }
  } else { None }
  let packed_rows = if ((stream.source_channels == 1UL || stream.source_channels == 2UL || stream.bit_depth == 16) && !stream.indexed) || stream.interlaced {
    let row_bytes = if stream.interlaced {
      let passes = match _png_adam7_passes(stream.width, stream.height, stream.source_channels, stream.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
      let mut maximum = 0UL
      for pass in passes { if pass.row_bytes > maximum { maximum = pass.row_bytes } }
      maximum
    } else { match _png_source_row_bytes(stream.width, stream.source_channels, stream.bit_depth) { Err(error) => return Err(error); Ok(value) => value } }
    match _png_new_packed_rows(row_bytes, stream.budget) { Err(error) => return Err(error); Ok(value) => Some(value) }
  } else { None }
  let image = match @storage.OwnedImage::new_operation(descriptor, stream.budget, PngBuiltinAllocator::{} as &@bytes.Allocator, self.limits.max_work()) { Err(error) => return Err(error); Ok(value) => value }
  let consumed = match image.with_mut_view(fn(view) { _png_inflate_zlib_to_raster(stream.source, self.limits.max_output_bytes(), view, stream, index_rows, packed_rows) }) { Err(error) => return Err(error); Ok(value) => value }
  let disposition = match _png_empty_disposition() { Err(error) => return Err(error); Ok(value) => value }
  Ok(@codec.DecodeResult::new(image, disposition, consumed))
}
