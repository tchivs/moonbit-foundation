# v0.25 Requirements — Indexed Low-Bit PNG Encode

**Defined:** 2026-07-24
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.25 Requirements

### Explicit low-bit eager output

- [x] **INDEXLOW-01**: Library users can explicitly encode a valid `PngIndexedImage` as bounded non-interlaced Type-3 PNG at bit depth 1, 2, or 4 while retaining canonical unpacked source indices.
- [x] **INDEXLOW-02**: Depth-specific Indexed PNG preflight enforces PLTE capacities 2/4/16 and checked packed-row/frame resource admission atomically before output or budget mutation.
- [x] **INDEXLOW-03**: Low-bit Indexed output has MSB-first, zero-tailed packed rows, preserves PLTE and canonical optional tRNS, and publicly decodes as exact RGB8 or RGBA8.

### Caller-buffered parity and qualification

- [x] **INDEXLOW-04**: Caller-buffered low-bit Indexed output reuses the bounded eager machine and remains byte-identical under hostile capacities, preserves lease ownership, and retains sticky terminals.
- [x] **INDEXLOW-05**: Independent low-bit wire/decode vectors, hostile lifecycle proof, Indexed8 and legacy compatibility, and the ordinary PNG package pass cover wasm, wasm-gc, js, and native.

## Future Requirements

- **INDEXADAM7**: Add indexed Adam7 only after packed indexed pass traversal has its own bounded contract.
- **INDEXCOMPRESS**: Consider Indexed low-bit filter/compression choices only after the fixed Stored/None profile is proven stable.

## Out of Scope

- Implicit quantization, scaling, dithering, a bit-packed public image model, generic constructor widening, indexed Adam7, strategy expansion, image-sized staging buffers, FFI, target wrappers, copied source trees, and release automation.

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| INDEXLOW-01 | Phase 79 | Complete |
| INDEXLOW-02 | Phase 79 | Complete |
| INDEXLOW-03 | Phase 79 | Complete |
| INDEXLOW-04 | Phase 80 | Complete |
| INDEXLOW-05 | Phase 80 | Complete |

**Coverage:**

- v0.25 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-24*
