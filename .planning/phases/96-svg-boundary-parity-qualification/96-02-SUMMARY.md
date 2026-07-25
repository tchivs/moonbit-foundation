---
phase: 96-svg-boundary-parity-qualification
plan: 02
subsystem: svg-qualification
tags: [moonbit, svg, numeric-boundary, lowering, rfc-0008, portability]
requires:
  - 96-01
provides:
  - Manual-invalid SceneNode lowerer parity matrix
  - RFC 0008 opacity operation and raster semantic controls
affects: [mb-svg, mb-canvas]
tech-stack:
  added: []
  patterns: [white-box checked seam observations, deterministic DrawOp assertions, frozen four-target test gate]
key-files:
  created: []
  modified:
    - modules/mb-svg/svg/lower_wbtest.mbt
    - modules/mb-svg/svg/portable_qualification_wbtest.mbt
decisions:
  - Parser Err(CoreError) remains separate from deterministic total-lowerer recovery for manually constructed SceneNode values.
  - Manual Group affine remains a focused seam-versus-direct-PushTransform sentinel until a separately scoped production repair changes the lowerer contract.
  - RFC 0008 opacity is qualified through exact operation ordering and semantic pixels, not timing or target-specific internals.
metrics:
  duration: 19min
  completed: 2026-07-26
  tasks_completed: 2
  files_modified: 2
status: complete
---

# Phase 96 Plan 02: Manual lowerer and portable opacity qualification Summary

Manual-invalid SceneNode values now have deterministic lowerer evidence across every supported geometry family, while RFC 0008 group/element opacity has explicit portable operation and pixel controls.

## Completed Tasks

### Task 1: Distinguish manual-invalid total recovery from parser-boundary rejection

- Added a row-based matrix pairing public parser `Err(CoreError)` fixtures, private checked-geometry errors, and manually constructed total-lowerer observations.
- Covers invalid root/viewBox, Group affine, Rect, Circle, Ellipse, Line, Polyline, Polygon, CanvasPath, and path-point values.
- Preserves the root identity fallback, empty Path2 sentinel, and the Fill/Stroke plus PushLayer/PopLayer ordering twice for deterministic output.
- Records the intentional manual-Group differential: `checked_compose_affine(identity, transform)` fails while current lowering emits the direct `PushTransform` observation.

### Task 2: Preserve RFC 0008 semantic opacity behavior through the frozen all-target gate

- Added an independent nested group/element opacity fixture that asserts exact DrawOp nesting and opacity values.
- Asserts semantic compositing pixels on opaque and transparent raster targets.
- Retains the existing sixteen-layer success and seventeenth-layer structured-failure controls in the portable suite.

## Verification

- `moon test modules/mb-svg/svg --target native --frozen` — 137 passed.
- `moon test modules/mb-svg/svg --target all --frozen` — 137 passed on wasm, wasm-gc, js, and native.

## Decisions Made

- Parser-originated unsafe input is never represented by an empty DrawingList; that fallback is only for explicitly manual public SceneNode values.
- The Group direct-transform behavior is a compatibility detection control, not a production repair in this qualification-only plan.
- Pixel semantics and operation ordering are the portable compatibility oracle for RFC 0008 layers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test expectation] Used out-of-envelope manual values for line and point-list lowerer rows**
- **Found during:** Task 1
- **Issue:** A manual `65536` line/point coordinate is still admissible without the parser fixture's accumulated transform, so the direct checked-path assertion was incorrectly expecting an error.
- **Fix:** Changed only those manually constructed lowerer rows to `65537`, while retaining the parser fixtures that prove transformed boundary overflow.
- **Files modified:** `modules/mb-svg/svg/lower_wbtest.mbt`
- **Commit:** `2ed7c0f`

## Known Stubs

None.

## Self-Check: PASSED

- Both modified test files and this summary exist.
- Task commits `2cfd491`, `2ed7c0f`, `f319411`, and `77201d2` are present in git history.
