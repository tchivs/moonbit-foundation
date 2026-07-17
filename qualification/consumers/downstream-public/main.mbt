///|
pub fn copied_source_consumer_marker() -> String {
  "public-named-dependency-consumer"
}

///|
test "downstream consumer source executes after public imports resolve" {
  inspect(
    copied_source_consumer_marker(),
    content="public-named-dependency-consumer",
  )
}
