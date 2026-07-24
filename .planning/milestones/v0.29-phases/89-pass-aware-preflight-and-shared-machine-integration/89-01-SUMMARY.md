---
phase: 89-pass-aware-preflight-and-shared-machine-integration
plan: "01"
subsystem: png
tags: [moonbit, png, indexed-color, adam7, preflight, budget, streaming]
requires:
  - phase: 88-indexed-adam7-api-and-fixed-wire-contract
    provides: additive Indexed1/2/4/8 Adam7 Stored/FixedOrStored selectors
provides:
  - All-profile Adam7 candidate-frame and atomic-admission regression proof
  - Shared acknowledged-machine preview/acknowledgement proof for eager/chunk seams
affects: [90-hostile-streaming-and-independent-qualification]
tech-stack:
  added: []
  patterns:
    - "White-box preflight tests compare retained plan facts to the selected Type-3 frame"
    - "Exact and one-less limit/budget cases assert unchanged remaining resources"
key-files:
  created:
    - .planning/phases/89-pass-aware-preflight-and-shared-machine-integration/89-CONTEXT.md
    - .planning/phases/89-pass-aware-preflight-and-shared-machine-integration/89-RESEARCH.md
    - .planning/phases/89-pass-aware-preflight-and-shared-machine-integration/89-01-PLAN.md
    - .planning/phases/89-pass-aware-preflight-and-shared-machine-integration/89-01-SUMMARY.md
  modified:
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
key-decisions:
  - "Phase 89 validates the existing production seam before changing it; no production change was needed because candidate and charge behavior already matched the contract."
  - "Use an independent odd 5x5 fixture with a two-entry palette across all four wire profiles; hostile lease schedules remain Phase 90."
patterns-established:
  - "Candidate facts are checked from the retained plan rather than reconstructed output bytes."
requirements-completed: [ADAM7COMP-02, ADAM7COMP-03]
coverage:
  - id: D1
    description: "Indexed1/2/4/8 Adam7 FixedOrStored preflight retains a plan whose frame equals the selected candidate."
    requirement: ADAM7COMP-02
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_wbtest.mbt#PNG indexed Adam7 FixedOrStored candidate facts and admission are exact"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact and one-less output/work limits and budgets are admitted or rejected atomically."
    requirement: ADAM7COMP-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_wbtest.mbt#PNG indexed Adam7 FixedOrStored candidate facts and admission are exact"
        status: pass
    human_judgment: false
  - id: D3
    description: "All four Adam7 chunk selector routes use the acknowledged machine and keep preview stable until acknowledgement."
    requirement: ADAM7COMP-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_wbtest.mbt#PNG indexed Adam7 FixedOrStored chunk uses shared acknowledged machine"
        status: pass
    human_judgment: false
  - id: D4
    description: "The complete PNG package remains green on all declared targets."
    verification:
      - kind: other
        ref: "moon test modules/mb-image/png --target all"
        status: pass
    human_judgment: false
metrics:
  duration: "~35 min"
  completed: 2026-07-24
  status: complete
---

# Phase 89: Pass-Aware Preflight and Shared-Machine Integration Summary

**Adam7 Indexed1/2/4/8 now have all-profile evidence that candidate frame facts, exact admission, and acknowledged replay remain on one bounded machine seam.**

## Accomplishments

- Added an independent 5x5 all-profile white-box matrix for FixedOrStored Adam7 preflight.
- Verified retained PLTE/tRNS-aware frame totals against the selected Stored or Fixed candidate.
- Verified exact and one-less output/work limits and budget work, including unchanged resource state on rejection.
- Verified all four chunk selector routes preview stably until acknowledgement through the shared machine.

## Task Commits

Pending the atomic implementation/docs commit recorded below by the GSD commit step.

## Files Created/Modified

- `modules/mb-image/png/encode_wbtest.mbt` - All-profile candidate facts and atomic admission tests.
- `modules/mb-image/png/stream_encode_wbtest.mbt` - Shared acknowledged-machine regression test.
- `.planning/phases/89-pass-aware-preflight-and-shared-machine-integration/` - Context, research, plan, and summary artifacts.

## Deviations from Plan

No production code change was required: focused tests confirmed the Phase 88 seam already computes the exact Phase 89 contract. The work stayed in tests and GSD artifacts.

## Verification

- `moon check modules/mb-image/png --target all` passed (warnings only).
- `moon test modules/mb-image/png --target all` passed: **318/318** on native, wasm, wasm-gc, and js.
- `git diff --check` passed.

## Next Phase Readiness

Phase 90 can focus exclusively on hostile leases, sticky replay/failure terminals, independent wire/decode qualification, frozen compatibility vectors, and the final four-target package gate.

---
*Phase: 89-pass-aware-preflight-and-shared-machine-integration*
*Completed: 2026-07-24*
