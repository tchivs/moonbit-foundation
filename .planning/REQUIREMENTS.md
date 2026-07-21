# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-22
**Milestone:** v0.10 PNG Compression Optimization
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## PNG Compression Strategy

- [ ] **PNGC-01**: A library user can explicitly request a documented PNG compression strategy while the existing eager and chunk constructors retain their byte-for-byte stored-DEFLATE output.
- [ ] **PNGC-02**: A library user requesting the optimized strategy receives deterministic fixed-Huffman-or-stored PNG output whose construction performs exact capability, geometry, output, work, and budget admission before any byte is exposed.
- [ ] **PNGC-03**: A library user can drain optimized eager and caller-buffered chunk output with exact progress, canonical eager/chunk parity, and unchanged sticky completion/failure semantics on js, wasm, wasm-gc, and native.

## PNG Compression Evidence

- [ ] **PNGC-04**: Maintainers can reproduce a deterministic corpus proving valid decoder round trips and never-larger FixedOrStored output, including a declared compression win for flat RGB8 and RGBA8 images.

## Future Requirements

- **PNGX-05**: Add bounded optional streaming adapters for host I/O only after the caller-buffered contract is stable.
- **PNGX-06**: Consider dynamic Huffman, adaptive filters, or broader match search only after fixed-Huffman evidence establishes a bounded baseline.

## Out of Scope

| Feature | Reason |
|---|---|
| Change the default stored-DEFLATE encoder | Existing eager and chunk byte streams are a documented compatibility baseline. |
| Dynamic Huffman, adaptive filters, or a 32 KiB LZ77 dictionary | They widen memory, planning, and compatibility risk beyond the first optimization slice. |
| FFI codecs, host stream adapters, release automation, or registry publication | They do not unblock the portable encoder algorithm or its tests. |
| APNG, new colour transforms, or metadata expansion | Independent format capabilities unrelated to compression strategy. |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| PNGC-01 | Phase 32 | Pending |
| PNGC-02 | Phase 33 | Pending |
| PNGC-03 | Phase 33 | Pending |
| PNGC-04 | Phase 34 | Pending |

**Coverage:**

- v0.10 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0

---
*Requirements defined: 2026-07-22*
