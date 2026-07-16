///|
test "checked subtraction accepts zero and equality but rejects underflow" {
  inspect(@checked.checked_sub(0UL, 0UL), content="Ok(0)")
  inspect(@checked.checked_sub(9UL, 9UL), content="Ok(0)")
  match @checked.checked_sub(8UL, 9UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticUnderflow,
        content="true",
      )
    Ok(_) => fail("one-unit underflow must fail")
  }
}

///|
test "checked addition and multiplication distinguish exact and overflow bounds" {
  inspect(
    @checked.checked_add(@uint64.MAX_VALUE - 1UL, 1UL),
    content="Ok(18446744073709551615)",
  )
  match @checked.checked_add(@uint64.MAX_VALUE, 1UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("addition overflow must fail")
  }
  inspect(
    @checked.checked_mul(@uint64.MAX_VALUE, 0UL),
    content="Ok(0)",
  )
  match @checked.checked_mul(@uint64.MAX_VALUE, 2UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("multiplication overflow must fail")
  }
}

///|
test "alignment validates before rounding" {
  inspect(@checked.align_up(0UL, 1UL), content="Ok(0)")
  inspect(@checked.align_up(9UL, 8UL), content="Ok(16)")
  match @checked.align_up(9UL, 0UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::InvalidAlignment,
        content="true",
      )
    Ok(_) => fail("zero alignment must fail")
  }
  match @checked.align_up(9UL, 3UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::InvalidAlignment,
        content="true",
      )
    Ok(_) => fail("non-power-of-two alignment must fail")
  }
  match @checked.align_up(@uint64.MAX_VALUE, 2UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("alignment overflow must fail")
  }
}

///|
test "backend narrowing accepts exact Int max and rejects one over" {
  inspect(@checked.checked_narrow_int(2147483647UL), content="Ok(2147483647)")
  match @checked.checked_narrow_int(2147483648UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NarrowingFailed, content="true")
    Ok(_) => fail("one-over Int max must not truncate")
  }
}

///|
test "allocation size multiplies before narrowing without wrap or truncation" {
  inspect(@checked.checked_allocation_size(0UL, @uint64.MAX_VALUE), content="Ok(0)")
  inspect(@checked.checked_allocation_size(1024UL, 4UL), content="Ok(4096)")
  match @checked.checked_allocation_size(1073741824UL, 2UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NarrowingFailed, content="true")
    Ok(_) => fail("backend allocation size must be representable as Int")
  }
}

///|
test "checked offsets move at zero and extrema without wrapping" {
  let zero = @checked.CheckedOffset::new(0UL)
  inspect(zero.advance(0UL).map(fn(offset) { offset.value() }), content="Ok(0)")
  let maximum = @checked.CheckedOffset::new(@uint64.MAX_VALUE)
  inspect(maximum.retreat(0UL).map(fn(offset) { offset.value() }), content="Ok(18446744073709551615)")
  match maximum.advance(1UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::InvalidOffset, content="true")
    Ok(_) => fail("offset advance must not wrap")
  }
  match zero.retreat(1UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::InvalidOffset, content="true")
    Ok(_) => fail("offset retreat must not underflow")
  }
}
