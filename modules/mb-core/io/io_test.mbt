///|
fn io_limits(bytes : UInt64) -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes~,
    allocations=8UL,
    allocation_size=bytes,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=0UL,
  )
}

///|
fn expect_io_ok(
  result : Result[UInt64, @error.CoreError],
  expected : UInt64,
) -> Unit raise {
  match result {
    Ok(value) => inspect(value == expected, content="true")
    Err(_) => fail("operation must succeed")
  }
}

///|
struct ScriptedReader {
  script : Array[Int]
  mut step : Int
  mut calls : Int
}

///|
impl @io.Reader for ScriptedReader with fn read(self, destination) {
  self.calls = self.calls + 1
  let action = self.script[self.step]
  self.step = self.step + 1
  if action > 0 {
    let count = action.to_uint64()
    for index = 0; index < action; index = index + 1 {
      ignore(destination.set(index.to_uint64(), (index + 1).to_byte()))
    }
    @io.ReadOutcome::Progress(count)
  } else if action == -1 {
    @io.ReadOutcome::EndOfStream
  } else if action == -2 {
    @io.ReadOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="scripted_read",
      ),
      0UL,
    )
  } else if action == -3 {
    @io.ReadOutcome::Progress(0UL)
  } else {
    ignore(destination.set(0UL, b'!'))
    @io.ReadOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::Data,
        @error.ErrorCode::InvalidEncoding,
        operation="scripted_read",
      ),
      1UL,
    )
  }
}

///|
struct ScriptedWriter {
  script : Array[Int]
  mut step : Int
  mut calls : Int
}

///|
impl @io.Writer for ScriptedWriter with fn write(self, _source) {
  self.calls = self.calls + 1
  let action = self.script[self.step]
  self.step = self.step + 1
  if action > 0 {
    @io.WriteOutcome::Progress(action.to_uint64())
  } else if action == -1 {
    @io.WriteOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        operation="scripted_write",
      ),
      0UL,
    )
  } else if action == -2 {
    @io.WriteOutcome::Progress(0UL)
  } else {
    @io.WriteOutcome::Failed(
      @error.CoreError::new(
        @error.ErrorCategory::State,
        @error.ErrorCode::InvalidRange,
        operation="scripted_write",
      ),
      1UL,
    )
  }
}

///|
test "read_exact accumulates partial progress and completes" {
  let budget = @budget.Budget::new(io_limits(4UL))
  let owned = match @bytes.OwnedBytes::new(4UL, budget) {
    Ok(value) => value
    Err(_) => fail("destination must allocate")
  }
  let reader = ScriptedReader::{ script: [1, 2, 1], step: 0, calls: 0 }
  let result = owned.with_mut(0UL, 4UL, fn(lease) {
    @io.read_exact(reader as &@io.Reader, lease)
  })
  expect_io_ok(result, 4UL)
  inspect(reader.calls, content="3")
}

///|
test "read_exact distinguishes eos failure no-progress and partial failure" {
  let budget = @budget.Budget::new(io_limits(12UL))
  let eos_owned = @bytes.OwnedBytes::new(3UL, budget).unwrap()
  let eos_reader = ScriptedReader::{ script: [1, -1], step: 0, calls: 0 }
  match
    eos_owned.with_mut(0UL, 3UL, fn(lease) {
      @io.read_exact(eos_reader as &@io.Reader, lease)
    }) {
    Err(error) => {
      inspect(
        error.code() == @error.ErrorCode::UnexpectedEndOfStream,
        content="true",
      )
      inspect(error.requested(), content="Some(3)")
      inspect(error.completed(), content="Some(1)")
    }
    Ok(_) => fail("early eos must fail")
  }
  let failed_owned = @bytes.OwnedBytes::new(3UL, budget).unwrap()
  let failed_reader = ScriptedReader::{ script: [1, -4], step: 0, calls: 0 }
  match
    failed_owned.with_mut(0UL, 3UL, fn(lease) {
      @io.read_exact(failed_reader as &@io.Reader, lease)
    }) {
    Err(error) => inspect(error.completed(), content="Some(2)")
    Ok(_) => fail("failure after progress must preserve total completion")
  }
  let stalled_owned = @bytes.OwnedBytes::new(1UL, budget).unwrap()
  let stalled = ScriptedReader::{ script: [-3], step: 0, calls: 0 }
  match
    stalled_owned.with_mut(0UL, 1UL, fn(lease) {
      @io.read_exact(stalled as &@io.Reader, lease)
    }) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NoProgress, content="true")
    Ok(_) => fail("zero progress must not spin")
  }
}

///|
test "zero-length exact operations never call their backend" {
  let budget = @budget.Budget::new(io_limits(0UL))
  let owned = @bytes.OwnedBytes::new(0UL, budget).unwrap()
  let reader = ScriptedReader::{ script: [], step: 0, calls: 0 }
  expect_io_ok(
    owned.with_mut(0UL, 0UL, fn(lease) {
      @io.read_exact(reader as &@io.Reader, lease)
    }),
    0UL,
  )
  let writer = ScriptedWriter::{ script: [], step: 0, calls: 0 }
  expect_io_ok(@io.write_all(writer as &@io.Writer, owned.view()), 0UL)
  inspect(reader.calls, content="0")
  inspect(writer.calls, content="0")
}

///|
test "write_all preserves partial completion and rejects no progress" {
  let budget = @budget.Budget::new(io_limits(4UL))
  let owned = @bytes.OwnedBytes::new(4UL, budget).unwrap()
  let writer = ScriptedWriter::{ script: [1, 2, 1], step: 0, calls: 0 }
  expect_io_ok(@io.write_all(writer as &@io.Writer, owned.view()), 4UL)
  let failed = ScriptedWriter::{ script: [1, -3], step: 0, calls: 0 }
  match @io.write_all(failed as &@io.Writer, owned.view()) {
    Err(error) => inspect(error.completed(), content="Some(2)")
    Ok(_) => fail("partial write failure must be retained")
  }
  let stalled = ScriptedWriter::{ script: [-2], step: 0, calls: 0 }
  match @io.write_all(stalled as &@io.Writer, owned.view()) {
    Err(error) =>
      inspect(error.code() == @error.ErrorCode::NoProgress, content="true")
    Ok(_) => fail("zero write progress must not spin")
  }
}

///|
test "seeking is a separate capability with checked boundaries" {
  expect_io_ok(
    @io.checked_seek_position(@io.SeekOrigin::Start, 0L, 4UL, 4UL),
    0UL,
  )
  expect_io_ok(
    @io.checked_seek_position(@io.SeekOrigin::End, 0L, 4UL, 4UL),
    4UL,
  )
  expect_io_ok(
    @io.checked_seek_position(@io.SeekOrigin::Current, -4L, 4UL, 4UL),
    0UL,
  )
  inspect(
    @io.checked_seek_position(@io.SeekOrigin::End, 1L, 4UL, 4UL) is Err(_),
    content="true",
  )
  inspect(
    @io.checked_seek_position(@io.SeekOrigin::Start, -1L, 4UL, 4UL) is Err(_),
    content="true",
  )
  let non_seekable = ScriptedReader::{ script: [-1], step: 0, calls: 0 }
    as &@io.Reader
  ignore(non_seekable)
}
