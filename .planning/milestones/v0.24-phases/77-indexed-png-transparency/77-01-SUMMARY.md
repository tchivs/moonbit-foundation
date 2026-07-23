---
phase: 77-indexed-png-transparency
plan: 01
subsystem: png
tags: [png, indexed8, palette-alpha, trns, crc]
requires:
  - phase: 76-indexed8-source-eager-plte
    provides: [PngIndexedImage, eager-indexed8-png]
provides:
  - owned validated per-palette alpha for eager Indexed8 sources
  - canonical optional tRNS framing with acknowledged CRC state
  - frozen opaque bytes and transparent wire/decode/atomicity evidence
affects: [indexed-png-encode, png-eager-transport]
tech-stack:
  added: []
  patterns: [validated-owned-segments, canonical-ancillary-frame, acknowledged-crc]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
key-decisions:
  - "Indexed palette alpha remains PNG-specific and is held in the existing single owning source allocation."
  - "tRNS is omitted for an all-opaque table; otherwise its canonical payload ends at the final non-255 alpha."
  - "tRNS CRC advances only after its payload byte is acknowledged by the writer machine."
patterns-established:
  - "Optional PNG ancillary chunks use scalar frame offsets and lengths shared by preflight and byte emission."
requirements-completed: [INDEX-03]
coverage:
  - id: D1
    description: "Eager Indexed8 accepts owned palette alpha and emits canonical optional tRNS."
    requirement: INDEX-03
    verification:
      - kind: integration
        ref: "modules/mb-image/png/encode_test.mbt#PNG Indexed8 tRNS wire order CRCs and Stored scanlines are exact"
        status: pass
    human_judgment: false
  - id: D2
    description: "Transparent indexed PNG public decode preserves exact RGBA8 palette semantics."
    requirement: INDEX-03
    verification:
      - kind: integration
        ref: "modules/mb-image/png/encode_test.mbt#PNG Indexed8 eager canonical tRNS decodes palette alpha as RGBA8"
        status: pass
    human_judgment: false
  - id: D3
    description: "Opaque Indexed8 output stays byte-identical to the Phase 76 89-byte vector."
    requirement: INDEX-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG Indexed8 wire order CRCs and Stored scanlines are exact"
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-07-24
status: complete
---

# Phase 77 Plan 01: Indexed PNG Transparency Summary

**Eager Indexed8 palette transparency with one owned alpha table, canonical optional tRNS chunks, and exact public RGBA8 decode-back.**

## Performance

- **Duration:** 33 min
- **Tasks:** 2/2
- **Files modified:** 5
- **Verification:** `moon -C modules/mb-image test png --target all --frozen --target-dir C:\Users\Admin\AppData\Local\Temp\moonbit-phase77-executor-20260724` — 272/272 on wasm, wasm-gc, js, and native.

## Accomplishments

- Extended `PngIndexedImage` to validate alpha cardinality before allocation or budget charge and own indices, RGB palette, and alpha bytes in one immutable allocation.
- Added canonical frame facts and byte-machine emission for `IHDR → PLTE → tRNS → IDAT → IEND`, with tRNS omitted when alpha is entirely opaque.
- Preserved the Phase 76 all-opaque 89-byte output verbatim and added independent chunk/CRC, public decode, atomicity, and acknowledgement-timing proof.

## Task Commits

1. **Task 1: Carry one palette-alpha Indexed8 source through canonical eager tRNS output** - `de081af` (TDD RED), `32a6bdb` (feature)
2. **Task 2: Prove transparency framing, CRC acknowledgement, opaque compatibility, and atomic admission** - `bbcd9f7` (tests)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - validated owned alpha segment and indexed alpha lookup.
- `modules/mb-image/png/encode.mbt` - canonical tRNS preflight span and admission accounting.
- `modules/mb-image/png/stream_encode.mbt` - tRNS chunk emission and acknowledgement-safe CRC.
- `modules/mb-image/png/encode_test.mbt` - public decode, independent wire/CRC, frozen opaque, and atomicity coverage.
- `modules/mb-image/png/encode_wbtest.mbt` - frame layout and CRC acknowledgement timing coverage.

## Decisions Made

- Kept Indexed8 alpha as a PNG-only owning-source extension; generic image models remain unchanged.
- Used the last non-opaque palette index plus one as the sole canonical tRNS payload length.
- Reused the established pending-byte protocol so preview cannot mutate tRNS CRC state.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The first frozen-vector test used a hand-calculated IDAT Adler/CRC tail. It was corrected from the actual Phase 76-equivalent opaque input (`00 04 00 02 0b 21 8b 71`); the encoder output and all pre-existing segmented assertions were unchanged.

## Known Stubs

None.

## Self-Check: PASSED

All five authorized implementation/test files exist, the three task commits exist, and the isolated four-target verification passed.

## Next Phase Readiness

The eager Indexed8 path now has bounded, canonical palette transparency without caller-buffered parity, indexed low-bit depths, Adam7, or generic model expansion.
