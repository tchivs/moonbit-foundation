---
phase: 14-canonical-qoi-encode-and-four-target-vectors
plan: "01"
subsystem: image-codec
tags: [moonbit, qoi, codec, encoder, portable, fixtures]
requires:
  - phase: 13-qoi-format-core-and-safe-decode
    provides: Pure-MoonBit QOI decoder, portable codec contracts, and checked fixture-generation pattern.
provides:
  - Canonical QOI 1.0 ImageEncoder for compatible packed RGB and straight-RGBA views.
  - Atomic encode resource preflight with exact writer progress reporting.
  - Checked source-to-canonical-byte vectors covering QOI opcode and boundary behavior.
affects: [qoi, image-codecs, portable-interchange, phase-15]
tech-stack:
  added: []
  patterns: [deterministic encode prepass, canonical QOI state transition, checked fixture generation]
key-files:
  created:
    - modules/mb-image/qoi/encode.mbt
    - modules/mb-image/qoi/encode_test.mbt
    - modules/mb-image/qoi/encode_wbtest.mbt
  modified:
    - modules/mb-image/qoi/qoi.mbt
    - fixtures/qoi/cases.json
    - scripts/fixtures/Generate-QoiVectors.ps1
    - modules/mb-image/qoi/generated_vectors.mbt
    - fixtures/manifest.json
key-decisions:
  - "QoiEncoder remains independent and implements only the established ImageEncoder seam."
  - "Canonical output is measured in a source prepass before one exact budget charge and any Writer output."
  - "Canonical encoder bytes originate in repository-owned JSON and are checked into target-neutral MoonBit vectors."
patterns-established:
  - "Normalize byte deltas with explicit signed-range adjustment; do not rely on negative remainder semantics."
requirements-completed: [QOI-03, QOI-05]
coverage:
  - id: D1
    description: Canonical QOI 1.0 encoding through the public ImageEncoder seam with compatible RGB and straight-RGBA views.
    requirement: QOI-03
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Specification-derived canonical byte, run-boundary, index, wraparound, and decode-round-trip vectors on all portable targets.
    requirement: QOI-05
    verification:
      - kind: unit
        ref: pwsh -NoProfile -File scripts/fixtures/Generate-QoiVectors.ps1 -Check; moon -C modules/mb-image test --target all --frozen
        status: pass
    human_judgment: false
duration: 45min
completed: 2026-07-20
status: complete
---

# Phase 14 Plan 01: Canonical QOI Encode and Four-Target Vectors Summary

**Pure-MoonBit canonical QOI 1.0 encoding with atomic resource preflight, exact forward-writer progress, and checked all-target byte vectors.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-07-20T10:38:00Z
- **Completed:** 2026-07-20T11:23:32Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added public `QoiEncoder` implementing the existing `@codec.ImageEncoder` seam for packed U8 RGB and straight-RGBA TopLeft built-in-sRGB views.
- Encodes a deterministic 14-byte QOI header, canonical RUN/INDEX/DIFF/LUMA/RGB/RGBA chunks, and the exact eight-byte marker after source validation, output prepass, one budget charge, and forward-only writing.
- Extended repository-owned QOI authority and generated MoonBit tables with canonical encode vectors that prove exact bytes, source recovery, headers, index behavior, byte wraparound, run boundaries, and Writer progress on js, wasm, wasm-gc, and native.

## Task Commits

1. **Task 1: Implement the canonical QOI encoder through the unchanged codec seam** - `055984f` (RED), `d254fe3` (implementation), `c883115` (public contract tests), `0674534` (wraparound correctness fix)
2. **Task 2: Extend checked QOI fixtures and prove canonical bytes on four targets** - `72a9460`

## Files Created/Modified

- `modules/mb-image/qoi/qoi.mbt` - Public `QoiEncoder` value next to the independent decoder.
- `modules/mb-image/qoi/encode.mbt` - Canonical QOI encoder, prepass, source validation, exact budget charge, and writer-progress remapping.
- `modules/mb-image/qoi/encode_test.mbt` - Public codec, resource, header, and I/O contract tests.
- `modules/mb-image/qoi/encode_wbtest.mbt` - Generated vector, dimension, byte, round-trip, and Writer-progress conformance tests.
- `fixtures/qoi/cases.json`, `scripts/fixtures/Generate-QoiVectors.ps1`, `modules/mb-image/qoi/generated_vectors.mbt`, `fixtures/manifest.json` - Reviewed fixture authority, deterministic materialization, generated table, and provenance.

## Decisions Made

- Used an independent QOI encoder with no registry, streaming API, FFI, benchmark, release work, or Phase 15 example.
- Used a count-only canonical prepass to validate all declared resource ceilings and atomically charge exact encoded-byte work before the first Writer call.
- Kept fixture `-Check` mutation-free and updated the manifest’s exact source SHA-256 and QOI-03/QOI-05 provenance usage.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected wrapped QOI byte-delta normalization.**
- **Found during:** Task 2 vector conformance.
- **Issue:** The first signed-delta helper used remainder arithmetic; negative remainders did not normalize `0 - 255` to QOI’s modular `+1` delta.
- **Fix:** Replaced remainder logic with explicit `[-128, 127]` normalization, making the `0xff -> 0x00` DIFF vector emit `0x7a` canonically.
- **Files modified:** `modules/mb-image/qoi/encode.mbt`, `fixtures/qoi/cases.json`, `modules/mb-image/qoi/generated_vectors.mbt`.
- **Verification:** Fixture freshness check and 235/235 passing tests on each supported target.
- **Committed in:** `0674534`, `72a9460`.

**Total deviations:** 1 auto-fixed Rule 1 correctness fix.

## Issues Encountered

- A test expectation initially assumed RGB fallback for `01 02 03`; QOI’s preference order correctly selects LUMA (`a2 79`), producing a 24-byte stream.
- An interrupted local test left a native test executable running; it was stopped before the next native build.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The portable QOI codec now has exact encode/decode evidence and remains within the unchanged codec seam, ready for the Phase 15 public workflow example.

## Self-Check: PASSED

All eight planned artifacts exist and all five Task 1/2 commits are present in the repository log.

---
*Phase: 14-canonical-qoi-encode-and-four-target-vectors*
*Completed: 2026-07-20*
