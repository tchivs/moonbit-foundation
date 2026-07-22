---
phase: 20-png-structural-safety-gate
plan: "02"
subsystem: png-codec
tags: [moonbit, png, crc32, parser-safety, generated-fixtures]
requires:
  - phase: 20-01
    provides: PngDecoder package boundary, policy inventory, and isolated Png quality lane
provides:
  - Fixed-scratch, forward-only PNG structural validation before raster work
  - Reader-driven generated hostile corpus with verified fixture provenance
  - Four-target proof of framing, metadata policy, and resource-envelope safety
affects: [phase-21-deflate-and-raster, png-interchange]
tech-stack:
  added: []
  patterns: [one-byte bounded reader, CRC-before-policy, non-consuming Budget child preflight]
key-files:
  created: []
  modified:
    - modules/mb-image/png/structural.mbt
    - modules/mb-image/png/generated_vectors.mbt
    - fixtures/png/cases.json
    - scripts/fixtures/Generate-PngStructuralVectors.ps1
key-decisions:
  - "Keep generated fixture access private and exercise it from structural_wbtest, preserving PngDecoder as the sole public PNG surface."
  - "Treat a structurally accepted empty-IDAT transport as the explicit Phase-20 capability terminal; Phase 21 alone owns DEFLATE and raster success."
patterns-established:
  - "PNG chunks are streamed through one private byte scratch and CRC-validated before state or policy actions."
  - "Future allocation/resource costs use checked arithmetic and an uncharged Budget child preflight."
requirements-completed: [PNG-01, PNG-02, PNG-03]
coverage:
  - id: D1
    description: Fixed-scratch PNG framing state machine with CRC, profile, metadata, and EOF enforcement.
    requirement: PNG-02
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Bounded non-consuming PNG probe and explicit pending capability seam with immutable caller state.
    requirement: PNG-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/png_test.mbt#PNG public decoder reaches capability only after complete structural transport
        status: pass
    human_judgment: false
  - id: D3
    description: Provenance-tagged hostile vector generator and full resource-envelope coverage on four portable targets.
    requirement: PNG-03
    verification:
      - kind: unit
        ref: pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check; pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
        status: pass
    human_judgment: false
metrics:
  duration: 13min
  completed: 2026-07-20
status: complete
---

# Phase 20 Plan 02: PNG Structural Safety Gap Closure Summary

**A fixed-scratch PNG gate now validates every chunk, CRC, accepted RGB/RGBA profile, metadata decision, resource envelope, and strict EOF before returning the Phase-20 pending capability error.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-20T15:16:00Z
- **Completed:** 2026-07-20T15:29:11Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Replaced signature-only decoding with a bounded state machine for IHDR, contiguous IDAT, IEND, type-form checks, streaming CRC-32, and strict EOF.
- Added checked profile/resource preflight and uncharged caller-Budget validation without constructing an image or emitting diagnostics.
- Generated executable hostile PNG bytes with provenance/digest checks; all vectors now run through the real decoder on js, wasm, wasm-gc, and native.

## Task Commits

1. **Task 1: Implement the fixed-scratch PNG chunk validator and post-validation terminal seam** - `ab0a016` (test), `1dfd6c7` (feat)
2. **Task 2: Expand generated structural vectors into all-target validator and envelope proof** - `4ae3fe7` (test), `56f46f6` (feat), `64344a4` (test)

## Files Created/Modified

- `modules/mb-image/png/structural.mbt` - private CRC/state/profile/resource structural gate.
- `modules/mb-image/png/png.mbt` - public decoder seam retained as the sole PNG API.
- `modules/mb-image/png/png_test.mbt` - black-box probe, framing, and pending-capability tests.
- `modules/mb-image/png/structural_wbtest.mbt` - generated-vector, policy, CRC, and envelope coverage.
- `modules/mb-image/png/generated_vectors.mbt` - generated executable fixture tuples.
- `fixtures/png/cases.json` and `fixtures/manifest.json` - compact hostile corpus and verified provenance digest.
- `scripts/fixtures/Generate-PngStructuralVectors.ps1` - deterministic schema, identity, digest, and artifact freshness check.

## Decisions Made

- Generated vectors remain package-private and run from the white-box layer because MoonBit black-box tests cannot consume private package helpers; this preserves the policy-verified public interface containing only `PngDecoder`.
- Empty IDAT content is structurally accepted only to reach `deflate-and-raster-pending`; Phase 21 remains responsible for legal DEFLATE and pixels.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired the stale Phase 20 current-plan state after the SDK parser could not advance it.**

- **Found during:** Final state update.
- **Issue:** `state.advance-plan` could not parse the pre-existing `Plan: Not yet planned` field even though this plan's summary existed.
- **Fix:** Kept the phase executing and recorded the factual 20-02 completion while preserving the pending 20-01 summary state.
- **Files modified:** `.planning/STATE.md`

**Total deviations:** 1 auto-fixed (Rule 3).
**Impact on plan:** Documentation state now accurately represents this completed plan without claiming the whole phase is complete.

## Known Stubs

None. The two empty arrays in `structural.mbt` are private bounded accumulators for the four-byte type and 13-byte IHDR fields, not placeholder data.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check` - passed.
- `moon -C modules/mb-image test png --target all --frozen` - 8/8 tests passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` - passed.

## Self-Check: PASSED

- All task commits (`ab0a016`, `1dfd6c7`, `4ae3fe7`, `56f46f6`, `64344a4`) exist.
- All PNG source, generated vector, fixture, and generator artifacts listed above exist.

## Next Phase Readiness

Phase 21 can replace only the final pending capability result after bounded DEFLATE and scanline reconstruction; it must retain this framing, CRC, profile, metadata, and resource gate.

---
*Phase: 20-png-structural-safety-gate*
*Completed: 2026-07-20*
