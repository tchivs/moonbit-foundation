///|
fn cff_hostile_assert_atomic_error(
  cff : Bytes,
  expected_context : String,
  num_glyphs? : UInt64 = 1UL,
) -> Unit raise {
  let budget = cff_wb_budget()
  let before = budget.remaining()
  let error = admit_cff1_structure(
    font_wb_view(cff_wb_otf(cff, num_glyphs~)),
    font_wb_limits(),
    budget,
    0UL,
  ).unwrap_err()
  inspect(error.context() == Some(expected_context), content="true")
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(
    budget.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(
    budget.remaining().allocation_size() == before.allocation_size(),
    content="true",
  )
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
fn cff_hostile_budget(
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
fn cff_hostile_assert_program_error(
  programs : Array[Bytes],
  category : @error.ErrorCategory,
  context : String,
) -> Unit raise {
  let source = cff_wb_otf(
    cff_wb_name_table_with_programs(programs),
    num_glyphs=programs.length().to_uint64(),
  )
  let budget = cff_wb_budget()
  let before = budget.remaining()
  let error = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    budget,
    0UL,
  ).unwrap_err()
  inspect(error.category() == category, content="true")
  inspect(error.context() == Some(context), content="true")
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
fn cff_qualification_hostile_b8(
  value : @budget.ResourceLimits,
) -> String {
  value.bytes().to_string() +
  "," +
  value.allocations().to_string() +
  "," +
  value.allocation_size().to_string() +
  "," +
  value.width().to_string() +
  "," +
  value.height().to_string() +
  "," +
  value.pixels().to_string() +
  "," +
  value.depth().to_string() +
  "," +
  value.work().to_string()
}

///|
fn cff_qualification_hostile_optional_uint(
  value : UInt64?,
) -> String {
  match value {
    Some(value) => value.to_string()
    None => "-"
  }
}

///|
fn cff_qualification_emit_hostile_observation(
  id : String,
  error : @error.CoreError?,
  success_operation : String,
  success_requested : UInt64?,
  success_limit : UInt64?,
  gid : UInt64?,
  publication : String,
  caller_before : @budget.ResourceLimits,
  caller_after : @budget.ResourceLimits,
  ancestor_before : @budget.ResourceLimits,
  ancestor_after : @budget.ResourceLimits,
) -> Unit {
  let outcome = match error {
    Some(error) => @error.render_error(error)
    None => {
      let mut rendered = "success|operation=" + success_operation
      match success_requested {
        Some(value) =>
          rendered = rendered + "|requested=" + value.to_string()
        None => ()
      }
      match success_limit {
        Some(value) => rendered = rendered + "|limit=" + value.to_string()
        None => ()
      }
      rendered
    }
  }
  println(
    "MNF_CFF_HOSTILE|" +
    id +
    "|gid=" +
    cff_qualification_hostile_optional_uint(gid) +
    "|publication=" +
    publication +
    "|caller_before=" +
    cff_qualification_hostile_b8(caller_before) +
    "|caller_after=" +
    cff_qualification_hostile_b8(caller_after) +
    "|ancestor_before=" +
    cff_qualification_hostile_b8(ancestor_before) +
    "|ancestor_after=" +
    cff_qualification_hostile_b8(ancestor_after) +
    "|" +
    outcome,
  )
}

///|
fn cff_qualification_observe_structural_row(
  id : String,
) -> Unit raise {
  let exact = cff_wb_table()
  let (cff, num_glyphs, gid) = match id {
    "structural-header-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:3]),
        1UL,
        None,
      )
    "structural-name-index-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:12]),
        1UL,
        None,
      )
    "structural-top-index-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:22]),
        1UL,
        None,
      )
    "structural-string-index-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:24]),
        1UL,
        None,
      )
    "structural-global-subrs-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:26]),
        1UL,
        None,
      )
    "structural-charstrings-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:32]),
        1UL,
        None,
      )
    "structural-private-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:34]),
        1UL,
        None,
      )
    "structural-local-subrs-one-short" =>
      (
        Bytes::from_array(font_wb_bytes_array(exact)[0:36]),
        1UL,
        None,
      )
    "structural-dict-arity" => (cff_cid_wb_table(ros_operands=0UL), 3UL, None)
    "structural-encoding-supplement" => {
      let bytes = cff_name_wb_table(encoding_mode=4UL)
      (
        Bytes::from_array(
          font_wb_bytes_array(bytes)[0:bytes.length() - 1],
        ),
        3UL,
        None,
      )
    }
    "structural-fd-select-fd" =>
      (
        cff_cid_wb_table(fd_select_format=0UL, gid_two_fd=2UL),
        3UL,
        Some(2UL),
      )
    "structural-fd-select-sentinel" =>
      (
        cff_cid_wb_table(fd_select_format=3UL, fd_sentinel=2UL),
        3UL,
        Some(2UL),
      )
    "structural-fd-private-range" =>
      (cff_cid_wb_table(invalid_unused_fd=true), 3UL, None)
    "structural-font-matrix-arity" =>
      (cff_cid_wb_table(invalid_matrix=true), 3UL, None)
    "structural-cid-charset" =>
      (cff_cid_wb_table(predefined_charset=true), 3UL, None)
    "structural-cid-encoding" =>
      (cff_cid_wb_table(include_encoding=true), 3UL, None)
    _ => fail("unknown structural hostile row: " + id)
  }
  let source = cff_wb_otf(cff, num_glyphs~)
  let limits = cff_wb_budget().remaining()
  let ancestor = @budget.Budget::new(limits)
  let caller = ancestor.child(limits).unwrap()
  let caller_before = caller.remaining()
  let ancestor_before = ancestor.remaining()
  let result = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    caller,
    gid.unwrap_or(0UL),
  )
  let error = result.unwrap_err()
  cff_qualification_emit_hostile_observation(
    id,
    Some(error),
    "",
    None,
    None,
    gid,
    "none",
    caller_before,
    caller.remaining(),
    ancestor_before,
    ancestor.remaining(),
  )
}

///|
fn cff_qualification_standard_hostile_budget(
) -> (@budget.Budget, @budget.Budget) {
  let limits = cff_wb_budget().remaining()
  let ancestor = @budget.Budget::new(limits)
  let caller = ancestor.child(limits).unwrap()
  (ancestor, caller)
}

///|
fn cff_qualification_stage_type2_program(
  root : Bytes,
  local_objects : Array[Bytes],
  global_objects : Array[Bytes],
  limits : Type2Limits,
  budget : @budget.Budget,
  default_width? : CffNumber = cff_number_zero(),
  nominal_width? : CffNumber = cff_number_zero(),
  seed? : Int64 = 0L,
  read_probe? : () -> Unit = fn() { () },
) -> Result[Type2AllGlyphResult, @error.CoreError] {
  let charstrings = type2_fixture_index([root])
  let global_subrs = type2_fixture_index(global_objects)
  let authority = charstrings.object_data
  let descriptor : CffGlyphDescriptor = {
    gid: 0UL,
    key_value: 0UL,
    charstring: cff_index_object(
      charstrings,
      0UL,
      "font-cff-type2-qualification",
    ).unwrap(),
    environment: {
      fd: None,
      private_dict: {
        local_subrs: None,
        default_width_x: default_width,
        nominal_width_x: nominal_width,
        initial_random_seed: type2_fixed_from_raw(seed).unwrap(),
        dict_units: 0UL,
      },
      local_subrs: type2_fixture_index(local_objects),
      top_font_matrix: cff_default_font_matrix(),
      fd_font_matrix: None,
      font_matrix: cff_default_font_matrix(),
    },
  }
  type2_stage_all_glyphs_with_probe(
    [descriptor],
    global_subrs,
    1000UL,
    limits,
    budget,
    authority,
    authority.mutation_revision(),
    fn(_) { () },
    read_probe~,
  )
}

///|
fn cff_qualification_observe_type2_program(
  id : String,
  root : Bytes,
  local_objects : Array[Bytes],
  global_objects : Array[Bytes],
  limits : Type2Limits,
  requested : UInt64?,
  limit : UInt64?,
  gid : UInt64,
  default_width? : CffNumber = cff_number_zero(),
  nominal_width? : CffNumber = cff_number_zero(),
  seed? : Int64 = 0L,
) -> Unit raise {
  let (ancestor, caller) = cff_qualification_standard_hostile_budget()
  let caller_before = caller.remaining()
  let ancestor_before = ancestor.remaining()
  let result = cff_qualification_stage_type2_program(
    root,
    local_objects,
    global_objects,
    limits,
    caller,
    default_width~,
    nominal_width~,
    seed~,
  )
  let (error, publication) = match result {
    Ok(_) => (None, "staged-glyph")
    Err(error) => (Some(error), "none")
  }
  cff_qualification_emit_hostile_observation(
    id,
    error,
    "font-cff-type2",
    requested,
    limit,
    Some(gid),
    publication,
    caller_before,
    caller.remaining(),
    ancestor_before,
    ancestor.remaining(),
  )
}

///|
fn cff_qualification_stack_program(
  count : Int,
  consume : Bool,
) -> Bytes {
  let program : Array[Byte] = []
  for _index = 0; _index < count; _index = _index + 1 {
    program.push(b'\x8B')
  }
  if consume {
    for _index = 0; _index < count; _index = _index + 1 {
      program.push(b'\x0C')
      program.push(b'\x12')
    }
  }
  program.push(b'\x0E')
  Bytes::from_array(program)
}

///|
fn cff_qualification_stem_program(count : Int) -> Bytes {
  let program : Array[Byte] = []
  for _index = 0; _index < count; _index = _index + 1 {
    program.push(b'\x8B')
    program.push(b'\x8B')
    program.push(b'\x01')
  }
  program.push(b'\x0E')
  Bytes::from_array(program)
}

///|
fn cff_qualification_depth_programs(
  count : Int,
) -> Array[Bytes] {
  let programs : Array[Bytes] = []
  for index = 0; index < count; index = index + 1 {
    if index + 1 == count {
      programs.push(b"\x0b")
    } else {
      programs.push(
        Bytes::from_array([
          (b'\x21'.to_int() + index).to_byte(),
          b'\x0a',
          b'\x0b',
        ]),
      )
    }
  }
  programs
}

///|
fn cff_qualification_observe_type2_row(
  id : String,
) -> Unit raise {
  let (
    root,
    local_objects,
    global_objects,
    limits,
    requested,
    limit,
    gid,
    default_width,
    nominal_width,
  ) = match id {
    "type2-number-stack-arity" =>
      (
        b"\x0c\x09\x0e",
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        None,
        None,
        0UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    "type2-arithmetic-logical-storage" =>
      (
        b"\x8c\x8b\x0c\x0c\x0e",
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(0UL),
        Some(0UL),
        1UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    "type2-random-width-state" =>
      (
        b"\x8b\x8b\x01\x8c\x8b\x8b\x15\x0e",
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        None,
        None,
        0UL,
        { negative: false, magnitude: 500UL, denominator: 1UL },
        { negative: false, magnitude: 100UL, denominator: 1UL },
      )
    "type2-path-flex-geometry" =>
      (
        type2_geometry_wb_program([1], b'\x05'),
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        None,
        None,
        0UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    "type2-stem-mask" =>
      (
        cff_qualification_stem_program(97),
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(97UL),
        Some(96UL),
        0UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    "type2-subroutine-frame" =>
      (
        b"\x20\x0a\x0e",
        [b"\x20\x0a\x0b"],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(11UL),
        Some(10UL),
        0UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    "type2-operator-capability" =>
      (
        b"\x8b\x8b\x8b\x8b\x0e",
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        None,
        None,
        1UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    "type2-termination" =>
      (
        b"\x20\x0a\x8b\x0c\x12\x0e",
        [b"\x0e"],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        None,
        None,
        0UL,
        cff_number_zero(),
        cff_number_zero(),
      )
    _ => fail("unknown Type 2 hostile row: " + id)
  }
  cff_qualification_observe_type2_program(
    id,
    root,
    local_objects,
    global_objects,
    limits,
    requested,
    limit,
    gid,
    default_width~,
    nominal_width~,
  )
}

///|
fn cff_qualification_observe_semantic_row(
  id : String,
) -> Unit raise {
  match id {
    "semantic-stack-48-exact" =>
      cff_qualification_observe_type2_program(
        id,
        cff_qualification_stack_program(48, true),
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(48UL),
        Some(48UL),
        0UL,
      )
    "semantic-stack-49-one-short" =>
      cff_qualification_observe_type2_program(
        id,
        cff_qualification_stack_program(49, false),
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(49UL),
        Some(48UL),
        0UL,
      )
    "semantic-stem-96-exact" =>
      cff_qualification_observe_type2_program(
        id,
        cff_qualification_stem_program(96),
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(96UL),
        Some(96UL),
        0UL,
      )
    "semantic-stem-97-one-short" =>
      cff_qualification_observe_type2_program(
        id,
        cff_qualification_stem_program(97),
        [],
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(97UL),
        Some(96UL),
        0UL,
      )
    "semantic-frame-depth-exact" =>
      cff_qualification_observe_type2_program(
        id,
        b"\x20\x0a\x0e",
        cff_qualification_depth_programs(10),
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(10UL),
        Some(10UL),
        0UL,
      )
    "semantic-frame-depth-one-short" =>
      cff_qualification_observe_type2_program(
        id,
        b"\x20\x0a\x0e",
        cff_qualification_depth_programs(11),
        [],
        type2_vm_wb_limits(65535UL, 65535UL),
        Some(11UL),
        Some(10UL),
        0UL,
      )
    "semantic-outline-points-exact" =>
      cff_qualification_observe_type2_program(
        id,
        type2_geometry_wb_program([10, 20], b'\x05'),
        [],
        [],
        type2_vm_wb_geometry_limits(2UL, 1UL, 65535UL, 65535UL),
        Some(2UL),
        Some(2UL),
        0UL,
      )
    "semantic-outline-points-one-short" =>
      cff_qualification_observe_type2_program(
        id,
        type2_geometry_wb_program([10, 20], b'\x05'),
        [],
        [],
        type2_vm_wb_geometry_limits(1UL, 1UL, 65535UL, 65535UL),
        Some(2UL),
        Some(1UL),
        0UL,
      )
    "semantic-outline-contours-exact" =>
      cff_qualification_observe_type2_program(
        id,
        b"\x8B\x8B\x15\x8C\x8C\x05\x8B\x8B\x15\x8C\x8C\x05\x0E",
        [],
        [],
        type2_vm_wb_geometry_limits(4UL, 2UL, 65535UL, 65535UL),
        Some(2UL),
        Some(2UL),
        0UL,
      )
    "semantic-outline-contours-one-short" =>
      cff_qualification_observe_type2_program(
        id,
        b"\x8B\x8B\x15\x8C\x8C\x05\x8B\x8B\x15\x8C\x8C\x05\x0E",
        [],
        [],
        type2_vm_wb_geometry_limits(8UL, 1UL, 65535UL, 65535UL),
        Some(2UL),
        Some(1UL),
        0UL,
      )
    "semantic-retained-allocation-exact"
    | "semantic-geometry-and-retained-arrays" => {
      let programs : Array[Bytes] = []
      for _index = 0; _index < 10; _index = _index + 1 {
        programs.push(b"\x0e")
      }
      let (descriptors, global_subrs, authority) =
        type2_fixture_descriptors(programs, [])
      let allocation_limit = if id == "semantic-retained-allocation-exact" {
        384UL
      } else {
        383UL
      }
      let limits = @budget.ResourceLimits::new(
        bytes=400UL,
        allocations=43UL,
        allocation_size=allocation_limit,
        width=0UL,
        height=0UL,
        pixels=0UL,
        depth=0UL,
        work=10UL,
      )
      let ancestor = @budget.Budget::new(limits)
      let caller = ancestor.child(limits).unwrap()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let result = type2_stage_all_glyphs(
        descriptors,
        global_subrs,
        1000UL,
        type2_vm_wb_limits(65535UL, 65535UL),
        caller,
        authority,
        authority.mutation_revision(),
      )
      let (error, publication) = match result {
        Ok(_) => (None, "staged-glyph")
        Err(error) => (Some(error), "none")
      }
      cff_qualification_emit_hostile_observation(
        id,
        error,
        "budget_charge",
        Some(384UL),
        Some(allocation_limit),
        Some(0UL),
        publication,
        caller_before,
        caller.remaining(),
        ancestor_before,
        ancestor.remaining(),
      )
    }
    _ => fail("unknown semantic hostile row: " + id)
  }
}

///|
fn cff_qualification_observe_resource_row(
  id : String,
) -> Unit raise {
  let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
  let (_owner, font) = cff_path_wb_owner_and_font([b"\x0e", cubic, b"\x0e"])
  let glyph = font.glyph_id(1UL).unwrap()
  let charge = font_wb_cff_cubic_path_charge()
  let (dimension, requested, exact) = match id {
    "outline-bytes-exact" => ("bytes", charge.bytes, true)
    "outline-bytes-one-short" => ("bytes", charge.bytes, false)
    "outline-allocations-exact" =>
      ("allocations", charge.allocations, true)
    "outline-allocations-one-short" =>
      ("allocations", charge.allocations, false)
    "outline-allocation-size-exact" =>
      ("allocation_size", charge.allocation_size, true)
    "outline-allocation-size-one-short" =>
      ("allocation_size", charge.allocation_size, false)
    "outline-work-exact" => ("work", charge.work, true)
    "outline-work-one-short" => ("work", charge.work, false)
    _ => fail("unknown outline resource hostile row: " + id)
  }
  let limit = if exact { requested } else { requested - 1UL }
  let limits = cff_path_wb_limits(
    if dimension == "bytes" { limit } else { charge.bytes },
    if dimension == "allocations" {
      limit
    } else {
      charge.allocations
    },
    if dimension == "allocation_size" {
      limit
    } else {
      charge.allocation_size
    },
    if dimension == "work" { limit } else { charge.work },
  )
  let ancestor = @budget.Budget::new(limits)
  let caller = ancestor.child(limits).unwrap()
  let caller_before = caller.remaining()
  let ancestor_before = ancestor.remaining()
  let result = font.outline(glyph, caller)
  let (error, publication) = match result {
    Ok(_) => (None, "path")
    Err(error) => (Some(error), "existing-font-only")
  }
  cff_qualification_emit_hostile_observation(
    id,
    error,
    "budget_charge",
    Some(requested),
    Some(limit),
    Some(1UL),
    publication,
    caller_before,
    caller.remaining(),
    ancestor_before,
    ancestor.remaining(),
  )
}

///|
fn cff_qualification_emit_admission_observation(
  id : String,
  result : Result[AdmittedCff1, @error.CoreError],
  gid : UInt64?,
  caller : @budget.Budget,
  caller_before : @budget.ResourceLimits,
  ancestor : @budget.Budget,
  ancestor_before : @budget.ResourceLimits,
) -> Unit {
  let (error, publication) = match result {
    Ok(_) => (None, "admitted-font")
    Err(error) => (Some(error), "none")
  }
  cff_qualification_emit_hostile_observation(
    id,
    error,
    "font-cff-admit",
    None,
    None,
    gid,
    publication,
    caller_before,
    caller.remaining(),
    ancestor_before,
    ancestor.remaining(),
  )
}

///|
fn cff_qualification_observe_mutation_row(
  id : String,
) -> Unit raise {
  match id {
    "mutation-admission-opening" => {
      let owner = font_wb_owner(cff_wb_otf(cff_wb_table()))
      let limits = cff_hostile_budget(1UL, 1UL, 1UL, 1UL).remaining()
      let ancestor = @budget.Budget::new(limits)
      let caller = ancestor.child(limits).unwrap()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let result = admit_cff1_structure_at_after_preflight(
        owner.view(),
        0UL,
        None,
        FontChecksumMode::Standalone,
        false,
        font_wb_limits(),
        caller,
        0UL,
        fn() { () },
        fn() { () },
        fn() { () },
        authoritative_opening_revision=owner.view().mutation_revision() + 1UL,
      )
      cff_qualification_emit_admission_observation(
        id,
        result,
        None,
        caller,
        caller_before,
        ancestor,
        ancestor_before,
      )
    }
    "mutation-selected-face" | "mutation-final-commit" => {
      let owner = font_wb_owner(
        cff_wb_otf(
          cff_wb_name_table_with_programs([b"\x0e", b"\x0e", b"\x0e"]),
          num_glyphs=3UL,
        ),
      )
      let (ancestor, caller) = cff_qualification_standard_hostile_budget()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let target_probe = if id == "mutation-selected-face" { 1 } else { 2 }
      let mut probes = 0
      let visited : Array[UInt64] = []
      let result = admit_cff1_structure_at_after_preflight_with_glyph_probe(
        owner.view(),
        0UL,
        None,
        FontChecksumMode::Standalone,
        false,
        font_wb_limits(),
        caller,
        0UL,
        fn() {
          probes = probes + 1
          if probes == target_probe {
            font_collection_wb_mutate_restore(owner, 0UL)
          }
        },
        fn() { () },
        fn() { () },
        fn(gid) { visited.push(gid) },
      )
      let observed_gid = if id == "mutation-final-commit" &&
        visited.length() > 0 {
        Some(visited[visited.length() - 1])
      } else {
        None
      }
      cff_qualification_emit_admission_observation(
        id,
        result,
        observed_gid,
        caller,
        caller_before,
        ancestor,
        ancestor_before,
      )
    }
    "mutation-type2-fetch" => {
      let owner = font_wb_owner(b"\xf7")
      let view = owner.view()
      let (ancestor, caller) = cff_qualification_standard_hostile_budget()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let empty_subrs = type2_vm_wb_empty_index(view)
      let descriptor : CffGlyphDescriptor = {
        gid: 0UL,
        key_value: 0UL,
        charstring: { offset: 0UL, length: view.length(), view },
        environment: {
          fd: None,
          private_dict: {
            local_subrs: None,
            default_width_x: cff_number_zero(),
            nominal_width_x: cff_number_zero(),
            initial_random_seed: type2_fixed_from_raw(0L).unwrap(),
            dict_units: 0UL,
          },
          local_subrs: empty_subrs,
          top_font_matrix: cff_default_font_matrix(),
          fd_font_matrix: None,
          font_matrix: cff_default_font_matrix(),
        },
      }
      let mut probes = 0
      let result = type2_stage_all_glyphs_with_probe(
        [descriptor],
        empty_subrs,
        1000UL,
        type2_vm_wb_limits(65535UL, 65535UL),
        caller,
        view,
        view.mutation_revision(),
        fn(_) { () },
        read_probe=fn() {
          probes = probes + 1
          if probes == 1 {
            font_collection_wb_mutate_restore(owner, 0UL)
          }
        },
      )
      let error = result.unwrap_err()
      cff_qualification_emit_hostile_observation(
        id,
        Some(error),
        "",
        None,
        None,
        Some(0UL),
        "none",
        caller_before,
        caller.remaining(),
        ancestor_before,
        ancestor.remaining(),
      )
    }
    "mutation-staged-path" => {
      let cubic = b"\xef\x95\x9f\x15\xa9\x8b\xb3\x95\xbd\x81\x08\x0e"
      let (owner, font) =
        cff_path_wb_owner_and_font([b"\x0e", cubic, b"\x0e"])
      let glyph = font.glyph_id(1UL).unwrap()
      let limits = cff_path_wb_exact_limits(font_wb_cff_cubic_path_charge())
      let ancestor = @budget.Budget::new(limits)
      let caller = ancestor.child(limits).unwrap()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let mut probes = 0
      let result = cff_decode_outline_atomic_with_probes(
        font.source,
        cff_path_wb_admitted(font),
        glyph.value(),
        font.limits,
        caller,
        fn() { () },
        fn() { () },
        vm_read_probe=fn() {
          probes = probes + 1
          if probes == 1 {
            font_collection_wb_mutate_restore(owner, 0UL)
          }
        },
      )
      let error = result.unwrap_err()
      cff_qualification_emit_hostile_observation(
        id,
        Some(error),
        "",
        None,
        None,
        Some(1UL),
        "existing-font-only",
        caller_before,
        caller.remaining(),
        ancestor_before,
        ancestor.remaining(),
      )
    }
    _ => fail("unknown mutation hostile row: " + id)
  }
}

///|
fn cff_qualification_observe_precedence_row(
  id : String,
) -> Unit raise {
  match id {
    "precedence-state-over-resource" => {
      let owner = font_wb_owner(cff_wb_otf(cff_wb_table()))
      let limits = cff_hostile_budget(1UL, 1UL, 1UL, 1UL).remaining()
      let ancestor = @budget.Budget::new(limits)
      let caller = ancestor.child(limits).unwrap()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let result = admit_cff1_structure_at_after_preflight(
        owner.view(),
        0UL,
        None,
        FontChecksumMode::Standalone,
        false,
        font_wb_limits(),
        caller,
        0UL,
        fn() { font_collection_wb_mutate_restore(owner, 0UL) },
        fn() { () },
        fn() { () },
      )
      cff_qualification_emit_admission_observation(
        id,
        result,
        None,
        caller,
        caller_before,
        ancestor,
        ancestor_before,
      )
    }
    "precedence-resource-over-data" => {
      let malformed = cff_wb_otf(b"\x01")
      let limits = cff_hostile_budget(
        malformed.length().to_uint64() - 1UL,
        32UL,
        4096UL,
        16384UL,
      ).remaining()
      let ancestor = @budget.Budget::new(limits)
      let caller = ancestor.child(limits).unwrap()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let result = admit_cff1_structure(
        font_wb_view(malformed),
        font_wb_limits(),
        caller,
        0UL,
      )
      cff_qualification_emit_admission_observation(
        id,
        result,
        None,
        caller,
        caller_before,
        ancestor,
        ancestor_before,
      )
    }
    "precedence-capability-over-data" => {
      let mixed = cff_wb_otf_tables([
        font_wb_table(b"CFF ", b"\x01"),
        font_wb_table(b"glyf", b""),
        font_wb_table(b"head", generated_head_table()),
        font_wb_table(b"loca", b""),
        font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
      ])
      let (ancestor, caller) = cff_qualification_standard_hostile_budget()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let result = admit_cff1_structure(
        font_wb_view(mixed),
        font_wb_limits(),
        caller,
        0UL,
      )
      cff_qualification_emit_admission_observation(
        id,
        result,
        None,
        caller,
        caller_before,
        ancestor,
        ancestor_before,
      )
    }
    "precedence-smallest-failing-gid" => {
      let source = cff_wb_otf(
        cff_wb_name_table_with_programs([b"\x0e", b"\x00", b"\x8b\x0e"]),
        num_glyphs=3UL,
      )
      let (ancestor, caller) = cff_qualification_standard_hostile_budget()
      let caller_before = caller.remaining()
      let ancestor_before = ancestor.remaining()
      let visited : Array[UInt64] = []
      let result = admit_cff1_structure_at_after_preflight_with_glyph_probe(
        font_wb_view(source),
        0UL,
        None,
        FontChecksumMode::Standalone,
        false,
        font_wb_limits(),
        caller,
        0UL,
        fn() { () },
        fn() { () },
        fn() { () },
        fn(gid) { visited.push(gid) },
      )
      let gid = if visited.length() > 0 {
        Some(visited[visited.length() - 1])
      } else {
        None
      }
      cff_qualification_emit_admission_observation(
        id,
        result,
        gid,
        caller,
        caller_before,
        ancestor,
        ancestor_before,
      )
    }
    _ => fail("unknown precedence hostile row: " + id)
  }
}

///|
test "font-cff1-v3 hostile row observation tracer" {
  for id in [
    "structural-header-one-short",
    "structural-name-index-one-short",
    "structural-top-index-one-short",
    "structural-string-index-one-short",
    "structural-global-subrs-one-short",
    "structural-charstrings-one-short",
    "structural-private-one-short",
    "structural-local-subrs-one-short",
    "structural-dict-arity",
    "structural-encoding-supplement",
    "structural-fd-select-fd",
    "structural-fd-select-sentinel",
    "structural-fd-private-range",
    "structural-font-matrix-arity",
    "structural-cid-charset",
    "structural-cid-encoding",
  ] {
    cff_qualification_observe_structural_row(id)
  }
  for id in [
    "type2-number-stack-arity",
    "type2-arithmetic-logical-storage",
    "type2-random-width-state",
    "type2-path-flex-geometry",
    "type2-stem-mask",
    "type2-subroutine-frame",
    "type2-operator-capability",
    "type2-termination",
  ] {
    cff_qualification_observe_type2_row(id)
  }
  for id in [
    "semantic-stack-48-exact",
    "semantic-stack-49-one-short",
    "semantic-stem-96-exact",
    "semantic-stem-97-one-short",
    "semantic-frame-depth-exact",
    "semantic-frame-depth-one-short",
    "semantic-outline-points-exact",
    "semantic-outline-points-one-short",
    "semantic-outline-contours-exact",
    "semantic-outline-contours-one-short",
    "semantic-retained-allocation-exact",
    "semantic-geometry-and-retained-arrays",
  ] {
    cff_qualification_observe_semantic_row(id)
  }
  for id in [
    "outline-bytes-exact",
    "outline-bytes-one-short",
    "outline-allocations-exact",
    "outline-allocations-one-short",
    "outline-allocation-size-exact",
    "outline-allocation-size-one-short",
    "outline-work-exact",
    "outline-work-one-short",
  ] {
    cff_qualification_observe_resource_row(id)
  }
  for id in [
    "mutation-admission-opening",
    "mutation-selected-face",
    "mutation-type2-fetch",
    "mutation-staged-path",
    "mutation-final-commit",
  ] {
    cff_qualification_observe_mutation_row(id)
  }
  for id in [
    "precedence-state-over-resource",
    "precedence-resource-over-data",
    "precedence-capability-over-data",
    "precedence-smallest-failing-gid",
  ] {
    cff_qualification_observe_precedence_row(id)
  }
}

///|
test "cff_structural_exact_and_one_short_cases" {
  let exact = cff_wb_table()
  let admitted = admit_cff1_structure(
    font_wb_view(cff_wb_otf(exact)),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap()
  inspect(admitted.charge.header_bytes, content="4")
  inspect(admitted.charge.index_offsets, content="6")
  inspect(admitted.charge.index_objects, content="3")
  inspect(admitted.charge.dict_units, content="7")
  inspect(admitted.charge.charset_entries, content="1")
  inspect(admitted.charge.encoding_entries, content="0")
  inspect(admitted.charge.fd_ranges, content="0")
  // StandardEncoding contains 149 nonzero SIDs; each is looked up against the
  // one-glyph ISOAdobe charset even though none is retained.
  inspect(admitted.charge.sid_cid_lookups, content="149")
  inspect(admitted.charge.descriptors, content="1")
  inspect(admitted.charge.fd_environments, content="1")
  let ceilings = cff_structural_limits(font_wb_limits()).unwrap()
  inspect(ceilings.max_index_entries > 0UL, content="true")
  inspect(ceilings.max_dict_units > 0UL, content="true")
  inspect(ceilings.max_charset_entries > 0UL, content="true")
  inspect(ceilings.max_encoding_entries > 0UL, content="true")
  inspect(ceilings.max_fd_ranges > 0UL, content="true")
  inspect(ceilings.max_sid_cid_lookups > 0UL, content="true")
  inspect(ceilings.max_retained_bytes > 0UL, content="true")

  // Header, Name, Top, String, Global Subrs, CharStrings, Private DICT,
  // and local Subrs exact/one-short boundaries.
  for
    item in [
      (3, "font-cff-header"),
      (12, "font-cff-name-index-terminal-extent"),
      (22, "font-cff-top-index-terminal-extent"),
      (24, "font-cff-string-index"),
      (26, "font-cff-global-subrs-index"),
      (32, "font-cff-charstrings-index-terminal-extent"),
      (34, "font-cff-private-range"),
      (36, "font-cff-local-subrs-index"),
    ] {
    cff_hostile_assert_atomic_error(
      Bytes::from_array(font_wb_bytes_array(exact)[0:item.0]),
      item.1,
    )
  }

  // Typed DICT operand/operator, charset, Encoding supplement, ROS, FDArray,
  // FDSelect 0/3, and final local-subroutine byte boundaries.
  cff_hostile_assert_atomic_error(
    cff_name_wb_table(encoding_mode=4UL)
    |> fn(bytes) {
      Bytes::from_array(font_wb_bytes_array(bytes)[0:bytes.length() - 1])
    },
    "font-cff-encoding-supplement",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(fd_select_format=3UL)
    |> fn(bytes) {
      Bytes::from_array(font_wb_bytes_array(bytes)[0:bytes.length() - 1])
    },
    "font-cff-local-subrs-index",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(ros_operands=0UL),
    "font-cff-top-dict-arity",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(fd_select_format=0UL, gid_two_fd=2UL),
    "font-cff-fd-select-fd",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(fd_select_format=3UL, fd_sentinel=2UL),
    "font-cff-fd-select-sentinel",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(invalid_unused_fd=true),
    "font-cff-fd-private-range",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(invalid_matrix=true),
    "font-cff-font-matrix-arity",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(predefined_charset=true),
    "font-cff-cid-charset",
    num_glyphs=3UL,
  )
  cff_hostile_assert_atomic_error(
    cff_cid_wb_table(include_encoding=true),
    "font-cff-cid-encoding",
    num_glyphs=3UL,
  )
}

///|
test "CFF all-glyph capability data and smallest-failing-GID outcomes are atomic" {
  cff_hostile_assert_program_error(
    [b"\x0e", b"\x8b\x8b\x8b\x8b\x0e", b"\x00"],
    @error.ErrorCategory::Capability,
    "font-cff-type2-seac",
  )
  cff_hostile_assert_program_error(
    [b"\x0e", b"\x0f", b"\x00"],
    @error.ErrorCategory::Capability,
    "font-cff-type2-cff2-operator",
  )
  cff_hostile_assert_program_error(
    [b"\x0e", b"\x8c\x8b\x0c\x0c\x0e", b"\x0f"],
    @error.ErrorCategory::Data,
    "font-cff-type2-division-by-zero",
  )
  cff_hostile_assert_program_error(
    [b"\x0e", b"\x00", b"\x8b\x8b\x8b\x8b\x0e"],
    @error.ErrorCategory::Data,
    "font-cff-type2-reserved-operator",
  )
}

///|
test "CFF structural work allocation and caller authority are exact or absent" {
  let source = cff_wb_otf(
    cff_cid_wb_table(fd_select_format=3UL),
    num_glyphs=3UL,
  )
  let admitted = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    cff_wb_budget(),
    2UL,
  ).unwrap()
  inspect(admitted.charge.fd_ranges, content="2")
  inspect(admitted.charge.sid_cid_lookups, content="4")
  inspect(admitted.charge.encoding_entries, content="0")
  inspect(admitted.charge.descriptors, content="3")
  inspect(admitted.charge.fd_environments, content="2")
  inspect(admitted.charge.work, content="1445")
  let exact = cff_hostile_budget(
    admitted.combined_charge.bytes,
    admitted.combined_charge.allocations,
    admitted.combined_charge.allocation_size,
    admitted.combined_charge.work,
  )
  admit_cff1_structure(font_wb_view(source), font_wb_limits(), exact, 2UL)
  |> ignore
  inspect(exact.remaining().bytes(), content="0")
  inspect(exact.remaining().allocations(), content="0")
  inspect(exact.remaining().work(), content="0")

  for dimension in [0, 1, 2, 3] {
    let budget = cff_hostile_budget(
      if dimension == 0 {
        admitted.combined_charge.bytes - 1UL
      } else {
        admitted.combined_charge.bytes
      },
      if dimension == 1 {
        admitted.combined_charge.allocations - 1UL
      } else {
        admitted.combined_charge.allocations
      },
      if dimension == 2 {
        admitted.combined_charge.allocation_size - 1UL
      } else {
        admitted.combined_charge.allocation_size
      },
      if dimension == 3 {
        admitted.combined_charge.work - 1UL
      } else {
        admitted.combined_charge.work
      },
    )
    let before = budget.remaining()
    let error = admit_cff1_structure(
      font_wb_view(source),
      font_wb_limits(),
      budget,
      2UL,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(budget.remaining().bytes() == before.bytes(), content="true")
    inspect(
      budget.remaining().allocations() == before.allocations(),
      content="true",
    )
    inspect(budget.remaining().work() == before.work(), content="true")
  }
}

///|
test "CFF format-4 common-table search work is exact and one-short atomic" {
  let source = cff_wb_otf_with_cmap(
    cff_wb_table(),
    cff_wb_cmap_format4_two_segments(),
  )
  let admitted = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap()
  inspect(admitted.charge.work, content="1467")

  let exact = cff_hostile_budget(
    admitted.combined_charge.bytes,
    admitted.combined_charge.allocations,
    admitted.combined_charge.allocation_size,
    admitted.combined_charge.work,
  )
  admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    exact,
    0UL,
  ) |> ignore
  inspect(exact.remaining().work(), content="0")

  let one_short = cff_hostile_budget(
    admitted.combined_charge.bytes,
    admitted.combined_charge.allocations,
    admitted.combined_charge.allocation_size,
    admitted.combined_charge.work - 1UL,
  )
  let before = one_short.remaining()
  let error = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    one_short,
    0UL,
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(error.context() == Some("work"), content="true")
  inspect(one_short.remaining().bytes() == before.bytes(), content="true")
  inspect(
    one_short.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(one_short.remaining().work() == before.work(), content="true")
}

///|
test "CFF caller work and allocation authority precede hostile keying traversal" {
  let source = cff_wb_otf(
    cff_cid_wb_table(invalid_unused_fd=true),
    num_glyphs=3UL,
  )
  for
    budget in [
      cff_hostile_budget(source.length().to_uint64(), 0UL, 16384UL, 16384UL),
      cff_hostile_budget(source.length().to_uint64(), 64UL, 16384UL, 0UL),
    ] {
    let before = budget.remaining()
    let error = admit_cff1_structure(
      font_wb_view(source),
      font_wb_limits(),
      budget,
      2UL,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(budget.remaining().bytes() == before.bytes(), content="true")
    inspect(
      budget.remaining().allocations() == before.allocations(),
      content="true",
    )
    inspect(budget.remaining().work() == before.work(), content="true")
  }

  let zero_work = cff_hostile_budget(
    source.length().to_uint64(),
    64UL,
    16384UL,
    0UL,
  )
  let mut common_traversals = 0
  let error = admit_cff1_structure_at_after_preflight(
    font_wb_view(source),
    0UL,
    None,
    FontChecksumMode::Standalone,
    false,
    font_wb_limits(),
    zero_work,
    2UL,
    fn() { () },
    fn() { common_traversals = common_traversals + 1 },
    fn() { () },
  ).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(common_traversals, content="0")
}

///|
test "CFF multi-fault precedence is state resource capability then data" {
  let malformed = cff_wb_otf(b"\x01")
  let resource_budget = cff_hostile_budget(
    malformed.length().to_uint64() - 1UL,
    32UL,
    4096UL,
    16384UL,
  )
  let resource_error = admit_cff1_structure(
    font_wb_view(malformed),
    font_wb_limits(),
    resource_budget,
    0UL,
  ).unwrap_err()
  inspect(
    resource_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(resource_error.context() == Some("bytes"), content="true")

  let mixed = cff_wb_otf_tables([
    font_wb_table(b"CFF ", b"\x01"),
    font_wb_table(b"glyf", b""),
    font_wb_table(b"head", generated_head_table()),
    font_wb_table(b"loca", b""),
    font_wb_table(b"maxp", cff_wb_maxp_table(1UL)),
  ])
  let capability_error = admit_cff1_structure(
    font_wb_view(mixed),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap_err()
  inspect(
    capability_error.category() == @error.ErrorCategory::Capability,
    content="true",
  )
  inspect(
    capability_error.context() == Some("font-cff-profile"),
    content="true",
  )

  let owner = font_wb_owner(cff_wb_otf(cff_wb_table()))
  let too_short = cff_hostile_budget(1UL, 1UL, 1UL, 1UL)
  let before = too_short.remaining()
  let state_error = admit_cff1_structure_at_after_preflight(
    owner.view(),
    0UL,
    None,
    FontChecksumMode::Standalone,
    false,
    font_wb_limits(),
    too_short,
    0UL,
    fn() { font_collection_wb_mutate_restore(owner, 0UL) },
    fn() { () },
    fn() { () },
  ).unwrap_err()
  inspect(state_error.category() == @error.ErrorCategory::State, content="true")
  inspect(
    state_error.context() == Some("font-cff-source-revision-drift"),
    content="true",
  )
  inspect(too_short.remaining().bytes() == before.bytes(), content="true")
  inspect(too_short.remaining().work() == before.work(), content="true")
}

///|
fn cff_qualification_assert_private_hostile_outcomes() -> Unit raise {
  let structural = [
    "structural-header-one-short",
    "structural-name-index-one-short",
    "structural-top-index-one-short",
    "structural-string-index-one-short",
    "structural-global-subrs-one-short",
    "structural-charstrings-one-short",
    "structural-private-one-short",
    "structural-local-subrs-one-short",
    "structural-dict-arity",
    "structural-encoding-supplement",
    "structural-fd-select-fd",
    "structural-fd-select-sentinel",
    "structural-fd-private-range",
    "structural-font-matrix-arity",
    "structural-cid-charset",
    "structural-cid-encoding",
  ]
  let type2 = [
    "type2-number-stack-arity",
    "type2-arithmetic-logical-storage",
    "type2-random-width-state",
    "type2-path-flex-geometry",
    "type2-stem-mask",
    "type2-subroutine-frame",
    "type2-operator-capability",
    "type2-termination",
  ]
  let semantic = [
    "semantic-stack-48-exact",
    "semantic-stack-49-one-short",
    "semantic-stem-96-exact",
    "semantic-stem-97-one-short",
    "semantic-frame-depth-exact",
    "semantic-frame-depth-one-short",
    "semantic-outline-points-exact",
    "semantic-outline-points-one-short",
    "semantic-outline-contours-exact",
    "semantic-outline-contours-one-short",
    "semantic-retained-allocation-exact",
    "semantic-geometry-and-retained-arrays",
  ]
  let resource = [
    "outline-bytes-exact",
    "outline-bytes-one-short",
    "outline-allocations-exact",
    "outline-allocations-one-short",
    "outline-allocation-size-exact",
    "outline-allocation-size-one-short",
    "outline-work-exact",
    "outline-work-one-short",
  ]
  let mutation = [
    "mutation-admission-opening",
    "mutation-selected-face",
    "mutation-type2-fetch",
    "mutation-staged-path",
    "mutation-final-commit",
  ]
  let precedence = [
    "precedence-state-over-resource",
    "precedence-resource-over-data",
    "precedence-capability-over-data",
    "precedence-smallest-failing-gid",
  ]
  inspect(structural.length() == 16, content="true")
  inspect(type2.length() == 8, content="true")
  inspect(semantic.length() == 12, content="true")
  inspect(resource.length() == 8, content="true")
  inspect(mutation.length() == 5, content="true")
  inspect(precedence.length() == 4, content="true")
  inspect(
    structural.length() +
    type2.length() +
    semantic.length() +
    resource.length() +
    mutation.length() +
    precedence.length() ==
    53,
    content="true",
  )

  let exact = cff_wb_table()
  for item in [
    (3, "font-cff-header"),
    (12, "font-cff-name-index-terminal-extent"),
    (22, "font-cff-top-index-terminal-extent"),
    (24, "font-cff-string-index"),
    (26, "font-cff-global-subrs-index"),
    (32, "font-cff-charstrings-index-terminal-extent"),
    (34, "font-cff-private-range"),
    (36, "font-cff-local-subrs-index"),
  ] {
    cff_hostile_assert_atomic_error(
      Bytes::from_array(font_wb_bytes_array(exact)[0:item.0]),
      item.1,
    )
  }
  cff_hostile_assert_program_error(
    [b"\x0e", b"\x8b\x8b\x8b\x8b\x0e", b"\x00"],
    @error.ErrorCategory::Capability,
    "font-cff-type2-seac",
  )
  cff_hostile_assert_program_error(
    [b"\x0e", b"\x8c\x8b\x0c\x0c\x0e", b"\x0f"],
    @error.ErrorCategory::Data,
    "font-cff-type2-division-by-zero",
  )

  let source = cff_wb_otf(
    cff_cid_wb_table(fd_select_format=3UL),
    num_glyphs=3UL,
  )
  let admitted = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    cff_wb_budget(),
    2UL,
  ).unwrap()
  inspect(admitted.charge.work == 1445UL, content="true")
  let one_short = cff_hostile_budget(
    admitted.combined_charge.bytes,
    admitted.combined_charge.allocations,
    admitted.combined_charge.allocation_size,
    admitted.combined_charge.work - 1UL,
  )
  let before = one_short.remaining()
  let resource_error = admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    one_short,
    2UL,
  ).unwrap_err()
  inspect(
    resource_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(resource_error.context() == Some("work"), content="true")
  inspect(one_short.remaining().bytes() == before.bytes(), content="true")
  inspect(one_short.remaining().work() == before.work(), content="true")
}

///|
fn cff_qualification_assert_private_mutation_windows() -> Unit raise {
  let window_ids = [
    "mutation-admission-opening",
    "mutation-selected-face",
    "mutation-type2-fetch",
    "mutation-staged-path",
    "mutation-final-commit",
  ]
  inspect(window_ids.length() == 5, content="true")
  let b8 = [
    "bytes",
    "allocations",
    "allocation_size",
    "width",
    "height",
    "pixels",
    "depth",
    "work",
  ]
  inspect(b8.length() == 8, content="true")

  let owner = font_wb_owner(cff_wb_otf(cff_wb_table()))
  let budget = cff_hostile_budget(1UL, 1UL, 1UL, 1UL)
  let before = budget.remaining()
  let mut callbacks = 0
  let state = admit_cff1_structure_at_after_preflight(
    owner.view(),
    0UL,
    None,
    FontChecksumMode::Standalone,
    false,
    font_wb_limits(),
    budget,
    0UL,
    fn() {
      callbacks = callbacks + 1
      font_collection_wb_mutate_restore(owner, 0UL)
    },
    fn() { () },
    fn() { () },
  ).unwrap_err()
  inspect(callbacks == 1, content="true")
  inspect(state.category() == @error.ErrorCategory::State, content="true")
  inspect(state.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(state.operation() == Some("font-cff-admit"), content="true")
  inspect(
    state.context() == Some("font-cff-source-revision-drift"),
    content="true",
  )
  inspect(budget.remaining().bytes() == before.bytes(), content="true")
  inspect(
    budget.remaining().allocations() == before.allocations(),
    content="true",
  )
  inspect(
    budget.remaining().allocation_size() == before.allocation_size(),
    content="true",
  )
  inspect(budget.remaining().width() == before.width(), content="true")
  inspect(budget.remaining().height() == before.height(), content="true")
  inspect(budget.remaining().pixels() == before.pixels(), content="true")
  inspect(budget.remaining().depth() == before.depth(), content="true")
  inspect(budget.remaining().work() == before.work(), content="true")
}

///|
test "font-cff1-v3 private hostile outcomes" {
  cff_qualification_assert_private_hostile_outcomes()
}

///|
test "font-cff1-v3 private mutation windows and atomic budgets" {
  cff_qualification_assert_private_mutation_windows()
}

// font-cff1-v3 private hostile:begin
// hostile {"group":"structural","row":{"id":"structural-header-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":4,"limit":3},"context":"font-cff-header","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"source-bytes","applicable":false,"reason":"truncated CFF framing is Data, not an adjustable resource ceiling"}}}
// hostile {"group":"structural","row":{"id":"structural-name-index-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":4,"limit":12},"context":"font-cff-name-index-terminal-extent","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"Name INDEX terminal extent is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-top-index-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":5,"limit":22},"context":"font-cff-top-index-terminal-extent","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"Top INDEX terminal extent is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-string-index-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":24},"context":"font-cff-string-index","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"String INDEX framing is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-global-subrs-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":26},"context":"font-cff-global-subrs-index","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"Global Subrs INDEX framing is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-charstrings-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":1,"limit":32},"context":"font-cff-charstrings-index-terminal-extent","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"CharStrings INDEX terminal extent is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-private-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":34},"context":"font-cff-private-range","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"private-framing","applicable":false,"reason":"Private DICT byte truncation is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-local-subrs-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":36},"context":"font-cff-local-subrs-index","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"private-framing","applicable":false,"reason":"local Subrs INDEX truncation is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-dict-arity","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-top-dict-arity","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"dict-arity","applicable":false,"reason":"typed DICT cardinality is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-encoding-supplement","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":3,"limit":86},"context":"font-cff-encoding-supplement","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"encoding-framing","applicable":false,"reason":"Encoding supplement truncation is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-fd-select-fd","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":2},"context":"font-cff-fd-select-fd","gid":2,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fdselect","applicable":false,"reason":"FDSelect FD index range is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-fd-select-sentinel","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":3},"context":"font-cff-fd-select-sentinel","gid":2,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fdselect","applicable":false,"reason":"FDSelect format-3 sentinel is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-fd-private-range","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":151},"context":"font-cff-fd-private-range","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fdarray","applicable":false,"reason":"every FD Private range is checked as structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-font-matrix-arity","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":5,"limit":6},"context":"font-cff-font-matrix-arity","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"font-matrix","applicable":false,"reason":"FontMatrix arity is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-cid-charset","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-cid-charset","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"cid-charset","applicable":false,"reason":"CID fonts require a non-predefined charset"}}}
// hostile {"group":"structural","row":{"id":"structural-cid-encoding","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1222:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-cid-encoding","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"cid-encoding","applicable":false,"reason":"CID fonts cannot carry a name-keyed Encoding"}}}
// hostile {"group":"type2-program","row":{"id":"type2-number-stack-arity","source":"modules/mb-font/font/cff_type2_wbtest.mbt:126:Type 2 operators reject arity type and numeric faults","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-stack-underflow","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"operand-framing","applicable":false,"reason":"number stack underflow and operator arity faults are malformed program Data"}}}
// hostile {"group":"type2-program","row":{"id":"type2-arithmetic-logical-storage","source":"modules/mb-font/font/cff_type2_wbtest.mbt:83:Type 2 scalar operators execute exact stack semantics","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-division-by-zero","gid":1,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"numeric-semantics","applicable":false,"reason":"arithmetic logical storage and transient semantic faults are Data"}}}
// hostile {"group":"type2-program","row":{"id":"type2-random-width-state","source":"modules/mb-font/font/cff_type2_wbtest.mbt:191:Type 2 width is accepted only in the first legal width position","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-moveto-arity","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"width-position","applicable":false,"reason":"random/transient rollback and duplicate width are Data invariants"}}}
// hostile {"group":"type2-program","row":{"id":"type2-path-flex-geometry","source":"modules/mb-font/font/cff_type2_bounds_wbtest.mbt:107:Type 2 every ordinary path operator rejects invalid residual arity","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-geometry-arity","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"path-arity","applicable":false,"reason":"moveto line curve flex and contour ordering faults are Data"}}}
// hostile {"group":"type2-program","row":{"id":"type2-stem-mask","source":"modules/mb-font/font/cff_type2_wbtest.mbt:284:Type 2 stem ceiling accepts 96 and rejects 97 before clearing operands","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":97,"limit":96},"context":"font-cff-type2-stems","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"stem-limit","kind":"covered-by","dimension":"stems","applicable":true,"reason":"the adjacent exact and one-short pair is owned by semantic-limit"}}}
// hostile {"group":"type2-program","row":{"id":"type2-subroutine-frame","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:79:Type 2 invalid subr and recursive frame exhaustion are deterministic","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":11,"limit":10},"context":"font-cff-type2-frame-depth","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"frame-depth","kind":"covered-by","dimension":"depth","applicable":true,"reason":"the adjacent exact and one-short pair is owned by semantic-limit"}}}
// hostile {"group":"type2-program","row":{"id":"type2-operator-capability","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:224:Type 2 capability and reserved operator classes are closed","category":"Capability","code":"CapabilityUnavailable","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-seac","gid":1,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"operator-profile","applicable":false,"reason":"recognized seac and CFF2 operators are Capability; reserved operators are Data"}}}
// hostile {"group":"type2-program","row":{"id":"type2-termination","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:164:Type 2 endchar terminates root and only an all-tail subroutine chain","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-non-tail-endchar","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"termination-framing","applicable":false,"reason":"root return trailing bytes and non-tail endchar are Data"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-stack-48-exact","source":"modules/mb-font/font/cff_type2_wbtest.mbt:162:Type 2 stack accepts 48 values and rejects the 49th before mutation","category":null,"code":null,"operation":"font-cff-type2","payload":{"requested":48,"limit":48},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"operand-stack","kind":"exact","dimension":"stack","applicable":true,"reason":"max_stack is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-stack-49-one-short","source":"modules/mb-font/font/cff_type2_wbtest.mbt:162:Type 2 stack accepts 48 values and rejects the 49th before mutation","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":49,"limit":48},"context":"font-cff-type2-operand-stack","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"operand-stack","kind":"one-short","dimension":"stack","applicable":true,"reason":"max_stack is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-stem-96-exact","source":"modules/mb-font/font/cff_type2_wbtest.mbt:284:Type 2 stem ceiling accepts 96 and rejects 97 before clearing operands","category":null,"code":null,"operation":"font-cff-type2","payload":{"requested":96,"limit":96},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"stem-limit","kind":"exact","dimension":"stems","applicable":true,"reason":"max_stems is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-stem-97-one-short","source":"modules/mb-font/font/cff_type2_wbtest.mbt:284:Type 2 stem ceiling accepts 96 and rejects 97 before clearing operands","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":97,"limit":96},"context":"font-cff-type2-stems","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"stem-limit","kind":"one-short","dimension":"stems","applicable":true,"reason":"max_stems is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-frame-depth-exact","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:106:Type 2 frame scratch exactly covers the legal depth ceiling","category":null,"code":null,"operation":"font-cff-type2","payload":{"requested":10,"limit":10},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"frame-depth","kind":"exact","dimension":"depth","applicable":true,"reason":"max_subr_depth is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-frame-depth-one-short","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:79:Type 2 invalid subr and recursive frame exhaustion are deterministic","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":11,"limit":10},"context":"font-cff-type2-frame-depth","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"frame-depth","kind":"one-short","dimension":"depth","applicable":true,"reason":"max_subr_depth is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-outline-points-exact","source":"modules/mb-font/font/cff_type2_bounds_wbtest.mbt:131:Type 2 moveto and endchar close contours with exact geometry limits","category":null,"code":null,"operation":"font-cff-type2","payload":{"requested":2,"limit":2},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"outline-points","kind":"exact","dimension":"points","applicable":true,"reason":"max_outline_points is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-outline-points-one-short","source":"modules/mb-font/font/cff_type2_bounds_wbtest.mbt:131:Type 2 moveto and endchar close contours with exact geometry limits","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":2,"limit":1},"context":"font-cff-type2-points","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"outline-points","kind":"one-short","dimension":"points","applicable":true,"reason":"max_outline_points is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-outline-contours-exact","source":"modules/mb-font/font/cff_type2_bounds_wbtest.mbt:131:Type 2 moveto and endchar close contours with exact geometry limits","category":null,"code":null,"operation":"font-cff-type2","payload":{"requested":2,"limit":2},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"outline-contours","kind":"exact","dimension":"contours","applicable":true,"reason":"max_outline_contours is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-outline-contours-one-short","source":"modules/mb-font/font/cff_type2_bounds_wbtest.mbt:131:Type 2 moveto and endchar close contours with exact geometry limits","category":"Resource","code":"BudgetExceeded","operation":"font-cff-type2","payload":{"requested":2,"limit":1},"context":"font-cff-type2-contours","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":"outline-contours","kind":"one-short","dimension":"contours","applicable":true,"reason":"max_outline_contours is independently adjustable"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-retained-allocation-exact","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:479:Type 2 retained arrays use the maximum single allocation","category":null,"code":null,"operation":"budget_charge","payload":{"requested":384,"limit":384},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[400,43,384,0,0,0,0,10],"caller_after":[400,43,384,0,0,0,0,10],"ancestor_before":[400,43,384,0,0,0,0,10],"ancestor_after":[400,43,384,0,0,0,0,10],"boundary":{"pair_id":"retained-allocation","kind":"exact","dimension":"allocation_size","applicable":true,"reason":"retained bounds/path arrays use an independently adjustable maximum allocation"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-geometry-and-retained-arrays","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:479:Type 2 retained arrays use the maximum single allocation","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":384,"limit":383},"context":"allocation_size","gid":0,"publication":"none","caller_before":[400,43,383,0,0,0,0,10],"caller_after":[400,43,383,0,0,0,0,10],"ancestor_before":[400,43,383,0,0,0,0,10],"ancestor_after":[400,43,383,0,0,0,0,10],"boundary":{"pair_id":"retained-allocation","kind":"one-short","dimension":"allocation_size","applicable":true,"reason":"retained bounds/path arrays use an independently adjustable maximum allocation"}}}
// hostile {"group":"resource","row":{"id":"outline-bytes-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":192,"limit":192},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-bytes","kind":"exact","dimension":"bytes","applicable":true,"reason":"caller and ancestor bytes ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-bytes-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:290:CFF outline exact path charge rejects each one-short window atomically","category":"Resource","code":"BudgetExceeded","operation":"font-outline","payload":{"requested":192,"limit":191},"context":"bytes","gid":1,"publication":"existing-font-only","caller_before":[191,5,384,0,0,0,0,19],"caller_after":[191,5,384,0,0,0,0,19],"ancestor_before":[191,5,384,0,0,0,0,19],"ancestor_after":[191,5,384,0,0,0,0,19],"boundary":{"pair_id":"outline-bytes","kind":"one-short","dimension":"bytes","applicable":true,"reason":"caller and ancestor bytes ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocations-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":5,"limit":5},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-allocations","kind":"exact","dimension":"allocations","applicable":true,"reason":"caller and ancestor allocation counts are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocations-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:290:CFF outline exact path charge rejects each one-short window atomically","category":"Resource","code":"BudgetExceeded","operation":"font-outline","payload":{"requested":5,"limit":4},"context":"allocations","gid":1,"publication":"existing-font-only","caller_before":[192,4,384,0,0,0,0,19],"caller_after":[192,4,384,0,0,0,0,19],"ancestor_before":[192,4,384,0,0,0,0,19],"ancestor_after":[192,4,384,0,0,0,0,19],"boundary":{"pair_id":"outline-allocations","kind":"one-short","dimension":"allocations","applicable":true,"reason":"caller and ancestor allocation counts are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocation-size-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":384,"limit":384},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-allocation-size","kind":"exact","dimension":"allocation_size","applicable":true,"reason":"caller and ancestor allocation-size ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocation-size-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:290:CFF outline exact path charge rejects each one-short window atomically","category":"Resource","code":"BudgetExceeded","operation":"font-outline","payload":{"requested":384,"limit":383},"context":"allocation_size","gid":1,"publication":"existing-font-only","caller_before":[192,5,383,0,0,0,0,19],"caller_after":[192,5,383,0,0,0,0,19],"ancestor_before":[192,5,383,0,0,0,0,19],"ancestor_after":[192,5,383,0,0,0,0,19],"boundary":{"pair_id":"outline-allocation-size","kind":"one-short","dimension":"allocation_size","applicable":true,"reason":"caller and ancestor allocation-size ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-work-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":19,"limit":19},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-work","kind":"exact","dimension":"work","applicable":true,"reason":"caller and ancestor work ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-work-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:350:CFF outline work preflight prevents caller and ancestor VM execution","category":"Resource","code":"BudgetExceeded","operation":"font-outline","payload":{"requested":19,"limit":18},"context":"work","gid":1,"publication":"existing-font-only","caller_before":[192,5,384,0,0,0,0,18],"caller_after":[192,5,384,0,0,0,0,18],"ancestor_before":[192,5,384,0,0,0,0,18],"ancestor_after":[192,5,384,0,0,0,0,18],"boundary":{"pair_id":"outline-work","kind":"one-short","dimension":"work","applicable":true,"reason":"caller and ancestor work ceilings are independently adjustable"}}}
// hostile {"group":"mutation","row":{"id":"mutation-admission-opening","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1522:CFF multi-fault precedence is state resource capability then data","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":null,"publication":"none","caller_before":[1,1,1,0,0,0,0,1],"caller_after":[1,1,1,0,0,0,0,1],"ancestor_before":[1,1,1,0,0,0,0,1],"ancestor_after":[1,1,1,0,0,0,0,1],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"revision","applicable":false,"reason":"revision drift is State authority, not Resource"}}}
// hostile {"group":"mutation","row":{"id":"mutation-selected-face","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:542:Type 2 all-GID staging is ascending, exact, and does not commit budget","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"selected-face-revision","applicable":false,"reason":"selected-face root authority drift is State"}}}
// hostile {"group":"mutation","row":{"id":"mutation-type2-fetch","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:286:Type 2 mid-fetch mutation wins truncated number and escape errors","category":"State","code":"InvalidRange","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-source-revision-drift","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fetch-revision","applicable":false,"reason":"mid-fetch mutation has State precedence"}}}
// hostile {"group":"mutation","row":{"id":"mutation-staged-path","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:508:CFF outline atomic mid-fetch mutation publishes no staged path","category":"State","code":"InvalidRange","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-source-revision-drift","gid":1,"publication":"existing-font-only","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[192,5,384,0,0,0,0,19],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[192,5,384,0,0,0,0,19],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"staged-path-revision","applicable":false,"reason":"staged path is discarded on State drift"}}}
// hostile {"group":"mutation","row":{"id":"mutation-final-commit","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:542:Type 2 all-GID staging is ascending, exact, and does not commit budget","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":2,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"commit-revision","applicable":false,"reason":"final revision guard precedes atomic commit"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-state-over-resource","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1522:CFF multi-fault precedence is state resource capability then data","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":null,"publication":"none","caller_before":[1,1,1,0,0,0,0,1],"caller_after":[1,1,1,0,0,0,0,1],"ancestor_before":[1,1,1,0,0,0,0,1],"ancestor_after":[1,1,1,0,0,0,0,1],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"precedence","applicable":false,"reason":"State wins before Resource Capability and Data"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-resource-over-data","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1522:CFF multi-fault precedence is state resource capability then data","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":420,"limit":419},"context":"bytes","gid":null,"publication":"none","caller_before":[419,32,4096,0,0,0,0,16384],"caller_after":[419,32,4096,0,0,0,0,16384],"ancestor_before":[419,32,4096,0,0,0,0,16384],"ancestor_after":[419,32,4096,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"precedence","applicable":false,"reason":"Resource preflight wins malformed header Data"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-capability-over-data","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1522:CFF multi-fault precedence is state resource capability then data","category":"Capability","code":"CapabilityUnavailable","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-profile","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"precedence","applicable":false,"reason":"recognized mixed profile Capability wins malformed CFF Data"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-smallest-failing-gid","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:1326:CFF all-glyph capability data and smallest-failing-GID outcomes are atomic","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-reserved-operator","gid":1,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"gid-order","applicable":false,"reason":"ascending validation reports the smallest failing GID literally"}}}
// font-cff1-v3 private hostile:end
