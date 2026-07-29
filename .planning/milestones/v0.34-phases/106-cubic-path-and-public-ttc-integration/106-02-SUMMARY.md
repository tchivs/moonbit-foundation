---
phase: 106-cubic-path-and-public-ttc-integration
plan: "02"
subsystem: font
tags: [moonbit, cff1, type2, path2, atomic-budget, mutation-precedence]

requires:
  - phase: 106-cubic-path-and-public-ttc-integration
    provides: standalone CFF1 promotion, exact-capacity cubic paths, retained command counts, and one-commit outline authority
provides:
  - exhaustive exact and one-short caller/ancestor evidence for every CFF path resource dimension
  - direct capacity, rational conversion, native command, mismatch, overflow, repetition, and interleaving evidence
  - authorized pre-execution, VM-fetch, and post-stage mutation evidence with State-first precedence and zero partial publication
affects: [phase-106-ttc-integration, phase-107-qualification, mb-font, mb-core-math]

tech-stack:
  added: []
  patterns:
    - private no-op-by-default query probes exist only at authorized pre-commit seams
    - a pre-execution probe is followed immediately by an outer source-revision guard before resource or VM failures
    - exact staged CFF paths retain one final guard, one Budget charge, and an immediate infallible return

key-files:
  created:
    - modules/mb-font/font/cff_type2_path_wbtest.mbt
  modified:
    - modules/mb-core/math/path_wbtest.mbt
    - modules/mb-font/font/cff_type2_path.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/font_test.mbt

key-decisions:
  - "Keep the public selected-outline path on a no-op wrapper and expose probes only through a private white-box transaction entry."
  - "Run the authorized pre-execution probe before fixed resource preflight, then guard the outer font revision immediately so State outranks competing Resource, Capability, and Data failures."
  - "Reuse the existing VM read probe for mid-fetch mutation evidence and add no callback, guard, allocation, validation, or other fallible seam after the sole Budget charge."

patterns-established:
  - "CFF atomic tests compare every caller and ancestor counter before and after each failure, not only the failing dimension."
  - "Repeated and interleaved public queries compare every ordered PathCommand plus per-call byte, allocation, and work deltas."

requirements-completed: [CFF-04]

coverage:
  - id: CFF-04-resource-matrix
    description: "The selected CFF outline transaction succeeds at exact caller and ancestor authority and rejects every independent one-short bytes, allocations, allocation-size, and work window without charging."
    requirement: CFF-04
    verification:
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_path_wbtest.mbt#CFF outline exact path charge covers caller and ancestor dimensions"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_path_wbtest.mbt#CFF outline exact path charge rejects each one-short window atomically"
        status: pass
    human_judgment: false
  - id: CFF-04-mutation-precedence
    description: "Pre-execution, VM-fetch, and post-stage mutation returns State with no Path2 or caller/ancestor charge, while stable faults preserve Resource then Capability then Data precedence."
    requirement: CFF-04
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#CFF outline atomic mutation probes preserve every budget window"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#CFF outline atomic multi-fault precedence is State Resource Capability Data"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/cff_type2_path_wbtest.mbt#CFF outline atomic mid-fetch mutation publishes no staged path"
        status: pass
    human_judgment: false
  - id: CFF-04-capacity-and-determinism
    description: "Format-neutral capacity, quotient-plus-remainder conversion, native commands, overflow/mismatch rejection, repeated/interleaved paths, and receiving-font GID validation remain deterministic."
    requirement: CFF-04
    verification:
      - kind: unit
        ref: "moon test modules/mb-core/math --target native (91 passed)"
        status: pass
      - kind: integration
        ref: "moon test modules/mb-font/font --target native --filter \"*Phase 106 standalone CFF1*\" (4 passed)"
        status: pass
      - kind: integration
        ref: "moon test --target native (1269 passed)"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-07-29
status: complete
---

# Phase 106 Plan 02: CFF Outline Transaction Expansion Summary

**Exact caller/ancestor authority, direct cubic conversion, deterministic repetition, and State-first mutation evidence now freeze the complete selected CFF outline transaction without adding another interpreter or publication seam.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-28T19:33:54Z
- **Completed:** 2026-07-28T19:50:57Z
- **Tasks:** 2
- **Files created/modified:** 5

## Accomplishments

- Added format-neutral `Path2::with_capacity` evidence for zero, exact positive, negative, length, and ordered insertion behavior.
- Added direct quotient-plus-remainder and transformed native line/cubic command goldens, including signed fractions and large cancellation.
- Froze exact and independently one-short bytes, allocations, allocation-size, and work authority for direct callers and nested ancestor windows.
- Proved retained/emitted command mismatch and `capacity * 64` overflow fail atomically without a path or charge.
- Proved repeated and interleaved selected-GID calls reproduce identical ordered commands and identical per-call charge deltas.
- Added private pre-execution probing with immediate outer revision preference, plus VM-fetch and post-stage mutation tests that preserve every caller and ancestor window.
- Froze State → Resource → Capability → Data multi-fault ordering and CFF receiving-font invalid/cross-font GID behavior.

## Task Commits

Each task followed a RED/GREEN sequence:

1. **Task 1: Expand exact/one-short, conversion, repetition, and ancestor evidence**
   - `f1a5db94` — test: add failing CFF path transaction matrix
   - `0666eebf` — feat: expose authorized CFF pre-execution probe
2. **Task 2: Freeze mutation, multi-fault, invalid-GID, and zero-publication behavior**
   - `773ca318` — test: add failing CFF atomic mutation matrix
   - `3f851047` — fix: prefer CFF revision drift before resource faults

## Files Created/Modified

- `modules/mb-core/math/path_wbtest.mbt` — freezes exact, zero, negative, length, and insertion-order behavior for the shared capacity constructor.
- `modules/mb-font/font/cff_type2_path.mbt` — adds the private no-op-by-default pre-execution probe and immediate outer revision preference while preserving the sole closing sequence.
- `modules/mb-font/font/cff_type2_path_wbtest.mbt` — covers conversion, native commands, exact/one-short authority, overflow, mismatch, and VM-fetch mutation.
- `modules/mb-font/font/font_wbtest.mbt` — covers caller/ancestor mutation atomicity and State/Resource/Capability/Data multi-fault ordering.
- `modules/mb-font/font/font_test.mbt` — covers repeated/interleaved public paths and receiving-font CFF GID validation.

## Decisions Made

- The existing `cff_decode_outline_atomic` remains the production entry and delegates with a no-op pre-execution probe; only white-box tests can select the probe seam.
- The pre-execution probe runs after receiving-font GID validation but before fixed resource preflight. An immediate outer revision guard makes mutation, including mutate-and-restore, win every competing non-State failure.
- Mid-fetch mutation continues through the Phase 105 VM read probe; no second selected-glyph interpreter or transaction was introduced.
- The closing transaction remains post-stage probe, final source-revision guard, exactly one `Budget::charge`, and immediate `Ok(path)`.

## Verification

- `moon test modules/mb-core/math --target native` — 91 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*CFF outline exact path charge*"` — 4 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*CFF outline atomic*"` — 4 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*Phase 106 standalone CFF1*"` — 4 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "Phase 105 preserves the public standalone static glyf fingerprint"` — 1 passed, 0 failed.
- `moon test --target native` — 1269 passed, 0 failed.
- `moon check --target all` — passed with 0 errors on every configured target.
- The all-target check retains 37 non-fatal pre-existing unused/deprecated-debug warnings; no verification was skipped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Normalized SDK-generated Phase 106 state continuity**
- **Found during:** Final state advancement.
- **Issue:** The state SDK advanced to Plan 3 and recorded metrics/decisions, but retained the Plan 01 activity description, Plan 02 next-step prose, and the prior ten-plan milestone count.
- **Fix:** Synchronized last activity, operator next step, and completed-plan prose with the completed 106-02 summary and roadmap position.
- **Files modified:** `.planning/STATE.md`
- **Verification:** State reports Plan 3 of 3, 92% progress, eleven completed plans, and Plan 106-03 as the next action.
- **Committed in:** final metadata commit

---

**Total deviations:** 1 auto-fixed blocking metadata issue.
**Impact on plan:** Execution state now matches the committed summary and roadmap; production scope and public APIs were unchanged.

## Issues Encountered

- Task 1 RED isolated the missing private pre-execution probe entry.
- Task 2 RED showed that the first probe placement occurred after fixed preflight, allowing Resource to outrank restored mutation and exposing an internal VM revision context. Moving the authorized probe before preflight and guarding immediately corrected the planned State-first contract.
- A package-wide formatter invocation touched unrelated font files during RED preparation. Every unintended formatting edit was explicitly restored before the RED commit; no unrelated file entered any plan commit.

## Known Stubs

None. The pre-existing fixture variable `placeholder_top` computes same-size
CFF offsets before writing the final Top DICT; it is not an unwired production
value or deferred behavior.

## Threat Flags

None. The plan adds no network endpoint, authentication path, filesystem access, schema boundary, FFI, ambient I/O, public CFF API, or post-commit callback surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The standalone selected-glyph transaction now has exhaustive capacity, resource, repetition, mutation, multi-fault, and receiving-font GID evidence.
- Plan 106-03 can route selected TTC/OTC CFF1 faces through the same transaction without reopening outline resource or mutation semantics.
- Existing standalone static-glyf behavior and the exact glyf fingerprint remain green.

## Self-Check: PASSED

- All five implementation/evidence files and this summary exist.
- RED `f1a5db94`/`773ca318` and GREEN `0666eebf`/`3f851047` commits exist in repository history.
- Final native focused, full native, glyf compatibility, and all-target checks passed before state advancement.

---
*Phase: 106-cubic-path-and-public-ttc-integration*
*Completed: 2026-07-29*
