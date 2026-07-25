---
phase: 93-svg-compatibility-portable-qualification
reviewed: 2026-07-25T18:59:09Z
depth: deep
files_reviewed: 4
files_reviewed_list:
  - fixtures/manifest.json
  - fixtures/svg/cases.json
  - modules/mb-svg/svg/moon.pkg
  - modules/mb-svg/svg/portable_qualification_wbtest.mbt
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 93: Code Review Report

**Reviewed:** 2026-07-25T18:59:09Z
**Depth:** deep
**Files Reviewed:** 4
**Verdict:** BLOCKED

## Summary

The fixture manifest digest matches `fixtures/svg/cases.json`, the direct MoonBit imports are valid across the workspace, and both required all-target commands pass. However, two passing qualification tests leave required RFC 0008 semantics unproved: the nested group/element case never rasterizes a stroke-covered pixel, and the 16/17 layer checks do not make their claimed success/atomicity properties observable. These gaps can allow regressions in the exact Phase 93 contract to ship undetected.

Verification run:

- `moon test modules/mb-svg/svg --target all --frozen` — 125/125 passed on wasm, wasm-gc, js, and native.
- `moon test modules/mb-canvas/canvas --target all --frozen` — 43/43 passed on wasm, wasm-gc, js, and native.

## Critical Issues

### CR-01: Nested group/element opacity never verifies the stroke raster result

**File:** `D:/source/moonbit-foundation/modules/mb-svg/svg/portable_qualification_wbtest.mbt:198`

**Issue:** The `nested-group-element-opacity` fixture includes a blue `stroke`, but both RGBA assertions read `(4,4)`. That pixel is in the rectangle interior and outside its width-2 outline, so both assertions observe only the red fill through the two layers. The operation-pattern assertion confirms a `Stroke` operation exists, but no semantic raster assertion proves that a stroke is painted within the element layer and then composited with the element and group opacities. A renderer regression affecting strokes in offscreen layers would pass this new test and the existing direct layer tests (which exercise fills).

**Fix:** Sample a stable stroke-covered point, such as `(4,0)`, on both backdrops and assert the expected composited RGBA values. For this fixture, the stroke is opaque within the element layer, then receives 0.5 element and 0.5 group opacity: over white it should be `(191, 191, 255, 255)` and over transparent it should be `(0, 0, 255, 64)`. Keep the current center assertions for the fill-only path.

### CR-02: Layer-capacity raster assertions are vacuous and do not prove atomic primary preservation

**File:** `D:/source/moonbit-foundation/modules/mb-svg/svg/portable_qualification_wbtest.mbt:277`

**Issue:** The sixteen-layer test seeds an opaque primary target and asserts only `center_a > 0`. The center alpha is already 255 before rendering and remains positive even if the nested SVG content is skipped entirely; it therefore supplies no semantic-raster evidence. The seventeen-layer test then checks only the center pixel after the error (`:308`), although the required contract is that the primary raster is unchanged. A regression that mutates another primary pixel during allocation/error handling would still pass. Together these tests do not establish the claimed 16-layer raster outcome or no-primary-mutation guarantee.

**Fix:** Make the successful 16-layer output distinguishable from its seed, for example by generating all sixteen layers with an opacity that stays visibly representable in RGBA8 (while remaining below 1 so each lowers to a layer), then assert the full expected center RGBA. For the 17-layer error path, seed a non-uniform target or snapshot all 64 RGBA pixels before render and compare every byte after the `Resource/BudgetExceeded` result.

---

_Reviewed: 2026-07-25T18:59:09Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
