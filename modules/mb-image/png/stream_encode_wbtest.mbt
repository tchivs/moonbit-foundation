///|
fn png_stream_wb_u32_at(value : Bytes, offset : Int) -> UInt64 {
  (value[offset].to_uint64() << 24) |
  (value[offset + 1].to_uint64() << 16) |
  (value[offset + 2].to_uint64() << 8) |
  value[offset + 3].to_uint64()
}

///|
fn png_stream_wb_slice(value : Bytes, start : Int, length : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = 0; index < length; index = index + 1 { result.push(value[start + index]) }
  Bytes::from_array(result)
}

///|
fn png_stream_wb_adler(value : Bytes, start : Int, length : Int) -> UInt64 {
  let mut adler = 1UL
  for index = 0; index < length; index = index + 1 {
    adler = _png_adler_step(adler, value[start + index])
  }
  adler
}

///|
fn png_stream_wb_image(width? : UInt64 = 1UL) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL, @model.ImageFormat::rgb8(),
    [@model.PlaneDescriptor::new(0UL, width * 3UL, width * 3UL, width * 3UL, 1UL, 1UL, width, 1UL).unwrap()],
    width * 3UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL,
          max_total_bytes=0UL, max_disposition_fields=4UL,
        ), png_stream_wb_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_stream_wb_budget(work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    ignore(view.set_byte(0UL, 0UL, 0UL, b'\x12').unwrap())
    ignore(view.set_byte(0UL, 0UL, 1UL, b'\x34').unwrap())
    view.set_byte(0UL, 0UL, 2UL, b'\x56').unwrap()
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_wb_budget(work? : UInt64 = 1024UL) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL, allocations=16UL, allocation_size=1048576UL, width=70000UL,
    height=64UL, pixels=280000UL, depth=0UL, work~,
  ))
}

///|
fn png_stream_wb_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=1048576UL,
    max_width=70000UL, max_height=64UL, max_pixels=280000UL, max_work=1048576UL,
  )
}

///|
fn png_stream_wb_drain(machine : PngEncodeMachine) -> Bytes {
  let bytes : Array[Byte] = []
  while machine.present().unwrap() is Some(_) {
    let byte = machine.present().unwrap().unwrap()
    bytes.push(byte)
    machine.acknowledge(byte).unwrap()
  }
  Bytes::from_array(bytes)
}

///|
test "PNG encode machine presents bytes without advancing and keeps scalar ownership" {
  let image = png_stream_wb_image()
  let machine = PngEncodeMachine::new(
    image.view(), png_stream_wb_limits(), png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let byte = machine.present().unwrap().unwrap()
  inspect(byte == b'\x89', content="true")
  inspect(machine.present().unwrap() == Some(byte), content="true")
  inspect(machine.completed(), content="0")
  machine.acknowledge(byte).unwrap()
  inspect(machine.completed(), content="1")
  inspect(machine.present().unwrap() == Some(b'P'), content="true")
  inspect(machine.pending is Some(_), content="true")
}

///|
test "PNG encoder isolated four-target evidence retains the pending byte until acknowledgement" {
  let image = png_stream_wb_image()
  let machine = PngEncodeMachine::new(
    image.view(), png_stream_wb_limits(), png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let mut accepted = 0UL
  while accepted < 43UL {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
    accepted = accepted + 1UL
  }
  let failed = machine.present().unwrap().unwrap()
  inspect(machine.completed(), content="43")
  inspect(failed == b'\x01', content="true")
  inspect(machine.present().unwrap() == Some(failed), content="true")
  inspect(machine.completed(), content="43")
  machine.acknowledge(failed).unwrap()
  inspect(machine.completed(), content="44")
  inspect(machine.pending == None, content="true")
  inspect(machine.present().unwrap() == Some(b'\x04'), content="true")
}

///|
test "PNG encode machine covers IDAT CRC and Adler over canonical ranges" {
  let image = png_stream_wb_image()
  let machine = PngEncodeMachine::new(
    image.view(), png_stream_wb_limits(), png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let bytes = png_stream_wb_drain(machine)
  inspect(png_stream_wb_u32_at(bytes, 33) == 15UL, content="true")
  inspect(_png_crc32(png_stream_wb_slice(bytes, 37, 19)) == png_stream_wb_u32_at(bytes, 56), content="true")
  inspect(png_stream_wb_adler(bytes, 48, 4) == png_stream_wb_u32_at(bytes, 52), content="true")
}

///|
test "PNG encode machine selects only the last stored block as final" {
  let image = png_stream_wb_image(width=21846UL)
  let machine = PngEncodeMachine::new(
    image.view(), png_stream_wb_limits(), png_stream_wb_budget(work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  let bytes = png_stream_wb_drain(machine)
  inspect(bytes.length(), content="65612")
  inspect(bytes[43] == b'\x00', content="true")
  inspect(bytes[65583] == b'\x01', content="true")
}

///|
test "PNG chunk encoder acknowledges only accepted lease bytes and finishes on the final acknowledgement" {
  let image = png_stream_wb_image()
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_wb_limits(), png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = @bytes.OwnedBytes::from_bytes(
    b"\x00", png_stream_wb_budget(work=0UL),
  ).unwrap()
  let first = owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(first.written(), content="1")
  inspect(encoder.total_written, content="1")
  match encoder.state {
    PngChunkEncoderState::Active(machine) => inspect(machine.completed(), content="1")
    _ => panic()
  }
}

///|
test "PNG fixed-or-stored preview is stable until acknowledgement at the fixed header" {
  let image = png_stream_wb_image(width=32UL)
  let machine = PngEncodeMachine::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored, png_stream_wb_limits(),
    png_stream_wb_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let mut index = 0
  while index < 43 {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
    index = index + 1
  }
  let fixed_header = machine.present().unwrap().unwrap()
  inspect((fixed_header & b'\x07') == b'\x03', content="true")
  inspect(machine.present().unwrap() == Some(fixed_header), content="true")
  inspect(machine.completed(), content="43")
  machine.acknowledge(fixed_header).unwrap()
  inspect(machine.completed(), content="44")
}
