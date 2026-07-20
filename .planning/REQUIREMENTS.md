# Requirements: v0.4 Portable Image Interchange

**Defined:** 2026-07-20
**Milestone:** v0.4 Portable Image Interchange
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.4 Requirements

### QOI Format Core

- [x] **QOI-01**: A library user can probe a QOI input without consuming it and receives deterministic no-match or need-more outcomes for incomplete prefixes.
- [x] **QOI-02**: A library user can decode a valid QOI 1.0 RGB or RGBA image into a portable owned image with exact pixel semantics.
- [x] **QOI-03**: A library user can encode a compatible RGB or straight-RGBA image as canonical QOI bytes and recover the same pixels through decoding.

### Safety and Conformance

- [x] **QOI-04**: A library user receives typed, deterministic errors for malformed headers, truncated chunks, invalid end markers, trailing data, resource limits, and underlying I/O failures without partial output allocation or budget mutation on preflight rejection.
- [x] **QOI-05**: Maintainers can verify spec-derived QOI opcode, wraparound, index, run, and byte-round-trip vectors on js, wasm, wasm-gc, and native targets.

### Public Evidence

- [x] **QOI-06**: A library user can run one public portable example that decodes QOI, applies an existing image operation, and encodes QOI with deterministic output evidence.

## Future Requirements

### Quality and Delivery

- **QOI-07**: Maintainers can reproduce native QOI decode/encode benchmark baselines after the codec behavior is frozen.
- **QOI-08**: A library user can use forward-only streaming QOI APIs with explicit partial-read and partial-write state.
- **CODEC-02**: A library user can decode and encode a heavyweight lossless interchange format with an independently reviewed scope and security model.

## Out of Scope

| Feature | Reason |
|---------|--------|
| PNG/DEFLATE | A larger parser and compression surface should follow only after QOI establishes the portable codec pattern. |
| FFI-backed codec implementation | v0.4 must exercise MoonBit-native algorithms and stay portable. |
| Streaming QOI API | Stateful partial-I/O semantics are a distinct contract and will not be hidden behind an eager decoder. |
| Release automation | Code and test evidence remain the milestone priority. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| QOI-01 | Phase 13 | Complete |
| QOI-02 | Phase 13 | Complete |
| QOI-03 | Phase 14 | Complete |
| QOI-04 | Phase 13 | Complete |
| QOI-05 | Phase 14 | Complete |
| QOI-06 | Phase 15 | Complete |

**Coverage:**

- v0.4 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0

---
*Requirements defined: 2026-07-20*
*Last updated: 2026-07-20 after v0.4 roadmap creation*
