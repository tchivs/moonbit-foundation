///|
fn codec_limits() -> @codec.CodecLimits {
  @codec.CodecLimits::new(
    max_probe_bytes=8UL,
    max_input_bytes=64UL,
    max_output_bytes=64UL,
    max_width=8UL,
    max_height=8UL,
    max_pixels=64UL,
    max_work=128UL,
  )
}

///|
fn prefix_view(value : Bytes) -> @bytes.ByteView {
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=value.length().to_uint64(),
      allocations=1UL,
      allocation_size=value.length().to_uint64(),
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
  @bytes.OwnedBytes::from_bytes(value, budget).unwrap().view()
}

///|
struct PrefixDecoder {}

///|
impl @codec.ImageDecoder for PrefixDecoder with fn probe(
  _self,
  prefix,
  limits,
  _diagnostics,
) {
  if prefix.length() > limits.max_probe_bytes() {
    return Err(@codec.capability_unavailable("codec-probe", "probe-limit"))
  }
  if prefix.length() < 2UL {
    Ok(@codec.ProbeOutcome::NeedMore(2UL))
  } else if prefix.get(0UL).unwrap() == b'M' && prefix.get(1UL).unwrap() == b'N' {
    Ok(@codec.ProbeOutcome::Match)
  } else {
    Ok(@codec.ProbeOutcome::NoMatch)
  }
}

///|
impl @codec.ImageDecoder for PrefixDecoder with fn decode(
  _self,
  reader,
  _options,
  _limits,
  _budget,
  _diagnostics,
) {
  let scratch_budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=3UL,
      allocations=1UL,
      allocation_size=3UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=0UL,
    ),
  )
  let scratch = @bytes.OwnedBytes::new(3UL, scratch_budget).unwrap()
  match
    scratch.with_mut(0UL, 3UL, fn(lease) { @io.read_exact(reader, lease) }) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Err(@codec.capability_unavailable("codec-decode", "test-probe-only"))
}

///|
struct ShortProgressReader {
  mut next : Byte
  mut calls : Int
}

///|
impl @io.Reader for ShortProgressReader with fn read(self, destination) {
  self.calls = self.calls + 1
  ignore(destination.set(0UL, self.next))
  self.next = (self.next.to_int() + 1).to_byte()
  @io.ReadOutcome::Progress(1UL)
}

///|
test "probe uses only caller-owned prefix bytes" {
  let decoder = PrefixDecoder::{  }
  let diagnostics = @error.Diagnostics::new()
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      prefix_view(b""),
      codec_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::NeedMore(2UL),
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      prefix_view(b"M"),
      codec_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::NeedMore(2UL),
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      prefix_view(b"MN"),
      codec_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::Match,
    content="true",
  )
  inspect(
    @codec.ImageDecoder::probe(
      decoder,
      prefix_view(b"NO"),
      codec_limits(),
      diagnostics,
    ).unwrap() ==
    @codec.ProbeOutcome::NoMatch,
    content="true",
  )
}

///|
test "decode accepts a non-seeking short-progress reader" {
  let reader = ShortProgressReader::{ next: b'A', calls: 0 }
  let decoder = PrefixDecoder::{  }
  let output_budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=64UL,
      allocations=4UL,
      allocation_size=64UL,
      width=8UL,
      height=8UL,
      pixels=64UL,
      depth=0UL,
      work=128UL,
    ),
  )
  let result = @codec.ImageDecoder::decode(
    decoder,
    reader as &@io.Reader,
    @codec.DecodeOptions::new(
      require_complete_input=true,
      preserve_opaque_metadata=true,
    ),
    codec_limits(),
    output_budget,
    @error.Diagnostics::new(),
  )
  match result {
    Err(error) => {
      inspect(
        error.code() == @error.ErrorCode::CapabilityUnavailable,
        content="true",
      )
      inspect(error.context() == Some("test-probe-only"), content="true")
    }
    Ok(_) => fail("the test decoder intentionally has no concrete codec")
  }
  inspect(reader.calls, content="3")
}

///|
test "codec options and limits are explicit and inspectable" {
  let limits = codec_limits()
  inspect(limits.max_input_bytes(), content="64")
  inspect(limits.max_output_bytes(), content="64")
  inspect(limits.max_width(), content="8")
  inspect(limits.max_height(), content="8")
  inspect(limits.max_pixels(), content="64")
  inspect(limits.max_work(), content="128")
  let decode = @codec.DecodeOptions::new(
    require_complete_input=true,
    preserve_opaque_metadata=true,
  )
  inspect(decode.require_complete_input(), content="true")
  inspect(decode.preserve_opaque_metadata(), content="true")
  let encode = @codec.EncodeOptions::new(
    lossless_required=true,
    preserve_opaque_metadata=true,
  )
  inspect(encode.lossless_required(), content="true")
  inspect(encode.preserve_opaque_metadata(), content="true")
}
