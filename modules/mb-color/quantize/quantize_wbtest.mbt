///|
test "floating ties use nearest even with explicit neighbors" {
  let cases = [
    (0.5 / 255.0, 0UL),
    (1.5 / 255.0, 2UL),
    (2.5 / 255.0, 2UL),
    ((2.5 - 1.0e-12) / 255.0, 2UL),
    ((2.5 + 1.0e-12) / 255.0, 3UL),
  ]
  for case in cases {
    inspect(
      quantize_encoded_srgb(
        @model.EncodedSrgbComponent::new(case.0).unwrap(),
      ).value().to_uint64() == case.1,
      content="true",
    )
    inspect(
      quantize_alpha(@model.NormalizedAlpha::new(case.0).unwrap()).value().to_uint64() ==
      case.1,
      content="true",
    )
  }
}

///|
test "generated floating and ratio vectors follow ties to even" {
  for vector in generated_quantize_vectors() {
    inspect(
      quantize_encoded_srgb(
        @model.EncodedSrgbComponent::new(vector.0).unwrap(),
      ).value().to_uint64() == vector.1.to_uint64(),
      content="true",
    )
  }
  for vector in generated_ratio_vectors() {
    inspect(
      round_ratio_ties_even(vector.0, vector.1).unwrap() == vector.2,
      content="true",
    )
  }
}

///|
test "ratio halfway decisions follow quotient parity" {
  inspect(round_ratio_ties_even(1UL, 2UL).unwrap(), content="0")
  inspect(round_ratio_ties_even(3UL, 2UL).unwrap(), content="2")
  inspect(round_ratio_ties_even(5UL, 2UL).unwrap(), content="2")
  inspect(round_ratio_ties_even(7UL, 2UL).unwrap(), content="4")
  inspect(round_ratio_ties_even(4UL, 3UL).unwrap(), content="1")
  inspect(round_ratio_ties_even(5UL, 3UL).unwrap(), content="2")
}
