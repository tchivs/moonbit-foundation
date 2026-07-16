///|
/// A deterministic pre-allocation seam. Implementations can reject an
/// allocation request with `AllocationFailed`; approved requests still use the
/// portable built-in storage. Built-in physical OOM is not a catchable portable
/// result and is deliberately not represented by this contract.
pub(open) trait Allocator {
  fn approve(Self, UInt64) -> Result[Unit, @error.CoreError]
}

///|
priv struct BuiltinAllocator {}

///|
impl Allocator for BuiltinAllocator with fn approve(_self, _requested) {
  Ok(())
}

///|
/// Opaque owned mutable byte storage. Neither the backing `FixedArray` nor a
/// raw mutable view is exposed.
pub struct OwnedBytes {
  priv owner : LeaseOwner
}

///|
fn allocation_charge(length : UInt64) -> @budget.ResourceCharge {
  @budget.ResourceCharge::new(
    bytes=length,
    allocations=1UL,
    allocation_size=length,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=0UL,
  )
}

///|
/// Construct portable built-in storage after checked narrowing and budget
/// precharge. Physical runtime OOM remains unrecoverable on the pinned
/// toolchain; range, budget, and injected allocator rejection are structured.
pub fn OwnedBytes::new(
  length : UInt64,
  budget : @budget.Budget,
) -> Result[OwnedBytes, @error.CoreError] {
  let allocator = BuiltinAllocator::{  } as &Allocator
  OwnedBytes::new_with_allocator(length, budget, allocator)
}

///|
pub fn OwnedBytes::new_with_allocator(
  length : UInt64,
  budget : @budget.Budget,
  allocator : &Allocator,
) -> Result[OwnedBytes, @error.CoreError] {
  let backend_length = match @checked.checked_narrow_int(length) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match allocator.approve(length) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match budget.charge(allocation_charge(length)) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let backing = FixedArray::make(backend_length, b'\x00')
  Ok({ owner: LeaseOwner::from_backing(backing) })
}

///|
/// Copy immutable external bytes into independently owned mutable storage.
pub fn OwnedBytes::from_bytes(
  source : Bytes,
  budget : @budget.Budget,
) -> Result[OwnedBytes, @error.CoreError] {
  let length = source.length()
  let owned = match OwnedBytes::new(length.to_uint64(), budget) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  owned.owner.backing.blit_from_bytes(0, source, 0, length)
  Ok(owned)
}

///|
pub fn OwnedBytes::length(self : OwnedBytes) -> UInt64 {
  self.owner.backing.length().to_uint64()
}

///|
pub fn OwnedBytes::view(self : OwnedBytes) -> ByteView {
  ByteView::{
    backing: self.owner.backing,
    start: 0,
    length_value: self.owner.backing.length(),
  }
}

///|
/// Mutable access is callback scoped. Cleanup is deferred so normal and
/// structured-error returns both invalidate the lease deterministically.
pub fn[T] OwnedBytes::with_mut(
  self : OwnedBytes,
  start : UInt64,
  length : UInt64,
  body : (MutByteLease) -> Result[T, @error.CoreError],
) -> Result[T, @error.CoreError] {
  self.owner.with_mut(start, length, body)
}
