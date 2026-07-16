///|
test "generated nearest axes consume every coordinate case" {
  for item in generated_resize_axis_vectors() {
    let (source_extent, destination_extent, expected) = item
    inspect(expected.length().to_uint64() == destination_extent, content="true")
    for destination = 0UL
        destination < destination_extent
        destination = destination + 1UL {
      inspect(
        nearest_source_index(destination, source_extent, destination_extent).unwrap() ==
        expected[destination.to_int()],
        content="true",
      )
    }
  }
}

///|
test "nearest resize rejects zero axes and insufficient work atomically" {
  let source = resize_convert_image(
    1UL,
    1UL,
    3UL,
    None,
    [b'\x01', b'\x02', b'\x03'],
  )
  for dimensions in [(0UL, 1UL), (1UL, 0UL)] {
    let budget = resize_convert_limits(3UL, 3UL)
    let before = budget.remaining()
    inspect(resize_nearest(source.view(), dimensions.0, dimensions.1, budget) is Err(_), content="true")
    inspect(budget.remaining().bytes() == before.bytes(), content="true")
    inspect(budget.remaining().work() == before.work(), content="true")
  }
  let budget = resize_convert_limits(12UL, 11UL)
  let before = budget.remaining()
  inspect(resize_nearest(source.view(), 2UL, 2UL, budget) is Err(_), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "generated RGB RGBA conversion vectors are behaviorally consumed" {
  for item in generated_conversion_vectors() {
    let (source, expected, lossy) = item
    let input = if source.length() == 3 {
      resize_convert_image(1UL, 1UL, 3UL, None, source)
    } else {
      resize_convert_image(
        1UL,
        1UL,
        4UL,
        Some(@color.AlphaMode::Straight),
        source,
      )
    }
    let result = if source.length() == 3 {
      rgb8_to_straight_rgba8(input.view(), resize_convert_limits(4UL, 4UL))
    } else if lossy {
      drop_straight_rgba8_alpha(input.view(), resize_convert_limits(3UL, 3UL))
    } else {
      straight_rgba8_to_rgb8(input.view(), resize_convert_limits(3UL, 3UL))
    }.unwrap()
    let output = result.image().view()
    for index = 0; index < expected.length(); index = index + 1 {
      inspect(
        output.get_byte(0UL, 0UL, index.to_uint64()).unwrap() == expected[index],
        content="true",
      )
    }
    inspect(result.disposition().is_lossy() == lossy, content="true")
  }
}

///|
test "unsupported conversion fails before authoritative charge" {
  let rgb = resize_convert_image(1UL, 1UL, 3UL, None, [b'\x01', b'\x02', b'\x03'])
  let budget = resize_convert_limits(4UL, 4UL)
  let before = budget.remaining()
  inspect(straight_rgba8_to_premultiplied(rgb.view(), budget) is Err(_), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}
