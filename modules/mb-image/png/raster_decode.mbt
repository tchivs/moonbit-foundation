///|
priv struct PngBuiltinAllocator {}

///|
impl @bytes.Allocator for PngBuiltinAllocator with fn approve(_self, _length) { Ok(()) }

///|
fn _png_empty_metadata(channels : UInt64) -> Result[@model.ImageMetadata, @error.CoreError] {
  let empty_opaque = match @metadata.OpaqueMetadata::from_entries(
    [], @metadata.MetadataLimits::new(max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL, max_total_bytes=0UL, max_disposition_fields=0UL), _png_private_budget(0UL),
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
    if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
    @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft, empty_opaque,
  ))
}

///|
fn _png_descriptor(transport : PngTransport) -> Result[@model.ImageDescriptor, @error.CoreError] {
  let pixels = match @checked.checked_mul(transport.width, transport.height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let payload = match @checked.checked_mul(pixels, transport.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let row = match @checked.checked_mul(transport.width, transport.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let plane = match @model.PlaneDescriptor::new(0UL, payload, row, row, 1UL, 1UL, transport.width, transport.height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let metadata = match _png_empty_metadata(transport.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @model.ImageDescriptor::new(
    transport.width, transport.height,
    if transport.channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [plane], payload, metadata,
  )
}

///|
fn _png_paeth(a : Int, b : Int, c : Int) -> Int {
  let p = a + b - c
  let pa = (p - a).abs()
  let pb = (p - b).abs()
  let pc = (p - c).abs()
  if pa <= pb && pa <= pc { a } else if pb <= pc { b } else { c }
}

///|
fn _png_get(view : @storage.MutImageView, x : UInt64, y : UInt64, channel : UInt64) -> Result[Int, @error.CoreError] {
  match view.get_byte(x, y, channel) {
    Err(error) => Err(error)
    Ok(value) => Ok(value.to_int())
  }
}

///|
fn _png_write_raster(view : @storage.MutImageView, transport : PngTransport, filtered : Array[Byte]) -> Result[Unit, @error.CoreError] {
  let row_bytes = match @checked.checked_mul(transport.width, transport.source_channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let expected = match @checked.checked_mul(row_bytes + 1UL, transport.height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if filtered.length().to_uint64() != expected { return Err(_png_error("png-filtered-size")) }
  let mut offset = 0UL
  for y = 0UL; y < transport.height; y = y + 1UL {
    let filter = filtered[offset.to_int()].to_int()
    if filter > 4 { return Err(_png_error("png-filter")) }
    offset = offset + 1UL
    for column = 0UL; column < row_bytes; column = column + 1UL {
      let x = column / transport.source_channels
      let channel = column % transport.source_channels
      let left = if column >= transport.source_channels {
        match _png_get(view, x - 1UL, y, channel) { Err(error) => return Err(error); Ok(value) => value }
      } else { 0 }
      let above = if y > 0UL {
        match _png_get(view, x, y - 1UL, channel) { Err(error) => return Err(error); Ok(value) => value }
      } else { 0 }
      let upper_left = if y > 0UL && column >= transport.source_channels {
        match _png_get(view, x - 1UL, y - 1UL, channel) { Err(error) => return Err(error); Ok(value) => value }
      } else { 0 }
      let raw = filtered[offset.to_int()].to_int()
      let value = if filter == 0 { raw } else if filter == 1 { raw + left } else if filter == 2 { raw + above } else if filter == 3 { raw + ((left + above) / 2) } else { raw + _png_paeth(left, above, upper_left) }
      if transport.source_channels == 1UL {
        for output_channel = 0UL; output_channel < 3UL; output_channel = output_channel + 1UL {
          match view.set_byte(x, y, output_channel, value.to_byte()) {
            Err(error) => return Err(error)
            Ok(_) => ()
          }
        }
      } else {
        match view.set_byte(x, y, channel, value.to_byte()) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      }
      offset = offset + 1UL
    }
  }
  Ok(())
}

///|
fn _png_empty_disposition() -> Result[@metadata.MetadataDisposition, @error.CoreError] {
  @metadata.MetadataDisposition::new([], [], [], false, @metadata.MetadataLimits::new(max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL, max_total_bytes=0UL, max_disposition_fields=0UL))
}
