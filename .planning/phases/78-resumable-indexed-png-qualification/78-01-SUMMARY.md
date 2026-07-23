---
phase: 78-resumable-indexed-png-qualification
plan: 01
subsystem: png
tags: [png, indexed8, streaming, leases, crc, portability]
requires:
  - phase: 76-indexed8-source-eager-plte
    provides: [PngIndexedImage, eager-indexed8-png]
  - phase: 77-indexed-png-transparency
    provides: [canonical-indexed-trns, frozen-opaque-vector]
provides:
  - explicit Indexed8 caller-buffered PNG construction backed by the shared machine
  - hostile lease and atomic admission qualification for Indexed8 chunks
  - independent Indexed8 chunk wire, CRC, compatibility, and public decode evidence
affects: [indexed-png-encode, png-streaming, png-qualification]
tech-stack:
  added: []
  patterns: [direct-shared-machine-adapter, acknowledged-caller-leases, independent-png-wire-oracle]
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/encode_test.mbt
key-decisions:
  - "new_indexed8 is the only Indexed8 chunk factory and delegates directly to PngEncodeMachine::new_with_indexed."
  - "Chunk qualification uses caller-owned hostile leases plus independent PNG structural and public decoder oracles."
patterns-established:
  - "Profile-specific chunk factories remain thin Active-machine adapters so preflight, CRC, and acknowledgement state stay singular."
requirements-completed: [INDEX-04, INDEX-05]
coverage:
  - id: D1
    description: "Indexed8 caller-buffered output is eager-identical under zero, one-byte, and ragged leases with sticky terminals and atomic admission."
    requirement: INDEX-04
    verification:
      - kind: integration
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG Indexed8 chunk hostile leases retain eager parity and sticky completion"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen --target-dir C:\\Users\\Admin\\AppData\\Local\\Temp\\moonbit-phase78-executor-final-20260724"
        status: pass
    human_judgment: false
  - id: D2
    description: "Opaque and transparent Indexed8 chunk bytes retain wire framing, CRCs, the 89-byte opaque vector, and public RGB8/RGBA8 decoding."
    requirement: INDEX-05
    verification:
      - kind: integration
        ref: "modules/mb-image/png/encode_test.mbt#PNG Indexed8 chunk opaque wire CRC compatibility and public RGB8 decode"
        status: pass
      - kind: integration
        ref: "modules/mb-image/png/encode_test.mbt#PNG Indexed8 chunk transparent wire CRC and public RGBA8 decode"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen --target-dir C:\\Users\\Admin\\AppData\\Local\\Temp\\moonbit-phase78-executor-final-20260724"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-07-24
status: complete
---

# Phase 78 Plan 01: Resumable Indexed PNG Qualification Summary

**One explicit Indexed8 chunk factory now reuses the acknowledged PNG machine, with hostile lease parity and independent opaque/transparent wire and public decode qualification.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-07-24
- **Tasks:** 2/2
- **Files modified:** 3
- **Verification:** 278/278 tests passed on wasm, wasm-gc, js, and native.

## Accomplishments

- Added `PngChunkEncoder::new_indexed8(source, limits, budget, diagnostics)` as a direct `PngEncodeMachine::new_with_indexed` adapter; no generic model or alternate encoder was added.
- Proved eager byte identity, accepted-only writes, untouched tails, caller lease ownership, sticky completed/error terminals, and output/pixel/work admission atomicity.
- Qualified opaque and transparent chunk-origin bytes with an independent frame/CRC parser, the retained 89-byte opaque vector, Stored scanlines, and public RGB8/RGBA8 decode assertions.

## Task Commits

1. **Task 1: Add the shared-machine Indexed8 chunk path and prove one transparent end-to-end lease drain** - `180c528` (TDD RED), `f554d87` (feature), `063d8e5` (lifecycle qualification)
2. **Task 2: Qualify opaque and transparent chunk bytes through independent wire and public decode oracles** - `c0e267d` (qualification tests)

## Files Created/Modified

- `modules/mb-image/png/stream_encode.mbt` - direct public Indexed8 chunk factory over the shared indexed preflight and machine.
- `modules/mb-image/png/stream_encode_test.mbt` - transparent tracer plus hostile lease, sticky terminal, and atomic admission coverage.
- `modules/mb-image/png/encode_test.mbt` - public chunk drain, independent wire/CRC, frozen vector, and RGB8/RGBA8 decode coverage.

## Decisions Made

- Kept `new_indexed8` a thin match-and-return wrapper so indexed validation, budget charging, frame facts, CRC progression, and acknowledgement remain authoritative in `PngEncodeMachine`.
- Kept the fixed Type-3/8 Stored/filter-None/non-interlaced PLTE/tRNS profile; no low-bit, Adam7, strategy, FFI, or generic-model scope was introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The prescribed focused `--filter "PNG Indexed8 chunk"` command compiled successfully but MoonBit reported no matching test entry. The unfiltered required all-target package command executed the complete suite and passed 278/278 on every target.

## Known Stubs

None.

## Self-Check: PASSED

All three authorized implementation/test files and the summary exist; TDD and qualification commits `180c528`, `f554d87`, `063d8e5`, and `c0e267d` are present in git history.

## Next Phase Readiness

INDEX-04 and INDEX-05 now have a shared-machine streaming API and portable public qualification evidence. No blockers or follow-up scope were introduced.
