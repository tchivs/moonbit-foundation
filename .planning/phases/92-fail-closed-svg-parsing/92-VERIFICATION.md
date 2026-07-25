---
phase: 92-fail-closed-svg-parsing
verified: 2026-07-25T18:14:20Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "An explicitly malformed paint scalar is rejected with a structured SVG error before parse_svg can return a SceneNode."
    status: failed
    reason: "Functional color parsing accepts every component after the first three without validating its syntax or permitted arity. Consequently malformed rgb()/hsl() paint values can return Ok(SceneNode)."
    artifacts:
      - path: "modules/mb-svg/svg/color.mbt"
        issue: "parse_func_color checks only parts.length() < 3 and parses parts[0..2], silently ignoring parts[3..]."
      - path: "modules/mb-svg/svg/svg_test.mbt"
        issue: "No public regression case covers extra/malformed trailing functional-color components."
    missing:
      - "Enforce the supported functional-color arity before returning a color, preserving only the documented ignored rgba()/hsla() alpha boundary if that compatibility is intentional."
      - "Add public four-target regression cases such as rgb(1,2,3,garbage) and hsl(1,2%,3%,garbage), asserting the stable svg-numeric-source CoreError."
---

# Phase 92: Fail-Closed SVG Parsing Verification Report

**Phase Goal:** Explicitly unsafe SVG numeric input is rejected with a structured error before it can produce a scene or drawing list.
**Verified:** 2026-07-25T18:14:20Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Explicit malformed, non-finite, or out-of-envelope root, geometry, viewBox, path, transform, and paint input returns the structured SVG error. | ✗ FAILED | `color.mbt:146-152` accepts any functional-color list with at least three entries and never examines extras. Thus `rgb(1,2,3,garbage)` and `hsl(1,2%,3%,garbage)` are accepted instead of producing `svg-numeric-source`. This is an explicit malformed paint input, not an omission/default branch. |
| 2 | Unsafe relative, viewBox, affine, trigonometric, transformed-geometry, rounded-rect, and sampling calculations reject before lowering. | ✓ VERIFIED | `transform.mbt` admits radians, tangent, constructed affine values, and compositions; `scene.mbt:255-671` preflights accumulated transforms, viewBox, generated geometry, and path points before the sole `Ok(node)` at `scene.mbt:211-215`. Derived-route tests execute in the all-target run. |
| 3 | A rejected SVG exposes neither a scene nor a drawing list; omitted attributes alone preserve defaults/inheritance. | ✓ VERIFIED | `parse_svg_with_budget` propagates all builder/preflight errors and invokes `preflight_scene` immediately before `Ok(node)` (`scene.mbt:206-220`). `attr_double`, `inherit_double`, and root builders select defaults/inheritance only on `None` (`scene.mbt:1173-1196`, `1400-1408`, `1651-1660`). Public tests pattern-match `Err` before lowering. |
| 4 | Finite singular transforms, including `scale(0)`, remain valid. | ✓ VERIFIED | Admission tests coefficients rather than determinant (`transform.mbt:193-213`); public and white-box controls parse and lower `scale(0)`. |
| 5 | `S/s` and `T/t` use normalized SVG arity and compatible reflected-control state. | ✓ VERIFIED | `path_data.mbt` reads four values for `S/s`, two for `T/t`, gates reflection on `last_curve`, and derives checked reflected/relative values before appending the path command. `path_data_wbtest.mbt` covers exact arity and reflection. |
| 6 | Public parser/path entry points retain bounded resource behavior. | ✓ VERIFIED | Document source is admitted before tokenization (`scene.mbt:179-185`, `696-706`); direct path source is admitted before allocating/converting input (`path_data.mbt:13-26`); budget work/depth tests are included in the package suite. |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-svg/svg/svg.mbt` | Stable numeric `CoreError` helpers | ✓ VERIFIED | `Data`, `svg`, source/nonfinite/range contexts, and inclusive envelope are implemented. |
| `modules/mb-svg/svg/length.mbt` | Checked length/list/viewBox ingress | ✓ VERIFIED | Lexical/source, nonfinite, range, exact viewBox arity, and malformed comma checks propagate `Result`. |
| `modules/mb-svg/svg/transform.mbt` | Exact-arity source and derived affine admission | ✓ VERIFIED | All supported forms check arity; radians, tangent, affine components, and composition pass through derived admission. |
| `modules/mb-svg/svg/path_data.mbt` | Result-returning, normalized path scanner | ✓ VERIFIED | Source scanner, relative/reflection checks, smooth arity, close-state handling, and input budget seam are wired to public parsing. |
| `modules/mb-svg/svg/scene.mbt` | Result-propagating scene construction and derived preflight | ✓ VERIFIED | Root/group/leaf builders return errors upward; preflight executes before public scene publication. |
| `modules/mb-svg/svg/color.mbt` | Fail-closed supported functional-color scalar parsing | ✗ STUB / FAIL-OPEN | First three consumed components validate, but no upper arity/extra-component validation exists (`146-152`), permitting malformed `rgb`/`hsl` forms. |
| `modules/mb-svg/svg/svg_test.mbt` | Public no-scene/no-list error contract | ⚠️ PARTIAL | Covers representative root, paint, transform, path, and derived routes, but omits the trailing functional-color grammar gap. |
| `modules/mb-svg/svg/{parse,scene,transform,path_data,lower,numeric_contract,bounds}_wbtest.mbt` | Route and compatibility/budget regression evidence | ✓ VERIFIED | Included by `moon test modules/mb-svg/svg --target all --frozen`; all 117 tests pass on each target. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `parse_svg` | scene builders | `Result` propagation | ✓ WIRED | `build_svg_root`/`build_element` errors return through `parse_svg_with_budget`; success enters preflight only once. |
| `parse_svg_with_budget` | parser-side validation | `preflight_scene(node)` before `Ok(node)` | ✓ WIRED | `scene.mbt:206-220` proves no parser-produced scene is published before validation. |
| `parse_path_data_with_budget` | source/derived numeric helpers | `read_number`, `checked_add`, `checked_reflect` | ✓ WIRED | Every command branch returns `Err` on scanner or derived failure. |
| paint attributes | `build_paint` → `parse_color`/numeric parsers → `parse_svg` | Result propagation | ✗ NOT_FAIL_CLOSED | Normal failures propagate, but the functional-color parser itself accepts malformed trailing components, so this link has a fail-open success branch. |

### Data-Flow Trace (Level 4)

Not applicable: this parser package has no UI/dynamic-render data source. The relevant flow is source text → parser `Result` → validated `SceneNode` → total lowerer, verified above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Package public/internal parser, lowering, compatibility, and bounds tests on all production targets | `moon test modules/mb-svg/svg --target all --frozen` | 117 passed / 0 failed on `wasm`, `wasm-gc`, `js`, and `native` | ✓ PASS |
| Extra malformed functional-color component is rejected | Static disconfirmation of `color.mbt:146-152`; existing suite has no matching regression | Fails by inspection: entries after index 2 are ignored, so malformed `rgb`/`hsl` trailing data cannot produce the required error | ✗ FAIL |

### Probe Execution

SKIPPED — no phase-declared or conventional `scripts/**/probe-*.sh` probe exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SVGPR-02 | 92-01, 92-02, 92-03 | Explicit unsafe SVG scalar input returns structured error with no scene/drawing list. | ✗ BLOCKED | The malformed functional-color fail-open path means the requirement is not universally true for explicit paint input. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-svg/svg/color.mbt` | 147 | `parts.length() < 3` permits unlimited trailing arguments | 🛑 Blocker | Extra malformed numeric/text paint components are silently ignored and a scene can be returned. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in the Phase 92 source/test scope. `git diff --check 7fe2f1d..HEAD` is clean.

### Human Verification Required

None. The blocking condition is deterministic and observable from the functional-color parser's control flow; it requires code/test revision, not subjective testing.

### Gaps Summary

The phase has broad, working source/derived admission and four-target evidence, but it does not meet its universal fail-closed paint-input promise. `parse_func_color` validates only the first three entries and accepts every trailing entry. This makes malformed forms such as `rgb(1,2,3,garbage)` succeed and allows `parse_svg` to publish a scene. Phase 93 is about valid compatibility/raster qualification and does not explicitly schedule this parser defect, so it is not deferred.

---

_Verified: 2026-07-25T18:14:20Z_
_Verifier: the agent (gsd-verifier)_
