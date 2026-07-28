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
  let expected = [34713L, 5468L, 18465L, 33204L]
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
  inspect(Type2Prng::new(seed).next().raw, content="34713")
}

///|
fn type2_wb_number(value : Int64) -> CffNumber {
  if value < 0L {
    {
      negative: true,
      magnitude: (-value).reinterpret_as_uint64(),
      denominator: 1UL,
    }
  } else {
    {
      negative: false,
      magnitude: value.reinterpret_as_uint64(),
      denominator: 1UL,
    }
  }
}

///|
fn type2_wb_fraction(
  negative : Bool,
  magnitude : UInt64,
  denominator : UInt64,
) -> CffNumber {
  { negative, magnitude, denominator }
}

///|
test "Type 2 Q16 conversion cancels huge CFF ratios before range checks" {
  let near_one = type2_wb_fraction(
    false,
    999999999999999999UL,
    1000000000000000000UL,
  )
  inspect(
    cff_number_to_type2_fixed(near_one, "q16-large-ratio").unwrap().raw,
    content="65535",
  )
  inspect(
    cff_number_to_type2_fixed(
      type2_wb_fraction(
        true,
        999999999999999999UL,
        1000000000000000000UL,
      ),
      "q16-negative-large-ratio",
    ).unwrap().raw,
    content="-65535",
  )

  let denominator = 100000000000000UL
  let negative_limit = type2_wb_fraction(
    true,
    3276800000000000000UL,
    denominator,
  )
  let positive_max = type2_wb_fraction(
    false,
    3276799999999999999UL,
    denominator,
  )
  inspect(
    cff_number_to_type2_fixed(negative_limit, "q16-negative-limit").unwrap().raw,
    content="-2147483648",
  )
  inspect(
    cff_number_to_type2_fixed(positive_max, "q16-positive-max").unwrap().raw,
    content="2147483647",
  )
  inspect(
    cff_number_to_type2_fixed(
      type2_wb_fraction(false, 3276800000000000000UL, denominator),
      "q16-positive-out-of-range",
    )
    is Err(_),
    content="true",
  )
  inspect(
    cff_number_to_type2_fixed(
      type2_wb_fraction(true, 3276800001525878907UL, denominator),
      "q16-negative-out-of-range",
    )
    is Err(_),
    content="true",
  )
}

///|
test "Type 2 rational add multiply and matrix scale cancel before products" {
  let reciprocal_left = type2_rational(4000000001L, 3000000001L).unwrap()
  let reciprocal_right = type2_rational(3000000001L, 4000000001L).unwrap()
  let product = type2_rational_mul(reciprocal_left, reciprocal_right).unwrap()
  inspect(product.numerator, content="1")
  inspect(product.denominator, content="1")

  let sum = type2_rational_add(
    type2_rational(1L, 4000000000L).unwrap(),
    type2_rational(1L, 6000000000L).unwrap(),
  ).unwrap()
  inspect(sum.numerator, content="1")
  inspect(sum.denominator, content="2400000000")

  let one = type2_wb_number(1L)
  let near_one = type2_wb_fraction(
    false,
    999999999999999999UL,
    1000000000000000000UL,
  )
  let zero = type2_wb_number(0L)
  let scaled = type2_matrix_compose(
    [near_one, zero, zero, near_one, zero, zero],
    None,
    1000UL,
  ).unwrap()
  let point = type2_matrix_apply(
    scaled,
    type2_fixed_integer(1L).unwrap(),
    type2_fixed_integer(1L).unwrap(),
  ).unwrap()
  inspect(type2_rational_floor(point.0).unwrap(), content="999")
  inspect(type2_rational_ceil(point.0).unwrap(), content="1000")
  inspect(type2_rational_floor(point.1).unwrap(), content="999")
  inspect(type2_rational_ceil(point.1).unwrap(), content="1000")

  let composed = type2_matrix_compose(
    [
      one,
      zero,
      zero,
      one,
      type2_wb_fraction(false, 1UL, 4000000000UL),
      zero,
    ],
    Some([
      one,
      zero,
      zero,
      one,
      type2_wb_fraction(false, 1UL, 6000000000UL),
      zero,
    ]),
    1UL,
  ).unwrap()
  let translated = type2_matrix_apply(
    composed,
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
  ).unwrap()
  inspect(translated.0.numerator, content="1")
  inspect(translated.0.denominator, content="2400000000")

  let huge = type2_rational(9223372036854775807L, 1L).unwrap()
  inspect(
    type2_rational_mul(huge, type2_rational(2L, 1L).unwrap()) is Err(_),
    content="true",
  )
  inspect(
    type2_rational_add(huge, type2_rational(1L, 1L).unwrap()) is Err(_),
    content="true",
  )
}

///|
fn type2_wb_matrix(
  a : Int64,
  b : Int64,
  c : Int64,
  d : Int64,
  tx : Int64,
  ty : Int64,
) -> Array[CffNumber] {
  [
    type2_wb_number(a),
    type2_wb_number(b),
    type2_wb_number(c),
    type2_wb_number(d),
    type2_wb_number(tx),
    type2_wb_number(ty),
  ]
}

///|
fn type2_wb_limits(
  points : UInt64,
  contours : UInt64,
  instructions : UInt64,
  work : UInt64,
) -> FontLimits {
  FontLimits::new(
    max_source_bytes=1UL,
    max_tables=1UL,
    max_table_bytes=1UL,
    max_glyphs=1UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_kern_subtables=1UL,
    max_kern_pairs=1UL,
    max_outline_points=points,
    max_outline_contours=contours,
    max_outline_components=1UL,
    max_outline_instruction_bytes=instructions,
    max_post_name_bytes=1UL,
    max_work=work,
  ).unwrap()
}

///|
test "Type 2 private limits intersect hard ceilings with caller authority" {
  let minimal = type2_limits(type2_wb_limits(1UL, 1UL, 1UL, 1UL)).unwrap()
  inspect(minimal.max_operand_stack, content="48")
  inspect(minimal.max_transient, content="32")
  inspect(minimal.max_stems, content="96")
  inspect(minimal.max_frames, content="10")
  inspect(minimal.max_subrs, content="65536")
  inspect(minimal.max_executed_bytes, content="1")
  inspect(minimal.max_points, content="1")
  inspect(minimal.max_contours, content="1")
  inspect(minimal.max_commands, content="3")
  inspect(minimal.max_calls, content="1")
  inspect(minimal.max_work, content="1")
  inspect(minimal.scratch_allocations, content="4")
  inspect(minimal.scratch_allocation_size, content="384")

  let clamped = type2_limits(
    type2_wb_limits(1000UL, 1000UL, 70000UL, 90000UL),
  ).unwrap()
  inspect(clamped.max_executed_bytes, content="65535")
  inspect(clamped.max_commands, content="3000")
  inspect(clamped.max_calls, content="90000")

  inspect(
    type2_limits(
      type2_wb_limits(
        18446744073709551615UL,
        18446744073709551615UL,
        1UL,
        1UL,
      ),
    )
    is Err(_),
    content="true",
  )
}

///|
test "Type 2 exact matrices apply FD then Top and retain outward bounds" {
  let top = type2_wb_matrix(2L, 0L, 0L, 3L, 10L, -10L)
  let fd = type2_wb_matrix(1L, 0L, 0L, 1L, 5L, 7L)
  let matrix = type2_matrix_compose(top, Some(fd), 1UL).unwrap()
  let point = type2_matrix_apply(
    matrix,
    type2_fixed_integer(1L).unwrap(),
    type2_fixed_integer(2L).unwrap(),
  ).unwrap()
  inspect(point.0.numerator, content="22")
  inspect(point.0.denominator, content="1")
  inspect(point.1.numerator, content="17")
  inspect(point.1.denominator, content="1")

  let default_top = cff_default_font_matrix()
  let normalized = type2_matrix_compose(default_top, None, 1000UL).unwrap()
  let fractional = type2_matrix_apply(
    normalized,
    type2_fixed_from_raw(-98304L).unwrap(),
    type2_fixed_from_raw(98304L).unwrap(),
  ).unwrap()
  inspect(type2_rational_floor(fractional.0).unwrap(), content="-2")
  inspect(type2_rational_ceil(fractional.0).unwrap(), content="-1")
  inspect(type2_rational_floor(fractional.1).unwrap(), content="1")
  inspect(type2_rational_ceil(fractional.1).unwrap(), content="2")
}

///|
test "Type 2 matrix primitives reject malformed and overflowing facts" {
  inspect(
    type2_matrix_compose([type2_wb_number(1L)], None, 1000UL) is Err(_),
    content="true",
  )
  let huge = [
    {
      negative: false,
      magnitude: 9223372036854775807UL,
      denominator: 1UL,
    },
    type2_wb_number(0L),
    type2_wb_number(0L),
    type2_wb_number(1L),
    type2_wb_number(0L),
    type2_wb_number(0L),
  ]
  inspect(type2_matrix_compose(huge, Some(huge), 1000UL) is Err(_), content="true")
}
