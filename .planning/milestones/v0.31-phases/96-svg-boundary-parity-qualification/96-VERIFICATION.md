---
phase: 96-svg-boundary-parity-qualification
verified: 2026-07-25T22:59:56Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 7/7
  gaps_closed:
    - "Audited manual Group affine bypass: unsafe inherited composition no longer publishes a raw local DrawOp."
  gaps_remaining: []
  regressions: []
---

# Phase 96: SVG Boundary Parity Qualification Verification Report

**Phase Goal:** Unsafe SVG geometry fails at the shared numeric boundary before publication, and maintainers can detect future parser/lowerer divergence without changing established compatibility behavior.
**Verified:** 2026-07-25T22:59:56Z
**Status:** passed
**Re-verification:** Yes — after the v0.31 audit found the obsolete Group-affine bypass and Plan 96-03 closed it.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Explicit unsafe and derived-overflow SVG geometry returns the established structured error before a scene, drawing list, or raster result is published. | ✓ VERIFIED | `scene.mbt:208-217` publishes `Ok(node)` only after `preflight_scene`; `:255-335` composes every parsed `Svg` and `Group` through `checked_compose_affine`. `svg_test.mbt:148-192` covers unsafe source, single-group, nested `65536 + 1`, root-map, primitive, point-list, CanvasPath, and path-point inputs as `Err(CoreError)` with `svg-numeric-derived`. The all-target package test passed. |
| 2 | Maintainers can run deterministic adversarial controls that fail if parser preflight and lowering disagree about a numeric-boundary outcome. | ✓ VERIFIED | `geometry_wbtest.mbt:102-168` observes the actual checked root-map, affine, point, primitive, point-list, CanvasPath, and post-construction-path seams — no duplicate arithmetic oracle. `lower_wbtest.mbt:856-975` pairs the checked `65536 + 1` / viewBox×Group failures with two actual lowerer runs and exact DrawOps. |
| 3 | Every Group lowerer decision is made from the inherited checked affine, including a preceding Svg viewBox map and outer Group transforms. | ✓ VERIFIED | `lower.mbt:33-94` starts at identity, composes `current` with the total Svg map before recursion (`:52-69`), and composes `current` with each Group transform before emitting or traversing children (`:71-94`). The shared authority is `geometry.mbt:38-51`. `verify.key-links` independently found both declared Plan 96-03 links. |
| 4 | A manual nested Group whose individually valid transforms compose beyond the envelope recovers deterministically: identity local transform, retained safe parent state, and unchanged draw/layer/pop order. | ✓ VERIFIED | `lower_wbtest.mbt:856-898` asserts `checked_compose_affine(translate(65536), translate(1))` returns `svg-numeric-derived`, then lowers the manual tree twice. Each result has outer `PushTransform(65536)`, inner identity `PushTransform(1,1,0,0)`, paint layer, Fill/Stroke, and balanced pops. `lower.mbt:72-94` implements this exact recovery. |
| 5 | A viewBox map followed by a locally finite Group cannot contribute an unsafe effective transform; valid nested Groups retain their local transforms. | ✓ VERIFIED | `lower_wbtest.mbt:900-946` proves `checked_compose_affine(map(65536), scale(2))` fails and verifies lowerer output keeps the safe root map but emits identity for the Group twice. `:948-975` verifies the valid `(10, 1)` Group translations remain unchanged. |
| 6 | Valid finite `scale(0)`, compact viewBox/default routes, and RFC 0008 opacity/layer behavior remain unchanged. | ✓ VERIFIED | `svg_test.mbt:50-88` parses and lowers finite `scale(0)`, asserting the compact root map and zero scale; `geometry_wbtest.mbt:81-98` verifies scale-zero maps inclusive endpoints to `(0,0)`. The package suite also exercises the existing `portable_qualification_wbtest.mbt` RFC 0008 ordering, semantic-pixel, and 16/17-layer controls. |
| 7 | Parity and compatibility controls pass on `wasm`, `wasm-gc`, `js`, and `native`. | ✓ VERIFIED | Independent run: `moon test modules/mb-svg/svg --target all --frozen` → `137/137` passed on each target. `modules/mb-svg/moon.mod.json:9` declares exactly `+js+wasm+wasm-gc+native`. |

**Score:** 7/7 truths verified (0 present but behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-svg/svg/lower.mbt` | Checked inherited-affine traversal and deterministic total recovery | ✓ VERIFIED | 419 substantive lines; `Svg` and `Group` use the shared composition seam, recursively carry safe state, and preserve transform/layer stack balance. |
| `modules/mb-svg/svg/lower_wbtest.mbt` | Nested-Group and viewBox-to-Group recovery regressions | ✓ VERIFIED | Substantive test matrix calls the public lowerer twice per recovery case and inspects every relevant DrawOp. `verify.artifacts` reports 2/2 Plan 96-03 artifacts passed. |
| `modules/mb-svg/svg/svg_test.mbt` | Public parser failure and valid-compatibility controls | ✓ VERIFIED | Uses exported `parse_svg`/`lower_to_drawing_list`; all negative paths remain `Err`, while valid paths lower only inside `Ok(scene)`. |
| `modules/mb-svg/svg/geometry_wbtest.mbt` | Direct shared-seam parity controls | ✓ VERIFIED | Calls checked seam functions and asserts their structured derived-error context, including accumulated affine composition. |
| `modules/mb-svg/svg/portable_qualification_wbtest.mbt` | RFC 0008 portable operation/pixel/layer controls | ✓ VERIFIED | Runs parsed SVG through lowerer and canvas rendering; the all-target suite passed its deterministic assertions. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lower.mbt` | `geometry.mbt` | `checked_compose_affine(current, map/transform)` | ✓ WIRED | Both Svg and Group branches call the shared authority before child traversal; no direct unsafe Group transform branch remains. |
| `lower_wbtest.mbt` | `lower.mbt` | Manual nested `SceneNode` → `lower_to_drawing_list` twice → exact DrawOps | ✓ WIRED | The test observes the runtime lowerer result, not a mock or helper result. |
| `scene.mbt` | `geometry.mbt` | Parser preflight before SceneNode publication | ✓ WIRED | Parsed Svg and Group nodes share the same checked composition function; errors return before `Ok(node)`. |
| `svg_test.mbt` | `scene.mbt` | `parse_svg` Result observation | ✓ WIRED | Public test rows consume actual `Err(CoreError)` values and never lower a failed parse. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lower_wbtest.mbt` | `DrawingList` operations | Manually constructed Svg/Group tree → `lower_to_drawing_list` | Yes — actual operation arrays reveal outer safe transform, identity recovery, fills/strokes, layers, and pops. | ✓ FLOWING |
| `svg_test.mbt` | `Result[SceneNode, CoreError]` | SVG fixture → `parse_svg` → parser preflight | Yes — public structured error fields and successful DrawingList operations are inspected. | ✓ FLOWING |
| `portable_qualification_wbtest.mbt` | Rendered pixels and resource result | SVG source → parser → lowerer → canvas renderer | Yes — target-neutral semantic pixels and layer-boundary behavior are asserted by the passed package suite. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Parser fail-closed boundary; checked seam parity; manual inherited-affine recovery; scale(0); viewBox/default; RFC 0008; portability | `moon test modules/mb-svg/svg --target all --frozen` | wasm 137/137; wasm-gc 137/137; js 137/137; native 137/137 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 96 declares no probe and the repository contains no conventional `scripts/**/probe-*.sh` probe for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SVGUNI-01 | 96-03 (cross-phase closure; roadmap owner: Phase 95) | Parser and lowering consume one checked geometry seam for Group affine composition. | ✓ SATISFIED | `lower.mbt:52-94` now wires Svg and Group traversal to `checked_compose_affine`; audit's missing link is closed. |
| SVGUNI-02 | 96-01, 96-02, 96-03 | Unsafe explicit or derived geometry stops before unsafe publication at parser or lowerer boundary. | ✓ SATISFIED | Parser returns structured `Err`; manually constructed accumulated-affine values recover with safe DrawOps instead of raw unsafe operations. |
| SVGUNI-03 | 96-02, 96-03 | Deterministic divergence controls preserve singular transforms, RFC 0008 semantics, and four-target portability. | ✓ SATISFIED | Exact seam/DrawOp tests plus a fresh frozen all-target run prove the stated controls. |

No orphaned Phase 96 requirement was found: `REQUIREMENTS.md:38-39` assigns SVGUNI-02 and SVGUNI-03 to Phase 96. SVGUNI-01 is intentionally listed only as Plan 96-03's cross-phase audit closure and remains roadmap-owned by Phase 95.

### Anti-Patterns Found

None. Scanned all five phase artifacts for `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholders, and empty-return stub patterns; none were present. `git diff --check b70b9d4^..3bb4ae0` returned clean. The pre-existing untracked workspace entries were not touched.

### Human Verification Required

None. Every behavior-dependent truth above is exercised by the fresh, passing four-target package command; no visual or external-service claim remains.

### Gaps Summary

None. The former audit blocker — manual Group lowering publishing `PushTransform(65537)` without inherited-affine admission — is absent. The current implementation uses the shared checked seam at both Svg and Group boundaries, and the tests exercise nested Group and viewBox-derived overflows with identity/safe-parent recovery. No later roadmap phase exists, so no item was deferred.

---

_Verified: 2026-07-25T22:59:56Z_
_Verifier: the agent (gsd-verifier)_
