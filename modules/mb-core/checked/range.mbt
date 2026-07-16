///|
fn range_error(
  operation : String,
  start : UInt64,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::InvalidRange,
    operation~,
    requested~,
    range_start=start,
    limit~,
  )
}

///|
/// Derive a half-open end only through checked addition, remapping arithmetic
/// overflow into the stable range failure contract.
fn checked_range_end(
  start : UInt64,
  length : UInt64,
) -> Result[UInt64, @error.CoreError] {
  match checked_add(start, length) {
    Ok(end) => Ok(end)
    Err(_) => Err(range_error("range_end", start, length, uint64_max - start))
  }
}

///|
/// A validated half-open range `[start, end)`. Empty ranges are canonical and
/// valid, including an empty range at UInt64 maximum.
pub struct CheckedRange {
  priv start_value : UInt64
  priv end_value : UInt64
}

///|
pub fn CheckedRange::from_start_length(
  start : UInt64,
  length : UInt64,
) -> Result[CheckedRange, @error.CoreError] {
  match checked_range_end(start, length) {
    Err(error) => Err(error)
    Ok(end) => Ok({ start_value: start, end_value: end })
  }
}

///|
pub fn CheckedRange::start(self : CheckedRange) -> UInt64 {
  self.start_value
}

///|
pub fn CheckedRange::end(self : CheckedRange) -> UInt64 {
  self.end_value
}

///|
pub fn CheckedRange::length(self : CheckedRange) -> UInt64 {
  self.end_value - self.start_value
}

///|
pub fn CheckedRange::is_empty(self : CheckedRange) -> Bool {
  self.start_value == self.end_value
}

///|
/// Half-open ranges overlap only when both are non-empty and each starts before
/// the other's end. Touching endpoints are therefore non-overlapping.
pub fn CheckedRange::overlaps(
  self : CheckedRange,
  other : CheckedRange,
) -> Bool {
  !self.is_empty() &&
  !other.is_empty() &&
  self.start_value < other.end_value &&
  other.start_value < self.end_value
}

///|
/// Construct a relative half-open subrange after proving containment, before
/// deriving either absolute endpoint.
pub fn CheckedRange::subrange(
  self : CheckedRange,
  relative_start : UInt64,
  length : UInt64,
) -> Result[CheckedRange, @error.CoreError] {
  let parent_length = self.length()
  if relative_start > parent_length {
    Err(
      range_error(
        "subrange_start",
        self.start_value,
        relative_start,
        parent_length,
      ),
    )
  } else if length > parent_length - relative_start {
    Err(
      range_error(
        "subrange_length",
        self.start_value,
        length,
        parent_length - relative_start,
      ),
    )
  } else {
    match checked_add(self.start_value, relative_start) {
      Err(_) =>
        Err(
          range_error(
            "subrange_offset",
            self.start_value,
            relative_start,
            parent_length,
          ),
        )
      Ok(start) => CheckedRange::from_start_length(start, length)
    }
  }
}
