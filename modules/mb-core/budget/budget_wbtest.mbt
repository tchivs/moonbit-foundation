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
