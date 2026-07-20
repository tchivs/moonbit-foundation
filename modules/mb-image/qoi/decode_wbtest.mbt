///|
test "QOI arithmetic is checked before resource preflight" {
  inspect(
    @checked.checked_mul(18446744073709551615UL, 2UL) is Err(_),
    content="true",
  )
}
