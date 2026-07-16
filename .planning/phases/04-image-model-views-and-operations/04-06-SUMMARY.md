---
phase: 04-image-model-views-and-operations
plan: "06"
subsystem: image-operations
tags: [moonbit, nearest-resize, pixel-conversion, alpha, atomic-budgets]

requires:
  - phase: 04-image-model-views-and-operations/04-05
    provides: Generated resize/conversion evidence, closed U8 operation gate, fresh output factory, and shared result contract
  - phase: 03-reference-color-semantics
    provides: Exact encoded straight/premultiplied alpha conversions and ties-even quantization
provides:
  - Checked integer-floor nearest resize over the closed packed U8 spine
  - Explicit RGB, straight RGBA, and premultiplied RGBA conversions
  - Atomic resource rejection and machine-readable alpha loss/transformation dispositions
affects: [04-image-model-views-and-operations, codec-contracts, phase-5-ppm]

tech-stack:
  added: []
  patterns:
    - Full-width output and maximum-coordinate validation before one scalar operation charge
    - Closed named conversion entry points instead of Boolean loss or swizzle modes
    - Pixel alpha math delegated to mb-color alpha contracts

key-files:
  created:
    - modules/mb-image/ops/resize.mbt
    - modules/mb-image/ops/convert.mbt
    - modules/mb-image/ops/resize_convert_test.mbt
    - modules/mb-image/ops/resize_convert_wbtest.mbt
  modified:
    - modules/mb-image/ops/moon.pkg
    - modules/mb-image/ops/reference_vectors_wbtest.mbt
    - scripts/fixtures/Generate-ImageVectors.ps1
    - policy/foundation.json

key-decisions:
  - "Use min(src_extent-1, floor(dst*src_extent/dst_extent)) with checked UInt64 products and preflight both maximum axis products before allocation."
  - "Expose strict opaque-only RGBA-to-RGB and a separately named lossy drop-alpha operation rather than a Boolean mode."
  - "Treat format changes as alpha disposition changes while preserving color, profile, opaque metadata, and stored-coordinate orientation."

patterns-established:
  - "Resize allocation order: capability, dimensions, output arithmetic, maximum coordinate products, one combined charge, then failure-free traversal."
  - "Conversion validation order: capability, output arithmetic, pure pixel invariant scan where needed, one combined charge, then mb-color-backed traversal."

requirements-completed: [IMAG-05, IMAG-06]

coverage:
  - id: D1
    description: Nearest resize uses checked integer-floor coordinate mapping, produces fresh tight output, and preserves metadata without hidden filtering or color conversion.
    requirement: IMAG-05
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/resize_convert_test.mbt and resize_convert_wbtest.mbt; moon -C modules/mb-image test ops --target all --frozen (18/18 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: Closed RGB/RGBA and straight/premultiplied conversions preserve color identity, report alpha transformation or loss, and fail atomically.
    requirement: IMAG-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required; 163/163 workspace tests per target"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 6: Deterministic Resize and Pixel Conversion Summary

**Checked integer-floor nearest resize plus explicit RGB/RGBA and straight/premultiplied U8 conversion with atomic budgets and executable metadata loss evidence**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-17T06:03:47+08:00
- **Completed:** 2026-07-17T06:13:18+08:00
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added fresh tightly packed nearest resize using only the locked checked UInt64 floor mapping across generated upscale, downscale, unit-axis, and final-pixel cases.
- Added named RGB-to-straight-RGBA, strict and explicit-lossy RGBA-to-RGB, and straight/premultiplied RGBA conversion entry points backed by `mb-color/alpha`.
- Preserved color/profile/opaque/orientation identity, transformed or discarded alpha explicitly, and proved unsupported, invalid-pixel, overflow, and budget failures consume no authoritative counters.

## Task Commits

1. **RED: Add failing resize and conversion contracts** - `b65f4db` (test)
2. **GREEN: Implement integer-floor nearest resize** - `aa18f5c` (feat)
3. **GREEN: Implement closed U8 pixel conversions** - `5e460e0` (feat)
4. **Correctness: Preflight nearest coordinate products** - `e9a9ebb` (fix)
5. **Policy: Assign alpha dependency to image ops** - `d86c055` (fix)

## Files Created/Modified

- `modules/mb-image/ops/resize.mbt` - Checked nearest coordinate mapping, tight descriptor construction, scalar allocation, and deterministic traversal.
- `modules/mb-image/ops/convert.mbt` - Closed conversion dispatcher, metadata reconstruction/disposition, pure invariant validation, and `mb-color/alpha` delegation.
- `modules/mb-image/ops/resize_convert_test.mbt` - Public pixel, metadata, profile, loss, fresh-output, and canonical-zero behavior.
- `modules/mb-image/ops/resize_convert_wbtest.mbt` - Generated-case consumption, zero-axis, work, unsupported-format, and invalid-premultiplied atomicity evidence.
- `modules/mb-image/ops/reference_vectors_wbtest.mbt` - Package-local resize and complete conversion vector tables.
- `scripts/fixtures/Generate-ImageVectors.ps1` - Deterministic rendering of behaviorally consumable conversion vectors.
- `modules/mb-image/ops/moon.pkg` - Exact direct `mb-color/alpha` dependency.
- `policy/foundation.json` - Publication inventory, dependency allowlist, and 21-line exact semantic interface.

## Decisions Made

- Preflight maximum resize coordinate products before allocation so no checked mapping failure can occur after a successful resource charge.
- Use distinct strict and lossy alpha-removal APIs; the lossy operation reports discarded `alpha`, while lossless format/alpha-mode conversions report transformed `alpha`.
- Preserve the exact color space, transfer, profile, opaque metadata, and stored orientation because these operations do not change color identity or display-coordinate policy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced generated nested Byte arrays that triggered pinned compiler ICE**
- **Found during:** Task 2 GREEN compilation
- **Issue:** The pinned `moonc v0.10.4+2cc641edf` crashed with `Invalid_argument("Moonc.Basic_ba_int.get")` while compiling nested generated `Array[Byte]` conversion tables.
- **Fix:** Rendered canonical UInt64 tables and performed explicit checked-domain Byte conversion inside the package-local test consumer.
- **Files modified:** `scripts/fixtures/Generate-ImageVectors.ps1`, `modules/mb-image/ops/reference_vectors_wbtest.mbt`, `modules/mb-image/ops/resize_convert_wbtest.mbt`
- **Verification:** Generator `-Check` and all four ops targets pass without ICE.
- **Committed in:** `5e460e0`

**2. [Rule 1 - Bug] Corrected direct alpha dependency policy ownership**
- **Found during:** First Required run
- **Issue:** The initial policy edit added `mb-color/alpha` to storage rather than ops, producing an exact import-count mismatch.
- **Fix:** Restored the storage allowlist and assigned the direct dependency to `mb-image/ops`.
- **Files modified:** `policy/foundation.json`
- **Verification:** Required passed exact imports, DAG, interface, publication, and read-only gates.
- **Committed in:** `d86c055`

**Total deviations:** 2 auto-fixed (1 blocking compiler compatibility issue, 1 policy placement bug). **Impact:** Both fixes preserve the planned API and architecture; no product scope was added.

## Issues Encountered

- The Required lane's expected negative README fixture prints a missing-file error while its enclosing fail-closed check succeeds; the lane exited 0 as designed.

## User Setup Required

None - no external service configuration required.

## Verification

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check`: all generated image artifacts and shared manifest were byte-identical.
- `moon -C modules/mb-image test ops --target all --frozen`: 18/18 passed independently on js, wasm, wasm-gc, and native.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 163/163 workspace tests per target, exact 21-line ops interface, publication allowlist, dependency DAG, negative fixtures, and read-only proof.

## Self-Check: PASSED

- All eight planned or necessary generator files exist.
- Commits `b65f4db`, `aa18f5c`, `5e460e0`, `e9a9ebb`, and `d86c055` resolve in repository history.
- No TODO/FIXME/placeholder stubs or new network, filesystem, authentication, registry, codec, or schema threat surface was introduced.

## Next Phase Readiness

- Plan 04-07 can build codec-facing Reader/Writer contracts over completed image models, views, metadata dispositions, and deterministic operations.
- No blockers remain.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
