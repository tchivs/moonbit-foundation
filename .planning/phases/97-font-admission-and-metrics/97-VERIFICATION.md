---
phase: 97-font-admission-and-metrics
verified: 2026-07-27T04:19:56Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 97: Font Admission and Metrics Verification Report

**Phase Goal:** Library authors can open one bounded static TrueType-outline SFNT from immutable bytes and inspect stable font-wide and per-glyph horizontal metrics through the portable `tchivs/mb-font` module.
**Verified:** 2026-07-27T04:19:56Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is achieved. This verdict is based on the current implementation, its current generated interface and policy wiring, four independently run named behavioral tests, and the post-implementation canonical Required-lane log. The PLAN/SUMMARY/REVIEW claims were used only to identify what to inspect.

Codebase-memory was refreshed for this worktree before discovery. Its current extractor indexed the repository but exposed no MoonBit function nodes or call edges under `modules/mb-font`; source-level call/data-flow tracing was therefore used as the documented fallback required by `AGENTS.md`.

### Observable Truths

The four ROADMAP success criteria are non-negotiable. PLAN truths were merged without reducing that scope; implementation-specific duplicates are represented by the ten observable truths below.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The public runtime boundary is one portable `tchivs/mb-font/font` package whose only module dependency is `tchivs/mb-core`. | ✓ VERIFIED | `modules/mb-font/moon.mod.json` declares only `tchivs/mb-core`; `font/moon.pkg` imports only `budget`, `bytes`, `checked`, and `error`; policy records one public package and the sole `mb-font -> mb-core` edge. |
| 2 | A caller can open a standalone `0x00010000` TrueType SFNT from a retained `ByteView` using explicit validated `FontLimits` and a caller-owned shared `Budget`. | ✓ VERIFIED | `Font::open` takes exactly those three arguments (`font.mbt:98-102`), captures the revision, preflights discovery, parses the directory, forms and charges one aggregate admission charge, and constructs `Font` only after all gates (`font.mbt:103-167`). Named test `generated standalone TrueType opens and returns exact units per em` passed 1/1. |
| 3 | Admission derives canonical directory facts, creates contained table-local windows, validates ordering/alignment/non-overlap and table/font checksums, and publishes only one complete opaque `Font`. | ✓ VERIFIED | `parse_font_directory` derives `12 + 16*numTables`, validates stored search facts, ascending unique tags, alignment and checked ranges, rejects overlap, and immediately creates checked subviews (`directory.mbt:371-587`). `font_validate_checksums` validates every record and `0xB1B0AFBA` (`directory.mbt:626-699`). The sole public construction is the final `Ok({...})` in `Font::open`. |
| 4 | All ten required tables have supported structural envelopes and mutually consistent cardinalities; valid unknown optional tables remain admissible. | ✓ VERIFIED | Required-table lookup and decoders are coordinated by `font_admit_required_tables` (`tables.mbt:1763-1829`); `head`, `maxp`, `hhea`, `OS/2`, `cmap`, `name`, and `post` are decoded from `TableWindow`s; exact `hmtx` and `loca` relationships are checked in `metrics.mbt:36-210`. The white-box directory matrix admits `zzzz` and rejects all ten missing required-table cases. |
| 5 | Callers can inspect exact units-per-em, signed global bounds, `hhea` metrics, and `OS/2` typographic metrics as separately named integer facts, with no target-dependent “best” selector. | ✓ VERIFIED | `Font` stores separate head/hhea/OS/2 facts and exposes four revision-guarded queries (`font.mbt:171-219`). Named test `font publishes separate exact global metric sources` passed 1/1 and asserts intentionally different hhea `(800,-200,90)` and typographic `(760,-240,40)` values. No “best/default/preferred/platform metric” surface exists in source or `.mbti`. |
| 6 | Callers can construct an opaque range-checked `GlyphId` and query exact advance, signed LSB, optional declared bounds, and checked RSB for every admitted glyph, including empty glyphs and the repeated-final-advance `hmtx` tail. | ✓ VERIFIED | Receiving-font range checks are in `font.mbt:224-289`. Direct/tail hmtx indexing, empty-loca handling, common glyph-header bounds, and checked RSB derivation are in `metrics.mbt:275-463`. Named test `font publishes opaque direct tail and empty horizontal metrics` passed 1/1 and proves direct, empty, and tail values including distinct tail LSB and `bounds=None`. |
| 7 | Queries are deterministic, do not retain/mutate the caller budget or use hidden cursor/cache state, revalidate cross-font glyph IDs, and reject any backing revision drift including mutate-back. | ✓ VERIFIED | `Font` has no `Budget`, lazy cache, mutable query cursor, or memoization field. All public queries call `require_revision`; `horizontal_metrics` checks before lookup and again before publication. The receiving font rechecks `GlyphId`. Named mutation/mutate-back test passed 1/1; repeat/order-independent and interleaved-font tests are present and included in the canonical suite. |
| 8 | Unsupported profiles, malformed/inconsistent required data, arithmetic/range failures, exhausted semantic limits/budget, and changed backing storage return structured errors without partial `Font` publication. | ✓ VERIFIED | Unsupported signatures/tables return `Capability/CapabilityUnavailable`; malformed supported data uses structured `CoreError` paths; checked arithmetic is used before reads/ranges; semantic and budget failures carry bounded facts. Failure tests use `unwrap_err`/`is Err` before any queryable `Font`. Cardinality, source-limit, atomic-budget, checksum, profile, and drift matrices are present in `font_test.mbt` and `font_wbtest.mbt`. |
| 9 | The generated public interface exposes only opaque admission/limits, named global metrics, opaque glyph IDs, and named horizontal metrics—no private parser/descriptor or deferred font capability. | ✓ VERIFIED | Current `pkg.generated.mbti` is an exact 46-line match to `policy/foundation.json`. It contains only `Font`, `FontLimits`, `FontBounds`, `FontLineMetrics`, `GlyphId`, `GlyphHorizontalMetrics`, and their intended methods. Policy negative probes reject private cursor/table/offset/window names and deferred cmap/outline/path/filesystem/FFI/host/shaping/hinting/rasterization aliases. |
| 10 | The contract is qualified identically on `js`, `wasm`, `wasm-gc`, and `native`, uses auditable generated micro-fonts only, and is integrated into workspace/publication policy and docs. | ✓ VERIFIED | Canonical Required log contains the font policy marker, 16 exact `Total tests: 1048, passed: 1048, failed: 0.` summaries, and one `Required quality lane passed.` marker. No `.ttf`, `.otf`, collection, or web-font asset exists under `modules/mb-font`; Phase 100 real-font qualification is documented as deferred. |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### PLAN Truth Coverage

| PLAN item | Resolution |
|---|---|
| 97-01 T1 package/dependency boundary | Truth 1 |
| 97-01 T2 retained `ByteView` + explicit limits + caller budget | Truth 2 |
| 97-01 T3 checked generated SFNT admission + atomic opaque publication | Truths 2-3 |
| 97-01 T4 exact/repeatable units-per-em + mutate-back rejection | Truths 5 and 7 |
| 97-01 T5 no mutable query cache/concurrent shared-budget claim | Truth 7 |
| 97-01 T6 no low-level or deferred public capability | Truth 9 |
| 97-02 T1 canonical directory/windows/checksums | Truth 3 |
| 97-02 T2 ten structurally valid required tables + unknown optional allowance | Truth 4 |
| 97-02 T3 structured fail-closed outcomes | Truth 8 |
| 97-02 T4 separately named global metrics | Truth 5 |
| 97-03 T1 opaque/range-checked glyph metrics | Truth 6 |
| 97-03 T2 repeated-final-advance tail + empty glyph semantics | Truth 6 |
| 97-03 T3 receiving-font range check + query drift rejection | Truth 7 |
| 97-03 T4 hostile relationships/ranges/arithmetic/resources fail atomically | Truth 8 |
| 97-03 T5 four-target behavior + minimal interface | Truths 9-10 |
| 97-03 T6 generated micro-font evidence only | Truth 10 |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/moon.mod.json` | Independent four-target module, sole core dependency | ✓ VERIFIED | Substantive manifest; wired through `moon.work` and policy. |
| `modules/mb-font/font/moon.pkg` | Single public package imports/targets | ✓ VERIFIED | Exact four core imports and four targets; policy-enforced. |
| `modules/mb-font/font/limits.mbt` | Validated opaque `FontLimits` | ✓ VERIFIED | Eight non-zero ceilings, constructor, accessors, structured failures; black-box tests. |
| `modules/mb-font/font/font.mbt` | Opaque atomic facade/global/per-glyph API | ✓ VERIFIED | Substantive coordinator and revision-guarded public queries; exact `.mbti` wiring. |
| `modules/mb-font/font/cursor.mbt` | Checked table-local BE reads | ✓ VERIFIED | Exact-fit containment before reads; one-short/overflow tests. |
| `modules/mb-font/font/directory.mbt` | Directory normalization/profile/checksum gate | ✓ VERIFIED | Substantive checked parser; called by `Font::open`. |
| `modules/mb-font/font/tables.mbt` | Private required-table facts/decoders | ✓ VERIFIED | Substantive structural and resource validation; called by coordinator. |
| `modules/mb-font/font/metrics.mbt` | Private hmtx/loca/glyf metric index/lookup | ✓ VERIFIED | Substantive exact cardinality, normalization, header, lookup, and RSB logic; called by `Font`. |
| `modules/mb-font/font/generated_fonts_wbtest.mbt` | Auditable generated micro-font builders/mutations | ✓ VERIFIED | Intentional 98% rename from planned `generated_fonts.mbt` in commit `11bb3bbb` to keep fixtures in white-box test compilation; functions are consumed by `font_wbtest.mbt`. Public black-box tests retain independent in-file generated builders. This is path drift, not missing behavior. |
| `modules/mb-font/font/font_test.mbt` | Public behavior/structured-error matrix | ✓ VERIFIED | 2,400+ lines; 27 black-box tests including all roadmap behaviors. |
| `modules/mb-font/font/font_wbtest.mbt` | Private boundary/cardinality matrix | ✓ VERIFIED | Checked reads, directory/search/checksum, required tables, hmtx/loca/glyf tests. |
| `policy/foundation.json` | Exact module/package/source/interface inventory | ✓ VERIFIED | Parses as JSON; current `.mbti` matches its 46 semantic lines exactly. |
| `scripts/quality/Assert-Policy.ps1` | Executable mb-font drift enforcement | ✓ VERIFIED | Exact imports/targets/files/docs/interface checks and negative capability probes; canonical marker passed. |
| `modules/mb-font/README.mbt.md` and `CHANGELOG.md` | Candidate public contract/release record | ✓ VERIFIED | Four-target workflow, semantics, dependency and Phase 100 boundary documented; included in publication inventory. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `font.mbt` | `directory.mbt` | `Font::open` → discovery/parse/profile/checksum | ✓ WIRED | Calls at `font.mbt:104-134`. |
| `directory.mbt` | `cursor.mbt` | Checked `read_u16/read_u32` and checked subview | ✓ WIRED | Header/record reads and immediate local windows at `directory.mbt:389-566`. |
| `font.mbt` | `tables.mbt` | Complete required-table admission before construction | ✓ WIRED | `font_admit_required_tables` at `font.mbt:136`; final construction starts at line 148. |
| Public/private tests | generated builders | Generated valid/hostile immutable bytes | ✓ WIRED | Black-box builders are in `font_test.mbt`; shared white-box builders are in `generated_fonts_wbtest.mbt` and used by `font_wbtest.mbt:98,203,229,299-326`. |
| `Font::open` | directory → tables → metric index | Single coordinator | ✓ WIRED | All failures return before the sole `Ok(Font)` expression. |
| Table decoders | normalized `TableWindow` | Local `view` arguments only | ✓ WIRED | Decoder signatures take `TableWindow`; no root-source subview reconstruction exists in `tables.mbt` or `metrics.mbt`. |
| `head`/`maxp`/`hhea` | `hmtx`/`loca` | Exact cardinality derivation | ✓ WIRED | `font_admit_metric_index` passes `numGlyphs`, `numberOfHMetrics`, and `indexToLocFormat` to checked length/normalization helpers. |
| Global getters | admitted head/hhea/OS/2 facts | Stored named values + common revision guard | ✓ WIRED | `font.mbt:148-219`. |
| `font.mbt` | `metrics.mbt` | Guard → receiving-font range check → lookup → guard | ✓ WIRED | `Font::horizontal_metrics` at `font.mbt:252-289`. |
| `metrics.mbt` | normalized hmtx/loca/glyf facts | Checked table-local offsets | ✓ WIRED | `MetricIndexFacts` retains table windows and normalized offsets; lookup never rebuilds root offsets. |
| `font_test.mbt` | public API | Generated bytes and public/error assertions | ✓ WIRED | Tests construct `ByteView`, limits, budget, then use only public values for roadmap behavior. |
| `policy/foundation.json` | `Assert-Policy.ps1` | Exact `.mbti`, inventory, targets, dependencies, negative probes | ✓ WIRED | Selector reads the policy, runs `moon info`, and exact-compares generated semantic lines. |

## Data-Flow Trace (Level 4)

| Artifact/query | Data | Source | Produces real data | Status |
|---|---|---|---|---|
| `Font::open` | Directory/table/metric facts | Caller `ByteView` → checked directory windows → required decoders/index | Yes; decoded from generated SFNT bytes under limits/budget | ✓ FLOWING |
| Global metric queries | units/bounds/hhea/OS/2 facts | Admitted `head`, `hhea`, and `OS/2` fields stored in opaque `Font` | Yes; distinct fixture values are asserted | ✓ FLOWING |
| `horizontal_metrics` | advance, LSB, bounds, RSB | Admitted `hmtx`, normalized `loca`, table-local `glyf` header | Yes; direct, empty, and tail values asserted | ✓ FLOWING |
| Structured failures | typed error facts | Profile, checked read/range, semantic limit, budget, revision gates | Yes; categories/codes/contexts/ranges asserted | ✓ FLOWING |

## Behavioral Spot-Checks

Each command ran from the repository root and selected exactly one named native test.

| Behavior | Command | Result | Status |
|---|---|---|---|
| Open bounded generated TrueType and read exact units-per-em | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'generated standalone TrueType opens and returns exact units per em'` | `Total tests: 1, passed: 1, failed: 0.` | ✓ PASS |
| Preserve separate exact global metric sources | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'font publishes separate exact global metric sources'` | `Total tests: 1, passed: 1, failed: 0.` | ✓ PASS |
| Direct/tail/empty per-glyph metric semantics | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'font publishes opaque direct tail and empty horizontal metrics'` | `Total tests: 1, passed: 1, failed: 0.` | ✓ PASS |
| Required/optional/glyph/unread mutation and mutate-back invalidate every query | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'required optional glyph unread and mutate-back changes invalidate every query'` | `Total tests: 1, passed: 1, failed: 0.` | ✓ PASS |

### Canonical Regression Evidence

The supplied authoritative command was:

`pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/phase97-canonical`

The stdout log `D:\AI-Data\temp\Admin\mnf-required-colr-full.stdout.log` is timestamped 2026-07-27T04:08:56Z, after the last `modules/mb-font` implementation change (`c2fcaa49`, 2026-07-27T02:43:56Z). Direct log reconciliation found:

- 1 `Interface verified for tchivs/mb-font/font: 46 semantic line(s)` entry;
- 1 font policy/dependency/publication/documentation/target/source/interface success marker;
- 16 exact `Total tests: 1048, passed: 1048, failed: 0.` summaries;
- 1 `Required quality lane passed.` marker.

The non-empty stderr log contains compiler warnings from MoonBit core and unrelated `mb-image/png` tests, but no failure; the Required lane completed successfully.

## Probe Execution

Step 7c: **SKIPPED** — no probe path, PASS-marker probe contract, or `scripts/**/tests/probe-*.sh` is declared by the Phase 97 plans/summaries.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| FONT-01 | 97-01, 97-02, 97-03 | Admit one static TrueType-outline SFNT from caller bytes under explicit limits and inspect named font-wide/per-glyph horizontal metrics through portable `tchivs/mb-font`. | ✓ SATISFIED | All four ROADMAP criteria and all merged PLAN truths verified above; four named behaviors pass; canonical four-target Required lane passes. |

No additional requirement is mapped to Phase 97 in `REQUIREMENTS.md`; there are no orphaned Phase 97 requirements. FONT-02/FONT-04, FONT-03, and FONT-05 remain explicitly assigned to Phases 98, 99, and 100.

## Prohibitions and Scope Fences

| Prohibition | Status | Evidence |
|---|---|---|
| No raw directory/tag/cursor/offset/window/checksum/private fact public API | ✓ VERIFIED | Exact current `.mbti` contains none; policy has private-leak checks. |
| No cmap query, kerning query, outline/Path2, shaping, hinting, rasterization, host/filesystem/FFI discovery | ✓ VERIFIED | No such public symbol; policy exercises negative aliases. Private cmap structural admission is not a public mapping capability. |
| No inferred “best/default/preferred/platform” line metric | ✓ VERIFIED | Separate named hhea and typographic APIs; exact distinct-value test; zero matching selector surface. |
| No repair/clamp/sort/deduplicate/partial publication of malformed required data | ✓ VERIFIED | Directory rejects noncanonical order/duplicates/ranges/checksums; metric admission rejects inconsistencies; construction occurs once after all gates. |
| No TTC/OTC, WOFF/WOFF2, CFF/CFF2, variation, color, or bitmap behavior | ✓ VERIFIED | Recognized profiles return capability errors; no corresponding public API. |
| No licensed/downloaded real-font fixture in Phase 97 | ✓ VERIFIED | No font asset exists under `modules/mb-font`; generated MoonBit bytes only; Phase 100 boundary is documented. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/quality/Assert-Policy.ps1` | 227 | Literal word `placeholder` inside a validator that rejects placeholder approval evidence | ℹ️ Info | Enforcement code, not a stub. |

The exact phase scope contains zero `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, or `PLACEHOLDER` debt markers and no user-visible stub phrase. `git diff --check` passed. The only pre-existing/unrelated working-tree entries are the untracked `97-UAT.md` and VPU quick SUMMARY; neither was modified.

The supplied deep review is clean (14 files, 0 findings), and the supplied security contract closes 17/17 threats with `threats_open: 0`. These corroborate, but do not replace, the code and behavioral evidence above.

## Human Verification Required

None. The phase is a deterministic portable library/parser contract with no visual, interactive, external-service, performance-feel, or otherwise human-only success criterion. Every behavior-dependent roadmap truth has a passing named test, and no PLAN `<human-check>` item exists.

## Gaps Summary

No blocking or warning gap remains.

The sole plan-path discrepancy is the planned `modules/mb-font/font/generated_fonts.mbt`. Commit `11bb3bbb` intentionally renamed it to `generated_fonts_wbtest.mbt` to keep generated fixtures out of production compilation, updated policy inventories, and retained the fixture helpers consumed by white-box tests; public black-box tests use independent in-file generated builders. The artifact’s promised behavior and wiring are therefore present under a stricter test-only boundary.

Later phases explicitly own Unicode mapping/kerning (98), outlines (99), and licensed real-font/full-workflow qualification (100). Those are not Phase 97 gaps.

---

_Verified: 2026-07-27T04:19:56Z_
_Verifier: the agent (gsd-verifier)_
