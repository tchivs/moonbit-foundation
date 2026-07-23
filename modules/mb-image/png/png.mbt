///|
/// A portable eager PNG decoder for strict non-interlaced and Adam7 RGB8/RGBA8
/// interchange. Encoded scanlines, compression, and pass state remain private.
pub struct PngDecoder {}

///|
pub fn PngDecoder::new() -> PngDecoder {
  PngDecoder::{  }
}

///| Decodes the explicit non-interlaced Type-4/16 encoded-sRGB profile into
/// packed little-endian straight-alpha `graya16` storage.
pub fn PngDecoder::decode_graya16(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  ignore(diagnostics)
  PngDecodeMachine::new_with_profile(
    PngDecodeProfile::GrayAlpha16, options, limits, budget,
  ).decode_reader(reader)
}

///| Decodes the explicit Type-6/16 encoded-sRGB profile into packed
/// little-endian straight-alpha `rgba16` storage without widening `decode`.
pub fn PngDecoder::decode_rgba16(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  ignore(diagnostics)
  PngDecodeMachine::new_with_profile(
    PngDecodeProfile::Rgba16, options, limits, budget,
  ).decode_reader(reader)
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

///| Constructs the explicit non-interlaced Type-4/16 preservation route for
/// caller-owned chunks. Completion, accounting, and terminal behavior remain
/// owned by the shared chunk machine.
pub fn PngChunkDecoder::new_graya16(
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> PngChunkDecoder {
  {
    limits,
    _diagnostics: diagnostics,
    state: PngChunkDecoderState::Active(PngDecodeMachine::new_with_profile(
      PngDecodeProfile::GrayAlpha16,
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

///| Constructs the explicit Type-6/16 preservation route for caller-owned
/// chunks. Completion, accounting, and terminal behavior remain owned by the
/// shared chunk machine.
pub fn PngChunkDecoder::new_rgba16(
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> PngChunkDecoder {
  {
    limits,
    _diagnostics: diagnostics,
    state: PngChunkDecoderState::Active(PngDecodeMachine::new_with_profile(
      PngDecodeProfile::Rgba16,
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
/// `Stored` and `FixedOrStored` are frozen compatibility routes. `DynamicOrFixedOrStored`
/// may select Dynamic only when a complete PNG is strictly smaller than unchanged
/// `FixedOrStored`; a tie retains `FixedOrStored`. This phase excludes adaptive filtering,
/// matching beyond distance four, 32 KiB history, image-sized staging, length-limited
/// optimization, FFI, host streaming, APNG, colour, and metadata expansion.
pub(all) enum PngCompressionStrategy {
  Stored
  FixedOrStored
  DynamicOrFixedOrStored
} derive(Eq)

///|
/// PNG scanline filter selection for the strict RGB8 and straight-RGBA8 profile.
/// `None` preserves the established filter-None representation. `Adaptive` selects
/// a method-0 filter for each row by evaluating None, Sub, Up, Average, then Paeth.
/// Each candidate is scored by the sum of its signed-absolute residual magnitudes;
/// only a strictly lower score replaces the winner, so equal scores retain the
/// earlier candidate in that order.
pub(all) enum PngFilterStrategy {
  None
  Adaptive
} derive(Eq)

///| PNG interlace selection for the strict RGB8 and straight-RGBA8 profile.
/// `None` preserves every established non-interlaced output route. `Adam7` is
/// explicit because its encoder traversal is not available until Phase 42.
pub(all) enum PngInterlaceStrategy {
  None
  Adam7
} derive(Eq)

///|
/// Private PNG raster profile selection. Legacy public factories remain on the
/// RGB8/straight-RGBA8 contract; Gray8 is deliberately available only through
/// its explicit Stored/non-interlaced factories.
priv enum PngEncodeProfile {
  LegacyRgbOrRgba
  Gray1
  Gray2
  Gray4
  Gray8
  Gray16
  GrayAlpha8
  GrayAlpha16
  Rgba16
} derive(Eq)

///|
/// A deterministic encoder for the strict RGB8 and straight-RGBA8 PNG profile.
/// `new()` emits the frozen Stored representation; the configured factory retains the
/// frozen FixedOrStored route and provides the opt-in DynamicOrFixedOrStored contract.
pub struct PngEncoder {
  priv strategy : PngCompressionStrategy
  priv filter_strategy : PngFilterStrategy
  priv interlace_strategy : PngInterlaceStrategy
  priv profile : PngEncodeProfile
}

///|
pub fn PngEncoder::new() -> PngEncoder {
  PngEncoder::new_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
    PngInterlaceStrategy::None,
  )
}

///| Constructs the explicit Gray8 PNG route: 8-bit grayscale, Stored DEFLATE,
/// filter None, and no interlace.
pub fn PngEncoder::new_gray8() -> PngEncoder {
  PngEncoder::new_gray8_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

///| Constructs the explicit Gray1 PNG route: 1-bit grayscale, Stored DEFLATE,
/// filter None, and no interlace.
pub fn PngEncoder::new_gray1() -> PngEncoder {
  {
    strategy: PngCompressionStrategy::Stored,
    filter_strategy: PngFilterStrategy::None,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray1,
  }
}

///| Constructs the explicit Gray2 PNG route: 2-bit grayscale, Stored DEFLATE,
/// filter None, and no interlace.
pub fn PngEncoder::new_gray2() -> PngEncoder {
  {
    strategy: PngCompressionStrategy::Stored,
    filter_strategy: PngFilterStrategy::None,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray2,
  }
}

///| Constructs the explicit Gray4 PNG route: 4-bit grayscale, Stored DEFLATE,
/// filter None, and no interlace.
pub fn PngEncoder::new_gray4() -> PngEncoder {
  {
    strategy: PngCompressionStrategy::Stored,
    filter_strategy: PngFilterStrategy::None,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray4,
  }
}

///| Constructs the explicit Gray16 PNG route: 16-bit grayscale, Stored
/// DEFLATE, filter None, and no interlace.
pub fn PngEncoder::new_gray16() -> PngEncoder {
  PngEncoder::new_gray16_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

///| Constructs a Gray16 encoder with an explicit compression strategy and the
/// filter-None route. Gray16 remains intentionally non-interlaced.
pub fn PngEncoder::new_gray16_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::new_gray16_with_strategies(strategy, PngFilterStrategy::None)
}

///| Constructs a Gray16 encoder with an explicit filter strategy and Stored
/// compression. Gray16 remains intentionally non-interlaced.
pub fn PngEncoder::new_gray16_with_filter_strategy(
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_gray16_with_strategies(
    PngCompressionStrategy::Stored, filter_strategy,
  )
}

///| Constructs a Gray16 encoder with explicit compression and filter
/// strategies. Its profile fixes PNG colour type 0 and excludes Adam7.
pub fn PngEncoder::new_gray16_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray16,
  }
}

///| Constructs the explicit Gray+Alpha8 PNG route: packed 8-bit straight
/// alpha, Stored DEFLATE, filter None, and no interlace.
pub fn PngEncoder::new_graya8() -> PngEncoder {
  PngEncoder::new_graya8_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

///| Constructs a Gray+Alpha8 encoder with an explicit compression strategy and
/// the filter-None route. Gray+Alpha8 remains intentionally non-interlaced.
pub fn PngEncoder::new_graya8_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::new_graya8_with_strategies(strategy, PngFilterStrategy::None)
}

///| Constructs a Gray+Alpha8 encoder with an explicit filter strategy and
/// Stored compression. Gray+Alpha8 remains intentionally non-interlaced.
pub fn PngEncoder::new_graya8_with_filter_strategy(
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_graya8_with_strategies(
    PngCompressionStrategy::Stored, filter_strategy,
  )
}

///| Constructs a Gray+Alpha8 encoder with explicit compression and filter
/// strategies. This legacy family remains explicitly non-interlaced.
pub fn PngEncoder::new_graya8_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::GrayAlpha8,
  }
}

///| Constructs a Gray+Alpha8 encoder with explicit interlace selection and the
/// Stored/filter-None route. Adam7 is opt-in; existing GrayAlpha8 factories
/// retain their explicit non-interlaced output.
pub fn PngEncoder::new_graya8_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_graya8_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

///| Constructs a Gray+Alpha8 encoder with independently selected compression,
/// filter, and interlace strategies.
pub fn PngEncoder::new_graya8_with_all_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy,
    profile: PngEncodeProfile::GrayAlpha8,
  }
}

///| Constructs the explicit Gray+Alpha16 PNG route: packed 16-bit straight
/// alpha, Stored DEFLATE, filter None, and no interlace.
pub fn PngEncoder::new_graya16() -> PngEncoder {
  PngEncoder::new_graya16_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

///| Constructs a Gray+Alpha16 encoder with an explicit compression strategy
/// and the filter-None route. Gray+Alpha16 remains intentionally non-interlaced.
pub fn PngEncoder::new_graya16_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::new_graya16_with_strategies(strategy, PngFilterStrategy::None)
}

///| Constructs a Gray+Alpha16 encoder with an explicit filter strategy and
/// Stored compression. Gray+Alpha16 remains intentionally non-interlaced.
pub fn PngEncoder::new_graya16_with_filter_strategy(
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_graya16_with_strategies(
    PngCompressionStrategy::Stored, filter_strategy,
  )
}

///| Constructs a Gray+Alpha16 encoder with explicit compression and filter
/// strategies. Its profile fixes PNG colour type 4 and excludes Adam7.
pub fn PngEncoder::new_graya16_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::GrayAlpha16,
  }
}

///| Constructs a Gray+Alpha16 encoder with explicit interlace selection and the
/// Stored/filter-None route. Adam7 is opt-in; existing GrayAlpha16 factories
/// retain their explicit non-interlaced output.
pub fn PngEncoder::new_graya16_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_graya16_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

///| Constructs a Gray+Alpha16 encoder with independently selected compression,
/// filter, and interlace strategies.
pub fn PngEncoder::new_graya16_with_all_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy,
    profile: PngEncodeProfile::GrayAlpha16,
  }
}

///| Constructs the explicit RGBA16 PNG route: packed little-endian U16
/// straight alpha, Stored DEFLATE, filter None, and no interlace.
pub fn PngEncoder::new_rgba16() -> PngEncoder {
  PngEncoder::new_rgba16_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

///| Constructs an RGBA16 encoder with an explicit compression strategy and the
/// filter-None route. RGBA16 remains intentionally non-interlaced.
pub fn PngEncoder::new_rgba16_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::new_rgba16_with_strategies(strategy, PngFilterStrategy::None)
}

///| Constructs an RGBA16 encoder with an explicit filter strategy and Stored
/// compression. RGBA16 remains intentionally non-interlaced.
pub fn PngEncoder::new_rgba16_with_filter_strategy(
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_rgba16_with_strategies(
    PngCompressionStrategy::Stored, filter_strategy,
  )
}

///| Constructs an RGBA16 encoder with explicit compression and filter
/// strategies. This legacy constructor fixes PNG colour type 6 and
/// `PngInterlaceStrategy::None`; use the explicit interlace selector family to
/// request Adam7.
pub fn PngEncoder::new_rgba16_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Rgba16,
  }
}

///| Constructs an RGBA16 encoder with explicit interlace selection and the
/// Stored/filter-None route. Adam7 remains opt-in; existing RGBA16 factories
/// retain their explicit non-interlaced output.
pub fn PngEncoder::new_rgba16_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_rgba16_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

///| Constructs an RGBA16 encoder with independently selected compression,
/// filter, and interlace strategies.
pub fn PngEncoder::new_rgba16_with_all_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy,
    profile: PngEncodeProfile::Rgba16,
  }
}

///| Constructs a Gray8 encoder with an explicit compression strategy and the
/// filter-None route. Gray8 remains intentionally non-interlaced.
pub fn PngEncoder::new_gray8_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::new_gray8_with_strategies(strategy, PngFilterStrategy::None)
}

///| Constructs a Gray8 encoder with an explicit filter strategy and Stored
/// compression. Gray8 remains intentionally non-interlaced.
pub fn PngEncoder::new_gray8_with_filter_strategy(
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_gray8_with_strategies(
    PngCompressionStrategy::Stored, filter_strategy,
  )
}

///| Constructs a Gray8 encoder with explicit compression and filter
/// strategies. Its profile fixes PNG colour type 0 and excludes Adam7.
pub fn PngEncoder::new_gray8_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray8,
  }
}

///|
/// Constructs an encoder with an explicit PNG compression strategy and the explicit
/// filter-None route. `FixedOrStored` retains its frozen bounded exact fixed-or-Stored
/// choice. `DynamicOrFixedOrStored` may choose Dynamic only for a strict complete-PNG
/// win over unchanged FixedOrStored and retains FixedOrStored on a tie.
pub fn PngEncoder::new_with_compression_strategy(
  strategy : PngCompressionStrategy,
) -> PngEncoder {
  PngEncoder::new_with_all_strategies(
    strategy, PngFilterStrategy::None, PngInterlaceStrategy::None,
  )
}

///|
/// Constructs an encoder with an explicit PNG filter selection and the Stored
/// compression route. `new_with_filter_strategy(Adaptive)` therefore remains
/// Stored plus Adaptive; use `new_with_strategies` to combine Adaptive with a
/// different compression strategy.
pub fn PngEncoder::new_with_filter_strategy(
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_with_all_strategies(
    PngCompressionStrategy::Stored, filter_strategy, PngInterlaceStrategy::None,
  )
}

/// Constructs an encoder with explicit PNG compression and filter strategies.
/// With `Adaptive`, method-0 candidates are evaluated in None, Sub, Up, Average,
/// Paeth order and scored by signed-absolute residual magnitude; only a strictly
/// lower score replaces the winner, retaining the earlier candidate on a tie.
/// `new()`, compression-only factories, and legacy routes remain explicit None
/// filters, while filter-only Adaptive remains Stored plus Adaptive.
pub fn PngEncoder::new_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  PngEncoder::new_with_all_strategies(
    strategy, filter_strategy, PngInterlaceStrategy::None,
  )
}

///| Constructs an encoder with explicit interlace selection and the frozen
/// Stored/filter-None route.
pub fn PngEncoder::new_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

///| Constructs an encoder with independently selected compression, filter, and
/// interlace strategies. Adam7 is an explicit pending capability until its
/// seven-pass encoder implementation is added.
pub fn PngEncoder::new_with_all_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::{
    strategy,
    filter_strategy,
    interlace_strategy,
    profile: PngEncodeProfile::LegacyRgbOrRgba,
  }
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
