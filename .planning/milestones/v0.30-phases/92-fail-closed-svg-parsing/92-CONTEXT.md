# Phase 92: Fail-Closed SVG Parsing - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the supported `mb-svg` parser fail closed for explicit unsafe numeric input and unsafe derived numeric results. Validation must reject before a `SceneNode` or drawing list can be produced. This phase implements the Phase 91 admission contract; it does not add SVG features, revise the numeric envelope, or change `mb-canvas` layer/opacity policy.

</domain>

<decisions>
## Implementation Decisions

### Admission ownership
- **D-01:** Use the Phase 91 target-neutral finite envelope (`[-65536.0, 65536.0]`) as the only numeric admission policy. Centralize finite/bounded checks at parser ingress and checked derived-value seams instead of spreading unrelated caps through lowering. — **Reversibility:** costly — every supported parser path and compatibility fixture relies on the public admission contract.
- **D-02:** Validate all explicit scalar routes: coordinates, lengths, transforms, viewBox values, path arguments, and supported paint scalars; validate relative-coordinate, viewBox, affine construction/composition, transform-to-geometry, and trigonometric derivations before a scene exists.

### Failure semantics
- **D-03:** Any explicitly supplied malformed, non-finite, out-of-envelope, or derivatively unsafe scalar returns a structured SVG error. It must never silently default, clamp, wrap, or create a partial scene/drawing list. — **Reversibility:** costly — weakening this would be a public error-contract regression.
- **D-04:** Omitted attributes alone retain their established SVG defaults/inheritance. Tests assert stable error category and source/derived context, not full message wording.

### Compatibility boundaries
- **D-05:** Finite singular transforms, including `scale(0)`, remain accepted; non-invertibility is not an unsafe numeric result.
- **D-06:** `S/s` and `T/t` smooth path semantics remain outside the public numeric-admission guarantee until their parser normalization is completed in this phase; do not claim partial support or preserve malformed reads as compatibility behavior.
- **D-07:** `lower_to_drawing_list` and `mb-canvas` are total consumers of a validated scene. RFC 0008 PushLayer/PopLayer opacity and the 16-layer capability boundary are unchanged.

### the agent's Discretion
Choose helper names, internal error variants, and test organization from existing `mb-svg` patterns, provided every invalid explicit path fails before scene creation and four-target behavior remains deterministic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` §Phase 92 — goal, SVGPR-02, and observable success criteria.
- `.planning/REQUIREMENTS.md` §SVGPR-02 — structured error/no-scene/no-drawing-list contract.
- `.planning/phases/91-svg-numeric-contract/91-CONTEXT.md` — locked envelope, explicit-versus-absent semantics, and ownership boundary.
- `.planning/phases/91-svg-numeric-contract/91-VERIFICATION.md` — verified Phase 91 baseline and deferred seams.
- `docs/policies/svg-numeric-admission.md` — public admission matrix implemented by this phase.

### SVG and canvas boundaries
- `docs/rfcs/0002-mb-svg.md` §6.1, §8.1, §11.1 — SVG subset, checked-coordinate gap, and conformance expectations.
- `docs/rfcs/0008-mb-canvas-layer.md` §5, §7, §10 — layer/opacity semantics and 16-layer boundary that must remain unchanged.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-svg/svg/length.mbt`: numeric length and viewBox parsing seam.
- `modules/mb-svg/svg/transform.mbt`: transform grammar, affine construction, and trigonometric seam.
- `modules/mb-svg/svg/path_data.mbt`: path scanner and relative/derived coordinate seam.
- `modules/mb-svg/svg/scene.mbt`: explicit-attribute/default/inheritance handling and SceneNode boundary.
- `modules/mb-svg/svg/lower.mbt`: typed-scene consumer used to prove no drawing list follows rejection.

### Established Patterns
- Parsing APIs use `Result[..., @error.CoreError]`; invalid numerics must use this structured path rather than panic or fallback.
- Black-box `*_test.mbt` validates public behavior; `*_wbtest.mbt` protects internal route/representation invariants.

### Integration Points
- The parser-to-scene construction path is the enforcement boundary; lower/raster fixtures prove rejected input cannot reach drawing-list generation.

</code_context>

<specifics>
## Specific Ideas

No UI/product preferences. Use portable MoonBit APIs and the Phase 91 policy/tests as the source of truth.

</specifics>

<deferred>
## Deferred Ideas

None — feature expansion, native acceleration, layer redesign, release automation, and benchmark work remain in later v0.30 phases.

</deferred>

---

*Phase: 92-Fail-Closed SVG Parsing*
*Context gathered: 2026-07-26*
