---
phase: 99-simple-and-composite-outlines
verified: 2026-07-27T12:44:43Z
status: passed
score: 14/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/14
  gaps_closed:
    - "The Phase 99 publication contract is internally consistent and enforced by both focused and repository-wide policy."
    - "Public outline documentation accurately describes the maxp/Data and FontLimits/max_work/Budget/Resource taxonomy."
  gaps_remaining: []
  regressions: []
---

# Phase 99: Simple and Composite Outlines Verification Report

**Phase Goal:** Library authors can extract complete unhinted `Path2`-compatible outlines for valid simple glyphs and bounded one-level composites without partial geometry on failure.
**Verified:** 2026-07-27T12:44:43Z
**Status:** passed
**Re-verification:** Yes — after Plan 99-04 gap closure

## Goal Achievement

Both previous blockers are closed in the actual repository. The runtime and public-interface truths that passed the initial verification also pass fresh regression checks. SUMMARY and review claims were not treated as evidence.

The codebase-memory graph was queried first as required. It exposed no MoonBit symbol nodes for this worktree, so source-level checks used the project-authorized direct-source fallback.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `Font::outline` is a direct shared-`Path2`, caller-Budget query that revalidates the receiving font, guards source revision before decode and after private work, and publishes only one complete path. | ✓ VERIFIED | `font.mbt:411-455` retains the pre-guard → glyph validation → private decode → callback seam → post-guard → single `Ok(path)` order. Fresh 92/92 four-target suites cover successful, empty, resource, and mutation paths. |
| 2 | Simple glyphs strictly decode endpoints, instruction envelopes, packed/repeated flags, signed x/y deltas, padding, bounds, and maxp claims. | ✓ VERIFIED | `outline.mbt` contains the strict decoder; `font_test.mbt:2212-2310` exercises repeat, delta, hostile-padding, and maxp cases. Fresh suites pass on all targets. |
| 3 | Simple contours preserve encoded order/winding and implement deterministic TrueType quadratic starts, implied midpoints, lines, quadratics, closure, empty glyphs, and degenerate contours without executing instructions. | ✓ VERIFIED | The simple lowerer and exact public/private path tests remain present; four-target 92/92 execution provides behavioral evidence. |
| 4 | Coordinates, implied points, transforms, offsets, and attachments remain checked signed `Int64` Q15 until final `Point2` construction. | ✓ VERIFIED | Private checked-Q15 helpers and final conversion remain in `outline.mbt`; matrix, midpoint, subtraction, and exact-coordinate tests pass in the fresh suites. |
| 5 | Outline work is bounded by maxp, four retained outline limits, cumulative `max_work`, caller Budget, and precharged scratch/output allocations. | ✓ VERIFIED | `outline.mbt:570-590` demonstrates maxp-before-retained-limit ordering; exact-fit, one-short, allocation-size, overflow, and failure-consumption regressions pass. |
| 6 | Composite extraction iteratively classifies the reachable graph, reports cycles/malformed graphs as Data, reports validated deeper acyclic graphs as Capability, and lowers no nested geometry. | ✓ VERIFIED | Tri-color graph code and its self-cycle, multi-cycle, and deeper-acyclic tests remain substantive and pass on all four targets. |
| 7 | One-level composites support first-component signed XY placement and later signed XY or real encoded-point attachment after transforming the child; implied points never enter attachment numbering. | ✓ VERIFIED | Descriptor/placement code and exact attachment-numbering tests remain wired through `Font::outline`; fresh suites pass. |
| 8 | Uniform, independent-axis, and 2×2 F2DOT14 transforms use exact OpenType matrix ordering; scaled, unscaled, and default offsets remain distinct; grid rounding is Capability. | ✓ VERIFIED | Transform and offset branches remain present with exact public/private tests; fresh suites pass. |
| 9 | Component order and contour winding are preserved; overlap and unique `USE_MY_METRICS` are neutral; reserved flags, duplicate metric flags, phantom references, and invalid references retain their taxonomy. | ✓ VERIFIED | Parser/lowerer tests for order, overlap, metrics neutrality, phantom, reference, and reserved-flag cases pass in every target suite. |
| 10 | Malformed streams, invalid references/flags, cycles, arithmetic failures, mutation, and resource exhaustion return structured errors without exposing partial commands. | ✓ VERIFIED | Private construction plus the single publication point remains intact; all structured error categories and transactional failure tests pass. |
| 11 | The permanent generated public/private matrix exercises simple, empty/degenerate, transformed/attached composite, hostile, resource, mutation, and prior-font behavior identically on all four targets. | ✓ VERIFIED | Fresh isolated runs report `Total tests: 92, passed: 92, failed: 0` on native, js, wasm, and wasm-gc. |
| 12 | The generated public interface contains only intended Phase 99 additions and leaks no parser/descriptor/Q15 state. | ✓ VERIFIED | Fresh `moon info --target all` succeeds; SHA-256 remains `d5bb5e76fe1448554aff2cf58e84b7a316d6f2255740736540cca956d89906e0`; the exact focused interface classifier passes. |
| 13 | The Phase 99 publication contract is internally consistent and enforced by repository policy. | ✓ VERIFIED | `moon.mod.json:4` exactly equals the selected policy description. `Assert-Policy.ps1:1074-1075` adds the focused case-sensitive comparison. A temporary drift fixture is rejected with `Manifest description drift in modules/mb-font.` Both focused and repository-wide gates pass. |
| 14 | Public documentation accurately describes the delivered outline API, limits, five-way taxonomy, and exclusions without Phase 100 overclaim. | ✓ VERIFIED | `README.mbt.md:279-285` classifies maxp underclaims as Data and only retained `FontLimits`, cumulative `max_work`, and caller `Budget` exhaustion as Resource. `Assert-Policy.ps1:1135-1148` enforces that split. Four literate target checks pass. |

**Score:** 14/14 truths verified (0 present-but-behavior-unverified)

### Roadmap and PLAN Must-Have Coverage

| Contract source | Resolution |
|---|---|
| ROADMAP SC1 — complete simple outlines with repeated flags, deltas, implied points, winding/order, closure | Truths 2-4 and 11 |
| ROADMAP SC2 — bounded one-level composites with XY/point placement and supported transforms | Truths 6-9 and 11 |
| ROADMAP SC3 — deterministic empty/degenerate results, no hinting/rasterization | Truths 3, 10, and 11 |
| ROADMAP SC4 — structured failure for malformed/reference/flag/cycle/arithmetic/mutation/resource cases without partial geometry | Truths 1, 5, 6, and 9-11 |
| Plans 99-01 through 99-03 — runtime, interface, portability, policy, and documentation | Truths 1-14 |
| Plan 99-04 — publication gap closure | Truths 13-14 |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/outline.mbt` | Transactional simple/composite decoder and lowerer | ✓ VERIFIED | Substantive and wired through `font_decode_outline`; fresh behavior suites pass. |
| `modules/mb-font/font/font.mbt` | Public guarded query and retained limits | ✓ VERIFIED | `Font::outline` and its two-guard publication sequence remain intact. |
| `modules/mb-font/font/limits.mbt` | Four explicit nonzero outline ceilings | ✓ VERIFIED | Constructor/accessor interface remains generated and tested. |
| `modules/mb-font/font/tables.mbt` | Version-1 maxp outline facts | ✓ VERIFIED | Maxp claims flow into the outline decoder and Data classification. |
| `modules/mb-font/font/metrics.mbt` | Shared admitted glyph-window helper | ✓ VERIFIED | Root/component lookup remains connected. |
| `modules/mb-font/font/font_test.mbt` | Public exact-path/error/resource matrix | ✓ VERIFIED | Included in all four 92-test passes. |
| `modules/mb-font/font/font_wbtest.mbt` | Private Q15/graph/charging/mutation evidence | ✓ VERIFIED | Included in all four 92-test passes. |
| `modules/mb-font/font/generated_fonts_wbtest.mbt` | Checksum-correct independent generated fixtures | ✓ VERIFIED | Consumed by the passing public/private matrix. |
| `modules/mb-font/font/pkg.generated.mbti` | Minimal generated public interface | ✓ VERIFIED | Freshly regenerated with the expected stable hash. |
| `policy/foundation.json` | Exact sources/imports/targets/interface/description contract | ✓ VERIFIED | JSON parses; selected description exactly matches the manifest; both policy gates pass. |
| `scripts/quality/Assert-Policy.ps1` | Independent fail-closed font classifier | ✓ VERIFIED | Focused description and README taxonomy checks are substantive, run, and pass; the drift fixture is rejected. |
| `modules/mb-font/moon.mod.json` | Approved Phase 99 module description | ✓ VERIFIED | Byte-for-byte/case-sensitive equality with policy confirmed. |
| `modules/mb-font/README.mbt.md` | Executable accurate public contract | ✓ VERIFIED | Correct taxonomy and four-target compilation confirmed. |
| `modules/mb-font/CHANGELOG.md` and root `README.md` | Candidate and bilingual discovery records | ✓ VERIFIED | Unchanged since initial verification; focused/repository policy and README checks retain their scope fences. |

The generic artifact query passes all 23 declarations across Plans 99-01 through 99-04. Its filename-reference key-link heuristic cannot resolve MoonBit same-package private symbols or documentation-to-test semantic links, so links below were verified from source and executable gates.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `font.mbt` | `outline.mbt` | `Font::outline_after_decode` → `font_decode_outline` | ✓ WIRED | Direct call at `font.mbt:439-448`; post-guard precedes the only returned path. |
| `outline.mbt` | maxp / `FontLimits` / caller Budget | Data-before-Resource checks and staged charging | ✓ WIRED | `outline.mbt:570-590` and composite equivalents distinguish maxp Data from retained/caller Resource. |
| Tests | implementation | generated bytes and exact result assertions | ✓ WIRED | Same 92-test package passes on all four targets. |
| `pkg.generated.mbti` | `policy/foundation.json` | exact semantic interface sequence | ✓ WIRED | Fresh generation and focused selector pass with the stable hash. |
| `policy/foundation.json` | `moon.mod.json` | focused and repository-wide case-sensitive description comparison | ✓ WIRED | Real descriptions match; temporary divergent policy fixture is rejected. |
| `README.mbt.md` | implementation/tests | documented error taxonomy | ✓ WIRED | README maxp/Data and retained-limit/Resource text matches `outline.mbt` plus `font_test.mbt:2262-2330`; focused bullet assertions pass. |

## Data-Flow Trace

| Query | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Simple outline | `PathCommand` sequence | admitted `loca`/`glyf` window → strict flags/deltas → Q15 points → lowerer | Yes; exact commands asserted | ✓ FLOWING |
| Composite outline | placed child points/contours | descriptor graph → child windows → Q15 transform → placement → ordered lowerer | Yes; transformed and attached paths asserted | ✓ FLOWING |
| Structured failure taxonomy | `CoreError` | maxp/format/graph/arithmetic/limits/work/Budget/revision gates | Yes; exact categories and contexts asserted | ✓ FLOWING |
| Publication metadata | module description | policy module record → focused/repository comparison → manifest | Yes; exact equality and negative drift fixture | ✓ FLOWING |
| Public taxonomy | Data/Resource bullets | implementation/test oracle → README → focused bullet assertions | Yes; executable test and four-target literate checks | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Native full font regression | `moon -C modules/mb-font test font --target native --frozen --target-dir target/phase99-reverify2-font-native --no-parallelize` | 92 passed, 0 failed | ✓ PASS |
| JavaScript full font regression | same with `--target js` | 92 passed, 0 failed | ✓ PASS |
| Wasm full font regression | same with `--target wasm` | 92 passed, 0 failed | ✓ PASS |
| Wasm-GC full font regression | same with `--target wasm-gc` | 92 passed, 0 failed | ✓ PASS |
| Four-target literate README | `moon -C modules/mb-font check README.mbt.md --target <target> --frozen --target-dir target/phase99-reverify-doc-<target> --serial` | exit 0 on all four targets | ✓ PASS |
| Focused font policy | `Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json` | verified | ✓ PASS |
| Repository-wide policy | `Assert-FoundationPolicy -PolicyPath ./policy/foundation.json` | verified | ✓ PASS |
| Temporary manifest-description drift | focused selector over a temporary policy copy with a divergent description | rejected with the exact manifest-drift diagnostic | ✓ PASS |
| Native package check | `moon -C modules/mb-font check --target native --frozen` | exit 0 | ✓ PASS |
| Fresh generated interface | `moon -C modules/mb-font info --target all --frozen --target-dir target/phase99-reverify-interface` | exit 0; expected SHA-256 | ✓ PASS |
| Policy JSON and whitespace | JSON parse; `git diff --check` | pass | ✓ PASS |

The only compiler warnings came from the installed MoonBit core `builtin/result.mbt`; project tests and checks had no failures.

## Probe Execution

Step 7c: **SKIPPED** — no Phase 99 plan or summary declares a probe, and no conventional Phase 99 probe exists.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| FONT-03 | 99-01, 99-02, 99-03, 99-04 | Complete unhinted simple and bounded one-level composite `Path2` outlines with checked arithmetic and no partial geometry on failure | ✓ SATISFIED | All four ROADMAP criteria, 14 must-haves, exact policy/docs gates, and fresh 92/92 four-target execution pass. |

No other requirement maps to Phase 99.

## Prohibitions and Scope Fences

| Prohibition | Status | Evidence |
|---|---|---|
| No failed query exposes partial `Path2` commands | ✓ VERIFIED | Private construction, one guarded return, and failure tests remain green. |
| No contour normalization/reversal/flattening/overlap processing | ✓ VERIFIED | Encoded ordering tests remain green. |
| No TrueType instruction execution | ✓ VERIFIED | Instructions are validated, charged, and skipped. |
| No recursive nested geometry | ✓ VERIFIED | Iterative classification returns Capability for deeper valid graphs. |
| No implied point enters attachment numbering | ✓ VERIFIED | Private/public attachment tests pass. |
| No `USE_MY_METRICS` geometry or metric rewrite | ✓ VERIFIED | Metrics-neutral test passes. |
| No private parser/descriptor/graph/Q15 or deferred capability leaks publicly | ✓ VERIFIED | Exact generated-interface classifier passes. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/quality/Assert-Policy.ps1` | 227 | Literal placeholder/TODO/TBD words in a rejection regex | ℹ️ Info | Validator oracle text, not debt or a stub. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker or runtime placeholder appears in the Plan 99-04 modified artifacts.

## Post-Wave Drift Gates

Schema and UI drift gates are non-applicable: Plan 99-04 changed only `modules/mb-font/moon.mod.json`, `scripts/quality/Assert-Policy.ps1`, and `modules/mb-font/README.mbt.md`. No schema or UI file was touched.

## Human Verification Required

None. All must-haves are deterministic library, policy, interface, documentation, or structured-error behaviors with executable evidence.

## Gaps Summary

No gaps remain. Plan 99-04 closes both prior blockers without runtime, public-interface, schema, UI, target, or dependency drift. Phase 99 achieves FONT-03 and is ready to proceed.

---

_Verified: 2026-07-27T12:44:43Z_
_Verifier: the agent (gsd-verifier)_
