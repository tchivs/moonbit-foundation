# Requirements: MoonBit Native Foundation v0.14

## Gray8 PNG Interchange

- [x] **GRAYPNG-01**: A library user can encode an existing `ChannelOrder::Gray`, 8-bit image as a standards-compliant non-interlaced Gray8 PNG through explicit eager and caller-buffered PNG factories, while every RGB8/RGBA8 factory keeps its existing bytes and behavior.
- [x] **GRAYPNG-02**: Gray8 eager and caller-buffered encoding uses the existing bounded preflight, filtering, Stored/FixedOrStored/DynamicOrFixedOrStored planning, output, work, and budget admission rules before any byte is exposed.
- [ ] **GRAYPNG-03**: Generated Gray8 cases prove public eager decode fidelity, caller-buffered eager-byte identity under zero/one/ragged capacities, frozen RGB/RGBA compatibility, and independent js/wasm/wasm-gc/native execution.

## Deferred

- Palette/indexed PNG encoding, Gray low-bit packing, Gray16 output, transparency conversion, and Gray8 Adam7 are separate additive contracts.
- Registry publication, release scripts, and external package mutation remain out of this code-first milestone.

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| GRAYPNG-01 | Phase 44 | Complete |
| GRAYPNG-02 | Phase 45 | Complete |
| GRAYPNG-03 | Phase 46 | Pending |
