# Project Research Summary

**Project:** MoonBit Native Foundation — v0.32 TrueType Font Foundation
**Domain:** Portable, bounded SFNT/TrueType parsing and reusable glyph-outline extraction
**Researched:** 2026-07-26
**Confidence:** HIGH

## Executive Summary

v0.32 should establish a small, independently publishable `tchivs/mb-font@0.1.0` module that turns caller-provided static TrueType bytes into trustworthy metrics, Unicode mappings, legacy kerning values, and unhinted reusable outlines. Expert implementations treat fonts as hostile random-access binary structures: they validate the complete SFNT directory and its cross-table graph before publishing a font, retain only checked table windows and bounded indexes, and decode glyph geometry on demand. The module must remain pure MoonBit, portable across `js`, `wasm`, `wasm-gc`, and `native`, depend only on `tchivs/mb-core`, and return `mb-core/math.Path2` rather than importing canvas or a foreign font stack.

The recommended architecture is an opaque `Font` opened from `ByteView`, explicit semantic `FontLimits`, and a shared `Budget`. Admission validates a standalone `0x00010000` SFNT, table ranges/checksums, required tables, and the `head`/`maxp`/`hhea`/`hmtx`/`loca`/`glyf`/`cmap` relationships. Queries then provide named global metrics, per-glyph horizontal metrics, deterministic cmap format 12-then-4 mapping, optional version-0 format-0 horizontal kerning, and transactional simple or one-level composite outline extraction. Exact integer and fixed-point facts should be retained until the final `Path2` conversion.

The dominant risks are arithmetic overflow before bounds checks, individually valid tables that disagree, packed glyph data that expands beyond its input size, incorrect quadratic or composite geometry, source mutation after zero-copy admission, and tests that are portable or legally reproducible only by accident. Prevent them at the architecture boundary: checked ranges before narrowing, a single cross-table publication gate, caller-authoritative semantic limits, active-stack cycle detection, a private numbered-point model, mutation-revision checks on every source-reading query, no partial `Font` or path results, and immutable generated plus licensed real-font fixtures with semantic assertions on all four targets.

## Key Findings

### Hard Constraints and Recommended Decisions

The research distinguishes milestone/RFC obligations from implementation choices that can still be refined without changing v0.32's product boundary.

**Hard constraints:**

- The runtime implementation is pure MoonBit and independently publishable as `tchivs/mb-font`; its only public runtime dependency is `tchivs/mb-core`.
- The same public contract runs on `js`, `wasm`, `wasm-gc`, and `native`. No FFI, ambient filesystem access, installed-font discovery, target-specific parser, or foreign runtime oracle is allowed.
- Input is a caller-provided retained byte view. Every attacker-controlled offset, length, count, expansion, allocation, and unit of work is checked and budgeted before unsafe use.
- v0.32 accepts one static TrueType-outline SFNT with `sfntVersion = 0x00010000`. CFF/CFF2, TTC/OTC, WOFF/WOFF2, variations, color/bitmap glyphs, hinting execution, shaping, rasterization, authoring, and font selection remain outside the milestone.
- Admission and outline extraction are atomic. Malformed data, unsupported capabilities, invalid queries, resource exhaustion, and changed backing storage remain distinguishable structured outcomes; no partial font or geometry is published.
- Outlines use the existing `mb-core/math.Path2` seam. `mb-font` must not depend on `mb-canvas`, `mb-image`, or `mb-color`.

**Recommended implementation decisions:**

- Use one public `font` package with private files/components rather than publishing raw `sfnt`, `cmap`, or `glyf` packages.
- Prefer `Font::open(source, limits, budget)` as the candidate constructor because semantic `FontLimits` are a first-class contract; the shorter `Font::parse(source, budget)` in stack research is conceptual, not a competing requirement.
- Retain validated directory/core-table/`loca`/cmap metadata, but decode outlines on demand. Do not add a persistent implicit glyph cache; a bounded request-local composite memo is acceptable.
- Use generated micro-fonts for branch isolation and at least one provenance-tracked real font for interoperability. Two complementary real specimens are preferred if licensing and feature coverage can be made explicit without bloating the repository.

### Recommended Stack

Use the repository-pinned MoonBit toolchain: `moon` and `moonrun` `0.1.20260713` (`75c7e1f`, 2026-07-13) with `moonc v0.10.4+2cc641edf` (2026-07-15). The normative binary profile is OpenType Specification 1.9.1, and Unicode scalar validation follows Unicode 17.0.0. The implementation should use only existing `mb-core@0.1.0` contracts and require no external package installation.

**Core technologies:**

- `mb-core/bytes.ByteView` — retained root bytes and zero-copy checked table subviews; pair with the opening mutation revision.
- `mb-core/checked` — `CheckedRange`, checked add/multiply/subtract, and explicit narrowing for every derived range, count, and index.
- `mb-core/budget.Budget` plus semantic `FontLimits` — shared bytes/allocation/work/depth accounting plus font-specific ceilings for tables, glyphs, cmap structures, instructions, points, contours, components, kern pairs, transforms, and output commands.
- `mb-core/error.CoreError` — stable categories and context for operation, table/glyph, source offset, requested amount, and limit.
- `mb-core/math.Path2` — public `MoveTo`, `LineTo`, `QuadTo`, and `Close` geometry consumed directly by downstream canvas/document tools.
- Private big-endian random-access cursor — table-local checked reads over `ByteView`; `BoundedReader` remains appropriate only for a future stream-to-owned-buffer adapter because it does not seek.

Keep the current JSON module manifest style and declare `preferred-target: native` with `supported-targets: +js+wasm+wasm-gc+native`. Run isolated and workspace-wide `moon check`/`moon test --target all --frozen`, review generated `.mbti` changes, and record exact tool versions in qualification evidence.

### Expected Features

**Must have (v0.32 table stakes):**

- Portable module, opaque font/ID model, immutable source lifetime, explicit limits and budgets, stable structured errors, and no dependency beyond `mb-core`.
- Fail-closed SFNT admission: signature, checked directory size, sorted unique tags, aligned/contained/non-overlapping table windows, checksums including `head.checksumAdjustment`, and allowance for unknown well-formed optional tables.
- Structural presence/validation of `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`, `loca`, and `glyf`.
- Named font-wide facts: units-per-em, global bounds, `hhea` ascent/descent/lineGap, and `OS/2` typographic ascent/descent/lineGap. Do not invent one “best” line metric.
- Per-glyph advance, left side bearing, bounds, and checked derived right side bearing, including the `hmtx` repeat-final-advance tail rule and metrics for empty glyphs.
- Deterministic Unicode cmap formats 12 and 4, supplementary-plane support, valid-scalar misses mapped to glyph zero, invalid-scalar query errors, and range checking against `numGlyphs`.
- Transactional simple outlines with exact flag/delta decoding, implied on-curve points, contour order/winding/closure preservation, bounded skipped instructions, and late conversion to `Path2`.
- Bounded one-level composite outlines with byte/word arguments, XY and point attachment, uniform/nonuniform/2×2 F2DOT14 transforms, cycle/fan-out/depth controls, metric interaction policy, and exact checked intermediates.
- Optional legacy `kern` version-0 horizontal format-0 pair lookup: signed hit, zero for absence or supported miss, and distinct unsupported/malformed outcomes.
- Generated conformance/adversarial vectors, licensed immutable real-font evidence, and identical public semantic facts and errors on all four targets.

**Should have (differentiators):**

- Direct outline-to-`Path2` composition without canvas coupling.
- Cross-table validation rather than isolated record decoding.
- Caller limits intersected with valid font declarations; `maxp` never grants resource permission.
- Operation-local atomicity so one bad or over-budget glyph does not poison a valid admitted font.
- Deterministic cmap/kern capability selection and compact public-workflow semantic digests.

**Defer to v0.32.x only with evidence:**

- Caller-owned outline cache with explicit identity and byte/entry limits.
- Composite depth beyond one if licensed corpus evidence shows the v0.32 boundary is impractical.
- Additional read-only `name`, `post`, or `OS/2` fields and additional legacy cmap/kern formats required by a concrete consumer.

**Defer to later focused milestones:**

- CFF/CFF2, variable and color/bitmap fonts, hinting, TTC/OTC and WOFF/WOFF2 adapters, shaping/GPOS/GSUB/bidi/fallback, discovery/registry APIs, rasterization, and font writing/subsetting.

### Architecture Approach

Create one opaque validated font index over retained bytes. `Font::open` first passes a top-level SFNT gate, then a cross-table gate, then atomically publishes bounded structural indexes. Every decoder receives a checked table or glyph subview, never root bytes plus a raw offset. Cmap, metrics, and kern queries use validated indexes; outline queries decode on demand into private numbered points and contours, resolve simple/composite geometry, and lower once to `Path2`.

**Major components:**

1. **Public facade and limits** — opaque `Font`, `GlyphId`, metrics/outline values, query methods, `FontLimits`, and stable error construction.
2. **Checked binary substrate** — table-local big-endian cursor, range/narrowing helpers, and budget charging.
3. **SFNT structural gate** — signature, directory, tags, ranges, overlap, alignment, checksum verification, and retained table records.
4. **Cross-table index** — supported `head`, `maxp`, `hhea`, `OS/2`, exact `hmtx`, normalized `loca`, required-table presence, and mutation revision.
5. **Character map** — fully validated selected format 12 or 4 index and binary lookup with glyph-range enforcement.
6. **Metrics and kerning** — named global/per-glyph facts and optional validated legacy pair search.
7. **Glyph model and decoders** — simple packed data and bounded composite resolution into numbered points/contours with request-local scratch.
8. **Outline normalizer** — implied-point rules and transactional `Path2` construction.
9. **Fixture and qualification system** — deterministic micro-font generator, mutation corpus, licensed specimen manifest, portable byte literals, semantic oracles, and four-target selectors.

The dependency remains `mb-font -> mb-core <- mb-canvas`. Expected repository integration includes `modules/mb-font`, a public portable example, `fixtures/font`, `fixtures/manifest.json`, workspace/policy inventory, and quality-script qualification; existing `mb-core` and `mb-canvas` APIs should not need modification.

### Reconciled Research Decisions

The four reports agree on the architecture but use different shorthand in a few places. Roadmap planning should use these resolved rules:

1. **Constructor and limits:** adopt the architecture form `Font::open(source, limits, budget)` for planning. A separate semantic `FontLimits` type is required because generic budget dimensions do not express font-specific expansion ceilings.
2. **Required tables:** require all ten tables named by stack/features (`cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`, `loca`, `glyf`). The shorter architecture gate list describes actively decoded dependencies, not permission to omit `name`, `OS/2`, or `post`; `OS/2` is decoded for named metrics while `name`/`post` need only bounded structural/version validation in v0.32.
3. **Directory search fields:** derive lookup/search behavior from `numTables` and never trust stored helpers. If the chosen strict profile requires canonical stored fields, validate them as data but do not use them to navigate.
4. **Unsupported `kern`:** validate every subtable envelope. Well-formed unsupported subtables may be skipped while searching for a supported one; if a present table provides no supported profile, the capability/query returns `UnsupportedFeature`, not zero. Malformed data remains an error; absence and supported misses return zero.
5. **Composite depth:** implement cycle-safe recursive machinery with active-stack detection and cumulative limits, but enforce the v0.32 public capability at one composite level. A recursive implementation is a safety mechanism, not a broader feature claim.
6. **Kerning phase:** place `kern` in Phase 2 with glyph IDs and metrics. It has no outline dependency, and early completion clarifies absent/miss/unsupported semantics before geometry work.
7. **Real-font corpus:** DejaVu Sans 2.37 is a candidate, not yet accepted evidence. Record its extracted TTF digest, table inventory, source/license notice, and intended facts. Prefer a second complementary licensed font to satisfy broader feature research, but treat exact specimen count as a planning acceptance choice; immutable provenance and required feature coverage are non-negotiable.

### Critical Pitfalls

1. **Unchecked arithmetic before narrowing** — keep wire values widened; use checked add/multiply/range/subrange and narrow only after containment. Generate exact-fit, one-short, overflow, and backend-narrowing vectors for every derived expression.
2. **Trusting the table directory or parsing tables independently** — reject duplicate/unsorted/overlapping/misaligned/out-of-range/checksum-invalid records and publish only after all cardinalities and glyph references agree.
3. **Budgeting bytes but not logical expansion** — charge expanded flags, points, contours, cmap groups, components, transforms, checksum scans, allocations, and emitted commands; `maxp` is a consistency claim, never resource authority.
4. **Losing TrueType geometry during lowering** — retain full numbered contours, decode streams separately, insert implied midpoints deterministically, and keep composite point attachment/transforms in exact integer/fixed-point domains before one final `Path2` lowering.
5. **Unsafe composite traversal and metric approximation** — enforce depth plus active-stack cycle detection, cumulative fan-out limits, transform flag rules, and an explicit phantom-point/`USE_MY_METRICS` policy; reject unsupported vertical phantom behavior rather than inventing it.
6. **Time-of-check/time-of-use mutation** — retain and verify `mutation_revision` before every operation that reads source bytes, even if bytes were changed back to their original value.
7. **Portable-looking but non-reproducible evidence** — never read host fonts or network in tests; record exact fixture bytes/digests, provenance, license, table inventory, and semantic expectations, then run identical vectors independently on all four targets.

## Implications for Roadmap

Based on the combined dependency graph and pitfall timing, use five phases. Each phase must add its own hostile boundary tests; Phase 5 verifies the whole system but must not be the first point where safety is addressed.

### Phase 1: Module Contract and SFNT Admission

**Rationale:** Every later feature depends on one trusted table map and stable ownership/resource/error contracts. Establishing this first prevents each table decoder from inventing offset or budget rules.

**Delivers:** `tchivs/mb-font@0.1.0` skeleton; one public portable package; opaque public types; `FontLimits`; checked big-endian cursor; retained `ByteView` and mutation revision; signature/directory/tag/range/alignment/overlap/checksum gate; required-table discovery; atomic font publication; workspace/policy/quality integration; initial deterministic fixture generator.

**Addresses:** Portable module, bounded immutable-byte admission, SFNT integrity, required-table contract, stable error/limit semantics.

**Avoids:** Offset/count overflow, duplicate or aliased table records, host-state/FFI coupling, partial font publication, input-byte-only budgets, and zero-copy mutation races.

### Phase 2: Core Tables, Metrics, Cmap, and Kern

**Rationale:** Metrics, normalized glyph locations, glyph identity, and the composite metric policy form the cross-table contract required by all geometry. Legacy kerning depends only on admitted glyph IDs, so it belongs here rather than with composites.

**Delivers:** Supported `head`, `maxp`, `hhea`, `OS/2`, `hmtx`, and `loca`; exact cross-table cardinalities; named global/per-glyph metrics; empty-glyph behavior; deterministic cmap format 12/4 selection and Unicode scalar API; validated optional kern format-0 lookup; contract decision for horizontal phantom points and `USE_MY_METRICS`.

**Addresses:** Global/per-glyph metrics, Unicode mapping, legacy kerning, cross-table validation, normalized checked glyph windows.

**Avoids:** Incorrect short/long `loca`, flattened `hmtx` tails, out-of-range glyph references, platform-dependent cmap selection, malformed/unsupported kern ambiguity, and undocumented line-metric or phantom-point policy.

### Phase 3: Simple Glyph Outlines

**Rationale:** Composite correctness depends on a complete, exact private representation of simple children and a proven normalization seam.

**Delivers:** Simple `glyf` header/contour validation; bounded instruction skipping; exact repeated-flag and x/y delta expansion; checked coordinate accumulation; private numbered points/contours; implied on-curve midpoint and wraparound rules; transactional `Path2` emission in original contour order/winding.

**Addresses:** Simple unhinted outline extraction and direct `Path2` composition.

**Avoids:** Compact expansion bombs, repeat off-by-one errors, reset/overflowed deltas, malformed stream repair, lost implied points, degenerate-contour panics, partial paths, and premature floating-point conversion.

### Phase 4: Composite Glyph Outlines

**Rationale:** Composite decoding layers recursion, cumulative budgets, transforms, point attachment, and metric inheritance over the Phase 2/3 contracts; it is the milestone's highest semantic-risk phase.

**Delivers:** Bounded one-level composite capability; active-stack cycle detection; request-local charged memo/scratch; byte/word XY and point arguments; uniform, x/y, and 2×2 F2DOT14 transforms; scaled/unscaled/default offset behavior; parent/child point attachment; approved phantom-point and `USE_MY_METRICS` behavior; exact checked accumulation and final `Path2` lowering.

**Addresses:** Credible accented/reused TrueType outlines and operation-local atomicity.

**Avoids:** Trusting `maxComponentDepth`, exponential fan-out, false global “seen” rejection, contradictory flags, wrong transform order/signedness, missing point numbering, phantom-point approximation, and cross-target numeric drift.

### Phase 5: Hostile, Interoperable, and Portable Qualification

**Rationale:** Acceptance requires reproducible proof at the public workflow boundary, not only parser unit tests. Qualification follows stable semantics so fixture facts and public digests do not churn.

**Delivers:** Complete generated micro-font and mutation matrix; short/long `loca`, cmap, metrics, simple/composite, kern, budget, mutation, and error vectors; provenance/licensing checks; accepted real-font specimens; public `bytes -> font -> cmap -> metrics -> outline -> kern` example; isolated and workspace-wide four-target qualification; documented API and evidence.

**Addresses:** Four-target conformance, real-font interoperability, fixture governance, error stability, and the full FONT-01 through FONT-05 workflow.

**Avoids:** Host-installed or moving fixtures, missing extracted digests/licenses, production-code-generated oracles, foreign-tool runtime dependency, visual-only geometry assertions, and target-specific semantic drift.

### Phase Ordering Rationale

- A validated table-window invariant, limits, ownership, and errors must precede every table implementation.
- Metrics and cmap establish glyph identity and valid glyph windows; composite metric/phantom behavior must be decided before composite code.
- Simple outlines supply the private numbered-point model and normalization algorithm that composites reuse.
- Composite work follows simple geometry because it adds recursion and transforms but must not redefine base contour semantics.
- Qualification is last for frozen public facts, while adversarial unit vectors are created alongside each phase so safety is never deferred.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 4:** Resolve unhinted horizontal phantom-point numbering, `USE_MY_METRICS`, multiple/conflicting metric flags, point-attachment references, default scaled/unscaled component-offset behavior, and the exact fixed-point evaluation/rounding rule from authoritative OpenType text.
- **Phase 5:** Finalize the real-font corpus, extracted SHA-256 values, table inventories, redistribution notices, portable byte-literal generation, and independent semantic oracle facts. DejaVu Sans 2.37 remains provisional until those records exist.

Phases with established patterns (skip broad research-phase):

- **Phase 1:** Repository module/workspace/policy conventions and `mb-core` checked range, budget, error, retained-view, and mutation contracts are directly available; planning should inspect exact local APIs rather than repeat ecosystem research.
- **Phase 2:** OpenType table layouts and required validation matrices are well documented in the existing research; targeted spec checks are sufficient.
- **Phase 3:** Simple `glyf` packing and quadratic normalization have explicit normative rules and a clear generated-vector test strategy.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Exact repository toolchain and `mb-core` seams were inspected; OpenType 1.9.1 and Unicode 17.0.0 are official normative sources. Real-font fixture selection remains provisional. |
| Features | HIGH | Scope and module boundaries align with RFC 0004, current project constraints, and official table behavior; exact pre-1.0 API names remain intentionally open. |
| Architecture | HIGH | The validated-index, checked-subview, on-demand decode, private point model, and `Path2` dependency direction converge across all research and existing repository contracts. |
| Pitfalls | HIGH | Failure modes are concrete, mapped to the earliest prevention phase, and paired with boundary/adversarial verification. A few composite edge semantics require targeted confirmation. |

**Overall confidence:** HIGH

### Gaps to Address

- **Composite phantom points and metrics:** Freeze supported horizontal phantom references, vertical-reference rejection, `USE_MY_METRICS`, and multiple-flag behavior in Phase 2 planning, then validate implementation in Phase 4.
- **Composite transform arithmetic:** Specify exact F2DOT14 composition order, offset default, rounding/conversion, safe geometry envelope, and canonical cross-target numeric evidence before coding transforms.
- **Strict directory profile:** Confirm whether noncanonical stored `searchRange`/`entrySelector`/`rangeShift` values are rejected or merely ignored; navigation must always use derived facts.
- **`name`/`post` structural depth:** Define the minimum bounded/version validation needed for required-table admission without accidentally promising a metadata API.
- **Real-font evidence:** Capture extracted-file digests, exact table inventories, source dates, licenses/notices, redistribution status, and feature-purpose mappings; select a second specimen only if it adds demonstrable coverage.
- **Candidate API shape:** Review `.mbti` ergonomics for `Font::open`, `FontLimits`, opaque `GlyphId`, `GlyphOutline`, and kerning capability errors before stabilizing the 0.1 surface.

## Sources

### Primary (HIGH confidence)

- [RFC 0004: `mb-font` charter](../../docs/rfcs/0004-mb-font.md) — authoritative module boundary, portable targets, hostile-input posture, unhinted geometry, and downstream ownership.
- [`STACK.md`](STACK.md), [`FEATURES.md`](FEATURES.md), [`ARCHITECTURE.md`](ARCHITECTURE.md), and [`PITFALLS.md`](PITFALLS.md) — detailed repository and domain research synthesized here.
- [OpenType Specification 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/) and [OpenType Font File](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — normative SFNT structure, directory, alignment, checksums, and required tables.
- Official OpenType table specifications: [`head`](https://learn.microsoft.com/en-us/typography/opentype/spec/head), [`maxp`](https://learn.microsoft.com/en-us/typography/opentype/spec/maxp), [`hhea`](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea), [`hmtx`](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx), [`OS/2`](https://learn.microsoft.com/en-us/typography/opentype/spec/os2), [`cmap`](https://learn.microsoft.com/en-us/typography/opentype/spec/cmap), [`loca`](https://learn.microsoft.com/en-us/typography/opentype/spec/loca), [`glyf`](https://learn.microsoft.com/en-us/typography/opentype/spec/glyf), and [`kern`](https://learn.microsoft.com/en-us/typography/opentype/spec/kern).
- [Unicode Standard 17.0.0, Chapter 3](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) — Unicode scalar-value validity.
- Repository `modules/mb-core/{bytes,checked,budget,error,io,math}`, `modules/mb-canvas`, `moon.work`, `policy/foundation.json`, `scripts/quality`, and `fixtures/manifest.json` — existing implementation and integration contracts.

### Secondary (MEDIUM confidence)

- [Official MoonBit workspace, module, package, test, and documentation guides](https://docs.moonbitlang.com/en/latest/) — toolchain/project configuration, cross-target tests, and documentation tests, cross-checked against the installed repository baseline.
- [DejaVu Fonts download](https://dejavu-fonts.github.io/Download.html) and [license](https://dejavu-fonts.github.io/License.html) — candidate DejaVu Sans 2.37 fixture provenance and redistribution terms; acceptance awaits the extracted TTF digest and table inventory.
- A pinned external inspector such as FontTools may be used once during fixture curation, but its output must be reduced to committed semantic facts and it is never a runtime or portable-CI dependency.

---
*Research completed: 2026-07-26*
*Ready for roadmap: yes*
