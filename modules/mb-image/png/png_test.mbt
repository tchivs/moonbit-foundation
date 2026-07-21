///|
fn png_test_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=128UL,
    max_output_bytes=64UL,
    max_width=4UL,
    max_height=4UL,
    max_pixels=16UL,
    max_work=128UL,
  )
}

///|
test "PNG public probe matrix is caller-owned and bounded" {
  let decoder = PngDecoder::new()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=8UL, allocations=1UL, allocation_size=8UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    ),
  )
  let owner = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n",
    budget,
  ).unwrap()
  inspect(
    @codec.ImageDecoder::probe(
      decoder, owner.view().subview(0UL, 4UL).unwrap(), png_test_limits(),
      @error.Diagnostics::new(),
    ).unwrap() == @codec.ProbeOutcome::NeedMore(8UL),
    content="true",
  )
  let non_png = @bytes.OwnedBytes::from_bytes(
    b"\x00PNG\r\n\x1a\n",
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=8UL,
        allocations=1UL,
        allocation_size=8UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  inspect(@codec.ImageDecoder::probe(decoder, non_png.view(), png_test_limits(), @error.Diagnostics::new()).unwrap() == @codec.ProbeOutcome::NoMatch, content="true")
  inspect(@codec.ImageDecoder::probe(decoder, owner.view(), png_test_limits(), @error.Diagnostics::new()).unwrap() == @codec.ProbeOutcome::Match, content="true")
  let limited = @codec.ImageDecoder::probe(
    decoder, owner.view(),
    @codec.CodecLimits::new(max_probe_bytes=7UL, max_input_bytes=128UL, max_output_bytes=64UL, max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=128UL),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(limited.category() == @error.ErrorCategory::Resource, content="true")
  inspect(limited.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(limited.context() == Some("probe-bytes"), content="true")
}

///|
test "PNG decoder rejects a signature-only forward reader before capability" {
  let source = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n",
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=8UL,
        allocations=1UL,
        allocation_size=8UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(source.view())
  let error = @codec.ImageDecoder::decode(
    PngDecoder::new(),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    png_test_limits(),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=128UL,
        allocations=1UL,
        allocation_size=64UL,
        width=4UL,
        height=4UL,
        pixels=16UL,
        depth=0UL,
        work=128UL,
      ),
    ),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(
    error.code() == @error.ErrorCode::UnexpectedEndOfStream,
    content="true",
  )
}

///|
test "PNG decoder decodes a stored zlib RGB scanline atomically" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=source.length().to_uint64(), allocations=1UL,
        allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
        pixels=0UL, depth=0UL, work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    ),
  )
  let before = budget.remaining()
  let diagnostics = @error.Diagnostics::new()
  let result = @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    png_test_limits(), budget, diagnostics,
  ).unwrap()
  inspect(result.image().view().get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x12'")
  inspect(result.image().view().get_byte(0UL, 0UL, 1UL).unwrap(), content="b'\\x34'")
  inspect(result.image().view().get_byte(0UL, 0UL, 2UL).unwrap(), content="b'\\x56'")
  inspect(before.bytes() > budget.remaining().bytes(), content="true")
  inspect(diagnostics.length(), content="0")
}

///|
test "PNG decoder retains a declared sRGB rendering intent" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x01sRGB\x03\x37\xc7\x4d\x53\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=source.length().to_uint64(), allocations=1UL,
      allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let result = match @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=129UL, allocations=2UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ) {
    Err(error) => fail("sRGB decode failed: " + error.context().unwrap())
    Ok(value) => value
  }
  let metadata = result.image().metadata()
  inspect(metadata.space() == @color.ColorSpaceIdentity::Srgb, content="true")
  inspect(metadata.transfer() == @color.TransferIdentity::EncodedSrgb, content="true")
  inspect(metadata.profile().is_builtin_srgb(), content="true")
  inspect(metadata.opaque_metadata().length(), content="1")
  inspect(metadata.opaque_metadata().entry(0).unwrap().value().get(0UL).unwrap(), content="b'\\x03'")
}

///|
test "PNG decoder retains legacy non-sRGB declarations without relabelling samples" {
  let prefix = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde"
  let idat_and_end = b"\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let source = prefix + b"\x00\x00\x00\x04gAMA\x00\x01\x86\xa0\x31\xe8\x96\x5f" + idat_and_end
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=source.length().to_uint64(), allocations=1UL,
      allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let result = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=128UL, allocations=3UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap()
  let metadata = result.image().metadata()
  inspect(metadata.transfer() == @color.TransferIdentity::LinearSrgb, content="true")
  inspect(!metadata.profile().is_builtin_srgb(), content="true")
  inspect(metadata.opaque_metadata().length(), content="1")
  let entry = metadata.opaque_metadata().entry(0).unwrap()
  inspect(entry.canonical_key() == "png:legacy:gamma", content="true")
  inspect(entry.value().get(0UL).unwrap(), content="b'\\x00'")
  inspect(result.image().view().get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x12'")
}

///|
test "PNG decoder rejects a colour declaration after IDAT" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x01sRGB\x00\xae\xce\x1c\xe9\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=source.length().to_uint64(), allocations=1UL,
      allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let error = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context() == Some("png-colour-order"), content="true")
}

///|
test "PNG exact input ceiling permits EOF but an actual trailing byte is limited" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x00IDAT\x35\xaf\x06\x1e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  inspect(source.length(), content="57")
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=57UL, max_output_bytes=64UL,
    max_width=4UL, max_height=4UL, max_pixels=16UL, max_work=128UL,
  )
  let budget = @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
    height=4UL, pixels=16UL, depth=0UL, work=128UL,
  ))
  let diagnostics = @error.Diagnostics::new()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=57UL, allocations=1UL, allocation_size=57UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  let exact = @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    limits, budget, diagnostics,
  ).unwrap_err()
  inspect(exact.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(exact.context() == Some("zlib-truncated"), content="true")
  inspect(diagnostics.length(), content="0")

  let trailing_owner = @bytes.OwnedBytes::from_bytes(
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x00IDAT\x35\xaf\x06\x1e\x00\x00\x00\x00IEND\xae\x42\x60\x82\x00",
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=58UL, allocations=1UL, allocation_size=58UL, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let trailing_reader = @io.MemoryReader::new(trailing_owner.view())
  let limited = @codec.ImageDecoder::decode(
    PngDecoder::new(), trailing_reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    limits,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=128UL, allocations=1UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(limited.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(limited.context() == Some("zlib-truncated"), content="true")
}

///|
fn png_test_remaining_unchanged(
  before : @budget.ResourceLimits,
  after : @budget.ResourceLimits,
) -> Bool {
  before.bytes() == after.bytes() &&
  before.allocations() == after.allocations() &&
  before.allocation_size() == after.allocation_size() &&
  before.width() == after.width() &&
  before.height() == after.height() &&
  before.pixels() == after.pixels() &&
  before.depth() == after.depth() &&
  before.work() == after.work()
}

///|
fn png_test_limits_from_generated(item : PngGeneratedCase) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=item.limits.probe,
    max_input_bytes=item.limits.input,
    max_output_bytes=item.limits.output,
    max_width=item.limits.width,
    max_height=item.limits.height,
    max_pixels=item.limits.pixels,
    max_work=item.limits.work,
  )
}

///|
fn png_test_budget_from_generated(item : PngGeneratedCase) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=item.budget.bytes, allocations=item.budget.allocations,
    allocation_size=item.budget.allocation_size, width=item.budget.width,
    height=item.budget.height, pixels=item.budget.pixels,
    depth=item.budget.depth, work=item.budget.work,
  ))
}

///|
fn _png_legacy_phase20_matrix() -> Unit raise Error {
  for item in _generated_png_public_cases() {
    let length = item.bytes.length().to_uint64()
    let owner = @bytes.OwnedBytes::from_bytes(
      item.bytes,
      @budget.Budget::new(@budget.ResourceLimits::new(
        bytes=length, allocations=1UL, allocation_size=length, width=0UL,
        height=0UL, pixels=0UL, depth=0UL, work=0UL,
      )),
    ).unwrap()
    let reader = @io.MemoryReader::new(owner.view())
    let budget = png_test_budget_from_generated(item)
    let before = budget.remaining()
    let diagnostics = @error.Diagnostics::new()
    let error = @codec.ImageDecoder::decode(
      PngDecoder::new(), reader as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=item.preserve_opaque_metadata,
      ),
      png_test_limits_from_generated(item),
      budget, diagnostics,
    ).unwrap_err()
    if item.code == "unexpected-end" {
      inspect(error.code() == @error.ErrorCode::UnexpectedEndOfStream, content="true")
    } else if item.code == "budget-exceeded" {
      inspect(error.category() == @error.ErrorCategory::Resource, content="true")
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    } else if item.code == "capability-unavailable" {
      if item.context == "opaque-metadata-preservation" {
        inspect(error.category() == @error.ErrorCategory::Capability, content="true")
        inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
      } else {
        if error.context() != Some("zlib-truncated") { fail("legacy PNG case: " + item.id + ": " + error.context().unwrap()) }
        inspect(error.category() == @error.ErrorCategory::Data, content="true")
        inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
        inspect(error.context() == Some("zlib-truncated"), content="true")
      }
    } else {
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
      inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
    }
    if item.code != "unexpected-end" &&
      !(item.code == "capability-unavailable" && item.context != "opaque-metadata-preservation") &&
      error.context() != Some(item.context) {
      fail("generated PNG context mismatch: " + item.id)
    }
    if item.immutable_caller_state {
      inspect(png_test_remaining_unchanged(before, budget.remaining()), content="true")
      inspect(diagnostics.length(), content="0")
    }
  }
}

///|
fn png_test_decode_vector(item : PngDecodeVector) -> Result[@codec.DecodeResult, @error.CoreError] {
  let length = item.bytes.length().to_uint64()
  let source = @bytes.OwnedBytes::from_bytes(
    item.bytes,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=length, allocations=1UL, allocation_size=length, width=0UL,
      height=0UL, pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let reader = @io.MemoryReader::new(source.view())
  @codec.ImageDecoder::decode(
    PngDecoder::new(), reader as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=item.max_output, max_width=64UL, max_height=16UL, max_pixels=1024UL, max_work=item.max_work),
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=item.budget_bytes, allocations=item.budget_allocations, allocation_size=1024UL, width=64UL, height=16UL, pixels=1024UL, depth=0UL, work=item.max_work)),
    @error.Diagnostics::new(),
  )
}

///|
test "generated PNG decode vectors execute fixed and dynamic streams through PngDecoder" {
  for item in _generated_png_decode_cases() {
    let decoded = png_test_decode_vector(item)
    if item.outcome == "accepted" {
      let result = match decoded { Ok(value) => value; Err(error) => fail("generated PNG accepted case failed: " + item.id + ": " + error.context().unwrap()) }
      let descriptor = result.image().descriptor()
      if descriptor.width() != item.width || descriptor.height() != item.height || descriptor.format().channel_count() != item.channels {
        fail("generated PNG descriptor mismatch: " + item.id)
      }
      if item.srgb_intent >= 0 {
        let metadata = descriptor.metadata()
        if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
          metadata.transfer() != @color.TransferIdentity::EncodedSrgb ||
          !metadata.profile().is_builtin_srgb() ||
          metadata.opaque_metadata().length() != 1 ||
          metadata.opaque_metadata().entry(0).unwrap().value().get(0UL).unwrap().to_int() != item.srgb_intent {
          fail("generated PNG sRGB metadata mismatch: " + item.id)
        }
      }
      if item.metadata_key != "" {
        let metadata = descriptor.metadata()
        if metadata.transfer() != @color.TransferIdentity::LinearSrgb ||
          metadata.profile().is_builtin_srgb() ||
          metadata.opaque_metadata().length() != 1 {
          fail("generated PNG non-sRGB identity mismatch: " + item.id)
        }
        let entry = metadata.opaque_metadata().entry(0).unwrap()
        if entry.canonical_key() != item.metadata_key || entry.value().length() != item.metadata_value.length().to_uint64() {
          fail("generated PNG non-sRGB metadata shape mismatch: " + item.id)
        }
        for index = 0UL; index < item.metadata_value.length().to_uint64(); index = index + 1UL {
          if entry.value().get(index).unwrap() != item.metadata_value[index.to_int()] {
            fail("generated PNG non-sRGB metadata value mismatch: " + item.id)
          }
        }
        if item.icc_profile_length > 0UL {
          let profile = metadata.profile().opaque_profile().unwrap()
          if profile.tag().value() != "icc" || profile.length() != item.icc_profile_length {
            fail("generated PNG ICC profile mismatch: " + item.id)
          }
        }
      }
      let view = result.image().view()
      for y = 0UL; y < item.height; y = y + 1UL {
        for x = 0UL; x < item.width; x = x + 1UL {
          for channel = 0UL; channel < item.channels; channel = channel + 1UL {
            let index = ((y * item.width + x) * item.channels + channel).to_int()
            if view.get_byte(x, y, channel).unwrap() != item.pixels[index] {
              fail("generated PNG pixel mismatch: " + item.id + " at " + x.to_string() + "," + y.to_string() + "," + channel.to_string() + " got " + view.get_byte(x, y, channel).unwrap().to_int().to_string() + " expected " + item.pixels[index].to_int().to_string())
            }
          }
        }
      }
      if item.comparison_group != "" && !item.baseline {
        for baseline in _generated_png_decode_cases() {
          if baseline.comparison_group == item.comparison_group && baseline.baseline {
            let baseline_result = png_test_decode_vector(baseline).unwrap()
            let baseline_descriptor = baseline_result.image().descriptor()
            if baseline_descriptor.width() != descriptor.width() || baseline_descriptor.height() != descriptor.height() || baseline_descriptor.format().channel_count() != descriptor.format().channel_count() {
              fail("generated PNG accepted boundary descriptor mismatch: " + item.id)
            }
            let baseline_view = baseline_result.image().view()
            for y = 0UL; y < item.height; y = y + 1UL {
              for x = 0UL; x < item.width; x = x + 1UL {
                for channel = 0UL; channel < item.channels; channel = channel + 1UL {
                  if baseline_view.get_byte(x, y, channel).unwrap() != view.get_byte(x, y, channel).unwrap() {
                    fail("generated PNG accepted boundary pixel mismatch: " + item.id)
                  }
                }
              }
            }
          }
        }
      }
    } else {
      let error = decoded.unwrap_err()
      if item.category == "resource" {
        if error.category() != @error.ErrorCategory::Resource { fail("generated PNG resource category mismatch: " + item.id) }
      } else if item.category == "capability" {
        if error.category() != @error.ErrorCategory::Capability { fail("generated PNG capability category mismatch: " + item.id) }
      } else if item.category == "data" {
        if error.category() != @error.ErrorCategory::Data {
          let actual = match error.category() {
            @error.ErrorCategory::InvalidInput => "invalid-input"
            @error.ErrorCategory::Data => "data"
            @error.ErrorCategory::State => "state"
            @error.ErrorCategory::Resource => "resource"
            @error.ErrorCategory::Capability => "capability"
            @error.ErrorCategory::Host => "host"
          }
          fail("generated PNG data category mismatch: " + item.id + ": " + actual + ": " + error.context().unwrap())
        }
      } else { fail("generated PNG unknown error category: " + item.id) }
      if item.code == "budget-exceeded" {
        inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
      } else if item.code == "capability-unavailable" {
        inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
      } else if item.code == "invalid-encoding" {
        inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
      } else { fail("generated PNG unknown error code: " + item.id) }
      if error.context() != Some(item.context) { fail("generated PNG context mismatch: " + item.id + ": " + error.context().unwrap()) }
      if item.comparison_group != "" && !item.baseline {
        for baseline in _generated_png_decode_cases() {
          if baseline.comparison_group == item.comparison_group && baseline.baseline {
            let baseline_error = png_test_decode_vector(baseline).unwrap_err()
            if baseline_error.category() != error.category() || baseline_error.code() != error.code() || baseline_error.context() != error.context() {
              fail("generated PNG hostile boundary mismatch: " + item.id)
            }
          }
        }
      }
    }
  }
}
