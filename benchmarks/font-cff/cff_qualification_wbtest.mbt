///|
fn cff_evidence_public_limits() -> @font.FontLimits {
  @font.FontLimits::new(
    max_source_bytes=1UL,
    max_tables=1UL,
    max_table_bytes=1UL,
    max_glyphs=1UL,
    max_name_records=1UL,
    max_cmap_records=1UL,
    max_kern_subtables=1UL,
    max_kern_pairs=1UL,
    max_outline_points=1UL,
    max_outline_contours=1UL,
    max_outline_components=1UL,
    max_outline_instruction_bytes=1UL,
    max_post_name_bytes=1UL,
    max_work=1UL,
  ).unwrap()
}

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
fn cff_evidence_collection_limits(
  source_length : UInt64,
  faces : UInt64,
) -> @font.FontCollectionLimits {
  @font.FontCollectionLimits::new(
    max_source_bytes=source_length,
    max_faces=faces,
    max_tables_per_face=256UL,
    max_table_records=512UL,
    max_dsig_records=16UL,
    max_dsig_bytes=1000000UL,
    max_retained_bookkeeping_bytes=1000000000UL,
    max_work=1000000000UL,
  ).unwrap()
}

///|
fn cff_evidence_read_u16(input : Bytes, offset : Int) -> UInt64 {
  (input[offset].to_uint64() << 8) | input[offset + 1].to_uint64()
}

///|
fn cff_evidence_single_face_ttc(standalone : Bytes) -> Bytes {
  let face_offset = 16
  let output = Array::make(standalone.length() + face_offset, b'\x00')
  _cff_evidence_put_u32(output, 0, 0x74746366UL)
  _cff_evidence_put_u32(output, 4, 0x00010000UL)
  _cff_evidence_put_u32(output, 8, 1UL)
  _cff_evidence_put_u32(output, 12, face_offset.to_uint64())
  for index = 0; index < standalone.length(); index = index + 1 {
    output[face_offset + index] = standalone[index]
  }
  let table_count = cff_evidence_read_u16(standalone, 4).to_int()
  for record = 0; record < table_count; record = record + 1 {
    let offset_field = face_offset + 12 + record * 16 + 8
    _cff_evidence_put_u32(
      output,
      offset_field,
      _cff_evidence_read_u32(standalone, 12 + record * 16 + 8) +
      face_offset.to_uint64(),
    )
  }
  Bytes::from_array(output)
}

///|
fn cff_evidence_assert_path_command(
  actual : @math.PathCommand?,
  expected : CffEvidencePathCommand,
) -> Unit raise {
  match actual {
    Some(@math.PathCommand::MoveTo(point)) => {
      inspect(expected.op == "MoveTo", content="true")
      inspect(expected.points.length() == 2, content="true")
      inspect(point.x() == expected.points[0].to_double(), content="true")
      inspect(point.y() == expected.points[1].to_double(), content="true")
    }
    Some(@math.PathCommand::LineTo(point)) => {
      inspect(expected.op == "LineTo", content="true")
      inspect(expected.points.length() == 2, content="true")
      inspect(point.x() == expected.points[0].to_double(), content="true")
      inspect(point.y() == expected.points[1].to_double(), content="true")
    }
    Some(@math.PathCommand::CubicTo(first, second, endpoint)) => {
      inspect(expected.op == "CubicTo", content="true")
      inspect(expected.points.length() == 6, content="true")
      inspect(first.x() == expected.points[0].to_double(), content="true")
      inspect(first.y() == expected.points[1].to_double(), content="true")
      inspect(second.x() == expected.points[2].to_double(), content="true")
      inspect(second.y() == expected.points[3].to_double(), content="true")
      inspect(endpoint.x() == expected.points[4].to_double(), content="true")
      inspect(endpoint.y() == expected.points[5].to_double(), content="true")
    }
    Some(@math.PathCommand::Close) => {
      inspect(expected.op == "Close", content="true")
      inspect(expected.points.length() == 0, content="true")
    }
    Some(@math.PathCommand::QuadTo(_, _)) =>
      fail("CFF public observation emitted an unexpected quadratic command")
    None => fail("CFF public observation omitted an expected path command")
  }
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

///|
fn cff_evidence_assert_font(
  font : @font.Font,
  expected : CffEvidencePublicFact,
) -> Unit raise {
  let glyph = font.glyph_for_scalar(expected.scalar).unwrap()
  inspect(glyph.value() == expected.gid.to_uint64(), content="true")
  let metrics = font.horizontal_metrics(glyph).unwrap()
  inspect(
    metrics.advance_width() == expected.advance.to_uint64(),
    content="true",
  )
  inspect(metrics.left_side_bearing() == expected.lsb, content="true")
  let bounds = metrics.bounds().unwrap()
  inspect(bounds.x_min() == expected.bounds[0], content="true")
  inspect(bounds.y_min() == expected.bounds[1], content="true")
  inspect(bounds.x_max() == expected.bounds[2], content="true")
  inspect(bounds.y_max(), content=expected.bounds[3].to_string())
  let partner = font
    .glyph_id(if expected.gid == 2 { 1UL } else { 2UL })
    .unwrap()
  inspect(font.kerning(glyph, partner).unwrap() == expected.kerning, content="true")
  let path = font.outline(glyph, cff_evidence_budget()).unwrap()
  inspect(path.length() == expected.path.length(), content="true")
  for index, command in expected.path {
    cff_evidence_assert_path_command(path.get(index), command)
  }
}

///|
fn cff_evidence_assert_standalone(
  source : Bytes,
  expected : CffEvidencePublicFact,
) -> Unit raise {
  let owner = cff_evidence_owner(source)
  let font = @font.Font::open(
    owner.view(),
    cff_evidence_limits(owner.length()),
    cff_evidence_budget(),
  ).unwrap()
  cff_evidence_assert_font(font, expected)
}

///|
fn cff_evidence_assert_selected(
  source : Bytes,
  face_index : UInt64,
  expected : CffEvidencePublicFact,
) -> Unit raise {
  let owner = cff_evidence_owner(source)
  let collection = @font.FontCollection::open(
    owner.view(),
    cff_evidence_collection_limits(
      owner.length(),
      _cff_evidence_read_u32(source, 8),
    ),
    cff_evidence_budget(),
  ).unwrap()
  let font = collection
    .open_face(
      face_index,
      cff_evidence_limits(owner.length()),
      cff_evidence_budget(),
    )
    .unwrap()
  cff_evidence_assert_font(font, expected)
}

///|
fn cff_evidence_assert_generated_name_tracer() -> Unit raise {
  let expected = cff_evidence_public_facts()[0]
  let standalone = cff_evidence_generated_name_otf()
  cff_evidence_assert_standalone(standalone, expected)
  cff_evidence_assert_selected(
    cff_evidence_single_face_ttc(standalone),
    0UL,
    expected,
  )
}

///|
fn cff_evidence_assert_every_public_workflow() -> Unit raise {
  let facts = cff_evidence_public_facts()
  let generated_name = cff_evidence_generated_name_otf()
  cff_evidence_assert_standalone(generated_name, facts[0])
  cff_evidence_assert_selected(
    cff_evidence_single_face_ttc(generated_name),
    0UL,
    facts[0],
  )
  let generated_cid = cff_evidence_generated_cid_otf()
  cff_evidence_assert_standalone(generated_cid, facts[1])
  cff_evidence_assert_selected(
    cff_evidence_single_face_ttc(generated_cid),
    0UL,
    facts[1],
  )
  let shared = cff_evidence_generated_shared_ttc()
  cff_evidence_assert_selected(shared, 0UL, facts[2])
  cff_evidence_assert_selected(shared, 1UL, facts[3])
  let latin = cff_evidence_source_sans_payload()
  cff_evidence_assert_standalone(latin, facts[4])
  cff_evidence_assert_selected(
    cff_evidence_single_face_ttc(latin),
    0UL,
    facts[4],
  )
  let cjk = cff_evidence_source_han_payload()
  cff_evidence_assert_standalone(cjk, facts[5])
  cff_evidence_assert_selected(
    cff_evidence_single_face_ttc(cjk),
    0UL,
    facts[5],
  )
}

///|
fn cff_evidence_assert_public_mutation() -> Unit raise {
  let owner = cff_evidence_owner(cff_evidence_generated_name_otf())
  let font = @font.Font::open(
    owner.view(),
    cff_evidence_limits(owner.length()),
    cff_evidence_budget(),
  ).unwrap()
  let glyph = font.glyph_for_scalar(65).unwrap()
  inspect(glyph.value(), content="1")
  owner.with_mut(0UL, 1UL, fn(lease) {
    lease.set(0UL, lease.get(0UL).unwrap())
  }).unwrap()
  for error in [
    font.glyph_for_scalar(65).unwrap_err(),
    font.horizontal_metrics(glyph).unwrap_err(),
    font.kerning(glyph, glyph).unwrap_err(),
  ] {
    inspect(error.category() == @error.ErrorCategory::State, content="true")
    inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
    inspect(error.operation(), content="Some(font-query)")
    inspect(error.context(), content="Some(font-source-revision-drift)")
  }
  let budget = cff_evidence_budget()
  let before = budget.remaining()
  let error = font.outline(glyph, budget).unwrap_err()
  inspect(error.category() == @error.ErrorCategory::State, content="true")
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation(), content="Some(font-outline)")
  inspect(error.context(), content="Some(font-source-revision-drift)")
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(
    after.allocation_size() == before.allocation_size(),
    content="true",
  )
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")
}

///|
fn cff_evidence_assert_correctness_workloads() -> Unit raise {
  let workloads = cff_evidence_workloads()
  let expected_ids = [
    "latin-full-admission",
    "cjk-full-admission",
    "latin-fixed-outline-batch",
    "cjk-high-gid-multi-fd-outline-batch",
  ]
  let expected_fixtures = [
    "source-sans-3.052R",
    "source-han-serif-jp-2.003R",
    "source-sans-3.052R",
    "source-han-serif-jp-2.003R",
  ]
  let expected_inputs = [
    "latin-full-admission|source-sans-3.052R|all-2478",
    "cjk-full-admission|source-han-serif-jp-2.003R|all-17923",
    "latin-fixed-outline-batch|source-sans-3.052R|2,3,34,97,321,1024,2477",
    "cjk-high-gid-multi-fd-outline-batch|source-han-serif-jp-2.003R|2,256,2048,8192,16384,17922",
  ]
  let expected_digests = [
    "175c0cf2f13f2abcb7f7de2f8e441e9356c0bc9068df2f0a1435177b8ee70e11",
    "26029f450cca92ffbf4d9ce17822b6a17f9dedb0174cbc2e8b26d633b70a5ae5",
    "48c7790a5567310e260779f0a2fe5cc703a5137a154738537ab264fb3d12105d",
    "9dcb9a9ac2e9081e857f427c34de1e2b87be13457592dd4d4387d5cd767b02cb",
  ]
  inspect(workloads.length() == 4, content="true")
  for index, workload in workloads {
    inspect(workload.id == expected_ids[index], content="true")
    inspect(
      workload.fixture_id == expected_fixtures[index],
      content="true",
    )
    inspect(workload.correctness_input == expected_inputs[index], content="true")
    inspect(
      workload.correctness_output_sha256 == expected_digests[index],
      content="true",
    )
    inspect(!workload.timing, content="true")
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
    if workload.operation == "full-admission" {
      inspect(workload.gids.length() == 0, content="true")
    } else {
      inspect(workload.operation == "outline-batch", content="true")
      for gid in workload.gids {
        let path = font
          .outline(
            font.glyph_id(gid.to_uint64()).unwrap(),
            cff_evidence_budget(),
          )
          .unwrap()
        inspect(path.length() > 0, content="true")
      }
    }
  }
}

///|
test "cff evidence/public-font-resolution-tracer" {
  let limits = cff_evidence_public_limits()
  inspect(limits.max_source_bytes(), content="1")
  inspect(limits.max_glyphs(), content="1")
}

///|
test "cff evidence/single private payload and fact carrier" {
  inspect(cff_evidence_source_sans_payload().length(), content="334924")
  inspect(cff_evidence_source_han_payload().length(), content="6210796")
  inspect(cff_evidence_generated_name_otf().length() > 0, content="true")
  inspect(cff_evidence_generated_cid_otf().length() > 0, content="true")
  inspect(cff_evidence_generated_shared_ttc().length() > 0, content="true")
  inspect(cff_evidence_public_facts().length(), content="6")
  inspect(cff_evidence_hostile_rows().length(), content="53")
  inspect(cff_evidence_targets().length(), content="4")
  inspect(cff_evidence_workloads().length(), content="4")
  inspect(cff_evidence_public_workflow_ids().length(), content="12")
  inspect(cff_evidence_compatibility_lock_ids().length(), content="2")
  inspect(cff_evidence_b8_order().length(), content="8")
  inspect(cff_evidence_generated_workflows().length(), content="6")
  inspect(cff_evidence_precedence_facts().length(), content="2")
}

///|
test "font-cff1-v3 carrier-public generated-name standalone and selected tracer" {
  cff_evidence_assert_generated_name_tracer()
}

///|
test "font-cff1-v3 carrier-public every standalone and selected workflow" {
  cff_evidence_assert_every_public_workflow()
}

///|
test "font-cff1-v3 carrier-public caller mutation is exact and atomic" {
  cff_evidence_assert_public_mutation()
}

///|
test "font-cff1-v3 carrier-public timing-free correctness workloads" {
  cff_evidence_assert_correctness_workloads()
}

///|
test "font-cff1-v3 runtime semantic tracer" {
  for index = 0; index < cff_evidence_workloads().length(); index = index + 1 {
    println(
      "MNF_CFF_RUNTIME|" +
      cff_evidence_workloads()[index].id +
      "|" +
      cff_evidence_runtime_semantics(index),
    )
  }
}
