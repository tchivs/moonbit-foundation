///|
priv struct Type2Fixed {
  raw : Int64
}

///|
priv struct Type2Prng {
  mut state : UInt64
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
  { raw: (state & 0xFFFFUL).reinterpret_as_int64() + 1L }
}
