///|
priv enum QoiStreamEncodeState {
  Tokens(QoiEncodeTokens)
  Marker
  Finished
  Failed
}

///|
fn qoi_stream_encode_state_error() -> @error.CoreError {
  qoi_encode_error(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    "qoi-stream-terminal",
  )
}

///|
pub fn QoiStreamEncoder::new(
  source : @storage.ImageView,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  _diagnostics : @error.Diagnostics,
) -> Result[QoiStreamEncoder, @error.CoreError] {
  let disposition = match qoi_empty_disposition() {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let (channels, color_space, total) = match qoi_encode_preflight(source, limits, budget) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tokens = match qoi_encode_tokens_new(source, channels) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    state: QoiStreamEncodeState::Tokens(tokens),
    pending: qoi_encode_header(source.width(), source.height(), channels, color_space),
    pending_offset: 0UL,
    total_copied: 0UL,
    total_length: total,
    _disposition: disposition,
  })
}

///|
fn QoiStreamEncoder::fail(self : QoiStreamEncoder, error : @error.CoreError) -> Unit {
  ignore(error)
  self.state = QoiStreamEncodeState::Failed
}

///|
fn QoiStreamEncoder::next_pending(self : QoiStreamEncoder) -> Result[Unit, @error.CoreError] {
  match self.state {
    QoiStreamEncodeState::Tokens(tokens) => match tokens.next() {
      Err(error) => Err(error)
      Ok(Some(token)) => {
        self.pending = token
        self.pending_offset = 0UL
        Ok(())
      }
      Ok(None) => {
        self.state = QoiStreamEncodeState::Marker
        self.pending = b"\x00\x00\x00\x00\x00\x00\x00\x01"
        self.pending_offset = 0UL
        Ok(())
      }
    }
    _ => Ok(())
  }
}

///|
pub fn QoiStreamEncoder::pull(
  self : QoiStreamEncoder,
  destination : @bytes.MutByteLease,
) -> QoiStreamPullResult {
  match self.state {
    QoiStreamEncodeState::Finished | QoiStreamEncodeState::Failed => return {
      written_value: 0UL,
      total_written_value: self.total_copied,
      outcome_value: QoiStreamPullOutcome::Failed(qoi_stream_encode_state_error()),
    }
    _ => ()
  }
  let mut written = 0UL
  while written < destination.length() {
    if self.pending_offset == self.pending.length().to_uint64() {
      match self.state {
        QoiStreamEncodeState::Marker => {
          self.state = QoiStreamEncodeState::Finished
          return {
            written_value: written,
            total_written_value: self.total_copied,
            outcome_value: QoiStreamPullOutcome::Finished,
          }
        }
        _ => match self.next_pending() {
          Err(error) => {
            self.fail(error)
            return {
              written_value: written,
              total_written_value: self.total_copied,
              outcome_value: QoiStreamPullOutcome::Failed(error),
            }
          }
          Ok(_) => ()
        }
      }
    }
    if self.pending_offset < self.pending.length().to_uint64() {
      let byte = self.pending[self.pending_offset.to_int()]
      match destination.set(written, byte) {
        Err(error) => {
          self.fail(error)
          return {
            written_value: written,
            total_written_value: self.total_copied,
            outcome_value: QoiStreamPullOutcome::Failed(error),
          }
        }
        Ok(_) => {
          self.pending_offset = self.pending_offset + 1UL
          self.total_copied = self.total_copied + 1UL
          written = written + 1UL
          if self.state is QoiStreamEncodeState::Marker &&
            self.pending_offset == self.pending.length().to_uint64() &&
            self.total_copied == self.total_length {
            self.state = QoiStreamEncodeState::Finished
            return {
              written_value: written,
              total_written_value: self.total_copied,
              outcome_value: QoiStreamPullOutcome::Finished,
            }
          }
        }
      }
    }
  }
  {
    written_value: written,
    total_written_value: self.total_copied,
    outcome_value: QoiStreamPullOutcome::NeedOutput,
  }
}
