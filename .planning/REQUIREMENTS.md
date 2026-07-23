# v0.23 Requirements — Low-Bit Grayscale PNG Encode

**Defined:** 2026-07-23
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.23 Requirements

### Explicit packed output

- [x] **GRAYPACK-01**: Library users can explicitly encode canonical opaque Gray/U8 sources whose levels are exactly representable as legal non-interlaced Type-0 PNG depth 1, 2, or 4, with MSB-first packed samples and zero padding bits.
- [x] **GRAYPACK-02**: Unsupported sample levels, descriptors, resource limits, and budgets fail atomically before eager output is exposed.

### Shared resumable semantics

- [x] **GRAYPACK-03**: Library users can select caller-buffered low-bit grayscale output that shares the bounded machine, has eager-identical bytes under hostile capacities, preserves lease ownership, and retains sticky typed terminals.

### Portable qualification

- [x] **GRAYPACK-04**: Independent packed-wire/decode vectors, hostile lifecycle evidence, frozen legacy compatibility, and the ordinary full PNG package pass cover wasm, wasm-gc, js, and native.

## Future Requirements

- **GRAYPACK-A7**: Add explicit low-bit grayscale Adam7 encoding only after the packed-pass traversal has its own bounded contract.
- **INDEXEDENC**: Add explicit indexed PNG writing only with a dedicated palette/index source contract; do not force it into the generic image model.

## Out of Scope

- Implicit quantization, scaling, dithering, a bit-packed `ImageFormat`, generic constructor widening, palette encoding, Adam7 low-bit output, staging buffers, FFI, release automation, target wrappers, and copied-source workflows.

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| GRAYPACK-01 | Phase 73 | Complete |
| GRAYPACK-02 | Phase 73 | Complete |
| GRAYPACK-03 | Phase 74 | Complete |
| GRAYPACK-04 | Phase 75 | Complete |

**Coverage:**

- v0.23 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-23*
