///|
fn png_encode_u32_at(value : Bytes, offset : Int) -> UInt64 {
  (value[offset].to_uint64() << 24) |
  (value[offset + 1].to_uint64() << 16) |
  (value[offset + 2].to_uint64() << 8) |
  value[offset + 3].to_uint64()
}

///|
/// Phase 36 RED: strict complete-PNG dynamic selection is not implemented yet.
test "PNG dynamic preflight selects only strict complete-PNG wins" {
  let image = png_wb_image(3UL, b"\x12\x34\x56")
  let fixed = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_wb_limits(),
    png_wb_budget(),
  ).unwrap()
  let dynamic = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::DynamicOrFixedOrStored,
    png_wb_limits(),
    png_wb_budget(),
  ).unwrap()
  inspect(dynamic.total_length == fixed.total_length, content="true")
  match dynamic.plan {
    PngDeflatePlan::Stored(_) | PngDeflatePlan::Fixed(_) => ()
    PngDeflatePlan::Dynamic(_) => panic()
  }
}

///|
fn png_wb_budget(
  bytes? : UInt64 = 512UL,
  work? : UInt64 = 1024UL,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=8UL,
      allocation_size=bytes,
      width=64UL,
      height=64UL,
      pixels=4096UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn png_wb_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=512UL,
    max_output_bytes=512UL,
    max_width=64UL,
    max_height=64UL,
    max_pixels=4096UL,
    max_work=1024UL,
  )
}

///|
fn png_wb_dynamic_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=512UL,
    max_output_bytes=512UL,
    max_width=128UL,
    max_height=64UL,
    max_pixels=4096UL,
    max_work=10000UL,
  )
}

///|
fn png_wb_dynamic_budget(
  bytes? : UInt64 = 512UL,
  work? : UInt64 = 10000UL,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=8UL,
      allocation_size=bytes,
      width=128UL,
      height=64UL,
      pixels=4096UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
/// The two rows make the first adaptive winner Sub and the second Up, so the
/// filtered stream is non-None while remaining small enough to audit by hand.
fn png_wb_adaptive_rgb_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL,
    2UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(0UL, 12UL, 6UL, 6UL, 1UL, 1UL, 2UL, 2UL).unwrap(),
    ],
    12UL,
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
        png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    png_wb_budget(bytes=12UL, work=0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    for row = 0UL; row < 2UL; row = row + 1UL {
      for index = 0UL; index < 6UL; index = index + 1UL {
        view
        .set_byte(
          index / 3UL,
          row,
          index % 3UL,
          [b'\x0a', b'\x14', b'\x1e'][index.to_int() % 3],
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
///| PNGF-02/03: admission records actual adaptive forward traversals rather
/// than a copied two-sweep formula.  The helper deliberately uses the facts
/// returned by preflight so Fixed and Dynamic can report their extra planning
/// walks without teaching this test an implementation-specific pass count.
fn png_wb_adaptive_cursor_work_ledger(
  strategy : PngCompressionStrategy,
) -> PngEncodePreflight {
  let image = png_wb_adaptive_rgb_image()
  let budget = png_wb_budget(work=1048576UL)
  _png_encode_preflight_with_filter(
    image.view(),
    strategy,
    PngFilterStrategy::Adaptive,
    png_wb_limits(),
    budget,
  ).unwrap()
}

///|
fn png_wb_adaptive_cursor_exact_work(
  strategy : PngCompressionStrategy,
  selected_work : UInt64,
) -> Bool {
  let image = png_wb_adaptive_rgb_image()
  let exact = png_wb_budget(work=selected_work)
  ignore(_png_encode_preflight_with_filter(
      image.view(),
      strategy,
      PngFilterStrategy::Adaptive,
      png_wb_limits(),
      exact,
    ).unwrap())
  exact.remaining().work() == 0UL
}

///|
fn png_wb_adaptive_cursor_rejects_one_less(
  strategy : PngCompressionStrategy,
  selected_work : UInt64,
) -> Bool {
  let image = png_wb_adaptive_rgb_image()
  let one_less = png_wb_budget(work=selected_work - 1UL)
  let unchanged = one_less.remaining()
  let rejected = _png_encode_preflight_with_filter(
    image.view(),
    strategy,
    PngFilterStrategy::Adaptive,
    png_wb_limits(),
    one_less,
  ).unwrap_err()
  rejected.context() == Some("work") &&
  png_wb_same_remaining(unchanged, one_less.remaining())
}

///| Adam7's first two nonempty passes are (0,0) then (4,0); their independent
/// filter tags establish canonical pass order without retaining geometry.
test "PNG Adam7 filtered cursor emits canonical pass order and omits empties" {
  for channels in [3UL, 4UL] {
    let passes = _png_adam7_passes(5UL, 5UL, channels, 8).unwrap()
    inspect(passes[0].x == 0UL && passes[1].x == 4UL && passes[0].row_bytes == channels, content="true")
    inspect(passes[0].width == 1UL && passes[0].height == 1UL && passes[6].width == 5UL, content="true")
  }
  let singleton = _png_adam7_passes(1UL, 1UL, 3UL, 8).unwrap()
  inspect(singleton[0].width == 1UL && singleton[0].height == 1UL && singleton[1].width == 0UL, content="true")
}

///| Every first row is local to its pass, so Adaptive cannot select Up from a
/// preceding image/pass row. Exact and one-less work retains the one-charge
/// preflight boundary for all available compression strategies.
test "PNG Adam7 Adaptive resets pass history and retains exact atomic admission" {
  let image = png_wb_adaptive_rgb_image()
  let channels = 3UL
  let passes = _png_adam7_passes(2UL, 2UL, channels, 8).unwrap()
    let mut cursor = PngFilteredCursor::new_with_interlace(
      image.view(), 2UL * channels, channels, PngFilterStrategy::Adaptive,
      PngInterlaceStrategy::Adam7,
    )
    let mut offset = 0UL
    for pass in passes {
      if pass.width == 0UL || pass.height == 0UL { continue }
      while cursor.index < offset {
        let (_, next) = cursor.next().unwrap(); cursor = next
      }
      let (tag, next) = cursor.next().unwrap()
      inspect(tag != b'\x02', content="true")
      cursor = next
      offset = offset + (pass.row_bytes + 1UL) * pass.height
    }
  for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored, PngCompressionStrategy::DynamicOrFixedOrStored] {
      let admitted = _png_encode_preflight_with_interlace(
        image.view(), strategy, PngFilterStrategy::Adaptive, PngInterlaceStrategy::Adam7,
        png_wb_limits(), png_wb_budget(work=1048576UL),
      ).unwrap()
      let exact = png_wb_budget(work=admitted.selected_work)
      ignore(_png_encode_preflight_with_interlace(
        image.view(), strategy, PngFilterStrategy::Adaptive, PngInterlaceStrategy::Adam7,
        png_wb_limits(), exact,
      ).unwrap())
      inspect(exact.remaining().work() == 0UL, content="true")
      let one_less = png_wb_budget(work=admitted.selected_work - 1UL)
      let before = one_less.remaining()
      let error = _png_encode_preflight_with_interlace(
        image.view(), strategy, PngFilterStrategy::Adaptive, PngInterlaceStrategy::Adam7,
        png_wb_limits(), one_less,
      ).unwrap_err()
      inspect(error.context() == Some("work") && png_wb_same_remaining(before, one_less.remaining()), content="true")
  }
}

///|
test "PNG adaptive cursor work ledger covers Stored planning and replay" {
  let facts = png_wb_adaptive_cursor_work_ledger(PngCompressionStrategy::Stored)
  inspect(facts.adaptive_planning_facts.resolved_rows, content="2")
  inspect(facts.adaptive_replay_facts.resolved_rows, content="2")
  inspect(facts.adaptive_replay_facts.candidate_residuals, content="60")
  inspect(facts.adaptive_replay_facts.selected_residuals, content="12")
  inspect(png_wb_adaptive_cursor_exact_work(PngCompressionStrategy::Stored, facts.selected_work), content="true")
  inspect(png_wb_adaptive_cursor_rejects_one_less(PngCompressionStrategy::Stored, facts.selected_work), content="true")
}

///|
test "PNG adaptive cursor work ledger covers FixedOrStored planning and replay" {
  let facts = png_wb_adaptive_cursor_work_ledger(PngCompressionStrategy::FixedOrStored)
  inspect(facts.adaptive_planning_facts.resolved_rows >= 2UL, content="true")
  inspect(facts.adaptive_replay_facts.resolved_rows, content="2")
  inspect(png_wb_adaptive_cursor_exact_work(PngCompressionStrategy::FixedOrStored, facts.selected_work), content="true")
  inspect(png_wb_adaptive_cursor_rejects_one_less(PngCompressionStrategy::FixedOrStored, facts.selected_work), content="true")
}

///|
///| Fixed planning probes every selected byte through a fresh forward traversal.
///| Stored establishes its candidate facts, Fixed establishes its matcher facts,
///| and the winner receives one more replay traversal.
test "PNG adaptive match cursor covers FixedOrStored probe traversals" {
  let facts = png_wb_adaptive_cursor_work_ledger(PngCompressionStrategy::FixedOrStored)
  inspect(facts.adaptive_planning_facts.resolved_rows, content="4")
  inspect(facts.adaptive_planning_facts.candidate_residuals, content="120")
  inspect(facts.adaptive_planning_facts.selected_residuals, content="24")
  inspect(facts.adaptive_replay_facts.resolved_rows, content="2")
  inspect(facts.adaptive_replay_facts.candidate_residuals, content="60")
  inspect(facts.adaptive_replay_facts.selected_residuals, content="12")
}

///|
test "PNG adaptive cursor work ledger covers DynamicOrFixedOrStored planning and replay" {
  let facts = png_wb_adaptive_cursor_work_ledger(
    PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  inspect(facts.adaptive_planning_facts.resolved_rows >= 6UL, content="true")
  inspect(facts.adaptive_replay_facts.resolved_rows, content="2")
  inspect(png_wb_adaptive_cursor_exact_work(PngCompressionStrategy::DynamicOrFixedOrStored, facts.selected_work), content="true")
  inspect(png_wb_adaptive_cursor_rejects_one_less(PngCompressionStrategy::DynamicOrFixedOrStored, facts.selected_work), content="true")
}

///|
///| Dynamic establishes Stored, Fixed, frequency/fingerprint, and exact-bit
///| traversals before selecting exactly one replay source.
test "PNG adaptive match cursor covers DynamicOrFixedOrStored probe traversals" {
  let facts = png_wb_adaptive_cursor_work_ledger(
    PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  inspect(facts.adaptive_planning_facts.resolved_rows, content="8")
  inspect(facts.adaptive_planning_facts.candidate_residuals, content="240")
  inspect(facts.adaptive_planning_facts.selected_residuals, content="48")
  inspect(facts.adaptive_replay_facts.resolved_rows, content="2")
  inspect(facts.adaptive_replay_facts.candidate_residuals, content="60")
  inspect(facts.adaptive_replay_facts.selected_residuals, content="12")
}

///| A declined Dynamic candidate still owns the exact cursor facts it already
///| consumed; its work must be admitted with the Fixed-or-Stored fallback.
test "PNG adaptive Dynamic decline facts are admitted" {
  let image = png_wb_adaptive_rgb_image()
  let outcome = _png_dynamic_plan_with_idat_limit(
    image.view(), 6UL, 3UL, PngFilterStrategy::Adaptive, 14UL, 0UL,
  ).unwrap()
  inspect(outcome.plan is None, content="true")
  inspect(outcome.frequency_facts.work().unwrap() > 0UL, content="true")
  inspect(outcome.bit_facts.work().unwrap() > 0UL, content="true")
  let preflight = _png_encode_preflight_with_filter_idat_limit(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_wb_limits(), png_wb_budget(), 0UL,
  ).unwrap()
  let expected_planning = _png_filtered_facts_add(
    _png_filtered_facts_add(
      _png_filtered_facts_add(
        _png_filtered_match_traverse(
          image.view(), 6UL, 3UL, PngFilterStrategy::Adaptive, 14UL,
        ).unwrap(),
        _png_fixed_plan(
          image.view(), 6UL, 3UL, PngFilterStrategy::Adaptive, 14UL,
        ).unwrap().traversal_facts,
      ).unwrap(),
      outcome.frequency_facts,
    ).unwrap(),
    outcome.bit_facts,
  ).unwrap()
  inspect(
    preflight.adaptive_planning_facts.resolved_rows == expected_planning.resolved_rows &&
      preflight.adaptive_planning_facts.candidate_residuals == expected_planning.candidate_residuals &&
      preflight.adaptive_planning_facts.selected_residuals == expected_planning.selected_residuals,
    content="true",
  )
  let exact = png_wb_budget(work=preflight.selected_work)
  ignore(_png_encode_preflight_with_filter_idat_limit(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_wb_limits(), exact, 0UL,
  ).unwrap())
  inspect(exact.remaining().work() == 0UL, content="true")
  let one_less = png_wb_budget(work=preflight.selected_work - 1UL)
  let before = one_less.remaining()
  let rejected = _png_encode_preflight_with_filter_idat_limit(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_wb_limits(), one_less, 0UL,
  ).unwrap_err()
  inspect(rejected.context() == Some("work") && png_wb_same_remaining(before, one_less.remaining()), content="true")
}

///|
fn png_wb_image(channels : UInt64, pixels : Bytes) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    1UL,
    1UL,
    if channels == 3UL {
      @model.ImageFormat::rgb8()
    } else {
      @model.ImageFormat::rgba8()
    },
    [
      @model.PlaneDescriptor::new(
        0UL, channels, channels, channels, 1UL, 1UL, 1UL, 1UL,
      ).unwrap(),
    ],
    channels,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb,
      @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL {
        Some(@color.AlphaMode::Straight)
      } else {
        None
      },
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
        png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    png_wb_budget(bytes=channels, work=0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    for index = 0UL; index < channels; index = index + 1UL {
      view.set_byte(0UL, 0UL, index, pixels[index.to_int()]).unwrap()
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
fn png_wb_encode(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(
    512UL,
    png_wb_budget(bytes=512UL, work=0UL),
  ).unwrap()
  let _ = @codec.ImageEncoder::encode(
    PngEncoder::new(),
    image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    png_wb_limits(),
    png_wb_budget(),
    @error.Diagnostics::new(),
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
    image.view(),
    png_wb_limits(),
    png_wb_budget(),
    @error.Diagnostics::new(),
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
  for index = 0; index < length; index = index + 1 {
    result.push(value[start + index])
  }
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
fn png_wb_filter_row(
  filter : PngRowFilter,
  source : Bytes,
  above : Bytes?,
  channels : UInt64,
) -> Bytes {
  let residuals : Array[Byte] = []
  for index = 0UL; index < source.length().to_uint64(); index = index + 1UL {
    residuals.push(
      _png_filter_candidate_byte(filter, source, above, channels, index).unwrap(),
    )
  }
  Bytes::from_array(residuals)
}

///|
/// PNGF-02 fixes the method-0 source-row formulas independently of framing.
test "PNG filter arithmetic uses raw RGB8 and straight RGBA8 neighbors" {
  let rgb = b"\x0a\x14\x1e\x0d\x19\x23"
  let rgba = b"\x0a\x14\x1e\x28\x0d\x19\x23\x31"
  inspect(
    png_wb_filter_row(PngRowFilter::None, rgb, None, 3UL) == rgb,
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Sub, rgb, None, 3UL) ==
    b"\x0a\x14\x1e\x03\x05\x05",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Up, rgb, None, 3UL) == rgb,
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Average, rgb, None, 3UL) ==
    b"\x0a\x14\x1e\x08\x0f\x14",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Paeth, rgb, None, 3UL) ==
    b"\x0a\x14\x1e\x03\x05\x05",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::None, rgba, None, 4UL) == rgba,
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Sub, rgba, None, 4UL) ==
    b"\x0a\x14\x1e\x28\x03\x05\x05\x09",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Up, rgba, None, 4UL) == rgba,
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Average, rgba, None, 4UL) ==
    b"\x0a\x14\x1e\x28\x08\x0f\x14\x1d",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Paeth, rgba, None, 4UL) ==
    b"\x0a\x14\x1e\x28\x03\x05\x05\x09",
    content="true",
  )
}

///|
/// PNGF-02 fixes prior-row and upper-left source samples for both profiles.
test "PNG filter arithmetic uses previous raw rows and upper-left Paeth samples" {
  let rgb_above = b"\x64\x6e\x78\x96\xa0\xaa"
  let rgb_source = b"\x32\x3c\x46\x6e\x78\x82"
  let rgba_above = b"\x64\x6e\x78\x82\x96\xa0\xaa\xb4"
  let rgba_source = b"\x32\x3c\x46\x50\x6e\x78\x82\x8c"
  inspect(
    png_wb_filter_row(PngRowFilter::Up, rgb_source, Some(rgb_above), 3UL) ==
    b"\xce\xce\xce\xd8\xd8\xd8",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Paeth, rgb_source, Some(rgb_above), 3UL) ==
    b"\xce\xce\xce\x0a\x0a\x0a",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Up, rgba_source, Some(rgba_above), 4UL) ==
    b"\xce\xce\xce\xce\xd8\xd8\xd8\xd8",
    content="true",
  )
  inspect(
    png_wb_filter_row(PngRowFilter::Paeth, rgba_source, Some(rgba_above), 4UL) ==
    b"\xce\xce\xce\xce\x0a\x0a\x0a\x0a",
    content="true",
  )
}

///|
/// PNGF-02 scores residuals as signed bytes, including the representable 128.
test "PNG filter arithmetic scores signed residual magnitudes exactly" {
  inspect(
    _png_filter_candidate_score(PngRowFilter::None, b"\x7f\x80\x81", None, 3UL).unwrap(),
    content="382",
  )
  inspect(
    _png_filter_candidate_score(PngRowFilter::None, b"\x80\x00\x00", None, 3UL).unwrap(),
    content="128",
  )
}

///|
/// PNGF-02 keeps the first candidate whenever residual scores tie.
test "PNG filter arithmetic retains the earliest equal-score candidate" {
  let (zero_filter, zero_score) = _png_filter_row_winner(
    b"\x00\x00\x00\x00\x00\x00",
    None,
    3UL,
  ).unwrap()
  inspect(zero_filter == PngRowFilter::None, content="true")
  inspect(zero_score, content="0")
  let (tie_filter, tie_score) = _png_filter_row_winner(
    b"\x64\x00\x00\x64\x00\x00",
    None,
    3UL,
  ).unwrap()
  inspect(tie_filter == PngRowFilter::Sub, content="true")
  inspect(tie_score, content="100")
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
  inspect(
    bytes[43] == b'\x01' && bytes[44] == b'\x04' && bytes[45] == b'\x00',
    content="true",
  )
  inspect(bytes[46] == b'\xfb' && bytes[47] == b'\xff', content="true")
  inspect(
    bytes[48] == b'\x00' &&
    bytes[49] == b'\x12' &&
    bytes[50] == b'\x34' &&
    bytes[51] == b'\x56',
    content="true",
  )
  inspect(
    png_encode_adler(bytes, 48, 4) == png_encode_u32_at(bytes, 52),
    content="true",
  )
  inspect(
    _png_crc32(png_encode_slice(bytes, 12, 17)) == png_encode_u32_at(bytes, 29),
    content="true",
  )
  inspect(
    _png_crc32(png_encode_slice(bytes, 37, 19)) == png_encode_u32_at(bytes, 56),
    content="true",
  )
  inspect(_png_crc32(b"IEND") == png_encode_u32_at(bytes, 68), content="true")
}

///|
test "canonical PNG byte sequence is stable for RGB and straight RGBA" {
  for
    image in [
      png_wb_image(3UL, b"\x12\x34\x56"),
      png_wb_image(4UL, b"\x04\x05\x06\x07"),
    ] {
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
  for
    image in [
      png_wb_image(3UL, b"\x12\x34\x56"),
      png_wb_image(4UL, b"\x04\x05\x06\x07"),
    ] {
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
  let (length_symbol, length_extra, length_extra_bits) = _png_fixed_length_code(
    258UL,
  )
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
    5UL,
    1UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(0UL, 15UL, 15UL, 15UL, 1UL, 1UL, 5UL, 1UL).unwrap(),
    ],
    15UL,
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
        png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    png_wb_budget(bytes=15UL, work=0UL),
  ).unwrap()
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
/// Five periodic literal values deliberately exceed the A1 distance-1..4
/// matcher, matching the public 128-pixel strict Dynamic winner fixture.
fn png_wb_dynamic_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    128UL,
    1UL,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(
        0UL, 384UL, 384UL, 384UL, 1UL, 1UL, 128UL, 1UL,
      ).unwrap(),
    ],
    384UL,
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
        png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    png_wb_dynamic_budget(bytes=384UL, work=0UL),
  ).unwrap()
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
fn png_wb_same_remaining(
  left : @budget.ResourceLimits,
  right : @budget.ResourceLimits,
) -> Bool {
  left.bytes() == right.bytes() &&
  left.allocations() == right.allocations() &&
  left.allocation_size() == right.allocation_size() &&
  left.width() == right.width() &&
  left.height() == right.height() &&
  left.pixels() == right.pixels() &&
  left.depth() == right.depth() &&
  left.work() == right.work()
}

///|
test "PNG fixed-or-stored white-box selected work boundary charges once" {
  let image = png_wb_fixed_or_stored_replay_image()
  let generous = png_wb_budget(work=1024UL)
  let before = generous.remaining()
  let facts = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_wb_limits(),
    generous,
  ).unwrap()
  let selected = before.work() - generous.remaining().work()
  match facts.plan {
    PngDeflatePlan::Fixed(plan) => {
      inspect(plan.matcher_work, content="189")
      inspect(plan.deflate_bits, content="126")
      inspect(plan.deflate_bytes, content="16")
      inspect(
        selected == facts.total_length + plan.matcher_work + plan.matcher_work,
        content="true",
      )
    }
    PngDeflatePlan::Stored(_) => panic()
    PngDeflatePlan::Dynamic(_) => panic()
  }
  let exact = png_wb_budget(work=selected)
  ignore(
    _png_encode_preflight(
      image.view(),
      PngCompressionStrategy::FixedOrStored,
      png_wb_limits(),
      exact,
    ).unwrap(),
  )
  inspect(exact.remaining().work(), content="0")
  let one_less = png_wb_budget(work=selected - 1UL)
  let one_less_before = one_less.remaining()
  let rejected = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::FixedOrStored,
    png_wb_limits(),
    one_less,
  ).unwrap_err()
  inspect(rejected.context() == Some("work"), content="true")
  inspect(
    png_wb_same_remaining(one_less_before, one_less.remaining()),
    content="true",
  )
}

///|
test "PNG dynamic selected work boundary charges once" {
  let image = png_wb_dynamic_image()
  let generous = png_wb_dynamic_budget(work=10000UL)
  let before = generous.remaining()
  let facts = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::DynamicOrFixedOrStored,
    png_wb_dynamic_limits(),
    generous,
  ).unwrap()
  let selected = before.work() - generous.remaining().work()
  match facts.plan {
    PngDeflatePlan::Dynamic(plan) => {
      inspect(plan.total_length, content="202")
      inspect(plan.matcher_work, content="4593")
      inspect(selected == 202UL + 4593UL + 4593UL, content="true")
      inspect(selected, content="9388")
    }
    PngDeflatePlan::Stored(_) | PngDeflatePlan::Fixed(_) => panic()
  }
  let exact = png_wb_dynamic_budget(work=9388UL)
  ignore(
    _png_encode_preflight(
      image.view(),
      PngCompressionStrategy::DynamicOrFixedOrStored,
      png_wb_dynamic_limits(),
      exact,
    ).unwrap(),
  )
  inspect(exact.remaining().work(), content="0")
  let one_less = png_wb_dynamic_budget(work=9387UL)
  let one_less_before = one_less.remaining()
  let rejected = _png_encode_preflight(
    image.view(),
    PngCompressionStrategy::DynamicOrFixedOrStored,
    png_wb_dynamic_limits(),
    one_less,
  ).unwrap_err()
  inspect(rejected.context() == Some("work"), content="true")
  inspect(
    png_wb_same_remaining(one_less_before, one_less.remaining()),
    content="true",
  )
}
