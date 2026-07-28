///|
priv struct Type2Fixed {
  raw : Int64
}

///|
priv struct Type2Prng {
  mut state : UInt64
}

///|
priv struct Type2Rational {
  numerator : Int64
  denominator : Int64
}

///|
#valtype
priv struct Type2WideUnsigned {
  hi : UInt64
  lo : UInt64
}

///|
priv struct Type2Matrix {
  a : Type2Rational
  b : Type2Rational
  c : Type2Rational
  d : Type2Rational
  tx : Type2Rational
  ty : Type2Rational
}

///|
fn type2_data_error(context : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="font-cff-type2",
    context~,
  )
}

///|
fn type2_fixed_from_raw(raw : Int64) -> Result[Type2Fixed, @error.CoreError] {
  if raw < -2147483648L || raw > 2147483647L {
    Err(type2_data_error("font-cff-type2-arithmetic"))
  } else {
    Ok({ raw, })
  }
}

///|
fn type2_fixed_integer(value : Int64) -> Result[Type2Fixed, @error.CoreError] {
  if value < -32768L || value > 32767L {
    return Err(type2_data_error("font-cff-type2-number"))
  }
  type2_fixed_from_raw(value * 65536L)
}

///|
fn type2_decode_number(
  source : @bytes.ByteView,
  cursor : UInt64,
) -> Result[(Type2Fixed, UInt64), @error.CoreError] {
  let first = match read_u8(source, cursor) {
    Err(_) => return Err(type2_data_error("font-cff-type2-number"))
    Ok(value) => value.to_uint64()
  }
  if first >= 32UL && first <= 246UL {
    let fixed = match type2_fixed_integer(first.reinterpret_as_int64() - 139L) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value
    }
    Ok((fixed, cursor + 1UL))
  } else if first >= 247UL && first <= 250UL {
    let second = match read_u8(source, cursor + 1UL) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value.to_uint64()
    }
    let integer = (first - 247UL) * 256UL + second + 108UL
    let fixed = match type2_fixed_integer(integer.reinterpret_as_int64()) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value
    }
    Ok((fixed, cursor + 2UL))
  } else if first >= 251UL && first <= 254UL {
    let second = match read_u8(source, cursor + 1UL) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value.to_uint64()
    }
    let magnitude = (first - 251UL) * 256UL + second + 108UL
    let fixed = match type2_fixed_integer(-magnitude.reinterpret_as_int64()) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value
    }
    Ok((fixed, cursor + 2UL))
  } else if first == 28UL {
    let signed = match read_i16(source, cursor + 1UL) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value.to_int64()
    }
    let fixed = match type2_fixed_integer(signed) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value
    }
    Ok((fixed, cursor + 3UL))
  } else if first == 255UL {
    let bits = match read_u32(source, cursor + 1UL) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value
    }
    let raw = if bits >= 0x80000000UL {
      bits.reinterpret_as_int64() - 4294967296L
    } else {
      bits.reinterpret_as_int64()
    }
    let fixed = match type2_fixed_from_raw(raw) {
      Err(_) => return Err(type2_data_error("font-cff-type2-number"))
      Ok(value) => value
    }
    Ok((fixed, cursor + 5UL))
  } else {
    Err(type2_data_error("font-cff-type2-number"))
  }
}

///|
fn type2_fixed_add(
  left : Type2Fixed,
  right : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  type2_fixed_from_raw(left.raw + right.raw)
}

///|
fn type2_fixed_sub(
  left : Type2Fixed,
  right : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  type2_fixed_from_raw(left.raw - right.raw)
}

///|
fn type2_fixed_abs(value : Type2Fixed) -> Result[Type2Fixed, @error.CoreError] {
  if value.raw == -2147483648L {
    Err(type2_data_error("font-cff-type2-arithmetic"))
  } else if value.raw < 0L {
    Ok({ raw: -value.raw })
  } else {
    Ok(value)
  }
}

///|
fn type2_fixed_neg(value : Type2Fixed) -> Result[Type2Fixed, @error.CoreError] {
  if value.raw == -2147483648L {
    Err(type2_data_error("font-cff-type2-arithmetic"))
  } else {
    Ok({ raw: -value.raw })
  }
}

///|
fn type2_fixed_mul(
  left : Type2Fixed,
  right : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  type2_fixed_from_raw((left.raw * right.raw) / 65536L)
}

///|
fn type2_fixed_div(
  left : Type2Fixed,
  right : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  if right.raw == 0L {
    return Err(type2_data_error("font-cff-type2-division-by-zero"))
  }
  type2_fixed_from_raw((left.raw * 65536L) / right.raw)
}

///|
fn type2_integer_square_root(value : Int64) -> Int64 {
  if value <= 0L {
    return 0L
  }
  let mut result = 0L
  let mut bit = 1L << 62
  let mut remaining = value
  while bit > remaining {
    bit = bit >> 2
  }
  while bit != 0L {
    if remaining >= result + bit {
      remaining = remaining - result - bit
      result = (result >> 1) + bit
    } else {
      result = result >> 1
    }
    bit = bit >> 2
  }
  result
}

///|
fn type2_fixed_sqrt(
  value : Type2Fixed,
) -> Result[Type2Fixed, @error.CoreError] {
  if value.raw < 0L {
    return Err(type2_data_error("font-cff-type2-square-root"))
  }
  type2_fixed_from_raw(type2_integer_square_root(value.raw * 65536L))
}

///|
fn Type2Prng::new(seed : Type2Fixed) -> Type2Prng {
  let bits = if seed.raw < 0L {
    (seed.raw + 4294967296L).reinterpret_as_uint64()
  } else {
    seed.raw.reinterpret_as_uint64()
  }
  {
    state: if bits == 0UL { 0x6D2B79F5UL } else { bits & 0xFFFFFFFFUL },
  }
}

///|
fn Type2Prng::next(self : Type2Prng) -> Type2Fixed {
  let mut state = self.state
  state = (state ^ (state << 13)) & 0xFFFFFFFFUL
  state = state ^ (state >> 17)
  state = (state ^ (state << 5)) & 0xFFFFFFFFUL
  self.state = state
  { raw: (state >> 16).reinterpret_as_int64() + 1L }
}

fn type2_checked_i64_mul(
  left : Int64,
  right : Int64,
) -> Result[Int64, @error.CoreError] {
  match outline_checked_mul(left, right) {
    Err(_) => Err(type2_data_error("font-cff-type2-transform"))
    Ok(value) => Ok(value)
  }
}

///|
fn type2_gcd(left : Int64, right : Int64) -> Int64 {
  let mut a = if left < 0L { -left } else { left }
  let mut b = if right < 0L { -right } else { right }
  while b != 0L {
    let remainder = a % b
    a = b
    b = remainder
  }
  if a == 0L { 1L } else { a }
}

///|
fn type2_wide_mul(left : UInt64, right : UInt64) -> Type2WideUnsigned {
  let left_low = left & 0xffffffffUL
  let left_high = left >> 32
  let right_low = right & 0xffffffffUL
  let right_high = right >> 32
  let low_product = left_low * right_low
  let middle_left = left_high * right_low + (low_product >> 32)
  let middle_right = left_low * right_high + (middle_left & 0xffffffffUL)
  {
    hi: left_high * right_high +
      (middle_left >> 32) +
      (middle_right >> 32),
    lo: left * right,
  }
}

///|
fn type2_wide_add(
  left : Type2WideUnsigned,
  right : Type2WideUnsigned,
) -> Type2WideUnsigned {
  let lo = left.lo + right.lo
  let carry = if lo < left.lo { 1UL } else { 0UL }
  { hi: left.hi + right.hi + carry, lo, }
}

///|
fn type2_wide_compare(
  left : Type2WideUnsigned,
  right : Type2WideUnsigned,
) -> Int {
  if left.hi < right.hi {
    -1
  } else if left.hi > right.hi {
    1
  } else if left.lo < right.lo {
    -1
  } else if left.lo > right.lo {
    1
  } else {
    0
  }
}

///|
fn type2_wide_subtract(
  left : Type2WideUnsigned,
  right : Type2WideUnsigned,
) -> Type2WideUnsigned {
  let borrow = if left.lo < right.lo { 1UL } else { 0UL }
  { hi: left.hi - right.hi - borrow, lo: left.lo - right.lo }
}

///|
fn type2_wide_div_rem(
  value : Type2WideUnsigned,
  divisor : UInt64,
) -> (Type2WideUnsigned, UInt64) {
  let mut quotient_high = 0UL
  let mut quotient_low = 0UL
  let mut remainder = 0UL
  for bit = 127; bit >= 0; bit = bit - 1 {
    let source_bit = if bit >= 64 {
      (value.hi >> (bit - 64)) & 1UL
    } else {
      (value.lo >> bit) & 1UL
    }
    remainder = (remainder << 1) | source_bit
    if remainder >= divisor {
      remainder = remainder - divisor
      if bit >= 64 {
        quotient_high = quotient_high | (1UL << (bit - 64))
      } else {
        quotient_low = quotient_low | (1UL << bit)
      }
    }
  }
  ({ hi: quotient_high, lo: quotient_low }, remainder)
}

///|
fn type2_rational(
  numerator : Int64,
  denominator : Int64,
) -> Result[Type2Rational, @error.CoreError] {
  if denominator <= 0L || numerator == -9223372036854775807L - 1L {
    return Err(type2_data_error("font-cff-type2-transform"))
  }
  let divisor = type2_gcd(numerator, denominator)
  Ok({ numerator: numerator / divisor, denominator: denominator / divisor })
}

///|
fn type2_rational_from_cff(
  value : CffNumber,
) -> Result[Type2Rational, @error.CoreError] {
  if value.denominator == 0UL ||
    value.denominator > 9223372036854775807UL ||
    value.magnitude > 9223372036854775807UL {
    return Err(type2_data_error("font-cff-type2-transform"))
  }
  let magnitude = value.magnitude.reinterpret_as_int64()
  type2_rational(
    if value.negative { -magnitude } else { magnitude },
    value.denominator.reinterpret_as_int64(),
  )
}

///|
fn type2_rational_add(
  left : Type2Rational,
  right : Type2Rational,
) -> Result[Type2Rational, @error.CoreError] {
  let common = type2_gcd(left.denominator, right.denominator)
  let left_scale = right.denominator / common
  let right_scale = left.denominator / common
  let left_magnitude = if left.numerator < 0L {
    (-left.numerator).reinterpret_as_uint64()
  } else {
    left.numerator.reinterpret_as_uint64()
  }
  let right_magnitude = if right.numerator < 0L {
    (-right.numerator).reinterpret_as_uint64()
  } else {
    right.numerator.reinterpret_as_uint64()
  }
  let left_product = type2_wide_mul(
    left_magnitude,
    left_scale.reinterpret_as_uint64(),
  )
  let right_product = type2_wide_mul(
    right_magnitude,
    right_scale.reinterpret_as_uint64(),
  )
  let left_negative = left.numerator < 0L
  let right_negative = right.numerator < 0L
  let (wide_numerator, negative) = if left_negative == right_negative {
    (type2_wide_add(left_product, right_product), left_negative)
  } else {
    match type2_wide_compare(left_product, right_product) {
      0 => ({ hi: 0UL, lo: 0UL }, false)
      comparison =>
        if comparison > 0 {
          (type2_wide_subtract(left_product, right_product), left_negative)
        } else {
          (type2_wide_subtract(right_product, left_product), right_negative)
        }
    }
  }
  if wide_numerator.hi == 0UL && wide_numerator.lo == 0UL {
    return Ok({ numerator: 0L, denominator: 1L })
  }
  // Any remaining cancellation can only come from the shared denominator
  // factor. Compute the wide numerator modulo that factor, then divide the
  // exact wide magnitude before narrowing it back to the public Int64 domain.
  let cancellation = if common == 1L {
    1L
  } else {
    let (_, remainder) = type2_wide_div_rem(
      wide_numerator,
      common.reinterpret_as_uint64(),
    )
    type2_gcd(remainder.reinterpret_as_int64(), common)
  }
  let reduced_numerator = if cancellation == 1L {
    wide_numerator
  } else {
    type2_wide_div_rem(
      wide_numerator,
      cancellation.reinterpret_as_uint64(),
    ).0
  }
  if reduced_numerator.hi != 0UL ||
    reduced_numerator.lo > 9223372036854775807UL {
    return Err(type2_data_error("font-cff-type2-transform"))
  }
  let magnitude = reduced_numerator.lo.reinterpret_as_int64()
  let numerator = if negative { -magnitude } else { magnitude }
  let denominator = match
    type2_checked_i64_mul(
      left.denominator / cancellation,
      left_scale,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  type2_rational(numerator, denominator)
}

///|
fn type2_rational_mul(
  left : Type2Rational,
  right : Type2Rational,
) -> Result[Type2Rational, @error.CoreError] {
  if left.numerator == 0L || right.numerator == 0L {
    return Ok({ numerator: 0L, denominator: 1L })
  }
  let left_cancellation = type2_gcd(left.numerator, right.denominator)
  let right_cancellation = type2_gcd(right.numerator, left.denominator)
  let numerator = match
    type2_checked_i64_mul(
      left.numerator / left_cancellation,
      right.numerator / right_cancellation,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let denominator = match
    type2_checked_i64_mul(
      left.denominator / right_cancellation,
      right.denominator / left_cancellation,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  type2_rational(numerator, denominator)
}

///|
fn type2_rational_sum_of_products(
  a : Type2Rational,
  b : Type2Rational,
  c : Type2Rational,
  d : Type2Rational,
) -> Result[Type2Rational, @error.CoreError] {
  let left = match type2_rational_mul(a, b) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let right = match type2_rational_mul(c, d) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  type2_rational_add(left, right)
}

///|
fn type2_matrix_from_cff(
  values : Array[CffNumber],
) -> Result[Type2Matrix, @error.CoreError] {
  if values.length() != 6 {
    return Err(type2_data_error("font-cff-type2-transform"))
  }
  let a = match type2_rational_from_cff(values[0]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let b = match type2_rational_from_cff(values[1]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let c = match type2_rational_from_cff(values[2]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let d = match type2_rational_from_cff(values[3]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tx = match type2_rational_from_cff(values[4]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ty = match type2_rational_from_cff(values[5]) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    a,
    b,
    c,
    d,
    tx,
    ty,
  })
}

///|
fn type2_matrix_compose_pair(
  outer : Type2Matrix,
  inner : Type2Matrix,
) -> Result[Type2Matrix, @error.CoreError] {
  let a = match
    type2_rational_sum_of_products(outer.a, inner.a, outer.c, inner.b) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let b = match
    type2_rational_sum_of_products(outer.b, inner.a, outer.d, inner.b) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let c = match
    type2_rational_sum_of_products(outer.a, inner.c, outer.c, inner.d) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let d = match
    type2_rational_sum_of_products(outer.b, inner.c, outer.d, inner.d) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tx_product = match
    type2_rational_sum_of_products(outer.a, inner.tx, outer.c, inner.ty) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tx = match type2_rational_add(tx_product, outer.tx) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ty_product = match
    type2_rational_sum_of_products(outer.b, inner.tx, outer.d, inner.ty) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ty = match type2_rational_add(ty_product, outer.ty) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ a, b, c, d, tx, ty })
}

///|
fn type2_matrix_scale(
  matrix : Type2Matrix,
  units_per_em : UInt64,
) -> Result[Type2Matrix, @error.CoreError] {
  if units_per_em == 0UL || units_per_em > 9223372036854775807UL {
    return Err(type2_data_error("font-cff-type2-transform"))
  }
  let scale = match
    type2_rational(units_per_em.reinterpret_as_int64(), 1L) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let a = match type2_rational_mul(matrix.a, scale) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let b = match type2_rational_mul(matrix.b, scale) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let c = match type2_rational_mul(matrix.c, scale) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let d = match type2_rational_mul(matrix.d, scale) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let tx = match type2_rational_mul(matrix.tx, scale) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let ty = match type2_rational_mul(matrix.ty, scale) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ a, b, c, d, tx, ty })
}

///|
fn type2_matrix_compose(
  top : Array[CffNumber],
  fd : Array[CffNumber]?,
  units_per_em : UInt64,
) -> Result[Type2Matrix, @error.CoreError] {
  let top_matrix = match type2_matrix_from_cff(top) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let effective = match fd {
    None => top_matrix
    Some(values) => {
      let fd_matrix = match type2_matrix_from_cff(values) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      match type2_matrix_compose_pair(top_matrix, fd_matrix) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    }
  }
  type2_matrix_scale(effective, units_per_em)
}

///|
fn type2_rational_from_fixed(value : Type2Fixed) -> Type2Rational {
  { numerator: value.raw, denominator: 65536L }
}

///|
fn type2_matrix_apply(
  matrix : Type2Matrix,
  x : Type2Fixed,
  y : Type2Fixed,
) -> Result[(Type2Rational, Type2Rational), @error.CoreError] {
  let x_value = type2_rational_from_fixed(x)
  let y_value = type2_rational_from_fixed(y)
  let transformed_x = match
    type2_rational_sum_of_products(matrix.a, x_value, matrix.c, y_value) {
    Err(error) => return Err(error)
    Ok(value) =>
      match type2_rational_add(value, matrix.tx) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
  }
  let transformed_y = match
    type2_rational_sum_of_products(matrix.b, x_value, matrix.d, y_value) {
    Err(error) => return Err(error)
    Ok(value) =>
      match type2_rational_add(value, matrix.ty) {
        Err(error) => return Err(error)
        Ok(result) => result
      }
  }
  Ok((transformed_x, transformed_y))
}

///|
fn type2_narrow_bound(value : Int64) -> Result[Int, @error.CoreError] {
  if value < -2147483647L || value > 2147483647L {
    return Err(type2_data_error("font-cff-type2-transform"))
  }
  if value < 0L {
    match @checked.checked_narrow_int((-value).reinterpret_as_uint64()) {
      Err(_) => Err(type2_data_error("font-cff-type2-transform"))
      Ok(result) => Ok(-result)
    }
  } else {
    match @checked.checked_narrow_int(value.reinterpret_as_uint64()) {
      Err(_) => Err(type2_data_error("font-cff-type2-transform"))
      Ok(result) => Ok(result)
    }
  }
}

///|
fn type2_rational_floor(
  value : Type2Rational,
) -> Result[Int, @error.CoreError] {
  let quotient = value.numerator / value.denominator
  let remainder = value.numerator % value.denominator
  let rounded = if value.numerator < 0L && remainder != 0L {
    quotient - 1L
  } else {
    quotient
  }
  type2_narrow_bound(rounded)
}

///|
fn type2_rational_ceil(
  value : Type2Rational,
) -> Result[Int, @error.CoreError] {
  let quotient = value.numerator / value.denominator
  let remainder = value.numerator % value.denominator
  let rounded = if value.numerator > 0L && remainder != 0L {
    quotient + 1L
  } else {
    quotient
  }
  type2_narrow_bound(rounded)
}
