///|
/// A portable eager decoder for QOI 1.0 images.
pub struct QoiDecoder {}

///|
pub fn QoiDecoder::new() -> QoiDecoder {
  QoiDecoder::{  }
}

///|
/// A caller-chunk-fed QOI 1.0 decoder. Completion is declared explicitly with
/// `finish`; it does not change the eager Reader-based codec contract.
pub struct QoiStreamDecoder {
  priv limits : @codec.CodecLimits
  priv budget : @budget.Budget
  priv _diagnostics : @error.Diagnostics
  priv mut state : QoiStreamState
  priv mut consumed_total : UInt64
}

///|
pub(all) enum QoiStreamPushOutcome {
  NeedInput
  Failed(@error.CoreError)
}

///|
pub struct QoiStreamPushResult {
  priv consumed_value : UInt64
  priv outcome_value : QoiStreamPushOutcome
}

///|
pub fn QoiStreamPushResult::consumed(self : QoiStreamPushResult) -> UInt64 {
  self.consumed_value
}

///|
pub fn QoiStreamPushResult::outcome(
  self : QoiStreamPushResult,
) -> QoiStreamPushOutcome {
  self.outcome_value
}

///|
pub fn QoiStreamDecoder::new(
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> QoiStreamDecoder {
  {
    limits,
    budget,
    _diagnostics: diagnostics,
    state: QoiStreamState::Header([]),
    consumed_total: 0UL,
  }
}

///|
/// A portable eager encoder for canonical QOI 1.0 images.
pub struct QoiEncoder {}

///|
pub fn QoiEncoder::new() -> QoiEncoder {
  QoiEncoder::{  }
}

///|
/// A zero-copy caller-lease QOI 1.0 encoder. `new` retains the supplied
/// immutable ImageView; callers must keep its backing image unchanged until
/// this encoder reaches terminal state. No source snapshot, lock, or output
/// staging buffer is created.
pub struct QoiStreamEncoder {
  priv mut state : QoiStreamEncodeState
  priv mut pending : Bytes
  priv mut pending_offset : UInt64
  priv mut total_copied : UInt64
  priv total_length : UInt64
  priv _disposition : @metadata.MetadataDisposition
}

///|
pub(all) enum QoiStreamPullOutcome {
  NeedOutput
  Finished
  Failed(@error.CoreError)
}

///|
pub struct QoiStreamPullResult {
  priv written_value : UInt64
  priv total_written_value : UInt64
  priv outcome_value : QoiStreamPullOutcome
}

///|
pub fn QoiStreamPullResult::written(self : QoiStreamPullResult) -> UInt64 {
  self.written_value
}

///|
pub fn QoiStreamPullResult::total_written(
  self : QoiStreamPullResult,
) -> UInt64 {
  self.total_written_value
}

///|
pub fn QoiStreamPullResult::outcome(
  self : QoiStreamPullResult,
) -> QoiStreamPullOutcome {
  self.outcome_value
}

///|
/// Inspect only caller-owned prefix bytes. This helper never reads a Reader.
fn _probe_qoi_prefix(prefix : @bytes.ByteView) -> @codec.ProbeOutcome {
  if prefix.length() < 4UL {
    @codec.ProbeOutcome::NeedMore(4UL)
  } else if prefix.get(0UL).unwrap() == b'q' &&
    prefix.get(1UL).unwrap() == b'o' &&
    prefix.get(2UL).unwrap() == b'i' &&
    prefix.get(3UL).unwrap() == b'f' {
    @codec.ProbeOutcome::Match
  } else {
    @codec.ProbeOutcome::NoMatch
  }
}
