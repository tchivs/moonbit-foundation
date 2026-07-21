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
test "PNG private machine owns accepted framing bytes across a pause" {
  let machine = _png_stream_machine_for_test()
  inspect(machine.accept(b'\x89') is Ok(_), content="true")
  inspect(machine.accepted_bytes() == 1UL, content="true")
  inspect(machine.has_result(), content="false")
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
  for byte in [b'\x00', b'\x00', b'\x00', b'\x01', b'g', b'A', b'M', b'A', b'\x00'] { machine.accept(byte).unwrap() }
  let crc = _png_crc32(b"gAMA\x00") ^ 1UL
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
