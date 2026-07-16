///|
fn expect_lease(
  result : Result[MutByteLease, @error.CoreError],
) -> MutByteLease {
  match result {
    Ok(lease) => lease
    Err(_) => abort("mutable lease must be acquired")
  }
}

///|
test "exclusive lease mutates and rejects an overlapping acquisition" {
  let owner = LeaseOwner::from_backing(FixedArray::make(4, b'\x00'))
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
  let owner = LeaseOwner::from_backing(FixedArray::make(2, b'\x00'))
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
    Err(error) =>
      inspect(error.context() == Some("lease-inactive"), content="true")
    Ok(_) => fail("a lease must be stale after callback cleanup")
  }
  let next = expect_lease(owner.acquire_mut(0UL, 2UL))
  next.release()
  next.release()
}

///|
test "checked split consumes parent and yields disjoint active children" {
  let owner = LeaseOwner::from_backing(FixedArray::make(4, b'\x00'))
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
  let owner = LeaseOwner::from_backing(FixedArray::make(3, b'\x00'))
  let parent = expect_lease(owner.acquire_mut(0UL, 3UL))
  match parent.split_mut(4UL) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    Ok(_) => fail("out-of-range split must fail")
  }
  inspect(parent.set(2UL, b'\x09') is Ok(_), content="true")
  parent.release()
}

///|
test "callback cleanup invalidates nested descendants and restores owner once" {
  let owner = LeaseOwner::from_backing(FixedArray::make(6, b'\x00'))
  let mut retained_left : MutByteLease? = None
  let mut retained_middle : MutByteLease? = None
  let mut retained_right : MutByteLease? = None
  let result = owner.with_mut(0UL, 6UL, fn(parent) {
    let (left, tail) = parent.split_mut(2UL).unwrap()
    let (middle, right) = tail.split_mut(2UL).unwrap()
    retained_left = Some(left)
    retained_middle = Some(middle)
    retained_right = Some(right)
    Ok(())
  })
  inspect(result is Ok(_), content="true")
  inspect(owner.leased, content="false")
  let left = retained_left.unwrap()
  let middle = retained_middle.unwrap()
  let right = retained_right.unwrap()
  inspect(left.get(0UL) is Err(_), content="true")
  inspect(middle.set(0UL, b'\x01') is Err(_), content="true")
  inspect(right.split_mut(1UL) is Err(_), content="true")
  inspect(left.group.live_handles, content="0")
  left.release()
  middle.release()
  right.release()
  inspect(left.group.live_handles, content="0")
  inspect(owner.leased, content="false")
  let next = expect_lease(owner.acquire_mut(0UL, 6UL))
  next.release()
}

///|
test "callback cleanup tolerates zero one or all explicit child releases" {
  let owner_zero = LeaseOwner::from_backing(FixedArray::make(2, b'\x00'))
  inspect(
    owner_zero.with_mut(0UL, 2UL, fn(parent) {
      ignore(parent.split_mut(1UL).unwrap())
      Ok(())
    })
    is Ok(_),
    content="true",
  )
  inspect(owner_zero.leased, content="false")

  let owner_one = LeaseOwner::from_backing(FixedArray::make(2, b'\x00'))
  inspect(
    owner_one.with_mut(0UL, 2UL, fn(parent) {
      let (left, _right) = parent.split_mut(1UL).unwrap()
      left.release()
      Ok(())
    })
    is Ok(_),
    content="true",
  )
  inspect(owner_one.leased, content="false")

  let owner_all = LeaseOwner::from_backing(FixedArray::make(2, b'\x00'))
  inspect(
    owner_all.with_mut(0UL, 2UL, fn(parent) {
      let (left, right) = parent.split_mut(1UL).unwrap()
      left.release()
      right.release()
      Ok(())
    })
    is Ok(_),
    content="true",
  )
  inspect(owner_all.leased, content="false")
}

///|
test "retained view shares owned backing without exposing it" {
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=2UL,
      allocations=1UL,
      allocation_size=2UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
  let owned = match OwnedBytes::new(2UL, budget) {
    Ok(value) => value
    Err(_) => fail("owned storage must construct")
  }
  let before = owned.view()
  inspect(
    owned.with_mut(0UL, 2UL, fn(lease) { lease.set(1UL, b'\x2a') }) is Ok(_),
    content="true",
  )
  match before.get(1UL) {
    Ok(value) => inspect(value == b'\x2a', content="true")
    Err(_) => fail("view must retain the shared backing")
  }
}
