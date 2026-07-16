///|
test "Int backend ceiling is explicit-width and stable" {
  inspect(int_max_as_uint64(), content="2147483647")
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
  inspect(checked_range_end(7UL, 0UL).is_ok(), content="true")
  inspect(
    checked_range_end(18446744073709551615UL, 0UL).is_ok(),
    content="true",
  )
  inspect(
    checked_range_end(18446744073709551615UL, 1UL).is_err(),
    content="true",
  )
}

///|
test "pixel count guard accepts zero before multiplication" {
  inspect(checked_pixel_count(0UL, 18446744073709551615UL).is_ok(), content="true")
  inspect(checked_pixel_count(18446744073709551615UL, 2UL).is_err(), content="true")
}
