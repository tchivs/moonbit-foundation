///|
fn byte_limits(bytes : UInt64) -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes~,
    allocations=4UL,
    allocation_size=bytes,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=0UL,
  )
}

///|
struct RejectingAllocator {}

///|
impl @bytes.Allocator for RejectingAllocator with fn approve(_self, requested) {
  Err(
    @error.CoreError::new(
      @error.ErrorCategory::Resource,
      @error.ErrorCode::AllocationFailed,
      operation="rejecting_allocator",
      requested~,
    ),
  )
}

///|
test "owned bytes charge budget before built-in allocation" {
  let budget = @budget.Budget::new(byte_limits(4UL))
  let owned = match @bytes.OwnedBytes::new(4UL, budget) {
    Ok(value) => value
    Err(_) => fail("bounded allocation must succeed")
  }
  inspect(owned.length(), content="4")
  inspect(budget.remaining().bytes(), content="0")
  inspect(budget.remaining().allocations(), content="3")
  match @bytes.OwnedBytes::new(1UL, budget) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    Ok(_) => fail("budget rejection must precede allocation")
  }
}

///|
test "injected allocator rejection is structured and does not consume budget" {
  let budget = @budget.Budget::new(byte_limits(8UL))
  let allocator = RejectingAllocator::{  } as &@bytes.Allocator
  match @bytes.OwnedBytes::new_with_allocator(4UL, budget, allocator) {
    Err(error) =>
      inspect(
        error.code() == @error.ErrorCode::AllocationFailed,
        content="true",
      )
    Ok(_) => fail("injected rejection must not allocate")
  }
  inspect(budget.remaining().bytes(), content="8")
  inspect(budget.remaining().allocations(), content="4")
}

///|
test "immutable views retain backing and validate relative subviews" {
  let budget = @budget.Budget::new(byte_limits(4UL))
  let owned = match @bytes.OwnedBytes::from_bytes(b"abcd", budget) {
    Ok(value) => value
    Err(_) => fail("external immutable bytes must copy")
  }
  let retained = owned.view()
  let middle = match retained.subview(1UL, 2UL) {
    Ok(value) => value
    Err(_) => fail("relative subview must succeed")
  }
  match middle.get(0UL) {
    Ok(value) => inspect(value == b'b', content="true")
    Err(_) => fail("validated access must succeed")
  }
  let empty = match middle.subview(2UL, 0UL) {
    Ok(value) => value
    Err(_) => fail("empty subview at exact end must succeed")
  }
  inspect(empty.length(), content="0")
  inspect(middle.subview(2UL, 1UL) is Err(_), content="true")
  inspect(middle.get(2UL) is Err(_), content="true")
}

///|
test "external immutable bytes are copied and mutable access is callback scoped" {
  let source = b"abc"
  let budget = @budget.Budget::new(byte_limits(3UL))
  let owned = match @bytes.OwnedBytes::from_bytes(source, budget) {
    Ok(value) => value
    Err(_) => fail("copy construction must succeed")
  }
  let changed = owned.with_mut(0UL, 3UL, fn(lease) { lease.set(0UL, b'z') })
  inspect(changed is Ok(_), content="true")
  inspect(source[0] == b'a', content="true")
  match owned.view().get(0UL) {
    Ok(value) => inspect(value == b'z', content="true")
    Err(_) => fail("retained view must observe owned backing")
  }
}

///|
test "split descendants are stale after normal callback exit and owner reacquires" {
  let budget = @budget.Budget::new(byte_limits(4UL))
  let owned = match @bytes.OwnedBytes::from_bytes(b"abcd", budget) {
    Ok(value) => value
    Err(_) => fail("owned storage must construct")
  }
  let mut retained_left : @bytes.MutByteLease? = None
  let mut retained_right : @bytes.MutByteLease? = None
  let result = owned.with_mut(0UL, 4UL, fn(parent) {
    let (left, right) = match parent.split_mut(2UL) {
      Ok(children) => children
      Err(_) =>
        return Err(
          @error.CoreError::new(
            @error.ErrorCategory::State,
            @error.ErrorCode::InvalidRange,
            operation="test_split",
          ),
        )
    }
    retained_left = Some(left)
    retained_right = Some(right)
    left.set(0UL, b'A')
  })
  inspect(result is Ok(_), content="true")
  let left = retained_left.unwrap()
  let right = retained_right.unwrap()
  inspect(left.get(0UL) is Err(_), content="true")
  inspect(left.set(0UL, b'X') is Err(_), content="true")
  inspect(right.split_mut(1UL) is Err(_), content="true")
  left.release()
  right.release()
  let reacquired = owned.with_mut(0UL, 4UL, fn(lease) { lease.set(3UL, b'Z') })
  inspect(reacquired is Ok(_), content="true")
  inspect(owned.view().get(3UL).unwrap() == b'Z', content="true")
}

///|
test "split descendants are stale after structured error and error is preserved" {
  let budget = @budget.Budget::new(byte_limits(4UL))
  let owned = @bytes.OwnedBytes::from_bytes(b"abcd", budget).unwrap()
  let mut retained_left : @bytes.MutByteLease? = None
  let mut retained_right : @bytes.MutByteLease? = None
  let result : Result[Unit, @error.CoreError] = owned.with_mut(0UL, 4UL, fn(
    parent,
  ) {
    let (left, right) = parent.split_mut(2UL).unwrap()
    retained_left = Some(left)
    retained_right = Some(right)
    Err(
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="callback_failure",
        context="preserved",
      ),
    )
  })
  match result {
    Err(error) => {
      inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
      inspect(error.context() == Some("preserved"), content="true")
    }
    Ok(_) => fail("callback error must be preserved")
  }
  let left = retained_left.unwrap()
  let right = retained_right.unwrap()
  inspect(left.get(0UL) is Err(_), content="true")
  inspect(right.set(0UL, b'X') is Err(_), content="true")
  left.release()
  left.release()
  right.release()
  right.release()
  inspect(
    owned.with_mut(0UL, 1UL, fn(lease) { lease.set(0UL, b'Q') }) is Ok(_),
    content="true",
  )
}

///|
test "range and backend-width failures remain distinct from allocation rejection" {
  let budget = @budget.Budget::new(byte_limits(8UL))
  match @bytes.OwnedBytes::new(2147483648UL, budget) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NarrowingFailed, content="true")
    Ok(_) => fail("unrepresentable backend length must reject")
  }
  let owned = match @bytes.OwnedBytes::new(2UL, budget) {
    Ok(value) => value
    Err(_) => fail("small allocation must succeed")
  }
  match owned.view().subview(2UL, 1UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    Ok(_) => fail("escaping subview must reject")
  }
}
