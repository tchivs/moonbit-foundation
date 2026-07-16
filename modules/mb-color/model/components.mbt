///|
fn component_range_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    context~,
  )
}

///|
fn encoded_range_error(value : UInt64, context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    requested=value,
    limit=255UL,
    context~,
  )
}

///|
fn validate_normalized(
  value : Double,
  context : String,
) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() || value < 0.0 || value > 1.0 {
    Err(component_range_error(context))
  } else {
    Ok(value)
  }
}

///|
fn validate_encoded8(
  value : UInt64,
  context : String,
) -> Result[Byte, @error.CoreError] {
  if value > 255UL {
    Err(encoded_range_error(value, context))
  } else {
    Ok(value.to_byte())
  }
}

///|
/// A finite normalized sRGB component with the encoded-sRGB transfer.
pub struct EncodedSrgbComponent {
  priv value_value : Double
}

///|
pub fn EncodedSrgbComponent::new(
  value : Double,
) -> Result[EncodedSrgbComponent, @error.CoreError] {
  validate_normalized(value, "encoded-srgb-component").map(fn(value) {
    EncodedSrgbComponent::{ value_value: value }
  })
}

///|
pub fn EncodedSrgbComponent::value(self : EncodedSrgbComponent) -> Double {
  self.value_value
}

///|
pub fn EncodedSrgbComponent::space(
  _self : EncodedSrgbComponent,
) -> ColorSpaceIdentity {
  ColorSpaceIdentity::Srgb
}

///|
pub fn EncodedSrgbComponent::transfer(
  _self : EncodedSrgbComponent,
) -> TransferIdentity {
  TransferIdentity::EncodedSrgb
}

///|
pub fn EncodedSrgbComponent::representation(
  _self : EncodedSrgbComponent,
) -> ComponentRepresentation {
  ComponentRepresentation::NormalizedDouble
}

///|
/// A finite normalized sRGB component with the linear-sRGB transfer.
pub struct LinearSrgbComponent {
  priv value_value : Double
}

///|
pub fn LinearSrgbComponent::new(
  value : Double,
) -> Result[LinearSrgbComponent, @error.CoreError] {
  validate_normalized(value, "linear-srgb-component").map(fn(value) {
    LinearSrgbComponent::{ value_value: value }
  })
}

///|
pub fn LinearSrgbComponent::value(self : LinearSrgbComponent) -> Double {
  self.value_value
}

///|
pub fn LinearSrgbComponent::space(
  _self : LinearSrgbComponent,
) -> ColorSpaceIdentity {
  ColorSpaceIdentity::Srgb
}

///|
pub fn LinearSrgbComponent::transfer(
  _self : LinearSrgbComponent,
) -> TransferIdentity {
  TransferIdentity::LinearSrgb
}

///|
pub fn LinearSrgbComponent::representation(
  _self : LinearSrgbComponent,
) -> ComponentRepresentation {
  ComponentRepresentation::NormalizedDouble
}

///|
/// Finite normalized alpha coverage. Alpha has no color-space or transfer identity.
pub struct NormalizedAlpha {
  priv value_value : Double
}

///|
pub fn NormalizedAlpha::new(
  value : Double,
) -> Result[NormalizedAlpha, @error.CoreError] {
  validate_normalized(value, "normalized-alpha").map(fn(value) {
    NormalizedAlpha::{ value_value: value }
  })
}

///|
pub fn NormalizedAlpha::value(self : NormalizedAlpha) -> Double {
  self.value_value
}

///|
/// An encoded-sRGB component represented by exactly one validated byte.
pub struct EncodedSrgb8Component {
  priv value_value : Byte
}

///|
pub fn EncodedSrgb8Component::new(
  value : UInt64,
) -> Result[EncodedSrgb8Component, @error.CoreError] {
  validate_encoded8(value, "encoded-srgb8-component").map(fn(value) {
    EncodedSrgb8Component::{ value_value: value }
  })
}

///|
pub fn EncodedSrgb8Component::from_byte(value : Byte) -> EncodedSrgb8Component {
  { value_value: value }
}

///|
pub fn EncodedSrgb8Component::value(self : EncodedSrgb8Component) -> Byte {
  self.value_value
}

///|
pub fn EncodedSrgb8Component::space(
  _self : EncodedSrgb8Component,
) -> ColorSpaceIdentity {
  ColorSpaceIdentity::Srgb
}

///|
pub fn EncodedSrgb8Component::transfer(
  _self : EncodedSrgb8Component,
) -> TransferIdentity {
  TransferIdentity::EncodedSrgb
}

///|
pub fn EncodedSrgb8Component::representation(
  _self : EncodedSrgb8Component,
) -> ComponentRepresentation {
  ComponentRepresentation::Encoded8
}

///|
/// Alpha coverage represented by exactly one validated byte.
pub struct EncodedAlpha8 {
  priv value_value : Byte
}

///|
pub fn EncodedAlpha8::new(
  value : UInt64,
) -> Result[EncodedAlpha8, @error.CoreError] {
  validate_encoded8(value, "encoded-alpha8").map(fn(value) {
    EncodedAlpha8::{ value_value: value }
  })
}

///|
pub fn EncodedAlpha8::from_byte(value : Byte) -> EncodedAlpha8 {
  { value_value: value }
}

///|
pub fn EncodedAlpha8::value(self : EncodedAlpha8) -> Byte {
  self.value_value
}
