---
phase: 30-public-png-chunk-encoder
plan: "01"
subsystem: png-encode
tags: [moonbit, png, chunked-encode, caller-buffered, policy]
requires:
  - phase: 29-pausable-png-encode-substrate
    provides: Private canonical PngEncodeMachine with preflight and byte acknowledgement
provides:
  - Public PngChunkEncoder caller-buffered pull contract
  - Exact per-call and cumulative output progress with sticky terminals
  - Fail-closed PNG semantic-interface policy for chunk encoding
affects: [31-portable-png-encode-evidence]
tech-stack:
  added: []
  patterns: [present-set-acknowledge byte transfer, caller-scoped output leases, sticky typed terminal outcomes]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
key-decisions:
  - "PngChunkEncoder is a thin lifecycle wrapper over one PngEncodeMachine and never retains a caller output lease or output-sized buffer."
  - "A byte is counted only after destination.set and machine.acknowledge both succeed; final acknowledgement makes Finished sticky."
requirements-completed: [PNGE-02, PNGE-03]
coverage:
  - id: D1
    description: "Public PngChunkEncoder drains canonical RGB8 and straight-RGBA8 eager-equivalent bytes through empty, one-byte, and irregular caller leases with exact progress."
    requirement: PNGE-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk encoder*'"
        status: pass
    human_judgment: false
  - id: D2
    description: "PngChunkEncoder preserves caller-output ownership and repeats Finished or the original typed lease failure without further writes."
    requirement: PNGE-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG chunk encoder retains no completed caller output lease"
        status: pass
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG chunk encoder replays the original released-lease failure"
        status: pass
    human_judgment: false
  - id: D3
    description: "PNG policy exactly permits the approved chunk-encoder API and rejects missing or obsolete stream declarations."
    requirement: PNGE-03
    verification:
      - kind: integration
        ref: "Assert-PngFoundationPolicy and Assert-PngQualificationNegativeFixtures"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-07-21
status: complete
---

# Phase 30 Plan 01: Public PNG Chunk Encoder Summary

**Public caller-buffered PNG encoding now drains the private canonical byte machine with exact progress, eager-byte parity, lease isolation, and sticky terminal outcomes.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-21T14:10:55Z
- **Completed:** 2026-07-21T14:16:39Z
- **Tasks:** 3/3
- **Files modified:** 6

## Accomplishments

- Added the public `PngChunkEncoder`, `PngChunkPullOutcome`, and `PngChunkPullResult` contract.
- Routed each accepted caller-lease byte through the sole `PngEncodeMachine` using present → set → acknowledge ordering.
- Locked the generated PNG public surface and fail-closed negative policy fixtures.

## Task Commits

1. **Task 1: Freeze the public PNG pull contract** — `6a0aab9` (test)
2. **Task 2: Implement the thin sticky public adapter** — `a8bfacc` (feat)
3. **Task 3: Register and verify the public surface** — `896c06c` (chore)

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk encoder*'` — 5/5 passed.
- `moon -C modules/mb-image test png --target native --frozen` — 97/97 passed.
- `moon -C modules/mb-image info --target all --frozen` — passed.
- `Assert-PngFoundationPolicy -PolicyPath policy/foundation.json` — passed.
- `Assert-PngQualificationNegativeFixtures -PolicyPath policy/foundation.json` — passed.

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — public encoder and pull-result declarations.
- `modules/mb-image/png/stream_encode.mbt` — private lifecycle and byte-transfer adapter.
- `modules/mb-image/png/stream_encode_test.mbt` — public progress, parity, ownership, and terminal regressions.
- `modules/mb-image/png/stream_encode_wbtest.mbt` — private acknowledgement accounting regression.
- `policy/foundation.json` — generated semantic interface sequence.
- `scripts/quality/Assert-Policy.ps1` — required and negative PNG stream-surface checks.

## Decisions Made

- The durable encoder state holds only the private machine, terminal discriminator, and scalar total; it never retains a caller lease, view, owner, or output buffer.
- Terminal success and failure branches return zero new bytes without reading or writing a supplied destination.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - no plan-blocking stubs were introduced.

## Issues Encountered

None.

## Next Phase Readiness

Phase 31 can add the planned four-target hostile output schedules and public decode-process-encode workflow evidence against the frozen API.

## Self-Check: PASSED

- All six planned implementation and policy files exist and their three task commits are present in history.
- The focused and complete native PNG suites, generated-interface comparison, and PNG policy negatives pass.

---
*Phase: 30-public-png-chunk-encoder*
*Completed: 2026-07-21*
