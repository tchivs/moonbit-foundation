///|
test "seek validation rejects before changing a caller cursor" {
  let mut cursor = 2UL
  match checked_seek_position(SeekOrigin::Current, 3L, cursor, 4UL) {
    Ok(value) => cursor = value
    Err(_) => ()
  }
  inspect(cursor, content="2")
}

///|
test "empty seek window has deterministic exact boundaries" {
  match checked_seek_position(SeekOrigin::Start, 0L, 0UL, 0UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("empty start seek must succeed")
  }
  match checked_seek_position(SeekOrigin::End, 0L, 0UL, 0UL) {
    Ok(value) => inspect(value, content="0")
    Err(_) => fail("empty end seek must succeed")
  }
  inspect(
    checked_seek_position(SeekOrigin::End, 1L, 0UL, 0UL) is Err(_),
    content="true",
  )
}

///|
test "bounded transition rejects oversized provider progress before cursor escape" {
  let result = validate_transition_progress(3UL, 2UL, 0UL, "bounded_read")
  inspect(result is Err(_), content="true")
}
