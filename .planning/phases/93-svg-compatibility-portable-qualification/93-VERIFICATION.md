---
phase: 93-svg-compatibility-portable-qualification
verified: 2026-07-25T19:10:53Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 93: SVG Compatibility & Portable Qualification Verification Report

**Phase Goal:** Library users retain deterministic valid SVG lowering and raster output, including isolated opacity semantics and the canvas layer-capacity boundary, on every portable target.
**Verified:** 2026-07-25T19:10:53Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Valid finite SVG fixtures retain deterministic drawing-operation and raster-output results on `js`, `wasm`, `wasm-gc`, and `native`. | ✓ VERIFIED | `portable_qualification_wbtest.mbt` exercises opaque rect, viewBox mapping, fill/stroke alpha, group overlap, nested opacity, and generated depth cases through `parse_svg → lower_to_drawing_list → @canvas.render`; it asserts exact op shapes and exact RGBA tuples. `moon test modules/mb-svg/svg --target all --frozen` passed 125/125 on each of wasm, wasm-gc, js, and native. |
| 2 | Group, element, fill, stroke, and nested opacity compose through existing isolated-layer semantics rather than changing per-paint output. | ✓ VERIFIED | The test asserts no layers and `fill.color_a == stroke.color_a == 0.5` for paint alpha; group overlap emits balanced `PushLayer(0.5)`/`PopLayer`; nested group + element emits two layers in LIFO order and checks fill and stroke pixels on opaque and transparent backdrops. `lower.mbt` lowers group and element opacity only through `push_layer`/`pop_layer`, while its paint styles retain fill/stroke alpha. All four targets passed these assertions. |
| 3 | Documents within the existing 16-layer canvas capability render as before, while a 17th nested opacity layer reports the established capacity outcome. | ✓ VERIFIED | Generated SVG, not hand-authored canvas ops, proves 16 balanced layers render with changed center and untouched corner. The 17-layer case requires `Resource/BudgetExceeded`, `canvas-render`, and `canvas-layer-depth: layer nesting depth exceeded`, then compares all 64 primary RGBA tuples to the pre-render snapshot. The renderer enforces `MAX_LAYER_DEPTH = 16` before allocating/recursing. SVG and canvas all-target suites passed. |
| 4 | Unsafe SVG rejection leaves no partial scene, drawing list, or raster result on all supported targets. | ✓ VERIFIED | The all-target test parses `<rect opacity="bad">`, requires the structured `Data/InvalidEncoding/svg/svg-numeric-source` error, and its error branch contains no lowering or rendering call. `parse_svg` returns `Result[SceneNode, CoreError]`, so an `Err` exposes no scene; therefore no drawing list/raster is constructed on that path. The 125/125 four-target SVG run includes this test and existing public numeric-admission controls. |
| 5 | Qualification causes no policy regression: any repair must be confined to the responsible existing seam and preserve Phase 91 admission, RFC 0008 allocation, and SVG surface semantics. | ✓ VERIFIED | Phase-93 implementation changes are only the fixture authority, manifest, package test imports, and qualification wbtest; `lower.mbt` and `rasterize.mbt` were not changed. Their existing behavior is directly exercised by the integration test and the 43/43 all-target canvas regression suite. No target branch, numeric-policy change, layer-count change, or SVG-surface expansion was found. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `fixtures/svg/cases.json` | Normative portable fixture schedule | ✓ VERIFIED | Contains seven named portable cases covering valid raster, opacity, and generated 16/17 depth outcomes. |
| `fixtures/manifest.json` | Fixture provenance and digest | ✓ VERIFIED | Records the SVGPR-03 expected use and SHA-256 `b7cfbdbe529ca4a2aabad6940ab5076941bfe2a706499486cb577ceb1bbb5d03`; an independent `Get-FileHash` matched it. |
| `modules/mb-svg/svg/portable_qualification_wbtest.mbt` | All-target parse/lower/raster and rejection controls | ✓ VERIFIED | 377 substantive lines, eight executable tests, no debt markers or placeholder paths; included in the passing SVG package suite. |
| `modules/mb-svg/svg/moon.pkg` | Direct imports and portable target declaration | ✓ VERIFIED | Declares the model/storage/profile/metadata imports used by the test and `+js+wasm+wasm-gc+native`. |
| `modules/mb-svg/svg/lower.mbt` | SVG opacity lowering seam | ✓ VERIFIED | Substantive lowering implementation; group and element `< 1.0` use balanced canvas layers and paint alpha remains in fill/stroke styles. |
| `modules/mb-canvas/canvas/rasterize.mbt` | Shared raster/layer-capacity seam | ✓ VERIFIED | Substantive renderer with `MAX_LAYER_DEPTH = 16`, structured `canvas-render` capacity error, offscreen recursion, and only composites after a nested segment succeeds. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `portable_qualification_wbtest.mbt` | `lower.mbt` | `parse_svg(source)` → `lower_to_drawing_list(scene)` | ✓ WIRED | Every valid fixture matches `Ok(scene)`, then loweres that exact scene into the inspected `DrawingList` (for example lines 93–103, 319–325). |
| `portable_qualification_wbtest.mbt` | `rasterize.mbt` | `@canvas.render(list, image, budget)` | ✓ WIRED | The same list is passed to the public canvas renderer before pixel assertions; source and target are linked through the `@canvas` package import. |
| 17-layer generated SVG case | `rasterize.mbt` | capacity error and atomic primary image | ✓ WIRED | The test inspects the renderer's `Resource/BudgetExceeded`/`canvas-render`/`canvas-layer-depth` result and then all target bytes; rasterizer's depth check is the producer of that exact error. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `portable_qualification_wbtest.mbt` | `scene` / `list` | Finite SVG literals passed to `parse_svg`, then `lower_to_drawing_list` | Actual parsed scene and actual `DrawingList`, not a mock or static operation list | ✓ FLOWING |
| `portable_qualification_wbtest.mbt` | `image` pixels | `@canvas.render(list, image, qualification_budget())` | Mutated 8×8 RGBA8 `OwnedImage` read back at semantic points (and all pixels in the atomic-error control) | ✓ FLOWING |
| fixture manifest | SHA-256 | Repository fixture authority | Independent hash equals declared digest | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| SVG end-to-end lowering, pixel, opacity, unsafe-input, and 16/17 capacity assertions | `moon test modules/mb-svg/svg --target all --frozen` | 125/125 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Shared canvas raster/layer regression behavior | `moon test modules/mb-canvas/canvas --target all --frozen` | 43/43 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Fixture provenance integrity | `Get-FileHash fixtures/svg/cases.json -Algorithm SHA256` | `b7cfbdbe529ca4a2aabad6940ab5076941bfe2a706499486cb577ceb1bbb5d03`, matching manifest | ✓ PASS |

### Probe Execution

SKIPPED — this phase is a MoonBit package qualification phase with direct four-target test commands, not a migration or tooling phase with declared probe scripts.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SVGPR-03 | `93-01-PLAN.md` | Deterministic valid SVG lowering/raster, isolated group/element opacity, and the 16-layer boundary on four portable targets. | ✓ SATISFIED | All five observable truths above are exercised as actual behavior by the two independent all-target test commands. |

No requirement mapped to Phase 93 is orphaned: the sole roadmap requirement, `SVGPR-03`, is claimed by `93-01-PLAN.md` and has direct implementation and test evidence.

### Anti-Patterns Found

No blocker, warning, or info anti-patterns were found in the phase files. The scan found no `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded user-visible empty-data marker. The four untracked workspace paths seen in `git status` are outside Phase 93 and were not changed.

### Disconfirmation Checks

The verification explicitly challenged three failure modes rather than accepting summary claims:

1. **Per-paint opacity masquerading as isolation:** the group-overlap and nested element cases assert both layer ordering and discriminating opaque/transparent RGBA pixels, including a stroke-only pixel.
2. **A capacity test that only checks an error:** the 17-layer test starts with a non-uniform target and checks every primary pixel after the renderer returns its exact structured error.
3. **A parser error with latent downstream work:** the unsafe-number error branch has no scene value and no lower/render calls; the public return type prevents a partial scene from escaping.

### Gaps Summary

No gaps found. The Phase 93 goal and all roadmap success criteria are supported by substantive, wired, data-flowing code and by passing behavior on each required portable target.

---

_Verified: 2026-07-25T19:10:53Z_
_Verifier: the agent (gsd-verifier)_
