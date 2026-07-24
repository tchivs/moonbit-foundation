# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-24
**Milestone:** v0.27 Low-Bit Indexed Adam7 PNG Encode
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.27 Requirements

### Packed low-bit Adam7 machine and eager contract

- [x] **INDEXLOWADAM7-01**: Library users can explicitly encode an existing canonical unpacked `PngIndexedImage` as a bounded Type-3 Adam7 PNG at selected depth 1, 2, or 4 through additive eager and caller-buffered selectors, while existing `encode_indexed` and `new_indexed` remain explicit non-interlaced forwards and every legacy Indexed1/2/4 and Indexed8 byte vector stays unchanged.
- [x] **INDEXLOWADAM7-02**: Low-bit Adam7 traversal derives every nonempty pass's checked local width, height, and packed row bytes from the selected-depth shared seven-pass geometry, emits a filter-None byte per pass row, and packs canonical source indices MSB-first from pass-local coordinates with deterministic zero tails, without a packed source model, second encoder, or image/pass/output staging.
- [x] **INDEXLOWADAM7-03**: Type-3/1, /2, and /4 Adam7 output preserves exact `IHDR → PLTE → optional canonical tRNS → IDAT → IEND` Stored/filter-None framing: PLTE capacity applies to actual entries, tRNS remains shortest canonical, and every source coordinate publicly decodes to its exact palette RGB8 or RGBA8 value.
- [x] **INDEXLOWADAM7-04**: Selected-depth Adam7 preflight computes checked packed pass totals, Stored IDAT/frame/output/work facts, validates dimensions and palette capacity, applies all limits, and performs exactly one budget charge atomically: exact limits pass while one-less output/work, palette overflow, or arithmetic failure expose no eager bytes or caller lease and do not mutate budget.

### Streaming qualification and portability

- [ ] **INDEXLOWADAM7-05**: Caller-buffered low-bit Adam7 output reuses the one admitted eager machine and is byte-identical under zero-capacity, one-byte, and ragged hostile lease schedules; total progress counts accepted bytes only, rejected sentinel-filled tails remain untouched, released leases replay sticky zero-write failure, and completed pulls are zero-write `Finished` without destination mutation.
- [ ] **INDEXLOWADAM7-06**: For each selected depth, independent test-local parsing of eager and collected chunk-origin bytes proves the Adam7 packed raw raster, tail zeros, framing, CRCs, and public decode; frozen Type-3 low-bit non-interlaced and Indexed8 Adam7 vectors remain unchanged, and the ordinary PNG package gate passes on wasm, wasm-gc, js, and native.

## Future Requirements

- **INDEXCOMPRESS-01**: Consider low-bit indexed filter or compression strategies only after the fixed Stored/None indexed profiles remain stable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Generic indexed-model widening, a packed public source model, quantization, palette generation, dithering, scaling, or decoder changes | This milestone encodes only the existing canonical unpacked indexed source. |
| Additional interlace, filter, or compression strategies | The explicit Adam7 selector and Stored/filter-None wire profile are the bounded compatibility baseline. |
| Image/pass/output staging or a second eager/chunk encoder | The sole acknowledged machine must replay bounded pass-local output directly. |
| FFI, target wrappers, copied source trees, registry publication, or release automation | None is required to implement or qualify this portable library capability. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INDEXLOWADAM7-01 | Phase 83 | Complete |
| INDEXLOWADAM7-02 | Phase 83 | Complete |
| INDEXLOWADAM7-03 | Phase 83 | Complete |
| INDEXLOWADAM7-04 | Phase 83 | Complete |
| INDEXLOWADAM7-05 | Phase 84 | Pending |
| INDEXLOWADAM7-06 | Phase 84 | Pending |

**Coverage:**

- v0.27 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-24 from `research/v027-LOWBIT-ADAM7.md`*
