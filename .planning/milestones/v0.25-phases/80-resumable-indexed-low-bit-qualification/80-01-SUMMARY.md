---
phase: 80-resumable-indexed-low-bit-qualification
plan: "01"
subsystem: png-stream-encoding
tags: [moonbit, png, indexed-colour, low-bit, caller-buffered, portability]
requires:
  - phase: 79-indexed-low-bit-eager-packing
    provides: Profile-aware Type-3 low-bit encode machine and eager selected-depth oracle
provides:
  - Selected-depth PngChunkEncoder::new_indexed adapter over the shared machine
  - Hostile caller-lease and atomic-admission qualification for Indexed1/2/4
affects: [png-encoding, indexed-png, portable-qualification]
tech-stack:
  added: []
  patterns: [Thin selector-bearing public adapters delegate to the shared acknowledged machine]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "new_indexed maps the finite public selector directly to PngIndexedWireProfile before constructing the existing machine."
  - "new_indexed8 remains the unchanged fixed-Eight compatibility route."
patterns-established:
  - "Selected indexed chunk parity uses the public eager encoder as its oracle while independent wire/decode vectors remain in encode_test.mbt."
requirements-completed: [INDEXLOW-04, INDEXLOW-05]
coverage:
  - id: D1
    description: "Selected Indexed2 caller-buffered output matches the public eager Type-3 encoder under zero and ragged leases."
    requirement: INDEXLOW-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG Indexed2 chunk tracer retains eager bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: "All selected Indexed1/2/4 paths retain hostile lease, sticky-terminal, and atomic-admission evidence on every target."
    requirement: INDEXLOW-04
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: unknown
    human_judgment: false
  - id: D3
    description: "Fixed Indexed8 compatibility and independent Type-3 wire/decode vectors continue through the ordinary package qualification."
    requirement: INDEXLOW-05
    verification:
      - kind: other
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: unknown
    human_judgment: false
duration: 15min
completed: 2026-07-23
status: complete
---

# Phase 80 Plan 01: Resumable Indexed Low-Bit Qualification Summary

**A thin `PngChunkEncoder::new_indexed` adapter now streams Type-3 Indexed1/2/4 through Phase 79's acknowledged machine, with hostile lease and admission qualification.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-23T21:36:51Z
- **Completed:** 2026-07-23T21:51:24Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added the public selected-depth caller-buffered factory, mapping One, Two, and Four directly to the pre-existing profile-aware machine.
- Preserved the `new_indexed8` fixed-Eight compatibility adapter and its existing lifecycle coverage.
- Added all-depth zero/one/ragged lease, accepted-progress, sentinel-tail, sticky success/failure, released-lease, and atomic output/pixel/work-budget tests.

## Task Commits

1. **Task 1: End-to-end Indexed2 caller lease through the shared low-bit machine** - `ed9a656` (test RED), `ea94d1f` (feat GREEN)
2. **Task 2: Qualify all selected depths, admission, compatibility, and portable independent evidence** - `5fe480a` (test)

## Files Created/Modified

- `modules/mb-image/png/stream_encode.mbt` - Adds the selector-bearing low-bit chunk factory over `new_with_indexed_profile`.
- `modules/mb-image/png/stream_encode_test.mbt` - Adds selected-depth eager parity, hostile leases, released-lease terminal, and admission qualification.

## Decisions Made

- Kept the public adapter deliberately thin: selector mapping plus the existing `Active(machine)` state initialization.
- Kept independent wire/CRC and decoder evidence in `encode_test.mbt`; new stream tests compare only with the public eager route.

## Deviations from Plan

None - implementation followed the planned single-machine, no-second-transport design.

## Verification

- PASS: RED gate failed as intended before the factory existed (`PngChunkEncoder has no method new_indexed`).
- PASS: `moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen --filter 'PNG Indexed2 chunk tracer retains eager bytes'` — 1 passed.
- PASS: tracer feedback gate, `moon -C modules/mb-image test png --target native --frozen` — 283 passed.
- NOT COMPLETED: `moon -C modules/mb-image test png --target all --frozen` was started with a dedicated worktree-owned target directory after shared-build contention. It remained in the wasm build stage without a test result through bounded polling, so the owned process and target directory were removed. This is not recorded as passing four-target evidence.

## Issues Encountered

- MoonBit's partial filter uses exact test names; the broad `PNG selected Indexed` filter compiled but executed zero tests. The plan's full package command remains the intended all-depth gate.
- Four-target evidence needs a later rerun when the MoonBit build environment is idle.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The additive API and qualification code are committed and ready for review.
- Re-run the ordinary frozen four-target PNG package command to close the portable verification evidence.

---
*Phase: 80-resumable-indexed-low-bit-qualification*
*Completed: 2026-07-23*

## Self-Check: PASSED

- Confirmed both modified PNG files and this summary exist.
- Confirmed commits `ed9a656`, `ea94d1f`, and `5fe480a` exist in git history.
