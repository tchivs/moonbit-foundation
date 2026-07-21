///|
/// The byte boundary owned by the private PNG decoder.  This deliberately
/// contains no `ByteView`: callers may release or mutate their source as soon
/// as `accept` returns.
priv enum PngDecodeMachineState {
  Signature(Int)
  Length(Array[Byte])
  Type(UInt64, Array[Byte])
  Payload(UInt64, Array[Byte], Array[Byte], UInt64)
  Crc(Array[Byte], Array[Byte], Array[Byte], UInt64)
  NeedEof
  Completed
  Failed(@error.CoreError)
}

///|
/// A fully owned, private output lifecycle.  The sink owns the only image
/// allocation made by the byte-fed machine; it is not exposed while the
/// framing state remains resumable or failed.
priv struct PngMachineLifecycle {
  sink : PngRasterSink
}

///|
/// The private byte-fed counterpart of a public decode result.  It comes into
/// existence only after the complete zlib stream, filtered raster, IEND CRC,
/// and explicit EOF transition have all succeeded.  Phase 26 deliberately
/// keeps it private while the eager facade remains on its proven transport.
priv struct PngMachineOutcome {
  image : @storage.OwnedImage
  disposition : @metadata.MetadataDisposition
  bytes_read : UInt64
}

///| Facts which are both bounded and semantically necessary before the first
/// IDAT header.  Payload bytes stay owned by the machine and become facts only
/// after their chunk CRC has authenticated them.
priv struct PngPreIdatFacts {
  mut palette : Array[Byte]
  mut palette_entries : UInt64
  mut saw_palette : Bool
  mut transparency : PngTransparency
  mut saw_transparency : Bool
  mut colour_facts : PngColourFacts
}

///|
fn _png_new_pre_idat_facts() -> PngPreIdatFacts {
  {
    palette: [],
    palette_entries: 0UL,
    saw_palette: false,
    transparency: PngTransparency::Opaque,
    saw_transparency: false,
    colour_facts: _png_new_colour_facts(),
  }
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
  mut ihdr : Array[Byte]?
  facts : PngPreIdatFacts
  mut saw_idat : Bool
  mut left_idat_sequence : Bool
  mut idat : PngIdatState?
  mut inflate : PngInflateState?
  mut lifecycle : PngMachineLifecycle?
  mut lifecycle_allocations : UInt64
  mut outcome : PngMachineOutcome?
}

///|
/// Reader facade used only by the eager bridge.  The wrapped reader remains
/// the sole source of bytes; this adapter observes each successful transition
/// exactly once after the provider has filled the destination window.
priv struct PngMachineReader {
  reader : &@io.Reader
  machine : PngDecodeMachine
}

///|
fn _png_reader_invalid_progress(
  progress : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation="png-machine-reader",
    requested=progress,
    completed=0UL,
    limit~,
  )
}

///|
impl @io.Reader for PngMachineReader with fn read(self, destination) {
  match self.reader.read(destination) {
    @io.ReadOutcome::Progress(count) => {
      let limit = destination.length()
      if count > limit {
        return @io.ReadOutcome::Failed(_png_reader_invalid_progress(count, limit), 0UL)
      }
      for index = 0UL; index < count; index = index + 1UL {
        // Existing synchronous validators retain their established typed-error
        // precedence. The machine records the same byte transition privately.
        ignore(self.machine.accept(destination.get(index).unwrap()))
      }
      @io.ReadOutcome::Progress(count)
    }
    @io.ReadOutcome::EndOfStream => @io.ReadOutcome::EndOfStream
    @io.ReadOutcome::Failed(error, completed) => {
      if completed > destination.length() {
        // Keep the provider's error identity but suppress its malformed
        // completion claim: no byte outside this window may be observed.
        return @io.ReadOutcome::Failed(error, 0UL)
      }
      // A failing Reader may already have filled a prefix of the destination.
      // Keep that source-of-truth accounting visible to the machine before
      // forwarding the original failure unchanged to the eager decoder.
      for index = 0UL; index < completed; index = index + 1UL {
        ignore(self.machine.accept(destination.get(index).unwrap()))
      }
      @io.ReadOutcome::Failed(error, completed)
    }
  }
}

///|
fn PngDecodeMachine::new(
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> PngDecodeMachine {
  { options, limits, budget, state: PngDecodeMachineState::Signature(0), accepted: 0UL, last_chunk_complete: false, ihdr: None, facts: _png_new_pre_idat_facts(), saw_idat: false, left_idat_sequence: false, idat: None, inflate: None, lifecycle: None, lifecycle_allocations: 0UL, outcome: None }
}

///|
fn PngDecodeMachine::accepted_bytes(self : PngDecodeMachine) -> UInt64 {
  self.accepted
}

///|
fn PngDecodeMachine::has_result(_self : PngDecodeMachine) -> Bool {
  // The public facade remains independent in Phase 26.
  false
}

///| Test-only outcome visibility.  This is intentionally distinct from the
/// public result: no caller can observe the image until terminal framing and
/// EOF have completed.
fn PngDecodeMachine::has_private_outcome(self : PngDecodeMachine) -> Bool {
  self.outcome is Some(_)
}

///| Test-only inspection of the private terminal descriptor.  Keeping this
/// accessor package-private proves metadata and output channel selection
/// without making the resumable substrate a public decoder yet.
fn PngDecodeMachine::private_outcome_descriptor(self : PngDecodeMachine) -> @model.ImageDescriptor? {
  match self.outcome {
    Some(value) => Some(value.image.descriptor())
    None => None
  }
}

///|
/// Test-only observable lifecycle facts.  Neither accessor exposes the image
/// or a result; they prove allocation is private and happens exactly once.
fn PngDecodeMachine::has_private_lifecycle(self : PngDecodeMachine) -> Bool {
  self.lifecycle is Some(_)
}

///|
fn PngDecodeMachine::private_lifecycle_allocations(self : PngDecodeMachine) -> UInt64 {
  self.lifecycle_allocations
}

///| Test-only facts accessors.  The machine never exposes caller-owned bytes
/// or a decode result while the terminal PNG checks remain outstanding.
fn PngDecodeMachine::has_private_palette(self : PngDecodeMachine) -> Bool {
  self.facts.saw_palette
}

///|
fn PngDecodeMachine::has_private_transparency(self : PngDecodeMachine) -> Bool {
  self.facts.saw_transparency
}

///|
fn PngDecodeMachine::has_private_colour_declaration(self : PngDecodeMachine) -> Bool {
  self.facts.colour_facts.saw_srgb || self.facts.colour_facts.saw_gamma ||
  self.facts.colour_facts.saw_chrm || self.facts.colour_facts.saw_iccp
}

///| Only the bounded chunks whose facts influence the eventual raster are
/// copied over pauses. Unknown ancillary payloads are CRC-checked and then
/// discarded byte by byte.
fn _png_machine_retains_payload(kind : Array[Byte]) -> Bool {
  _png_type_is(kind, b'I', b'H', b'D', b'R') ||
  _png_type_is(kind, b'P', b'L', b'T', b'E') ||
  _png_type_is(kind, b't', b'R', b'N', b'S') ||
  _png_is_recognised_colour(kind)
}

///| Reject a malformed retained declaration before collecting an unbounded
/// payload. iCCP has its own explicit 64KiB compressed envelope.
fn PngDecodeMachine::validate_retained_header(
  self : PngDecodeMachine,
  length : UInt64,
  kind : Array[Byte],
) -> Result[Unit, @error.CoreError] {
  if _png_type_is(kind, b'I', b'H', b'D', b'R') {
    if self.ihdr is Some(_) { return Err(_png_error("png-ihdr-order")) }
    if length != 13UL { return Err(_png_error("png-ihdr-length")) }
  } else if _png_type_is(kind, b'P', b'L', b'T', b'E') {
    if self.ihdr is None || self.facts.saw_palette { return Err(_png_error("png-plte-order")) }
    if self.saw_idat { return Err(_png_error("png-semantic-chunk")) }
    match self.ihdr {
      Some(ihdr) => if ihdr[9] != b'\x03' { return Err(_png_error("png-semantic-chunk")) }
      None => ()
    }
    if length < 3UL || length > 768UL || length % 3UL != 0UL { return Err(_png_error("png-plte-length")) }
  } else if _png_type_is(kind, b't', b'R', b'N', b'S') {
    if self.ihdr is None || self.saw_idat || self.facts.saw_transparency { return Err(_png_error("png-trns-order")) }
    if length > 256UL { return Err(_png_error("png-trns-length")) }
  } else if _png_is_recognised_colour(kind) {
    if self.ihdr is None || self.saw_idat || self.facts.saw_palette { return Err(_png_error("png-colour-order")) }
    match _png_fixed_colour_length(kind) {
      Some(expected) => if length != expected {
        if _png_type_is(kind, b's', b'R', b'G', b'B') { return Err(_png_error("png-srgb-length")) }
        if _png_type_is(kind, b'g', b'A', b'M', b'A') { return Err(_png_error("png-gama-length")) }
        return Err(_png_error("png-chrm-length"))
      }
      None => if length > 65536UL { return Err(_png_limit("png-iccp-compressed", length, 65536UL)) }
    }
  }
  Ok(())
}

///| A data-backed iCCP source never calls this reader. Keeping the placeholder
/// private makes the synchronous post-payload profile validation independent
/// of the caller's chunk slice.
priv struct PngNoInputReader {}

///|
impl @io.Reader for PngNoInputReader with fn read(_self, _destination) {
  @io.ReadOutcome::EndOfStream
}

///| iCCP is collected only inside its capped pre-IDAT continuation. Once its
/// CRC is accepted, inflate and validate it before any IDAT allocation.
fn _png_machine_inflate_iccp(
  payload : Array[Byte],
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[Bytes, @error.CoreError] {
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let reader = PngNoInputReader::{}
  _png_inflate_iccp(Bytes::from_array(payload), reader as &@io.Reader, scratch, limits, budget)
}

///| Commit one CRC-authenticated pre-IDAT payload.  All cases here operate on
/// bounded, machine-owned arrays; malformed metadata cannot influence the
/// first-IDAT lifecycle before its own CRC has passed.
fn PngDecodeMachine::apply_pre_idat_chunk(
  self : PngDecodeMachine,
  kind : Array[Byte],
  payload : Array[Byte],
) -> Result[Unit, @error.CoreError] {
  let ihdr = match self.ihdr { Some(value) => value; None => [] }
  if _png_type_is(kind, b'I', b'H', b'D', b'R') {
    match _png_preflight_ihdr(payload, self.limits, self.budget) {
      Err(error) => return Err(error)
      Ok(_) => { self.ihdr = Some(payload); return Ok(()) }
    }
  }
  if _png_type_is(kind, b'P', b'L', b'T', b'E') {
    if ihdr.length() != 13 || ihdr[9] != b'\x03' { return Err(_png_error("png-semantic-chunk")) }
    let maximum = if ihdr[8] == b'\x01' { 2UL } else if ihdr[8] == b'\x02' { 4UL } else if ihdr[8] == b'\x04' { 16UL } else { 256UL }
    if payload.length().to_uint64() / 3UL > maximum { return Err(_png_error("png-plte-length")) }
    self.facts.palette = payload
    self.facts.palette_entries = self.facts.palette.length().to_uint64() / 3UL
    self.facts.saw_palette = true
    return Ok(())
  }
  if _png_type_is(kind, b't', b'R', b'N', b'S') {
    if ihdr.length() != 13 { return Err(_png_error("png-trns-order")) }
    if ihdr[9] == 0 {
      if payload.length() != 2 { return Err(_png_error("png-trns-length")) }
      if ihdr[8] == b'\x10' { self.facts.transparency = PngTransparency::Grayscale16(payload[0], payload[1]) }
      else {
        if payload[0] != b'\x00' { return Err(_png_error("png-trns-sample")) }
        let mask = if ihdr[8] == b'\x01' { 1 } else if ihdr[8] == b'\x02' { 3 } else if ihdr[8] == b'\x04' { 15 } else { 255 }
        if payload[1].to_int() > mask { return Err(_png_error("png-trns-sample")) }
        self.facts.transparency = PngTransparency::Grayscale(payload[1])
      }
    } else if ihdr[9] == 2 {
      if payload.length() != 6 { return Err(_png_error("png-trns-length")) }
      if ihdr[8] == b'\x10' { self.facts.transparency = PngTransparency::Rgb16(payload[0], payload[1], payload[2], payload[3], payload[4], payload[5]) }
      else {
        if payload[0] != b'\x00' || payload[2] != b'\x00' || payload[4] != b'\x00' { return Err(_png_error("png-trns-sample")) }
        self.facts.transparency = PngTransparency::Rgb(payload[1], payload[3], payload[5])
      }
    } else if ihdr[9] == 3 {
      if !self.facts.saw_palette { return Err(_png_error("png-trns-order")) }
      if payload.length().to_uint64() > self.facts.palette_entries { return Err(_png_error("png-trns-length")) }
      self.facts.transparency = PngTransparency::Indexed(Bytes::from_array(payload))
    } else { return Err(_png_error("png-semantic-chunk")) }
    self.facts.saw_transparency = true
    return Ok(())
  }
  if _png_type_is(kind, b's', b'R', b'G', b'B') {
    if self.facts.colour_facts.saw_srgb { return Err(_png_error("png-srgb-duplicate")) }
    let intent = match _png_validate_srgb_payload(payload) { Err(error) => return Err(error); Ok(value) => value }
    self.facts.colour_facts = { saw_srgb: true, srgb_intent: Some(intent), saw_gamma: self.facts.colour_facts.saw_gamma, gamma_is_srgb: self.facts.colour_facts.gamma_is_srgb, gamma: self.facts.colour_facts.gamma, saw_chrm: self.facts.colour_facts.saw_chrm, chrm_is_srgb: self.facts.colour_facts.chrm_is_srgb, chrm: self.facts.colour_facts.chrm, saw_iccp: self.facts.colour_facts.saw_iccp, iccp_name: self.facts.colour_facts.iccp_name, iccp_profile: self.facts.colour_facts.iccp_profile }
    return Ok(())
  }
  if _png_type_is(kind, b'g', b'A', b'M', b'A') {
    if self.facts.colour_facts.saw_gamma { return Err(_png_error("png-gama-duplicate")) }
    let standard = match _png_validate_gamma_payload(payload) { Err(error) => return Err(error); Ok(value) => value }
    self.facts.colour_facts = { saw_srgb: self.facts.colour_facts.saw_srgb, srgb_intent: self.facts.colour_facts.srgb_intent, saw_gamma: true, gamma_is_srgb: standard, gamma: Some(Bytes::from_array(payload)), saw_chrm: self.facts.colour_facts.saw_chrm, chrm_is_srgb: self.facts.colour_facts.chrm_is_srgb, chrm: self.facts.colour_facts.chrm, saw_iccp: self.facts.colour_facts.saw_iccp, iccp_name: self.facts.colour_facts.iccp_name, iccp_profile: self.facts.colour_facts.iccp_profile }
    return Ok(())
  }
  if _png_type_is(kind, b'c', b'H', b'R', b'M') {
    if self.facts.colour_facts.saw_chrm { return Err(_png_error("png-chrm-duplicate")) }
    let standard = match _png_validate_chrm_payload(payload) { Err(error) => return Err(error); Ok(value) => value }
    self.facts.colour_facts = { saw_srgb: self.facts.colour_facts.saw_srgb, srgb_intent: self.facts.colour_facts.srgb_intent, saw_gamma: self.facts.colour_facts.saw_gamma, gamma_is_srgb: self.facts.colour_facts.gamma_is_srgb, gamma: self.facts.colour_facts.gamma, saw_chrm: true, chrm_is_srgb: standard, chrm: Some(Bytes::from_array(payload)), saw_iccp: self.facts.colour_facts.saw_iccp, iccp_name: self.facts.colour_facts.iccp_name, iccp_profile: self.facts.colour_facts.iccp_profile }
    return Ok(())
  }
  if _png_type_is(kind, b'i', b'C', b'C', b'P') {
    if self.facts.colour_facts.saw_iccp { return Err(_png_error("png-iccp-duplicate")) }
    let mut index = 0
    let name : Array[Byte] = []
    let mut last_space = false
    while index < payload.length() && payload[index] != b'\x00' {
      let byte = payload[index]
      if !_png_is_iccp_name_byte(byte) || index >= 79 || (index == 0 && byte == b' ') || (byte == b' ' && last_space) { return Err(_png_error("png-iccp-name")) }
      name.push(byte)
      last_space = byte == b' '
      index = index + 1
    }
    if index == payload.length() { return Err(_png_error("png-iccp-envelope")) }
    if index == 0 || last_space { return Err(_png_error("png-iccp-name")) }
    if index + 1 >= payload.length() { return Err(_png_error("png-iccp-envelope")) }
    if payload[index + 1] != b'\x00' { return Err(_png_error("png-iccp-method")) }
    let compressed : Array[Byte] = []
    for cursor = index + 2; cursor < payload.length(); cursor = cursor + 1 { compressed.push(payload[cursor]) }
    if compressed.length() == 0 { return Err(_png_error("png-iccp-data")) }
    let temporary = match _png_iccp_temporary_budget(compressed.length().to_uint64(), self.limits, self.budget) { Err(error) => return Err(error); Ok(value) => value }
    let profile = match _png_machine_inflate_iccp(compressed, self.limits, temporary) { Err(error) => return Err(error); Ok(value) => value }
    self.facts.colour_facts = { saw_srgb: self.facts.colour_facts.saw_srgb, srgb_intent: self.facts.colour_facts.srgb_intent, saw_gamma: self.facts.colour_facts.saw_gamma, gamma_is_srgb: self.facts.colour_facts.gamma_is_srgb, gamma: self.facts.colour_facts.gamma, saw_chrm: self.facts.colour_facts.saw_chrm, chrm_is_srgb: self.facts.colour_facts.chrm_is_srgb, chrm: self.facts.colour_facts.chrm, saw_iccp: true, iccp_name: Some(Bytes::from_array(name)), iccp_profile: Some(profile) }
  }
  Ok(())
}

///|
/// Build the private output exactly when the first IDAT header is accepted.
/// The IHDR preflight has already validated geometry without charging a
/// prospective output allocation; this method uses the same descriptor and
/// child-budget helpers as eager decoding before allocating the image/sink.
fn PngDecodeMachine::preflight_first_idat(self : PngDecodeMachine) -> Result[Unit, @error.CoreError] {
  if self.lifecycle is Some(_) { return Ok(()) }
  let ihdr = match self.ihdr { Some(value) => value; None => return Err(_png_error("png-ihdr-first")) }
  if ihdr[9] == b'\x03' && !self.facts.saw_palette { return Err(_png_error("png-plte-required")) }
  let source_channels = if ihdr[9] == 0 || ihdr[9] == 3 { 1UL } else if ihdr[9] == 2 { 3UL } else if ihdr[9] == 4 { 2UL } else { 4UL }
  let channels = match self.facts.transparency {
    PngTransparency::Opaque => if ihdr[9] == 4 || ihdr[9] == 6 { 4UL } else { 3UL }
    _ => 4UL
  }
  let source_bytes_per_pixel = match _png_source_bytes_per_pixel(source_channels, ihdr[8].to_int()) { Err(error) => return Err(error); Ok(value) => value }
  let indexed = ihdr[9] == 3
  let transport = PngTransport::{
    width: _png_u32_at(ihdr, 0), height: _png_u32_at(ihdr, 4), bit_depth: ihdr[8].to_int(),
    source_channels, source_bytes_per_pixel, channels, indexed,
    palette: Bytes::from_array(self.facts.palette), palette_entries: self.facts.palette_entries, transparency: self.facts.transparency,
    idat: b"", consumed: 0UL,
  }
  let declaration = match _png_colour_declaration(self.facts.colour_facts, ihdr[9] == 0 || ihdr[9] == 4) { Err(error) => return Err(error); Ok(value) => value }
  let output_budget = match _png_output_budget_for(ihdr, indexed, channels, self.limits, self.budget) { Err(error) => return Err(error); Ok(value) => value }
  let (result_budget, metadata_budget) = match declaration {
    PngColourDeclaration::Srgb(_) => match _png_srgb_budget(ihdr, indexed, channels, self.limits, self.budget) { Err(error) => return Err(error); Ok((metadata, raster)) => (raster, Some(metadata)) }
    PngColourDeclaration::Legacy(gamma, chrm) => {
      let value_bytes = (match gamma { Some(value) => value.length().to_uint64(); None => 0UL }) + (match chrm { Some(value) => value.length().to_uint64(); None => 0UL })
      match _png_non_srgb_budget(ihdr, indexed, channels, value_bytes, self.limits, self.budget) { Err(error) => return Err(error); Ok((metadata, raster)) => (raster, Some(metadata)) }
    }
    PngColourDeclaration::Icc(name, profile) => match _png_non_srgb_budget(ihdr, indexed, channels, name.length().to_uint64() + profile.length().to_uint64(), self.limits, self.budget) { Err(error) => return Err(error); Ok((metadata, raster)) => (raster, Some(metadata)) }
    PngColourDeclaration::Default => (output_budget, None)
  }
  let metadata = match declaration {
    PngColourDeclaration::Srgb(intent) => match metadata_budget { Some(budget) => match _png_srgb_metadata(channels, intent, budget) { Err(error) => return Err(error); Ok(value) => value }; None => return Err(_png_error("png-srgb-budget")) }
    PngColourDeclaration::Legacy(gamma, chrm) => match metadata_budget { Some(budget) => match _png_legacy_metadata(channels, gamma, chrm, budget) { Err(error) => return Err(error); Ok(value) => value }; None => return Err(_png_error("png-legacy-budget")) }
    PngColourDeclaration::Icc(name, profile) => match metadata_budget { Some(budget) => match _png_iccp_metadata(channels, name, profile, budget) { Err(error) => return Err(error); Ok(value) => value }; None => return Err(_png_error("png-iccp-budget")) }
    PngColourDeclaration::Default => match _png_empty_metadata(channels) { Err(error) => return Err(error); Ok(value) => value }
  }
  let descriptor = match _png_descriptor_with_metadata(transport, metadata) { Err(error) => return Err(error); Ok(value) => value }
  let image = match @storage.OwnedImage::new_operation(descriptor, result_budget, PngBuiltinAllocator::{} as &@bytes.Allocator, self.limits.max_work()) { Err(error) => return Err(error); Ok(value) => value }
  let sink = match PngRasterSink::new(image, transport, ihdr[12] == 1, result_budget) { Err(error) => return Err(error); Ok(value) => value }
  self.lifecycle = Some(PngMachineLifecycle::{ sink })
  self.lifecycle_allocations = self.lifecycle_allocations + 1UL
  Ok(())
}

///|
fn PngDecodeMachine::framing_chunk_complete(self : PngDecodeMachine) -> Bool {
  self.last_chunk_complete
}

///|
/// The byte-fed owner must be told that the source reached EOF.  In
/// particular, a CRC-authenticated IEND is not success by itself: the zlib
/// trailer, filtered raster, IEND CRC, and this terminal EOF transition must
/// all have happened while the image remains private.
fn PngDecodeMachine::finish(self : PngDecodeMachine) -> Result[Unit, @error.CoreError] {
  match self.state {
    PngDecodeMachineState::NeedEof => {
      let inflate = match self.inflate { Some(value) => value; None => return Err(_png_error("zlib-truncated")) }
      if !inflate.complete() { return Err(_png_error("zlib-truncated")) }
      let lifecycle = match self.lifecycle { Some(value) => value; None => return Err(_png_error("png-idat-order")) }
      match lifecycle.sink.finish() {
        Err(error) => { self.state = PngDecodeMachineState::Failed(error); Err(error) }
        Ok(_) => {
          let disposition = match _png_empty_disposition() {
            Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
            Ok(value) => value
          }
          self.outcome = Some({ image: lifecycle.sink.into_image(), disposition, bytes_read: self.accepted })
          self.state = PngDecodeMachineState::Completed
          Ok(())
        }
      }
    }
    _ => Err(_png_error("png-finished"))
  }
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
          // An active legacy IDAT source discovers the next chunk while
          // satisfying the inflater.  Consequently an unfinished member
          // reports `zlib-truncated` before IEND's fixed-length rule.
          if self.saw_idat {
            let inflate = match self.inflate { Some(value) => value; None => { let error = _png_error("zlib-truncated"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
            if !inflate.complete() {
              let error = _png_error("zlib-truncated")
              self.state = PngDecodeMachineState::Failed(error)
              return Err(error)
            }
          }
          let error = _png_error("png-iend-length")
          self.state = PngDecodeMachineState::Failed(error)
          return Err(error)
        }
        if _png_type_is(kind, b'I', b'D', b'A', b'T') {
          if self.left_idat_sequence {
            let error = _png_error("png-idat-contiguous")
            self.state = PngDecodeMachineState::Failed(error)
            return Err(error)
          }
          match self.preflight_first_idat() {
            Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
            Ok(_) => ()
          }
          self.idat = match _png_new_idat_state(length, kind) {
            Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
            Ok(value) => Some(value)
          }
          if self.inflate is None { self.inflate = Some(PngInflateState::new(self.limits.max_output_bytes())) }
        } else if self.saw_idat {
          self.left_idat_sequence = true
          // The eager transport asks the active inflater for another byte
          // before it interprets ordinary non-IDAT chunks.  Preserve that
          // observable precedence: an unfinished zlib member wins over the
          // later separated-IDAT framing violation.  The legacy transport
          // still gives IHDR, PLTE, and colour declarations their dedicated
          // semantic errors first, so leave those to the regular validator.
          if !_png_type_is(kind, b'I', b'H', b'D', b'R') &&
            !_png_type_is(kind, b'P', b'L', b'T', b'E') &&
            !_png_is_recognised_colour(kind) {
            let inflate = match self.inflate { Some(value) => value; None => { let error = _png_error("zlib-truncated"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
            if !inflate.complete() {
              let error = _png_error("zlib-truncated")
              self.state = PngDecodeMachineState::Failed(error)
              return Err(error)
            }
          }
        }
        if !_png_type_is(kind, b'I', b'D', b'A', b'T') &&
          !_png_type_is(kind, b'I', b'E', b'N', b'D') &&
          !_png_machine_retains_payload(kind) {
          if _png_is_known_semantic(kind) {
            let error = _png_error("png-semantic-chunk")
            self.state = PngDecodeMachineState::Failed(error)
            return Err(error)
          }
          if _png_is_critical(kind) {
            let error = _png_error("png-unknown-critical")
            self.state = PngDecodeMachineState::Failed(error)
            return Err(error)
          }
          if self.options.preserve_opaque_metadata() {
            let error = @codec.capability_unavailable(
              "png-decode", "opaque-metadata-preservation",
            )
            self.state = PngDecodeMachineState::Failed(error)
            return Err(error)
          }
        }
        match self.validate_retained_header(length, kind) {
          Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
          Ok(_) => ()
        }
        let crc = _png_crc_for_type(kind)
        self.state = if length == 0UL { PngDecodeMachineState::Crc(kind, [], [], crc) } else { PngDecodeMachineState::Payload(length, kind, [], crc) }
      }
    }
    PngDecodeMachineState::Payload(remaining, kind, payload, crc) => {
      if _png_type_is(kind, b'I', b'D', b'A', b'T') {
        let idat = match self.idat { Some(value) => value; None => { let error = _png_error("png-idat-state"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
        match idat.accept_payload_byte(byte) { Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }; Ok(_) => () }
        let inflate = match self.inflate { Some(value) => value; None => { let error = _png_error("zlib-truncated"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
        let lifecycle = match self.lifecycle { Some(value) => value; None => { let error = _png_error("png-idat-order"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
        match inflate.accept_to(byte, lifecycle.sink) { Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }; Ok(_) => () }
      }
      let next_crc = _png_crc_step(crc, byte)
      if _png_machine_retains_payload(kind) { payload.push(byte) }
      if remaining == 1UL { self.state = PngDecodeMachineState::Crc(kind, payload, [], next_crc) } else { self.state = PngDecodeMachineState::Payload(remaining - 1UL, kind, payload, next_crc) }
    }
    PngDecodeMachineState::Crc(kind, payload, bytes, crc) => {
      if _png_type_is(kind, b'I', b'D', b'A', b'T') {
        let idat = match self.idat { Some(value) => value; None => { let error = _png_error("png-idat-state"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
        match idat.accept_crc_byte(byte) { Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }; Ok(_) => () }
      }
      bytes.push(byte)
      if bytes.length() == 4 {
        let stored = (bytes[0].to_int().to_uint64() << 24) | (bytes[1].to_int().to_uint64() << 16) | (bytes[2].to_int().to_uint64() << 8) | bytes[3].to_int().to_uint64()
        if stored != (crc ^ 4294967295UL) {
          let error = _png_error("png-crc")
          self.state = PngDecodeMachineState::Failed(error)
          return Err(error)
        }
        if _png_type_is(kind, b'I', b'H', b'D', b'R') {
          match _png_preflight_ihdr(payload, self.limits, self.budget) {
            Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
            Ok(_) => self.ihdr = Some(payload)
          }
        } else if _png_machine_retains_payload(kind) {
          match self.apply_pre_idat_chunk(kind, payload) {
            Err(error) => { self.state = PngDecodeMachineState::Failed(error); return Err(error) }
            Ok(_) => ()
          }
        }
        if _png_type_is(kind, b'I', b'D', b'A', b'T') {
          let idat = match self.idat { Some(value) => value; None => { let error = _png_error("png-idat-state"); self.state = PngDecodeMachineState::Failed(error); return Err(error) } }
          if !idat.chunk_complete() {
            let error = _png_error("png-idat-state")
            self.state = PngDecodeMachineState::Failed(error)
            return Err(error)
          }
          self.idat = None
          self.saw_idat = true
        }
        self.last_chunk_complete = true
        self.state = if _png_type_is(kind, b'I', b'E', b'N', b'D') { PngDecodeMachineState::NeedEof } else { PngDecodeMachineState::Length([]) }
      }
    }
    PngDecodeMachineState::NeedEof => {
      let error = _png_error("png-trailing-data")
      self.state = PngDecodeMachineState::Failed(error)
      return Err(error)
    }
    PngDecodeMachineState::Completed => return Err(_png_error("png-finished"))
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
  let scratch = match @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  while true {
    match scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
      Ok(_) => match self.accept(scratch.view().get(0UL).unwrap()) {
        Err(error) => return Err(error)
        Ok(_) => {
          // The private framing substrate intentionally permits an isolated
          // pre-IHDR chunk for its transition tests.  The eager public facade
          // retains the PNG semantic rule at the reader boundary.
          if self.ihdr is None {
            match self.state {
              PngDecodeMachineState::Payload(_, kind, _, _) |
              PngDecodeMachineState::Crc(kind, _, _, _) => {
                if !_png_type_is(kind, b'I', b'H', b'D', b'R') {
                  return Err(_png_error("png-ihdr-first"))
                }
              }
              _ => ()
            }
          }
          if !self.saw_idat {
            match self.state {
              PngDecodeMachineState::Crc(kind, _, _, _) => {
                if _png_type_is(kind, b'I', b'E', b'N', b'D') {
                  return Err(_png_error("png-iend-order"))
                }
              }
              _ => ()
            }
          }
        }
      }
      Err(error) => {
        if error.code() != @error.ErrorCode::UnexpectedEndOfStream {
          return Err(error)
        }
        match self.state {
          PngDecodeMachineState::NeedEof => ()
          _ => return Err(error)
        }
        match self.finish() {
          Err(terminal) => return Err(terminal)
          Ok(_) => break
        }
      }
    }
  }
  match self.outcome {
    Some(outcome) => Ok(@codec.DecodeResult::new(
      outcome.image, outcome.disposition, outcome.bytes_read,
    ))
    None => Err(_png_error("png-machine-outcome"))
  }
}
