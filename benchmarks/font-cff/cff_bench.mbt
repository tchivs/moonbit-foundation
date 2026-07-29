// Fixed native release observations over the closed CFF1 qualification carrier.
//
// The package/file path is the only supported selector:
// moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen
//
// Fixture reconstruction and correctness checks stay outside measured closures.
// Every Font open and every outline operation receives a newly constructed
// same-limit Budget; each operation owns the instance it receives.

///|
fn cff_benchmark_require(condition : Bool, message : String) -> Unit {
  if !condition {
    abort(message)
  }
}

///|
fn cff_benchmark_budget() -> @budget.Budget {
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
fn cff_benchmark_limits(source_length : UInt64) -> @font.FontLimits {
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
fn cff_benchmark_owner(source : Bytes) -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(source, cff_benchmark_budget()).unwrap()
}

///|
fn cff_benchmark_assert_workload(
  index : Int,
  id : String,
  fixture_id : String,
  operation : String,
  correctness_input : String,
  correctness_input_sha256 : String,
) -> CffEvidenceWorkload {
  let workloads = cff_evidence_workloads()
  cff_benchmark_require(workloads.length() == 4, "CFF workload count")
  let workload = workloads[index]
  cff_benchmark_require(workload.id == id, "CFF workload identity")
  cff_benchmark_require(
    workload.fixture_id == fixture_id,
    "CFF workload fixture identity",
  )
  cff_benchmark_require(
    workload.operation == operation,
    "CFF workload operation",
  )
  cff_benchmark_require(
    workload.correctness_input == correctness_input,
    "CFF workload correctness input",
  )
  cff_benchmark_require(
    workload.correctness_input_sha256 == correctness_input_sha256,
    "CFF workload correctness digest",
  )
  cff_benchmark_require(!workload.timing, "CFF portable workload timing flag")
  workload
}

///|
fn cff_benchmark_assert_font_identity(
  font : @font.Font,
  expected : CffEvidencePublicFact,
) -> Unit raise {
  let glyph = font.glyph_for_scalar(expected.scalar).unwrap()
  cff_benchmark_require(
    glyph.value() == expected.gid.to_uint64(),
    "CFF benchmark mapped GID",
  )
  let metrics = font.horizontal_metrics(glyph).unwrap()
  cff_benchmark_require(
    metrics.advance_width() == expected.advance.to_uint64(),
    "CFF benchmark advance",
  )
  cff_benchmark_require(
    metrics.left_side_bearing() == expected.lsb,
    "CFF benchmark side bearing",
  )
}

///|
fn cff_benchmark_open(
  owner : @bytes.OwnedBytes,
) -> @font.Font raise {
  @font.Font::open(
    owner.view(),
    cff_benchmark_limits(owner.length()),
    cff_benchmark_budget(),
  ).unwrap()
}

///|
fn cff_benchmark_glyphs(
  font : @font.Font,
  gids : Array[Int],
) -> Array[@font.GlyphId] raise {
  let glyphs = []
  for gid in gids {
    glyphs.push(font.glyph_id(gid.to_uint64()).unwrap())
  }
  glyphs
}

///|
fn cff_benchmark_assert_outlines(
  font : @font.Font,
  glyphs : Array[@font.GlyphId],
) -> Unit raise {
  for glyph in glyphs {
    let path = font.outline(glyph, cff_benchmark_budget()).unwrap()
    cff_benchmark_require(path.length() > 0, "CFF benchmark nonempty outline")
  }
}

///|
test "bench cff/latin-full-admission" (b : @bench.T) {
  let source = cff_evidence_source_sans_payload()
  let owner = cff_benchmark_owner(source)
  let workload = cff_benchmark_assert_workload(
    0,
    "latin-full-admission",
    "source-sans-3.052R",
    "full-admission",
    "latin-full-admission|source-sans-3.052R|all-2478",
    "18ee23225ee236464bff292ecbb27b8730f0a91a61ef8580565d665e53b976f6",
  )
  cff_benchmark_require(workload.gids.length() == 0, "Latin admission GIDs")
  let font = cff_benchmark_open(owner)
  cff_benchmark_assert_font_identity(font, cff_evidence_public_facts()[4])
  b.bench(fn() {
    b.keep(
      @font.Font::open(
        owner.view(),
        cff_benchmark_limits(owner.length()),
        cff_benchmark_budget(),
      ),
    )
  })
}

///|
test "bench cff/cjk-full-admission" (b : @bench.T) {
  let source = cff_evidence_source_han_payload()
  let owner = cff_benchmark_owner(source)
  let workload = cff_benchmark_assert_workload(
    1,
    "cjk-full-admission",
    "source-han-serif-jp-2.003R",
    "full-admission",
    "cjk-full-admission|source-han-serif-jp-2.003R|all-17923",
    "9eb460dcf7adf96bf2c6ebd66a06b1ca50d21b17d2b6a4b1af118c222f6575f6",
  )
  cff_benchmark_require(workload.gids.length() == 0, "CJK admission GIDs")
  let font = cff_benchmark_open(owner)
  cff_benchmark_assert_font_identity(font, cff_evidence_public_facts()[5])
  b.bench(fn() {
    b.keep(
      @font.Font::open(
        owner.view(),
        cff_benchmark_limits(owner.length()),
        cff_benchmark_budget(),
      ),
    )
  })
}

///|
test "bench cff/latin-fixed-outline-batch" (b : @bench.T) {
  let source = cff_evidence_source_sans_payload()
  let owner = cff_benchmark_owner(source)
  let workload = cff_benchmark_assert_workload(
    2,
    "latin-fixed-outline-batch",
    "source-sans-3.052R",
    "outline-batch",
    "latin-fixed-outline-batch|source-sans-3.052R|2,3,34,97,321,1024,2477",
    "cb351d9e0af5379e261c3e5cd014b77048943419c42a0a52d60be4c8d7f73994",
  )
  let font = cff_benchmark_open(owner)
  let glyphs = cff_benchmark_glyphs(font, workload.gids)
  cff_benchmark_assert_outlines(font, glyphs)
  b.bench(fn() {
    for glyph in glyphs {
      b.keep(font.outline(glyph, cff_benchmark_budget()))
    }
  })
}

///|
test "bench cff/cjk-high-gid-multi-fd-outline-batch" (b : @bench.T) {
  let source = cff_evidence_source_han_payload()
  let owner = cff_benchmark_owner(source)
  let workload = cff_benchmark_assert_workload(
    3,
    "cjk-high-gid-multi-fd-outline-batch",
    "source-han-serif-jp-2.003R",
    "outline-batch",
    "cjk-high-gid-multi-fd-outline-batch|source-han-serif-jp-2.003R|2,256,2048,8192,16384,17922",
    "c5ee2c463a026a7b1cd65206a20c753fc520f3619deb06be84ff993e9c544fd8",
  )
  let font = cff_benchmark_open(owner)
  let glyphs = cff_benchmark_glyphs(font, workload.gids)
  cff_benchmark_assert_outlines(font, glyphs)
  b.bench(fn() {
    for glyph in glyphs {
      b.keep(font.outline(glyph, cff_benchmark_budget()))
    }
  })
}
