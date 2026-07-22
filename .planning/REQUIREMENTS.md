# Requirements: MoonBit Native Foundation v0.15

## Gray16 PNG Interchange

- [ ] **GRAY16-01**: A library user can encode an existing packed `ChannelOrder::Gray`, `ComponentType::U16` image through explicit eager and caller-buffered factories as a standards-compliant non-interlaced PNG with color type 0, bit depth 16, and big-endian sample bytes, without changing Gray8/RGB8/RGBA8 bytes or behavior.
- [x] **GRAY16-02**: Gray16 eager and caller-buffered encoding uses the existing bounded preflight, None/Adaptive filtering, Stored/FixedOrStored/DynamicOrFixedOrStored planning, output/work/budget admission, and acknowledgement-safe replay path before output is observable; unsupported Gray16 Adam7 and noncanonical inputs fail atomically.
- [ ] **GRAY16-03**: Generated Gray16 cases prove both 16-bit wire-sample preservation and documented public decode canonicalization, caller-buffered eager-byte identity under zero/one/ragged capacities, frozen Gray8/RGB8/RGBA8 compatibility, and independent js/wasm/wasm-gc/native execution.

## Deferred

- Palette/indexed encoding, Gray low-bit packing, grayscale transparency conversion, Gray16 Adam7, Gray+alpha output, RGB/RGBA16 output, registry publication, release scripts, and external package mutation remain out of this code-first milestone.

## Traceability

| Requirement | Phase | Status |
| --- | --- | --- |
| GRAY16-01 | Phase 47 | Pending |
| GRAY16-02 | Phase 48 | Complete |
| GRAY16-03 | Phase 49 | Pending |
