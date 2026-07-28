///|
fn type2_geometry_wb_program(arguments : Array[Int], operator : Byte) -> Bytes {
  let source : Array[Byte] = [b'\x8B', b'\x8B', b'\x15']
  for argument in arguments {
    source.push((argument + 139).to_byte())
  }
  source.push(operator)
  source.push(b'\x0E')
  Bytes::from_array(source)
}

///|
test "Type 2 ordinary path operators preserve relative current point and charges" {
  let cases : Array[(Array[Int], Byte, Int64, Int64, UInt64, UInt64)] = [
    ([10, 20, -5, 5], b'\x05', 5L, 25L, 3UL, 4UL), // rlineto
    ([10, 20, -5], b'\x06', 5L, 20L, 4UL, 5UL), // hlineto
    ([10, 20, -5], b'\x07', 20L, 5L, 4UL, 5UL), // vlineto
    ([1, 2, 3, 4, 5, 6], b'\x08', 9L, 12L, 4UL, 3UL), // rrcurveto
    (
      [1, 2, 3, 4, 5, 6, 7, 8],
      b'\x18',
      16L,
      20L,
      5UL,
      4UL,
    ), // rcurlineto
    (
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      b'\x19',
      25L,
      30L,
      6UL,
      5UL,
    ), // rlinecurve
    ([1, 2, 3, 4, 5], b'\x1A', 4L, 11L, 4UL, 3UL), // vvcurveto
    ([2, 3, 4, 5, 6], b'\x1B', 13L, 7L, 4UL, 3UL), // hhcurveto
    ([2, 3, 4, 5, 6], b'\x1E', 8L, 12L, 4UL, 3UL), // vhcurveto
    ([2, 3, 4, 5, 6], b'\x1F', 11L, 9L, 4UL, 3UL), // hvcurveto
  ]
  for item in cases {
    let result = type2_vm_wb_run(
      type2_geometry_wb_program(item.0, item.1),
    ).unwrap()
    inspect(result.geometry.current_x.raw, content=(item.2 * 65536L).to_string())
    inspect(result.geometry.current_y.raw, content=(item.3 * 65536L).to_string())
    inspect(result.geometry.points, content=item.4.to_string())
    inspect(result.geometry.commands, content=item.5.to_string())
    inspect(result.geometry.contours, content="1")
  }
}

///|
test "Type 2 geometry rejects missing contours residual arguments and overflow" {
  for source in [
    b"\x8C\x8C\x05\x0E", // line before moveto
    type2_geometry_wb_program([1], b'\x05'), // odd rlineto residual
    type2_geometry_wb_program([1, 2, 3, 4, 5, 6, 7], b'\x08'),
    type2_geometry_wb_program([1, 2, 3, 4, 5, 6], b'\x1A'),
    type2_geometry_wb_program([1, 2, 3, 4, 5, 6], b'\x1F'),
    b"\xFF\x7F\xFF\xFF\xFF\x8B\x15\x8C\x8B\x05\x0E",
  ] {
    type2_vm_wb_assert_data(type2_vm_wb_run(source))
  }
}

///|
test "Type 2 moveto and endchar close contours with exact geometry limits" {
  let program = type2_geometry_wb_program([10, 20], b'\x05')
  let exact = type2_vm_wb_run_with(
    program,
    0L,
    0L,
    0L,
    type2_vm_wb_geometry_limits(2UL, 1UL, 65535UL, 65535UL),
  ).unwrap()
  inspect(exact.geometry.points, content="2")
  inspect(exact.geometry.contours, content="1")
  inspect(exact.geometry.commands, content="3")

  let one_short = type2_vm_wb_run_with(
    program,
    0L,
    0L,
    0L,
    type2_vm_wb_geometry_limits(1UL, 1UL, 65535UL, 65535UL),
  ).unwrap_err()
  inspect(one_short.category() == @error.ErrorCategory::Resource, content="true")
  inspect(one_short.context() == Some("font-cff-type2-points"), content="true")

  let two_contours = b"\x8B\x8B\x15\x8C\x8C\x05\x8B\x8B\x15\x8C\x8C\x05\x0E"
  let contour_error = type2_vm_wb_run_with(
    two_contours,
    0L,
    0L,
    0L,
    type2_vm_wb_geometry_limits(8UL, 1UL, 65535UL, 65535UL),
  ).unwrap_err()
  inspect(
    contour_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    contour_error.context() == Some("font-cff-type2-contours"),
    content="true",
  )
}
