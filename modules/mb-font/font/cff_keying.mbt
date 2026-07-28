///|
#warnings("-7")
priv struct CffGlyphEnvironment {
  fd : UInt64?
  private_dict : CffPrivateDict
  local_subrs : CffIndex
  top_font_matrix : Array[CffNumber]
  font_matrix : Array[CffNumber]
}

///|
#warnings("-7")
priv struct CffGlyphDescriptor {
  gid : UInt64
  key_value : UInt64
  charstring : CffIndexObject
  environment : CffGlyphEnvironment
}

///|
#warnings("-7")
priv struct CffCharset {
  format : UInt64
  predefined : UInt64?
  values : Array[UInt64]
  sid_cid_lookups : UInt64
}

///|
#warnings("-7")
priv struct CffEncoding {
  format : UInt64
  predefined : UInt64?
  codes : Array[UInt64]
  gids : Array[UInt64]
  sid_cid_lookups : UInt64
}

///|
#warnings("-7")
priv struct CffFdSelect {
  format : UInt64
  selectors : Array[UInt64]
  range_count : UInt64
}

///|
#warnings("-7")
priv struct CffKeying {
  cid_keyed : Bool
  charset : CffCharset
  encoding : CffEncoding?
  ros : CffRos?
  fd_select : CffFdSelect?
  fd_count : UInt64
}

///|
#warnings("-7")
priv struct CffPrivateEnvironment {
  private_dict : CffPrivateDict
  local_subrs : CffIndex
  font_matrix : Array[CffNumber]
  dict_units : UInt64
}

///|
#warnings("-7")
priv struct CffKeyingResult {
  keying : CffKeying
  glyphs : Array[CffGlyphDescriptor]
  retained_indexes : Array[CffIndex]
  dict_units : UInt64
  sid_cid_lookups : UInt64
}

///|
fn cff_sid_limit(strings : CffIndex) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_add(391UL, strings.count) {
    Err(_) => Err(cff_data_error("font-cff-sid-domain"))
    Ok(value) => Ok(if value < 65000UL { value } else { 65000UL })
  }
}

///|
fn cff_validate_sid(
  sid : UInt64,
  strings : CffIndex,
  context : String,
) -> Result[Unit, @error.CoreError] {
  let limit = match cff_sid_limit(strings) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if sid >= limit {
    Err(cff_data_error(context, requested=sid, limit~))
  } else {
    Ok(())
  }
}

///|
/// Authorize a retained SID group before the first domain lookup. The probe is
/// test-only observability for the exact point at which lookup traversal starts.
fn cff_validate_sid_group(
  sids : Array[UInt64],
  strings : CffIndex,
  context : String,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[UInt64, @error.CoreError] {
  let lookup_work = sids.length().to_uint64()
  match authority.preflight(lookup_work, 0UL, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if lookup_work > 0UL {
    lookup_probe()
  }
  for sid in sids {
    match cff_validate_sid(sid, strings, context) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  Ok(lookup_work)
}

///|
fn cff_validate_ros_sids(
  ros : CffRos,
  strings : CffIndex,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[UInt64, @error.CoreError] {
  match authority.preflight(2UL, 0UL, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  lookup_probe()
  match
    cff_validate_sid(ros.registry_sid, strings, "font-cff-cid-registry-sid") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match
    cff_validate_sid(ros.ordering_sid, strings, "font-cff-cid-ordering-sid") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  Ok(2UL)
}

///|
fn cff_expert_charset() -> Array[UInt64] {
  [
    0UL, 1UL, 229UL, 230UL, 231UL, 232UL, 233UL, 234UL, 235UL, 236UL, 237UL, 238UL,
    13UL, 14UL, 15UL, 99UL, 239UL, 240UL, 241UL, 242UL, 243UL, 244UL, 245UL, 246UL,
    247UL, 248UL, 27UL, 28UL, 249UL, 250UL, 251UL, 252UL, 253UL, 254UL, 255UL, 256UL,
    257UL, 258UL, 259UL, 260UL, 261UL, 262UL, 263UL, 264UL, 265UL, 266UL, 109UL,
    110UL, 267UL, 268UL, 269UL, 270UL, 271UL, 272UL, 273UL, 274UL, 275UL, 276UL,
    277UL, 278UL, 279UL, 280UL, 281UL, 282UL, 283UL, 284UL, 285UL, 286UL, 287UL,
    288UL, 289UL, 290UL, 291UL, 292UL, 293UL, 294UL, 295UL, 296UL, 297UL, 298UL,
    299UL, 300UL, 301UL, 302UL, 303UL, 304UL, 305UL, 306UL, 307UL, 308UL, 309UL,
    310UL, 311UL, 312UL, 313UL, 314UL, 315UL, 316UL, 317UL, 318UL, 158UL, 155UL,
    163UL, 319UL, 320UL, 321UL, 322UL, 323UL, 324UL, 325UL, 326UL, 150UL, 164UL,
    169UL, 327UL, 328UL, 329UL, 330UL, 331UL, 332UL, 333UL, 334UL, 335UL, 336UL,
    337UL, 338UL, 339UL, 340UL, 341UL, 342UL, 343UL, 344UL, 345UL, 346UL, 347UL,
    348UL, 349UL, 350UL, 351UL, 352UL, 353UL, 354UL, 355UL, 356UL, 357UL, 358UL,
    359UL, 360UL, 361UL, 362UL, 363UL, 364UL, 365UL, 366UL, 367UL, 368UL, 369UL,
    370UL, 371UL, 372UL, 373UL, 374UL, 375UL, 376UL, 377UL, 378UL,
  ]
}

///|
fn cff_expert_subset_charset() -> Array[UInt64] {
  [
    0UL, 1UL, 231UL, 232UL, 235UL, 236UL, 237UL, 238UL, 13UL, 14UL, 15UL, 99UL, 239UL,
    240UL, 241UL, 242UL, 243UL, 244UL, 245UL, 246UL, 247UL, 248UL, 27UL, 28UL, 249UL,
    250UL, 251UL, 253UL, 254UL, 255UL, 256UL, 257UL, 258UL, 259UL, 260UL, 261UL,
    262UL, 263UL, 264UL, 265UL, 266UL, 109UL, 110UL, 267UL, 268UL, 269UL, 270UL,
    272UL, 300UL, 301UL, 302UL, 305UL, 314UL, 315UL, 158UL, 155UL, 163UL, 320UL,
    321UL, 322UL, 323UL, 324UL, 325UL, 326UL, 150UL, 164UL, 169UL, 327UL, 328UL,
    329UL, 330UL, 331UL, 332UL, 333UL, 334UL, 335UL, 336UL, 337UL, 338UL, 339UL,
    340UL, 341UL, 342UL, 343UL, 344UL, 345UL, 346UL,
  ]
}

///|
fn cff_predefined_charset(
  identifier : UInt64,
  num_glyphs : UInt64,
) -> Result[CffCharset, @error.CoreError] {
  let source = match identifier {
    0UL => {
      let values : Array[UInt64] = []
      let mut sid = 0UL
      while sid < 229UL {
        values.push(sid)
        sid = sid + 1UL
      }
      values
    }
    1UL => cff_expert_charset()
    2UL => cff_expert_subset_charset()
    _ => return Err(cff_data_error("font-cff-name-charset"))
  }
  if num_glyphs > source.length().to_uint64() {
    return Err(
      cff_data_error(
        "font-cff-predefined-charset-coverage",
        requested=num_glyphs,
        limit=source.length().to_uint64(),
      ),
    )
  }
  let values : Array[UInt64] = []
  let mut gid = 0UL
  while gid < num_glyphs {
    values.push(source[gid.to_int()])
    gid = gid + 1UL
  }
  Ok({ format: 0UL, predefined: Some(identifier), values, sid_cid_lookups: 0UL })
}

///|
fn cff_charset_seen_table() -> Array[Byte] {
  let seen : Array[Byte] = []
  let mut index = 0
  while index < 8192 {
    seen.push(b'\x00')
    index = index + 1
  }
  seen
}

///|
fn cff_charset_record_value(
  seen : Array[Byte],
  values : Array[UInt64],
  value : UInt64,
  cid_keyed : Bool,
  strings : CffIndex,
) -> Result[Unit, @error.CoreError] {
  if value == 0UL {
    return Err(cff_data_error("font-cff-charset-notdef"))
  }
  let seen_index = (value >> 3).to_int()
  let seen_mask = 1UL << (value & 7UL).to_int()
  if (seen[seen_index].to_uint64() & seen_mask) != 0UL {
    return Err(
      cff_data_error(
        if cid_keyed {
          "font-cff-cid-duplicate"
        } else {
          "font-cff-sid-duplicate"
        },
      ),
    )
  }
  if !cid_keyed {
    match cff_validate_sid(value, strings, "font-cff-charset-sid") {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  }
  seen[seen_index] = (seen[seen_index].to_uint64() | seen_mask).to_byte()
  values.push(value)
  Ok(())
}

///|
fn cff_decode_custom_charset(
  cff : TableWindow,
  offset : UInt64,
  num_glyphs : UInt64,
  cid_keyed : Bool,
  strings : CffIndex,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[CffCharset, @error.CoreError] {
  match cff_require_window(cff.view, offset, 1UL, "font-cff-charset-format") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = cff.view.get(offset).unwrap().to_uint64()
  if format > 2UL {
    return Err(cff_data_error("font-cff-charset-format"))
  }
  if format == 0UL {
    let entries = num_glyphs - 1UL
    let bytes = match @checked.checked_mul(entries, 2UL) {
      Err(_) => return Err(cff_data_error("font-cff-charset-count"))
      Ok(value) => value
    }
    match
      cff_require_window(
        cff.view,
        offset + 1UL,
        bytes,
        "font-cff-charset-format0",
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
  } else {
    let nleft_width = if format == 1UL { 1UL } else { 2UL }
    let mut cursor = offset + 1UL
    let mut produced = 1UL
    while produced < num_glyphs {
      match
        cff_require_window(
          cff.view,
          cursor,
          2UL + nleft_width,
          "font-cff-charset-range",
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      let first = match read_u16(cff.view, cursor) {
        Err(_) => return Err(cff_data_error("font-cff-charset-range"))
        Ok(value) => value
      }
      let nleft = if format == 1UL {
        cff.view.get(cursor + 2UL).unwrap().to_uint64()
      } else {
        match read_u16(cff.view, cursor + 2UL) {
          Err(_) => return Err(cff_data_error("font-cff-charset-range"))
          Ok(value) => value
        }
      }
      let span = nleft + 1UL
      if span > num_glyphs - produced || first > 65535UL - nleft {
        return Err(cff_data_error("font-cff-charset-range"))
      }
      produced = produced + span
      cursor = cursor + 2UL + nleft_width
    }
  }
  let lookup_work = num_glyphs - 1UL
  match authority.preflight(lookup_work, 0UL, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  if lookup_work > 0UL {
    lookup_probe()
  }
  let values : Array[UInt64] = [0UL]
  let seen = cff_charset_seen_table()
  let mut sid_cid_lookups = 0UL
  seen[0] = b'\x01'
  if format == 0UL {
    let mut gid = 1UL
    while gid < num_glyphs {
      let value = match read_u16(cff.view, offset + 1UL + (gid - 1UL) * 2UL) {
        Err(_) => return Err(cff_data_error("font-cff-charset-format0"))
        Ok(value) => value
      }
      match cff_charset_record_value(seen, values, value, cid_keyed, strings) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      sid_cid_lookups = match @checked.checked_add(sid_cid_lookups, 1UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      gid = gid + 1UL
    }
  } else {
    let nleft_width = if format == 1UL { 1UL } else { 2UL }
    let mut cursor = offset + 1UL
    while values.length().to_uint64() < num_glyphs {
      let first = read_u16(cff.view, cursor).unwrap()
      let nleft = if format == 1UL {
        cff.view.get(cursor + 2UL).unwrap().to_uint64()
      } else {
        read_u16(cff.view, cursor + 2UL).unwrap()
      }
      let mut delta = 0UL
      while delta <= nleft {
        match
          cff_charset_record_value(
            seen,
            values,
            first + delta,
            cid_keyed,
            strings,
          ) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        sid_cid_lookups = match @checked.checked_add(sid_cid_lookups, 1UL) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
        delta = delta + 1UL
      }
      cursor = cursor + 2UL + nleft_width
    }
  }
  Ok({ format, predefined: None, values, sid_cid_lookups })
}

///|
fn cff_standard_encoding() -> Array[UInt64] {
  [
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    1UL, 2UL, 3UL, 4UL, 5UL, 6UL, 7UL, 8UL, 9UL, 10UL, 11UL, 12UL, 13UL, 14UL, 15UL,
    16UL, 17UL, 18UL, 19UL, 20UL, 21UL, 22UL, 23UL, 24UL, 25UL, 26UL, 27UL, 28UL,
    29UL, 30UL, 31UL, 32UL, 33UL, 34UL, 35UL, 36UL, 37UL, 38UL, 39UL, 40UL, 41UL,
    42UL, 43UL, 44UL, 45UL, 46UL, 47UL, 48UL, 49UL, 50UL, 51UL, 52UL, 53UL, 54UL,
    55UL, 56UL, 57UL, 58UL, 59UL, 60UL, 61UL, 62UL, 63UL, 64UL, 65UL, 66UL, 67UL,
    68UL, 69UL, 70UL, 71UL, 72UL, 73UL, 74UL, 75UL, 76UL, 77UL, 78UL, 79UL, 80UL,
    81UL, 82UL, 83UL, 84UL, 85UL, 86UL, 87UL, 88UL, 89UL, 90UL, 91UL, 92UL, 93UL,
    94UL, 95UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 0UL, 96UL, 97UL, 98UL, 99UL, 100UL, 101UL, 102UL, 103UL,
    104UL, 105UL, 106UL, 107UL, 108UL, 109UL, 110UL, 0UL, 111UL, 112UL, 113UL, 114UL,
    0UL, 115UL, 116UL, 117UL, 118UL, 119UL, 120UL, 121UL, 122UL, 0UL, 123UL, 0UL,
    124UL, 125UL, 126UL, 127UL, 128UL, 129UL, 130UL, 131UL, 0UL, 132UL, 133UL, 0UL,
    134UL, 135UL, 136UL, 137UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 138UL, 0UL, 139UL, 0UL, 0UL, 0UL, 0UL, 140UL, 141UL,
    142UL, 143UL, 0UL, 0UL, 0UL, 0UL, 0UL, 144UL, 0UL, 0UL, 0UL, 145UL, 0UL, 0UL,
    146UL, 147UL, 148UL, 149UL, 0UL, 0UL, 0UL, 0UL,
  ]
}

///|
fn cff_expert_encoding() -> Array[UInt64] {
  [
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    1UL, 229UL, 230UL, 0UL, 231UL, 232UL, 233UL, 234UL, 235UL, 236UL, 237UL, 238UL,
    13UL, 14UL, 15UL, 99UL, 239UL, 240UL, 241UL, 242UL, 243UL, 244UL, 245UL, 246UL,
    247UL, 248UL, 27UL, 28UL, 249UL, 250UL, 251UL, 252UL, 0UL, 253UL, 254UL, 255UL,
    256UL, 257UL, 0UL, 0UL, 0UL, 258UL, 0UL, 0UL, 259UL, 260UL, 261UL, 262UL, 0UL,
    0UL, 263UL, 264UL, 265UL, 0UL, 266UL, 109UL, 110UL, 267UL, 268UL, 269UL, 0UL,
    270UL, 271UL, 272UL, 273UL, 274UL, 275UL, 276UL, 277UL, 278UL, 279UL, 280UL,
    281UL, 282UL, 283UL, 284UL, 285UL, 286UL, 287UL, 288UL, 289UL, 290UL, 291UL,
    292UL, 293UL, 294UL, 295UL, 296UL, 297UL, 298UL, 299UL, 300UL, 301UL, 302UL,
    303UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL, 0UL,
    0UL, 0UL, 0UL, 0UL, 304UL, 305UL, 306UL, 0UL, 0UL, 307UL, 308UL, 309UL, 310UL,
    311UL, 0UL, 312UL, 0UL, 0UL, 313UL, 0UL, 0UL, 314UL, 315UL, 0UL, 0UL, 316UL,
    317UL, 318UL, 0UL, 0UL, 0UL, 158UL, 155UL, 163UL, 319UL, 320UL, 321UL, 322UL,
    323UL, 324UL, 325UL, 0UL, 0UL, 326UL, 150UL, 164UL, 169UL, 327UL, 328UL, 329UL,
    330UL, 331UL, 332UL, 333UL, 334UL, 335UL, 336UL, 337UL, 338UL, 339UL, 340UL,
    341UL, 342UL, 343UL, 344UL, 345UL, 346UL, 347UL, 348UL, 349UL, 350UL, 351UL,
    352UL, 353UL, 354UL, 355UL, 356UL, 357UL, 358UL, 359UL, 360UL, 361UL, 362UL,
    363UL, 364UL, 365UL, 366UL, 367UL, 368UL, 369UL, 370UL, 371UL, 372UL, 373UL,
    374UL, 375UL, 376UL, 377UL, 378UL,
  ]
}

///|
fn cff_charset_gid_for_sid(charset : CffCharset, sid : UInt64) -> UInt64? {
  let mut gid = 1UL
  while gid < charset.values.length().to_uint64() {
    if charset.values[gid.to_int()] == sid {
      return Some(gid)
    }
    gid = gid + 1UL
  }
  None
}

///|
fn cff_predefined_encoding(
  identifier : UInt64,
  charset : CffCharset,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[CffEncoding, @error.CoreError] {
  let sid_lookup_work = match identifier {
    0UL => 149UL
    1UL => 165UL
    _ => return Err(cff_data_error("font-cff-name-encoding"))
  }
  let lookup_work = match @checked.checked_add(256UL, sid_lookup_work) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match authority.preflight(lookup_work, 0UL, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  lookup_probe()
  let source = match identifier {
    0UL => cff_standard_encoding()
    1UL => cff_expert_encoding()
    _ => return Err(cff_data_error("font-cff-name-encoding"))
  }
  let codes : Array[UInt64] = []
  let gids : Array[UInt64] = []
  let mut sid_cid_lookups = 0UL
  let mut code = 0UL
  while code < 256UL {
    let sid = source[code.to_int()]
    if sid != 0UL {
      match cff_charset_gid_for_sid(charset, sid) {
        None => ()
        Some(gid) => {
          codes.push(code)
          gids.push(gid)
        }
      }
      sid_cid_lookups = match @checked.checked_add(sid_cid_lookups, 1UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
    }
    code = code + 1UL
  }
  Ok({ format: 0UL, predefined: Some(identifier), codes, gids, sid_cid_lookups })
}

///|
fn cff_decode_custom_encoding(
  cff : TableWindow,
  offset : UInt64,
  charset : CffCharset,
  strings : CffIndex,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[CffEncoding, @error.CoreError] {
  match cff_require_window(cff.view, offset, 2UL, "font-cff-encoding-format") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let raw_format = cff.view.get(offset).unwrap().to_uint64()
  let format = raw_format & 0x7FUL
  if format > 1UL {
    return Err(cff_data_error("font-cff-encoding-format"))
  }
  let codes : Array[UInt64] = []
  let gids : Array[UInt64] = []
  let seen : Array[Bool] = Array::make(256, false)
  let mut sid_cid_lookups = 0UL
  let mut cursor = offset + 2UL
  if format == 0UL {
    let count = cff.view.get(offset + 1UL).unwrap().to_uint64()
    match
      cff_require_window(cff.view, cursor, count, "font-cff-encoding-format0") {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    if count > charset.values.length().to_uint64() - 1UL {
      return Err(cff_data_error("font-cff-encoding-cardinality"))
    }
    let mut index = 0UL
    while index < count {
      let code = cff.view.get(cursor + index).unwrap().to_uint64()
      if seen[code.to_int()] {
        return Err(cff_data_error("font-cff-encoding-code-duplicate"))
      }
      seen[code.to_int()] = true
      codes.push(code)
      gids.push(index + 1UL)
      index = index + 1UL
    }
    cursor = cursor + count
  } else {
    let range_count = cff.view.get(offset + 1UL).unwrap().to_uint64()
    let range_bytes = match @checked.checked_mul(range_count, 2UL) {
      Err(_) => return Err(cff_data_error("font-cff-encoding-range"))
      Ok(value) => value
    }
    match
      cff_require_window(
        cff.view,
        cursor,
        range_bytes,
        "font-cff-encoding-range",
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let mut range = 0UL
    while range < range_count {
      let first = cff.view.get(cursor + range * 2UL).unwrap().to_uint64()
      let nleft = cff.view.get(cursor + range * 2UL + 1UL).unwrap().to_uint64()
      if first > 255UL - nleft {
        return Err(cff_data_error("font-cff-encoding-range"))
      }
      let mut delta = 0UL
      while delta <= nleft {
        let code = first + delta
        if seen[code.to_int()] {
          return Err(cff_data_error("font-cff-encoding-code-duplicate"))
        }
        seen[code.to_int()] = true
        codes.push(code)
        gids.push(gids.length().to_uint64() + 1UL)
        if gids.length().to_uint64() > charset.values.length().to_uint64() - 1UL {
          return Err(cff_data_error("font-cff-encoding-cardinality"))
        }
        delta = delta + 1UL
      }
      range = range + 1UL
    }
    cursor = cursor + range_bytes
  }
  let main_gid_count = gids.length().to_uint64()
  if (raw_format & 0x80UL) != 0UL {
    match
      cff_require_window(cff.view, cursor, 1UL, "font-cff-encoding-supplement") {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let supplement_count = cff.view.get(cursor).unwrap().to_uint64()
    cursor = cursor + 1UL
    let supplement_bytes = match @checked.checked_mul(supplement_count, 3UL) {
      Err(_) => return Err(cff_data_error("font-cff-encoding-supplement"))
      Ok(value) => value
    }
    match
      cff_require_window(
        cff.view,
        cursor,
        supplement_bytes,
        "font-cff-encoding-supplement",
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let lookup_work = match @checked.checked_mul(supplement_count, 2UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match authority.preflight(lookup_work, 0UL, 0UL) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    if lookup_work > 0UL {
      lookup_probe()
    }
    let mut supplement = 0UL
    while supplement < supplement_count {
      let record = cursor + supplement * 3UL
      let code = cff.view.get(record).unwrap().to_uint64()
      let sid = read_u16(cff.view, record + 1UL).unwrap()
      if sid == 0UL {
        return Err(cff_data_error("font-cff-encoding-notdef"))
      }
      match cff_validate_sid(sid, strings, "font-cff-encoding-sid") {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      if seen[code.to_int()] {
        return Err(cff_data_error("font-cff-encoding-code-duplicate"))
      }
      let gid = match cff_charset_gid_for_sid(charset, sid) {
        None => return Err(cff_data_error("font-cff-encoding-sid"))
        Some(value) => value
      }
      if gid == 0UL || gid > main_gid_count {
        return Err(cff_data_error("font-cff-encoding-supplement-gid"))
      }
      sid_cid_lookups = match @checked.checked_add(sid_cid_lookups, 2UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      seen[code.to_int()] = true
      codes.push(code)
      gids.push(gid)
      supplement = supplement + 1UL
    }
  }
  Ok({ format, predefined: None, codes, gids, sid_cid_lookups })
}

///|
fn cff_decode_fd_select(
  cff : TableWindow,
  offset : UInt64,
  num_glyphs : UInt64,
  fd_count : UInt64,
) -> Result[CffFdSelect, @error.CoreError] {
  match cff_require_window(cff.view, offset, 1UL, "font-cff-fd-select-format") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = cff.view.get(offset).unwrap().to_uint64()
  if format == 0UL {
    match
      cff_require_window(
        cff.view,
        offset,
        num_glyphs + 1UL,
        "font-cff-fd-select-format0",
      ) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let selectors : Array[UInt64] = []
    let mut gid = 0UL
    while gid < num_glyphs {
      let fd = cff.view.get(offset + 1UL + gid).unwrap().to_uint64()
      if fd >= fd_count {
        return Err(
          cff_data_error("font-cff-fd-select-fd", requested=fd, limit=fd_count),
        )
      }
      selectors.push(fd)
      gid = gid + 1UL
    }
    return Ok({ format, selectors, range_count: 0UL })
  }
  if format != 3UL {
    return Err(cff_data_error("font-cff-fd-select-format"))
  }
  match
    cff_require_window(
      cff.view,
      offset + 1UL,
      2UL,
      "font-cff-fd-select-format3",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let range_count = read_u16(cff.view, offset + 1UL).unwrap()
  if range_count == 0UL || range_count > num_glyphs {
    return Err(
      cff_data_error(
        "font-cff-fd-select-range-count",
        requested=range_count,
        limit=num_glyphs,
      ),
    )
  }
  let range_bytes = match @checked.checked_mul(range_count, 3UL) {
    Err(_) => return Err(cff_data_error("font-cff-fd-select-format3"))
    Ok(value) => value
  }
  let body_bytes = match @checked.checked_add(range_bytes, 2UL) {
    Err(_) => return Err(cff_data_error("font-cff-fd-select-format3"))
    Ok(value) => value
  }
  match
    cff_require_window(
      cff.view,
      offset + 3UL,
      body_bytes,
      "font-cff-fd-select-format3",
    ) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let mut previous_first = 0UL
  let mut range = 0UL
  while range < range_count {
    let record = offset + 3UL + range * 3UL
    let first = read_u16(cff.view, record).unwrap()
    let fd = cff.view.get(record + 2UL).unwrap().to_uint64()
    if range == 0UL {
      if first != 0UL {
        return Err(cff_data_error("font-cff-fd-select-first"))
      }
    } else if first <= previous_first {
      return Err(cff_data_error("font-cff-fd-select-order"))
    }
    if first >= num_glyphs {
      return Err(
        cff_data_error(
          "font-cff-fd-select-range",
          requested=first,
          limit=num_glyphs,
        ),
      )
    }
    if fd >= fd_count {
      return Err(
        cff_data_error("font-cff-fd-select-fd", requested=fd, limit=fd_count),
      )
    }
    previous_first = first
    range = range + 1UL
  }
  let sentinel = read_u16(cff.view, offset + 3UL + range_bytes).unwrap()
  if sentinel != num_glyphs {
    return Err(
      cff_data_error(
        "font-cff-fd-select-sentinel",
        requested=sentinel,
        limit=num_glyphs,
      ),
    )
  }
  if sentinel <= previous_first {
    return Err(cff_data_error("font-cff-fd-select-order"))
  }
  let selectors : Array[UInt64] = Array::make(num_glyphs.to_int(), 0UL)
  range = 0UL
  while range < range_count {
    let record = offset + 3UL + range * 3UL
    let first = read_u16(cff.view, record).unwrap()
    let fd = cff.view.get(record + 2UL).unwrap().to_uint64()
    let terminal = if range + 1UL < range_count {
      read_u16(cff.view, record + 3UL).unwrap()
    } else {
      sentinel
    }
    let mut gid = first
    while gid < terminal {
      selectors[gid.to_int()] = fd
      gid = gid + 1UL
    }
    range = range + 1UL
  }
  Ok({ format, selectors, range_count })
}

///|
fn cff_decode_private_environment(
  cff : TableWindow,
  private_range : CffPrivateRange,
  font_matrix : Array[CffNumber],
  limits : FontLimits,
  private_context : String,
  authority : CffAuthorityLedger,
) -> Result[CffPrivateEnvironment, @error.CoreError] {
  let mut local_subrs = match cff_empty_index(cff.view) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let private_view = match
    cff_table_subview(
      cff,
      private_range.offset.value,
      private_range.size,
      private_context,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let dict_allocation = match @checked.checked_mul(private_range.size, 32UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match authority.preflight(0UL, 0UL, dict_allocation) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let private_dict = match cff_decode_private_dict(private_view) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match private_dict.local_subrs {
    None => ()
    Some(relative) => {
      let start = match
        @checked.checked_add(private_range.offset.value, relative.value) {
        Err(_) => return Err(cff_data_error("font-cff-local-subrs-offset"))
        Ok(value) => value
      }
      match
        authority.preflight_index(
          cff.view,
          start,
          limits.max_work(),
          "font-cff-local-subrs-index",
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      let (index, _) = match
        cff_decode_index(
          cff.view,
          start,
          limits.max_work(),
          "font-cff-local-subrs-index",
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      local_subrs = index
    }
  }
  Ok({
    private_dict,
    local_subrs,
    font_matrix,
    dict_units: private_dict.dict_units,
  })
}

///|
fn cff_resolve_name_keying(
  cff : TableWindow,
  top : CffTopDict,
  strings : CffIndex,
  charstrings : CffIndex,
  num_glyphs : UInt64,
  limits : FontLimits,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[CffKeyingResult, @error.CoreError] {
  if top.fd_array is Some(_) || top.fd_select is Some(_) {
    return Err(cff_data_error("font-cff-name-fd-contract"))
  }
  let private_range = match top.private_range {
    None => return Err(cff_data_error("font-cff-name-private-required"))
    Some(value) => value
  }
  let environment = match
    cff_decode_private_environment(
      cff,
      private_range,
      top.font_matrix,
      limits,
      "font-cff-private-range",
      authority,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charset_operand = match top.charset {
    None => 0UL
    Some(value) => value.value
  }
  let charset = if charset_operand < 3UL {
    match cff_predefined_charset(charset_operand, num_glyphs) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  } else {
    match
      cff_decode_custom_charset(
        cff, charset_operand, num_glyphs, false, strings, authority, lookup_probe,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let encoding_operand = match top.encoding {
    None => 0UL
    Some(value) => value.value
  }
  let encoding = if encoding_operand < 2UL {
    match
      cff_predefined_encoding(
        encoding_operand, charset, authority, lookup_probe,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  } else {
    match
      cff_decode_custom_encoding(
        cff, encoding_operand, charset, strings, authority, lookup_probe,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
  }
  let glyphs : Array[CffGlyphDescriptor] = []
  let mut gid = 0UL
  while gid < num_glyphs {
    let charstring = match
      cff_index_object(charstrings, gid, "font-cff-charstrings-index") {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    glyphs.push({
      gid,
      key_value: charset.values[gid.to_int()],
      charstring,
      environment: {
        fd: None,
        private_dict: environment.private_dict,
        local_subrs: environment.local_subrs,
        top_font_matrix: top.font_matrix,
        font_matrix: environment.font_matrix,
      },
    })
    gid = gid + 1UL
  }
  Ok({
    keying: {
      cid_keyed: false,
      charset,
      encoding: Some(encoding),
      ros: None,
      fd_select: None,
      fd_count: 1UL,
    },
    glyphs,
    retained_indexes: [environment.local_subrs],
    dict_units: environment.dict_units,
    sid_cid_lookups: match
      @checked.checked_add(charset.sid_cid_lookups, encoding.sid_cid_lookups) {
      Err(error) => return Err(error)
      Ok(value) => value
    },
  })
}

///|
fn cff_resolve_cid_keying(
  cff : TableWindow,
  top : CffTopDict,
  strings : CffIndex,
  charstrings : CffIndex,
  num_glyphs : UInt64,
  limits : FontLimits,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[CffKeyingResult, @error.CoreError] {
  let ros = match top.ros {
    None => return Err(cff_data_error("font-cff-cid-ros"))
    Some(value) => value
  }
  let mut sid_cid_lookups = match
    cff_validate_ros_sids(ros, strings, authority, lookup_probe) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if top.encoding is Some(_) {
    return Err(cff_data_error("font-cff-cid-encoding"))
  }
  let charset_offset = match top.charset {
    None => return Err(cff_data_error("font-cff-cid-charset"))
    Some(value) if value.value < 3UL =>
      return Err(cff_data_error("font-cff-cid-charset"))
    Some(value) => value.value
  }
  let fd_array_offset = match top.fd_array {
    None => return Err(cff_data_error("font-cff-cid-fd-array"))
    Some(value) => value.value
  }
  let fd_select_offset = match top.fd_select {
    None => return Err(cff_data_error("font-cff-cid-fd-select"))
    Some(value) => value.value
  }
  let charset = match
    cff_decode_custom_charset(
      cff, charset_offset, num_glyphs, true, strings, authority, lookup_probe,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  sid_cid_lookups = match
    @checked.checked_add(sid_cid_lookups, charset.sid_cid_lookups) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let (fd_array, _) = match
    ({
      match
        authority.preflight_index(
          cff.view,
          fd_array_offset,
          limits.max_glyphs(),
          "font-cff-fd-array-index",
        ) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      cff_decode_index(
        cff.view,
        fd_array_offset,
        limits.max_glyphs(),
        "font-cff-fd-array-index",
      )
    }) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if fd_array.count == 0UL || fd_array.count > 256UL {
    return Err(
      cff_data_error(
        "font-cff-fd-array-count",
        requested=fd_array.count,
        limit=256UL,
      ),
    )
  }
  let environments : Array[CffPrivateEnvironment] = []
  let environment_allocation = match
    @checked.checked_mul(fd_array.count, 64UL) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match authority.preflight(fd_array.count, 1UL, environment_allocation) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let retained_indexes : Array[CffIndex] = [fd_array]
  let mut dict_units = 0UL
  let mut fd = 0UL
  while fd < fd_array.count {
    let object = match
      cff_index_object(fd_array, fd, "font-cff-fd-array-index") {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let font_dict_allocation = match
      @checked.checked_mul(object.view.length(), 32UL) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    match authority.preflight(0UL, 0UL, font_dict_allocation) {
      Err(error) => return Err(error)
      Ok(_) => ()
    }
    let font_dict = match cff_decode_font_dict(object.view) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let font_dict_lookups = match
      cff_validate_sid_group(
        font_dict.sid_operands,
        strings,
        "font-cff-font-name",
        authority,
        lookup_probe,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    sid_cid_lookups = match
      @checked.checked_add(sid_cid_lookups, font_dict_lookups) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let private_range = match font_dict.private_range {
      None => return Err(cff_data_error("font-cff-fd-private-required"))
      Some(value) => value
    }
    dict_units = match @checked.checked_add(dict_units, font_dict.dict_units) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let environment = match
      cff_decode_private_environment(
        cff,
        private_range,
        font_dict.font_matrix,
        limits,
        "font-cff-fd-private-range",
        authority,
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    retained_indexes.push(environment.local_subrs)
    environments.push(environment)
    dict_units = match
      @checked.checked_add(dict_units, environment.dict_units) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    fd = fd + 1UL
  }
  let fd_select = match
    ({
      let selector_allocation = match @checked.checked_mul(num_glyphs, 8UL) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      match authority.preflight(0UL, 1UL, selector_allocation) {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      cff_decode_fd_select(cff, fd_select_offset, num_glyphs, fd_array.count)
    }) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let glyphs : Array[CffGlyphDescriptor] = []
  let mut gid = 0UL
  while gid < num_glyphs {
    let selected_fd = fd_select.selectors[gid.to_int()]
    let selected = environments[selected_fd.to_int()]
    let charstring = match
      cff_index_object(charstrings, gid, "font-cff-charstrings-index") {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    glyphs.push({
      gid,
      key_value: charset.values[gid.to_int()],
      charstring,
      environment: {
        fd: Some(selected_fd),
        private_dict: selected.private_dict,
        local_subrs: selected.local_subrs,
        top_font_matrix: top.font_matrix,
        font_matrix: selected.font_matrix,
      },
    })
    gid = gid + 1UL
  }
  Ok({
    keying: {
      cid_keyed: true,
      charset,
      encoding: None,
      ros: Some(ros),
      fd_select: Some(fd_select),
      fd_count: fd_array.count,
    },
    glyphs,
    retained_indexes,
    dict_units,
    sid_cid_lookups,
  })
}

///|
fn cff_resolve_keying(
  cff : TableWindow,
  top : CffTopDict,
  strings : CffIndex,
  charstrings : CffIndex,
  num_glyphs : UInt64,
  limits : FontLimits,
  authority : CffAuthorityLedger,
  lookup_probe : () -> Unit,
) -> Result[CffKeyingResult, @error.CoreError] {
  match top.ros {
    Some(_) =>
      cff_resolve_cid_keying(
        cff, top, strings, charstrings, num_glyphs, limits, authority, lookup_probe,
      )
    None =>
      cff_resolve_name_keying(
        cff, top, strings, charstrings, num_glyphs, limits, authority, lookup_probe,
      )
  }
}
