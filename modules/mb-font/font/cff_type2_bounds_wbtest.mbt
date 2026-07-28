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
    ([1, 2, 3, 4, 5, 6, 7, 8], b'\x18', 16L, 20L, 5UL, 4UL), // rcurlineto
    ([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], b'\x19', 25L, 30L, 6UL, 5UL), // rlinecurve
    ([1, 2, 3, 4, 5], b'\x1A', 4L, 11L, 4UL, 3UL), // vvcurveto
    ([2, 3, 4, 5, 6], b'\x1B', 13L, 7L, 4UL, 3UL), // hhcurveto
    ([2, 3, 4, 5, 6], b'\x1E', 8L, 12L, 4UL, 3UL), // vhcurveto
    ([2, 3, 4, 5, 6], b'\x1F', 11L, 9L, 4UL, 3UL), // hvcurveto
    ([1, 2, 3, 4, 5, 6, 7, 8], b'\x1E', 17L, 19L, 7UL, 4UL),
    ([1, 2, 3, 4, 5, 6, 7, 8], b'\x1F', 17L, 19L, 7UL, 4UL),
  ]
  for item in cases {
    let result = type2_vm_wb_run(type2_geometry_wb_program(item.0, item.1)).unwrap()
    inspect(
      result.geometry.current_x.raw,
      content=(item.2 * 65536L).to_string(),
    )
    inspect(
      result.geometry.current_y.raw,
      content=(item.3 * 65536L).to_string(),
    )
    inspect(result.geometry.points, content=item.4.to_string())
    inspect(result.geometry.commands, content=item.5.to_string())
    inspect(result.geometry.contours, content="1")
  }
}

///|
test "Type 2 moveto forms and cubic control hull are exact" {
  let moves : Array[(Bytes, Int64, Int64)] = [
    (b"\x95\x9F\x15\x0E", 10L, 20L), // rmoveto
    (b"\x95\x16\x0E", 10L, 0L), // hmoveto
    (b"\x95\x04\x0E", 0L, 10L), // vmoveto
  ]
  for item in moves {
    let result = type2_vm_wb_run(item.0).unwrap()
    inspect(
      result.geometry.current_x.raw,
      content=(item.1 * 65536L).to_string(),
    )
    inspect(
      result.geometry.current_y.raw,
      content=(item.2 * 65536L).to_string(),
    )
    inspect(result.geometry.points, content="1")
    inspect(result.geometry.contours, content="1")
    inspect(result.geometry.commands, content="2")
    inspect(result.geometry.has_segments, content="false")
  }

  // Move (10, 10), then cubic controls (15, 30), (25, 0), end (30, 15).
  let cubic = type2_vm_wb_run(b"\x95\x95\x15\x90\x9F\x95\x6D\x90\x9A\x08\x0E").unwrap()
  inspect(cubic.geometry.min_x.raw, content=(10L * 65536L).to_string())
  inspect(cubic.geometry.min_y.raw, content="0")
  inspect(cubic.geometry.max_x.raw, content=(30L * 65536L).to_string())
  inspect(cubic.geometry.max_y.raw, content=(30L * 65536L).to_string())
}

///|
test "Type 2 every ordinary path operator rejects invalid residual arity" {
  for
    source in [
      b"\x8C\x8C\x05\x0E", // line before moveto
      b"\x8B\x8B\x15\x8B\x8B\x8B\x15\x0E", // rmoveto
      b"\x8B\x8B\x15\x8B\x8B\x04\x0E", // vmoveto
      b"\x8B\x8B\x15\x8B\x8B\x16\x0E", // hmoveto
      type2_geometry_wb_program([1], b'\x05'), // odd rlineto residual
      type2_geometry_wb_program([], b'\x06'),
      type2_geometry_wb_program([], b'\x07'),
      type2_geometry_wb_program([1, 2, 3, 4, 5, 6, 7], b'\x08'),
      type2_geometry_wb_program([1, 2, 3, 4, 5, 6, 7], b'\x18'),
      type2_geometry_wb_program([1, 2, 3, 4, 5, 6, 7], b'\x19'),
      type2_geometry_wb_program([1, 2, 3, 4, 5, 6], b'\x1A'),
      type2_geometry_wb_program([1, 2, 3, 4, 5, 6], b'\x1B'),
      type2_geometry_wb_program([1, 2, 3, 4, 5, 6], b'\x1E'),
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
  inspect(
    one_short.category() == @error.ErrorCategory::Resource,
    content="true",
  )
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

  let two_contours_exact = type2_vm_wb_run_with(
    two_contours,
    0L,
    0L,
    0L,
    type2_vm_wb_geometry_limits(4UL, 2UL, 65535UL, 65535UL),
  ).unwrap()
  inspect(two_contours_exact.geometry.points, content="4")
  inspect(two_contours_exact.geometry.contours, content="2")
  inspect(two_contours_exact.geometry.commands, content="6")
}
