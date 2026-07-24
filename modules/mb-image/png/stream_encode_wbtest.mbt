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
  for index = 0; index < length; index = index + 1 {
    result.push(value[start + index])
  }
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
    width,
    1UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(
        0UL,
        width * 3UL,
        width * 3UL,
        width * 3UL,
        1UL,
        1UL,
        width,
        1UL,
      ).unwrap(),
    ],
    width * 3UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb,
      @color.TransferIdentity::EncodedSrgb,
      None,
      @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [],
        @metadata.MetadataLimits::new(
          max_entries=0UL,
          max_token_bytes=1UL,
          max_value_bytes=0UL,
          max_total_bytes=0UL,
          max_disposition_fields=4UL,
        ),
        png_stream_wb_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    png_stream_wb_budget(work=0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    ignore(view.set_byte(0UL, 0UL, 0UL, b'\x12').unwrap())
    ignore(view.set_byte(0UL, 0UL, 1UL, b'\x34').unwrap())
    view.set_byte(0UL, 0UL, 2UL, b'\x56').unwrap()
    Ok(())
  })
  .unwrap()
  image
}

///|
fn png_stream_wb_dynamic_image() -> @storage.OwnedImage {
  let image = png_stream_wb_image(width=128UL)
  image
  .with_mut_view(fn(view) {
    for x = 0UL; x < 128UL; x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        view
        .set_byte(x, 0UL, channel, ((x * 3UL + channel) % 5UL).to_byte())
        .unwrap()
      }
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
/// A multi-row straight-RGBA8 source exercises the same source cursor with a
/// different pixel width. The matching rows make Adaptive choose Sub then Up.
fn png_stream_wb_adaptive_rgba_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL,
    2UL,
    @model.ImageFormat::rgba8(),
    [
      @model.PlaneDescriptor::new(0UL, 16UL, 8UL, 8UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
    ],
    16UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb,
      @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight),
      @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [],
        @metadata.MetadataLimits::new(
          max_entries=0UL,
          max_token_bytes=1UL,
          max_value_bytes=0UL,
          max_total_bytes=0UL,
          max_disposition_fields=4UL,
        ),
        png_stream_wb_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    png_stream_wb_budget(work=0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    for row = 0UL; row < 2UL; row = row + 1UL {
      for index = 0UL; index < 8UL; index = index + 1UL {
        view
        .set_byte(
          index / 4UL,
          row,
          index % 4UL,
          [b'\x0a', b'\x14', b'\x1e', b'\x28'][index.to_int() % 4],
        )
        .unwrap()
      }
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
fn png_stream_wb_budget(work? : UInt64 = 1024UL) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=1048576UL,
      allocations=16UL,
      allocation_size=1048576UL,
      width=70000UL,
      height=64UL,
      pixels=280000UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn png_stream_wb_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=1048576UL,
    max_output_bytes=1048576UL,
    max_width=70000UL,
    max_height=64UL,
    max_pixels=280000UL,
    max_work=1048576UL,
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

///| A 5x5 row-major RGB8/RGBA8 source forces all seven Adam7 passes to emit,
/// so a DEFLATE preview exercises a real multi-pass cursor successor.
fn png_stream_wb_adam7_image(channels : UInt64) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    5UL, 5UL,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(
      0UL, channels * 25UL, channels * 5UL, channels * 5UL,
      1UL, 1UL, 5UL, 5UL,
    ).unwrap()],
    channels * 25UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb,
      @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [],
        @metadata.MetadataLimits::new(
          max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL,
          max_total_bytes=0UL, max_disposition_fields=4UL,
        ), png_stream_wb_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_wb_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          view.set_byte(x, y, channel, (y * channels * 5UL + x * channels + channel).to_byte()).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_wb_append(machine : PngEncodeMachine, bytes : Array[Byte]) -> Unit {
  while machine.present().unwrap() is Some(_) {
    let byte = machine.present().unwrap().unwrap()
    bytes.push(byte)
    machine.acknowledge(byte).unwrap()
  }
}

///| `present` may cache a DEFLATE byte, but it must not commit the real Adam7
/// cursor, CRC, or Adler successor until the caller acknowledges that byte.
test "PNG Adam7 multi-pass preview waits for acknowledgement" {
  for channels in [3UL, 4UL] {
    let image = png_stream_wb_adam7_image(channels)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      let delayed = PngEncodeMachine::new_with_all_strategies(
        image.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
        png_stream_wb_limits(), png_stream_wb_budget(work=1048576UL),
        @error.Diagnostics::new(),
      ).unwrap()
      let delayed_bytes : Array[Byte] = []
      while delayed.completed() < 43UL {
        let byte = delayed.present().unwrap().unwrap()
        delayed_bytes.push(byte)
        delayed.acknowledge(byte).unwrap()
      }
      let preview = delayed.present().unwrap().unwrap()
      let completed = delayed.completed()
      let idat_crc = delayed.idat_crc
      let adler = delayed.adler
      for _ in [0, 1, 2] {
        if delayed.present().unwrap() != Some(preview) ||
          delayed.completed() != completed || delayed.idat_crc != idat_crc ||
          delayed.adler != adler {
          abort("png adam7 preview advanced before acknowledgement")
        }
      }
      delayed_bytes.push(preview)
      delayed.acknowledge(preview).unwrap()
      png_stream_wb_append(delayed, delayed_bytes)

      let immediate = PngEncodeMachine::new_with_all_strategies(
        image.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
        png_stream_wb_limits(), png_stream_wb_budget(work=1048576UL),
        @error.Diagnostics::new(),
      ).unwrap()
      let immediate_bytes : Array[Byte] = []
      png_stream_wb_append(immediate, immediate_bytes)
      if Bytes::from_array(delayed_bytes) != Bytes::from_array(immediate_bytes) {
        abort("png adam7 preview replay changed output")
      }
    }
  }
}

///|
/// Dynamic state is a preview effect: repeated present calls at the first
/// DEFLATE byte must not install the next scalar state.
test "PNG dynamic replay preview waits for acknowledgement" {
  let image = png_stream_wb_dynamic_image()
  let machine = PngEncodeMachine::new_with_compression_strategy(
    image.view(),
    PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_wb_limits(),
    png_stream_wb_budget(work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  while machine.completed() < 43UL {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
  }
  let first = machine.present().unwrap().unwrap()
  let before = machine.dynamic_state.unwrap()
  inspect(machine.present().unwrap() == Some(first), content="true")
  inspect(
    machine.dynamic_state.unwrap().phase == before.phase &&
    machine.completed() == 43UL,
    content="true",
  )
  machine.acknowledge(first).unwrap()
  inspect(machine.completed() == 44UL, content="true")
}

///|
/// The admitted fingerprint/work is checked before EOB, and the normal machine
/// error is repeatable without any later acknowledgement.
test "PNG dynamic replay verifies planned work and source fingerprint" {
  let image = png_stream_wb_dynamic_image()
  let machine = PngEncodeMachine::new_with_compression_strategy(
    image.view(),
    PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_wb_limits(),
    png_stream_wb_budget(work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  image
  .with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'\xff') })
  .unwrap()
  let mut failure : @error.CoreError? = None
  while machine.completed() < machine.total_length() {
    match machine.present() {
      Err(error) => {
        failure = Some(error)
        break
      }
      Ok(Some(byte)) => machine.acknowledge(byte).unwrap()
      Ok(None) => break
    }
  }
  let first = failure.unwrap()
  let second = machine.present().unwrap_err()
  inspect(
    first.context() == Some("png-encode-dynamic-replay-drift"),
    content="true",
  )
  inspect(
    second.context() == first.context() &&
    machine.completed() < machine.total_length(),
    content="true",
  )
}

///|
/// PNGF-02: the fixed-state source cursor exposes the selected tag and
/// residuals, while the established None provider remains unchanged.
test "PNG adaptive planner cursor replays selected RGB and RGBA rows" {
  let rgb = png_wb_adaptive_rgb_image()
  let rgba = png_stream_wb_adaptive_rgba_image()
  let rgb_machine = PngEncodeMachine::new_with_strategies(
    rgb.view(),
    PngCompressionStrategy::Stored,
    PngFilterStrategy::Adaptive,
    png_stream_wb_limits(),
    png_stream_wb_budget(work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  let rgba_machine = PngEncodeMachine::new_with_strategies(
    rgba.view(),
    PngCompressionStrategy::Stored,
    PngFilterStrategy::Adaptive,
    png_stream_wb_limits(),
    png_stream_wb_budget(work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  let none_machine = PngEncodeMachine::new_with_strategies(
    rgb.view(),
    PngCompressionStrategy::Stored,
    PngFilterStrategy::None,
    png_stream_wb_limits(),
    png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  inspect(rgb_machine.scanline_byte(0UL).unwrap() == b'\x01', content="true")
  inspect(rgb_machine.scanline_byte(1UL).unwrap() == b'\x0a', content="true")
  inspect(rgb_machine.scanline_byte(4UL).unwrap() == b'\x00', content="true")
  inspect(rgb_machine.scanline_byte(7UL).unwrap() == b'\x02', content="true")
  inspect(rgba_machine.scanline_byte(0UL).unwrap() == b'\x01', content="true")
  inspect(rgba_machine.scanline_byte(9UL).unwrap() == b'\x02', content="true")
  inspect(none_machine.scanline_byte(0UL).unwrap() == b'\x00', content="true")
}

///|
test "PNG adaptive planner cursor keeps row selection pending until acknowledgement" {
  let image = png_wb_adaptive_rgb_image()
  let cursor = PngFilteredCursor::new(
    image.view(), 6UL, 3UL, PngFilterStrategy::Adaptive,
  )
  let (first, preview) = cursor.next().unwrap()
  inspect(first == b'\x01', content="true")
  inspect(cursor.facts().resolved_rows, content="0")
  inspect(preview.facts().resolved_rows, content="1")
  let (second, again) = cursor.next().unwrap()
  inspect(second == first, content="true")
  inspect(cursor.facts().resolved_rows, content="0")
  inspect(again.facts().resolved_rows, content="1")
  let (next, committed) = preview.next().unwrap()
  inspect(next == b'\x0a', content="true")
  inspect(committed.facts().resolved_rows, content="1")
}

///|
///| The matcher probe must use the same one-row-at-a-time source that later
///| becomes the acknowledged replay successor; a Fixed preflight therefore has
///| Stored and Fixed planning traversals before its one replay traversal.
test "PNG adaptive match cursor keeps Fixed preview accounting bounded" {
  let image = png_wb_adaptive_rgb_image()
  let facts = _png_encode_preflight_with_filter(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    PngFilterStrategy::Adaptive,
    png_stream_wb_limits(),
    png_stream_wb_budget(work=1048576UL),
  ).unwrap()
  inspect(facts.adaptive_planning_facts.resolved_rows, content="4")
  inspect(facts.adaptive_replay_facts.resolved_rows, content="2")
}

///|
test "PNG encode machine presents bytes without advancing and keeps scalar ownership" {
  let image = png_stream_wb_image()
  let machine = PngEncodeMachine::new(
    image.view(),
    png_stream_wb_limits(),
    png_stream_wb_budget(),
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
    image.view(),
    png_stream_wb_limits(),
    png_stream_wb_budget(),
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
    image.view(),
    png_stream_wb_limits(),
    png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let bytes = png_stream_wb_drain(machine)
  inspect(png_stream_wb_u32_at(bytes, 33) == 15UL, content="true")
  inspect(
    _png_crc32(png_stream_wb_slice(bytes, 37, 19)) ==
    png_stream_wb_u32_at(bytes, 56),
    content="true",
  )
  inspect(
    png_stream_wb_adler(bytes, 48, 4) == png_stream_wb_u32_at(bytes, 52),
    content="true",
  )
}

///|
test "PNG encode machine selects only the last stored block as final" {
  let image = png_stream_wb_image(width=21846UL)
  let machine = PngEncodeMachine::new(
    image.view(),
    png_stream_wb_limits(),
    png_stream_wb_budget(work=1048576UL),
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
    image.view(),
    png_stream_wb_limits(),
    png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = @bytes.OwnedBytes::from_bytes(
    b"\x00",
    png_stream_wb_budget(work=0UL),
  ).unwrap()
  let first = owner
    .with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) })
    .unwrap()
  inspect(first.written(), content="1")
  inspect(encoder.total_written, content="1")
  match encoder.state {
    PngChunkEncoderState::Active(machine) =>
      inspect(machine.completed(), content="1")
    _ => panic()
  }
}

///|
test "PNG fixed-or-stored preview is stable until acknowledgement at the fixed header" {
  let image = png_stream_wb_image(width=32UL)
  let machine = PngEncodeMachine::new_with_compression_strategy(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_stream_wb_limits(),
    png_stream_wb_budget(),
    @error.Diagnostics::new(),
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

///| Phase 89: the Adam7 Indexed1/2/4/8 chunk selectors all land in the same
/// acknowledged machine and preview bytes remain stable until accepted.
test "PNG indexed Adam7 FixedOrStored chunk uses shared acknowledged machine" {
  for profile in [
    PngIndexedWireProfile::One, PngIndexedWireProfile::Two,
    PngIndexedWireProfile::Four, PngIndexedWireProfile::Eight,
  ] {
    let source = PngIndexedImage::new(
      5UL, 5UL,
      b"\x00\x01\x01\x00\x01\x01\x00\x00\x01\x00\x01\x01\x00\x01\x00\x01\x00\x01\x01\x00\x01\x00\x01\x01\x00",
      b"\x12\x34\x56\xa0\xb0\xc0", b"\x00\x80",
      png_stream_wb_budget(work=0UL),
    ).unwrap()
    let encoder = match profile {
      PngIndexedWireProfile::One => PngChunkEncoder::new_indexed_with_interlace_and_compression_strategy(
        source, PngIndexedBitDepth::One, PngInterlaceStrategy::Adam7,
        PngCompressionStrategy::FixedOrStored, png_stream_wb_limits(),
        png_stream_wb_budget(), @error.Diagnostics::new(),
      ).unwrap()
      PngIndexedWireProfile::Two => PngChunkEncoder::new_indexed_with_interlace_and_compression_strategy(
        source, PngIndexedBitDepth::Two, PngInterlaceStrategy::Adam7,
        PngCompressionStrategy::FixedOrStored, png_stream_wb_limits(),
        png_stream_wb_budget(), @error.Diagnostics::new(),
      ).unwrap()
      PngIndexedWireProfile::Four => PngChunkEncoder::new_indexed_with_interlace_and_compression_strategy(
        source, PngIndexedBitDepth::Four, PngInterlaceStrategy::Adam7,
        PngCompressionStrategy::FixedOrStored, png_stream_wb_limits(),
        png_stream_wb_budget(), @error.Diagnostics::new(),
      ).unwrap()
      PngIndexedWireProfile::Eight => PngChunkEncoder::new_indexed8_with_interlace_and_compression_strategy(
        source, PngInterlaceStrategy::Adam7, PngCompressionStrategy::FixedOrStored,
        png_stream_wb_limits(), png_stream_wb_budget(), @error.Diagnostics::new(),
      ).unwrap()
    }
    match encoder.state {
      PngChunkEncoderState::Active(machine) => {
        inspect(machine.interlace_strategy == PngInterlaceStrategy::Adam7, content="true")
        inspect(machine.indexed_source is Some(_), content="true")
        let first = machine.present().unwrap().unwrap()
        inspect(machine.present().unwrap() == Some(first), content="true")
        inspect(machine.completed() == 0UL, content="true")
        machine.acknowledge(first).unwrap()
        inspect(machine.completed() == 1UL, content="true")
      }
      _ => panic()
    }
  }
}

///|
fn png_stream_wb_fixed_or_stored_replay_image() -> @storage.OwnedImage {
  let image = png_stream_wb_image(width=5UL)
  let pixels = [
    b'\x0a', b'\x0c', b'\x0c', b'\x0a', b'\x0a', b'\x0c', b'\x0b', b'\x0c', b'\x0a',
    b'\x0c', b'\x0a', b'\x0b', b'\x0a', b'\x0c', b'\x0a',
  ]
  image
  .with_mut_view(fn(view) {
    for index = 0UL; index < 15UL; index = index + 1UL {
      view
      .set_byte(index / 3UL, 0UL, index % 3UL, pixels[index.to_int()])
      .unwrap()
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
fn png_stream_wb_same_error(
  left : @error.CoreError,
  right : @error.CoreError,
) -> Bool {
  left.category() == right.category() &&
  left.code() == right.code() &&
  left.operation() == right.operation() &&
  left.context() == right.context() &&
  left.requested() == right.requested() &&
  left.completed() == right.completed() &&
  left.limit() == right.limit()
}

///|
test "PNG fixed-or-stored white-box failed output awaits acknowledgement" {
  let image = png_stream_wb_fixed_or_stored_replay_image()
  let machine = PngEncodeMachine::new_with_compression_strategy(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_stream_wb_limits(),
    png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let mut prefix = 0UL
  while prefix < 43UL {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
    prefix = prefix + 1UL
  }
  let completed = machine.completed()
  let idat_crc = machine.idat_crc
  let fixed = machine.fixed_state.unwrap()
  let byte = machine.present().unwrap().unwrap()
  inspect((byte & b'\x07') == b'\x03', content="true")
  inspect(machine.present().unwrap() == Some(byte), content="true")
  inspect(machine.completed() == completed, content="true")
  inspect(machine.idat_crc == idat_crc, content="true")
  inspect(
    machine.fixed_state.unwrap().raw_cursor == fixed.raw_cursor,
    content="true",
  )
  inspect(
    machine.fixed_state.unwrap().matcher_work == fixed.matcher_work,
    content="true",
  )
  inspect(machine.fixed_state.unwrap().adler == fixed.adler, content="true")
  machine.acknowledge(byte).unwrap()
  inspect(machine.completed() == completed + 1UL, content="true")
  inspect(machine.fixed_state.unwrap().header_written, content="true")
  inspect(machine.idat_crc != idat_crc, content="true")
}

///|
test "PNG fixed-or-stored white-box replay mismatch is sticky" {
  let image = png_stream_wb_fixed_or_stored_replay_image()
  let facts = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_stream_wb_limits(),
    png_stream_wb_budget(),
  ).unwrap()
  match facts.plan {
    PngDeflatePlan::Fixed(plan) => {
      inspect(plan.matcher_work, content="189")
      inspect(plan.deflate_bits, content="126")
      inspect(plan.deflate_bytes, content="16")
    }
    PngDeflatePlan::Stored(_) => panic()
    PngDeflatePlan::Dynamic(_) => panic()
  }
  let machine = PngEncodeMachine::new_with_compression_strategy(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_stream_wb_limits(),
    png_stream_wb_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  image
  .with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'\x00') })
  .unwrap()
  let mut accepted = 0UL
  while accepted < 57UL {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
    accepted = accepted + 1UL
  }
  let fixed = machine.fixed_state.unwrap()
  let idat_crc = machine.idat_crc
  let first = machine.present().unwrap_err()
  inspect(first.category() == @error.ErrorCategory::State, content="true")
  inspect(first.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    first.context() == Some("png-encode-fixed-replay-work"),
    content="true",
  )
  inspect(machine.completed(), content="57")
  inspect(machine.pending == None, content="true")
  inspect(machine.pending_fixed is None, content="true")
  inspect(
    machine.fixed_state.unwrap().raw_cursor == fixed.raw_cursor,
    content="true",
  )
  inspect(
    machine.fixed_state.unwrap().matcher_work == fixed.matcher_work,
    content="true",
  )
  inspect(machine.fixed_state.unwrap().adler == fixed.adler, content="true")
  inspect(machine.idat_crc == idat_crc, content="true")
  let replay = machine.present().unwrap_err()
  inspect(png_stream_wb_same_error(first, replay), content="true")
  inspect(machine.completed(), content="57")
}

///| A compact immutable indexed source reaches the same Fixed producer through
/// the private indexed seam. The work ledger is deliberately perturbed before
/// EOB so replay fails closed and caches the typed zero-progress error.
fn png_stream_wb_indexed_source() -> PngIndexedImage {
  PngIndexedImage::new(
    256UL, 1UL, Bytes::from_array(Array::make(256, b'\x00')),
    b"\x00\x10\x20\x20\x30\x40\x40\x50\x60\x60\x70\x80",
    b"\x00\xff\xff\xff", png_stream_wb_budget(),
  ).unwrap()
}

test "PNG indexed fixed replay work fingerprint drift is sticky" {
  let machine = PngEncodeMachine::new_with_indexed_profile_and_strategy(
    png_stream_wb_indexed_source(), _png_indexed_wire_profile(PngIndexedBitDepth::Two),
    PngInterlaceStrategy::None, PngCompressionStrategy::FixedOrStored,
    png_stream_wb_limits(), png_stream_wb_budget(work=4096UL), @error.Diagnostics::new(),
  ).unwrap()
  inspect(machine.plan is PngDeflatePlan::Fixed(_), content="true")
  let target = machine.row_bytes * machine.scanlines + machine.scanlines
  match machine.fixed_state {
    None => panic()
    Some(_) => ()
  }
  let mut steps = 0UL
  let mut stop_reason = 0
  while steps < 50UL && stop_reason == 0 {
    match machine.present() {
      Err(_) => stop_reason = 1
      Ok(None) => stop_reason = 2
      Ok(Some(byte)) => {
        match machine.acknowledge(byte) {
          Err(_) => stop_reason = 3
          Ok(_) => steps = steps + 1UL
        }
      }
    }
  }
  inspect(steps, content="50")
  inspect(stop_reason, content="0")
  inspect(machine.fixed_state.unwrap().raw_cursor < target, content="true")
  let state = machine.fixed_state.unwrap()
  machine.fixed_state = Some({ ..state, matcher_work: state.matcher_work + 1UL })
  let mut first_error : @error.CoreError? = None
  let mut eob_steps = 0UL
  while first_error is None && eob_steps < 4096UL {
    match machine.present() {
      Err(error) => first_error = Some(error)
      Ok(None) => panic()
      Ok(Some(byte)) => {
        machine.acknowledge(byte).unwrap()
        eob_steps = eob_steps + 1UL
      }
    }
  }
  let first = match first_error {
    Some(error) => error
    None => panic()
  }
  let before = machine.completed()
  inspect(first.category() == @error.ErrorCategory::State, content="true")
  inspect(first.context() == Some("png-encode-fixed-replay-work"), content="true")
  inspect(machine.completed() == before, content="true")
  inspect(machine.pending == None, content="true")
  let replay = machine.present().unwrap_err()
  inspect(png_stream_wb_same_error(first, replay), content="true")
  inspect(machine.completed() == before, content="true")
}
