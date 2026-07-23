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

///| A hand-authored Type-4/16 PNG: each pixel has distinct high and low
/// component bytes so the decoder oracle detects both truncation and swaps.
fn png_test_graya16_literal() -> Bytes {
  b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x10\x04\x00\x00\x00\x0e\xbbkB\x00\x00\x00\x14IDATx\x01\x01\x09\x00\xf6\xff\x00\x124\xa7\xc5\xbe\x0fZv\x0e\x17\x03Pk\x88\xb2u\x00\x00\x00\x00IEND\xaeB`\x82"
}

///| This second hand-authored complete literal differs only by its fixed,
/// CRC-authenticated sRGB declaration (intent 0).
fn png_test_graya16_srgb_literal() -> Bytes {
  b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x02\x00\x00\x00\x01\x10\x04\x00\x00\x00\x0e\xbbkB\x00\x00\x00\x01sRGB\x00\xae\xce\x1c\xe9\x00\x00\x00\x14IDATx\x01\x01\x09\x00\xf6\xff\x00\x124\xa7\xc5\xbe\x0fZv\x0e\x17\x03Pk\x88\xb2u\x00\x00\x00\x00IEND\xaeB`\x82"
}

///| A fixed, independent 5x5 Type-4/16 Adam7 stream.  Each of the seven
/// passes is nonempty; component bytes vary by coordinate so the oracle sees
/// both the interlace scatter and little-endian U16 storage order.
fn png_test_graya16_adam7_literal() -> Bytes {
  b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x05\x00\x00\x00\x05\x10\x04\x00\x00\x01\x00\xf1\x02\xbb\x00\x00\x00zIDATx\x01\x01o\x00\x90\xff\x00\x113Uw\x00Q3Yw\x00\x11sY\xb7Qs]\xb7\x0013Ww\x001s[\xb7\x00\x11SW\x971SY\x97QS[\x97\x00!3Vw\x00A3Xw\x00!SX\x97ASZ\x97\x00!sZ\xb7\x00As\\\xb7\x00\x11CV\x87!CW\x871CX\x87ACY\x87QCZ\x87\x00\x11cX\xa7!cY\xa71cZ\xa7Ac[\xa7Qc\\\xa7s\xc7$U \x8d%`\x00\x00\x00\x00IEND\xaeB`\x82"
}

///| The Adam7 fixture needs a larger geometry ceiling than the two-pixel
/// Phase 62 literal, while retaining the same bounded public decode contract.
fn png_test_graya16_adam7_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL, max_input_bytes=256UL, max_output_bytes=128UL,
    max_width=8UL, max_height=8UL, max_pixels=64UL, max_work=512UL,
  )
}

///| The independent all-pass wire literal must reach the explicit profile and
/// retain every PNG MSB-first source component as little-endian Glo,Ghi,Alo,Ahi.
test "PNG explicit graya16 preserves every Adam7 Type-4/16 component byte" {
  let source = png_test_graya16_adam7_literal()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=source.length().to_uint64(), allocations=1UL,
      allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let explicit = PngDecoder::decode_graya16(
    @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_test_graya16_adam7_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=512UL, allocations=4UL, allocation_size=128UL, width=8UL,
      height=8UL, pixels=64UL, depth=0UL, work=512UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap().image().view()
  let expected = b"\x33\x11wU\x33!wV\x331wW\x33AwX\x33QwY\x43\x11\x87V\x43!\x87W\x431\x87X\x43A\x87Y\x43Q\x87Z\x53\x11\x97W\x53!\x97X\x531\x97Y\x53A\x97Z\x53Q\x97[\x63\x11\xa7X\x63!\xa7Y\x631\xa7Z\x63A\xa7[\x63Q\xa7\\\x73\x11\xb7Y\x73!\xb7Z\x731\xb7[\x73A\xb7\\\x73Q\xb7]"
  for y = 0UL; y < 5UL; y = y + 1UL {
    for x = 0UL; x < 5UL; x = x + 1UL {
      let offset = (y * 5UL + x) * 4UL
      for component = 0UL; component < 4UL; component = component + 1UL {
        inspect(
          explicit.get_component_byte(x, y, component / 2UL, component % 2UL).unwrap() ==
            expected.get((offset + component).to_int()).unwrap(),
          content="true",
        )
      }
    }
  }
  let generic = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_test_graya16_adam7_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=512UL, allocations=4UL, allocation_size=128UL, width=8UL,
      height=8UL, pixels=64UL, depth=0UL, work=512UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap().image().view()
  for y = 0UL; y < 5UL; y = y + 1UL {
    for x = 0UL; x < 5UL; x = x + 1UL {
      let offset = (y * 5UL + x) * 4UL
      for channel = 0UL; channel < 3UL; channel = channel + 1UL {
        inspect(generic.get_byte(x, y, channel).unwrap() == expected.get((offset + 1UL).to_int()).unwrap(), content="true")
      }
      inspect(generic.get_byte(x, y, 3UL).unwrap() == expected.get((offset + 3UL).to_int()).unwrap(), content="true")
    }
  }
}

///|
test "PNG explicit graya16 preserves Type-4/16 source lanes without changing generic RGBA8" {
  let source = png_test_graya16_literal()
  let owner = @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=source.length().to_uint64(), allocations=1UL,
      allocation_size=source.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let result = PngDecoder::decode_graya16(
    @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=128UL, allocations=3UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap()
  let decoded = result.image()
  let image = decoded.view()
  let format = decoded.descriptor().format()
  inspect(format.component() == @model.ComponentType::U16, content="true")
  inspect(format.channels() == @model.ChannelOrder::GrayAlpha, content="true")
  inspect(format.layout() == @model.PlaneLayout::Packed, content="true")
  inspect(format.endianness() == @model.Endianness::Little, content="true")
  inspect(decoded.metadata().orientation() == @model.Orientation::TopLeft, content="true")
  inspect(decoded.metadata().alpha() == Some(@color.AlphaMode::Straight), content="true")
  inspect(decoded.metadata().profile().is_builtin_srgb(), content="true")
  inspect(result.bytes_read() == source.length().to_uint64(), content="true")
  for expected in [(0UL, 0UL, b'\x34'), (0UL, 1UL, b'\x12'), (0UL, 2UL, b'\xc5'), (0UL, 3UL, b'\xa7'), (1UL, 0UL, b'\x0f'), (1UL, 1UL, b'\xbe'), (1UL, 2UL, b'\x76'), (1UL, 3UL, b'\x5a')] {
    let (x, component, value) = expected
    inspect(image.get_component_byte(x, 0UL, component / 2UL, component % 2UL).unwrap() == value, content="true")
  }
  let generic = @codec.ImageDecoder::decode(
    PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true, preserve_opaque_metadata=false,
    ),
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=128UL, allocations=3UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap().image().view()
  for channel = 0UL; channel < 3UL; channel = channel + 1UL {
    inspect(generic.get_byte(0UL, 0UL, channel).unwrap() == b'\x12', content="true")
  }
  inspect(generic.get_byte(0UL, 0UL, 3UL).unwrap() == b'\xa7', content="true")

  let srgb_source = png_test_graya16_srgb_literal()
  let srgb_owner = @bytes.OwnedBytes::from_bytes(
    srgb_source,
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=srgb_source.length().to_uint64(), allocations=1UL,
      allocation_size=srgb_source.length().to_uint64(), width=0UL, height=0UL,
      pixels=0UL, depth=0UL, work=0UL,
    )),
  ).unwrap()
  let srgb = PngDecoder::decode_graya16(
    @io.MemoryReader::new(srgb_owner.view()) as &@io.Reader,
    @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
    png_test_limits(),
    @budget.Budget::new(@budget.ResourceLimits::new(
      bytes=160UL, allocations=4UL, allocation_size=64UL, width=4UL,
      height=4UL, pixels=16UL, depth=0UL, work=128UL,
    )),
    @error.Diagnostics::new(),
  ).unwrap()
  inspect(srgb.bytes_read() == srgb_source.length().to_uint64(), content="true")
  inspect(srgb.image().metadata().opaque_metadata().length() == 1, content="true")
  inspect(srgb.image().view().get_component_byte(1UL, 0UL, 1UL, 1UL).unwrap() == b'\x5a', content="true")
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

///| The legacy Phase-20 corpus now crosses several current decoder stages.
/// These explicit stages prevent a decoder result from selecting its own oracle.
priv enum PngLegacyStructuralStage {
  InheritedPreTransport
  CurrentSemanticOrFixedLength
  ActiveIdatZlibTerminal
  OpaqueMetadataBoundary
  PreflightResource
}

///|
priv enum PngLegacyBudgetMode {
  Fixture
  DecodeCapable
}

///|
priv struct PngLegacyExpectation {
  stage : PngLegacyStructuralStage
  category : @error.ErrorCategory
  code : @error.ErrorCode
  context : String?
  budget_mode : PngLegacyBudgetMode
  assert_immutable_budget : Bool
}

///|
fn png_test_legacy_decode_budget() -> @budget.Budget {
  @budget.Budget::new(@budget.ResourceLimits::new(
    bytes=8192UL, allocations=8UL, allocation_size=4096UL, width=16UL,
    height=16UL, pixels=256UL, depth=0UL, work=8192UL,
  ))
}

///|
fn png_test_legacy_generated_error_category(category : String) -> @error.ErrorCategory {
  match category {
    "data" => @error.ErrorCategory::Data
    "resource" => @error.ErrorCategory::Resource
    "capability" => @error.ErrorCategory::Capability
    _ => @error.ErrorCategory::Data
  }
}

///|
fn png_test_legacy_generated_error_code(code : String) -> @error.ErrorCode {
  match code {
    "unexpected-end" => @error.ErrorCode::UnexpectedEndOfStream
    "budget-exceeded" => @error.ErrorCode::BudgetExceeded
    "capability-unavailable" => @error.ErrorCode::CapabilityUnavailable
    _ => @error.ErrorCode::InvalidEncoding
  }
}

///|
fn png_test_legacy_inherited_expectation(item : PngGeneratedCase) -> PngLegacyExpectation {
  {
    stage: if item.code == "budget-exceeded" {
      PngLegacyStructuralStage::PreflightResource
    } else {
      PngLegacyStructuralStage::InheritedPreTransport
    },
    category: png_test_legacy_generated_error_category(item.category),
    code: png_test_legacy_generated_error_code(item.code),
    context: if item.context == "" { None } else { Some(item.context) },
    budget_mode: PngLegacyBudgetMode::Fixture,
    // Current parser stages may charge their local scratch. The old immutable
    // contract is retained only for the below-limit preflight resource rows.
    assert_immutable_budget: item.immutable_caller_state && item.code == "budget-exceeded",
  }
}

///| One authoritative current-stage map for every generated Phase-20 record.
fn png_test_legacy_expectation(item : PngGeneratedCase) -> PngLegacyExpectation {
  let zlib = {
    stage: PngLegacyStructuralStage::ActiveIdatZlibTerminal,
    category: @error.ErrorCategory::Data,
    code: @error.ErrorCode::InvalidEncoding,
    context: Some("zlib-truncated"),
    budget_mode: PngLegacyBudgetMode::DecodeCapable,
    assert_immutable_budget: false,
  }
  match item.id {
    // Current semantic parsers validate these fixed-size chunks before payload CRC.
    "semantic-crc" => {
      stage: PngLegacyStructuralStage::CurrentSemanticOrFixedLength,
      category: @error.ErrorCategory::Data,
      code: @error.ErrorCode::InvalidEncoding,
      context: Some("png-semantic-chunk"),
      budget_mode: PngLegacyBudgetMode::Fixture,
      assert_immutable_budget: false,
    }
    "semantic-chrm" => {
      stage: PngLegacyStructuralStage::CurrentSemanticOrFixedLength,
      category: @error.ErrorCategory::Data,
      code: @error.ErrorCode::InvalidEncoding,
      context: Some("png-chrm-length"),
      budget_mode: PngLegacyBudgetMode::Fixture,
      assert_immutable_budget: false,
    }
    "semantic-gama" => {
      stage: PngLegacyStructuralStage::CurrentSemanticOrFixedLength,
      category: @error.ErrorCategory::Data,
      code: @error.ErrorCode::InvalidEncoding,
      context: Some("png-gama-length"),
      budget_mode: PngLegacyBudgetMode::Fixture,
      assert_immutable_budget: false,
    }
    "semantic-iccp" => {
      stage: PngLegacyStructuralStage::CurrentSemanticOrFixedLength,
      category: @error.ErrorCategory::Data,
      code: @error.ErrorCode::InvalidEncoding,
      context: Some("png-iccp-envelope"),
      budget_mode: PngLegacyBudgetMode::Fixture,
      assert_immutable_budget: false,
    }
    "semantic-srgb" => {
      stage: PngLegacyStructuralStage::CurrentSemanticOrFixedLength,
      category: @error.ErrorCategory::Data,
      code: @error.ErrorCode::InvalidEncoding,
      context: Some("png-srgb-length"),
      budget_mode: PngLegacyBudgetMode::Fixture,
      assert_immutable_budget: false,
    }
    "ancillary-preserve" => {
      stage: PngLegacyStructuralStage::OpaqueMetadataBoundary,
      category: @error.ErrorCategory::Capability,
      code: @error.ErrorCode::CapabilityUnavailable,
      context: Some("opaque-metadata-preservation"),
      budget_mode: PngLegacyBudgetMode::Fixture,
      assert_immutable_budget: false,
    }
    // These formerly stopped at the Phase-20 capability boundary. They now
    // enter the real DEFLATE pipeline with an intentionally decode-capable budget.
    "ihdr-colour-grayscale" | "ihdr-colour-grayscale-alpha" |
    "ihdr-interlace-method" | "split-contiguous-idat" |
    "ancillary-after-idat" | "separated-idat" | "truncated-iend-crc" |
    "iend-crc" | "nonempty-iend" | "duplicate-iend" | "post-iend-idat" |
    "trailing-byte" | "strict-eof-trailing-at-max" | "ancillary-discard" |
    "rgb-structural" | "rgba-structural" | "rgba-at-ceiling" |
    "rgb-exact-input-ceiling" | "input-57-below" | "width-at-ceiling" |
    "height-at-ceiling" | "pixels-at-ceiling" |
    "shared-output-at-ceiling" | "output-bytes-at-ceiling" |
    "work-at-ceiling" | "budget-bytes-at-ceiling" |
    "budget-allocations-at-ceiling" | "budget-allocation-size-at-ceiling" |
    "budget-width-at-ceiling" | "budget-height-at-ceiling" |
    "budget-pixels-at-ceiling" | "budget-work-at-ceiling" => zlib
    _ => png_test_legacy_inherited_expectation(item)
  }
}

///|
test "generated Phase-20 structural corpus keeps strict PngDecoder terminal errors" {
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
    let expected = png_test_legacy_expectation(item)
    let budget = match expected.budget_mode {
      PngLegacyBudgetMode::Fixture => png_test_budget_from_generated(item)
      PngLegacyBudgetMode::DecodeCapable => png_test_legacy_decode_budget()
    }
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
    let stage = match expected.stage {
      PngLegacyStructuralStage::InheritedPreTransport => "pre-transport"
      PngLegacyStructuralStage::CurrentSemanticOrFixedLength => "semantic"
      PngLegacyStructuralStage::ActiveIdatZlibTerminal => "active-idat"
      PngLegacyStructuralStage::OpaqueMetadataBoundary => "opaque-metadata"
      PngLegacyStructuralStage::PreflightResource => "preflight-resource"
    }
    if error.category() != expected.category || error.code() != expected.code ||
      error.context() != expected.context {
      let actual = match error.context() { Some(value) => value; None => "none" }
      fail("generated PNG " + stage + " terminal mismatch: " + item.id + ": " + actual)
    }
    if expected.assert_immutable_budget &&
      !png_test_remaining_unchanged(before, budget.remaining()) {
      fail("generated PNG budget mismatch: " + item.id)
    }
    inspect(diagnostics.length(), content="0")
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
    @budget.Budget::new(@budget.ResourceLimits::new(bytes=item.budget_bytes, allocations=item.budget_allocations, allocation_size=item.budget_allocation_size, width=64UL, height=16UL, pixels=1024UL, depth=0UL, work=item.max_work)),
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
        if descriptor.supports_reference_operations() {
          fail("generated PNG retained non-sRGB source unexpectedly supports reference operations: " + item.id)
        }
        let writer = @io.MemoryWriter::new(
          128UL,
          @budget.Budget::new(@budget.ResourceLimits::new(
            bytes=128UL, allocations=8UL, allocation_size=128UL, width=64UL,
            height=16UL, pixels=1024UL, depth=0UL, work=1024UL,
          )),
        ).unwrap()
        let error = @codec.ImageEncoder::encode(
          PngEncoder::new(), result.image().view(), writer as &@io.Writer,
          @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
          @codec.CodecLimits::new(max_probe_bytes=8UL, max_input_bytes=4096UL, max_output_bytes=1024UL, max_width=64UL, max_height=16UL, max_pixels=1024UL, max_work=1024UL),
          @budget.Budget::new(@budget.ResourceLimits::new(
            bytes=1024UL, allocations=8UL, allocation_size=1024UL, width=64UL,
            height=16UL, pixels=1024UL, depth=0UL, work=1024UL,
          )),
          @error.Diagnostics::new(),
        ).unwrap_err()
        if error.category() != @error.ErrorCategory::Capability ||
          error.code() != @error.ErrorCode::CapabilityUnavailable ||
          writer.position() != 0UL {
          fail("generated PNG retained non-sRGB encoder boundary mismatch: " + item.id)
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
            let baseline_metadata = baseline_descriptor.metadata()
            let metadata = descriptor.metadata()
            if baseline_metadata.space() != metadata.space() ||
              baseline_metadata.transfer() != metadata.transfer() ||
              baseline_metadata.profile().is_builtin_srgb() != metadata.profile().is_builtin_srgb() ||
              baseline_metadata.opaque_metadata().length() != metadata.opaque_metadata().length() ||
              baseline_descriptor.supports_reference_operations() != descriptor.supports_reference_operations() {
              fail("generated PNG accepted boundary metadata mismatch: " + item.id)
            }
            for index = 0; index < metadata.opaque_metadata().length(); index = index + 1 {
              let baseline_entry = baseline_metadata.opaque_metadata().entry(index).unwrap()
              let entry = metadata.opaque_metadata().entry(index).unwrap()
              if baseline_entry.canonical_key() != entry.canonical_key() || baseline_entry.value().length() != entry.value().length() {
                fail("generated PNG accepted boundary opaque metadata shape mismatch: " + item.id)
              }
              for value_index = 0UL; value_index < entry.value().length(); value_index = value_index + 1UL {
                if baseline_entry.value().get(value_index).unwrap() != entry.value().get(value_index).unwrap() {
                  fail("generated PNG accepted boundary opaque metadata value mismatch: " + item.id)
                }
              }
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
