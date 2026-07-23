# v0.24 Requirements — Indexed PNG Encode

**Defined:** 2026-07-24
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.24 Requirements

### Indexed source and eager output

- [ ] **INDEX-01**: Library users can construct a dedicated immutable Indexed8 PNG source with a validated RGB palette and canonical unpacked index raster.
- [ ] **INDEX-02**: Library users can eagerly emit bounded non-interlaced Type-3/8 PNG with exact IHDR, PLTE, IDAT, and IEND framing and atomic rejection.

### Transparency and resumable semantics

- [ ] **INDEX-03**: Indexed sources with palette alpha emit canonical optional tRNS and decode publicly as RGB8 or RGBA8 with exact palette semantics.
- [ ] **INDEX-04**: Caller-buffered indexed output shares the bounded layout machine, has eager-identical bytes under hostile capacities, preserves lease ownership, and retains sticky terminals.

### Portable qualification

- [ ] **INDEX-05**: Independent indexed wire/decode vectors, hostile lifecycle evidence, frozen legacy compatibility, and the ordinary full PNG package pass cover wasm, wasm-gc, js, and native.

## Future Requirements

- **GRAYPACK-A7**: Add explicit low-bit grayscale Adam7 encoding only after the packed-pass traversal has its own bounded contract.
- **INDEXLOWBIT**: Add Indexed PNG depths 1/2/4 only after the Indexed8 layout and caller-buffered contracts are stable.
- **INDEXADAM7**: Add indexed Adam7 only after packed indexed pass traversal has its own bounded contract.

## Out of Scope

- Implicit quantization, scaling, dithering, a bit-packed `ImageFormat`, generic constructor widening, Indexed1/2/4, indexed Adam7, staging buffers, FFI, release automation, target wrappers, and copied-source workflows.

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| INDEX-01 | Phase 76 | Pending |
| INDEX-02 | Phase 76 | Pending |
| INDEX-03 | Phase 77 | Pending |
| INDEX-04 | Phase 78 | Pending |
| INDEX-05 | Phase 78 | Pending |

**Coverage:**

- v0.24 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-24*
