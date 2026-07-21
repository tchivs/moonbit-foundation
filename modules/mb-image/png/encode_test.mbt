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
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels * width, channels * width, channels * width, 1UL, 1UL, width, 1UL).unwrap()],
    channels * width,
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
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=channels * width, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for index = 0UL; index < channels; index = index + 1UL {
        view.set_byte(x, 0UL, index, pixels[(x * channels + index).to_int()]).unwrap()
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
fn png_encode(image : @storage.OwnedImage) -> (@codec.EncodeResult, @io.MemoryWriter) {
  png_encode_with(PngEncoder::new(), image)
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
