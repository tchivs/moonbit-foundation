///|
fn font_collection_wb_put_u16(
  output : Array[Byte],
  offset : Int,
  value : UInt64,
) -> Unit {
  output[offset] = (value >> 8).to_byte()
  output[offset + 1] = value.to_byte()
}

///|
fn font_collection_wb_put_u32(
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
fn font_collection_wb_view(source : Bytes) -> @bytes.ByteView {
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
  )
  .unwrap()
  .view()
}

///|
fn font_collection_wb_two_face_v2() -> Bytes {
  let output = Array::make(160, b'\x00')
  font_collection_wb_put_u32(output, 0, 0x74746366UL)
  font_collection_wb_put_u32(output, 4, 0x00020000UL)
  font_collection_wb_put_u32(output, 8, 2UL)
  font_collection_wb_put_u32(output, 12, 48UL)
  font_collection_wb_put_u32(output, 16, 80UL)
  // v2 DSIG tuple at [20, 32) remains all-zero.
  font_collection_wb_put_u32(output, 48, 0x4F54544FUL)
  font_collection_wb_put_u16(output, 52, 1UL)
  font_collection_wb_put_u16(output, 54, 16UL)
  font_collection_wb_put_u32(output, 60, 0x43464620UL)
  font_collection_wb_put_u32(output, 64, 7UL)
  font_collection_wb_put_u32(output, 68, 132UL)
  font_collection_wb_put_u32(output, 72, 4UL)
  font_collection_wb_put_u32(output, 80, 0x00010000UL)
  font_collection_wb_put_u16(output, 84, 2UL)
  font_collection_wb_put_u16(output, 86, 32UL)
  font_collection_wb_put_u16(output, 88, 1UL)
  font_collection_wb_put_u32(output, 92, 0x676C7966UL)
  font_collection_wb_put_u32(output, 96, 11UL)
  font_collection_wb_put_u32(output, 100, 136UL)
  font_collection_wb_put_u32(output, 104, 4UL)
  font_collection_wb_put_u32(output, 108, 0x6C6F6361UL)
  font_collection_wb_put_u32(output, 112, 13UL)
  font_collection_wb_put_u32(output, 116, 140UL)
  font_collection_wb_put_u32(output, 120, 4UL)
  Bytes::from_array(output)
}

///|
fn font_collection_wb_limits() -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=160UL,
    max_faces=2UL,
    max_tables_per_face=2UL,
    max_table_records=3UL,
    max_dsig_records=1UL,
    max_dsig_bytes=1UL,
    max_retained_bookkeeping_bytes=248UL,
    max_work=64UL,
  ).unwrap()
}

///|
test "collection structural pass keeps root ranges and face order" {
  let budget = @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=248UL,
      allocations=2UL,
      allocation_size=80UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=64UL,
    ),
  )
  let facts = font_collection_parse(
    font_collection_wb_view(font_collection_wb_two_face_v2()),
    font_collection_wb_limits(),
    budget,
  ).unwrap()
  inspect(facts.faces.length(), content="2")
  inspect(facts.faces[0].directory_start, content="48")
  inspect(facts.faces[0].profile == FontFaceProfile::Cff, content="true")
  inspect(facts.faces[1].directory_start, content="80")
  inspect(facts.faces[1].profile == FontFaceProfile::StaticGlyf, content="true")
  inspect(facts.protected_ranges.length(), content="3")
  inspect(facts.protected_ranges[0].end, content="32")
  inspect(facts.protected_ranges[1].start, content="48")
  inspect(facts.protected_ranges[2].start, content="80")
}

///|
test "collection accounting formula includes every protected and alias pair" {
  inspect(font_collection_choose_two(0UL, 48UL).unwrap(), content="0")
  inspect(font_collection_choose_two(3UL, 48UL).unwrap(), content="3")
  inspect(
    font_collection_exact_work(2UL, 2UL, 3UL, 0UL, 0UL, 0UL, 48UL).unwrap(),
    content="48",
  )
  let overflow = font_collection_choose_two(18446744073709551615UL, 48UL).unwrap_err()
  inspect(overflow.category() == @error.ErrorCategory::Resource, content="true")
  inspect(overflow.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(overflow.context() == Some("max-work"), content="true")
}

///|
test "collection DSIG work includes header records and block pairs exactly" {
  inspect(
    font_collection_exact_work(1UL, 1UL, 3UL, 1UL, 1UL, 1UL, 48UL).unwrap(),
    content="48",
  )
  let error = font_collection_exact_work(1UL, 1UL, 3UL, 1UL, 1UL, 1UL, 47UL).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.context() == Some("max-work"), content="true")
}
