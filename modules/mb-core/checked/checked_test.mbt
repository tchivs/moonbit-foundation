///|
test "checked subtraction accepts zero and equality but rejects underflow" {
  match @checked.checked_sub(0UL, 0UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("zero subtraction must succeed")
  }
  match @checked.checked_sub(9UL, 9UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("equal subtraction must succeed")
  }
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
  match @checked.checked_add(18446744073709551614UL, 1UL) {
    Ok(value) => inspect(value, content="18446744073709551615")
    Err(_) => fail("exact addition bound must succeed")
  }
  match @checked.checked_add(18446744073709551615UL, 1UL) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::ArithmeticOverflow,
        content="true",
      )
    Ok(_) => fail("addition overflow must fail")
  }
  match @checked.checked_mul(18446744073709551615UL, 0UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("multiplication by zero must succeed")
  }
  match @checked.checked_mul(18446744073709551615UL, 2UL) {
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
  match @checked.align_up(0UL, 1UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("zero aligned to one must succeed")
  }
  match @checked.align_up(9UL, 8UL) {
    Ok(value) => inspect(value, content="16")
    Err(_) => fail("valid upward alignment must succeed")
  }
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
  match @checked.align_up(18446744073709551615UL, 2UL) {
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
  match @checked.checked_narrow_int(2147483647UL) {
    Ok(value) => inspect(value, content="2147483647")
    Err(_) => fail("exact Int maximum must narrow")
  }
  match @checked.checked_narrow_int(2147483648UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NarrowingFailed, content="true")
    Ok(_) => fail("one-over Int max must not truncate")
  }
}

///|
test "allocation size multiplies before narrowing without wrap or truncation" {
  match @checked.checked_allocation_size(0UL, 18446744073709551615UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("zero allocation product must succeed")
  }
  match @checked.checked_allocation_size(1024UL, 4UL) {
    Ok(value) => inspect(value, content="4096")
    Err(_) => fail("representable allocation product must succeed")
  }
  match @checked.checked_allocation_size(1073741824UL, 2UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NarrowingFailed, content="true")
    Ok(_) => fail("backend allocation size must be representable as Int")
  }
}

///|
test "checked offsets move at zero and extrema without wrapping" {
  let zero = @checked.CheckedOffset::new(0UL)
  match zero.advance(0UL) {
    Ok(offset) => inspect(offset.value(), content="0")
    Err(_) => fail("zero offset advance must succeed")
  }
  let maximum = @checked.CheckedOffset::new(18446744073709551615UL)
  match maximum.retreat(0UL) {
    Ok(offset) => inspect(offset.value(), content="18446744073709551615")
    Err(_) => fail("zero offset retreat must succeed")
  }
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
