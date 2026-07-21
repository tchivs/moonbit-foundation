///|
fn png_stream_test_budget(work? : UInt64 = 1048576UL) -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=1048576UL, allocations=16UL, allocation_size=1048576UL,
    width=70000UL, height=8UL, pixels=560000UL, depth=0UL, work~, 
  ))
}

///|
fn png_stream_test_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=1048576UL, max_output_bytes=1048576UL,
    max_width=70000UL, max_height=8UL, max_pixels=560000UL, max_work=1048576UL,
  )
}

///|
fn png_stream_test_image(channels : UInt64, width? : UInt64 = 1UL) -> @storage.OwnedImage {
  let descriptor = @model.ImageDescriptor::new(
    width, 1UL,
    if channels == 3UL { @model.ImageFormat::rgb8() } else { @model.ImageFormat::rgba8() },
    [@model.PlaneDescriptor::new(0UL, channels, channels * width, channels * width, 1UL, 1UL, 1UL, 1UL).unwrap()],
    channels * width,
    @model.ImageMetadata::new(
      @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
      if channels == 4UL { Some(@color.AlphaMode::Straight) } else { None },
      @profile.ProfileIdentity::builtin_srgb(), @model.Orientation::TopLeft,
      @metadata.OpaqueMetadata::from_entries(
        [], @metadata.MetadataLimits::new(
          max_entries=0UL, max_token_bytes=1UL, max_value_bytes=0UL,
          max_total_bytes=0UL, max_disposition_fields=4UL,
        ), png_stream_test_budget(work=0UL),
      ).unwrap(),
    ),
  ).unwrap()
  let image = @storage.OwnedImage::new(
    descriptor, png_stream_test_budget(work=0UL),
  ).unwrap()
  image.with_mut_view(fn(view) {
    for x = 0UL; x < width; x = x + 1UL {
      for channel = 0UL; channel < channels; channel = channel + 1UL {
        view.set_byte(x, 0UL, channel, (x + channel).to_byte()).unwrap()
      }
    }
    Ok(())
  }).unwrap()
  image
}

///|
fn png_stream_test_eager(image : @storage.OwnedImage) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new(), image.view(), writer as &@io.Writer,
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
test "PNG encode machine eager oracle remains canonical for RGB and RGBA" {
  for image in [png_stream_test_image(3UL), png_stream_test_image(4UL)] {
    let eager = png_stream_test_eager(image)
    inspect(eager[0] == b'\x89' && eager[1] == b'P', content="true")
    inspect(eager[25] == if image.view().format().channel_count() == 3UL { b'\x02' } else { b'\x06' }, content="true")
  }
}

///|
test "PNG encode machine eager oracle crosses the stored-block threshold" {
  let image = png_stream_test_image(3UL, width=21846UL)
  let bytes = png_stream_test_eager(image)
  let scanlines = 65539UL
  let blocks = 2UL
  inspect(bytes.length().to_uint64() == scanlines + 6UL + blocks * 5UL + 57UL, content="true")
  inspect(bytes[43] == b'\x00', content="true")
}
