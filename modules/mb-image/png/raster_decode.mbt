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
priv struct PngIndexRows {
  mut current : @bytes.OwnedBytes
  mut previous : @bytes.OwnedBytes
}

///|
fn _png_new_index_rows(
  width : UInt64,
  budget : @budget.Budget,
) -> Result[PngIndexRows, @error.CoreError] {
  let current = match @bytes.OwnedBytes::new(width, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let previous = match @bytes.OwnedBytes::new(width, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ current, previous })
}

///|
fn PngIndexRows::reconstruct(
  self : PngIndexRows,
  column : UInt64,
  row : UInt64,
  filter : Int,
  raw : Int,
) -> Result[Byte, @error.CoreError] {
  let left = if column > 0UL {
    self.current.view().get(column - 1UL).unwrap().to_int()
  } else { 0 }
  let above = if row > 0UL {
    self.previous.view().get(column).unwrap().to_int()
  } else { 0 }
  let upper_left = if row > 0UL && column > 0UL {
    self.previous.view().get(column - 1UL).unwrap().to_int()
  } else { 0 }
  let value = if filter == 0 { raw } else if filter == 1 { raw + left } else if filter == 2 { raw + above } else if filter == 3 { raw + ((left + above) / 2) } else { raw + _png_paeth(left, above, upper_left) }
  let byte = value.to_byte()
  match self.current.with_mut(column, 1UL, fn(lease) { lease.set(0UL, byte) }) {
    Err(error) => Err(error)
    Ok(_) => Ok(byte)
  }
}

///|
fn PngIndexRows::finish_row(self : PngIndexRows) -> Unit {
  let prior = self.previous
  self.previous = self.current
  self.current = prior
}

///|
fn _png_write_indexed_pixel(
  view : @storage.MutImageView,
  x : UInt64,
  y : UInt64,
  index : Byte,
  palette : Bytes,
  palette_entries : UInt64,
  transparency : PngTransparency,
) -> Result[Unit, @error.CoreError] {
  let entry = index.to_int().to_uint64()
  if entry >= palette_entries { return Err(_png_error("png-palette-index")) }
  let offset = (entry * 3UL).to_int()
  for channel = 0UL; channel < 3UL; channel = channel + 1UL {
    match view.set_byte(x, y, channel, palette[offset + channel.to_int()]) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match transparency {
    PngTransparency::Indexed(alpha) => {
      let value = if entry < alpha.length().to_uint64() { alpha[entry.to_int()] } else { b'\xff' }
      match view.set_byte(x, y, 3UL, value) { Err(error) => return Err(error); Ok(_) => () }
    }
    _ => ()
  }
  Ok(())
}

///|
fn _png_write_indexed_raster(
  view : @storage.MutImageView,
  width : UInt64,
  height : UInt64,
  palette : Bytes,
  palette_entries : UInt64,
  transparency : PngTransparency,
  filtered : Array[Byte],
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let expected = match @checked.checked_mul(width + 1UL, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if filtered.length().to_uint64() != expected { return Err(_png_error("png-filtered-size")) }
  let rows = match _png_new_index_rows(width, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut offset = 0UL
  for y = 0UL; y < height; y = y + 1UL {
    let filter = filtered[offset.to_int()].to_int()
    if filter > 4 { return Err(_png_error("png-filter")) }
    offset = offset + 1UL
    for x = 0UL; x < width; x = x + 1UL {
      let index = match rows.reconstruct(x, y, filter, filtered[offset.to_int()].to_int()) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      match _png_write_indexed_pixel(view, x, y, index, palette, palette_entries, transparency) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      offset = offset + 1UL
    }
    rows.finish_row()
  }
  Ok(())
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
        match transport.transparency {
          PngTransparency::Grayscale(key) => match view.set_byte(x, y, 3UL, if value.to_byte() == key { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }
          _ => ()
        }
      } else {
        match view.set_byte(x, y, channel, value.to_byte()) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if channel == 2UL {
          match transport.transparency {
            PngTransparency::Rgb(red, green, blue) => {
              let alpha = if view.get_byte(x, y, 0UL).unwrap() == red && view.get_byte(x, y, 1UL).unwrap() == green && value.to_byte() == blue { b'\x00' } else { b'\xff' }
              match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
            }
            _ => ()
          }
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
