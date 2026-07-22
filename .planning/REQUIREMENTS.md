# Requirements: v0.17 GrayAlpha16 PNG Interchange

**Defined:** 2026-07-23
**Core Value:** MoonBit developers can add high-precision grayscale-plus-alpha PNG handling without rebuilding incompatible U16 models, encoder paths, or portable conformance evidence.

## v0.17 Requirements

### U16 Gray+Alpha Model

- [x] **GRAYA16-01**: A library user can create and inspect a packed U16 grayscale-plus-alpha image with exactly one gray and one straight-alpha component, while existing Gray, GrayAlpha8, RGB, and RGBA descriptor and storage behavior remains unchanged.

### Bounded PNG Encoding

- [x] **GRAYA16-02**: A library user can encode a compatible packed U16 Gray+Alpha image through explicit eager and caller-buffered factories as a standards-compliant non-interlaced PNG with color type 4 and bit depth 16, preserving each source gray/alpha sample as `Ghi,Glo,Ahi,Alo` at the wire boundary.
- [x] **GRAYA16-03**: GrayAlpha16 eager and caller-buffered output reuses the shared bounded preflight, None/Adaptive filtering, Stored/FixedOrStored/DynamicOrFixedOrStored planning, and acknowledgement-safe replay path; unsupported input and resource failures are atomic before output or lease exposure.

### Public Interchange Evidence

- [ ] **GRAYA16-04**: Generated GrayAlpha16 PNGs prove literal U16 wire fidelity and documented public decode canonicalization to straight RGBA8 high bytes; zero, one-byte, and ragged caller capacities remain eager-byte-identical with accepted-only progress and sticky terminals; frozen Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 vectors retain their bytes and all evidence runs independently on js, wasm, wasm-gc, and native.

## Future Requirements

- **GRAYA16-ADAM7**: Add explicit Adam7 GrayAlpha16 encoding only after non-interlaced U16 GrayAlpha public evidence is stable.
- **GRAYA16-COLOR**: Consider high-precision color/alpha conversion only after the current RGBA8 decoder canonicalization boundary is revisited deliberately.

## Out of Scope

- GrayAlpha16 Adam7, palette/low-bit formats, color conversion, ICC/HDR transforms, and decoder model widening.
- Alternative encoder pipelines, image-sized staging buffers, native FFI, platform-specific behavior, release automation, registry publication, and copied-source workflows.

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| GRAYA16-01 | Phase 53 | Complete |
| GRAYA16-02 | Phase 54 | Complete |
| GRAYA16-03 | Phase 54 | Complete |
| GRAYA16-04 | Phase 55 | Pending |

**Coverage:**

- v0.17 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0
