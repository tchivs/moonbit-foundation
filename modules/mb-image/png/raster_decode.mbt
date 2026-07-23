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

///| The sRGB rendering intent is retained as one bounded PNG metadata value;
/// the image samples themselves use the existing built-in encoded-sRGB model.
fn _png_srgb_metadata(
  channels : UInt64,
  intent : Byte,
  budget : @budget.Budget,
) -> Result[@model.ImageMetadata, @error.CoreError] {
  let opaque_metadata = match @metadata.OpaqueMetadata::from_entries(
    [("png", "srgb", "intent", Bytes::from_array([intent]))],
    @metadata.MetadataLimits::new(max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL, max_total_bytes=32UL, max_disposition_fields=1UL), budget,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
    if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
    @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft, opaque_metadata,
  ))
}

///|
fn _png_descriptor_with_metadata(
  transport : PngTransport,
  metadata : @model.ImageMetadata,
) -> Result[@model.ImageDescriptor, @error.CoreError] {
  let pixels = match @checked.checked_mul(transport.width, transport.height) { Err(error) => return Err(error); Ok(value) => value }
  let payload = match @checked.checked_mul(pixels, transport.channels) { Err(error) => return Err(error); Ok(value) => value }
  let row = match @checked.checked_mul(transport.width, transport.channels) { Err(error) => return Err(error); Ok(value) => value }
  let plane = match @model.PlaneDescriptor::new(0UL, payload, row, row, 1UL, 1UL, transport.width, transport.height) { Err(error) => return Err(error); Ok(value) => value }
  @model.ImageDescriptor::new(transport.width, transport.height, if transport.channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() }, [plane], payload, metadata)
}

///| The explicit decoder profile exposes existing packed little-endian U16
/// grayscale+alpha storage while retaining the ordinary PNG metadata contract.
fn _png_graya16_descriptor_with_metadata(
  transport : PngTransport,
  metadata : @model.ImageMetadata,
) -> Result[@model.ImageDescriptor, @error.CoreError] {
  let pixels = match @checked.checked_mul(transport.width, transport.height) { Err(error) => return Err(error); Ok(value) => value }
  let payload = match @checked.checked_mul(pixels, 4UL) { Err(error) => return Err(error); Ok(value) => value }
  let row = match @checked.checked_mul(transport.width, 4UL) { Err(error) => return Err(error); Ok(value) => value }
  let plane = match @model.PlaneDescriptor::new(0UL, payload, row, row, 1UL, 1UL, transport.width, transport.height) { Err(error) => return Err(error); Ok(value) => value }
  @model.ImageDescriptor::new(transport.width, transport.height, @model.ImageFormat::graya16(), [plane], payload, metadata)
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

///| Expands a raw packed grayscale sample into the RGB8 range.
fn _png_scale_grayscale_sample(sample : Int, bit_depth : Int) -> Int {
  if bit_depth == 1 { sample * 255 }
  else if bit_depth == 2 { sample * 85 }
  else if bit_depth == 4 { sample * 17 }
  else { sample }
}

///| Private row state keeps filtering in the encoded packed-byte domain.
priv struct PngPackedRows {
  mut current : @bytes.OwnedBytes
  mut previous : @bytes.OwnedBytes
}

///|
fn _png_new_packed_rows(
  row_bytes : UInt64,
  budget : @budget.Budget,
) -> Result[PngPackedRows, @error.CoreError] {
  let current = match @bytes.OwnedBytes::new(row_bytes, budget) { Err(error) => return Err(error); Ok(value) => value }
  let previous = match @bytes.OwnedBytes::new(row_bytes, budget) { Err(error) => return Err(error); Ok(value) => value }
  Ok({ current, previous })
}

///|
fn PngPackedRows::reconstruct(
  self : PngPackedRows,
  column : UInt64,
  row : UInt64,
  bpp : UInt64,
  filter : Int,
  raw : Int,
) -> Result[Byte, @error.CoreError] {
  let left = if column >= bpp { self.current.view().get(column - bpp).unwrap().to_int() } else { 0 }
  let above = if row > 0UL { self.previous.view().get(column).unwrap().to_int() } else { 0 }
  let upper_left = if row > 0UL && column >= bpp { self.previous.view().get(column - bpp).unwrap().to_int() } else { 0 }
  let value = if filter == 0 { raw } else if filter == 1 { raw + left } else if filter == 2 { raw + above } else if filter == 3 { raw + ((left + above) / 2) } else { raw + _png_paeth(left, above, upper_left) }
  let byte = value.to_byte()
  match self.current.with_mut(column, 1UL, fn(lease) { lease.set(0UL, byte) }) { Err(error) => Err(error); Ok(_) => Ok(byte) }
}

///| Writes one already reconstructed grayscale-alpha source row as straight RGBA8.
fn _png_write_grayscale_alpha_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
) -> Result[Unit, @error.CoreError] {
  for x = 0UL; x < width; x = x + 1UL {
    let gray = rows.current.view().get(x * 2UL).unwrap()
    let alpha = rows.current.view().get(x * 2UL + 1UL).unwrap()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () }
    }
    match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
  }
  Ok(())
}

///| PNG sixteen-bit samples are emitted as their big-endian high byte only;
/// no scaling, rounding, dithering, or colour-management transform occurs.
fn _png_write_16bit_grayscale_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
  transparency : PngTransparency,
) -> Result[Unit, @error.CoreError] {
  for x = 0UL; x < width; x = x + 1UL {
    let offset = x * 2UL
    let high = rows.current.view().get(offset).unwrap()
    let low = rows.current.view().get(offset + 1UL).unwrap()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      match view.set_byte(x, y, channel, high) { Err(error) => return Err(error); Ok(_) => () }
    }
    match transparency {
      PngTransparency::Grayscale16(key_high, key_low) => {
        match view.set_byte(x, y, 3UL, if high == key_high && low == key_low { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }
      }
      _ => ()
    }
  }
  Ok(())
}

///| PNG sixteen-bit truecolour uses the high byte of each raw component after
/// bytewise filtering; tRNS equality is evaluated on all six raw bytes first.
fn _png_write_16bit_rgb_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
  transparency : PngTransparency,
) -> Result[Unit, @error.CoreError] {
  for x = 0UL; x < width; x = x + 1UL {
    let offset = x * 6UL
    let red_high = rows.current.view().get(offset).unwrap()
    let red_low = rows.current.view().get(offset + 1UL).unwrap()
    let green_high = rows.current.view().get(offset + 2UL).unwrap()
    let green_low = rows.current.view().get(offset + 3UL).unwrap()
    let blue_high = rows.current.view().get(offset + 4UL).unwrap()
    let blue_low = rows.current.view().get(offset + 5UL).unwrap()
    for item in [(0UL, red_high), (1UL, green_high), (2UL, blue_high)] {
      let (channel, value) = item
      match view.set_byte(x, y, channel, value) { Err(error) => return Err(error); Ok(_) => () }
    }
    match transparency {
      PngTransparency::Rgb16(rh, rl, gh, gl, bh, bl) => {
        let alpha = if red_high == rh && red_low == rl && green_high == gh && green_low == gl && blue_high == bh && blue_low == bl { b'\x00' } else { b'\xff' }
        match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
      }
      _ => ()
    }
  }
  Ok(())
}

///| PNG sixteen-bit grayscale-alpha preserves its native straight alpha while
/// emitting the high byte of each reconstructed big-endian component.
fn _png_write_16bit_grayscale_alpha_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
) -> Result[Unit, @error.CoreError] {
  for x = 0UL; x < width; x = x + 1UL {
    let offset = x * 4UL
    let gray = rows.current.view().get(offset).unwrap()
    let alpha = rows.current.view().get(offset + 2UL).unwrap()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () }
    }
    match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
  }
  Ok(())
}

///| The explicit profile writes reconstructed PNG MSB-first component bytes
/// directly into the existing little-endian U16 component representation.
fn _png_write_16bit_grayscale_alpha_row_graya16(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
) -> Result[Unit, @error.CoreError] {
  for x = 0UL; x < width; x = x + 1UL {
    let offset = x * 4UL
    for item in [(0UL, 0UL, rows.current.view().get(offset + 1UL).unwrap()), (0UL, 1UL, rows.current.view().get(offset).unwrap()), (1UL, 0UL, rows.current.view().get(offset + 3UL).unwrap()), (1UL, 1UL, rows.current.view().get(offset + 2UL).unwrap())] {
      let (channel, byte_index, value) = item
      match view.set_component_byte(x, y, channel, byte_index, value) { Err(error) => return Err(error); Ok(_) => () }
    }
  }
  Ok(())
}

///| PNG sixteen-bit RGBA preserves straight alpha and maps every reconstructed
/// big-endian component to its high byte without a colour transform.
fn _png_write_16bit_rgba_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
) -> Result[Unit, @error.CoreError] {
  for x = 0UL; x < width; x = x + 1UL {
    let offset = x * 8UL
    for item in [(0UL, 0UL), (1UL, 2UL), (2UL, 4UL), (3UL, 6UL)] {
      let (channel, source_offset) = item
      let value = rows.current.view().get(offset + source_offset).unwrap()
      match view.set_byte(x, y, channel, value) { Err(error) => return Err(error); Ok(_) => () }
    }
  }
  Ok(())
}

///|
fn PngPackedRows::finish_row(self : PngPackedRows) -> Unit {
  let prior = self.previous
  self.previous = self.current
  self.current = prior
}

///| Adam7 predictor state is local to a pass. Reusing both rows bounds memory
/// while ensuring the first row of every pass has no above neighbour.
fn PngPackedRows::reset(self : PngPackedRows) -> Result[Unit, @error.CoreError] {
  let length = self.current.view().length()
  match self.current.with_mut(0UL, length, fn(lease) {
    let mut index = 0UL
    while index < length {
      match lease.set(index, b'\x00') { Err(error) => return Err(error); Ok(_) => () }
      index = index + 1UL
    }
    Ok(())
  }) { Err(error) => return Err(error); Ok(_) => () }
  match self.previous.with_mut(0UL, length, fn(lease) {
    let mut index = 0UL
    while index < length {
      match lease.set(index, b'\x00') { Err(error) => return Err(error); Ok(_) => () }
      index = index + 1UL
    }
    Ok(())
  }) { Err(error) => Err(error); Ok(_) => Ok(()) }
}

///| A private, byte-fed raster continuation.  It owns the output image and
/// only obtains a mutable image lease while committing an already reconstructed
/// source byte or row; no caller ByteView or image lease survives a pause.
priv struct PngRasterSink {
  image : @storage.OwnedImage
  transport : PngTransport
  interlaced : Bool
  profile : PngDecodeProfile
  row_bytes : UInt64
  expected : UInt64
  passes : Array[PngAdam7Pass]
  rows : PngPackedRows?
  mut emitted : UInt64
  mut row : UInt64
  mut column : UInt64
  mut filter : Int
  mut pass_index : Int
  mut pass_row : UInt64
}

///|
fn PngRasterSink::new(
  image : @storage.OwnedImage,
  transport : PngTransport,
  interlaced : Bool,
  budget : @budget.Budget,
) -> Result[PngRasterSink, @error.CoreError] {
  PngRasterSink::new_with_profile(
    image, transport, interlaced, PngDecodeProfile::GenericRgba8, budget,
  )
}

///| The machine-selected profile reaches the sink only after preflight has
/// selected the descriptor and private image lifecycle.
fn PngRasterSink::new_with_profile(
  image : @storage.OwnedImage,
  transport : PngTransport,
  interlaced : Bool,
  profile : PngDecodeProfile,
  budget : @budget.Budget,
) -> Result[PngRasterSink, @error.CoreError] {
  let row_bytes = match _png_source_row_bytes(transport.width, transport.source_channels, transport.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let passes = if interlaced { match _png_adam7_passes(transport.width, transport.height, transport.source_channels, transport.bit_depth) { Err(error) => return Err(error); Ok(value) => value } } else { [] }
  let mut expected = if interlaced { 0UL } else { match @checked.checked_mul(row_bytes + 1UL, transport.height) { Err(error) => return Err(error); Ok(value) => value } }
  let mut largest_row = row_bytes
  if interlaced {
    largest_row = 0UL
    for pass in passes {
      if pass.width > 0UL && pass.height > 0UL {
        let size = match @checked.checked_mul(pass.row_bytes + 1UL, pass.height) { Err(error) => return Err(error); Ok(value) => value }
        expected = match @checked.checked_add(expected, size) { Err(error) => return Err(error); Ok(value) => value }
        if pass.row_bytes > largest_row { largest_row = pass.row_bytes }
      }
    }
  }
  let needs_rows = interlaced || transport.indexed || transport.bit_depth == 16 || transport.source_channels == 1UL || transport.source_channels == 2UL
  let rows = if needs_rows { match _png_new_packed_rows(largest_row, budget) { Err(error) => return Err(error); Ok(value) => Some(value) } } else { None }
  let mut pass_index = 0
  if interlaced {
    while pass_index < passes.length() && (passes[pass_index].width == 0UL || passes[pass_index].height == 0UL) { pass_index = pass_index + 1 }
  }
  Ok({ image, transport, interlaced, profile, row_bytes, expected, passes, rows, emitted: 0UL, row: 0UL, column: 0UL, filter: 0, pass_index, pass_row: 0UL })
}

///|
fn PngRasterSink::image_view(self : PngRasterSink) -> @storage.ImageView {
  self.image.view()
}

///|
/// The machine keeps the owned image inside this sink until framing reaches a
/// terminal success state.  This private move accessor is deliberately not a
/// result constructor: callers must still complete IDAT, zlib, IEND, and EOF
/// validation before the image can become observable.
fn PngRasterSink::into_image(self : PngRasterSink) -> @storage.OwnedImage {
  self.image
}

///|
fn PngRasterSink::finish(self : PngRasterSink) -> Result[Unit, @error.CoreError] {
  if !self.is_complete() { Err(_png_error("png-filtered-size")) } else { Ok(()) }
}

///|
/// Query completion without moving the owned image or advancing any row state.
/// The public chunk facade uses this solely to preserve EOF error precedence.
fn PngRasterSink::is_complete(self : PngRasterSink) -> Bool {
  let complete_rows = if self.interlaced {
    self.pass_index == self.passes.length() && self.pass_row == 0UL
  } else {
    self.row == self.transport.height
  }
  self.emitted == self.expected && self.column == 0UL && complete_rows
}

///| Feed exactly one decompressed byte.  Filter tags and all sample state are
/// persisted before this method returns, so callers may pause at any boundary.
fn PngRasterSink::emit(self : PngRasterSink, byte : Byte) -> Result[Unit, @error.CoreError] {
  if self.emitted >= self.expected { return Err(_png_error("png-filtered-size")) }
  if self.column == 0UL {
    self.filter = byte.to_int()
    if self.filter > 4 { return Err(_png_error("png-filter")) }
    self.column = 1UL
    self.emitted = self.emitted + 1UL
    return Ok(())
  }
  let pixel_column = self.column - 1UL
  if self.interlaced {
    if self.pass_index >= self.passes.length() { return Err(_png_error("png-filtered-size")) }
    let pass = self.passes[self.pass_index]
    let rows = match self.rows { Some(value) => value; None => return Err(_png_error("png-packed-rows")) }
    match rows.reconstruct(pixel_column, self.pass_row, self.transport.source_bytes_per_pixel, self.filter, byte.to_int()) { Err(error) => return Err(error); Ok(_) => () }
    if pixel_column + 1UL == pass.row_bytes {
      match self.image.with_mut_view(fn(view) { _png_write_adam7_transport_row(view, rows, pass, self.pass_row, self.transport) }) { Err(error) => return Err(error); Ok(_) => () }
      rows.finish_row()
    }
  } else if self.transport.indexed {
    let rows = match self.rows { Some(value) => value; None => return Err(_png_error("png-index-rows")) }
    match rows.reconstruct(pixel_column, self.row, 1UL, self.filter, byte.to_int()) { Err(error) => return Err(error); Ok(_) => () }
    if pixel_column + 1UL == self.row_bytes {
      match self.image.with_mut_view(fn(view) { _png_write_packed_indexed_row(view, rows, self.row, self.transport.width, self.transport.bit_depth, self.transport.palette, self.transport.palette_entries, self.transport.transparency) }) { Err(error) => return Err(error); Ok(_) => () }
      rows.finish_row()
    }
  } else if self.transport.bit_depth == 16 || self.transport.source_channels == 1UL || self.transport.source_channels == 2UL {
    let rows = match self.rows { Some(value) => value; None => return Err(_png_error("png-packed-rows")) }
    let bpp = if self.transport.bit_depth == 16 { self.transport.source_bytes_per_pixel } else { self.transport.source_channels }
    match rows.reconstruct(pixel_column, self.row, bpp, self.filter, byte.to_int()) { Err(error) => return Err(error); Ok(_) => () }
    if pixel_column + 1UL == self.row_bytes {
      match self.image.with_mut_view(fn(view) {
        if self.transport.bit_depth == 16 {
          if self.transport.source_channels == 1UL { _png_write_16bit_grayscale_row(view, rows, self.row, self.transport.width, self.transport.transparency) }
          else if self.transport.source_channels == 2UL {
            if self.profile == PngDecodeProfile::GrayAlpha16 { _png_write_16bit_grayscale_alpha_row_graya16(view, rows, self.row, self.transport.width) }
            else { _png_write_16bit_grayscale_alpha_row(view, rows, self.row, self.transport.width) }
          }
          else if self.transport.source_channels == 3UL { _png_write_16bit_rgb_row(view, rows, self.row, self.transport.width, self.transport.transparency) }
          else { _png_write_16bit_rgba_row(view, rows, self.row, self.transport.width) }
        } else if self.transport.source_channels == 1UL { _png_write_packed_grayscale_row(view, rows, self.row, self.transport.width, self.transport.bit_depth, self.transport.transparency) }
        else { _png_write_grayscale_alpha_row(view, rows, self.row, self.transport.width) }
      }) { Err(error) => return Err(error); Ok(_) => () }
      rows.finish_row()
    }
  } else {
    let x = pixel_column / self.transport.source_channels
    let channel = pixel_column % self.transport.source_channels
    match self.image.with_mut_view(fn(view) {
      let left = if pixel_column >= self.transport.source_channels { match view.get_byte(x - 1UL, self.row, channel) { Err(error) => return Err(error); Ok(value) => value.to_int() } } else { 0 }
      let above = if self.row > 0UL { match view.get_byte(x, self.row - 1UL, channel) { Err(error) => return Err(error); Ok(value) => value.to_int() } } else { 0 }
      let upper_left = if self.row > 0UL && pixel_column >= self.transport.source_channels { match view.get_byte(x - 1UL, self.row - 1UL, channel) { Err(error) => return Err(error); Ok(value) => value.to_int() } } else { 0 }
      let value = if self.filter == 0 { byte.to_int() } else if self.filter == 1 { byte.to_int() + left } else if self.filter == 2 { byte.to_int() + above } else if self.filter == 3 { byte.to_int() + ((left + above) / 2) } else { byte.to_int() + _png_paeth(left, above, upper_left) }
      match view.set_byte(x, self.row, channel, value.to_byte()) { Err(error) => return Err(error); Ok(_) => () }
      if channel == 2UL {
        match self.transport.transparency { PngTransparency::Rgb(red, green, blue) => match view.set_byte(x, self.row, 3UL, if view.get_byte(x, self.row, 0UL).unwrap() == red && view.get_byte(x, self.row, 1UL).unwrap() == green && value.to_byte() == blue { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
      }
      Ok(())
    }) { Err(error) => return Err(error); Ok(_) => () }
  }
  self.column = self.column + 1UL
  if self.interlaced {
    if self.column == self.passes[self.pass_index].row_bytes + 1UL {
      self.column = 0UL
      self.pass_row = self.pass_row + 1UL
      if self.pass_row == self.passes[self.pass_index].height {
        self.pass_index = self.pass_index + 1
        self.pass_row = 0UL
        while self.pass_index < self.passes.length() && (self.passes[self.pass_index].width == 0UL || self.passes[self.pass_index].height == 0UL) { self.pass_index = self.pass_index + 1 }
        if self.pass_index < self.passes.length() { match self.rows { Some(rows) => match rows.reset() { Err(error) => return Err(error); Ok(_) => () }; None => return Err(_png_error("png-packed-rows")) } }
      }
    }
  } else if self.column == self.row_bytes + 1UL { self.column = 0UL; self.row = self.row + 1UL }
  self.emitted = self.emitted + 1UL
  Ok(())
}

///| Expands a reconstructed encoded Adam7 row at its pass-local coordinates.
/// Filtering has already run on packed source bytes; this function only maps
/// source samples to the established RGB8/RGBA8 public representation.
fn _png_write_adam7_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  pass : PngAdam7Pass,
  row : UInt64,
  transport : PngStreamTransport,
) -> Result[Unit, @error.CoreError] {
  for column = 0UL; column < pass.width; column = column + 1UL {
    let x = pass.x + column * pass.dx
    let y = pass.y + row * pass.dy
    if transport.indexed {
      let start = column * transport.bit_depth.to_uint64()
      let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
      let mask = if transport.bit_depth == 1 { 1 } else if transport.bit_depth == 2 { 3 } else if transport.bit_depth == 4 { 15 } else { 255 }
      let index = ((byte >> (8 - transport.bit_depth - (start % 8UL).to_int())) & mask).to_byte()
      match _png_write_indexed_pixel(view, x, y, index, transport.palette, transport.palette_entries, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
    } else if transport.source_channels == 1UL && transport.bit_depth < 8 {
      let start = column * transport.bit_depth.to_uint64()
      let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
      let mask = if transport.bit_depth == 1 { 1 } else if transport.bit_depth == 2 { 3 } else { 15 }
      let raw = (byte >> (8 - transport.bit_depth - (start % 8UL).to_int())) & mask
      let value = _png_scale_grayscale_sample(raw, transport.bit_depth).to_byte()
      for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, value) { Err(error) => return Err(error); Ok(_) => () } }
      match transport.transparency { PngTransparency::Grayscale(key) => match view.set_byte(x, y, 3UL, if raw.to_byte() == key { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
    } else {
      let offset = column * transport.source_bytes_per_pixel
      if transport.bit_depth == 16 {
        if transport.source_channels == 1UL {
          let high = rows.current.view().get(offset).unwrap(); let low = rows.current.view().get(offset + 1UL).unwrap()
          for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, high) { Err(error) => return Err(error); Ok(_) => () } }
          match transport.transparency { PngTransparency::Grayscale16(a, b) => match view.set_byte(x, y, 3UL, if high == a && low == b { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
        } else if transport.source_channels == 2UL {
          let gray = rows.current.view().get(offset).unwrap(); let alpha = rows.current.view().get(offset + 2UL).unwrap()
          for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () } }
          match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
        } else if transport.source_channels == 3UL {
          let rh = rows.current.view().get(offset).unwrap(); let rl = rows.current.view().get(offset + 1UL).unwrap(); let gh = rows.current.view().get(offset + 2UL).unwrap(); let gl = rows.current.view().get(offset + 3UL).unwrap(); let bh = rows.current.view().get(offset + 4UL).unwrap(); let bl = rows.current.view().get(offset + 5UL).unwrap()
          for item in [(0UL, rh), (1UL, gh), (2UL, bh)] { let (channel, value) = item; match view.set_byte(x, y, channel, value) { Err(error) => return Err(error); Ok(_) => () } }
          match transport.transparency { PngTransparency::Rgb16(a,b,c,d,e,f) => match view.set_byte(x, y, 3UL, if rh == a && rl == b && gh == c && gl == d && bh == e && bl == f { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
        } else {
          for item in [(0UL, 0UL), (1UL, 2UL), (2UL, 4UL), (3UL, 6UL)] { let (channel, source) = item; match view.set_byte(x, y, channel, rows.current.view().get(offset + source).unwrap()) { Err(error) => return Err(error); Ok(_) => () } }
        }
      } else if transport.source_channels == 1UL {
        let gray = rows.current.view().get(offset).unwrap()
        for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () } }
        match transport.transparency { PngTransparency::Grayscale(key) => match view.set_byte(x, y, 3UL, if gray == key { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
      } else if transport.source_channels == 2UL {
        let gray = rows.current.view().get(offset).unwrap(); let alpha = rows.current.view().get(offset + 1UL).unwrap()
        for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () } }
        match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
      } else {
        for channel = 0UL; channel < transport.source_channels; channel = channel + 1UL { match view.set_byte(x, y, channel, rows.current.view().get(offset + channel).unwrap()) { Err(error) => return Err(error); Ok(_) => () } }
        if transport.source_channels == 3UL { match transport.transparency { PngTransparency::Rgb(red, green, blue) => match view.set_byte(x, y, 3UL, if rows.current.view().get(offset).unwrap() == red && rows.current.view().get(offset + 1UL).unwrap() == green && rows.current.view().get(offset + 2UL).unwrap() == blue { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () } }
      }
    }
  }
  Ok(())
}

///|
///| Same Adam7 sample expansion as the eager transport path, but with only
/// the owned raster facts required by the resumable sink.
fn _png_write_adam7_transport_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  pass : PngAdam7Pass,
  row : UInt64,
  transport : PngTransport,
) -> Result[Unit, @error.CoreError] {
  for column = 0UL; column < pass.width; column = column + 1UL {
    let x = pass.x + column * pass.dx
    let y = pass.y + row * pass.dy
    if transport.indexed {
      let start = column * transport.bit_depth.to_uint64()
      let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
      let mask = if transport.bit_depth == 1 { 1 } else if transport.bit_depth == 2 { 3 } else if transport.bit_depth == 4 { 15 } else { 255 }
      let index = ((byte >> (8 - transport.bit_depth - (start % 8UL).to_int())) & mask).to_byte()
      match _png_write_indexed_pixel(view, x, y, index, transport.palette, transport.palette_entries, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
    } else if transport.source_channels == 1UL && transport.bit_depth < 8 {
      let start = column * transport.bit_depth.to_uint64()
      let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
      let mask = if transport.bit_depth == 1 { 1 } else if transport.bit_depth == 2 { 3 } else { 15 }
      let raw = (byte >> (8 - transport.bit_depth - (start % 8UL).to_int())) & mask
      let value = _png_scale_grayscale_sample(raw, transport.bit_depth).to_byte()
      for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, value) { Err(error) => return Err(error); Ok(_) => () } }
      match transport.transparency { PngTransparency::Grayscale(key) => match view.set_byte(x, y, 3UL, if raw.to_byte() == key { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
    } else {
      let offset = column * transport.source_bytes_per_pixel
      if transport.bit_depth == 16 {
        if transport.source_channels == 1UL {
          let high = rows.current.view().get(offset).unwrap(); let low = rows.current.view().get(offset + 1UL).unwrap()
          for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, high) { Err(error) => return Err(error); Ok(_) => () } }
          match transport.transparency { PngTransparency::Grayscale16(a, b) => match view.set_byte(x, y, 3UL, if high == a && low == b { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
        } else if transport.source_channels == 2UL {
          let gray = rows.current.view().get(offset).unwrap(); let alpha = rows.current.view().get(offset + 2UL).unwrap()
          for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () } }
          match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
        } else if transport.source_channels == 3UL {
          let rh = rows.current.view().get(offset).unwrap(); let rl = rows.current.view().get(offset + 1UL).unwrap(); let gh = rows.current.view().get(offset + 2UL).unwrap(); let gl = rows.current.view().get(offset + 3UL).unwrap(); let bh = rows.current.view().get(offset + 4UL).unwrap(); let bl = rows.current.view().get(offset + 5UL).unwrap()
          for item in [(0UL, rh), (1UL, gh), (2UL, bh)] { let (channel, value) = item; match view.set_byte(x, y, channel, value) { Err(error) => return Err(error); Ok(_) => () } }
          match transport.transparency { PngTransparency::Rgb16(a,b,c,d,e,f) => match view.set_byte(x, y, 3UL, if rh == a && rl == b && gh == c && gl == d && bh == e && bl == f { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
        } else { for item in [(0UL, 0UL), (1UL, 2UL), (2UL, 4UL), (3UL, 6UL)] { let (channel, source) = item; match view.set_byte(x, y, channel, rows.current.view().get(offset + source).unwrap()) { Err(error) => return Err(error); Ok(_) => () } } }
      } else if transport.source_channels == 1UL {
        let gray = rows.current.view().get(offset).unwrap()
        for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () } }
        match transport.transparency { PngTransparency::Grayscale(key) => match view.set_byte(x, y, 3UL, if gray == key { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () }
      } else if transport.source_channels == 2UL {
        let gray = rows.current.view().get(offset).unwrap(); let alpha = rows.current.view().get(offset + 1UL).unwrap()
        for channel = 0UL; channel < 3UL; channel = channel + 1UL { match view.set_byte(x, y, channel, gray) { Err(error) => return Err(error); Ok(_) => () } }
        match view.set_byte(x, y, 3UL, alpha) { Err(error) => return Err(error); Ok(_) => () }
      } else {
        for channel = 0UL; channel < transport.source_channels; channel = channel + 1UL { match view.set_byte(x, y, channel, rows.current.view().get(offset + channel).unwrap()) { Err(error) => return Err(error); Ok(_) => () } }
        if transport.source_channels == 3UL { match transport.transparency { PngTransparency::Rgb(red, green, blue) => match view.set_byte(x, y, 3UL, if rows.current.view().get(offset).unwrap() == red && rows.current.view().get(offset + 1UL).unwrap() == green && rows.current.view().get(offset + 2UL).unwrap() == blue { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }; _ => () } }
      }
    }
  }
  Ok(())
}

///|
fn _png_write_packed_grayscale_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
  bit_depth : Int,
  transparency : PngTransparency,
) -> Result[Unit, @error.CoreError] {
  let mask = if bit_depth == 1 { 1 } else if bit_depth == 2 { 3 } else if bit_depth == 4 { 15 } else { 255 }
  for x = 0UL; x < width; x = x + 1UL {
    let start = x * bit_depth.to_uint64()
    let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
    let shift = 8 - bit_depth - (start % 8UL).to_int()
    let raw = (byte >> shift) & mask
    let expanded = _png_scale_grayscale_sample(raw, bit_depth).to_byte()
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      match view.set_byte(x, y, channel, expanded) { Err(error) => return Err(error); Ok(_) => () }
    }
    match transparency {
      PngTransparency::Grayscale(key) => match view.set_byte(x, y, 3UL, if raw.to_byte() == key { b'\x00' } else { b'\xff' }) { Err(error) => return Err(error); Ok(_) => () }
      _ => ()
    }
  }
  Ok(())
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
  bit_depth : Int,
  palette : Bytes,
  palette_entries : UInt64,
  transparency : PngTransparency,
  filtered : Array[Byte],
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let row_bytes = match _png_grayscale_row_bytes(width, bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let expected = match @checked.checked_mul(row_bytes + 1UL, height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if filtered.length().to_uint64() != expected { return Err(_png_error("png-filtered-size")) }
  let rows = match _png_new_packed_rows(row_bytes, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut offset = 0UL
  for y = 0UL; y < height; y = y + 1UL {
    let filter = filtered[offset.to_int()].to_int()
    if filter > 4 { return Err(_png_error("png-filter")) }
    offset = offset + 1UL
    for column = 0UL; column < row_bytes; column = column + 1UL {
      match rows.reconstruct(column, y, 1UL, filter, filtered[offset.to_int()].to_int()) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      offset = offset + 1UL
    }
    match _png_write_packed_indexed_row(view, rows, y, width, bit_depth, palette, palette_entries, transparency) { Err(error) => return Err(error); Ok(_) => () }
    rows.finish_row()
  }
  Ok(())
}

///| Expands exactly the visible MSB-first packed palette samples after filtering.
fn _png_write_packed_indexed_row(
  view : @storage.MutImageView,
  rows : PngPackedRows,
  y : UInt64,
  width : UInt64,
  bit_depth : Int,
  palette : Bytes,
  palette_entries : UInt64,
  transparency : PngTransparency,
) -> Result[Unit, @error.CoreError] {
  let mask = if bit_depth == 1 { 1 } else if bit_depth == 2 { 3 } else if bit_depth == 4 { 15 } else { 255 }
  for x = 0UL; x < width; x = x + 1UL {
    let start = x * bit_depth.to_uint64()
    let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
    let shift = 8 - bit_depth - (start % 8UL).to_int()
    let index = ((byte >> shift) & mask).to_byte()
    match _png_write_indexed_pixel(view, x, y, index, palette, palette_entries, transparency) { Err(error) => return Err(error); Ok(_) => () }
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
fn _png_write_raster(view : @storage.MutImageView, transport : PngTransport, filtered : Array[Byte], budget : @budget.Budget) -> Result[Unit, @error.CoreError] {
  if transport.indexed {
    return _png_write_indexed_raster(view, transport.width, transport.height, transport.bit_depth, transport.palette, transport.palette_entries, transport.transparency, filtered, budget)
  }
  if transport.source_channels == 1UL && transport.bit_depth < 8 {
    return _png_write_packed_grayscale_raster(view, transport, filtered, budget)
  }
  if transport.bit_depth == 16 {
    let row_bytes = match @checked.checked_mul(transport.width, transport.source_bytes_per_pixel) { Err(error) => return Err(error); Ok(value) => value }
    let expected = match @checked.checked_mul(row_bytes + 1UL, transport.height) { Err(error) => return Err(error); Ok(value) => value }
    if filtered.length().to_uint64() != expected { return Err(_png_error("png-filtered-size")) }
    let rows = match _png_new_packed_rows(row_bytes, budget) { Err(error) => return Err(error); Ok(value) => value }
    let mut offset = 0UL
    for y = 0UL; y < transport.height; y = y + 1UL {
      let filter = filtered[offset.to_int()].to_int()
      if filter > 4 { return Err(_png_error("png-filter")) }
      offset = offset + 1UL
      for column = 0UL; column < row_bytes; column = column + 1UL {
        match rows.reconstruct(column, y, transport.source_bytes_per_pixel, filter, filtered[offset.to_int()].to_int()) { Err(error) => return Err(error); Ok(_) => () }
        offset = offset + 1UL
      }
      if transport.source_channels == 1UL {
        match _png_write_16bit_grayscale_row(view, rows, y, transport.width, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
      } else if transport.source_channels == 2UL {
        match _png_write_16bit_grayscale_alpha_row(view, rows, y, transport.width) { Err(error) => return Err(error); Ok(_) => () }
      } else if transport.source_channels == 3UL {
        match _png_write_16bit_rgb_row(view, rows, y, transport.width, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
      } else {
        match _png_write_16bit_rgba_row(view, rows, y, transport.width) { Err(error) => return Err(error); Ok(_) => () }
      }
      rows.finish_row()
    }
    return Ok(())
  }
  if transport.source_channels == 2UL && transport.channels == 4UL {
    let row_bytes = match @checked.checked_mul(transport.width, 2UL) { Err(error) => return Err(error); Ok(value) => value }
    let expected = match @checked.checked_mul(row_bytes + 1UL, transport.height) { Err(error) => return Err(error); Ok(value) => value }
    if filtered.length().to_uint64() != expected { return Err(_png_error("png-filtered-size")) }
    let rows = match _png_new_packed_rows(row_bytes, budget) { Err(error) => return Err(error); Ok(value) => value }
    let mut offset = 0UL
    for y = 0UL; y < transport.height; y = y + 1UL {
      let filter = filtered[offset.to_int()].to_int()
      if filter > 4 { return Err(_png_error("png-filter")) }
      offset = offset + 1UL
      for column = 0UL; column < row_bytes; column = column + 1UL {
        match rows.reconstruct(column, y, 2UL, filter, filtered[offset.to_int()].to_int()) { Err(error) => return Err(error); Ok(_) => () }
        offset = offset + 1UL
      }
      match _png_write_grayscale_alpha_row(view, rows, y, transport.width) { Err(error) => return Err(error); Ok(_) => () }
      rows.finish_row()
    }
    return Ok(())
  }
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

///| The eager helper mirrors the live inflater: filters run on packed bytes.
fn _png_write_packed_grayscale_raster(
  view : @storage.MutImageView,
  transport : PngTransport,
  filtered : Array[Byte],
  budget : @budget.Budget,
) -> Result[Unit, @error.CoreError] {
  let row_bytes = match _png_grayscale_row_bytes(transport.width, transport.bit_depth) { Err(error) => return Err(error); Ok(value) => value }
  let expected = match @checked.checked_mul(row_bytes + 1UL, transport.height) { Err(error) => return Err(error); Ok(value) => value }
  if filtered.length().to_uint64() != expected { return Err(_png_error("png-filtered-size")) }
  let rows = match _png_new_packed_rows(row_bytes, budget) { Err(error) => return Err(error); Ok(value) => value }
  let mut offset = 0UL
  for y = 0UL; y < transport.height; y = y + 1UL {
    let filter = filtered[offset.to_int()].to_int()
    if filter > 4 { return Err(_png_error("png-filter")) }
    offset = offset + 1UL
    for column = 0UL; column < row_bytes; column = column + 1UL {
      match rows.reconstruct(column, y, 1UL, filter, filtered[offset.to_int()].to_int()) { Err(error) => return Err(error); Ok(_) => () }
      offset = offset + 1UL
    }
    match _png_write_packed_grayscale_row(view, rows, y, transport.width, transport.bit_depth, transport.transparency) { Err(error) => return Err(error); Ok(_) => () }
    rows.finish_row()
  }
  Ok(())
}

///|
fn _png_empty_disposition() -> Result[@metadata.MetadataDisposition, @error.CoreError] {
  @metadata.MetadataDisposition::new([], [], [], false, @metadata.MetadataLimits::new(max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL, max_total_bytes=0UL, max_disposition_fields=0UL))
}
