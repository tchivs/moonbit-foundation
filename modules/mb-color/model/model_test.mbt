///|
fn require_encoded(_value : @model.EncodedSrgbComponent) -> Unit {
  ()
}

///|
fn require_linear(_value : @model.LinearSrgbComponent) -> Unit {
  ()
}

///|
test "normalized color components preserve explicit semantic identity" {
  let encoded = match @model.EncodedSrgbComponent::new(1.0 / 255.0) {
    Ok(value) => value
    Err(_) => fail("encoded sRGB interior value must construct")
  }
  let linear = match @model.LinearSrgbComponent::new(0.5) {
    Ok(value) => value
    Err(_) => fail("linear sRGB interior value must construct")
  }
  require_encoded(encoded)
  require_linear(linear)
  inspect(encoded.value() == 1.0 / 255.0, content="true")
  inspect(encoded.space() == @model.ColorSpaceIdentity::Srgb, content="true")
  inspect(
    encoded.transfer() == @model.TransferIdentity::EncodedSrgb,
    content="true",
  )
  inspect(
    encoded.representation() == @model.ComponentRepresentation::NormalizedDouble,
    content="true",
  )
  inspect(linear.value() == 0.5, content="true")
  inspect(linear.space() == @model.ColorSpaceIdentity::Srgb, content="true")
  inspect(
    linear.transfer() == @model.TransferIdentity::LinearSrgb,
    content="true",
  )
  inspect(
    linear.representation() == @model.ComponentRepresentation::NormalizedDouble,
    content="true",
  )
}

///|
test "normalized domains accept closed endpoints and preserve alpha identity" {
  let encoded_zero = @model.EncodedSrgbComponent::new(0.0)
  let encoded_one = @model.EncodedSrgbComponent::new(1.0)
  let linear_zero = @model.LinearSrgbComponent::new(0.0)
  let linear_one = @model.LinearSrgbComponent::new(1.0)
  let alpha_zero = @model.NormalizedAlpha::new(0.0)
  let alpha_one = @model.NormalizedAlpha::new(1.0)
  inspect(encoded_zero is Ok(_), content="true")
  inspect(encoded_one is Ok(_), content="true")
  inspect(linear_zero is Ok(_), content="true")
  inspect(linear_one is Ok(_), content="true")
  inspect(alpha_zero is Ok(_), content="true")
  match alpha_one {
    Ok(alpha) => inspect(alpha.value() == 1.0, content="true")
    Err(_) => fail("normalized alpha endpoint must construct")
  }
}

///|
fn assert_normalized_rejection(
  result : Result[@model.EncodedSrgbComponent, @error.CoreError],
  context : String,
) -> Bool {
  match result {
    Err(error) =>
      error.category() == @error.ErrorCategory::InvalidInput &&
      error.code() == @error.ErrorCode::InvalidRange &&
      error.context() == Some(context)
    Ok(_) => false
  }
}

///|
test "non-finite and out-of-range normalized values are rejected without clamping" {
  let nan = 0.0 / 0.0
  let infinity = 1.0 / 0.0
  let neg_infinity = -1.0 / 0.0
  inspect(
    assert_normalized_rejection(
      @model.EncodedSrgbComponent::new(nan),
      "encoded-srgb-component",
    ),
    content="true",
  )
  inspect(
    assert_normalized_rejection(
      @model.EncodedSrgbComponent::new(infinity),
      "encoded-srgb-component",
    ),
    content="true",
  )
  inspect(
    assert_normalized_rejection(
      @model.EncodedSrgbComponent::new(neg_infinity),
      "encoded-srgb-component",
    ),
    content="true",
  )
  inspect(
    assert_normalized_rejection(
      @model.EncodedSrgbComponent::new(-0.000001),
      "encoded-srgb-component",
    ),
    content="true",
  )
  inspect(
    assert_normalized_rejection(
      @model.EncodedSrgbComponent::new(1.000001),
      "encoded-srgb-component",
    ),
    content="true",
  )
  inspect(
    @model.LinearSrgbComponent::new(nan) is Err(_),
    content="true",
  )
  inspect(@model.LinearSrgbComponent::new(-1.0) is Err(_), content="true")
  inspect(@model.NormalizedAlpha::new(infinity) is Err(_), content="true")
  inspect(@model.NormalizedAlpha::new(2.0) is Err(_), content="true")
}

///|
test "encoded eight-bit components validate before narrowing" {
  let zero = match @model.EncodedSrgb8Component::new(0UL) {
    Ok(value) => value
    Err(_) => fail("encoded zero must construct")
  }
  let maximum = match @model.EncodedSrgb8Component::new(255UL) {
    Ok(value) => value
    Err(_) => fail("encoded maximum must construct")
  }
  let from_byte = @model.EncodedSrgb8Component::from_byte(17UL.to_byte())
  inspect(zero.value().to_uint64(), content="0")
  inspect(maximum.value().to_uint64(), content="255")
  inspect(from_byte.value().to_uint64(), content="17")
  inspect(maximum.space() == @model.ColorSpaceIdentity::Srgb, content="true")
  inspect(
    maximum.transfer() == @model.TransferIdentity::EncodedSrgb,
    content="true",
  )
  inspect(
    maximum.representation() == @model.ComponentRepresentation::Encoded8,
    content="true",
  )
  inspect(@model.EncodedSrgb8Component::new(256UL) is Err(_), content="true")
  inspect(
    @model.EncodedSrgb8Component::new(18446744073709551615UL) is Err(_),
    content="true",
  )
}

///|
test "encoded alpha is distinct from color transfer identity" {
  let alpha = match @model.EncodedAlpha8::new(255UL) {
    Ok(value) => value
    Err(_) => fail("encoded alpha maximum must construct")
  }
  let from_byte = @model.EncodedAlpha8::from_byte(1UL.to_byte())
  inspect(alpha.value().to_uint64(), content="255")
  inspect(from_byte.value().to_uint64(), content="1")
  inspect(@model.EncodedAlpha8::new(256UL) is Err(_), content="true")
  inspect(
    @model.EncodedAlpha8::new(18446744073709551615UL) is Err(_),
    content="true",
  )
}

///|
test "closed identity vocabulary names every supported state" {
  inspect(@model.ColorSpaceIdentity::Srgb == @model.ColorSpaceIdentity::Srgb, content="true")
  inspect(
    @model.TransferIdentity::EncodedSrgb != @model.TransferIdentity::LinearSrgb,
    content="true",
  )
  inspect(
    @model.ComponentRepresentation::NormalizedDouble !=
      @model.ComponentRepresentation::Encoded8,
    content="true",
  )
  inspect(@model.AlphaMode::Straight != @model.AlphaMode::Premultiplied, content="true")
}
