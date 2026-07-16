///|
fn encoded(value : Double) -> @model.EncodedSrgbComponent {
  @model.EncodedSrgbComponent::new(value).unwrap()
}

///|
fn alpha(value : Double) -> @model.NormalizedAlpha {
  @model.NormalizedAlpha::new(value).unwrap()
}

///|
fn require_encoded8(_value : @model.EncodedSrgb8Component) -> Unit {
  ()
}

///|
fn require_alpha8(_value : @model.EncodedAlpha8) -> Unit {
  ()
}

///|
test "quantize keeps encoded sRGB and alpha domains distinct" {
  let color = @quantize.quantize_encoded_srgb(encoded(0.5))
  let coverage = @quantize.quantize_alpha(alpha(0.5))
  require_encoded8(color)
  require_alpha8(coverage)
  inspect(
    color.transfer() == @model.TransferIdentity::EncodedSrgb,
    content="true",
  )
  inspect(
    color.representation() == @model.ComponentRepresentation::Encoded8,
    content="true",
  )
}

///|
test "quantize maps endpoints without saturation" {
  inspect(
    @quantize.quantize_encoded_srgb(encoded(0.0)).value().to_uint64(),
    content="0",
  )
  inspect(
    @quantize.quantize_encoded_srgb(encoded(1.0)).value().to_uint64(),
    content="255",
  )
  inspect(@quantize.quantize_alpha(alpha(0.0)).value().to_uint64(), content="0")
  inspect(
    @quantize.quantize_alpha(alpha(1.0)).value().to_uint64(),
    content="255",
  )
}

///|
test "dequantize and requantize preserve all encoded codes" {
  for code = 0; code < 256; code = code + 1 {
    let color = @model.EncodedSrgb8Component::new(code.to_uint64()).unwrap()
    let coverage = @model.EncodedAlpha8::new(code.to_uint64()).unwrap()
    let normalized_color = @quantize.dequantize_encoded_srgb(color)
    let normalized_alpha = @quantize.dequantize_alpha(coverage)
    inspect(
      @quantize.quantize_encoded_srgb(normalized_color).value().to_uint64() ==
      code.to_uint64(),
      content="true",
    )
    inspect(
      @quantize.quantize_alpha(normalized_alpha).value().to_uint64() ==
      code.to_uint64(),
      content="true",
    )
    inspect(
      (normalized_color.value() - code.to_double() / 255.0).abs() <= 0.5 / 255.0,
      content="true",
    )
    inspect(
      (normalized_alpha.value() - code.to_double() / 255.0).abs() <= 0.5 / 255.0,
      content="true",
    )
  }
}

///|
test "public exact ratio helper rejects invalid arithmetic" {
  let zero = @quantize.round_ratio_ties_even(1UL, 0UL)
  match zero {
    Err(error) => {
      inspect(
        error.category() == @error.ErrorCategory::InvalidInput,
        content="true",
      )
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    }
    Ok(_) => fail("zero denominator must be rejected")
  }
  let overflow = @quantize.round_ratio_ties_even(
    18446744073709551614UL, 18446744073709551615UL,
  )
  match overflow {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("twice-remainder overflow must be rejected")
  }
}
