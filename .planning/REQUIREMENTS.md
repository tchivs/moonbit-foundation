# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-22
**Milestone:** v0.11 PNG Dynamic Huffman Compression
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## Dynamic PNG Compression

- [x] **PNGD-01**: A library user can explicitly select `DynamicOrFixedOrStored`, while legacy `Stored` constructors and the established `FixedOrStored` strategy retain their frozen byte sequences; Dynamic is selected only by this new opt-in route.
- [x] **PNGD-02**: A library user selecting the dynamic strategy receives a deterministic, bounded dynamic-Huffman PNG only when its completely planned PNG is strictly smaller than the unchanged FixedOrStored winner; otherwise the existing winner is emitted after the same exact pre-output capability, geometry, output, work, and single-budget admission.
- [x] **PNGD-03**: A library user can drain an admitted dynamic selection through eager and caller-buffered encoders with byte-identical results, exact progress, acknowledgement-safe state changes, and the existing sticky completion/failure contract.

## Dynamic PNG Evidence

- [ ] **PNGD-04**: Maintainers can reproduce a generated, literal-heavy RGB8 and straight-RGBA8 corpus on js, wasm, wasm-gc, and native that proves a Dynamic block (`BTYPE=10`) is strictly smaller than FixedOrStored, deterministic across eager and hostile chunk schedules, and decodes completely to every source component.

## Scope Fences

| Boundary | v0.11 policy |
|---|---|
| Compatibility | `Stored`, legacy constructors, and `FixedOrStored` stay byte-stable; equal-size dynamic candidates retain the existing FixedOrStored representation. |
| Compression | Retain filter-None scanlines and the distance-1-through-4 matcher. No adaptive filtering, 32 KiB dictionary, broader matching, or length-limited/package-merge optimization. |
| Boundedness | Dynamic planning uses fixed-size alphabet/header facts only; it must not retain image-sized scanlines, tokens, compressed output, caller leases, or history buffers. |
| PNG and stream contracts | Preserve one IDAT, zlib framing, CRC, Adler-32, eager lifecycle, caller-lease ownership, exact progress, and sticky terminals. |
| Ecosystem scope | No FFI, host stream adapters, external packages, CI/release/registry work, APNG, colour work, or metadata expansion. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PNGD-01 | Phase 35 | Complete |
| PNGD-02 | Phase 36 | Complete |
| PNGD-03 | Phase 36 | Complete |
| PNGD-04 | Phase 37 | Pending |

**Coverage:**

- v0.11 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0

---
*Requirements defined: 2026-07-22*
