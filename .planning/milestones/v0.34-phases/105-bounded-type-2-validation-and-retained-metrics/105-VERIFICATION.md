---
phase: 105-bounded-type-2-validation-and-retained-metrics
verified: 2026-07-28T16:39:29Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirement_score: 3/3 satisfied
requirements:
  - id: T2-01
    status: satisfied
    reason: "The sole pure-MoonBit Type 2 VM now uses the locked high16(state)+1 xorshift32 mapping, with corrected golden and operator-integration evidence."
  - id: T2-02
    status: satisfied
    reason: "Exact hint/subroutine/resource behavior remains passing, and every VM non-State failure now receives final source-revision preference, including deterministic mid-fetch mutation cases."
  - id: CFF-03
    status: satisfied
    reason: "Ascending all-glyph admission remains atomic, every non-empty contour contributes its transformed start to conservative bounds, and retained hmtx facts remain metric authority."
re_verification:
  previous_status: gaps_found
  previous_score: 1/4
  gaps_closed:
    - "Type2Prng::next now emits unsigned high16(state)+1; seed 0x12345678 begins with raw 34713 and the old low-bit golden was removed."
    - "The bounds sink now tracks segment emission per contour and includes each line-first or cubic-first contour start through the normal transformed hull path."
    - "EOF, byte, number, escape, operator, and dispatch failures now receive final revision preference; mid-fetch mutation tests return State while stable twins retain Data."
  gaps_remaining: []
  regressions: []
---

# Phase 105: Bounded Type 2 Validation and Retained Metrics Verification Report

**Phase Goal:** Maintainers can validate every Type 2 glyph deterministically and retain truthful compact bounds before any CFF-backed font is published.
**Verified:** 2026-07-28T16:39:29Z
**Status:** passed
**Re-verification:** Yes — after gap-closure Plan 105-05

## Goal Achievement

### Observable Truths

| # | Roadmap success criterion | Status | Evidence |
|---|---|---|---|
| 1 | Supported Type 2 number, stack, transient, arithmetic, logical, storage, width, line, curve, flex, subroutine, termination, and project-owned `random` behavior produces target-identical fixed-point results. | ✓ VERIFIED | The existing sole integer/fixed VM and operator tests remain intact. `Type2Prng::next` now returns `(state >> 16) + 1`; the hand-derived seed `0x12345678` sequence `[34713, 5468, 18465, 33204]` is frozen in the fixed-kernel test and the VM integration assertion now expects `34713`. |
| 2 | Hint/stem framing is exact and every named authority, including mutation, fails deterministically without host recursion or partial execution state. | ✓ VERIFIED | Existing exact masks, explicit local/global frames, depth/termination/resource tests remain in the passing native suite. All previously direct EOF/byte/number/escape failures now call `type2_error_with_revision`; the new read-probe regression mutates after the loop guard and proves State wins truncated number and escape Data outcomes. |
| 3 | Admission executes every glyph through one interpreter, retains truthful conservative bounds per GID, and keeps `hmtx` authoritative. | ✓ VERIFIED | Ascending all-GID execution and `hmtx` retention are unchanged. `contour_has_segments` resets on every moveto, and the first line/cubic includes the saved contour start through `include_point`; transformed later-contour extrema are now directly asserted while moveto-only glyphs remain `None`. |
| 4 | Any structural, program, numeric, resource, or mutation failure publishes no `Font`, no bounds, and no committed admission charge. | ✓ VERIFIED | Quick regression review confirms the previously verified staged structure → all-glyph VM → combined preflight → final revision guard → sole `commit_atomic` path is unchanged. The 1247-test native result includes the existing malformed, resource, mutation, and atomic-publication regressions. |

**Score:** 4/4 roadmap truths verified

The PLAN frontmatter details remain merged into the four roadmap truths: fixed arithmetic/random and all operator families support truth 1; hint/subroutine/limits/error ordering support truth 2; matrices/geometry/all-GID/hmtx support truth 3; and combined staging/commit supports truth 4.

## Gap Closure Verification

| Previous gap | Implementation evidence | Behavioral evidence | Status |
|---|---|---|---|
| PRNG used low16 instead of locked high16 | `cff_type2_fixed.mbt:228` now uses `(state >> 16) + 1`; transition, seed normalization, and per-GID reset are unchanged. | Focused high16 golden test: 1 passed. Fixed test expects `[34713, 5468, 18465, 33204]`; VM integration expects `34713`. | ✓ CLOSED |
| Later contour start omitted from bounds hull | `cff_type2_bounds.mbt` adds `contour_has_segments`, resets it on moveto, and calls `include_contour_start` before the first line/cubic hull update. | Focused line-first and cubic-first transformed later-contour test: 1 passed; existing moveto-only `None` regression remains in the full suite. | ✓ CLOSED |
| Direct VM errors bypassed final revision preference | `cff_type2.mbt` wraps root/subr EOF, raw-byte fetch, number decode, escape fetch, common dispatch errors, and exhausted-frame EOF with `type2_error_with_revision`. | Focused stable-Data/mid-fetch-mutation-State test: 1 passed for both truncated number and escape cases. | ✓ CLOSED |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/cff_type2_fixed.mbt` | Checked Q16.16, locked PRNG, exact matrices and rounding | ✓ VERIFIED | Substantive, wired, and corrected to high16 output. |
| `modules/mb-font/font/cff_type2.mbt` | Sole iterative VM, explicit frames, all-GID staging, universal error guard | ✓ VERIFIED | Production wrappers use the no-op probe; the private probe only enables precise white-box mutation placement. All non-State loop failures receive final revision preference. |
| `modules/mb-font/font/cff_type2_bounds.mbt` | Conservative transformed optional bounds | ✓ VERIFIED | Each non-empty contour start, endpoints, and cubic controls enter the same transformed hull; moveto-only glyphs stay empty. |
| `modules/mb-font/font/cff_dict.mbt`, `cff_keying.mbt`, `limits.mbt` | Retained seed, Top/optional-FD matrices, private limits | ✓ VERIFIED | Quick regression: required facts still feed `type2_execute_glyph` without duplicated name-keyed transforms. |
| `modules/mb-font/font/cff_admission.mbt`, `metrics.mbt` | Atomic all-glyph publication and `hmtx` authority | ✓ VERIFIED | Quick regression: combined charge/commit wiring and real `hmtx` data flow are unchanged. |
| Plan 105-05 white-box tests | Direct regression for all three previous blockers | ✓ VERIFIED | Tests first appeared in RED commits `d29d0686`, `9ec2f92a`, and `2de81b09`; fixes landed in `923af312`, `3aa19297`, and `c91c3657`. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Private DICT seed | random operator stack result | `initial_random_seed` → `Type2Prng::new` → high16 `next()` | ✓ WIRED | Exact locked output now reaches the same VM operator switch. |
| moveto/contour start | transformed retained hull | first line/cubic → `include_contour_start` → `include_point` → matrix application | ✓ WIRED | Line-first and cubic-first later contours are both covered. |
| every VM non-State failure | State precedence | `type2_error_with_revision(root, opening_revision, error)` | ✓ WIRED | Original bypassing direct returns were audited and wrapped; common result errors already use the same seam. |
| per-GID descriptors | sole VM and bounds sink | ascending `type2_stage_all_glyphs_with_probe` → `type2_execute_glyph` | ✓ WIRED | Fresh per-glyph VM state and selected environment remain unchanged. |
| structure + Type 2 facts | sole admission commit | combine → atomic preflight → final revision guard → `commit_atomic` | ✓ WIRED | No regression in the previously verified transaction. |
| retained CFF metric facts | face-local `hmtx` values | `CffMetricFacts.hmtx` → checked hmtx reader | ✓ WIRED | Type 2 width remains validation-only. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `cff_type2_fixed.mbt` | random Q16.16 raw value | selected Private DICT seed and xorshift32 state | Yes, locked high16 mapping | ✓ FLOWING |
| `cff_type2_bounds.mbt` | `GlyphBoundsFacts?` | every non-empty contour start plus transformed endpoints/control points | Yes, conservative hull with outward rounding | ✓ FLOWING |
| `cff_admission.mbt` | ordered retained bounds | complete all-GID VM result | Yes, only after total success and one commit | ✓ FLOWING |
| `metrics.mbt` | advance/LSB | actual admitted `hmtx` table window | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Locked high16 random sequence | `moon test modules/mb-font/font --target native -j 2 -f "Type 2 xorshift stream is repeatable, resettable, and strictly positive"` | 1 passed | ✓ PASS |
| Later line/cubic contour-start extrema | `moon test modules/mb-font/font --target native -j 2 -f "Type 2 bounds include each non-empty contour start"` | 1 passed | ✓ PASS |
| Mid-fetch mutation versus stable Data | `moon test modules/mb-font/font --target native -j 2 -f "Type 2 mid-fetch mutation wins truncated number and escape errors"` | 1 passed | ✓ PASS |
| Complete native regression | `moon test --target native -j 2` | 1247 passed, 0 failed (main/execution evidence supplied for re-verification) | ✓ PASS |
| Four-target compilation | `moon check --target all` | 0 errors on all configured targets; 31 non-fatal warnings (main/execution evidence supplied) | ✓ PASS |

## Probe Execution

No phase probe scripts or deferred `<human-check>` blocks are declared. Probe execution is not applicable.

## Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| T2-01 | 105-01 through 105-05 | ✓ SATISFIED | Sole pure-MoonBit fixed VM plus corrected high16 deterministic random golden and integration tests. |
| T2-02 | 105-01 through 105-05 | ✓ SATISFIED | Existing exact hint/frame/resource behavior plus universal final revision preference and deterministic mid-fetch mutation coverage. |
| CFF-03 | 105-01, 105-03, 105-04, 105-05 | ✓ SATISFIED | Ascending atomic all-glyph admission, corrected conservative per-contour bounds, retained real `hmtx` authority, and zero-publication/zero-charge failures. |

**Requirement score:** 3/3 satisfied. No Phase 105 requirement is orphaned.

## Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, or unimplemented marker was found in the Plan 105-05 implementation/test scope. The private read probe defaults to a production no-op and does not alter the public API. The all-target evidence retains 31 non-fatal unused/deprecated-debug warnings; none blocks the verified contracts.

## Human Verification Required

None. All Phase 105 outcomes are deterministic private VM, bounds, resource, and admission facts with direct automated evidence.

## Gaps Summary

All three previous gaps are closed with production changes and focused passing regressions. No regressions remain, all four roadmap success criteria are verified, and T2-01, T2-02, and CFF-03 are satisfied. Phase 105 achieves its goal and is ready for Phase 106.

---

_Verified: 2026-07-28T16:39:29Z_
_Verifier: the agent (gsd-verifier)_
