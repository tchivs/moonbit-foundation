# Phase 96: SVG Boundary Parity Qualification - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the shared SVG numeric boundary delivered by Phase 95: unsafe explicit and derived geometry must fail before publication, and deterministic controls must detect parser/lowerer divergence on all supported targets. No SVG feature or public API expansion is in scope.

</domain>

<decisions>
## Implementation Decisions

### Boundary publication controls
- **D-01:** Treat parser-produced `SceneNode`/drawing/raster results as forbidden after an unsafe explicit or derived geometry result; assert the established structured error at the parse boundary.
- **D-02:** Keep `lower_to_drawing_list` total for manually constructed invalid public scene values. Its deterministic empty/identity recovery is a separate compatibility behavior, not a parser-success path.

### Parity qualification
- **D-03:** Use semantic adversarial fixtures and white-box seam controls to prove the parser and lowerer reach identical numeric-boundary outcomes. Do not use source-text duplication checks or timing comparisons.
- **D-04:** Run the final controls under wasm, wasm-gc, js, and native. Assert observable operation/error semantics, not target-specific internal timing.

### Compatibility preservation
- **D-05:** Preserve finite `scale(0)`, valid viewBox/default behavior, and RFC 0008 group opacity/layer behavior as explicit regression controls; no new public API, numeric bound, or error schema.

### the agent's Discretion
- Select the narrowest existing test files and fixtures that cover every geometry family while keeping controls deterministic and target-neutral.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` §Phase 96 — goal and success criteria.
- `.planning/REQUIREMENTS.md` §SVGUNI-02 and §SVGUNI-03 — acceptance contracts and traceability.
- `.planning/PROJECT.md` — project-level numeric, compatibility, and module constraints.

### Established SVG contracts
- `.planning/phases/95-shared-svg-geometry-boundary/95-CONTEXT.md` — shared-seam and total-lowering decisions to preserve.
- `.planning/phases/95-shared-svg-geometry-boundary/95-VERIFICATION.md` — verified Phase 95 behavior and residual cleanup note.
- `docs/rfcs/0008-mb-canvas-layer.md` — opacity and layer lowering contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-svg/svg/geometry.mbt`: package-private checked geometry seam.
- `modules/mb-svg/svg/geometry_wbtest.mbt`, `lower_wbtest.mbt`, and `svg_test.mbt`: established white-box and public semantic test homes.

### Established Patterns
- Parser propagates numeric `Result` errors fail-closed; public lowering adapts only invalid manually built values into deterministic fallbacks.
- `moon test modules/mb-svg/svg --target all --frozen` is the target-neutral package qualification command.

### Integration Points
- `scene.mbt` parser preflight and `lower.mbt` drawing lowering consume the private geometry facts; test additions must observe both without changing the public API.

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond the established compatibility contracts.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 96-svg-boundary-parity-qualification*
*Context gathered: 2026-07-26*
