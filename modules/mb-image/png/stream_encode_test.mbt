///|
fn png_stream_test_budget(work? : UInt64 = 1048576UL) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL, allocations=16UL, allocation_size=1048576UL,
    width=70000UL, height=8UL, pixels=560000UL, depth=0UL, work~, 
  ))
}

///|
fn png_stream_test_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
  width? : UInt64 = 70000UL,
  height? : UInt64 = 8UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=width, max_height=height, max_pixels=560000UL, max_work=work,
  )
}

///|
fn png_stream_test_image(
  channels : UInt64,
  width? : UInt64 = 1UL,
  include_opaque? : Bool = false,
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
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < channels; channel = channel + 1UL {
          view.set_byte(x, y, channel, (y * channels * width + x * channels + channel).to_byte()).unwrap()
        }
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Packed one-channel Gray8 test image for the explicit caller-buffered route.
fn png_stream_gray8_image(
  pixels : Bytes,
  width? : UInt64 = 1UL,
  height? : UInt64 = 1UL,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, height,
    @model.ImageFormat::new(
      @model.ComponentType::U8, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(
      0UL, width * height, width, width, 1UL, 1UL, width, height,
    ).unwrap()],
    width * height,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        view.set_byte(x, y, 0UL, pixels[(y * width + x).to_int()]).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| The eager and chunk Gray8 fidelity cases use the same compact multi-row source.
fn png_stream_gray8_fidelity_image() -> @storage.OwnedImage {
  png_stream_gray8_image(
    b"\x00\x7f\xff\x12\xa5\x34\xc8\x56\xe1\x09\xab\xcd\x23\x89\xfe",
    width=5UL, height=3UL,
  )
}

///|
fn png_stream_gray16_image() -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    2UL, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
    4UL,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
    view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 0UL, b'\xcd').unwrap()
    view.set_component_byte(1UL, 0UL, 0UL, 1UL, b'\xab').unwrap()
    Ok(())
  }).unwrap()
  image
}

///| Gray16 corpora that force the selected DEFLATE route without retaining a
/// converted row: a flat stream has short-distance matches, while the five-byte
/// period defeats the bounded distance-1..4 matcher and favors Dynamic coding.
fn png_stream_gray16_replay_image(
  width : UInt64,
  periodic? : Bool = false,
) -> @storage.OwnedImage {
  let bytes = width * 2UL
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL,
    @model.ImageFormat::new(
      @model.ComponentType::U16, @model.ChannelOrder::Gray,
      @model.PlaneLayout::Packed, @model.Endianness::Little,
    ).unwrap(),
    [@model.PlaneDescriptor::new(0UL, bytes, bytes, bytes, 1UL, 1UL, width, 1UL).unwrap()],
    bytes,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      None, @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      let low = if periodic { (x * 2UL % 5UL).to_byte() } else { b'\x34' }
      let high = if periodic { ((x * 2UL + 1UL) % 5UL).to_byte() } else { b'\x12' }
      view.set_component_byte(x, 0UL, 0UL, 0UL, low).unwrap()
      view.set_component_byte(x, 0UL, 0UL, 1UL, high).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_test_eager(image : @storage.OwnedImage) -> Bytes {
  png_stream_test_eager_with_strategy(image, PngCompressionStrategy::Stored)
}

///|
fn png_stream_test_eager_with_strategy(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(strategy), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_test_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(strategy, filter_strategy), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_test_eager_with_all_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_all_strategies(strategy, filter_strategy, interlace_strategy), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_test_flat_image(channels : UInt64, width : UInt64) -> @storage.OwnedImage {
  let image = png_stream_test_image(channels, width=width)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, b'\xaa').unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Five periodic literal values deliberately exceed the A1 distance-1..4
/// matcher, making this a compact strict Dynamic candidate rather than a match
/// compression corpus.
fn png_stream_test_dynamic_image(width? : UInt64 = 128UL) -> @storage.OwnedImage {
  let image = png_stream_test_image(3UL, width=width)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, ((x * 3UL + channel) % 5UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///| Five periodic literal values deliberately exceed the retained distance-1..4
///| matcher for RGB8 and straight-RGBA8 corpus sources.
fn png_stream_test_dynamic_corpus_image(
  channels : UInt64,
  width? : UInt64 = 128UL,
) -> @storage.OwnedImage {
  let image = png_stream_test_image(channels, width=width)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, ((x * channels + channel) % 5UL).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_test_fixed_or_stored_corpus_decode_matches_source(
  bytes : Bytes,
  source : @storage.OwnedImage,
) -> Unit {
  let owner = @bytes.OwnedBytes::from_bytes(
    bytes, png_stream_test_budget(work=0UL),
  ).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let expected = source.view()
  if decoded.image().descriptor().width() != source.descriptor().width() ||
    decoded.image().descriptor().height() != source.descriptor().height() ||
    decoded.image().descriptor().format().channel_count() !=
      source.descriptor().format().channel_count() {
    abort("png fixed-or-stored corpus decoded descriptor")
  }
  for y = 0UL; y < expected.height(); y = y + 1UL {
    for x = 0UL; x < expected.width(); x = x + 1UL {
      for channel = 0UL; channel < expected.format().channel_count(); channel = channel + 1UL {
        if restored.get_byte(x, y, channel).unwrap() !=
          expected.get_byte(x, y, channel).unwrap() {
          abort("png fixed-or-stored corpus decoded component")
        }
      }
    }
  }
}

///|
fn png_stream_test_fixed_or_stored_corpus_case(source : @storage.OwnedImage) -> Unit {
  let stored = png_stream_test_eager_with_strategy(source, PngCompressionStrategy::Stored)
  let eager_first = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::FixedOrStored,
  )
  let eager_second = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::FixedOrStored,
  )
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    source.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  if eager_first.length() > stored.length() {
    abort("png fixed-or-stored corpus never-larger")
  }
  if eager_first.length() >= stored.length() {
    abort("png fixed-or-stored corpus win")
  }
  if eager_first != eager_second || eager_first != chunked {
    abort("png fixed-or-stored corpus determinism")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_first, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_second, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(chunked, source)
}

///| Public Dynamic evidence compares all strategy routes while retaining the
///| existing complete-input descriptor-and-component decode oracle.
fn png_stream_test_dynamic_corpus_case(source : @storage.OwnedImage) -> Unit {
  let stored = png_stream_test_eager_with_strategy(source, PngCompressionStrategy::Stored)
  let fixed = png_stream_test_eager_with_strategy(source, PngCompressionStrategy::FixedOrStored)
  let eager_first = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  let eager_second = png_stream_test_eager_with_strategy(
    source, PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    source.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  ignore(stored)
  if eager_first.length() > fixed.length() {
    abort("png dynamic corpus never-larger")
  }
  if eager_first.length() >= fixed.length() {
    abort("png dynamic corpus strict win")
  }
  if (eager_first[43] & b'\x07') != b'\x05' {
    abort("png dynamic corpus final dynamic block")
  }
  if eager_first != eager_second || eager_first != chunked {
    abort("png dynamic corpus determinism")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_first, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager_second, source)
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(chunked, source)
}

///|
fn png_chunk_test_owner(capacity : UInt64, fill? : Byte = b'\x00') -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    Bytes::from_array(Array::make(capacity.to_int(), fill)),
    png_stream_test_budget(work=0UL),
  ).unwrap()
}

///|
fn png_chunk_test_pull(
  encoder : PngChunkEncoder,
  capacity : UInt64,
  output : Array[Byte],
) -> PngChunkPullResult {
  let owner = png_chunk_test_owner(capacity)
  let result = owner.with_mut(0UL, capacity, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  for index = 0UL; index < result.written(); index = index + 1UL {
    output.push(owner.view().get(index).unwrap())
  }
  result
}

///|
fn png_chunk_test_drain_encoder(
  encoder : PngChunkEncoder,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let output : Array[Byte] = []
  let mut turn = 0
  while turn < 1024 {
    let capacity = schedule[turn % schedule.length()]
    let result = png_chunk_test_pull(encoder, capacity, output)
    if result.total_written() != output.length().to_uint64() {
      return Err(@error.CoreError::new(
        @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
        context="png-chunk-total",
      ))
    }
    match result.outcome() {
      PngChunkPullOutcome::Finished => return Ok(Bytes::from_array(output))
      PngChunkPullOutcome::Failed(error) => return Err(error)
      PngChunkPullOutcome::NeedOutput => turn = turn + 1
    }
  }
  Err(@error.CoreError::new(
    @error.ErrorCategory::State, @error.ErrorCode::InvalidRange,
    context="png-chunk-unreachable",
  ))
}

///| Eager Gray8 output is the oracle for the caller-buffered Gray8 factory.
fn png_stream_gray8_eager(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray8(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///|
fn png_stream_gray16_eager(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray16(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| Combined eager Gray16 output is the caller-buffered identity oracle.
fn png_stream_gray16_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| FixedOrStored eager output is the chunk identity oracle for Gray8.
fn png_stream_gray8_eager_with_compression(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
) -> Bytes {
  png_stream_gray8_eager_with_strategies(image, strategy, PngFilterStrategy::None)
}

///| Combined eager output is the caller-buffered identity oracle for Gray8.
fn png_stream_gray8_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_gray8_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(bytes)
}

///| One ordinary nonzero lease capacity is enough to prove accepted-byte
/// accounting and byte-for-byte identity with the eager Gray8 route.
test "PNG Gray8 chunk Stored output matches eager and rejects atomically" {
  let gray = png_stream_gray8_image(b"\x7f")
  let eager = png_stream_gray8_eager(gray)
  let encoder = PngChunkEncoder::new_gray8(
    gray.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [17UL]).unwrap()
  inspect(chunked == eager && chunked[24] == b'\x08' && chunked[25] == b'\x00' && chunked[28] == b'\x00', content="true")

  let rgb = png_stream_test_image(3UL)
  let budget = png_stream_test_budget()
  let before = budget.remaining()
  let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
  let error = PngChunkEncoder::new_gray8(
    rgb.view(), png_stream_test_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(gray8-required)")
  inspect(png_adam7_stream_same_remaining(before, budget.remaining()), content="true")
  for index = 0UL; index < sentinel.view().length(); index = index + 1UL {
    if sentinel.view().get(index).unwrap() != b'Z' { abort("png gray8 rejection exposed lease") }
  }
}

///|
test "PNG Gray16 chunk Stored output matches eager and rejects atomically" {
  let gray = png_stream_gray16_image()
  let eager = png_stream_gray16_eager(gray)
  let chunked = png_chunk_test_drain_encoder(
    PngChunkEncoder::new_gray16(
      gray.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(),
    [3UL, 7UL],
  ).unwrap()
  inspect(chunked == eager, content="true")
  let rgb = png_stream_test_image(3UL)
  let budget = png_stream_test_budget()
  let before = budget.remaining()
  let error = PngChunkEncoder::new_gray16(
    rgb.view(), png_stream_test_limits(), budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.context(), content="Some(gray16-required)")
  inspect(
    budget.remaining().bytes() == before.bytes() &&
      budget.remaining().allocations() == before.allocations() &&
      budget.remaining().work() == before.work(),
    content="true",
  )
}

///| Combined Gray16 factory families must preserve eager/chunk identity before
/// the bounded filter and compression implementation is added.
test "PNG Gray16 chunk strategy factories match eager" {
  let gray = png_stream_gray16_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray16_eager_with_strategies(gray, strategy, filter_strategy)
      let chunked = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray16_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [3UL, 7UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
      inspect(
        eager[24] == b'\x10' && eager[25] == b'\x00' && eager[28] == b'\x00',
        content="true",
      )
      if strategy == PngCompressionStrategy::Stored && filter_strategy == PngFilterStrategy::None {
        inspect(
          eager[48] == b'\x00' && eager[49] == b'\x12' && eager[50] == b'\x34' &&
            eager[51] == b'\xab' && eager[52] == b'\xcd',
          content="true",
        )
      }
    }
  }
  ignore(PngChunkEncoder::new_gray16_with_compression_strategy(
    gray.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  ignore(PngChunkEncoder::new_gray16_with_filter_strategy(
    gray.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
}

///| FixedOrStored Gray8 uses the same accepted-byte acknowledgement accounting
/// as the eager bounded machine.
test "PNG Gray8 chunk FixedOrStored matches eager with accepted progress" {
  let gray = png_stream_gray8_image(
    Bytes::from_array(Array::make(32, b'\xaa')), width=32UL,
  )
  let eager = png_stream_gray8_eager_with_compression(
    gray, PngCompressionStrategy::FixedOrStored,
  )
  let encoder = PngChunkEncoder::new_gray8_with_compression_strategy(
    gray.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [17UL]).unwrap()
  inspect(chunked == eager && chunked[25] == b'\x00', content="true")
}

///| Gray8 eager/chunk parity covers every public compression-only,
/// filter-only, and combined factory using ordinary positive-capacity pulls.
test "PNG Gray8 chunk strategy factories match eager" {
  let gray = png_stream_gray8_image(b"\x10\x20\x30\x40", width=2UL, height=2UL)
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let eager = png_stream_gray8_eager_with_compression(gray, strategy)
    let chunked = png_chunk_test_drain_encoder(
      PngChunkEncoder::new_gray8_with_compression_strategy(
        gray.view(), strategy, png_stream_test_limits(), png_stream_test_budget(),
        @error.Diagnostics::new(),
      ).unwrap(),
      [17UL],
    ).unwrap()
    inspect(chunked == eager, content="true")
  }
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let eager = png_stream_gray8_eager_with_strategies(
      gray, PngCompressionStrategy::Stored, filter_strategy,
    )
    let chunked = png_chunk_test_drain_encoder(
      PngChunkEncoder::new_gray8_with_filter_strategy(
        gray.view(), filter_strategy, png_stream_test_limits(), png_stream_test_budget(),
        @error.Diagnostics::new(),
      ).unwrap(),
      [17UL],
    ).unwrap()
    inspect(chunked == eager, content="true")
  }
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray8_eager_with_strategies(gray, strategy, filter_strategy)
      let chunked = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [17UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
    }
  }
}

///| Public Gray8 chunk encoders may make no progress with an empty caller
/// lease, then must reproduce eager bytes with fresh hostile-capacity drains.
test "PNG Gray8 chunk strategy pairs preserve eager bytes under hostile capacities" {
  let gray = png_stream_gray8_fidelity_image()
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager = png_stream_gray8_eager_with_strategies(gray, strategy, filter_strategy)
      let zero_encoder = PngChunkEncoder::new_gray8_with_strategies(
        gray.view(), strategy, filter_strategy, png_stream_test_limits(),
        png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let empty = png_chunk_test_owner(0UL)
      let zero = empty.with_mut(0UL, 0UL, fn(lease) {
        Ok(zero_encoder.pull(lease))
      }).unwrap()
      inspect(zero.written(), content="0")
      inspect(zero.total_written(), content="0")
      inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")

      let zero_prefixed = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [0UL, 1UL],
      ).unwrap()
      inspect(zero_prefixed == eager, content="true")

      let one_byte = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [1UL],
      ).unwrap()
      inspect(one_byte == eager, content="true")

      let ragged = png_chunk_test_drain_encoder(
        PngChunkEncoder::new_gray8_with_strategies(
          gray.view(), strategy, filter_strategy, png_stream_test_limits(),
          png_stream_test_budget(), @error.Diagnostics::new(),
        ).unwrap(),
        [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
      ).unwrap()
      inspect(ragged == eager, content="true")
    }
  }
}

///|
fn png_chunk_test_drain(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Result[Bytes, @error.CoreError] {
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  png_chunk_test_drain_encoder(encoder, schedule)
}

///| Combined Adaptive construction has the same accepted-prefix ownership,
/// zero-capacity turns, eager parity, and sticky terminal behavior as the
/// shared caller-buffered machine.
test "PNG adaptive combined chunk routes" {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for image in [
      png_stream_test_dynamic_corpus_image(3UL, width=2UL),
      png_stream_test_dynamic_corpus_image(4UL, width=2UL),
    ] {
      let eager = png_stream_test_eager_with_strategies(
        image, strategy, PngFilterStrategy::Adaptive,
      )
      let encoder = PngChunkEncoder::new_with_strategies(
        image.view(), strategy, PngFilterStrategy::Adaptive,
        png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap()
      let chunked = png_chunk_test_drain_encoder(
        encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
      ).unwrap()
      inspect(chunked == eager, content="true")
      png_stream_test_fixed_or_stored_corpus_decode_matches_source(chunked, image)
    }
  }
}

test "PNG filter strategy chunk frozen compatibility vectors" {
  let rgb = png_stream_test_image(3UL)
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let default = png_chunk_test_drain_encoder(PngChunkEncoder::new(
    rgb.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_compression_strategy(
    rgb.view(), PngCompressionStrategy::Stored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  let adaptive = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_filter_strategy(
    rgb.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  for bytes in [default, configured, adaptive] {
    inspect(bytes == rgb_stored, content="true")
    png_stream_test_fixed_or_stored_corpus_decode_matches_source(bytes, rgb)
  }

  let rgba = png_stream_test_image(4UL)
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let rgba_adaptive = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_filter_strategy(
    rgba.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(rgba_adaptive == rgba_stored, content="true")
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(rgba_adaptive, rgba)

  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let fixed_bytes = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    let dynamic_fallback = png_chunk_test_drain_encoder(PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(fixed_bytes == fixed && dynamic_fallback == fixed, content="true")
    png_stream_test_fixed_or_stored_corpus_decode_matches_source(fixed_bytes, image)
    png_stream_test_fixed_or_stored_corpus_decode_matches_source(dynamic_fallback, image)
  }

}

///|
test "PNG compression strategy chunk factories encode supported images" {
  for strategy in [PngCompressionStrategy::Stored, PngCompressionStrategy::FixedOrStored] {
    let image = png_stream_test_image(3UL)
    let encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), strategy, png_stream_test_limits(), png_stream_test_budget(),
      @error.Diagnostics::new(),
    ).unwrap()
    let bytes = png_chunk_test_drain_encoder(encoder, [1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(bytes[0] == b'\x89' && bytes[1] == b'P', content="true")
    let owner = @bytes.OwnedBytes::from_bytes(
      bytes, png_stream_test_budget(work=0UL),
    ).unwrap()
    let decoded = @codec.ImageDecoder::decode(
      PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
      @codec.DecodeOptions::new(
        require_complete_input=true, preserve_opaque_metadata=false,
      ), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    inspect(decoded.image().view().get_byte(0UL, 0UL, 0UL).unwrap() == b'\x00', content="true")
  }
}

///|
test "PNG fixed-or-stored configured eager and chunk output retain exact hostile-capacity parity" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let eager = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::FixedOrStored)
    let encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::FixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(chunked == eager, content="true")
    inspect((eager[43] & b'\x07') == b'\x03', content="true")
  }
}

///|
test "PNG dynamic strategy chunk factory freezes compatibility routes" {
  let rgb = png_stream_test_image(3UL)
  let rgb_stored = png_chunk_test_drain(rgb, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgb_stored ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let rgba = png_stream_test_image(4UL)
  let rgba_stored = png_chunk_test_drain(rgba, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgba_stored ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    let fixed_encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::FixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let dynamic_encoder = PngChunkEncoder::new_with_compression_strategy(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
    ).unwrap()
    let fixed_bytes = png_chunk_test_drain_encoder(fixed_encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    let dynamic_bytes = png_chunk_test_drain_encoder(dynamic_encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(fixed_bytes == fixed, content="true")
    inspect(dynamic_bytes == fixed, content="true")
    inspect((fixed[43] & b'\x07') == b'\x03', content="true")
  }
}

///| The public strict-winner evidence freezes its complete PNG bytes, checks
///| BTYPE=10 and complete-input decode, and retains hostile caller-buffer parity.
test "PNG dynamic strict winner decodes completely through public API" {
  let image = png_stream_test_dynamic_image()
  let eager = png_stream_test_eager_with_strategy(
    image, PngCompressionStrategy::DynamicOrFixedOrStored,
  )
  inspect(
    eager ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x80\x00\x00\x00\x01\x08\x02\x00\x00\x00\x99\xb0\x31\xe1\x00\x00\x00\x91IDAT\x78\x01\x05\xc0\x01\x01\x00\x00\x00\xc1\xb0\x73\xfd\x33\x1b\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x48\x1d\xa9\x23\x75\xa4\x8e\xd4\x91\x3a\x52\x47\xea\x01\x40\x1d\x02\xff\xd8\xa1\x67\x97\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  inspect((eager[43] & b'\x07') == b'\x05', content="true")
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(chunked == eager, content="true")
  let owner = @bytes.OwnedBytes::from_bytes(eager, png_stream_test_budget(work=0UL)).unwrap()
  let decoded = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let restored = decoded.image().view()
  let expected = image.view()
  inspect(restored.width() == expected.width() && restored.height() == expected.height(), content="true")
  for x = 0UL; x < expected.width(); x = x + 1UL {
    for channel = 0UL; channel < 3UL; channel = channel + 1UL {
      inspect(restored.get_byte(x, 0UL, channel).unwrap() == expected.get_byte(x, 0UL, channel).unwrap(), content="true")
    }
  }
}

///| Eager and caller-buffered adapters acknowledge the same scalar Dynamic
/// machine, including zero-capacity pulls.
test "PNG dynamic eager and chunk output have exact hostile-capacity parity" {
  let image = png_stream_test_dynamic_image()
  let eager = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::DynamicOrFixedOrStored)
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 4UL, 2UL, 7UL]).unwrap()
  inspect(chunked == eager && (eager[43] & b'\x07') == b'\x05', content="true")
}

///| Finished is sticky and a subsequent zero-capacity caller lease has no work
/// to acknowledge.
test "PNG dynamic configured sticky terminals preserve leases" {
  let image = png_stream_test_dynamic_image()
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  ignore(png_chunk_test_drain_encoder(encoder, [1UL]).unwrap())
  let owner = png_chunk_test_owner(1UL, fill=b'\xaa')
  let result = owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(result.written() == 0UL && result.outcome() is PngChunkPullOutcome::Finished, content="true")
  inspect(owner.view().get(0UL).unwrap() == b'\xaa', content="true")
}

///| The 128-pixel periodic RGB8 fixture has `total_length == 202UL` and
/// `matcher_work == 4593UL` in the Task 1 white-box evidence, so its selected
/// Dynamic admission ledger is `202UL + 4593UL + 4593UL == 9388UL`.
test "PNG dynamic public exact and one-less admission is atomic" {
  let fixture_work = 9388UL
  let image = png_stream_test_dynamic_image()

  let eager_budget = png_stream_test_budget(work=fixture_work)
  let eager_before = eager_budget.remaining()
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), eager_budget, @error.Diagnostics::new(),
  ).unwrap())
  inspect(eager_budget.remaining().work(), content="0")
  inspect(
    eager_before.bytes() == eager_budget.remaining().bytes() &&
      eager_before.allocations() == eager_budget.remaining().allocations() &&
      eager_before.allocation_size() == eager_budget.remaining().allocation_size() &&
      eager_before.width() == eager_budget.remaining().width() &&
      eager_before.height() == eager_budget.remaining().height() &&
      eager_before.pixels() == eager_budget.remaining().pixels() &&
      eager_before.depth() == eager_budget.remaining().depth(), content="true",
  )

  let chunk_budget = png_stream_test_budget(work=fixture_work)
  let chunk_before = chunk_budget.remaining()
  ignore(PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), chunk_budget, @error.Diagnostics::new(),
  ).unwrap())
  inspect(chunk_budget.remaining().work(), content="0")
  inspect(
    chunk_before.bytes() == chunk_budget.remaining().bytes() &&
      chunk_before.allocations() == chunk_budget.remaining().allocations() &&
      chunk_before.allocation_size() == chunk_budget.remaining().allocation_size() &&
      chunk_before.width() == chunk_budget.remaining().width() &&
      chunk_before.height() == chunk_budget.remaining().height() &&
      chunk_before.pixels() == chunk_budget.remaining().pixels() &&
      chunk_before.depth() == chunk_budget.remaining().depth(), content="true",
  )

  let eager_one_less_budget = png_stream_test_budget(work=fixture_work - 1UL)
  let eager_one_less_before = eager_one_less_budget.remaining()
  let eager_writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager_error = @codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::DynamicOrFixedOrStored),
    image.view(), eager_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), eager_one_less_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(eager_writer.position(), content="0")
  inspect(png_fixed_or_stored_same_remaining(eager_one_less_before, eager_one_less_budget.remaining()), content="true")

  let chunk_one_less_budget = png_stream_test_budget(work=fixture_work - 1UL)
  let chunk_one_less_before = chunk_one_less_budget.remaining()
  let candidate = png_chunk_test_owner(7UL, fill=b'Z')
  let chunk_error = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), chunk_one_less_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(png_chunk_test_same_error(eager_error, chunk_error), content="true")
  inspect(png_fixed_or_stored_same_remaining(chunk_one_less_before, chunk_one_less_budget.remaining()), content="true")
  for index = 0UL; index < 7UL; index = index + 1UL {
    inspect(candidate.view().get(index).unwrap() == b'Z', content="true")
  }
}

///| Public eager and caller-buffered Adaptive fallback routes agree on their
///| smallest admitted work budget and leave rejected construction atomic.
test "PNG adaptive Dynamic decline public admission is atomic" {
  let image = png_stream_test_flat_image(3UL, 32UL)
  let mut rejected = 0UL
  let mut exact = 1UL
  while PngChunkEncoder::new_with_strategies(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      PngFilterStrategy::Adaptive, png_stream_test_limits(),
      png_stream_test_budget(work=exact), @error.Diagnostics::new(),
    ) is Err(_) {
    rejected = exact
    exact = exact * 2UL
  }
  while rejected + 1UL < exact {
    let middle = rejected + ((exact - rejected) / 2UL)
    match PngChunkEncoder::new_with_strategies(
      image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
      PngFilterStrategy::Adaptive, png_stream_test_limits(),
      png_stream_test_budget(work=middle), @error.Diagnostics::new(),
    ) {
      Ok(_) => exact = middle
      Err(_) => rejected = middle
    }
  }
  let eager_budget = png_stream_test_budget(work=exact)
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), eager_budget, @error.Diagnostics::new(),
  ).unwrap())
  let eager_bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    eager_bytes.push(writer.view().get(index).unwrap())
  }
  let eager = Bytes::from_array(eager_bytes)
  let chunk_budget = png_stream_test_budget(work=exact)
  let encoder = PngChunkEncoder::new_with_strategies(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_stream_test_limits(), chunk_budget,
    @error.Diagnostics::new(),
  ).unwrap()
  let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 4UL, 2UL, 7UL]).unwrap()
  inspect(chunked == eager && eager_budget.remaining().work() == 0UL && chunk_budget.remaining().work() == 0UL, content="true")
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(eager, image)
  let rejected_budget = png_stream_test_budget(work=exact - 1UL)
  let rejected_before = rejected_budget.remaining()
  let rejected_writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager_error = @codec.ImageEncoder::encode(
    PngEncoder::new_with_strategies(PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive),
    image.view(), rejected_writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), rejected_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(rejected_writer.position() == 0UL && png_fixed_or_stored_same_remaining(rejected_before, rejected_budget.remaining()), content="true")
  let chunk_budget = png_stream_test_budget(work=exact - 1UL)
  let chunk_before = chunk_budget.remaining()
  let chunk_error = PngChunkEncoder::new_with_strategies(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    PngFilterStrategy::Adaptive, png_stream_test_limits(), chunk_budget,
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(png_chunk_test_same_error(eager_error, chunk_error) && png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()), content="true")
}

///|
test "PNG dynamic replay drift is sticky through chunk encoder" {
  let image = png_stream_test_dynamic_image()
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::DynamicOrFixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  image.with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'Z') }).unwrap()
  let scratch : Array[Byte] = []
  let mut turns = 0UL
  let mut first_error : Option[@error.CoreError] = None
  let mut first_total = 0UL
  while turns < 1024UL {
    let pulled = png_chunk_test_pull(encoder, 1UL, scratch)
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turns = turns + 1UL
      PngChunkPullOutcome::Finished => panic()
      PngChunkPullOutcome::Failed(error) => {
        first_error = Some(error)
        first_total = pulled.total_written()
        break
      }
    }
  }
  let first = match first_error {
    Some(error) => error
    None => panic()
  }
  inspect(first.category() == @error.ErrorCategory::State, content="true")
  inspect(first.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(first.context() == Some("png-encode-dynamic-replay-drift"), content="true")
  let later = png_chunk_test_owner(7UL, fill=b'Z')
  let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written() == first_total, content="true")
  inspect(png_chunk_test_same_error(first, replay_error), content="true")
  for index = 0UL; index < 7UL; index = index + 1UL {
    inspect(later.view().get(index).unwrap() == b'Z', content="true")
  }
}

///|
test "PNG fixed-or-stored corpus evidence is deterministic, valid, never-larger, and wins flat RGB8/RGBA8" {
  png_stream_test_fixed_or_stored_corpus_case(png_stream_test_flat_image(3UL, 32UL))
  png_stream_test_fixed_or_stored_corpus_case(png_stream_test_flat_image(4UL, 32UL))
}

///|
test "PNG dynamic corpus evidence is deterministic, strictly wins periodic RGB8/RGBA8, and decodes completely" {
  png_stream_test_dynamic_corpus_case(png_stream_test_dynamic_corpus_image(3UL))
  png_stream_test_dynamic_corpus_case(png_stream_test_dynamic_corpus_image(4UL))
}

///|
test "PNG compression strategy legacy chunk constructors retain frozen stored bytes" {
  let rgb = png_stream_test_image(3UL)
  let rgb_bytes = png_chunk_test_drain(rgb, [1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgb_bytes ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
  let rgba = png_stream_test_image(4UL)
  let rgba_bytes = png_chunk_test_drain(rgba, [1UL, 3UL, 2UL, 5UL]).unwrap()
  inspect(
    rgba_bytes ==
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82",
    content="true",
  )
}

///| Public Adam7 chunk output must retain its zero-capacity no-op, agree with
///| eager bytes under one-byte and ragged drains, and decode exactly.
fn png_adam7_public_chunk_fidelity(
  source : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
) -> Unit {
  let eager = png_stream_test_eager_with_all_strategies(
    source, strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  if eager[28] != b'\x01' { abort("png adam7 eager interlace") }

  let one_byte_encoder = PngChunkEncoder::new_with_all_strategies(
    source.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) {
    Ok(one_byte_encoder.pull(lease))
  }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) {
    abort("png adam7 zero-capacity progress")
  }
  let one_byte = png_chunk_test_drain_encoder(one_byte_encoder, [1UL]).unwrap()
  if one_byte != eager || one_byte[28] != b'\x01' {
    abort("png adam7 one-byte eager identity")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(one_byte, source)

  let ragged_encoder = PngChunkEncoder::new_with_all_strategies(
    source.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let ragged = png_chunk_test_drain_encoder(
    ragged_encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
  ).unwrap()
  if ragged != eager || ragged[28] != b'\x01' {
    abort("png adam7 ragged eager identity")
  }
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(ragged, source)
}

///| Frozen legacy and explicit-None routes remain method 0 while generated
///| multi-pass Adam7 output stays byte-identical to the eager public route.
test "PNG Adam7 public chunk fidelity, hostile identity, and frozen None compatibility" {
  let rgb = png_stream_test_image(3UL)
  let rgba = png_stream_test_image(4UL)
  let rgb_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0fIDAT\x78\x01\x01\x04\x00\xfb\xff\x00\x00\x01\x02\x00\x08\x00\x04\xad\xa5\x4e\x4e\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  let rgba_stored =
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x10IDAT\x78\x01\x01\x05\x00\xfa\xff\x00\x00\x01\x02\x03\x00\x0f\x00\x07\x2c\x93\x65\xb4\x00\x00\x00\x00IEND\xae\x42\x60\x82"
  for image in [rgb, rgba] {
    let expected = if image.view().format().channel_count() == 3UL {
      rgb_stored
    } else {
      rgba_stored
    }
    for encoder in [
      PngChunkEncoder::new(image.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_compression_strategy(image.view(), PngCompressionStrategy::Stored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_filter_strategy(image.view(), PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_filter_strategy(image.view(), PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_interlace_strategy(image.view(), PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::Stored, PngFilterStrategy::Adaptive, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
    ] {
      let bytes = png_chunk_test_drain_encoder(
        encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
      ).unwrap()
      inspect(bytes == expected && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = if channels == 3UL {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x02\x00\x00\x000\xe8\x3b\x30\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x45\x63\x00\x00\x14\xf5\x3f\xc1\x59\xc4\xa1\xc0\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    } else {
      b"\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR\x00\x00\x00 \x00\x00\x00\x01\x08\x06\x00\x00\x00\xbf\x8a\xac\x67\x00\x00\x00\x0cIDAT\x78\x01\x63\x58\x35\xc0\x00\x00\x6c\x3c\x55\x01\xb7\x54\x9d\x82\x00\x00\x00\x00IEND\xae\x42\x60\x82"
    }
    for encoder in [
      PngChunkEncoder::new_with_compression_strategy(image.view(), PngCompressionStrategy::FixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_compression_strategy(image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_strategies(image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
      PngChunkEncoder::new_with_all_strategies(image.view(), PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, PngInterlaceStrategy::None, png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new()).unwrap(),
    ] {
      let bytes = png_chunk_test_drain_encoder(
        encoder, [0UL, 1UL, 3UL, 2UL, 5UL],
      ).unwrap()
      inspect(bytes == fixed && bytes[28] == b'\x00', content="true")
    }
  }
  for channels in [3UL, 4UL] {
    let source = png_stream_test_image(channels, width=5UL, height=5UL)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      png_adam7_public_chunk_fidelity(source, strategy)
    }
  }
}

///|
test "PNG encode machine eager oracle remains canonical for RGB and RGBA" {
  for image in [png_stream_test_image(3UL), png_stream_test_image(4UL)] {
    let eager = png_stream_test_eager(image)
    let colour_type = if image.view().format().channel_count() == 3UL { b'\x02' } else { b'\x06' }
    inspect(eager[0] == b'\x89' && eager[1] == b'P', content="true")
    inspect(eager[25] == colour_type, content="true")
  }
}

///|
test "PNG encode machine stores the exact multi-block length formula" {
  let scanlines = 65539UL
  let blocks = 2UL
  inspect(scanlines + 6UL + blocks * 5UL + 57UL, content="65612")
}

///|
test "PNG chunk encoder reports empty, one-byte, and irregular exact progress" {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL)
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(zero.written(), content="0")
  inspect(zero.total_written(), content="0")
  inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let output : Array[Byte] = []
  let first = png_chunk_test_pull(encoder, 1UL, output)
  inspect(first.written(), content="1")
  inspect(first.total_written(), content="1")
  inspect(first.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let irregular = png_chunk_test_pull(encoder, 3UL, output)
  inspect(irregular.written(), content="3")
  inspect(irregular.total_written(), content="4")
}

///|
test "PNG chunk encoder equals eager bytes for RGB and straight RGBA" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels)
    let eager = png_stream_test_eager(image)
    let chunked = png_chunk_test_drain(image, [1UL, 3UL, 2UL, 5UL]).unwrap()
    inspect(chunked == eager, content="true")
  }
}

///|
test "PNG chunk encoder retains no completed caller output lease" {
  let image = png_stream_test_image(3UL)
  let eager = png_stream_test_eager(image)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let first_owner = png_chunk_test_owner(1UL)
  let first = first_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(first.written(), content="1")
  let output : Array[Byte] = [first_owner.view().get(0UL).unwrap()]
  first_owner.with_mut(0UL, 1UL, fn(lease) { lease.set(0UL, b'X') }).unwrap()
  let mut turn = 0
  while turn < 1024 {
    let result = png_chunk_test_pull(encoder, 2UL, output)
    match result.outcome() {
      PngChunkPullOutcome::Finished => break
      PngChunkPullOutcome::Failed(_) => panic()
      PngChunkPullOutcome::NeedOutput => turn = turn + 1
    }
  }
  inspect(Bytes::from_array(output) == eager, content="true")
  let terminal_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let terminal = terminal_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(terminal.written(), content="0")
  inspect(terminal.total_written() == eager.length().to_uint64(), content="true")
  inspect(terminal.outcome() is PngChunkPullOutcome::Finished, content="true")
  inspect(terminal_owner.view().get(0UL).unwrap() == b'Z', content="true")
}

///|
test "PNG chunk encoder replays the original released-lease failure" {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = owner.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(failed.written(), content="0")
  inspect(failed.total_written(), content="0")
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written(), content="0")
  inspect(replay_error.category() == first_error.category(), content="true")
  inspect(replay_error.code() == first_error.code(), content="true")
  inspect(replay_error.operation() == first_error.operation(), content="true")
  inspect(replay_error.context() == first_error.context(), content="true")
  inspect(replay_error.requested() == first_error.requested(), content="true")
  inspect(replay_error.completed() == first_error.completed(), content="true")
  inspect(replay_error.limit() == first_error.limit(), content="true")
  inspect(replay_owner.view().get(0UL).unwrap() == b'Z', content="true")
}

///|
test "PNG encoder isolated four-target evidence preserves hostile output and preflight parity" {
  png_chunk_test_four_target_evidence()
}

///|
fn png_chunk_test_same_error(
  left : @error.CoreError,
  right : @error.CoreError,
) -> Bool {
  left.category() == right.category() &&
    left.code() == right.code() &&
    left.operation() == right.operation() &&
    left.context() == right.context() &&
    left.requested() == right.requested() &&
    left.completed() == right.completed() &&
    left.limit() == right.limit()
}

///|
fn png_chunk_test_eager_error(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
) -> @error.CoreError {
  let writer = @io.MemoryWriter::new(
    1048576UL, png_stream_test_budget(work=0UL),
  ).unwrap()
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true, preserve_opaque_metadata=false,
    ), limits, budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if writer.position() != 0UL { abort("png chunk eager preflight output") }
  error
}

///|
fn png_chunk_test_drain_hostile_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  schedule : Array[UInt64],
) -> Bytes {
  let eager = png_stream_test_eager_with_strategies(image, strategy, filter_strategy)
  let encoder = PngChunkEncoder::new_with_strategies(
    image.view(), strategy, filter_strategy, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 1024UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity)
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png chunk hostile progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    if turn == 0UL && capacity == 0UL &&
      (pulled.written() != 0UL || pulled.total_written() != 0UL ||
        !(pulled.outcome() is PngChunkPullOutcome::NeedOutput)) {
      abort("png chunk empty output")
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png chunk hostile output failure")
      PngChunkPullOutcome::Finished => {
        let terminal_total = pulled.total_written()
        for _ in [0, 1] {
          let terminal_owner = png_chunk_test_owner(7UL, fill=b'Z')
          let terminal = terminal_owner.with_mut(0UL, 7UL, fn(lease) {
            Ok(encoder.pull(lease))
          }).unwrap()
          if terminal.written() != 0UL || terminal.total_written() != terminal_total ||
            !(terminal.outcome() is PngChunkPullOutcome::Finished) {
            abort("png chunk terminal progress")
          }
          for index = 0UL; index < 7UL; index = index + 1UL {
            if terminal_owner.view().get(index).unwrap() != b'Z' {
              abort("png chunk terminal mutation")
            }
          }
        }
        let bytes = Bytes::from_array(output)
        if bytes != eager { abort("png chunk eager parity") }
        return bytes
      }
    }
  }
  abort("png chunk hostile drain unreachable")
}

///| Retain the legacy Stored/filter-None hostile route through the generalized
///| public-factory drain.
fn png_chunk_test_drain_hostile(
  image : @storage.OwnedImage,
  schedule : Array[UInt64],
) -> Bytes {
  png_chunk_test_drain_hostile_with_strategies(
    image, PngCompressionStrategy::Stored, PngFilterStrategy::None, schedule,
  )
}

///|
fn png_stream_adaptive_evidence_image(
  channels : UInt64,
  width : UInt64,
  height : UInt64,
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, height,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(
      0UL, channels * width * height, channels * width, channels * width,
      1UL, 1UL, width, height,
    ).unwrap()],
    channels * width * height,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=1UL, max_token_bytes=16UL, max_value_bytes=1UL,
          max_total_bytes=32UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  @storage.OwnedImage::new(descriptor, png_stream_test_budget(work=0UL)).unwrap()
}

///| CandidateSelection winner R1, duplicated locally for public chunk evidence.
fn png_stream_adaptive_evidence_rgb8_horizontal_image() -> @storage.OwnedImage {
  let image = png_stream_adaptive_evidence_image(3UL, 32UL, 1UL)
  image.with_mut_view(fn(view) {
    for x = 0UL; x < 32UL; x = x + 1UL {
      view.set_byte(x, 0UL, 0UL, x.to_byte()).unwrap()
      view.set_byte(x, 0UL, 1UL, (x + 64UL).to_byte()).unwrap()
      view.set_byte(x, 0UL, 2UL, (x + 128UL).to_byte()).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///| CandidateSelection winner A1, duplicated locally for public chunk evidence.
fn png_stream_adaptive_evidence_straight_rgba8_vertical_image() -> @storage.OwnedImage {
  let image = png_stream_adaptive_evidence_image(4UL, 16UL, 8UL)
  image.with_mut_view(fn(view) {
    for y = 0UL; y < 8UL; y = y + 1UL {
      for x = 0UL; x < 16UL; x = x + 1UL {
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
test "PNG adaptive filter evidence RGB8 horizontal chunk exactly matches eager and decodes completely" {
  let source = png_stream_adaptive_evidence_rgb8_horizontal_image()
  let bytes = png_chunk_test_drain_hostile_with_strategies(
    source, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  )
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(bytes, source)
}

///|
test "PNG adaptive filter evidence straight-RGBA8 vertical chunk exactly matches eager and decodes completely" {
  let source = png_stream_adaptive_evidence_straight_rgba8_vertical_image()
  let bytes = png_chunk_test_drain_hostile_with_strategies(
    source, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  )
  png_stream_test_fixed_or_stored_corpus_decode_matches_source(bytes, source)
}

///|
fn png_chunk_test_preflight_parity() -> Unit {
  let image = png_stream_test_image(3UL)
  let output_limits = png_stream_test_limits(output=71UL)
  let eager_output = png_chunk_test_eager_error(
    image, output_limits, png_stream_test_budget(),
  )
  let output_budget = png_stream_test_budget()
  let output_before = output_budget.remaining().work()
  let chunk_output = PngChunkEncoder::new(
    image.view(), output_limits, output_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_output, chunk_output) ||
    output_budget.remaining().work() != output_before {
    abort("png chunk output preflight parity")
  }

  let work_limits = png_stream_test_limits()
  let eager_work = png_chunk_test_eager_error(
    image, work_limits, png_stream_test_budget(work=71UL),
  )
  let work_budget = png_stream_test_budget(work=71UL)
  let work_before = work_budget.remaining().work()
  let chunk_work = PngChunkEncoder::new(
    image.view(), work_limits, work_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_work, chunk_work) ||
    work_budget.remaining().work() != work_before {
    abort("png chunk work preflight parity")
  }

  let retained = png_stream_test_image(3UL, include_opaque=true)
  let opaque_limits = png_stream_test_limits()
  let eager_opaque = png_chunk_test_eager_error(
    retained, opaque_limits, png_stream_test_budget(),
  )
  let opaque_budget = png_stream_test_budget()
  let opaque_before = opaque_budget.remaining().work()
  let chunk_opaque = PngChunkEncoder::new(
    retained.view(), opaque_limits, opaque_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager_opaque, chunk_opaque) ||
    opaque_budget.remaining().work() != opaque_before {
    abort("png chunk opaque preflight parity")
  }
}

///|
fn png_chunk_test_released_lease_terminal() -> Unit {
  let image = png_stream_test_image(3UL)
  let encoder = PngChunkEncoder::new(
    image.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let owner = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = owner.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(encoder.pull(lease))
  }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png chunk released lease outcome")
  }
  let replay_owner = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = replay_owner.with_mut(0UL, 1UL, fn(lease) {
    Ok(encoder.pull(lease))
  }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => abort("png chunk released lease replay")
  }
  if failed.written() != 0UL || replay.written() != 0UL ||
    failed.total_written() != 0UL || replay.total_written() != 0UL ||
    !png_chunk_test_same_error(first_error, replay_error) ||
    replay_owner.view().get(0UL).unwrap() != b'Z' {
    abort("png chunk released lease terminal")
  }
}

///|
fn png_chunk_test_four_target_evidence() -> Unit {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels)
    ignore(png_chunk_test_drain_hostile(image, [0UL, 1UL]))
    ignore(png_chunk_test_drain_hostile(image, [1UL]))
    ignore(png_chunk_test_drain_hostile(
      image, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
    ))
  }
  png_chunk_test_released_lease_terminal()
  png_chunk_test_preflight_parity()
}

///|
fn png_fixed_or_stored_same_remaining(
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
fn png_fixed_or_stored_limits(
  output? : UInt64 = 1048576UL,
  work? : UInt64 = 1048576UL,
  width? : UInt64 = 70000UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=output,
    max_width=width, max_height=8UL, max_pixels=560000UL, max_work=work,
  )
}

///|
fn png_fixed_or_stored_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  let eager_budget = png_stream_test_budget(work=work)
  let eager_before = eager_budget.remaining()
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  let eager = @codec.ImageEncoder::encode(
    PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    limits, eager_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if writer.position() != 0UL {
    abort("png fixed-or-stored eager admission exposed output")
  }
  if !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
    abort("png fixed-or-stored eager admission changed budget")
  }
  let chunk_budget = png_stream_test_budget(work=work)
  let chunk_before = chunk_budget.remaining()
  let chunk = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    limits, chunk_budget, @error.Diagnostics::new(),
  ).unwrap_err()
  if !png_chunk_test_same_error(eager, chunk) {
    abort("png fixed-or-stored public admission mismatch")
  }
  if !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
    abort("png fixed-or-stored chunk admission changed budget")
  }
}

///| All combined routes use the shared constructor, so every rejection remains
/// atomic before an eager writer byte or caller-owned output lease is exposed.
fn png_adaptive_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let eager_budget = png_stream_test_budget(work=work)
    let eager_before = eager_budget.remaining()
    let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
    let eager = @codec.ImageEncoder::encode(
      PngEncoder::new_with_strategies(strategy, PngFilterStrategy::Adaptive),
      image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      limits, eager_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if writer.position() != 0UL ||
      !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
      abort("png adaptive combined eager admission")
    }
    let chunk_budget = png_stream_test_budget(work=work)
    let chunk_before = chunk_budget.remaining()
    let untouched_lease = png_chunk_test_owner(7UL, fill=b'Z')
    let chunk = PngChunkEncoder::new_with_strategies(
      image.view(), strategy, PngFilterStrategy::Adaptive,
      limits, chunk_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if !png_chunk_test_same_error(eager, chunk) ||
      !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
      abort("png adaptive combined chunk admission")
    }
    for index = 0UL; index < 7UL; index = index + 1UL {
      if untouched_lease.view().get(index).unwrap() != b'Z' {
        abort("png adaptive combined admission exposed lease")
      }
    }
  }
}

///| Gray8 strategy surfaces share the same admission ledger as legacy routes;
/// every rejection occurs before either eager output or a caller lease exists.
fn png_gray8_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_gray8_with_strategies(strategy, filter_strategy),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png gray8 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_gray8_with_strategies(
        image.view(), strategy, filter_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png gray8 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png gray8 admission exposed lease")
        }
      }
    }
  }
}

///| Gray16 must use the same preflight transaction for every bounded strategy
/// pair: rejection cannot write eager bytes, reserve caller budget, or expose a
/// caller-owned lease.
fn png_gray16_combined_public_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
      let eager_budget = png_stream_test_budget(work=work)
      let eager_before = eager_budget.remaining()
      let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
      let eager = @codec.ImageEncoder::encode(
        PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
        image.view(), writer as &@io.Writer,
        @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
        limits, eager_budget, @error.Diagnostics::new(),
      ).unwrap_err()
      if writer.position() != 0UL ||
        !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
        abort("png gray16 eager admission exposed output")
      }
      let chunk_budget = png_stream_test_budget(work=work)
      let chunk_before = chunk_budget.remaining()
      let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
      let chunk = PngChunkEncoder::new_gray16_with_strategies(
        image.view(), strategy, filter_strategy, limits, chunk_budget,
        @error.Diagnostics::new(),
      ).unwrap_err()
      if !png_chunk_test_same_error(eager, chunk) ||
        !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
        abort("png gray16 chunk admission mismatch")
      }
      for index = 0UL; index < 7UL; index = index + 1UL {
        if sentinel.view().get(index).unwrap() != b'Z' {
          abort("png gray16 admission exposed lease")
        }
      }
    }
  }
}

///|
fn png_fixed_or_stored_replay_image() -> @storage.OwnedImage {
  let image = png_stream_test_image(3UL, width=5UL)
  let pixels = [
    b'\x0a', b'\x0c', b'\x0c', b'\x0a', b'\x0a', b'\x0c', b'\x0b', b'\x0c', b'\x0a',
    b'\x0c', b'\x0a', b'\x0b', b'\x0a', b'\x0c', b'\x0a',
  ]
  image.with_mut_view(fn(view) {
    for index = 0UL; index < 15UL; index = index + 1UL {
      view.set_byte(index / 3UL, 0UL, index % 3UL, pixels[index.to_int()]).unwrap()
    }
    Ok(())
  }).unwrap()
  image
}

///|
test "PNG fixed-or-stored public admission is atomic" {
  png_fixed_or_stored_public_reject(
    png_stream_test_image(3UL, include_opaque=true), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_image(3UL, width=2UL), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_fixed_or_stored_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(), 1UL,
  )
}

///| Capability, geometry, output, work, and budget rejections match between
/// eager and caller-buffered Adaptive combined factories before output exists.
test "PNG adaptive combined admission is atomic" {
  png_adaptive_combined_public_reject(
    png_stream_test_image(3UL, include_opaque=true), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_image(3UL, width=2UL), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_adaptive_combined_public_reject(
    png_stream_test_flat_image(3UL, 32UL), png_fixed_or_stored_limits(), 1UL,
  )
}

///| Gray8 uses the same capability, geometry, output, work, and budget
/// rejection ordering for every compression/filter combination.
test "PNG Gray8 strategy admission is atomic" {
  png_gray8_combined_public_reject(
    png_stream_test_image(3UL), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(b"\x01\x02", width=2UL),
    png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(Bytes::from_array(Array::make(32, b'\xaa')), width=32UL),
    png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(Bytes::from_array(Array::make(32, b'\xaa')), width=32UL),
    png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_gray8_combined_public_reject(
    png_stream_gray8_image(Bytes::from_array(Array::make(32, b'\xaa')), width=32UL),
    png_fixed_or_stored_limits(), 1UL,
  )
}

///| All Gray16 strategy pairs reject capability, geometry, output, work, and
/// budget failures before any observable eager or caller-buffered state.
test "PNG Gray16 strategy admission is atomic" {
  png_gray16_combined_public_reject(
    png_stream_test_image(3UL), png_fixed_or_stored_limits(), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(width=1UL), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(output=1UL), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(work=1UL), 1048576UL,
  )
  png_gray16_combined_public_reject(
    png_stream_gray16_image(), png_fixed_or_stored_limits(), 1UL,
  )
}

///|
test "PNG fixed-or-stored public replay mismatch is sticky" {
  let image = png_fixed_or_stored_replay_image()
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let ignored : Array[Byte] = []
  let mut prefix = 0UL
  while prefix < 43UL {
    let pull = png_chunk_test_pull(encoder, 1UL, ignored)
    inspect(pull.written(), content="1")
    prefix = prefix + 1UL
  }
  let header = png_chunk_test_pull(encoder, 1UL, ignored)
  inspect(header.written(), content="1")
  inspect((ignored[43] & b'\x07') == b'\x03', content="true")
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 0UL, b'\x00')
  }).unwrap()
  let mut previews = 0UL
  while previews < 13UL {
    inspect(png_chunk_test_pull(encoder, 1UL, ignored).written(), content="1")
    previews = previews + 1UL
  }
  let first = png_chunk_test_owner(1UL, fill=b'Z')
  let failed = first.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let first_error = match failed.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(failed.written(), content="0")
  inspect(failed.total_written(), content="57")
  inspect(first_error.category() == @error.ErrorCategory::State, content="true")
  inspect(first_error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(first_error.context() == Some("png-encode-fixed-replay-work"), content="true")
  inspect(first.view().get(0UL).unwrap() == b'Z', content="true")
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written(), content="57")
  inspect(png_chunk_test_same_error(first_error, replay_error), content="true")
  inspect(later.view().get(0UL).unwrap() == b'Z', content="true")
}

///| Gray8 fixed replay failure preserves accepted progress and repeats the
/// terminal error without touching a later caller-owned lease.
test "PNG Gray8 fixed replay mismatch is sticky" {
  let image = png_stream_gray8_image(b"\x0a\x0c\x0c\x0a\x0a", width=5UL)
  let encoder = PngChunkEncoder::new_gray8_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let accepted : Array[Byte] = []
  while accepted.length() < 43 {
    let pull = png_chunk_test_pull(encoder, 1UL, accepted)
    if pull.written() != 1UL { abort("png gray8 fixed replay prefix") }
  }
  image.with_mut_view(fn(view) { view.set_byte(0UL, 0UL, 0UL, b'\x00') }).unwrap()
  let mut accepted_total = accepted.length().to_uint64()
  let mut first_error : @error.CoreError? = None
  let mut turns = 0UL
  while turns < 1024UL {
    let owner = png_chunk_test_owner(1UL, fill=b'Z')
    let pull = owner.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    match pull.outcome() {
      PngChunkPullOutcome::NeedOutput => {
        if pull.written() != 1UL || pull.total_written() != accepted_total + 1UL {
          abort("png gray8 fixed replay accepted progress")
        }
        accepted_total = pull.total_written()
        turns = turns + 1UL
      }
      PngChunkPullOutcome::Failed(error) => {
        if pull.written() != 0UL || pull.total_written() != accepted_total ||
          owner.view().get(0UL).unwrap() != b'Z' {
          abort("png gray8 fixed replay failure")
        }
        first_error = Some(error)
        break
      }
      PngChunkPullOutcome::Finished => abort("png gray8 fixed replay did not drift")
    }
  }
  let error = match first_error { Some(value) => value; None => abort("png gray8 fixed replay missing error") }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png gray8 fixed replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) || later.view().get(0UL).unwrap() != b'Z' {
    abort("png gray8 replay was not sticky")
  }
}

///| A Gray16 source mutation after acknowledged framing bytes must invalidate
/// the selected Fixed/Dynamic replay without exposing a terminal byte or
/// changing later caller-owned lease contents.
fn png_gray16_replay_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  expected_header : Byte,
  post_capacity : UInt64,
) -> Unit {
  let encoder = PngChunkEncoder::new_gray16_with_strategies(
    image.view(), strategy, filter_strategy,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png gray16 replay prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header {
    abort("png gray16 replay selected wrong deflate route")
  }
  image.with_mut_view(fn(view) {
    view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\xff')
  }).unwrap()
  let mut accepted_total = prefix.length().to_uint64()
  let mut first_error : @error.CoreError? = None
  let mut turns = 0UL
  while turns < 2048UL {
    let owner = png_chunk_test_owner(post_capacity, fill=b'Z')
    let pull = owner.with_mut(0UL, post_capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    match pull.outcome() {
      PngChunkPullOutcome::NeedOutput => {
        if pull.written() == 0UL || pull.total_written() != accepted_total + pull.written() {
          abort("png gray16 replay accepted progress")
        }
        accepted_total = pull.total_written()
        turns = turns + 1UL
      }
      PngChunkPullOutcome::Failed(error) => {
        if pull.written() != 0UL || pull.total_written() != accepted_total ||
          owner.view().get(0UL).unwrap() != b'Z' {
          abort("png gray16 replay first terminal")
        }
        first_error = Some(error)
        break
      }
      PngChunkPullOutcome::Finished => abort("png gray16 replay did not drift")
    }
  }
  let error = match first_error {
    Some(value) => value
    None => abort("png gray16 replay missing error")
  }
  let later = png_chunk_test_owner(post_capacity, fill=b'Z')
  let replay = later.with_mut(0UL, post_capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(value) => value
    _ => abort("png gray16 replay was not sticky")
  }
  if replay.written() != 0UL || replay.total_written() != accepted_total ||
    !png_chunk_test_same_error(error, replay_error) || later.view().get(0UL).unwrap() != b'Z' {
    abort("png gray16 replay was not sticky")
  }
}

///| Fixed and Dynamic Gray16 plans replay the same profile-aware U16 wire
/// bytes. The periodic corpus proves the Dynamic BTYPE=10 route rather than
/// silently accepting Fixed fallback.
test "PNG Gray16 Fixed and Dynamic replay mutations are sticky" {
  png_gray16_replay_mutation_is_sticky(
    png_stream_gray16_replay_image(5UL),
    PngCompressionStrategy::FixedOrStored, PngFilterStrategy::None, b'\x03', 7UL,
  )
  png_gray16_replay_mutation_is_sticky(
    png_stream_gray16_replay_image(128UL, periodic=true),
    PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::None, b'\x05', 7UL,
  )
}

///|
test "PNG fixed-or-stored configured sticky terminals preserve leases" {
  let image = png_stream_test_flat_image(3UL, 32UL)
  let encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  inspect(zero.written(), content="0")
  inspect(zero.total_written(), content="0")
  inspect(zero.outcome() is PngChunkPullOutcome::NeedOutput, content="true")
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 1024UL {
    let pulled = png_chunk_test_pull(
      encoder, [1UL, 3UL, 2UL, 5UL][(turn % 4UL).to_int()], output,
    )
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Finished => {
        let terminal_total = pulled.total_written()
        let later = png_chunk_test_owner(7UL, fill=b'Z')
        let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        inspect(replay.written(), content="0")
        inspect(replay.total_written() == terminal_total, content="true")
        inspect(replay.outcome() is PngChunkPullOutcome::Finished, content="true")
        for index = 0UL; index < 7UL; index = index + 1UL {
          inspect(later.view().get(index).unwrap() == b'Z', content="true")
        }
        break
      }
      PngChunkPullOutcome::Failed(_) => panic()
    }
  }
  let failed_encoder = PngChunkEncoder::new_with_compression_strategy(
    image.view(), PngCompressionStrategy::FixedOrStored,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let released = png_chunk_test_owner(1UL, fill=b'Z')
  let first = released.with_mut(0UL, 1UL, fn(lease) {
    lease.release()
    Ok(failed_encoder.pull(lease))
  }).unwrap()
  let first_error = match first.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  let later = png_chunk_test_owner(1UL, fill=b'Z')
  let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(failed_encoder.pull(lease)) }).unwrap()
  let replay_error = match replay.outcome() {
    PngChunkPullOutcome::Failed(error) => error
    _ => panic()
  }
  inspect(replay.written(), content="0")
  inspect(replay.total_written() == first.total_written(), content="true")
  inspect(png_chunk_test_same_error(first_error, replay_error), content="true")
  inspect(later.view().get(0UL).unwrap() == b'Z', content="true")
}

///| Adaptive caller-buffered replays may accept framing bytes before a mutable
/// source changes, but must expose no terminal byte and preserve every lease.
fn png_adaptive_mutation_is_sticky(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  mutation_x : UInt64,
  mutation_channel : UInt64,
  mutation_value : Byte,
  expected_header : Byte,
  expected_context : String,
) -> Unit {
  let encoder = PngChunkEncoder::new_with_strategies(
    image.view(), strategy, PngFilterStrategy::Adaptive,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  image.with_mut_view(fn(view) {
    view.set_byte(mutation_x, 0UL, mutation_channel, mutation_value)
  }).unwrap()
  let prefix : Array[Byte] = []
  while prefix.length() < 44 {
    let pull = png_chunk_test_pull(encoder, 1UL, prefix)
    if pull.written() != 1UL { abort("png adaptive mutation prefix") }
  }
  if (prefix[43] & b'\x07') != expected_header { abort("png adaptive mutation header") }
  let mut turn = 0UL
  while turn < 2048UL {
    let first = png_chunk_test_owner(1UL, fill=b'Z')
    let pull = first.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    match pull.outcome() {
      PngChunkPullOutcome::NeedOutput => {
        if pull.written() != 1UL { abort("png adaptive mutation progress") }
        turn = turn + 1UL
      }
      PngChunkPullOutcome::Failed(error) => {
        if error.category() != @error.ErrorCategory::State ||
          error.code() != @error.ErrorCode::InvalidRange ||
          error.context() != Some(expected_context) {
          abort("png adaptive mutation error")
        }
        let accepted_total = pull.total_written()
        if pull.written() != 0UL || first.view().get(0UL).unwrap() != b'Z' {
          abort("png adaptive mutation first terminal")
        }
        let later = png_chunk_test_owner(1UL, fill=b'Z')
        let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
        let replay_error = match replay.outcome() {
          PngChunkPullOutcome::Failed(value) => value
          _ => panic()
        }
        if replay.written() != 0UL || replay.total_written() != accepted_total ||
          !png_chunk_test_same_error(error, replay_error) ||
          later.view().get(0UL).unwrap() != b'Z' {
          abort("png adaptive mutation sticky")
        }
        return
      }
      PngChunkPullOutcome::Finished => panic()
    }
  }
  panic()
}

///|
test "PNG adaptive FixedOrStored public replay mutation is sticky" {
  png_adaptive_mutation_is_sticky(
    png_fixed_or_stored_replay_image(), PngCompressionStrategy::FixedOrStored,
    0UL, 2UL, b'\x0a', b'\x03', "png-encode-fixed-replay-drift",
  )
}

///|
test "PNG adaptive DynamicOrFixedOrStored public replay mutation is sticky" {
  png_adaptive_mutation_is_sticky(
    png_stream_test_dynamic_image(), PngCompressionStrategy::DynamicOrFixedOrStored,
    0UL, 0UL, b'Z', b'\x05', "png-encode-dynamic-replay-drift",
  )
}

///| Adaptive selection retains the Fixed fallback and admits Dynamic only for
/// a strict complete-PNG win.
test "PNG adaptive compression selection retains Fixed equality and Dynamic strict winner" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_flat_image(channels, 32UL)
    let fixed = png_stream_test_eager_with_strategies(
      image, PngCompressionStrategy::FixedOrStored, PngFilterStrategy::Adaptive,
    )
    let fallback = png_stream_test_eager_with_strategies(
      image, PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    )
    inspect((fixed[43] & b'\x07') == b'\x03', content="true")
    inspect(fallback == fixed, content="true")
  }
  for channels in [3UL, 4UL] {
    let image = png_stream_test_dynamic_corpus_image(channels)
    let dynamic = png_stream_test_eager_with_strategies(
      image, PngCompressionStrategy::DynamicOrFixedOrStored, PngFilterStrategy::Adaptive,
    )
    inspect((dynamic[43] & b'\x07') == b'\x05', content="true")
  }
}

///|
fn png_adam7_stream_same_remaining(
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

///| The public eager and caller-buffered all-strategy constructors must agree
/// on each preflight error, before either one exposes owned output state.
fn png_adam7_stream_admission_reject(
  image : @storage.OwnedImage,
  limits : @codec.CodecLimits,
  work : UInt64,
) -> Unit {
  for strategy in [
    PngCompressionStrategy::Stored,
    PngCompressionStrategy::FixedOrStored,
    PngCompressionStrategy::DynamicOrFixedOrStored,
  ] {
    let eager_budget = png_stream_test_budget(work=work)
    let eager_before = eager_budget.remaining()
    let writer = @io.MemoryWriter::new(
      1048576UL, png_stream_test_budget(work=0UL),
    ).unwrap()
    let eager = @codec.ImageEncoder::encode(
      PngEncoder::new_with_all_strategies(
        strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      ), image.view(), writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      limits, eager_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if writer.position() != 0UL ||
      !png_adam7_stream_same_remaining(eager_before, eager_budget.remaining()) {
      abort("png adam7 eager admission exposed state")
    }

    let chunk_budget = png_stream_test_budget(work=work)
    let chunk_before = chunk_budget.remaining()
    let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
    let chunk = PngChunkEncoder::new_with_all_strategies(
      image.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
      limits, chunk_budget, @error.Diagnostics::new(),
    ).unwrap_err()
    if !png_chunk_test_same_error(eager, chunk) ||
      !png_adam7_stream_same_remaining(chunk_before, chunk_budget.remaining()) {
      abort("png adam7 chunk admission mismatch")
    }
    for index = 0UL; index < 7UL; index = index + 1UL {
      if sentinel.view().get(index).unwrap() != b'Z' {
        abort("png adam7 chunk admission exposed lease")
      }
    }
  }
}

///| Drain a real multi-pass caller-buffered stream after first proving a zero
/// lease is a no-op.  Only bytes accepted into the lease count toward progress.
fn png_adam7_chunk_drain(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  schedule : Array[UInt64],
) -> Unit {
  let eager = png_stream_test_eager_with_all_strategies(
    image, strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  )
  let encoder = PngChunkEncoder::new_with_all_strategies(
    image.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap()
  let empty = png_chunk_test_owner(0UL, fill=b'Z')
  let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if zero.written() != 0UL || zero.total_written() != 0UL ||
    !(zero.outcome() is PngChunkPullOutcome::NeedOutput) {
    abort("png adam7 empty lease progress")
  }
  let output : Array[Byte] = []
  let mut turn = 0UL
  while turn < 2048UL {
    let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
    let owner = png_chunk_test_owner(capacity, fill=b'Z')
    let before = output.length().to_uint64()
    let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
    if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
      abort("png adam7 accepted-only progress")
    }
    for index = 0UL; index < pulled.written(); index = index + 1UL {
      output.push(owner.view().get(index).unwrap())
    }
    match pulled.outcome() {
      PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
      PngChunkPullOutcome::Failed(_) => abort("png adam7 chunk drain failed")
      PngChunkPullOutcome::Finished => {
        if Bytes::from_array(output) != eager { abort("png adam7 eager parity") }
        for _ in [0, 1] {
          let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
          let replay = sentinel.with_mut(0UL, 7UL, fn(lease) {
            Ok(encoder.pull(lease))
          }).unwrap()
          if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
            !(replay.outcome() is PngChunkPullOutcome::Finished) {
            abort("png adam7 terminal progress")
          }
          for index = 0UL; index < 7UL; index = index + 1UL {
            if sentinel.view().get(index).unwrap() != b'Z' {
              abort("png adam7 terminal lease mutation")
            }
          }
        }
        return
      }
    }
  }
  abort("png adam7 chunk drain unreachable")
}

///| Five isolated all-strategy Adam7 rejection modes preserve no chunk encoder,
/// no lease contents, and no caller budget state for both supported profiles.
test "PNG Adam7 chunk all-strategy admission is atomic" {
  for channels in [3UL, 4UL] {
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL, include_opaque=true),
      png_stream_test_limits(), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(width=4UL), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(output=1UL), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(work=1UL), 1048576UL,
    )
    png_adam7_stream_admission_reject(
      png_stream_test_image(channels, width=5UL, height=5UL),
      png_stream_test_limits(), 1UL,
    )
  }
}

///| Multi-pass RGB8/RGBA8 Adam7 streams preserve their private preview until
/// acknowledgement, accept only leased bytes, and retain a sticky terminal.
test "PNG Adam7 multi-pass chunk replay is acknowledgement safe" {
  for channels in [3UL, 4UL] {
    let image = png_stream_test_image(channels, width=5UL, height=5UL)
    for strategy in [
      PngCompressionStrategy::Stored,
      PngCompressionStrategy::FixedOrStored,
      PngCompressionStrategy::DynamicOrFixedOrStored,
    ] {
      png_adam7_chunk_drain(image, strategy, [1UL])
      png_adam7_chunk_drain(image, strategy, [0UL, 1UL, 3UL, 2UL, 5UL])
    }
  }
}
