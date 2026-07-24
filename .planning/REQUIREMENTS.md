# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-24
**Milestone:** v0.29 Indexed Adam7 Compression Profiles
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.29 Requirements

### Indexed Adam7 API and compatibility

- [ ] **ADAM7COMP-01**: Library users can explicitly select `Stored` or `FixedOrStored` for Adam7 Type-3/1, /2, /4, and /8 eager and caller-buffered encoding; existing/default indexed interlace APIs remain byte-identical Stored/filter-None forwards, and non-interlaced v0.28 selectors remain unchanged.

### Pass-aware bounded compression contract

- [ ] **ADAM7COMP-02**: The Adam7 `FixedOrStored` route derives canonical pass-local filter-None packed rows through one bounded producer and emits an exact Fixed DEFLATE block only when its complete Type-3 frame is no larger than Stored, without image/pass/output staging, a second encoder, broader matching, or a generic source-model change.

### Atomic admission and shared machine

- [ ] **ADAM7COMP-03**: Before writer bytes, caller lease exposure, or budget mutation, selected-depth Adam7 geometry, actual PLTE, shortest canonical tRNS, Stored/Fixed frame facts, and pass-aware work are checked atomically; exact limits admit one budget charge and one established acknowledged machine.

### Hostile streaming and independent qualification

- [ ] **ADAM7COMP-04**: Adam7 Fixed winners and Stored fallbacks reproduce fresh eager bytes under zero-capacity, one-byte, and ragged leases with accepted-only progress and untouched rejected tails; released leases, replay-work drift, and post-finish pulls are sticky zero-write outcomes.
- [ ] **ADAM7COMP-05**: Independent test-local parsing of eager and collected Adam7 Type-3 bytes proves seven-pass framing, Fixed/Stored DEFLATE, PLTE/tRNS canonicalisation, packed-row tails, Adler/CRCs, public RGB8/RGBA8 decode, frozen legacy vectors, and the ordinary PNG package gate on native, wasm, wasm-gc, and js.

## Future Requirements

- **ADAM7COMP-FUTURE-01**: Consider Dynamic indexed DEFLATE only after a separately scoped strict-win contract and compatibility plan are approved.
- **ADAM7COMP-FUTURE-02**: Consider adaptive indexed filtering only after a separately scoped packed-pass filtering and compression interaction contract.
- **ADAM7COMP-FUTURE-03**: Consider wider indexed matching or a 32 KiB dictionary only after bounded work and replay ownership remain explicit.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dynamic indexed DEFLATE, adaptive indexed filtering, or broader matching | v0.29 extends only the already qualified Fixed-or-Stored contract to Adam7. |
| Generic indexed-model widening, palette generation, quantization, dithering, scaling, or decoder changes | The milestone consumes the existing canonical unpacked indexed source and public decoder. |
| Image/pass/output staging, alternate encoders, FFI, target wrappers, registry publication, or release automation | None is needed for this bounded portable capability. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADAM7COMP-01 | Phase 88 | Pending |
| ADAM7COMP-02 | Phase 89 | Pending |
| ADAM7COMP-03 | Phase 89 | Pending |
| ADAM7COMP-04 | Phase 90 | Pending |
| ADAM7COMP-05 | Phase 90 | Pending |

**Coverage:**

- v0.29 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-07-24 from the v0.28 indexed compression baseline and deferred Indexed Adam7 scope.*
