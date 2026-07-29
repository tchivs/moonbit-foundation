///|
fn shape_transaction_budget(work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn assert_shape_scope_closed(error : @error.CoreError) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-shape-scope"), content="true")
  inspect(
    error.context() == Some("font-shape-scope-closed"),
    content="true",
  )
}

///|
test "shape transaction composes one charge across caller and ancestor" {
  let owner = font_test_owner(font_test_minimal_truetype())
  let font = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let parent = shape_transaction_budget(1UL)
  let child = parent
    .child(
      @budget.ResourceLimits::new(
        bytes=0UL,
        allocations=0UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=1UL,
      ),
    )
    .unwrap()
  let value = font
    .with_shape_transaction(child, fn(scope) {
      let units = scope.units_per_em().unwrap()
      Ok((
        units,
        @budget.ResourceCharge::new(
          bytes=0UL,
          allocations=0UL,
          allocation_size=0UL,
          width=0UL,
          height=0UL,
          pixels=0UL,
          work=1UL,
        ),
      ))
    })
    .unwrap()
  inspect(value, content="1000")
  inspect(parent.remaining().work(), content="0")
  inspect(child.remaining().work(), content="0")
}

///|
test "shape transaction one-short and final revision failure are atomic" {
  let short_owner = font_test_owner(font_test_minimal_truetype())
  let short_font = Font::open(
    short_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let short = shape_transaction_budget(0UL)
  let short_error = short_font
    .with_shape_transaction(short, fn(scope) {
      scope.units_per_em().unwrap()
      Ok((
        (),
        @budget.ResourceCharge::new(
          bytes=0UL,
          allocations=0UL,
          allocation_size=0UL,
          width=0UL,
          height=0UL,
          pixels=0UL,
          work=1UL,
        ),
      ))
    })
    .unwrap_err()
  inspect(
    short_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    short_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(short.remaining().work(), content="0")

  let drift_owner = font_test_owner(font_test_minimal_truetype())
  let drift_font = Font::open(
    drift_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let exact = shape_transaction_budget(1UL)
  let drift_error = drift_font
    .with_shape_transaction(exact, fn(scope) {
      scope.units_per_em().unwrap()
      font_test_mutate_bytes(drift_owner, 0UL, b"\x01")
      Ok((
        (),
        @budget.ResourceCharge::new(
          bytes=0UL,
          allocations=0UL,
          allocation_size=0UL,
          width=0UL,
          height=0UL,
          pixels=0UL,
          work=1UL,
        ),
      ))
    })
    .unwrap_err()
  inspect(
    drift_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  inspect(
    drift_error.context() == Some("font-source-revision-drift"),
    content="true",
  )
  inspect(exact.remaining().work(), content="1")
}

///|
test "captured and generic-returned shape scopes close after callback" {
  let owner = font_test_owner(font_test_minimal_truetype())
  let font = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  let mut captured : FontShapeScope? = None
  font
  .with_shape_transaction(shape_transaction_budget(0UL), fn(scope) {
    captured = Some(scope)
    Ok(((), @budget.ResourceCharge::none()))
  })
  .unwrap()
  assert_shape_scope_closed(captured.unwrap().units_per_em().unwrap_err())

  let returned = font
    .with_shape_transaction(shape_transaction_budget(0UL), fn(scope) {
      Ok((scope, @budget.ResourceCharge::none()))
    })
    .unwrap()
  assert_shape_scope_closed(returned.units_per_em().unwrap_err())
}
