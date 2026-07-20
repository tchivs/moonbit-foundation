///|
priv enum QoiStreamPending {
  Opcode
  Rgb(Array[Byte])
  Rgba(Array[Byte])
  Luma(Byte)
}

///|
priv struct QoiStreamPixels {
  header : QoiHeader
  image : @storage.OwnedImage
  pixels : UInt64
  index : Array[QoiPixel]
  mut previous : QoiPixel
  mut written : UInt64
  mut pending : QoiStreamPending
}

///|
priv enum QoiStreamState {
  Header(Array[Byte])
  Pixels(QoiStreamPixels)
  Marker(QoiStreamPixels, Array[Byte])
  Trailing(QoiStreamPixels, Array[Byte], Bool)
  Failed(@error.CoreError)
  Finished
}

///|
fn qoi_stream_state_error() -> @error.CoreError {
  qoi_error(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    "qoi-stream-terminal",
  )
}

///|
fn qoi_stream_incomplete(
  context : String,
  completed : UInt64,
) -> @error.CoreError {
  qoi_error(
    @error.ErrorCategory::Data,
    @error.ErrorCode::UnexpectedEndOfStream,
    context,
    completed~,
  )
}

///|
fn qoi_stream_preflight(
  bytes : Array[Byte],
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> Result[QoiStreamPixels, @error.CoreError] {
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
  let header = QoiHeader::{ width, height, channels, transfer }
  let pixels = match @checked.checked_mul(width, height) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let payload = match @checked.checked_mul(pixels, channels) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let work = match @checked.checked_add(pixels, payload) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  for item in [
    ("output-bytes", payload, limits.max_output_bytes()),
    ("width", width, limits.max_width()),
    ("height", height, limits.max_height()),
    ("pixels", pixels, limits.max_pixels()),
    ("work", work, limits.max_work()),
  ] {
    let (context, requested, limit) = item
    match qoi_limit(context, requested, limit) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  let descriptor = match qoi_descriptor(header, payload) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let image = match @storage.OwnedImage::new_operation(
    descriptor,
    budget,
    QoiBuiltinAllocator::{  } as &@bytes.Allocator,
    work,
  ) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    header,
    image,
    pixels,
    index: Array::make(64, QoiPixel::{ r: b'\x00', g: b'\x00', b: b'\x00', a: b'\x00' }),
    previous: QoiPixel::{ r: b'\x00', g: b'\x00', b: b'\x00', a: b'\xff' },
    written: 0UL,
    pending: QoiStreamPending::Opcode,
  })
}

///|
fn QoiStreamPixels::emit(
  self : QoiStreamPixels,
  pixel : QoiPixel,
  run : UInt64,
) -> Result[Unit, @error.CoreError] {
  let remaining = self.pixels - self.written
  if run > remaining {
    return Err(qoi_error(
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
      "qoi-run-overrun",
      requested=run,
      limit=remaining,
    ))
  }
  match self.image.with_mut_view(fn(view) {
    for repeated = 0UL; repeated < run; repeated = repeated + 1UL {
      match qoi_write_pixel(view, self.header, self.written + repeated, pixel) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
    }
    Ok(())
  }) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  for repeated = 0UL; repeated < run; repeated = repeated + 1UL {
    self.index[qoi_hash(pixel)] = pixel
  }
  self.previous = pixel
  self.written = self.written + run
  Ok(())
}

///|
fn QoiStreamPixels::feed(
  self : QoiStreamPixels,
  byte : Byte,
) -> Result[Bool, @error.CoreError] {
  match self.pending {
    Opcode => match byte {
      b'\xfe' => { self.pending = Rgb([]); Ok(false) }
      b'\xff' => { self.pending = Rgba([]); Ok(false) }
      b'\x00'..=b'\x3f' => {
        match self.emit(self.index[byte.to_int()], 1UL) {
          Ok(_) => Ok(self.written == self.pixels)
          Err(error) => Err(error)
        }
      }
      b'\x40'..=b'\x7f' => {
        let previous = self.previous
        match self.emit(QoiPixel::{
          r: (previous.r.to_int() + ((byte.to_int() >> 4) & 3) - 2).to_byte(),
          g: (previous.g.to_int() + ((byte.to_int() >> 2) & 3) - 2).to_byte(),
          b: (previous.b.to_int() + (byte.to_int() & 3) - 2).to_byte(),
          a: previous.a,
        }, 1UL) {
          Ok(_) => Ok(self.written == self.pixels)
          Err(error) => Err(error)
        }
      }
      b'\x80'..=b'\xbf' => { self.pending = Luma(byte); Ok(false) }
      b'\xc0'..=b'\xfd' => {
        match self.emit(self.previous, (byte.to_int() & 63).to_uint64() + 1UL) {
          Ok(_) => Ok(self.written == self.pixels)
          Err(error) => Err(error)
        }
      }
    }
    Rgb(values) => {
      values.push(byte)
      if values.length() < 3 { Ok(false) } else {
        self.pending = Opcode
        match self.emit(QoiPixel::{ r: values[0], g: values[1], b: values[2], a: self.previous.a }, 1UL) {
          Ok(_) => Ok(self.written == self.pixels)
          Err(error) => Err(error)
        }
      }
    }
    Rgba(values) => {
      values.push(byte)
      if values.length() < 4 { Ok(false) } else {
        self.pending = Opcode
        match self.emit(QoiPixel::{ r: values[0], g: values[1], b: values[2], a: values[3] }, 1UL) {
          Ok(_) => Ok(self.written == self.pixels)
          Err(error) => Err(error)
        }
      }
    }
    Luma(first) => {
      let previous = self.previous
      let delta_green = (first.to_int() & 63) - 32
      self.pending = Opcode
      match self.emit(QoiPixel::{
        r: (previous.r.to_int() + delta_green + ((byte.to_int() >> 4) & 15) - 8).to_byte(),
        g: (previous.g.to_int() + delta_green).to_byte(),
        b: (previous.b.to_int() + delta_green + (byte.to_int() & 15) - 8).to_byte(),
        a: previous.a,
      }, 1UL) {
        Ok(_) => Ok(self.written == self.pixels)
        Err(error) => Err(error)
      }
    }
  }
}

///|
fn QoiStreamDecoder::fail(
  self : QoiStreamDecoder,
  error : @error.CoreError,
) -> Unit {
  self.state = QoiStreamState::Failed(error)
}

///|
fn QoiStreamDecoder::feed_byte(
  self : QoiStreamDecoder,
  byte : Byte,
) -> Result[Unit, @error.CoreError] {
  match self.state {
    Header(bytes) => {
      bytes.push(byte)
      if bytes.length() == 14 {
        match qoi_stream_preflight(bytes, self.limits, self.budget) {
          Ok(pixels) => self.state = QoiStreamState::Pixels(pixels)
          Err(error) => return Err(error)
        }
      }
      Ok(())
    }
    Pixels(pixels) => {
      match pixels.feed(byte) {
        Err(error) => return Err(error)
        Ok(true) => self.state = QoiStreamState::Marker(pixels, [])
        Ok(false) => ()
      }
      Ok(())
    }
    Marker(pixels, marker) => {
      marker.push(byte)
      if marker.length() == 8 { self.state = QoiStreamState::Trailing(pixels, marker, false) }
      Ok(())
    }
    Trailing(pixels, marker, _) => {
      self.state = QoiStreamState::Trailing(pixels, marker, true)
      Ok(())
    }
    Failed(error) => Err(error)
    Finished => Err(qoi_stream_state_error())
  }
}

///|
pub fn QoiStreamDecoder::push(
  self : QoiStreamDecoder,
  source : @bytes.ByteView,
) -> QoiStreamPushResult {
  match self.state {
    Failed(_) | Finished => return { consumed_value: 0UL, outcome_value: Failed(qoi_stream_state_error()) }
    _ => ()
  }
  let mut accepted = 0UL
  for index = 0UL; index < source.length(); index = index + 1UL {
    let next = match @checked.checked_add(self.consumed_total, 1UL) {
      Ok(value) => value
      Err(error) => {
        self.fail(error)
        return { consumed_value: accepted, outcome_value: Failed(error) }
      }
    }
    match qoi_limit("input-bytes", next, self.limits.max_input_bytes()) {
      Ok(_) => ()
      Err(error) => {
        self.fail(error)
        return { consumed_value: accepted, outcome_value: Failed(error) }
      }
    }
    let byte = source.get(index).unwrap()
    self.consumed_total = next
    accepted = accepted + 1UL
    match self.feed_byte(byte) {
      Ok(_) => ()
      Err(error) => {
        self.fail(error)
        return { consumed_value: accepted, outcome_value: Failed(error) }
      }
    }
  }
  { consumed_value: accepted, outcome_value: NeedInput }
}

///|
pub fn QoiStreamDecoder::finish(
  self : QoiStreamDecoder,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  match self.state {
    Failed(_) | Finished => Err(qoi_stream_state_error())
    Header(bytes) => {
      let error = qoi_stream_incomplete("qoi-header", bytes.length().to_uint64())
      self.fail(error)
      Err(error)
    }
    Pixels(pixels) => {
      let completed = match pixels.pending {
        Opcode => self.consumed_total
        _ => self.consumed_total
      }
      let error = qoi_stream_incomplete("qoi-payload", completed)
      self.fail(error)
      Err(error)
    }
    Marker(_, marker) => {
      if marker.length() < 8 {
        let error = qoi_stream_incomplete("qoi-end-marker", marker.length().to_uint64())
        self.fail(error)
        return Err(error)
      }
      abort("marker is transferred to trailing when complete")
    }
    Trailing(pixels, marker, has_trailing) => {
      let expected = [b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x01']
      for index = 0; index < 8; index = index + 1 {
        if marker[index] != expected[index] {
          let error = qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-end-marker")
          self.fail(error)
          return Err(error)
        }
      }
      if has_trailing {
        let error = qoi_error(@error.ErrorCategory::Data, @error.ErrorCode::InvalidEncoding, "qoi-trailing-data", requested=1UL, completed=0UL)
        self.fail(error)
        return Err(error)
      }
      let disposition = match qoi_empty_disposition() {
        Ok(value) => value
        Err(error) => { self.fail(error); return Err(error) }
      }
      self.state = QoiStreamState::Finished
      Ok(@codec.DecodeResult::new(pixels.image, disposition, self.consumed_total))
    }
  }
}
