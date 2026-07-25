# Phase 91: SVG Numeric Contract - Context

**Gathered:** 2026-07-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the target-neutral numeric admission contract and route-matrix evidence for the supported `mb-svg` subset. This phase locks policy and tests; Phase 92 performs the parser/scene migration. It does not add SVG features or change `mb-canvas` rendering policy.

</domain>

<decisions>
## Implementation Decisions

### Numeric envelope
- **D-01:** Derive one documented, target-neutral finite numeric envelope from existing canvas, raster, and resource constraints; do not choose an arbitrary generic `Double` magnitude. — **Reversibility:** costly — the contract is exercised by every SVG numeric ingress and compatibility fixture.
- **D-02:** Route-matrix evidence must cover both source parsing and every derived path (relative geometry, viewBox mapping, affine construction/composition, and trigonometric transforms).

### Explicit versus absent values
- **D-03:** An explicitly supplied malformed, non-finite, out-of-envelope, or unsafe numeric value is a structured SVG error. Only an absent attribute may take the existing SVG default or inheritance path. — **Reversibility:** costly — changing it later would weaken published parser behavior and test fixtures.
- **D-04:** Stable error category/context is required; full diagnostic-message text is not a compatibility contract.

### Valid geometry and rendering ownership
- **D-05:** Retain finite singular transforms such as `scale(0)`; non-invertibility alone is not numeric unsafety.
- **D-06:** `mb-svg` validates numeric input before a `SceneNode` exists. `lower_to_drawing_list` and `mb-canvas` remain total consumers of that validated scene; RFC 0008 opacity/layer behavior is unchanged.

### the agent's Discretion
Choose the exact helper placement and test organization from existing `mb-svg` parser patterns, provided the admission policy stays centralized and target-neutral.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` §Phase 91 — goal, requirement SVGPR-01, and observable success criteria.
- `.planning/REQUIREMENTS.md` §SVGPR-01 — required numeric admission and route-matrix result.
- `.planning/research/SUMMARY.md` — validated seams, risks, phase ordering, and explicit scope boundaries.

### SVG and canvas boundaries
- `docs/rfcs/0002-mb-svg.md` §6.1, §8.1, §11.1 — bounded SVG subset, checked-coordinate residual gap, and evidence expectations.
- `docs/rfcs/0008-mb-canvas-layer.md` §5, §7, §10 — isolated layer semantics and 16-layer capability boundary that must not be altered.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-svg/svg/length.mbt`: current length/viewBox numeric parsing seam.
- `modules/mb-svg/svg/transform.mbt`: transform grammar and affine creation seam.
- `modules/mb-svg/svg/path_data.mbt`: path-number scanner and relative-coordinate derivation seam.
- `modules/mb-svg/svg/scene.mbt`: attribute/default/inheritance combinator and SceneNode boundary.

### Established Patterns
- Parser APIs return `Result[..., @error.CoreError]`; the route matrix should preserve structured error flow rather than rely on panics or string snapshots.
- `lower_to_drawing_list` consumes a typed scene; the safety invariant belongs before lowering.

### Integration Points
- Phase 92 will consume the contract through `length.mbt`, `transform.mbt`, `path_data.mbt`, and `scene.mbt`, then use existing lower/raster fixtures for no-partial-result proof.

</code_context>

<specifics>
## Specific Ideas

No specific UI or product requirements — use the documented portable parser and test conventions.

</specifics>

<deferred>
## Deferred Ideas

None — SVG feature expansion, layer optimization, and native acceleration remain outside v0.30.

</deferred>

---

*Phase: 91-SVG Numeric Contract*
*Context gathered: 2026-07-25*
