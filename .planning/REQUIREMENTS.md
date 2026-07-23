# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-24
**Milestone:** v0.26 Indexed8 Adam7 PNG Encode
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.26 Requirements

### Explicit Indexed8 Adam7 output

- [ ] **INDEXADAM7-01**: Library users can explicitly encode a valid `PngIndexedImage` as Type-3/8 Adam7 PNG through additive eager and caller-buffered APIs while legacy `encode_indexed8` and `new_indexed8` retain their non-interlaced signatures and bytes.
- [ ] **INDEXADAM7-02**: Indexed8 Adam7 traversal derives every nonempty pass row from the checked shared Adam7 geometry and reads canonical source indices directly, without a second encoder or image-sized/pass-sized staging.
- [ ] **INDEXADAM7-03**: Indexed8 Adam7 output preserves `IHDR → PLTE → optional canonical tRNS → IDAT → IEND` framing and publicly decodes every palette pixel as exact RGB8 or RGBA8.
- [ ] **INDEXADAM7-04**: Layout-specific scanline, frame, work, output, and budget admission is checked and atomic: exact limits pass, while one-less limits leave eager writers, caller leases, and budgets unchanged.

### Streaming qualification and portability

- [ ] **INDEXADAM7-05**: Caller-buffered Indexed8 Adam7 output reuses the bounded eager machine, remains byte-identical under zero/one/ragged leases, preserves accepted-only progress and untouched tails, and retains sticky terminal behavior.
- [ ] **INDEXADAM7-06**: Independent seven-pass wire evidence, public decode, frozen Indexed8/low-bit compatibility vectors, and the ordinary PNG package gate qualify the feature on wasm, wasm-gc, js, and native.

## Future Requirements

- **INDEXLOWADAM7-01**: Add indexed Type-3/1, /2, and /4 Adam7 only after packed indexed pass traversal has a separately proven bounded contract.
- **INDEXCOMPRESS-01**: Consider low-bit indexed filter or compression strategies only after the fixed Stored/None indexed profiles remain stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Indexed Type-3/1, /2, or /4 Adam7 | Packed pass traversal needs its own bounded contract; this milestone isolates the established Indexed8 representation. |
| Generic image-model widening, quantization, palette generation, dithering, or scaling | The milestone encodes an existing canonical indexed source only. |
| Adaptive filters, Fixed/Dynamic compression, or a second encoder | The fixed Indexed8 profile and sole acknowledged machine are the compatibility and boundedness baseline. |
| Image/pass/output staging, FFI, target wrappers, copied source trees, or release automation | None is needed to deliver or verify this library capability. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INDEXADAM7-01 | Phase 81 | Pending |
| INDEXADAM7-02 | Phase 81 | Pending |
| INDEXADAM7-03 | Phase 81 | Pending |
| INDEXADAM7-04 | Phase 81 | Pending |
| INDEXADAM7-05 | Phase 82 | Pending |
| INDEXADAM7-06 | Phase 82 | Pending |

**Coverage:**

- v0.26 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-24 after Indexed8 Adam7 research*
