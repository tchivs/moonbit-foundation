///|
priv struct QoiBuiltinAllocator {}

///|
impl @bytes.Allocator for QoiBuiltinAllocator with fn approve(_self, _length) {
  Ok(())
}

///|
priv struct QoiHeader {
  width : UInt64
  height : UInt64
  channels : UInt64
  transfer : @color.TransferIdentity
}

///|
priv struct QoiPixel {
  r : Byte
  g : Byte
  b : Byte
  a : Byte
}

///|
fn qoi_private_budget(length : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=length,
      allocations=1UL,
      allocation_size=length,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
}

///|
fn qoi_error(
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
    operation="qoi-decode",
    requested?,
    completed?,
    limit?,
    context~,
  )
}

///|
fn qoi_limit(
  context : String,
  requested : UInt64,
  limit : UInt64,
) -> Result[Unit, @error.CoreError] {
  if requested > limit {
    Err(
      qoi_error(
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
fn qoi_read_one(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Byte, UInt64), @error.CoreError] {
  let next = match @checked.checked_add(consumed, 1UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match qoi_limit("input-bytes", next, limits.max_input_bytes()) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Err(error) => Err(error)
    Ok(_) => Ok((scratch.view().get(0UL).unwrap(), next))
  }
}

///|
fn qoi_parse_header(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  limits : @codec.CodecLimits,
) -> Result[(QoiHeader, UInt64), @error.CoreError] {
  let bytes : Array[Byte] = []
  let mut consumed = 0UL
  for field = 0; field < 14; field = field + 1 {
    match qoi_read_one(reader, scratch, consumed, limits) {
      Err(error) => return Err(error)
      Ok((byte, next)) => {
        bytes.push(byte)
        consumed = next
      }
    }
  }
  if bytes[0] != b'q' || bytes[1] != b'o' || bytes[2] != b'i' || bytes[3] != b'f' {
    return Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-magic"))
  }
  let width = bytes[4].to_int().to_uint64() * 16777216UL +
    bytes[5].to_int().to_uint64() * 65536UL +
    bytes[6].to_int().to_uint64() * 256UL + bytes[7].to_int().to_uint64()
  let height = bytes[8].to_int().to_uint64() * 16777216UL +
    bytes[9].to_int().to_uint64() * 65536UL +
    bytes[10].to_int().to_uint64() * 256UL + bytes[11].to_int().to_uint64()
  if width == 0UL || height == 0UL {
    return Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-dimensions"))
  }
  let channels = match bytes[12] {
    b'\x03' => 3UL
    b'\x04' => 4UL
    _ => return Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-channels"))
  }
  let transfer = match bytes[13] {
    b'\x00' => @color.TransferIdentity::EncodedSrgb
    b'\x01' => @color.TransferIdentity::LinearSrgb
    _ => return Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-colorspace"))
  }
  Ok((QoiHeader::{ width, height, channels, transfer }, consumed))
}

///|
fn qoi_empty_metadata(
  transfer : @color.TransferIdentity,
  channels : UInt64,
) -> Result[@model.ImageMetadata, @error.CoreError] {
  let opaque_metadata = match
    @metadata.OpaqueMetadata::from_entries(
      [],
      @metadata.MetadataLimits::new(
        max_entries=0UL,
        max_token_bytes=1UL,
        max_value_bytes=0UL,
        max_total_bytes=0UL,
        max_disposition_fields=0UL,
      ),
      qoi_private_budget(0UL),
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok(
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb,
      transfer,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      opaque_metadata,
    ),
  )
}

///|
fn qoi_descriptor(
  header : QoiHeader,
  payload : UInt64,
) -> Result[@model.ImageDescriptor, @error.CoreError] {
  let row_bytes = match @checked.checked_mul(header.width, header.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let plane = match
    @model.PlaneDescriptor::new(
      0UL, payload, row_bytes, row_bytes, 1UL, 1UL, header.width, header.height,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let metadata = match qoi_empty_metadata(header.transfer, header.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  @model.ImageDescriptor::new(
    header.width,
    header.height,
    if header.channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [plane],
    payload,
    metadata,
  )
}

///|
fn qoi_empty_disposition() -> Result[@metadata.MetadataDisposition, @error.CoreError] {
  @metadata.MetadataDisposition::new(
    [],
    [],
    [],
    false,
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=1UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=0UL,
    ),
  )
}

///|
fn qoi_hash(pixel : QoiPixel) -> Int {
  (pixel.r.to_int() * 3 + pixel.g.to_int() * 5 + pixel.b.to_int() * 7 + pixel.a.to_int() * 11) % 64
}

///|
fn qoi_write_pixel(
  view : @storage.MutImageView,
  header : QoiHeader,
  position : UInt64,
  pixel : QoiPixel,
) -> Result[Unit, @error.CoreError] {
  let x = position % header.width
  let y = position / header.width
  match view.set_byte(x, y, 0UL, pixel.r) { Err(error) => return Err(error); Ok(_) => () }
  match view.set_byte(x, y, 1UL, pixel.g) { Err(error) => return Err(error); Ok(_) => () }
  match view.set_byte(x, y, 2UL, pixel.b) { Err(error) => return Err(error); Ok(_) => () }
  if header.channels == 4UL {
    match view.set_byte(x, y, 3UL, pixel.a) { Err(error) => return Err(error); Ok(_) => () }
  }
  Ok(())
}

///|
fn qoi_read_payload(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[(Byte, UInt64), @error.CoreError] {
  match qoi_read_one(reader, scratch, consumed, limits) {
    Err(error) => {
      let completed = match error.completed() {
        Some(value) => value
        None => 0UL
      }
      Err(qoi_error(
        error.category(), error.code(), "qoi-payload",
        requested=1UL,
        completed~, 
      ))
    }
    Ok(value) => Ok(value)
  }
}

///|
fn qoi_finish_strict(
  reader : &@io.Reader,
  scratch : @bytes.OwnedBytes,
  consumed : UInt64,
  limits : @codec.CodecLimits,
) -> Result[UInt64, @error.CoreError] {
  let mut cursor = consumed
  for expected in [b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x01'] {
    match qoi_read_one(reader, scratch, cursor, limits) {
      Err(error) => return Err(error)
      Ok((actual, next)) => {
        if actual != expected {
          return Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-end-marker"))
        }
        cursor = next
      }
    }
  }
  match scratch.with_mut(0UL, 1UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Ok(_) => Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-trailing-data", requested=1UL, completed=0UL))
    Err(error) => if error.code() == @error.ErrorCode::UnexpectedEndOfStream { Ok(cursor) } else { Err(error) }
  }
}

///|
pub impl @codec.ImageDecoder for QoiDecoder with fn probe(
  _self,
  prefix,
  limits,
  _diagnostics,
) {
  if prefix.length() > limits.max_probe_bytes() {
    return Err(qoi_error(@error.ErrorCategory::Resource, @error.ErrorCode::BudgetExceeded, "probe-bytes", requested=prefix.length(), limit=limits.max_probe_bytes()))
  }
  Ok(_probe_qoi_prefix(prefix))
}

///|
pub impl @codec.ImageDecoder for QoiDecoder with fn decode(
  _self,
  reader,
  options,
  limits,
  budget,
  _diagnostics,
) {
  let scratch = match @bytes.OwnedBytes::new(1UL, qoi_private_budget(1UL)) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let (header, initial_consumed) = match qoi_parse_header(reader, scratch, limits) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut consumed = initial_consumed
  let pixels = match @checked.checked_mul(header.width, header.height) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let payload = match @checked.checked_mul(pixels, header.channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let work = match @checked.checked_add(pixels, payload) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  for item in [
    ("output-bytes", payload, limits.max_output_bytes()),
    ("width", header.width, limits.max_width()),
    ("height", header.height, limits.max_height()),
    ("pixels", pixels, limits.max_pixels()),
    ("work", work, limits.max_work()),
  ] {
    let (context, requested, limit) = item
    match qoi_limit(context, requested, limit) { Err(error) => return Err(error); Ok(_) => () }
  }
  let descriptor = match qoi_descriptor(header, payload) { Err(error) => return Err(error); Ok(value) => value }
  let image = match @storage.OwnedImage::new_operation(descriptor, budget, QoiBuiltinAllocator::{  } as &@bytes.Allocator, work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match image.with_mut_view(fn(view) {
    let index = Array::make(64, QoiPixel::{ r: b'\x00', g: b'\x00', b: b'\x00', a: b'\x00' })
    let mut previous = QoiPixel::{ r: b'\x00', g: b'\x00', b: b'\x00', a: b'\xff' }
    let mut written = 0UL
    while written < pixels {
      let (opcode, next) = match qoi_read_payload(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
      consumed = next
      let mut run = 1UL
      match opcode {
        b'\xfe' => {
          let (r, after_r) = match qoi_read_payload(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
          let (g, after_g) = match qoi_read_payload(reader, scratch, after_r, limits) { Err(error) => return Err(error); Ok(value) => value }
          let (b, after_b) = match qoi_read_payload(reader, scratch, after_g, limits) { Err(error) => return Err(error); Ok(value) => value }
          previous = QoiPixel::{ r, g, b, a: previous.a }
          consumed = after_b
        }
        b'\xff' => {
          let (r, after_r) = match qoi_read_payload(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
          let (g, after_g) = match qoi_read_payload(reader, scratch, after_r, limits) { Err(error) => return Err(error); Ok(value) => value }
          let (b, after_b) = match qoi_read_payload(reader, scratch, after_g, limits) { Err(error) => return Err(error); Ok(value) => value }
          let (a, after_a) = match qoi_read_payload(reader, scratch, after_b, limits) { Err(error) => return Err(error); Ok(value) => value }
          previous = QoiPixel::{ r, g, b, a }
          consumed = after_a
        }
        b'\x00'..=b'\x3f' => previous = index[opcode.to_int()]
        b'\x40'..=b'\x7f' => {
          previous = QoiPixel::{
            r: (previous.r.to_int() + ((opcode.to_int() >> 4) & 3) - 2).to_byte(),
            g: (previous.g.to_int() + ((opcode.to_int() >> 2) & 3) - 2).to_byte(),
            b: (previous.b.to_int() + (opcode.to_int() & 3) - 2).to_byte(),
            a: previous.a,
          }
        }
        b'\x80'..=b'\xbf' => {
          let (second, after_second) = match qoi_read_payload(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
          let delta_green = (opcode.to_int() & 63) - 32
          previous = QoiPixel::{
            r: (previous.r.to_int() + delta_green + ((second.to_int() >> 4) & 15) - 8).to_byte(),
            g: (previous.g.to_int() + delta_green).to_byte(),
            b: (previous.b.to_int() + delta_green + (second.to_int() & 15) - 8).to_byte(),
            a: previous.a,
          }
          consumed = after_second
        }
        b'\xc0'..=b'\xfd' => run = (opcode.to_int() & 63).to_uint64() + 1UL
      }
      let remaining = pixels - written
      if run > remaining {
        return Err(qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-run-overrun", requested=run, limit=remaining))
      }
      for repeated = 0UL; repeated < run; repeated = repeated + 1UL {
        match qoi_write_pixel(view, header, written, previous) { Err(error) => return Err(error); Ok(_) => () }
        index[qoi_hash(previous)] = previous
        written = written + 1UL
      }
    }
    Ok(())
  }) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let bytes_read = if options.require_complete_input() {
    match qoi_finish_strict(reader, scratch, consumed, limits) { Err(error) => return Err(error); Ok(value) => value }
  } else {
    consumed
  }
  let disposition = match qoi_empty_disposition() { Err(error) => return Err(error); Ok(value) => value }
  Ok(@codec.DecodeResult::new(image, disposition, bytes_read))
}
