# v0.21 Requirements — RGBA16 PNG Decode

## Active Requirements

### Packed high-precision representation

- [x] **RGBA16DEC-01**: Library users can construct and inspect a checked packed little-endian, straight-alpha `rgba16` image representation without changing existing `rgba8` or `graya16` contracts.

### Explicit Type-6/16 preservation

- [x] **RGBA16DEC-02**: Library users can call `PngDecoder::decode_rgba16` for legal encoded-sRGB Type-6/16 PNG input and receive every `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo` source byte as `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`; generic decoding remains frozen as `RGBA8(Rhi,Ghi,Bhi,Ahi)`.

### Shared resumable semantics

- [x] **RGBA16DEC-03**: Library users can select `PngChunkDecoder::new_rgba16` for the same legal Type-6/16 input, reusing the bounded decoder machine and preserving eager-equivalent result, accepted-only progress, atomic failure, and sticky terminals under hostile schedules.

### Portable qualification

- [x] **RGBA16DEC-04**: Independent Type-6/16 wire vectors cover filters, Adam7, metadata/resource rejection, frozen generic RGBA8 behavior, and the ordinary full PNG package pass on wasm, wasm-gc, js, and native.

## Future Requirements

- **RGBA16DEC-COLOR**: Add colour-managed or non-sRGB Type-6/16 conversion only after a distinct colour-transform contract.
- **RGBA16DEC-CONVERT**: Add public high-precision conversion APIs only when a downstream consumer requires them.

## Out of Scope

- Generic decoder result widening, implicit conversion, premultiplication, image-sized staging, alternate decoder machines, big-endian storage, FFI, release automation, target wrappers, and copied-source workflows.

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| RGBA16DEC-01 | Phase 65 | Not started |
| RGBA16DEC-02 | Phase 66 | Not started |
| RGBA16DEC-03 | Phase 67 | Not started |
| RGBA16DEC-04 | Phase 68 | Not started |
