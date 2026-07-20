# Technology Stack

**Project:** MoonBit Native Foundation — v0.6 PNG Interchange
**Researched:** 2026-07-20
**Overall confidence:** MEDIUM — the MoonBit toolchain and existing portable contracts were verified locally. The PNG/zlib/DEFLATE findings come from direct primary specifications, but the configured source-confidence seam classifies its generic `webfetch` provider as LOW; phase implementation must retain the linked normative sources beside its tests.

## Executive recommendation

Build PNG entirely inside the existing `tchivs/mb-image` module. Add a small reusable `mb-image/deflate` package for bit-level DEFLATE and zlib, then a `mb-image/png` codec package which consumes it through the existing `codec`, `storage`, `metadata`, and forward-only I/O contracts. Add no third-party MoonBit package: the current `mb-core` primitives already supply the checked arithmetic, byte ownership/views, budgets, diagnostics, and bounded stream seams needed for hostile binary input.

The v0.6 public interchange scope should be deliberately narrower than a standards-conformant universal PNG decoder: accept only non-interlaced, 8-bit truecolour (`colour type 2`) and truecolour-with-alpha (`colour type 6`) static images; decode all legal DEFLATE block forms within those PNG files; emit deterministic RGB8/RGBA8 PNGs. This is a useful, honest RGB/RGBA interchange path. It is **not** a claim of full PNG decoder conformance, which requires every standardized colour/depth combination and Adam7.

Use a complete bounded DEFLATE decoder but a minimal deterministic encoder: fixed-Huffman, literal-only DEFLATE blocks wrapped in zlib, filter type `None`, fixed-size IDAT segmentation, and no ancillary chunks. It is standards-conformant, reproducible, and avoids introducing an LZ matcher or compression-ratio policy into the first PNG milestone. Compression-ratio work can be an explicit later enhancement without changing the wire contract.

## Recommended Stack

### Core framework

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| MoonBit toolchain (`moon`) | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Compile and test portable codec packages | Locally verified; `moon check` and `moon test` expose `js`, `wasm`, `wasm-gc`, `native`, and `all`. Keep the existing development pin for this milestone. |
| `tchivs/mb-core/checked` | existing `0.1.0` workspace module | Checked dimensions, byte counts, offsets, and work accounting | PNG chunk lengths and scanline geometry are attacker-controlled. Reuse checked `UInt64` calculations before allocation or indexing. |
| `tchivs/mb-core/budget` | existing `0.1.0` workspace module | Hierarchical byte/allocation/pixel/work ceilings | The current `Budget` already supports preflighted, shared resource charges; PNG must charge image storage and codec work before exposure. |
| `tchivs/mb-core/bytes` + `io` | existing `0.1.0` workspace module | Owned scratch, read/write leases, bounded reader/writer progress | Existing QOI proves the portable forward-only pattern. PNG should remain stream-oriented rather than concatenate IDAT data or buffer an input file. |
| `tchivs/mb-image/codec`, `model`, `storage`, `metadata` | existing `0.1.0` workspace module | Stable image codec seam and RGB8/RGBA8 image output | Preserves the established `ImageDecoder`/`ImageEncoder` contract, caller limits, diagnostics, and operation-compatible owned image result. |
| `tchivs/mb-color/model` + `profile` | existing `0.1.0` workspace module | sRGB identity and alpha metadata | Maps the supported RGB/RGBA sample data to the same image metadata model already used by QOI. |

### New pure-MoonBit packages and components

| Component | Package | Required responsibilities | Dependencies |
|---|---|---|---|
| Bit reader/writer | `tchivs/mb-image/deflate` (internal implementation surface) | LSB-first buffering, exact EOF states, byte alignment, bounded bit reads/writes | `mb-core/error`, `checked`, `bytes`, `io`, `budget` |
| Canonical Huffman | `tchivs/mb-image/deflate` | Validate code-length trees; build canonical codes without ambiguous/incomplete trees; decode literals, lengths, and distances under a declared work charge | `mb-core/error`, `checked`, `budget` |
| Sliding output history | `tchivs/mb-image/deflate` | 32 KiB maximum history ring; validate distances before copy; support overlap-copy semantics; never retain unbounded decompressed bytes outside the output image/row pipeline | `mb-core/bytes`, `checked`, `budget` |
| zlib wrapper | `tchivs/mb-image/deflate` | Validate CMF/FLG and FCHECK, reject FDICT for PNG, enforce advertised window, compute/verify Adler-32, write deterministic header/trailer | bit reader/writer + DEFLATE + checked arithmetic |
| PNG framing/checksums | `tchivs/mb-image/png` | Validate signature, `length/type/data/CRC` chunk framing, CRC-32 over type+data, critical ordering, IDAT contiguity, and strict IEND/trailing-data behavior | `mb-image/deflate`, `mb-core/io`, `bytes`, `checked`, `budget`, `error` |
| PNG raster path | `tchivs/mb-image/png` | Validate IHDR subset, reconstruct filters 0–4, map RGB8/RGBA8 rows directly into `OwnedImage`, emit canonical scanlines | `codec`, `model`, `storage`, `metadata`, `mb-color/model`, `profile` |

`deflate` is package-scoped to `mb-image`, not a new module and not an umbrella compression framework. Its public API should stay narrow until a second codec proves genuine reuse. `png` depends on `deflate`; neither creates reverse dependencies into `mb-core` or `mb-color`.

### Normative wire-format baselines

| Standard | Verified version | Required implementation rule |
|---|---|---|
| [PNG Specification (Third Edition)](https://www.w3.org/TR/2025/REC-png-3-20250624/) | W3C Recommendation, 24 June 2025 | PNG is signature plus chunks. Validate 8-byte signature, chunk length/type/data/CRC, IHDR → contiguous IDAT+ → IEND ordering, and CRC on every processed chunk. The chunk length is unsigned but must not exceed `2^31 - 1`; MNF imposes lower caller limits. |
| [RFC 1950 — zlib 3.3](https://www.rfc-editor.org/rfc/rfc1950.html) | May 1996 | PNG uses zlib framing: validate CMF/FLG/FCHECK, require method 8, reject preset dictionaries, and verify the Adler-32 trailer over uncompressed filtered scanlines. |
| [RFC 1951 — DEFLATE 1.3](https://www.rfc-editor.org/rfc/rfc1951.html) | May 1996 | Decoder handles stored, fixed-Huffman, and dynamic-Huffman blocks, rejects reserved values, validates canonical trees and backward distances, and supports legal distances through 32 KiB. |

PNG compression method 0 is zlib-wrapped DEFLATE with a window of at most 32,768 bytes; IDAT boundaries are arbitrary and concatenate into one zlib stream. Therefore the zlib reader must continue across IDAT chunks without treating a chunk boundary as a DEFLATE block, row, or trailer boundary. [PNG §10](https://www.w3.org/TR/png-3/#10Compression) and [RFC 1950 §2.3](https://www.rfc-editor.org/rfc/rfc1950.html#section-2.3) make header/checksum validation non-optional for a conforming zlib consumer.

### Supported v0.6 PNG profile

| Area | Decode | Canonical encode |
|---|---|---|
| Pixel format | 8-bit colour type 2 (RGB) and 6 (RGBA), tightly mapped to existing `rgb8` / `rgba8` | Preserve the source's RGB8 or RGBA8 format; no implicit colour conversion |
| Interlace | Method 0 only | Method 0 |
| PNG filter method | Method 0; reconstruct None, Sub, Up, Average, and Paeth (types 0–4) | Type 0 (None) for every row |
| DEFLATE | zlib + stored/fixed/dynamic block decode; valid 1–32 KiB advertised window | zlib header `0x78 0x01`; fixed-Huffman literal-only blocks; no LZ matches and no dynamic tree generation |
| Chunks | Require `IHDR`, consecutive `IDAT`, `IEND`; CRC-check every processed chunk; skip CRC-valid, bounded non-animation ancillary chunks; reject unknown critical chunks and animation chunks | Exactly `IHDR`, deterministic-size consecutive `IDAT` chunks, `IEND`; no ancillary chunks |
| Completeness | When `require_complete_input`, reject data after IEND | Always writes the exact canonical terminal sequence |

The narrow colour/interlace profile is a project policy, not a reinterpretation of the specification: the W3C conformance section requires a full PNG decoder to support all defined bit-depth/colour-type combinations and both defined interlace methods. Record accepted-profile rejection as `CapabilityUnavailable`/an explicit codec-scope diagnostic rather than calling such files corrupt. [PNG §13.1 and §15.3.3](https://www.w3.org/TR/png-3/#13Decoders).

### Bounding contract

| Resource | Enforcement point | Policy |
|---|---|---|
| Input bytes | Every Reader transition and chunk header/data byte | Apply `CodecLimits.max_input_bytes`; never trust declared chunk length as an allocation request. |
| Chunk payload | Chunk parser | Limit every ancillary skip and IDAT feed; use fixed scratch and streaming CRC. Do not allocate a chunk-sized buffer. |
| Dimensions/pixels/output | IHDR preflight before `OwnedImage::new_operation` | Reject zero, unsupported, overflowed, or limit-exceeding geometry before exposing image output. |
| Inflate history | DEFLATE state | Fixed ≤32 KiB ring plus current/previous unfiltered row buffers; no whole-IDAT staging. |
| Scanline bytes | IHDR preflight | Checked `width * channels`, then checked `row_bytes + filter_byte`; allocate only the two bounded row buffers. |
| Work | Huffman symbols, copies, filters, CRC/Adler updates, and encode output | Charge a deterministic upper bound through `Budget` and compare it with `CodecLimits.max_work`; reject before output image allocation where the bound is known. |
| Output bytes | Encoder preflight and Writer progress | Compute a conservative canonical upper bound for literal-only DEFLATE + chunk framing; compare with `max_output_bytes` before the first write. |

This permits streaming with bounded intermediate memory while still producing an owned image result. It follows the streamability premise of RFC 1950/1951, but MNF's concrete ceilings are its own safety policy and must remain caller-configurable.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|---|---|---|---|
| Codec location | `mb-image/deflate` + `mb-image/png` packages | Add DEFLATE to `mb-core` | `mb-core` deliberately owns generic safety primitives, not image/codec semantics; broadening it is an architectural change without a second consumer. |
| Decode scope | Complete DEFLATE plus explicit RGB/RGBA PNG profile | Claim a fully conformant PNG decoder | Full PNG requires palette, grayscale, low/16-bit sample conversion, transparency variants, Adam7, and broader metadata behavior, which the v0.6 goal does not fund. |
| Encode strategy | Fixed-Huffman literal-only canonical stream | LZ77 match finder and dynamic-Huffman optimizer | Optimisation expands correctness and determinism surface. It can be added later while retaining existing canonical output as a stable baseline. |
| PNG filters | Decode all five; encode None | Adaptive filter selection | Adaptive selection is worthwhile only after correctness and reproducibility are proven; it is not required for interoperable output. |
| IDAT handling | One logical zlib stream over bounded chunk feeds | Concatenate IDAT into one byte array | The standard permits boundaries anywhere in the zlib stream; concatenation wastes memory and defeats streaming limits. |
| Dependencies | Existing MNF packages + MoonBit standard library | Third-party codec package | The project requirement is pure MoonBit, and existing contracts already cover the required primitives. |

## Installation

No external package installation is recommended. The milestone adds packages to the existing `mb-image` module and keeps its current target declaration:

```json
"supported-targets": "+js+wasm+wasm-gc+native"
```

The four required compilation/test lanes remain:

```powershell
moon check --target all --deny-warn
moon test --target js --deny-warn
moon test --target wasm --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target native --deny-warn
```

## Sources and confidence

| Source | Use | Seam confidence |
|---|---|---|
| [W3C PNG Third Edition](https://www.w3.org/TR/2025/REC-png-3-20250624/) | Current PNG chunk, filter, compression, colour, interlace, and conformance rules | LOW — direct primary source, but `classify-confidence --provider webfetch --verified` returned LOW for the generic provider. |
| [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950.html) | zlib header, preset-dictionary, and Adler-32 rules | LOW — same source-provider classification caveat. |
| [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951.html) | DEFLATE bit/block/Huffman/distance rules | LOW — same source-provider classification caveat. |
| Local `moon version`, `moon check --help`, `moon test --help`; existing `mb-core` and QOI sources | Exact toolchain surface and reusable portable contracts | MEDIUM — local direct evidence; Context7 was unavailable and its classified confidence is MEDIUM. |

## Implementation watch items

- Confirm with adversarial vectors that dynamic Huffman validation rejects oversubscribed, incomplete-when-invalid, and repeat-overrun code trees before any out-of-bounds lookup.
- Make the IDAT-to-zlib adapter resumable across arbitrary Reader progress and arbitrary IDAT boundaries; test checksum bytes split across chunks.
- Keep CRC and Adler-32 distinct: PNG CRC covers chunk type/data; zlib Adler-32 covers the full uncompressed filtered scanline sequence.
- Treat 16-bit samples, palette/grayscale conversion, transparency chunks, colour-management chunks, Adam7, and APNG as explicit later capability work; do not silently drop or partially interpret them.
- Fix the canonical IDAT payload segment size in source and vectors before publishing byte fixtures. It is a format-output policy, not an externally imposed PNG limit.
