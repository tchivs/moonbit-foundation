///|
fn type2_fixture_index(objects : Array[Bytes]) -> CffIndex {
  let data : Array[Byte] = []
  let offsets : Array[UInt64] = [1UL]
  let mut next = 1UL
  for object in objects {
    for byte in object {
      data.push(byte)
      next = next + 1UL
    }
    offsets.push(next)
  }
  let view = font_wb_view(Bytes::from_array(data))
  {
    count: objects.length().to_uint64(),
    off_size: 1UL,
    offsets,
    object_data: view,
    encoded_length: view.length(),
  }
}

///|
fn type2_fixture_run(
  root : Bytes,
  local_objects : Array[Bytes],
  global_objects : Array[Bytes],
  limits : Type2Limits,
) -> Result[Type2VmResult, @error.CoreError] {
  let root_view = font_wb_view(root)
  type2_execute_program(
    root_view,
    type2_fixture_index(local_objects),
    type2_fixture_index(global_objects),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    limits,
    root_view.mutation_revision(),
  )
}

///|
test "Type 2 subroutine bias thresholds are count-derived" {
  inspect(type2_subr_bias(0UL), content="107")
  inspect(type2_subr_bias(1239UL), content="107")
  inspect(type2_subr_bias(1240UL), content="1131")
  inspect(type2_subr_bias(33899UL), content="1131")
  inspect(type2_subr_bias(33900UL), content="32768")
  inspect(type2_subr_bias(65536UL), content="32768")
}

///|
test "Type 2 local and global frames share the operand stack without host recursion" {
  // root -> local[0] -> global[0] -> return -> return -> root endchar
  let local_to_global = type2_fixture_run(
    b"\x20\x0a\x0e",
    [b"\x20\x1d\x0b"],
    [b"\x92\x0b"],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(local_to_global.width.unwrap().raw, content="458752")
  inspect(local_to_global.ledger.calls, content="2")
  inspect(local_to_global.ledger.returns, content="2")

  // root -> global[0] -> local[0] -> return -> return -> root endchar
  let global_to_local = type2_fixture_run(
    b"\x20\x1d\x0e",
    [b"\x93\x0b"],
    [b"\x20\x0a\x0b"],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(global_to_local.width.unwrap().raw, content="524288")
  inspect(global_to_local.ledger.calls, content="2")
  inspect(global_to_local.ledger.returns, content="2")
}

///|
test "Type 2 invalid subr and recursive frame exhaustion are deterministic" {
  let invalid = type2_fixture_run(
    b"\x20\x0a\x0e",
    [],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap_err()
  inspect(invalid.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    invalid.context() == Some("font-cff-type2-local-subr-index"),
    content="true",
  )

  let recursive = type2_fixture_run(
    b"\x20\x0a\x0e",
    [b"\x20\x0a\x0b"],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap_err()
  inspect(recursive.category() == @error.ErrorCategory::Resource, content="true")
  inspect(
    recursive.context() == Some("font-cff-type2-frame-depth"),
    content="true",
  )
}

///|
test "Type 2 frame scratch exactly covers the legal depth ceiling" {
  let depth_ten = [
    b"\x21\x0a\x0b",
    b"\x22\x0a\x0b",
    b"\x23\x0a\x0b",
    b"\x24\x0a\x0b",
    b"\x25\x0a\x0b",
    b"\x26\x0a\x0b",
    b"\x27\x0a\x0b",
    b"\x28\x0a\x0b",
    b"\x29\x0a\x0b",
    b"\x0b",
  ]
  let limits = type2_vm_wb_limits(65535UL, 65535UL)
  let root = font_wb_view(b"\x20\x0a\x0e")
  let vm = Type2Vm::new(
    root,
    type2_fixture_index(depth_ten),
    type2_fixture_index([]),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_identity_matrix(),
    limits,
  )
  // Root plus ten live subroutine frames is the proven peak occupancy.
  inspect(vm.frames.capacity(), content="11")
  let legal = type2_fixture_run(b"\x20\x0a\x0e", depth_ten, [], limits).unwrap()
  inspect(legal.ledger.calls, content="10")
  inspect(legal.ledger.returns, content="10")

  let depth_eleven = [
    b"\x21\x0a\x0b",
    b"\x22\x0a\x0b",
    b"\x23\x0a\x0b",
    b"\x24\x0a\x0b",
    b"\x25\x0a\x0b",
    b"\x26\x0a\x0b",
    b"\x27\x0a\x0b",
    b"\x28\x0a\x0b",
    b"\x29\x0a\x0b",
    b"\x2a\x0a\x0b",
    b"\x0b",
  ]
  let rejected = type2_fixture_run(
    b"\x20\x0a\x0e",
    depth_eleven,
    [],
    limits,
  ).unwrap_err()
  inspect(
    rejected.context() == Some("font-cff-type2-frame-depth"),
    content="true",
  )
}

///|
test "Type 2 endchar terminates root and only an all-tail subroutine chain" {
  inspect(type2_vm_wb_run(b"\x0e") is Ok(_), content="true")

  let tail = type2_fixture_run(
    b"\x20\x0a",
    [b"\x0e"],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(tail.terminated, content="true")

  let nested_tail = type2_fixture_run(
    b"\x20\x0a",
    [b"\x20\x1d"],
    [b"\x0e"],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap()
  inspect(nested_tail.terminated, content="true")

  type2_vm_wb_assert_data(type2_vm_wb_run(b""))
  type2_vm_wb_assert_data(type2_vm_wb_run(b"\x0b"))
  type2_vm_wb_assert_data(type2_vm_wb_run(b"\x0e\x0e"))
  let non_tail = type2_fixture_run(
    b"\x20\x0a\x8b\x0c\x12\x0e",
    [b"\x0e"],
    [],
    type2_vm_wb_limits(65535UL, 65535UL),
  ).unwrap_err()
  inspect(non_tail.category() == @error.ErrorCategory::Data, content="true")
  inspect(
    non_tail.context() == Some("font-cff-type2-non-tail-endchar"),
    content="true",
  )
  type2_vm_wb_assert_data(
    type2_fixture_run(
      b"\x20\x0a",
      [b"\x0e\x8b"],
      [],
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
  type2_vm_wb_assert_data(
    type2_fixture_run(
      b"\x20\x0a\x0e",
      [b"\x92"],
      [],
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
  type2_vm_wb_assert_data(
    type2_fixture_run(
      b"\x20\x0a\x0e",
      [b"\x0b\x8b"],
      [],
      type2_vm_wb_limits(65535UL, 65535UL),
    ),
  )
}

///|
test "Type 2 capability and reserved operator classes are closed" {
  let dotsection = type2_vm_wb_run(b"\x0c\x00\x0e").unwrap()
  inspect(dotsection.terminated, content="true")

  for source in [
    b"\x8b\x8b\x8b\x8b\x0e", // deprecated seac endchar
    b"\x0f", // CFF2 vsindex
    b"\x10", // CFF2 blend
  ] {
    let error = type2_vm_wb_run(source).unwrap_err()
    inspect(
      error.category() == @error.ErrorCategory::Capability,
      content="true",
    )
  }

  for source in [b"\x00", b"\x02", b"\x0c\x01"] {
    type2_vm_wb_assert_data(type2_vm_wb_run(source))
  }
}

///|
test "Type 2 error precedence is State then Resource then Capability then Data" {
  let owner = font_wb_owner(b"\x00")
  let opening_revision = owner.view().mutation_revision()
  font_wb_mutate_one_byte(owner, 0UL)
  let view = owner.view()
  let state = type2_execute_program(
    view,
    type2_vm_wb_empty_index(view),
    type2_vm_wb_empty_index(view),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_fixed_from_raw(0L).unwrap(),
    type2_vm_wb_limits(1UL, 1UL),
    opening_revision,
  ).unwrap_err()
  inspect(state.category() == @error.ErrorCategory::State, content="true")

  let resource_before_capability = type2_vm_wb_run_with(
    b"\x8b\x8b\x8b\x8b\x0e",
    0L,
    0L,
    0L,
    type2_vm_wb_limits(65535UL, 4UL),
  ).unwrap_err()
  inspect(
    resource_before_capability.category() == @error.ErrorCategory::Resource,
    content="true",
  )

  let capability = type2_vm_wb_run(b"\x8b\x8b\x8b\x8b\x0e").unwrap_err()
  inspect(
    capability.category() == @error.ErrorCategory::Capability,
    content="true",
  )

  let data = type2_vm_wb_run(b"\x00").unwrap_err()
  inspect(data.category() == @error.ErrorCategory::Data, content="true")
}

///|
test "Type 2 mid-fetch mutation wins truncated number and escape errors" {
  for item in [
    (b"\xF7", "font-cff-type2-number"),
    (b"\x0C", "font-cff-type2-escape-truncated"),
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
      type2_identity_matrix(),
      type2_vm_wb_limits(65535UL, 65535UL),
      opening_revision,
      true,
      fn() {
        probes = probes + 1
        if probes == 1 {
          font_collection_wb_mutate_restore(owner, 0UL)
        }
      },
    ).unwrap_err()
    inspect(probes, content="1")
    inspect(
      mutated.category() == @error.ErrorCategory::State,
      content="true",
    )
    inspect(
      mutated.context() == Some("font-cff-type2-source-revision-drift"),
      content="true",
    )
  }
}

///|
fn type2_fixture_descriptors(
  programs : Array[Bytes],
  seeds : Array[Int64],
) -> (Array[CffGlyphDescriptor], CffIndex, @bytes.ByteView) {
  let charstrings = type2_fixture_index(programs)
  let global_subrs = type2_fixture_index([])
  let descriptors : Array[CffGlyphDescriptor] = []
  for gid = 0; gid < programs.length(); gid = gid + 1 {
    let seed = if gid < seeds.length() { seeds[gid] } else { 0L }
    descriptors.push({
      gid: gid.to_uint64(),
      key_value: gid.to_uint64(),
      charstring: cff_index_object(
        charstrings,
        gid.to_uint64(),
        "font-cff-type2-fixture",
      ).unwrap(),
      environment: {
        fd: None,
        private_dict: {
          local_subrs: None,
          default_width_x: cff_number_zero(),
          nominal_width_x: cff_number_zero(),
          initial_random_seed: type2_fixed_from_raw(seed).unwrap(),
          dict_units: 0UL,
        },
        local_subrs: type2_fixture_index([]),
        top_font_matrix: cff_default_font_matrix(),
        fd_font_matrix: None,
        font_matrix: cff_default_font_matrix(),
      },
    })
  }
  (descriptors, global_subrs, charstrings.object_data)
}

///|
fn type2_fixture_staging_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=65536UL,
      allocations=65536UL,
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
fn type2_fixture_repeated_roll_program(repetitions : Int) -> Bytes {
  let program : Array[Byte] = [b'\x8b', b'\x8c', b'\x8d']
  for repetition = 0; repetition < repetitions; repetition = repetition + 1 {
    // Keep three operands live while repeatedly rotating them by one.
    program.push(b'\x8e')
    program.push(b'\x8c')
    program.push(b'\x0c')
    program.push(b'\x1e')
  }
  for drop = 0; drop < 3; drop = drop + 1 {
    program.push(b'\x0c')
    program.push(b'\x12')
  }
  program.push(b'\x0e')
  Bytes::from_array(program)
}

///|
fn type2_fixture_many_curve_program(curves : Int) -> Bytes {
  let program : Array[Byte] = [b'\x8b', b'\x8b', b'\x15']
  for curve = 0; curve < curves; curve = curve + 1 {
    for operand = 0; operand < 6; operand = operand + 1 {
      program.push(b'\x8b')
    }
    program.push(b'\x08')
  }
  program.push(b'\x0e')
  Bytes::from_array(program)
}

///|
fn type2_fixture_allocation_budget(allocations : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      // Two retained 32-byte bounds-plus-path-command slots.
      bytes=64UL,
      // Independent invariant: four fixed scratch arrays per glyph, one
      // retained-bounds payload for the drawn glyph, and two outer arrays.
      allocations~,
      allocation_size=384UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=65535UL,
    ),
  )
}

///|
test "Type 2 repeated roll and many curves use fixed scratch allocation authority" {
  let programs = [
    type2_fixture_repeated_roll_program(64),
    type2_fixture_many_curve_program(32),
  ]
  let (descriptors, global_subrs, authority) = type2_fixture_descriptors(
    programs,
    [],
  )
  let exact = type2_fixture_allocation_budget(11UL)
  let staged = type2_stage_all_glyphs(
    descriptors,
    global_subrs,
    1000UL,
    type2_vm_wb_geometry_limits(128UL, 2UL, 65535UL, 65535UL),
    exact,
    authority,
    authority.mutation_revision(),
  ).unwrap()
  inspect(staged.bounds[0] is None, content="true")
  inspect(staged.bounds[1] is Some(_), content="true")
  inspect(staged.charge.allocations, content="11")
  inspect(staged.charge.allocation_size, content="384")

  let (short_descriptors, short_global_subrs, short_authority) =
    type2_fixture_descriptors(programs, [])
  let one_short = type2_fixture_allocation_budget(10UL)
  let before = one_short.remaining()
  let error = type2_stage_all_glyphs(
    short_descriptors,
    short_global_subrs,
    1000UL,
    type2_vm_wb_geometry_limits(128UL, 2UL, 65535UL, 65535UL),
    one_short,
    short_authority,
    short_authority.mutation_revision(),
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.context() == Some("allocations"), content="true")
  inspect(
    one_short.remaining().allocations() == before.allocations(),
    content="true",
  )
}

///|
test "Type 2 all-GID staging is ascending, exact, and does not commit budget" {
  let (descriptors, global_subrs, authority) = type2_fixture_descriptors(
    [
      b"\x8b\x8b\x15\x8c\x8c\x05\x0e",
      b"\x8b\x8b\x15\x8c\x8c\x05\x0e",
    ],
    [],
  )
  let budget = type2_fixture_staging_budget()
  let before = budget.remaining()
  let visited : Array[UInt64] = []
  let staged = type2_stage_all_glyphs_with_probe(
    descriptors,
    global_subrs,
    1000UL,
    type2_vm_wb_limits(65535UL, 65535UL),
    budget,
    authority,
    authority.mutation_revision(),
    fn(gid) { visited.push(gid) },
  ).unwrap()
  inspect(visited, content="[0, 1]")
  inspect(staged.bounds.length(), content="2")
  inspect(staged.path_command_counts, content="[3, 3]")
  inspect(staged.charge.bounds_slots, content="2")
  inspect(staged.charge.executed_bytes, content="14")
  inspect(staged.charge.points, content="4")
  inspect(staged.charge.contours, content="2")
  inspect(staged.charge.commands, content="6")
  inspect(staged.charge.bytes, content="64")
  inspect(staged.charge.allocations, content="12")
  inspect(staged.charge.allocation_size, content="384")
  inspect(staged.charge.work, content="24")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(
    budget.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "Type 2 work authority rejects caller and ancestor before VM visit" {
  let limits = type2_vm_wb_limits(65535UL, 65535UL)
  let resource_limits = @budget.ResourceLimits::new(
    bytes=32UL,
    allocations=6UL,
    allocation_size=384UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=0UL,
  )
  let (caller_descriptors, caller_subrs, caller_authority) =
    type2_fixture_descriptors([b"\x00"], [])
  let caller = @budget.Budget::new(resource_limits)
  let caller_before = caller.remaining()
  let caller_visited : Array[UInt64] = []
  let caller_error = type2_stage_all_glyphs_with_probe(
    caller_descriptors,
    caller_subrs,
    1000UL,
    limits,
    caller,
    caller_authority,
    caller_authority.mutation_revision(),
    fn(gid) { caller_visited.push(gid) },
  ).unwrap_err()
  inspect(caller_error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(caller_error.context() == Some("work"), content="true")
  inspect(caller_visited.length(), content="0")
  inspect(caller.remaining().work() == caller_before.work(), content="true")

  let (ancestor_descriptors, ancestor_subrs, ancestor_authority) =
    type2_fixture_descriptors([b"\x00"], [])
  let ancestor_limits = @budget.ResourceLimits::new(
    bytes=32UL,
    allocations=6UL,
    allocation_size=384UL,
    width=0UL,
    height=0UL,
    pixels=0UL,
    depth=0UL,
    work=1UL,
  )
  let ancestor = @budget.Budget::new(ancestor_limits)
  let child = ancestor.child(ancestor_limits).unwrap()
  ancestor
  .charge(
    @budget.ResourceCharge::new(
      bytes=0UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=1UL,
    ),
  )
  .unwrap()
  let ancestor_before = ancestor.remaining()
  let child_before = child.remaining()
  let ancestor_visited : Array[UInt64] = []
  let ancestor_error = type2_stage_all_glyphs_with_probe(
    ancestor_descriptors,
    ancestor_subrs,
    1000UL,
    limits,
    child,
    ancestor_authority,
    ancestor_authority.mutation_revision(),
    fn(gid) { ancestor_visited.push(gid) },
  ).unwrap_err()
  inspect(
    ancestor_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(ancestor_error.context() == Some("work"), content="true")
  inspect(ancestor_visited.length(), content="0")
  inspect(ancestor.remaining().work() == ancestor_before.work(), content="true")
  inspect(child.remaining().work() == child_before.work(), content="true")
}

///|
test "Type 2 all-GID staging resets transient state and stops at first failure" {
  let (descriptors, global_subrs, authority) = type2_fixture_descriptors(
    [
      b"\x8c\x8b\x0c\x14\x0e",
      b"\x8b\x0c\x15\x0c\x12\x0e",
      b"\x00",
    ],
    [],
  )
  let budget = type2_fixture_staging_budget()
  let before = budget.remaining()
  let visited : Array[UInt64] = []
  let error = type2_stage_all_glyphs_with_probe(
    descriptors,
    global_subrs,
    1000UL,
    type2_vm_wb_limits(65535UL, 65535UL),
    budget,
    authority,
    authority.mutation_revision(),
    fn(gid) { visited.push(gid) },
  ).unwrap_err()
  inspect(visited, content="[0, 1]")
  inspect(
    error.context() == Some("font-cff-type2-transient-uninitialized"),
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
test "Type 2 all-GID staging resets PRNG from each selected environment" {
  let random_shape = b"\x0c\x17\xef\x0c\x18\x16\x8c\x8b\x05\x0e"
  let (descriptors, global_subrs, authority) = type2_fixture_descriptors(
    [random_shape, random_shape, random_shape],
    [65536L, 131072L, 65536L],
  )
  let budget = type2_fixture_staging_budget()
  let staged = type2_stage_all_glyphs(
    descriptors,
    global_subrs,
    1000UL,
    type2_vm_wb_limits(65535UL, 65535UL),
    budget,
    authority,
    authority.mutation_revision(),
  ).unwrap()
  let first = staged.bounds[0].unwrap()
  let different = staged.bounds[1].unwrap()
  let repeated = staged.bounds[2].unwrap()
  inspect(first.x_min == repeated.x_min, content="true")
  inspect(first.x_max == repeated.x_max, content="true")
  inspect(first.x_min != different.x_min, content="true")
}
