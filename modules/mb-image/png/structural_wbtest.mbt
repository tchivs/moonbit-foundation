///|
test "PNG structural CRC uses type plus payload scope" {
  inspect(_png_crc32(b"IHDR") != _png_crc32(b""), content="true")
}

///|
fn png_decode_generated_vector(
  item : PngGeneratedCase,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let length = item.bytes.length().to_uint64()
  let owner = @bytes.OwnedBytes::from_bytes(
    item.bytes,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length, allocations=1UL, allocation_size=length, width=0UL,
        height=0UL, pixels=0UL, depth=0UL, work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=item.preserve_opaque_metadata,
    ),
    @codec.CodecLimits::new(
      max_probe_bytes=item.limits.probe, max_input_bytes=item.limits.input,
      max_output_bytes=item.limits.output, max_width=item.limits.width,
      max_height=item.limits.height, max_pixels=item.limits.pixels,
      max_work=item.limits.work,
    ),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=item.budget.bytes, allocations=item.budget.allocations,
        allocation_size=item.budget.allocation_size, width=item.budget.width,
        height=item.budget.height, pixels=item.budget.pixels,
        depth=item.budget.depth, work=item.budget.work,
      ),
    ),
    @error.Diagnostics::new(),
  )
}

///|
fn _png_legacy_phase20_structural_matrix() -> Unit raise Error {
  for item in _generated_png_structural_cases() {
    let error = png_decode_generated_vector(item).unwrap_err()
    if item.code == "unexpected-end" {
      inspect(
        error.code() == @error.ErrorCode::UnexpectedEndOfStream,
        content="true",
      )
    } else if item.code == "budget-exceeded" {
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    } else if item.code == "capability-unavailable" {
      if item.context == "opaque-metadata-preservation" {
        inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
      } else {
        if error.context() != Some("zlib-truncated") { fail("legacy PNG case: " + item.id + ": " + error.context().unwrap()) }
        inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
        inspect(error.context() == Some("zlib-truncated"), content="true")
      }
    } else {
      inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
    }
    if item.code != "unexpected-end" &&
      !(item.code == "capability-unavailable" && item.context != "opaque-metadata-preservation") &&
      error.context() != Some(item.context) {
      fail("generated PNG context mismatch: " + item.id)
    }
  }
}

///|
fn _png_legacy_phase20_crc_matrix() -> Unit raise InspectError {
  let ids = ["ihdr-crc", "idat-crc", "ancillary-crc", "semantic-crc", "iend-crc"]
  for item in _generated_png_structural_cases() {
    if ids.contains(item.id) {
      let error = png_decode_generated_vector(item).unwrap_err()
      inspect(error.context() == Some("png-crc"), content="true")
    }
  }
}

///|
test "PNG IHDR preflight checks every codec and allocation envelope ceiling" {
  let ihdr = [
    b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01',
    b'\x08', b'\x02', b'\x00', b'\x00', b'\x00',
  ]
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1024UL, allocations=1UL, allocation_size=1024UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=2048UL,
  ))
  for item in [
    ("width", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=0UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("height", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=0UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("pixels", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=0UL, max_work=2048UL,
    )),
    ("image-bytes", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=2UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("output-bytes", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=3UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    )),
    ("work", @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=6UL,
    )),
  ] {
    let (expected, limits) = item
    let error = _png_preflight_ihdr(ihdr, limits, budget).unwrap_err()
    inspect(error.context() == Some(expected), content="true")
  }
  let allocation_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1024UL, allocations=1UL, allocation_size=2UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=2048UL,
  ))
  let allocation = _png_preflight_ihdr(
    ihdr,
    @codec.CodecLimits::new(
      max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL,
      max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=2048UL,
    ),
    allocation_budget,
  ).unwrap_err()
  inspect(allocation.context() == Some("allocation_size"), content="true")
}

///|
test "PNG grayscale IHDR charges RGB8 output and grayscale filtered work" {
  let ihdr = [
    b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x05',
    b'\x08', b'\x00', b'\x00', b'\x00', b'\x00',
  ]
  let exact_limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=30UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=45UL,
  )
  let exact_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=30UL, allocations=1UL, allocation_size=30UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=45UL,
  ))
  inspect(_png_preflight_ihdr(ihdr, exact_limits, exact_budget) is Ok(_), content="true")
  let output_below = _png_preflight_ihdr(
    ihdr,
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=29UL, max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=45UL),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=30UL, allocations=1UL, allocation_size=30UL, width=16UL, height=16UL, pixels=256UL, depth=0UL, work=45UL)),
  ).unwrap_err()
  inspect(output_below.context() == Some("image-bytes"), content="true")
  let work_below = _png_preflight_ihdr(
    ihdr,
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=30UL, max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=44UL),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=30UL, allocations=1UL, allocation_size=30UL, width=16UL, height=16UL, pixels=256UL, depth=0UL, work=45UL)),
  ).unwrap_err()
  inspect(work_below.context() == Some("work"), content="true")
}

///|
test "PNG tRNS reserves RGBA8 while retaining grayscale source-byte work" {
  let limits = @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=40UL, max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=55UL)
  let exact = @budget.Budget::new(@budget.ResourceLimits::new(bytes=40UL, allocations=1UL, allocation_size=40UL, width=16UL, height=16UL, pixels=256UL, depth=0UL, work=55UL))
  inspect(_png_transparent_decode_budget(2UL, 5UL, 1UL, limits, exact) is Ok(_), content="true")
  let below = _png_transparent_decode_budget(2UL, 5UL, 1UL, @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=39UL, max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=55UL), exact).unwrap_err()
  inspect(below.context() == Some("image-bytes"), content="true")
}

///|
test "PNG indexed IHDR accepts legal packed depths and charges packed rows" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=64UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=128UL,
  )
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=64UL, allocations=3UL, allocation_size=64UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=128UL,
  ))
  for item in [(1, 9UL), (2, 5UL), (4, 3UL), (8, 2UL)] {
    let (depth, width) = item
    let indexed = [
      b'\x00', b'\x00', b'\x00', width.to_int().to_byte(), b'\x00', b'\x00', b'\x00', b'\x01',
      depth.to_byte(), b'\x03', b'\x00', b'\x00', b'\x00',
    ]
    inspect(_png_preflight_ihdr(indexed, limits, budget) is Ok(_), content="true")
    inspect(_png_grayscale_row_bytes(width, depth).unwrap() == 2UL, content="true")
  }
  let illegal = [
    b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01',
    b'\x10', b'\x03', b'\x00', b'\x00', b'\x00',
  ]
  inspect(_png_preflight_ihdr(illegal, limits, budget).unwrap_err().context() == Some("png-bit-depth"), content="true")
}

///|
test "PNG indexed packed decode reserves image plus exactly two source rows" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=135UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=150UL,
  )
  let exact = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=139UL, allocations=3UL, allocation_size=135UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=150UL,
  ))
  inspect(_png_indexed_decode_budget(9UL, 5UL, 1, 3UL, limits, exact) is Ok(_), content="true")
  let below = _png_indexed_decode_budget(
    9UL, 5UL, 1, 3UL, limits,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=138UL, allocations=3UL, allocation_size=135UL, width=16UL,
      height=16UL, pixels=256UL, depth=0UL, work=150UL,
    )),
  ).unwrap_err()
  inspect(below.context() == Some("bytes"), content="true")
}

///|
test "PNG grayscale IHDR accepts low depths and computes packed row bytes" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=256UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=512UL,
  )
  for item in [(1, 9UL, 2UL), (2, 5UL, 2UL), (4, 3UL, 2UL), (8, 2UL, 2UL)] {
    let (depth, width, row_bytes) = item
    let ihdr = [
      b'\x00', b'\x00', b'\x00', width.to_int().to_byte(),
      b'\x00', b'\x00', b'\x00', b'\x01',
      depth.to_byte(), b'\x00', b'\x00', b'\x00', b'\x00',
    ]
    let budget = @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=width * 3UL + row_bytes * 2UL, allocations=3UL,
      allocation_size=width * 3UL, width=16UL, height=16UL,
      pixels=256UL, depth=0UL, work=512UL,
    ))
    inspect(_png_preflight_ihdr(ihdr, limits, budget) is Ok(_), content="true")
    inspect(_png_grayscale_row_bytes(width, depth).unwrap() == row_bytes, content="true")
  }
}

///|
test "PNG semantic classifier rejects every deferred semantic chunk family" {
  for kind in [
    [b'P', b'L', b'T', b'E'], [b't', b'R', b'N', b'S'],
    [b'c', b'H', b'R', b'M'], [b'g', b'A', b'M', b'A'],
    [b'i', b'C', b'C', b'P'], [b's', b'B', b'I', b'T'],
    [b's', b'R', b'G', b'B'], [b'c', b'I', b'C', b'P'],
    [b'm', b'D', b'C', b'v'], [b'c', b'L', b'L', b'i'],
    [b'a', b'c', b'T', b'L'], [b'f', b'c', b'T', b'L'],
    [b'f', b'd', b'A', b'T'],
  ] {
    inspect(_png_is_known_semantic(kind), content="true")
  }
}

///|
struct PngEofFailureReader {}

///|
impl @io.Reader for PngEofFailureReader with fn read(_self, _destination) {
  @io.ReadOutcome::Failed(
    @error.CoreError::new(
      @error.ErrorCategory::Host,
      @error.ErrorCode::HostOperationFailed,
      operation="png-eof-scripted-read",
      context="scripted",
    ),
    0UL,
  )
}

///|
struct PngEofNoProgressReader {}

///|
impl @io.Reader for PngEofNoProgressReader with fn read(_self, _destination) {
  @io.ReadOutcome::Progress(0UL)
}

///|
test "PNG EOF probe does not charge an absent byte and preserves reader failures" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=57UL, max_output_bytes=64UL,
    max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=128UL,
  )
  let scratch = @bytes.OwnedBytes::new(1UL, _png_private_budget(1UL)).unwrap()
  let empty_owner = @bytes.OwnedBytes::from_bytes(
    b"",
    _png_private_budget(0UL),
  ).unwrap()
  let empty_reader = @io.MemoryReader::new(empty_owner.view())
  inspect(
    _png_require_eof(empty_reader as &@io.Reader, scratch, 57UL, limits) is Ok(_),
    content="true",
  )
  let failing_reader = PngEofFailureReader::{}
  let error = _png_require_eof(
    failing_reader as &@io.Reader, scratch, 57UL, limits,
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Host, content="true")
  inspect(error.code() == @error.ErrorCode::HostOperationFailed, content="true")
  let no_progress_reader = PngEofNoProgressReader::{}
  let no_progress = _png_require_eof(
    no_progress_reader as &@io.Reader, scratch, 57UL, limits,
  ).unwrap_err()
  inspect(no_progress.code() == @error.ErrorCode::NoProgress, content="true")
}

///|
test "PNG grayscale-alpha IHDR accepts legal depths and charges source pairs as RGBA8" {
  let legal = [
    b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x05',
    b'\x08', b'\x04', b'\x00', b'\x00', b'\x00',
  ]
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=40UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=65UL,
  )
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=40UL, allocations=1UL, allocation_size=40UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=65UL,
  ))
  inspect(_png_preflight_ihdr(legal, limits, budget) is Ok(_), content="true")
  for depth in [b'\x01', b'\x02', b'\x04'] {
    let illegal = [
      b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x01',
      depth, b'\x04', b'\x00', b'\x00', b'\x00',
    ]
    inspect(_png_preflight_ihdr(illegal, limits, budget).unwrap_err().context() == Some("png-bit-depth"), content="true")
  }
  let output_below = _png_preflight_ihdr(
    legal,
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=39UL, max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=65UL),
    budget,
  ).unwrap_err()
  inspect(output_below.context() == Some("image-bytes"), content="true")
  let work_below = _png_preflight_ihdr(
    legal,
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=40UL, max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=64UL),
    budget,
  ).unwrap_err()
  inspect(work_below.context() == Some("work"), content="true")
}

///|
test "PNG 16-bit grayscale and truecolour IHDRs reserve encoded source rows" {
  let gray = [
    b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x05',
    b'\x10', b'\x00', b'\x00', b'\x00', b'\x00',
  ]
  let rgb = [
    b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x05',
    b'\x10', b'\x02', b'\x00', b'\x00', b'\x00',
  ]
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=80UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=134UL,
  )
  let gray_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=80UL, allocations=3UL, allocation_size=80UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=134UL,
  ))
  let rgb_budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=80UL, allocations=3UL, allocation_size=80UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=134UL,
  ))
  inspect(_png_preflight_ihdr(gray, limits, gray_budget) is Ok(_), content="true")
  inspect(_png_preflight_ihdr(rgb, limits, rgb_budget) is Ok(_), content="true")
}

///|
test "PNG IHDR accepts Adam7 while rejecting unsupported interlace methods" {
  let adam7 : Array[Byte] = [
    b'\x00', b'\x00', b'\x00', b'\x08',
    b'\x00', b'\x00', b'\x00', b'\x08',
    b'\x08', b'\x02', b'\x00', b'\x00', b'\x01',
  ]
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=4096UL,
    max_width=64UL, max_height=64UL, max_pixels=4096UL, max_work=8192UL,
  )
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=4096UL, allocations=8UL, allocation_size=4096UL,
    width=64UL, height=64UL, pixels=4096UL, depth=0UL, work=8192UL,
  ))
  inspect(_png_preflight_ihdr(adam7, limits, budget) is Ok(_), content="true")
  adam7[12] = b'\x02'
  inspect(
    _png_preflight_ihdr(adam7, limits, budget).unwrap_err().context() == Some("png-ihdr-method"),
    content="true",
  )
}

///|
test "PNG Adam7 geometry accounts for all pass rows with bounded reusable storage" {
  let passes = _png_adam7_passes(5UL, 5UL, 4UL, 8).unwrap()
  inspect(passes.length(), content="7")
  let expected = [
    (0UL, 0UL, 8UL, 8UL, 1UL, 1UL, 4UL),
    (4UL, 0UL, 8UL, 8UL, 1UL, 1UL, 4UL),
    (0UL, 4UL, 4UL, 8UL, 2UL, 1UL, 8UL),
    (2UL, 0UL, 4UL, 4UL, 1UL, 2UL, 4UL),
    (0UL, 2UL, 2UL, 4UL, 3UL, 1UL, 12UL),
    (1UL, 0UL, 2UL, 2UL, 2UL, 3UL, 8UL),
    (0UL, 1UL, 1UL, 2UL, 5UL, 2UL, 20UL),
  ]
  for index = 0; index < expected.length(); index = index + 1 {
    let pass = passes[index]
    let (x, y, dx, dy, width, height, row_bytes) = expected[index]
    inspect(pass.x == x && pass.y == y && pass.dx == dx && pass.dy == dy, content="true")
    inspect(pass.width == width && pass.height == height && pass.row_bytes == row_bytes, content="true")
  }
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=111UL,
    max_width=5UL, max_height=5UL, max_pixels=25UL, max_work=211UL,
  )
  let exact = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=140UL, allocations=3UL, allocation_size=100UL, width=5UL,
    height=5UL, pixels=25UL, depth=0UL, work=211UL,
  ))
  inspect(_png_adam7_decode_budget(5UL, 5UL, 4UL, 8, 4UL, limits, exact) is Ok(_), content="true")
  let below = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=139UL, allocations=3UL, allocation_size=100UL, width=5UL,
    height=5UL, pixels=25UL, depth=0UL, work=211UL,
  ))
  inspect(
    _png_adam7_decode_budget(5UL, 5UL, 4UL, 8, 4UL, limits, below).unwrap_err().context() == Some("bytes"),
    content="true",
  )
  let tiny = _png_adam7_passes(1UL, 1UL, 1UL, 1).unwrap()
  inspect(tiny[0].width == 1UL && tiny[0].height == 1UL, content="true")
  for index = 1; index < tiny.length(); index = index + 1 {
    inspect(tiny[index].width == 0UL || tiny[index].height == 0UL, content="true")
  }
}

test "PNG 16-bit native-alpha IHDRs reserve encoded source rows" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=128UL,
    max_width=16UL, max_height=16UL, max_pixels=256UL, max_work=256UL,
  )
  for item in [(b'\x04', 4UL), (b'\x06', 8UL)] {
    let (colour_type, source_bpp) = item
    let ihdr = [
      b'\x00', b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x03',
      b'\x10', colour_type, b'\x00', b'\x00', b'\x00',
    ]
    let image_bytes = 2UL * 3UL * 4UL
    let source_rows = 2UL * source_bpp * 2UL
    let exact = @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=image_bytes + source_rows, allocations=3UL,
      allocation_size=if image_bytes > 2UL * source_bpp { image_bytes } else { 2UL * source_bpp },
      width=16UL, height=16UL, pixels=256UL, depth=0UL, work=256UL,
    ))
    inspect(_png_preflight_ihdr(ihdr, limits, exact) is Ok(_), content="true")
    inspect(_png_source_bytes_per_pixel(if colour_type == b'\x04' { 2UL } else { 4UL }, 16).unwrap(), content=source_bpp.to_string())
  }
}

///|
test "PNG colour declaration helpers validate sRGB and iCCP envelopes" {
  inspect(_png_validate_srgb_payload([b'\x00']) is Ok(b'\x00'), content="true")
  inspect(_png_validate_srgb_payload([b'\x04']).unwrap_err().context(), content="Some(\"png-srgb-intent\")")
  inspect(_png_validate_srgb_payload([]).unwrap_err().context(), content="Some(\"png-srgb-length\")")
  inspect(_png_validate_iccp_payload(b"profile\x00\x00\x78") is Ok(_), content="true")
  inspect(_png_validate_iccp_payload(b" profile\x00\x00\x78").unwrap_err().context(), content="Some(\"png-iccp-name\")")
  inspect(_png_validate_iccp_payload(b"profile\x00\x01\x78").unwrap_err().context(), content="Some(\"png-iccp-method\")")
}
