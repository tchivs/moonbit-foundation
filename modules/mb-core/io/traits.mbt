///|
/// A backend-neutral read transition. `Progress(0)` is invalid and exact
/// helpers convert it to `NoProgress`; EOS is never encoded as a zero count.
pub(all) enum ReadOutcome {
  Progress(UInt64)
  EndOfStream
  Failed(@error.CoreError, UInt64)
}

///|
/// A backend-neutral write transition. The count on `Failed` records bytes
/// completed by that call before the failure became observable.
pub(all) enum WriteOutcome {
  Progress(UInt64)
  Failed(@error.CoreError, UInt64)
}

///|
/// Open stream capability for callers that can supply an exclusive mutable
/// destination lease.
pub(open) trait Reader {
  fn read(Self, @bytes.MutByteLease) -> ReadOutcome
}

///|
/// Open stream capability for callers that can supply an immutable source
/// view.
pub(open) trait Writer {
  fn write(Self, @bytes.ByteView) -> WriteOutcome
}

///|
pub(all) enum SeekOrigin {
  Start
  Current
  End
} derive(Eq)

///|
/// Seeking is deliberately separate from Reader and Writer. APIs request a
/// `&Seeker` only when positioning is genuinely required.
pub(open) trait Seeker {
  fn seek(Self, SeekOrigin, Int64) -> Result[UInt64, @error.CoreError]
}

///|
fn seek_error(requested : UInt64, limit : UInt64) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidOffset,
    operation="seek",
    requested~,
    limit~,
  )
}

///|
fn negative_delta_magnitude(delta : Int64) -> UInt64 {
  if delta == -9223372036854775807L - 1L {
    9223372036854775808UL
  } else {
    (-delta).reinterpret_as_uint64()
  }
}

///|
/// Validate origin, signed delta, and logical window before a provider mutates
/// its cursor. Exact zero and exact end are valid positions.
pub fn checked_seek_position(
  origin : SeekOrigin,
  delta : Int64,
  current : UInt64,
  length : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if current > length {
    return Err(seek_error(current, length))
  }
  let base = match origin {
    Start => 0UL
    Current => current
    End => length
  }
  if delta >= 0L {
    let amount = delta.reinterpret_as_uint64()
    match @checked.checked_add(base, amount) {
      Err(_) => Err(seek_error(amount, length - base))
      Ok(position) =>
        if position > length {
          Err(seek_error(amount, length - base))
        } else {
          Ok(position)
        }
    }
  } else {
    let amount = negative_delta_magnitude(delta)
    match @checked.checked_sub(base, amount) {
      Err(_) => Err(seek_error(amount, base))
      Ok(position) => Ok(position)
    }
  }
}
