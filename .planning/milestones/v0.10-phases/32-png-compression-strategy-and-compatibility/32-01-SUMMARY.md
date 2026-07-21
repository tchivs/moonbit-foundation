---
phase: 32-png-compression-strategy-and-compatibility
plan: "01"
subsystem: png-encoding
tags: [moonbit, png, deflate, compression-strategy, compatibility]
requires:
  - phase: 29-pausable-png-encode-substrate
    provides: Shared private PNG encode machine and caller-buffered encoder contract.
  - phase: 31-portable-png-encode-evidence
    provides: Four-target eager/chunk PNG encode evidence and stored-byte baseline.
provides:
  - Public Stored and FixedOrStored PNG compression strategy selection.
  - Additive configured eager and caller-buffered PNG factories.
  - Independent frozen stored-byte regressions for legacy eager and chunk constructors.
affects: [phase-33-png-fixed-or-stored-emission, phase-34-png-compression-evidence]
tech-stack:
  added: []
  patterns: [Explicit legacy constructor selection, strategy retained in private encode state]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - policy/foundation.json
key-decisions:
  - "FixedOrStored deliberately uses the stored emitter in Phase 32 and makes no size claim."
  - "Legacy eager and chunk constructors explicitly select Stored and remain independently byte-locked."
patterns-established:
  - "Future compression strategies enter the existing PngEncodeMachine without bypassing preflight, acknowledgement, or terminal handling."
requirements-completed: [PNGC-01]
coverage:
  - id: D1
    description: Public PNG compression strategy and eager/chunk configured factories.
    requirement: PNGC-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen -f '*PNG compression strategy*'"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png"
        status: pass
    human_judgment: false
  - id: D2
    description: Legacy eager and caller-buffered stored-DEFLATE byte compatibility.
    requirement: PNGC-01
    verification:
      - kind: unit
        ref: "modules/mb-image/png/{encode_test,stream_encode_test}.mbt#PNG compression strategy legacy constructors retain frozen stored bytes"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-image test png --target js|wasm|wasm-gc|native --frozen"
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-07-21
status: complete
---

# Phase 32 Plan 01: PNG Compression Strategy and Compatibility Summary

**Additive PNG Stored/FixedOrStored selection factories with independently frozen legacy stored-DEFLATE eager and chunk output.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-07-21T17:27:21Z
- **Completed:** 2026-07-21T17:43:07Z
- **Tasks:** 3/3
- **Files modified:** 6

## Accomplishments

- Published equality-comparable `PngCompressionStrategy::{Stored, FixedOrStored}` and documented the Phase 32 stored-baseline boundary.
- Added eager and caller-buffered configured factories while retaining the selected strategy in the authoritative private encode route.
- Locked legacy eager and chunk RGB8/RGBA8 outputs to complete stored-DEFLATE byte vectors and registered the exact generated public interface.

## Task Commits

1. **Task 1: Write failing public-contract and independent legacy-byte tests** — `2db65e7` (`test`)
2. **Task 2: Implement strategy-aware construction without changing stored emission** — `84510ec` (`feat`)
3. **Task 3: Register the exact additive interface and run portable compatibility gates** — `35b71c8` (`chore`)

No refactor commit was necessary.

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — public strategy enum and eager configured factory.
- `modules/mb-image/png/encode.mbt` — passes eager strategy selection into the shared machine.
- `modules/mb-image/png/stream_encode.mbt` — configured chunk factory and retained private strategy state.
- `modules/mb-image/png/encode_test.mbt` — configured eager construction and frozen legacy byte tests.
- `modules/mb-image/png/stream_encode_test.mbt` — configured chunk construction, irregular drain helper, and frozen legacy bytes.
- `policy/foundation.json` — exact normalized public PNG interface registration.

## Decisions Made

- `FixedOrStored` remains a stored-emission alias with no optimization or size guarantee until Phase 33.
- Legacy constructors choose `Stored` explicitly, keeping their compatibility independent of future configured behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Preserved private white-box constructor compatibility**
- **Found during:** Task 2
- **Issue:** Changing the existing private `PngEncodeMachine::new` signature broke package white-box tests outside the plan-owned files.
- **Fix:** Kept `new` as an explicit `Stored` wrapper and added a private strategy-aware constructor used by configured eager/chunk paths.
- **Files modified:** `modules/mb-image/png/stream_encode.mbt`
- **Verification:** Focused GREEN selector and complete native PNG suite pass.
- **Committed in:** `84510ec`

**Total deviations:** 1 auto-fixed (Rule 3 blocking issue).

## Known Stubs

None — empty arrays in the touched tests are intentional byte accumulators, not user-facing placeholder data.

## Issues Encountered

None beyond the compatibility-preserving constructor wrapper documented above.

## User Setup Required

None — no external services or configuration are required.

## Next Phase Readiness

Phase 33 can replace only the `FixedOrStored` private branch with bounded fixed-or-stored planning/emission without changing the public API or legacy stored constructors.

## Verification

- RED: focused native selector failed for the absent public enum/factories before implementation.
- GREEN: focused selector passed 4/4; full native PNG package suite passed 102/102.
- Policy: `Invoke-MoonQuality.ps1 -Lane Png` passed, including interface and all-target PNG evidence.
- Portable: explicit js, wasm, wasm-gc, and native package tests each passed 102/102.

## Self-Check: PASSED

- All six plan-owned implementation/policy files exist.
- Task commits `2db65e7`, `84510ec`, and `35b71c8` exist in git history.

