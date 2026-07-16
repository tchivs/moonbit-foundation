///|
fn lease_state_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation="mutable_lease",
    context~,
  )
}

///|
fn lease_range_error(
  operation : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation~,
    requested~,
    limit~,
  )
}

///|
struct LeaseOwner {
  backing : FixedArray[Byte]
  priv mut leased : Bool
}

///|
fn LeaseOwner::new(length : Int) -> LeaseOwner {
  { backing: FixedArray::make(length, b'\x00'), leased: false }
}

///|
struct LeaseGroup {
  owner : LeaseOwner
  priv mut live_handles : Int
}

///|
struct LeaseState {
  priv mut active : Bool
}

///|
/// An opaque runtime-validated exclusive mutable window. The backing array is
/// never exposed. Every access verifies both the handle and its checked range.
pub struct MutByteLease {
  priv backing : FixedArray[Byte]
  priv start : Int
  priv length_value : Int
  priv state : LeaseState
  priv group : LeaseGroup
}

///|
fn LeaseOwner::acquire_mut(
  self : LeaseOwner,
  start : UInt64,
  length : UInt64,
) -> Result[MutByteLease, @error.CoreError] {
  if self.leased {
    return Err(lease_state_error("lease-active"))
  }
  let full = match @checked.CheckedRange::from_start_length(
    0UL,
    self.backing.length().to_uint64(),
  ) {
    Ok(range) => range
    Err(error) => return Err(error)
  }
  let window = match full.subrange(start, length) {
    Ok(range) => range
    Err(_) => return Err(lease_range_error("acquire_mut", length, full.length()))
  }
  let start_index = match @checked.checked_narrow_int(window.start()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let length_index = match @checked.checked_narrow_int(window.length()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  self.leased = true
  Ok({
    backing: self.backing,
    start: start_index,
    length_value: length_index,
    state: { active: true },
    group: { owner: self, live_handles: 1 },
  })
}

///|
fn LeaseOwner::with_mut[T](
  self : LeaseOwner,
  start : UInt64,
  length : UInt64,
  body : (MutByteLease) -> Result[T, @error.CoreError],
) -> Result[T, @error.CoreError] {
  match self.acquire_mut(start, length) {
    Err(error) => Err(error)
    Ok(lease) => {
      defer lease.release()
      body(lease)
    }
  }
}

///|
pub fn MutByteLease::length(self : MutByteLease) -> UInt64 {
  self.length_value.to_uint64()
}

///|
fn MutByteLease::checked_index(
  self : MutByteLease,
  index : UInt64,
) -> Result[Int, @error.CoreError] {
  if !self.state.active {
    return Err(lease_state_error("lease-inactive"))
  }
  let index_value = match @checked.checked_narrow_int(index) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if index_value < 0 || index_value >= self.length_value {
    Err(lease_range_error("lease_index", index, self.length()))
  } else {
    Ok(self.start + index_value)
  }
}

///|
pub fn MutByteLease::get(
  self : MutByteLease,
  index : UInt64,
) -> Result[Byte, @error.CoreError] {
  match self.checked_index(index) {
    Err(error) => Err(error)
    Ok(absolute) => Ok(self.backing[absolute])
  }
}

///|
pub fn MutByteLease::set(
  self : MutByteLease,
  index : UInt64,
  value : Byte,
) -> Result[Unit, @error.CoreError] {
  match self.checked_index(index) {
    Err(error) => Err(error)
    Ok(absolute) => {
      self.backing[absolute] = value
      Ok(())
    }
  }
}

///|
pub fn MutByteLease::release(self : MutByteLease) -> Unit {
  if self.state.active {
    self.state.active = false
    self.group.live_handles = self.group.live_handles - 1
    if self.group.live_handles == 0 {
      self.group.owner.leased = false
    }
  }
}

///|
/// Consume the logical parent and replace it with two disjoint children. The
/// parent is invalidated only after the split point is validated.
pub fn MutByteLease::split_mut(
  self : MutByteLease,
  at : UInt64,
) -> Result[(MutByteLease, MutByteLease), @error.CoreError] {
  if !self.state.active {
    return Err(lease_state_error("lease-inactive"))
  }
  let split = match @checked.checked_narrow_int(at) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if split < 0 || split > self.length_value {
    return Err(lease_range_error("split_mut", at, self.length()))
  }
  self.state.active = false
  self.group.live_handles = 2
  let left = MutByteLease::{
    backing: self.backing,
    start: self.start,
    length_value: split,
    state: { active: true },
    group: self.group,
  }
  let right = MutByteLease::{
    backing: self.backing,
    start: self.start + split,
    length_value: self.length_value - split,
    state: { active: true },
    group: self.group,
  }
  Ok((left, right))
}
