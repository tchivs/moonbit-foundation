# Changelog

All notable changes to `tchivs/mb-font` will be recorded in this file. This
module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-26

Compatibility status: candidate. No stable API or public release is claimed.

### Added

- `tchivs/mb-font/font`: portable, bounded admission of one standalone
  TrueType-outline SFNT from a caller-provided byte view, explicit `FontLimits`,
  and an authoritative `mb-core` budget.
- Opaque admitted `Font` and `GlyphId` values with retained-source mutation
  invalidation.
- Named global metric sources from `head`, `hhea`, and `OS/2`.
- Exact per-glyph `hmtx` advance/left-bearing semantics, optional common-header
  `glyf` bounds, empty-glyph handling, and checked right-side-bearing
  derivation.
- Deterministic one-scalar Unicode mapping through the canonical format-12 or
  format-4 `cmap`, returning an opaque glyph identity and glyph zero for a valid
  miss.
- Optional basic legacy horizontal `kern` version-0 format-0 pair lookup with
  exact signed adjustments and distinct absent, miss, unsupported, malformed,
  and retained-source mutation outcomes.
- Explicit nonzero `max_kern_subtables` and `max_kern_pairs` ceilings with
  preflighted exact work and caller-budget accounting.
- Direct guarded `Font::outline(glyph, budget)` extraction into the shared
  `mb-core/math` `Path2`, with independent per-query budgets and two retained
  source-revision guards.
- Four explicit nonzero outline ceilings for points, contours, composite
  descriptors, and per-glyph instruction bytes, intersected with `maxp`,
  cumulative `max_work`, and caller budgets.
- Complete unhinted simple-glyph lowering with strict packed/repeated flags,
  signed deltas, implied on-curve midpoints, encoded contour order/winding, and
  explicit closure.
- Bounded one-level composite outlines with ordered simple/empty components,
  signed XY and encoded-real point attachment, uniform/independent/2-by-2
  F2DOT14 transforms, and deterministic scaled/unscaled/default offsets.
- Checked signed `Int64` Q15 arithmetic through transformation and attachment,
  crossing to public `Double` coordinates only during final `Point2`
  construction.
- Transactional hostile-input behavior with distinct
  `InvalidInput`/`Data`/`Capability`/`Resource`/`State` outcomes and no partial
  geometry publication.
- Deterministic generated micro-font qualification across `js`, `wasm`,
  `wasm-gc`, and `native`.
- FONT-05 complete public-workflow qualification with the exact 580-byte compact
  command oracle and the licensed, immutable 757,076-byte DejaVu Sans 2.37
  interoperability specimen.
- Independently derived DejaVu mapping, named metric, `Path2`, capability, and
  legacy-kerning facts bound to the upstream font and notice digests and their
  exact `Bitstream-Vera AND LicenseRef-DejaVu-Arev` provenance.
- A closed eleven-case hostile matrix for malformed data, unsupported
  capabilities, mutation, checked ranges, source limits, admission and outline
  budgets, and nested composites, executed identically on `js`, `wasm`,
  `wasm-gc`, and `native`.
- Canonical four-target evidence records whose normalized semantics retain all
  public, hostile, fixture, toolchain, and dependency facts.
- Bounded TTC/OTC version 1/version 2 collection inspection with exact face
  count, ordered static-glyf/CFF/CFF2/variable/other profiles, and
  absent/present-unverified DSIG facts.
- Selected static-glyf face admission through the existing `Font` contract,
  preserving root-relative ranges, caller/ancestor budgets, retained-source
  identity, and atomic mutation failure.
- The licensed 757,428-byte two-face DejaVu derivative, SHA-256
  `833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b`,
  with retained upstream notice, exact table sharing, a metadata-only
  collection oracle, and both faces bound to the standalone oracle.
- Phase 103 hostile, limit, budget, public mutation, and deterministic private
  transition qualification across all four supported targets.
- Managed `font-complete-public-v2` evidence with four ordered target records,
  closed focused identities, discovered complete-package pass totals, and
  semantic equality after removing only top-level target and runner.
- Bounded static CFF1 admission for opaque standalone `OTTO` fonts and selected
  `StaticCff` collection faces through the existing `Font`, `FontLimits`,
  caller-budget, retained-source, metrics, mapping, kerning, and transactional
  cubic `Path2` contract.
- Canonical generated name-keyed, CID-keyed, hostile, Type 2, geometry, limit,
  and mutation vectors plus exact-upstream Source Sans 3 3.052R and Source Han
  Serif JP 2.003R specimens with retained OFL-1.1 licenses.
- Two-reader semantic agreement from the independent fontTools and AFDKO
  readers, with OTS retained as a structural-only observation.
- Managed `font-complete-public-v3` evidence with exactly four ordered target
  records and equality after removing only top-level target and runner.
- A non-published `benchmarks/font-cff` evidence module with package-private
  generated payload; production `mb-font` contains no licensed CFF bytes or
  fixture API.
- A separate observation-only native baseline owned by Wave 6, without a
  threshold, comparison, verdict, ranking, superiority, release, or stability
  claim.
- Opaque `GlyphId` values now retain private physical `Font` ownership, so
  aliases of one font remain compatible while distinct same-range fonts fail
  before glyph table or budget work.
- Additive `Font::with_shape_transaction[T]` request authority with the exact
  generic tuple callback, checked combined charge, whole-hierarchy preflight,
  final retained-source guard, and sole budget commit. A scope may nominally
  escape through generic `T` or closure capture, but shared runtime
  invalidation makes every later operation fail as closed; no static lifetime
  enforcement is claimed.

### Fixed

- Valid Macintosh platform 1, encoding 0, format-6 `cmap` records may coexist
  with a canonical format-4/12 Unicode map. Format 6 remains private,
  non-selectable, non-queryable, and uncharged as supported mapping-body work;
  malformed or wrong-domain records still fail closed.

The candidate still does not claim deeper composite geometry, phantom-point
placement, grid rounding or hinting execution, rasterization, WOFF1/WOFF2
admission, CFF2 selection or execution, variable instantiation, DSIG
cryptographic trust, color/bitmap glyphs, text shaping/layout/discovery,
collection extraction/materialization, font writing/editing, ambient
filesystem/network or host discovery, FFI, or additional formats. Phase 107
qualification does not claim a threshold, cross-target/library comparison,
superiority, registry publication, stability promotion,
release-policy change, or a new public API.
