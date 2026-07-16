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
  inspect(checked_seek_position(SeekOrigin::Start, 0L, 0UL, 0UL), content="Ok(0)")
  inspect(checked_seek_position(SeekOrigin::End, 0L, 0UL, 0UL), content="Ok(0)")
  inspect(checked_seek_position(SeekOrigin::End, 1L, 0UL, 0UL) is Err(_), content="true")
}
