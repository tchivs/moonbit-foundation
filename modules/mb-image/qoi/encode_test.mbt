///|
fn qoi_encode_budget(
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
fn qoi_encode_limits(
  output? : UInt64 = 512UL,
  work? : UInt64 = 1024UL,
) -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=16UL,
    max_input_bytes=512UL,
    max_output_bytes=output,
    max_width=64UL,
    max_height=64UL,
    max_pixels=4096UL,
    max_work=work,
  )
}

///|
fn qoi_encode_metadata(
  channels : UInt64,
  transfer : @color.TransferIdentity,
  include_opaque? : Bool = false,
) -> @model.ImageMetadata {
  let entries = if include_opaque {
    [("test", "marker", "raw", b"x")]
  } else {
    []
  }
  let opaque_metadata = @metadata.OpaqueMetadata::from_entries(
    entries,
    @metadata.MetadataLimits::new(
      max_entries=1UL,
      max_token_bytes=16UL,
      max_value_bytes=1UL,
      max_total_bytes=32UL,
      max_disposition_fields=5UL,
    ),
    qoi_encode_budget(bytes=1UL, work=0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    transfer,
    if channels == 4UL {
      Some(@color.AlphaMode::Straight)
    } else {
      None
    },
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft,
    opaque_metadata,
  )
}

///|
fn qoi_encode_image(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  transfer : @color.TransferIdentity,
  pixels : Bytes,
  include_opaque? : Bool = false,
) -> @storage.OwnedImage {
  let length = width * height * channels
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
        0UL,
        length,
        width * channels,
        width * channels,
        1UL,
        1UL,
        width,
        height,
      ).unwrap(),
    ],
    length,
    qoi_encode_metadata(channels, transfer, include_opaque~),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    qoi_encode_budget(bytes=length, work=0UL),
  ).unwrap()
  image
  .with_mut_view(fn(view) {
    for offset = 0UL; offset < length; offset = offset + 1UL {
      match
        view.set_byte(
          offset / channels % width,
          offset / channels / width,
          offset % channels,
          pixels[offset.to_int()],
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
fn qoi_writer_prefix(writer : @io.MemoryWriter) -> Bytes {
  let output : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    output.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(output)
}

///|
fn qoi_encode(
  image : @storage.OwnedImage,
  limits? : @codec.CodecLimits = qoi_encode_limits(),
  budget? : @budget.Budget = qoi_encode_budget(),
) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(
    512UL,
    qoi_encode_budget(bytes=512UL, work=0UL),
  ).unwrap()
  let result = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    limits,
    budget,
    @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
test "QOI encoder D-01 is publicly constructible" {
  let _encoder = QoiEncoder::new()
}

///|
test "QOI encoder D-02 maps RGB RGBA and sRGB header semantics" {
  let rgb = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
  )
  let (rgb_result, rgb_writer) = qoi_encode(rgb)
  let rgb_bytes = qoi_writer_prefix(rgb_writer)
  inspect(
    rgb_bytes ==
    b"qoif\x00\x00\x00\x01\x00\x00\x00\x01\x03\x00\xa2\x79\x00\x00\x00\x00\x00\x00\x00\x01",
    content="true",
  )
  inspect(rgb_result.bytes_written(), content="24")
  let rgba = qoi_encode_image(
    1UL,
    1UL,
    4UL,
    @color.TransferIdentity::LinearSrgb,
    b"\x04\x05\x06\x07",
  )
  let (_, rgba_writer) = qoi_encode(rgba)
  let rgba_bytes = qoi_writer_prefix(rgba_writer)
  inspect(rgba_bytes[12] == b'\x04', content="true")
  inspect(rgba_bytes[13] == b'\x01', content="true")
}

///|
test "QOI encoder D-04 round trips every logical RGB and RGBA pixel" {
  for
    image in [
      qoi_encode_image(
        2UL,
        1UL,
        3UL,
        @color.TransferIdentity::EncodedSrgb,
        b"\x01\x02\x03\x04\x05\x06",
      ),
      qoi_encode_image(
        2UL,
        1UL,
        4UL,
        @color.TransferIdentity::LinearSrgb,
        b"\x00\x00\x00\xff\x00\x00\x00\x7f",
      ),
    ] {
    let (_, writer) = qoi_encode(image)
    let decoded = decode_qoi(qoi_writer_prefix(writer)).unwrap()
    let source = image.view()
    let restored = decoded.image().view()
    inspect(
      decoded.descriptor().format().channel_count() ==
      image.descriptor().format().channel_count(),
      content="true",
    )
    inspect(
      decoded.descriptor().metadata().transfer() ==
      image.descriptor().metadata().transfer(),
      content="true",
    )
    for y = 0UL; y < source.height(); y = y + 1UL {
      for x = 0UL; x < source.width(); x = x + 1UL {
        for channel = 0UL
            channel < source.format().channel_count()
            channel = channel + 1UL {
          inspect(
            restored.get_byte(x, y, channel).unwrap() ==
            source.get_byte(x, y, channel).unwrap(),
            content="true",
          )
        }
      }
    }
  }
}

///|
test "QOI D-03 rejects capability limits and budget before Writer output" {
  let image = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
    include_opaque=true,
  )
  let writer = @io.MemoryWriter::new(
    64UL,
    qoi_encode_budget(bytes=64UL, work=0UL),
  ).unwrap()
  let error = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_limits(),
    qoi_encode_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(
    error.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(writer.position(), content="0")
  let valid = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
  )
  let restricted_writer = @io.MemoryWriter::new(
    64UL,
    qoi_encode_budget(bytes=64UL, work=0UL),
  ).unwrap()
  let limited = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    valid.view(),
    restricted_writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_limits(output=23UL),
    qoi_encode_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(limited.context() == Some("output-bytes"), content="true")
  inspect(restricted_writer.position(), content="0")
  let budget_writer = @io.MemoryWriter::new(
    64UL,
    qoi_encode_budget(bytes=64UL, work=0UL),
  ).unwrap()
  inspect(
    @codec.ImageEncoder::encode(
      QoiEncoder::new(),
      valid.view(),
      budget_writer as &@io.Writer,
      @codec.EncodeOptions::new(
        lossless_required=true,
        preserve_opaque_metadata=false,
      ),
      qoi_encode_limits(),
      qoi_encode_budget(work=23UL),
      @error.Diagnostics::new(),
    )
    is Err(_),
    content="true",
  )
  inspect(budget_writer.position(), content="0")
}

///|
struct QoiNoProgressWriter {}

///|
impl @io.Writer for QoiNoProgressWriter with fn write(_self, _source) {
  @io.WriteOutcome::Progress(0UL)
}

///|
struct QoiScriptWriter {
  mut completed : UInt64
  fail_at : UInt64
}

///|
impl @io.Writer for QoiScriptWriter with fn write(self, _source) {
  if self.completed >= self.fail_at {
    return @io.WriteOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::Host,
        @error.ErrorCode::HostOperationFailed,
        operation="qoi-scripted-write",
        context="scripted",
      ),
      0UL,
    )
  }
  self.completed = self.completed + 1UL
  @io.WriteOutcome::Progress(1UL)
}

///|
test "QOI D-03 retains exact no-progress and later Writer failure progress" {
  let image = qoi_encode_image(
    1UL,
    1UL,
    3UL,
    @color.TransferIdentity::EncodedSrgb,
    b"\x01\x02\x03",
  )
  let no_progress = QoiNoProgressWriter::{  }
  let stalled = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    no_progress as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_limits(),
    qoi_encode_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(stalled.code() == @error.ErrorCode::NoProgress, content="true")
  inspect(stalled.completed() == Some(0UL), content="true")
  let failed = QoiScriptWriter::{ completed: 0UL, fail_at: 15UL }
  let failure = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    failed as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_limits(),
    qoi_encode_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(
    failure.code() == @error.ErrorCode::HostOperationFailed,
    content="true",
  )
  inspect(failure.requested() == Some(24UL), content="true")
  inspect(failure.completed() == Some(15UL), content="true")
}
