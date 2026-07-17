///|
fn public_limits() -> @budget.ResourceLimits {
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
pub fn consume_core_artifact() -> Bool {
  let marker = @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="artifact-consumer",
  )
  match @checked.checked_add(40UL, 2UL) {
    Err(_) => false
    Ok(sum) => {
      let budget = @budget.Budget::new(public_limits())
      match @bytes.OwnedBytes::from_bytes(b"core", budget) {
        Err(_) => false
        Ok(owned) => {
          let reader = @io.MemoryReader::new(owned.view())
          let clock = @host.FakeClock::new(sum)
          match clock.now_millis() {
            Err(_) => false
            Ok(now) =>
              marker.code() == @error.ErrorCode::InvalidEncoding &&
              owned.length() == 4UL && reader.position() == 0UL && now == 42UL
          }
        }
      }
    }
  }
}

///|
test "exact extracted mb-core artifact exposes every public package" {
  inspect(consume_core_artifact(), content="true")
}
