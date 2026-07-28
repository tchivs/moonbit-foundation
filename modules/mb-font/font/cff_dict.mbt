///|
priv struct CffNumber {
  negative : Bool
  magnitude : UInt64
  denominator : UInt64
}

///|
priv struct CffTableOffset {
  value : UInt64
}

///|
priv struct CffPrivateOffset {
  value : UInt64
}

///|
priv struct CffPrivateRange {
  size : UInt64
  offset : CffTableOffset
}

///|
#warnings("-7")
priv struct CffRos {
  registry_sid : UInt64
  ordering_sid : UInt64
  supplement : UInt64
}

///|
#warnings("-7")
priv struct CffTopDict {
  charstring_type : CffNumber
  charstring_type_explicit : Bool
  charstrings : CffTableOffset
  private_range : CffPrivateRange?
  charset : CffTableOffset?
  encoding : CffTableOffset?
  ros : CffRos?
  fd_array : CffTableOffset?
  fd_select : CffTableOffset?
  font_matrix : Array[CffNumber]
}

///|
#warnings("-7")
priv struct CffFontDict {
  private_range : CffPrivateRange?
  font_matrix : Array[CffNumber]
}

///|
#warnings("-7")
priv struct CffPrivateDict {
  local_subrs : CffPrivateOffset?
  default_width_x : CffNumber
  nominal_width_x : CffNumber
}

///|
priv struct CffDictEntry {
  operator : UInt64
  operands : Array[CffNumber]
}

///|
fn cff_number_unsigned(value : UInt64) -> CffNumber {
  { negative: false, magnitude: value, denominator: 1UL }
}

///|
fn cff_number_signed(negative : Bool, magnitude : UInt64) -> CffNumber {
  { negative: negative && magnitude != 0UL, magnitude, denominator: 1UL }
}

///|
fn cff_number_zero() -> CffNumber {
  cff_number_unsigned(0UL)
}

///|
fn cff_default_font_matrix() -> Array[CffNumber] {
  [
    { negative: false, magnitude: 1UL, denominator: 1000UL },
    cff_number_zero(),
    cff_number_zero(),
    { negative: false, magnitude: 1UL, denominator: 1000UL },
    cff_number_zero(),
    cff_number_zero(),
  ]
}

///|
fn cff_number_nonnegative_integer(
  value : CffNumber,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  if value.negative || value.denominator != 1UL {
    Err(cff_data_error(context))
  } else {
    Ok(value.magnitude)
  }
}

///|
fn cff_pow10(
  exponent : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  let mut value = 1UL
  let mut index = 0UL
  while index < exponent {
    value = match @checked.checked_mul(value, 10UL) {
      Err(_) => return Err(cff_data_error(context))
      Ok(result) => result
    }
    index = index + 1UL
  }
  Ok(value)
}

///|
fn cff_decode_real(
  source : @bytes.ByteView,
  start : UInt64,
  context : String,
) -> Result[(CffNumber, UInt64), @error.CoreError] {
  let mut cursor = start
  let mut magnitude = 0UL
  let mut fractional_digits = 0UL
  let mut exponent_magnitude = 0UL
  let mut negative = false
  let mut exponent_negative = false
  let mut decimal_seen = false
  let mut exponent_seen = false
  let mut digit_seen = false
  let mut finished = false
  while !finished {
    match cff_require_window(source, cursor, 1UL, context) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let byte = source.get(cursor).unwrap()
    cursor = cursor + 1UL
    for shift in [4, 0] {
      let nibble = (byte.to_uint64() >> shift) & 0xFUL
      if nibble <= 9UL {
        digit_seen = true
        if exponent_seen {
          exponent_magnitude = match
            @checked.checked_add(
              match @checked.checked_mul(exponent_magnitude, 10UL) {
                Err(_) => return Err(cff_data_error(context + "-real-range"))
                Ok(value) => value
              },
              nibble,
            ) {
            Err(_) => return Err(cff_data_error(context + "-real-range"))
            Ok(value) => value
          }
          if exponent_magnitude > 18UL {
            return Err(cff_data_error(context + "-real-range"))
          }
        } else {
          magnitude = match
            @checked.checked_add(
              match @checked.checked_mul(magnitude, 10UL) {
                Err(_) => return Err(cff_data_error(context + "-real-range"))
                Ok(value) => value
              },
              nibble,
            ) {
            Err(_) => return Err(cff_data_error(context + "-real-range"))
            Ok(value) => value
          }
          if decimal_seen {
            fractional_digits = fractional_digits + 1UL
          }
        }
      } else {
        match nibble {
          0xAUL =>
            if decimal_seen || exponent_seen {
              return Err(cff_data_error(context + "-real"))
            } else {
              decimal_seen = true
            }
          0xBUL => {
            if exponent_seen || !digit_seen {
              return Err(cff_data_error(context + "-real"))
            }
            exponent_seen = true
          }
          0xCUL => {
            if exponent_seen || !digit_seen {
              return Err(cff_data_error(context + "-real"))
            }
            exponent_seen = true
            exponent_negative = true
          }
          0xDUL => return Err(cff_data_error(context + "-real-reserved"))
          0xEUL =>
            if digit_seen {
              return Err(cff_data_error(context + "-real"))
            } else {
              negative = true
            }
          0xFUL => {
            finished = true
            break
          }
          _ => return Err(cff_data_error(context + "-real"))
        }
      }
    }
  }
  if !digit_seen {
    return Err(cff_data_error(context + "-real"))
  }
  let mut denominator = match
    cff_pow10(fractional_digits, context + "-real-range") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if exponent_seen && exponent_magnitude != 0UL {
    let factor = match cff_pow10(exponent_magnitude, context + "-real-range") {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    if exponent_negative {
      denominator = match @checked.checked_mul(denominator, factor) {
        Err(_) => return Err(cff_data_error(context + "-real-range"))
        Ok(value) => value
      }
    } else if exponent_magnitude >= fractional_digits {
      magnitude = match
        @checked.checked_mul(
          magnitude,
          match
            cff_pow10(
              exponent_magnitude - fractional_digits,
              context + "-real-range",
            ) {
            Err(error) => return Err(error)
            Ok(value) => value
          },
        ) {
        Err(_) => return Err(cff_data_error(context + "-real-range"))
        Ok(value) => value
      }
      denominator = 1UL
    } else {
      denominator = match
        cff_pow10(
          fractional_digits - exponent_magnitude,
          context + "-real-range",
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    }
  }
  Ok(
    ({ negative: negative && magnitude != 0UL, magnitude, denominator }, cursor),
  )
}

///|
fn cff_decode_dict_number(
  source : @bytes.ByteView,
  cursor : UInt64,
  context : String,
) -> Result[(CffNumber, UInt64), @error.CoreError] {
  match cff_require_window(source, cursor, 1UL, context) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let first = source.get(cursor).unwrap().to_uint64()
  if first >= 32UL && first <= 246UL {
    let value = first.to_int() - 139
    if value < 0 {
      Ok((cff_number_signed(true, (-value).to_uint64()), cursor + 1UL))
    } else {
      Ok((cff_number_unsigned(value.to_uint64()), cursor + 1UL))
    }
  } else if first >= 247UL && first <= 250UL {
    match cff_require_window(source, cursor, 2UL, context) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let second = source.get(cursor + 1UL).unwrap().to_uint64()
    Ok(
      (
        cff_number_unsigned((first - 247UL) * 256UL + second + 108UL),
        cursor + 2UL,
      ),
    )
  } else if first >= 251UL && first <= 254UL {
    match cff_require_window(source, cursor, 2UL, context) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let second = source.get(cursor + 1UL).unwrap().to_uint64()
    Ok(
      (
        cff_number_signed(true, (first - 251UL) * 256UL + second + 108UL),
        cursor + 2UL,
      ),
    )
  } else if first == 28UL {
    match cff_require_window(source, cursor, 3UL, context) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let raw = read_u16(source, cursor + 1UL).unwrap()
    if raw >= 0x8000UL {
      Ok((cff_number_signed(true, 0x10000UL - raw), cursor + 3UL))
    } else {
      Ok((cff_number_unsigned(raw), cursor + 3UL))
    }
  } else if first == 29UL {
    match cff_require_window(source, cursor, 5UL, context) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let raw = read_u32(source, cursor + 1UL).unwrap()
    if raw >= 0x80000000UL {
      Ok((cff_number_signed(true, 0x100000000UL - raw), cursor + 5UL))
    } else {
      Ok((cff_number_unsigned(raw), cursor + 5UL))
    }
  } else if first == 30UL {
    cff_decode_real(source, cursor + 1UL, context)
  } else {
    Err(cff_data_error(context + "-operand"))
  }
}

///|
fn cff_parse_dict(
  source : @bytes.ByteView,
  context : String,
) -> Result[Array[CffDictEntry], @error.CoreError] {
  let entries : Array[CffDictEntry] = []
  let mut operands : Array[CffNumber] = []
  let mut cursor = 0UL
  while cursor < source.length() {
    let first = source.get(cursor).unwrap().to_uint64()
    if first == 28UL || first == 29UL || first == 30UL || first >= 32UL {
      let (number, next) = match
        cff_decode_dict_number(source, cursor, context) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      operands.push(number)
      cursor = next
    } else if first == 12UL {
      match cff_require_window(source, cursor, 2UL, context + "-operator") {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      if operands.length() == 0 {
        return Err(cff_data_error(context + "-arity"))
      }
      let escaped = source.get(cursor + 1UL).unwrap().to_uint64()
      entries.push({ operator: 0x100UL + escaped, operands })
      operands = []
      cursor = cursor + 2UL
    } else if first <= 21UL {
      if operands.length() == 0 {
        return Err(cff_data_error(context + "-arity"))
      }
      entries.push({ operator: first, operands })
      operands = []
      cursor = cursor + 1UL
    } else {
      return Err(cff_data_error(context + "-reserved"))
    }
  }
  if operands.length() != 0 {
    return Err(cff_data_error(context + "-truncated"))
  }
  Ok(entries)
}

///|
fn cff_require_arity(
  entry : CffDictEntry,
  expected : UInt64,
  context : String,
) -> Result[Unit, @error.CoreError] {
  let actual = entry.operands.length().to_uint64()
  if actual != expected {
    Err(cff_data_error(context + "-arity", requested=actual, limit=expected))
  } else {
    Ok(())
  }
}

///|
fn cff_require_even_nonempty(
  entry : CffDictEntry,
  context : String,
) -> Result[Unit, @error.CoreError] {
  let actual = entry.operands.length().to_uint64()
  if actual == 0UL || actual % 2UL != 0UL {
    Err(cff_data_error(context + "-arity", requested=actual))
  } else {
    Ok(())
  }
}

///|
fn cff_decode_top_dict(
  source : @bytes.ByteView,
) -> Result[CffTopDict, @error.CoreError] {
  let entries = match cff_parse_dict(source, "font-cff-top-dict") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut charstring_type = cff_number_unsigned(2UL)
  let mut charstring_type_explicit = false
  let mut charstrings : CffTableOffset? = None
  let mut private_range : CffPrivateRange? = None
  let mut charset : CffTableOffset? = None
  let mut encoding : CffTableOffset? = None
  let mut ros : CffRos? = None
  let mut fd_array : CffTableOffset? = None
  let mut fd_select : CffTableOffset? = None
  let mut font_matrix = cff_default_font_matrix()
  let mut font_matrix_seen = false
  for entry in entries {
    match entry.operator {
      15UL => {
        match cff_require_arity(entry, 1UL, "font-cff-top-charset") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if charset is Some(_) {
          return Err(cff_data_error("font-cff-top-charset-duplicate"))
        }
        let value = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-top-charset",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        charset = Some({ value, })
      }
      16UL => {
        match cff_require_arity(entry, 1UL, "font-cff-top-encoding") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if encoding is Some(_) {
          return Err(cff_data_error("font-cff-top-encoding-duplicate"))
        }
        let value = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-top-encoding",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        encoding = Some({ value, })
      }
      17UL => {
        match cff_require_arity(entry, 1UL, "font-cff-top-charstrings") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if charstrings is Some(_) {
          return Err(cff_data_error("font-cff-top-charstrings-duplicate"))
        }
        let value = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-top-charstrings",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        charstrings = Some({ value, })
      }
      18UL => {
        match cff_require_arity(entry, 2UL, "font-cff-top-private") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if private_range is Some(_) {
          return Err(cff_data_error("font-cff-top-private-duplicate"))
        }
        let size = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-top-private",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let offset = match
          cff_number_nonnegative_integer(
            entry.operands[1],
            "font-cff-top-private",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        private_range = Some({ size, offset: { value: offset } })
      }
      0x106UL => {
        match cff_require_arity(entry, 1UL, "font-cff-charstring-type") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if charstring_type_explicit {
          return Err(cff_data_error("font-cff-charstring-type-duplicate"))
        }
        charstring_type = entry.operands[0]
        charstring_type_explicit = true
      }
      0x107UL => {
        match cff_require_arity(entry, 6UL, "font-cff-font-matrix") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if font_matrix_seen {
          return Err(cff_data_error("font-cff-font-matrix-duplicate"))
        }
        font_matrix = entry.operands
        font_matrix_seen = true
      }
      0x11EUL => {
        match cff_require_arity(entry, 3UL, "font-cff-top-ros") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if ros is Some(_) {
          return Err(cff_data_error("font-cff-top-ros-duplicate"))
        }
        let registry_sid = match
          cff_number_nonnegative_integer(entry.operands[0], "font-cff-top-ros") {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let ordering_sid = match
          cff_number_nonnegative_integer(entry.operands[1], "font-cff-top-ros") {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let supplement = match
          cff_number_nonnegative_integer(entry.operands[2], "font-cff-top-ros") {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        ros = Some({ registry_sid, ordering_sid, supplement })
      }
      0x124UL => {
        match cff_require_arity(entry, 1UL, "font-cff-top-fd-array") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if fd_array is Some(_) {
          return Err(cff_data_error("font-cff-top-fd-array-duplicate"))
        }
        let value = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-top-fd-array",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        fd_array = Some({ value, })
      }
      0x125UL => {
        match cff_require_arity(entry, 1UL, "font-cff-top-fd-select") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if fd_select is Some(_) {
          return Err(cff_data_error("font-cff-top-fd-select-duplicate"))
        }
        let value = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-top-fd-select",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        fd_select = Some({ value, })
      }
      0UL
      | 1UL
      | 2UL
      | 3UL
      | 4UL
      | 13UL
      | 0x100UL
      | 0x101UL
      | 0x102UL
      | 0x103UL
      | 0x104UL
      | 0x105UL
      | 0x108UL
      | 0x114UL
      | 0x115UL
      | 0x116UL
      | 0x11FUL
      | 0x120UL
      | 0x121UL
      | 0x122UL
      | 0x123UL
      | 0x126UL =>
        match cff_require_arity(entry, 1UL, "font-cff-top-operator") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      5UL =>
        match cff_require_arity(entry, 4UL, "font-cff-top-font-bbox") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      14UL | 0x117UL =>
        if entry.operands.length() == 0 {
          return Err(cff_data_error("font-cff-top-operator-arity"))
        }
      _ => return Err(cff_data_error("font-cff-top-operator"))
    }
  }
  let charstrings_value = match charstrings {
    None => return Err(cff_data_error("font-cff-top-charstrings-required"))
    Some(value) => value
  }
  Ok({
    charstring_type,
    charstring_type_explicit,
    charstrings: charstrings_value,
    private_range,
    charset,
    encoding,
    ros,
    fd_array,
    fd_select,
    font_matrix,
  })
}

///|
#warnings("-1")
fn cff_decode_font_dict(
  source : @bytes.ByteView,
) -> Result[CffFontDict, @error.CoreError] {
  let entries = match cff_parse_dict(source, "font-cff-font-dict") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut private_range : CffPrivateRange? = None
  let mut font_matrix = cff_default_font_matrix()
  let mut font_matrix_seen = false
  for entry in entries {
    match entry.operator {
      18UL => {
        match cff_require_arity(entry, 2UL, "font-cff-font-private") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if private_range is Some(_) {
          return Err(cff_data_error("font-cff-font-private-duplicate"))
        }
        let size = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-font-private",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        let offset = match
          cff_number_nonnegative_integer(
            entry.operands[1],
            "font-cff-font-private",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        private_range = Some({ size, offset: { value: offset } })
      }
      0x107UL => {
        match cff_require_arity(entry, 6UL, "font-cff-font-matrix") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if font_matrix_seen {
          return Err(cff_data_error("font-cff-font-matrix-duplicate"))
        }
        font_matrix = entry.operands
        font_matrix_seen = true
      }
      0x126UL =>
        match cff_require_arity(entry, 1UL, "font-cff-font-name") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      _ => return Err(cff_data_error("font-cff-font-operator"))
    }
  }
  Ok({ private_range, font_matrix })
}

///|
fn cff_decode_private_dict(
  source : @bytes.ByteView,
) -> Result[CffPrivateDict, @error.CoreError] {
  let entries = match cff_parse_dict(source, "font-cff-private-dict") {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let mut local_subrs : CffPrivateOffset? = None
  let mut default_width_x = cff_number_zero()
  let mut nominal_width_x = cff_number_zero()
  let mut default_seen = false
  let mut nominal_seen = false
  for entry in entries {
    match entry.operator {
      19UL => {
        match cff_require_arity(entry, 1UL, "font-cff-private-subrs") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if local_subrs is Some(_) {
          return Err(cff_data_error("font-cff-private-subrs-duplicate"))
        }
        let value = match
          cff_number_nonnegative_integer(
            entry.operands[0],
            "font-cff-private-subrs",
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        local_subrs = Some({ value, })
      }
      20UL => {
        match cff_require_arity(entry, 1UL, "font-cff-private-default-width") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if default_seen {
          return Err(cff_data_error("font-cff-private-default-width-duplicate"))
        }
        default_width_x = entry.operands[0]
        default_seen = true
      }
      21UL => {
        match cff_require_arity(entry, 1UL, "font-cff-private-nominal-width") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        if nominal_seen {
          return Err(cff_data_error("font-cff-private-nominal-width-duplicate"))
        }
        nominal_width_x = entry.operands[0]
        nominal_seen = true
      }
      6UL | 7UL | 8UL | 9UL | 0x10CUL | 0x10DUL =>
        match cff_require_even_nonempty(entry, "font-cff-private-array") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      10UL
      | 11UL
      | 0x109UL
      | 0x10AUL
      | 0x10BUL
      | 0x10EUL
      | 0x111UL
      | 0x112UL
      | 0x113UL =>
        match cff_require_arity(entry, 1UL, "font-cff-private-operator") {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
      _ => return Err(cff_data_error("font-cff-private-operator"))
    }
  }
  Ok({ local_subrs, default_width_x, nominal_width_x })
}
