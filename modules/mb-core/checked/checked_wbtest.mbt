///|
test "Int backend ceiling is explicit-width and stable" {
  inspect(int_max_as_uint64(), content="2147483647")
}

///|
test "checked Int64 addition covers every right-operand sign branch" {
  let maximum = 9223372036854775807L
  let minimum = -9223372036854775807L - 1L
  inspect(checked_add_int64(7L, 0L), content="Ok(7)")
  inspect(checked_add_int64(-4L, 9L), content="Ok(5)")
  inspect(checked_add_int64(4L, -9L), content="Ok(-5)")
  inspect(
    checked_add_int64(maximum - 1L, 1L),
    content="Ok(9223372036854775807)",
  )
  inspect(
    checked_add_int64(minimum + 1L, -1L),
    content="Ok(-9223372036854775808)",
  )
  inspect(checked_add_int64(maximum, 1L) is Err(_), content="true")
  inspect(checked_add_int64(minimum, -1L) is Err(_), content="true")
}

///|
test "checked Int64 negation covers zero and both sign branches" {
  let minimum = -9223372036854775807L - 1L
  inspect(checked_neg_int64(0L), content="Ok(0)")
  inspect(checked_neg_int64(27L), content="Ok(-27)")
  inspect(checked_neg_int64(-27L), content="Ok(27)")
  inspect(checked_neg_int64(minimum) is Err(_), content="true")
}

///|
test "checked UInt64 to Int64 conversion guards before reinterpretation" {
  inspect(checked_uint64_to_int64(0UL), content="Ok(0)")
  inspect(
    checked_uint64_to_int64(9223372036854775807UL),
    content="Ok(9223372036854775807)",
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
