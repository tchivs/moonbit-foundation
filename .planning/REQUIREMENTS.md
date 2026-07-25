# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-26
**Milestone:** v0.31 SVG Numeric Boundary Unification
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.31 Requirements

### Shared Geometry Boundary

- [ ] **SVGUNI-01**: Library consumers receive unchanged valid SVG scene and drawing-list behavior while parser preflight and lowering obtain transform, viewBox, shape, and path geometry facts from one checked internal implementation.
- [ ] **SVGUNI-02**: Explicit unsafe or derived-overflow SVG geometry returns the established structured error before a scene, drawing list, or raster operation is published, regardless of whether it reaches the parser or lowerer boundary.

### Compatibility Qualification

- [ ] **SVGUNI-03**: Maintainers have deterministic regression controls that detect parser/lowerer numeric-boundary divergence while preserving valid finite singular transforms and RFC 0008 opacity/layer behavior on wasm, wasm-gc, js, and native.

## Future Requirements

### SVG Surface Expansion

- **SVGNEXT-01**: SVG text, gradients, masks, filters, `<use>`, animation, broader XML/CSS, and percentage resolution remain separate capability milestones after the numeric boundary is unified.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New SVG elements or styling features | This milestone removes a maintenance seam; it does not expand the public SVG surface. |
| Native acceleration, FFI, or a second rasterizer | The goal is portable semantic unification, not a backend rewrite. |
| New numeric limits or public error schema | v0.30 already established these contracts; this milestone must preserve them. |
| Cross-target timing comparisons | Portable qualification proves correctness/buildability, not comparable timing. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SVGUNI-01 | TBD | Pending |
| SVGUNI-02 | TBD | Pending |
| SVGUNI-03 | TBD | Pending |

**Coverage:**
- v0.31 requirements: 3 total
- Mapped to phases: 0
- Unmapped: 3 (roadmap pending)

---
*Requirements defined: 2026-07-26*
*Last updated: 2026-07-26 after v0.31 scope definition*
