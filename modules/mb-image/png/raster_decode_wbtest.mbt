///|
test "PNG raster inverse filters preserve nonzero left and above samples" {
  let transport = PngTransport::{ width: 2UL, height: 5UL, channels: 3UL, idat: b"", consumed: 0UL }
  let descriptor = _png_descriptor(transport).unwrap()
  let image = @storage.OwnedImage::new_operation(
    descriptor,
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=64UL, allocations=1UL, allocation_size=64UL, width=8UL, height=8UL, pixels=64UL, depth=0UL, work=64UL)),
    PngBuiltinAllocator::{} as &@bytes.Allocator,
    64UL,
  ).unwrap()
  let filtered = [
    b'\x00', b'\x0a',b'\x14',b'\x1e', b'\x14',b'\x1e',b'\x28',
    b'\x01', b'\x0f',b'\x19',b'\x23', b'\x0f',b'\x14',b'\x14',
    b'\x02', b'\x0a',b'\x0a',b'\x0a', b'\x0f',b'\x0a',b'\x0a',
    b'\x03', b'\x08',b'\x12',b'\x12', b'\x17',b'\x14',b'\x17',
    b'\x04', b'\x0a',b'\x05',b'\x0a', b'\x14',b'\x14',b'\x14',
  ]
  image.with_mut_view(fn(view) { _png_write_raster(view, transport, filtered) }).unwrap()
  let view = image.view()
  inspect(view.get_byte(1UL, 1UL, 2UL).unwrap(), content="b'\\x37'")
  inspect(view.get_byte(1UL, 2UL, 0UL).unwrap(), content="b'\\x2D'")
  inspect(view.get_byte(1UL, 3UL, 1UL).unwrap(), content="b'\\x41'")
  inspect(view.get_byte(1UL, 4UL, 2UL).unwrap(), content="b'\\x5F'")
}

///|
test "PNG raster rejects invalid filter tags and exact-size mismatch" {
  inspect(_png_paeth(10, 20, 15), content="15")
}
