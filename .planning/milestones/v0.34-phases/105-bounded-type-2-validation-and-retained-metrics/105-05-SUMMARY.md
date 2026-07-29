---
phase: 105-bounded-type-2-validation-and-retained-metrics
plan: "05"
subsystem: font
tags: [moonbit, cff1, type2, fixed-point, bounds, mutation-precedence]

requires:
  - phase: 105-bounded-type-2-validation-and-retained-metrics
    provides: deterministic Type 2 VM, transformed bounds sink, and atomic all-glyph admission
provides:
  - project-owned high16 xorshift32 random output with locked golden vectors
  - conservative transformed bounds that include every non-empty contour start
  - universal final source-revision precedence for Type 2 VM failures
affects: [phase-106-cff-outline-publication, type2-validation, cff-admission]

tech-stack:
  added: []
  patterns:
    - per-contour segment state gates contour-start hull inclusion
    - every non-State VM failure passes through one final revision guard
    - private no-op-by-default read probes make mutation races deterministic in white-box tests

key-files:
  created: []
  modified:
    - modules/mb-font/font/cff_type2_fixed.mbt
    - modules/mb-font/font/cff_type2_fixed_wbtest.mbt
    - modules/mb-font/font/cff_type2_wbtest.mbt
    - modules/mb-font/font/cff_type2_bounds.mbt
    - modules/mb-font/font/cff_type2_bounds_wbtest.mbt
    - modules/mb-font/font/cff_type2.mbt
    - modules/mb-font/font/cff_type2_fixture_wbtest.mbt

key-decisions:
  - "Keep the xorshift32 transition and per-GID reset unchanged; only map high16(state)+1 into Q16.16 raw output."
  - "Include a contour start only when that contour emits its first line or cubic, preserving None for moveto-only glyphs."
  - "Use type2_error_with_revision as the sole final preference seam for EOF, byte, number, escape, mask, operator, and dispatch failures."

patterns-established:
  - "Contour bounds: moveto records state, while first-segment emission activates the saved start through the normal transformed hull path."
  - "VM errors: loop-entry State checks are supplemented by a final revision recheck before every non-State return."

requirements-completed: [T2-01, T2-02, CFF-03]

coverage:
  - id: D1
    description: "The Type 2 random operator emits the locked high16(state)+1 sequence, beginning with 34713 for seed 0x12345678."
    requirement: T2-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_fixed_wbtest.mbt#Type 2 xorshift stream is repeatable, resettable, and strictly positive"
        status: pass
      - kind: integration
        ref: "moon test --target native -j 2 (1247 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every non-empty line-first or cubic-first contour contributes its transformed start to conservative retained bounds."
    requirement: CFF-03
    verification:
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_bounds_wbtest.mbt#Type 2 bounds include each non-empty contour start"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_bounds_wbtest.mbt#Type 2 empty and moveto-only glyphs retain no bound"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mutation after the loop guard but before a failing number or escape fetch wins as State, while stable twins retain Data contexts."
    requirement: T2-02
    verification:
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_fixture_wbtest.mbt#Type 2 mid-fetch mutation wins truncated number and escape errors"
        status: pass
      - kind: integration
        ref: "moon check --target all (0 errors)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-28
status: complete
---

# Phase 105 Plan 05: Type 2 Verifier Gap Closure Summary

**High16 deterministic random, per-contour conservative hull starts, and final revision-precedence guards close all three Phase 105 verifier blockers.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-28T16:23:18Z
- **Completed:** 2026-07-28T16:35:37Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Corrected `Type2Prng::next` to emit unsigned `high16(state) + 1`, with the locked seed `0x12345678` sequence starting at `34713`.
- Added per-contour segment state so a later contour's transformed moveto extreme enters the hull only when that contour draws.
- Routed root/subroutine EOF, raw-byte fetch, number decode, escaped-byte fetch, exhausted-frame EOF, and existing dispatch failures through final revision preference.
- Preserved empty/endchar-only/moveto-only `None` bounds, State → Resource → Capability → Data ordering, and atomic admission behavior.

## Task Commits

Each task followed a RED/GREEN sequence:

1. **Task 1: Correct and refreeze deterministic random output**
   - `d29d0686` — test: lock high16 Type 2 random vectors
   - `923af312` — feat: emit high16 Type 2 random values
2. **Task 2: Include every non-empty contour start in conservative bounds**
   - `9ec2f92a` — test: expose omitted later contour starts
   - `3aa19297` — feat: retain every non-empty contour start
3. **Task 3: Route all VM errors through final revision precedence**
   - `2de81b09` — test: expose mid-fetch mutation precedence gap
   - `c91c3657` — feat: guard every Type 2 VM error exit

## Files Created/Modified

- `modules/mb-font/font/cff_type2_fixed.mbt` — selects the high 16 xorshift state bits without changing the state transition.
- `modules/mb-font/font/cff_type2_fixed_wbtest.mbt` — freezes the correct four-value high16 sequence and reset/range behavior.
- `modules/mb-font/font/cff_type2_wbtest.mbt` — aligns the random operator integration assertion with the locked first value.
- `modules/mb-font/font/cff_type2_bounds.mbt` — tracks segment emission per contour and includes the saved start on first drawing.
- `modules/mb-font/font/cff_type2_bounds_wbtest.mbt` — covers transformed line-first and cubic-first later-contour extremes.
- `modules/mb-font/font/cff_type2.mbt` — adds a private read probe and final revision guards to all direct VM error exits.
- `modules/mb-font/font/cff_type2_fixture_wbtest.mbt` — proves stable Data contexts and mid-fetch mutation State precedence.

## Decisions Made

- The PRNG fix changes only output-bit selection; seed normalization, transition, per-GID reset, and operator plumbing remain intact.
- A moveto does not create bounds. The saved start is included through the same matrix/hull path immediately before the contour's first segment.
- The deterministic read probe is private and defaults to a no-op; it exists only to place white-box mutation at the exact guard/fetch boundary.

## Verification

- Focused PRNG RED: expected `34713`, current implementation produced `23206`.
- Focused PRNG GREEN: 1 passed, 0 failed.
- Focused later-contour RED: expected transformed `x_max=210`, current implementation produced `110`.
- Focused later-contour and moveto-only GREEN: 2 passed, 0 failed.
- Focused mid-fetch RED: mutation-raced truncated fetch returned non-State.
- Focused mid-fetch GREEN: 1 passed, 0 failed, covering both number and escape truncation.
- `moon test modules/mb-font/font --target native -j 2` — 237 passed, 0 failed.
- `moon test --target native -j 2` — 1247 passed, 0 failed.
- `moon check --target all` — passed with 0 errors on every configured target.
- The final checks retain 31 non-fatal pre-existing unused/deprecated-debug warnings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated the existing VM random integration golden**
- **Found during:** Task 1 full module verification.
- **Issue:** `cff_type2_wbtest.mbt` was outside the plan's file list but still asserted the obsolete low16 value `23206`, causing 235/236 module tests to pass after the production fix.
- **Fix:** Updated the integration assertion to the locked high16 first value `34713`.
- **Files modified:** `modules/mb-font/font/cff_type2_wbtest.mbt`
- **Verification:** Module-native tests passed 236/236 after Task 1 and 237/237 after all tasks.
- **Committed in:** `923af312`

---

**Total deviations:** 1 auto-fixed (1 blocking issue).
**Impact on plan:** The extra test-only edit was required to keep existing integration evidence consistent with the corrected normative contract; no production scope widened.

## Issues Encountered

- The only failure outside the planned RED cases was the stale VM integration golden described above; it was corrected before Task 1 completion.

## Known Stubs

None. Empty arrays found by the scan are bounded accumulators, copied stack slices, or deterministic white-box fixture builders; none flow to an unwired UI or public result.

## Threat Flags

None. The changes add no public endpoint, authentication path, filesystem access, schema boundary, or new public trust surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- T2-01, T2-02, and CFF-03 now have direct passing regressions for every verifier blocker.
- Phase 106 can consume deterministic random behavior, conservative multi-contour bounds, and universal mutation precedence.
- No blocker remains in the Phase 105 gap-closure scope.

## Self-Check: PASSED

- All seven listed implementation/evidence files and this summary exist.
- All six RED/GREEN task commits are present in repository history.
- Final native and all-target verification passed before summary creation.

---
*Phase: 105-bounded-type-2-validation-and-retained-metrics*
*Completed: 2026-07-28*
