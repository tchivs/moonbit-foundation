///|
fn shape_wb_limits(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  width : UInt64,
  height : UInt64,
  pixels : UInt64,
  work : UInt64,
) -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes~,
    allocations~,
    allocation_size~,
    width~,
    height~,
    pixels~,
    depth=0UL,
    work~,
  )
}

///|
fn shape_wb_assert_limits_equal(
  actual : @budget.ResourceLimits,
  expected : @budget.ResourceLimits,
) -> Unit raise {
  inspect(actual.bytes() == expected.bytes(), content="true")
  inspect(actual.allocations() == expected.allocations(), content="true")
  inspect(
    actual.allocation_size() == expected.allocation_size(),
    content="true",
  )
  inspect(actual.width() == expected.width(), content="true")
  inspect(actual.height() == expected.height(), content="true")
  inspect(actual.pixels() == expected.pixels(), content="true")
  inspect(actual.depth() == expected.depth(), content="true")
  inspect(actual.work() == expected.work(), content="true")
}

///|
fn shape_wb_assert_revision_error(error : @error.CoreError) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-shape-transaction"),
    content="true",
  )
  inspect(
    error.context() == Some("font-source-revision-drift"),
    content="true",
  )
}

///|
fn shape_wb_noop_probes() -> FontShapeTransactionProbes {
  FontShapeTransactionProbes::{
    post_structure: fn() { () },
    post_capability: fn() { () },
    post_complete_staging: fn() { () },
    before_final_guard: fn() { () },
  }
}

///|
fn shape_wb_open_font() -> (Font, @bytes.OwnedBytes) {
  let owner = font_wb_owner(generated_minimal_truetype())
  let font = Font::open(owner.view(), font_wb_limits(), font_wb_open_budget()).unwrap()
  (font, owner)
}

///|
fn shape_wb_capability_error() -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    operation="font-shape-stage",
    context="later-capability",
  )
}

///|
test "post-structure and post-capability mutation probes beat later callback faults" {
  let (structure_font, structure_owner) = shape_wb_open_font()
  let structure_parent = @budget.Budget::new(
    shape_wb_limits(2UL, 2UL, 2UL, 2UL, 2UL, 2UL, 2UL),
  )
  let structure_child = structure_parent
    .child(shape_wb_limits(2UL, 2UL, 2UL, 2UL, 2UL, 2UL, 2UL))
    .unwrap()
  let structure_parent_before = structure_parent.remaining()
  let structure_child_before = structure_child.remaining()
  let mut structure_body_calls = 0
  let structure_result : Result[Unit, @error.CoreError] = structure_font
    .with_shape_transaction_probes(
      structure_child,
      @budget.ResourceCharge::none(),
      FontShapeTransactionProbes::{
        post_structure: fn() { font_wb_mutate_one_byte(structure_owner, 0UL) },
        post_capability: fn() { () },
        post_complete_staging: fn() { () },
        before_final_guard: fn() { () },
      },
      fn(_) {
        structure_body_calls = structure_body_calls + 1
        Err(shape_wb_capability_error())
      },
    )
  shape_wb_assert_revision_error(structure_result.unwrap_err())
  inspect(structure_body_calls, content="0")
  shape_wb_assert_limits_equal(
    structure_parent.remaining(),
    structure_parent_before,
  )
  shape_wb_assert_limits_equal(structure_child.remaining(), structure_child_before)

  let (capability_font, capability_owner) = shape_wb_open_font()
  let capability_parent = @budget.Budget::new(
    shape_wb_limits(2UL, 2UL, 2UL, 2UL, 2UL, 2UL, 2UL),
  )
  let capability_child = capability_parent
    .child(shape_wb_limits(2UL, 2UL, 2UL, 2UL, 2UL, 2UL, 2UL))
    .unwrap()
  let capability_parent_before = capability_parent.remaining()
  let capability_child_before = capability_child.remaining()
  let mut capability_body_calls = 0
  let capability_result : Result[Unit, @error.CoreError] = capability_font
    .with_shape_transaction_probes(
      capability_child,
      @budget.ResourceCharge::none(),
      FontShapeTransactionProbes::{
        post_structure: fn() { () },
        post_capability: fn() {
          font_wb_mutate_one_byte(capability_owner, 0UL)
        },
        post_complete_staging: fn() { () },
        before_final_guard: fn() { () },
      },
      fn(_) {
        capability_body_calls = capability_body_calls + 1
        Err(shape_wb_capability_error())
      },
    )
  shape_wb_assert_revision_error(capability_result.unwrap_err())
  inspect(capability_body_calls, content="0")
  shape_wb_assert_limits_equal(
    capability_parent.remaining(),
    capability_parent_before,
  )
  shape_wb_assert_limits_equal(
    capability_child.remaining(),
    capability_child_before,
  )
}

///|
test "post-staging and final mutation probes beat later resource outcomes" {
  let (staging_font, staging_owner) = shape_wb_open_font()
  let staging_parent = @budget.Budget::new(
    shape_wb_limits(0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL),
  )
  let staging_child = staging_parent
    .child(shape_wb_limits(0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL))
    .unwrap()
  let staging_parent_before = staging_parent.remaining()
  let staging_child_before = staging_child.remaining()
  let staging_result = staging_font
    .with_shape_transaction_probes(
      staging_child,
      @budget.ResourceCharge::none(),
      FontShapeTransactionProbes::{
        post_structure: fn() { () },
        post_capability: fn() { () },
        post_complete_staging: fn() {
          font_wb_mutate_one_byte(staging_owner, 0UL)
        },
        before_final_guard: fn() { () },
      },
      fn(_) {
        Ok(
          (
            (),
            @budget.ResourceCharge::new(
              bytes=1UL,
              allocations=0UL,
              allocation_size=0UL,
              width=0UL,
              height=0UL,
              pixels=0UL,
              work=0UL,
            ),
          ),
        )
      },
    )
  shape_wb_assert_revision_error(staging_result.unwrap_err())
  shape_wb_assert_limits_equal(staging_parent.remaining(), staging_parent_before)
  shape_wb_assert_limits_equal(staging_child.remaining(), staging_child_before)

  let (final_font, final_owner) = shape_wb_open_font()
  let final_parent = @budget.Budget::new(
    shape_wb_limits(1UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL),
  )
  let final_child = final_parent
    .child(shape_wb_limits(1UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL))
    .unwrap()
  let final_parent_before = final_parent.remaining()
  let final_child_before = final_child.remaining()
  let final_result = final_font
    .with_shape_transaction_probes(
      final_child,
      @budget.ResourceCharge::none(),
      FontShapeTransactionProbes::{
        post_structure: fn() { () },
        post_capability: fn() { () },
        post_complete_staging: fn() { () },
        before_final_guard: fn() {
          font_wb_mutate_one_byte(final_owner, 0UL)
        },
      },
      fn(_) {
        Ok(
          (
            (),
            @budget.ResourceCharge::new(
              bytes=1UL,
              allocations=0UL,
              allocation_size=0UL,
              width=0UL,
              height=0UL,
              pixels=0UL,
              work=0UL,
            ),
          ),
        )
      },
    )
  shape_wb_assert_revision_error(final_result.unwrap_err())
  shape_wb_assert_limits_equal(final_parent.remaining(), final_parent_before)
  shape_wb_assert_limits_equal(final_child.remaining(), final_child_before)
}

///|
test "combined transaction charge commits exact hierarchy once and fails atomically" {
  let font_charge = @budget.ResourceCharge::new(
    bytes=1UL,
    allocations=1UL,
    allocation_size=4UL,
    width=5UL,
    height=6UL,
    pixels=2UL,
    work=3UL,
  )
  let text_charge = @budget.ResourceCharge::new(
    bytes=2UL,
    allocations=2UL,
    allocation_size=7UL,
    width=4UL,
    height=8UL,
    pixels=3UL,
    work=4UL,
  )
  let exact_limits = shape_wb_limits(3UL, 3UL, 7UL, 5UL, 8UL, 5UL, 7UL)
  let (exact_font, _) = shape_wb_open_font()
  let exact_parent = @budget.Budget::new(exact_limits)
  let exact_child = exact_parent.child(exact_limits).unwrap()
  let value = exact_font
    .with_shape_transaction_probes(
      exact_child,
      font_charge,
      shape_wb_noop_probes(),
      fn(scope) {
        inspect(scope.units_per_em().unwrap(), content="1000")
        Ok((37, text_charge))
      },
    )
    .unwrap()
  inspect(value, content="37")
  let expected_after = shape_wb_limits(0UL, 0UL, 7UL, 5UL, 8UL, 0UL, 0UL)
  shape_wb_assert_limits_equal(exact_parent.remaining(), expected_after)
  shape_wb_assert_limits_equal(exact_child.remaining(), expected_after)

  let (short_font, _) = shape_wb_open_font()
  let short_parent = @budget.Budget::new(exact_limits)
  let short_limits = shape_wb_limits(2UL, 3UL, 7UL, 5UL, 8UL, 5UL, 7UL)
  let short_child = short_parent.child(short_limits).unwrap()
  let short_parent_before = short_parent.remaining()
  let short_child_before = short_child.remaining()
  let short_error = short_font
    .with_shape_transaction_probes(
      short_child,
      font_charge,
      shape_wb_noop_probes(),
      fn(_) { Ok(((), text_charge)) },
    )
    .unwrap_err()
  inspect(short_error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(short_error.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(short_error.operation() == Some("budget_charge"), content="true")
  inspect(short_error.context() == Some("bytes"), content="true")
  shape_wb_assert_limits_equal(short_parent.remaining(), short_parent_before)
  shape_wb_assert_limits_equal(short_child.remaining(), short_child_before)

  let (overflow_font, _) = shape_wb_open_font()
  let overflow_parent = @budget.Budget::new(exact_limits)
  let overflow_child = overflow_parent.child(exact_limits).unwrap()
  let overflow_parent_before = overflow_parent.remaining()
  let overflow_child_before = overflow_child.remaining()
  let overflow_error = overflow_font
    .with_shape_transaction_probes(
      overflow_child,
      @budget.ResourceCharge::new(
        bytes=18446744073709551615UL,
        allocations=0UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        work=0UL,
      ),
      shape_wb_noop_probes(),
      fn(_) { Ok(((), @budget.ResourceCharge::bytes(1UL))) },
    )
    .unwrap_err()
  inspect(
    overflow_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    overflow_error.code() == @error.ErrorCode::ArithmeticOverflow,
    content="true",
  )
  inspect(
    overflow_error.operation() == Some("resource-charge-add"),
    content="true",
  )
  inspect(overflow_error.context() == Some("bytes"), content="true")
  shape_wb_assert_limits_equal(
    overflow_parent.remaining(),
    overflow_parent_before,
  )
  shape_wb_assert_limits_equal(
    overflow_child.remaining(),
    overflow_child_before,
  )
}
