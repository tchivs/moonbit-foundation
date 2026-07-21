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
