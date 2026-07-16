///|
fn generous_limits() -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes=100UL,
    allocations=10UL,
    allocation_size=64UL,
    width=16UL,
    height=16UL,
    pixels=256UL,
    depth=4UL,
    work=1000UL,
  )
}

///|
test "exact remaining charge succeeds and the next unit fails unchanged" {
  let budget = @budget.Budget::new(generous_limits())
  let exact = @budget.ResourceCharge::new(
    bytes=100UL,
    allocations=10UL,
    allocation_size=64UL,
    width=16UL,
    height=16UL,
    pixels=256UL,
    work=1000UL,
  )
  inspect(budget.charge(exact) is Ok(_), content="true")
  inspect(budget.remaining().bytes(), content="0")
  inspect(
    budget.charge(@budget.ResourceCharge::bytes(1UL)) is Err(_),
    content="true",
  )
  inspect(budget.remaining().bytes(), content="0")
}

///|
test "multidimensional rejection rolls every consumable field back" {
  let budget = @budget.Budget::new(generous_limits())
  let rejected = @budget.ResourceCharge::new(
    bytes=4UL,
    allocations=1UL,
    allocation_size=8UL,
    width=3UL,
    height=3UL,
    pixels=9UL,
    work=1001UL,
  )
  match budget.charge(rejected) {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
      inspect(error.context() == Some("work"), content="true")
    }
    Ok(_) => fail("work overflow must reject the complete charge")
  }
  let remaining = budget.remaining()
  inspect(remaining.bytes(), content="100")
  inspect(remaining.allocations(), content="10")
  inspect(remaining.pixels(), content="256")
  inspect(remaining.work(), content="1000")
}

///|
test "zero charges and balanced empty scopes are no-ops" {
  let budget = @budget.Budget::new(generous_limits())
  inspect(budget.charge(@budget.ResourceCharge::none()) is Ok(_), content="true")
  let before = budget.remaining()
  let scope = match budget.enter_depth() {
    Ok(scope) => scope
    Err(_) => fail("empty scope must enter")
  }
  scope.leave()
  scope.leave()
  inspect(budget.current_depth(), content="0")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
}

///|
test "per-operation allocation and dimension caps reject before consumption" {
  let budget = @budget.Budget::new(generous_limits())
  let rejected = @budget.ResourceCharge::new(
    bytes=1UL,
    allocations=1UL,
    allocation_size=65UL,
    width=17UL,
    height=16UL,
    pixels=1UL,
    work=1UL,
  )
  inspect(budget.charge(rejected) is Err(_), content="true")
  inspect(budget.remaining().bytes(), content="100")
  inspect(budget.remaining().allocations(), content="10")
  inspect(budget.remaining().pixels(), content="256")
  inspect(budget.remaining().work(), content="1000")
}

///|
test "child budgets narrow locally while consuming the shared parent ledger" {
  let parent = @budget.Budget::new(generous_limits())
  let child_limits = @budget.ResourceLimits::new(
    bytes=4UL,
    allocations=2UL,
    allocation_size=32UL,
    width=8UL,
    height=8UL,
    pixels=16UL,
    depth=1UL,
    work=10UL,
  )
  let child = match parent.child(child_limits) {
    Ok(child) => child
    Err(_) => fail("strictly narrower child must construct")
  }
  inspect(child.charge(@budget.ResourceCharge::bytes(3UL)) is Ok(_), content="true")
  inspect(parent.remaining().bytes(), content="97")
  inspect(child.remaining().bytes(), content="1")
  inspect(child.charge(@budget.ResourceCharge::bytes(2UL)) is Err(_), content="true")
  inspect(parent.remaining().bytes(), content="97")
  inspect(child.remaining().bytes(), content="1")
  inspect(parent.charge(@budget.ResourceCharge::bytes(97UL)) is Ok(_), content="true")
  inspect(child.charge(@budget.ResourceCharge::bytes(1UL)) is Err(_), content="true")
}

///|
test "depth is shared and scoped cleanup covers success and error results" {
  let budget = @budget.Budget::new(generous_limits())
  inspect(
    @budget.with_depth(budget, fn(_scope) { Ok(7) }),
    content="Ok(7)",
  )
  inspect(budget.current_depth(), content="0")
  let failed : Result[Int, @error.CoreError] = @budget.with_depth(
    budget,
    fn(_scope) {
      Err(
        @error.CoreError::new(
          @error.ErrorCategory::State,
          @error.ErrorCode::BudgetExceeded,
          operation="body",
        ),
      )
    },
  )
  inspect(failed is Err(_), content="true")
  inspect(budget.current_depth(), content="0")
}
