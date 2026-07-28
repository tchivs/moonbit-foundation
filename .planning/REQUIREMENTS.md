# Requirements: MoonBit Native Foundation v0.33

**Defined:** 2026-07-28
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.33 Requirements

Requirements for the TrueType Collection Adapters milestone. Each requirement maps to exactly one roadmap phase.

### Collection Inspection

- [x] **TTC-01**: Library authors can open caller-provided immutable TTC/OTC version 1 or 2 bytes under explicit collection limits, inspect the exact non-zero face count and bounded semantic profile of each zero-based face, and distinguish absent from structurally present-but-unverified version-2 DSIG data without exposing raw offsets or table records.

### Selected-Face Admission

- [x] **TTC-02**: Library authors can select one in-range static `glyf`-based TrueType face from an admitted collection and receive the existing opaque `Font`, whose metrics, Unicode mapping, kerning, glyph identity, and unhinted outline behavior match the equivalent standalone logical font.
- [x] **TTC-03**: A selected collection face resolves table offsets against the collection root, preserves valid exact cross-face table sharing, enforces collection-specific checksum rules, and remains usable when unsupported CFF/CFF2 or variable siblings are present.

### Safety and Qualification

- [ ] **TTC-04**: Malformed collection structure, invalid face indices, unsupported selected profiles, source mutation, checked-arithmetic failures, semantic-limit exhaustion, and budget exhaustion return deterministic structured outcomes without publishing a partial collection or font or charging an uncommitted transaction.
- [ ] **TTC-05**: Maintainers can reproduce generated hostile, licensed interoperability, standalone-compatibility, and complete public collection-to-`Font` workflow evidence with identical semantic facts on `js`, `wasm`, `wasm-gc`, and `native`.

## Future Requirements

Deferred to later RFC-led milestones.

### Compressed Web Containers

- **WOFF-01**: Library authors can admit bounded WOFF1 data through a pure-MoonBit decompression and table-reconstruction boundary.
- **WOFF-02**: Library authors can admit bounded WOFF2 data through a pure-MoonBit Brotli and transformed-table reconstruction boundary.

### Additional Outline Profiles

- **FONT-06**: Library authors can query CFF/CFF2 outlines through a checked reusable path model.
- **FONT-07**: Library authors can select and instantiate bounded variable-font axes.

## Out of Scope

| Feature | Reason |
|---------|--------|
| WOFF1/WOFF2 decode | Compression and transformed-table reconstruction require a separate dependency and resource model; combining them with TTC offset adaptation would prevent a bounded vertical slice. |
| CFF/CFF2 charstrings | v0.33 adapts containers only and returns the existing static `glyf`-based `Font`. |
| Variable, color, and bitmap font implementation | Each adds independent table semantics and requires its own RFC-led milestone. |
| DSIG cryptographic verification | v0.33 validates only the bounded collection-wide envelope and makes no authenticity or trust claim. |
| Font discovery, fallback, shaping, bidi, hinting, or rasterization | These are text-system and rendering layers above the reusable font-data foundation. |
| Collection writing, extraction, subsetting, merging, or standalone materialization | The milestone is read-only and no-copy; authoring would introduce a separate serialization contract. |
| Ambient filesystem/network access or host font lookup | Callers continue to provide immutable bytes so behavior remains deterministic and portable. |

## Traceability

Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TTC-01 | Phase 101 | Complete |
| TTC-02 | Phase 102 | Complete |
| TTC-03 | Phase 102 | Complete |
| TTC-04 | Phase 103 | Pending |
| TTC-05 | Phase 103 | Pending |

**Coverage:**

- v0.33 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-07-28*
*Last updated: 2026-07-28 after v0.33 roadmap creation*
