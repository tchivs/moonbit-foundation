///|
/// A portable eager decoder for QOI 1.0 images.
pub struct QoiDecoder {}

///|
pub fn QoiDecoder::new() -> QoiDecoder {
  QoiDecoder::{  }
}

///|
/// Inspect only caller-owned prefix bytes. This helper never reads a Reader.
fn _probe_qoi_prefix(prefix : @bytes.ByteView) -> @codec.ProbeOutcome {
  if prefix.length() < 4UL {
    @codec.ProbeOutcome::NeedMore(4UL)
  } else if
    prefix.get(0UL).unwrap() == b'q' && prefix.get(1UL).unwrap() == b'o' &&
    prefix.get(2UL).unwrap() == b'i' && prefix.get(3UL).unwrap() == b'f' {
    @codec.ProbeOutcome::Match
  } else {
    @codec.ProbeOutcome::NoMatch
  }
}
