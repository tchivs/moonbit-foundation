///|
fn qoi_encode_error(
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
  requested? : UInt64,
  completed? : UInt64,
  limit? : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    category,
    code,
    operation="qoi-encode",
    requested?,
    completed?,
    limit?,
    context~,
  )
}

///|
fn qoi_encode_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(
      qoi_encode_error(
        @error.ErrorCategory::Resource,
        @error.ErrorCode::BudgetExceeded,
        context,
        requested~,
        limit~,
      ),
    )
  } else {
    Ok(())
  }
}

///|
/// QOI stores nonzero unsigned 32-bit dimensions in its 14-byte header.
fn qoi_encode_dimension(value : UInt64) -> Result[UInt64, @error.CoreError] {
  if value == 0UL || value > 4294967295UL {
    Err(
      qoi_encode_error(
        @error.ErrorCategory::Capability,
        @error.ErrorCode::CapabilityUnavailable,
        "qoi-u32-dimensions",
      ),
    )
  } else {
    Ok(value)
  }
}

///|
fn qoi_encode_capability(context : String) -> @error.CoreError {
  @codec.capability_unavailable("qoi-encode", context)
}

///|
/// Validate all QOI-representable image semantics before the budget or Writer.
fn qoi_encode_source(
  source : @storage.ImageView,
) -> Result[(UInt64, Byte), @error.CoreError] {
  match qoi_encode_dimension(source.width()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match qoi_encode_dimension(source.height()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = source.format()
  let metadata = source.metadata()
  if format.component() != @model.ComponentType::U8 {
    return Err(qoi_encode_capability("component-u8-required"))
  }
  if format.layout() != @model.PlaneLayout::Packed {
    return Err(qoi_encode_capability("packed-required"))
  }
  if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    !metadata.profile().is_builtin_srgb() {
    return Err(qoi_encode_capability("builtin-srgb-required"))
  }
  if metadata.orientation() != @model.Orientation::TopLeft {
    return Err(qoi_encode_capability("top-left-required"))
  }
  if metadata.opaque_metadata().length() != 0 {
    return Err(qoi_encode_capability("opaque-metadata-unsupported"))
  }
  let color_space = match metadata.transfer() {
    @color.TransferIdentity::EncodedSrgb => b'\x00'
    @color.TransferIdentity::LinearSrgb => b'\x01'
    _ => return Err(qoi_encode_capability("srgb-transfer-required"))
  }
  let channels = match format.channels() {
    @model.ChannelOrder::Rgb => {
      if metadata.alpha() is Some(_) {
        return Err(qoi_encode_capability("rgb-alpha-unsupported"))
      }
      3UL
    }
    @model.ChannelOrder::Rgba =>
      match metadata.alpha() {
        Some(@color.AlphaMode::Straight) => 4UL
        _ => return Err(qoi_encode_capability("straight-rgba-required"))
      }
    _ => return Err(qoi_encode_capability("rgb-or-rgba-required"))
  }
  let row_bytes = match @checked.checked_mul(source.width(), channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if source.row_bytes() != row_bytes || source.row_stride() < row_bytes {
    return Err(qoi_encode_capability("packed-row-layout-required"))
  }
  Ok((channels, color_space))
}

///|
fn qoi_encode_header(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  color_space : Byte,
) -> Bytes {
  let result : Array[Byte] = [b'q', b'o', b'i', b'f']
  for dimension in [width, height] {
    result.push((dimension / 16777216UL).to_byte())
    result.push((dimension / 65536UL % 256UL).to_byte())
    result.push((dimension / 256UL % 256UL).to_byte())
    result.push((dimension % 256UL).to_byte())
  }
  result.push(channels.to_byte())
  result.push(color_space)
  Bytes::from_array(result)
}

///|
fn qoi_same(left : QoiPixel, right : QoiPixel) -> Bool {
  left.r == right.r &&
  left.g == right.g &&
  left.b == right.b &&
  left.a == right.a
}

///|
/// Return the signed modular byte delta in the QOI range -128 through 127.
fn qoi_signed_delta(next : Byte, previous : Byte) -> Int {
  (next.to_int() - previous.to_int() + 128) % 256 - 128
}

///|
fn qoi_source_pixel(
  source : @storage.ImageView,
  x : UInt64,
  y : UInt64,
  channels : UInt64,
) -> Result[QoiPixel, @error.CoreError] {
  let r = match source.get_byte(x, y, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let g = match source.get_byte(x, y, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let b = match source.get_byte(x, y, 2UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let a = if channels == 4UL {
    match source.get_byte(x, y, 3UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  } else {
    b'\xff'
  }
  Ok(QoiPixel::{ r, g, b, a })
}

///|
fn qoi_chunk_length(
  source : @storage.ImageView,
  channels : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let index = Array::make(64, QoiPixel::{
    r: b'\x00',
    g: b'\x00',
    b: b'\x00',
    a: b'\x00',
  })
  let mut previous = QoiPixel::{
    r: b'\x00',
    g: b'\x00',
    b: b'\x00',
    a: b'\xff',
  }
  let mut run = 0UL
  let mut length = 0UL
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for position = 0UL; position < pixels; position = position + 1UL {
    let pixel = match
      qoi_source_pixel(
        source,
        position % source.width(),
        position / source.width(),
        channels,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if qoi_same(pixel, previous) {
      run = run + 1UL
      if run == 62UL || position + 1UL == pixels {
        length = match @checked.checked_add(length, 1UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        run = 0UL
      }
    } else {
      if run > 0UL {
        length = match @checked.checked_add(length, 1UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        run = 0UL
      }
      let slot = qoi_hash(pixel)
      if qoi_same(index[slot], pixel) {
        length = match @checked.checked_add(length, 1UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      } else {
        index[slot] = pixel
        let dr = qoi_signed_delta(pixel.r, previous.r)
        let dg = qoi_signed_delta(pixel.g, previous.g)
        let db = qoi_signed_delta(pixel.b, previous.b)
        if pixel.a == previous.a &&
          dr >= -2 &&
          dr <= 1 &&
          dg >= -2 &&
          dg <= 1 &&
          db >= -2 &&
          db <= 1 {
          length = match @checked.checked_add(length, 1UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
        } else if pixel.a == previous.a &&
          dg >= -32 &&
          dg <= 31 &&
          dr - dg >= -8 &&
          dr - dg <= 7 &&
          db - dg >= -8 &&
          db - dg <= 7 {
          length = match @checked.checked_add(length, 2UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
        } else if pixel.a == previous.a {
          length = match @checked.checked_add(length, 4UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
        } else {
          length = match @checked.checked_add(length, 5UL) {
            Err(error) => return Err(error)
            Ok(value) => value
          }
        }
      }
      previous = pixel
    }
  }
  Ok(length)
}

///|
fn qoi_remap_write_error(
  error : @error.CoreError,
  requested : UInt64,
  completed_before : UInt64,
) -> @error.CoreError {
  let call_completed = match error.completed() {
    Some(value) => value
    None => 0UL
  }
  let completed = match @checked.checked_add(completed_before, call_completed) {
    Ok(value) => value
    Err(_) => completed_before
  }
  @error.CoreError::new(
    error.category(),
    error.code(),
    operation="qoi-encode",
    requested~,
    completed~,
    context?=error.context(),
  )
}

///|
fn qoi_write_part(
  writer : &@io.Writer,
  bytes : Bytes,
  requested : UInt64,
  completed : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let owner = match
    @bytes.OwnedBytes::from_bytes(
      bytes,
      qoi_private_budget(bytes.length().to_uint64()),
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match @io.write_all(writer, owner.view()) {
    Err(error) => Err(qoi_remap_write_error(error, requested, completed))
    Ok(count) => @checked.checked_add(completed, count)
  }
}

///|
fn qoi_write_chunks(
  source : @storage.ImageView,
  channels : UInt64,
  writer : &@io.Writer,
  requested : UInt64,
  completed : UInt64,
) -> Result[UInt64, @error.CoreError] {
  let index = Array::make(64, QoiPixel::{
    r: b'\x00',
    g: b'\x00',
    b: b'\x00',
    a: b'\x00',
  })
  let mut previous = QoiPixel::{
    r: b'\x00',
    g: b'\x00',
    b: b'\x00',
    a: b'\xff',
  }
  let mut run = 0UL
  let mut cursor = completed
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for position = 0UL; position < pixels; position = position + 1UL {
    let pixel = match
      qoi_source_pixel(
        source,
        position % source.width(),
        position / source.width(),
        channels,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if qoi_same(pixel, previous) {
      run = run + 1UL
      if run == 62UL || position + 1UL == pixels {
        cursor = match
          qoi_write_part(
            writer,
            Bytes::from_array([(0xc0 + (run - 1UL).to_int()).to_byte()]),
            requested,
            cursor,
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        run = 0UL
      }
    } else {
      if run > 0UL {
        cursor = match
          qoi_write_part(
            writer,
            Bytes::from_array([(0xc0 + (run - 1UL).to_int()).to_byte()]),
            requested,
            cursor,
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        run = 0UL
      }
      let slot = qoi_hash(pixel)
      if qoi_same(index[slot], pixel) {
        cursor = match
          qoi_write_part(
            writer,
            Bytes::from_array([slot.to_byte()]),
            requested,
            cursor,
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      } else {
        index[slot] = pixel
        let dr = qoi_signed_delta(pixel.r, previous.r)
        let dg = qoi_signed_delta(pixel.g, previous.g)
        let db = qoi_signed_delta(pixel.b, previous.b)
        let chunk = if pixel.a == previous.a &&
          dr >= -2 &&
          dr <= 1 &&
          dg >= -2 &&
          dg <= 1 &&
          db >= -2 &&
          db <= 1 {
          Bytes::from_array([
            (0x40 + ((dr + 2) << 4) + ((dg + 2) << 2) + (db + 2)).to_byte(),
          ])
        } else if pixel.a == previous.a &&
          dg >= -32 &&
          dg <= 31 &&
          dr - dg >= -8 &&
          dr - dg <= 7 &&
          db - dg >= -8 &&
          db - dg <= 7 {
          Bytes::from_array([
            (0x80 + dg + 32).to_byte(),
            (((dr - dg + 8) << 4) + (db - dg + 8)).to_byte(),
          ])
        } else if pixel.a == previous.a {
          Bytes::from_array([b'\xfe', pixel.r, pixel.g, pixel.b])
        } else {
          Bytes::from_array([b'\xff', pixel.r, pixel.g, pixel.b, pixel.a])
        }
        cursor = match qoi_write_part(writer, chunk, requested, cursor) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      }
      previous = pixel
    }
  }
  Ok(cursor)
}

///|
pub impl @codec.ImageEncoder for QoiEncoder with fn encode(
  _self,
  source,
  writer,
  _options,
  limits,
  budget,
  _diagnostics,
) {
  let (channels, color_space) = match qoi_encode_source(source) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let pixels = match @checked.checked_mul(source.width(), source.height()) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let chunks = match qoi_chunk_length(source, channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let total = match @checked.checked_add(22UL, chunks) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for
    item in [
      ("output-bytes", total, limits.max_output_bytes()),
      ("width", source.width(), limits.max_width()),
      ("height", source.height(), limits.max_height()),
      ("pixels", pixels, limits.max_pixels()),
      ("work", total, limits.max_work()),
    ] {
    let (context, requested, limit) = item
    match qoi_encode_limit(context, requested, limit) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  match
    budget.charge(
      @budget.ResourceCharge::new(
        bytes=0UL,
        allocations=0UL,
        allocation_size=0UL,
        width=source.width(),
        height=source.height(),
        pixels=0UL,
        work=total,
      ),
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let header = qoi_encode_header(
    source.width(),
    source.height(),
    channels,
    color_space,
  )
  let completed = match qoi_write_part(writer, header, total, 0UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let completed = match
    qoi_write_chunks(source, channels, writer, total, completed) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let completed = match
    qoi_write_part(
      writer, b"\x00\x00\x00\x00\x00\x00\x00\x01", total, completed,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let disposition = match qoi_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(@codec.EncodeResult::new(disposition, completed))
}
