---
quick_id: 260721-4vk
subsystem: png-decoder
tags: [png, trns, rgba8, fixtures, moonbit]
requirements-completed: []
requirements-progress:
  - PNGX-01 tRNS transparency subset
status: complete
---

# Quick Task 260721-4vk: PNG tRNS Transparency Summary

**Bounded eager PNG decoding now maps valid 8-bit grayscale, RGB, and indexed `tRNS` data to straight RGBA8 while preserving encoded-source filter semantics.**

## Accomplishments

- Added private typed tRNS transport state with CRC, ordering, payload length, sample high-byte, PLTE, duplication, and type-6 validation.
- Preserved source bpp during filter reconstruction, then applied grayscale/RGB keys or indexed palette alpha to RGBA8 output.
- Reserved RGBA image storage atomically, including both indexed source-row caches, and regenerated the independent decode/structural vector evidence and manifest digests.

## Scope Completion

This task completes only the 8-bit non-interlaced `tRNS` subset of PNGX-01.
Low-bit-depth and 16-bit profiles, grayscale-alpha, Adam7, and colour-management
semantics remain future work.

## Commit

- `21e5556` `feat(quick-260721-4vk): decode PNG tRNS transparency`
- `0354596` `fix(quick-260721-4vk): verify PNG tRNS source transparency oracle`

## Verification

- `Generate-PngDecodeVectors.ps1 -Check` — passed (161 executable cases).
- `Generate-PngStructuralVectors.ps1 -Check` — passed (89 public/white-box cases).
- `moon -C modules/mb-image test png --target all --frozen` — passed (23 tests on wasm, wasm-gc, js, native).
- `Invoke-MoonQuality.ps1 -Lane Png` — passed, including lane isolation.
- `moon -C modules/mb-image check --target all --deny-warn --frozen` — blocked by pre-existing unused-field diagnostics in generated structural vector types and legacy `PngTransport` fields; no task-owned fixes were applied outside the scoped slice.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped transparent child-budget work limit to the caller maximum**
- **Found during:** tRNS vector execution.
- **Issue:** The child budget used computed image work as its operation limit, causing valid transparent images to fail when image creation requested the caller's maximum work allowance.
- **Fix:** Kept checked computed-work validation, while assigning the child budget's work limit from `limits.max_work()`.
- **Committed in:** `21e5556`.

### Follow-up Evidence Hardening

**2. [Rule 2 - Missing Critical] Independently verify type-0 and type-2 tRNS expected pixels**
- **Found during:** Independent review after the initial commit.
- **Issue:** The generator independently reconstructed indexed transparency but emitted grayscale and RGB expected pixels directly from JSON.
- **Fix:** The generator now inflates and reconstructs grayscale/RGB scanlines with their encoded source bpp, validates the zero high-byte tRNS keys, derives straight RGBA, and compares it with the declared fixture bytes before emission.
- **Committed in:** `0354596`.

## Known Stubs

None.

## Next Steps

The supported tRNS slice is complete. Broader PNGX-01 work remains limited to later 16-bit, low-bit-depth, grayscale-alpha, Adam7, and color-management slices.
