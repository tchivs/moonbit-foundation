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
test "font qualification executes the closed collection hostile outcome matrix" {
  fail("Phase 103 collection hostile matrix is not implemented")
}

///|
test "font qualification preserves public collection mutation atomicity" {
  fail("Phase 103 public collection mutation matrix is not implemented")
}
