// Shared, timing-free native correctness serialization for qualification and
// benchmark capture. Keep this outside *_wbtest.mbt so `moon bench` and the
// four-target qualification tracer execute the same serializer.

///|
fn cff_evidence_limits(source_length : UInt64) -> @font.FontLimits {
  @font.FontLimits::new(
    max_source_bytes=source_length,
    max_tables=256UL,
    max_table_bytes=source_length,
    max_glyphs=20000UL,
    max_name_records=100000UL,
    max_cmap_records=256UL,
    max_kern_subtables=256UL,
    max_kern_pairs=100000UL,
    max_outline_points=1000000UL,
    max_outline_contours=100000UL,
    max_outline_components=100000UL,
    max_outline_instruction_bytes=1000000UL,
    max_post_name_bytes=1000000UL,
    max_work=1000000000UL,
  ).unwrap()
}

///|
fn cff_evidence_budget() -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes=1000000000UL,
      allocations=1000000UL,
      allocation_size=1000000000UL,
      width=0UL,
      height=0UL,
      pixels=0UL,
      depth=1000000UL,
      work=1000000000UL,
    ),
  )
}

///|
fn cff_evidence_owner(source : Bytes) -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(source, cff_evidence_budget()).unwrap()
}

///|
fn cff_evidence_write_point(
  output : StringBuilder,
  point : @math.Point2,
) -> Unit {
  output.write_string(point.x().to_string())
  output.write_string(",")
  output.write_string(point.y().to_string())
}

///|
fn cff_evidence_write_path(
  output : StringBuilder,
  path : @math.Path2,
) -> Unit raise {
  output.write_string("path=")
  output.write_string(path.length().to_string())
  output.write_string("[")
  for index = 0; index < path.length(); index = index + 1 {
    if index > 0 {
      output.write_string(";")
    }
    match path.get(index) {
      Some(@math.PathCommand::MoveTo(point)) => {
        output.write_string("M(")
        cff_evidence_write_point(output, point)
        output.write_string(")")
      }
      Some(@math.PathCommand::LineTo(point)) => {
        output.write_string("L(")
        cff_evidence_write_point(output, point)
        output.write_string(")")
      }
      Some(@math.PathCommand::QuadTo(control, endpoint)) => {
        output.write_string("Q(")
        cff_evidence_write_point(output, control)
        output.write_string(",")
        cff_evidence_write_point(output, endpoint)
        output.write_string(")")
      }
      Some(@math.PathCommand::CubicTo(first, second, endpoint)) => {
        output.write_string("C(")
        cff_evidence_write_point(output, first)
        output.write_string(",")
        cff_evidence_write_point(output, second)
        output.write_string(",")
        cff_evidence_write_point(output, endpoint)
        output.write_string(")")
      }
      Some(@math.PathCommand::Close) => output.write_string("Z")
      None => fail("runtime semantic path omitted a command")
    }
  }
  output.write_string("]")
}

///|
fn cff_evidence_write_glyph_semantics(
  output : StringBuilder,
  font : @font.Font,
  gid_value : Int,
) -> Unit raise {
  let glyph = font.glyph_id(gid_value.to_uint64()).unwrap()
  let metrics = font.horizontal_metrics(glyph).unwrap()
  let bounds = metrics.bounds().unwrap()
  let path = font.outline(glyph, cff_evidence_budget()).unwrap()
  output.write_string("gid=")
  output.write_string(glyph.value().to_string())
  output.write_string(",advance=")
  output.write_string(metrics.advance_width().to_string())
  output.write_string(",lsb=")
  output.write_string(metrics.left_side_bearing().to_string())
  output.write_string(",bounds=")
  output.write_string(bounds.x_min().to_string())
  output.write_string(",")
  output.write_string(bounds.y_min().to_string())
  output.write_string(",")
  output.write_string(bounds.x_max().to_string())
  output.write_string(",")
  output.write_string(bounds.y_max().to_string())
  output.write_string(",")
  cff_evidence_write_path(output, path)
}

///|
fn cff_evidence_runtime_semantics(index : Int) -> String raise {
  let workload = cff_evidence_workloads()[index]
  let source = if workload.fixture_id == "source-sans-3.052R" {
    cff_evidence_source_sans_payload()
  } else {
    cff_evidence_source_han_payload()
  }
  let owner = cff_evidence_owner(source)
  let font = @font.Font::open(
    owner.view(),
    cff_evidence_limits(owner.length()),
    cff_evidence_budget(),
  ).unwrap()
  let output = StringBuilder::new()
  output.write_string("cff-runtime-semantics/1|workload=")
  output.write_string(workload.id)
  output.write_string("|fixture=")
  output.write_string(workload.fixture_id)
  output.write_string("|source_length=")
  output.write_string(owner.length().to_string())
  output.write_string("|operation=")
  output.write_string(workload.operation)
  if workload.operation == "full-admission" {
    let fact = cff_evidence_public_facts()[if index == 0 { 4 } else { 5 }]
    let glyph = font.glyph_for_scalar(fact.scalar).unwrap()
    let partner = font
      .glyph_id(if fact.gid == 2 { 1UL } else { 2UL })
      .unwrap()
    output.write_string("|scalar=")
    output.write_string(fact.scalar.to_string())
    output.write_string("|mapped_gid=")
    output.write_string(glyph.value().to_string())
    output.write_string("|kerning=")
    output.write_string(font.kerning(glyph, partner).unwrap().to_string())
    output.write_string("|")
    cff_evidence_write_glyph_semantics(output, font, fact.gid)
  } else {
    output.write_string("|glyphs=")
    output.write_string(workload.gids.length().to_string())
    output.write_string("[")
    for gid_index, gid in workload.gids {
      if gid_index > 0 {
        output.write_string(";")
      }
      cff_evidence_write_glyph_semantics(output, font, gid)
    }
    output.write_string("]")
  }
  output.to_string()
}
