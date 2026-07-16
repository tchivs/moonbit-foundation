///|
fn encoded(value : Double) -> @model.EncodedSrgbComponent {
  @model.EncodedSrgbComponent::new(value).unwrap()
}

///|
fn linear(value : Double) -> @model.LinearSrgbComponent {
  @model.LinearSrgbComponent::new(value).unwrap()
}

///|
fn alpha(value : Double) -> @model.NormalizedAlpha {
  @model.NormalizedAlpha::new(value).unwrap()
}

///|
fn encoded8(value : Int) -> @model.EncodedSrgb8Component {
  @model.EncodedSrgb8Component::new(value.to_uint64()).unwrap()
}

///|
fn alpha8(value : Int) -> @model.EncodedAlpha8 {
  @model.EncodedAlpha8::new(value.to_uint64()).unwrap()
}

///|
test "normalized alpha states preserve explicit domain and identity" {
  let straight_encoded = @alpha.StraightNormalizedSrgba::encoded(
    encoded(0.25), encoded(0.5), encoded(0.75), alpha(0.5),
  )
  inspect(straight_encoded.space() == @model.ColorSpaceIdentity::Srgb, content="true")
  inspect(straight_encoded.transfer() == @model.TransferIdentity::EncodedSrgb, content="true")
  inspect(straight_encoded.representation() == @model.ComponentRepresentation::NormalizedDouble, content="true")
  inspect(straight_encoded.alpha_mode() == @model.AlphaMode::Straight, content="true")
  inspect(straight_encoded.alpha().value(), content="0.5")
  match straight_encoded.encoded_rgb() {
    Some((r, g, b)) => {
      inspect(r.value(), content="0.25")
      inspect(g.value(), content="0.5")
      inspect(b.value(), content="0.75")
    }
    None => fail("encoded constructor must expose encoded components")
  }
  inspect(straight_encoded.linear_rgb().is_none(), content="true")

  let straight_linear = @alpha.StraightNormalizedSrgba::linear(
    linear(0.25), linear(0.5), linear(0.75), alpha(0.5),
  )
  inspect(straight_linear.transfer() == @model.TransferIdentity::LinearSrgb, content="true")
  inspect(straight_linear.encoded_rgb().is_none(), content="true")
  match straight_linear.linear_rgb() {
    Some((r, _, _)) => inspect(r.value(), content="0.25")
    None => fail("linear constructor must expose linear components")
  }
}

///|
test "premultiplied normalized constructors reject p greater than alpha" {
  for result in [
    @alpha.PremultipliedNormalizedSrgba::encoded(encoded(0.6), encoded(0.1), encoded(0.1), alpha(0.5)),
    @alpha.PremultipliedNormalizedSrgba::encoded(encoded(0.1), encoded(0.6), encoded(0.1), alpha(0.5)),
    @alpha.PremultipliedNormalizedSrgba::encoded(encoded(0.1), encoded(0.1), encoded(0.6), alpha(0.5)),
  ] {
    match result {
      Err(error) => inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      Ok(_) => fail("each encoded channel greater than alpha must be rejected")
    }
  }
  match @alpha.PremultipliedNormalizedSrgba::linear(
    linear(0.01), linear(0.0), linear(0.0), alpha(0.0),
  ) {
    Err(error) => inspect(error.context() == Some("premultiplied-linear-r"), content="true")
    Ok(_) => fail("noncanonical zero-alpha linear state must be rejected")
  }
}

///|
test "normalized conversions canonicalize zero and preserve transfer domain" {
  let encoded_zero = @alpha.premultiply_normalized(
    @alpha.StraightNormalizedSrgba::encoded(encoded(1.0), encoded(0.5), encoded(0.25), alpha(0.0)),
  ).unwrap()
  match encoded_zero.encoded_rgb() {
    Some((r, g, b)) => inspect((r.value(), g.value(), b.value()), content="(0, 0, 0)")
    None => fail("encoded transfer identity must be preserved")
  }
  let linear_zero = @alpha.unpremultiply_normalized(
    @alpha.PremultipliedNormalizedSrgba::linear(linear(0.0), linear(0.0), linear(0.0), alpha(0.0)).unwrap(),
  ).unwrap()
  match linear_zero.linear_rgb() {
    Some((r, g, b)) => inspect((r.value(), g.value(), b.value()), content="(0, 0, 0)")
    None => fail("linear transfer identity must be preserved")
  }
}

///|
test "encoded states expose typed components and fixed identities" {
  let straight = @alpha.StraightEncodedSrgba8::new(encoded8(1), encoded8(2), encoded8(3), alpha8(254))
  inspect(straight.r().value().to_uint64(), content="1")
  inspect(straight.g().value().to_uint64(), content="2")
  inspect(straight.b().value().to_uint64(), content="3")
  inspect(straight.a().value().to_uint64(), content="254")
  inspect(straight.space() == @model.ColorSpaceIdentity::Srgb, content="true")
  inspect(straight.transfer() == @model.TransferIdentity::EncodedSrgb, content="true")
  inspect(straight.representation() == @model.ComponentRepresentation::Encoded8, content="true")
  inspect(straight.alpha_mode() == @model.AlphaMode::Straight, content="true")
}

///|
test "encoded premultiplied constructor rejects every p greater than a" {
  for result in [
    @alpha.PremultipliedEncodedSrgba8::new(encoded8(2), encoded8(1), encoded8(1), alpha8(1)),
    @alpha.PremultipliedEncodedSrgba8::new(encoded8(1), encoded8(2), encoded8(1), alpha8(1)),
    @alpha.PremultipliedEncodedSrgba8::new(encoded8(1), encoded8(1), encoded8(2), alpha8(1)),
    @alpha.PremultipliedEncodedSrgba8::new(encoded8(1), encoded8(0), encoded8(0), alpha8(0)),
  ] {
    match result {
      Err(error) => inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      Ok(_) => fail("invalid premultiplied encoded state must not be repaired")
    }
  }
}

///|
test "encoded conversions cover alpha boundaries ties and exact identities" {
  for a in [0, 1, 254, 255] {
    let straight = @alpha.StraightEncodedSrgba8::new(encoded8(255), encoded8(128), encoded8(1), alpha8(a))
    let premultiplied = @alpha.premultiply_encoded(straight).unwrap()
    inspect(premultiplied.a().value().to_uint64() == a.to_uint64(), content="true")
    if a == 0 {
      inspect((premultiplied.r().value().to_uint64(), premultiplied.g().value().to_uint64(), premultiplied.b().value().to_uint64()), content="(0, 0, 0)")
    }
  }
  let full = @alpha.StraightEncodedSrgba8::new(encoded8(17), encoded8(128), encoded8(255), alpha8(255))
  let full_roundtrip = @alpha.unpremultiply_encoded(@alpha.premultiply_encoded(full).unwrap()).unwrap()
  inspect((full_roundtrip.r().value().to_uint64(), full_roundtrip.g().value().to_uint64(), full_roundtrip.b().value().to_uint64()), content="(17, 128, 255)")
  inspect(@alpha.premultiply_encoded(@alpha.StraightEncodedSrgba8::new(encoded8(128), encoded8(0), encoded8(0), alpha8(254))).unwrap().r().value().to_uint64(), content="127")
}
