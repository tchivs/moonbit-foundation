///|
/// The explicit logical ceiling used by the pinned portable UInt64 contract.
let uint64_max : UInt64 = 18446744073709551615UL

///|
let int64_max : Int64 = 9223372036854775807L

///|
let int64_min : Int64 = -9223372036854775807L - 1L

///|
let int64_max_as_uint64 : UInt64 = 9223372036854775807UL

///|
/// The backend allocation and index ceiling is the pinned 32-bit signed Int
/// maximum. Logical quantities remain UInt64 until checked against this value.
fn int_max_as_uint64() -> UInt64 {
  2147483647UL
}

///|
fn arithmetic_error(
  code : @error.ErrorCode,
  operation : String,
  requested : UInt64,
  limit : UInt64,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    code,
    operation~,
    requested~,
    limit~,
  )
}

///|
fn int64_arithmetic_overflow(operation : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::InvalidInput,
    @error.ErrorCode::ArithmeticOverflow,
    operation~,
  )
}

///|
/// Add two logical quantities only after proving that the operator cannot wrap.
pub fn checked_add(
  left : UInt64,
  right : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if left > uint64_max - right {
    Err(
      arithmetic_error(
        @error.ErrorCode::ArithmeticOverflow,
        "checked_add",
        right,
        uint64_max - left,
      ),
    )
  } else {
    Ok(left + right)
  }
}

///|
/// Add signed design-unit quantities only after proving the selected sign
/// branch cannot cross either exact Int64 boundary.
pub fn checked_add_int64(
  left : Int64,
  right : Int64,
) -> Result[Int64, @error.CoreError] {
  if (right > 0L && left > int64_max - right) ||
    (right < 0L && left < int64_min - right) {
    Err(int64_arithmetic_overflow("checked_add_int64"))
  } else {
    Ok(left + right)
  }
}

///|
/// Negate every signed value except the one value with no positive Int64
/// representation.
pub fn checked_neg_int64(value : Int64) -> Result[Int64, @error.CoreError] {
  if value == int64_min {
    Err(int64_arithmetic_overflow("checked_neg_int64"))
  } else {
    Ok(-value)
  }
}

///|
/// Narrow an unsigned logical value only after proving it is within the exact
/// nonnegative Int64 range. Reinterpretation preserves the already-proven bits.
pub fn checked_uint64_to_int64(
  value : UInt64,
) -> Result[Int64, @error.CoreError] {
  if value > int64_max_as_uint64 {
    Err(
      arithmetic_error(
        @error.ErrorCode::ArithmeticOverflow,
        "checked_uint64_to_int64",
        value,
        int64_max_as_uint64,
      ),
    )
  } else {
    Ok(value.reinterpret_as_int64())
  }
}

///|
/// Subtract only after proving that the left operand covers the right operand.
pub fn checked_sub(
  left : UInt64,
  right : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if left < right {
    Err(
      arithmetic_error(
        @error.ErrorCode::ArithmeticUnderflow,
        "checked_sub",
        right,
        left,
      ),
    )
  } else {
    Ok(left - right)
  }
}

///|
/// Multiply only after a division guard that cannot overflow.
pub fn checked_mul(
  left : UInt64,
  right : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if right != 0UL && left > uint64_max / right {
    Err(
      arithmetic_error(
        @error.ErrorCode::ArithmeticOverflow,
        "checked_mul",
        right,
        uint64_max / left,
      ),
    )
  } else {
    Ok(left * right)
  }
}

///|
fn is_power_of_two(value : UInt64) -> Bool {
  value != 0UL && (value & (value - 1UL)) == 0UL
}

///|
/// Round upward only after validating the alignment and checked padding.
pub fn align_up(
  value : UInt64,
  alignment : UInt64,
) -> Result[UInt64, @error.CoreError] {
  if !is_power_of_two(alignment) {
    Err(
      arithmetic_error(
        @error.ErrorCode::InvalidAlignment,
        "align_up",
        alignment,
        uint64_max,
      ),
    )
  } else {
    let remainder = value & (alignment - 1UL)
    if remainder == 0UL {
      Ok(value)
    } else {
      checked_add(value, alignment - remainder)
    }
  }
}

///|
/// The only logical-to-backend index conversion in the checked package.
pub fn checked_narrow_int(value : UInt64) -> Result[Int, @error.CoreError] {
  let limit = int_max_as_uint64()
  if value > limit {
    Err(
      arithmetic_error(
        @error.ErrorCode::NarrowingFailed,
        "checked_narrow_int",
        value,
        limit,
      ),
    )
  } else {
    Ok(value.to_int())
  }
}

///|
/// Compute a backend allocation size through checked logical multiplication and
/// the package's sole narrowing operation.
pub fn checked_allocation_size(
  count : UInt64,
  element_size : UInt64,
) -> Result[Int, @error.CoreError] {
  match checked_mul(count, element_size) {
    Err(error) => Err(error)
    Ok(size) => checked_narrow_int(size)
  }
}

///|
/// A validated logical offset whose representation cannot be mutated directly.
pub struct CheckedOffset {
  priv value_value : UInt64
}

///|
pub fn CheckedOffset::new(value : UInt64) -> CheckedOffset {
  { value_value: value }
}

///|
pub fn CheckedOffset::value(self : CheckedOffset) -> UInt64 {
  self.value_value
}

///|
pub fn CheckedOffset::advance(
  self : CheckedOffset,
  amount : UInt64,
) -> Result[CheckedOffset, @error.CoreError] {
  if self.value_value > uint64_max - amount {
    Err(
      arithmetic_error(
        @error.ErrorCode::InvalidOffset,
        "offset_advance",
        amount,
        uint64_max - self.value_value,
      ),
    )
  } else {
    Ok(CheckedOffset::new(self.value_value + amount))
  }
}

///|
pub fn CheckedOffset::retreat(
  self : CheckedOffset,
  amount : UInt64,
) -> Result[CheckedOffset, @error.CoreError] {
  if self.value_value < amount {
    Err(
      arithmetic_error(
        @error.ErrorCode::InvalidOffset,
        "offset_retreat",
        amount,
        self.value_value,
      ),
    )
  } else {
    Ok(CheckedOffset::new(self.value_value - amount))
  }
}
