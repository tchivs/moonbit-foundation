///|
fn consumer_limits() -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes=4UL,
    allocations=2UL,
    allocation_size=4UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=0UL,
  )
}

///|
fn main {
  let marker = @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="registry-consumer",
  )
  let sum = @checked.checked_add(40UL, 2UL).unwrap()
  let budget = @budget.Budget::new(consumer_limits())
  let owned = @bytes.OwnedBytes::from_bytes(b"core", budget).unwrap()
  let reader = @io.MemoryReader::new(owned.view())
  let clock = @host.FakeClock::new(sum)
  let now = clock.now_millis().unwrap()
  if marker.code() == @error.ErrorCode::InvalidEncoding &&
    sum == 42UL && owned.length() == 4UL && reader.position() == 0UL &&
    now == 42UL {
    println("consumer=mb-core sum=42 bytes=4 position=0 clock=42")
  } else {
    println("consumer=mb-core status=failed")
  }
}
