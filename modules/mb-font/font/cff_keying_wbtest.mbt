///|
fn cff_key_wb_append(output : Array[Byte], bytes : Bytes) -> Unit {
  for byte in font_wb_bytes_array(bytes) {
    output.push(byte)
  }
}

///|
fn cff_key_wb_dict_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push(b'\x1d')
  font_wb_put_u32(output, value)
}

///|
fn cff_key_wb_index(objects : Array[Bytes]) -> Bytes {
  let output : Array[Byte] = []
  font_wb_put_u16(output, objects.length().to_uint64())
  if objects.length() == 0 {
    return Bytes::from_array(output)
  }
  output.push(b'\x01')
  let mut next = 1UL
  output.push(next.to_byte())
  for object in objects {
    next = next + object.length().to_uint64()
    output.push(next.to_byte())
  }
  for object in objects {
    cff_key_wb_append(output, object)
  }
  Bytes::from_array(output)
}

///|
fn cff_key_wb_assert_atomic_error(
  source : Bytes,
  expected_context : String,
  num_glyphs? : UInt64 = 3UL,
) -> Unit raise {
  let budget = cff_wb_budget()
  let before = budget.remaining()
  let result = admit_cff1_structure(
    font_wb_view(cff_wb_otf(source, num_glyphs~)),
    font_wb_limits(),
    budget,
    0UL,
  )
  inspect(result is Err(_), content="true")
  inspect(
    result.unwrap_err().context() == Some(expected_context),
    content="true",
  )
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(
    budget.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
fn cff_key_wb_authority(work : UInt64) -> CffAuthorityLedger {
  CffAuthorityLedger::new(cff_hostile_budget(0UL, 0UL, 0UL, work), 0UL, 0UL).unwrap()
}

///|
fn cff_key_wb_table_window(source : Bytes) -> TableWindow {
  {
    tag: 0x43464620UL,
    checksum: 0UL,
    offset: 0UL,
    length_value: source.length().to_uint64(),
    view: font_wb_view(source),
  }
}

///|
test "CFF keying lookup groups require work authority before traversal" {
  let empty_strings = cff_empty_index(font_wb_view(b"")).unwrap()

  // StandardEncoding requires the fixed 256-slot scan plus exactly 149
  // nonzero-SID lookups before it may enter the source loop.
  let mut predefined_probes = 0
  let predefined = cff_predefined_encoding(
    0UL,
    { format: 0UL, predefined: Some(0UL), values: [0UL], sid_cid_lookups: 0UL },
    cff_key_wb_authority(404UL),
    fn() { predefined_probes = predefined_probes + 1 },
  )
  inspect(
    predefined.unwrap_err().category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(predefined_probes, content="0")

  // One custom charset SID requires one authorized lookup before record
  // validation starts.
  let custom_charset = b"\x00\x00\x01"
  let mut charset_probes = 0
  let charset = cff_decode_custom_charset(
    cff_key_wb_table_window(custom_charset),
    0UL,
    2UL,
    false,
    empty_strings,
    cff_key_wb_authority(0UL),
    fn() { charset_probes = charset_probes + 1 },
  )
  inspect(
    charset.unwrap_err().category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(charset_probes, content="0")

  // A custom Encoding supplement performs exactly two lookup operations:
  // SID-domain validation and SID-to-GID resolution.
  let custom_encoding = b"\x80\x01\x41\x01\x42\x00\x01"
  let mut supplement_probes = 0
  let encoding = cff_decode_custom_encoding(
    cff_key_wb_table_window(custom_encoding),
    0UL,
    {
      format: 0UL,
      predefined: Some(0UL),
      values: [0UL, 1UL],
      sid_cid_lookups: 0UL,
    },
    empty_strings,
    cff_key_wb_authority(1UL),
    fn() { supplement_probes = supplement_probes + 1 },
  )
  inspect(
    encoding.unwrap_err().category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(supplement_probes, content="0")

  // CID ROS requires its two distinct SID validations before either begins.
  let mut ros_probes = 0
  let ros = cff_validate_ros_sids(
    { registry_sid: 0UL, ordering_sid: 0UL, supplement: 0UL },
    empty_strings,
    cff_key_wb_authority(1UL),
    fn() { ros_probes = ros_probes + 1 },
  )
  inspect(
    ros.unwrap_err().category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(ros_probes, content="0")

  // The same production helper used by Top DICT and Font DICT SID groups
  // rejects one-short authority before the first domain lookup.
  let mut sid_group_probes = 0
  let sid_group = cff_validate_sid_group(
    [0UL, 0UL],
    empty_strings,
    "font-cff-cid-registry-sid",
    cff_key_wb_authority(1UL),
    fn() { sid_group_probes = sid_group_probes + 1 },
  )
  inspect(
    sid_group.unwrap_err().category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(sid_group_probes, content="0")
}
