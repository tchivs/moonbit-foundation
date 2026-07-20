///|
test "crop returns a fresh tight owned image and preserves metadata" {
  let source = padded_image(3UL, None, @model.Orientation::RightBottom)
  let region = @model.Rect::new(1UL, 0UL, 1UL, 2UL).unwrap()
  let result = @ops.crop(source.view(), region, operation_limits(6UL, 6UL)).unwrap()
  let output = result.image()
  inspect(output.storage_length(), content="6")
  inspect(output.view().row_stride(), content="3")
  inspect(output.metadata().orientation() == @model.Orientation::RightBottom, content="true")
  inspect(output.metadata().opaque_metadata().length(), content="1")
  inspect(result.disposition().preserved_length(), content="5")
  for y = 0UL; y < 2UL; y = y + 1UL {
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      inspect(
        output.view().get_byte(0UL, y, channel).unwrap() ==
        source.view().get_byte(1UL, y, channel).unwrap(),
        content="true",
      )
    }
  }
  source.with_mut_view(fn(view) { view.set_byte(1UL, 0UL, 0UL, b'Z') }).unwrap()
  inspect(output.view().get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x04'")
}

///|
test "crop rejects invalid public requests before charging the budget" {
  let source = padded_image(3UL, None, @model.Orientation::TopLeft)
  let budget = operation_limits(12UL, 12UL)
  let before = budget.remaining()
  let empty = @model.Rect::new(0UL, 0UL, 0UL, 1UL).unwrap()
  inspect(@ops.crop(source.view(), empty, budget) is Err(_), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
  let outside = @model.Rect::new(1UL, 0UL, 2UL, 1UL).unwrap()
  inspect(
    @ops.crop(source.view(), outside, operation_limits(12UL, 12UL)) is Err(_),
    content="true",
  )
}
