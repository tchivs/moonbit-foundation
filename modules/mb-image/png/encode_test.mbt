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
) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    1UL, 1UL,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels, channels, channels, 1UL, 1UL, 1UL, 1UL).unwrap()],
    channels,
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
  let image = @storage.OwnedImage::new(descriptor, png_encode_budget(bytes=channels, work=0UL)).unwrap()
  image.with_mut_view(fn(view) {
    for index = 0UL; index < channels; index = index + 1UL {
      view.set_byte(0UL, 0UL, index, pixels[index.to_int()]).unwrap()
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
fn png_encode(image : @storage.OwnedImage) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(512UL, png_encode_budget(bytes=512UL, work=0UL)).unwrap()
  let result = @codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
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
struct PngEncodeScriptWriter { mut completed : UInt64; fail_at : UInt64 }

///|
impl @io.Writer for PngEncodeScriptWriter with fn write(self, _source) {
  if self.completed >= self.fail_at {
    @io.WriteOutcome::Failed(@error.CoreError::new(
      @error.ErrorCategory::Host, @error.ErrorCode::HostOperationFailed,
      operation="png-scripted-write", context="scripted",
    ), 0UL)
  } else {
    self.completed = self.completed + 1UL
    @io.WriteOutcome::Progress(1UL)
  }
}

///|
test "PNG encoder retains requested and completed Writer progress" {
  let failed = PngEncodeScriptWriter::{ completed: 0UL, fail_at: 15UL }
  let error = @codec.ImageEncoder::encode(
    PngEncoder::new(), png_encode_image(3UL, b"\x12\x34\x56").view(), failed as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_encode_limits(), png_encode_budget(), @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.code() == @error.ErrorCode::HostOperationFailed, content="true")
  inspect(error.requested() == Some(72UL), content="true")
  inspect(error.completed() == Some(15UL), content="true")
}
