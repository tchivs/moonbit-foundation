///|
#warnings("-7")
priv struct CffGlyphEnvironment {
  fd : UInt64?
  private_dict : CffPrivateDict?
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
}

///|
#warnings("-7")
priv struct CffEncoding {
  format : UInt64
  predefined : UInt64?
  codes : Array[UInt64]
  gids : Array[UInt64]
}

///|
#warnings("-7")
priv struct CffFdSelect {
  format : UInt64
  selectors : Array[UInt64]
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
  private_dict : CffPrivateDict?
  local_subrs : CffIndex
  font_matrix : Array[CffNumber]
}

///|
#warnings("-7")
priv struct CffKeyingResult {
  keying : CffKeying
  glyphs : Array[CffGlyphDescriptor]
  retained_indexes : Array[CffIndex]
}

///|
fn cff_sid_limit(strings : CffIndex) -> Result[UInt64, @error.CoreError] {
  match @checked.checked_add(391UL, strings.count) {
    Err(_) => Err(cff_data_error("font-cff-sid-domain"))
    Ok(value) => Ok(value)
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
    Err(cff_data_error(context, requested=sid, limit=limit))
  } else {
    Ok(())
  }
}

///|
fn cff_keying_empty_encoding() -> CffEncoding {
  { format: 0UL, predefined: Some(0UL), codes: [], gids: [] }
}

///|
fn cff_decode_custom_charset_format_zero(
  cff : TableWindow,
  offset : UInt64,
  num_glyphs : UInt64,
  cid_keyed : Bool,
  strings : CffIndex,
) -> Result[CffCharset, @error.CoreError] {
  match cff_require_window(cff.view, offset, 1UL, "font-cff-charset-format") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let format = cff.view.get(offset).unwrap().to_uint64()
  if format != 0UL {
    return Err(cff_data_error("font-cff-charset-format"))
  }
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
  let values : Array[UInt64] = [0UL]
  let seen : Array[Byte] = []
  let mut seen_byte = 0
  while seen_byte < 8192 {
    seen.push(b'\x00')
    seen_byte = seen_byte + 1
  }
  seen[0] = b'\x01'
  let mut gid = 1UL
  while gid < num_glyphs {
    let value = match read_u16(cff.view, offset + 1UL + (gid - 1UL) * 2UL) {
      Err(_) => return Err(cff_data_error("font-cff-charset-format0"))
      Ok(value) => value
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
    gid = gid + 1UL
  }
  Ok({ format, predefined: None, values })
}

///|
fn cff_decode_fd_select_zero(
  cff : TableWindow,
  offset : UInt64,
  num_glyphs : UInt64,
  fd_count : UInt64,
) -> Result[CffFdSelect, @error.CoreError] {
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
  let format = cff.view.get(offset).unwrap().to_uint64()
  if format != 0UL {
    return Err(cff_data_error("font-cff-fd-select-format"))
  }
  let selectors : Array[UInt64] = []
  let mut gid = 0UL
  while gid < num_glyphs {
    let fd = cff.view.get(offset + 1UL + gid).unwrap().to_uint64()
    if fd >= fd_count {
      return Err(
        cff_data_error(
          "font-cff-fd-select-fd",
          requested=fd,
          limit=fd_count,
        ),
      )
    }
    selectors.push(fd)
    gid = gid + 1UL
  }
  Ok({ format, selectors })
}

///|
fn cff_decode_private_environment(
  cff : TableWindow,
  private_range : CffPrivateRange?,
  font_matrix : Array[CffNumber],
  limits : FontLimits,
  private_context : String,
) -> Result[CffPrivateEnvironment, @error.CoreError] {
  let mut private_dict : CffPrivateDict? = None
  let mut local_subrs = match cff_empty_index(cff.view) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  match private_range {
    None => ()
    Some(range) => {
      let private_view = match
        cff_table_subview(
          cff,
          range.offset.value,
          range.size,
          private_context,
        ) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let decoded = match cff_decode_private_dict(private_view) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      match decoded.local_subrs {
        None => ()
        Some(relative) => {
          let start = match
            @checked.checked_add(range.offset.value, relative.value) {
            Err(_) => return Err(cff_data_error("font-cff-local-subrs-offset"))
            Ok(value) => value
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
      private_dict = Some(decoded)
    }
  }
  Ok({ private_dict, local_subrs, font_matrix })
}

///|
fn cff_resolve_name_keying(
  cff : TableWindow,
  top : CffTopDict,
  strings : CffIndex,
  charstrings : CffIndex,
  num_glyphs : UInt64,
  limits : FontLimits,
) -> Result[CffKeyingResult, @error.CoreError] {
  if top.fd_array is Some(_) || top.fd_select is Some(_) {
    return Err(cff_data_error("font-cff-name-fd-contract"))
  }
  let environment = match
    cff_decode_private_environment(
      cff,
      top.private_range,
      top.font_matrix,
      limits,
      "font-cff-private-range",
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let charset = if num_glyphs == 1UL {
    { format: 0UL, predefined: Some(0UL), values: [0UL] }
  } else {
    match top.charset {
      Some(offset) if offset.value >= 3UL =>
        match
          cff_decode_custom_charset_format_zero(
            cff,
            offset.value,
            num_glyphs,
            false,
            strings,
          ) {
          Err(error) => return Err(error)
          Ok(value) => value
        }
      _ => return Err(cff_data_error("font-cff-name-charset"))
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
      encoding: Some(cff_keying_empty_encoding()),
      ros: None,
      fd_select: None,
      fd_count: 1UL,
    },
    glyphs,
    retained_indexes: [environment.local_subrs],
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
) -> Result[CffKeyingResult, @error.CoreError] {
  let ros = match top.ros {
    None => return Err(cff_data_error("font-cff-cid-ros"))
    Some(value) => value
  }
  match cff_validate_sid(ros.registry_sid, strings, "font-cff-cid-registry-sid") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match cff_validate_sid(ros.ordering_sid, strings, "font-cff-cid-ordering-sid") {
    Err(error) => return Err(error)
    Ok(_) => ()
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
    cff_decode_custom_charset_format_zero(
      cff,
      charset_offset,
      num_glyphs,
      true,
      strings,
    ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  let (fd_array, _) = match
    cff_decode_index(
      cff.view,
      fd_array_offset,
      limits.max_glyphs(),
      "font-cff-fd-array-index",
    ) {
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
  let retained_indexes : Array[CffIndex] = [fd_array]
  let mut fd = 0UL
  while fd < fd_array.count {
    let object = match
      cff_index_object(fd_array, fd, "font-cff-fd-array-index") {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let font_dict = match cff_decode_font_dict(object.view) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    let environment = match
      cff_decode_private_environment(
        cff,
        font_dict.private_range,
        font_dict.font_matrix,
        limits,
        "font-cff-fd-private-range",
      ) {
      Err(error) => return Err(error)
      Ok(value) => value
    }
    retained_indexes.push(environment.local_subrs)
    environments.push(environment)
    fd = fd + 1UL
  }
  let fd_select = match
    cff_decode_fd_select_zero(
      cff,
      fd_select_offset,
      num_glyphs,
      fd_array.count,
    ) {
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
) -> Result[CffKeyingResult, @error.CoreError] {
  match top.ros {
    Some(_) =>
      cff_resolve_cid_keying(cff, top, strings, charstrings, num_glyphs, limits)
    None =>
      cff_resolve_name_keying(
        cff,
        top,
        strings,
        charstrings,
        num_glyphs,
        limits,
      )
  }
}
