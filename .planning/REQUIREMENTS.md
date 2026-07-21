# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-21
**Milestone:** v0.9 Resumable PNG Encode
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## PNG Chunked Encode

- [x] **PNGE-01**: A library user can create a public PNG chunk encoder for a compatible RGB8 or straight-RGBA8 image and receives all capability, dimension, limit, and budget rejection before any encoded byte is exposed.
- [x] **PNGE-02**: A library user can repeatedly provide arbitrary caller-owned mutable output buffers and receives deterministic exact progress until the complete canonical PNG representation is emitted exactly once, without retained caller buffers or duplicated/omitted bytes.
- [x] **PNGE-03**: A library user receives the same canonical bytes and terminal failure semantics as the eager PNG encoder; completion and failure are sticky, and later calls cannot expose additional bytes.

## PNG Chunked Encode Evidence

- [ ] **PNGE-04**: Maintainers can verify hostile output-capacity schedules, eager/chunk byte parity, limits, budgets, and terminal behavior unchanged on js, wasm, wasm-gc, and native.
- [ ] **PNGE-05**: A library user can run one public portable PNG chunk-decode → image operation → chunk-encode workflow that prints deterministic output evidence using only public MoonBit contracts.

## Future Requirements

- **PNGX-04**: Add compression-ratio optimization and benchmarked encoder strategies without changing the canonical baseline implicitly.
- **PNGX-05**: Add bounded optional streaming adapters for host I/O only after the caller-buffered contract is stable.

## Out of Scope

| Feature | Reason |
|---|---|
| FFI-backed PNG or zlib implementation | The core encoder remains portable MoonBit code across four targets. |
| Compression-ratio optimization | v0.9 protects byte-stable eager parity before adding alternate strategies. |
| Registry publication or release automation | It does not unblock the PNG implementation or its public consumers. |
| New image colour transforms or APNG | They are independent format/colour milestones and do not define chunked output semantics. |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| PNGE-01 | Phase 29 | Complete |
| PNGE-02 | Phase 30 | Complete |
| PNGE-03 | Phase 30 | Complete |
| PNGE-04 | Phase 31 | Pending |
| PNGE-05 | Phase 31 | Pending |

**Coverage:**

- v0.9 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0
