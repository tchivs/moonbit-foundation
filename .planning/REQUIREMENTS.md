# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-25
**Milestone:** v0.30 SVG Production Readiness
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.30 Requirements

### Numeric Safety

- [x] **SVGPR-01**: Library users receive a documented, target-neutral SVG numeric admission contract with route-matrix tests for every supported scalar ingress and derived-value path.
- [x] **SVGPR-02**: Library users receive a structured error, with no scene or drawing list produced, when an explicitly supplied SVG coordinate, length, transform, viewBox, path, or paint scalar is non-finite, malformed, out of the accepted envelope, or produces an unsafe derived value.

### Compatibility and Portability

- [x] **SVGPR-03**: Library users retain deterministic lowering and raster output for valid finite SVG, including isolated group/element opacity and the existing 16-layer canvas capability boundary, on `js`, `wasm`, `wasm-gc`, and `native`.

### Benchmark Evidence

- [x] **SVGPR-04**: Maintainers can run three accurately named, correctness-gated `mb-svg` workloads (path parse, transform composition, parse-to-lower) and compare a documented native release baseline without treating cross-target timings as comparable performance.

## Future Requirements

### SVG Surface Expansion

- **SVGNEXT-01**: Library users can render SVG text after `mb-font` and `mb-text` establish their contracts.
- **SVGNEXT-02**: Library users can use gradients, masks, filters, and `<use>` after separate RFC-approved boundaries exist.
- **SVGNEXT-03**: Raster layers can optimize to bounded affected regions after a performance RFC and measured baseline justify it.

## Out of Scope

| Feature | Reason |
|---|---|
| New SVG elements, CSS, text, gradients, masks, filters, animation, or `<use>` | v0.30 hardens the existing subset; feature-surface expansion needs separate contracts. |
| Native acceleration, FFI, or a second rasterizer | Portable MoonBit remains the core implementation and current performance work is evidence, not acceleration. |
| Image-sized layer staging optimizations | RFC 0008 correctness semantics are already implemented; optimization requires measurements and a separate scope decision. |
| Global performance thresholds or cross-target timing comparisons | Host-specific timing is not portable correctness evidence. |
| Registry publication and release automation | No current consumer is blocked by delivery automation. |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| SVGPR-01 | Phase 91 | Complete |
| SVGPR-02 | Phase 92 | Complete |
| SVGPR-03 | Phase 93 | Complete |
| SVGPR-04 | Phase 94 | Complete |

**Coverage:**

- v0.30 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0

---
*Requirements defined: 2026-07-25*
*Last updated: 2026-07-25 after v0.30 roadmap creation*
