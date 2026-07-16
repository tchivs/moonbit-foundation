///|
fn expect_lease(result : Result[MutByteLease, @error.CoreError]) -> MutByteLease {
  match result {
    Ok(lease) => lease
    Err(_) => abort("mutable lease must be acquired")
  }
}

///|
test "exclusive lease mutates and rejects an overlapping acquisition" {
  let owner = LeaseOwner::new(4)
  let lease = expect_lease(owner.acquire_mut(0UL, 4UL))
  inspect(lease.set(1UL, b'\x2a') is Ok(_), content="true")
  match lease.get(1UL) {
    Ok(value) => inspect(value == b'\x2a', content="true")
    Err(_) => fail("active lease read must succeed")
  }
  match owner.acquire_mut(1UL, 1UL) {
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::State, content="true")
      inspect(error.context() == Some("lease-active"), content="true")
    }
    Ok(_) => fail("a second mutable lease must be rejected")
  }
  lease.release()
}

///|
test "callback cleanup invalidates stale handles and permits reacquisition" {
  let owner = LeaseOwner::new(2)
  let mut retained : MutByteLease? = None
  let result = owner.with_mut(0UL, 2UL, fn(lease) {
    retained = Some(lease)
    lease.set(0UL, b'\x07')
  })
  inspect(result is Ok(_), content="true")
  let stale = match retained {
    Some(lease) => lease
    None => fail("callback must receive the lease")
  }
  match stale.get(0UL) {
    Err(error) => inspect(error.context() == Some("lease-inactive"), content="true")
    Ok(_) => fail("a lease must be stale after callback cleanup")
  }
  let next = expect_lease(owner.acquire_mut(0UL, 2UL))
  next.release()
  next.release()
}

///|
test "checked split consumes parent and yields disjoint active children" {
  let owner = LeaseOwner::new(4)
  let parent = expect_lease(owner.acquire_mut(0UL, 4UL))
  let (left, right) = match parent.split_mut(2UL) {
    Ok(children) => children
    Err(_) => fail("in-range split must succeed")
  }
  inspect(parent.set(0UL, b'\x01') is Err(_), content="true")
  inspect(left.set(1UL, b'\x0b') is Ok(_), content="true")
  inspect(right.set(0UL, b'\x16') is Ok(_), content="true")
  match left.get(1UL) {
    Ok(value) => inspect(value == b'\x0b', content="true")
    Err(_) => fail("left child must remain active")
  }
  match right.get(0UL) {
    Ok(value) => inspect(value == b'\x16', content="true")
    Err(_) => fail("right child must remain active")
  }
  inspect(owner.acquire_mut(0UL, 4UL) is Err(_), content="true")
  left.release()
  inspect(owner.acquire_mut(0UL, 4UL) is Err(_), content="true")
  right.release()
  let next = expect_lease(owner.acquire_mut(0UL, 4UL))
  next.release()
}

///|
test "split validates relative bounds without consuming the parent" {
  let owner = LeaseOwner::new(3)
  let parent = expect_lease(owner.acquire_mut(0UL, 3UL))
  match parent.split_mut(4UL) {
    Err(error) => inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    Ok(_) => fail("out-of-range split must fail")
  }
  inspect(parent.set(2UL, b'\x09') is Ok(_), content="true")
  parent.release()
}
