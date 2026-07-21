///|
fn png_encode_u32_at(value : Bytes, offset : Int) -> UInt64 {
  (value[offset].to_uint64() << 24) |
  (value[offset + 1].to_uint64() << 16) |
  (value[offset + 2].to_uint64() << 8) |
  value[offset + 3].to_uint64()
}

///| Phase 36 RED: strict complete-PNG dynamic selection is not implemented yet.
test "PNG dynamic preflight selects only strict complete-PNG wins" {
  inspect(false, content="dynamic strict preflight missing")
}

///|
fn png_wb_budget(bytes? : UInt64 = 512UL, work? : UInt64 = 1024UL) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations=8UL, allocation_size=bytes, width=64UL,
    height=64UL, pixels=4096UL, depth=0UL, work~,
  ))
}

///|
fn png_wb_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=512UL, max_output_bytes=512UL,
    max_width=64UL, max_height=64UL, max_pixels=4096UL, max_work=1024UL,
  )
}

///|
fn png_wb_image(channels : UInt64, pixels : Bytes) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    1UL, 1UL,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels, channels, channels, 1UL, 1UL, 1UL, 1UL).unwrap()],
    channels,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL,
          max_total_bytes=0UL, max_disposition_fields=4UL,
        ), png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_wb_budget(bytes=channels, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for index = 0UL; index < channels; index = index + 1UL {
      view.set_byte(0UL, 0UL, index, pixels[index.to_int()]).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_wb_encode(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(512UL, png_wb_budget(bytes=512UL, work=0UL)).unwrap()
  let _ = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_wb_limits(), png_wb_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_wb_machine_encode(image : @storage.OwnedImage) -> (Bytes, UInt64) {
  let machine = PngEncodeMachine::new(
    image.view(), png_wb_limits(), png_wb_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let bytes : Array[Byte] = []
  while machine.present().unwrap() is Some(_) {
    let byte = machine.present().unwrap().unwrap()
    bytes.push(byte)
    machine.acknowledge(byte).unwrap()
  }
  (Bytes::from_array(bytes), machine.completed())
}

///|
fn png_encode_slice(value : Bytes, start : Int, length : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = 0; index < length; index = index + 1 { result.push(value[start + index]) }
  Bytes::from_array(result)
}

///|
fn png_encode_adler(value : Bytes, start : Int, length : Int) -> UInt64 {
  let mut adler = 1UL
  for index = 0; index < length; index = index + 1 {
    adler = _png_adler_step(adler, value[start + index])
  }
  adler
}

///|
test "canonical PNG RGB framing has checked chunks stored block and checksums" {
  let bytes = png_wb_encode(png_wb_image(3UL, b"\x12\x34\x56"))
  inspect(bytes.length(), content="72")
  inspect(png_encode_slice(bytes, 0, 8) == b"\x89PNG\r\n\x1a\n", content="true")
  inspect(png_encode_u32_at(bytes, 8) == 13UL, content="true")
  inspect(png_encode_slice(bytes, 12, 4) == b"IHDR", content="true")
  inspect(png_encode_u32_at(bytes, 33) == 15UL, content="true")
  inspect(png_encode_slice(bytes, 37, 4) == b"IDAT", content="true")
  inspect(bytes[41] == b'\x78' && bytes[42] == b'\x01', content="true")
  inspect(bytes[43] == b'\x01' && bytes[44] == b'\x04' && bytes[45] == b'\x00', content="true")
  inspect(bytes[46] == b'\xfb' && bytes[47] == b'\xff', content="true")
  inspect(bytes[48] == b'\x00' && bytes[49] == b'\x12' && bytes[50] == b'\x34' && bytes[51] == b'\x56', content="true")
  inspect(png_encode_adler(bytes, 48, 4) == png_encode_u32_at(bytes, 52), content="true")
  inspect(_png_crc32(png_encode_slice(bytes, 12, 17)) == png_encode_u32_at(bytes, 29), content="true")
  inspect(_png_crc32(png_encode_slice(bytes, 37, 19)) == png_encode_u32_at(bytes, 56), content="true")
  inspect(_png_crc32(b"IEND") == png_encode_u32_at(bytes, 68), content="true")
}

///|
test "canonical PNG byte sequence is stable for RGB and straight RGBA" {
  for image in [png_wb_image(3UL, b"\x12\x34\x56"), png_wb_image(4UL, b"\x04\x05\x06\x07")] {
    let first = png_wb_encode(image)
    let second = png_wb_encode(image)
    inspect(first == second, content="true")
    if image.view().format().channel_count() == 3UL {
      inspect(first[25] == b'\x02', content="true")
    } else {
      inspect(first[25] == b'\x06', content="true")
    }
  }
}

///|
test "PNG encoder isolated four-target evidence matches eager and private canonical sequences" {
  for image in [png_wb_image(3UL, b"\x12\x34\x56"), png_wb_image(4UL, b"\x04\x05\x06\x07")] {
    let eager = png_wb_encode(image)
    let (machine, completed) = png_wb_machine_encode(image)
    inspect(eager == machine, content="true")
    inspect(completed == eager.length().to_uint64(), content="true")
  }
}

///|
test "PNG fixed-or-stored fixed-code arithmetic reverses codes and handles length 258" {
  let (literal_zero, literal_zero_bits) = _png_fixed_literal_code(0UL)
  let (eob, eob_bits) = _png_fixed_literal_code(256UL)
  let (length_symbol, length_extra, length_extra_bits) = _png_fixed_length_code(258UL)
  inspect(literal_zero, content="12")
  inspect(literal_zero_bits, content="8")
  inspect(eob, content="0")
  inspect(eob_bits, content="7")
  inspect(length_symbol, content="285")
  inspect(length_extra, content="0")
  inspect(length_extra_bits, content="0")
}

///|
fn png_wb_fixed_or_stored_replay_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    5UL, 1UL, @model.ImageFormat::rgb8(),
    [@model.PlaneDescriptor::new(0UL, 15UL, 15UL, 15UL, 1UL, 1UL, 5UL, 1UL).unwrap()],
    15UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL,
          max_total_bytes=0UL, max_disposition_fields=4UL,
        ), png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_wb_budget(bytes=15UL, work=0UL)).unwrap()
  let pixels = [
    b'\x0a', b'\x0c', b'\x0c', b'\x0a', b'\x0a', b'\x0c', b'\x0b', b'\x0c', b'\x0a',
    b'\x0c', b'\x0a', b'\x0b', b'\x0a', b'\x0c', b'\x0a',
  ]
  image.with_mut_view(fn(view) {
    for index = 0UL; index < 15UL; index = index + 1UL {
      view.set_byte(index / 3UL, 0UL, index % 3UL, pixels[index.to_int()]).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_wb_same_remaining(left : @budget.ResourceLimits, right : @budget.ResourceLimits) -> Bool {
  left.bytes() == right.bytes() && left.allocations() == right.allocations() &&
    left.allocation_size() == right.allocation_size() && left.width() == right.width() &&
    left.height() == right.height() && left.pixels() == right.pixels() &&
    left.depth() == right.depth() && left.work() == right.work()
}

///|
test "PNG fixed-or-stored white-box selected work boundary charges once" {
  let image = png_wb_fixed_or_stored_replay_image()
  let generous = png_wb_budget(work=1024UL)
  let before = generous.remaining()
  let facts = _png_encode_preflight(
    image.view(), PngCompressionStrategy::FixedOrStored, png_wb_limits(), generous,
  ).unwrap()
  let selected = before.work() - generous.remaining().work()
  match facts.plan {
    PngDeflatePlan::Fixed(plan) => {
      inspect(plan.matcher_work, content="189")
      inspect(plan.deflate_bits, content="126")
      inspect(plan.deflate_bytes, content="16")
      inspect(selected == facts.total_length + plan.matcher_work + plan.matcher_work, content="true")
    }
    PngDeflatePlan::Stored(_) => panic()
  }
  let exact = png_wb_budget(work=selected)
  ignore(_png_encode_preflight(
    image.view(), PngCompressionStrategy::FixedOrStored, png_wb_limits(), exact,
  ).unwrap())
  inspect(exact.remaining().work(), content="0")
  let one_less = png_wb_budget(work=selected - 1UL)
  let one_less_before = one_less.remaining()
  let rejected = _png_encode_preflight(
    image.view(), PngCompressionStrategy::FixedOrStored, png_wb_limits(), one_less,
  ).unwrap_err()
  inspect(rejected.context() == Some("work"), content="true")
  inspect(png_wb_same_remaining(one_less_before, one_less.remaining()), content="true")
}
