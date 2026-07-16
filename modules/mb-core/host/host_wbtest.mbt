///|
test "capability absence context is bounded deterministically" {
  let error = capability_unavailable(
    "resource_resolve",
    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  )
  inspect(error.context().unwrap().length(), content="96")
}
