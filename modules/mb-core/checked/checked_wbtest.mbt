///|
test "Int backend ceiling is explicit-width and stable" {
  inspect(int_max_as_uint64(), content="2147483647")
}

///|
fn assert_int64_ok(
  result : Result[Int64, @error.CoreError],
  expected : Int64,
) -> Unit raise {
  match result {
    Ok(value) => inspect(value == expected, content="true")
    Err(_) => fail("checked Int64 operation must succeed")
  }
}

///|
test "checked Int64 addition covers every right-operand sign branch" {
  let maximum = 9223372036854775807L
  let minimum = -9223372036854775807L - 1L
  assert_int64_ok(checked_add_int64(7L, 0L), 7L)
  assert_int64_ok(checked_add_int64(-4L, 9L), 5L)
  assert_int64_ok(checked_add_int64(4L, -9L), -5L)
  assert_int64_ok(checked_add_int64(maximum - 1L, 1L), maximum)
  assert_int64_ok(checked_add_int64(minimum + 1L, -1L), minimum)
  inspect(checked_add_int64(maximum, 1L) is Err(_), content="true")
  inspect(checked_add_int64(minimum, -1L) is Err(_), content="true")
}

///|
test "checked Int64 negation covers zero and both sign branches" {
  let minimum = -9223372036854775807L - 1L
  assert_int64_ok(checked_neg_int64(0L), 0L)
  assert_int64_ok(checked_neg_int64(27L), -27L)
  assert_int64_ok(checked_neg_int64(-27L), 27L)
  inspect(checked_neg_int64(minimum) is Err(_), content="true")
}

///|
test "checked UInt64 to Int64 conversion guards before reinterpretation" {
  assert_int64_ok(checked_uint64_to_int64(0UL), 0L)
  assert_int64_ok(
    checked_uint64_to_int64(9223372036854775807UL),
    9223372036854775807L,
  )
  inspect(
    checked_uint64_to_int64(9223372036854775808UL) is Err(_),
    content="true",
  )
  inspect(
    checked_uint64_to_int64(18446744073709551615UL) is Err(_),
    content="true",
  )
}

///|
test "power-of-two validation rejects zero before subtracting" {
  inspect(is_power_of_two(0UL), content="false")
  inspect(is_power_of_two(1UL), content="true")
  inspect(is_power_of_two(8UL), content="true")
  inspect(is_power_of_two(12UL), content="false")
}

///|
test "range end guard preserves exact and overflow adjacency" {
  inspect(checked_range_end(7UL, 0UL) is Ok(_), content="true")
  inspect(
    checked_range_end(18446744073709551615UL, 0UL) is Ok(_),
    content="true",
  )
  inspect(
    checked_range_end(18446744073709551615UL, 1UL) is Err(_),
    content="true",
  )
}

///|
test "pixel count guard accepts zero before multiplication" {
  inspect(
    checked_pixel_count(0UL, 18446744073709551615UL) is Ok(_),
    content="true",
  )
  inspect(
    checked_pixel_count(18446744073709551615UL, 2UL) is Err(_),
    content="true",
  )
}
