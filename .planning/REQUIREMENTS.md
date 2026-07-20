# Requirements: v0.3 Image Processing Core

**Defined:** 2026-07-20  
**Milestone:** v0.3 Image Processing Core  
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.3 Requirements

### Geometry

- [ ] **GEOM-01**: A library user can crop an image into a checked rectangular result without out-of-bounds access or integer-overflow allocation.
- [ ] **GEOM-02**: A library user can flip an image horizontally or vertically and rotate it by right angles while preserving pixel semantics.
- [ ] **GEOM-03**: A library user can resize an image deterministically with a documented nearest-neighbor reference algorithm across all supported targets.

### Raster Operations

- [ ] **RASTER-01**: A library user can composite one RGBA image over another using documented, alpha-correct source-over semantics.
- [ ] **RASTER-02**: A library user can apply deterministic grayscale and box-blur filters with checked dimensions and bounded intermediate storage.
- [ ] **RASTER-03**: A library user receives typed, deterministic errors for unsupported formats, invalid regions, incompatible dimensions, and resource limits.

### Integration and Evidence

- [ ] **INTEG-01**: A library user can run one public example that composes geometry and raster operations before encoding a PPM result.
- [ ] **INTEG-02**: Public behavioral and adversarial tests validate the new API on js, wasm, wasm-gc, and native targets.
- [ ] **INTEG-03**: Maintainers can reproduce a declared benchmark workload for resize and compositing without introducing release automation.

## Future Requirements

### Codecs and Quality

- **CODEC-01**: A library user can decode and encode a lossless interchange format beyond reference PPM.
- **RESIZE-01**: A library user can select higher-quality interpolation kernels.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Registry publication automation | Deferred; it is not required to implement or validate image-processing capabilities. |
| GPU acceleration | Portable reference behavior and API contracts must stabilize first. |
| Arbitrary-angle rotation | Requires resampling policy beyond this milestone's right-angle geometry contract. |
| Full Photoshop-style editing UI | MNF supplies reusable infrastructure, not an end-user application. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GEOM-01 | TBD | Pending |
| GEOM-02 | TBD | Pending |
| GEOM-03 | TBD | Pending |
| RASTER-01 | TBD | Pending |
| RASTER-02 | TBD | Pending |
| RASTER-03 | TBD | Pending |
| INTEG-01 | TBD | Pending |
| INTEG-02 | TBD | Pending |
| INTEG-03 | TBD | Pending |

**Coverage:**
- v0.3 requirements: 9 total
- Mapped to phases: 0
- Unmapped: 9 (roadmap pending)

---
*Requirements defined: 2026-07-20*
*Last updated: 2026-07-20 after switching to code-first implementation*
