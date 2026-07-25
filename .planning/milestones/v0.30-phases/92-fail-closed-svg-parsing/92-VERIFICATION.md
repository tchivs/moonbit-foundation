---
phase: 92-fail-closed-svg-parsing
verified: 2026-07-25T18:20:11Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "An explicitly malformed paint scalar is rejected with a structured SVG error before parse_svg can return a SceneNode."
  gaps_remaining: []
  regressions: []
---

# Phase 92: Fail-Closed SVG Parsing Verification Report

**Phase Goal:** Explicitly unsafe SVG numeric input is rejected with a structured error before it can produce a scene or drawing list.
**Verified:** 2026-07-25T18:20:11Z
**Status:** passed
**Re-verification:** Yes — after gap closure in `ce966aa`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Explicit malformed, non-finite, or out-of-envelope root, geometry, viewBox, path, transform, and paint input returns the structured SVG error. | ✓ VERIFIED | Shared source admission is used by length/list, path, transform, and color seams. `color.mbt:37-49` routes strict `rgb`/`hsl` through exact-arity parsing; `color.mbt:153-156` now rejects every non-three-argument strict form. The public parser cases added in `svg_test.mbt:75-76` prove malformed trailing `rgb` and `hsl` arguments return `InvalidEncoding` with `svg-numeric-source`. The existing `rgba`/`hsla` ignored-alpha compatibility boundary is intentionally retained and exercised by `scene_wbtest.mbt:366-419`. |
| 2 | Unsafe relative, viewBox, affine, trigonometric, transformed-geometry, rounded-rect, and sampling calculations reject before lowering. | ✓ VERIFIED | `path_data.mbt` admits relative/reflected values through `checked_add`/`checked_reflect`; `transform.mbt:71-223` checks exact arity, radians, tangent, constructed affine values, and compositions; `scene.mbt:206-215` runs `preflight_scene` before its sole successful parser return. Public/internal derived-route tests are part of the four-target suite. |
| 3 | A rejected SVG exposes neither a scene nor a drawing list, while omitted attributes retain established SVG defaults/inheritance. | ✓ VERIFIED | `parse_svg_with_budget` propagates builder or preflight `Err` and constructs `Ok(node)` only after preflight. `build_paint`, `inherit_double`, and `attr_double` take their inherited/default branches only on absent attributes. Public tests pattern-match `Err` before lowering; omitted/default controls parse and lower in `numeric_contract_wbtest.mbt:34-46` and `scene_wbtest.mbt:422-443`. |
| 4 | Finite singular transforms, including `scale(0)`, remain valid. | ✓ VERIFIED | Transform admission checks finite coefficients rather than determinant/invertibility. `svg_test.mbt:50-60`, `numeric_contract_wbtest.mbt:6-31`, and `transform_wbtest.mbt:242-245` exercise parse-and-lower or parser controls for `scale(0)` on every target. |
| 5 | `S/s` and `T/t` use normalized SVG arity and compatible reflected-control state. | ✓ VERIFIED | `path_data.mbt:160-223` consumes four `S/s` values and two `T/t` values; reflection is gated by the matching prior curve family and derived controls are admitted. `path_data_wbtest.mbt:199-214` verifies exact arity and compatible reflection. |
| 6 | Public parser and direct-path entry points retain bounded resource behavior. | ✓ VERIFIED | `scene.mbt:179-185` admits document source before tokenization; `path_data.mbt:13-26` admits path source before allocation/conversion. `bounds_wbtest.mbt:126-190` verifies document/path ceilings, boundary acceptance, and no work consumption on early source rejection. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-svg/svg/svg.mbt` | Stable numeric `CoreError` helpers | ✓ VERIFIED | Substantive helper implementation supplies Data/category, `svg` operation, source/nonfinite/range contexts, and the inclusive envelope; used by parser seams. |
| `modules/mb-svg/svg/{length,color,transform,path_data}.mbt` | Fail-closed source and derived scalar admission | ✓ VERIFIED | All are substantive `Result` parsers and are called by scene construction. `color.mbt` has no strict functional-color trailing-argument bypass after `ce966aa`. |
| `modules/mb-svg/svg/scene.mbt` | Result-propagating scene construction and derived preflight | ✓ VERIFIED | Builders propagate parser failures; parser-side preflight precedes the only `Ok(SceneNode)` publication path. |
| `modules/mb-svg/svg/{svg,parse,scene,transform,path_data,lower,numeric_contract,bounds}_wbtest.mbt` | Four-target public/internal regression evidence | ✓ VERIFIED | 117 tests execute and pass on wasm, wasm-gc, js, and native. |

`verify.artifacts` and `verify.key-links` cannot parse this phase's string-form frontmatter artifacts/links and returned zero entries; the artifact and link checks above were therefore completed directly against source and tests.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `parse_svg` | scene builders | `Result` propagation | ✓ WIRED | Builder errors return from `parse_svg_with_budget`; no fallback creates a `SceneNode` for invalid numeric input. |
| `parse_svg_with_budget` | parser-side validation | `preflight_scene(node)` before `Ok(node)` | ✓ WIRED | `scene.mbt:206-215` gates public scene publication on parser-side derived numeric checks. |
| paint attributes | `build_paint` → `parse_color` → `parse_svg` | Numeric-error propagation | ✓ WIRED | `build_paint` returns every SVG numeric error rather than selecting an inheritance/fallback branch; strict functional-color malformed trailing components now reach this path. |
| `parse_path_data_with_budget` | source/derived helpers | `read_number`, `checked_add`, `checked_reflect` | ✓ WIRED | Every command branch returns `Err` before a successful path is returned on source or derived numeric failure. |

### Data-Flow Trace (Level 4)

Not applicable: this is a parser package, not a dynamic-data rendering artifact. The relevant data flow is source text → typed `Result` → validated `SceneNode` → total lowerer; its error and success branches are traced above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Full SVG parser/lowering/compatibility/bounds suite on all production targets | `moon test modules/mb-svg/svg --target all --frozen` | 117 passed, 0 failed on wasm, wasm-gc, js, and native | ✓ PASS |
| Strict trailing functional-color rejection | Public cases in `svg_test.mbt:75-76` exercised by the command above | `rgb(1,2,3,garbage)` and `hsl(1,2%,3%,garbage)` require `InvalidEncoding` / `svg-numeric-source` | ✓ PASS |
| `rgba`/`hsla` ignored-alpha compatibility | `scene_wbtest.mbt:366-419`, exercised by the command above | Valid `rgba(...,0.25)` and `hsla(...,0.25)` parse in the finite scene control | ✓ PASS |

### Probe Execution

SKIPPED — no phase-declared or conventional `scripts/**/probe-*.sh` probe exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SVGPR-02 | 92-01, 92-02, 92-03 | Explicit unsafe SVG scalar input returns a structured error with no scene/drawing list. | ✓ SATISFIED | All six must-haves are verified; the prior malformed strict functional-color bypass is closed by source enforcement and public four-target regression coverage. |

### Anti-Patterns Found

No blocker or warning anti-patterns found in the Phase 92 source/test scope. There are no unreferenced `TBD`, `FIXME`, or `XXX` markers, and `git diff --check 7fe2f1d..HEAD` is clean.

### Human Verification Required

None.

### Gaps Summary

The sole prior gap is closed. Strict `rgb()` and `hsl()` now reject any trailing argument before component conversion, and the rejection is tested through the public `parse_svg` error contract on all four targets. `rgba()` and `hsla()` retain the plan's explicit ignored-alpha compatibility boundary; their first three consumed components remain admitted and their unconsumed alpha does not become a new SVGPR-02 scalar route.

---

_Verified: 2026-07-25T18:20:11Z_
_Verifier: the agent (gsd-verifier)_
