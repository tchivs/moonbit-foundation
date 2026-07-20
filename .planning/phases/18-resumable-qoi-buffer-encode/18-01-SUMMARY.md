---
phase: 18-resumable-qoi-buffer-encode
plan: "01"
subsystem: image-codec
tags: [moonbit, qoi, streaming, zero-copy, policy]
requires:
  - phase: 17-resumable-qoi-chunk-decode
    provides: caller-owned streaming codec result and terminal-state conventions
provides:
  - Resumable canonical QOI output through callback-scoped mutable byte leases
  - Shared bounded token generation for eager and stream QOI encoders
  - Exact QOI source/interface policy checks for the stream encoder
affects: [19-qoi-streaming-public-evidence]
tech-stack:
  added: []
  patterns: [bounded pending-token drain, constructor-only resource preflight]
key-files:
  created:
    - modules/mb-image/qoi/stream_encode.mbt
    - modules/mb-image/qoi/stream_encode_test.mbt
    - modules/mb-image/qoi/stream_encode_wbtest.mbt
  modified:
    - modules/mb-image/qoi/qoi.mbt
    - modules/mb-image/qoi/encode.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
key-decisions:
  - "QoiStreamEncoder retains only an immutable ImageView and one bounded pending token; mutable leases never escape pull."
  - "Canonical token selection is shared with eager Writer output so capacity schedules cannot choose different QOI opcodes."
patterns-established:
  - "Streaming encoders preflight and charge once during construction, then make copying the only pull-time operation."
requirements-completed: [QSTR-04, QSTR-05]
coverage:
  - id: D1
    description: Caller-owned zero, one-byte, and mixed-capacity leases drain canonical QOI bytes with exact per-call and cumulative progress.
    requirement: QSTR-04
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test qoi --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Constructor preflight validates limits and budget before output, with one work charge and sticky terminal state.
    requirement: QSTR-05
    verification:
      - kind: unit
        ref: modules/mb-image/qoi/stream_encode_wbtest.mbt
        status: pass
    human_judgment: false
  - id: D3
    description: Broad and scoped policy inventories include the generated QOI stream-encoder interface and all new source/test files.
    verification:
      - kind: integration
        ref: pwsh scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-07-20
status: complete
---

# Phase 18 Plan 01: Resumable QOI Buffer Encode Summary

**A zero-copy QOI stream encoder now drains eager-identical canonical bytes through arbitrary caller-owned mutable leases with constructor-only resource preflight.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-20T13:38:00Z
- **Completed:** 2026-07-20T13:48:28Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added public `QoiStreamEncoder`, exact-progress pull results, `NeedOutput`/`Finished`/typed-failure outcomes, and documented stable-source zero-copy lifetime rules.
- Shared canonical QOI opcode generation between eager Writer output and bounded stream pending tokens; zero-, one-, token-edge, and mixed capacities match generated eager vectors.
- Preserved eager-equivalent validation, exact length/limit order, metadata setup, and a single work charge before caller output is available.
- Extended generated-interface, broad/scoped source order, directory, and negative policy fixtures for all stream-encoder files and public types.

## Task Commits

1. **Task 1: Define the caller-lease stream encoder and shared canonical token state** — `dab5a81` (RED tests), `1c33986` (feature), `d8a90d4` (preflight atomicity fix)
2. **Task 2: Prove canonical capacity schedules and update exact QOI policy guards** — `0c0f0fb` (tests and policy)

## Files Created/Modified

- `modules/mb-image/qoi/qoi.mbt` — public stream encoder and pull-result contract.
- `modules/mb-image/qoi/encode.mbt` — shared bounded canonical opcode generator and construction preflight.
- `modules/mb-image/qoi/stream_encode.mbt` — mutable-lease pull drain with sticky terminal state.
- `modules/mb-image/qoi/stream_encode_test.mbt` — public preflight, progress, lease, and terminal tests.
- `modules/mb-image/qoi/stream_encode_wbtest.mbt` — generated-vector schedules, pending-token, and charge tests.
- `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` — exact QOI policy inventory and negatives.

## Decisions Made

- A stream stores no mutable lease; only the live lease receives copied pending bytes during one `pull` call.
- The last marker byte is the sole transition to `Finished`; subsequent pulls return zero bytes with the deterministic stream-terminal error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Preserved failed-constructor budget atomicity**
- **Found during:** Task 2 verification
- **Issue:** Metadata disposition construction followed the work charge, allowing a theoretical post-charge constructor failure.
- **Fix:** Constructed the disposition before resource preflight/charge.
- **Files modified:** `modules/mb-image/qoi/stream_encode.mbt`
- **Verification:** Four-target QOI test suite and QOI quality lane pass.
- **Committed in:** `d8a90d4`

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 19 can add public streaming evidence on the stable pull interface without changing eager QOI traits, Reader/Writer semantics, policy scope, or source ownership.

## Self-Check: PASSED

- Confirmed stream source and both stream test files exist.
- Confirmed task commits `dab5a81`, `1c33986`, `0c0f0fb`, and `d8a90d4` exist in repository history.
