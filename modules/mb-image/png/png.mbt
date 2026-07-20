///|
/// A portable eager PNG decoder for strict non-interlaced and Adam7 RGB8/RGBA8
/// interchange. Encoded scanlines, compression, and pass state remain private.
pub struct PngDecoder {}

///|
pub fn PngDecoder::new() -> PngDecoder {
  PngDecoder::{  }
}

///|
/// A deterministic encoder for the strict RGB8 and straight-RGBA8 PNG profile.
/// It emits one canonical stored-DEFLATE representation without host adapters.
pub struct PngEncoder {}

///|
pub fn PngEncoder::new() -> PngEncoder {
  PngEncoder::{  }
}

///|
fn _probe_png_prefix(prefix : @bytes.ByteView) -> @codec.ProbeOutcome {
  if prefix.length() < 8UL {
    @codec.ProbeOutcome::NeedMore(8UL)
  } else if prefix.get(0UL).unwrap() == b'\x89' &&
    prefix.get(1UL).unwrap() == b'P' &&
    prefix.get(2UL).unwrap() == b'N' &&
    prefix.get(3UL).unwrap() == b'G' &&
    prefix.get(4UL).unwrap() == b'\r' &&
    prefix.get(5UL).unwrap() == b'\n' &&
    prefix.get(6UL).unwrap() == b'\x1a' &&
    prefix.get(7UL).unwrap() == b'\n' {
    @codec.ProbeOutcome::Match
  } else {
    @codec.ProbeOutcome::NoMatch
  }
}

///|
pub impl @codec.ImageDecoder for PngDecoder with fn probe(
  _self,
  prefix,
  limits,
  _diagnostics,
) {
  if prefix.length() > limits.max_probe_bytes() {
    return Err(
      _png_limit("probe-bytes", prefix.length(), limits.max_probe_bytes()),
    )
  }
  Ok(_probe_png_prefix(prefix))
}

///|
pub impl @codec.ImageDecoder for PngDecoder with fn decode(
  _self,
  reader,
  options,
  limits,
  budget,
  _diagnostics,
) {
  let stream = match _png_read_stream_transport(reader, options, limits, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let transport = PngTransport::{ width: stream.width, height: stream.height, bit_depth: stream.bit_depth, source_channels: stream.source_channels, source_bytes_per_pixel: stream.source_bytes_per_pixel, channels: stream.channels, indexed: stream.indexed, palette: stream.palette, palette_entries: stream.palette_entries, transparency: stream.transparency, idat: b"", consumed: 0UL }
  let descriptor = match _png_descriptor(transport) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  // Adam7 uses the shared packed pass rows for indexed samples too; allocating
  // the non-interlaced indexed rows as well would violate its three-allocation
  // preflight contract (image plus current/previous pass rows).
  let index_rows = if stream.indexed && !stream.interlaced {
    let row_bytes = match _png_grayscale_row_bytes(stream.width, stream.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
    match _png_new_packed_rows(row_bytes, stream.budget) {
      Err(error) => return Err(error)
      Ok(value) => Some(value)
    }
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
  let image = match @storage.OwnedImage::new_operation(
    descriptor, stream.budget, PngBuiltinAllocator::{} as &@bytes.Allocator,
    limits.max_work(),
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let consumed = match image.with_mut_view(fn(view) { _png_inflate_zlib_to_raster(stream.source, limits.max_output_bytes(), view, stream, index_rows, packed_rows) }) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let disposition = match _png_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@codec.DecodeResult::new(image, disposition, consumed))
}
