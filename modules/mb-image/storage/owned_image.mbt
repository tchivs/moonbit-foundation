///|
priv struct ImageBuiltinAllocator {}

///|
impl @bytes.Allocator for ImageBuiltinAllocator with fn approve(_self, _length) {
  Ok(())
}

///|
/// An image whose validated descriptor and independently owned byte storage
/// have the same lifetime. Mutable backing is available only through callbacks.
pub struct OwnedImage {
  priv descriptor_value : @model.ImageDescriptor
  priv storage : @bytes.OwnedBytes
}

///|
pub fn OwnedImage::new(
  descriptor : @model.ImageDescriptor,
  budget : @budget.Budget,
) -> Result[OwnedImage, @error.CoreError] {
  OwnedImage::new_with_allocator(
    descriptor,
    budget,
    ImageBuiltinAllocator::{  } as &@bytes.Allocator,
  )
}

///|
pub fn OwnedImage::new_with_allocator(
  descriptor : @model.ImageDescriptor,
  budget : @budget.Budget,
  allocator : &@bytes.Allocator,
) -> Result[OwnedImage, @error.CoreError] {
  OwnedImage::new_operation(descriptor, budget, allocator, 0UL)
}

///|
/// Allocate fresh operation output with one authoritative storage-and-work
/// charge. Dimensions and pixels are derived from the already validated
/// descriptor; callers provide only the explicit deterministic operation work.
pub fn OwnedImage::new_operation(
  descriptor : @model.ImageDescriptor,
  budget : @budget.Budget,
  allocator : &@bytes.Allocator,
  work : UInt64,
) -> Result[OwnedImage, @error.CoreError] {
  let storage = match
    @bytes.OwnedBytes::new_with_allocator_and_charge(
      descriptor.storage_length(),
      budget,
      allocator,
      descriptor.width(),
      descriptor.height(),
      descriptor.pixel_count(),
      work,
    ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ descriptor_value: descriptor, storage })
}

///|
pub fn OwnedImage::descriptor(self : OwnedImage) -> @model.ImageDescriptor {
  self.descriptor_value
}

///|
pub fn OwnedImage::metadata(self : OwnedImage) -> @model.ImageMetadata {
  self.descriptor_value.metadata()
}

///|
pub fn OwnedImage::storage_length(self : OwnedImage) -> UInt64 {
  self.storage.length()
}

///|
pub fn OwnedImage::view(self : OwnedImage) -> ImageView {
  ImageView::from_owned(self.descriptor_value, self.storage.view())
}

///|
/// Acquire one enclosing backing lease and invalidate every logical descendant
/// when the callback exits, including structured-error exits.
pub fn[T] OwnedImage::with_mut_view(
  self : OwnedImage,
  body : (MutImageView) -> Result[T, @error.CoreError],
) -> Result[T, @error.CoreError] {
  match
    require_packed_u8_view(
      self.descriptor_value.format(),
      "owned-image-with-mut-view",
      "packed-u8-mut-view-required",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  self.storage.with_mut(0UL, self.storage.length(), fn(lease) {
    body(MutImageView::from_owned(self.descriptor_value, lease))
  })
}
