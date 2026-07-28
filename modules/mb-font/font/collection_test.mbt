///|
fn font_collection_test_push_u16(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_collection_test_push_u32(output : Array[Byte], value : UInt64) -> Unit {
  output.push((value >> 24).to_byte())
  output.push((value >> 16).to_byte())
  output.push((value >> 8).to_byte())
  output.push(value.to_byte())
}

///|
fn font_collection_test_put_u16(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn font_collection_test_put_u32(
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
fn font_collection_test_write_directory(
  output : Array[Byte],
  start : Int,
  sfnt_version : UInt64,
  tags : Array[UInt64],
  table_offsets : Array[UInt64],
) -> Unit {
  let count = tags.length()
  font_collection_test_put_u32(output, start, sfnt_version)
  font_collection_test_put_u16(output, start + 4, count.to_uint64())
  let search_range = if count >= 2 { 32UL } else { 16UL }
  let selector = if count >= 2 { 1UL } else { 0UL }
  let range_shift = count.to_uint64() * 16UL - search_range
  font_collection_test_put_u16(output, start + 6, search_range)
  font_collection_test_put_u16(output, start + 8, selector)
  font_collection_test_put_u16(output, start + 10, range_shift)
  let mut index = 0
  while index < count {
    let record = start + 12 + index * 16
    font_collection_test_put_u32(output, record, tags[index])
    font_collection_test_put_u32(output, record + 4, 0x10203040UL)
    font_collection_test_put_u32(output, record + 8, table_offsets[index])
    font_collection_test_put_u32(output, record + 12, 4UL)
    index = index + 1
  }
}

///|
fn font_collection_test_multi_ttc() -> Bytes {
  let output = Array::make(400, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00020000UL)
  font_collection_test_put_u32(output, 8, 5UL)
  for item in [(12, 64UL), (16, 112UL), (20, 144UL), (24, 176UL), (28, 240UL)] {
    let (field, directory) = item
    font_collection_test_put_u32(output, field, directory)
  }
  // TTC v2 DSIG tuple is all-zero: structurally absent.
  font_collection_test_write_directory(
    output,
    64,
    0x00010000UL,
    [0x676C7966UL, 0x6C6F6361UL],
    [272UL, 276UL],
  )
  font_collection_test_write_directory(
    output,
    112,
    0x4F54544FUL,
    [0x43464620UL],
    [280UL],
  )
  font_collection_test_write_directory(
    output,
    144,
    0x4F54544FUL,
    [0x43464632UL],
    [284UL],
  )
  font_collection_test_write_directory(
    output,
    176,
    0x00010000UL,
    [0x66766172UL, 0x676C7966UL, 0x6C6F6361UL],
    [288UL, 292UL, 296UL],
  )
  font_collection_test_write_directory(
    output,
    240,
    0x00010000UL,
    [0x6E616D65UL],
    [300UL],
  )
  Bytes::from_array(output)
}

///|
fn font_collection_test_wrong_rebase_ttc() -> Bytes {
  let output = Array::make(128, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 64UL)
  // Root range [20, 24) is valid. Incorrectly rebasing it at directory 64
  // yields [84, 88), an in-bounds overlap with the directory itself.
  font_collection_test_write_directory(
    output,
    64,
    0x00010000UL,
    [0x6E616D65UL],
    [20UL],
  )
  Bytes::from_array(output)
}

///|
fn font_collection_test_pair_ttc(
  left_tag : UInt64,
  left_checksum : UInt64,
  left_offset : UInt64,
  left_length : UInt64,
  right_tag : UInt64,
  right_checksum : UInt64,
  right_offset : UInt64,
  right_length : UInt64,
) -> Bytes {
  let output = Array::make(160, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 2UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_put_u32(output, 16, 64UL)
  for
    item in [
      (32, left_tag, left_checksum, left_offset, left_length),
      (64, right_tag, right_checksum, right_offset, right_length),
    ] {
    let (start, tag, checksum, offset, length) = item
    font_collection_test_put_u32(output, start, 0x00010000UL)
    font_collection_test_put_u16(output, start + 4, 1UL)
    font_collection_test_put_u16(output, start + 6, 16UL)
    font_collection_test_put_u32(output, start + 12, tag)
    font_collection_test_put_u32(output, start + 16, checksum)
    font_collection_test_put_u32(output, start + 20, offset)
    font_collection_test_put_u32(output, start + 24, length)
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_same_face_overlap_ttc() -> Bytes {
  let output = Array::make(128, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_write_directory(
    output,
    32,
    0x00010000UL,
    [0x676C7966UL, 0x6C6F6361UL],
    [96UL, 96UL],
  )
  Bytes::from_array(output)
}

///|
fn font_collection_test_pair_limits(
  max_retained : UInt64,
  max_work : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=160UL,
    max_faces=2UL,
    max_tables_per_face=1UL,
    max_table_records=2UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=max_retained,
    max_work~,
  ).unwrap()
}

///|
fn font_collection_test_pair_budget(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn font_collection_test_prefix(source : Bytes, length : Int) -> Bytes {
  let output : Array[Byte] = []
  let mut index = 0
  while index < length {
    output.push(source[index])
    index = index + 1
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_zeroes(output : Array[Byte], count : Int) -> Unit {
  let mut index = 0
  while index < count {
    output.push(b'\x00')
    index = index + 1
  }
}

///|
fn font_collection_test_ttc() -> Bytes {
  let output : Array[Byte] = []
  font_collection_test_push_u32(output, 0x74746366UL)
  font_collection_test_push_u32(output, 0x00010000UL)
  font_collection_test_push_u32(output, 1UL)
  font_collection_test_push_u32(output, 32UL)
  font_collection_test_zeroes(output, 16)
  font_collection_test_push_u32(output, 0x00010000UL)
  font_collection_test_push_u16(output, 2UL)
  font_collection_test_push_u16(output, 32UL)
  font_collection_test_push_u16(output, 1UL)
  font_collection_test_push_u16(output, 0UL)
  font_collection_test_push_u32(output, 0x676C7966UL)
  font_collection_test_push_u32(output, 0UL)
  font_collection_test_push_u32(output, 80UL)
  font_collection_test_push_u32(output, 4UL)
  font_collection_test_push_u32(output, 0x6C6F6361UL)
  font_collection_test_push_u32(output, 0UL)
  font_collection_test_push_u32(output, 84UL)
  font_collection_test_push_u32(output, 4UL)
  font_collection_test_zeroes(output, 12)
  Bytes::from_array(output)
}

///|
fn font_collection_test_zero_faces() -> Bytes {
  let output : Array[Byte] = []
  font_collection_test_push_u32(output, 0x74746366UL)
  font_collection_test_push_u32(output, 0x00010000UL)
  font_collection_test_push_u32(output, 0UL)
  Bytes::from_array(output)
}

///|
fn font_collection_test_owner(source : Bytes) -> @bytes.OwnedBytes {
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
fn font_collection_test_limits_with_source(
  max_source_bytes : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes~,
    max_faces=1UL,
    max_tables_per_face=2UL,
    max_table_records=2UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=184UL,
    max_work=47UL,
  ).unwrap()
}

///|
fn font_collection_test_limits() -> FontCollectionLimits {
  font_collection_test_limits_with_source(88UL)
}

///|
fn font_collection_test_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=184UL,
      allocations=2UL,
      allocation_size=48UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=47UL,
    ),
  )
}

///|
fn font_collection_test_assert_error(
  error : @error.CoreError,
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
) -> Unit raise {
  inspect(error.category() == category, content="true")
  inspect(error.code() == code, content="true")
  inspect(error.operation() == Some("font-collection-open"), content="true")
}

///|
fn font_collection_test_assert_budget_unchanged(
  before : @budget.ResourceLimits,
  budget : @budget.Budget,
) -> Unit raise {
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
fn font_collection_test_assert_invalid_limit(
  result : Result[FontCollectionLimits, @error.CoreError],
  context : String,
) -> Unit raise {
  let error = result.unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    error.operation() == Some("font-collection-limits-new"),
    content="true",
  )
  inspect(error.requested() == Some(0UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
fn font_collection_test_mutate(
  owner : @bytes.OwnedBytes,
  offset : UInt64,
  replacement : Byte,
) -> Unit {
  owner
  .with_mut(offset, 1UL, fn(lease) { lease.set(0UL, replacement) })
  .unwrap()
}

///|
fn font_collection_test_assert_query_drift(
  error : @error.CoreError,
) -> Unit raise {
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-collection-query"), content="true")
  inspect(
    error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
}

///|
fn font_collection_test_assert_every_query_drift(
  collection : FontCollection,
) -> Unit raise {
  font_collection_test_assert_query_drift(collection.face_count().unwrap_err())
  font_collection_test_assert_query_drift(
    collection.face_profile(0UL).unwrap_err(),
  )
  font_collection_test_assert_query_drift(collection.dsig_status().unwrap_err())
}

///|
fn font_collection_test_read_u32(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 24) |
  (source[offset + 1].to_uint64() << 16) |
  (source[offset + 2].to_uint64() << 8) |
  source[offset + 3].to_uint64()
}

///|
fn font_collection_test_read_u16(source : Bytes, offset : Int) -> UInt64 {
  (source[offset].to_uint64() << 8) | source[offset + 1].to_uint64()
}

///|
fn font_collection_test_selected_ttc_from(standalone : Bytes) -> Bytes {
  let directory_start = 256
  let output = Array::make(directory_start + standalone.length(), b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, directory_start.to_uint64())
  for index, byte in standalone {
    output[directory_start + index] = byte
  }
  // Relocate every selected table against collection byte zero. `loca` is
  // deliberately placed before the non-zero directory while the other real
  // tables remain after it, so accidental directory-relative rebasing fails.
  let table_count = font_collection_test_read_u16(standalone, 4).to_int()
  let mut loca_record = 0
  for index = 0; index < table_count; index = index + 1 {
    let record = 12 + index * 16
    let old_offset = font_collection_test_read_u32(standalone, record + 8)
    let tag = font_collection_test_read_u32(standalone, record)
    let new_offset = if tag == 0x6C6F6361UL {
      loca_record = record
      32UL
    } else {
      old_offset + directory_start.to_uint64()
    }
    font_collection_test_put_u32(
      output,
      directory_start + record + 8,
      new_offset,
    )
  }
  let loca_offset = font_collection_test_read_u32(standalone, loca_record + 8)
  let loca_length = font_collection_test_read_u32(
    standalone,
    loca_record + 12,
  )
  for index = 0; index < loca_length.to_int(); index = index + 1 {
    output[32 + index] = standalone[loca_offset.to_int() + index]
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_selected_ttc() -> Bytes {
  font_collection_test_selected_ttc_from(font_test_minimal_truetype())
}

///|
fn font_collection_test_equivalence_truetype() -> Bytes {
  let simple = font_test_simple_outline_glyf()
  font_test_build_truetype([
    { tag: b"OS/2", payload: font_test_fixed_table(78) },
    {
      tag: b"cmap",
      payload: font_test_cmap_format12([
        (0x0041UL, 0x0041UL, 1UL),
        (0x1F600UL, 0x1F600UL, 2UL),
      ]),
    },
    { tag: b"glyf", payload: simple },
    { tag: b"head", payload: font_test_head_table() },
    {
      tag: b"hhea",
      payload: font_test_metric_hhea_table_with_count(3UL),
    },
    {
      tag: b"hmtx",
      payload: b"\x01\xf4\x00\x00\x02\x58\x00\x0a\x02\xbc\xff\xec",
    },
    {
      tag: b"kern",
      payload: font_test_kern_format0([(1UL, 2UL, -37)]),
    },
    { tag: b"loca", payload: b"\x00\x00\x00\x00\x00\x0a\x00\x0a" },
    { tag: b"maxp", payload: font_test_maxp_table_with_glyphs(3UL) },
    { tag: b"name", payload: font_test_name_table() },
    { tag: b"post", payload: font_test_post_table() },
  ])
}

///|
fn font_collection_test_assert_point_equal(
  left : @math.Point2,
  right : @math.Point2,
) -> Unit raise {
  inspect(left.x() == right.x(), content="true")
  inspect(left.y() == right.y(), content="true")
}

///|
fn font_collection_test_assert_path_equal(
  left : @math.Path2,
  right : @math.Path2,
) -> Unit raise {
  inspect(left.length() == right.length(), content="true")
  for index = 0; index < left.length(); index = index + 1 {
    match (left.get(index), right.get(index)) {
      (
        Some(@math.PathCommand::MoveTo(left_point)),
        Some(@math.PathCommand::MoveTo(right_point)),
      )
      | (
        Some(@math.PathCommand::LineTo(left_point)),
        Some(@math.PathCommand::LineTo(right_point)),
      ) =>
        font_collection_test_assert_point_equal(left_point, right_point)
      (
        Some(@math.PathCommand::QuadTo(left_control, left_end)),
        Some(@math.PathCommand::QuadTo(right_control, right_end)),
      ) => {
        font_collection_test_assert_point_equal(left_control, right_control)
        font_collection_test_assert_point_equal(left_end, right_end)
      }
      (
        Some(
          @math.PathCommand::CubicTo(
            left_control1,
            left_control2,
            left_end,
          ),
        ),
        Some(
          @math.PathCommand::CubicTo(
            right_control1,
            right_control2,
            right_end,
          ),
        ),
      ) => {
        font_collection_test_assert_point_equal(left_control1, right_control1)
        font_collection_test_assert_point_equal(left_control2, right_control2)
        font_collection_test_assert_point_equal(left_end, right_end)
      }
      (
        Some(@math.PathCommand::Close),
        Some(@math.PathCommand::Close),
      ) => ()
      _ => fail("standalone and selected outline commands differ")
    }
  }
}

///|
fn font_collection_test_assert_bounds_equal(
  left : FontBounds,
  right : FontBounds,
) -> Unit raise {
  inspect(left.x_min() == right.x_min(), content="true")
  inspect(left.y_min() == right.y_min(), content="true")
  inspect(left.x_max() == right.x_max(), content="true")
  inspect(left.y_max() == right.y_max(), content="true")
}

///|
fn font_collection_test_assert_line_metrics_equal(
  left : FontLineMetrics,
  right : FontLineMetrics,
) -> Unit raise {
  inspect(left.ascent() == right.ascent(), content="true")
  inspect(left.descent() == right.descent(), content="true")
  inspect(left.line_gap() == right.line_gap(), content="true")
}

///|
fn font_collection_test_copy_selected_directory(
  output : Array[Byte],
  standalone : Bytes,
  directory_start : Int,
  payload_base : UInt64,
) -> Unit {
  let directory_length = 12 + 10 * 16
  for index = 0; index < directory_length; index = index + 1 {
    output[directory_start + index] = standalone[index]
  }
  for index = 0; index < 10; index = index + 1 {
    let record = 12 + index * 16
    let old_offset = font_collection_test_read_u32(standalone, record + 8)
    font_collection_test_put_u32(
      output,
      directory_start + record + 8,
      payload_base + old_offset,
    )
  }
}

///|
fn font_collection_test_shared_selected_ttc() -> Bytes {
  let standalone = font_test_minimal_truetype()
  let payload_base = 768UL
  let output = Array::make(payload_base.to_int() + standalone.length(), b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 2UL)
  font_collection_test_put_u32(output, 12, 256UL)
  font_collection_test_put_u32(output, 16, 512UL)
  font_collection_test_copy_selected_directory(
    output,
    standalone,
    256,
    payload_base,
  )
  font_collection_test_copy_selected_directory(
    output,
    standalone,
    512,
    payload_base,
  )
  for index, byte in standalone {
    output[payload_base.to_int() + index] = byte
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_mixed_selected_ttc() -> Bytes {
  let standalone = font_test_minimal_truetype()
  let payload_base = 768UL
  let output = Array::make(payload_base.to_int() + standalone.length(), b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 4UL)
  for item in [(12, 256UL), (16, 512UL), (20, 544UL), (24, 576UL)] {
    let (field, directory) = item
    font_collection_test_put_u32(output, field, directory)
  }
  font_collection_test_copy_selected_directory(
    output,
    standalone,
    256,
    payload_base,
  )
  font_collection_test_write_directory(
    output,
    512,
    0x4F54544FUL,
    [0x43464620UL],
    [700UL],
  )
  font_collection_test_write_directory(
    output,
    544,
    0x4F54544FUL,
    [0x43464632UL],
    [704UL],
  )
  font_collection_test_write_directory(
    output,
    576,
    0x00010000UL,
    [0x66766172UL, 0x676C7966UL, 0x6C6F6361UL],
    [708UL, 712UL, 716UL],
  )
  for index, byte in standalone {
    output[payload_base.to_int() + index] = byte
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_selected_limits(source_length : UInt64) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=source_length,
    max_faces=1UL,
    max_tables_per_face=16UL,
    max_table_records=16UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=4096UL,
    max_work=65536UL,
  ).unwrap()
}

///|
fn font_collection_test_selected_collection_limits(
  source_length : UInt64,
  faces : UInt64,
  records : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=source_length,
    max_faces=faces,
    max_tables_per_face=16UL,
    max_table_records=records,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=16384UL,
    max_work=262144UL,
  ).unwrap()
}

///|
fn font_collection_test_selected_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=65536UL,
      allocations=16UL,
      allocation_size=65536UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=65536UL,
    ),
  )
}

///|
fn font_collection_test_selected_budget_with(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  work : UInt64,
) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations~,
      allocation_size~,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn font_collection_test_selected_font_limits(
  max_source_bytes : UInt64,
  max_work? : UInt64 = 16384UL,
) -> FontLimits {
  FontLimits::new(
    max_source_bytes~,
    max_tables=16UL,
    max_table_bytes=1024UL,
    max_glyphs=16UL,
    max_name_records=16UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=256UL,
    max_outline_points=4096UL,
    max_outline_contours=256UL,
    max_outline_components=256UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=256UL,
    max_work~,
  ).unwrap()
}

///|
test "TTC-02 opens a cached static face against the retained collection root" {
  let source = font_collection_test_selected_ttc()
  let owner = font_collection_test_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_selected_limits(source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let first = collection
    .open_face(0UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
  let second = collection
    .open_face(0UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
  inspect(first.units_per_em().unwrap(), content="1000")
  inspect(second.units_per_em().unwrap(), content="1000")
  inspect(first.global_bounds().unwrap().x_min(), content="0")
  inspect(first.hhea_line_metrics().unwrap().ascent(), content="0")
  inspect(first.typographic_line_metrics().unwrap().descent(), content="0")
  inspect(first.glyph_for_scalar(65).unwrap().value(), content="0")
  let glyph = first.glyph_id(0UL).unwrap()
  inspect(first.horizontal_metrics(glyph).unwrap().advance_width(), content="500")
  inspect(first.kerning(glyph, glyph).unwrap(), content="0")
  inspect(
    first.outline(glyph, font_test_outline_budget()).unwrap().length(),
    content="0",
  )
}

///|
test "Phase 104 freezes the public selected static glyf fingerprint" {
  let source = font_collection_test_selected_ttc()
  let owner = font_collection_test_owner(source)
  let collection_budget = font_collection_test_selected_budget()
  let collection_before = collection_budget.remaining()
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_selected_limits(source.length().to_uint64()),
    collection_budget,
  ).unwrap()
  inspect(collection.face_count().unwrap(), content="1")
  inspect(
    collection.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  let face_budget = font_collection_test_selected_budget()
  let face_before = face_budget.remaining()
  let font = collection
    .open_face(0UL, font_test_limits(), face_budget)
    .unwrap()
  let glyph = font.glyph_id(0UL).unwrap()
  inspect(font.units_per_em().unwrap(), content="1000")
  inspect(font.horizontal_metrics(glyph).unwrap().advance_width(), content="500")
  inspect(font.kerning(glyph, glyph).unwrap(), content="0")
  inspect(
    font.outline(glyph, font_test_outline_budget()).unwrap().length(),
    content="0",
  )
  inspect(
    collection_budget.remaining().bytes() < collection_before.bytes(),
    content="true",
  )
  inspect(face_budget.remaining().bytes() < face_before.bytes(), content="true")
  inspect(face_budget.remaining().work() < face_before.work(), content="true")
}

///|
test "TTC-02 standalone and selected faces are publicly equivalent" {
  let standalone_source = font_collection_test_equivalence_truetype()
  let head_offset = font_test_table_offset(standalone_source, b"head")
  inspect(
    font_collection_test_read_u32(
      standalone_source,
      head_offset.to_int() + 8,
    ) != 0UL,
    content="true",
  )
  let standalone_owner = font_collection_test_owner(standalone_source)
  let standalone = Font::open(
    standalone_owner.view(),
    font_collection_test_selected_font_limits(
      standalone_source.length().to_uint64(),
    ),
    font_collection_test_selected_budget(),
  ).unwrap()

  let collection_source = font_collection_test_selected_ttc_from(
    standalone_source,
  )
  let collection_owner = font_collection_test_owner(collection_source)
  let collection = FontCollection::open(
    collection_owner.view(),
    font_collection_test_selected_collection_limits(
      collection_source.length().to_uint64(),
      1UL,
      11UL,
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  let selected = collection
    .open_face(
      0UL,
      font_collection_test_selected_font_limits(
        collection_source.length().to_uint64(),
      ),
      font_collection_test_selected_budget(),
    )
    .unwrap()

  inspect(
    standalone.units_per_em().unwrap() == selected.units_per_em().unwrap(),
    content="true",
  )
  font_collection_test_assert_bounds_equal(
    standalone.global_bounds().unwrap(),
    selected.global_bounds().unwrap(),
  )
  font_collection_test_assert_line_metrics_equal(
    standalone.hhea_line_metrics().unwrap(),
    selected.hhea_line_metrics().unwrap(),
  )
  font_collection_test_assert_line_metrics_equal(
    standalone.typographic_line_metrics().unwrap(),
    selected.typographic_line_metrics().unwrap(),
  )

  let standalone_bmp = standalone.glyph_for_scalar(0x0041).unwrap()
  let selected_bmp = selected.glyph_for_scalar(0x0041).unwrap()
  let standalone_supplementary = standalone
    .glyph_for_scalar(0x1F600)
    .unwrap()
  let selected_supplementary = selected.glyph_for_scalar(0x1F600).unwrap()
  inspect(
    standalone_bmp.value() == selected_bmp.value(),
    content="true",
  )
  inspect(
    standalone_supplementary.value() == selected_supplementary.value(),
    content="true",
  )
  inspect(
    standalone.glyph_id(1UL).unwrap().value() ==
    selected.glyph_id(1UL).unwrap().value(),
    content="true",
  )

  for pair in [
    (standalone_bmp, selected_bmp),
    (standalone_supplementary, selected_supplementary),
  ] {
    let (standalone_glyph, selected_glyph) = pair
    let standalone_metrics = standalone
      .horizontal_metrics(standalone_glyph)
      .unwrap()
    let selected_metrics = selected.horizontal_metrics(selected_glyph).unwrap()
    inspect(
      standalone_metrics.advance_width() == selected_metrics.advance_width(),
      content="true",
    )
    inspect(
      standalone_metrics.left_side_bearing() ==
      selected_metrics.left_side_bearing(),
      content="true",
    )
    inspect(
      standalone_metrics.right_side_bearing() ==
      selected_metrics.right_side_bearing(),
      content="true",
    )
    match (standalone_metrics.bounds(), selected_metrics.bounds()) {
      (Some(left), Some(right)) =>
        font_collection_test_assert_bounds_equal(left, right)
      (None, None) => ()
      _ => fail("standalone and selected glyph bounds differ")
    }
  }

  inspect(
    standalone.kerning(standalone_bmp, standalone_supplementary).unwrap() ==
    selected.kerning(selected_bmp, selected_supplementary).unwrap(),
    content="true",
  )
  inspect(
    standalone.kerning(standalone_supplementary, standalone_bmp).unwrap() ==
    selected.kerning(selected_supplementary, selected_bmp).unwrap(),
    content="true",
  )
  font_collection_test_assert_path_equal(
    standalone
    .outline(standalone_bmp, font_test_composite_budget())
    .unwrap(),
    selected.outline(selected_bmp, font_test_composite_budget()).unwrap(),
  )
}

///|
test "TTC-02 selection gates revision then index then cached profile" {
  let selected_source = font_collection_test_selected_ttc()
  let selected_owner = font_collection_test_owner(selected_source)
  let selected = FontCollection::open(
    selected_owner.view(),
    font_collection_test_selected_limits(selected_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let index_budget = font_collection_test_selected_budget()
  let index_before = index_budget.remaining()
  let index_error = selected
    .open_face(1UL, font_test_limits(), index_budget)
    .unwrap_err()
  inspect(
    index_error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(index_error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    index_error.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(index_error.requested() == Some(1UL), content="true")
  inspect(index_error.limit() == Some(1UL), content="true")
  inspect(
    index_error.context() == Some("font-collection-face-index"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(index_before, index_budget)
  font_collection_test_mutate(selected_owner, 20UL, b'\x01')
  let drift_budget = font_collection_test_selected_budget()
  let drift_before = drift_budget.remaining()
  let drift = selected
    .open_face(1UL, font_test_limits(), drift_budget)
    .unwrap_err()
  inspect(drift.category() == @error.ErrorCategory::State, content="true")
  inspect(drift.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    drift.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(
    drift.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(drift_before, drift_budget)

  let mixed_owner = font_collection_test_owner(font_collection_test_multi_ttc())
  let mixed = FontCollection::open(
    mixed_owner.view(),
    FontCollectionLimits::new(
      max_source_bytes=400UL,
      max_faces=5UL,
      max_tables_per_face=3UL,
      max_table_records=8UL,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=440UL,
      max_work=252UL,
    ).unwrap(),
    @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=440UL,
        allocations=2UL,
        allocation_size=200UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=252UL,
      ),
    ),
  ).unwrap()
  let profile_budget = font_collection_test_selected_budget()
  let profile_before = profile_budget.remaining()
  let profile = mixed
    .open_face(1UL, font_test_limits(), profile_budget)
    .unwrap_err()
  inspect(
    profile.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    profile.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(
    profile.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(
    profile.context() == Some("font-collection-face-profile"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(profile_before, profile_budget)
}

///|
test "TTC-02 selected multi-fault precedence is exact and atomic" {
  let mixed_source = font_collection_test_multi_ttc()
  let mixed = FontCollection::open(
    font_collection_test_owner(mixed_source).view(),
    FontCollectionLimits::new(
      max_source_bytes=400UL,
      max_faces=5UL,
      max_tables_per_face=3UL,
      max_table_records=8UL,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=440UL,
      max_work=252UL,
    ).unwrap(),
    font_collection_test_pair_budget(440UL, 2UL, 200UL, 252UL),
  ).unwrap()

  let index_budget = font_collection_test_selected_budget()
  let index_before = index_budget.remaining()
  let index = mixed
    .open_face(5UL, font_test_limits(), index_budget)
    .unwrap_err()
  inspect(
    index.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(index.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    index.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(index.context() == Some("font-collection-face-index"), content="true")
  inspect(index.requested() == Some(5UL), content="true")
  inspect(index.limit() == Some(5UL), content="true")
  font_collection_test_assert_budget_unchanged(index_before, index_budget)

  let depleted = font_collection_test_selected_budget_with(0UL, 0UL, 0UL, 0UL)
  let depleted_before = depleted.remaining()
  let profile = mixed
    .open_face(
      1UL,
      font_collection_test_selected_font_limits(1UL, max_work=1UL),
      depleted,
    )
    .unwrap_err()
  inspect(
    profile.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    profile.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(
    profile.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(
    profile.context() == Some("font-collection-face-profile"),
    content="true",
  )
  inspect(profile.source_offset() is None, content="true")
  inspect(profile.requested() is None, content="true")
  inspect(profile.limit() is None, content="true")
  font_collection_test_assert_budget_unchanged(depleted_before, depleted)

  let malformed_standalone = font_test_minimal_truetype().to_array()
  font_collection_test_put_u32(malformed_standalone, 64, 0UL)
  font_collection_test_put_u32(malformed_standalone, 72, 0UL)
  let malformed_source = font_collection_test_selected_ttc_from(
    Bytes::from_array(malformed_standalone),
  )
  let malformed = FontCollection::open(
    font_collection_test_owner(malformed_source).view(),
    font_collection_test_selected_limits(
      malformed_source.length().to_uint64(),
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  let malformed_budget = font_collection_test_selected_budget_with(
    1UL,
    3UL,
    640UL,
    65536UL,
  )
  let malformed_before = malformed_budget.remaining()
  let structural = malformed
    .open_face(0UL, font_test_limits(), malformed_budget)
    .unwrap_err()
  inspect(structural.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    structural.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(structural.operation() == Some("font-open"), content="true")
  inspect(structural.context() == Some("font-head-length"), content="true")
  font_collection_test_assert_budget_unchanged(
    malformed_before,
    malformed_budget,
  )

  let missing_standalone = font_test_minimal_truetype().to_array()
  missing_standalone[63] = b'e'
  let cmap_offset = font_collection_test_read_u32(
    Bytes::from_array(missing_standalone.copy()),
    12 + 16 + 8,
  )
  missing_standalone[cmap_offset.to_int()] = (
    missing_standalone[cmap_offset.to_int()].to_uint64() ^ 1UL
  ).to_byte()
  let missing_source = font_collection_test_selected_ttc_from(
    Bytes::from_array(missing_standalone),
  )
  let missing = FontCollection::open(
    font_collection_test_owner(missing_source).view(),
    font_collection_test_selected_limits(missing_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let missing_budget = font_collection_test_selected_budget()
  let missing_before = missing_budget.remaining()
  let required = missing
    .open_face(0UL, font_test_limits(), missing_budget)
    .unwrap_err()
  inspect(required.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    required.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(required.operation() == Some("font-open"), content="true")
  inspect(required.context() == Some("font-required-table"), content="true")
  inspect(required.source_offset() is None, content="true")
  inspect(required.requested() is None, content="true")
  inspect(required.limit() is None, content="true")
  font_collection_test_assert_budget_unchanged(missing_before, missing_budget)

  let bad = font_collection_test_selected_ttc().to_array()
  let bad_cmap_offset = font_collection_test_read_u32(
    Bytes::from_array(bad.copy()),
    256 + 12 + 16 + 8,
  )
  bad[bad_cmap_offset.to_int()] = (
    bad[bad_cmap_offset.to_int()].to_uint64() ^ 1UL
  ).to_byte()
  let bad_source = Bytes::from_array(bad)
  let bad_collection = FontCollection::open(
    font_collection_test_owner(bad_source).view(),
    font_collection_test_selected_limits(bad_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let checksum_budget = font_collection_test_selected_budget_with(
    1UL,
    3UL,
    640UL,
    65536UL,
  )
  let checksum_before = checksum_budget.remaining()
  let checksum = bad_collection
    .open_face(0UL, font_test_limits(), checksum_budget)
    .unwrap_err()
  inspect(checksum.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    checksum.code() == @error.ErrorCode::InvalidEncoding,
    content="true",
  )
  inspect(checksum.operation() == Some("font-open"), content="true")
  inspect(checksum.context() == Some("font-table-checksum"), content="true")
  inspect(checksum.source_offset() == Some(bad_cmap_offset), content="true")
  inspect(
    checksum.requested() ==
    Some(font_collection_test_read_u32(bad_source, 256 + 12 + 16 + 12)),
    content="true",
  )
  inspect(checksum.limit() is None, content="true")
  font_collection_test_assert_budget_unchanged(
    checksum_before,
    checksum_budget,
  )
}

///|
test "TTC-03 exact sharing and unsupported siblings stay selection local" {
  let shared_source = font_collection_test_shared_selected_ttc()
  let shared_owner = font_collection_test_owner(shared_source)
  let shared = FontCollection::open(
    shared_owner.view(),
    font_collection_test_selected_collection_limits(
      shared_source.length().to_uint64(),
      2UL,
      20UL,
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  let first = shared
    .open_face(0UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
  let last = shared
    .open_face(1UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
  inspect(first.units_per_em().unwrap(), content="1000")
  inspect(last.units_per_em().unwrap(), content="1000")
  inspect(
    first.horizontal_metrics(first.glyph_id(0UL).unwrap()).unwrap().advance_width(),
    content="500",
  )
  inspect(
    last.horizontal_metrics(last.glyph_id(0UL).unwrap()).unwrap().advance_width(),
    content="500",
  )

  let mixed_source = font_collection_test_mixed_selected_ttc()
  let mixed_owner = font_collection_test_owner(mixed_source)
  let mixed = FontCollection::open(
    mixed_owner.view(),
    font_collection_test_selected_collection_limits(
      mixed_source.length().to_uint64(),
      4UL,
      15UL,
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  inspect(
    mixed
    .open_face(0UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
    .units_per_em()
    .unwrap(),
    content="1000",
  )
  for index in [1UL, 2UL, 3UL] {
    let budget = font_collection_test_selected_budget()
    let before = budget.remaining()
    let error = mixed.open_face(index, font_test_limits(), budget).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
    inspect(
      error.context() == Some("font-collection-face-profile"),
      content="true",
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-02 selected D plus T charge is exact and every failure is atomic" {
  let source = font_collection_test_selected_ttc()
  let owner = font_collection_test_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_selected_limits(source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let mut table_bytes = 0UL
  for index = 0; index < 10; index = index + 1 {
    table_bytes = table_bytes +
      font_collection_test_read_u32(source, 256 + 12 + index * 16 + 12)
  }
  let expected_bytes = 172UL + table_bytes
  let exact = font_collection_test_selected_budget()
  let exact_before = exact.remaining()
  let exact_limits = font_collection_test_selected_font_limits(
    source.length().to_uint64(),
  )
  let opened = collection.open_face(0UL, exact_limits, exact).unwrap()
  let exact_after = exact.remaining()
  inspect(
    exact_before.bytes() - exact_after.bytes() == expected_bytes,
    content="true",
  )
  inspect(
    exact_before.allocations() - exact_after.allocations() == 3UL,
    content="true",
  )
  let exact_work = exact_before.work() - exact_after.work()
  inspect(exact_work > 0UL, content="true")
  inspect(opened.units_per_em().unwrap(), content="1000")
  inspect(
    collection
    .open_face(
      0UL,
      font_collection_test_selected_font_limits(
        source.length().to_uint64(),
        max_work=exact_work,
      ),
      font_collection_test_selected_budget(),
    )
    .unwrap()
    .units_per_em()
    .unwrap(),
    content="1000",
  )
  let short_work_budget = font_collection_test_selected_budget()
  let short_work_before = short_work_budget.remaining()
  let short_work = collection
    .open_face(
      0UL,
      font_collection_test_selected_font_limits(
        source.length().to_uint64(),
        max_work=exact_work - 1UL,
      ),
      short_work_budget,
    )
    .unwrap_err()
  inspect(
    short_work.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    short_work.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(short_work.operation() == Some("font-open"), content="true")
  inspect(short_work.context() == Some("max-work"), content="true")
  inspect(short_work.requested() == Some(exact_work), content="true")
  inspect(short_work.limit() == Some(exact_work - 1UL), content="true")
  font_collection_test_assert_budget_unchanged(
    short_work_before,
    short_work_budget,
  )
  for item in [
    (
      expected_bytes - 1UL,
      3UL,
      640UL,
      exact_work,
      "bytes",
      expected_bytes,
      expected_bytes - 1UL,
    ),
    (
      expected_bytes,
      2UL,
      640UL,
      exact_work,
      "allocations",
      3UL,
      2UL,
    ),
    (
      expected_bytes,
      3UL,
      639UL,
      exact_work,
      "allocation_size",
      640UL,
      639UL,
    ),
    (
      expected_bytes,
      3UL,
      640UL,
      exact_work - 1UL,
      "work",
      exact_work,
      exact_work - 1UL,
    ),
  ] {
    let (
      bytes,
      allocations,
      allocation_size,
      work,
      context,
      requested,
      limit,
    ) = item
    let budget = @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes~,
        allocations~,
        allocation_size~,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work~,
      ),
    )
    let before = budget.remaining()
    let error = collection
      .open_face(0UL, exact_limits, budget)
      .unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.operation() == Some("budget_charge"), content="true")
    inspect(error.context() == Some(context), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == Some(limit), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let short_source_budget = font_collection_test_selected_budget()
  let short_source_before = short_source_budget.remaining()
  let short_source = collection
    .open_face(
      0UL,
      font_collection_test_selected_font_limits(
        source.length().to_uint64() - 1UL,
      ),
      short_source_budget,
    )
    .unwrap_err()
  inspect(
    short_source.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    short_source.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(short_source.operation() == Some("font-open"), content="true")
  inspect(short_source.context() == Some("max-source-bytes"), content="true")
  inspect(
    short_source.requested() == Some(source.length().to_uint64()),
    content="true",
  )
  inspect(
    short_source.limit() == Some(source.length().to_uint64() - 1UL),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    short_source_before,
    short_source_budget,
  )

  let ancestor = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=expected_bytes,
      allocations=3UL,
      allocation_size=640UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=exact_work,
    ),
  )
  let child = ancestor.child(ancestor.remaining()).unwrap()
  ancestor.charge(
    @budget.ResourceCharge::new(
      bytes=1UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=0UL,
    ),
  ).unwrap()
  let ancestor_before = ancestor.remaining()
  let child_before = child.remaining()
  let ancestor_error = collection.open_face(0UL, exact_limits, child).unwrap_err()
  inspect(
    ancestor_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    ancestor_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(
    ancestor_error.operation() == Some("budget_charge"),
    content="true",
  )
  inspect(ancestor_error.context() == Some("bytes"), content="true")
  inspect(ancestor_error.requested() == Some(expected_bytes), content="true")
  inspect(
    ancestor_error.limit() == Some(expected_bytes - 1UL),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(ancestor_before, ancestor)
  font_collection_test_assert_budget_unchanged(child_before, child)

  let work_ancestor = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=expected_bytes,
      allocations=3UL,
      allocation_size=640UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=exact_work,
    ),
  )
  let work_child = work_ancestor.child(work_ancestor.remaining()).unwrap()
  work_ancestor.charge(
    @budget.ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=1UL,
    ),
  ).unwrap()
  let work_ancestor_before = work_ancestor.remaining()
  let work_child_before = work_child.remaining()
  let work_ancestor_error = collection
    .open_face(0UL, exact_limits, work_child)
    .unwrap_err()
  inspect(
    work_ancestor_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    work_ancestor_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(
    work_ancestor_error.operation() == Some("budget_charge"),
    content="true",
  )
  inspect(work_ancestor_error.context() == Some("work"), content="true")
  inspect(
    work_ancestor_error.requested() == Some(exact_work),
    content="true",
  )
  inspect(
    work_ancestor_error.limit() == Some(exact_work - 1UL),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    work_ancestor_before,
    work_ancestor,
  )
  font_collection_test_assert_budget_unchanged(work_child_before, work_child)

  let bad = source.to_array()
  let cmap_offset = font_collection_test_read_u32(source, 256 + 12 + 16 + 8)
  bad[cmap_offset.to_int()] = (bad[cmap_offset.to_int()].to_uint64() ^ 1UL).to_byte()
  let bad_source = Bytes::from_array(bad)
  let bad_owner = font_collection_test_owner(bad_source)
  let bad_collection = FontCollection::open(
    bad_owner.view(),
    font_collection_test_selected_limits(bad_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let bad_budget = font_collection_test_selected_budget()
  let bad_before = bad_budget.remaining()
  let checksum = bad_collection
    .open_face(0UL, font_test_limits(), bad_budget)
    .unwrap_err()
  inspect(checksum.category() == @error.ErrorCategory::Data, content="true")
  inspect(checksum.context() == Some("font-table-checksum"), content="true")
  font_collection_test_assert_budget_unchanged(bad_before, bad_budget)
}

///|
test "TTC-02 selected Fonts inherit permanent root mutation identity" {
  let source = font_collection_test_selected_ttc()
  let owner = font_collection_test_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_selected_limits(source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let first_budget = font_collection_test_selected_budget()
  let second_budget = font_collection_test_selected_budget()
  let first_before = first_budget.remaining()
  let second_before = second_budget.remaining()
  let first = collection.open_face(0UL, font_test_limits(), first_budget).unwrap()
  let second = collection
    .open_face(0UL, font_test_limits(), second_budget)
    .unwrap()
  let first_glyph = first.glyph_id(0UL).unwrap()
  let second_glyph = second.glyph_id(0UL).unwrap()
  inspect(
    first_before.bytes() - first_budget.remaining().bytes() ==
    second_before.bytes() - second_budget.remaining().bytes(),
    content="true",
  )
  inspect(
    first_before.work() - first_budget.remaining().work() ==
    second_before.work() - second_budget.remaining().work(),
    content="true",
  )
  let original = owner.view().get(32UL).unwrap()
  font_collection_test_mutate(
    owner,
    32UL,
    (original.to_uint64() ^ 1UL).to_byte(),
  )
  font_collection_test_mutate(owner, 32UL, original)
  for item in [(first, first_glyph), (second, second_glyph)] {
    let (font, glyph) = item
    for error in [
      font.units_per_em().unwrap_err(),
      font.global_bounds().unwrap_err(),
      font.hhea_line_metrics().unwrap_err(),
      font.typographic_line_metrics().unwrap_err(),
      font.glyph_for_scalar(65).unwrap_err(),
      font.glyph_id(0UL).unwrap_err(),
      font.horizontal_metrics(glyph).unwrap_err(),
      font.kerning(glyph, glyph).unwrap_err(),
      font.outline(glyph, font_test_outline_budget()).unwrap_err(),
    ] {
      inspect(error.category() == @error.ErrorCategory::State, content="true")
      inspect(
        error.context() == Some("font-source-revision-drift"),
        content="true",
      )
    }
  }
}

///|
fn font_collection_test_limits_result(
  max_source_bytes : UInt64,
  max_faces : UInt64,
  max_tables_per_face : UInt64,
  max_table_records : UInt64,
  max_dsig_records : UInt64,
  max_dsig_bytes : UInt64,
  max_retained_bookkeeping_bytes : UInt64,
  max_work : UInt64,
) -> Result[FontCollectionLimits, @error.CoreError] {
  FontCollectionLimits::new(
    max_source_bytes~,
    max_faces~,
    max_tables_per_face~,
    max_table_records~,
    max_dsig_records~,
    max_dsig_bytes~,
    max_retained_bookkeeping_bytes~,
    max_work~,
  )
}

///|
test "TTC-01 tracer opens one static glyf collection atomically" {
  let owner = font_collection_test_owner(font_collection_test_ttc())
  let budget = font_collection_test_budget()
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_limits(),
    budget,
  ).unwrap()
  inspect(collection.face_count().unwrap(), content="1")
  inspect(
    collection.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  inspect(
    collection.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
  let remaining = budget.remaining()
  inspect(remaining.bytes(), content="0")
  inspect(remaining.allocations(), content="0")
  inspect(remaining.allocation_size(), content="48")
  inspect(remaining.work(), content="0")
}

///|
test "TTC-01 tracer rejects malformed envelopes without charging" {
  for
    source in [
      b"",
      b"\x74",
      b"\x74\x74",
      b"\x74\x74\x63",
      b"\x74\x74\x63\x66\x00\x01\x00\x00\x00\x00\x00",
      font_collection_test_zero_faces(),
    ] {
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_budget()
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_limits(),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 tracer enforces exact source authority before traversal" {
  let source = font_collection_test_ttc()
  let exact_owner = font_collection_test_owner(source)
  ignore(
    FontCollection::open(
      exact_owner.view(),
      font_collection_test_limits_with_source(88UL),
      font_collection_test_budget(),
    ).unwrap(),
  )
  let one_over_owner = font_collection_test_owner(source)
  let budget = font_collection_test_budget()
  let before = budget.remaining()
  let error = FontCollection::open(
    one_over_owner.view(),
    font_collection_test_limits_with_source(87UL),
    budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    error,
    @error.ErrorCategory::Resource,
    @error.ErrorCode::BudgetExceeded,
  )
  inspect(error.requested() == Some(88UL), content="true")
  inspect(error.limit() == Some(87UL), content="true")
  inspect(error.context() == Some("max-source-bytes"), content="true")
  font_collection_test_assert_budget_unchanged(before, budget)
}

///|
test "font collection limits preserve every explicit ceiling" {
  let limits = font_collection_test_limits_result(
    2UL, 3UL, 5UL, 7UL, 11UL, 13UL, 17UL, 19UL,
  ).unwrap()
  inspect(limits.max_source_bytes(), content="2")
  inspect(limits.max_faces(), content="3")
  inspect(limits.max_tables_per_face(), content="5")
  inspect(limits.max_table_records(), content="7")
  inspect(limits.max_dsig_records(), content="11")
  inspect(limits.max_dsig_bytes(), content="13")
  inspect(limits.max_retained_bookkeeping_bytes(), content="17")
  inspect(limits.max_work(), content="19")
}

///|
test "font collection limits reject every zero ceiling in argument order" {
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(0UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL),
    "max-source-bytes",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 0UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL),
    "max-faces",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 0UL, 1UL, 1UL, 1UL, 1UL, 1UL),
    "max-tables-per-face",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 0UL, 1UL, 1UL, 1UL, 1UL),
    "max-table-records",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 0UL, 1UL, 1UL, 1UL),
    "max-dsig-records",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 1UL, 0UL, 1UL, 1UL),
    "max-dsig-bytes",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 0UL, 1UL),
    "max-retained-bookkeeping-bytes",
  )
  font_collection_test_assert_invalid_limit(
    font_collection_test_limits_result(1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 1UL, 0UL),
    "max-work",
  )
}

///|
test "collection queries expose exact unchanged index errors" {
  let owner = font_collection_test_owner(font_collection_test_ttc())
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  let error = collection.face_profile(1UL).unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-collection-query"), content="true")
  inspect(error.requested() == Some(1UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some("font-collection-face-index"), content="true")
}

///|
test "required unrelated and restored mutations invalidate every collection query" {
  for offset in [80UL, 87UL] {
    let owner = font_collection_test_owner(font_collection_test_ttc())
    let collection = FontCollection::open(
      owner.view(),
      font_collection_test_limits(),
      font_collection_test_budget(),
    ).unwrap()
    font_collection_test_mutate(owner, offset, b'\x01')
    font_collection_test_assert_every_query_drift(collection)
  }
  let restored_owner = font_collection_test_owner(font_collection_test_ttc())
  let restored = FontCollection::open(
    restored_owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  font_collection_test_mutate(restored_owner, 80UL, b'\x01')
  font_collection_test_mutate(restored_owner, 80UL, b'\x00')
  font_collection_test_assert_every_query_drift(restored)
}

///|
test "revision drift precedes index validation and remains owner-local" {
  let drifted_owner = font_collection_test_owner(font_collection_test_ttc())
  let drifted = FontCollection::open(
    drifted_owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  let stable_owner = font_collection_test_owner(font_collection_test_ttc())
  let stable = FontCollection::open(
    stable_owner.view(),
    font_collection_test_limits(),
    font_collection_test_budget(),
  ).unwrap()
  font_collection_test_mutate(drifted_owner, 87UL, b'\x01')
  font_collection_test_assert_query_drift(
    drifted.face_profile(1UL).unwrap_err(),
  )
  inspect(stable.face_count().unwrap(), content="1")
  inspect(
    stable.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  inspect(
    stable.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
}

///|
test "TTC-01 all-face structure preserves v2 offset order and closed profiles" {
  let owner = font_collection_test_owner(font_collection_test_multi_ttc())
  let limits = FontCollectionLimits::new(
    max_source_bytes=400UL,
    max_faces=5UL,
    max_tables_per_face=3UL,
    max_table_records=8UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=440UL,
    max_work=252UL,
  ).unwrap()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=440UL,
      allocations=2UL,
      allocation_size=200UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=252UL,
    ),
  )
  let collection = FontCollection::open(owner.view(), limits, budget).unwrap()
  inspect(collection.face_count().unwrap(), content="5")
  for
    item in [
      (0UL, FontFaceProfile::StaticGlyf),
      (1UL, FontFaceProfile::Cff),
      (2UL, FontFaceProfile::Cff2),
      (3UL, FontFaceProfile::Variable),
      (4UL, FontFaceProfile::OtherUnsupported),
    ] {
    let (index, expected) = item
    inspect(collection.face_profile(index).unwrap() == expected, content="true")
  }
  inspect(
    collection.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
}

///|
test "TTC-01 table offsets remain collection-root relative" {
  let source = font_collection_test_wrong_rebase_ttc()
  let owner = font_collection_test_owner(source)
  let limits = FontCollectionLimits::new(
    max_source_bytes=128UL,
    max_faces=1UL,
    max_tables_per_face=1UL,
    max_table_records=1UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=184UL,
    max_work=36UL,
  ).unwrap()
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=184UL,
      allocations=2UL,
      allocation_size=48UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=36UL,
    ),
  )
  let collection = FontCollection::open(owner.view(), limits, budget).unwrap()
  inspect(
    collection.face_profile(0UL).unwrap() == FontFaceProfile::OtherUnsupported,
    content="true",
  )
}

///|
test "TTC-01 v2 offset array and final directory record truncate as Data" {
  let complete = font_collection_test_multi_ttc()
  for length in [15, 31, 43, 267] {
    let owner = font_collection_test_owner(
      font_collection_test_prefix(complete, length),
    )
    let budget = font_collection_test_budget()
    let before = budget.remaining()
    let limits = FontCollectionLimits::new(
      max_source_bytes=400UL,
      max_faces=5UL,
      max_tables_per_face=3UL,
      max_table_records=8UL,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=440UL,
      max_work=252UL,
    ).unwrap()
    let error = FontCollection::open(owner.view(), limits, budget).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 exact sharing and touching pass while every overlap conflict fails" {
  let name = 0x6E616D65UL
  for
    source in [
      font_collection_test_pair_ttc(name, 7UL, 96UL, 4UL, name, 7UL, 96UL, 4UL),
      font_collection_test_pair_ttc(name, 7UL, 96UL, 4UL, name, 9UL, 100UL, 4UL),
      font_collection_test_pair_ttc(name, 7UL, 96UL, 0UL, name, 9UL, 96UL, 0UL),
    ] {
    let owner = font_collection_test_owner(source)
    ignore(
      FontCollection::open(
        owner.view(),
        font_collection_test_pair_limits(248UL, 66UL),
        font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL),
      ).unwrap(),
    )
  }
  for
    source in [
      font_collection_test_pair_ttc(name, 7UL, 96UL, 8UL, name, 7UL, 100UL, 8UL),
      font_collection_test_pair_ttc(name, 7UL, 96UL, 4UL, name, 8UL, 96UL, 4UL),
      font_collection_test_pair_ttc(name, 7UL, 64UL, 4UL, name, 9UL, 100UL, 4UL),
    ] {
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(248UL, 66UL),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let same_face_owner = font_collection_test_owner(
    font_collection_test_same_face_overlap_ttc(),
  )
  let same_face_budget = font_collection_test_pair_budget(
    184UL, 2UL, 48UL, 47UL,
  )
  let before = same_face_budget.remaining()
  let limits = FontCollectionLimits::new(
    max_source_bytes=128UL,
    max_faces=1UL,
    max_tables_per_face=2UL,
    max_table_records=2UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=184UL,
    max_work=47UL,
  ).unwrap()
  let error = FontCollection::open(
    same_face_owner.view(),
    limits,
    same_face_budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    error,
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
  )
  font_collection_test_assert_budget_unchanged(before, same_face_budget)
  let duplicate_directory = font_collection_test_pair_ttc(
    name, 7UL, 96UL, 4UL, name, 9UL, 100UL, 4UL,
  ).to_array()
  font_collection_test_put_u32(duplicate_directory, 16, 32UL)
  let duplicate_owner = font_collection_test_owner(
    Bytes::from_array(duplicate_directory),
  )
  let duplicate_budget = font_collection_test_pair_budget(
    248UL, 2UL, 80UL, 66UL,
  )
  let duplicate_before = duplicate_budget.remaining()
  let duplicate_error = FontCollection::open(
    duplicate_owner.view(),
    font_collection_test_pair_limits(248UL, 66UL),
    duplicate_budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    duplicate_error,
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
  )
  font_collection_test_assert_budget_unchanged(
    duplicate_before, duplicate_budget,
  )
}

///|
test "TTC-01 empty table offsets remain four-byte aligned" {
  let source = font_collection_test_pair_ttc(
    0x6E616D65UL,
    7UL,
    97UL,
    0UL,
    0x706F7374UL,
    9UL,
    100UL,
    4UL,
  )
  let owner = font_collection_test_owner(source)
  let budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
  let before = budget.remaining()
  let error = FontCollection::open(
    owner.view(),
    font_collection_test_pair_limits(248UL, 66UL),
    budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    error,
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
  )
  inspect(
    error.context() == Some("font-collection-table-alignment"),
    content="true",
  )
  inspect(error.source_offset() == Some(52UL), content="true")
  font_collection_test_assert_budget_unchanged(before, budget)
}

///|
test "TTC-01 compact charge exact fit succeeds and every one-short is atomic" {
  let shared = font_collection_test_pair_ttc(
    0x6E616D65UL, 7UL, 96UL, 4UL, 0x6E616D65UL, 7UL, 96UL, 4UL,
  )
  let exact_owner = font_collection_test_owner(shared)
  let exact_budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
  ignore(
    FontCollection::open(
      exact_owner.view(),
      font_collection_test_pair_limits(248UL, 66UL),
      exact_budget,
    ).unwrap(),
  )
  inspect(exact_budget.remaining().bytes(), content="0")
  inspect(exact_budget.remaining().allocations(), content="0")
  inspect(exact_budget.remaining().allocation_size(), content="80")
  inspect(exact_budget.remaining().work(), content="0")
  for
    item in [
      (247UL, 2UL, 80UL, 66UL),
      (248UL, 1UL, 80UL, 66UL),
      (248UL, 2UL, 79UL, 66UL),
      (248UL, 2UL, 80UL, 65UL),
    ] {
    let (bytes, allocations, allocation_size, work) = item
    let owner = font_collection_test_owner(shared)
    let budget = font_collection_test_pair_budget(
      bytes, allocations, allocation_size, work,
    )
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(248UL, 66UL),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  for item in [(247UL, 66UL), (248UL, 65UL)] {
    let (retained, work) = item
    let owner = font_collection_test_owner(shared)
    let budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(retained, work),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Resource,
      @error.ErrorCode::BudgetExceeded,
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 declaration ceilings fail before dependent structural work" {
  let source = font_collection_test_multi_ttc()
  for
    item in [
      (4UL, 3UL, 8UL, "max-faces"),
      (5UL, 2UL, 8UL, "max-tables-per-face"),
      (5UL, 3UL, 7UL, "max-table-records"),
    ] {
    let (faces, per_face, records, context) = item
    let owner = font_collection_test_owner(source)
    let budget = @budget.Budget::new(
      @budget.ResourceLimits::new(
        bytes=440UL,
        allocations=2UL,
        allocation_size=200UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=252UL,
      ),
    )
    let before = budget.remaining()
    let limits = FontCollectionLimits::new(
      max_source_bytes=400UL,
      max_faces=faces,
      max_tables_per_face=per_face,
      max_table_records=records,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=440UL,
      max_work=252UL,
    ).unwrap()
    let error = FontCollection::open(owner.view(), limits, budget).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Resource,
      @error.ErrorCode::BudgetExceeded,
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
fn font_collection_test_dsig_ttc() -> Bytes {
  let output = Array::make(100, b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00020000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_put_u32(output, 16, 0x44534947UL)
  font_collection_test_put_u32(output, 20, 32UL)
  font_collection_test_put_u32(output, 24, 68UL)
  font_collection_test_write_directory(
    output,
    32,
    0x00010000UL,
    [0x6E616D65UL],
    [64UL],
  )
  // DSIG v1 header and one format-1 signature record.
  font_collection_test_put_u32(output, 68, 1UL)
  font_collection_test_put_u16(output, 72, 1UL)
  font_collection_test_put_u16(output, 74, 1UL)
  font_collection_test_put_u32(output, 76, 1UL)
  font_collection_test_put_u32(output, 80, 12UL)
  font_collection_test_put_u32(output, 84, 20UL)
  // Signature block: two reserved UInt16 values, length, opaque payload.
  font_collection_test_put_u32(output, 92, 4UL)
  output[96] = b'\xde'
  output[97] = b'\xad'
  output[98] = b'\xbe'
  output[99] = b'\xef'
  Bytes::from_array(output)
}

///|
fn font_collection_test_two_dsig_ttc(
  first_relative_start : UInt64,
  second_relative_start : UInt64,
  outer_length : UInt64,
) -> Bytes {
  let output = Array::make((68UL + outer_length).to_int(), b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00020000UL)
  font_collection_test_put_u32(output, 8, 1UL)
  font_collection_test_put_u32(output, 12, 32UL)
  font_collection_test_put_u32(output, 16, 0x44534947UL)
  font_collection_test_put_u32(output, 20, outer_length)
  font_collection_test_put_u32(output, 24, 68UL)
  font_collection_test_write_directory(
    output,
    32,
    0x00010000UL,
    [0x6E616D65UL],
    [64UL],
  )
  font_collection_test_put_u32(output, 68, 1UL)
  font_collection_test_put_u16(output, 72, 2UL)
  font_collection_test_put_u16(output, 74, 1UL)
  for item in [(76, first_relative_start), (88, second_relative_start)] {
    let (record, relative_start) = item
    font_collection_test_put_u32(output, record, 1UL)
    font_collection_test_put_u32(output, record + 4, 12UL)
    font_collection_test_put_u32(output, record + 8, relative_start)
  }
  // Invalid containment fixtures intentionally point into the record array;
  // do not overwrite the declarations that must diagnose that condition.
  for relative_start in [first_relative_start, second_relative_start] {
    if relative_start >= 32UL && relative_start + 12UL <= outer_length {
      font_collection_test_put_u32(
        output,
        (68UL + relative_start + 4UL).to_int(),
        4UL,
      )
    }
  }
  Bytes::from_array(output)
}

///|
fn font_collection_test_dsig_limits(
  max_records : UInt64,
  max_bytes : UInt64,
  max_work : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=100UL,
    max_faces=1UL,
    max_tables_per_face=1UL,
    max_table_records=1UL,
    max_dsig_records=max_records,
    max_dsig_bytes=max_bytes,
    max_retained_bookkeeping_bytes=208UL,
    max_work~,
  ).unwrap()
}

///|
fn font_collection_test_two_dsig_limits(
  max_records : UInt64,
  max_bytes : UInt64,
  max_work : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=128UL,
    max_faces=1UL,
    max_tables_per_face=1UL,
    max_table_records=1UL,
    max_dsig_records=max_records,
    max_dsig_bytes=max_bytes,
    max_retained_bookkeeping_bytes=208UL,
    max_work~,
  ).unwrap()
}

///|
fn font_collection_test_dsig_budget(work : UInt64) -> @budget.Budget {
  font_collection_test_pair_budget(208UL, 2UL, 72UL, work)
}

///|
test "TTC-01 DSIG tuple and supported envelope remain explicitly unverified" {
  let source = font_collection_test_dsig_ttc()
  let owner = font_collection_test_owner(source)
  let budget = font_collection_test_dsig_budget(57UL)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_dsig_limits(1UL, 32UL, 57UL),
    budget,
  ).unwrap()
  inspect(
    collection.dsig_status().unwrap() ==
    FontCollectionDsigStatus::PresentUnverified,
    content="true",
  )
  inspect(budget.remaining().work(), content="0")

  for
    item in [
      (16, 0UL, "font-collection-dsig-tuple"),
      (20, 0UL, "font-collection-dsig-tuple"),
      (24, 0UL, "font-collection-dsig-tuple"),
    ] {
    let (field, value, context) = item
    let malformed = source.to_array()
    font_collection_test_put_u32(malformed, field, value)
    let malformed_owner = font_collection_test_owner(
      Bytes::from_array(malformed),
    )
    let malformed_budget = font_collection_test_dsig_budget(57UL)
    let before = malformed_budget.remaining()
    let error = FontCollection::open(
      malformed_owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 57UL),
      malformed_budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, malformed_budget)
  }
}

///|
test "TTC-01 DSIG body rejects malformed and complete unsupported facts" {
  let source = font_collection_test_dsig_ttc()
  for
    item in [
      (
        68,
        2UL,
        @error.ErrorCategory::Capability,
        "font-collection-dsig-version",
      ),
      (76, 2UL, @error.ErrorCategory::Capability, "font-collection-dsig-format"),
      (72, 0UL, @error.ErrorCategory::Data, "font-collection-dsig-count"),
      (74, 2UL, @error.ErrorCategory::Data, "font-collection-dsig-flags"),
      (
        80,
        11UL,
        @error.ErrorCategory::Data,
        "font-collection-dsig-block-length",
      ),
      (84, 8UL, @error.ErrorCategory::Data, "font-collection-dsig-block-range"),
      (88, 1UL, @error.ErrorCategory::Data, "font-collection-dsig-reserved"),
      (
        92,
        0UL,
        @error.ErrorCategory::Data,
        "font-collection-dsig-payload-length",
      ),
    ] {
    let (field, value, category, context) = item
    let malformed = source.to_array()
    if field == 72 || field == 74 {
      font_collection_test_put_u16(malformed, field, value)
    } else {
      font_collection_test_put_u32(malformed, field, value)
    }
    let owner = font_collection_test_owner(Bytes::from_array(malformed))
    let budget = font_collection_test_dsig_budget(57UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 57UL),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      category,
      if category == @error.ErrorCategory::Capability {
        @error.ErrorCode::CapabilityUnavailable
      } else {
        @error.ErrorCode::InvalidEncoding
      },
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 DSIG record and work ceilings are exact and atomic" {
  let source = font_collection_test_dsig_ttc()
  for
    item in [
      (0UL, 32UL, 57UL, "max-dsig-records"),
      (1UL, 31UL, 57UL, "max-dsig-bytes"),
      (1UL, 32UL, 56UL, "max-work"),
    ] {
    let (records, bytes, work, context) = item
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_dsig_budget(57UL)
    let before = budget.remaining()
    let limits = if records == 0UL {
      // Public constructors reject zero, so prove the one-over declaration by
      // declaring two records under an exact one-record ceiling.
      font_collection_test_dsig_limits(1UL, bytes, work)
    } else {
      font_collection_test_dsig_limits(records, bytes, work)
    }
    let candidate = if records == 0UL {
      let bytes = source.to_array()
      font_collection_test_put_u16(bytes, 72, 2UL)
      Bytes::from_array(bytes)
    } else {
      source
    }
    let candidate_owner = font_collection_test_owner(candidate)
    let error = FontCollection::open(candidate_owner.view(), limits, budget).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Resource,
      @error.ErrorCode::BudgetExceeded,
    )
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
    ignore(owner)
  }
}

///|
test "TTC-01 D-18 structural facts precede full-work and caller-budget errors" {
  let malformed_face = font_collection_test_dsig_ttc().to_array()
  font_collection_test_put_u16(malformed_face, 38, 0UL)
  for item in [(56UL, 57UL), (57UL, 56UL)] {
    let (max_work, budget_work) = item
    let owner = font_collection_test_owner(Bytes::from_array(malformed_face))
    let budget = font_collection_test_dsig_budget(budget_work)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, max_work),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    inspect(
      error.context() == Some("font-collection-search-facts"),
      content="true",
    )
    inspect(error.source_offset() == None, content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }

  let malformed_alias = font_collection_test_pair_ttc(
    0x6E616D65UL,
    7UL,
    96UL,
    8UL,
    0x6E616D65UL,
    7UL,
    100UL,
    8UL,
  )
  for item in [(65UL, 66UL), (66UL, 65UL)] {
    let (max_work, budget_work) = item
    let owner = font_collection_test_owner(malformed_alias)
    let budget = font_collection_test_pair_budget(
      248UL, 2UL, 80UL, budget_work,
    )
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(248UL, max_work),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    inspect(
      error.context() == Some("font-collection-cross-face-overlap"),
      content="true",
    )
    inspect(error.source_offset() == Some(100UL), content="true")
    inspect(error.requested() == Some(8UL), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }

  let malformed_dsig = font_collection_test_dsig_ttc().to_array()
  font_collection_test_put_u32(malformed_dsig, 88, 1UL)
  for item in [(56UL, 57UL), (57UL, 56UL)] {
    let (max_work, budget_work) = item
    let owner = font_collection_test_owner(Bytes::from_array(malformed_dsig))
    let budget = font_collection_test_dsig_budget(budget_work)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, max_work),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    inspect(
      error.context() == Some("font-collection-dsig-reserved"),
      content="true",
    )
    inspect(error.source_offset() == Some(88UL), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 staged work authority has exact stable precedence boundaries" {
  let source = font_collection_test_dsig_ttc()
  for
    item in [
      (10UL, 57UL, 11UL, 10UL, "max-work"),
      (57UL, 10UL, 11UL, 10UL, "work"),
      (42UL, 57UL, 43UL, 42UL, "max-work"),
      (57UL, 42UL, 43UL, 42UL, "work"),
      (56UL, 57UL, 57UL, 56UL, "max-work"),
      (57UL, 56UL, 57UL, 56UL, "work"),
    ] {
    let (max_work, budget_work, requested, limit, context) = item
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_dsig_budget(budget_work)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, max_work),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some(context), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == Some(limit), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 DSIG authority precedes faces but DSIG semantics follow them" {
  let source = font_collection_test_dsig_ttc()
  let malformed_tuple = source.to_array()
  font_collection_test_put_u16(malformed_tuple, 38, 0UL)
  font_collection_test_put_u32(malformed_tuple, 16, 0UL)
  let tuple_owner = font_collection_test_owner(Bytes::from_array(malformed_tuple))
  let tuple_budget = font_collection_test_dsig_budget(57UL)
  let tuple_before = tuple_budget.remaining()
  let tuple_error = FontCollection::open(
    tuple_owner.view(),
    font_collection_test_dsig_limits(1UL, 32UL, 57UL),
    tuple_budget,
  ).unwrap_err()
  font_collection_test_assert_error(
    tuple_error,
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
  )
  inspect(
    tuple_error.context() == Some("font-collection-dsig-tuple"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(tuple_before, tuple_budget)

  let mut semantics_follow_faces = true
  for
    item in [
      (68, 2UL, false),
      (72, 0UL, true),
      (74, 2UL, true),
    ] {
    let (field, value, is_u16) = item
    let malformed = source.to_array()
    font_collection_test_put_u16(malformed, 38, 0UL)
    if is_u16 {
      font_collection_test_put_u16(malformed, field, value)
    } else {
      font_collection_test_put_u32(malformed, field, value)
    }
    let owner = font_collection_test_owner(Bytes::from_array(malformed))
    let budget = font_collection_test_dsig_budget(57UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 57UL),
      budget,
    ).unwrap_err()
    semantics_follow_faces = semantics_follow_faces &&
      error.category() == @error.ErrorCategory::Data &&
      error.code() == @error.ErrorCode::InvalidEncoding &&
      error.context() == Some("font-collection-search-facts")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  inspect(semantics_follow_faces, content="true")
}

///|
test "TTC-01 two-record DSIG accepts touching and unordered disjoint blocks" {
  for
    source in [
      font_collection_test_two_dsig_ttc(32UL, 44UL, 56UL),
      font_collection_test_two_dsig_ttc(44UL, 32UL, 56UL),
    ] {
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_dsig_budget(64UL)
    let collection = FontCollection::open(
      owner.view(),
      font_collection_test_two_dsig_limits(2UL, 56UL, 64UL),
      budget,
    ).unwrap()
    inspect(
      collection.dsig_status().unwrap() ==
      FontCollectionDsigStatus::PresentUnverified,
      content="true",
    )
    inspect(budget.remaining().work(), content="0")
  }
}

///|
test "TTC-01 two-record DSIG rejects overlap containment and trailing gaps" {
  for
    item in [
      (
        font_collection_test_two_dsig_ttc(32UL, 40UL, 52UL),
        "font-collection-dsig-block-overlap",
        108UL,
        12UL,
        None,
      ),
      (
        font_collection_test_two_dsig_ttc(32UL, 32UL, 44UL),
        "font-collection-dsig-block-overlap",
        100UL,
        12UL,
        None,
      ),
      (
        font_collection_test_two_dsig_ttc(28UL, 44UL, 56UL),
        "font-collection-dsig-block-range",
        96UL,
        12UL,
        Some(100UL),
      ),
      (
        font_collection_test_two_dsig_ttc(32UL, 44UL, 60UL),
        "font-collection-dsig-outer-length",
        124UL,
        4UL,
        Some(128UL),
      ),
    ] {
    let (source, context, source_offset, requested, limit) = item
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_dsig_budget(64UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_two_dsig_limits(2UL, 60UL, 64UL),
      budget,
    ).unwrap_err()
    font_collection_test_assert_error(
      error,
      @error.ErrorCategory::Data,
      @error.ErrorCode::InvalidEncoding,
    )
    inspect(error.context() == Some(context), content="true")
    inspect(error.source_offset() == Some(source_offset), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == limit, content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}

///|
test "TTC-01 two-record DSIG record and work boundaries are exact" {
  let source = font_collection_test_two_dsig_ttc(32UL, 44UL, 56UL)
  for
    item in [
      (1UL, 56UL, 64UL, 64UL, "max-dsig-records", true),
      (2UL, 56UL, 63UL, 64UL, "max-work", true),
      (2UL, 56UL, 64UL, 63UL, "", false),
    ] {
    let (records, bytes, max_work, budget_work, context, collection_limit) = item
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_dsig_budget(budget_work)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_two_dsig_limits(records, bytes, max_work),
      budget,
    ).unwrap_err()
    if collection_limit {
      font_collection_test_assert_error(
        error,
        @error.ErrorCategory::Resource,
        @error.ErrorCode::BudgetExceeded,
      )
      inspect(error.context() == Some(context), content="true")
    } else {
      inspect(error.category() == @error.ErrorCategory::Resource, content="true")
      inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    }
    font_collection_test_assert_budget_unchanged(before, budget)
  }
}
