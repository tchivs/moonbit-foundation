# Phase 93: SVG Compatibility & Portable Qualification - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the existing supported `mb-svg` subset across `js`, `wasm`, `wasm-gc`, and `native`: valid finite SVG must retain deterministic lowering and raster output, and group/element opacity must preserve RFC 0008 isolated-layer semantics through the established 16-layer canvas boundary. This phase adds compatibility evidence and narrowly fixes any demonstrated portability regression; it does not change SVG surface area, the numeric admission envelope, or canvas rendering policy.

</domain>

<decisions>
## Implementation Decisions

### Portable compatibility evidence
- **D-01:** Use a compact, curated finite SVG fixture matrix and assert deterministic drawing-operation structure plus semantic raster pixels on all four production targets. Do not use target-specific snapshots, host-dependent binary encodings, or cross-target timing assertions. — **Reversibility:** costly — the fixture matrix is the public evidence for SVGPR-03 across the supported targets.
- **D-02:** Keep parser rejection/no-partial-result checks as portable controls alongside valid-fixture qualification, but do not reopen Phase 92 numeric-policy design unless a target-specific regression proves it necessary.

### Opacity and layer semantics
- **D-03:** Treat RFC 0008 isolated layers as the canonical opacity contract: group and element `opacity` wrap the affected subtree/element using balanced `PushLayer`/`PopLayer`; `fill-opacity` and `stroke-opacity` remain per-paint alpha. Verify mixed fill/stroke and nested group/element cases by operations and raster outcome. — **Reversibility:** costly — changing this would alter public rendering semantics and RFC 0008 conformance.
- **D-04:** Test composition semantically at selected stable pixels (including transparent/opaque backdrop cases) rather than merely counting layer operations, while retaining operation-order assertions to make diagnostics precise.

### Capacity boundary
- **D-05:** Preserve the current 16 nested raster-layer capability exactly: documents within the limit render normally; the 17th layer produces the established raster capacity error. Do not clamp, flatten, recover partially, or redesign layer allocation in this phase. — **Reversibility:** costly — the limit is an RFC 0008 resource contract shared by canvas and SVG callers.

### the agent's Discretion
Choose fixture data, exact stable pixel coordinates, package/test-file placement, and whether qualification needs small test-only helpers, provided all assertions are deterministic on `js`, `wasm`, `wasm-gc`, and `native` and production opacity policy remains unchanged.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and prior safety contract
- `.planning/ROADMAP.md` §Phase 93 — goal, SVGPR-03, and observable success criteria.
- `.planning/REQUIREMENTS.md` §SVGPR-03 — portable deterministic lowering/raster and layer-capacity requirement.
- `.planning/phases/91-svg-numeric-contract/91-CONTEXT.md` — target-neutral admission and ownership boundary.
- `.planning/phases/92-fail-closed-svg-parsing/92-CONTEXT.md` — failure/no-partial-result semantics that qualification must retain.
- `.planning/phases/92-fail-closed-svg-parsing/92-VERIFICATION.md` — verified parser and bounded-input baseline.

### SVG and canvas rendering contract
- `docs/rfcs/0002-mb-svg.md` §6.1, §8.1, §11.1 — supported SVG subset and conformance expectations.
- `docs/rfcs/0008-mb-canvas-layer.md` §5, §7, §10 — isolated opacity layer semantics and 16-layer capacity boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-svg/svg/lower.mbt`: production lowering seam that emits `PushLayer`/`PopLayer` for group and element opacity.
- `modules/mb-svg/svg/lower_wbtest.mbt`: operation-order controls for group, element, and nested opacity.
- `modules/mb-svg/svg/conformance_wbtest.mbt`: compact valid-SVG parse-to-lower fixture pattern.
- `modules/mb-canvas/canvas/rasterize.mbt` and `render_wbtest.mbt`: portable rasterizer and existing layer compositing/depth controls.

### Established Patterns
- Public black-box tests prove parser/no-partial contract; `*_wbtest.mbt` protects stable operation and pixel-level representation behavior.
- Drawing lists are portable data; raster pixel tests should use explicit small fixtures and semantic channel assertions.

### Integration Points
- `parse_svg` → `lower_to_drawing_list` → `@canvas.rasterize` is the qualification path.
- SVG-produced nested opacity must hit the same `MAX_LAYER_DEPTH` enforcement used by direct canvas drawing lists.

</code_context>

<specifics>
## Specific Ideas

Auto-selected implementation choices: combine operation-order and raster-pixel evidence; preserve the existing layer limit/error rather than adding a policy change; use all four production targets as required gates.

</specifics>

<deferred>
## Deferred Ideas

None — SVG surface expansion, image-sized layer optimizations, native acceleration, and benchmark timing methodology remain outside this phase.

</deferred>

---

*Phase: 93-SVG Compatibility & Portable Qualification*
*Context gathered: 2026-07-26*
