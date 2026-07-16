///|
test "decode uses inclusive low branch at the published threshold" {
  for value in [0.040449, 0.04045] {
    inspect(
      (decode_srgb(@model.EncodedSrgbComponent::new(value).unwrap()).value() -
      value / 12.92).abs() <=
      decode_absolute_tolerance(),
      content="true",
    )
  }
  let above = 0.040451
  let expected = @math.pow((above + 0.055) / 1.055, 2.4)
  inspect(
    (decode_srgb(@model.EncodedSrgbComponent::new(above).unwrap()).value() -
    expected).abs() <=
    decode_absolute_tolerance(),
    content="true",
  )
}

///|
test "encode uses inclusive low branch at the published threshold" {
  for value in [0.0031298, 0.0031308] {
    inspect(
      (encode_srgb(@model.LinearSrgbComponent::new(value).unwrap()).value() -
      12.92 * value).abs() <=
      encode_absolute_tolerance(),
      content="true",
    )
  }
  let above = 0.0031318
  let expected = 1.055 * @math.pow(above, 1.0 / 2.4) - 0.055
  inspect(
    (encode_srgb(@model.LinearSrgbComponent::new(above).unwrap()).value() -
    expected).abs() <=
    encode_absolute_tolerance(),
    content="true",
  )
}

///|
test "registered transfer vectors match the standards formulas" {
  for vector in generated_decode_vectors() {
    let actual = decode_srgb(
      @model.EncodedSrgbComponent::new(vector.0).unwrap(),
    ).value()
    inspect(
      (actual - vector.1).abs() <= decode_absolute_tolerance(),
      content="true",
    )
  }
  for vector in generated_encode_vectors() {
    let actual = encode_srgb(@model.LinearSrgbComponent::new(vector.0).unwrap()).value()
    inspect(
      (actual - vector.1).abs() <= encode_absolute_tolerance(),
      content="true",
    )
  }
}
