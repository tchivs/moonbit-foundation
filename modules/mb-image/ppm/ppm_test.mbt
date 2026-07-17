///|
fn encode_budget(bytes? : UInt64 = 128UL, work? : UInt64 = 128UL) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=4UL,
      allocation_size=bytes,
      width=16UL,
      height=16UL,
      pixels=256UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn encode_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=256UL,
    max_output_bytes=256UL,
    max_width=16UL,
    max_height=16UL,
    max_pixels=256UL,
    max_work=256UL,
  )
}

///|
fn encode_metadata(
  orientation? : @model.Orientation = @model.Orientation::TopLeft,
  with_opaque? : Bool = false,
) -> @model.ImageMetadata {
  let entries = if with_opaque { [("test", "marker", "raw", b"x")] } else { [] }
  let limits = @metadata.MetadataLimits::new(
    max_entries=1UL,
    max_token_bytes=16UL,
    max_value_bytes=1UL,
    max_total_bytes=32UL,
    max_disposition_fields=5UL,
  )
  let metadata = @metadata.OpaqueMetadata::from_entries(
    entries,
    limits,
    encode_budget(bytes=1UL, work=0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    orientation,
    metadata,
  )
}

///|
fn encode_image(
  width : UInt64,
  height : UInt64,
  stride_extra? : UInt64 = 0UL,
  orientation? : @model.Orientation = @model.Orientation::TopLeft,
  with_opaque? : Bool = false,
) -> @storage.OwnedImage {
  let row_bytes = width * 3UL
  let stride = row_bytes + stride_extra
  let length = (height - 1UL) * stride + row_bytes
  let descriptor = @model.ImageDescriptor::new(
    width,
    height,
    @model.ImageFormat::rgb8(),
    [
      @model.PlaneDescriptor::new(
        0UL, length, stride, row_bytes, 1UL, 1UL, width, height,
      ).unwrap(),
    ],
    length,
    encode_metadata(orientation~, with_opaque~),
  ).unwrap()
  let image = @storage.OwnedImage::new(descriptor, encode_budget(bytes=length, work=0UL)).unwrap()
  image
  .with_mut_view(fn(view) {
    for y = 0UL; y < height; y = y + 1UL {
      for x = 0UL; x < width; x = x + 1UL {
        for channel = 0UL; channel < 3UL; channel = channel + 1UL {
          match view.set_byte(x, y, channel, ((y * width + x) * 3UL + channel + 1UL).to_byte()) {
            Ok(_) => ()
            Err(error) => return Err(error)
          }
        }
      }
    }
    Ok(())
  })
  .unwrap()
  image
}

///|
fn encode_ppm(image : @storage.OwnedImage) -> (@codec.EncodeResult, @io.MemoryWriter) {
  let writer = @io.MemoryWriter::new(256UL, encode_budget(bytes=256UL, work=0UL)).unwrap()
  let result = @codec.ImageEncoder::encode(
    PpmEncoder::new(),
    image.view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    encode_limits(),
    encode_budget(),
    @error.Diagnostics::new(),
  ).unwrap()
  (result, writer)
}

///|
fn writer_prefix(writer : @io.MemoryWriter) -> Bytes {
  let result : Array[Byte] = []
  for index = 0UL; index < writer.position(); index = index + 1UL {
    result.push(writer.view().get(index).unwrap())
  }
  Bytes::from_array(result)
}

///|
test "canonical encoder writes the exact header and logical rows" {
  let (tight_result, tight_writer) = encode_ppm(encode_image(2UL, 2UL))
  let (padded_result, padded_writer) = encode_ppm(encode_image(2UL, 2UL, stride_extra=2UL))
  let expected = b"P6\n2 2\n255\n\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c"
  inspect(writer_prefix(tight_writer) == expected, content="true")
  inspect(writer_prefix(padded_writer) == expected, content="true")
  inspect(tight_result.bytes_written(), content="23")
  inspect(padded_result.bytes_written(), content="23")
}

///|
test "unsupported orientation and opaque metadata fail before output" {
  for image in [
    encode_image(1UL, 1UL, orientation=@model.Orientation::TopRight),
    encode_image(1UL, 1UL, with_opaque=true),
  ] {
    let writer = @io.MemoryWriter::new(64UL, encode_budget(bytes=64UL, work=0UL)).unwrap()
    let error = @codec.ImageEncoder::encode(
      PpmEncoder::new(),
      image.view(),
      writer as &@io.Writer,
      @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
      encode_limits(),
      encode_budget(),
      @error.Diagnostics::new(),
    ).unwrap_err()
    inspect(error.code() == @error.ErrorCode::CapabilityUnavailable, content="true")
    inspect(writer.position(), content="0")
  }
}

///|
struct NoProgressWriter {}

///|
impl @io.Writer for NoProgressWriter with fn write(_self, _source) {
  @io.WriteOutcome::Progress(0UL)
}

///|
test "zero writer progress remains structured" {
  let writer = NoProgressWriter::{  }
  let error = @codec.ImageEncoder::encode(
    PpmEncoder::new(),
    encode_image(1UL, 1UL).view(),
    writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    encode_limits(),
    encode_budget(),
    @error.Diagnostics::new(),
  ).unwrap_err()
  inspect(error.code() == @error.ErrorCode::NoProgress, content="true")
  inspect(error.completed() == Some(0UL), content="true")
}
