///|
fn font_wb_view(source : Bytes) -> @bytes.ByteView {
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
  ).unwrap().view()
}

///|
test "checked big endian reads accept exact fit and reject one short" {
  inspect(read_u8(font_wb_view(b"\x12"), 0UL).unwrap(), content="b'\\x12'")
  inspect(read_u8(font_wb_view(b""), 0UL) is Err(_), content="true")
  inspect(read_u16(font_wb_view(b"\x12\x34"), 0UL).unwrap(), content="4660")
  inspect(read_u16(font_wb_view(b"\x12"), 0UL) is Err(_), content="true")
  inspect(read_i16(font_wb_view(b"\xff\xfe"), 0UL).unwrap(), content="-2")
  inspect(read_i16(font_wb_view(b"\xff"), 0UL) is Err(_), content="true")
  inspect(
    read_u32(font_wb_view(b"\x12\x34\x56\x78"), 0UL).unwrap(),
    content="305419896",
  )
  inspect(
    read_u32(font_wb_view(b"\x12\x34\x56"), 0UL) is Err(_),
    content="true",
  )
}
