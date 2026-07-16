///|
fn invalid_profile_tag(length : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidEncoding,
    operation="profile_tag",
    requested=length,
    limit=32UL,
    context="profile-format-tag",
  )
}

///|
fn profile_payload_too_large(
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
    operation="profile_payload",
    requested~,
    limit~,
    context="profile-payload",
  )
}

///|
fn is_ascii_alphanumeric(code : Int) -> Bool {
  (code >= 65 && code <= 90) ||
  (code >= 97 && code <= 122) ||
  (code >= 48 && code <= 57)
}

///|
fn is_profile_tag_tail(code : Int) -> Bool {
  is_ascii_alphanumeric(code) ||
  code == 46 ||
  code == 95 ||
  code == 43 ||
  code == 45
}

///|
fn valid_profile_tag(value : String) -> Bool {
  let units = value.code_units()
  if units.length() < 1 || units.length() > 32 {
    return false
  }
  if !is_ascii_alphanumeric(units[0].to_int()) {
    return false
  }
  for index = 1; index < units.length(); index = index + 1 {
    if !is_profile_tag_tail(units[index].to_int()) {
      return false
    }
  }
  true
}

///|
/// A bounded ASCII identity token supplied by the caller. The token records
/// claimed format only; it does not validate or certify the payload.
pub struct ProfileFormatTag {
  priv value_value : String
}

///|
pub fn ProfileFormatTag::new(
  value : String,
) -> Result[ProfileFormatTag, @error.CoreError] {
  if valid_profile_tag(value) {
    Ok({ value_value: value })
  } else {
    Err(invalid_profile_tag(value.length().to_uint64()))
  }
}

///|
/// Canonical spelling for caller-declared ICC bytes. This is a format label,
/// not an ICC-conformance assertion.
pub fn ProfileFormatTag::icc() -> ProfileFormatTag {
  { value_value: "icc" }
}

///|
pub fn ProfileFormatTag::value(self : ProfileFormatTag) -> String {
  self.value_value
}

///|
/// The caller's explicit maximum for a single opaque profile payload.
pub struct ProfileLimits {
  priv max_payload_bytes_value : UInt64
}

///|
pub fn ProfileLimits::new(max_payload_bytes : UInt64) -> ProfileLimits {
  { max_payload_bytes_value: max_payload_bytes }
}

///|
pub fn ProfileLimits::max_payload_bytes(self : ProfileLimits) -> UInt64 {
  self.max_payload_bytes_value
}

///|
/// Exact independently owned profile bytes paired with caller identity
/// metadata. Contents remain opaque: no header, transform, digest, or semantic
/// equivalence is inferred.
pub struct OpaqueProfile {
  priv tag_value : ProfileFormatTag
  priv owner : @bytes.OwnedBytes
}

///|
/// Validate identity and the caller maximum before delegating all allocation,
/// atomic budget charge, and copy ordering to `OwnedBytes::from_bytes`.
pub fn OpaqueProfile::from_bytes(
  tag : ProfileFormatTag,
  source : Bytes,
  limits : ProfileLimits,
  budget : @budget.Budget,
) -> Result[OpaqueProfile, @error.CoreError] {
  let length = source.length().to_uint64()
  if length > limits.max_payload_bytes() {
    return Err(profile_payload_too_large(length, limits.max_payload_bytes()))
  }
  match @bytes.OwnedBytes::from_bytes(source, budget) {
    Err(error) => Err(error)
    Ok(owner) => Ok({ tag_value: tag, owner })
  }
}

///|
pub fn OpaqueProfile::tag(self : OpaqueProfile) -> ProfileFormatTag {
  self.tag_value
}

///|
pub fn OpaqueProfile::length(self : OpaqueProfile) -> UInt64 {
  self.owner.length()
}

///|
pub fn OpaqueProfile::view(self : OpaqueProfile) -> @bytes.ByteView {
  self.owner.view()
}

///|
/// A direct built-in sRGB identity or an explicitly tagged opaque payload.
pub struct ProfileIdentity {
  priv builtin_srgb_value : Bool
  priv opaque_profile_value : OpaqueProfile?
}

///|
pub fn ProfileIdentity::builtin_srgb() -> ProfileIdentity {
  { builtin_srgb_value: true, opaque_profile_value: None }
}

///|
#warnings("-35")
pub fn ProfileIdentity::opaque(profile : OpaqueProfile) -> ProfileIdentity {
  { builtin_srgb_value: false, opaque_profile_value: Some(profile) }
}

///|
pub fn ProfileIdentity::is_builtin_srgb(self : ProfileIdentity) -> Bool {
  self.builtin_srgb_value
}

///|
pub fn ProfileIdentity::opaque_profile(
  self : ProfileIdentity,
) -> OpaqueProfile? {
  self.opaque_profile_value
}
