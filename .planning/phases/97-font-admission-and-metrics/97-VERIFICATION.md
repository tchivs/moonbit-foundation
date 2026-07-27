---
phase: 97-font-admission-and-metrics
verified: 2026-07-27T04:36:54Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 10/10
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 97: Font Admission and Metrics Verification Report

**Phase Goal:** Library authors can open one bounded static TrueType-outline SFNT from immutable bytes and inspect stable font-wide and per-glyph horizontal metrics through the portable `tchivs/mb-font` module.
**Verified:** 2026-07-27T04:36:54Z
**Status:** passed
**Re-verification:** Yes — freshness rerun after the coverage-schema and automated-UAT quick task

## Goal Achievement

The phase goal is achieved. This verdict starts from the four ROADMAP success criteria and verifies the current implementation, wiring, generated interface, policy, tests, and post-fix regression evidence. SUMMARY, UAT, review, and security claims are corroborating records, not substitutes for code evidence.

The codebase-memory index was refreshed for this exact worktree before discovery. It indexed the `mb-font` files but exposed no MoonBit function/call nodes, so the source-level checks below use the project-authorized direct-inspection fallback.

### Observable Truths

The four ROADMAP criteria are non-negotiable. PLAN truths were merged without reducing that scope and deduplicated into ten observable truths.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The runtime boundary is one portable `tchivs/mb-font/font` package whose only module dependency is `tchivs/mb-core`. | ✓ VERIFIED | `moon.mod.json` declares only `tchivs/mb-core`; `font/moon.pkg` imports only core `budget`, `bytes`, `checked`, and `error`; `moon.work` registers the module once. The focused policy selector passed against the exact dependency, package, source, and four-target inventories. |
| 2 | A caller can open a standalone `0x00010000` TrueType SFNT from a retained `ByteView` using explicit validated `FontLimits` and a caller-owned shared `Budget`. | ✓ VERIFIED | `Font::open` takes exactly those arguments, captures the source revision, preflights directory discovery, parses checked facts, forms and atomically charges the aggregate admission charge, and publishes only after all gates. The named open/units test passed 1/1 in this rerun. |
| 3 | Admission derives canonical directory facts, creates contained table-local windows, validates ordering/alignment/non-overlap and table/font checksums, and publishes only one complete opaque `Font`. | ✓ VERIFIED | `parse_font_directory` checked-derives directory size/search facts, requires ascending unique tags, aligned contained non-overlapping ranges, and immediately creates subviews. `font_validate_checksums` checks every table and the `0xB1B0AFBA` whole-font invariant. The only `Font` construction is the final `Ok({...})` in `Font::open`. |
| 4 | All ten required tables have supported envelopes and mutually consistent cardinalities; a valid unknown optional table remains admissible. | ✓ VERIFIED | `font_require_table_presence` requires `OS/2`, `cmap`, `glyf`, `head`, `hhea`, `hmtx`, `loca`, `maxp`, `name`, and `post`. `font_admit_required_tables` decodes the structural facts; `font_admit_metric_index` checks exact hmtx/loca/glyf relationships. White-box matrices include all missing-table cases and a valid `zzzz` optional table. |
| 5 | Callers can inspect exact units-per-em, signed global bounds, `hhea` metrics, and `OS/2` typographic metrics as separately named integers, without a target-dependent “best” selector. | ✓ VERIFIED | `Font` stores separate admitted values and exposes four revision-guarded getters. The named global-metric test passed 1/1 and asserts intentionally distinct hhea `(800,-200,90)` and typographic `(760,-240,40)` facts. No best/default/preferred/platform selector exists in source or the generated interface. |
| 6 | Callers can construct an opaque range-checked `GlyphId` and query exact advance, signed LSB, optional bounds, and checked RSB for every glyph, including empty glyphs and the repeated-final-advance hmtx tail. | ✓ VERIFIED | `Font::glyph_id` validates range; the receiving `Font` validates it again. `font_read_hmtx_metric` repeats only the final advance and reads each tail LSB separately. Equal loca entries yield `bounds=None`; RSB uses checked signed arithmetic. The direct/tail/empty named test passed 1/1 with exact values. |
| 7 | Queries are deterministic, do not retain/mutate the caller budget or use hidden cursor/cache state, and reject source revision drift—including mutate-back—before publishing a value. | ✓ VERIFIED | `Font` retains no `Budget` or mutable query cache. Every getter uses `require_revision`; `horizontal_metrics` checks both before lookup and before result construction. Repeat/order/interleaved tests and the every-query mutation/mutate-back test are present; the latter passed 1/1 in this rerun. |
| 8 | Unsupported profiles, malformed/inconsistent required data, checked-arithmetic/range failures, exhausted limits/budget, and changed backing storage return structured errors without partial `Font` publication. | ✓ VERIFIED | Unsupported signatures/tables use `CapabilityUnavailable`; malformed supported bytes use structured data errors; semantic ceilings use resource errors. Directory, cmap, name/post, metric, checksum, source-limit, atomic-budget, and revision matrices all run before the sole final construction expression. The current all-target font suite passed 39/39 on each target. |
| 9 | The generated public interface exposes only opaque admission/limits, named global metrics, opaque glyph IDs, and named horizontal metrics—no private parser/descriptor or deferred font capability. | ✓ VERIFIED | The focused policy selector regenerated and exact-compared the 46 semantic lines, rejected private cursor/table/offset/window names, and exercised negative fixtures for cmap, outline/path, filesystem, FFI, host, shaping, hinting, and rasterization aliases. It passed in this rerun. |
| 10 | The contract behaves on `js`, `wasm`, `wasm-gc`, and `native`, uses auditable generated micro-fonts only, and is integrated into workspace/publication policy and docs. | ✓ VERIFIED | The current package suite passed 39/39 on all four targets. The authoritative Required log contains sixteen exact `1048/1048` summaries and one final lane-pass marker. No `.ttf`, `.otf`, collection, or web-font asset exists under `modules/mb-font`; licensed real-font qualification remains explicitly assigned to Phase 100. |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### PLAN Truth Coverage

| PLAN item | Resolution |
|---|---|
| 97-01 package/dependency, retained bytes, limits/budget, checked tracer, units-per-em, repeatability/drift, and public-scope truths | Truths 1-3, 5, 7, and 9 |
| 97-02 canonical directory/checksums, ten required tables, structured failure, and named global metrics truths | Truths 3-5 and 8 |
| 97-03 opaque/range-checked glyph metrics, hmtx tail/empty glyph, receiving-font validation/drift, hostile resources, four targets/minimal interface, and generated-only evidence truths | Truths 6-10 |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/moon.mod.json` | Independent four-target module, sole core dependency | ✓ VERIFIED | Substantive manifest; wired through `moon.work` and exact policy. |
| `modules/mb-font/font/moon.pkg` | Single public package imports/targets | ✓ VERIFIED | Exact four core imports and four supported targets. |
| `modules/mb-font/font/limits.mbt` | Validated opaque `FontLimits` | ✓ VERIFIED | Eight non-zero ceilings, constructor/accessors, structured per-field rejection, black-box tests. |
| `modules/mb-font/font/font.mbt` | Opaque atomic facade and named global/per-glyph API | ✓ VERIFIED | Complete coordinator, single publication point, uniform revision guards, receiving-font glyph validation, and exact public interface wiring. |
| `modules/mb-font/font/cursor.mbt` | Checked table-local big-endian reads | ✓ VERIFIED | Proves full window before observing bytes; exact-fit/one-short white-box coverage. |
| `modules/mb-font/font/directory.mbt` | Directory normalization/profile/checksum gate | ✓ VERIFIED | Checked canonical parser; called by `Font::open`; selector, overlap, allocation, and checksum work are ledgered. |
| `modules/mb-font/font/tables.mbt` | Private required-table facts/decoders | ✓ VERIFIED | Structural/cardinality/resource validation for required tables; called by the coordinator. |
| `modules/mb-font/font/metrics.mbt` | Private hmtx/loca/glyf index and lookup | ✓ VERIFIED | Exact cardinality, normalization, glyph-header validation, tail lookup, and checked RSB derivation. |
| `modules/mb-font/font/generated_fonts_wbtest.mbt` | Auditable generated micro-font builders/mutations | ✓ VERIFIED | Intentional test-only replacement for the planned `generated_fonts.mbt`; substantive helpers are consumed by white-box tests, while black-box tests retain independent in-file builders. Exact policy requires the replacement in the test-source inventory. |
| `modules/mb-font/font/font_test.mbt` | Public behavior and structured-error matrix | ✓ VERIFIED | 30 black-box tests covering the roadmap behavior and hostile boundaries. |
| `modules/mb-font/font/font_wbtest.mbt` | Private boundary/cardinality matrix | ✓ VERIFIED | Eight tests covering checked reads, directory/search/checksum, required tables, and metric invariants. |
| `policy/foundation.json` | Exact module/package/source/interface inventory | ✓ VERIFIED | Valid JSON; records one package, sole core edge, production/test files, four targets, and 46 semantic interface lines. |
| `scripts/quality/Assert-Policy.ps1` | Executable mb-font drift enforcement | ✓ VERIFIED | Focused selector passed current regeneration, exact comparisons, and deferred-capability negative probes. |
| `modules/mb-font/README.mbt.md` and `CHANGELOG.md` | Candidate contract and release record | ✓ VERIFIED | Document the portable workflow, exact semantics, dependency, generated evidence, and Phase 100 boundary; both are publication-inventoried. |

The literal artifact checker reports the old planned `generated_fonts.mbt` path absent. Current commit `11bb3bbb` intentionally moved those helpers to `generated_fonts_wbtest.mbt` so fixtures cannot enter production compilation. The promised artifact behavior is substantive, wired, tested, and exact-policy-enforced under the stricter test-only path; this is intentional path drift, not a missing phase outcome.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `font.mbt` | `directory.mbt` | `Font::open` → discovery/parse/profile/checksum | ✓ WIRED | The coordinator passes the retained source and explicit limits, then consumes normalized facts. |
| `directory.mbt` | `cursor.mbt` | Checked reads and contained subviews | ✓ WIRED | Header/record fields use checked readers; accepted records become table-local views immediately. |
| `font.mbt` | `tables.mbt` | Complete required-table admission before construction | ✓ WIRED | `font_admit_required_tables` returns private facts before the final `Font` expression. |
| `font.mbt` | `metrics.mbt` | Admitted index plus guarded per-glyph lookup | ✓ WIRED | Pre-guard → receiving-font range check → `font_lookup_horizontal_metrics` → post-guard → public value. |
| `tables.mbt`/`metrics.mbt` | normalized `TableWindow` facts | Table-local checked offsets | ✓ WIRED | Decoders/lookup consume local views; no attacker-controlled root offset is reconstructed. |
| Tests | generated micro-font bytes | Public in-file builders and test-only shared builders | ✓ WIRED | Public tests use only the public API; white-box builders are consumed by `font_wbtest.mbt`. |
| `policy/foundation.json` | `Assert-Policy.ps1` | Exact inventory/interface allowlist | ✓ WIRED | Focused selector regenerated `.mbti`, exact-compared it, and ran negative probes successfully. |

## Data-Flow Trace (Level 4)

| Artifact/query | Data | Source | Produces real data | Status |
|---|---|---|---|---|
| `Font::open` | Directory/table/metric facts | Caller `ByteView` → checked directory windows → required decoders/index | Yes; values are decoded from generated SFNT bytes under caller limits/budget | ✓ FLOWING |
| Global metric getters | units/bounds/hhea/OS/2 facts | Admitted `head`, `hhea`, and `OS/2` fields stored in opaque `Font` | Yes; intentionally distinct fixture values are asserted | ✓ FLOWING |
| `horizontal_metrics` | advance, LSB, optional bounds, RSB | Admitted hmtx plus normalized loca and table-local glyf header | Yes; direct, empty, tail, short/long loca, and full/compact hmtx cases are asserted | ✓ FLOWING |
| Structured failures | typed error facts | Profile, checked read/range, semantic limit, budget, checksum, cardinality, and revision gates | Yes; category/code/context/requested/limit facts are asserted | ✓ FLOWING |

## Behavioral Spot-Checks

Four transition-sensitive named native checks were rerun from the repository root, followed by one current all-target package suite.

| Behavior | Command | Result | Status |
|---|---|---|---|
| Open bounded generated TrueType and read exact units-per-em | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'generated standalone TrueType opens and returns exact units per em'` | `1 passed, 0 failed` | ✓ PASS |
| Preserve separate exact global metric sources | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'font publishes separate exact global metric sources'` | `1 passed, 0 failed` | ✓ PASS |
| Direct/tail/empty per-glyph metric semantics | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'font publishes opaque direct tail and empty horizontal metrics'` | `1 passed, 0 failed` | ✓ PASS |
| Required/optional/glyph/unread mutation and mutate-back invalidate every query | `moon -C modules/mb-font test --target native --frozen -p tchivs/mb-font/font -f 'required optional glyph unread and mutate-back changes invalidate every query'` | `1 passed, 0 failed` | ✓ PASS |
| Current complete font package behavior on all targets | `moon -C modules/mb-font test --target all --frozen --deny-warn -p tchivs/mb-font/font` | 39/39 on wasm, wasm-gc, js, and native | ✓ PASS |

The two emitted warnings are from the installed MoonBit core `builtin/result.mbt`; the command exited 0 and every target reported 39/39.

### Canonical Regression and Freshness Evidence

Authoritative stdout: `D:\AI-Data\temp\Admin\mnf-required-colr-full.stdout.log`

- SHA-256: `669A4EF7B7BF830C18FD3B1BD628046901C89281148E5467BA300F766EE65017`
- Last write: `2026-07-27T04:08:56.001Z`
- Exact `Total tests: 1048, passed: 1048, failed: 0.` count: **16**
- Exact `Required quality lane passed.` count: **1**
- `Interface verified for tchivs/mb-font/font: 46 semantic line(s)` count: **1**

Authoritative stderr SHA-256 is `7110ADED00365E4B9C81E4AC1FB526FFAE75C33A5E92D8D30325746F8A89FE83`; it contains compiler warnings but no lane failure. Per the supplied regression provenance, the Required run occurred after the PNG structural newline correction represented by `06ec46ae`; the correction was committed after the run. The log also postdates every Phase 97 production/review fix. Apart from that already-exercised PNG correction, later commits are debug/verification/coverage/UAT planning records, not `mb-font` production or policy changes.

## Coverage and UAT Freshness

The post-verification quick task changed only Phase 97 coverage/UAT metadata and planning state. Current classifier output was rerun, not trusted from its SUMMARY:

| Summary | Total | Automated passed | Human judgment | Present/errors | Status |
|---|---:|---:|---:|---:|---|
| `97-01-SUMMARY.md` | 3 | 3 | 0 | 0/0 | ✓ ALL AUTO |
| `97-02-SUMMARY.md` | 3 | 3 | 0 | 0/0 | ✓ ALL AUTO |
| `97-03-SUMMARY.md` | 3 | 3 | 0 | 0/0 | ✓ ALL AUTO |

`97-UAT.md` is current and complete: **9 total, 9 passed, 0 issues, 0 pending, 0 skipped, 0 blocked**, nine `source: automated` entries, `[testing complete]`, and no gaps. No PLAN contains a deferred `<human-check>` block. This fresh verification supersedes the report that the metadata quick made stale.

## Probe Execution

Step 7c: **SKIPPED** — no Phase 97 plan/summary declares a probe path or `scripts/**/tests/probe-*.sh` contract.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| FONT-01 | 97-01, 97-02, 97-03 | Admit one static TrueType-outline SFNT from caller bytes under explicit limits and inspect named font-wide/per-glyph horizontal metrics through portable `tchivs/mb-font`. | ✓ SATISFIED | All four ROADMAP criteria and merged PLAN truths are verified; current named/all-target checks and the canonical Required lane pass. |

No other requirement maps to Phase 97. FONT-02/FONT-04, FONT-03, and FONT-05 remain explicitly assigned to Phases 98, 99, and 100; they are scope boundaries, not Phase 97 gaps.

## Prohibitions and Scope Fences

| Prohibition | Status | Evidence |
|---|---|---|
| No raw directory/tag/cursor/offset/window/checksum/private fact public API | ✓ VERIFIED | Exact generated interface contains none; policy checks private-leak patterns. |
| No cmap query, kerning query, outline/Path2, shaping, hinting, rasterization, host/filesystem/FFI discovery | ✓ VERIFIED | No corresponding public symbol; independent negative policy fixtures reject aliases. Private cmap structural admission is not a public lookup capability. |
| No inferred best/default/preferred/platform line metric | ✓ VERIFIED | Separate hhea and typographic APIs plus distinct-value test; no selector surface. |
| No repair/clamp/sort/deduplicate/partial publication of malformed required data | ✓ VERIFIED | Directory rejects noncanonical facts; metric admission rejects inconsistencies; construction occurs once after all gates. |
| No TTC/OTC, WOFF/WOFF2, CFF/CFF2, variation, color, or bitmap behavior | ✓ VERIFIED | Recognized profiles return capability errors; no public capability is exposed. |
| No licensed/downloaded real-font fixture in Phase 97 | ✓ VERIFIED | No font asset exists under `modules/mb-font`; generated MoonBit bytes only; Phase 100 owns real-font qualification. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/quality/Assert-Policy.ps1` | 227 | Literal `placeholder` in a validator that rejects placeholder approval evidence | ℹ️ Info | Enforcement code, not a stub or debt marker. |

The exact phase scope contains no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, functional placeholder, coming-soon text, or unimplemented runtime surface. `git diff --check` passes for the report, and the unrelated untracked VPU quick SUMMARY remains untouched.

The current deep review is clean (`depth: deep`, 14 files, 0 critical/warning/info findings). Its reviewed Phase 97 source/policy scope has not changed since the clean review. `97-SECURITY.md` is verified with 17/17 threats closed and `threats_open: 0`. These records corroborate, but do not replace, the implementation and test evidence above.

## Human Verification Required

None. This phase is a deterministic portable library/parser contract with no visual, interactive, external-service, or performance-feel criterion. Every state transition, cleanup/ordering invariant, and resource/revision behavior used by the roadmap truths has executable passing coverage. `behavior_unverified: 0`.

## Gaps Summary

No blocking or warning gap remains.

The sole literal plan-path discrepancy is the generated fixture file rename to `generated_fonts_wbtest.mbt`. The replacement is substantive, wired, exercised on all targets, and intentionally kept out of production compilation by exact policy. Later Unicode/kerning, outline, and licensed real-font qualification work is explicitly owned by Phases 98-100.

---

_Verified: 2026-07-27T04:36:54Z_
_Verifier: the agent (gsd-verifier)_
