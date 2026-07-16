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
  OwnedImage::new_operation(
    descriptor,
    budget,
    allocator,
    descriptor.width(),
    descriptor.height(),
    descriptor.pixel_count(),
    0UL,
  )
}

///|
/// Allocate fresh operation output with one authoritative storage-and-work
/// charge. Callers pass scalars rather than a prebuilt charge to prevent
/// inspection, precharging, or double charging across package boundaries.
pub fn OwnedImage::new_operation(
  descriptor : @model.ImageDescriptor,
  budget : @budget.Budget,
  allocator : &@bytes.Allocator,
  width : UInt64,
  height : UInt64,
  pixels : UInt64,
  work : UInt64,
) -> Result[OwnedImage, @error.CoreError] {
  let storage = match
    @bytes.OwnedBytes::new_with_allocator_and_charge(
      descriptor.storage_length(),
      budget,
      allocator,
      width,
      height,
      pixels,
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
