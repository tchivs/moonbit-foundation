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
