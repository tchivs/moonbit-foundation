///|
fn font_qualification_limits() -> FontLimits {
  FontLimits::new(
    max_source_bytes=1000000UL,
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
fn font_qualification_admission_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=1000000UL,
      allocations=16UL,
      allocation_size=1000000UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=10000000UL,
    ),
  )
}

///|
fn font_qualification_outline_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=0UL,
      allocations=256UL,
      allocation_size=1000000UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=10000000UL,
    ),
  )
}

///|
fn font_qualification_assert_bounds(
  bounds : FontBounds,
  x_min : Int,
  y_min : Int,
  x_max : Int,
  y_max : Int,
) -> Unit raise {
  inspect(bounds.x_min() == x_min, content="true")
  inspect(bounds.y_min() == y_min, content="true")
  inspect(bounds.x_max() == x_max, content="true")
  inspect(bounds.y_max() == y_max, content="true")
}

///|
fn font_qualification_assert_line_metrics(
  metrics : FontLineMetrics,
  ascent : Int,
  descent : Int,
  line_gap : Int,
) -> Unit raise {
  inspect(metrics.ascent() == ascent, content="true")
  inspect(metrics.descent() == descent, content="true")
  inspect(metrics.line_gap() == line_gap, content="true")
}

///|
fn font_qualification_assert_command(
  path : @math.Path2,
  index : Int,
  kind : String,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Unit raise {
  match path.get(index) {
    Some(@math.PathCommand::MoveTo(point)) => {
      inspect(kind == "M", content="true")
      inspect(point.x() == x1, content="true")
      inspect(point.y() == y1, content="true")
    }
    Some(@math.PathCommand::LineTo(point)) => {
      inspect(kind == "L", content="true")
      inspect(point.x() == x1, content="true")
      inspect(point.y() == y1, content="true")
    }
    Some(@math.PathCommand::QuadTo(control, endpoint)) => {
      inspect(kind == "Q", content="true")
      inspect(control.x() == x1, content="true")
      inspect(control.y() == y1, content="true")
      inspect(endpoint.x() == x2, content="true")
      inspect(endpoint.y() == y2, content="true")
    }
    Some(@math.PathCommand::CubicTo(_, _, _)) =>
      fail("unexpected cubic qualification path command")
    Some(@math.PathCommand::Close) => inspect(kind == "Z", content="true")
    None => fail("missing qualification path command")
  }
}

///|
fn font_qualification_assert_outline_expectation(
  font : Font,
  expectation : FontQualificationOutlineExpectation,
) -> Unit raise {
  let glyph = font.glyph_for_scalar(expectation.scalar).unwrap()
  inspect(glyph.value() == expectation.glyph_id, content="true")
  inspect(expectation.fingerprint_sha256.length() == 64, content="true")
  let path = font.outline(glyph, font_qualification_outline_budget()).unwrap()
  inspect(path.length() == expectation.commands.length(), content="true")
  for index, command in expectation.commands {
    font_qualification_assert_command(
      path,
      index,
      command.kind,
      command.x1,
      command.y1,
      command.x2,
      command.y2,
    )
  }
}

///|
fn font_qualification_assert_metrics(
  font : Font,
  glyph : GlyphId,
  advance : UInt64,
  lsb : Int,
  x_min : Int,
  y_min : Int,
  x_max : Int,
  y_max : Int,
) -> Unit raise {
  let metrics = font.horizontal_metrics(glyph).unwrap()
  inspect(metrics.advance_width() == advance, content="true")
  inspect(metrics.left_side_bearing() == lsb, content="true")
  font_qualification_assert_bounds(
    metrics.bounds().unwrap(),
    x_min,
    y_min,
    x_max,
    y_max,
  )
}

///|
test "font-complete-public freezes compact public workflow facts" {
  let owner = font_test_owner(font_qualification_compact_bytes())
  let font = Font::open(
    owner.view(),
    font_qualification_limits(),
    font_qualification_admission_budget(),
  ).unwrap()
  inspect(font.units_per_em().unwrap(), content="1000")
  font_qualification_assert_bounds(font.global_bounds().unwrap(), 0, 0, 0, 0)
  font_qualification_assert_line_metrics(
    font.hhea_line_metrics().unwrap(),
    0,
    0,
    0,
  )
  font_qualification_assert_line_metrics(
    font.typographic_line_metrics().unwrap(),
    0,
    0,
    0,
  )
  let simple_glyph = font.glyph_for_scalar(0x0041).unwrap()
  let composite_glyph = font.glyph_for_scalar(0x10300).unwrap()
  inspect(simple_glyph.value(), content="1")
  inspect(composite_glyph.value(), content="2")
  font_qualification_assert_metrics(font, simple_glyph, 500UL, 0, 0, 0, 100, 100)
  font_qualification_assert_metrics(
    font,
    composite_glyph,
    500UL,
    0,
    -32768,
    -32768,
    32767,
    32767,
  )

  let simple = font
    .outline(simple_glyph, font_qualification_outline_budget())
    .unwrap()
  inspect(simple.length(), content="5")
  font_qualification_assert_command(simple, 0, "M", 0.0, 0.0, 0.0, 0.0)
  font_qualification_assert_command(simple, 1, "Q", 50.0, 0.0, 75.0, 0.0)
  font_qualification_assert_command(simple, 2, "Q", 100.0, 0.0, 100.0, 100.0)
  font_qualification_assert_command(simple, 3, "L", 0.0, 100.0, 0.0, 0.0)
  font_qualification_assert_command(simple, 4, "Z", 0.0, 0.0, 0.0, 0.0)

  let composite = font
    .outline(composite_glyph, font_qualification_outline_budget())
    .unwrap()
  inspect(composite.length(), content="10")
  font_qualification_assert_command(composite, 0, "M", 10.0, -4.0, 0.0, 0.0)
  font_qualification_assert_command(composite, 1, "Q", 35.0, -4.0, 47.5, -4.0)
  font_qualification_assert_command(composite, 2, "Q", 60.0, -4.0, 60.0, 46.0)
  font_qualification_assert_command(composite, 3, "L", 10.0, 46.0, 0.0, 0.0)
  font_qualification_assert_command(composite, 4, "Z", 0.0, 0.0, 0.0, 0.0)
  font_qualification_assert_command(composite, 5, "M", 60.0, 46.0, 0.0, 0.0)
  font_qualification_assert_command(composite, 6, "Q", 85.0, 46.0, 97.5, 46.0)
  font_qualification_assert_command(composite, 7, "Q", 110.0, 46.0, 110.0, 96.0)
  font_qualification_assert_command(composite, 8, "L", 60.0, 96.0, 0.0, 0.0)
  font_qualification_assert_command(composite, 9, "Z", 0.0, 0.0, 0.0, 0.0)
  inspect(font.kerning(simple_glyph, composite_glyph).unwrap(), content="-37")
}

///|
test "font-complete-public exercises the compact format-4 branch" {
  let cmap = font_test_cmap_format4_two_segments().to_array()
  font_test_put_u16(cmap, 40, 0UL)
  font_test_put_u16(cmap, 36, 0xFFC0UL)
  let owner = font_test_owner(
    font_test_truetype_with_cmap_and_glyphs(Bytes::from_array(cmap), 2UL),
  )
  let font = Font::open(
    owner.view(),
    font_qualification_limits(),
    font_qualification_admission_budget(),
  ).unwrap()
  inspect(font.glyph_for_scalar(0x0041).unwrap().value(), content="1")
  inspect(font.glyph_for_scalar(0x0042).unwrap().value(), content="0")
}

///|
fn font_qualification_assert_dejavu_public_facts(font : Font) -> Unit raise {
  inspect(font.units_per_em().unwrap(), content="2048")
  font_qualification_assert_bounds(
    font.global_bounds().unwrap(),
    -2090,
    -948,
    3673,
    2524,
  )
  font_qualification_assert_line_metrics(
    font.hhea_line_metrics().unwrap(),
    1901,
    -483,
    0,
  )
  font_qualification_assert_line_metrics(
    font.typographic_line_metrics().unwrap(),
    1556,
    -492,
    410,
  )

  let a = font.glyph_for_scalar(0x0041).unwrap()
  let e_acute = font.glyph_for_scalar(0x00E9).unwrap()
  let combining_almost_equal = font.glyph_for_scalar(0x034C).unwrap()
  let old_italic_a = font.glyph_for_scalar(0x10300).unwrap()
  inspect(a.value(), content="36")
  inspect(e_acute.value(), content="171")
  inspect(combining_almost_equal.value(), content="765")
  inspect(old_italic_a.value(), content="5373")
  font_qualification_assert_metrics(font, a, 1401UL, 16, 16, 0, 1384, 1493)
  font_qualification_assert_metrics(
    font,
    e_acute,
    1260UL,
    113,
    113,
    -29,
    1151,
    1638,
  )
  font_qualification_assert_metrics(
    font,
    combining_almost_equal,
    0UL,
    -842,
    -842,
    1221,
    -182,
    1680,
  )
  font_qualification_assert_metrics(
    font,
    old_italic_a,
    1550UL,
    100,
    100,
    -29,
    1450,
    1493,
  )

  let e_error = font
    .outline(e_acute, font_qualification_outline_budget())
    .unwrap_err()
  inspect(e_error.category() == @error.ErrorCategory::Capability, content="true")
  inspect(
    e_error.code() == @error.ErrorCode::CapabilityUnavailable,
    content="true",
  )
  inspect(
    e_error.context() == Some("font-outline-grid-rounding"),
    content="true",
  )

  let supported_outlines = font_qualification_dejavu_supported_outlines()
  inspect(supported_outlines.length(), content="3")
  for expectation in supported_outlines {
    font_qualification_assert_outline_expectation(font, expectation)
  }

  let v = font.glyph_id(57UL).unwrap()
  inspect(font.kerning(a, v).unwrap(), content="-131")
}

///|
test "font-complete-public freezes DejaVu Sans 2.37 public facts" {
  let owner = font_test_owner(font_qualification_dejavu_sans_237_bytes())
  let font = Font::open(
    owner.view(),
    font_qualification_limits(),
    font_qualification_admission_budget(),
  ).unwrap()
  font_qualification_assert_dejavu_public_facts(font)
}

///|
fn font_qualification_collection_limits(
  source_length : UInt64,
  faces : UInt64,
  records : UInt64,
) -> FontCollectionLimits {
  FontCollectionLimits::new(
    max_source_bytes=source_length,
    max_faces=faces,
    max_tables_per_face=64UL,
    max_table_records=records,
    max_dsig_records=8UL,
    max_dsig_bytes=65536UL,
    max_retained_bookkeeping_bytes=1000000UL,
    max_work=10000000UL,
  ).unwrap()
}

///|
fn font_qualification_collection_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=2000000UL,
      allocations=64UL,
      allocation_size=1000000UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=0UL,
      work=20000000UL,
    ),
  )
}

///|
fn font_qualification_assert_public_collection_case_ids() -> Unit raise {
  let cases = font_collection_qualification_cases()
  let expected_ids = [
    "generated-ttc-v1-static-selected",
    "generated-ttc-v2-dsig-absent",
    "generated-ttc-v2-dsig-present-unverified",
    "generated-ttc-v1-exact-sharing",
    "generated-ttc-v2-mixed-profiles",
    "generated-ttc-v1-nonzero-directory-base",
    "licensed-dejavu-two-face-v1-face-0",
    "licensed-dejavu-two-face-v1-face-1",
  ]
  inspect(cases.length() >= expected_ids.length(), content="true")
  for index = 0; index < expected_ids.length(); index = index + 1 {
    let expected = cases[index]
    inspect(expected.id == expected_ids[index], content="true")
    inspect(expected.group == "public_workflows", content="true")
    inspect(expected.stage == "select", content="true")
    inspect(expected.entrypoint == "FontCollection::open_face", content="true")
    inspect(expected.boundary == "success", content="true")
    inspect(expected.publication == "font", content="true")
  }
}

///|
test "font-complete-public qualifies generated collection workflows" {
  font_qualification_assert_public_collection_case_ids()

  let selected_source = font_collection_test_selected_ttc()
  let selected_owner = font_collection_test_owner(selected_source)
  let selected = FontCollection::open(
    selected_owner.view(),
    font_collection_test_selected_limits(selected_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  inspect(selected.face_count().unwrap(), content="1")
  inspect(
    selected.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  inspect(
    selected.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
  inspect(
    selected
    .open_face(0UL, font_test_limits(), font_collection_test_selected_budget())
    .unwrap()
    .units_per_em()
    .unwrap(),
    content="1000",
  )

  let shared_source = font_collection_test_shared_selected_ttc()
  let shared_owner = font_collection_test_owner(shared_source)
  let shared = FontCollection::open(
    shared_owner.view(),
    font_collection_test_selected_collection_limits(
      shared_source.length().to_uint64(),
      2UL,
      20UL,
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  inspect(shared.face_count().unwrap(), content="2")
  for index in [0UL, 1UL] {
    inspect(
      shared.face_profile(index).unwrap() == FontFaceProfile::StaticGlyf,
      content="true",
    )
    inspect(
      shared
      .open_face(index, font_test_limits(), font_collection_test_selected_budget())
      .unwrap()
      .units_per_em()
      .unwrap(),
      content="1000",
    )
  }

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
  inspect(mixed.face_count().unwrap(), content="5")
  for
    item in [
      (0UL, FontFaceProfile::StaticGlyf),
      (1UL, FontFaceProfile::Cff),
      (2UL, FontFaceProfile::Cff2),
      (3UL, FontFaceProfile::Variable),
      (4UL, FontFaceProfile::OtherUnsupported),
    ] {
    let (index, profile) = item
    inspect(mixed.face_profile(index).unwrap() == profile, content="true")
  }
  inspect(
    mixed.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )

  let dsig_source = font_collection_test_dsig_ttc()
  let dsig_owner = font_collection_test_owner(dsig_source)
  let dsig = FontCollection::open(
    dsig_owner.view(),
    font_collection_test_dsig_limits(1UL, 32UL, 57UL),
    font_collection_test_dsig_budget(57UL),
  ).unwrap()
  inspect(
    dsig.dsig_status().unwrap() == FontCollectionDsigStatus::PresentUnverified,
    content="true",
  )
}

///|
test "font-complete-public qualifies licensed DejaVu collection faces" {
  font_qualification_assert_public_collection_case_ids()
  let cases = font_collection_qualification_cases()
  inspect(cases[6].fixture_id == "licensed-dejavu-two-face-v1", content="true")
  inspect(cases[6].face_index == Some(0UL), content="true")
  inspect(cases[7].fixture_id == "licensed-dejavu-two-face-v1", content="true")
  inspect(cases[7].face_index == Some(1UL), content="true")

  let source = font_qualification_dejavu_two_face_ttc_v1_bytes()
  inspect(source.length(), content="757428")
  let owner = font_test_owner(source)
  let collection = FontCollection::open(
    owner.view(),
    font_qualification_collection_limits(
      source.length().to_uint64(),
      2UL,
      40UL,
    ),
    font_qualification_collection_budget(),
  ).unwrap()
  inspect(collection.face_count().unwrap(), content="2")
  inspect(
    collection.dsig_status().unwrap() == FontCollectionDsigStatus::Absent,
    content="true",
  )
  for index in [0UL, 1UL] {
    inspect(
      collection.face_profile(index).unwrap() == FontFaceProfile::StaticGlyf,
      content="true",
    )
    let font = collection
      .open_face(
        index,
        font_qualification_limits(),
        font_qualification_admission_budget(),
      )
      .unwrap()
    font_qualification_assert_dejavu_public_facts(font)
  }
}

///|
fn font_qualification_assert_static_glyf_semantic_compatibility() -> Unit raise {
  let standalone_source = font_collection_test_equivalence_truetype()
  let standalone_owner = font_test_owner(standalone_source)
  let standalone = Font::open(
    standalone_owner.view(),
    font_collection_test_selected_font_limits(
      standalone_source.length().to_uint64(),
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  let collection_source = font_collection_test_selected_ttc_from(
    standalone_source,
  )
  let collection_owner = font_collection_test_owner(collection_source)
  let collection = FontCollection::open(
    collection_owner.view(),
    font_collection_test_selected_collection_limits(
      collection_source.length().to_uint64(),
      1UL,
      11UL,
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  let selected = collection
    .open_face(
      0UL,
      font_collection_test_selected_font_limits(
        collection_source.length().to_uint64(),
      ),
      font_collection_test_selected_budget(),
    )
    .unwrap()

  inspect(collection.face_count().unwrap() == 1UL, content="true")
  inspect(
    collection.face_profile(0UL).unwrap() == FontFaceProfile::StaticGlyf,
    content="true",
  )
  for font in [standalone, selected] {
    inspect(font.units_per_em().unwrap() == 1000UL, content="true")
    font_qualification_assert_bounds(font.global_bounds().unwrap(), 0, 0, 0, 0)
    let a = font.glyph_for_scalar(0x0041).unwrap()
    let smile = font.glyph_for_scalar(0x1F600).unwrap()
    inspect(a.value() == 1UL, content="true")
    inspect(smile.value() == 2UL, content="true")
    font_qualification_assert_metrics(font, a, 600UL, 10, 0, 0, 100, 100)
    let smile_metrics = font.horizontal_metrics(smile).unwrap()
    inspect(smile_metrics.advance_width() == 700UL, content="true")
    inspect(smile_metrics.left_side_bearing() == -20, content="true")
    inspect(smile_metrics.bounds() is None, content="true")
    inspect(font.kerning(a, smile).unwrap() == -37, content="true")
    let path = font
      .outline(a, font_test_composite_budget())
      .unwrap()
    inspect(path.length() == 4, content="true")
    font_qualification_assert_command(path, 0, "M", 0.0, 0.0, 0.0, 0.0)
    font_qualification_assert_command(path, 1, "L", 100.0, 0.0, 0.0, 0.0)
    font_qualification_assert_command(path, 2, "Q", 100.0, 100.0, 0.0, 0.0)
    font_qualification_assert_command(path, 3, "Z", 0.0, 0.0, 0.0, 0.0)
  }

  let invalid_gid = standalone.glyph_id(3UL).unwrap_err()
  inspect(
    invalid_gid.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(
    invalid_gid.code() == @error.ErrorCode::InvalidRange,
    content="true",
  )
  inspect(invalid_gid.operation() == Some("font-glyph-id"), content="true")
  inspect(invalid_gid.context() == Some("font-glyph-id-range"), content="true")
  inspect(invalid_gid.requested() == Some(3UL), content="true")
  inspect(invalid_gid.limit() == Some(3UL), content="true")

  let mutation_source = font_collection_test_selected_ttc()
  let mutation_owner = font_collection_test_owner(mutation_source)
  let mutation_collection = FontCollection::open(
    mutation_owner.view(),
    font_collection_test_selected_limits(
      mutation_source.length().to_uint64(),
    ),
    font_collection_test_selected_budget(),
  ).unwrap()
  let before_mutation_budget = font_collection_test_selected_budget()
  let before_mutation = before_mutation_budget.remaining()
  let index_error = mutation_collection
    .open_face(1UL, font_test_limits(), before_mutation_budget)
    .unwrap_err()
  inspect(
    index_error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(
    index_error.context() == Some("font-collection-face-index"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    before_mutation,
    before_mutation_budget,
  )
  font_collection_test_mutate(mutation_owner, 20UL, b'\x01')
  let after_mutation_budget = font_collection_test_selected_budget()
  let after_mutation = after_mutation_budget.remaining()
  let state_error = mutation_collection
    .open_face(1UL, font_test_limits(), after_mutation_budget)
    .unwrap_err()
  inspect(state_error.category() == @error.ErrorCategory::State, content="true")
  inspect(
    state_error.context() == Some("font-collection-source-revision-drift"),
    content="true",
  )
  font_collection_test_assert_budget_unchanged(
    after_mutation,
    after_mutation_budget,
  )

  let exact_owner = font_test_owner(font_test_minimal_truetype())
  let exact_budget = font_test_budget_with_dimensions(
    460UL,
    allocations=3UL,
    allocation_size=640UL,
    1296UL,
  )
  let exact_before = exact_budget.remaining()
  ignore(
    Font::open(
      exact_owner.view(),
      font_test_limits(),
      exact_budget,
    ).unwrap(),
  )
  let exact_after = exact_budget.remaining()
  inspect(exact_before.bytes() - exact_after.bytes() == 460UL, content="true")
  inspect(
    exact_before.allocations() - exact_after.allocations() == 3UL,
    content="true",
  )
  inspect(exact_after.allocation_size() == 640UL, content="true")
  inspect(exact_before.work() - exact_after.work() == 1296UL, content="true")

  let selected_source = font_collection_test_selected_ttc()
  let selected_owner = font_collection_test_owner(selected_source)
  let selected_collection = FontCollection::open(
    selected_owner.view(),
    font_collection_test_selected_limits(selected_source.length().to_uint64()),
    font_collection_test_selected_budget(),
  ).unwrap()
  let face_limits = font_collection_test_selected_font_limits(
    selected_source.length().to_uint64(),
    max_work=658UL,
  )
  let face_budget = font_collection_test_selected_budget_with(
    454UL,
    3UL,
    640UL,
    658UL,
  )
  let face_before = face_budget.remaining()
  ignore(
    selected_collection
    .open_face(0UL, face_limits, face_budget)
    .unwrap(),
  )
  let face_after = face_budget.remaining()
  inspect(face_before.bytes() - face_after.bytes(), content="454")
  inspect(
    face_before.allocations() - face_after.allocations() == 3UL,
    content="true",
  )
  inspect(face_after.allocation_size(), content="640")
  inspect(face_before.work() - face_after.work(), content="658")

  let ancestor = font_collection_test_selected_budget_with(
    454UL,
    3UL,
    640UL,
    658UL,
  )
  let child = ancestor.child(ancestor.remaining()).unwrap()
  ancestor.charge(
    @budget.ResourceCharge::new(
      bytes=1UL,
      allocations=0UL,
      allocation_size=0UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      work=0UL,
    ),
  ).unwrap()
  let ancestor_before = ancestor.remaining()
  let child_before = child.remaining()
  let ancestor_error = selected_collection
    .open_face(0UL, face_limits, child)
    .unwrap_err()
  inspect(
    ancestor_error.category() == @error.ErrorCategory::Resource,
    content="true",
  )
  inspect(
    ancestor_error.code() == @error.ErrorCode::BudgetExceeded,
    content="true",
  )
  inspect(ancestor_error.operation() == Some("budget_charge"), content="true")
  inspect(ancestor_error.context() == Some("bytes"), content="true")
  inspect(ancestor_error.requested() == Some(454UL), content="true")
  inspect(ancestor_error.limit() == Some(453UL), content="true")
  font_collection_test_assert_budget_unchanged(ancestor_before, ancestor)
  font_collection_test_assert_budget_unchanged(child_before, child)
}

///|
test "font-cff1-v3 freezes static glyf semantic compatibility" {
  font_qualification_assert_static_glyf_semantic_compatibility()
}
