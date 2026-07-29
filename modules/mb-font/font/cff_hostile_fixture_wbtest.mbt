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
// hostile {"group":"structural","row":{"id":"structural-header-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":4,"limit":3},"context":"font-cff-header","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"source-bytes","applicable":false,"reason":"truncated CFF framing is Data, not an adjustable resource ceiling"}}}
// hostile {"group":"structural","row":{"id":"structural-name-index-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-name-index-terminal-extent","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"Name INDEX terminal extent is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-top-index-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-top-index-terminal-extent","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"Top INDEX terminal extent is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-string-index-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-string-index","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"String INDEX framing is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-global-subrs-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-global-subrs-index","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"Global Subrs INDEX framing is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-charstrings-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-charstrings-index-terminal-extent","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"index-framing","applicable":false,"reason":"CharStrings INDEX terminal extent is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-private-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-private-range","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"private-framing","applicable":false,"reason":"Private DICT byte truncation is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-local-subrs-one-short","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-local-subrs-index","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"private-framing","applicable":false,"reason":"local Subrs INDEX truncation is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-dict-arity","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":3,"limit":0},"context":"font-cff-top-dict-arity","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"dict-arity","applicable":false,"reason":"typed DICT cardinality is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-encoding-supplement","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-encoding-supplement","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"encoding-framing","applicable":false,"reason":"Encoding supplement truncation is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-fd-select-fd","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":2,"limit":1},"context":"font-cff-fd-select-fd","gid":2,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fdselect","applicable":false,"reason":"FDSelect FD index range is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-fd-select-sentinel","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":3,"limit":2},"context":"font-cff-fd-select-sentinel","gid":2,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fdselect","applicable":false,"reason":"FDSelect format-3 sentinel is structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-fd-private-range","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-fd-private-range","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fdarray","applicable":false,"reason":"every FD Private range is checked as structural Data"}}}
// hostile {"group":"structural","row":{"id":"structural-font-matrix-arity","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":6,"limit":5},"context":"font-cff-font-matrix-arity","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"font-matrix","applicable":false,"reason":"FontMatrix arity is Data"}}}
// hostile {"group":"structural","row":{"id":"structural-cid-charset","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-cid-charset","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"cid-charset","applicable":false,"reason":"CID fonts require a non-predefined charset"}}}
// hostile {"group":"structural","row":{"id":"structural-cid-encoding","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:77:cff_structural_exact_and_one_short_cases","category":"Data","code":"InvalidEncoding","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-cid-encoding","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"cid-encoding","applicable":false,"reason":"CID fonts cannot carry a name-keyed Encoding"}}}
// hostile {"group":"type2-program","row":{"id":"type2-number-stack-arity","source":"modules/mb-font/font/cff_type2_wbtest.mbt:126:Type 2 operators reject arity type and numeric faults","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-stack-underflow","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"operand-framing","applicable":false,"reason":"number stack underflow and operator arity faults are malformed program Data"}}}
// hostile {"group":"type2-program","row":{"id":"type2-arithmetic-logical-storage","source":"modules/mb-font/font/cff_type2_wbtest.mbt:83:Type 2 scalar operators execute exact stack semantics","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":0,"limit":0},"context":"font-cff-type2-division-by-zero","gid":1,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"numeric-semantics","applicable":false,"reason":"arithmetic logical storage and transient semantic faults are Data"}}}
// hostile {"group":"type2-program","row":{"id":"type2-random-width-state","source":"modules/mb-font/font/cff_type2_wbtest.mbt:191:Type 2 width is accepted only in the first legal width position","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-width-duplicate","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"width-position","applicable":false,"reason":"random/transient rollback and duplicate width are Data invariants"}}}
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
// hostile {"group":"semantic-limit","row":{"id":"semantic-retained-allocation-exact","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:479:Type 2 retained arrays use the maximum single allocation","category":null,"code":null,"operation":"budget_charge","payload":{"requested":384,"limit":384},"context":null,"gid":0,"publication":"staged-glyph","caller_before":[400,43,384,0,0,0,0,10],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[400,43,384,0,0,0,0,10],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"retained-allocation","kind":"exact","dimension":"allocation_size","applicable":true,"reason":"retained bounds/path arrays use an independently adjustable maximum allocation"}}}
// hostile {"group":"semantic-limit","row":{"id":"semantic-geometry-and-retained-arrays","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:479:Type 2 retained arrays use the maximum single allocation","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":384,"limit":383},"context":"allocation_size","gid":0,"publication":"none","caller_before":[400,43,383,0,0,0,0,10],"caller_after":[400,43,383,0,0,0,0,10],"ancestor_before":[400,43,383,0,0,0,0,10],"ancestor_after":[400,43,383,0,0,0,0,10],"boundary":{"pair_id":"retained-allocation","kind":"one-short","dimension":"allocation_size","applicable":true,"reason":"retained bounds/path arrays use an independently adjustable maximum allocation"}}}
// hostile {"group":"resource","row":{"id":"outline-bytes-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":192,"limit":192},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-bytes","kind":"exact","dimension":"bytes","applicable":true,"reason":"caller and ancestor bytes ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-bytes-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:290:CFF outline exact path charge rejects each one-short window atomically","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":192,"limit":191},"context":"bytes","gid":1,"publication":"existing-font-only","caller_before":[191,5,384,0,0,0,0,19],"caller_after":[191,5,384,0,0,0,0,19],"ancestor_before":[191,5,384,0,0,0,0,19],"ancestor_after":[191,5,384,0,0,0,0,19],"boundary":{"pair_id":"outline-bytes","kind":"one-short","dimension":"bytes","applicable":true,"reason":"caller and ancestor bytes ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocations-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":5,"limit":5},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-allocations","kind":"exact","dimension":"allocations","applicable":true,"reason":"caller and ancestor allocation counts are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocations-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:290:CFF outline exact path charge rejects each one-short window atomically","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":5,"limit":4},"context":"allocations","gid":1,"publication":"existing-font-only","caller_before":[192,4,384,0,0,0,0,19],"caller_after":[192,4,384,0,0,0,0,19],"ancestor_before":[192,4,384,0,0,0,0,19],"ancestor_after":[192,4,384,0,0,0,0,19],"boundary":{"pair_id":"outline-allocations","kind":"one-short","dimension":"allocations","applicable":true,"reason":"caller and ancestor allocation counts are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocation-size-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":384,"limit":384},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-allocation-size","kind":"exact","dimension":"allocation_size","applicable":true,"reason":"caller and ancestor allocation-size ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-allocation-size-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:290:CFF outline exact path charge rejects each one-short window atomically","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":384,"limit":383},"context":"allocation_size","gid":1,"publication":"existing-font-only","caller_before":[192,5,383,0,0,0,0,19],"caller_after":[192,5,383,0,0,0,0,19],"ancestor_before":[192,5,383,0,0,0,0,19],"ancestor_after":[192,5,383,0,0,0,0,19],"boundary":{"pair_id":"outline-allocation-size","kind":"one-short","dimension":"allocation_size","applicable":true,"reason":"caller and ancestor allocation-size ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-work-exact","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:246:CFF outline exact path charge covers caller and ancestor dimensions","category":null,"code":null,"operation":"budget_charge","payload":{"requested":19,"limit":19},"context":null,"gid":1,"publication":"path","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[0,0,384,0,0,0,0,0],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[0,0,384,0,0,0,0,0],"boundary":{"pair_id":"outline-work","kind":"exact","dimension":"work","applicable":true,"reason":"caller and ancestor work ceilings are independently adjustable"}}}
// hostile {"group":"resource","row":{"id":"outline-work-one-short","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:350:CFF outline work preflight prevents caller and ancestor VM execution","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":19,"limit":18},"context":"work","gid":1,"publication":"existing-font-only","caller_before":[192,5,384,0,0,0,0,18],"caller_after":[192,5,384,0,0,0,0,18],"ancestor_before":[192,5,384,0,0,0,0,18],"ancestor_after":[192,5,384,0,0,0,0,18],"boundary":{"pair_id":"outline-work","kind":"one-short","dimension":"work","applicable":true,"reason":"caller and ancestor work ceilings are independently adjustable"}}}
// hostile {"group":"mutation","row":{"id":"mutation-admission-opening","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:377:CFF multi-fault precedence is state resource capability then data","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":null,"publication":"none","caller_before":[1,1,1,0,0,0,0,1],"caller_after":[1,1,1,0,0,0,0,1],"ancestor_before":[1,1,1,0,0,0,0,1],"ancestor_after":[1,1,1,0,0,0,0,1],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"revision","applicable":false,"reason":"revision drift is State authority, not Resource"}}}
// hostile {"group":"mutation","row":{"id":"mutation-selected-face","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:542:Type 2 all-GID staging is ascending, exact, and does not commit budget","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"selected-face-revision","applicable":false,"reason":"selected-face root authority drift is State"}}}
// hostile {"group":"mutation","row":{"id":"mutation-type2-fetch","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:286:Type 2 mid-fetch mutation wins truncated number and escape errors","category":"State","code":"InvalidRange","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-source-revision-drift","gid":0,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"fetch-revision","applicable":false,"reason":"mid-fetch mutation has State precedence"}}}
// hostile {"group":"mutation","row":{"id":"mutation-staged-path","source":"modules/mb-font/font/cff_type2_path_wbtest.mbt:508:CFF outline atomic mid-fetch mutation publishes no staged path","category":"State","code":"InvalidRange","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-source-revision-drift","gid":1,"publication":"existing-font-only","caller_before":[192,5,384,0,0,0,0,19],"caller_after":[192,5,384,0,0,0,0,19],"ancestor_before":[192,5,384,0,0,0,0,19],"ancestor_after":[192,5,384,0,0,0,0,19],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"staged-path-revision","applicable":false,"reason":"staged path is discarded on State drift"}}}
// hostile {"group":"mutation","row":{"id":"mutation-final-commit","source":"modules/mb-font/font/cff_type2_fixture_wbtest.mbt:542:Type 2 all-GID staging is ascending, exact, and does not commit budget","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":2,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"commit-revision","applicable":false,"reason":"final revision guard precedes atomic commit"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-state-over-resource","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:377:CFF multi-fault precedence is state resource capability then data","category":"State","code":"InvalidRange","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-source-revision-drift","gid":null,"publication":"none","caller_before":[1,1,1,0,0,0,0,1],"caller_after":[1,1,1,0,0,0,0,1],"ancestor_before":[1,1,1,0,0,0,0,1],"ancestor_after":[1,1,1,0,0,0,0,1],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"precedence","applicable":false,"reason":"State wins before Resource Capability and Data"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-resource-over-data","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:377:CFF multi-fault precedence is state resource capability then data","category":"Resource","code":"BudgetExceeded","operation":"budget_charge","payload":{"requested":257,"limit":256},"context":"bytes","gid":null,"publication":"none","caller_before":[256,32,4096,0,0,0,0,16384],"caller_after":[256,32,4096,0,0,0,0,16384],"ancestor_before":[256,32,4096,0,0,0,0,16384],"ancestor_after":[256,32,4096,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"precedence","applicable":false,"reason":"Resource preflight wins malformed header Data"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-capability-over-data","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:377:CFF multi-fault precedence is state resource capability then data","category":"Capability","code":"CapabilityUnavailable","operation":"font-cff-admit","payload":{"requested":null,"limit":null},"context":"font-cff-profile","gid":null,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"precedence","applicable":false,"reason":"recognized mixed profile Capability wins malformed CFF Data"}}}
// hostile {"group":"multi-fault-precedence","row":{"id":"precedence-smallest-failing-gid","source":"modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:181:CFF all-glyph capability data and smallest-failing-GID outcomes are atomic","category":"Data","code":"InvalidEncoding","operation":"font-cff-type2","payload":{"requested":null,"limit":null},"context":"font-cff-type2-reserved-operator","gid":1,"publication":"none","caller_before":[4096,32,16384,0,0,0,0,16384],"caller_after":[4096,32,16384,0,0,0,0,16384],"ancestor_before":[4096,32,16384,0,0,0,0,16384],"ancestor_after":[4096,32,16384,0,0,0,0,16384],"boundary":{"pair_id":null,"kind":"not-applicable","dimension":"gid-order","applicable":false,"reason":"ascending validation reports the smallest failing GID literally"}}}
// font-cff1-v3 private hostile:end
