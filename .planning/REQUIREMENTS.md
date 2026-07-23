# v0.22 Requirements — RGBA16 PNG Encode

**Defined:** 2026-07-23
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.22 Requirements

### Explicit Type-6/16 encoding

- [ ] **RGBA16ENC-01**: Library users can explicitly encode a checked packed little-endian, straight-alpha `rgba16` image as a legal non-interlaced Type-6/16 PNG whose big-endian wire samples preserve every component byte, without changing legacy RGB8/RGBA8 output.

### Shared resumable semantics

- [x] **RGBA16ENC-02**: Library users can select a caller-buffered RGBA16 encoder that reuses the bounded encoder machine, has eager-identical bytes under hostile capacities, retains accepted-only lease progress and sticky typed terminals, and exposes no partial output before atomic admission succeeds.

### Adam7 output

- [x] **RGBA16ENC-03**: Library users can explicitly select legal Type-6/16 Adam7 PNG output from `rgba16` sources while preserving every U16 lane, existing filter/compression choices, and frozen non-interlaced behavior.

### Portable qualification

- [ ] **RGBA16ENC-04**: Independent wire and decode vectors cover normal and Adam7 source fidelity, hostile capability/resource/lease failures, frozen legacy compatibility, and the ordinary full PNG package on wasm, wasm-gc, js, and native.

## Future Requirements

- **RGBA16ENC-COLOR**: Add color-managed or non-sRGB Type-6/16 encoding only with a separate colour-transform contract.
- **RGBA16ENC-CONVERT**: Add public high-precision conversion APIs only when a downstream consumer needs them.

## Out of Scope

- Generic encoder output changes, implicit conversion, premultiplication, image-sized staging, alternate encoder machines, big-endian source storage, FFI, release automation, target wrappers, and copied-source workflows.

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| RGBA16ENC-01 | Phase 69 | Pending |
| RGBA16ENC-02 | Phase 70 | Complete |
| RGBA16ENC-03 | Phase 71 | Complete |
| RGBA16ENC-04 | Phase 72 | Pending |

**Coverage:**

- v0.22 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-23*
*Last updated: 2026-07-23 after initial definition*
