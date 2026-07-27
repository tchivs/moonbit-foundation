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
test "font-complete-public freezes DejaVu Sans 2.37 public facts" {
  let owner = font_test_owner(font_qualification_dejavu_sans_237_bytes())
  let font = Font::open(
    owner.view(),
    font_qualification_limits(),
    font_qualification_admission_budget(),
  ).unwrap()
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

  let a_path = font.outline(a, font_qualification_outline_budget()).unwrap()
  inspect(a_path.length(), content="13")
  font_qualification_assert_command(a_path, 0, "M", 700.0, 1294.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 1, "L", 426.0, 551.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 2, "L", 975.0, 551.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 3, "Z", 0.0, 0.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 4, "M", 586.0, 1493.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 5, "L", 815.0, 1493.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 6, "L", 1384.0, 0.0, 0.0, 0.0)
  font_qualification_assert_command(a_path, 7, "L", 1174.0, 0.0, 0.0, 0.0)

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

  let composite_path = font
    .outline(combining_almost_equal, font_qualification_outline_budget())
    .unwrap()
  inspect(composite_path.length(), content="48")
  font_qualification_assert_command(
    composite_path,
    0,
    "M",
    -516.0,
    1264.0,
    0.0,
    0.0,
  )
  font_qualification_assert_command(
    composite_path,
    1,
    "L",
    -573.0,
    1297.0,
    0.0,
    0.0,
  )
  font_qualification_assert_command(
    composite_path,
    2,
    "Q",
    -598.0,
    1311.0,
    -613.5,
    1316.5,
  )
  font_qualification_assert_command(
    composite_path,
    3,
    "Q",
    -629.0,
    1322.0,
    -641.0,
    1322.0,
  )
  font_qualification_assert_command(
    composite_path,
    4,
    "Q",
    -677.0,
    1322.0,
    -697.0,
    1297.0,
  )
  font_qualification_assert_command(
    composite_path,
    5,
    "Q",
    -717.0,
    1272.0,
    -717.0,
    1227.0,
  )
  font_qualification_assert_command(
    composite_path,
    6,
    "L",
    -717.0,
    1221.0,
    0.0,
    0.0,
  )
  font_qualification_assert_command(
    composite_path,
    7,
    "L",
    -842.0,
    1221.0,
    0.0,
    0.0,
  )

  let old_italic_path = font
    .outline(old_italic_a, font_qualification_outline_budget())
    .unwrap()
  inspect(old_italic_path.length(), content="13")
  font_qualification_assert_command(old_italic_path, 0, "M", 100.0, 35.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 1, "L", 660.0, 1493.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 2, "L", 890.0, 1493.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 3, "L", 1450.0, 35.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 4, "L", 1282.0, -29.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 5, "L", 1089.0, 473.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 6, "L", 461.0, 473.0, 0.0, 0.0)
  font_qualification_assert_command(old_italic_path, 7, "L", 268.0, -29.0, 0.0, 0.0)

  let v = font.glyph_id(57UL).unwrap()
  inspect(font.kerning(a, v).unwrap(), content="-131")
}
