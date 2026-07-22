///|
fn png_encode_budget(
  bytes? : UInt64 = 512UL,
  work? : UInt64 = 1024UL,
) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes~, allocations=8UL, allocation_size=bytes, width=64UL,
    height=64UL, pixels=4096UL, depth=0UL, work~,
  ))
}

///|
fn png_encode_limits(
  output? : UInt64 = 512UL,
  work? : UInt64 = 1024UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=512UL, max_output_bytes=output,
    max_width=64UL, max_height=64UL, max_pixels=4096UL, max_work=work,
  )
}

///|
fn png_encode_image(
  channels : UInt64,
  pixels : Bytes,
  include_opaque? : Bool = false,
  width? : UInt64 = 1UL,
  height? : UInt64 = 1UL,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, height,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels * width * height, channels * width, channels * width, 1UL, 1UL, width, height).unwrap()],
    channels * width * height,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        if include_opaque { [("test", "marker", "raw", b"x")] } else { [] },
        @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ),
        png_encode_budget(bytes=1UL, work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=channels * width * height, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for index = 0UL; index < channels; index = index + 1UL {
          view.set_byte(x, y, index, pixels[((y * width + x) * channels + index).to_int()]).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_encode_prefix(writer : @io.MemoryWriter) -> Bytes {
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_encode_with(
  encoder : PngEncoder,
  image : @storage.OwnedImage,
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let result = @codec.ImageEncoder::encode(
    encoder, image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
fn png_adam7_encode_with(
  encoder : PngEncoder,
  image : @storage.OwnedImage,
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_encode_budget(bytes=1048576UL, work=0UL),
  ).unwrap()
  let result = @codec.ImageEncoder::encode(
    encoder, image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_adam7_admission_limits(), png_encode_budget(bytes=1048576UL, work=1048576UL),
    @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
fn png_encode(image : @storage.OwnedImage) -> (@codec.EncodeResult, @io.MemoryWriter) {
  png_encode_with(PngEncoder::new(), image)
}

///|
fn png_adam7_same_remaining(
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

///| A compact multi-pass source whose component at `(x, y, channel)` is its
/// row-major byte offset.  The same source shape is used by the chunk tests.
fn png_adam7_admission_image(
  channels : UInt64,
  include_opaque? : Bool = false,
) -> @storage.OwnedImage {
  let image = png_encode_image(
    channels, Bytes::from_array(Array::make((channels * 25UL).to_int(), b'\x00')),
    include_opaque=include_opaque, width=5UL, height=5UL,
  )
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
fn png_adam7_admission_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
  width? : UInt64 = 64UL,
  height? : UInt64 = 64UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=width, max_height=height, max_pixels=4096UL, max_work=work,
  )
}

///| Eager all-strategy Adam7 construction must leave both Writer and every
/// caller-owned budget ledger field untouched when preflight rejects it.
fn png_adam7_eager_admission_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let budget = png_encode_budget(bytes=1048576UL, work=work)
    let before = budget.remaining()
    let writer = @io.MemoryWriter::new(
      1048576UL, png_encode_budget(bytes=1048576UL, work=0UL),
    ).unwrap()
    ignore(@codec.ImageEncoder::encode(
      PngEncoder::new_with_all_strategies(
        strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      ), image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      limits, budget, @error.Diagnostics::new(),
    ).unwrap_err())
    if writer.position() != 0UL || !png_adam7_same_remaining(before, budget.remaining()) {
      abort("png adam7 eager admission atomic")
    }
  }
}

///|
fn png_filter_strategy_decode_matches_source(
  bytes : Bytes,
  source : @storage.OwnedImage,
) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_encode_budget(bytes=1048576UL, work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ), png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let expected = source.view()
  if restored.width() != expected.width() || restored.height() != expected.height() ||
    restored.format().channel_count() != expected.format().channel_count() {
    abort("png filter strategy decoded descriptor")
  }
  for y = 0UL; y < expected.height(); y = y + 1UL {
    for x = 0UL; x < expected.width(); x = x + 1UL {
      for channel = 0UL; channel < expected.format().channel_count(); channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() !=
          expected.get_byte(x, y, channel).unwrap() {
          abort("png filter strategy decoded component")
        }
      }
    }
  }
}

///|
fn png_adaptive_evidence_rgb8_horizontal_candidate_image(width : UInt64) -> @storage.OwnedImage {
  let image = png_encode_image(
    3UL, Bytes::from_array(Array::make((width * 3UL).to_int(), b'\x00')),
    width=width,
  )
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      view.set_byte(x, 0UL, 0UL, x.to_byte()).unwrap()
      view.set_byte(x, 0UL, 1UL, (x + 64UL).to_byte()).unwrap()
      view.set_byte(x, 0UL, 2UL, (x + 128UL).to_byte()).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_rgb8_diagonal_image() -> @storage.OwnedImage {
  let image = png_encode_image(
    3UL, Bytes::from_array(Array::make(32 * 4 * 3, b'\x00')),
    width=32UL, height=4UL,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 4UL; y = y + 1UL {
      for x = 0UL; x < 32UL; x = x + 1UL {
        let value = x + y
        view.set_byte(x, y, 0UL, value.to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (value + 64UL).to_byte()).unwrap()
        view.set_byte(x, y, 2UL, (value + 128UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_straight_rgba8_candidate_image(
  width : UInt64,
  height : UInt64,
) -> @storage.OwnedImage {
  let image = png_encode_image(
    4UL, Bytes::from_array(Array::make((width * height * 4UL).to_int(), b'\x00')),
    width=width, height=height,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        let value = 3UL * x + y
        view.set_byte(x, y, 0UL, value.to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (value + 64UL).to_byte()).unwrap()
        view.set_byte(x, y, 2UL, (value + 128UL).to_byte()).unwrap()
        view.set_byte(x, y, 3UL, 200UL.to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_straight_rgba8_diagonal_image() -> @storage.OwnedImage {
  let image = png_encode_image(
    4UL, Bytes::from_array(Array::make(16 * 16 * 4, b'\x00')),
    width=16UL, height=16UL,
  )
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 16UL; y = y + 1UL {
      for x = 0UL; x < 16UL; x = x + 1UL {
        let value = x + y
        view.set_byte(x, y, 0UL, value.to_byte()).unwrap()
        view.set_byte(x, y, 1UL, (value + 64UL).to_byte()).unwrap()
        view.set_byte(x, y, 2UL, (value + 128UL).to_byte()).unwrap()
        view.set_byte(x, y, 3UL, 200UL.to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_adaptive_evidence_adaptive_beats_none(image : @storage.OwnedImage) -> Bytes {
  let none = png_adaptive_evidence_encode(image, PngFilterStrategy::None)
  let adaptive = png_adaptive_evidence_encode(image, PngFilterStrategy::Adaptive)
  if adaptive.length() >= none.length() {
    abort("png adaptive evidence strict win")
  }
  adaptive
}

///|
fn png_adaptive_evidence_encode(
  image : @storage.OwnedImage,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(
    4096UL, png_encode_budget(bytes=4096UL, work=0UL),
  ).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(
      PngCompressionStrategy::FixedOrStored, filter_strategy,
    ), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(output=4096UL, work=1048576UL),
    png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
  ).unwrap())
  png_encode_prefix(writer)
}

///|
test "PNG adaptive filter evidence candidate RGB8 R1 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_rgb8_horizontal_candidate_image(32UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate RGB8 R2 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_rgb8_horizontal_candidate_image(64UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate RGB8 R3 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(png_adaptive_evidence_rgb8_diagonal_image()))
}

///|
test "PNG adaptive filter evidence candidate straight-RGBA8 A1 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_straight_rgba8_candidate_image(16UL, 8UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate straight-RGBA8 A2 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_straight_rgba8_candidate_image(32UL, 4UL),
  ))
}

///|
test "PNG adaptive filter evidence candidate straight-RGBA8 A3 strict win" {
  ignore(png_adaptive_evidence_adaptive_beats_none(
    png_adaptive_evidence_straight_rgba8_diagonal_image(),
  ))
}

///| Selected CandidateSelection winner R1: 32x1 `(x, x+64, x+128)` RGB8.
fn png_adaptive_evidence_rgb8_horizontal_image() -> @storage.OwnedImage {
  png_adaptive_evidence_rgb8_horizontal_candidate_image(32UL)
}

///| Selected CandidateSelection winner A1: 16x8 `(3x+y, 3x+y+64,
///| 3x+y+128, 200)` straight-RGBA8.
fn png_adaptive_evidence_straight_rgba8_vertical_image() -> @storage.OwnedImage {
  png_adaptive_evidence_straight_rgba8_candidate_image(16UL, 8UL)
}

///|
test "PNG adaptive filter evidence RGB8 horizontal eager strictly beats None and decodes completely" {
  let source = png_adaptive_evidence_rgb8_horizontal_image()
  png_filter_strategy_decode_matches_source(
    png_adaptive_evidence_adaptive_beats_none(source), source,
  )
}

///|
test "PNG adaptive filter evidence straight-RGBA8 vertical eager strictly beats None and decodes completely" {
  let source = png_adaptive_evidence_straight_rgba8_vertical_image()
  png_filter_strategy_decode_matches_source(
    png_adaptive_evidence_adaptive_beats_none(source), source,
  )
}

///| Every public compression strategy may opt into bounded Adaptive filtering
/// while preserving complete-input RGB8 and straight-RGBA8 fidelity.
test "PNG adaptive combined eager routes" {
  let rgb = png_encode_image(
    3UL, b"\x0a\x0c\x0c\x0a\x0a\x0c\x0b\x0c\x0a\x0c\x0a\x0b",
    width=2UL, height=2UL,
  )
  let rgba = png_encode_image(
    4UL, b"\x03\x05\x07\xff\x04\x06\x08\xfe\x05\x07\x09\xfd\x06\x08\x0a\xfc",
    width=2UL, height=2UL,
  )
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for image in [rgb, rgba] {
      let (_, writer) = png_encode_with(
        PngEncoder::new_with_strategies(strategy, PngFilterStrategy::Adaptive), image,
      )
      png_filter_strategy_decode_matches_source(png_encode_prefix(writer), image)
    }
  }
}

///|
test "PNG filter strategy eager frozen compatibility vectors" {
  let rgb = png_encode_image(3UL, b"\x00\x01\x02")
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, rgb_default_writer) = png_encode_with(PngEncoder::new(), rgb)
  let (_, rgb_configured_writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::Stored), rgb,
  )
  let (_, rgb_adaptive_writer) = png_encode_with(
    PngEncoder::new_with_filter_strategy(PngFilterStrategy::Adaptive), rgb,
  )
  for bytes in [png_encode_prefix(rgb_default_writer), png_encode_prefix(rgb_configured_writer), png_encode_prefix(rgb_adaptive_writer)] {
    inspect(bytes == rgb_stored, content="true")
    png_filter_strategy_decode_matches_source(bytes, rgb)
  }

  let rgba = png_encode_image(4UL, b"\x00\x01\x02\x03")
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let (_, rgba_default_writer) = png_encode_with(PngEncoder::new(), rgba)
  let (_, rgba_configured_writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::Stored), rgba,
  )
  let (_, rgba_adaptive_writer) = png_encode_with(
    PngEncoder::new_with_filter_strategy(PngFilterStrategy::Adaptive), rgba,
  )
  for bytes in [png_encode_prefix(rgba_default_writer), png_encode_prefix(rgba_configured_writer), png_encode_prefix(rgba_adaptive_writer)] {
    inspect(bytes == rgba_stored, content="true")
    png_filter_strategy_decode_matches_source(bytes, rgba)
  }

  for channels in [3UL, 4UL] {
    let image = png_encode_image(
      channels, Bytes::from_array(Array::make((channels * 32UL).to_int(), b'\xaa')),
      width=32UL,
    )
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let (_, fixed_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
    )
    let (_, dynamic_fallback_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored), image,
    )
    for bytes in [png_encode_prefix(fixed_writer), png_encode_prefix(dynamic_fallback_writer)] {
      inspect(bytes == fixed, content="true")
      png_filter_strategy_decode_matches_source(bytes, image)
    }
  }

}

///|
test "PNG compression strategy eager factories encode supported images" {
  for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
    let image = png_encode_image(3UL, b"\x12\x34\x56")
    let (_, writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(strategy), image,
    )
    let bytes = png_encode_prefix(writer)
    let owner = @bytes.OwnedBytes::from_bytes(
      bytes, png_encode_budget(bytes=512UL, work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x12', content="true")
  }
}

///|
test "PNG fixed-or-stored eager selects a final fixed DEFLATE block" {
  let pixels = Bytes::from_array(Array::make(96, b'\xaa'))
  let image = png_encode_image(3UL, pixels, width=32UL)
  let (_, writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
  )
  let bytes = png_encode_prefix(writer)
  // The first DEFLATE byte follows the two-byte zlib header at the IDAT payload.
  inspect((bytes[43] & b'\x07') == b'\x03', content="true")
  let owner = @bytes.OwnedBytes::from_bytes(bytes, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap()
  inspect(decoded.image().view().get_byte(31UL, 0UL, 2UL).unwrap() == b'\xaa', content="true")
}

///| The opt-in strategy has one strict Dynamic winner and exposes final BTYPE=10
/// without changing either legacy strategy.
test "PNG dynamic eager preserves non-winning complete-PNG fallback" {
  let image = png_encode_image(3UL, Bytes::from_array(Array::make(96, b'\xaa')), width=32UL)
  let (_, writer) = png_encode_with(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored), image,
  )
  let bytes = png_encode_prefix(writer)
  inspect((bytes[43] & b'\x07') == b'\x03', content="true")
}

///|
test "PNG dynamic strategy eager factory freezes compatibility routes" {
  let (_, rgb_stored_writer) = png_encode(png_encode_image(3UL, b"\x12\x34\x56"))
  inspect(
    png_encode_prefix(rgb_stored_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let (_, rgba_stored_writer) = png_encode(png_encode_image(4UL, b"\x04\x05\x06\x07"))
  inspect(
    png_encode_prefix(rgba_stored_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x04\x05\x06\x07\x00\x37\x00\x17\x05\x48\x0f\xc7\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  for channels in [3UL, 4UL] {
    let image = png_encode_image(
      channels, Bytes::from_array(Array::make((channels * 32UL).to_int(), b'\xaa')),
      width=32UL,
    )
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let (_, fixed_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
    )
    let (_, dynamic_writer) = png_encode_with(
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored), image,
    )
    let dynamic = png_encode_prefix(dynamic_writer)
    inspect(png_encode_prefix(fixed_writer) == fixed, content="true")
    inspect(dynamic == fixed, content="true")
    inspect((fixed[43] & b'\x07') == b'\x03', content="true")
    let owner = @bytes.OwnedBytes::from_bytes(
      dynamic, png_encode_budget(bytes=512UL, work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(31UL, 0UL, channels - 1UL).unwrap() == b'\xaa', content="true")
  }
}

///|
test "PNG encoder emits canonical RGB and RGBA stored-deflate bytes" {
  let (rgb_result, rgb_writer) = png_encode(png_encode_image(3UL, b"\x12\x34\x56"))
  inspect(
    png_encode_prefix(rgb_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  inspect(rgb_result.bytes_written(), content="72")
  let (_, rgba_writer) = png_encode(png_encode_image(4UL, b"\x04\x05\x06\x07"))
  inspect(png_encode_prefix(rgba_writer)[25] == b'\x06', content="true")
}

///|
test "PNG compression strategy legacy eager constructors retain frozen stored bytes" {
  let (_, rgb_writer) = png_encode(png_encode_image(3UL, b"\x12\x34\x56"))
  inspect(
    png_encode_prefix(rgb_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let (_, rgba_writer) = png_encode(png_encode_image(4UL, b"\x04\x05\x06\x07"))
  inspect(
    png_encode_prefix(rgba_writer) ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x04\x05\x06\x07\x00\x37\x00\x17\x05\x48\x0f\xc7\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
}

///| Generated RGB8/RGBA8 Adam7 public encodings must round-trip exactly while
///| every legacy and explicit-None factory retains its frozen method-0 bytes.
test "PNG Adam7 public eager fidelity and frozen None compatibility" {
  let rgb = png_encode_image(3UL, b"\x12\x34\x56")
  let rgba = png_encode_image(4UL, b"\x04\x05\x06\x07")
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x04\x05\x06\x07\x00\x37\x00\x17\x05\x48\x0f\xc7\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  for image in [rgb, rgba] {
    let expected = if image.view().format().channel_count() == 3UL {
      rgb_stored
    } else {
      rgba_stored
    }
    for encoder in [
      PngEncoder::new(),
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::Stored),
      PngEncoder::new_with_filter_strategy(PngFilterStrategy::None),
      PngEncoder::new_with_filter_strategy(PngFilterStrategy::Adaptive),
      PngEncoder::new_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::None),
      PngEncoder::new_with_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive),
      PngEncoder::new_with_interlace_strategy(PngInterlaceStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, PngInterlaceStrategy::None),
    ] {
      let (_, writer) = png_encode_with(encoder, image)
      let bytes = png_encode_prefix(writer)
      inspect(bytes == expected && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let image = png_encode_image(
      channels, Bytes::from_array(Array::make((channels * 32UL).to_int(), b'\xaa')), width=32UL,
    )
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    for encoder in [
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
      PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
      PngEncoder::new_with_strategies(PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None),
      PngEncoder::new_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None),
      PngEncoder::new_with_all_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None),
    ] {
      let (_, writer) = png_encode_with(encoder, image)
      let bytes = png_encode_prefix(writer)
      inspect(bytes == fixed && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let image = png_adam7_admission_image(channels)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      let encoder = PngEncoder::new_with_all_strategies(
        strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      )
      let (_, writer) = png_adam7_encode_with(encoder, image)
      let bytes = png_encode_prefix(writer)
      inspect(bytes[28] == b'\x01' && bytes[0] == b'\x89' &&
        bytes[bytes.length() - 1] == b'\x82', content="true")
      png_filter_strategy_decode_matches_source(bytes, image)
    }
  }
}

///| Every all-strategy Adam7 eager route rejects capability, geometry, output,
/// codec-work, and caller-budget failures before its Writer becomes observable.
test "PNG Adam7 eager all-strategy admission is atomic" {
  for channels in [3UL, 4UL] {
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels, include_opaque=true),
      png_adam7_admission_limits(), 1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(width=4UL),
      1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(output=1UL),
      1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(work=1UL),
      1048576UL,
    )
    png_adam7_eager_admission_reject(
      png_adam7_admission_image(channels), png_adam7_admission_limits(), 1UL,
    )
  }
}

///|
test "PNG encoder round trips RGB and straight RGBA pixels" {
  for image in [png_encode_image(3UL, b"\x12\x34\x56"), png_encode_image(4UL, b"\x04\x05\x06\x07")] {
    let (_, writer) = png_encode(image)
    let bytes = png_encode_prefix(writer)
    let owner = @bytes.OwnedBytes::from_bytes(bytes, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
      png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap()
    for channel = 0UL; channel < image.view().format().channel_count(); channel = channel + 1UL {
      inspect(decoded.image().view().get_byte(0UL, 0UL, channel).unwrap() == image.view().get_byte(0UL, 0UL, channel).unwrap(), content="true")
    }
  }
}

///|
test "PNG encoder rejects output and budget limits before Writer output" {
  let image = png_encode_image(3UL, b"\x12\x34\x56")
  let writer = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(output=71UL), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context() == Some("output-bytes"), content="true")
  inspect(writer.position(), content="0")
  let restricted = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  inspect(@codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), restricted as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(work=71UL), @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(restricted.position(), content="0")
  let semantic_writer = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  let semantic = @codec.ImageEncoder::encode(
    PngEncoder::new(), png_encode_image(3UL, b"\x12\x34\x56", include_opaque=true).view(),
    semantic_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(semantic.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
  inspect(semantic_writer.position(), content="0")
}

///|
test "PNG encoder rejects retained non-sRGB metadata before output" {
  let source = b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x04gAMA\x00\x01\x86\xa0\x31\xe8\x96\x5f\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x12\x34\x56\x00\xf8\x00\x9d\xf8\xd7\x64\x8c\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let owner = @bytes.OwnedBytes::from_bytes(source, png_encode_budget(bytes=source.length().to_uint64(), work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(bytes=512UL), @error.Diagnostics::new(),
  ).unwrap()
  inspect(!decoded.image().descriptor().supports_reference_operations(), content="true")
  let writer = @io.MemoryWriter::new(128UL, png_encode_budget(bytes=128UL, work=0UL)).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), decoded.image().view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
  inspect(error.context() == Some("builtin-encoded-srgb-required"), content="true")
  inspect(writer.position(), content="0")
}

///|
struct PngEncodeScriptWriter {
  mut completed : UInt64
  mut calls : UInt64
  accepted : Array[Byte]
  mut one_byte_calls : Bool
  fail_at : UInt64
}

///|
impl @io.Writer for PngEncodeScriptWriter with fn write(self, source) {
  self.calls = self.calls + 1UL
  if source.length() != 1UL { self.one_byte_calls = false }
  if self.completed >= self.fail_at {
    @io.WriteOutcome::Failed(@error.CoreError::new(
      @error.ErrorCategory::Host, @error.ErrorCode::HostOperationFailed,
      operation="png-scripted-write", requested=91UL, completed=17UL,
      limit=23UL, context="scripted",
    ), 0UL)
  } else {
    self.accepted.push(source.get(0UL).unwrap())
    self.completed = self.completed + 1UL
    @io.WriteOutcome::Progress(1UL)
  }
}

///|
test "PNG encoder isolated four-target evidence preserves original Writer failure and accepted prefix" {
  let image = png_encode_image(3UL, b"\x12\x34\x56")
  let canonical = png_encode(image).1 |> png_encode_prefix
  let failed = PngEncodeScriptWriter::{
    completed: 0UL, calls: 0UL, accepted: [], one_byte_calls: true, fail_at: 43UL,
  }
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), failed as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Host, content="true")
  inspect(error.code() == @error.ErrorCode::HostOperationFailed, content="true")
  inspect(error.operation() == Some("png-scripted-write"), content="true")
  inspect(error.requested() == Some(91UL), content="true")
  inspect(error.completed() == Some(17UL), content="true")
  inspect(error.limit() == Some(23UL), content="true")
  inspect(error.context() == Some("scripted"), content="true")
  inspect(failed.completed == 43UL, content="true")
  inspect(failed.calls == 44UL, content="true")
  inspect(failed.one_byte_calls, content="true")
  let expected_prefix : Array[Byte] = []
  for index = 0; index < 43; index = index + 1 {
    expected_prefix.push(canonical[index])
  }
  inspect(Bytes::from_array(failed.accepted) == Bytes::from_array(expected_prefix), content="true")
}

///|
struct PngEncodeMalformedProgressWriter {
  progress : UInt64
  mut calls : UInt64
}

///|
impl @io.Writer for PngEncodeMalformedProgressWriter with fn write(self, _source) {
  self.calls = self.calls + 1UL
  @io.WriteOutcome::Progress(self.progress)
}

///|
test "PNG encoder rejects malformed direct one-byte Writer progress" {
  let image = png_encode_image(3UL, b"\x12\x34\x56")
  for progress in [0UL, 2UL] {
    let writer = PngEncodeMalformedProgressWriter::{ progress, calls: 0UL }
    let error = @codec.ImageEncoder::encode(
      PngEncoder::new(), image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::State, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    inspect(error.operation() == Some("png-encode-write"), content="true")
    inspect(error.requested() == Some(progress), content="true")
    inspect(error.completed() == Some(0UL), content="true")
    inspect(error.limit() == Some(1UL), content="true")
    inspect(writer.calls, content="1")
  }
}

///|
test "PNG fixed-or-stored public selected work charges once" {
  let image = png_encode_image(3UL, Bytes::from_array(Array::make(96, b'\xaa')), width=32UL)
  let generous = png_encode_budget(work=1048576UL)
  let before = generous.remaining()
  let writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(work=1048576UL), generous, @error.Diagnostics::new(),
  ).unwrap())
  let charged = before.work() - generous.remaining().work()
  inspect(charged > 0UL, content="true")
  let exact = png_encode_budget(work=charged)
  let exact_writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), exact_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(work=charged), exact, @error.Diagnostics::new(),
  ).unwrap())
  inspect(exact.remaining().work(), content="0")
  let one_less = png_encode_budget(work=charged - 1UL)
  let one_less_before = one_less.remaining()
  let rejected = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  inspect(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), rejected as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(work=charged), one_less, @error.Diagnostics::new(),
  ) is Err(_), content="true")
  inspect(rejected.position(), content="0")
  inspect(one_less.remaining().work() == one_less_before.work(), content="true")
}
