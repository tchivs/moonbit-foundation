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
}
