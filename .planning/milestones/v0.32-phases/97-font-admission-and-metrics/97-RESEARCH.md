# Phase 97: Font Admission and Metrics - Research

**Researched:** 2026-07-26  
**Domain:** Portable bounded TrueType SFNT admission, ownership, and horizontal metrics  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public Contract and Dependency Boundary
- Publish one portable public `tchivs/mb-font/font` package; keep SFNT/table parsers private file-level components rather than exposing low-level table packages.
- Use an opaque `Font` and opaque/range-checked `GlyphId` so callers cannot bypass admission invariants or construct invalid glyph references.
- Plan around `Font::open(source, limits, budget)` with an explicit `FontLimits` value; generic budgets alone do not express table, glyph, expansion, and work ceilings.
- Keep the only runtime dependency `tchivs/mb-font -> tchivs/mb-core`; return core data types and do not add canvas, image, color, FFI, filesystem, or platform-font dependencies.

### Source Ownership and Atomic Admission
- Retain a caller-provided `ByteView` and capture its mutation revision; every query that reads retained source bytes must reject revision drift before consuming or publishing results.
- Accept only standalone static TrueType-outline SFNT with `sfntVersion = 0x00010000` in this milestone; reject TTC/OTC, WOFF/WOFF2, CFF/CFF2, variations, and color/bitmap profiles as unsupported.
- Publish `Font` only after one cross-table admission gate succeeds; malformed tables, inconsistent cardinalities, unsupported required profiles, or exhausted limits never produce a partial font.
- Perform checked widened offset/count/range arithmetic before narrowing, allocation, slicing, checksum work, or table-local reads.

### SFNT Integrity Profile
- Derive directory lookup facts from `numTables`; validate stored search helper fields for canonical consistency if the official profile requires them, but never trust them for navigation.
- Require sorted unique tags, checked contained table ranges, required alignment, non-overlap, table checksums, and the font-wide `head.checksumAdjustment` invariant.
- Require and structurally admit `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`, `loca`, and `glyf`; unknown well-formed optional tables remain allowed.
- Normalize table records to checked table-local `ByteView` windows so downstream decoders never combine root bytes with raw attacker-controlled offsets.

### Metrics and Resource Semantics
- Expose units-per-em, global bounds, `hhea` ascent/descent/lineGap, and `OS/2` typographic ascent/descent/lineGap as separately named facts; do not invent a target-dependent “best” line metric.
- Expose per-glyph advance width, left side bearing, declared bounds, and a checked derived right side bearing, including empty glyphs and the `hmtx` repeated-final-advance tail rule.
- Treat `maxp` and table-declared counts as consistency claims, not permission to allocate or work; caller `FontLimits` intersect declarations and the shared budget remains authoritative.
- Preserve integer font-unit facts until callers request or downstream phases produce geometry; Phase 97 must avoid floating-point policy that would pre-empt later outline decisions.

### Verification and Compatibility
- Use deterministic generated micro-font bytes to cover exact-fit/one-short ranges, duplicate/overlap/checksum failures, long/short `loca`, `hmtx` tail metrics, empty glyphs, mutation drift, and budget limits.
- Test only public results and stable structured error facts across `js`, `wasm`, `wasm-gc`, and `native`; timing and host-specific representations are not compatibility oracles.
- Review generated `.mbti` output to keep the candidate surface minimal and ensure no private table parser or unsupported capability leaks publicly.
- Keep Phase 97 fixtures self-contained and provenance-ready, while licensed real-font selection and end-to-end interoperability evidence remain owned by Phase 100.

### the agent's Discretion
- Exact MoonBit type and method names may change during planning if the generated `.mbti` remains minimal, explicit, and consistent with established module conventions.
- The internal split among cursor, table-record, core-table, and metrics source files is flexible provided the public package remains singular and dependency direction stays acyclic.
- Compact bounded structural indexes may be cached after admission; persistent decoded glyph/outline caches are not part of this phase.

### Deferred Ideas (OUT OF SCOPE)
- Phase 98 owns cmap format 12/4 selection and legacy horizontal format-0 kerning.
- Phase 99 owns simple/composite `glyf` decoding, phantom-point/`USE_MY_METRICS`, transform, and `Path2` lowering rules.
- Phase 100 owns licensed real-font selection, provenance/digests, public end-to-end examples, and full hostile four-target qualification.
- CFF/CFF2, collections/web-font containers, variations, color/bitmap glyphs, hinting, shaping, discovery, rasterization, and authoring remain outside v0.32.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| FONT-01 | Library authors can admit one static TrueType-outline SFNT from caller-provided immutable bytes under explicit limits and inspect named font-wide and per-glyph horizontal metrics through a portable `tchivs/mb-font` API. | The ordered admission gate, exact `mb-core` seams, proposed public API, cross-table metric rules, file map, and test matrix below make the requirement directly plannable. |
</phase_requirements>

## Summary

Phase 97 should be planned as three implementation slices: repository/module integration, a private atomic SFNT admission pipeline, and a minimal public metrics facade. The phase context supersedes the older milestone research split: metrics and the `head`/`maxp`/`hhea`/`hmtx`/`loca`/`glyf` relationships are part of Phase 97, while cmap lookup, kerning, and outline payload decoding remain later work. [VERIFIED: `.planning/phases/97-font-admission-and-metrics/97-CONTEXT.md`; `.planning/research/SUMMARY.md`]

The core design is an opaque `Font` that retains a root `@bytes.ByteView`, its opening `mutation_revision`, checked table-local subviews, compact structural facts, and named decoded metrics. `Font::open` must validate the entire supported profile and charge all admission work before it constructs the public value. A query must reject source revision drift before it reads, and again before it publishes a result if it read retained bytes. [VERIFIED: `modules/mb-core/bytes/views.mbt`; `modules/mb-image/png/stream_encode.mbt`; `.planning/research/ARCHITECTURE.md`]

**Primary recommendation:** plan one fail-closed admission transaction in dependency order—source and directory, normalized table windows, checksums/profile, core-table facts, cross-table cardinalities and glyph metric indexes, final revision check, then `Font` publication. [VERIFIED: `.planning/research/ARCHITECTURE.md`; `.planning/research/PITFALLS.md`]

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models must be MoonBit; no foreign font engine may become the core implementation. [VERIFIED: `AGENTS.md`]
- The public package must support `js`, `wasm`, `wasm-gc`, and `native`; native is preferred but must not change portable semantics. [VERIFIED: `AGENTS.md`; `policy/foundation.json`]
- The module dependency graph must remain acyclic and explicitly documented; this phase adds only `tchivs/mb-font -> tchivs/mb-core`. [VERIFIED: `AGENTS.md`; `docs/rfcs/0004-mb-font.md`]
- Public behavior must be deterministic and usable without GUI, filesystem, network, or other ambient host state. [VERIFIED: `AGENTS.md`]
- Public compatibility is candidate/pre-1.0, with generated interface review and repository policy enforcement. [VERIFIED: `AGENTS.md`; `scripts/quality/Assert-Policy.ps1`]
- Use graph tools first for code discovery. The graph was available but indexed documentation nodes rather than MoonBit symbols, so exact API discovery required the permitted targeted source fallback. [VERIFIED: codebase-memory project architecture result; `AGENTS.md`]
- No project-specific skill exists under the documented project skill roots. [VERIFIED: project skill discovery; `AGENTS.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Caller-byte ownership and revision detection | API / library facade | `mb-core/bytes` | `Font` owns the admission lifetime; `ByteView` supplies retained windows and mutation revisions. |
| SFNT directory and checksum admission | Private parser core | `mb-core/checked`, `mb-core/budget` | All hostile offsets and work are normalized before any table decoder runs. |
| Required-table structural admission | Private table decoders | Admission coordinator | Table-local parsers produce facts; only the coordinator can publish the cross-table result. |
| Global and per-glyph metric queries | Public `font` package | Private metric index | Public methods expose stable integer facts without exposing raw table types. |
| Four-target proof | Package tests and repository quality scripts | Workspace policy | The same generated bytes and semantic assertions run on every required backend. |

[VERIFIED: `.planning/research/ARCHITECTURE.md`; `.planning/phases/97-font-admission-and-metrics/97-CONTEXT.md`]

## Standard Stack

### Core

| Component | Verified version / symbol | Purpose | Planning rule |
|---|---|---|---|
| MoonBit toolchain | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`, `moonrun 0.1.20260713` | Build, check, test, and interface generation | Preserve the repository pin; use `moon.mod.json`. |
| `tchivs/mb-core/bytes` | `ByteView::{length, get, subview, mutation_revision}` | Retained zero-copy root/table windows and TOCTOU detection | Store the root view plus opening revision; never store unchecked root offsets. |
| `tchivs/mb-core/checked` | `checked_add`, `checked_sub`, `checked_mul`, `checked_narrow_int`, `CheckedRange::{from_start_length, subrange, overlaps}` | Widened range and cardinality derivation | Perform these operations before slicing, indexing, allocating, or looping. |
| `tchivs/mb-core/budget` | `Budget::{charge, remaining, child}`, `ResourceCharge::new` | Shared atomic resource accounting | Preflight known admission cost and charge attacker-driven scans/work. |
| `tchivs/mb-core/error` | `CoreError::new` plus typed accessors | Stable portable failures | Assert category/code/context/source offsets, not rendered prose. |

[VERIFIED: `policy/foundation.json`; `modules/mb-core/{bytes,checked,budget,error}`]

### No New Dependencies

Phase 97 installs no external package and needs no FFI or host adapter. The only module dependency is `tchivs/mb-core: 0.1.0`; therefore a package-legitimacy audit is not applicable. [VERIFIED: phase CONTEXT; `docs/rfcs/0004-mb-font.md`]

## Exact Local APIs to Reuse

These are verified existing symbols, not proposals:

```moonbit
source.length()                       // UInt64
source.mutation_revision()            // UInt64
source.get(index)                     // Result[Byte, CoreError]
source.subview(relative_start, len)   // Result[ByteView, CoreError]

@checked.checked_add(a, b)
@checked.checked_sub(a, b)
@checked.checked_mul(a, b)
@checked.checked_narrow_int(value)
@checked.CheckedRange::from_start_length(start, length)
range.subrange(relative_start, length)
range.overlaps(other)

budget.charge(@budget.ResourceCharge::new(...))
budget.remaining()

@error.CoreError::new(
  category,
  code,
  operation="font-open",
  source_offset=offset,
  requested=requested,
  limit=limit,
  context="stable-token",
)
```

[VERIFIED: `modules/mb-core/bytes/views.mbt`; `modules/mb-core/checked/{checked,range}.mbt`; `modules/mb-core/budget/budget.mbt`; `modules/mb-core/error/core_error.mbt`]

The local precedent for a retained-source guard captures the revision when the operation value is created and compares it before replay, returning a stable state error on drift. Font admission additionally needs a second comparison immediately before public `Font` construction, and source-reading queries need a pre-read and pre-publication comparison. [VERIFIED: `modules/mb-image/png/stream_encode.mbt:989`; `modules/mb-image/png/stream_encode.mbt:1334`]

## Proposed Public API

The following names are **proposed**, not existing symbols. The planner may refine names, but the generated `.mbti` should preserve the capabilities and opacity.

```moonbit
// PROPOSED
pub struct Font { /* private retained source and validated facts */ }
pub struct GlyphId { priv value : UInt64 }
pub struct FontLimits { /* private non-zero ceilings */ }
pub struct FontBounds { /* signed integer font-unit bounds */ }
pub struct FontLineMetrics { /* signed ascent/descent/line_gap */ }
pub struct GlyphHorizontalMetrics {
  /* integer advance/side bearings and bounds : FontBounds? */
}

pub fn FontLimits::new(
  max_source_bytes~ : UInt64,
  max_tables~ : UInt64,
  max_table_bytes~ : UInt64,
  max_glyphs~ : UInt64,
  max_name_records~ : UInt64,
  max_cmap_records~ : UInt64,
  max_post_name_bytes~ : UInt64,
  max_work~ : UInt64,
) -> Result[FontLimits, @error.CoreError]

pub fn Font::open(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]

pub fn Font::glyph_count(self : Font) -> UInt64
pub fn Font::glyph_id(self : Font, value : UInt64)
  -> Result[GlyphId, @error.CoreError]
pub fn GlyphId::value(self : GlyphId) -> UInt64

pub fn Font::units_per_em(self : Font) -> Result[UInt64, @error.CoreError]
pub fn Font::global_bounds(self : Font) -> Result[FontBounds, @error.CoreError]
pub fn Font::hhea_line_metrics(self : Font)
  -> Result[FontLineMetrics, @error.CoreError]
pub fn Font::typographic_line_metrics(self : Font)
  -> Result[FontLineMetrics, @error.CoreError]
pub fn Font::horizontal_metrics(self : Font, glyph : GlyphId)
  -> Result[GlyphHorizontalMetrics, @error.CoreError]
```

Planning guidance:

- Every public `Font` query first compares the retained `ByteView` mutation revision with the admission revision. After that check, it may return bounded immutable admission facts or read only validated table-local views; any source-reading path checks the revision again before publishing its result. [VERIFIED: phase CONTEXT; `.planning/research/PITFALLS.md`]
- Expose signed font-unit values as integer facts (`Int` is sufficient for 16-bit stored values and widened right-side-bearing arithmetic); expose counts/unsigned widths in the repository-standard logical `UInt64` domain. This exact representation remains planner discretion and must be confirmed through `.mbti` review. [VERIFIED: `modules/mb-core/checked/checked.mbt`; phase CONTEXT]
- An empty glyph exposes `bounds: None`; it never receives synthetic ink bounds. Its ink width is zero, so right side bearing is checked as `advance_width - left_side_bearing`. [VERIFIED: phase CONTEXT; `.planning/research/STACK.md`; `.planning/research/PITFALLS.md`]
- `Font` stores no mutable persistent query cache and does not retain the caller's mutable `Budget`. Admission consumes the supplied budget synchronously; queries use immutable bounded admission facts or validated source views. The design does not permit concurrent sharing of one mutable `Budget` across queries. [VERIFIED: phase CONTEXT; local `Budget` implementation]

## Admission Architecture

### Ordered Gate

```text
caller ByteView + revision
        |
        v
source/limit preflight
        |
        v
SFNT header -> canonical directory facts derived from numTables
        |
        v
sorted unique records -> checked aligned contained non-overlapping ByteViews
        |
        v
required tags + unsupported-profile rejection + per-table checksums
        |
        v
head/maxp/hhea/OS2 fixed facts
        |
        v
hmtx + loca + glyf-header metric facts
        |
        v
name/cmap/post bounded structural envelopes
        |
        v
cross-table cardinalities + head checksumAdjustment + aggregate checks
        |
        v
final source revision check
        |
        v
publish opaque Font
```

[VERIFIED: `.planning/research/ARCHITECTURE.md`; `.planning/research/STACK.md`; phase CONTEXT]

### Gate Details the Plan Must Make Explicit

1. **Source preflight:** intersect `source.length`, all `FontLimits`, and `budget.remaining`; derive `12 + numTables * 16` with checked arithmetic before reading records. [VERIFIED: `.planning/research/PITFALLS.md`; local checked API]
2. **Directory facts:** require `sfntVersion == 0x00010000`; derive search helpers from `numTables`; validate stored helpers against the strict profile but never use them for navigation. [VERIFIED: `.planning/research/STACK.md`; phase CONTEXT]
3. **Record normalization:** require ascending unique tags, four-byte-aligned offsets, checked containment, and pairwise non-overlap; turn every record into a table-local `ByteView`. Unknown optional tables need only this envelope and checksum validation. [VERIFIED: `.planning/research/STACK.md`; phase CONTEXT]
4. **Checksums:** charge checksum work; treat table ends as virtually zero-padded for checksum calculation; calculate the `head` table record with `checksumAdjustment` treated as zero and validate the standalone font-wide invariant. [VERIFIED: `.planning/research/STACK.md`]
5. **Profile rejection:** distinguish malformed supported data (`Data/InvalidEncoding`) from well-formed but unsupported containers/outlines/variation/color/bitmap profiles (`Capability/CapabilityUnavailable`). Keep stable context tokens. [VERIFIED: local `CoreError` contract; phase CONTEXT]
6. **Core fixed tables:** validate supported versions/minimum or exact lengths and decode only fields needed by this phase. In particular, enforce `head` units-per-em and location format, TrueType `maxp` version/cardinality, `hhea.numberOfHMetrics`, and OS/2 version-dependent structural length. [VERIFIED: `.planning/research/STACK.md`]
7. **Metric cardinalities:** require `1 <= numberOfHMetrics <= numGlyphs`; checked-derive the exact `hmtx` payload (`4 * numberOfHMetrics + 2 * (numGlyphs - numberOfHMetrics)`); repeat only the final advance width for the tail. [VERIFIED: `.planning/research/STACK.md`; `.planning/research/PITFALLS.md`]
8. **Location cardinalities:** require the `loca` representation selected by `head.indexToLocFormat`, exactly `numGlyphs + 1` entries, nondecreasing normalized offsets, containment in `glyf`, and equal adjacent offsets for empty glyphs. [VERIFIED: `.planning/research/STACK.md`; `.planning/research/PITFALLS.md`]
9. **Glyph metric facts:** Phase 97 may read the common non-empty `glyf` header needed for declared bounds, but must not decode contour flags, points, components, instructions, phantom points, or `Path2`. [VERIFIED: phase CONTEXT; `.planning/research/ARCHITECTURE.md`]
10. **Other required tables:** validate the required `cmap`, `name`, and `post` table windows plus only their minimum supported header, version, and count-derived envelope facts. Phase 97 performs no cmap record selection/query, string decoding, glyph-name decoding, or metadata API; those semantic capabilities remain later-phase work. [VERIFIED: phase CONTEXT; `.planning/research/SUMMARY.md`]
11. **Atomic publication:** build temporary private facts, do a final revision comparison, then construct `Font` once. A failed gate leaves no public font and must not partially charge a multi-field budget transaction when preflight fails. The completed `Font` retains no `Budget` handle. [VERIFIED: local `Budget::charge`; `.planning/research/PITFALLS.md`]

## Metrics Rules

| Public fact | Source | Validation / derivation |
|---|---|---|
| Units per em | `head.unitsPerEm` | Preserve as unsigned integer font units. |
| Global bounds | `head.{xMin,yMin,xMax,yMax}` | Preserve signed stored facts; do not convert to floating point. |
| Horizontal line metrics | `hhea.{ascender,descender,lineGap}` | Return as a named triplet. |
| Typographic line metrics | `OS/2.{sTypoAscender,sTypoDescender,sTypoLineGap}` | Return separately; never select it implicitly as “best.” |
| Advance width | `hmtx` | Direct long metric or repeated final long-metric advance for a tail glyph. |
| Left side bearing | `hmtx` | Direct paired LSB or the glyph's tail LSB entry. |
| Declared bounds | `glyf` common header | `bounds: None` for a zero-length `loca` window; otherwise checked common-header facts only. Never synthesize empty-glyph ink bounds. |
| Right side bearing | derived | Non-empty: checked widened `advance - (lsb + xMax - xMin)`. Empty: ink width is zero, so checked `advance_width - left_side_bearing`. |

[VERIFIED: `.planning/research/STACK.md`; `.planning/research/PITFALLS.md`; phase CONTEXT]

Do not cross into Phase 99 by validating packed point streams or recomputing glyph bounds from outline coordinates. Any aggregate consistency checks based only on Phase 97 facts must be isolated from later outline conformance checks. [VERIFIED: phase CONTEXT]

## Recommended File and API Map

All entries below are **proposed new files** except the integration files explicitly marked existing.

```text
modules/mb-font/
├── moon.mod.json                 # proposed module metadata; mb-core only
├── README.mbt.md                 # proposed public contract/examples
├── CHANGELOG.md                  # proposed candidate release record
└── font/
    ├── moon.pkg                  # proposed single public package/import set
    ├── font.mbt                  # proposed opaque public values and methods
    ├── limits.mbt                # proposed FontLimits and limit errors
    ├── cursor.mbt                # proposed private BE table-local cursor
    ├── directory.mbt             # proposed private SFNT records/checksums
    ├── tables.mbt                # proposed private fixed-table decoders
    ├── metrics.mbt               # proposed hmtx/loca/glyf-header facts
    ├── generated_fonts.mbt       # proposed deterministic test byte builder
    ├── font_test.mbt             # proposed public black-box contract tests
    └── font_wbtest.mbt           # proposed private parser invariant tests

moon.work                          # existing; add module member
policy/foundation.json             # existing; add module/package inventory
scripts/quality/Assert-Policy.ps1  # existing; extend exact module/DAG/source checks
```

[VERIFIED: existing module layouts under `modules/mb-core`, `modules/mb-image`, and `modules/mb-svg`; `moon.work`; `policy/foundation.json`; `scripts/quality/Assert-Policy.ps1`]

Keep generated micro-font bytes in the package tests for Phase 97. Do not add a licensed binary fixture or Phase 100 provenance work now. [VERIFIED: phase CONTEXT]

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Retained byte ownership | Raw mutable arrays or copied table buffers | `@bytes.ByteView` and checked `subview` | Existing retention and revision semantics already solve lifetime and drift. |
| Range safety | Ad hoc `offset + length <= total` expressions | `@checked.CheckedRange` and checked arithmetic | Prevents overflow-before-check and backend narrowing errors. |
| Resource accounting | Parser-local counters with partial rollback | `@budget.Budget::charge` plus `FontLimits` | Existing charge preflight is atomic across dimensions. |
| Error strings | New font-specific string exception type | `@error.CoreError` typed fields and stable context tokens | Existing public tests and quality policy expect semantic error facts. |
| Font parsing runtime | FreeType, HarfBuzz, FontTools, platform font APIs | Pure MoonBit private parser | Foreign runtime/host dependence violates the module charter and targets. |

[VERIFIED: local `mb-core` APIs; `docs/rfcs/0004-mb-font.md`; phase CONTEXT]

## Common Pitfalls

### Arithmetic after narrowing

**Failure:** wire counts become `Int` before checked multiplication or range containment.  
**Plan guard:** keep logical quantities as `UInt64`; narrow only at the final backend index.  
**Tests:** exact fit, one short, overflow, and narrowing failure for directory, hmtx, and loca expressions.  
[VERIFIED: `modules/mb-core/checked/checked.mbt`; `.planning/research/PITFALLS.md`]

### Independently valid tables disagree

**Failure:** `maxp`, `hhea`, `hmtx`, `loca`, `glyf`, `post`, or cmap glyph cardinalities disagree but a partial font is published.  
**Plan guard:** one coordinator owns cross-table publication; private parsers return facts only.  
**Tests:** pairwise mismatch vectors with `Font::open` returning an error and no queryable value.  
[VERIFIED: `.planning/research/PITFALLS.md`]

### Flattening the hmtx tail

**Failure:** tail glyphs repeat both width and bearing, or the implementation assumes four bytes per glyph.  
**Plan guard:** repeat only the last advance; consume a distinct signed LSB for each tail glyph.  
**Tests:** minimum and full `numberOfHMetrics`, different tail bearings, empty tail glyph.  
[VERIFIED: `.planning/research/PITFALLS.md`]

### Treating maxp as a budget

**Failure:** attacker declarations become allocation permission.  
**Plan guard:** declarations must be internally consistent and under `FontLimits` and shared budget.  
**Tests:** declaration at limit and limit+1; rejected charge leaves budget unchanged where a full cost is known.  
[VERIFIED: `.planning/research/PITFALLS.md`; local budget tests]

### Revision check only at open

**Failure:** retained table windows become stale after a caller mutation.  
**Plan guard:** all public `Font` methods check the retained revision; source-reading methods check again before return.  
**Tests:** mutate required, optional, glyph, and unrelated bytes; mutate back to original value; every query still rejects.  
[VERIFIED: local PNG revision guard; `.planning/research/PITFALLS.md`]

### Scope leakage

**Failure:** cmap selection, kerning, outline decoding, real-font files, or `Path2` types leak into Phase 97.  
**Plan guard:** `.mbti` contains only admission/limits/IDs/named metrics; private structural parsing must not create later public capabilities.  
[VERIFIED: phase CONTEXT]

## Testing and Verification Plan

Nyquist validation is explicitly disabled in `.planning/config.json`, so no formal `## Validation Architecture` contract is required. The phase still needs the following implementation verification because the locked decisions require four-target-ready tests. [VERIFIED: `.planning/config.json`; phase CONTEXT]

### Test Layers

| Layer | Proposed file | Purpose | Fast command |
|---|---|---|---|
| Public black-box | `modules/mb-font/font/font_test.mbt` | Only public construction, metrics, IDs, and structured errors | `moon -C modules/mb-font test --target native --frozen` |
| Private white-box | `modules/mb-font/font/font_wbtest.mbt` | Cursor boundaries, checksum arithmetic, table windows, cardinality helpers | `moon -C modules/mb-font test --target native --frozen` |
| Four-target package gate | same tests | Backend-neutral semantic equivalence | `moon -C modules/mb-font test --target all --frozen` |
| Interface gate | generated `.mbti` | No private parser or deferred capability leaks | `moon -C modules/mb-font info --target all --frozen` |
| Workspace/policy gate | existing quality scripts | Module inventory, imports, targets, publication files | repository quality command selected by the planner |

[VERIFIED: existing module test naming; `scripts/quality/Assert-Policy.ps1`; `.planning/research/STACK.md`]

### Required Generated Vector Matrix

| Area | Minimum cases |
|---|---|
| SFNT envelope | exact header/directory, every one-short boundary, wrong signature, noncanonical helpers |
| Directory records | unsorted, duplicate, misaligned, contained exact-fit, out-of-range, overlap, unknown valid optional |
| Checksums | one bad table, bad `head` record checksum, bad font-wide adjustment, odd-length zero-padding case |
| Required tables | each missing once; unsupported version/profile; bounded outer `cmap`/`name`/`post` structures |
| Cross-table counts | zero/over-limit glyph count, `hhea` count 0 and `> numGlyphs`, short/long loca length mismatches |
| hmtx | one long metric plus tail LSBs, full long metrics, signed LSB, derived RSB boundaries |
| loca/glyf header | short and long, equal empty offsets, descending offset, final out of bounds, non-empty header one-short |
| ownership | revision stable; mutation after open; mutation back; query rejects before publishing |
| budgets | one-less/exact/one-more tables, glyphs, table bytes, name/cmap records, work; no partial public result |
| portability | identical public values and category/code/context fields on all four targets |

[VERIFIED: phase CONTEXT; `.planning/research/PITFALLS.md`]

### Requirement-to-Test Map

| Requirement | Behavior | Test type | Command |
|---|---|---|---|
| FONT-01 | Valid static TrueType SFNT admits atomically | black-box | `moon -C modules/mb-font test --target native --frozen` |
| FONT-01 | Invalid/unsupported/over-budget input returns stable structured facts | black-box + white-box | same |
| FONT-01 | Named global and per-glyph horizontal metrics are exact integers | black-box | same |
| FONT-01 | Source mutation invalidates queries | black-box | same |
| FONT-01 | Public facts/errors match across required targets | cross-target | `moon -C modules/mb-font test --target all --frozen` |
| FONT-01 | Public surface contains no cmap/kern/outline/host API | interface review | `moon -C modules/mb-font info --target all --frozen` |

## Security Domain

Phase 97 parses hostile binary input, so ASVS input-validation/resource controls apply even though authentication, sessions, access control, and cryptography do not. [VERIFIED: `docs/rfcs/0004-mb-font.md`; `.planning/research/PITFALLS.md`]

| ASVS Category | Applies | Standard control |
|---|---|---|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Checked ranges, strict supported versions, cross-table gate, no repair/clamping |
| V6 Cryptography | no | SFNT checksums are integrity fields, not cryptographic authenticity |

| Threat pattern | STRIDE | Mitigation |
|---|---|---|
| Offset/count wrap and out-of-range reads | Tampering / DoS | Widened checked arithmetic and table-local views |
| Count-driven allocation/work exhaustion | DoS | Semantic `FontLimits` intersected with shared `Budget` |
| Overlapping tables and aliasing | Tampering | Sorted normalized ranges and explicit non-overlap |
| Post-admission source mutation | Tampering | Retained mutation revision checked on every query |
| Partial admitted object after failure | Tampering | Temporary facts plus one final publication point |

## Planning Implications

Recommended plan structure:

1. **Module and contract task:** add `mb-font`, manifests, single package, policy/workspace wiring, opaque proposed types, `FontLimits`, and initial `.mbti` baseline.
2. **Binary substrate and directory task:** private big-endian cursor, checked table windows, directory/profile/checksum admission, stable errors, generated directory vectors.
3. **Core tables and metrics task:** fixed table facts, hmtx/loca/glyf-header relationships, opaque `GlyphId`, named public metric methods, empty-glyph rules.
4. **Atomicity and qualification task:** revision-first query guards, immutable bounded admission facts, no retained/shared mutable budget or hidden persistent query cache, exact budget boundaries, black/white-box matrix, four-target tests, final `.mbti` and policy review.

[VERIFIED: `.planning/research/ARCHITECTURE.md`; phase CONTEXT]

The planner should add explicit acceptance criteria for:

- no public raw tag/table/cursor types;
- no public cmap, kern, outline, path, font-file, or host APIs;
- no source read through root offset arithmetic after table normalization;
- no allocation or loop driven solely by font declarations;
- no returned metric after revision drift;
- empty glyphs return `bounds: None` and use zero ink width for checked RSB derivation;
- `cmap`, `name`, and `post` admission stops at required windows and minimum header/version/envelope facts;
- `Font` retains neither a mutable `Budget` nor a hidden mutable persistent query cache;
- identical structured error facts across all four targets.

[VERIFIED: phase CONTEXT; `.planning/research/PITFALLS.md`]

## Open Questions (RESOLVED)

1. **Empty-glyph bounds and right side bearing — resolved**
   - A zero-length `glyf` window exposes `bounds: None`; Phase 97 does not invent synthetic ink bounds. Empty-glyph ink width is defined as zero, so the checked derived value is `right_side_bearing = advance_width - left_side_bearing`. [VERIFIED: phase CONTEXT; `.planning/research/STACK.md`]

2. **Required `cmap`, `name`, and `post` depth — resolved**
   - Phase 97 validates each required table window and only the minimum supported header, version, and count-derived envelope facts needed to keep admission bounded. It adds no cmap record selection/query, name-string or glyph-name decoding, or metadata API; semantic cmap work remains Phase 98 and metadata remains out of this phase. [VERIFIED: phase CONTEXT; `.planning/research/SUMMARY.md`]

3. **Query state, cached facts, and budgets — resolved**
   - Every public `Font` query first checks the retained root `ByteView` revision. It may then return bounded immutable facts cached during admission or read validated table-local views; a source-reading query rechecks before publication. `Font` has no hidden mutable persistent query cache, does not retain the admission `Budget`, and does not support concurrent sharing of a mutable `Budget` across queries. [VERIFIED: phase CONTEXT; local `ByteView` and `Budget` implementations]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | The exact proposed `FontLimits` field list is sufficient for Phase 97. [ASSUMED] | Proposed API | Table-specific structural work may justify one additional ceiling during planning. |

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | build/test/info | yes | `0.1.20260713` | none needed |
| `moonc` | compile | yes | `v0.10.4+2cc641edf` | bundled pinned toolchain |
| `moonrun` | test/runtime | yes | `0.1.20260713` | bundled pinned toolchain |
| Git | repository integration | yes | `2.54.0.windows.1` | none needed |

[VERIFIED: local version probes; `policy/foundation.json`]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/97-font-admission-and-metrics/97-CONTEXT.md` — locked scope and decisions.
- `.planning/REQUIREMENTS.md` — FONT-01.
- `.planning/STATE.md` — milestone and phase ownership.
- `docs/rfcs/0004-mb-font.md` — module boundary, portability, hostile-input posture.
- `modules/mb-core/bytes/{views,owned_bytes}.mbt` — exact retained-view and revision APIs.
- `modules/mb-core/checked/{checked,range}.mbt` — exact checked arithmetic/range APIs.
- `modules/mb-core/budget/budget.mbt` — atomic hierarchical budget APIs.
- `modules/mb-core/error/core_error.mbt` — portable structured error surface.
- `modules/mb-image/png/stream_encode.mbt` — retained-source revision precedent.
- `policy/foundation.json`, `moon.work`, `scripts/quality/Assert-Policy.ps1` — repository integration pattern.

### Synthesized Project Research (HIGH confidence)

- `.planning/research/SUMMARY.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/STACK.md`
- `.planning/research/PITFALLS.md`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — exact local versions and symbols inspected.
- Architecture: HIGH — locked context and existing hostile-parser patterns agree.
- SFNT/metrics validation: HIGH — taken from the project's completed OpenType 1.9.1 research synthesis.
- Proposed API names: MEDIUM — intentionally subject to `.mbti` review.
- Pitfalls and tests: HIGH — derived from local parser/budget/revision patterns and the milestone pitfall audit.

**Research date:** 2026-07-26  
**Valid until:** 2026-08-25
