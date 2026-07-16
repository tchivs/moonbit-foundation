///|
fn round_scaled_ties_even(scaled : Double) -> UInt64 {
  let lower = scaled.floor().to_int()
  let fraction = scaled - lower.to_double()
  let rounded = if fraction < 0.5 {
    lower
  } else if fraction > 0.5 {
    lower + 1
  } else if lower % 2 == 0 {
    lower
  } else {
    lower + 1
  }
  rounded.to_uint64()
}

///|
fn invalid_ratio_denominator() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation="round_ratio_ties_even",
    requested=0UL,
    limit=1UL,
    context="ratio-denominator",
  )
}

///|
/// Round an exact nonnegative integer ratio to nearest, with halfway values
/// resolved to the even quotient.
///
/// Zero denominators and an overflowing twice-remainder are structured errors.
/// The decision is completed in UInt64 before any caller narrows the result.
pub fn round_ratio_ties_even(
  numerator : UInt64,
  denominator : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if denominator == 0UL {
    return Err(invalid_ratio_denominator())
  }
  let quotient = numerator / denominator
  let remainder = numerator % denominator
  match @checked.checked_mul(remainder, 2UL) {
    Err(error) => Err(error)
    Ok(twice_remainder) =>
      if twice_remainder < denominator {
        Ok(quotient)
      } else if twice_remainder > denominator {
        Ok(quotient + 1UL)
      } else if quotient % 2UL == 0UL {
        Ok(quotient)
      } else {
        Ok(quotient + 1UL)
      }
  }
}

///|
/// Quantize a validated normalized encoded-sRGB component to its encoded byte.
///
/// This operation never clamps and never delegates halfway policy to a cast or
/// backend rounding function.
pub fn quantize_encoded_srgb(
  component : @model.EncodedSrgbComponent,
) -> @model.EncodedSrgb8Component {
  let rounded = round_scaled_ties_even(component.value() * 255.0)
  @model.EncodedSrgb8Component::from_byte(rounded.to_byte())
}

///|
/// Recover the normalized encoded-sRGB value represented by an encoded byte.
pub fn dequantize_encoded_srgb(
  component : @model.EncodedSrgb8Component,
) -> @model.EncodedSrgbComponent {
  @model.EncodedSrgbComponent::new(
    component.value().to_uint64().to_double() / 255.0,
  ).unwrap()
}

///|
/// Quantize validated normalized alpha coverage to its distinct encoded byte.
pub fn quantize_alpha(alpha : @model.NormalizedAlpha) -> @model.EncodedAlpha8 {
  let rounded = round_scaled_ties_even(alpha.value() * 255.0)
  @model.EncodedAlpha8::from_byte(rounded.to_byte())
}

///|
/// Recover normalized alpha coverage from its distinct encoded byte.
pub fn dequantize_alpha(alpha : @model.EncodedAlpha8) -> @model.NormalizedAlpha {
  @model.NormalizedAlpha::new(alpha.value().to_uint64().to_double() / 255.0).unwrap()
}
