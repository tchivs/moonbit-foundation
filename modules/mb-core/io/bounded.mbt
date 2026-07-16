///|
fn bounded_error(
  operation : String,
  requested : UInt64,
  limit : UInt64,
  completed : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::State,
    @error.ErrorCode::InvalidRange,
    operation~,
    requested~,
    completed~,
    limit~,
  )
}

///|
fn validate_transition_progress(
  progress : UInt64,
  allowed : UInt64,
  completed : UInt64,
  operation : String,
) -> Result[UInt64, @error.CoreError] {
  if progress > allowed {
    Err(bounded_error(operation, progress, allowed, completed))
  } else {
    Ok(completed + progress)
  }
}

///|
/// A non-seeking logical window over any Reader, including another bounded or
/// otherwise non-seekable source.
pub struct BoundedReader {
  priv source : &Reader
  priv length_value : UInt64
  priv mut cursor : UInt64
}

///|
pub fn BoundedReader::new(source : &Reader, length : UInt64) -> BoundedReader {
  { source, length_value: length, cursor: 0UL }
}

///|
pub fn BoundedReader::position(self : BoundedReader) -> UInt64 {
  self.cursor
}

///|
pub fn BoundedReader::remaining(self : BoundedReader) -> UInt64 {
  self.length_value - self.cursor
}

///|
pub impl Reader for BoundedReader with fn read(self, destination) {
  if destination.length() == 0UL {
    return Progress(0UL)
  }
  if self.cursor == self.length_value {
    return EndOfStream
  }
  let logical_remaining = self.length_value - self.cursor
  let allowed = if destination.length() < logical_remaining {
    destination.length()
  } else {
    logical_remaining
  }
  match self.source.read(destination.limit(allowed)) {
    Progress(count) =>
      match
        validate_transition_progress(
          count,
          allowed,
          self.cursor,
          "bounded_read",
        ) {
        Err(error) => Failed(error, 0UL)
        Ok(position) => {
          self.cursor = position
          Progress(count)
        }
      }
    EndOfStream => EndOfStream
    Failed(error, completed) =>
      match
        validate_transition_progress(
          completed,
          allowed,
          self.cursor,
          "bounded_read",
        ) {
        Err(validation) => Failed(validation, 0UL)
        Ok(position) => {
          self.cursor = position
          Failed(error, completed)
        }
      }
  }
}

///|
/// A non-seeking logical window over any Writer. Each delegated call receives
/// an immutable subview capped to the remaining declared output length.
pub struct BoundedWriter {
  priv destination : &Writer
  priv length_value : UInt64
  priv mut cursor : UInt64
}

///|
pub fn BoundedWriter::new(
  destination : &Writer,
  length : UInt64,
) -> BoundedWriter {
  { destination, length_value: length, cursor: 0UL }
}

///|
pub fn BoundedWriter::position(self : BoundedWriter) -> UInt64 {
  self.cursor
}

///|
pub fn BoundedWriter::remaining(self : BoundedWriter) -> UInt64 {
  self.length_value - self.cursor
}

///|
pub impl Writer for BoundedWriter with fn write(self, source) {
  if source.length() == 0UL {
    return Progress(0UL)
  }
  if self.cursor == self.length_value {
    return Failed(
      bounded_error("bounded_write", source.length(), 0UL, 0UL),
      0UL,
    )
  }
  let logical_remaining = self.length_value - self.cursor
  let allowed = if source.length() < logical_remaining {
    source.length()
  } else {
    logical_remaining
  }
  let window = match source.subview(0UL, allowed) {
    Err(error) => return Failed(error, 0UL)
    Ok(value) => value
  }
  match self.destination.write(window) {
    Progress(count) =>
      match
        validate_transition_progress(
          count,
          allowed,
          self.cursor,
          "bounded_write",
        ) {
        Err(error) => Failed(error, 0UL)
        Ok(position) => {
          self.cursor = position
          Progress(count)
        }
      }
    Failed(error, completed) =>
      match
        validate_transition_progress(
          completed,
          allowed,
          self.cursor,
          "bounded_write",
        ) {
        Err(validation) => Failed(validation, 0UL)
        Ok(position) => {
          self.cursor = position
          Failed(error, completed)
        }
      }
  }
}
