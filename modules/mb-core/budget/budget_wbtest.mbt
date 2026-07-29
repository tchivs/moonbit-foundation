///|
test "preflight validates all dimensions before committing any counter" {
  let budget = Budget::new(
    ResourceLimits::new(
      bytes=2UL,
      allocations=2UL,
      allocation_size=2UL,
      width=2UL,
      height=2UL,
      pixels=2UL,
      depth=2UL,
      work=2UL,
    ),
  )
  let rejected = ResourceCharge::new(
    bytes=1UL,
    allocations=1UL,
    allocation_size=1UL,
    width=1UL,
    height=1UL,
    pixels=1UL,
    work=3UL,
  )
  inspect(budget.charge(rejected) is Err(_), content="true")
  inspect(budget.remaining().bytes(), content="2")
  inspect(budget.remaining().allocations(), content="2")
  inspect(budget.remaining().pixels(), content="2")
  inspect(budget.remaining().work(), content="2")
}

///|
test "UInt64 maximum precision is preserved without backend narrowing" {
  let budget = Budget::new(
    ResourceLimits::new(
      bytes=18446744073709551615UL,
      allocations=18446744073709551615UL,
      allocation_size=18446744073709551615UL,
      width=18446744073709551615UL,
      height=18446744073709551615UL,
      pixels=18446744073709551615UL,
      depth=1UL,
      work=18446744073709551615UL,
    ),
  )
  inspect(
    budget.charge(ResourceCharge::bytes(18446744073709551615UL)) is Ok(_),
    content="true",
  )
  inspect(budget.remaining().bytes(), content="0")
}

///|
fn budget_wb_assert_charge_add_overflow(
  first : ResourceCharge,
  second : ResourceCharge,
  dimension : String,
) -> Unit raise {
  let error = first.checked_add(second).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(
    error.code() == @error.ErrorCode::ArithmeticOverflow,
    content="true",
  )
  inspect(error.operation() == Some("resource-charge-add"), content="true")
  inspect(error.context() == Some(dimension), content="true")
}

///|
test "resource charge composition rejects every additive dimension overflow" {
  let maximum = 18446744073709551615UL
  budget_wb_assert_charge_add_overflow(
    ResourceCharge::new(
      bytes=maximum,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=0UL,
    ),
    ResourceCharge::bytes(1UL),
    "bytes",
  )
  budget_wb_assert_charge_add_overflow(
    ResourceCharge::new(
      bytes=0UL,
      allocations=maximum,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=0UL,
    ),
    ResourceCharge::new(
      bytes=0UL,
      allocations=1UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=0UL,
    ),
    "allocations",
  )
  budget_wb_assert_charge_add_overflow(
    ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=maximum,
      work=0UL,
    ),
    ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=1UL,
      work=0UL,
    ),
    "pixels",
  )
  budget_wb_assert_charge_add_overflow(
    ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=maximum,
    ),
    ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=1UL,
    ),
    "work",
  )
}

///|
test "resource charge composition adds consumables and takes ceiling maxima immutably" {
  let first = ResourceCharge::new(
    bytes=2UL,
    allocations=3UL,
    allocation_size=11UL,
    width=5UL,
    height=13UL,
    pixels=17UL,
    work=19UL,
  )
  let second = ResourceCharge::new(
    bytes=23UL,
    allocations=29UL,
    allocation_size=7UL,
    width=31UL,
    height=3UL,
    pixels=37UL,
    work=41UL,
  )
  let combined = first.checked_add(second).unwrap()
  inspect(combined.bytes_value, content="25")
  inspect(combined.allocations_value, content="32")
  inspect(combined.allocation_size_value, content="11")
  inspect(combined.width_value, content="31")
  inspect(combined.height_value, content="13")
  inspect(combined.pixels_value, content="54")
  inspect(combined.work_value, content="60")
  inspect(first.bytes_value, content="2")
  inspect(first.width_value, content="5")
  inspect(second.bytes_value, content="23")
  inspect(second.width_value, content="31")
}
