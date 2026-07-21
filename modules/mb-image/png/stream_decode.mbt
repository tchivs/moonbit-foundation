///|
/// The byte boundary owned by the private PNG decoder.  This deliberately
/// contains no `ByteView`: callers may release or mutate their source as soon
/// as `accept` returns.
priv enum PngDecodeMachineState {
  Signature(Int)
  Framing
  Failed(@error.CoreError)
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
}

///|
fn PngDecodeMachine::new(
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> PngDecodeMachine {
  { options, limits, budget, state: PngDecodeMachineState::Signature(0), accepted: 0UL }
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
      self.state = if index + 1 == signature.length() { PngDecodeMachineState::Framing } else { PngDecodeMachineState::Signature(index + 1) }
    }
    PngDecodeMachineState::Framing => ()
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
