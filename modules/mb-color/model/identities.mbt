///|
/// Color-space identity carried explicitly by reference color components.
pub(all) enum ColorSpaceIdentity {
  Srgb
} derive(Eq)

///|
/// Transfer identity carried explicitly and independently of color space.
pub(all) enum TransferIdentity {
  EncodedSrgb
  LinearSrgb
} derive(Eq)

///|
/// Scalar representation used by a color component.
pub(all) enum ComponentRepresentation {
  NormalizedDouble
  Encoded8
} derive(Eq)

///|
/// Alpha interpretation. Operations require callers to select a state.
pub(all) enum AlphaMode {
  Straight
  Premultiplied
} derive(Eq)
