///|
test "validated scalar snapshot preserves values adjacency and count after caller mutation" {
  let scalars = [0x41, 0x41, 0x1F600]
  let snapshot = validate_and_snapshot_scalars_with_probe(scalars, fn() {
    scalars[0] = 0x42
    scalars[1] = 0x43
    scalars.push(0x44)
  }).unwrap()
  inspect(snapshot.length(), content="3")
  inspect(snapshot[0], content="65")
  inspect(snapshot[1], content="65")
  inspect(snapshot[2], content="128512")
  inspect(scalars.length(), content="4")
  inspect(scalars[0], content="66")
}

///|
test "private scalar validator accepts exact Unicode scalar boundaries" {
  let scalars = [0, 0xD7FF, 0xE000, 0x10FFFF]
  let snapshot = validate_and_snapshot_scalars_with_probe(scalars, fn() { () }).unwrap()
  inspect(snapshot.length(), content="4")
  inspect(snapshot[0], content="0")
  inspect(snapshot[1], content="55295")
  inspect(snapshot[2], content="57344")
  inspect(snapshot[3], content="1114111")
}
