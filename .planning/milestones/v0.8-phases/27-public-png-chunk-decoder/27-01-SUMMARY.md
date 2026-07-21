---
phase: 27-public-png-chunk-decoder
plan: "01"
subsystem: png-decoder
tags: [moonbit, png, resumable-decode, byteview, portability]
requires:
  - phase: 26-pausable-png-decode-substrate
    provides: private byte-fed PNG framing, DEFLATE, raster, and terminal outcome machine
provides:
  - public PngChunkDecoder with explicit finish and exact per-push consumption
  - sticky terminal errors and one-time DecodeResult transfer
  - exact policy registration for the PNG chunk API
affects: [28-portable-png-streaming-evidence]
tech-stack:
  added: []
  patterns: [thin public wrapper over one private state machine, explicit EOF result transfer]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_decode.mbt
    - modules/mb-image/png/raster_decode.mbt
    - modules/mb-image/png/stream_decode_test.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
key-decisions:
  - "PngChunkDecoder feeds each admitted source byte synchronously into the Phase 26 PngDecodeMachine; it retains no caller ByteView."
  - "Only finish may move the private machine outcome into DecodeResult; completed and failed states are terminal."
requirements-completed: [PNGS-01, PNGS-02]
coverage:
  - id: D1
    description: Caller-buffered PNG pushes report exact consumption and expose no image before explicit finish.
    requirement: PNGS-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_decode_test.mbt#PNG chunk decoder API has strict explicit finish
        status: pass
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit finish transfers exactly one strict result and replays terminal errors deterministically.
    requirement: PNGS-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_decode_test.mbt#PNG chunk decoder transfers one result and preserves terminal errors
        status: pass
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png
        status: pass
    human_judgment: false
metrics:
  tasks: 3
  files_modified: 6
status: complete
---

# Phase 27 Plan 01: Public PNG Chunk Decoder Summary

**Portable PngChunkDecoder feeds arbitrary caller-owned bytes through the Phase 26 machine and transfers one strict image only at explicit EOF.**

## Accomplishments

- Added the documented `PngChunkDecoder`, push outcome, and push result API without changing the eager `PngDecoder` Reader contract.
- Preserved exact per-push accounting, source-limit preflight, first-error replay, and final outcome transfer after terminal PNG integrity checks.
- Registered the exact public surface and proved PNG quality through policy negatives, 3,850 decode vectors, and all four targets.

## Task Commits

1. **Task 1: Freeze public chunk-decoder and terminal contracts** — `341c9a0` (test)
2. **Task 2: Implement the thin public adapter over the private PNG machine** — `5f3fe1a` (feat)
3. **Task 3: Register the exact public interface and prove portable PNG behavior** — `ef2ceb7` (test)

## Verification

- `moon -C modules/mb-image test png --target native --frozen` — 69/69 passed before final contract expansion.
- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — 3,850 cases passed.
- `moon -C modules/mb-image test png --target all --frozen` — 70/70 passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed, including policy and scoped negative fixtures.

## Decisions Made

- The wrapper owns only public lifecycle and accounting; all parsing remains in the single private `PngDecodeMachine`.
- The raster sink exposes a private non-mutating completeness query so EOF classification does not move or expose the output image.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Renamed the facade state type to avoid an existing private PNG type collision.**
- **Found during:** Task 2
- **Fix:** Used `PngChunkDecoderState`, preserving the planned three-state wrapper model.
- **Verification:** Native and four-target PNG test suites passed.
- **Committed in:** `5f3fe1a`

## Next Phase Readiness

Phase 28 can build public hostile-schedule and portable workflow evidence over the stable `PngChunkDecoder` surface.

## Self-Check: PASSED

- Required code, policy, and quality files exist in their expected paths.
- Task commits `341c9a0`, `5f3fe1a`, and `ef2ceb7` exist in repository history.
