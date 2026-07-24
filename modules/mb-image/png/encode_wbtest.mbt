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

///| The default white-box limits are intentionally generous. Exact selected
/// Indexed8 Adam7 admission needs a compact local limit fixture.
fn png_wb_indexed_limits(output : UInt64, work : UInt64) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=512UL,
    max_output_bytes=output,
    max_width=64UL,
    max_height=64UL,
    max_pixels=4096UL,
    max_work=work,
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

///| A legal little-endian four-byte GrayAlpha16 source makes the profile-aware
/// Adam7 cursor's filter history and U16 wire lanes independently observable.
fn png_wb_graya16_adam7_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    5UL, 5UL, @model.ImageFormat::graya16(),
    [@model.PlaneDescriptor::new(0UL, 100UL, 20UL, 20UL, 1UL, 1UL, 5UL, 5UL).unwrap()],
    100UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
      @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_wb_budget(bytes=0UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_wb_budget(bytes=100UL, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        let sample = y * 5UL + x
        view.set_component_byte(x, y, 0UL, 0UL, sample.to_byte()).unwrap()
        view.set_component_byte(x, y, 0UL, 1UL, (b'\x80'.to_uint64() + sample).to_byte()).unwrap()
        view.set_component_byte(x, y, 1UL, 0UL, (b'\x40'.to_uint64() + sample).to_byte()).unwrap()
        view.set_component_byte(x, y, 1UL, 1UL, (b'\xc0'.to_uint64() + sample).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
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

///| Drain the real private logical source so this regression observes the
/// canonical pass geometry only through the production cursor.
fn png_wb_adam7_cursor_bytes(image : @storage.OwnedImage) -> Bytes {
  let channels = image.view().format().channel_count()
  let mut cursor = PngFilteredCursor::new_with_interlace(
    image.view(), image.view().width() * channels, channels,
    PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  let expected_length = _png_adam7_passes(
    image.view().width(), image.view().height(), channels, 8,
  ).unwrap().fold(init=0UL, fn(total, pass) {
    if pass.width == 0UL || pass.height == 0UL {
      total
    } else {
      total + (pass.row_bytes + 1UL) * pass.height
    }
  })
  let bytes : Array[Byte] = []
  while cursor.index < expected_length {
    let (byte, next) = cursor.next().unwrap()
    bytes.push(byte)
    cursor = next
  }
  Bytes::from_array(bytes)
}

///| Adam7's seven nonempty 5x5 passes are consumed from the production
/// cursor.  Every row starts with filter None, followed by its source samples.
test "PNG Adam7 filtered cursor emits canonical pass order and omits empties" {
  let rgb = png_wb_image(
    3UL, Bytes::from_array(Array::make(75, b'\x00')), width=5UL, height=5UL,
  )
  rgb.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          view.set_byte(x, y, channel, (y * 15UL + x * 3UL + channel).to_byte()).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  let rgb_actual = png_wb_adam7_cursor_bytes(rgb)
  let rgb_expected =
    b"\x00\x00\x01\x02\x00\x0c\x0d\x0e\x00\x3c\x3d\x3e\x48\x49\x4a\x00\x06\x07\x08\x00\x42\x43\x44\x00\x1e\x1f\x20\x24\x25\x26\x2a\x2b\x2c\x00\x03\x04\x05\x09\x0a\x0b\x00\x21\x22\x23\x27\x28\x29\x00\x3f\x40\x41\x45\x46\x47\x00\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x00\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b"
  inspect(rgb_actual.length(), content=rgb_expected.length().to_string())
  for index = 0; index < rgb_actual.length(); index = index + 1 {
    if rgb_actual[index].to_int() != rgb_expected[index].to_int() {
      fail(
        "PNG Adam7 RGB cursor at " + index.to_string() + " got " +
        rgb_actual[index].to_int().to_string() + " expected " +
        rgb_expected[index].to_int().to_string(),
      )
    }
  }
  let rgba = png_wb_image(
    4UL, Bytes::from_array(Array::make(100, b'\x00')), width=5UL, height=5UL,
  )
  rgba.with_mut_view(fn(view) {
    for y = 0UL; y < 5UL; y = y + 1UL {
      for x = 0UL; x < 5UL; x = x + 1UL {
        for channel = 0UL; channel < 4UL; channel = channel + 1UL {
          view.set_byte(x, y, channel, (y * 20UL + x * 4UL + channel).to_byte()).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  inspect(
    png_wb_adam7_cursor_bytes(rgba) ==
    b"\x00\x00\x01\x02\x03\x00\x10\x11\x12\x13\x00\x50\x51\x52\x53\x60\x61\x62\x63\x00\x08\x09\x0a\x0b\x00\x58\x59\x5a\x5b\x00\x28\x29\x2a\x2b\x30\x31\x32\x33\x38\x39\x3a\x3b\x00\x04\x05\x06\x07\x0c\x0d\x0e\x0f\x00\x2c\x2d\x2e\x2f\x34\x35\x36\x37\x00\x54\x55\x56\x57\x5c\x5d\x5e\x5f\x00\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x00\x3c\x3d\x3e\x3f\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f",
    content="true",
  )
  for channels in [3UL, 4UL] {
    let singleton = png_wb_image(channels, if channels == 3UL {
      b"\xaa\xbb\xcc"
    } else {
      b"\xaa\xbb\xcc\xdd"
    })
    let expected = if channels == 3UL {
      b"\x00\xaa\xbb\xcc"
    } else {
      b"\x00\xaa\xbb\xcc\xdd"
    }
    inspect(
      png_wb_adam7_cursor_bytes(singleton) == expected,
      content="true",
    )
  }
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

///| GrayAlpha16 uses the same profile-aware Adam7 cursor for every legal
/// filter/compression selection: each pass starts with local predictor history
/// and preflight charges selected work only after all checks succeed.
test "PNG GrayAlpha16 Adam7 profile cursor keeps pass history and exact work" {
  let image = png_wb_graya16_adam7_image()
  let channels = 4UL
  let passes = _png_adam7_passes(5UL, 5UL, channels, 8).unwrap()
  let mut cursor = PngFilteredCursor::new_with_interlace(
    image.view(), 20UL, channels, PngFilterStrategy::Adaptive,
    PngInterlaceStrategy::Adam7, profile=PngEncodeProfile::GrayAlpha16,
  )
  let mut offset = 0UL
  for pass in passes {
    if pass.width == 0UL || pass.height == 0UL { continue }
    while cursor.index < offset {
      let (_, next) = cursor.next().unwrap(); cursor = next
    }
    let (tag, next) = cursor.next().unwrap()
    if tag == b'\x02' || tag == b'\x03' || tag == b'\x04' {
      abort("png graya16 adam7 pass inherited predictor")
    }
    cursor = next
    offset = offset + (pass.row_bytes + 1UL) * pass.height
  }
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let admitted = _png_encode_preflight_with_interlace_profile(
        image.view(), PngEncodeProfile::GrayAlpha16, strategy, filter_strategy,
        PngInterlaceStrategy::Adam7, png_wb_dynamic_limits(), png_wb_budget(work=1048576UL),
      ).unwrap()
      let exact = png_wb_budget(work=admitted.selected_work)
      ignore(_png_encode_preflight_with_interlace_profile(
        image.view(), PngEncodeProfile::GrayAlpha16, strategy, filter_strategy,
        PngInterlaceStrategy::Adam7, png_wb_dynamic_limits(), exact,
      ).unwrap())
      inspect(exact.remaining().work() == 0UL, content="true")
      let one_less = png_wb_budget(work=admitted.selected_work - 1UL)
      let before = one_less.remaining()
      let error = _png_encode_preflight_with_interlace_profile(
        image.view(), PngEncodeProfile::GrayAlpha16, strategy, filter_strategy,
        PngInterlaceStrategy::Adam7, png_wb_dynamic_limits(), one_less,
      ).unwrap_err()
      inspect(
        error.context() == Some("work") && png_wb_same_remaining(before, one_less.remaining()),
        content="true",
      )
    }
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
fn png_wb_image(
  channels : UInt64,
  pixels : Bytes,
  width? : UInt64 = 1UL,
  height? : UInt64 = 1UL,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width,
    height,
    if channels == 3UL {
      @model.ImageFormat::rgb8()
    } else {
      @model.ImageFormat::rgba8()
    },
    [
      @model.PlaneDescriptor::new(
        0UL, channels * width * height, channels * width, channels * width,
        1UL, 1UL, width, height,
      ).unwrap(),
    ],
    channels * width * height,
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
    png_wb_budget(bytes=channels * width * height, work=0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for index = 0UL; index < channels; index = index + 1UL {
          view.set_byte(x, y, index, pixels[((y * width + x) * channels + index).to_int()]).unwrap()
        }
      }
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

///|
test "PNG Indexed8 frame facts shift PLTE while zero-PLTE offsets remain frozen" {
  let indexed = PngIndexedImage::new(
    2UL, 1UL, b"\x00\x01", b"\x12\x34\x56\xa0\xb0\xc0",
    b"\xff\xff", png_wb_budget(bytes=64UL, work=0UL),
  ).unwrap()
  let indexed_facts = _png_encode_indexed_preflight(
    indexed, png_wb_limits(), png_wb_budget(work=1024UL),
  ).unwrap()
  inspect(indexed_facts.frame.plte_length, content="6")
  inspect(indexed_facts.frame.plte_start, content="33")
  inspect(indexed_facts.frame.trns_length, content="0")
  inspect(indexed_facts.frame.trns_start, content="51")
  inspect(indexed_facts.frame.idat_start, content="51")
  inspect(indexed_facts.frame.iend_start, content="77")
  inspect(indexed_facts.frame.total_length, content="89")
  let machine = PngEncodeMachine::new_with_indexed(
    indexed, png_wb_limits(), png_wb_budget(work=1024UL), @error.Diagnostics::new(),
  ).unwrap()
  while machine.completed() < 47UL {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
  }
  inspect(machine.present().unwrap().unwrap() == b'\xf7', content="true")
  let legacy = _png_encode_preflight(
    png_wb_image(3UL, b"\x12\x34\x56").view(), PngCompressionStrategy::Stored,
    png_wb_limits(), png_wb_budget(work=1024UL),
  ).unwrap()
  inspect(legacy.frame.plte_length, content="0")
  inspect(legacy.frame.trns_length, content="0")
  inspect(legacy.frame.trns_start, content="33")
  inspect(legacy.frame.idat_start, content="33")
  inspect(legacy.frame.iend_start, content="60")
  inspect(legacy.frame.total_length, content="72")
}

///| Selected Indexed8 Adam7 facts must be charged once from the shared pass
/// geometry: exact admission reaches zero work, and one-less limits stay atomic.
test "PNG Indexed8 Adam7 preflight facts and admission are exact" {
  let source = PngIndexedImage::new(
    5UL, 5UL,
    b"\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00\x02\x03\x00\x01\x02\x00\x01\x02\x03\x00",
    b"\x12\x34\x56\xa0\xb0\xc0\xd0\xe0\xf0\x21\x43\x65", b"\x00\x80\x7f\xff",
    png_wb_budget(bytes=256UL, work=0UL),
  ).unwrap()
  let exact = png_wb_budget(work=143UL)
  let facts = _png_encode_indexed_preflight_with_profile(
    source, PngIndexedWireProfile::Eight, PngInterlaceStrategy::Adam7,
    png_wb_indexed_limits(143UL, 143UL), exact,
  ).unwrap()
  inspect(facts.scanlines, content="36")
  inspect(facts.blocks, content="1")
  inspect(facts.idat_length, content="47")
  inspect(facts.total_length, content="143")
  inspect(facts.selected_work, content="143")
  inspect(exact.remaining().work(), content="0")

  let one_less_work = png_wb_budget(work=142UL)
  let work_before = one_less_work.remaining()
  inspect(_png_encode_indexed_preflight_with_profile(
    source, PngIndexedWireProfile::Eight, PngInterlaceStrategy::Adam7,
    png_wb_indexed_limits(143UL, 143UL), one_less_work,
  ) is Err(_), content="true")
  inspect(png_wb_same_remaining(work_before, one_less_work.remaining()), content="true")

  let one_less_output = png_wb_budget(work=143UL)
  let output_before = one_less_output.remaining()
  inspect(_png_encode_indexed_preflight_with_profile(
    source, PngIndexedWireProfile::Eight, PngInterlaceStrategy::Adam7,
    png_wb_indexed_limits(142UL, 143UL), one_less_output,
  ) is Err(_), content="true")
  inspect(png_wb_same_remaining(output_before, one_less_output.remaining()), content="true")
}

///| The selected profiles use their own packed Adam7 rows before the one work
/// charge. Literal totals here intentionally do not derive from a helper.
test "PNG selected low-bit Adam7 preflight facts and admission are exact" {
  for item in [
    (PngIndexedWireProfile::One, 2UL, 22UL, 33UL, 122UL),
    (PngIndexedWireProfile::Two, 4UL, 24UL, 35UL, 132UL),
    (PngIndexedWireProfile::Four, 16UL, 27UL, 38UL, 183UL),
  ] {
    let (profile, cap, expected_scanlines, expected_idat, expected_total) = item
    let indices = b"\x00\x01\x00\x01\x00\x00\x01\x00\x01\x00\x00\x01\x00\x01\x00\x01\x00\x00\x01\x00\x01\x00\x01\x00\x00"
    let palette = Bytes::from_array(Array::make((cap * 3UL).to_int(), b'\x12'))
    let alpha = Bytes::from_array(Array::make(cap.to_int(), b'\x80'))
    let source = PngIndexedImage::new(
      5UL, 5UL, indices, palette, alpha, png_wb_budget(bytes=256UL, work=0UL),
    ).unwrap()
    let exact = png_wb_budget(work=expected_total)
    let facts = _png_encode_indexed_preflight_with_profile(
      source, profile, PngInterlaceStrategy::Adam7,
      png_wb_indexed_limits(expected_total, expected_total), exact,
    ).unwrap()
    inspect(facts.scanlines == expected_scanlines, content="true")
    inspect(facts.blocks == 1UL && facts.idat_length == expected_idat, content="true")
    inspect(facts.total_length == expected_total && facts.selected_work == expected_total, content="true")
    inspect(exact.remaining().work() == 0UL, content="true")

    let one_less_output = png_wb_budget(work=expected_total)
    let output_before = one_less_output.remaining()
    inspect(_png_encode_indexed_preflight_with_profile(
      source, profile, PngInterlaceStrategy::Adam7,
      png_wb_indexed_limits(expected_total - 1UL, expected_total), one_less_output,
    ) is Err(_), content="true")
    inspect(png_wb_same_remaining(output_before, one_less_output.remaining()), content="true")

    let one_less_work = png_wb_budget(work=expected_total - 1UL)
    let work_before = one_less_work.remaining()
    inspect(_png_encode_indexed_preflight_with_profile(
      source, profile, PngInterlaceStrategy::Adam7,
      png_wb_indexed_limits(expected_total, expected_total), one_less_work,
    ) is Err(_), content="true")
    inspect(png_wb_same_remaining(work_before, one_less_work.remaining()), content="true")

    let oversized = PngIndexedImage::new(
      1UL, 1UL, b"\x00", Bytes::from_array(Array::make(((cap + 1UL) * 3UL).to_int(), b'\x12')),
      Bytes::from_array(Array::make((cap + 1UL).to_int(), b'\x80')),
      png_wb_budget(bytes=256UL, work=0UL),
    ).unwrap()
    let cap_budget = png_wb_budget()
    let cap_before = cap_budget.remaining()
    inspect(_png_encode_indexed_preflight_with_profile(
      oversized, profile, PngInterlaceStrategy::Adam7, png_wb_limits(), cap_budget,
    ) is Err(_), content="true")
    inspect(png_wb_same_remaining(cap_before, cap_budget.remaining()), content="true")
  }
  inspect(_png_adam7_passes(18446744073709551615UL, 1UL, 1UL, 4) is Err(_), content="true")
}

///|
test "PNG low-bit indexed profiles derive packed facts and reject before work charge" {
  for item in [
    (PngIndexedWireProfile::One, 2UL, 9UL, 2UL),
    (PngIndexedWireProfile::Two, 4UL, 5UL, 2UL),
    (PngIndexedWireProfile::Four, 16UL, 3UL, 2UL),
  ] {
    let (profile, cap, width, expected_row_bytes) = item
    let indices = Bytes::from_array(Array::make(width.to_int(), b'\x00'))
    let palette = Bytes::from_array(Array::make((cap * 3UL).to_int(), b'\x12'))
    let alpha = Bytes::from_array(Array::make(cap.to_int(), b'\xff'))
    let source = PngIndexedImage::new(
      width, 1UL, indices, palette, alpha, png_wb_budget(bytes=128UL, work=0UL),
    ).unwrap()
    let admitted = _png_encode_indexed_preflight_with_profile(
      source, profile, PngInterlaceStrategy::None, png_wb_limits(), png_wb_budget(work=1024UL),
    ).unwrap()
    inspect(admitted.row_bytes == expected_row_bytes, content="true")
    inspect(admitted.scanlines == expected_row_bytes + 1UL, content="true")
    let exact = png_wb_budget(work=admitted.selected_work)
    ignore(_png_encode_indexed_preflight_with_profile(
      source, profile, PngInterlaceStrategy::None, png_wb_limits(), exact,
    ).unwrap())
    inspect(exact.remaining().work() == 0UL, content="true")
    let one_less = png_wb_budget(work=admitted.selected_work - 1UL)
    let before = one_less.remaining()
    let error = _png_encode_indexed_preflight_with_profile(
      source, profile, PngInterlaceStrategy::None, png_wb_limits(), one_less,
    ).unwrap_err()
    inspect(error.context() == Some("work") && png_wb_same_remaining(before, one_less.remaining()), content="true")

    let oversized_palette = Bytes::from_array(Array::make(((cap + 1UL) * 3UL).to_int(), b'\x12'))
    let oversized_alpha = Bytes::from_array(Array::make((cap + 1UL).to_int(), b'\xff'))
    let oversized = PngIndexedImage::new(
      1UL, 1UL, b"\x00", oversized_palette, oversized_alpha,
      png_wb_budget(bytes=128UL, work=0UL),
    ).unwrap()
    let rejected_budget = png_wb_budget()
    let rejected_before = rejected_budget.remaining()
    let rejected = _png_encode_indexed_preflight_with_profile(
      oversized, profile, PngInterlaceStrategy::None, png_wb_limits(), rejected_budget,
    ).unwrap_err()
    inspect(
      rejected.context() == Some("indexed-palette-cap") &&
        png_wb_same_remaining(rejected_before, rejected_budget.remaining()),
      content="true",
    )
  }
}

///|
test "PNG Indexed8 tRNS frame facts and CRC advance only on acknowledgement" {
  let indexed = PngIndexedImage::new(
    4UL, 1UL, b"\x00\x01\x02\x03",
    b"\x12\x34\x56\xa0\xb0\xc0\x11\x22\x33\x44\x55\x66",
    b"\x00\xff\x80\xff", png_wb_budget(bytes=64UL, work=0UL),
  ).unwrap()
  let facts = _png_encode_indexed_preflight(
    indexed, png_wb_limits(), png_wb_budget(work=1024UL),
  ).unwrap()
  inspect(facts.frame.plte_start, content="33")
  inspect(facts.frame.plte_length, content="12")
  inspect(facts.frame.trns_start, content="57")
  inspect(facts.frame.trns_length, content="3")
  inspect(facts.frame.idat_start, content="72")
  inspect(facts.frame.iend_start, content="100")
  inspect(facts.frame.total_length, content="112")
  let machine = PngEncodeMachine::new_with_indexed(
    indexed, png_wb_limits(), png_wb_budget(work=1024UL), @error.Diagnostics::new(),
  ).unwrap()
  while machine.completed() < 65UL {
    let byte = machine.present().unwrap().unwrap()
    machine.acknowledge(byte).unwrap()
  }
  let before = machine.trns_crc
  inspect(machine.present().unwrap().unwrap() == b'\x00', content="true")
  inspect(machine.trns_crc == before, content="true")
  machine.acknowledge(b'\x00').unwrap()
  let after_first = machine.trns_crc
  inspect(after_first != before, content="true")
  inspect(machine.present().unwrap().unwrap() == b'\xff', content="true")
  inspect(machine.trns_crc == after_first, content="true")
  machine.acknowledge(b'\xff').unwrap()
  let after_second = machine.trns_crc
  inspect(after_second != after_first, content="true")
  inspect(machine.present().unwrap().unwrap() == b'\x80', content="true")
  inspect(machine.trns_crc == after_second, content="true")
  machine.acknowledge(b'\x80').unwrap()
  inspect(machine.trns_crc != after_second, content="true")
}

///|
test "PNG Indexed8 preflight rejects empty scanlines and oversized IDAT" {
  inspect(_png_indexed_stored_idat_length(0UL) is Err(_), content="true")
  inspect(
    _png_indexed_stored_idat_length(4294967295UL) is Err(_), content="true",
  )
}
