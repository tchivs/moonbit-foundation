---
phase: 57-bounded-adam7-streaming-semantics
plan: "02"
subsystem: png-encoding
tags: [moonbit, png, grayalpha16, adam7, bounded-encoding, atomicity, replay]
requires:
  - phase: 57-01
    provides: GrayAlpha16 Adam7 all-strategy traversal and bounded profile evidence
provides:
  - Atomic GrayAlpha16 Adam7 strategy admission across all six legal selector pairs
  - Pre-write sticky U16 replay-drift rejection for Stored, Fixed, and Dynamic plans
affects: [58-grayalpha16-adam7-public-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [profile-aware preflight, caller-owned lease sentinel, revision guard, sticky terminal]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "GrayAlpha16 Adam7 admission uses the existing profile-aware preflight transaction for every legal compression/filter pair."
  - "Stored U16 replay drift now fails through the same pre-write PngEncodeMachine guard as Fixed and Dynamic plans."
metrics:
  tasks_completed: 2
  files_modified: 2
completed: 2026-07-23
status: complete
---

# Phase 57 Plan 02: Bounded Adam7 Streaming Semantics Summary

GrayAlpha16 Adam7 now rejects all bounded construction failures atomically and rejects checked U16 replay mutations before every Stored, Fixed, or Dynamic caller lease write.

## Accomplishments

- Parameterized the existing GrayAlpha16 public rejection helper by interlace selector, retaining frozen non-interlaced coverage and adding Adam7 coverage for all None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored pairs.
- Asserted incompatible capability, geometry, output, work, and budget failures leave the eager writer, budget ledger, and chunk sentinel lease untouched while eager and chunk errors agree.
- Extended the public U16 replay helper with the Adam7 selector and tested all six legal strategy pairs after an acknowledged framing prefix and alpha-lane mutation.
- Corrected the shared Stored `PngEncodeMachine::validate_u16_replay_revision()` branch to return `png-encode-stored-replay-drift` before `PngChunkEncoder::pull()` can write its caller lease.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 strategy admission is atomic'` | PASS — 1 test |
| `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha16 Adam7 replay mutations are sticky for every strategy pair'` before Stored fix | RED — native test executable exited `0xc0000409` because the Stored replay route remained writable after mutation |
| Same replay command after Stored fix | PASS — 1 test |
| `moon -C modules/mb-image test png --target native --frozen` | FAILED — existing native `png.whitebox_test.exe` exited `0xc0000409`; focused Plan 57 regressions pass |
| `git diff --check` | PASS |

## Task Commits

1. `23a658a` — `test(57-02): cover Adam7 admission atomicity`
2. `5e192b6` — `test(57-02): add Adam7 replay drift coverage`
3. `8387b8d` — `fix(57-02): reject stored U16 replay drift`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stored replay drift bypassed the U16 pre-write guard**
- **Found during:** Task 2 RED replay regression.
- **Issue:** `PngDeflatePlan::Stored` returned success after an admitted U16 source changed, allowing `pull` to proceed toward a caller-owned lease.
- **Fix:** Returned the plan-specific `png-encode-stored-replay-drift` machine-state error from the existing shared revision guard.
- **Files modified:** `modules/mb-image/png/stream_encode.mbt`
- **Commit:** `8387b8d`

### Verification Limitation

- The full native PNG suite reached the known `0xc0000409` failure in `png.whitebox_test.exe`. This execution did not alter white-box infrastructure; both plan-specific public regressions pass.

## Known Stubs

None.

## Self-Check: PASSED

- Both modified PNG source/test files exist.
- Task commits `23a658a`, `5e192b6`, and `8387b8d` exist in repository history.
