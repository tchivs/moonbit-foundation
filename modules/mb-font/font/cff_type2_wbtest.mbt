///|
fn type2_vm_wb_limits(
  bytes : UInt64,
  work : UInt64,
) -> Type2Limits {
  type2_limits(
    FontLimits::new(
      max_source_bytes=4096UL,
      max_tables=1UL,
      max_table_bytes=4096UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_kern_subtables=1UL,
      max_kern_pairs=1UL,
      max_outline_points=128UL,
      max_outline_contours=32UL,
      max_outline_components=1UL,
      max_outline_instruction_bytes=bytes,
      max_post_name_bytes=1UL,
      max_work=work,
    ).unwrap(),
  ).unwrap()
}

///|
fn type2_vm_wb_empty_index(view : @bytes.ByteView) -> CffIndex {
  cff_empty_index(view).unwrap()
}

///|
fn type2_vm_wb_run_with(
  source : Bytes,
  default_width : Int64,
  nominal_width : Int64,
  seed : Int64,
  limits : Type2Limits,
) -> Result[Type2VmResult, @error.CoreError] {
  let view = font_wb_view(source)
  type2_execute_program(
    view,
    type2_vm_wb_empty_index(view),
    type2_vm_wb_empty_index(view),
    type2_fixed_from_raw(default_width).unwrap(),
    type2_fixed_from_raw(nominal_width).unwrap(),
    type2_fixed_from_raw(seed).unwrap(),
    limits,
    view.mutation_revision(),
  )
}

///|
fn type2_vm_wb_run(source : Bytes) -> Result[Type2VmResult, @error.CoreError] {
  type2_vm_wb_run_with(
    source,
    0L,
    0L,
    0L,
    type2_vm_wb_limits(65535UL, 65535UL),
  )
}

///|
fn type2_vm_wb_assert_data(
  result : Result[Type2VmResult, @error.CoreError],
) -> Unit raise {
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Data, content="true")
  inspect(error.operation() == Some("font-cff-type2"), content="true")
}

///|
test "Type 2 scalar operators execute exact stack semantics" {
  let cases : Array[(Bytes, Int64)] = [
    (b"\x8a\x0c\x09\x0e", 65536L), // abs(-1)
    (b"\x8c\x8d\x0c\x0a\x0e", 196608L), // 1 + 2
    (b"\x8e\x8c\x0c\x0b\x0e", 131072L), // 3 - 1
    (b"\x8f\x8d\x0c\x0c\x0e", 131072L), // 4 / 2
    (b"\x8c\x0c\x0e\x0e", -65536L), // neg(1)
    (b"\x8d\x8d\x0c\x0f\x0e", 65536L), // 2 == 2
    (b"\x8c\x8d\x0c\x03\x0e", 65536L), // true and true
    (b"\x8b\x8c\x0c\x04\x0e", 65536L), // false or true
    (b"\x8b\x0c\x05\x0e", 65536L), // not(false)
    (b"\x95\x9f\x8c\x8d\x0c\x16\x0e", 655360L), // if 1 <= 2 then 10
    (b"\x8e\x8e\x0c\x18\x0e", 589824L), // 3 * 3
    (b"\x98\x0c\x1a\x0e", 196608L), // sqrt(9)
    (b"\x8d\x0c\x1b\x0c\x0a\x0e", 262144L), // dup(2), add
    (b"\x8c\x8d\x0c\x1c\x0c\x0b\x0e", 65536L), // exch, sub
    (b"\x8c\x8d\x8b\x0c\x1d\x0c\x0a\x0c\x0a\x0e", 327680L), // index
    (
      b"\x8c\x8d\x8e\x8e\x8c\x0c\x1e\x0c\x0b\x0c\x0a\x0e",
      131072L,
    ), // roll
    (b"\x92\x8b\x0c\x14\x8b\x0c\x15\x0e", 458752L), // put/get
  ]
  for item in cases {
    let result = type2_vm_wb_run(item.0).unwrap()
    inspect(result.width.unwrap().raw, content=item.1.to_string())
    inspect(result.terminated, content="true")
  }

  let random = type2_vm_wb_run_with(
    b"\x0c\x17\x0e",
    0L,
    0L,
    0x12345678L,
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(random.width.unwrap().raw, content="23206")

  let dropped = type2_vm_wb_run(b"\x8c\x0c\x12\x0e").unwrap()
  inspect(dropped.width is None, content="true")
}

///|
test "Type 2 operators reject arity type and numeric faults" {
  for source in [
    b"\x0c\x09\x0e",
    b"\x8c\x0c\x0a\x0e",
    b"\x8c\x0c\x0b\x0e",
    b"\x8c\x0c\x0c\x0e",
    b"\x0c\x0e\x0e",
    b"\x8c\x0c\x0f\x0e",
    b"\x8c\x0c\x03\x0e",
    b"\x8c\x0c\x04\x0e",
    b"\x0c\x05\x0e",
    b"\x8c\x8d\x8e\x0c\x16\x0e",
    b"\x8c\x0c\x18\x0e",
    b"\x0c\x1a\x0e",
    b"\x0c\x1b\x0e",
    b"\x8c\x0c\x1c\x0e",
    b"\x8c\x0c\x1d\x0e",
    b"\x8c\x8d\x0c\x1e\x0e",
    b"\x8c\x0c\x14\x0e",
    b"\x8b\x0c\x15\x0e",
    b"\x8c\x8b\x0c\x0c\x0e",
    b"\x8a\x0c\x1a\x0e",
  ] {
    type2_vm_wb_assert_data(type2_vm_wb_run(source))
  }
  // put/get indices must be exact integers in [0, 32), and get-before-put is Data.
  for source in [
    b"\x8c\xff\x00\x00\x80\x00\x0c\x14\x0e",
    b"\x8c\xab\x0c\x14\x0e",
    b"\x8b\x0c\x15\x0e",
  ] {
    type2_vm_wb_assert_data(type2_vm_wb_run(source))
  }
}

///|
test "Type 2 stack accepts 48 values and rejects the 49th before mutation" {
  let exact : Array[Byte] = []
  for index = 0; index < 48; index = index + 1 {
    exact.push(b'\x8B')
  }
  for index = 0; index < 48; index = index + 1 {
    exact.push(b'\x0C')
    exact.push(b'\x12')
  }
  exact.push(b'\x0E')
  inspect(
    type2_vm_wb_run(Bytes::from_array(exact)) is Ok(_),
    content="true",
  )

  let overflow : Array[Byte] = []
  for index = 0; index < 49; index = index + 1 {
    overflow.push(b'\x8B')
  }
  overflow.push(b'\x0E')
  let error = type2_vm_wb_run(Bytes::from_array(overflow)).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(
    error.context() == Some("font-cff-type2-operand-stack"),
    content="true",
  )
}

///|
test "Type 2 width is accepted only in the first legal width position" {
  let defaults = type2_vm_wb_run_with(
    b"\x0e",
    32768000L,
    6553600L,
    0L,
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(defaults.width.unwrap().raw, content="32768000")

  let explicit = type2_vm_wb_run_with(
    b"\x95\x0e",
    32768000L,
    6553600L,
    0L,
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(explicit.width.unwrap().raw, content="7208960")

  let stem_width = type2_vm_wb_run_with(
    b"\x8c\x8d\x8e\x01\x0e",
    32768000L,
    6553600L,
    0L,
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(stem_width.width.unwrap().raw, content="6619136")
  inspect(stem_width.stems, content="1")

  let move_width = type2_vm_wb_run_with(
    b"\x8c\x8d\x8e\x15\x0e",
    32768000L,
    6553600L,
    0L,
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(move_width.width.unwrap().raw, content="6619136")

  type2_vm_wb_assert_data(
    type2_vm_wb_run_with(
      b"\x8d\x8e\x01\x8c\x0e",
      32768000L,
      6553600L,
      0L,
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
}

///|
test "Type 2 random and transient state are unchanged by failed preflight" {
  let one_short = type2_vm_wb_run_with(
    b"\x0c\x17\x0e",
    0L,
    0L,
    0x12345678L,
    type2_vm_wb_limits(65535UL, 1UL),
  ).unwrap_err()
  inspect(
    one_short.category() == @error.ErrorCategory::Resource,
    content="true",
  )

  type2_vm_wb_assert_data(type2_vm_wb_run(b"\x92\x8b\x0c\x14\xab\x0c\x15\x0e"))
}
