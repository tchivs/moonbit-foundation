# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-24
**Milestone:** v0.28 Indexed PNG Compression Profiles
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.28 Requirements

### Indexed Fixed-or-Stored API and exact wire contract

- [ ] **INDEXCOMP-01**: Library users can explicitly select `Stored` or `FixedOrStored` for non-interlaced Type-3/1, /2, /4, and /8 `PngIndexedImage` eager and caller-buffered encoding; the existing indexed methods and the new `Stored` selection produce byte-identical Stored/filter-None compatibility bytes, while `DynamicOrFixedOrStored` fails before planning or budget charge with a stable unavailable-capability result.
- [ ] **INDEXCOMP-02**: For an explicit indexed `FixedOrStored` request, the encoder derives canonical filter-None indexed raw bytes through one bounded shared raw-byte/match producer and emits an exact Fixed DEFLATE block only when its complete Type-3 PNG frame is no larger than Stored; otherwise it emits Stored, without image/pass/output/token staging, a second encoder, matcher widening, or a generic source-model change.

### Ancillary-aware bounded admission and integration

- [ ] **INDEXCOMP-03**: Before writer progress, caller lease exposure, or budget mutation, the selected non-interlaced indexed profile computes selected-depth geometry, actual PLTE and shortest canonical tRNS framing, and exact Stored/Fixed frame/output/work facts; exact limits admit exactly one budget charge and one-less output/work, palette overflow, or checked-arithmetic failure are atomic.

### Hostile streaming and independent qualification

- [ ] **INDEXCOMP-04**: The admitted indexed Fixed-or-Stored plan uses the existing acknowledged eager and caller-buffered machine so zero-capacity, one-byte, and ragged leases reproduce fresh eager bytes with accepted-only progress and untouched rejected sentinel tails; released leases and replay-accounting failures become sticky zero-write terminal errors, and completed pulls leave destinations unchanged.
- [ ] **INDEXCOMP-05**: Independent test-local parsing of eager and collected chunk-origin Type-3 bytes proves Fixed-or-Stored selection, DEFLATE/wire framing, PLTE/tRNS canonicalisation, filter-None packed raw rows and tails, Adler/CRCs, public RGB8/RGBA8 decode, and frozen legacy vectors; the ordinary PNG package gate passes on wasm, wasm-gc, js, and native.

## Future Requirements

- **INDEXCOMP-FUTURE-01**: Consider Dynamic indexed DEFLATE only after a separately scoped strict-win contract and compatibility plan are approved.
- **INDEXCOMP-FUTURE-02**: Consider adaptive indexed filtering only after it has a separately scoped packed-row and compression interaction contract.
- **INDEXCOMP-FUTURE-03**: Consider Indexed Adam7 compression selection only after the non-interlaced profile has its own qualified compatibility baseline.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dynamic indexed DEFLATE, adaptive indexed filters, or indexed Adam7 compression selection | v0.28 admits only explicit non-interlaced Stored-or-Fixed selection; existing Adam7 paths stay Stored/filter-None. |
| Generic indexed-model widening, a packed public source model, quantization, palette generation, dithering, scaling, or decoder changes | This milestone operates only on the existing canonical unpacked indexed source. |
| A 32 KiB dictionary or broader matching, image/pass/output/token staging, or a second encoder | The existing bounded producer, matcher, and acknowledged machine remain the sole path. |
| FFI, host adapters, target wrappers, copied source trees, registry publication, or release automation | None is needed for this portable library capability. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INDEXCOMP-01 | Phase 85 | Pending |
| INDEXCOMP-02 | Phase 85 | Pending |
| INDEXCOMP-03 | Phase 86 | Pending |
| INDEXCOMP-04 | Phase 87 | Pending |
| INDEXCOMP-05 | Phase 87 | Pending |

**Coverage:**

- v0.28 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-24 from `research/v028-INDEXED-PNG-COMPRESSION.md`; v0.27 requirements remain archived at `milestones/v0.27-REQUIREMENTS.md`.*
