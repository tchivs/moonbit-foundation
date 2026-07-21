---
phase: 29-pausable-png-encode-substrate
plan: "03"
subsystem: png-encode
tags: [moonbit, png, writer, error-identity, portable-testing]

requires:
  - phase: 29-pausable-png-encode-substrate
    provides: Private canonical PNG emitter and one-byte eager adapter
provides:
  - Direct one-byte Writer adapter that preserves provider CoreError fields
  - Shared filtered writer-identity, pending-byte, and canonical-parity regressions
  - Target-isolated js, wasm, wasm-gc, and native evidence runner
affects: [30-public-png-chunk-encoder, 31-portable-png-streaming-evidence]

tech-stack:
  added: []
  patterns: [direct WriteOutcome handling, acknowledge-only-on-Progress-1, target-isolated evidence]

key-files:
  created: [scripts/quality/Invoke-PngEncodeEvidence.ps1]
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt

key-decisions:
  - "Use Writer.write directly for the eager one-byte staging view so a Failed outcome returns the provider CoreError unchanged."
  - "Acknowledge a private PNG byte only after WriteOutcome::Progress(1); all other progress values are adapter errors."
  - "Run four portable targets as independent, target-directory-isolated evidence commands instead of an aggregate target invocation."

patterns-established:
  - "A one-byte eager encoder can preserve host diagnostic identity by consuming its Writer outcome at the ownership boundary."
  - "Shared test filters can provide reproducible target-specific evidence when a combined qualification exceeds runtime limits."

requirements-completed: [PNGE-01]

coverage:
  - id: D1
    description: "PngEncoder preserves a one-byte Writer failure's Host category, HostOperationFailed code, operation, requested, completed, limit, and context while retaining the failed private byte."
    requirement: PNGE-01
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG encoder isolated four-target evidence preserves original Writer failure and accepted prefix"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target native"
        status: pass
    human_judgment: false
  - id: D2
    description: "Private pending-byte acknowledgement and eager/private canonical parity are proven independently on js, wasm, wasm-gc, and native."
    requirement: PNGE-01
    verification:
      - kind: integration
        ref: "scripts/quality/Invoke-PngEncodeEvidence.ps1 (js, wasm, wasm-gc, native)"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-21
status: complete
---

# Phase 29 Plan 03: Writer Error Identity Gap Closure Summary

**PngEncoder now returns host Writer failures field-for-field and proves its private canonical byte ownership on all four portable targets.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-21T13:34:00Z
- **Completed:** 2026-07-21T13:49:00Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Replaced the normalizing complete-write helper with direct one-byte `Writer.write` outcome handling, preserving embedded provider errors without acknowledging failed bytes.
- Added exact shared-filter evidence for original Writer-error identity, private pending-byte acknowledgement, and eager/private RGB8 and straight-RGBA8 canonical parity.
- Added a parameterized runner that isolates each portable target's build output and reports an attributable pass/fail result.

## Task Commits

1. **Task 1: Freeze direct Writer-error identity and isolated evidence behavior** — `8fbdf58` (test)
2. **Task 2: Use the supported direct Writer API and run one portable target per evidence invocation** — `aaebf0b` (feat)

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f '*PNG encoder isolated four-target evidence*'` — 3/3 passed.
- `moon -C modules/mb-image test png --target native --frozen -f '*PNG encoder rejects malformed direct one-byte Writer progress*'` — 1/1 passed.
- `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target js` — 3/3 passed.
- `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target wasm` — 3/3 passed.
- `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target wasm-gc` — 3/3 passed.
- `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target native` — 3/3 passed.
- `moon -C modules/mb-image test png --target native --frozen` — 92/92 passed.

## Files Created/Modified

- `modules/mb-image/png/encode.mbt` — direct one-byte Writer outcome adapter.
- `modules/mb-image/png/encode_test.mbt` — exact provider-error and malformed-progress regressions.
- `modules/mb-image/png/encode_wbtest.mbt` — shared-filter eager/private canonical parity test.
- `modules/mb-image/png/stream_encode_wbtest.mbt` — shared-filter pending-byte acknowledgement test.
- `scripts/quality/Invoke-PngEncodeEvidence.ps1` — one-target-at-a-time portable evidence runner.

## Decisions Made

- Preserve provider-originated `CoreError` values by returning the error embedded in `WriteOutcome::Failed` unchanged.
- Treat `Progress(1)` as the sole complete-write acknowledgement signal for the existing one-byte staging view.
- Keep runner invocations separate so each target has an isolated build directory and result record.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - no stub patterns were found in the Plan 03 files.

## Issues Encountered

The historical aggregate four-target PNG invocation had exceeded the verifier timeout; all replacement target-specific evidence commands completed successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The private/eager encoder boundary now preserves host diagnostics and byte acknowledgement ownership for Phase 30's public caller-buffered wrapper.

## Self-Check: PASSED

---
*Phase: 29-pausable-png-encode-substrate*
*Completed: 2026-07-21*
