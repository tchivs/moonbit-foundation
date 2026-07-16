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
priv struct LeaseOwner {
  backing : FixedArray[Byte]
  mut leased : Bool
}

///|
fn LeaseOwner::from_backing(backing : FixedArray[Byte]) -> LeaseOwner {
  { backing, leased: false }
}

///|
struct LeaseGroup {
  owner : LeaseOwner
  mut live_handles : Int
  mut scope_active : Bool
  mut owner_restored : Bool
}

///|
fn LeaseGroup::restore_owner_once(self : LeaseGroup) -> Unit {
  if !self.owner_restored {
    self.owner_restored = true
    self.owner.leased = false
  }
}

///|
fn LeaseGroup::cleanup_scope(self : LeaseGroup) -> Unit {
  if self.scope_active {
    self.scope_active = false
    self.live_handles = 0
    self.restore_owner_once()
  }
}

///|
struct LeaseState {
  mut active : Bool
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
  let full = match
    @checked.CheckedRange::from_start_length(
      0UL,
      self.backing.length().to_uint64(),
    ) {
    Ok(range) => range
    Err(error) => return Err(error)
  }
  let window = match full.subrange(start, length) {
    Ok(range) => range
    Err(_) =>
      return Err(lease_range_error("acquire_mut", length, full.length()))
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
    group: {
      owner: self,
      live_handles: 1,
      scope_active: true,
      owner_restored: false,
    },
  })
}

///|
fn[T] LeaseOwner::with_mut(
  self : LeaseOwner,
  start : UInt64,
  length : UInt64,
  body : (MutByteLease) -> Result[T, @error.CoreError],
) -> Result[T, @error.CoreError] {
  match self.acquire_mut(start, length) {
    Err(error) => Err(error)
    Ok(lease) => {
      defer lease.group.cleanup_scope()
      body(lease)
    }
  }
}

///|
/// An opaque retained immutable byte window. The backing allocation remains
/// reachable through the view, while its representation stays private.
pub struct ByteView {
  priv backing : FixedArray[Byte]
  priv start : Int
  priv length_value : Int
}

///|
pub fn ByteView::length(self : ByteView) -> UInt64 {
  self.length_value.to_uint64()
}

///|
pub fn ByteView::get(
  self : ByteView,
  index : UInt64,
) -> Result[Byte, @error.CoreError] {
  let index_value = match @checked.checked_narrow_int(index) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if index_value < 0 || index_value >= self.length_value {
    Err(lease_range_error("byte_view_get", index, self.length()))
  } else {
    Ok(self.backing[self.start + index_value])
  }
}

///|
/// Create a zero-copy retained subview after validating the requested window
/// relative to the current view.
pub fn ByteView::subview(
  self : ByteView,
  relative_start : UInt64,
  length : UInt64,
) -> Result[ByteView, @error.CoreError] {
  let current = match
    @checked.CheckedRange::from_start_length(
      self.start.to_uint64(),
      self.length(),
    ) {
    Ok(range) => range
    Err(error) => return Err(error)
  }
  let window = match current.subrange(relative_start, length) {
    Ok(range) => range
    Err(_) =>
      return Err(lease_range_error("byte_subview", length, self.length()))
  }
  let start = match @checked.checked_narrow_int(window.start()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let view_length = match @checked.checked_narrow_int(window.length()) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ backing: self.backing, start, length_value: view_length })
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
  if !self.state.active || !self.group.scope_active {
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
    if self.group.scope_active && self.group.live_handles > 0 {
      self.group.live_handles = self.group.live_handles - 1
      if self.group.live_handles == 0 {
        self.group.restore_owner_once()
      }
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
  if !self.state.active || !self.group.scope_active {
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
  self.group.live_handles = self.group.live_handles + 1
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
