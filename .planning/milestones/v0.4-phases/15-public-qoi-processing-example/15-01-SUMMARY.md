---
phase: 15-public-qoi-processing-example
plan: "01"
subsystem: image-codec
tags: [moonbit, qoi, portable, codec, image-processing]
requires:
  - phase: 14-canonical-qoi-encode-and-four-target-vectors
    provides: Public canonical QOI decoder and encoder values over the portable codec seam.
provides:
  - Independent in-memory QOI decode, horizontal-flip, and canonical-encode executable.
  - Four frozen target commands and deterministic output evidence for QOI consumers.
affects: [qoi, image-codecs, portable-interchange, public-examples]
tech-stack:
  added: []
  patterns: [public caller-owned codec boundaries, deterministic byte and digest evidence]
key-files:
  created:
    - examples/qoi-portable/moon.mod.json
    - examples/qoi-portable/main/moon.pkg
    - examples/qoi-portable/main/main.mbt
  modified:
    - moon.work
    - modules/mb-image/README.mbt.md
key-decisions:
  - "Use the fixed diff-byte-wrap QOI vector with explicit fresh budgets, limits, diagnostics, and memory I/O at each public boundary."
  - "Assert the flipped canonical QOI bytes, rolling digest, and computed SHA-256 before emitting the sole status line."
patterns-established:
  - "Portable examples prove public codec pipelines with exact byte evidence on js, wasm, wasm-gc, and native."
requirements-completed: [QOI-06]
coverage:
  - id: D1
    description: Public portable QOI decode, flip_horizontal, and canonical encode example with deterministic byte evidence.
    requirement: QOI-06
    verification:
      - kind: integration
        ref: moon -C examples/qoi-portable run main --target js|wasm|wasm-gc|native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Public README discovery entry with exact frozen commands for every supported target.
    requirement: QOI-06
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test --target all --frozen
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-07-20
status: complete
---

# Phase 15 Plan 01: Public QOI Processing Example Summary

**Independent portable QOI consumer proving fixed in-memory decode, horizontal pixel flip, and canonical re-encode on all four supported targets.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-20T11:39:14Z
- **Completed:** 2026-07-20T11:46:03Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added `examples/qoi-portable`, a standalone public module that decodes the fixed 27-byte QOI vector, calls `flip_horizontal`, and encodes the canonical 24-byte result entirely in memory.
- Asserted dimensions, transformed stored pixels, decode and encode progress, empty diagnostics, complete canonical bytes, rolling digest `750514177`, and a computed SHA-256 digest before the sole success line.
- Documented the portable QOI workflow and exact frozen `js`, `wasm`, `wasm-gc`, and `native` commands alongside the existing PPM and Native CLI examples.

## Task Commits

1. **Task 1: Build the independent deterministic QOI portable workflow** - `103192c` (feat)
2. **Task 2: Document the public QOI portable consumer and frozen target commands** - `6c05a21` (docs)
3. **Acceptance-gap correction: Verify canonical QOI SHA-256 evidence** - `714f0b5` (fix)

## Files Created/Modified

- `moon.work` - Registers the independent portable QOI example workspace member.
- `examples/qoi-portable/moon.mod.json` - Declares the portable public-consumer module and its registry dependencies.
- `examples/qoi-portable/main/moon.pkg` - Imports only public core, codec, operation, and QOI packages.
- `examples/qoi-portable/main/main.mbt` - Implements the deterministic in-memory public pipeline and evidence checks.
- `modules/mb-image/README.mbt.md` - Links the QOI example and records the four frozen target commands.

## Decisions Made

- Used the corrected flipped-output vector `716f696600000002000000010300655a0000000000000001`, rolling digest `750514177`, and SHA-256 `5dc3abfe81e722b211af255f6f96805225f98435f1f9525c46df48217f858df2`, matching the public QOI encoder's canonical output for `(0,255,255)` followed by `(255,255,255)`.
- Kept the consumer independent from registry selection, filesystem or CLI input, FFI, streaming, benchmarks, and codec implementation internals.

## Verification

- `moon -C examples/qoi-portable run main --target js --frozen` — passed.
- `moon -C examples/qoi-portable run main --target wasm --frozen` — passed.
- `moon -C examples/qoi-portable run main --target wasm-gc --frozen` — passed.
- `moon -C examples/qoi-portable run main --target native --frozen` — passed.
- `moon -C modules/mb-image test --target all --frozen` — passed: 235/235 on wasm, wasm-gc, js, and native.
- Independent SHA-256 calculation over the canonical 24 bytes — passed: `5dc3abfe81e722b211af255f6f96805225f98435f1f9525c46df48217f858df2`.

## Deviations from Plan

None - plan executed exactly as written after its accepted evidence correction.

## Known Stubs

None - the created and modified implementation files contain no placeholder or unwired data paths.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

QOI-06 now has a separately runnable, all-target public consumer with complete deterministic evidence.

## Self-Check: PASSED

All five implementation artifacts and this summary exist; Task 1 commit `103192c`, Task 2 commit `6c05a21`, and SHA correction commit `714f0b5` are present in the repository log.
