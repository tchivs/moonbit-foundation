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
test "cff_structural_exact_and_one_short_cases" {
  let exact = cff_wb_table()
  let admitted = admit_cff1_structure(
    font_wb_view(cff_wb_otf(exact)),
    font_wb_limits(),
    cff_wb_budget(),
    0UL,
  ).unwrap()
  inspect(admitted.charge.header_bytes, content="4")
  inspect(admitted.charge.index_offsets > 0UL, content="true")
  inspect(admitted.charge.index_objects > 0UL, content="true")
  inspect(admitted.charge.dict_units > 0UL, content="true")
  inspect(admitted.charge.charset_entries > 0UL, content="true")
  inspect(admitted.charge.sid_cid_lookups > 0UL, content="true")
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
  inspect(admitted.charge.fd_ranges > 0UL, content="true")
  inspect(admitted.charge.encoding_entries, content="0")
  inspect(admitted.charge.descriptors, content="3")
  inspect(admitted.charge.fd_environments, content="2")

  let exact = cff_hostile_budget(
    admitted.charge.bytes,
    admitted.charge.allocations,
    admitted.charge.allocation_size,
    admitted.charge.work,
  )
  admit_cff1_structure(
    font_wb_view(source),
    font_wb_limits(),
    exact,
    2UL,
  ) |> ignore
  inspect(exact.remaining().bytes(), content="0")
  inspect(exact.remaining().allocations(), content="0")
  inspect(exact.remaining().work(), content="0")

  for dimension in [0, 1, 2, 3] {
    let budget = cff_hostile_budget(
      if dimension == 0 {
        admitted.charge.bytes - 1UL
      } else {
        admitted.charge.bytes
      },
      if dimension == 1 {
        admitted.charge.allocations - 1UL
      } else {
        admitted.charge.allocations
      },
      if dimension == 2 {
        admitted.charge.allocation_size - 1UL
      } else {
        admitted.charge.allocation_size
      },
      if dimension == 3 {
        admitted.charge.work - 1UL
      } else {
        admitted.charge.work
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
  inspect(capability_error.context() == Some("font-cff-profile"), content="true")

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
  ).unwrap_err()
  inspect(state_error.category() == @error.ErrorCategory::State, content="true")
  inspect(
    state_error.context() == Some("font-cff-source-revision-drift"),
    content="true",
  )
  inspect(too_short.remaining().bytes() == before.bytes(), content="true")
  inspect(too_short.remaining().work() == before.work(), content="true")
}
