# Requirements: v0.18 GrayAlpha16 Adam7 PNG

**Defined:** 2026-07-23
**Core Value:** MoonBit developers can use the existing U16 Gray+Alpha model for portable, bounded interlaced PNG output without rebuilding a second encoder or weakening frozen non-interlaced contracts.

## v0.18 Requirements

### Adam7 Type-4/16 Encoding

- [x] **GRAYA16A7-01**: A library user can select explicit eager and caller-buffered Adam7 factories for a legal packed U16 Gray+Alpha image and receive an interlaced PNG with bit depth 16, colour type 4, and pass samples serialized as `Ghi,Glo,Ahi,Alo`.

### Bounded Streaming Semantics

- [x] **GRAYA16A7-02**: GrayAlpha16 Adam7 encoding reuses the shared bounded preflight, pass filtering, Stored/FixedOrStored/DynamicOrFixedOrStored planning, and acknowledgement-safe replay path; incompatible inputs and resource failures remain atomic before output or lease exposure.

### Portable Public Evidence

- [x] **GRAYA16A7-03**: Generated multi-pass GrayAlpha16 Adam7 PNGs prove public pass-aware wire fidelity and documented RGBA8 high-byte decode canonicalization; zero, one-byte, and ragged caller capacities remain eager-byte-identical with accepted-only progress and sticky terminals; frozen non-interlaced and legacy vectors remain unchanged on js, wasm, wasm-gc, and native.

## Future Requirements

- **GRAYA16A7-COLOR**: Revisit high-precision colour and alpha conversion only through an explicit decoder-contract milestone.

## Out of Scope

- Big-endian GrayAlpha16 descriptor admission, alternate encoder pipelines, image-sized staging, colour conversion, decoder model widening, palette/low-bit formats, native FFI, release automation, registry publication, and copied-source workflows.

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| GRAYA16A7-01 | Phase 56 | Planned |
| GRAYA16A7-02 | Phase 57 | Planned |
| GRAYA16A7-03 | Phase 58 | Planned |

**Coverage:**

- v0.18 requirements: 3 total
- Mapped to phases: 3
- Unmapped: 0
