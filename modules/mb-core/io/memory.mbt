///|
fn stream_capacity_error(
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
pub struct MemoryReader {
  priv source : @bytes.ByteView
  priv mut cursor : UInt64
}

///|
pub fn MemoryReader::new(source : @bytes.ByteView) -> MemoryReader {
  { source, cursor: 0UL }
}

///|
pub fn MemoryReader::position(self : MemoryReader) -> UInt64 {
  self.cursor
}

///|
pub impl Reader for MemoryReader with fn read(self, destination) {
  if destination.length() == 0UL {
    return Progress(0UL)
  }
  let length = self.source.length()
  if self.cursor == length {
    return EndOfStream
  }
  let available = length - self.cursor
  let count = if destination.length() < available {
    destination.length()
  } else {
    available
  }
  let mut copied = 0UL
  while copied < count {
    let value = match self.source.get(self.cursor + copied) {
      Ok(value) => value
      Err(error) => {
        self.cursor = self.cursor + copied
        return Failed(error, copied)
      }
    }
    match destination.set(copied, value) {
      Err(error) => {
        self.cursor = self.cursor + copied
        return Failed(error, copied)
      }
      Ok(_) => copied = copied + 1UL
    }
  }
  self.cursor = self.cursor + copied
  Progress(copied)
}

///|
pub impl Seeker for MemoryReader with fn seek(self, origin, delta) {
  match
    checked_seek_position(origin, delta, self.cursor, self.source.length()) {
    Err(error) => Err(error)
    Ok(position) => {
      self.cursor = position
      Ok(position)
    }
  }
}

///|
pub struct MemoryWriter {
  priv destination : @bytes.OwnedBytes
  priv mut cursor : UInt64
}

///|
pub fn MemoryWriter::new(
  capacity : UInt64,
  budget : @budget.Budget,
) -> Result[MemoryWriter, @error.CoreError] {
  match @bytes.OwnedBytes::new(capacity, budget) {
    Err(error) => Err(error)
    Ok(destination) => Ok({ destination, cursor: 0UL })
  }
}

///|
pub fn MemoryWriter::position(self : MemoryWriter) -> UInt64 {
  self.cursor
}

///|
pub fn MemoryWriter::capacity(self : MemoryWriter) -> UInt64 {
  self.destination.length()
}

///|
pub fn MemoryWriter::view(self : MemoryWriter) -> @bytes.ByteView {
  self.destination.view()
}

///|
pub impl Writer for MemoryWriter with fn write(self, source) {
  if source.length() == 0UL {
    return Progress(0UL)
  }
  let capacity = self.destination.length()
  if self.cursor == capacity {
    return Failed(
      stream_capacity_error("memory_write", source.length(), 0UL, 0UL),
      0UL,
    )
  }
  let available = capacity - self.cursor
  let count = if source.length() < available {
    source.length()
  } else {
    available
  }
  let start = self.cursor
  let result = self.destination.with_mut(start, count, fn(destination) {
    let mut copied = 0UL
    while copied < count {
      let value = match source.get(copied) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      match destination.set(copied, value) {
        Err(error) => return Err(error)
        Ok(_) => copied = copied + 1UL
      }
    }
    Ok(copied)
  })
  match result {
    Err(error) => Failed(error, 0UL)
    Ok(copied) => {
      self.cursor = self.cursor + copied
      Progress(copied)
    }
  }
}

///|
pub impl Seeker for MemoryWriter with fn seek(self, origin, delta) {
  match
    checked_seek_position(origin, delta, self.cursor, self.destination.length()) {
    Err(error) => Err(error)
    Ok(position) => {
      self.cursor = position
      Ok(position)
    }
  }
}
