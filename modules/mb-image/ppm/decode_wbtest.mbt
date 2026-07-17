///|
test "decode descriptor arithmetic rejects full-width overflow" {
  inspect(
    @checked.checked_mul(18446744073709551615UL, 2UL) is Err(_),
    content="true",
  )
  inspect(
    @checked.checked_mul(9223372036854775808UL, 3UL) is Err(_),
    content="true",
  )
}
