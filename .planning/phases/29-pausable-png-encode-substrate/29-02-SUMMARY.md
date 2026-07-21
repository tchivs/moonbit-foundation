---
phase: 29-pausable-png-encode-substrate
plan: "02"
subsystem: png-encode
tags: [moonbit, png, stored-deflate, writer, policy]

requires:
  - phase: 29-pausable-png-encode-substrate
    provides: Private PngEncodeMachine with atomic preflight and byte presentation/acknowledgement
provides:
  - Eager PngEncoder drains the private canonical machine through one-byte complete writes
  - Writer failures preserve the completed write-helper error and leave the pending byte unacknowledged
  - PNG source and test inventory is registered in policy and the isolated quality lane
affects: [30-public-png-chunk-encoder, 31-portable-png-streaming-evidence]

tech-stack:
  added: []
  patterns: [one-byte writer adapter, acknowledge-after-complete-write, exact private-source inventory]

key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1

key-decisions:
  - "Return the complete-write helper error unchanged so its typed fields remain observable at the eager facade boundary."
  - "Remove the obsolete eager PNG assembly helpers so PngEncodeMachine is the sole canonical emitter."

patterns-established:
  - "Eager adapters construct their private machine before Writer access, present one byte, complete one write, then acknowledge that byte."

requirements-completed: [PNGE-01]

coverage:
  - id: D1
    description: "PngEncoder preserves canonical RGB/RGBA output and drains the private machine with byte-sized complete-write calls."
    requirement: PNGE-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
      - kind: other
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png"
        status: pass
    human_judgment: false
  - id: D2
    description: "Writer failure at canonical offset 43 retains the accepted prefix and leaves the private byte pending."
    requirement: PNGE-01
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG encoder preserves complete-write failure and acknowledges only accepted bytes"
        status: pass
    human_judgment: false

duration: 11min
completed: 2026-07-21
status: complete
---

# Phase 29 Plan 02: Eager PNG Machine Adapter Summary

**PngEncoder now drains the single private canonical PNG machine through fixed one-byte complete writes with acknowledgement only after success.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-21T13:17:16Z
- **Completed:** 2026-07-21T13:27:58Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Added RED/green regression coverage for exact one-byte Writer calls, accepted-prefix accounting, private pending-byte retention, and eager/private byte parity.
- Removed the dormant eager scanline, DEFLATE, and PNG assembly path; the unchanged public facade now uses only `PngEncodeMachine`.
- Registered `stream_encode.mbt` and its tests in the exact PNG policy and quality inventories while retaining the generated public interface.

## Task Commits

1. **Task 1: Add black-box eager-machine parity and atomic Writer-adapter tests** — `797fb31` (test)
2. **Task 2: Drain the private machine through PngEncoder and register private-source policy** — `ac28be7` (feat)

## Files Created/Modified

- `modules/mb-image/png/encode.mbt` — one-byte eager adapter over the private machine, with no competing full-output assembler.
- `modules/mb-image/png/encode_test.mbt` — Writer failure, prefix, and one-byte call regressions.
- `modules/mb-image/png/encode_wbtest.mbt` — eager/private canonical drain parity.
- `modules/mb-image/png/stream_encode_wbtest.mbt` — unacknowledged-byte retention at the Writer boundary.
- `policy/foundation.json` — private encode production-source registration.
- `scripts/quality/Assert-Policy.ps1` — PNG source, directory, and prospective public-stream negative checks.
- `scripts/quality/Invoke-MoonQuality.ps1` — PNG lane package allowlist registration.

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f '*PNG encoder*'` — 5/5 passed.
- PNG structural vectors — 89 P+W cases passed.
- PNG decode vectors — 3,850 executable cases passed.
- `moon -C modules/mb-image test png --target all --frozen` — 91/91 passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed, including policy/interface, negative-fixture, allowlist, vector, workflow, and four-target checks.

## Decisions Made

- Return the `@io.write_all` error unchanged instead of synthesizing a PNG-specific error, preserving the completed write operation's typed fields.
- Keep the adapter's transient owned view fixed at one byte, so every successful complete write maps to exactly one machine acknowledgement.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The RED test initially exposed test-only MoonBit typing errors; correcting the mutable-array declaration and BytesView comparison produced the intended failure before implementation. No production deviation was required.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 30 can expose its caller-buffered encoder over the same private byte presentation/acknowledgement contract without altering eager output or public PNG declarations.

## Self-Check: PASSED

---
*Phase: 29-pausable-png-encode-substrate*
*Completed: 2026-07-21*
