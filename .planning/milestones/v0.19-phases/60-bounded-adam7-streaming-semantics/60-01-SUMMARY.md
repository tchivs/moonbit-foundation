---
phase: 60-bounded-adam7-streaming-semantics
plan: "01"
subsystem: png-streaming
tags: [moonbit, png, adam7, replay-integrity, bounded-streaming]
requires:
  - phase: 59-grayalpha8-adam7-factory-and-pass-profile
    provides: GrayAlpha8 Adam7 profile-aware eager and chunk factory selectors
provides:
  - Profile-neutral pre-lease source-revision validation for PNG chunk replay
  - Six-case GrayAlpha8 Adam7 None/Adaptive and Stored/Fixed/Dynamic replay-drift matrix
  - Atomic GrayAlpha8 Adam7 admission regression coverage
affects: [61-grayalpha8-adam7-public-portable-proof, png-streaming]
tech-stack:
  added: []
  patterns: [validate admitted source revisions before caller-owned lease writes]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Revision validation is profile-neutral at the sole Active pull seam and retains plan-specific diagnostics."
  - "GrayAlpha8 Adam7 replay tests assert measured BTYPE values before post-prefix mutation."
patterns-established:
  - "Replay drift: validate before destination.set, transition to sticky failure, and preserve accepted-only totals."
requirements-completed: [GRAYA8A7-02]
coverage:
  - id: D1
    description: Profile-neutral pre-lease PNG replay revision guard
    requirement: GRAYA8A7-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: Six measured GrayAlpha8 Adam7 strategy-pair replay mutation cases and atomic admission matrix
    requirement: GRAYA8A7-02
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 Adam7 replay mutations are sticky for every strategy pair"
        status: pass
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 Adam7 strategy admission is atomic"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-07-23
status: complete
---

# Phase 60 Plan 01: Bounded Adam7 Streaming Semantics Summary

**GrayAlpha8 Adam7 replay now rejects any admitted-source mutation before the next caller lease write across all measured compression and filter selections.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-23T11:21:29+08:00
- **Completed:** 2026-07-23T11:34:15Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Generalized the existing U16-only replay revision guard at `PngChunkEncoder::pull` without changing Stored, Fixed, or Dynamic diagnostic identities.
- Added the all-seven-pass measured GrayAlpha8 Adam7 corpus: Stored ramp, Fixed flat, and Dynamic periodic fixtures under None and Adaptive filtering.
- Proved zero first/later lease writes, accepted-only progress, untouched sentinel tails, and sticky plan-specific errors after post-prefix mutation.
- Extended GrayAlpha8 atomic-admission coverage through the public all-strategy selectors for both retained None and Adam7 routes.

## Task Commits

1. **Task 1 RED: GrayAlpha8 Stored/None replay tracer** — `433ed9d` (`test`)
2. **Task 1 GREEN: profile-neutral pre-lease revision guard** — `5ce203d` (`feat`)
3. **Task 2: six-pair replay and admission matrix** — `700f4d2` (`test`)
4. **Regression alignment: legacy fixed replay assertion** — `113f34d` (`test`)
5. **Regression alignment: legacy adaptive replay assertions** — `b08a44f` (`test`)

## Files Created/Modified

- `modules/mb-image/png/stream_encode.mbt` — invokes `validate_replay_revision` before any active caller-lease write.
- `modules/mb-image/png/stream_encode_test.mbt` — measured GrayAlpha8 Adam7 mutation/admission matrix and updated legacy pre-lease expectations.

## Decisions Made

- Keep the single profile-aware encoder, Adam7 traversal, filter contexts, preflight ledger, and selected replay plans unchanged.
- Use captured/current mutation revision equality as the common admission-to-pull integrity seam; the selected plan determines the existing error context.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Regression] Updated legacy non-U16 replay expectations for the new common guard.**
- **Found during:** Full native PNG regression run after Task 2.
- **Issue:** Legacy Fixed and Adaptive tests expected replay to emit post-mutation bytes before their older replay-work failure.
- **Fix:** Moved their mutations after the acknowledged 44-byte prefix and asserted immediate zero-write sticky `*-replay-drift` results.
- **Files modified:** `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** `moon -C modules/mb-image test png --target native --frozen` (225 passed).
- **Committed in:** `113f34d`, `b08a44f`

**Total deviations:** 1 auto-fixed issue.
**Impact on plan:** Required to keep existing shared-pipeline coverage consistent with the intended profile-neutral pre-lease behavior; no scope expansion.

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 replay mutations are sticky for every strategy pair'` — passed (1/1)
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 strategy admission is atomic'` — passed (1/1)
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 chunk all strategy parity'` — passed (1/1)
- `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 strategy admission is atomic'` — passed (1/1)
- `moon -C modules/mb-image test png --target native --frozen` — passed (225/225)

## Known Stubs

None.

## Next Phase Readiness

Phase 61 can add its public portable wire/decode proof on top of a single bounded GrayAlpha8 Adam7 replay path with mutation rejection already verified.

## Self-Check: PASSED

- Required source and test files exist.
- All five implementation commits exist.

