# v0.25 Research: Indexed Low-Bit PNG Encode

**Scope:** Type-3 PNG encoding at bit depths 1, 2, and 4, extending the shipped Indexed8 source, optional canonical `tRNS`, and eager/chunk state machine.

**Researched:** 2026-07-24
**Confidence:** MEDIUM for PNG-format facts (official W3C specification, fetched through the web fallback); HIGH for repository seams and test anchors (direct source inspection).

## Recommendation

Keep `PngIndexedImage` as the only source model: it already owns a canonical unpacked U8 index raster plus RGB palette and per-entry alpha. Add a small public indexed-depth selector restricted to `1`, `2`, and `4`, then use it only in explicit indexed eager and chunk factories. Do not add a bit-packed image format, quantizer, source copy, staging buffer, generic `ImageEncoder` path, Adam7 mode, or strategy parameter.

The implementation should add indexed profiles/depth facts to the existing private `PngEncodeMachine`, not a second encoder. The only changed payload path is the Type-3 scanline source: take canonical unpacked indices, pack them MSB-first into a deterministic zero-filled row tail, then let the existing Stored/None zlib, PLTE/tRNS frame facts, CRC acknowledgement, writer loop, and caller-buffered `pull` lifecycle emit those bytes. This is the smallest extension that retains v0.24 eager/chunk byte parity and lease ownership semantics.

## External PNG Facts

- Type 3 permits bit depths `1`, `2`, `4`, and `8`; PLTE is required. Its entry count must not exceed `2^bit_depth`; image indices outside the actual PLTE count are errors. The palette components remain 8-bit RGB irrespective of index depth. [MEDIUM: W3C PNG Third Edition](https://www.w3.org/TR/png-3/)
- Type-3 indices pack left-to-right into high-order bits. A scanline begins on a byte boundary and its final low-order unused bits are unspecified by the format. Encode them as zero to make MNF output canonical and exact-vector testable. [MEDIUM: W3C PNG Third Edition](https://www.w3.org/TR/png-3/)
- For indexed images, `tRNS` is an optional leading alpha table: no more entries than PLTE; omitted trailing values are opaque. Existing v0.24 canonicalization (emit through the last non-`255` alpha, otherwise omit) remains correct at all four Type-3 depths. [MEDIUM: W3C PNG Third Edition](https://www.w3.org/TR/png-3/)
- PNG filtering is byte-based. The specification recommends filter `None` for depths below 8 and says it is usually best for indexed colour. Retain the locked Stored/None route; do not use low-bit work as a reason to expose filter/compression strategies. [MEDIUM: W3C PNG Third Edition](https://www.w3.org/TR/png-3/)

## Existing Seams to Reuse

| Seam | Existing evidence | v0.25 use |
|---|---|---|
| Owning source | `PngIndexedImage::new` validates unpacked indices, palette and alpha, then retains one private owner in `png.mbt`. | No source-model or constructor widening. Add depth-dependent palette-capacity admission during encode preflight. |
| Packed-row math | `_png_profile_wire_row_bytes` in `encode.mbt` already calculates `ceil(width * depth / 8)` with checked multiplication/addition. | Generalize privately for indexed depth; do not reinterpret a Type-3 row as grayscale samples. |
| MSB-first packer | `_png_wire_byte` packs Gray1/2/4 using `shift = 8 - depth - ((x * depth) % 8)`. | Reuse this exact byte-position formula with `PngIndexedImage::index_at`; index is already the unscaled code. |
| Indexed framing | `_png_encode_indexed_preflight` and `PngFrameFacts` calculate PLTE, optional `tRNS`, IDAT and IEND before a budget charge. | Replace `row_bytes = width` with checked packed row bytes and preserve all frame/CRC spans. |
| Single emission state machine | `PngEncodeMachine::new_with_indexed`, `present`, then `acknowledge` already protect PLTE/tRNS/IDAT CRC state. | Keep both eager and `PngChunkEncoder` backed by this machine. |
| Decoder oracle | `raster_decode.mbt` already unpacks indexed 1/2/4-bit rows MSB-first and rejects `index >= palette_entries`. | Test emitted bytes through the public RGB8/RGBA8 decoder, not through encoder internals. |
| Hostile lease tests | `png_stream_packed_hostile_drain` and Indexed8 tests cover zero/one/ragged capacities, sentinels, terminals and released leases. | Parameterize/reuse for indexed depths instead of inventing a transport harness. |

## Required Private Contract

Use one depth fact (`1 | 2 | 4`) shared by Type-3 profile selection, IHDR generation, preflight, and scanline emission. A public enum such as `PngIndexedBitDepth::{One, Two, Four}` is preferable to six depth-named methods: it makes the finite supported set explicit while avoiding a generic encoder option. Keep `encode_indexed8` and `new_indexed8` unchanged for compatibility; add explicit selector-bearing companions for low depth.

The profile must still force:

- colour type `3`, non-interlaced IHDR, Stored DEFLATE, filter byte `0`;
- `IHDR → PLTE → optional tRNS → IDAT → IEND`;
- canonical unpacked input and a zero-filled packed-tail output;
- no source mutation/revision dependency, no retained caller lease, and one `present → destination.set → acknowledge` byte lifecycle.

### Checked admission and exact sizes

Before output, a writer/lease, or an encode-work charge becomes observable:

1. Obtain the selected depth and require `palette_entries <= 2^depth` (maximum 2, 4, or 16). Existing source validation already guarantees every canonical index is below `palette_entries`, so this implies it fits in the selected code width.
2. Compute `bits = checked_mul(width, depth)`, `row_bytes = checked_add(bits, 7) / 8`, `scanline_bytes = checked_add(row_bytes, 1)`, and `scanlines = checked_mul(scanline_bytes, height)`.
3. Reuse the existing Stored IDAT block arithmetic and `PngFrameFacts` for exact PLTE/tRNS/IDAT/IEND total length.
4. Apply width, height, pixels, output-byte and work limits; only then perform the single existing budget charge and construct the active machine.

The Type-3 low-bit frame may be smaller than Indexed8, so frame length and charged work must be recalculated from packed scanlines, never borrowed from an 8-bit plan. Conversely, PLTE and `tRNS` lengths remain based on actual palette entries, not `2^depth`.

### Canonical packing examples

These are independent wire-oracle values for a Stored/None scanline after its filter byte `00`.

| Depth | Unpacked indices | Packed scanline bytes | What it proves |
|---:|---|---|---|
| 1 | `0,1,0,1,0,1,0,1,1` | `00 55 80` | ninth sample occupies bit 7; seven unspecified tail bits are canonicalized to zero |
| 2 | `0,1,2,3,0` | `00 1B 00` | four codes per first byte and a one-code tail |
| 4 | `0,1,2` | `00 01 20` | two codes per byte and one-code tail |

## Candidate Requirements and Acceptance Criteria

| ID | Candidate requirement | Acceptance criteria |
|---|---|---|
| INDEXLOW-01 | Users can encode a valid `PngIndexedImage` as non-interlaced Type-3/1, /2, or /4 using an explicit finite depth selector while retaining canonical unpacked indices. | IHDR has selected depth, colour type 3, compression/filter/interlace `0/0/0`; PLTE appears before IDAT; existing `encode_indexed8` byte vectors do not change. |
| INDEXLOW-02 | Depth-specific preflight is bounded and atomic. | Reject palette counts over 2/4/16, all checked-size overflow and width/height/pixel/output/work limits before writer position, chunk construction or encode budget changes; accepted exact work consumes exactly the planned charge. |
| INDEXLOW-03 | Low-bit output has canonical, interoperable raster and palette transparency. | Independent stored-scanline oracle proves the three table rows above on odd widths and multiple rows; opaque palettes omit `tRNS`; partial alpha emits the existing shortest canonical tRNS and public decode returns exact RGB8/RGBA8 palette values. |
| INDEXLOW-04 | Caller-buffered low-bit output remains the same machine as eager output. | For every depth, zero-, one-, and ragged-capacity drains equal eager bytes; only accepted bytes advance progress; unused lease tail remains sentinel-filled; a post-finish pull is zero-write `Finished`; a released lease yields a sticky zero-write failure without changing a later lease. |
| INDEXLOW-05 | The extension is qualified without broadening its feature contract. | Test the ordinary PNG package on `wasm`, `wasm-gc`, `js`, and `native`; retain legacy/Indexed8 regressions; no strategies, Adam7, generic model changes, quantization, staging, FFI, wrapper, copied source tree or release-script changes. |

## Test Plan and Anchors

1. **Eager packing and frame tests** (`encode_test.mbt`): use the three table rows, one multi-row case per depth, PLTE capacities exactly 2/4/16, and transparent/opaque palettes. Parse chunk order and CRC with the existing test-local Indexed helpers. Do not calculate the expected wire with production functions.
2. **Private boundary tests** (`encode_wbtest.mbt`): assert packed row bytes, exact `scanlines`, IDAT length, frame offsets, work charge, and zero tail bits. Include depth profile-to-IHDR mapping to prevent accidental `8` from the old indexed branch.
3. **Public decoder tests** (`encode_test.mbt`): decode generated opaque bytes as RGB8 and generated transparent bytes as RGBA8; assert all pixels, especially the last pixel in each odd-width tail. Add a crafted packed Type-3 file whose in-range and out-of-range indices prove the decoder's palette bounds remain independent.
4. **Chunk lifecycle tests** (`stream_encode_test.mbt`): adapt the existing low-bit-gray hostile drain and Indexed8 release-failure tests, not a new loop. Run `[0,1]`, `[1]`, and `[0,1,3,2,5]` schedules for each depth and at least one partial-alpha case.
5. **Admission tests** (`encode_test.mbt` and/or `stream_encode_test.mbt`): depth capacity excess, output max one byte short, zero work, and exact-vs-one-less work; snapshot budget resources and writer/lease state before each rejection.

## Risks and Guardrails

| Risk | Consequence | Guardrail |
|---|---|---|
| Reusing Gray code conversion | Index values are scaled/rejected as luminance levels. | Give Type-3 a separate depth helper and pack `index_at` verbatim. |
| Computing `row_bytes = width` | Incorrect IDAT size, budgets and IDAT bytes. | Compute checked `ceil(width * depth / 8)` before all frame/limit logic. |
| Leaving tail bits accidental | Eager/chunk output can drift and vectors are not deterministic. | Initialize each packed byte to zero and place only valid samples. |
| Allowing a 16-entry palette at depth 2 | Encodes a structurally invalid PNG even if image uses only four indices. | Cap PLTE count, not merely observed index maxima, at `2^depth`. |
| Copying an Indexed8 transport | Breaks progress/CRC/terminal parity. | Extend `PngEncodeMachine::new_with_indexed` and add only thin eager/chunk adapters. |
| Adding adaptive filters because byte filtering exists | Broadens API and invalidates the fixed bounded preflight contract. | Keep Stored/None; the format guidance supports this choice for low depth. |
| Treating decoder acceptance as sufficient | Can miss wrong IHDR, tail packing, frame size or CRC. | Combine independent raw IDAT scanline/CRC checks with public decode-back. |

## Suggested Phase Split

### Phase 79 — Indexed Low-Bit Preflight and Eager Packing

**Goal:** Explicitly selected Type-3/1, /2 and /4 eager encoding from the existing `PngIndexedImage`, with exact packed raster, PLTE/tRNS framing and atomic admission.

**Owns:** `png.mbt` public depth selection if needed; `encode.mbt` depth/profile, checked row/frame preflight and packer; `stream_encode.mbt` IHDR/scanline integration; eager and private packing/frame tests.

**Exit:** `INDEXLOW-01` through `INDEXLOW-03`; public decode-back and all v0.24 bytes retained.

### Phase 80 — Resumable Indexed Low-Bit Parity and Four-Target Qualification

**Goal:** Expose the same completed low-bit machine through caller buffers and prove lifecycle, hostile leases, independent wire semantics, and portable compatibility.

**Owns:** thin low-bit indexed `PngChunkEncoder` factory/selector if not included in the Phase 79 public API; `stream_encode_test.mbt` hostile and terminal coverage; fixture/vector evidence and target command proof.

**Exit:** `INDEXLOW-04` and `INDEXLOW-05`; no separate state machine and no scope expansion.

**Ordering rationale:** exact depth admission and packed frame facts must exist before a chunk factory can be meaningful. Once the eager frame is authoritative, the second phase is deliberately thin: it qualifies the existing byte lifecycle under hostile ownership rather than duplicating encoding work.

## Deliberately Deferred

- implicit quantization, scaling or dithering;
- a generic indexed `ImageView`/`ImageFormat` or generic `ImageEncoder` widening;
- indexed Adam7 and packed-pass traversal;
- compression/filter strategy expansion;
- staging buffers, FFI, wrappers, copied source trees and release automation.

## Sources

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — Type-3 depth set, packing order/tails, PLTE/tRNS requirements, and low-bit filter guidance. **MEDIUM** (official primary specification retrieved through web-search fallback).
- Repository source inspected directly: `modules/mb-image/png/{png,encode,stream_encode,raster_decode,encode_test,stream_encode_test}.mbt`. **HIGH** for current seams and test anchors.
- v0.24 implementation contexts and research under `.planning/milestones/v0.24-phases/`. **HIGH** for established scope boundaries.
