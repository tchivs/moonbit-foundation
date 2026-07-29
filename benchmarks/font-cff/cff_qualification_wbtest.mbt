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
