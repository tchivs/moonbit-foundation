///|
enum NormalizedRgb {
  Encoded(
    @model.EncodedSrgbComponent,
    @model.EncodedSrgbComponent,
    @model.EncodedSrgbComponent
  )
  Linear(
    @model.LinearSrgbComponent,
    @model.LinearSrgbComponent,
    @model.LinearSrgbComponent
  )
}

///|
fn premultiplied_range_error(
  operation : String,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation~,
    context~,
  )
}

///|
fn validate_normalized_premultiplied(
  r : Double,
  g : Double,
  b : Double,
  alpha : Double,
  operation : String,
  prefix : String,
) -> Result[Unit, @error.CoreError] {
  if r > alpha {
    Err(premultiplied_range_error(operation, prefix + "-r"))
  } else if g > alpha {
    Err(premultiplied_range_error(operation, prefix + "-g"))
  } else if b > alpha {
    Err(premultiplied_range_error(operation, prefix + "-b"))
  } else {
    Ok(())
  }
}

///|
fn validate_encoded_premultiplied(
  r : @model.EncodedSrgb8Component,
  g : @model.EncodedSrgb8Component,
  b : @model.EncodedSrgb8Component,
  alpha : @model.EncodedAlpha8,
) -> Result[Unit, @error.CoreError] {
  let limit = alpha.value().to_uint64()
  let r_value = r.value().to_uint64()
  let g_value = g.value().to_uint64()
  let b_value = b.value().to_uint64()
  if r_value > limit {
    Err(
      @error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        operation="PremultipliedEncodedSrgba8::new",
        requested=r_value,
        limit~,
        context="premultiplied-encoded-r",
      ),
    )
  } else if g_value > limit {
    Err(
      @error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        operation="PremultipliedEncodedSrgba8::new",
        requested=g_value,
        limit~,
        context="premultiplied-encoded-g",
      ),
    )
  } else if b_value > limit {
    Err(
      @error.CoreError::new(
        @error.ErrorCategory::InvalidInput,
        @error.ErrorCode::InvalidRange,
        operation="PremultipliedEncodedSrgba8::new",
        requested=b_value,
        limit~,
        context="premultiplied-encoded-b",
      ),
    )
  } else {
    Ok(())
  }
}

///|
pub struct StraightNormalizedSrgba {
  priv rgb : NormalizedRgb
  priv alpha_value : @model.NormalizedAlpha
}

///|
pub fn StraightNormalizedSrgba::encoded(
  r : @model.EncodedSrgbComponent,
  g : @model.EncodedSrgbComponent,
  b : @model.EncodedSrgbComponent,
  alpha : @model.NormalizedAlpha,
) -> StraightNormalizedSrgba {
  { rgb: Encoded(r, g, b), alpha_value: alpha }
}

///|
pub fn StraightNormalizedSrgba::linear(
  r : @model.LinearSrgbComponent,
  g : @model.LinearSrgbComponent,
  b : @model.LinearSrgbComponent,
  alpha : @model.NormalizedAlpha,
) -> StraightNormalizedSrgba {
  { rgb: Linear(r, g, b), alpha_value: alpha }
}

///|
pub fn StraightNormalizedSrgba::encoded_rgb(
  self : StraightNormalizedSrgba,
) -> (
  @model.EncodedSrgbComponent,
  @model.EncodedSrgbComponent,
  @model.EncodedSrgbComponent,
)? {
  match self.rgb {
    Encoded(r, g, b) => Some((r, g, b))
    Linear(_, _, _) => None
  }
}

///|
pub fn StraightNormalizedSrgba::linear_rgb(
  self : StraightNormalizedSrgba,
) -> (
  @model.LinearSrgbComponent,
  @model.LinearSrgbComponent,
  @model.LinearSrgbComponent,
)? {
  match self.rgb {
    Linear(r, g, b) => Some((r, g, b))
    Encoded(_, _, _) => None
  }
}

///|
pub fn StraightNormalizedSrgba::alpha(
  self : StraightNormalizedSrgba,
) -> @model.NormalizedAlpha {
  self.alpha_value
}

///|
pub fn StraightNormalizedSrgba::space(
  _self : StraightNormalizedSrgba,
) -> @model.ColorSpaceIdentity {
  @model.ColorSpaceIdentity::Srgb
}

///|
pub fn StraightNormalizedSrgba::transfer(
  self : StraightNormalizedSrgba,
) -> @model.TransferIdentity {
  match self.rgb {
    Encoded(_, _, _) => @model.TransferIdentity::EncodedSrgb
    Linear(_, _, _) => @model.TransferIdentity::LinearSrgb
  }
}

///|
pub fn StraightNormalizedSrgba::representation(
  _self : StraightNormalizedSrgba,
) -> @model.ComponentRepresentation {
  @model.ComponentRepresentation::NormalizedDouble
}

///|
pub fn StraightNormalizedSrgba::alpha_mode(
  _self : StraightNormalizedSrgba,
) -> @model.AlphaMode {
  @model.AlphaMode::Straight
}

///|
pub struct PremultipliedNormalizedSrgba {
  priv rgb : NormalizedRgb
  priv alpha_value : @model.NormalizedAlpha
}

///|
pub fn PremultipliedNormalizedSrgba::encoded(
  r : @model.EncodedSrgbComponent,
  g : @model.EncodedSrgbComponent,
  b : @model.EncodedSrgbComponent,
  alpha : @model.NormalizedAlpha,
) -> Result[PremultipliedNormalizedSrgba, @error.CoreError] {
  match
    validate_normalized_premultiplied(
      r.value(),
      g.value(),
      b.value(),
      alpha.value(),
      "PremultipliedNormalizedSrgba::encoded",
      "premultiplied-encoded",
    ) {
    Err(error) => Err(error)
    Ok(_) => Ok({ rgb: Encoded(r, g, b), alpha_value: alpha })
  }
}

///|
pub fn PremultipliedNormalizedSrgba::linear(
  r : @model.LinearSrgbComponent,
  g : @model.LinearSrgbComponent,
  b : @model.LinearSrgbComponent,
  alpha : @model.NormalizedAlpha,
) -> Result[PremultipliedNormalizedSrgba, @error.CoreError] {
  match
    validate_normalized_premultiplied(
      r.value(),
      g.value(),
      b.value(),
      alpha.value(),
      "PremultipliedNormalizedSrgba::linear",
      "premultiplied-linear",
    ) {
    Err(error) => Err(error)
    Ok(_) => Ok({ rgb: Linear(r, g, b), alpha_value: alpha })
  }
}

///|
pub fn PremultipliedNormalizedSrgba::encoded_rgb(
  self : PremultipliedNormalizedSrgba,
) -> (
  @model.EncodedSrgbComponent,
  @model.EncodedSrgbComponent,
  @model.EncodedSrgbComponent,
)? {
  match self.rgb {
    Encoded(r, g, b) => Some((r, g, b))
    Linear(_, _, _) => None
  }
}

///|
pub fn PremultipliedNormalizedSrgba::linear_rgb(
  self : PremultipliedNormalizedSrgba,
) -> (
  @model.LinearSrgbComponent,
  @model.LinearSrgbComponent,
  @model.LinearSrgbComponent,
)? {
  match self.rgb {
    Linear(r, g, b) => Some((r, g, b))
    Encoded(_, _, _) => None
  }
}

///|
pub fn PremultipliedNormalizedSrgba::alpha(
  self : PremultipliedNormalizedSrgba,
) -> @model.NormalizedAlpha {
  self.alpha_value
}

///|
pub fn PremultipliedNormalizedSrgba::space(
  _self : PremultipliedNormalizedSrgba,
) -> @model.ColorSpaceIdentity {
  @model.ColorSpaceIdentity::Srgb
}

///|
pub fn PremultipliedNormalizedSrgba::transfer(
  self : PremultipliedNormalizedSrgba,
) -> @model.TransferIdentity {
  match self.rgb {
    Encoded(_, _, _) => @model.TransferIdentity::EncodedSrgb
    Linear(_, _, _) => @model.TransferIdentity::LinearSrgb
  }
}

///|
pub fn PremultipliedNormalizedSrgba::representation(
  _self : PremultipliedNormalizedSrgba,
) -> @model.ComponentRepresentation {
  @model.ComponentRepresentation::NormalizedDouble
}

///|
pub fn PremultipliedNormalizedSrgba::alpha_mode(
  _self : PremultipliedNormalizedSrgba,
) -> @model.AlphaMode {
  @model.AlphaMode::Premultiplied
}

///|
pub fn premultiply_normalized(
  value : StraightNormalizedSrgba,
) -> Result[PremultipliedNormalizedSrgba, @error.CoreError] {
  let alpha = value.alpha_value
  let coverage = alpha.value()
  match value.rgb {
    Encoded(r, g, b) => {
      let red = @model.EncodedSrgbComponent::new(r.value() * coverage).unwrap()
      let green = @model.EncodedSrgbComponent::new(g.value() * coverage).unwrap()
      let blue = @model.EncodedSrgbComponent::new(b.value() * coverage).unwrap()
      PremultipliedNormalizedSrgba::encoded(red, green, blue, alpha)
    }
    Linear(r, g, b) => {
      let red = @model.LinearSrgbComponent::new(r.value() * coverage).unwrap()
      let green = @model.LinearSrgbComponent::new(g.value() * coverage).unwrap()
      let blue = @model.LinearSrgbComponent::new(b.value() * coverage).unwrap()
      PremultipliedNormalizedSrgba::linear(red, green, blue, alpha)
    }
  }
}

///|
pub fn unpremultiply_normalized(
  value : PremultipliedNormalizedSrgba,
) -> Result[StraightNormalizedSrgba, @error.CoreError] {
  let alpha = value.alpha_value
  let coverage = alpha.value()
  match value.rgb {
    Encoded(r, g, b) => {
      let red = @model.EncodedSrgbComponent::new(
        if coverage == 0.0 {
          0.0
        } else {
          r.value() / coverage
        },
      ).unwrap()
      let green = @model.EncodedSrgbComponent::new(
        if coverage == 0.0 {
          0.0
        } else {
          g.value() / coverage
        },
      ).unwrap()
      let blue = @model.EncodedSrgbComponent::new(
        if coverage == 0.0 {
          0.0
        } else {
          b.value() / coverage
        },
      ).unwrap()
      Ok(StraightNormalizedSrgba::encoded(red, green, blue, alpha))
    }
    Linear(r, g, b) => {
      let red = @model.LinearSrgbComponent::new(
        if coverage == 0.0 {
          0.0
        } else {
          r.value() / coverage
        },
      ).unwrap()
      let green = @model.LinearSrgbComponent::new(
        if coverage == 0.0 {
          0.0
        } else {
          g.value() / coverage
        },
      ).unwrap()
      let blue = @model.LinearSrgbComponent::new(
        if coverage == 0.0 {
          0.0
        } else {
          b.value() / coverage
        },
      ).unwrap()
      Ok(StraightNormalizedSrgba::linear(red, green, blue, alpha))
    }
  }
}

///|
pub struct StraightEncodedSrgba8 {
  priv red : @model.EncodedSrgb8Component
  priv green : @model.EncodedSrgb8Component
  priv blue : @model.EncodedSrgb8Component
  priv alpha_value : @model.EncodedAlpha8
}

///|
pub fn StraightEncodedSrgba8::new(
  r : @model.EncodedSrgb8Component,
  g : @model.EncodedSrgb8Component,
  b : @model.EncodedSrgb8Component,
  a : @model.EncodedAlpha8,
) -> StraightEncodedSrgba8 {
  { red: r, green: g, blue: b, alpha_value: a }
}

///|
pub fn StraightEncodedSrgba8::r(
  self : StraightEncodedSrgba8,
) -> @model.EncodedSrgb8Component {
  self.red
}

///|
pub fn StraightEncodedSrgba8::g(
  self : StraightEncodedSrgba8,
) -> @model.EncodedSrgb8Component {
  self.green
}

///|
pub fn StraightEncodedSrgba8::b(
  self : StraightEncodedSrgba8,
) -> @model.EncodedSrgb8Component {
  self.blue
}

///|
pub fn StraightEncodedSrgba8::a(
  self : StraightEncodedSrgba8,
) -> @model.EncodedAlpha8 {
  self.alpha_value
}

///|
pub fn StraightEncodedSrgba8::space(
  _self : StraightEncodedSrgba8,
) -> @model.ColorSpaceIdentity {
  @model.ColorSpaceIdentity::Srgb
}

///|
pub fn StraightEncodedSrgba8::transfer(
  _self : StraightEncodedSrgba8,
) -> @model.TransferIdentity {
  @model.TransferIdentity::EncodedSrgb
}

///|
pub fn StraightEncodedSrgba8::representation(
  _self : StraightEncodedSrgba8,
) -> @model.ComponentRepresentation {
  @model.ComponentRepresentation::Encoded8
}

///|
pub fn StraightEncodedSrgba8::alpha_mode(
  _self : StraightEncodedSrgba8,
) -> @model.AlphaMode {
  @model.AlphaMode::Straight
}

///|
pub struct PremultipliedEncodedSrgba8 {
  priv red : @model.EncodedSrgb8Component
  priv green : @model.EncodedSrgb8Component
  priv blue : @model.EncodedSrgb8Component
  priv alpha_value : @model.EncodedAlpha8
}

///|
pub fn PremultipliedEncodedSrgba8::new(
  r : @model.EncodedSrgb8Component,
  g : @model.EncodedSrgb8Component,
  b : @model.EncodedSrgb8Component,
  a : @model.EncodedAlpha8,
) -> Result[PremultipliedEncodedSrgba8, @error.CoreError] {
  match validate_encoded_premultiplied(r, g, b, a) {
    Err(error) => Err(error)
    Ok(_) => Ok({ red: r, green: g, blue: b, alpha_value: a })
  }
}

///|
pub fn PremultipliedEncodedSrgba8::r(
  self : PremultipliedEncodedSrgba8,
) -> @model.EncodedSrgb8Component {
  self.red
}

///|
pub fn PremultipliedEncodedSrgba8::g(
  self : PremultipliedEncodedSrgba8,
) -> @model.EncodedSrgb8Component {
  self.green
}

///|
pub fn PremultipliedEncodedSrgba8::b(
  self : PremultipliedEncodedSrgba8,
) -> @model.EncodedSrgb8Component {
  self.blue
}

///|
pub fn PremultipliedEncodedSrgba8::a(
  self : PremultipliedEncodedSrgba8,
) -> @model.EncodedAlpha8 {
  self.alpha_value
}

///|
pub fn PremultipliedEncodedSrgba8::space(
  _self : PremultipliedEncodedSrgba8,
) -> @model.ColorSpaceIdentity {
  @model.ColorSpaceIdentity::Srgb
}

///|
pub fn PremultipliedEncodedSrgba8::transfer(
  _self : PremultipliedEncodedSrgba8,
) -> @model.TransferIdentity {
  @model.TransferIdentity::EncodedSrgb
}

///|
pub fn PremultipliedEncodedSrgba8::representation(
  _self : PremultipliedEncodedSrgba8,
) -> @model.ComponentRepresentation {
  @model.ComponentRepresentation::Encoded8
}

///|
pub fn PremultipliedEncodedSrgba8::alpha_mode(
  _self : PremultipliedEncodedSrgba8,
) -> @model.AlphaMode {
  @model.AlphaMode::Premultiplied
}

///|
fn round_encoded_component(
  value : @model.EncodedSrgb8Component,
  multiplier : UInt64,
  denominator : UInt64,
) -> Result[@model.EncodedSrgb8Component, @error.CoreError] {
  match @checked.checked_mul(value.value().to_uint64(), multiplier) {
    Err(error) => Err(error)
    Ok(numerator) =>
      match @quantize.round_ratio_ties_even(numerator, denominator) {
        Err(error) => Err(error)
        Ok(rounded) => @model.EncodedSrgb8Component::new(rounded)
      }
  }
}

///|
pub fn premultiply_encoded(
  value : StraightEncodedSrgba8,
) -> Result[PremultipliedEncodedSrgba8, @error.CoreError] {
  let coverage = value.alpha_value.value().to_uint64()
  match round_encoded_component(value.red, coverage, 255UL) {
    Err(error) => Err(error)
    Ok(red) =>
      match round_encoded_component(value.green, coverage, 255UL) {
        Err(error) => Err(error)
        Ok(green) =>
          match round_encoded_component(value.blue, coverage, 255UL) {
            Err(error) => Err(error)
            Ok(blue) =>
              PremultipliedEncodedSrgba8::new(
                red,
                green,
                blue,
                value.alpha_value,
              )
          }
      }
  }
}

///|
pub fn unpremultiply_encoded(
  value : PremultipliedEncodedSrgba8,
) -> Result[StraightEncodedSrgba8, @error.CoreError] {
  let coverage = value.alpha_value.value().to_uint64()
  if coverage == 0UL {
    let zero = @model.EncodedSrgb8Component::from_byte(0)
    Ok(StraightEncodedSrgba8::new(zero, zero, zero, value.alpha_value))
  } else {
    match round_encoded_component(value.red, 255UL, coverage) {
      Err(error) => Err(error)
      Ok(red) =>
        match round_encoded_component(value.green, 255UL, coverage) {
          Err(error) => Err(error)
          Ok(green) =>
            match round_encoded_component(value.blue, 255UL, coverage) {
              Err(error) => Err(error)
              Ok(blue) =>
                Ok(
                  StraightEncodedSrgba8::new(
                    red,
                    green,
                    blue,
                    value.alpha_value,
                  ),
                )
            }
        }
    }
  }
}
