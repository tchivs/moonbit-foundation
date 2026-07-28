///|
fn cff_path_wb_rational(
  numerator : Int64,
  denominator : Int64,
) -> Type2Rational {
  { numerator, denominator }
}

///|
fn cff_path_wb_identity_matrix() -> Type2Matrix {
  {
    a: cff_path_wb_rational(1L, 1L),
    b: cff_path_wb_rational(0L, 1L),
    c: cff_path_wb_rational(0L, 1L),
    d: cff_path_wb_rational(1L, 1L),
    tx: cff_path_wb_rational(0L, 1L),
    ty: cff_path_wb_rational(0L, 1L),
  }
}

///|
fn cff_path_wb_fixed(raw : Int64) -> Type2Fixed {
  type2_fixed_from_raw(raw).unwrap()
}

///|
fn cff_path_wb_owner_and_font(
  programs : Array[Bytes],
) -> (@bytes.OwnedBytes, Font) {
  let owner = font_wb_owner(
    cff_wb_otf_with_cmap(
      cff_wb_name_table_with_programs(programs),
      cff_wb_cmap_format4_two_segments(),
      num_glyphs=programs.length().to_uint64(),
    ),
  )
  let font = Font::open(owner.view(), font_wb_limits(), cff_wb_budget()).unwrap()
  (owner, font)
}

///|
fn cff_path_wb_admitted(font : Font) -> AdmittedCff1 {
  match font.outline_source {
    FontOutlineSource::Cff1(value) => value
    FontOutlineSource::Glyf(_) => abort("expected CFF outline source")
  }
}

///|
fn cff_path_wb_limits(
  bytes : UInt64,
  allocations : UInt64,
  allocation_size : UInt64,
  work : UInt64,
) -> @budget.ResourceLimits {
  @budget.ResourceLimits::new(
    bytes~,
    allocations~,
    allocation_size~,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work~,
  )
}

///|
fn cff_path_wb_exact_limits(charge : CffPathCharge) -> @budget.ResourceLimits {
  cff_path_wb_limits(
    charge.bytes,
    charge.allocations,
    charge.allocation_size,
    charge.work,
  )
}

///|
fn cff_path_wb_assert_limits_equal(
  left : @budget.ResourceLimits,
  right : @budget.ResourceLimits,
) -> Unit raise {
  inspect(left.bytes() == right.bytes(), content="true")
  inspect(left.allocations() == right.allocations(), content="true")
  inspect(left.allocation_size() == right.allocation_size(), content="true")
  inspect(left.width() == right.width(), content="true")
  inspect(left.height() == right.height(), content="true")
  inspect(left.pixels() == right.pixels(), content="true")
  inspect(left.depth() == right.depth(), content="true")
  inspect(left.work() == right.work(), content="true")
}

///|
fn cff_path_wb_assert_resource(
  result : Result[@math.Path2, @error.CoreError],
  dimension : String,
) -> Unit raise {
  inspect(result is Err(_), content="true")
  let error = result.unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
  inspect(error.context() == Some(dimension), content="true")
}

///|
fn cff_path_wb_assert_path_equal(
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
      ) => {
        inspect(left_point.x() == right_point.x(), content="true")
        inspect(left_point.y() == right_point.y(), content="true")
      }
      (
        Some(@math.PathCommand::CubicTo(left_control1, left_control2, left_end)),
        Some(
          @math.PathCommand::CubicTo(right_control1, right_control2, right_end)
        ),
      ) => {
        inspect(left_control1.x() == right_control1.x(), content="true")
        inspect(left_control1.y() == right_control1.y(), content="true")
        inspect(left_control2.x() == right_control2.x(), content="true")
        inspect(left_control2.y() == right_control2.y(), content="true")
        inspect(left_end.x() == right_end.x(), content="true")
        inspect(left_end.y() == right_end.y(), content="true")
      }
      (Some(@math.PathCommand::Close), Some(@math.PathCommand::Close)) => ()
      _ => fail("CFF path commands differ")
    }
  }
}

///|
test "CFF path conversion freezes quotient plus remainder goldens" {
  inspect(
    type2_rational_to_double(cff_path_wb_rational(6L, 3L)).unwrap() == 2.0,
    content="true",
  )
  inspect(
    type2_rational_to_double(cff_path_wb_rational(7L, 2L)).unwrap() == 3.5,
    content="true",
  )
  inspect(
    type2_rational_to_double(cff_path_wb_rational(-7L, 2L)).unwrap() == -3.5,
    content="true",
  )
  inspect(
    type2_rational_to_double(cff_path_wb_rational(2147483647L, 65536L)).unwrap() ==
    32767.99998474121,
    content="true",
  )
  let invalid = type2_rational_to_double(cff_path_wb_rational(1L, 0L)).unwrap_err()
  inspect(invalid.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    invalid.context() == Some("font-cff-type2-path-coordinate"),
    content="true",
  )
}

///|
test "CFF path sink emits transformed native line and cubic commands" {
  let sink = Type2PathSink::new(4, cff_path_wb_identity_matrix())
  sink.move_to(cff_path_wb_fixed(-98304L), cff_path_wb_fixed(98304L)).unwrap()
  sink.line_to(cff_path_wb_fixed(-65536L), cff_path_wb_fixed(81920L)).unwrap()
  sink
  .cubic_to(
    cff_path_wb_fixed(65536L),
    cff_path_wb_fixed(131072L),
    cff_path_wb_fixed(196608L),
    cff_path_wb_fixed(262144L),
    cff_path_wb_fixed(327680L),
    cff_path_wb_fixed(393216L),
  )
  .unwrap()
  sink.close()
  inspect(sink.path.length(), content="4")
  match sink.path.get(0) {
    Some(@math.PathCommand::MoveTo(point)) =>
      inspect(point.x() == -1.5 && point.y() == 1.5, content="true")
    _ => fail("expected native CFF MoveTo")
  }
  match sink.path.get(1) {
    Some(@math.PathCommand::LineTo(point)) =>
      inspect(point.x() == -1.0 && point.y() == 1.25, content="true")
    _ => fail("expected native CFF LineTo")
  }
  match sink.path.get(2) {
    Some(@math.PathCommand::CubicTo(control1, control2, end)) =>
      inspect(
        control1.x() == 1.0 &&
        control1.y() == 2.0 &&
        control2.x() == 3.0 &&
        control2.y() == 4.0 &&
        end.x() == 5.0 &&
        end.y() == 6.0,
        content="true",
      )
    _ => fail("expected native CFF CubicTo")
  }
  inspect(sink.path.get(3) is Some(@math.PathCommand::Close), content="true")

  let transformed = Type2PathSink::new(1, {
    a: cff_path_wb_rational(2L, 1L),
    b: cff_path_wb_rational(0L, 1L),
    c: cff_path_wb_rational(0L, 1L),
    d: cff_path_wb_rational(3L, 1L),
    tx: cff_path_wb_rational(1L, 2L),
    ty: cff_path_wb_rational(-1L, 2L),
  })
  transformed
  .cubic_to(
    cff_path_wb_fixed(65536L),
    cff_path_wb_fixed(131072L),
    cff_path_wb_fixed(196608L),
    cff_path_wb_fixed(262144L),
    cff_path_wb_fixed(327680L),
    cff_path_wb_fixed(393216L),
  )
  .unwrap()
  match transformed.path.get(0) {
    Some(@math.PathCommand::CubicTo(control1, control2, end)) =>
      inspect(
        control1.x() == 2.5 &&
        control1.y() == 5.5 &&
        control2.x() == 6.5 &&
        control2.y() == 11.5 &&
        end.x() == 10.5 &&
        end.y() == 17.5,
        content="true",
      )
    _ => fail("expected transformed native CFF CubicTo")
  }
}

///|
test "CFF outline exact path charge covers caller and ancestor dimensions" {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  let (_owner, font) = cff_path_wb_owner_and_font([b"\x0e", cubic, b"\x0e"])
  let glyph = font.glyph_id(1UL).unwrap()
  let charge = font_wb_cff_cubic_path_charge()
  let exact_limits = cff_path_wb_exact_limits(charge)

  let caller = @budget.Budget::new(exact_limits)
  let caller_path = font.outline(glyph, caller).unwrap()
  inspect(
    caller_path.length().to_uint64() == charge.command_capacity,
    content="true",
  )
  inspect(caller.remaining().bytes(), content="0")
  inspect(caller.remaining().allocations(), content="0")
  inspect(caller.remaining().work(), content="0")

  let ancestor = @budget.Budget::new(exact_limits)
  let nested = ancestor.child(exact_limits).unwrap()
  let nested_path = font.outline(glyph, nested).unwrap()
  cff_path_wb_assert_path_equal(caller_path, nested_path)
  inspect(ancestor.remaining().bytes(), content="0")
  inspect(ancestor.remaining().allocations(), content="0")
  inspect(ancestor.remaining().work(), content="0")
  inspect(nested.remaining().bytes(), content="0")
  inspect(nested.remaining().allocations(), content="0")
  inspect(nested.remaining().work(), content="0")

  let mut probes = 0
  let probe_budget = @budget.Budget::new(exact_limits)
  let probed = cff_decode_outline_atomic_with_probes(
    font.source,
    cff_path_wb_admitted(font),
    glyph.value(),
    font.limits,
    probe_budget,
    fn() { probes = probes + 1 },
    fn() { () },
  ).unwrap()
  inspect(probes, content="1")
  cff_path_wb_assert_path_equal(caller_path, probed)
}

///|
test "CFF outline exact path charge rejects each one-short window atomically" {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  let (_owner, font) = cff_path_wb_owner_and_font([b"\x0e", cubic, b"\x0e"])
  let glyph = font.glyph_id(1UL).unwrap()
  let charge = font_wb_cff_cubic_path_charge()
  let short_limits = [
    (
      "bytes",
      cff_path_wb_limits(
        charge.bytes - 1UL,
        charge.allocations,
        charge.allocation_size,
        charge.work,
      ),
    ),
    (
      "allocations",
      cff_path_wb_limits(
        charge.bytes,
        charge.allocations - 1UL,
        charge.allocation_size,
        charge.work,
      ),
    ),
    (
      "allocation_size",
      cff_path_wb_limits(
        charge.bytes,
        charge.allocations,
        charge.allocation_size - 1UL,
        charge.work,
      ),
    ),
    (
      "work",
      cff_path_wb_limits(
        charge.bytes,
        charge.allocations,
        charge.allocation_size,
        charge.work - 1UL,
      ),
    ),
  ]
  for item in short_limits {
    let caller = @budget.Budget::new(item.1)
    let caller_before = caller.remaining()
    cff_path_wb_assert_resource(font.outline(glyph, caller), item.0)
    cff_path_wb_assert_limits_equal(caller_before, caller.remaining())

    let ancestor = @budget.Budget::new(item.1)
    let nested = ancestor.child(item.1).unwrap()
    let ancestor_before = ancestor.remaining()
    let nested_before = nested.remaining()
    cff_path_wb_assert_resource(font.outline(glyph, nested), item.0)
    cff_path_wb_assert_limits_equal(ancestor_before, ancestor.remaining())
    cff_path_wb_assert_limits_equal(nested_before, nested.remaining())
  }
}

///|
test "CFF outline exact path charge rejects overflow and count mismatch atomically" {
  let vm_limits = type2_limits(font_wb_limits()).unwrap()
  let overflow = cff_path_charge(vm_limits, 288230376151711744UL, 0UL).unwrap_err()
  inspect(overflow.category() == @error.ErrorCategory::Resource, content="true")
  inspect(
    overflow.context() == Some("font-cff-type2-path-bytes"),
    content="true",
  )

  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  let (_owner, font) = cff_path_wb_owner_and_font([b"\x0e", cubic, b"\x0e"])
  let glyph = font.glyph_id(1UL).unwrap()
  let charge = font_wb_cff_cubic_path_charge()
  let admitted = cff_path_wb_admitted(font)
  admitted.path_command_counts[1] = charge.command_capacity + 1UL
  let budget = @budget.Budget::new(
    cff_path_wb_exact_limits({
      ..charge,
      bytes: charge.bytes + 64UL,
      allocation_size: charge.allocation_size + 64UL,
      command_capacity: charge.command_capacity + 1UL,
    }),
  )
  let before = budget.remaining()
  let mismatch = cff_decode_outline_atomic(
    font.source,
    admitted,
    glyph.value(),
    font.limits,
    budget,
    fn() { () },
  ).unwrap_err()
  inspect(mismatch.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    mismatch.context() == Some("font-cff-type2-path-command-count"),
    content="true",
  )
  cff_path_wb_assert_limits_equal(before, budget.remaining())
}

///|
test "CFF outline atomic mid-fetch mutation publishes no staged path" {
  for item in [
    (b"\xf7", "font-cff-type2-number"),
    (b"\x0c", "font-cff-type2-escape-truncated"),
  ] {
    let stable = type2_vm_wb_run(item.0).unwrap_err()
    inspect(stable.category() == @error.ErrorCategory::Data, content="true")
    inspect(stable.context() == Some(item.1), content="true")

    let owner = font_wb_owner(item.0)
    let view = owner.view()
    let opening_revision = view.mutation_revision()
    let mut probes = 0
    let mutated = type2_execute_program_with_matrix_and_read_probe(
      view,
      type2_vm_wb_empty_index(view),
      type2_vm_wb_empty_index(view),
      type2_fixed_from_raw(0L).unwrap(),
      type2_fixed_from_raw(0L).unwrap(),
      type2_fixed_from_raw(0L).unwrap(),
      cff_path_wb_identity_matrix(),
      type2_vm_wb_limits(65535UL, 65535UL),
      opening_revision,
      false,
      fn() {
        probes = probes + 1
        if probes == 1 {
          font_collection_wb_mutate_restore(owner, 0UL)
        }
      },
      path_sink=Some(Type2PathSink::new(1, cff_path_wb_identity_matrix())),
    ).unwrap_err()
    inspect(probes, content="1")
    inspect(mutated.category() == @error.ErrorCategory::State, content="true")
    inspect(
      mutated.context() == Some("font-cff-type2-source-revision-drift"),
      content="true",
    )
  }
}
