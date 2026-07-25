---
phase: 96-svg-boundary-parity-qualification
verified: 2026-07-25T22:37:52Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 96: SVG Boundary Parity Qualification Verification Report

**Phase Goal:** Unsafe SVG geometry fails at the shared numeric boundary before publication, and maintainers can detect future parser/lowerer divergence without changing established compatibility behavior.
**Verified:** 2026-07-25T22:37:52Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Explicit unsafe and derived-overflow SVG geometry returns the established structured error before a parser-produced scene can be lowered or rasterized. | ✓ VERIFIED | `scene.mbt:206-217` invokes `preflight_scene` and returns `Err` before `Ok(node)`. `svg_test.mbt:21-46,148-191` asserts all four public error facts (Data, code, `svg`, context) for explicit source/nonfinite/range input and all derived root, affine, primitive, point-list, CanvasPath, and path-point rows; its only lowering calls are in `Ok(scene)` branches (`:50-88`). The four-target suite executed these tests successfully. |
| 2 | Every derived adversarial root, affine, primitive, point-list, CanvasPath, and post-construction path-point family has a direct private checked-seam observation, without a duplicated arithmetic oracle. | ✓ VERIFIED | `geometry_wbtest.mbt:102-168` calls `checked_viewbox_transform`, `checked_compose_affine`, `checked_transform_point`, all primitive/point-list builders, `checked_canvas_path`, and `checked_path_points`, asserting `svg-numeric-derived`. Production preflight routes each `SceneNode` variant through the same helpers in `scene.mbt:263-324`. |
| 3 | Manual invalid `SceneNode` values preserve total-lowerer compatibility without being represented as parser success. | ✓ VERIFIED | `lower_wbtest.mbt:780-861` first asserts parser `Err(CoreError)` for distinct source inputs, then constructs manual root, rectangle, circle, ellipse, line, polyline, polygon, CanvasPath, and path-point values. It lowers each twice and asserts the existing identity or empty-path DrawOp sentinel plus layer/fill/stroke ordering. `lower.mbt:91-128` is the wired identity/empty-path recovery implementation. |
| 4 | The known manual Group seam/lowerer differential is explicit and detectable rather than silently treated as parser behavior. | ✓ VERIFIED | `lower_wbtest.mbt:825-835` proves `checked_compose_affine(identity, unsafe_group)` returns `svg-numeric-derived` while manually lowering the Group preserves the present direct `PushTransform(65537)` sentinel. This matches the intentional total-lowerer boundary in `lower.mbt:59-75`; parsed groups cannot reach it unchecked because `scene.mbt:275-280` preflights composition. |
| 5 | Finite `scale(0)`, compact viewBox mapping, and omitted-default SVG routes remain valid. | ✓ VERIFIED | Public controls in `svg_test.mbt:50-88` parse then lower only successful scenes, asserting non-empty output, root map `(2,2,2)`, zero scale, and all supported defaulted shape/path families. Private finite-boundary control in `geometry_wbtest.mbt:81-98` verifies `scale(0)` maps inclusive endpoints to `(0,0)`. |
| 6 | RFC 0008 group/element opacity ordering, semantic raster output, and the 16-layer resource boundary are unchanged. | ✓ VERIFIED | `portable_qualification_wbtest.mbt:318-377` checks 16-layer rendering, deterministic pixels, and atomic structured failure at layer 17. `:380-430` checks exact `PushTransform → PushLayer(group) → PushLayer(element) → Fill/Stroke → PopLayer → PopLayer → PopTransform` order and opaque/transparent target pixels. These are the RFC 0008 semantics stated in `docs/rfcs/0008-mb-canvas-layer.md:47-52,110-117`. |
| 7 | Qualification controls run successfully on every declared portable target. | ✓ VERIFIED | Independent command `moon test modules/mb-svg/svg --target all --frozen` completed with `137/137` passing on wasm, wasm-gc, js, and native. `modules/mb-svg/moon.mod.json:9` declares exactly `+js+wasm+wasm-gc+native`. |

**Score:** 7/7 truths verified (0 present but behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `modules/mb-svg/svg/svg_test.mbt` | Public structured parser-error controls | ✓ VERIFIED | Substantive exported-API tests cover explicit and derived failures, inspect the established error schema, and lower only `Ok(scene)` values. |
| `modules/mb-svg/svg/geometry_wbtest.mbt` | Direct private checked-seam parity matrix | ✓ VERIFIED | Substantive calls cover root mapping, composed affine, transformed points, all primitive/point-list builders, CanvasPath, and Path2-point admission. |
| `modules/mb-svg/svg/lower_wbtest.mbt` | Manual-invalid deterministic lowerer controls | ✓ VERIFIED | Row matrix calls the actual total lowerer twice per applicable leaf fallback and preserves the documented Group direct-transform sentinel. |
| `modules/mb-svg/svg/portable_qualification_wbtest.mbt` | Target-neutral opacity/layer semantic controls | ✓ VERIFIED | Uses actual parsed SVG, DrawOps, canvas rendering, semantic pixels, and the 16/17-depth behavior. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `svg_test.mbt` | `scene.mbt` | `parse_svg` returns `Err(CoreError)` before SceneNode publication | ✓ WIRED | `parse_svg` is public at `scene.mbt:165-166`; it calls preflight before publishing (`:206-217`). `svg_test.mbt:45,149-191` consumes the returned Result directly. The plan tool's regex is malformed, but manual source trace verifies the actual link. |
| `geometry_wbtest.mbt` | `geometry.mbt` | Direct `checked_*` Result observations | ✓ WIRED | The matrix at `geometry_wbtest.mbt:102-168` calls the package-private seam functions exercised by parser preflight. |
| `lower_wbtest.mbt` | `lower.mbt` | `lower_to_drawing_list` observes identity/empty-path recovery | ✓ WIRED | Manual rows call `lower_to_drawing_list` at `:765-766,813-814,832,839-861`; runtime adapters are `lower.mbt:94-128`. |
| `portable_qualification_wbtest.mbt` | `lower.mbt` and `mb-canvas` | Parsed scene lowers to DrawOps then renders to pixels | ✓ WIRED | `:319-328,345-375,388-429` execute `parse_svg → lower_to_drawing_list → @canvas.render` and assert operation/pixel outcomes. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `svg_test.mbt` | `Result[SceneNode, CoreError]` | SVG fixture → `parse_svg` → `preflight_scene` | Yes — error tests inspect the actual public error and successful controls lower the actual scene. | ✓ FLOWING |
| `lower_wbtest.mbt` | `DrawingList` DrawOps | Explicit manual `SceneNode` → `lower_to_drawing_list` | Yes — exact runtime DrawOps and Path2 lengths are inspected; no mock list or hardcoded result is used. | ✓ FLOWING |
| `portable_qualification_wbtest.mbt` | Raster pixels | Parsed SVG → DrawingList → `@canvas.render` → image pixels | Yes — opaque and transparent images receive actual render output, including atomic failure preservation. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Parser/seam parity, manual fallback, RFC 0008 opacity/layer behavior, all portable targets | `moon test modules/mb-svg/svg --target all --frozen` | wasm 137/137; wasm-gc 137/137; js 137/137; native 137/137 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no phase-declared probe and no conventional `scripts/**/probe-*.sh` file exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SVGUNI-02 | 96-01, 96-02 | Unsafe explicit or derived geometry returns structured error before scene/drawing/raster publication at parser or lowerer boundary. | ✓ SATISFIED | Public parser checks prove fail-closed publication; private seam and manual total-lowerer controls prove the separate manual-value contract without a new error API. |
| SVGUNI-03 | 96-02 | Deterministic controls detect parser/lowerer divergence while preserving singular transforms, RFC 0008 behavior, and four-target portability. | ✓ SATISFIED | Matrix tests preserve the Group differential as a focused sentinel, retain `scale(0)`/viewBox/default behavior, verify opacity/layers/pixels, and pass all targets. |

No orphaned Phase 96 requirement was found: `REQUIREMENTS.md:38-39` maps only SVGUNI-02 and SVGUNI-03 to this phase, and the two plans declare those IDs.

### Anti-Patterns Found

None. The phase diff from `87351fe^` through `77201d2` modifies only the four intended test files under `modules/mb-svg/svg` (plus planning records); `scene.mbt`, `lower.mbt`, `geometry.mbt`, `svg.mbt`, and `moon.mod.json` have no Phase 96 diff. No `TBD`/`FIXME`/`XXX`, placeholder, empty implementation, or whitespace error (`git diff --check`) was found in the phase-modified test files.

### Human Verification Required

None. The phase's runtime claims are exercised by the independently run frozen package suite on all four declared targets.

### Gaps Summary

None. The parser boundary, private checked seam, manual-invalid total-lowerer distinction, Group differential sentinel, compatibility regressions, RFC 0008 semantic controls, and four-target execution all have code-level and behavioral evidence. No production or public-API change was introduced by this qualification-only phase.

---

_Verified: 2026-07-25T22:37:52Z_
_Verifier: the agent (gsd-verifier)_
