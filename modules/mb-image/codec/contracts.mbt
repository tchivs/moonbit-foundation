///|
/// A closed prefix-only probe result. `NeedMore` carries the minimum total
/// prefix length the codec needs; probing never consumes a Reader.
pub(all) enum ProbeOutcome {
  Match
  NoMatch
  NeedMore(UInt64)
} derive(Eq)

///|
/// Explicit caller-owned ceilings for probe, stream progress, decoded image
/// shape, and codec work. They are independent from the authoritative Budget.
pub struct CodecLimits {
  priv max_probe_bytes_value : UInt64
  priv max_input_bytes_value : UInt64
  priv max_output_bytes_value : UInt64
  priv max_width_value : UInt64
  priv max_height_value : UInt64
  priv max_pixels_value : UInt64
  priv max_work_value : UInt64
}

///|
pub fn CodecLimits::new(
  max_probe_bytes~ : UInt64,
  max_input_bytes~ : UInt64,
  max_output_bytes~ : UInt64,
  max_width~ : UInt64,
  max_height~ : UInt64,
  max_pixels~ : UInt64,
  max_work~ : UInt64,
) -> CodecLimits {
  {
    max_probe_bytes_value: max_probe_bytes,
    max_input_bytes_value: max_input_bytes,
    max_output_bytes_value: max_output_bytes,
    max_width_value: max_width,
    max_height_value: max_height,
    max_pixels_value: max_pixels,
    max_work_value: max_work,
  }
}

///|
pub fn CodecLimits::max_probe_bytes(self : CodecLimits) -> UInt64 {
  self.max_probe_bytes_value
}

///|
pub fn CodecLimits::max_input_bytes(self : CodecLimits) -> UInt64 {
  self.max_input_bytes_value
}

///|
pub fn CodecLimits::max_output_bytes(self : CodecLimits) -> UInt64 {
  self.max_output_bytes_value
}

///|
pub fn CodecLimits::max_width(self : CodecLimits) -> UInt64 {
  self.max_width_value
}

///|
pub fn CodecLimits::max_height(self : CodecLimits) -> UInt64 {
  self.max_height_value
}

///|
pub fn CodecLimits::max_pixels(self : CodecLimits) -> UInt64 {
  self.max_pixels_value
}

///|
pub fn CodecLimits::max_work(self : CodecLimits) -> UInt64 {
  self.max_work_value
}

///|
pub struct DecodeOptions {
  priv require_complete_input_value : Bool
  priv preserve_opaque_metadata_value : Bool
}

///|
pub fn DecodeOptions::new(
  require_complete_input~ : Bool,
  preserve_opaque_metadata~ : Bool,
) -> DecodeOptions {
  {
    require_complete_input_value: require_complete_input,
    preserve_opaque_metadata_value: preserve_opaque_metadata,
  }
}

///|
pub fn DecodeOptions::require_complete_input(self : DecodeOptions) -> Bool {
  self.require_complete_input_value
}

///|
pub fn DecodeOptions::preserve_opaque_metadata(self : DecodeOptions) -> Bool {
  self.preserve_opaque_metadata_value
}

///|
pub struct EncodeOptions {
  priv lossless_required_value : Bool
  priv preserve_opaque_metadata_value : Bool
}

///|
pub fn EncodeOptions::new(
  lossless_required~ : Bool,
  preserve_opaque_metadata~ : Bool,
) -> EncodeOptions {
  {
    lossless_required_value: lossless_required,
    preserve_opaque_metadata_value: preserve_opaque_metadata,
  }
}

///|
pub fn EncodeOptions::lossless_required(self : EncodeOptions) -> Bool {
  self.lossless_required_value
}

///|
pub fn EncodeOptions::preserve_opaque_metadata(self : EncodeOptions) -> Bool {
  self.preserve_opaque_metadata_value
}

///|
/// Successful decode output with exact consumed stream progress and an
/// executable metadata disposition supplied by the codec.
pub struct DecodeResult {
  priv image_value : @storage.OwnedImage
  priv disposition_value : @metadata.MetadataDisposition
  priv bytes_read_value : UInt64
}

///|
pub fn DecodeResult::new(
  image : @storage.OwnedImage,
  disposition : @metadata.MetadataDisposition,
  bytes_read : UInt64,
) -> DecodeResult {
  { image_value: image, disposition_value: disposition, bytes_read_value: bytes_read }
}

///|
pub fn DecodeResult::image(self : DecodeResult) -> @storage.OwnedImage {
  self.image_value
}

///|
pub fn DecodeResult::descriptor(self : DecodeResult) -> @model.ImageDescriptor {
  self.image_value.descriptor()
}

///|
pub fn DecodeResult::disposition(
  self : DecodeResult,
) -> @metadata.MetadataDisposition {
  self.disposition_value
}

///|
pub fn DecodeResult::bytes_read(self : DecodeResult) -> UInt64 {
  self.bytes_read_value
}

///|
/// Successful encode output with exact writer progress and codec-declared
/// metadata disposition.
pub struct EncodeResult {
  priv disposition_value : @metadata.MetadataDisposition
  priv bytes_written_value : UInt64
}

///|
pub fn EncodeResult::new(
  disposition : @metadata.MetadataDisposition,
  bytes_written : UInt64,
) -> EncodeResult {
  { disposition_value: disposition, bytes_written_value: bytes_written }
}

///|
pub fn EncodeResult::disposition(
  self : EncodeResult,
) -> @metadata.MetadataDisposition {
  self.disposition_value
}

///|
pub fn EncodeResult::bytes_written(self : EncodeResult) -> UInt64 {
  self.bytes_written_value
}

///|
/// Construct the stable error used when a codec or option is unavailable.
pub fn capability_unavailable(
  operation : String,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation~,
    context~,
  )
}

///|
/// Open decoder seam: probe caller-owned bytes, then decode a forward-only
/// Reader under explicit options, ceilings, budget, and diagnostics.
pub(open) trait ImageDecoder {
  fn probe(
    Self,
    @bytes.ByteView,
    CodecLimits,
    @error.Diagnostics,
  ) -> Result[ProbeOutcome, @error.CoreError]
  fn decode(
    Self,
    &@io.Reader,
    DecodeOptions,
    CodecLimits,
    @budget.Budget,
    @error.Diagnostics,
  ) -> Result[DecodeResult, @error.CoreError]
}

///|
/// Open encoder seam over an immutable image view and a forward-only Writer.
pub(open) trait ImageEncoder {
  fn encode(
    Self,
    @storage.ImageView,
    &@io.Writer,
    EncodeOptions,
    CodecLimits,
    @budget.Budget,
    @error.Diagnostics,
  ) -> Result[EncodeResult, @error.CoreError]
}

