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

///| The explicit preservation route is deliberately a private machine profile;
/// white-box fixtures verify its first-IDAT admission boundary directly.
fn _png_graya16_machine_for_test() -> PngDecodeMachine {
  PngDecodeMachine::new_with_profile(
    PngDecodeProfile::GrayAlpha16,
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
fn _png_graya16_accept_signature_and_ihdr(
  machine : PngDecodeMachine,
  bit_depth : Byte,
  colour_type : Byte,
  interlace : Byte,
) -> Unit {
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] {
    machine.accept(byte).unwrap()
  }
  _png_machine_accept_chunk(
    machine, [b'I', b'H', b'D', b'R'],
    [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', bit_depth, colour_type, b'\x00', b'\x00', interlace],
  ).unwrap()
}

///| Admit just a complete first-IDAT header: profile errors must precede
/// child budgets, image allocation, sink construction, and any outcome.
fn _png_graya16_first_idat_error(machine : PngDecodeMachine) -> @error.CoreError {
  let mut result : Result[Unit, @error.CoreError] = Ok(())
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'D', b'A', b'T'] {
    if result is Ok(_) { result = machine.accept(byte) }
  }
  result.unwrap_err()
}

///|
fn _png_assert_graya16_profile_error(
  machine : PngDecodeMachine,
) -> Unit raise {
  let before = machine.budget.remaining()
  let error = _png_graya16_first_idat_error(machine)
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
  inspect(error.operation() == Some("png-decode"), content="true")
  inspect(error.context() == Some("graya16-profile"), content="true")
  inspect(machine.has_private_lifecycle(), content="false")
  inspect(machine.private_lifecycle_allocations() == 0UL, content="true")
  inspect(machine.has_private_outcome(), content="false")
  inspect(machine.budget.remaining().bytes() == before.bytes(), content="true")
}

///| A valid decompressed grayscale ICC profile is injected as the already
/// authenticated fact to isolate first-IDAT profile admission from iCCP's
/// separate bounded DEFLATE reader.
fn _png_graya16_set_authenticated_iccp(machine : PngDecodeMachine) -> Unit {
  let profile : Array[Byte] = []
  for index = 0; index < 128; index = index + 1 {
    profile.push(
      if index == 3 { b'\x80' }
      else if index == 16 { b'G' }
      else if index == 17 { b'R' }
      else if index == 18 { b'A' }
      else if index == 19 { b'Y' }
      else if index == 36 { b'a' }
      else if index == 37 { b'c' }
      else if index == 38 { b's' }
      else if index == 39 { b'p' }
      else { b'\x00' },
    )
  }
  machine.facts.colour_facts = {
    saw_srgb: false, srgb_intent: None, saw_gamma: false, gamma_is_srgb: false,
    gamma: None, saw_chrm: false, chrm_is_srgb: false, chrm: None,
    saw_iccp: true, iccp_name: Some(b"gray"), iccp_profile: Some(Bytes::from_array(profile)),
  }
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
/// A minimal complete RGB8 PNG prefix used by the byte-fed machine tests.
/// The matching IDAT payload below is a zlib stored block for filter byte 0
/// and one RGB pixel (0x11, 0x22, 0x33).
fn _png_machine_accept_rgb8_header(machine : PngDecodeMachine) -> Unit {
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] {
    machine.accept(byte).unwrap()
  }
  _png_machine_accept_chunk(
    machine,
    [b'I', b'H', b'D', b'R'],
    [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', b'\x08', b'\x02', b'\x00', b'\x00', b'\x00'],
  ).unwrap()
}

///|
/// Feed an IDAT through separate header, compressed-payload, and CRC pauses.
/// The private machine must retain only its state, never a source view or a
/// complete IDAT payload.
fn _png_machine_accept_idat_payload(machine : PngDecodeMachine, payload : Array[Byte]) -> Unit {
  let length = payload.length().to_uint64()
  for shift in [24, 16, 8, 0] { machine.accept((length >> shift).to_byte()).unwrap() }
  for byte in [b'I', b'D', b'A', b'T'] { machine.accept(byte).unwrap() }
  for byte in payload { machine.accept(byte).unwrap() }
  let mut crc = _png_crc_for_type([b'I', b'D', b'A', b'T'])
  for byte in payload { crc = _png_crc_step(crc, byte) }
  let stored = crc ^ 4294967295UL
  for shift in [24, 16, 8, 0] { machine.accept((stored >> shift).to_byte()).unwrap() }
}

///|
fn _png_machine_accept_stored_rgb_idat(machine : PngDecodeMachine) -> Unit {
  _png_machine_accept_idat_payload(machine, [b'\x78', b'\x01', b'\x01', b'\x04', b'\x00', b'\xfb', b'\xff', b'\x00', b'\x11', b'\x22', b'\x33', b'\x00', b'\xae', b'\x00', b'\x67'])
}

///|
test "PNG private machine owns accepted framing bytes across a pause" {
  let machine = _png_stream_machine_for_test()
  inspect(machine.accept(b'\x89') is Ok(_), content="true")
  inspect(machine.accepted_bytes() == 1UL, content="true")
  inspect(machine.has_result(), content="false")
}

///|
/// The full internal path is one-byte resumable: framing enters IDAT state,
/// then the zlib continuation, then the private raster sink.  Nothing is
/// published until IEND has passed and the caller explicitly declares EOF.
test "PNG private machine resumes split IDAT zlib CRC IEND and EOF without a result" {
  let machine = _png_stream_machine_for_test()
  _png_machine_accept_rgb8_header(machine)
  _png_machine_accept_stored_rgb_idat(machine)
  inspect(machine.has_private_lifecycle(), content="true")
  inspect(machine.has_result(), content="false")
  _png_machine_accept_chunk(machine, [b'I', b'E', b'N', b'D'], []).unwrap()
  inspect(machine.has_result(), content="false")
  machine.finish().unwrap()
  inspect(machine.has_result(), content="false")
}

///|
/// DEFLATE need not end at an IDAT boundary.  Each chunk receives its own
/// CRC-authenticated continuation while one retained inflater carries the
/// zlib header, stored-block body, and Adler trailer across the split.
test "PNG private machine resumes one zlib stream across split IDAT chunks" {
  let machine = _png_stream_machine_for_test()
  _png_machine_accept_rgb8_header(machine)
  _png_machine_accept_idat_payload(machine, [b'\x78', b'\x01', b'\x01', b'\x04', b'\x00', b'\xfb', b'\xff'])
  inspect(machine.has_result(), content="false")
  _png_machine_accept_idat_payload(machine, [b'\x00', b'\x11', b'\x22', b'\x33', b'\x00', b'\xae', b'\x00', b'\x67'])
  _png_machine_accept_chunk(machine, [b'I', b'E', b'N', b'D'], []).unwrap()
  machine.finish().unwrap()
  inspect(machine.has_result(), content="false")
}

///|
/// A CRC-authenticated first IDAT still cannot produce any result if its zlib
/// stream, IEND, or the explicit EOF transition is incomplete.
test "PNG private machine keeps result private before terminal checks" {
  let machine = _png_stream_machine_for_test()
  _png_machine_accept_rgb8_header(machine)
  _png_machine_accept_stored_rgb_idat(machine)
  inspect(machine.finish().unwrap_err().context() == Some("png-finished"), content="true")
  inspect(machine.has_result(), content="false")
}

///| A terminal-looking stream with a bad IEND CRC must not turn the retained
/// image into even the private result-equivalent.  This is the final framing
/// gate after raster and zlib completion, before the explicit EOF transition.
test "PNG private machine withholds its outcome after a late IEND CRC failure" {
  let machine = _png_stream_machine_for_test()
  _png_machine_accept_rgb8_header(machine)
  _png_machine_accept_stored_rgb_idat(machine)
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'E', b'N', b'D', b'\xae', b'\x42', b'\x60'] {
    machine.accept(byte).unwrap()
  }
  inspect(machine.accept(b'\x83').unwrap_err().context() == Some("png-crc"), content="true")
  inspect(machine.has_private_outcome(), content="false")
  inspect(machine.has_result(), content="false")
}

///| Colour declarations and tRNS influence the descriptor before raster
/// allocation, but the owned result-equivalent is still withheld until IEND
/// and EOF.  This exercises the indexed RGBA branch and the sRGB metadata
/// selection from the same CRC-authenticated pre-IDAT facts.
test "PNG private outcome retains sRGB metadata and indexed tRNS channels" {
  let machine = _png_stream_machine_for_test()
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { machine.accept(byte).unwrap() }
  _png_machine_accept_chunk(machine, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01', b'\x08', b'\x03', b'\x00', b'\x00', b'\x00']).unwrap()
  _png_machine_accept_chunk(machine, [b's', b'R', b'G', b'B'], [b'\x03']).unwrap()
  _png_machine_accept_chunk(machine, [b'P', b'L', b'T', b'E'], [b'\x11', b'\x22', b'\x33']).unwrap()
  _png_machine_accept_chunk(machine, [b't', b'R', b'N', b'S'], [b'\x80']).unwrap()
  _png_machine_accept_idat_payload(machine, [b'\x78', b'\x01', b'\x01', b'\x02', b'\x00', b'\xfd', b'\xff', b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x01'])
  _png_machine_accept_chunk(machine, [b'I', b'E', b'N', b'D'], []).unwrap()
  inspect(machine.has_private_outcome(), content="false")
  machine.finish().unwrap()
  inspect(machine.has_private_outcome(), content="true")
  let descriptor = machine.private_outcome_descriptor().unwrap()
  inspect(descriptor.format().channel_count() == 4UL, content="true")
  let retained = descriptor.metadata().opaque_metadata()
  inspect(retained.length() == 1, content="true")
  inspect(retained.entry(0).unwrap().canonical_key() == "png:srgb:intent", content="true")
  inspect(retained.entry(0).unwrap().value().get(0UL).unwrap() == b'\x03', content="true")
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

///| Every explicit-profile mismatch shares one typed, pre-allocation boundary.
test "PNG graya16 profile rejects incompatible first-IDAT facts atomically" {
  let wrong_depth = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(wrong_depth, b'\x08', b'\x04', b'\x00')
  _png_assert_graya16_profile_error(wrong_depth)

  let wrong_colour = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(wrong_colour, b'\x10', b'\x00', b'\x00')
  _png_assert_graya16_profile_error(wrong_colour)

  let interlaced = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(interlaced, b'\x10', b'\x04', b'\x01')
  _png_assert_graya16_profile_error(interlaced)

  let legacy = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(legacy, b'\x10', b'\x04', b'\x00')
  _png_machine_accept_chunk(legacy, [b'g', b'A', b'M', b'A'], [b'\x00', b'\x01', b'\x86', b'\xa0']).unwrap()
  _png_assert_graya16_profile_error(legacy)

  let iccp = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(iccp, b'\x10', b'\x04', b'\x00')
  _png_graya16_set_authenticated_iccp(iccp)
  _png_assert_graya16_profile_error(iccp)
}

///| Default and CRC-authenticated sRGB facts are the only accepted colour
/// declarations for the explicit profile, and both allocate exactly once at
/// first-IDAT just like the existing generic machine.
test "PNG graya16 profile admits default and sRGB Type-4/16 before raster bytes" {
  let default_profile = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(default_profile, b'\x10', b'\x04', b'\x00')
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'D', b'A', b'T'] {
    default_profile.accept(byte).unwrap()
  }
  inspect(default_profile.has_private_lifecycle(), content="true")
  inspect(default_profile.private_lifecycle_allocations() == 1UL, content="true")

  let srgb_profile = _png_graya16_machine_for_test()
  _png_graya16_accept_signature_and_ihdr(srgb_profile, b'\x10', b'\x04', b'\x00')
  _png_machine_accept_chunk(srgb_profile, [b's', b'R', b'G', b'B'], [b'\x00']).unwrap()
  for byte in [b'\x00', b'\x00', b'\x00', b'\x00', b'I', b'D', b'A', b'T'] {
    srgb_profile.accept(byte).unwrap()
  }
  inspect(srgb_profile.has_private_lifecycle(), content="true")
  inspect(srgb_profile.private_lifecycle_allocations() == 1UL, content="true")
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
struct PngReaderOverreportsProgress {}

///|
impl @io.Reader for PngReaderOverreportsProgress with fn read(_self, destination) {
  ignore(destination.set(0UL, b'\x89'))
  @io.ReadOutcome::Progress(destination.length() + 1UL)
}

///| A Reader must never be allowed to claim bytes beyond the window handed to
/// it.  The eager observer rejects the malformed report before touching an
/// out-of-range byte, so it cannot corrupt its private framing accounting.
test "PNG eager reader adapter rejects overreported progress before observation" {
  let source = PngReaderOverreportsProgress::{}
  let machine = _png_stream_machine_for_test()
  let observed = PngMachineReader::{ reader: source as &@io.Reader, machine }
  let scratch = @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)).unwrap()
  let result = _png_read_one(observed as &@io.Reader, scratch, 0UL, machine.limits)
  inspect(result is Err(_), content="true")
  inspect(machine.accepted_bytes() == 0UL, content="true")
}

///|
struct PngReaderOverreportsFailurePrefix {}

///|
impl @io.Reader for PngReaderOverreportsFailurePrefix with fn read(_self, destination) {
  ignore(destination.set(0UL, b'\x89'))
  @io.ReadOutcome::Failed(
    @error.CoreError::new(
      @error.ErrorCategory::Host,
      @error.ErrorCode::HostOperationFailed,
      operation="png-reader-overreported-failure-prefix",
    ),
    destination.length() + 1UL,
  )
}

///| A malformed failure prefix keeps its source error but contributes no
/// private framing byte from outside the provided destination window.
test "PNG eager reader adapter suppresses overreported failure prefix" {
  let source = PngReaderOverreportsFailurePrefix::{}
  let machine = _png_stream_machine_for_test()
  let observed = PngMachineReader::{ reader: source as &@io.Reader, machine }
  let scratch = @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)).unwrap()
  let result = _png_read_one(observed as &@io.Reader, scratch, 0UL, machine.limits)
  inspect(result is Err(_), content="true")
  inspect(machine.accepted_bytes() == 0UL, content="true")
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

///| A complete one-pixel stored PNG used to freeze the public EOF classifier.
fn png_wb_complete_chunk_png() -> Bytes {
  b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
}

///|
fn png_wb_prefix(source : Bytes, length : Int) -> Bytes {
  let result : Array[Byte] = []
  for index = 0; index < length; index = index + 1 { result.push(source[index]) }
  Bytes::from_array(result)
}

///|
fn png_wb_source(source : Bytes) -> @bytes.OwnedBytes {
  let length = source.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=length, allocations=1UL, allocation_size=length, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
}

///|
fn png_wb_chunk_decoder() -> PngChunkDecoder {
  PngChunkDecoder::new(
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=4096UL,
    ),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=1024UL, allocations=8UL, allocation_size=1024UL,
      width=16UL, height=16UL, pixels=256UL, depth=0UL, work=4096UL,
    )),
    @error.Diagnostics::new(),
  )
}

///| Verify the private classifier and its exact public `finish` route agree.
/// The public decoder must then retain that same first error with zero later
/// source consumption.
fn png_wb_error_matches(left : @error.CoreError, right : @error.CoreError) -> Bool {
  left.category() == right.category() &&
  left.code() == right.code() &&
  left.operation() == right.operation() &&
  left.context() == right.context() &&
  left.requested() == right.requested() &&
  left.completed() == right.completed() &&
  left.limit() == right.limit()
}

///|
fn png_wb_assert_incomplete(source : Bytes, context : String) -> Unit raise {
  let machine = _png_stream_machine_for_test()
  for index = 0; index < source.length(); index = index + 1 {
    match machine.accept(source[index]) {
      Ok(_) => ()
      Err(error) => fail("incomplete vector rejected before strict EOF: " + error.context().unwrap())
    }
  }
  let private_error = machine.chunk_incomplete_error(machine.accepted_bytes())
  inspect(private_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(private_error.code() == @error.ErrorCode::UnexpectedEndOfStream, content="true")
  inspect(private_error.context() == Some(context), content="true")
  inspect(private_error.completed() == Some(source.length().to_uint64()), content="true")

  let decoder = png_wb_chunk_decoder()
  let owner = png_wb_source(source)
  let pushed = decoder.push(owner.view())
  inspect(pushed.consumed() == source.length().to_uint64(), content="true")
  inspect(pushed.outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let public_error = decoder.finish().unwrap_err()
  inspect(png_wb_error_matches(public_error, private_error), content="true")
  let later = png_wb_source(b"X")
  let replay = decoder.push(later.view())
  inspect(replay.consumed() == 0UL, content="true")
  match replay.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(png_wb_error_matches(error, public_error), content="true")
    _ => fail("incomplete chunk finish must be sticky")
  }
  inspect(png_wb_error_matches(decoder.finish().unwrap_err(), public_error), content="true")
}

///| A complete IEND is no longer an EOF classification case. Keep the eager
/// invalid-encoding shape intact while proving the public wrapper replays it
/// unchanged after the one terminal finish attempt.
fn png_wb_assert_terminal_raster_error(source : Bytes) -> Unit raise {
  let machine = _png_stream_machine_for_test()
  for index = 0; index < source.length(); index = index + 1 {
    machine.accept(source[index]).unwrap()
  }
  let eager_error = machine.finish().unwrap_err()
  inspect(eager_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(eager_error.context() == Some("png-filtered-size"), content="true")
  inspect(eager_error.completed() is None, content="true")

  let decoder = png_wb_chunk_decoder()
  let owner = png_wb_source(source)
  inspect(decoder.push(owner.view()).outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let public_error = decoder.finish().unwrap_err()
  inspect(png_wb_error_matches(public_error, eager_error), content="true")
  let later = png_wb_source(b"X")
  let replay = decoder.push(later.view())
  inspect(replay.consumed() == 0UL, content="true")
  match replay.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(png_wb_error_matches(error, eager_error), content="true")
    _ => fail("terminal raster error must remain sticky")
  }
}

///| Assemble a valid signature/IHDR and a still-open IDAT payload prefix. The
/// payload has no CRC because zlib incompleteness must win over framing.
fn png_wb_open_idat(payload : Bytes) -> Bytes {
  let base = png_wb_complete_chunk_png()
  let result : Array[Byte] = []
  for index = 0; index < 33; index = index + 1 { result.push(base[index]) }
  let length = payload.length().to_uint64()
  for shift in [24, 16, 8, 0] { result.push((length >> shift).to_byte()) }
  for byte in [b'I', b'D', b'A', b'T'] { result.push(byte) }
  for index = 0; index < payload.length(); index = index + 1 { result.push(payload[index]) }
  Bytes::from_array(result)
}

///| Assemble an IHDR whose private raster can absorb the inspected inflater
/// prefix without changing the fact that the IDAT CRC and IEND are absent.
fn png_wb_open_idat_sized(payload : Bytes, width : Byte, height : Byte) -> Bytes {
  let result : Array[Byte] = []
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { result.push(byte) }
  png_wb_append_chunk(result, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', width, b'\x00', b'\x00', b'\x00', height, b'\x08', b'\x02', b'\x00', b'\x00', b'\x00'])
  let length = payload.length().to_uint64()
  for shift in [24, 16, 8, 0] { result.push((length >> shift).to_byte()) }
  for byte in [b'I', b'D', b'A', b'T'] { result.push(byte) }
  for index = 0; index < payload.length(); index = index + 1 { result.push(payload[index]) }
  Bytes::from_array(result)
}

///|
fn png_wb_append(source : Bytes, suffix : Bytes) -> Bytes {
  let result : Array[Byte] = []
  for byte in source { result.push(byte) }
  for byte in suffix { result.push(byte) }
  Bytes::from_array(result)
}

///| The first three fixed-Huffman bytes leave a nonempty literal cursor in
/// `Symbols`; this is not a stored-block substitute.
fn png_wb_fixed_token_pause() -> Bytes raise {
  let payload = b"\x78\x01\x63\x10\x94\xd3\xb6\x70\x0d\x62\x8c\xcf\xa9\x54\x57\x57\x67\xf2\x03\x03\xe6\x55\x1b\xb6\xef\xdd\xbb\x97\x05\xc8\x04\x0a\x02\x00\xa1\xd0\x0a\x68"
  let prefix = png_wb_prefix(payload, 3)
  let inflate = PngInflateState::new(64UL)
  for byte in prefix { inflate.accept(byte).unwrap() }
  match inflate.phase {
    PngInflatePhase::Symbols(_, _, _) => ()
    _ => fail("fixed vector must pause in Symbols")
  }
  inspect(inflate.cursor.length > 0, content="true")
  png_wb_open_idat_sized(prefix, b'\x02', b'\x05')
}

///| The first five dynamic-Huffman bytes have finished the dynamic header but
/// retain the code-length tree construction cursor.
fn png_wb_dynamic_tree_pause() -> Bytes raise {
  let payload = b"\x78\x9c\x15\x8c\x09\x0e\x00\x00\x04\xc3\xd6\xed\xff\x7f\x56\x22\xec\x82\xa6\x83\x14\x9a\x64\xf6\xba\xb6\x4a\x0e\xb1\x04\xa7\xfc\x3d\xb6\xa0\x6e\x5a\x3f\xe4\x4f\x23\x7e\xd9\xd8\x7f\x7b\xe5\xd7\x2c\xb3\x1c\x1e\x80\x00\x9c"
  let prefix = png_wb_prefix(payload, 5)
  let inflate = PngInflateState::new(128UL)
  for byte in prefix { inflate.accept(byte).unwrap() }
  match inflate.phase {
    PngInflatePhase::DynamicCodeLengths(_, _, _, hclen, _, cursor) => inspect(cursor < hclen, content="true")
    _ => fail("dynamic tree vector must pause in DynamicCodeLengths")
  }
  png_wb_open_idat_sized(prefix, b'\x10', b'\x10')
}

///| This exact prefix comes from the hostile dynamic stream after it has
/// emitted data and entered a retained length/distance transition.
fn png_wb_dynamic_match_payload_prefix() -> Bytes {
  let payload = b"\x78\x9c\x95\xc2\xbd\x0a\x40\x50\x00\x86\xe1\xcf\xbf\xc3\xe1\x94\x52\x8a\x94\x28\xa5\x0c\x36\x9b\xcd\x66\xb3\xd9\x6c\xee\xff\x06\x5c\xc3\xfb\xf4\x48\x94\x17\x24\xa8\xfc\xb8\x44\x15\x98\x1a\x55\x68\x3b\x54\x91\x1b\x51\xc5\xd5\x82\x2a\xa9\x37\x54\x69\xb3\xa3\x32\xed\x81\x2a\xeb\x4f\x54\xf9\x70\xa1\xb2\xd3\x8d\xaa\x98\x1f\x54\xe5\xf2\xa2\x72\xeb\x87\xfe\x71\x0f\x52\x81"
  png_wb_prefix(payload, 44)
}

///|
fn png_wb_dynamic_match_pause() -> Bytes raise {
  let prefix = png_wb_dynamic_match_payload_prefix()
  let inflate = PngInflateState::new(1024UL)
  for byte in prefix { inflate.accept(byte).unwrap() }
  inspect(inflate.emitted_bytes() > 0UL, content="true")
  match inflate.phase {
    PngInflatePhase::LengthExtra(_, _, _, _, _) |
    PngInflatePhase::DistanceSymbol(_, _, _, _) |
    PngInflatePhase::DistanceExtra(_, _, _, _, _, _) |
    PngInflatePhase::Copy(_, _, _, _, _) => ()
    _ => fail("dynamic vector must pause in a match transition")
  }
  png_wb_open_idat_sized(prefix, b'\x10', b'\x10')
}

///| The dynamic caller prefix is also sent through `accept_to` and the real
/// 16x16 RGB raster sink, exercising the continuation ownership seam rather
/// than only the inflater's no-sink test path.
test "PNG private inflater streams dynamic match pauses to the raster sink" {
  let transport = PngTransport::{ width: 16UL, height: 16UL, bit_depth: 8, source_channels: 3UL, source_bytes_per_pixel: 3UL, channels: 3UL, indexed: false, palette: b"", palette_entries: 0UL, transparency: PngTransparency::Opaque, idat: b"", consumed: 0UL }
  let image = @storage.OwnedImage::new_operation(
    _png_descriptor(transport).unwrap(),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=1024UL, allocations=1UL, allocation_size=1024UL, width=16UL, height=16UL, pixels=256UL, depth=0UL, work=1024UL)),
    PngBuiltinAllocator::{} as &@bytes.Allocator,
    1024UL,
  ).unwrap()
  let sink = PngRasterSink::new(image, transport, false, @budget.Budget::new(@budget.ResourceLimits::new(bytes=0UL, allocations=0UL, allocation_size=0UL, width=0UL, height=0UL, pixels=0UL, depth=0UL, work=0UL))).unwrap()
  let inflate = PngInflateState::new(1024UL)
  for byte in png_wb_dynamic_match_payload_prefix() { inflate.accept_to(byte, sink).unwrap() }
  inspect(inflate.emitted_bytes() > 0UL, content="true")
  match inflate.phase {
    PngInflatePhase::LengthExtra(_, _, _, _, _) |
    PngInflatePhase::DistanceSymbol(_, _, _, _) |
    PngInflatePhase::DistanceExtra(_, _, _, _, _, _) |
    PngInflatePhase::Copy(_, _, _, _, _) => ()
    _ => fail("dynamic raster vector must retain a match transition")
  }
}

///|
fn png_wb_assert_pending_iend_type(source : Bytes) -> Unit raise {
  let machine = _png_stream_machine_for_test()
  for byte in source { machine.accept(byte).unwrap() }
  match machine.state {
    PngDecodeMachineState::PendingIendType => ()
    _ => fail("zero-length terminal type must remain pending")
  }
  inspect(machine.accept(b'X').unwrap_err().context() == Some("png-iend-type"), content="true")
}

///| Every framing suffix has a stable, typed strict-EOF context.  Signature,
/// generic chunk length/payload/CRC, and partial IDAT CRC all run through the
/// same public `finish` transition as the private classifier.
test "PNG chunk EOF classifier freezes signature generic framing and IDAT CRC rows" {
  let complete = png_wb_complete_chunk_png()
  for length = 0; length < 8; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-signature")
  }
  for length = 8; length < 12; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-chunk-length")
  }
  for length = 16; length < 29; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-chunk-payload")
  }
  for length = 29; length < 33; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-chunk-crc")
  }
  for length = 56; length < 60; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-idat-crc")
  }
}

///| A completed raster has IEND-specific EOF diagnoses.  This covers no IEND
/// bytes, each partial length/type/CRC suffix, and confirms IEND remains only
/// a pending terminal until `finish` is called.
test "PNG chunk EOF classifier freezes IEND length type and CRC rows" {
  let complete = png_wb_complete_chunk_png()
  png_wb_assert_incomplete(png_wb_prefix(complete, 60), "png-iend")
  for length = 61; length < 64; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-iend-length")
  }
  for length = 64; length < 68; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-iend-type")
  }
  for length = 68; length < 72; length = length + 1 {
    png_wb_assert_incomplete(png_wb_prefix(complete, length), "png-iend-crc")
  }
}

///| Incomplete zlib always wins over the surrounding open IDAT or missing
/// IEND.  The prefixes touch header, stored block, fixed token, dynamic tree,
/// dynamic match, and Adler continuations without exposing a second parser.
test "PNG chunk EOF classifier gives zlib precedence across inflater pauses" {
  for payload in [
    b"\x78",
    b"\x78\x01\x01\x01",
    b"\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00",
  ] {
    png_wb_assert_incomplete(png_wb_open_idat(payload), "zlib-truncated")
  }
}

///| The omitted frozen rows must be reached by literal caller prefixes: a
/// partial fixed token, dynamic tree construction, dynamic match transition,
/// then zero-length wrong/non-IEND terminal types after a finished raster.
test "PNG chunk EOF classifier freezes real inflater and zero-length type rows" {
  png_wb_assert_incomplete(png_wb_fixed_token_pause(), "zlib-truncated")
  png_wb_assert_incomplete(png_wb_dynamic_tree_pause(), "zlib-truncated")
  png_wb_assert_incomplete(png_wb_dynamic_match_pause(), "zlib-truncated")

  let complete = png_wb_complete_chunk_png()
  let post_idat = png_wb_prefix(complete, 60)
  let wrong_fourth = png_wb_append(post_idat, b"\x00\x00\x00\x00IENX")
  let ancillary = png_wb_append(post_idat, b"\x00\x00\x00\x00vpAg")
  inspect(wrong_fourth.length() == 68, content="true")
  inspect(ancillary.length() == 68, content="true")
  png_wb_assert_pending_iend_type(wrong_fourth)
  png_wb_assert_pending_iend_type(ancillary)
  png_wb_assert_incomplete(wrong_fourth, "png-iend-type")
  png_wb_assert_incomplete(ancillary, "png-iend-type")
}


///|
fn png_wb_append_chunk(output : Array[Byte], kind : Array[Byte], payload : Array[Byte]) -> Unit {
  let length = payload.length().to_uint64()
  for shift in [24, 16, 8, 0] { output.push((length >> shift).to_byte()) }
  let mut crc = _png_crc_for_type(kind)
  for byte in kind { output.push(byte) }
  for byte in payload { crc = _png_crc_step(crc, byte); output.push(byte) }
  let stored = crc ^ 4294967295UL
  for shift in [24, 16, 8, 0] { output.push((stored >> shift).to_byte()) }
}

///| zlib completes here, but one of two declared RGB rows is absent.  The
/// raster classifier must therefore win before the missing-IEND framing row.
fn png_wb_short_raster_png() -> Bytes {
  let output : Array[Byte] = []
  for byte in [b'\x89', b'P', b'N', b'G', b'\r', b'\n', b'\x1a', b'\n'] { output.push(byte) }
  png_wb_append_chunk(output, [b'I', b'H', b'D', b'R'], [b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x02', b'\x08', b'\x02', b'\x00', b'\x00', b'\x00'])
  png_wb_append_chunk(output, [b'I', b'D', b'A', b'T'], [b'\x78', b'\x01', b'\x01', b'\x04', b'\x00', b'\xfb', b'\xff', b'\x00', b'\x12', b'\x34', b'\x56', b'\x00', b'\xf8', b'\x00', b'\x9d'])
  png_wb_append_chunk(output, [b'I', b'E', b'N', b'D'], [])
  Bytes::from_array(output)
}

///| The completed inflater cannot mask a short filtered row. Its raster
/// failure precedes the missing-IEND state even when both are incomplete.
test "PNG chunk EOF classifier gives raster precedence over terminal framing" {
  let short = png_wb_short_raster_png()
  png_wb_assert_incomplete(png_wb_prefix(short, short.length() - 12), "png-filtered-size")
  png_wb_assert_terminal_raster_error(short)
}

///| A nonzero IEND declaration is rejected when its fourth type byte arrives,
/// before any claimed payload becomes dispatchable. A wrong or non-IEND fourth
/// type remains an IEND type failure; trailing input wins over later EOF.
test "PNG chunk terminal framing preserves IEND rejection and trailing precedence" {
  let complete = png_wb_complete_chunk_png()
  let decoder = png_wb_chunk_decoder()
  let prefix = png_wb_source(png_wb_prefix(complete, 60))
  inspect(decoder.push(prefix.view()).outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let nonzero = png_wb_source(b"\x00\x00\x00\x01IENDX")
  let rejected = decoder.push(nonzero.view())
  inspect(rejected.consumed() == 8UL, content="true")
  match rejected.outcome() {
    PngChunkPushOutcome::Failed(error) => inspect(error.context() == Some("png-iend-length"), content="true")
    _ => fail("nonzero IEND must reject at the fourth type byte")
  }
  let second = png_wb_chunk_decoder()
  let full = png_wb_source(complete)
  inspect(second.push(full.view()).outcome() is PngChunkPushOutcome::NeedInput, content="true")
  let trailing = png_wb_source(b"X")
  let first_error = match second.push(trailing.view()).outcome() {
    PngChunkPushOutcome::Failed(error) => error
    _ => fail("post-IEND byte must fail during push")
  }
  inspect(first_error.context() == Some("png-trailing-data"), content="true")
  inspect(png_wb_error_matches(second.finish().unwrap_err(), first_error), content="true")
}
