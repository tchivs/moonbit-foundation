///|
fn qoi_encode_vector_budget(
  bytes? : UInt64 = 2048UL,
  work? : UInt64 = 4096UL,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=8UL,
      allocation_size=bytes,
      width=128UL,
      height=128UL,
      pixels=16384UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn qoi_encode_vector_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=16UL,
    max_input_bytes=2048UL,
    max_output_bytes=2048UL,
    max_width=128UL,
    max_height=128UL,
    max_pixels=16384UL,
    max_work=4096UL,
  )
}

///|
fn qoi_encode_vector_metadata(
  channels : UInt64,
  colorspace : UInt64,
) -> @model.ImageMetadata {
  let opaque_metadata = @metadata.OpaqueMetadata::from_entries(
    [],
    @metadata.MetadataLimits::new(
      max_entries=0UL,
      max_token_bytes=1UL,
      max_value_bytes=0UL,
      max_total_bytes=0UL,
      max_disposition_fields=0UL,
    ),
    qoi_encode_vector_budget(bytes=0UL, work=0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    if colorspace == 0UL {
      @color.TransferIdentity::EncodedSrgb
    } else {
      @color.TransferIdentity::LinearSrgb
    },
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
fn qoi_encode_vector_image(
  width : UInt64,
  height : UInt64,
  channels : UInt64,
  colorspace : UInt64,
  pixels : Bytes,
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
    qoi_encode_vector_metadata(channels, colorspace),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor,
    qoi_encode_vector_budget(bytes=length, work=0UL),
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
fn qoi_encode_vector_bytes(
  image : @storage.OwnedImage,
) -> (@codec.EncodeResult, Bytes) {
  let writer = @io.MemoryWriter::new(
    2048UL,
    qoi_encode_vector_budget(bytes=2048UL, work=0UL),
  ).unwrap()
  let result = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_vector_limits(),
    qoi_encode_vector_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  let bytes : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    bytes.push(writer.view().get(index).unwrap())
  }
  (result, Bytes::from_array(bytes))
}

///|
fn qoi_encode_vector_decode(
  source : Bytes,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    qoi_encode_vector_budget(bytes=source.length().to_uint64(), work=0UL),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    QoiDecoder::new(),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_vector_limits(),
    qoi_encode_vector_budget(),
    @error.Diagnostics::new(),
  )
}

///|
test "QOI encoder validates intrinsic u32 dimensions before header bytes" {
  inspect(qoi_encode_dimension(4294967295UL) is Ok(_), content="true")
  inspect(qoi_encode_dimension(4294967296UL) is Err(_), content="true")
  inspect(
    qoi_encode_header(4294967295UL, 1UL, 3UL, b'\x00') ==
    b"qoif\xff\xff\xff\xff\x00\x00\x00\x01\x03\x00",
    content="true",
  )
}

///|
test "generated QOI encoder vectors prove exact canonical bytes and round trips" {
  for item in _generated_qoi_encode_cases() {
    let (id, pixels, width, height, channels, colorspace, expected) = item
    let image = qoi_encode_vector_image(
      width, height, channels, colorspace, pixels,
    )
    let (result, encoded) = qoi_encode_vector_bytes(image)
    if encoded != expected {
      fail(id)
    }
    inspect(
      result.bytes_written() == expected.length().to_uint64(),
      content="true",
    )
    let decoded = match qoi_encode_vector_decode(encoded) {
      Err(_) => fail(id)
      Ok(value) => value
    }
    let descriptor = decoded.descriptor()
    inspect(descriptor.width() == width, content="true")
    inspect(descriptor.height() == height, content="true")
    inspect(descriptor.format().channel_count() == channels, content="true")
    let transfer = if colorspace == 0UL {
      @color.TransferIdentity::EncodedSrgb
    } else {
      @color.TransferIdentity::LinearSrgb
    }
    inspect(descriptor.metadata().transfer() == transfer, content="true")
    let view = decoded.image().view()
    for offset = 0UL
        offset < pixels.length().to_uint64()
        offset = offset + 1UL {
      let pixel = offset / channels
      if view.get_byte(pixel % width, pixel / width, offset % channels).unwrap() !=
        pixels[offset.to_int()] {
        fail(id)
      }
    }
  }
}

///|
struct QoiVectorNoProgressWriter {}

///|
impl @io.Writer for QoiVectorNoProgressWriter with fn write(_self, _source) {
  @io.WriteOutcome::Progress(0UL)
}

///|
struct QoiVectorFailWriter {
  mut completed : UInt64
  fail_at : UInt64
}

///|
impl @io.Writer for QoiVectorFailWriter with fn write(self, _source) {
  if self.completed >= self.fail_at {
    return @io.WriteOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::Host,
        @error.ErrorCode::HostOperationFailed,
        operation="qoi-vector-write",
        context="scripted",
      ),
      0UL,
    )
  }
  self.completed = self.completed + 1UL
  @io.WriteOutcome::Progress(1UL)
}

///|
test "generated QOI encoder length drives exact Writer failure progress" {
  let (_, pixels, width, height, channels, colorspace, expected) = _generated_qoi_encode_cases()[0]
  let image = qoi_encode_vector_image(
    width, height, channels, colorspace, pixels,
  )
  let stalled = QoiVectorNoProgressWriter::{  }
  let no_progress = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    stalled as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_vector_limits(),
    qoi_encode_vector_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(no_progress.code() == @error.ErrorCode::NoProgress, content="true")
  let failed = QoiVectorFailWriter::{ completed: 0UL, fail_at: 15UL }
  let error = @codec.ImageEncoder::encode(
    QoiEncoder::new(),
    image.view(),
    failed as &@io.Writer,
    @codec.EncodeOptions::new(
      lossless_required=true,
      preserve_opaque_metadata=false,
    ),
    qoi_encode_vector_limits(),
    qoi_encode_vector_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(
    error.requested() == Some(expected.length().to_uint64()),
    content="true",
  )
  inspect(error.completed() == Some(15UL), content="true")
}
