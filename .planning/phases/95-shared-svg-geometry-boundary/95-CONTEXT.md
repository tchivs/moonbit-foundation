# Phase 95: Shared SVG Geometry Boundary - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Make parser preflight and lowering obtain transform, viewBox, shape, and path geometry facts from one internal checked seam while preserving every valid SVG scene/drawing-list behavior established through v0.30. This phase removes duplicated arithmetic; it does not add SVG features, change numeric limits or public error facts, or redesign canvas layers.

</domain>

<decisions>
## Implementation Decisions

### Shared-geometry ownership
- **D-01:** Establish one package-private checked geometry seam as the authority for viewBox mapping, affine/point derivation, and supported shape/path construction facts. Parser preflight and lowering must consume that seam rather than maintain parallel arithmetic. — **Reversibility:** costly — reintroducing local geometry formulas would recreate the drift class that this milestone removes.
- **D-02:** Keep `parse_svg` as the public fail-closed publication boundary and preserve `lower_to_drawing_list` as the established total public consumer. The internal seam may expose checked facts, but Phase 95 must not add a public `Result` API or change behavior for valid scenes. — **Reversibility:** costly — public parser timing and lowerer totality are compatibility contracts already qualified across four targets.

### Numeric and rendering compatibility
- **D-03:** Preserve the v0.30 `[-65536.0, 65536.0]` finite envelope, existing structured source/derived error categories, omitted-attribute defaults, and acceptance of finite singular transforms such as `scale(0)`. — **Reversibility:** costly — these are externally observable parsing contracts.
- **D-04:** Preserve RFC 0008 group/element opacity ordering and the 16-layer capability boundary exactly; the shared geometry refactor must not alter layer operations, paint opacity, or raster semantics. — **Reversibility:** costly — changing these would break the existing SVG/canvas rendering contract.

### Regression evidence
- **D-05:** Reuse compact valid transform/viewBox/shape/path fixtures and semantic drawing-list assertions. Prove the new shared seam structurally through focused white-box controls, not source-text duplication checks or target-specific snapshots.

### the agent's Discretion

Choose internal type/function names, factor boundaries, and test-file placement from existing `mb-svg` patterns. The planner may split mechanical extraction from compatibility proof, provided both parser preflight and lowering consume the same seam by phase completion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and prior verified contract
- `.planning/ROADMAP.md` §Phase 95 — goal, SVGUNI-01, and observable success criteria.
- `.planning/REQUIREMENTS.md` §SVGUNI-01 — exact shared-boundary requirement.
- `.planning/milestones/v0.30-phases/92-fail-closed-svg-parsing/92-CONTEXT.md` — numeric envelope, no-partial-publication contract, lowerer totality, and singular-transform compatibility.
- `.planning/milestones/v0.30-phases/93-svg-compatibility-portable-qualification/93-CONTEXT.md` — portable operation/raster qualification and RFC 0008 opacity/layer compatibility controls.
- `.planning/milestones/v0.30-MILESTONE-AUDIT.md` — known parser-preflight/lowerer drift risk motivating this maintenance milestone.

### Public policy and renderer contracts
- `docs/policies/svg-numeric-admission.md` — documented target-neutral numeric envelope and ingress/derivation contract.
- `docs/rfcs/0002-mb-svg.md` §6.1, §8.1, §11.1 — supported SVG subset and conformance expectations.
- `docs/rfcs/0008-mb-canvas-layer.md` §5, §7, §10 — isolated opacity and 16-layer capability contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-svg/svg/scene.mbt`: `parse_svg` and its parser-side preflight walker currently enforce derived numeric admission before `SceneNode` publication.
- `modules/mb-svg/svg/lower.mbt`: total scene-to-drawing-list lowering owns the matching viewBox and shape/path arithmetic.
- `modules/mb-svg/svg/numeric_contract_wbtest.mbt`: focused target-neutral numeric boundary controls.
- `modules/mb-svg/svg/lower_wbtest.mbt` and `modules/mb-svg/svg/conformance_wbtest.mbt`: stable operation-order and valid parse-to-lower fixture patterns.

### Established Patterns
- Parsing uses `Result[..., @error.CoreError]`; invalid explicit or derived values fail before a public scene exists.
- Public `*_test.mbt` covers external behavior; focused `*_wbtest.mbt` protects internal representations and deterministic route controls.

### Integration Points
- The geometry seam lies between `parse_svg` preflight in `scene.mbt` and `lower_to_drawing_list` in `lower.mbt`; it must remain within the portable `mb-svg` module and keep dependencies acyclic.

</code_context>

<specifics>
## Specific Ideas

Auto-selected maintenance policy: share the checked geometry implementation while leaving the externally visible parser/lowerer API and v0.30 semantic contract unchanged.

</specifics>

<deferred>
## Deferred Ideas

None — new SVG elements, CSS/XML expansion, native acceleration, a second rasterizer, benchmark thresholds, and layer-policy changes remain outside this phase.

</deferred>

---

*Phase: 95-Shared SVG Geometry Boundary*
*Context gathered: 2026-07-26*
