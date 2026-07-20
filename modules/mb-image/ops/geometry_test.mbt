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
  match @ops.crop(source.view(), empty, budget) {
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidDimensions, content="true")
      inspect(error.operation() == Some("image-crop"), content="true")
      inspect(error.context() == Some("empty-crop-region"), content="true")
    }
    Ok(_) => fail("empty crop must reject")
  }
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
  let outside = @model.Rect::new(1UL, 0UL, 2UL, 1UL).unwrap()
  match @ops.crop(source.view(), outside, operation_limits(12UL, 12UL)) {
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::InvalidInput, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
      inspect(error.operation() == Some("image-crop"), content="true")
      inspect(error.context() == Some("crop-region-outside-source"), content="true")
    }
    Ok(_) => fail("out-of-bounds crop must reject")
  }
}

///|
test "explicit rotations map every non-square RGB and RGBA coordinate clockwise" {
  for alpha in [None, Some(@color.AlphaMode::Straight)] {
    let channels = if alpha is None { 3UL } else { 4UL }
    let pixels : Array[Byte] = []
    for y = 0UL; y < 3UL; y = y + 1UL {
      for x = 0UL; x < 2UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          pixels.push((y * 32UL + x * 8UL + channel).to_byte())
        }
      }
    }
    let source = resize_convert_image(2UL, 3UL, channels, alpha, pixels)
    let rotated_90 = @ops.rotate_90(source.view(), operation_limits(24UL, 24UL)).unwrap()
    let rotated_180 = @ops.rotate_180(source.view(), operation_limits(24UL, 24UL)).unwrap()
    let rotated_270 = @ops.rotate_270(source.view(), operation_limits(24UL, 24UL)).unwrap()
    inspect(rotated_90.image().descriptor().width(), content="3")
    inspect(rotated_90.image().descriptor().height(), content="2")
    inspect(rotated_180.image().descriptor().width(), content="2")
    inspect(rotated_180.image().descriptor().height(), content="3")
    inspect(rotated_270.image().descriptor().width(), content="3")
    inspect(rotated_270.image().descriptor().height(), content="2")
    for y = 0UL; y < 3UL; y = y + 1UL {
      for x = 0UL; x < 2UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          let value = source.view().get_byte(x, y, channel).unwrap()
          inspect(
            rotated_90.image().view().get_byte(2UL - y, x, channel).unwrap() == value,
            content="true",
          )
          inspect(
            rotated_180.image().view().get_byte(1UL - x, 2UL - y, channel).unwrap() == value,
            content="true",
          )
          inspect(
            rotated_270.image().view().get_byte(y, 1UL - x, channel).unwrap() == value,
            content="true",
          )
        }
      }
    }
    inspect(rotated_90.image().metadata().orientation() == @model.Orientation::TopLeft, content="true")
    inspect(rotated_90.disposition().preserved_length(), content="4")
    inspect(rotated_90.disposition().transformed_length(), content="1")
    inspect(rotated_90.disposition().transformed(0).unwrap().value(), content="orientation")
  }
}

///|
test "rotation budget failure remains typed and atomic" {
  let source = resize_convert_image(2UL, 3UL, 3UL, None, [
    b'\x01', b'\x02', b'\x03', b'\x04', b'\x05', b'\x06',
    b'\x07', b'\x08', b'\x09', b'\x0a', b'\x0b', b'\x0c',
    b'\x0d', b'\x0e', b'\x0f', b'\x10', b'\x11', b'\x12',
  ])
  let budget = operation_limits(18UL, 17UL)
  let before = budget.remaining()
  inspect(@ops.rotate_90(source.view(), budget) is Err(_), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(budget.remaining().allocations() == before.allocations(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}
