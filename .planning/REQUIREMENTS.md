# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-20
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.6 Requirements

### PNG Structural Safety

- [x] **PNG-01**: A library user can non-consumingly probe a PNG signature and receive deterministic incomplete, unsupported, or invalid outcomes within codec input limits.
- [x] **PNG-02**: A library user receives a typed deterministic rejection for invalid PNG framing, chunk order, chunk CRC, unsupported critical or semantic chunk, incomplete IEND, or trailing input.
- [x] **PNG-03**: A library user receives checked dimension, pixel, input, output, work, allocation, and metadata-policy enforcement before PNG decode exposes an image.

### PNG Decode

- [x] **PNG-04**: A library user can decode non-interlaced 8-bit truecolour RGB and RGBA PNG images with all five PNG filters into existing portable image contracts.
- [x] **PNG-05**: A library user can decode legal zlib streams using stored, fixed-Huffman, or dynamic-Huffman DEFLATE blocks across arbitrary IDAT boundaries while malformed headers, trees, distances, checksums, and expansion attempts fail deterministically.

### PNG Encode and Evidence

- [ ] **PNG-06**: A library user can encode compatible RGB8 or straight-RGBA8 image views to one deterministic PNG byte sequence after eager-equivalent zero-write preflight.
- [ ] **PNG-07**: A library user can run one portable PNG decode → existing image operation → encode workflow, and maintainers can verify fixtures and hostile cases on js, wasm, wasm-gc, and native.

## Future Requirements

### PNG Extensions

- **PNGX-01**: Decode palette, grayscale, transparency, and 16-bit PNG profiles with explicit image-model mapping.
- **PNGX-02**: Support Adam7 interlace and colour-management metadata without silent semantic loss.
- **PNGX-03**: Provide public resumable PNG streaming APIs after the eager subset is stable.
- **PNGX-04**: Add compression-ratio optimization and benchmarked encoder strategies without changing the canonical baseline implicitly.

## Out of Scope

| Feature | Reason |
|---|---|
| FFI-backed PNG or zlib implementation | v0.6 exercises MoonBit-native algorithms and keeps portable targets aligned. |
| APNG, animation, text/EXIF, palette, grayscale, `tRNS`, 16-bit, Adam7, and colour/HDR chunks | They need separate representation and semantic contracts; rejecting them is safer than silently degrading data. |
| Public PNG push/pull streaming API | Internal incremental parsing is required now; public resumable contracts remain a later compatibility decision. |
| Registry publication, release automation, or credential work | They do not unblock the PNG code path. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PNG-01 | Phase 20 | Complete |
| PNG-02 | Phase 20 | Complete |
| PNG-03 | Phase 20 | Complete |
| PNG-04 | Phase 21 | Complete |
| PNG-05 | Phase 21 | Complete |
| PNG-06 | Phase 22 | Pending |
| PNG-07 | Phase 22 | Pending |

**Coverage:**

- v0.6 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-07-20*
*Last updated: 2026-07-20 after v0.6 roadmap creation*
