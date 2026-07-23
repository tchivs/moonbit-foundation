# v0.19 Requirements — GrayAlpha8 Adam7 PNG

## Active Requirements

### Explicit Adam7 factories

- [ ] **GRAYA8A7-01**: Library users can select explicit eager and caller-buffered Adam7 Type-4/8 PNG factories for legal packed straight-alpha GrayAlpha8 sources; existing non-interlaced factories and bytes remain unchanged.

### Bounded shared semantics

- [ ] **GRAYA8A7-02**: Every legal None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored GrayAlpha8 Adam7 selection reuses the shared bounded pass traversal, atomic preflight, filtering, compression, and replay path; checked U8 source mutation fails before any further lease write with a zero-write sticky terminal result.

### Public portable proof

- [ ] **GRAYA8A7-03**: Public non-symmetric Adam7 Type-4/8 wire/decode vectors, fresh zero/one/ragged caller schedules, frozen non-interlaced/legacy vectors, and the full PNG package pass on js, wasm, wasm-gc, and native.

## Future Requirements

- **GRAYA8A7-COLOR**: Revisit colour conversion or decoder-model widening only in a dedicated contract milestone.

## Out of Scope

- Big-endian GrayAlpha16 changes, palette/low-bit formats, image-sized staging, alternate encoders, native FFI, release automation, registry publication, target wrappers, and copied-source workflows.

## Traceability

| Requirement | Planned Phase | Status |
|---|---|---|
| GRAYA8A7-01 | Phase 59 | Planned |
| GRAYA8A7-02 | Phase 60 | Planned |
| GRAYA8A7-03 | Phase 61 | Planned |
