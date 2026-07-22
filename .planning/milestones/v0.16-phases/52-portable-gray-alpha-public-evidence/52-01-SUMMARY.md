---
phase: 52-portable-gray-alpha-public-evidence
plan: "01"
subsystem: png-public-evidence
tags: [moonbit, png, grayscale-alpha, portable, streaming, compatibility]
requires:
  - phase: 51-bounded-gray-alpha-png-encoding
    provides: explicit bounded eager and caller-buffered GrayAlpha8 PNG factories
provides:
  - Public GrayAlpha8 type-4 wire and RGBA8 decode evidence
  - Six-pair hostile caller-buffered GrayAlpha8 schedule coverage
  - Frozen Gray8, Gray16, RGB8, and straight-RGBA8 compatibility vectors
affects: [png-encoding, portable-conformance, grayscale-alpha]
tech-stack:
  added: []
  patterns: [literal public PNG compatibility vectors, accepted-prefix caller lease assertions]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Kept exact GrayAlpha8 wire and decoded-pixel assertions at public encoder and decoder seams."
  - "Used fresh chunk encoders for each hostile schedule so every strategy/filter pair has an independent eager oracle."
patterns-established:
  - "Portable PNG contract tests freeze literal Stored outputs instead of deriving expected bytes from a second encoder."
  - "Caller-buffered public evidence checks accepted output, untouched lease tails, and sticky terminals together."
requirements-completed: [GRAYA-04, GRAYA-05]
coverage:
  - id: D1
    description: Public GrayAlpha8 Stored/None type-4 scanline ordering and straight-RGBA8 decoder canonicalization.
    requirement: GRAYA-04
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG GrayAlpha8 public eager evidence
        status: pass
    human_judgment: false
  - id: D2
    description: All six GrayAlpha8 strategy/filter pairs retain eager identity and caller lease ownership under zero, one-byte, and ragged schedules.
    requirement: GRAYA-05
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 chunk public evidence
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-07-23
status: complete
---

# Phase 52 Plan 01: Portable Gray+Alpha Public Evidence Summary

**Public GrayAlpha8 PNG evidence now freezes the type-4 `(13,A7)/(D2,4C)` wire contract, RGBA8 decode canonicalization, hostile chunk ownership, and four-target portability.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-22T19:06:55Z
- **Completed:** 2026-07-22T19:20:38Z
- **Tasks:** 2/2
- **Files modified:** 2
- **Verification:** `moon -C modules/mb-image test png --target all --frozen` — 196 passed, 0 failed on wasm, wasm-gc, js, and native.

## Accomplishments

- Proved public Stored/None GrayAlpha8 type-4 framing and literal scanline bytes `00 13 A7 D2 4C`, then decoded through the public decoder to straight RGBA8 `(13,13,13,A7)` and `(D2,D2,D2,4C)`.
- Exercised all six compression/filter pairs with fresh caller-buffered encoders under zero-capacity, one-byte, and deterministic ragged schedules; each asserts accepted-only progress, untouched lease tails, eager parity, and sticky `Finished`.
- Preserved literal Gray8, Gray16, RGB8, and straight-RGBA8 eager and chunk compatibility vectors without changing production code.

## Task Commits

1. **Task 1: Prove one public GrayAlpha8 Stored/None wire-to-decode path and freeze eager vectors** — `a7aa1cf` (`test`)
2. **Task 2: Prove hostile public GrayAlpha8 chunk schedules, frozen chunk vectors, and all-target portability** — `11794ab` (`test`)

## Files Created/Modified

- `modules/mb-image/png/encode_test.mbt` — public GrayAlpha8 wire/decode assertions, six-pair decoding coverage, and a literal Gray16 eager baseline.
- `modules/mb-image/png/stream_encode_test.mbt` — hostile GrayAlpha8 public drain helper/matrix and a literal Gray16 chunk baseline.

## Decisions Made

- Kept every new assertion on the public `PngEncoder`, `PngChunkEncoder`, and `ImageDecoder` seams; expected data remains literal.
- Reused the established Gray16 drain shape because it directly enforces caller-owned lease and terminal semantics required by this phase.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The foreground all-target command exceeded the environment's 124-second tool limit. The same command was rerun through a hidden captured process and completed successfully with exit code 0.

## Known Stubs

None.

## Self-Check: PASSED

- Both planned test files and commits `a7aa1cf` and `11794ab` exist.
- The required four-target package suite passed 196/196 on every target.

## Next Phase Readiness

- GRAYA-04 and GRAYA-05 now have portable, public regression evidence with no production, release, fixture, or platform-specific changes.

---
*Phase: 52-portable-gray-alpha-public-evidence*
*Plan: 01*
*Completed: 2026-07-23*
