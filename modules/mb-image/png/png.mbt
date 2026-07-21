///|
/// A portable eager PNG decoder for strict non-interlaced and Adam7 RGB8/RGBA8
/// interchange. Encoded scanlines, compression, and pass state remain private.
pub struct PngDecoder {}

///|
pub fn PngDecoder::new() -> PngDecoder {
  PngDecoder::{  }
}

///|
/// A caller-chunk-fed PNG decoder. Completion is declared explicitly with
/// `finish`; it retains no caller ByteView and does not change PngDecoder's
/// Reader-based contract.
pub struct PngChunkDecoder {
  priv limits : @codec.CodecLimits
  priv _diagnostics : @error.Diagnostics
  priv mut state : PngChunkDecoderState
  priv mut consumed_total : UInt64
}

///|
/// Progress from a PngChunkDecoder push. A completed image is intentionally
/// not available here: only finish can transfer the terminal result.
pub(all) enum PngChunkPushOutcome {
  NeedInput
  Failed(@error.CoreError)
}

///|
/// Exact consumption and progress from one caller-owned input view.
pub struct PngChunkPushResult {
  priv consumed_value : UInt64
  priv outcome_value : PngChunkPushOutcome
}

///|
pub fn PngChunkPushResult::consumed(self : PngChunkPushResult) -> UInt64 {
  self.consumed_value
}

///|
pub fn PngChunkPushResult::outcome(
  self : PngChunkPushResult,
) -> PngChunkPushOutcome {
  self.outcome_value
}

///|
pub fn PngChunkDecoder::new(
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> PngChunkDecoder {
  {
    limits,
    _diagnostics: diagnostics,
    state: PngChunkDecoderState::Active(PngDecodeMachine::new(
      @codec.DecodeOptions::new(
        require_complete_input=true,
        preserve_opaque_metadata=false,
      ),
      limits,
      budget,
    )),
    consumed_total: 0UL,
  }
}

///|
/// A PNG-specific compression selection for the strict RGB8 and straight-RGBA8 profile.
/// `FixedOrStored` currently emits the Stored baseline, provides no optimization or
/// size guarantee, and receives fixed-or-stored behavior in Phase 33. This strategy
/// excludes dynamic Huffman coding and adaptive filters.
pub(all) enum PngCompressionStrategy {
  Stored
  FixedOrStored
} derive(Eq)

///|
/// A deterministic encoder for the strict RGB8 and straight-RGBA8 PNG profile.
/// It emits one canonical stored-DEFLATE representation without host adapters.
pub struct PngEncoder {
  priv strategy : PngCompressionStrategy
}

///|
pub fn PngEncoder::new() -> PngEncoder {
  PngEncoder::{ strategy: PngCompressionStrategy::Stored }
}

///|
/// Constructs an encoder with an explicit PNG compression strategy. `FixedOrStored`
/// currently emits the Stored baseline, provides no optimization or size guarantee,
/// and receives fixed-or-stored behavior in Phase 33; it excludes dynamic Huffman
/// coding and adaptive filters.
pub fn PngEncoder::new_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::{ strategy }
}

///|
/// A caller-buffered PNG encoder. It retains the immutable image and private
/// canonical emitter state only; every output lease is scoped to one pull.
pub struct PngChunkEncoder {
  priv mut state : PngChunkEncoderState
  priv mut total_written : UInt64
}

///|
/// The result of supplying one caller-owned mutable output lease to a PNG
/// chunk encoder.
pub(all) enum PngChunkPullOutcome {
  NeedOutput
  Finished
  Failed(@error.CoreError)
}

///|
/// Exact progress from one PngChunkEncoder pull.
pub struct PngChunkPullResult {
  priv written_value : UInt64
  priv total_written_value : UInt64
  priv outcome_value : PngChunkPullOutcome
}

///|
pub fn PngChunkPullResult::written(self : PngChunkPullResult) -> UInt64 {
  self.written_value
}

///|
pub fn PngChunkPullResult::total_written(self : PngChunkPullResult) -> UInt64 {
  self.total_written_value
}

///|
pub fn PngChunkPullResult::outcome(
  self : PngChunkPullResult,
) -> PngChunkPullOutcome {
  self.outcome_value
}

///| Legacy PNG declarations have no transform in this portable profile. Their
/// canonical raw PNG values are retained and the descriptor intentionally
/// avoids the encoded-sRGB identity used by reference operations.
fn _png_legacy_metadata(
  channels : UInt64,
  gamma : Bytes?,
  chrm : Bytes?,
  budget : @budget.Budget,
) -> Result[@model.ImageMetadata, @error.CoreError] {
  let profile_bytes : Array[Byte] = []
  let entries : Array[(String, String, String, Bytes)] = []
  match gamma {
    Some(value) => {
      for byte in value { profile_bytes.push(byte) }
      entries.push(("png", "legacy", "gamma", value))
    }
    None => ()
  }
  match chrm {
    Some(value) => {
      for byte in value { profile_bytes.push(byte) }
      entries.push(("png", "legacy", "chromaticity", value))
    }
    None => ()
  }
  let profile = match @profile.OpaqueProfile::from_bytes(
    @profile.ProfileFormatTag::new("png-legacy").unwrap(), Bytes::from_array(profile_bytes),
    @profile.ProfileLimits::new(36UL), budget,
  ) { Err(error) => return Err(error); Ok(value) => value }
  let retained = match @metadata.OpaqueMetadata::from_entries(
    entries,
    @metadata.MetadataLimits::new(max_entries=2UL, max_token_bytes=16UL, max_value_bytes=32UL, max_total_bytes=128UL, max_disposition_fields=2UL),
    budget,
  ) { Err(error) => return Err(error); Ok(value) => value }
  Ok(@model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::LinearSrgb,
    if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
    @profile.ProfileIdentity::opaque(profile), @model.Orientation::TopLeft, retained,
  ))
}

///| iCCP profiles remain opaque. The profile bytes live in the bounded profile
/// identity while the validated PNG profile name remains canonical metadata.
fn _png_iccp_metadata(
  channels : UInt64,
  name : Bytes,
  bytes : Bytes,
  budget : @budget.Budget,
) -> Result[@model.ImageMetadata, @error.CoreError] {
  let profile = match @profile.OpaqueProfile::from_bytes(
    @profile.ProfileFormatTag::icc(), bytes,
    @profile.ProfileLimits::new(65536UL), budget,
  ) { Err(error) => return Err(error); Ok(value) => value }
  let retained = match @metadata.OpaqueMetadata::from_entries(
    [("png", "icc", "name", name)],
    @metadata.MetadataLimits::new(max_entries=1UL, max_token_bytes=16UL, max_value_bytes=79UL, max_total_bytes=79UL, max_disposition_fields=1UL),
    budget,
  ) { Err(error) => return Err(error); Ok(value) => value }
  Ok(@model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::LinearSrgb,
    if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
    @profile.ProfileIdentity::opaque(profile), @model.Orientation::TopLeft, retained,
  ))
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
  PngDecodeMachine::new(options, limits, budget).decode_reader(reader)
}
