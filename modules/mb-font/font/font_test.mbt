///|
fn assert_invalid_font_limit(
  result : Result[FontLimits, @error.CoreError],
  context : String,
) -> Unit {
  let error = result.unwrap_err()
  inspect(
    error.category() == @error.ErrorCategory::InvalidInput,
    content="true",
  )
  inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
  inspect(error.operation() == Some("font-limits-new"), content="true")
  inspect(error.requested() == Some(0UL), content="true")
  inspect(error.limit() == Some(1UL), content="true")
  inspect(error.context() == Some(context), content="true")
}

///|
test "font limits preserve every explicit semantic ceiling" {
  let limits = FontLimits::new(
    max_source_bytes=1024UL,
    max_tables=10UL,
    max_table_bytes=256UL,
    max_glyphs=4UL,
    max_name_records=3UL,
    max_cmap_records=2UL,
    max_post_name_bytes=64UL,
    max_work=4096UL,
  ).unwrap()
  inspect(limits.max_source_bytes(), content="1024")
  inspect(limits.max_tables(), content="10")
  inspect(limits.max_table_bytes(), content="256")
  inspect(limits.max_glyphs(), content="4")
  inspect(limits.max_name_records(), content="3")
  inspect(limits.max_cmap_records(), content="2")
  inspect(limits.max_post_name_bytes(), content="64")
  inspect(limits.max_work(), content="4096")
}

///|
test "font limits reject every zero semantic ceiling" {
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=0UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-source-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=0UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-tables",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=0UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-table-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=0UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-glyphs",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=0UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-name-records",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=0UL,
      max_post_name_bytes=1UL,
      max_work=1UL,
    ),
    "max-cmap-records",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=0UL,
      max_work=1UL,
    ),
    "max-post-name-bytes",
  )
  assert_invalid_font_limit(
    FontLimits::new(
      max_source_bytes=1UL,
      max_tables=1UL,
      max_table_bytes=1UL,
      max_glyphs=1UL,
      max_name_records=1UL,
      max_cmap_records=1UL,
      max_post_name_bytes=1UL,
      max_work=0UL,
    ),
    "max-work",
  )
}
