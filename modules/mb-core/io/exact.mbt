///|
fn exact_error(
  code : @error.ErrorCode,
  operation : String,
  requested : UInt64,
  completed : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    code,
    operation~,
    requested~,
    completed~,
  )
}

///|
fn propagate_stream_error(
  error : @error.CoreError,
  operation : String,
  requested : UInt64,
  completed : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    error.category(),
    error.code(),
    operation~,
    requested~,
    completed~,
  )
}

///|
fn invalid_progress(
  operation : String,
  progress : UInt64,
  remaining : UInt64,
  completed : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation~,
    requested=progress,
    completed~,
    limit=remaining,
  )
}

///|
/// Fill the complete destination through explicit partial transitions. This
/// consumes the logical mutable lease into disjoint prefixes so every backend
/// call sees only the still-unfilled suffix.
pub fn read_exact(
  reader : &Reader,
  destination : @bytes.MutByteLease,
) -> Result[UInt64, @error.CoreError] {
  let requested = destination.length()
  if requested == 0UL {
    return Ok(0UL)
  }
  let mut completed = 0UL
  let mut remaining = destination
  while completed < requested {
    match reader.read(ReadWindow::from_lease(remaining)) {
      Progress(count) => {
        if count == 0UL {
          remaining.release()
          return Err(
            exact_error(
              @error.ErrorCode::NoProgress,
              "read_exact",
              requested,
              completed,
            ),
          )
        }
        if count > remaining.length() {
          let limit = remaining.length()
          remaining.release()
          return Err(invalid_progress("read_exact", count, limit, completed))
        }
        let (used, tail) = match remaining.split_mut(count) {
          Ok(value) => value
          Err(error) => {
            remaining.release()
            return Err(error)
          }
        }
        used.release()
        remaining = tail
        completed = completed + count
      }
      EndOfStream => {
        remaining.release()
        return Err(
          exact_error(
            @error.ErrorCode::UnexpectedEndOfStream,
            "read_exact",
            requested,
            completed,
          ),
        )
      }
      Failed(error, call_completed) => {
        if call_completed > remaining.length() {
          let limit = remaining.length()
          remaining.release()
          return Err(
            invalid_progress("read_exact", call_completed, limit, completed),
          )
        }
        remaining.release()
        let total = completed + call_completed
        return Err(
          propagate_stream_error(error, "read_exact", requested, total),
        )
      }
    }
  }
  remaining.release()
  Ok(completed)
}

///|
/// Write the complete source through checked zero-copy subviews. A backend that
/// reports zero progress fails after one transition instead of spinning.
pub fn write_all(
  writer : &Writer,
  source : @bytes.ByteView,
) -> Result[UInt64, @error.CoreError] {
  let requested = source.length()
  if requested == 0UL {
    return Ok(0UL)
  }
  let mut completed = 0UL
  while completed < requested {
    let remaining = requested - completed
    let tail = match source.subview(completed, remaining) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match writer.write(tail) {
      Progress(count) => {
        if count == 0UL {
          return Err(
            exact_error(
              @error.ErrorCode::NoProgress,
              "write_all",
              requested,
              completed,
            ),
          )
        }
        if count > remaining {
          return Err(invalid_progress("write_all", count, remaining, completed))
        }
        completed = completed + count
      }
      Failed(error, call_completed) => {
        if call_completed > remaining {
          return Err(
            invalid_progress("write_all", call_completed, remaining, completed),
          )
        }
        let total = completed + call_completed
        return Err(propagate_stream_error(error, "write_all", requested, total))
      }
    }
  }
  Ok(completed)
}
