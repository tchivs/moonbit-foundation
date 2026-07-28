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
fn type2_flex_wb_program(arguments : Array[Int], escaped : Byte) -> Bytes {
  let source : Array[Byte] = [b'\x8B', b'\x8B', b'\x15']
  for argument in arguments {
    source.push((argument + 139).to_byte())
  }
  source.push(b'\x0C')
  source.push(escaped)
  source.push(b'\x0E')
  Bytes::from_array(source)
}

///|
fn type2_bounds_wb_run_with_matrix(
  source : Bytes,
  matrix : Type2Matrix,
) -> Result[Type2VmResult, @error.CoreError] {
  let view = font_wb_view(source)
  type2_execute_program_with_matrix(
    view,
    type2_vm_wb_empty_index(view),
    type2_vm_wb_empty_index(view),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    matrix,
    type2_vm_wb_limits(65535UL, 65535UL),
    view.mutation_revision(),
  )
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

///|
test "Type 2 flex forms lower to the same two cubics as explicit rrcurveto" {
  let cases : Array[(Array[Int], Byte, Array[Int])] = [
    (
      [1, 2, 3, 4, 5, 6, 7],
      b'\x22',
      [1, 0, 2, 3, 4, 0, 5, 0, 6, -3, 7, 0],
    ), // hflex
    (
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 50],
      b'\x23',
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    ), // flex
    (
      [1, 2, 3, 4, 5, 6, 7, 8, 9],
      b'\x24',
      [1, 2, 3, 4, 5, 0, 6, 0, 7, 8, 9, -14],
    ), // hflex1
    (
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      b'\x25',
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, -25, 11],
    ), // flex1
  ]
  for item in cases {
    let flex = type2_vm_wb_run(type2_flex_wb_program(item.0, item.1)).unwrap()
    let explicit = type2_vm_wb_run(
      type2_geometry_wb_program(item.2, b'\x08'),
    ).unwrap()
    inspect(
      flex.geometry.current_x.raw == explicit.geometry.current_x.raw,
      content="true",
    )
    inspect(
      flex.geometry.current_y.raw == explicit.geometry.current_y.raw,
      content="true",
    )
    inspect(flex.geometry.min_x.raw == explicit.geometry.min_x.raw, content="true")
    inspect(flex.geometry.min_y.raw == explicit.geometry.min_y.raw, content="true")
    inspect(flex.geometry.max_x.raw == explicit.geometry.max_x.raw, content="true")
    inspect(flex.geometry.max_y.raw == explicit.geometry.max_y.raw, content="true")
    inspect(flex.geometry.points, content="7")
    inspect(flex.geometry.commands, content="4")
  }

  for item in [
    (b'\x22', [1, 2, 3, 4, 5, 6]),
    (b'\x23', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
    (b'\x24', [1, 2, 3, 4, 5, 6, 7, 8]),
    (b'\x25', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
  ] {
    type2_vm_wb_assert_data(
      type2_vm_wb_run(type2_flex_wb_program(item.1, item.0)),
    )
  }
}

///|
test "Type 2 bounds transform every hull point and round outward" {
  let identity = type2_matrix_compose(type2_wb_matrix(1L, 0L, 0L, 1L, 0L, 0L), None, 1UL).unwrap()
  let fractional = type2_bounds_wb_run_with_matrix(
    b"\x8B\x8B\x15\xFF\x00\x01\x80\x00\xFF\xFF\xFE\x80\x00\x05\x0E",
    identity,
  ).unwrap().geometry.bounds.unwrap()
  inspect(fractional.x_min, content="0")
  inspect(fractional.y_min, content="-2")
  inspect(fractional.x_max, content="2")
  inspect(fractional.y_max, content="0")

  let top = type2_wb_matrix(2L, 0L, 0L, 3L, 10L, -10L)
  let fd = type2_wb_matrix(1L, 0L, 0L, 1L, 5L, 7L)
  let path = type2_geometry_wb_program([1, 2], b'\x05')
  let name = type2_bounds_wb_run_with_matrix(
    path,
    type2_matrix_compose(top, None, 1UL).unwrap(),
  ).unwrap().geometry.bounds.unwrap()
  inspect(name.x_min, content="10")
  inspect(name.y_min, content="-10")
  inspect(name.x_max, content="12")
  inspect(name.y_max, content="-4")

  let cid = type2_bounds_wb_run_with_matrix(
    path,
    type2_matrix_compose(top, Some(fd), 1UL).unwrap(),
  ).unwrap().geometry.bounds.unwrap()
  inspect(cid.x_min, content="20")
  inspect(cid.y_min, content="11")
  inspect(cid.x_max, content="22")
  inspect(cid.y_max, content="17")

  let omitted_fd = type2_bounds_wb_run_with_matrix(
    path,
    type2_matrix_compose(top, None, 1UL).unwrap(),
  ).unwrap().geometry.bounds.unwrap()
  inspect(omitted_fd.x_min == name.x_min, content="true")
  inspect(omitted_fd.y_min == name.y_min, content="true")
  inspect(omitted_fd.x_max == name.x_max, content="true")
  inspect(omitted_fd.y_max == name.y_max, content="true")
}

///|
test "Type 2 bounds include each non-empty contour start" {
  let matrix = type2_matrix_compose(
    type2_wb_matrix(2L, 0L, 0L, 3L, 10L, -10L),
    None,
    1UL,
  ).unwrap()
  let programs = [
    // Draw (0, 0) -> (10, 10), move to (100, 100), then line inward.
    b"\x8B\x8B\x15\x95\x95\x05\xE5\xE5\x15\x59\x59\x05\x0E",
    // Draw the same first contour, then curve inward from (100, 100).
    b"\x8B\x8B\x15\x95\x95\x05\xE5\xE5\x15\x81\x81\x81\x81\x81\x81\x08\x0E",
  ]
  for program in programs {
    let bounds = type2_bounds_wb_run_with_matrix(
      program,
      matrix,
    ).unwrap().geometry.bounds.unwrap()
    inspect(bounds.x_min, content="10")
    inspect(bounds.y_min, content="-10")
    inspect(bounds.x_max, content="210")
    inspect(bounds.y_max, content="290")
  }
}

///|
test "Type 2 empty and moveto-only glyphs retain no bound" {
  inspect(type2_vm_wb_run(b"\x0E").unwrap().geometry.bounds is None, content="true")
  inspect(
    type2_vm_wb_run(b"\x95\x9F\x15\x0E").unwrap().geometry.bounds is None,
    content="true",
  )
}

///|
test "Type 2 bounds accept fixed extremes and reject transform overflow" {
  let extremes = type2_vm_wb_run(
    b"\x8B\x8B\x15\xFF\x7F\xFF\xFF\xFF\xFF\x80\x00\x00\x00\x05\x0E",
  ).unwrap().geometry.bounds.unwrap()
  inspect(extremes.x_min, content="0")
  inspect(extremes.y_min, content="-32768")
  inspect(extremes.x_max, content="32768")
  inspect(extremes.y_max, content="0")

  let zero : Type2Rational = { numerator: 0L, denominator: 1L }
  let one : Type2Rational = { numerator: 1L, denominator: 1L }
  let huge : Type2Rational = {
    numerator: 9223372036854775807L,
    denominator: 1L,
  }
  let overflow_matrix : Type2Matrix = {
    a: huge,
    b: zero,
    c: zero,
    d: one,
    tx: zero,
    ty: zero,
  }
  let overflow = type2_bounds_wb_run_with_matrix(
    type2_geometry_wb_program([2, 0], b'\x05'),
    overflow_matrix,
  ).unwrap_err()
  inspect(overflow.category() == @error.ErrorCategory::Data, content="true")
}
