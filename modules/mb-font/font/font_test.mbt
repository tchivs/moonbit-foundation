///|
fn assert_invalid_font_limit(
  result : Result[FontLimits, @error.CoreError],
  context : String,
) -> Unit raise {
  let error = result.unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-limits-new"), content="true")
  inspect(error.requested() == Some(0UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
test "font limits preserve every explicit semantic ceiling" {
  let limits = FontLimits::new(
    max_source_bytes=1024UL,
    max_tables=10UL,
    max_table_bytes=256UL,
    max_glyphs=4UL,
    max_name_records=3UL,
    max_cmap_records=2UL,
    max_post_name_bytes=64UL,
    max_work=4096UL,
  ).unwrap()
  inspect(limits.max_source_bytes(), content="1024")
  inspect(limits.max_tables(), content="10")
  inspect(limits.max_table_bytes(), content="256")
  inspect(limits.max_glyphs(), content="4")
  inspect(limits.max_name_records(), content="3")
  inspect(limits.max_cmap_records(), content="2")
  inspect(limits.max_post_name_bytes(), content="64")
  inspect(limits.max_work(), content="4096")
}

///|
test "font limits reject every zero semantic ceiling" {
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=0UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-source-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=0UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-tables",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=0UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-table-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=0UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-glyphs",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=0UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-name-records",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=0UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-cmap-records",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=0UL,
      max_work=1UL,
    ),
    "max-post-name-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=0UL,
    ),
    "max-work",
  )
}

///|
struct FontTestTable {
  tag : Bytes
  payload : Bytes
}

///|
fn font_test_push_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_test_push_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_test_put_u32(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 24).to_byte()
  output[offset + 1] = (value >> 16).to_byte()
  output[offset + 2] = (value >> 8).to_byte()
  output[offset + 3] = value.to_byte()
}

///|
fn font_test_checksum(source : Bytes) -> UInt64 {
  let mut checksum = 0UL
  let mut offset = 0
  while offset < source.length() {
    let b0 = source[offset].to_uint64()
    let b1 = if offset + 1 < source.length() {
      source[offset + 1].to_uint64()
    } else {
      0UL
    }
    let b2 = if offset + 2 < source.length() {
      source[offset + 2].to_uint64()
    } else {
      0UL
    }
    let b3 = if offset + 3 < source.length() {
      source[offset + 3].to_uint64()
    } else {
      0UL
    }
    let word = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    checksum = (checksum + word) & 0xFFFFFFFFUL
    offset = offset + 4
  }
  checksum
}

///|
fn font_test_head_table() -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u32(output, 0UL)
  font_test_push_u32(output, 0x5F0F3CF5UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1000UL)
  for index = 0; index < 16; index = index + 1 {
    output.push(b'\x00')
  }
  for index = 0; index < 8; index = index + 1 {
    output.push(b'\x00')
  }
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 8UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_test_cmap_table() -> Bytes {
  let output : Array[Byte] = []
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 1UL)
  font_test_push_u32(output, 12UL)
  font_test_push_u16(output, 4UL)
  font_test_push_u16(output, 24UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 2UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0xFFFFUL)
  font_test_push_u16(output, 0UL)
  font_test_push_u16(output, 0xFFFFUL)
  font_test_push_u16(output, 1UL)
  font_test_push_u16(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_test_fixed_table(length : Int) -> Bytes {
  Bytes::from_array(Array::make(length, b'\x00'))
}

///|
fn font_test_hhea_table() -> Bytes {
  let output = Array::make(36, b'\x00')
  font_test_put_u32(output, 0, 0x00010000UL)
  font_test_put_u32(output, 32, 1UL)
  output[34] = b'\x00'
  output[35] = b'\x01'
  Bytes::from_array(output)
}

///|
fn font_test_maxp_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  font_test_put_u32(output, 0, 0x00010000UL)
  output[4] = b'\x00'
  output[5] = b'\x01'
  Bytes::from_array(output)
}

///|
fn font_test_name_table() -> Bytes {
  b"\x00\x00\x00\x00\x00\x06"
}

///|
fn font_test_post_table() -> Bytes {
  let output = Array::make(32, b'\x00')
  font_test_put_u32(output, 0, 0x00030000UL)
  Bytes::from_array(output)
}

///|
fn font_test_minimal_truetype() -> Bytes {
  let tables : Array[FontTestTable] = [
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    { tag: b"cmap", payload: font_test_cmap_table() },
    { tag: b"glyf", payload: b"" },
    { tag: b"head", payload: font_test_head_table() },
    { tag: b"hhea", payload: font_test_hhea_table() },
    { tag: b"hmtx", payload: b"\x01\xf4\x00\x00" },
    { tag: b"loca", payload: b"\x00\x00\x00\x00" },
    { tag: b"maxp", payload: font_test_maxp_table() },
    { tag: b"name", payload: font_test_name_table() },
    { tag: b"post", payload: font_test_post_table() },
  ]
  let output : Array[Byte] = []
  font_test_push_u32(output, 0x00010000UL)
  font_test_push_u16(output, 10UL)
  font_test_push_u16(output, 128UL)
  font_test_push_u16(output, 3UL)
  font_test_push_u16(output, 32UL)
  let mut next_offset = 172UL
  let offsets : Array[UInt64] = []
  for table in tables {
    for byte in table.tag {
      output.push(byte)
    }
    font_test_push_u32(output, font_test_checksum(table.payload))
    font_test_push_u32(output, next_offset)
    font_test_push_u32(output, table.payload.length().to_uint64())
    offsets.push(next_offset)
    next_offset = (next_offset + table.payload.length().to_uint64() + 3UL) &
      0xFFFFFFFFFFFFFFFCUL
  }
  for table in tables {
    for byte in table.payload {
      output.push(byte)
    }
    while output.length() % 4 != 0 {
      output.push(b'\x00')
    }
  }
  let zero_adjustment = Bytes::from_array(output.copy())
  let adjustment = (0xB1B0AFBAUL - font_test_checksum(zero_adjustment)) &
    0xFFFFFFFFUL
  font_test_put_u32(output, offsets[3].to_int() + 8, adjustment)
  Bytes::from_array(output)
}

///|
fn font_test_owner(source : Bytes) -> @bytes.OwnedBytes {
  let length = source.length().to_uint64()
  @bytes.OwnedBytes::from_bytes(
    source,
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=length,
        allocations=1UL,
        allocation_size=length,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=0UL,
      ),
    ),
  ).unwrap()
}

///|
fn font_test_limits() -> FontLimits {
  FontLimits::new(
    max_source_bytes=4096UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
}

///|
fn font_test_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=4096UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
test "generated standalone TrueType opens and returns exact units per em" {
  let owner = font_test_owner(font_test_minimal_truetype())
  let budget = font_test_budget()
  let font = Font::open(owner.view(), font_test_limits(), budget).unwrap()
  let after_open = budget.remaining()
  inspect(font.units_per_em().unwrap(), content="1000")
  inspect(font.units_per_em().unwrap(), content="1000")
  let after_queries = budget.remaining()
  inspect(after_queries.bytes() == after_open.bytes(), content="true")
  inspect(after_queries.work() == after_open.work(), content="true")
}

///|
test "unsupported outline signature publishes no Font" {
  let owner = font_test_owner(font_test_minimal_truetype())
  owner.with_mut(
    0UL,
    4UL,
    fn(lease) {
      match lease.set(0UL, b'O') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match lease.set(1UL, b'T') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match lease.set(2UL, b'T') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      match lease.set(3UL, b'O') {
        Err(error) => return Err(error)
        Ok(_) => ()
      }
      Ok(())
    },
  ).unwrap()
  let error = Font::open(
    owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    error.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(error.operation() == Some("font-open"), content="true")
  inspect(error.context() == Some("font-outline-profile"), content="true")
}

///|
fn font_test_mutate_bytes(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  replacement : Bytes,
) -> Unit raise {
  owner.with_mut(
    offset,
    replacement.length().to_uint64(),
    fn(lease) {
      let mut index = 0UL
      while index < replacement.length().to_uint64() {
        match lease.set(index, replacement[index.to_int()]) {
          Err(error) => return Err(error)
          Ok(_) => ()
        }
        index = index + 1UL
      }
      Ok(())
    },
  ).unwrap()
}

///|
fn font_test_mutate_u32(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  value : UInt64,
) -> Unit raise {
  let replacement : Array[Byte] = []
  font_test_push_u32(replacement, value)
  font_test_mutate_bytes(owner, offset, Bytes::from_array(replacement))
}

///|
fn font_test_view_bytes(source : @bytes.ByteView) -> Bytes raise {
  let output : Array[Byte] = []
  let mut offset = 0UL
  while offset < source.length() {
    output.push(source.get(offset).unwrap())
    offset = offset + 1UL
  }
  Bytes::from_array(output)
}

///|
fn font_test_recompute_adjustment(
  owner : @bytes.OwnedBytes,
) -> Unit raise {
  font_test_mutate_u32(owner, 296UL, 0UL)
  let adjustment = (
    0xB1B0AFBAUL - font_test_checksum(font_test_view_bytes(owner.view()))
  ) &
    0xFFFFFFFFUL
  font_test_mutate_u32(owner, 296UL, adjustment)
}

///|
fn font_test_assert_revision_drift(error : @error.CoreError) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-query"), content="true")
  inspect(
    error.context() == Some("font-source-revision-drift"),
    content="true",
  )
}

///|
test "required unrelated and mutate-back source changes invalidate every query" {
  let required_owner = font_test_owner(font_test_minimal_truetype())
  let required_font = Font::open(
    required_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(required_owner, 306UL, b"\x04")
  font_test_assert_revision_drift(required_font.units_per_em().unwrap_err())
  font_test_assert_revision_drift(required_font.units_per_em().unwrap_err())

  let unrelated_owner = font_test_owner(font_test_minimal_truetype())
  let unrelated_font = Font::open(
    unrelated_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(unrelated_owner, 431UL, b"\x01")
  font_test_assert_revision_drift(unrelated_font.units_per_em().unwrap_err())

  let restored_owner = font_test_owner(font_test_minimal_truetype())
  let original = restored_owner.view().get(306UL).unwrap()
  let restored_font = Font::open(
    restored_owner.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap()
  font_test_mutate_bytes(restored_owner, 306UL, b"\x04")
  font_test_mutate_bytes(restored_owner, 306UL, Bytes::from_array([original]))
  font_test_assert_revision_drift(restored_font.units_per_em().unwrap_err())
}

///|
test "directory table escape and missing head publish no Font" {
  let escaped = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_u32(escaped, 68UL, 0xFFFFFFFCUL)
  let range_error = Font::open(
    escaped.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(range_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(range_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(range_error.operation() == Some("font-open"), content="true")
  inspect(range_error.context() == Some("font-table-range"), content="true")

  let missing = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_bytes(missing, 60UL, b"heaf")
  let missing_error = Font::open(
    missing.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(missing_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(missing_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(missing_error.operation() == Some("font-open"), content="true")
  inspect(
    missing_error.context() == Some("font-required-table"),
    content="true",
  )
}

///|
test "head length magic and font adjustment fail at stable semantic gates" {
  let short_head = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_u32(short_head, 64UL, 0UL)
  font_test_mutate_u32(short_head, 72UL, 0UL)
  font_test_recompute_adjustment(short_head)
  let length_error = Font::open(
    short_head.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(length_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(length_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(length_error.context() == Some("font-head-length"), content="true")

  let bad_magic = font_test_owner(font_test_minimal_truetype())
  font_test_mutate_bytes(bad_magic, 300UL, b"\x00")
  font_test_mutate_u32(bad_magic, 296UL, 0UL)
  let head = bad_magic.view().subview(288UL, 54UL).unwrap()
  font_test_mutate_u32(
    bad_magic,
    64UL,
    font_test_checksum(font_test_view_bytes(head)),
  )
  font_test_recompute_adjustment(bad_magic)
  let magic_error = Font::open(
    bad_magic.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(magic_error.category() == @error.ErrorCategory::Data, content="true")
  inspect(magic_error.code() == @error.ErrorCode::InvalidEncoding, content="true")
  inspect(magic_error.context() == Some("font-head-magic"), content="true")

  let bad_adjustment = font_test_owner(font_test_minimal_truetype())
  let original_adjustment_byte = bad_adjustment.view().get(296UL).unwrap()
  font_test_mutate_bytes(
    bad_adjustment,
    296UL,
    Bytes::from_array([(original_adjustment_byte.to_uint64() ^ 1UL).to_byte()]),
  )
  let adjustment_error = Font::open(
    bad_adjustment.view(),
    font_test_limits(),
    font_test_budget(),
  ).unwrap_err()
  inspect(
    adjustment_error.category() == @error.ErrorCategory::Data,
    content="true",
  )
  inspect(
    adjustment_error.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(
    adjustment_error.context() == Some("font-checksum-adjustment"),
    content="true",
  )
}

///|
test "semantic source ceiling and atomic budget charge reject before publication" {
  let source = font_test_minimal_truetype()
  let length = source.length().to_uint64()
  let semantic_budget = font_test_budget()
  let semantic_before = semantic_budget.remaining()
  let semantic_limits = FontLimits::new(
    max_source_bytes=length - 1UL,
    max_tables=32UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_post_name_bytes=256UL,
    max_work=16384UL,
  ).unwrap()
  let semantic_error = Font::open(
    font_test_owner(source).view(),
    semantic_limits,
    semantic_budget,
  ).unwrap_err()
  inspect(
    semantic_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    semantic_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(
    semantic_error.context() == Some("max-source-bytes"),
    content="true",
  )
  let semantic_after = semantic_budget.remaining()
  inspect(semantic_after.bytes() == semantic_before.bytes(), content="true")
  inspect(semantic_after.work() == semantic_before.work(), content="true")

  let narrow_budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=length - 1UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
  let narrow_before = narrow_budget.remaining()
  let budget_error = Font::open(
    font_test_owner(source).view(),
    font_test_limits(),
    narrow_budget,
  ).unwrap_err()
  inspect(
    budget_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    budget_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(budget_error.operation() == Some("budget_charge"), content="true")
  inspect(budget_error.context() == Some("bytes"), content="true")
  let narrow_after = narrow_budget.remaining()
  inspect(narrow_after.bytes() == narrow_before.bytes(), content="true")
  inspect(narrow_after.work() == narrow_before.work(), content="true")
}

///|
test "unsupported containers outlines variations color and bitmap profiles are capabilities" {
  for signature in [b"ttcf", b"wOFF", b"wOF2", b"OTTO"] {
    let owner = font_test_owner(font_test_minimal_truetype())
    font_test_mutate_bytes(owner, 0UL, signature)
    let error = Font::open(
      owner.view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Capability, content="true")
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(error.context() == Some("font-outline-profile"), content="true")
  }
  for tag in [b"CFF ", b"CFF2", b"fvar", b"COLR", b"CBDT", b"sbix"] {
    let owner = font_test_owner(font_test_minimal_truetype())
    font_test_mutate_bytes(owner, 44UL, tag)
    let error = Font::open(
      owner.view(),
      font_test_limits(),
      font_test_budget(),
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Capability, content="true")
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(
      error.context() == Some("font-unsupported-profile"),
      content="true",
    )
  }
}
