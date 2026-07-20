///|
/// A portable eager PNG decoder for the strict non-interlaced RGB8/RGBA8
/// interchange profile.  Compression and scanline state remain private.
pub struct PngDecoder {}

///|
pub fn PngDecoder::new() -> PngDecoder {
  PngDecoder::{  }
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
  let transport = match _png_read_transport(reader, options, limits, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let filtered = match _png_inflate_zlib(transport.idat, limits.max_output_bytes()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let descriptor = match _png_descriptor(transport) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let image = match @storage.OwnedImage::new_operation(
    descriptor, budget, PngBuiltinAllocator::{} as &@bytes.Allocator,
    limits.max_work(),
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match image.with_mut_view(fn(view) { _png_write_raster(view, transport, filtered) }) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let disposition = match _png_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@codec.DecodeResult::new(image, disposition, transport.consumed))
}
