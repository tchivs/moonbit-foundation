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
