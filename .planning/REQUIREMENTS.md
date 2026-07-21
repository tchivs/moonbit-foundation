# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-20
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.7 Requirements

### PNG Colour Semantics

- [x] **PNGCM-01**: A library user receives a typed deterministic rejection for duplicate, late, malformed, or conflicting recognised PNG colour chunks before an image is exposed.
- [x] **PNGCM-02**: A library user can decode a valid `sRGB` declaration into the existing encoded-sRGB image metadata while retaining its rendering intent.
- [ ] **PNGCM-03**: A library user can receive valid `gAMA`, `cHRM`, or `iCCP` declarations as bounded, explicit non-sRGB image metadata rather than having raw samples silently relabelled as sRGB.
- [ ] **PNGCM-04**: A library user receives a typed capability result when a requested PNG operation would require an unavailable colour transform or would discard non-sRGB colour semantics.

### PNG Colour Evidence

- [ ] **PNGCM-05**: Maintainers can verify recognised colour chunk positives, ordering/precedence failures, and bounded profile-expansion failures on js, wasm, wasm-gc, and native.

## Future Requirements

### PNG Extensions

- **PNGX-03**: Provide public resumable PNG streaming APIs after the eager subset is stable.
- **PNGX-04**: Add compression-ratio optimization and benchmarked encoder strategies without changing the canonical baseline implicitly.

## Out of Scope

| Feature | Reason |
|---|---|
| FFI-backed PNG or zlib implementation | v0.6 exercises MoonBit-native algorithms and keeps portable targets aligned. |
| cICP/HDR, APNG, animation, text/EXIF, and full ICC colour transforms | They require separate image/colour-transform contracts; v0.7 retains or rejects semantics rather than inventing transforms. |
| Public PNG push/pull streaming API | Internal incremental parsing is required now; public resumable contracts remain a later compatibility decision. |
| Registry publication, release automation, or credential work | They do not unblock the PNG code path. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PNGCM-01 | Phase 23 | Complete |
| PNGCM-02 | Phase 23 | Complete |
| PNGCM-03 | Phase 24 | Pending |
| PNGCM-04 | Phase 24 | Pending |
| PNGCM-05 | Phase 25 | Pending |

**Coverage:**

- v0.7 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-07-21*
*Last updated: 2026-07-21 after v0.7 PNG Colour Fidelity milestone creation*
