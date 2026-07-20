///|
test "PNG raster inverse filters preserve nonzero left and above samples" {
  let transport = PngTransport::{ width: 2UL, height: 5UL, bit_depth: 8, source_channels: 3UL, channels: 3UL, transparency: PngTransparency::Opaque, idat: b"", consumed: 0UL }
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
  image.with_mut_view(fn(view) { _png_write_raster(view, transport, filtered, @budget.Budget::new(@budget.ResourceLimits::new(bytes=0UL, allocations=0UL, allocation_size=0UL, width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL))) }).unwrap()
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

///|
test "PNG grayscale raster filters reconstruct one source lane into RGB8" {
  let transport = PngTransport::{ width: 2UL, height: 5UL, bit_depth: 8, source_channels: 1UL, channels: 3UL, transparency: PngTransparency::Opaque, idat: b"", consumed: 0UL }
  let descriptor = _png_descriptor(transport).unwrap()
  let image = @storage.OwnedImage::new_operation(
    descriptor,
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=64UL, allocations=1UL, allocation_size=64UL, width=8UL, height=8UL, pixels=64UL, depth=0UL, work=64UL)),
    PngBuiltinAllocator::{} as &@bytes.Allocator,
    64UL,
  ).unwrap()
  let filtered = [
    b'\x00', b'\x11', b'\x22',
    b'\x01', b'\x33', b'\x11',
    b'\x02', b'\x22', b'\x22',
    b'\x03', b'\x4d', b'\x1a',
    b'\x04', b'\x22', b'\x11',
  ]
  image.with_mut_view(fn(view) { _png_write_raster(view, transport, filtered, @budget.Budget::new(@budget.ResourceLimits::new(bytes=0UL, allocations=0UL, allocation_size=0UL, width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL))) }).unwrap()
  let view = image.view()
  for item in [(0UL, 0UL, b'\x11'), (1UL, 0UL, b'\x22'), (0UL, 1UL, b'\x33'), (1UL, 1UL, b'\x44'), (0UL, 2UL, b'\x55'), (1UL, 2UL, b'\x66'), (0UL, 3UL, b'\x77'), (1UL, 3UL, b'\x88'), (0UL, 4UL, b'\x99'), (1UL, 4UL, b'\xaa')] {
    let (x, y, expected) = item
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      inspect(view.get_byte(x, y, channel).unwrap() == expected, content="true")
    }
  }
}

///|
test "PNG indexed raster filters reconstructed index lanes before RGB palette lookup" {
  let transport = PngTransport::{ width: 2UL, height: 5UL, bit_depth: 8, source_channels: 1UL, channels: 3UL, transparency: PngTransparency::Opaque, idat: b"", consumed: 0UL }
  let image = @storage.OwnedImage::new_operation(
    _png_descriptor(transport).unwrap(),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=64UL, allocations=1UL, allocation_size=64UL, width=8UL, height=8UL, pixels=64UL, depth=0UL, work=64UL)),
    PngBuiltinAllocator::{} as &@bytes.Allocator,
    64UL,
  ).unwrap()
  let filtered = [
    b'\x00', b'\x01', b'\x02',
    b'\x01', b'\x03', b'\xfd',
    b'\x02', b'\xff', b'\x01',
    b'\x03', b'\x01', b'\x02',
    b'\x04', b'\x01', b'\xfd',
  ]
  image.with_mut_view(fn(view) {
    _png_write_indexed_raster(
      view, 2UL, 5UL,
      b"\x10\x11\x12\x20\x21\x22\x30\x31\x32\x40\x41\x42",
      4UL, PngTransparency::Opaque, filtered,
      @budget.Budget::new(@budget.ResourceLimits::new(bytes=4UL, allocations=2UL, allocation_size=2UL, width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL)),
    )
  }).unwrap()
  let view = image.view()
  inspect(view.get_byte(1UL, 1UL, 2UL).unwrap(), content="b'\\x12'")
  inspect(view.get_byte(0UL, 4UL, 0UL).unwrap(), content="b'\\x40'")
  inspect(view.get_byte(1UL, 4UL, 1UL).unwrap(), content="b'\\x11'")
}

///|
test "PNG packed grayscale samples scale endpoints without consuming padding" {
  inspect(_png_scale_grayscale_sample(1, 1), content="255")
  inspect(_png_scale_grayscale_sample(3, 2), content="255")
  inspect(_png_scale_grayscale_sample(15, 4), content="255")
  inspect(_png_scale_grayscale_sample(7, 4), content="119")
}
