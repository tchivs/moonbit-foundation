///|
fn _png_stream_machine_for_test() -> PngDecodeMachine {
  PngDecodeMachine::new(
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=4096UL,
    ),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=1024UL, allocations=8UL, allocation_size=1024UL,
      width=16UL, height=16UL, pixels=256UL, depth=0UL, work=4096UL,
    )),
  )
}

///|
fn _png_machine_accept_chunk(machine : PngDecodeMachine, kind : Array[Byte], payload : Array[Byte]) -> Result[Unit, @error.CoreError] {
  let length = payload.length().to_uint64()
  for shift in [24, 16, 8, 0] { machine.accept((length >> shift).to_byte()).unwrap() }
  for byte in kind { machine.accept(byte).unwrap() }
  let mut crc = _png_crc_for_type(kind)
  for byte in payload { crc = _png_crc_step(crc, byte); machine.accept(byte).unwrap() }
  let stored = crc ^ 4294967295UL
  for shift in [24, 16, 8, 0] { machine.accept((stored >> shift).to_byte()).unwrap() }
  Ok(())
}

///|
test "PNG private machine owns accepted framing bytes across a pause" {
  let machine = _png_stream_machine_for_test()
  inspect(machine.accept(b'\x89') is Ok(_), content="true")
  inspect(machine.accepted_bytes() == 1UL, content="true")
  inspect(machine.has_result(), content="false")
}

///| The image and sink are allocated only after a CRC-authenticated IHDR and
/// the complete first IDAT header.  They remain entirely private while the
/// first IDAT CRC (and every later terminal check) is still outstanding.
test "PNG private machine preflights one private lifecycle at the first IDAT header" {
  let machine = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  _png_machine_accept_chunk(machine, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', b'\x08', b'\x02', b'\x00', b'\x00', b'\x00']).unwrap()
  inspect(machine.has_private_lifecycle(), content="false")
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'D', b'A', b'T'] { machine.accept(byte).unwrap() }
  inspect(machine.has_private_lifecycle(), content="true")
  inspect(machine.private_lifecycle_allocations() == 1UL, content="true")
  inspect(machine.has_result(), content="false")
}

///| An invalid first-IDAT preflight cannot publish a partly created output
/// lifecycle.  Indexed data without PLTE fails before image allocation.
test "PNG private machine keeps lifecycle atomic when first-IDAT preflight fails" {
  let machine = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  _png_machine_accept_chunk(machine, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', b'\x08', b'\x03', b'\x00', b'\x00', b'\x00']).unwrap()
  let mut result : Result[Unit, @error.CoreError] = Ok(())
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'D', b'A', b'T'] {
    if result is Ok(_) { result = machine.accept(byte) }
  }
  inspect(result is Err(_), content="true")
  inspect(machine.has_private_lifecycle(), content="false")
  inspect(machine.private_lifecycle_allocations() == 0UL, content="true")
  inspect(machine.has_result(), content="false")
}

///| Every retained profile fact crosses the same one-byte framing boundary.
/// The indexed lifecycle cannot exist until CRC-authenticated PLTE/tRNS and
/// the colour declaration have been committed.
test "PNG private machine retains CRC-authenticated pre-IDAT profile facts" {
  let machine = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  _png_machine_accept_chunk(machine, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', b'\x08', b'\x03', b'\x00', b'\x00', b'\x00']).unwrap()
  _png_machine_accept_chunk(machine, [b's', b'R', b'G', b'B'], [b'\x00']).unwrap()
  _png_machine_accept_chunk(machine, [b'P', b'L', b'T', b'E'], [b'\x11', b'\x22', b'\x33']).unwrap()
  _png_machine_accept_chunk(machine, [b't', b'R', b'N', b'S'], [b'\xff']).unwrap()
  inspect(machine.has_private_colour_declaration(), content="true")
  inspect(machine.has_private_palette(), content="true")
  inspect(machine.has_private_transparency(), content="true")
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'D', b'A', b'T'] { machine.accept(byte).unwrap() }
  inspect(machine.has_private_lifecycle(), content="true")
  inspect(machine.private_lifecycle_allocations() == 1UL, content="true")
  inspect(machine.has_result(), content="false")
}

///| Retained semantic bytes are provisional until the fourth CRC byte.
test "PNG private machine does not commit a split bad palette CRC" {
  let machine = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  _png_machine_accept_chunk(machine, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', b'\x08', b'\x03', b'\x00', b'\x00', b'\x00']).unwrap()
  for byte in [b'\x00', b'\x00', b'\x00', b'\x03', b'P', b'L', b'T', b'E', b'\x11', b'\x22', b'\x33'] { machine.accept(byte).unwrap() }
  let crc = _png_crc32(b"PLTE\x11\x22\x33") ^ 1UL
  for shift in [24, 16, 8] { machine.accept((crc >> shift).to_byte()).unwrap() }
  inspect(machine.has_private_palette(), content="false")
  inspect(machine.accept(crc.to_byte()).unwrap_err().context() == Some("png-crc"), content="true")
  inspect(machine.has_private_palette(), content="false")
}

///|
test "PNG private IDAT state resumes split payload and CRC" {
  let state = PngIdatState::new()
  for byte in [b'I', b'D', b'A', b'T'] { state.accept_type_byte(byte).unwrap() }
  state.accept_length_byte(b'\x00').unwrap()
  state.accept_length_byte(b'\x00').unwrap()
  state.accept_length_byte(b'\x00').unwrap()
  state.accept_length_byte(b'\x02').unwrap()
  state.accept_payload_byte(b'x').unwrap()
  inspect(state.remaining_bytes() == 1UL, content="true")
  state.accept_payload_byte(b'y').unwrap()
  inspect(state.awaiting_crc(), content="true")
  let crc = state.expected_crc()
  for shift in [24, 16, 8, 0] {
    state.accept_crc_byte((crc >> shift).to_byte()).unwrap()
  }
  inspect(state.chunk_complete(), content="true")
}

///|
test "PNG private IDAT state rejects a split CRC before another header" {
  let state = PngIdatState::new()
  for byte in [b'I', b'D', b'A', b'T'] { state.accept_type_byte(byte).unwrap() }
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00'] { state.accept_length_byte(byte).unwrap() }
  let crc = state.expected_crc() ^ 1UL
  state.accept_crc_byte((crc >> 24).to_byte()).unwrap()
  state.accept_crc_byte((crc >> 16).to_byte()).unwrap()
  state.accept_crc_byte((crc >> 8).to_byte()).unwrap()
  inspect(state.accept_crc_byte(crc.to_byte()).unwrap_err().context() == Some("png-crc"), content="true")
}

///|
test "PNG framing machine accepts a signature and IHDR at one byte boundaries" {
  let machine = _png_stream_machine_for_test()
  let ihdr = [
    b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01',
    b'\x08', b'\x02', b'\x00', b'\x00', b'\x00',
  ]
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  for byte in [b'\x00', b'\x00', b'\x00', b'\x0d', b'I', b'H', b'D', b'R'] { machine.accept(byte).unwrap() }
  for byte in ihdr { machine.accept(byte).unwrap() }
  let mut crc = _png_crc_for_type([b'I', b'H', b'D', b'R'])
  for byte in ihdr { crc = _png_crc_step(crc, byte) }
  crc = crc ^ 4294967295UL
  for shift in [24, 16, 8, 0] { machine.accept((crc >> shift).to_byte()).unwrap() }
  inspect(machine.framing_chunk_complete(), content="true")
}

///|
test "PNG framing machine rejects a split ancillary CRC and IEND length" {
  let machine = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  // An unknown ancillary payload is deliberately discarded after its CRC;
  // it remains useful for proving that split framing failures do not require
  // a retained semantic declaration.
  for byte in [b'\x00', b'\x00', b'\x00', b'\x01', b'v', b'p', b'A', b'g', b'\x00'] { machine.accept(byte).unwrap() }
  let crc = _png_crc32(b"vpAg\x00") ^ 1UL
  for shift in [24, 16, 8] { machine.accept((crc >> shift).to_byte()).unwrap() }
  inspect(machine.accept(crc.to_byte()).unwrap_err().context() == Some("png-crc"), content="true")
  let iend = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n', b'\x00', b'\x00', b'\x00', b'\x01', b'I', b'E', b'N'] { iend.accept(byte).unwrap() }
  inspect(iend.accept(b'D').unwrap_err().context() == Some("png-iend-length"), content="true")
}

///|
test "PNG eager reader adapter observes one-byte signature header and CRC reads once" {
  let source_bytes = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x00IEND\xaeB`\x82",
    _png_private_budget(20UL),
  ).unwrap()
  let reader = @io.MemoryReader::new(source_bytes.view())
  let machine = _png_stream_machine_for_test()
  let observed = PngMachineReader::{ reader: reader as &@io.Reader, machine }
  let scratch = @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)).unwrap()
  let mut consumed = 0UL
  for index = 0; index < 20; index = index + 1 {
    let (_, next) = _png_read_one(observed as &@io.Reader, scratch, consumed, machine.limits)
      .unwrap()
    consumed = next
  }
  inspect(consumed == 20UL, content="true")
  inspect(machine.accepted_bytes() == 20UL, content="true")
  inspect(machine.framing_chunk_complete(), content="true")
}

///|
struct PngReaderFailureAfterByte {}

///|
impl @io.Reader for PngReaderFailureAfterByte with fn read(_self, destination) {
  ignore(destination.set(0UL, b'\x89'))
  @io.ReadOutcome::Failed(
    @error.CoreError::new(
      @error.ErrorCategory::Host,
      @error.ErrorCode::HostOperationFailed,
      operation="png-reader-failure-after-byte",
    ),
    1UL,
  )
}

///|
test "PNG eager reader adapter observes a completed failing prefix once" {
  let source = PngReaderFailureAfterByte::{}
  let machine = _png_stream_machine_for_test()
  let observed = PngMachineReader::{ reader: source as &@io.Reader, machine }
  let scratch = @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)).unwrap()
  let result = _png_read_one(observed as &@io.Reader, scratch, 0UL, machine.limits)
  inspect(result is Err(_), content="true")
  inspect(machine.accepted_bytes() == 1UL, content="true")
}

///|
test "PNG private inflater retains a stored block across every compressed byte pause" {
  // zlib(0x78, 0x01) + a final stored block containing `A` + Adler-32.
  // Each call is one accepted IDAT payload byte, so this crosses the zlib,
  // block header, stored length, stored body, and trailer continuations.
  let inflate = PngInflateState::new(1UL)
  for byte in [
    b'\x78', b'\x01', b'\x01', b'\x01', b'\x00', b'\xfe', b'\xff',
    b'A', b'\x00', b'\x42', b'\x00', b'\x42',
  ] {
    inflate.accept(byte).unwrap()
  }
  inspect(inflate.emitted_bytes() == 1UL, content="true")
  inspect(inflate.complete(), content="true")
}

///| A byte-fed inflater must hand decoded samples straight to the owned raster
/// sink.  This is deliberately a stored block so the test isolates the
/// zlib/DEFLATE-to-raster seam from Huffman token selection.
test "PNG private inflater delivers stored bytes directly to the raster sink" {
  let transport = PngTransport::{ width: 1UL, height: 1UL, bit_depth: 8, source_channels: 3UL, source_bytes_per_pixel: 3UL, channels: 3UL, indexed: false, palette: b"", palette_entries: 0UL, transparency: PngTransparency::Opaque, idat: b"", consumed: 0UL }
  let image = @storage.OwnedImage::new_operation(
    _png_descriptor(transport).unwrap(),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=16UL, allocations=1UL, allocation_size=16UL, width=2UL, height=2UL, pixels=4UL, depth=0UL, work=16UL)),
    PngBuiltinAllocator::{} as &@bytes.Allocator,
    16UL,
  ).unwrap()
  let sink = PngRasterSink::new(image, transport, false, @budget.Budget::new(@budget.ResourceLimits::new(bytes=0UL, allocations=0UL, allocation_size=0UL, width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL))).unwrap()
  let inflate = PngInflateState::new(4UL)
  for byte in [b'\x78', b'\x01', b'\x01', b'\x04', b'\x00', b'\xfb', b'\xff', b'\x00', b'\x11', b'\x22', b'\x33', b'\x00', b'\xae', b'\x00', b'\x67'] {
    inflate.accept_to(byte, sink).unwrap()
  }
  inspect(inflate.complete(), content="true")
  sink.finish().unwrap()
  let view = sink.image_view()
  inspect(view.get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x11'")
  inspect(view.get_byte(0UL, 0UL, 2UL).unwrap(), content="b'\\x33'")
}

///| This is the fixed-Huffman payload from the hostile one-IDAT-byte schedule,
/// without any PNG framing.  It pins output order across a literal/match
/// continuation: the five filter tags must remain 0, 1, 2, 3, and 4.
test "PNG private inflater preserves fixed-Huffman filter byte order" {
  let transport = PngTransport::{ width: 2UL, height: 5UL, bit_depth: 8, source_channels: 3UL, source_bytes_per_pixel: 3UL, channels: 3UL, indexed: false, palette: b"", palette_entries: 0UL, transparency: PngTransparency::Opaque, idat: b"", consumed: 0UL }
  let image = @storage.OwnedImage::new_operation(
    _png_descriptor(transport).unwrap(),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=128UL, allocations=1UL, allocation_size=128UL, width=8UL, height=8UL, pixels=64UL, depth=0UL, work=128UL)),
    PngBuiltinAllocator::{} as &@bytes.Allocator,
    128UL,
  ).unwrap()
  let sink = PngRasterSink::new(image, transport, false, @budget.Budget::new(@budget.ResourceLimits::new(bytes=0UL, allocations=0UL, allocation_size=0UL, width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL))).unwrap()
  let inflate = PngInflateState::new(64UL)
  for byte in b"\x78\x01\x63\x10\x94\xd3\xb6\x70\x0d\x62\x8c\xcf\xa9\x54\x57\x57\x67\xf2\x03\x03\xe6\x55\x1b\xb6\xef\xdd\xbb\x97\x05\xc8\x04\x0a\x02\x00\xa1\xd0\x0a\x68" {
    inflate.accept_to(byte, sink).unwrap()
  }
  inspect(inflate.emitted_bytes() == 35UL, content="true")
  inspect(inflate.complete(), content="true")
  sink.finish().unwrap()
  let view = sink.image_view()
  inspect(view.get_byte(1UL, 4UL, 2UL).unwrap(), content="b'\\x8F'")
}

///|
test "PNG private inflater retains every dynamic header tree and token byte boundary" {
  // The stream uses a dynamic tree, code-length repeats, and back-references.
  // Supplying each byte separately proves partial dynamic headers, trees, and
  // token/match state never restart at a source pause.
  let inflate = PngInflateState::new(128UL)
  for byte in b"\x78\x9c\x15\x8c\x09\x0e\x00\x00\x04\xc3\xd6\xed\xff\x7f\x56\x22\xec\x82\xa6\x83\x14\x9a\x64\xf6\xba\xb6\x4a\x0e\xb1\x04\xa7\xfc\x3d\xb6\xa0\x6e\x5a\x3f\xe4\x4f\x23\x7e\xd9\xd8\x7f\x7b\xe5\xd7\x2c\xb3\x1c\x1e\x80\x00\x9c" {
    inflate.accept(byte).unwrap()
  }
  inspect(inflate.emitted_bytes() == 100UL, content="true")
  inspect(inflate.complete(), content="true")
}

///|
test "PNG private inflater preserves dynamic malformed-tree failures across pauses" {
  // zlib + a final dynamic block whose literal tree is incomplete.  Its bytes
  // are supplied separately, so the tree builder must report the established
  // error rather than a continuation-specific failure.
  let inflate = PngInflateState::new(1024UL)
  let mut result : Result[Unit, @error.CoreError] = Ok(())
  for byte in [b'\x78', b'\x01', b'\x05', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'] {
    if result is Ok(_) { result = inflate.accept(byte) }
  }
  inspect(result.unwrap_err().context() == Some("deflate-incomplete-tree"), content="true")
}

///|
test "PNG private inflater preserves dynamic oversubscribed-tree failures across pauses" {
  // Dynamic HLIT/HDIST/HCLEN followed by three one-bit code-length entries.
  // That alphabet is oversubscribed before any literal token is decoded.
  let inflate = PngInflateState::new(1024UL)
  let mut result : Result[Unit, @error.CoreError] = Ok(())
  for byte in [b'\x78', b'\x01', b'\x05', b'\x00', b'\x92', b'\x00'] {
    if result is Ok(_) { result = inflate.accept(byte) }
  }
  inspect(result.unwrap_err().context() == Some("deflate-oversubscribed-tree"), content="true")
}
