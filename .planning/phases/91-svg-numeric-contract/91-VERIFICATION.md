---
phase: 91-svg-numeric-contract
verified: 2026-07-25T16:31:58Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 91: SVG Numeric Contract Verification Report

**Phase Goal:** Library users have a documented, target-neutral SVG numeric admission contract covering every supported scalar ingress and derived-value path.
**Verified:** 2026-07-25T16:31:58Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Users can consult one finite, bounded, target-neutral SVG admission policy. | ✓ VERIFIED | [`svg-numeric-admission.md`](../../../docs/policies/svg-numeric-admission.md) defines `SVG_NUMERIC_LIMIT = 65536.0`, inclusive `[-65536.0, 65536.0]`, and the resource width/height basis. It specifies the predicate before `SceneNode` and names all four production targets. |
| 2 | The policy fixes the explicit-invalid versus absent/default distinction and stable structured-error fields. | ✓ VERIFIED | The policy's error table specifies `CoreError` `Data`, `InvalidEncoding`/`InvalidRange`, operation `svg`, and the four stable contexts; its explicit-value rule says only an absent attribute may use default/inheritance. Existing seams retain those absent branches: `points_from_attrs` and `attr_double` in [`scene.mbt`](../../../modules/mb-svg/svg/scene.mbt). |
| 3 | Every currently guaranteed scalar-ingress route has route-matrix evidence. | ✓ VERIFIED | The policy lists root, geometry, points, direct path, transform, paint, dash-list, and currently consumed RGB/HSL component routes. Focused controls in `parse_wbtest.mbt` and `scene_wbtest.mbt` exercise the finite boundary, roots/viewBox, shapes, points, dash list, paint scalars, and all five supported functional-colour component forms. |
| 4 | Every currently guaranteed derived route has route-matrix evidence, without overstating Phase 92 work. | ✓ VERIFIED | [`path_data_wbtest.mbt`](../../../modules/mb-svg/svg/path_data_wbtest.mbt) exercises direct relative `m/l/h/v/c/q/a`; [`transform_wbtest.mbt`](../../../modules/mb-svg/svg/transform_wbtest.mbt) exercises affine construction/composition and trigonometry; [`lower_wbtest.mbt`](../../../modules/mb-svg/svg/lower_wbtest.mbt) covers viewBox, rounded-rect arithmetic, and circle sampling. The policy explicitly marks smooth `S/s/T/t` reflected controls and accumulated transformed geometry as Phase 92 admission/enforcement work, matching Phase 92's stated fail-closed parsing goal. |
| 5 | A finite SVG at the documented boundary parses and lowers on every production target. | ✓ VERIFIED | [`numeric_contract_wbtest.mbt`](../../../modules/mb-svg/svg/numeric_contract_wbtest.mbt) calls `parse_svg` for `x=65536`, `y=-65536`, then `lower_to_drawing_list`, requiring a non-empty list. `moon test modules/mb-svg/svg --target all --frozen` passed 91/91 tests on wasm, wasm-gc, js, and native. |
| 6 | Finite singular transforms and RFC 0008 opacity/layer behavior remain unchanged. | ✓ VERIFIED | The transform control accepts `scale(0,65536)` while asserting that its inverse is `None`; the lower control checks nested group/element `PushLayer`/`PopLayer` ordering. Production [`lower.mbt`](../../../modules/mb-svg/svg/lower.mbt) still owns the total lowerer and layer emission, with no Phase 91 production-source change. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| [`docs/policies/svg-numeric-admission.md`](../../../docs/policies/svg-numeric-admission.md) | Public envelope, error contract, route matrix, and ownership boundary | ✓ VERIFIED | Substantive policy with finite predicate, 19 route rows, error table, unsupported colour-form declaration, scope/assumptions, and explicit Phase 92 boundary. Wired to controls by route identifiers. |
| [`numeric_contract_wbtest.mbt`](../../../modules/mb-svg/svg/numeric_contract_wbtest.mbt) | Boundary parse-to-lower tracer | ✓ VERIFIED | Substantive `parse_svg` → `lower_to_drawing_list` test checks boundary coordinates, finite singular transform, and non-empty output; included in the passing package test command. |
| [`parse_wbtest.mbt`](../../../modules/mb-svg/svg/parse_wbtest.mbt) | Lexical/root/points boundary evidence | ✓ VERIFIED | Focused test checks length, list, and exact four-value viewBox endpoints. |
| [`scene_wbtest.mbt`](../../../modules/mb-svg/svg/scene_wbtest.mbt) | Scene ingress, paint, dash-list, and absent/default evidence | ✓ VERIFIED | Focused test checks resolved parsed values rather than only parse success, plus separate absent root/points/inherited-paint controls. |
| [`path_data_wbtest.mbt`](../../../modules/mb-svg/svg/path_data_wbtest.mbt) | Direct path and direct-relative derived-route evidence | ✓ VERIFIED | Table-driven cases assert emitted endpoints and curve controls at the inclusive boundary for `m/l/h/v/c/q/a`. |
| [`transform_wbtest.mbt`](../../../modules/mb-svg/svg/transform_wbtest.mbt) | Transform, affine, trigonometric, and singular controls | ✓ VERIFIED | Tests matrix/translate/scale/rotate/skew/composition with finite envelope assertions and the determinant-zero control. |
| [`lower_wbtest.mbt`](../../../modules/mb-svg/svg/lower_wbtest.mbt) | Lowering derivations and opacity preservation | ✓ VERIFIED | Tests typed draw operations for viewBox, nested opacity layers, rounded-rect ratio output, and 32-segment circle sampling. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| Policy scalar envelope | Package tracer | `parse_svg` followed by `lower_to_drawing_list` | ✓ WIRED | The tracer contains `65536` and `-65536`, calls both APIs, and asserts a non-empty drawing list; the all-target package run passed. |
| Policy route identifiers | Focused white-box controls | `SVG-NUM-*` comments in test bodies | ✓ WIRED | Every current route identifier has a focused test reference. `SVG-NUM-SMOOTH-PENDING` and `SVG-NUM-TRANSFORMED-GEOMETRY` intentionally have no Phase 91 control because their admission rejection/enforcement is explicitly Phase 92 work, not an unclaimed missing link. |
| Validated scene | Total lowerer and canvas layer behavior | existing `lower_to_drawing_list` / `PushLayer` / `PopLayer` flow | ✓ WIRED | `lower.mbt` remains the consumer of `SceneNode`; focused lower controls exercise viewBox and nested layer output. |
| Test sources | js, wasm, wasm-gc, native | `moon test modules/mb-svg/svg --target all --frozen` | ✓ WIRED | Independent verification run passed all 91 tests on each target. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `numeric_contract_wbtest.mbt` | parsed `SceneNode` / drawing list | literal SVG → `parse_svg` → `lower_to_drawing_list` | Typed scene and non-empty `DrawingList` | ✓ FLOWING |
| Focused route controls | parsed scalars, affine values, paths, draw operations | parser/lower APIs in the actual package | Assertions inspect resolved values and typed operations | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| All focused policy controls, including parse-to-lower boundary behavior | `moon test modules/mb-svg/svg --target all --frozen` | 91/91 passed on wasm, wasm-gc, js, and native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SVGPR-01 | 91-01, 91-02 | Documented, target-neutral numeric admission contract with route-matrix tests for every supported scalar ingress and derived-value path | ✓ SATISFIED | Policy covers the envelope, stable errors, source/derived matrix, and Phase 92 boundary; route-identified controls pass on all four production targets. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty output pattern in Phase 91 policy/control artifacts | — | No blocker or warning found. |

## Phase Boundary Confirmed

Phase 91 is a documentation-and-evidence phase, not the fail-closed parser migration. The current source still contains the pre-existing fallback seams (for example `attr_double` and `points_from_attrs` default explicit parse failures, and `read_number` can return `0.0` on parse failure). The policy does not falsely claim those paths are already enforced: it assigns explicit malformed/non-finite/range/derived rejection behavior, smooth `S/s/T/t` normalization, and accumulated transformed-geometry admission to Phase 92. That aligns with the next roadmap goal, **Fail-Closed SVG Parsing**, and is not a Phase 91 gap.

## Gaps Summary

No Phase 91 gaps found. The goal is achieved: users have one target-neutral policy, route-matrix evidence for the current contract, and independently passing all-target valid-boundary controls. Phase 92 remains responsible for implementing and proving fail-closed rejection behavior.

---

_Verified: 2026-07-25T16:31:58Z_
_Verifier: the agent (gsd-verifier)_
