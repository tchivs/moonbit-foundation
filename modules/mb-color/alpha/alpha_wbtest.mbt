///|
fn encoded8_internal(value : Int) -> @model.EncodedSrgb8Component {
  @model.EncodedSrgb8Component::new(value.to_uint64()).unwrap()
}

///|
fn alpha8_internal(value : Int) -> @model.EncodedAlpha8 {
  @model.EncodedAlpha8::new(value.to_uint64()).unwrap()
}

///|
test "generated alpha vectors match exact ties-even conversions" {
  for vector in generated_alpha_vectors() {
    let (component, coverage, premultiplied, recovered) = vector
    let straight = StraightEncodedSrgba8::new(
      encoded8_internal(component),
      encoded8_internal(0),
      encoded8_internal(0),
      alpha8_internal(coverage),
    )
    let p = premultiply_encoded(straight).unwrap()
    inspect(
      p.r().value().to_uint64() == premultiplied.to_uint64(),
      content="true",
    )
    let u = unpremultiply_encoded(p).unwrap()
    inspect(u.r().value().to_uint64() == recovered.to_uint64(), content="true")
  }
}

///|
test "exhaustive encoded pairs establish directional identities and bounds" {
  let mut maximum_nonzero_straight_pair_error = 0
  for coverage = 0; coverage < 256; coverage = coverage + 1 {
    for component = 0; component < 256; component = component + 1 {
      let straight = StraightEncodedSrgba8::new(
        encoded8_internal(component),
        encoded8_internal(0),
        encoded8_internal(0),
        alpha8_internal(coverage),
      )
      let p = premultiply_encoded(straight).unwrap()
      let u = unpremultiply_encoded(p).unwrap()
      let recovered = u.r().value().to_uint64().to_int()
      let error = (recovered - component).abs()
      if coverage > 0 && error > maximum_nonzero_straight_pair_error {
        maximum_nonzero_straight_pair_error = error
      }
      inspect(p.r().value().to_uint64() <= coverage.to_uint64(), content="true")
      if coverage == 0 {
        inspect(recovered, content="0")
      }
    }
    for premultiplied = 0
        premultiplied <= coverage
        premultiplied = premultiplied + 1 {
      let p = PremultipliedEncodedSrgba8::new(
        encoded8_internal(premultiplied),
        encoded8_internal(0),
        encoded8_internal(0),
        alpha8_internal(coverage),
      ).unwrap()
      let p_again = premultiply_encoded(unpremultiply_encoded(p).unwrap()).unwrap()
      inspect(p_again.r().value() == p.r().value(), content="true")
    }
  }
  inspect(maximum_nonzero_straight_pair_error, content="127")
}
