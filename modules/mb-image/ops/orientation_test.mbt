///|
test "apply orientation returns fresh TopLeft output" {
  let source = padded_image(3UL, None, @model.Orientation::TopRight)
  let budget = operation_limits(12UL, 12UL)
  let result = @ops.apply_orientation(source.view(), budget).unwrap()
  inspect(result.image().descriptor().width(), content="2")
  inspect(result.image().descriptor().height(), content="2")
  inspect(
    result.image().metadata().orientation() == @model.Orientation::TopLeft,
    content="true",
  )
  inspect(
    result.image().view().get_byte(0UL, 0UL, 0UL).unwrap() ==
    source.view().get_byte(1UL, 0UL, 0UL).unwrap(),
    content="true",
  )
  inspect(result.disposition().preserved_length(), content="4")
  inspect(result.disposition().transformed_length(), content="1")
  inspect(
    result.disposition().transformed(0).unwrap().value(),
    content="orientation",
  )
}
