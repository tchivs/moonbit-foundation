---
phase: 95-shared-svg-geometry-boundary
verified: 2026-07-25T21:56:37Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 95: Shared SVG Geometry Boundary Verification Report

**Phase Goal:** Library users retain established valid SVG scenes and drawing lists while transforms, viewBox mapping, and shape/path coordinate derivation use one checked internal geometry implementation.
**Verified:** 2026-07-25T21:56:37Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Valid SVG fixtures using transforms, viewBox mapping, every supported shape, and paths retain usable scene/drawing-list behavior. | ✓ VERIFIED | Exported test `svg_test.mbt:63-89` parses a mixed root-viewBox + `scale(0)` fixture spanning rect/circle/ellipse/line/polyline/polygon/path and asserts the 11 DrawOps and affine values. The independently run all-target suite passed 134/134 on wasm, wasm-gc, js, and native. |
| 2 | Parser preflight and lowering obtain checked facts for every supported geometry family from the same private seam. | ✓ VERIFIED | `geometry.mbt:38-250` defines package-private checked affine, viewBox, point, rectangle, primitive, point-list, and CanvasPath facts. `scene.mbt:265-320` uses them in every `SceneNode` branch and propagates `Err`; `lower.mbt:47-128` uses the same facts through total adapters. |
| 3 | `parse_svg` remains the fail-closed public publication boundary, while `lower_to_drawing_list` remains total for manually constructed invalid data. | ✓ VERIFIED | `scene.mbt:165-225` only publishes `SceneNode` after `preflight_scene` succeeds; `lower.mbt:33-36` still returns `DrawingList`, and `lower.mbt:94-128` converts failed root/path facts to identity/empty deterministic values. Executed tests include `svg_test.mbt:171-189` and `lower_wbtest.mbt:691-728`. |
| 4 | The inclusive finite envelope, established structured derived error, omitted defaults, and finite `scale(0)` behavior are retained. | ✓ VERIFIED | `geometry.mbt:5-50` delegates derived arithmetic to existing `admit_derived`; direct overflow control in `geometry_wbtest.mbt:43-47` asserts `svg-numeric-derived`; public scale-zero/default tests are in `svg_test.mbt:50-89` and `numeric_contract_wbtest.mbt:5-42`. All executed on all four targets. |
| 5 | Valid manual/lowered geometry preserves deterministic DrawOp and path forms, including 32-sample ellipses and viewBox meet/slice/none behavior. | ✓ VERIFIED | `lower_wbtest.mbt:636-687` asserts concrete viewBox affine values and rounded-rect, ellipse, point-list, and path command forms. Existing lowerer controls cover viewBox variants; the full suite passed on every declared target. |
| 6 | The total lowerer uses deterministic recovery only when a manually constructed root/primitive/path is invalid; it does not add a public error API. | ✓ VERIFIED | `total_viewbox_transform`, `total_rect_path`, `total_path`, and `total_checked_path` in `lower.mbt:94-128` are private adapters. `lower_wbtest.mbt:691-728` lowers the same invalid manual scene twice, verifies equal eight-op output, empty paths, and preserved layers; it ran in the package gate. No `pub` API or new public error declaration was added in the verified phase diff. |
| 7 | RFC 0008 opacity operation ordering and the 16-layer boundary remain unchanged. | ✓ VERIFIED | `lower.mbt:59-75,134-172` retains transform/layer ownership. `lower_wbtest.mbt:498-580` asserts group/element layer order, and `portable_qualification_wbtest.mbt:318-368` asserts 16-layer render success plus atomic 17th-layer rejection. These tests passed in the four-target package run. |

**Score:** 7/7 truths verified (0 present but behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `modules/mb-svg/svg/geometry.mbt` | Private checked geometry authority | ✓ VERIFIED | Exists (251 lines), has substantive Result-returning logic for all planned geometry families, is package-private, and is called from both parser preflight and lowering. |
| `modules/mb-svg/svg/geometry_wbtest.mbt` | Direct seam controls | ✓ VERIFIED | Exists (107 lines); directly exercises map/affine/points, all primitive/path families, structured overflow, scale(0), parse-to-lower tracing, and total recovery. Included in the 134-test all-target run. |
| `modules/mb-svg/svg/lower_wbtest.mbt` | Semantic DrawingList and total-lowerer controls | ✓ VERIFIED | Substantive operation-level assertions cover valid forms, fallback determinism, opacity ordering, numeric compatibility, and layer behavior; calls `lower_to_drawing_list`. |
| `modules/mb-svg/svg/svg_test.mbt` | Exported parse-to-lower compatibility | ✓ VERIFIED | Public-only fixture calls `parse_svg`, then `lower_to_drawing_list` on success (`:68-73`); it asserts all supported valid families, viewBox, defaults, and scale(0). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `scene.mbt` | `geometry.mbt` | Preflight Result facts before SceneNode publication | ✓ WIRED | `preflight_node` at `scene.mbt:263-324` routes Svg, Group, Rect, Circle, Ellipse, Line, Polyline, Polygon, and Path through checked helpers and returns their errors. |
| `lower.mbt` | `geometry.mbt` | Total adapters consume valid checked facts | ✓ WIRED | `lower_node` plus adapters at `lower.mbt:40-128` call checked viewBox, primitive/path, and point-validation facts; valid parsed data receives `Ok` facts, invalid manual data receives deterministic fallback. |
| `svg_test.mbt` | public parser/lowerer | Parse success lowered into DrawingList | ✓ WIRED | `svg_test.mbt:68-73` has the call chain. The generic pattern check reported a false negative because `parse_svg` and `lower_to_drawing_list` occur on separate lines in one `match` branch; manual source trace and executed test verify the link. |
| `lower_wbtest.mbt` | `lower.mbt` | DrawOp assertions exercise total adapter and layer order | ✓ WIRED | `lower_wbtest.mbt:636-728` invokes lowerer and inspects exact operations, including the two repeated invalid-scene lowerings. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `scene.mbt` + `geometry.mbt` | parsed `SceneNode` values and accumulated affine | SVG source → `parse_svg` → `preflight_scene` | Yes — parsed root/group/shape/path data is passed to shared helpers; no static scene/result is returned. | ✓ FLOWING |
| `lower.mbt` + `geometry.mbt` | root transform and `Path2` facts | `SceneNode` → checked Result facts → `DrawingList` | Yes — successful facts become DrawOps; only failed manual-invalid facts use the explicitly tested identity/empty fallback. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Portable SVG compatibility, seam tests, parser errors, total fallback, opacity/layer controls | `moon test modules/mb-svg/svg --target all --frozen` | wasm 134/134; wasm-gc 134/134; js 134/134; native 134/134 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 95 declares no probe and no `scripts/**/probe-*.sh` path was found in either plan or summary.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| SVGUNI-01 | 95-01, 95-02 | Valid SVG behavior remains unchanged while parser and lowerer share one checked internal geometry implementation. | ✓ SATISFIED | All seven observable truths above; private seam is wired to both consumers, public compatibility/error tests and four-target gate pass. |

No orphaned Phase 95 requirement was found: `REQUIREMENTS.md:37` maps only `SVGUNI-01` to this phase, and both plans declare it.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `modules/mb-svg/svg/scene.mbt` | 340-670 | Superseded private preflight helper block remains after callers moved to `geometry.mbt`. | ℹ️ Info | It has no callers outside its own dead block, so it cannot bypass the shared seam at runtime. Remove in a later cleanup to prevent maintenance confusion. |
| `modules/mb-svg/svg/lower.mbt` | 192-400 | Superseded private local geometry helper block remains after `lower_node` moved to checked helpers. | ℹ️ Info | It has no callers outside its own dead block, so active lowering uses `geometry.mbt`. No `TBD`/`FIXME`/`XXX`, placeholder, empty implementation, or whitespace defect was found in phase-modified files/commits. |

### Human Verification Required

None. The phase exposes library behavior only; its behavior-dependent claims are exercised by the independently run portable package suite.

### Gaps Summary

None. The shared runtime geometry boundary, parser fail-closed behavior, deterministic manual-invalid lowering, valid-SVG compatibility, numeric/error compatibility, and RFC 0008 controls are all present, wired, and behaviorally exercised. The unreachable legacy helper blocks are recorded as non-blocking cleanup information, not a runtime alternate implementation.

---

_Verified: 2026-07-25T21:56:37Z_
_Verifier: the agent (gsd-verifier)_
