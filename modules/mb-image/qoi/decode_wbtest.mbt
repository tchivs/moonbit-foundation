///|
test "QOI arithmetic is checked before resource preflight" {
  inspect(
    @checked.checked_mul(18446744073709551615UL, 2UL) is Err(_),
    content="true",
  )
}

///|
fn qoi_vector_decode(
  source : Bytes,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  let length = source.length().to_uint64()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length,
        allocations=1UL,
        allocation_size=length,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
  let reader = @io.MemoryReader::new(owner.view())
  @codec.ImageDecoder::decode(
    QoiDecoder::new(),
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=false,
    ),
    @codec.CodecLimits::new(
      max_probe_bytes=16UL,
      max_input_bytes=1024UL,
      max_output_bytes=512UL,
      max_width=64UL,
      max_height=64UL,
      max_pixels=128UL,
      max_work=1024UL,
    ),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=512UL,
        allocations=1UL,
        allocation_size=512UL,
        width=64UL,
        height=64UL,
        pixels=128UL,
        depth=0UL,
        work=1024UL,
      ),
    ),
    @error.Diagnostics::new(),
  )
}

///|
test "generated QOI vectors cover every chunk family with exact bytes" {
  for item in _generated_qoi_cases() {
    let (id, source, expected, width, height, channels, colorspace) = item
    let decoded = match qoi_vector_decode(source) {
      Ok(value) => value
      Err(_) => fail(id)
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
        offset < expected.length().to_uint64()
        offset = offset + 1UL {
      let pixel = offset / channels
      if view.get_byte(pixel % width, pixel / width, offset % channels).unwrap() !=
        expected[offset.to_int()] {
        fail(id)
      }
    }
  }
}
