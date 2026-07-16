///|
/// Absolute tolerance for encoded-sRGB to linear-sRGB reference conversion.
pub fn decode_absolute_tolerance() -> Double {
  1.0e-12
}

///|
/// Absolute tolerance for linear-sRGB to encoded-sRGB reference conversion.
pub fn encode_absolute_tolerance() -> Double {
  1.0e-12
}

///|
/// Absolute tolerance for a complete decode/encode or encode/decode round trip.
pub fn roundtrip_absolute_tolerance() -> Double {
  2.0e-12
}

///|
/// Convert a validated normalized encoded-sRGB component to linear sRGB.
///
/// The published threshold belongs to the low branch. The input type carries
/// its transfer identity, so this conversion has no ambiguous `Double` seam.
pub fn decode_srgb(
  component : @model.EncodedSrgbComponent,
) -> @model.LinearSrgbComponent {
  let encoded = component.value()
  let linear = if encoded <= 0.04045 {
    encoded / 12.92
  } else {
    @math.pow((encoded + 0.055) / 1.055, 2.4)
  }
  @model.LinearSrgbComponent::new(linear).unwrap()
}

///|
/// Convert a validated normalized linear-sRGB component to encoded sRGB.
///
/// The published threshold belongs to the low branch. No implicit clamp or
/// backend rounding operation participates in this normalized conversion.
pub fn encode_srgb(
  component : @model.LinearSrgbComponent,
) -> @model.EncodedSrgbComponent {
  let linear = component.value()
  let encoded = if linear <= 0.0031308 {
    12.92 * linear
  } else {
    1.055 * @math.pow(linear, 1.0 / 2.4) - 0.055
  }
  @model.EncodedSrgbComponent::new(encoded).unwrap()
}
