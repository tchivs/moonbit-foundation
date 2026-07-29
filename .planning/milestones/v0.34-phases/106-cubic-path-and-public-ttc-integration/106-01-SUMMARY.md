---
phase: 106-cubic-path-and-public-ttc-integration
plan: "01"
subsystem: font
tags: [moonbit, cff1, type2, path2, cubic, atomic-budget]

requires:
  - phase: 105-bounded-type-2-validation-and-retained-metrics
    provides: deterministic Type 2 VM, transformed bounds, compact descriptors, and atomic all-glyph admission
provides:
  - standalone static CFF1 promotion through the existing opaque Font API
  - native exact-capacity MoveTo, LineTo, CubicTo, and Close Path2 publication
  - compact per-GID publishable command counts and one-commit selected-outline authority
affects: [phase-106-ttc-integration, phase-107-qualification, mb-font, mb-core-math]

tech-stack:
  added: []
  patterns:
    - one shared Type 2 geometry state feeds compact admission bounds and selected-glyph path emission
    - retained command counts preflight exact path capacity before one selected VM execution
    - post-stage mutation guard precedes one caller-and-ancestor Budget charge and immediate Path2 return

key-files:
  created:
    - modules/mb-font/font/cff_type2_path.mbt
  modified:
    - modules/mb-core/math/path.mbt
    - modules/mb-font/font/cff_type2_bounds.mbt
    - modules/mb-font/font/cff_type2.mbt
    - modules/mb-font/font/cff_admission.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/cff_admission_wbtest.mbt
    - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
    - modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt
    - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
    - modules/mb-font/font/collection_wbtest.mbt
    - modules/mb-font/font/font_qualification_hostile_test.mbt

key-decisions:
  - "Retain compact bounds plus exact per-GID publishable command counts; never retain full paths or a replay command stream."
  - "Keep one Type 2 operator loop and apply exact rational matrices before one quotient-plus-remainder Double conversion at Point2 construction."
  - "Keep face-local hmtx and retained CFF bounds as public metric authority; Type 2 width remains validation-only."
  - "Charge 64 logical bytes per CFF path command plus fixed VM scratch and actual work through one atomic caller-and-ancestor commit."

patterns-established:
  - "Pending moveto: a contour publishes MoveTo only when its first line or cubic is emitted, and only non-empty contours publish Close."
  - "CFF Font projection: complete admitted common facts and CFF execution facts cross one private non-fallible promotion boundary."
  - "Selected outline transaction: fixed preflight, one VM execution, exact preflight, post-stage probe, revision guard, one Budget charge, immediate return."

requirements-completed: [CFF-04]

coverage:
  - id: CFF-04-standalone
    description: "A static CFF1 OTTO opens through Font::open and preserves scalar lookup, numeric GID, hmtx metrics, kerning, and native cubic outline behavior."
    requirement: CFF-04
    verification:
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#Phase 106 standalone CFF1 opens and publishes one native cubic path"
        status: pass
      - kind: integration
        ref: "moon test modules/mb-font/font --target native --filter \"*Phase 106 standalone CFF1*\" (3 passed)"
        status: pass
    human_judgment: false
  - id: CFF-04-atomic-authority
    description: "Exact caller and ancestor authority succeeds, allocation-size one-short fails unchanged, and post-stage mutation returns State without charging either ledger."
    requirement: CFF-04
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#CFF outline exact path charge tracer rejects post-stage mutation atomically"
        status: pass
      - kind: integration
        ref: "moon test modules/mb-font/font --target native --filter \"*CFF outline exact path charge tracer*\" (1 passed)"
        status: pass
    human_judgment: false
  - id: CFF-04-geometry-edges
    description: "Empty, move-only, line, flex, multi-contour, fractional, cancellation, translated, scalar, and numeric-GID behavior is frozen through public Font operations."
    requirement: CFF-04
    verification:
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#Phase 106 standalone CFF1 freezes empty line flex contour and mapping edges"
        status: pass
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#Phase 106 standalone CFF1 converts fractional cancellation and translation once"
        status: pass
    human_judgment: false

duration: 33min
completed: 2026-07-29
status: complete
---

# Phase 106 Plan 01: Standalone CFF Cubic Path Tracer Summary

**Standalone static CFF1 fonts now flow through the existing opaque `Font` API to exact-capacity native cubic `Path2` geometry with compact retained authority and one atomic caller/ancestor budget commit.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-07-28T18:56:44Z
- **Completed:** 2026-07-28T19:30:04Z
- **Tasks:** 2
- **Files created/modified:** 15

## Accomplishments

- Added format-neutral `Path2::with_capacity(Int)` without changing storage privacy, append order, or existing path behavior.
- Promoted complete standalone CFF1 admission facts into the existing opaque `Font`, preserving common queries, face-local hmtx metrics, cmap, kern, and structured errors.
- Added a private shared Type 2 path sink that emits native cubic commands from the sole interpreter while keeping exact matrix arithmetic rational until checked `Point2` conversion.
- Retained only compact bounds and per-GID command counts, then re-executed one selected descriptor once into an exact-capacity path.
- Implemented fixed and exact caller/ancestor preflights, post-stage mutation precedence, one final revision guard, one `Budget::charge`, and an immediate infallible return.
- Froze empty/move-only, line, flex, multi-contour, fractional, large-cancellation, translated, scalar, and numeric-GID behavior through public tests.

## Task Commits

1. **Task 1: Open one standalone CFF1 font and publish one exact native cubic path end to end**
   - `85ca537b` — test: add failing standalone CFF path tracer
   - `c526223e` — feat: publish standalone CFF cubic outlines atomically
2. **Task 2: Freeze contour, empty-glyph, and Unicode/GID edge behavior**
   - `50148f32` — test: freeze CFF outline edge behavior

Task 2 was intentionally test-only. Its edge matrix passed on first execution because Task 1's shared sink already implemented the planned contour, conversion, and mapping behavior.

## Files Created/Modified

- `modules/mb-core/math/path.mbt` — adds exact initial-capacity construction for the shared path owner.
- `modules/mb-font/font/cff_type2_path.mbt` — owns the private path sink, checked rational conversion, exact charge, and selected-outline transaction.
- `modules/mb-font/font/cff_type2_bounds.mbt` — shares contour state and geometry events with optional path emission.
- `modules/mb-font/font/cff_type2.mbt` — retains per-GID command counts and runs one selected descriptor through the existing VM in path mode.
- `modules/mb-font/font/cff_admission.mbt` — retains complete common facts and joins their work into atomic CFF admission.
- `modules/mb-font/font/tables.mbt` — extracts an outline-neutral common-table admission helper while preserving the glyf wrapper.
- `modules/mb-font/font/font.mbt` — projects complete CFF facts and privately dispatches cardinality, metrics, cmap/kern, and outlines.
- `modules/mb-font/font/font_test.mbt` — provides the public standalone tracer and its geometry, transform, empty, scalar, and GID edge matrix.
- `modules/mb-font/font/font_wbtest.mbt` — proves exact caller/ancestor charging, allocation-size one-short rejection, and post-stage mutation atomicity.
- Existing CFF admission, fixture, collection, and qualification tests were aligned with the expanded compact retained slot and supported OTTO profile.

## Decisions Made

- Exact publishable command counts are admission facts; full `Path2` values are never retained or replayed.
- Bounds and paths consume one shared Type 2 geometry lifecycle, so coordinate accumulation, matrix composition, contour activation, and closure cannot diverge.
- A moveto remains pending until drawing begins. Endchar-only and move-only glyphs therefore return an empty path with `None` bounds.
- `hmtx` remains metric authority even when a Type 2 width operand disagrees.
- The CFF path authority unit is 64 logical bytes per command; the final charge also includes four VM scratch allocations, one path allocation when non-empty, the largest allocation, and actual VM/path work.

## Verification

- `moon test modules/mb-core/math --target native` — 88 passed, 0 failed.
- `moon test modules/mb-font/font --target native` — 247 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*Phase 106 standalone CFF1*"` — 3 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*CFF outline exact path charge tracer*"` — 1 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "Phase 105 preserves the public standalone static glyf fingerprint"` — 1 passed, 0 failed.
- `moon check --target all` — passed with 0 errors on every configured target.
- The all-target check reports 37 non-fatal unused/deprecated-debug warnings, primarily private retained facts and white-box-only helpers; no verification was skipped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated exact CFF retained-ledger expectations**
- **Found during:** Task 1 full-module verification.
- **Issue:** Adding one retained per-GID command-count array changed the compact Type 2 slot from 24 to 32 logical bytes and added one outer allocation, leaving exact/one-short admission tests on the old authority values.
- **Fix:** Updated exact retained bytes/allocations and derived caller limits from admitted combined charges in the affected admission, hostile, name-keyed, Type 2 fixture, and collection tests.
- **Files modified:** `cff_admission_wbtest.mbt`, `cff_hostile_fixture_wbtest.mbt`, `cff_name_keyed_fixture_wbtest.mbt`, `cff_type2_fixture_wbtest.mbt`, `collection_wbtest.mbt`
- **Verification:** All CFF white-box files passed individually and the complete font module passed 247/247.
- **Committed in:** `c526223e`

**2. [Rule 3 - Blocking] Reclassified OTTO as supported in legacy capability tests**
- **Found during:** Task 1 full-module verification.
- **Issue:** Two legacy tests still used `OTTO` as the unsupported outline signature after this plan made supported static CFF1 OTTO a public `Font::open` profile.
- **Fix:** Replaced those negative fixtures with the genuinely unsupported `typ1` signature while preserving the existing capability error contract.
- **Files modified:** `font_test.mbt`, `font_qualification_hostile_test.mbt`
- **Verification:** `font_test.mbt` passed 73/73 before Task 2 expansion; final module verification passed 247/247.
- **Committed in:** `c526223e`

**3. [Rule 3 - Blocking] Normalized SDK-generated Phase 106 state labels**
- **Found during:** Final state advancement.
- **Issue:** The state SDK advanced to Plan 2 but attributed four recorded decisions to `Phase ?` and retained stale Phase 105 next-step prose.
- **Fix:** Assigned the decisions to Phase 106 and synchronized activity, blocker, metric, and next-step prose with the completed plan and current roadmap position.
- **Files modified:** `.planning/STATE.md`
- **Verification:** State now reports Plan 2 of 3, 83% milestone progress, Phase 106 decision labels, and Phase 106 Plan 02 as the next action.
- **Committed in:** final metadata commit

---

**Total deviations:** 3 auto-fixed blocking issues.
**Impact on plan:** The code/test changes were required consequences of the planned retained-authority and OTTO-support contracts, and the metadata adjustment kept execution state coherent; no production scope or public CFF-specific API was added.

## Issues Encountered

- Full-module verification initially surfaced stale exact-ledger and unsupported-OTTO fixtures. Both were isolated to directly affected historical tests and corrected before Task 1 commit.
- No authentication gate, package installation, or external service dependency occurred.

## Known Stubs

None. The fixture variable named `placeholder_top` is a complete same-size offset-layout probe used to calculate final CFF offsets; it is not a runtime stub or unwired result.

## Threat Flags

None. The plan hardens the existing untrusted-font and budget trust boundaries but adds no network endpoint, authentication path, filesystem access, schema boundary, FFI, or ambient I/O.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Standalone CFF1 now exercises the complete opaque `Font` workflow and native cubic `Path2` publication required by CFF-04.
- Plan 106-02 can focus on direct format-neutral capacity-constructor and storage expansion without reopening CFF publication semantics.
- Plan 106-03 can reuse the same complete admitted facts and selected-outline transaction for TTC/OTC face-local integration.
- No blocker remains in the 106-01 scope.

## Self-Check: PASSED

- All nine listed implementation/evidence files and this summary exist.
- RED `85ca537b`, GREEN `c526223e`, and Task 2 `50148f32` commits exist in repository history.
- Final native focused, complete module, glyf fingerprint, and all-target verification passed before state advancement.

---
*Phase: 106-cubic-path-and-public-ttc-integration*
*Completed: 2026-07-29*
