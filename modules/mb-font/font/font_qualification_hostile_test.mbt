///|
fn font_qualification_assert_error(
  error : @error.CoreError,
  expected : FontQualificationCase,
) -> Unit raise {
  match expected.category {
    "Data" =>
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
    "Capability" =>
      inspect(
        error.category() == @error.ErrorCategory::Capability,
        content="true",
      )
    "State" =>
      inspect(error.category() == @error.ErrorCategory::State, content="true")
    "Resource" =>
      inspect(
        error.category() == @error.ErrorCategory::Resource,
        content="true",
      )
    _ => fail("hostile case has an unknown error category")
  }
  match expected.code {
    "InvalidEncoding" =>
      inspect(
        error.code() == @error.ErrorCode::InvalidEncoding,
        content="true",
      )
    "CapabilityUnavailable" =>
      inspect(
        error.code() == @error.ErrorCode::CapabilityUnavailable,
        content="true",
      )
    "InvalidRange" =>
      inspect(
        error.code() == @error.ErrorCode::InvalidRange,
        content="true",
      )
    "BudgetExceeded" =>
      inspect(
        error.code() == @error.ErrorCode::BudgetExceeded,
        content="true",
      )
    _ => fail("hostile case has an unknown error code")
  }
  if error.context() != Some(expected.context) {
    fail(expected.id)
  }
  match expected.requested {
    Some(value) =>
      if error.requested() != Some(value) {
        fail(expected.id)
      }
    None => ()
  }
  match expected.limit {
    Some(value) =>
      if error.limit() != Some(value) {
        fail(expected.id)
      }
    None => ()
  }
}

///|
fn font_qualification_limits_with_source(max_source_bytes : UInt64) -> FontLimits {
  FontLimits::new(
    max_source_bytes~,
    max_tables=64UL,
    max_table_bytes=600000UL,
    max_glyphs=7000UL,
    max_name_records=64UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=3000UL,
    max_outline_points=2048UL,
    max_outline_contours=128UL,
    max_outline_components=32UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=64000UL,
    max_work=10000000UL,
  ).unwrap()
}

///|
fn font_qualification_checked_range_limits() -> FontLimits {
  FontLimits::new(
    max_source_bytes=1000000UL,
    max_tables=64UL,
    max_table_bytes=0xFFFFFFFFUL,
    max_glyphs=7000UL,
    max_name_records=64UL,
    max_cmap_records=16UL,
    max_kern_subtables=16UL,
    max_kern_pairs=3000UL,
    max_outline_points=2048UL,
    max_outline_contours=128UL,
    max_outline_components=32UL,
    max_outline_instruction_bytes=1024UL,
    max_post_name_bytes=64000UL,
    max_work=10000000UL,
  ).unwrap()
}

///|
fn font_qualification_open_budget(bytes : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=3UL,
      allocation_size=4096UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=16384UL,
    ),
  )
}

///|
fn font_qualification_exact_outline_budget(work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=5UL,
      allocation_size=160UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn font_qualification_expect_open_error(
  owner : @bytes.OwnedBytes,
  expected : FontQualificationCase,
) -> Unit raise {
  match
    Font::open(
      owner.view(),
      font_qualification_limits(),
      font_qualification_admission_budget(),
    ) {
    Ok(_) => fail("failed hostile open published a Font")
    Err(error) => font_qualification_assert_error(error, expected)
  }
}

///|
fn font_qualification_run_hostile_case(
  expected : FontQualificationCase,
) -> Unit raise {
  match expected.id {
    "malformed-directory-range" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      font_test_mutate_u32(owner, 68UL, 0xFFFFFFFCUL)
      font_qualification_expect_open_error(owner, expected)
    }
    "unsupported-outline-profile" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      font_test_mutate_bytes(owner, 0UL, b"OTTO")
      font_qualification_expect_open_error(owner, expected)
    }
    "mutation-after-open" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      let font = Font::open(
        owner.view(),
        font_qualification_limits(),
        font_qualification_admission_budget(),
      ).unwrap()
      let glyph = font.glyph_for_scalar(0x0041).unwrap()
      font_test_mutate_bytes(owner, 0UL, b"\x00")
      for result in [
        font.units_per_em().map(fn(_) { () }),
        font.glyph_for_scalar(0x0041).map(fn(_) { () }),
        font.horizontal_metrics(glyph).map(fn(_) { () }),
        font.kerning(glyph, glyph).map(fn(_) { () }),
        font
        .outline(glyph, font_qualification_outline_budget())
        .map(fn(_) { () }),
      ] {
        match result {
          Ok(_) => fail("mutated source published stale public data")
          Err(error) => font_qualification_assert_error(error, expected)
        }
      }
    }
    "checked-range-overflow" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      font_test_mutate_u32(owner, 68UL, 0xFFFFFFFCUL)
      font_test_mutate_u32(owner, 72UL, 0xFFFFFFFFUL)
      match
        Font::open(
          owner.view(),
          font_qualification_checked_range_limits(),
          font_qualification_admission_budget(),
        ) {
        Ok(_) => fail("checked range failure published a Font")
        Err(error) => font_qualification_assert_error(error, expected)
      }
    }
    "limit-source-exact" => {
      let source = font_qualification_compact_bytes()
      inspect(source.length(), content="580")
      let owner = font_test_owner(source)
      match
        Font::open(
          owner.view(),
          font_qualification_limits_with_source(580UL),
          font_qualification_open_budget(580UL),
        ) {
        Err(_) => fail("exact source limit did not publish a Font")
        Ok(font) => inspect(font.units_per_em().unwrap(), content="1000")
      }
    }
    "limit-source-one-short" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      match
        Font::open(
          owner.view(),
          font_qualification_limits_with_source(579UL),
          font_qualification_open_budget(580UL),
        ) {
        Ok(_) => fail("one-short source limit published a Font")
        Err(error) => font_qualification_assert_error(error, expected)
      }
    }
    "budget-open-exact" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      let budget = font_qualification_open_budget(580UL)
      match
        Font::open(
          owner.view(),
          font_qualification_limits(),
          budget,
        ) {
        Err(_) => fail("exact open budget did not publish a Font")
        Ok(font) => {
          inspect(font.units_per_em().unwrap(), content="1000")
          inspect(budget.remaining().bytes(), content="0")
        }
      }
    }
    "budget-open-one-short" => {
      let owner = font_test_owner(font_qualification_compact_bytes())
      let budget = font_qualification_open_budget(579UL)
      let before = budget.remaining()
      match Font::open(owner.view(), font_qualification_limits(), budget) {
        Ok(_) => fail("one-short open budget published a Font")
        Err(error) => font_qualification_assert_error(error, expected)
      }
      let after = budget.remaining()
      inspect(after.bytes() == before.bytes(), content="true")
      inspect(after.work() == before.work(), content="true")
      inspect(after.allocations() == before.allocations(), content="true")
    }
    "budget-outline-exact" => {
      let owner = font_test_owner(font_test_simple_outline_truetype())
      let font = Font::open(
        owner.view(),
        font_qualification_limits(),
        font_qualification_admission_budget(),
      ).unwrap()
      let glyph = font.glyph_id(0UL).unwrap()
      let budget = font_qualification_exact_outline_budget(18UL)
      match font.outline(glyph, budget) {
        Err(_) => fail("exact outline budget did not publish a Path2")
        Ok(path) => {
          inspect(path.length(), content="4")
          inspect(budget.remaining().work(), content="0")
          inspect(budget.remaining().allocations(), content="0")
        }
      }
    }
    "budget-outline-one-short" => {
      let owner = font_test_owner(font_test_simple_outline_truetype())
      let font = Font::open(
        owner.view(),
        font_qualification_limits(),
        font_qualification_admission_budget(),
      ).unwrap()
      let glyph = font.glyph_id(0UL).unwrap()
      let budget = font_qualification_exact_outline_budget(17UL)
      match font.outline(glyph, budget) {
        Ok(_) => fail("one-short outline budget published a Path2")
        Err(error) => font_qualification_assert_error(error, expected)
      }
      let after = budget.remaining()
      inspect(after.work(), content="4")
      inspect(after.allocations(), content="1")
      inspect(font.horizontal_metrics(glyph) is Ok(_), content="true")
    }
    "nested-composite-recognized" => {
      let simple = font_test_simple_outline_glyf()
      let child_parent = font_test_composite_glyph([
        font_test_component_record(0x0003UL, 0UL, 0, 0, []),
      ])
      let deeper_parent = font_test_composite_glyph([
        font_test_component_record(0x0003UL, 1UL, 0, 0, []),
      ])
      let owner = font_test_owner(
        font_test_outline_graph_truetype([
          simple,
          child_parent,
          deeper_parent,
        ]),
      )
      let font = Font::open(
        owner.view(),
        font_qualification_limits(),
        font_qualification_admission_budget(),
      ).unwrap()
      let glyph = font.glyph_id(2UL).unwrap()
      match font.outline(glyph, font_qualification_outline_budget()) {
        Ok(_) => fail("nested composite published a Path2")
        Err(error) => font_qualification_assert_error(error, expected)
      }
      inspect(font.horizontal_metrics(glyph) is Ok(_), content="true")
    }
    _ => fail("closed hostile case has no public dispatcher")
  }
}

///|
test "font qualification executes the closed hostile outcome matrix" {
  let expected_ids = [
    "malformed-directory-range",
    "unsupported-outline-profile",
    "mutation-after-open",
    "checked-range-overflow",
    "limit-source-exact",
    "limit-source-one-short",
    "budget-open-exact",
    "budget-open-one-short",
    "budget-outline-exact",
    "budget-outline-one-short",
    "nested-composite-recognized",
  ]
  let cases = font_qualification_cases()
  inspect(cases.length() == expected_ids.length(), content="true")
  for index = 0; index < expected_ids.length(); index = index + 1 {
    let expected = cases[index]
    inspect(expected.id == expected_ids[index], content="true")
    match expected.stage {
      "open" | "query" | "outline" => ()
      _ => fail("hostile case has an unknown public stage")
    }
    match expected.publication {
      "none" | "existing-font-only" | "font" | "font-only" | "path" => ()
      _ => fail("hostile case has an unknown publication contract")
    }
    font_qualification_run_hostile_case(expected)
  }
}

///|
fn font_collection_qualification_assert_snapshot_equal(
  left : FontCollectionQualificationBudgetSnapshot,
  right : FontCollectionQualificationBudgetSnapshot,
) -> Unit raise {
  inspect(left.bytes == right.bytes, content="true")
  inspect(left.allocations == right.allocations, content="true")
  inspect(left.allocation_size == right.allocation_size, content="true")
  inspect(left.width == right.width, content="true")
  inspect(left.height == right.height, content="true")
  inspect(left.pixels == right.pixels, content="true")
  inspect(left.depth == right.depth, content="true")
  inspect(left.work == right.work, content="true")
}

///|
fn font_collection_qualification_assert_ids(
  cases : Array[FontCollectionQualificationCase],
  start : Int,
  group : String,
  ids : Array[String],
) -> Unit raise {
  for offset = 0; offset < ids.length(); offset = offset + 1 {
    let expected = cases[start + offset]
    inspect(expected.id == ids[offset], content="true")
    inspect(expected.group == group, content="true")
    inspect(expected.fixture_id.length() > 0, content="true")
    inspect(expected.entrypoint.length() > 0, content="true")
    inspect(expected.authority.length() > 0, content="true")
    inspect(expected.mutation_window.length() > 0, content="true")
    match expected.boundary {
      "failure" | "one-short" => {
        inspect(expected.error.category is Some(_), content="true")
        inspect(expected.error.code is Some(_), content="true")
        inspect(expected.error.operation is Some(_), content="true")
        inspect(expected.error.context is Some(_), content="true")
        inspect(expected.publication != "font", content="true")
        font_collection_qualification_assert_snapshot_equal(
          expected.budget_before,
          expected.budget_after,
        )
      }
      "success" | "exact" => inspect(expected.publication != "none", content="true")
      _ => fail(expected.id)
    }
    ignore(expected.face_index)
    ignore(expected.error.source_offset)
    ignore(expected.error.requested)
    ignore(expected.error.limit)
  }
}

///|
fn font_collection_qualification_assert_closed_matrix() -> Unit raise {
  let cases = font_collection_qualification_cases()
  inspect(cases.length(), content="97")
  font_collection_qualification_assert_ids(
    cases,
    0,
    "public_workflows",
    [
      "generated-ttc-v1-static-selected",
      "generated-ttc-v2-dsig-absent",
      "generated-ttc-v2-dsig-present-unverified",
      "generated-ttc-v1-exact-sharing",
      "generated-ttc-v2-mixed-profiles",
      "generated-ttc-v1-nonzero-directory-base",
      "licensed-dejavu-two-face-v1-face-0",
      "licensed-dejavu-two-face-v1-face-1",
    ],
  )
  font_collection_qualification_assert_ids(
    cases,
    8,
    "hostile_cases",
    [
      "collection-header-truncated",
      "collection-signature-invalid",
      "collection-version-unsupported",
      "collection-face-count-zero",
      "collection-offset-array-truncated",
      "collection-face-directory-truncated",
      "collection-directory-search-facts-invalid",
      "collection-directory-tags-unordered",
      "collection-table-range-overflow",
      "collection-protected-range-overlap",
      "collection-same-face-overlap",
      "collection-cross-face-partial-overlap",
      "collection-shared-range-metadata-conflict",
      "collection-dsig-partial-zero-tuple",
      "collection-dsig-range-not-at-eof",
      "collection-dsig-envelope-malformed",
      "collection-dsig-version-unsupported",
      "collection-dsig-format-unsupported",
      "collection-dsig-block-overlap",
      "collection-face-index-equal-count",
      "collection-select-cff",
      "collection-select-cff2",
      "collection-select-variable",
      "collection-checked-pair-work-overflow",
    ],
  )
  font_collection_qualification_assert_ids(
    cases,
    32,
    "mutation_cases",
    [
      "mutation-collection-after-open-before-query",
      "mutation-collection-mid-open-final-guard",
      "mutation-selection-before-open-face",
      "mutation-selection-mid-admission-final-guard",
      "mutation-selected-font-after-publication",
      "mutation-glyph-lookup-mid-query",
      "mutation-kerning-mid-query",
      "mutation-simple-outline-mid-query",
      "mutation-composite-outline-mid-query",
    ],
  )
  font_collection_qualification_assert_ids(
    cases,
    41,
    "limit_cases",
    [
      "limit-collection-source-bytes-exact",
      "limit-collection-source-bytes-one-short",
      "limit-collection-faces-exact",
      "limit-collection-faces-one-short",
      "limit-collection-tables-per-face-exact",
      "limit-collection-tables-per-face-one-short",
      "limit-collection-table-records-exact",
      "limit-collection-table-records-one-short",
      "limit-collection-dsig-records-exact",
      "limit-collection-dsig-records-one-short",
      "limit-collection-dsig-bytes-exact",
      "limit-collection-dsig-bytes-one-short",
      "limit-collection-retained-bookkeeping-bytes-exact",
      "limit-collection-retained-bookkeeping-bytes-one-short",
      "limit-collection-work-exact",
      "limit-collection-work-one-short",
      "limit-selected-source-bytes-exact",
      "limit-selected-source-bytes-one-short",
      "limit-selected-tables-exact",
      "limit-selected-tables-one-short",
      "limit-selected-table-bytes-exact",
      "limit-selected-table-bytes-one-short",
      "limit-selected-glyphs-exact",
      "limit-selected-glyphs-one-short",
      "limit-selected-name-records-exact",
      "limit-selected-name-records-one-short",
      "limit-selected-cmap-records-exact",
      "limit-selected-cmap-records-one-short",
      "limit-selected-kern-subtables-exact",
      "limit-selected-kern-subtables-one-short",
      "limit-selected-kern-pairs-exact",
      "limit-selected-kern-pairs-one-short",
      "limit-selected-outline-points-exact",
      "limit-selected-outline-points-one-short",
      "limit-selected-outline-contours-exact",
      "limit-selected-outline-contours-one-short",
      "limit-selected-outline-components-exact",
      "limit-selected-outline-components-one-short",
      "limit-selected-instruction-bytes-exact",
      "limit-selected-instruction-bytes-one-short",
      "limit-selected-post-name-bytes-exact",
      "limit-selected-post-name-bytes-one-short",
      "limit-selected-work-exact",
      "limit-selected-work-one-short",
    ],
  )
  font_collection_qualification_assert_ids(
    cases,
    85,
    "budget_cases",
    [
      "budget-caller-bytes-exact",
      "budget-caller-bytes-one-short",
      "budget-caller-allocations-exact",
      "budget-caller-allocations-one-short",
      "budget-caller-allocation-size-exact",
      "budget-caller-allocation-size-one-short",
      "budget-caller-work-exact",
      "budget-caller-work-one-short",
      "budget-ancestor-bytes-exact",
      "budget-ancestor-bytes-one-short",
      "budget-ancestor-work-exact",
      "budget-ancestor-work-one-short",
    ],
  )
}

///|
fn font_collection_qualification_expect_open_error(
  source : Bytes,
  category : @error.ErrorCategory,
  code : @error.ErrorCode,
  context : String,
) -> Unit raise {
  let owner = font_collection_test_owner(source)
  let budget = font_qualification_collection_budget()
  let before = budget.remaining()
  let error = FontCollection::open(
    owner.view(),
    font_qualification_collection_limits(1000000UL, 64UL, 256UL),
    budget,
  ).unwrap_err()
  inspect(error.category() == category, content="true")
  inspect(error.code() == code, content="true")
  inspect(error.operation() == Some("font-collection-open"), content="true")
  if error.context() != Some(context) {
    fail(context)
  }
  font_collection_test_assert_budget_unchanged(before, budget)
}

///|
fn font_collection_qualification_assert_structural_failures() -> Unit raise {
  font_collection_qualification_expect_open_error(
    b"",
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-header",
  )
  let invalid_signature = font_collection_test_ttc().to_array()
  font_collection_test_put_u32(invalid_signature, 0, 0UL)
  font_collection_qualification_expect_open_error(
    Bytes::from_array(invalid_signature),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-signature",
  )
  let invalid_version = font_collection_test_ttc().to_array()
  font_collection_test_put_u32(invalid_version, 4, 0x00030000UL)
  font_collection_qualification_expect_open_error(
    Bytes::from_array(invalid_version),
    @error.ErrorCategory::Capability,
    @error.ErrorCode::CapabilityUnavailable,
    "font-collection-version",
  )
  font_collection_qualification_expect_open_error(
    font_collection_test_zero_faces(),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-face-count",
  )
  font_collection_qualification_expect_open_error(
    font_collection_test_prefix(font_collection_test_multi_ttc(), 15),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-offset-array",
  )
  font_collection_qualification_expect_open_error(
    font_collection_test_prefix(font_collection_test_multi_ttc(), 75),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-directory-range",
  )

  let bad_search = font_collection_test_multi_ttc().to_array()
  font_collection_test_put_u16(bad_search, 70, 0UL)
  font_collection_qualification_expect_open_error(
    Bytes::from_array(bad_search),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-search-facts",
  )
  let unordered_tags = font_collection_test_multi_ttc().to_array()
  font_collection_test_put_u32(unordered_tags, 76, 0x6C6F6361UL)
  font_collection_test_put_u32(unordered_tags, 92, 0x676C7966UL)
  font_collection_qualification_expect_open_error(
    Bytes::from_array(unordered_tags),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-table-tag-order",
  )
  font_collection_qualification_expect_open_error(
    font_collection_test_pair_ttc(
      0x6E616D65UL,
      7UL,
      0xFFFFFFFCUL,
      8UL,
      0x6E616D65UL,
      7UL,
      96UL,
      4UL,
    ),
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    "font-collection-table-range",
  )

  let name = 0x6E616D65UL
  for
    item in [
      (
        font_collection_test_pair_ttc(
          name, 7UL, 96UL, 8UL, name, 7UL, 100UL, 8UL,
        ),
        "font-collection-cross-face-overlap",
      ),
      (
        font_collection_test_pair_ttc(
          name, 7UL, 96UL, 4UL, name, 8UL, 96UL, 4UL,
        ),
        "font-collection-shared-metadata",
      ),
      (
        font_collection_test_pair_ttc(
          name, 7UL, 64UL, 4UL, name, 9UL, 100UL, 4UL,
        ),
        "font-collection-table-protected-overlap",
      ),
    ] {
    let (source, context) = item
    let owner = font_collection_test_owner(source)
    let budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_pair_limits(248UL, 66UL),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Data, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidEncoding, content="true")
    inspect(error.operation() == Some("font-collection-open"), content="true")
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let same_owner = font_collection_test_owner(
    font_collection_test_same_face_overlap_ttc(),
  )
  let same_budget = font_collection_test_pair_budget(184UL, 2UL, 48UL, 47UL)
  let same_before = same_budget.remaining()
  let same_error = FontCollection::open(
    same_owner.view(),
    FontCollectionLimits::new(
      max_source_bytes=128UL,
      max_faces=1UL,
      max_tables_per_face=2UL,
      max_table_records=2UL,
      max_dsig_records=1UL,
      max_dsig_bytes=1UL,
      max_retained_bookkeeping_bytes=184UL,
      max_work=47UL,
    ).unwrap(),
    same_budget,
  ).unwrap_err()
  inspect(
    same_error.context() == Some("font-collection-same-face-overlap"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(same_before, same_budget)
}

///|
fn font_collection_qualification_assert_dsig_and_profile_failures() -> Unit raise {
  let dsig_source = font_collection_test_dsig_ttc()
  for field in [16, 20, 24] {
    let malformed = dsig_source.to_array()
    font_collection_test_put_u32(malformed, field, 0UL)
    let owner = font_collection_test_owner(Bytes::from_array(malformed))
    let budget = font_collection_test_dsig_budget(57UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 57UL),
      budget,
    ).unwrap_err()
    inspect(
      error.context() == Some("font-collection-dsig-tuple"),
      content="true",
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let trailing_dsig = dsig_source.to_array()
  font_collection_test_put_u32(trailing_dsig, 20, 28UL)
  let trailing_owner = font_collection_test_owner(
    Bytes::from_array(trailing_dsig),
  )
  let trailing_budget = font_collection_test_dsig_budget(57UL)
  let trailing_before = trailing_budget.remaining()
  let trailing_error = FontCollection::open(
    trailing_owner.view(),
    font_collection_test_dsig_limits(1UL, 32UL, 57UL),
    trailing_budget,
  ).unwrap_err()
  inspect(
    trailing_error.context() == Some("font-collection-dsig-range"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    trailing_before,
    trailing_budget,
  )
  for
    item in [
      (68, 2UL, false, @error.ErrorCategory::Capability, "font-collection-dsig-version"),
      (76, 2UL, false, @error.ErrorCategory::Capability, "font-collection-dsig-format"),
      (72, 0UL, true, @error.ErrorCategory::Data, "font-collection-dsig-count"),
      (74, 2UL, true, @error.ErrorCategory::Data, "font-collection-dsig-flags"),
      (80, 11UL, false, @error.ErrorCategory::Data, "font-collection-dsig-block-length"),
      (84, 8UL, false, @error.ErrorCategory::Data, "font-collection-dsig-block-range"),
      (88, 1UL, false, @error.ErrorCategory::Data, "font-collection-dsig-reserved"),
    ] {
    let (field, value, is_u16, category, context) = item
    let malformed = dsig_source.to_array()
    if is_u16 {
      font_collection_test_put_u16(malformed, field, value)
    } else {
      font_collection_test_put_u32(malformed, field, value)
    }
    let owner = font_collection_test_owner(Bytes::from_array(malformed))
    let budget = font_collection_test_dsig_budget(57UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      owner.view(),
      font_collection_test_dsig_limits(1UL, 32UL, 57UL),
      budget,
    ).unwrap_err()
    inspect(error.category() == category, content="true")
    inspect(error.context() == Some(context), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let overlap_source = font_collection_test_two_dsig_ttc(32UL, 40UL, 52UL)
  let overlap_owner = font_collection_test_owner(overlap_source)
  let overlap_budget = font_collection_test_dsig_budget(64UL)
  let overlap_before = overlap_budget.remaining()
  let overlap_error = FontCollection::open(
    overlap_owner.view(),
    font_collection_test_two_dsig_limits(2UL, 52UL, 64UL),
    overlap_budget,
  ).unwrap_err()
  inspect(
    overlap_error.context() == Some("font-collection-dsig-block-overlap"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    overlap_before,
    overlap_budget,
  )

  let mixed_source = font_collection_test_multi_ttc()
  let mixed_owner = font_collection_test_owner(mixed_source)
  let mixed = FontCollection::open(
    mixed_owner.view(),
    font_qualification_collection_limits(
      mixed_source.length().to_uint64(),
      5UL,
      8UL,
    ),
    font_qualification_collection_budget(),
  ).unwrap()
  for index in [1UL, 2UL, 3UL] {
    let budget = font_collection_test_selected_budget()
    let before = budget.remaining()
    let error = mixed
      .open_face(index, font_test_limits(), budget)
      .unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Capability, content="true")
    inspect(
      error.code() == @error.ErrorCode::CapabilityUnavailable,
      content="true",
    )
    inspect(
      error.operation() == Some("font-collection-open-face"),
      content="true",
    )
    inspect(
      error.context() == Some("font-collection-face-profile"),
      content="true",
    )
    font_collection_test_assert_budget_unchanged(before, budget)
  }
  let index_budget = font_collection_test_selected_budget()
  let index_before = index_budget.remaining()
  let index_error = mixed
    .open_face(5UL, font_test_limits(), index_budget)
    .unwrap_err()
  inspect(
    index_error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(index_error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(index_error.requested() == Some(5UL), content="true")
  inspect(index_error.limit() == Some(5UL), content="true")
  font_collection_test_assert_budget_unchanged(index_before, index_budget)
}

///|
fn font_collection_qualification_assert_limits_and_budgets() -> Unit raise {
  let compact = font_collection_test_ttc()
  let exact_owner = font_collection_test_owner(compact)
  ignore(
    FontCollection::open(
      exact_owner.view(),
      font_collection_test_limits_with_source(88UL),
      font_collection_test_budget(),
    ).unwrap(),
  )
  let short_owner = font_collection_test_owner(compact)
  let short_budget = font_collection_test_budget()
  let short_before = short_budget.remaining()
  let short_error = FontCollection::open(
    short_owner.view(),
    font_collection_test_limits_with_source(87UL),
    short_budget,
  ).unwrap_err()
  inspect(short_error.category() == @error.ErrorCategory::Resource, content="true")
  inspect(short_error.context() == Some("max-source-bytes"), content="true")
  inspect(short_error.requested() == Some(88UL), content="true")
  inspect(short_error.limit() == Some(87UL), content="true")
  font_collection_test_assert_budget_unchanged(short_before, short_budget)

  let multi = font_collection_test_multi_ttc()
  ignore(
    FontCollection::open(
      font_collection_test_owner(multi).view(),
      FontCollectionLimits::new(
        max_source_bytes=400UL,
        max_faces=5UL,
        max_tables_per_face=3UL,
        max_table_records=8UL,
        max_dsig_records=1UL,
        max_dsig_bytes=1UL,
        max_retained_bookkeeping_bytes=440UL,
        max_work=252UL,
      ).unwrap(),
      font_collection_test_pair_budget(440UL, 2UL, 200UL, 252UL),
    ).unwrap(),
  )
  for
    item in [
      (4UL, 3UL, 8UL, 440UL, 252UL, "max-faces", 5UL, 4UL),
      (5UL, 2UL, 8UL, 440UL, 252UL, "max-tables-per-face", 3UL, 2UL),
      (5UL, 3UL, 7UL, 440UL, 252UL, "max-table-records", 8UL, 7UL),
      (
        5UL,
        3UL,
        8UL,
        439UL,
        252UL,
        "max-retained-bookkeeping-bytes",
        440UL,
        439UL,
      ),
      (5UL, 3UL, 8UL, 440UL, 251UL, "max-work", 252UL, 251UL),
    ] {
    let (
      faces,
      tables,
      records,
      retained,
      work,
      context,
      requested,
      limit,
    ) = item
    let budget = font_collection_test_pair_budget(440UL, 2UL, 200UL, 252UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      font_collection_test_owner(multi).view(),
      FontCollectionLimits::new(
        max_source_bytes=400UL,
        max_faces=faces,
        max_tables_per_face=tables,
        max_table_records=records,
        max_dsig_records=1UL,
        max_dsig_bytes=1UL,
        max_retained_bookkeeping_bytes=retained,
        max_work=work,
      ).unwrap(),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some(context), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == Some(limit), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }

  let two_dsig = font_collection_test_two_dsig_ttc(32UL, 44UL, 56UL)
  ignore(
    FontCollection::open(
      font_collection_test_owner(two_dsig).view(),
      font_collection_test_two_dsig_limits(2UL, 56UL, 64UL),
      font_collection_test_dsig_budget(64UL),
    ).unwrap(),
  )
  for
    item in [
      (1UL, 56UL, "max-dsig-records", 2UL, 1UL),
      (2UL, 55UL, "max-dsig-bytes", 56UL, 55UL),
    ] {
    let (records, bytes, context, requested, limit) = item
    let budget = font_collection_test_dsig_budget(64UL)
    let before = budget.remaining()
    let error = FontCollection::open(
      font_collection_test_owner(two_dsig).view(),
      font_collection_test_two_dsig_limits(records, bytes, 64UL),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.context() == Some(context), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == Some(limit), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }

  let shared = font_collection_test_pair_ttc(
    0x6E616D65UL,
    7UL,
    96UL,
    4UL,
    0x6E616D65UL,
    7UL,
    96UL,
    4UL,
  )
  let exact_budget = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
  ignore(
    FontCollection::open(
      font_collection_test_owner(shared).view(),
      font_collection_test_pair_limits(248UL, 66UL),
      exact_budget,
    ).unwrap(),
  )
  inspect(exact_budget.remaining().bytes(), content="0")
  inspect(exact_budget.remaining().allocations(), content="0")
  inspect(exact_budget.remaining().allocation_size(), content="80")
  inspect(exact_budget.remaining().work(), content="0")
  for
    item in [
      (247UL, 2UL, 80UL, 66UL, "bytes", 248UL, 247UL),
      (248UL, 1UL, 80UL, 66UL, "allocations", 2UL, 1UL),
      (248UL, 2UL, 79UL, 66UL, "allocation_size", 80UL, 79UL),
      (248UL, 2UL, 80UL, 65UL, "work", 66UL, 65UL),
    ] {
    let (bytes, allocations, allocation_size, work, context, requested, limit) = item
    let budget = font_collection_test_pair_budget(
      bytes,
      allocations,
      allocation_size,
      work,
    )
    let before = budget.remaining()
    let error = FontCollection::open(
      font_collection_test_owner(shared).view(),
      font_collection_test_pair_limits(248UL, 66UL),
      budget,
    ).unwrap_err()
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.operation() == Some("budget_charge"), content="true")
    inspect(error.context() == Some(context), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == Some(limit), content="true")
    font_collection_test_assert_budget_unchanged(before, budget)
  }

  for
    item in [
      (1UL, 0UL, "bytes", 248UL, 247UL),
      (0UL, 1UL, "work", 66UL, 65UL),
    ] {
    let (bytes_charge, work_charge, context, requested, limit) = item
    let ancestor = font_collection_test_pair_budget(248UL, 2UL, 80UL, 66UL)
    let child = ancestor.child(ancestor.remaining()).unwrap()
    ancestor.charge(
      @budget.ResourceCharge::new(
        bytes=bytes_charge,
        allocations=0UL,
        allocation_size=0UL,
        width=0UL,
        height=0UL,
        pixels=0UL,
        work=work_charge,
      ),
    ).unwrap()
    let ancestor_before = ancestor.remaining()
    let child_before = child.remaining()
    let error = FontCollection::open(
      font_collection_test_owner(shared).view(),
      font_collection_test_pair_limits(248UL, 66UL),
      child,
    ).unwrap_err()
    inspect(error.operation() == Some("budget_charge"), content="true")
    inspect(error.context() == Some(context), content="true")
    inspect(error.requested() == Some(requested), content="true")
    inspect(error.limit() == Some(limit), content="true")
    font_collection_test_assert_budget_unchanged(ancestor_before, ancestor)
    font_collection_test_assert_budget_unchanged(child_before, child)
  }

  let selected_source = font_collection_test_selected_ttc()
  let selected_owner = font_collection_test_owner(selected_source)
  let selected = FontCollection::open(
    selected_owner.view(),
    font_collection_test_selected_limits(selected_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let selected_budget = font_collection_test_selected_budget()
  let selected_before = selected_budget.remaining()
  let selected_error = selected
    .open_face(
      0UL,
      font_collection_test_selected_font_limits(
        selected_source.length().to_uint64() - 1UL,
      ),
      selected_budget,
    )
    .unwrap_err()
  inspect(selected_error.operation() == Some("font-open"), content="true")
  inspect(selected_error.context() == Some("max-source-bytes"), content="true")
  font_collection_test_assert_budget_unchanged(selected_before, selected_budget)
}

///|
test "font qualification executes the closed collection hostile outcome matrix" {
  font_collection_qualification_assert_closed_matrix()
  font_collection_qualification_assert_structural_failures()
  font_collection_qualification_assert_dsig_and_profile_failures()
  font_collection_qualification_assert_limits_and_budgets()
}

///|
test "font qualification preserves public collection mutation atomicity" {
  font_collection_qualification_assert_closed_matrix()
  let source = font_collection_test_selected_ttc()
  let owner = font_collection_test_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_collection_test_selected_limits(source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let font = collection
    .open_face(0UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
  let glyph = font.glyph_id(0UL).unwrap()
  let original = owner.view().get(20UL).unwrap()
  font_collection_test_mutate(
    owner,
    20UL,
    (original.to_uint64() ^ 1UL).to_byte(),
  )
  font_collection_test_mutate(owner, 20UL, original)
  font_collection_test_assert_every_query_drift(collection)
  let selection_budget = font_collection_test_selected_budget()
  let selection_before = selection_budget.remaining()
  let selection_error = collection
    .open_face(0UL, font_test_limits(), selection_budget)
    .unwrap_err()
  inspect(selection_error.category() == @error.ErrorCategory::State, content="true")
  inspect(selection_error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(
    selection_error.operation() == Some("font-collection-open-face"),
    content="true",
  )
  inspect(
    selection_error.context() ==
    Some("font-collection-source-revision-drift"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    selection_before,
    selection_budget,
  )
  for error in [
    font.units_per_em().unwrap_err(),
    font.global_bounds().unwrap_err(),
    font.hhea_line_metrics().unwrap_err(),
    font.typographic_line_metrics().unwrap_err(),
    font.glyph_for_scalar(65).unwrap_err(),
    font.glyph_id(0UL).unwrap_err(),
    font.horizontal_metrics(glyph).unwrap_err(),
    font.kerning(glyph, glyph).unwrap_err(),
  ] {
    inspect(error.category() == @error.ErrorCategory::State, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    inspect(error.operation() == Some("font-query"), content="true")
    inspect(error.context() == Some("font-source-revision-drift"), content="true")
  }
  let outline_error = font
    .outline(glyph, font_test_outline_budget())
    .unwrap_err()
  inspect(
    outline_error.category() == @error.ErrorCategory::State,
    content="true",
  )
  inspect(
    outline_error.code() == @error.ErrorCode::InvalidRange,
    content="true",
  )
  inspect(
    outline_error.operation() == Some("font-outline"),
    content="true",
  )
  inspect(
    outline_error.context() == Some("font-source-revision-drift"),
    content="true",
  )
}
