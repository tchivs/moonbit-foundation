///|
fn type2_wb_assert_data(error : @error.CoreError, context : String) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::Data, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(error.operation() == Some("font-cff-type2"), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
test "Type 2 wire numbers decode to exact signed Q16.16 values" {
  for item in [
    (b"\x8b", 0L, 1UL),
    (b"\x20", -7012352L, 1UL),
    (b"\xf6", 7012352L, 1UL),
    (b"\xf7\x00", 7077888L, 2UL),
    (b"\xfa\xff", 74121216L, 2UL),
    (b"\xfb\x00", -7077888L, 2UL),
    (b"\xfe\xff", -74121216L, 2UL),
    (b"\x1c\x7f\xff", 2147418112L, 3UL),
    (b"\x1c\x80\x00", -2147483648L, 3UL),
    (b"\xff\x00\x01\x80\x00", 98304L, 5UL),
    (b"\xff\xff\xfe\x80\x00", -98304L, 5UL),
    (b"\xff\x7f\xff\xff\xff", 2147483647L, 5UL),
    (b"\xff\x80\x00\x00\x00", -2147483648L, 5UL),
  ] {
    let decoded = type2_decode_number(font_wb_view(item.0), 0UL).unwrap()
    inspect(decoded.0.raw, content=item.1.to_string())
    inspect(decoded.1, content=item.2.to_string())
  }
  for source in [b"", b"\x1c", b"\x1c\x00", b"\xf7", b"\xfb", b"\xff\x00\x00"] {
    type2_wb_assert_data(
      type2_decode_number(font_wb_view(source), 0UL).unwrap_err(),
      "font-cff-type2-number",
    )
  }
}

///|
test "Type 2 fixed arithmetic is checked and rounds toward zero" {
  let one = type2_fixed_from_raw(65536L).unwrap()
  let half = type2_fixed_from_raw(32768L).unwrap()
  let negative_half = type2_fixed_from_raw(-32768L).unwrap()
  inspect(type2_fixed_add(one, half).unwrap().raw, content="98304")
  inspect(type2_fixed_sub(one, half).unwrap().raw, content="32768")
  inspect(type2_fixed_abs(negative_half).unwrap().raw, content="32768")
  inspect(type2_fixed_neg(negative_half).unwrap().raw, content="32768")
  inspect(type2_fixed_mul(half, half).unwrap().raw, content="16384")
  inspect(type2_fixed_mul(negative_half, half).unwrap().raw, content="-16384")
  inspect(
    type2_fixed_mul(
      type2_fixed_from_raw(-1L).unwrap(),
      type2_fixed_from_raw(32768L).unwrap(),
    ).unwrap().raw,
    content="0",
  )
  inspect(
    type2_fixed_mul(
      type2_fixed_from_raw(1L).unwrap(),
      type2_fixed_from_raw(-32768L).unwrap(),
    ).unwrap().raw,
    content="0",
  )
  inspect(type2_fixed_div(one, half).unwrap().raw, content="131072")
  inspect(type2_fixed_div(negative_half, one).unwrap().raw, content="-32768")
  inspect(type2_fixed_sqrt(type2_fixed_from_raw(16384L).unwrap()).unwrap().raw, content="32768")
  inspect(type2_fixed_sqrt(type2_fixed_from_raw(131072L).unwrap()).unwrap().raw, content="92681")
}

///|
test "Type 2 fixed arithmetic rejects undefined and signed-32 overflow" {
  inspect(type2_fixed_from_raw(-2147483649L) is Err(_), content="true")
  inspect(type2_fixed_from_raw(2147483648L) is Err(_), content="true")
  let min = type2_fixed_from_raw(-2147483648L).unwrap()
  let max = type2_fixed_from_raw(2147483647L).unwrap()
  let one_raw = type2_fixed_from_raw(1L).unwrap()
  let zero = type2_fixed_from_raw(0L).unwrap()
  for error in [
    type2_fixed_add(max, one_raw).unwrap_err(),
    type2_fixed_sub(min, one_raw).unwrap_err(),
    type2_fixed_abs(min).unwrap_err(),
    type2_fixed_neg(min).unwrap_err(),
    type2_fixed_mul(max, max).unwrap_err(),
    type2_fixed_div(max, one_raw).unwrap_err(),
  ] {
    type2_wb_assert_data(error, "font-cff-type2-arithmetic")
  }
  type2_wb_assert_data(
    type2_fixed_div(one_raw, zero).unwrap_err(),
    "font-cff-type2-division-by-zero",
  )
  type2_wb_assert_data(
    type2_fixed_sqrt(type2_fixed_neg(one_raw).unwrap()).unwrap_err(),
    "font-cff-type2-square-root",
  )
}

///|
test "Type 2 xorshift stream is repeatable, resettable, and strictly positive" {
  let seed = type2_fixed_from_raw(0x12345678L).unwrap()
  let first = Type2Prng::new(seed)
  let second = Type2Prng::new(seed)
  let expected = [23206L, 9380L, 62661L, 44185L]
  for raw in expected {
    let a = first.next().raw
    let b = second.next().raw
    inspect(a, content=raw.to_string())
    inspect(b, content=raw.to_string())
    inspect(a >= 1L && a <= 65536L, content="true")
  }
  let zero_seed = Type2Prng::new(type2_fixed_from_raw(0L).unwrap())
  let zero_first = zero_seed.next().raw
  inspect(zero_first > 0L && zero_first <= 65536L, content="true")
  inspect(zero_seed.next().raw != zero_first, content="true")
  inspect(Type2Prng::new(seed).next().raw, content="23206")
}
