# Phase 76: Indexed8 PNG Source & Eager PLTE - Research

**Researched:** 2026-07-24
**Domain:** PNG Type-3/8 source admission and eager PLTE framing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Add an owning, immutable PNG-only `PngIndexedImage` source contract; do not extend `ImageView`, `ImageFormat`, or generic `ImageEncoder`.
- The initial wire format is Type-3 at depth 8 only, non-interlaced, RGB palette only, Stored DEFLATE, and filter None.
- The source accepts canonical unpacked one-byte-per-pixel indices; it validates width/height, `indices.len == width * height`, palette count 1..256, and every index < palette count before output/budget exposure.
- Eager output must emit `IHDR → PLTE → IDAT → IEND` with exact independent CRC/wire tests and decode back through the existing public generic RGB8 route.
- Refactor the private machine framing facts as necessary to support variable ancillary chunks, but keep all legacy source profiles byte-identical and retain a single bounded traversal.
- tRNS, chunk output, non-Stored strategies, Indexed1/2/4, Adam7, quantization, and staging are deferred.

### the agent's Discretion

*(No section supplied in CONTEXT.md.)*

### Deferred Ideas (OUT OF SCOPE)

*(No section supplied in CONTEXT.md.)*
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INDEX-01 | Library users can construct a dedicated immutable Indexed8 PNG source with a validated RGB palette and canonical unpacked index raster. | Add `PngIndexedImage` in the PNG module; validate all shape and palette/index facts before retaining copied byte owners. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`; `modules/mb-core/bytes/owned_bytes.mbt`] |
| INDEX-02 | Library users can eagerly emit bounded non-interlaced Type-3/8 PNG with exact IHDR, PLTE, IDAT, and IEND framing and atomic rejection. | Add an indexed-only eager entry point that uses the existing private machine after atomic source/limit/budget preflight, with a frame plan that inserts PLTE without changing zero-PLTE legacy bytes. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/{encode.mbt,stream_encode.mbt}`] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared data models in MoonBit; native is primary, while portable targets need deliberate conformance. [VERIFIED: codebase: `AGENTS.md`]
- Keep public dependencies acyclic and explicit; do not introduce FFI for this codec work. [VERIFIED: codebase: `AGENTS.md`; `modules/mb-image/png/moon.pkg`]
- Keep public operations deterministic and GUI-independent. [VERIFIED: codebase: `AGENTS.md`]
- Prefer the codebase graph for code discovery; targeted source inspection was used after the available graph index proved to be for the related repository rather than this v019 worktree. [VERIFIED: runtime; `AGENTS.md`]
- Perform implementation through the GSD workflow. [VERIFIED: codebase: `AGENTS.md`]

## Summary

Phase 76 should add one public, PNG-specific immutable source and one eager-only encoding entry point: `PngIndexedImage` plus `PngEncoder::encode_indexed8`. The generic `ImageEncoder` trait must remain unchanged because it accepts `ImageView`, whose model has no indexed/palette semantics. The source constructor must validate dimensions, checked pixel count, exact index length, RGB palette cardinality, and every index before it performs ownership copies or allows any encoder/writer budget to be touched. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/{76-CONTEXT.md,76-DISCUSSION-LOG.md}`; `modules/mb-image/{codec/contracts.mbt,storage/views.mbt}`; `modules/mb-core/bytes/owned_bytes.mbt`]

The smallest safe encoder change is a private input/profile branch (`Indexed8`) and a scalar frame plan used by `PngEncodeMachine`. Today `byte_at` hard-codes the no-ancillary layout, including `IDAT` at byte 33 and `IEND` after `45 + idat_length`; preflight similarly adds a fixed 57 bytes. An indexed path needs `12 + palette_bytes` extra bytes, a rolling PLTE CRC, and shifted IDAT/IEND offsets. It must retain the existing zero-PLTE branch for every legacy profile so their byte stream and preflight length remain identical. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt:1735-1945,stream_encode.mbt:692-720,stream_encode.mbt:1342-1456}`]

**Primary recommendation:** Implement this as one source/API plus one private frame/input refactor, then prove it with an independent Type-3 wire/CRC oracle, generic RGB8 decode-back, atomic-rejection checks, and legacy byte-regression vectors. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`; `modules/mb-image/png/{encode_test.mbt,encode_wbtest.mbt}`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Indexed source ownership and validation | PNG public API | Byte storage | Palette/index semantics belong to the PNG-only type; `OwnedBytes::from_bytes` is the established defensive-copy owner. [VERIFIED: codebase: `modules/mb-core/bytes/owned_bytes.mbt`; `modules/mb-image/codec/contracts.mbt`] |
| Checked geometry, limits, and budget admission | PNG encoder preflight | — | Existing `_png_encode_preflight_with_filter_layout_idat_limit_profile` centralizes checked geometry, output limits, work, and a single budget charge. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:1735-1945`] |
| IHDR/PLTE/IDAT/IEND byte emission | Private `PngEncodeMachine` | Writer adapter | The machine already emits and acknowledges every byte, updating CRC/Adler only after sink acceptance. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1342-1456`; `modules/mb-image/png/encode.mbt:1949-1990`] |
| Interoperability oracle | Existing generic `PngDecoder` route | Public encode test | Type-3 decode is already canonicalized into generic RGB8, so decode-back proves consumer compatibility without changing generic image semantics. [VERIFIED: codebase: `.planning/milestones/legacy-quick/260721-3xb-validate-decode-non-interlaced-8-bit-ind/260721-3xb-SUMMARY.md`; `modules/mb-image/png/png.mbt`] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-image/png` package | repository current | Public source/API and canonical eager PNG implementation | This phase extends its established private preflight/machine rather than adding a dependency or encoder stack. [VERIFIED: codebase: `modules/mb-image/png/{moon.pkg,png.mbt,encode.mbt,stream_encode.mbt}`] |
| `@bytes.OwnedBytes` | repository current | Defensive ownership for indices and palette | Its documented constructor copies immutable external bytes into independently owned storage. [VERIFIED: codebase: `modules/mb-core/bytes/owned_bytes.mbt:97-104`] |
| `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Build and execute package tests | Versions are installed in the target environment. [VERIFIED: local `moon --version`, `moonc -v`, `moonrun --version`] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| `_png_crc_for_type`, `_png_crc_step`, `_png_adler_step` | Production checksum state | Reuse only in production framing; the wire oracle must calculate CRC independently. [VERIFIED: codebase: `modules/mb-image/png/{structural.mbt,stream_encode.mbt}`] |
| `PngEncodeMachine::present` / `acknowledge` | Bounded eager output | Keep the acknowledged-byte boundary when PLTE bytes are introduced. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1385-1456`] |
| `@codec.ImageDecoder::decode(PngDecoder::new(), ...)` | Public decode-back compatibility test | Assert RGB8 dimensions and palette-expanded raster after eager indexed output. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:649-678`] |

**Installation:** None. No external package, FFI, or module is needed. [VERIFIED: codebase: `.planning/REQUIREMENTS.md`; `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
caller Bytes: unpacked indices + RGB triples
                 |
                 v
      PngIndexedImage::new (all validation, then own copies)
                 |
                 v
 PngEncoder::encode_indexed8(source, writer, limits, budget, diagnostics)
                 |
                 v
  shared checked preflight + Indexed8 frame facts
       | invalid                         | accepted
       v                                 v
 no writer/budget exposure     PngEncodeMachine, one bounded traversal
                                         |
                                         v
      signature -> IHDR(type=3, depth=8) -> PLTE -> IDAT(Stored/None) -> IEND
                                         |
                         +---------------+----------------+
                         v                                v
          independent chunk/CRC/Stored oracle     generic PngDecoder -> RGB8 pixels
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # public PngIndexedImage and indexed eager method declaration
├── encode.mbt              # indexed source admission, shared preflight/input facts, eager adapter
├── stream_encode.mbt       # frame-plan-aware byte emission and rolling PLTE CRC
├── encode_test.mbt         # black-box source, atomicity, independent wire oracle, decode-back
└── encode_wbtest.mbt       # private frame offsets/length/CRC and legacy-layout regression
```

### Pattern 1: Validate, then retain one immutable PNG-only source

Use `PngIndexedImage::new(width, height, indices, rgb_palette, budget)` as the only public constructor. Before copying either input, require: `1 <= width,height <= UInt32::MAX`; checked `width * height`; exact index length; palette byte length divisible by 3; palette entry count in `1..=256`; and every index smaller than that entry count. Retain private owned storage and expose only read accessors needed by the PNG encoder. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`; `modules/mb-core/bytes/owned_bytes.mbt`; `modules/mb-image/png/encode.mbt:121-267`]

Do not construct an `ImageView`, add an indexed `ImageFormat`, or implement this through the generic `ImageEncoder` trait. The generic trait has an `ImageView` source parameter, while the chosen source carries palette/index information that that model intentionally lacks. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/{76-CONTEXT.md,76-DISCUSSION-LOG.md}`; `modules/mb-image/codec/contracts.mbt:238-248`]

### Pattern 2: One private input traversal, parameterized frame facts

Introduce a private source/input abstraction consumed by `_png_encode_preflight_with_filter_layout_idat_limit_profile`, `PngFilteredMatchCursor`, and `PngEncodeMachine`: legacy `ImageView` branches retain their current byte provider and revision check; the indexed branch returns one raw index byte per pixel and has immutable owned backing. Add `PngEncodeProfile::Indexed8`, reachable only from `encode_indexed8`, with Stored, filter-None, and non-interlaced admission fixed rather than configurable. [VERIFIED: codebase: `modules/mb-image/png/{png.mbt:181-205,encode.mbt:121-267,encode.mbt:1735-1945,stream_encode.mbt:692-720}`]

Replace fixed frame arithmetic with a private scalar layout such as `PngFrameFacts { plte_length, plte_start, idat_start, iend_start, total_length }`. Legacy facts set `plte_length = 0` and therefore retain the current offsets; Indexed8 sets `plte_length = palette_entries * 3`, emits PLTE before IDAT, seeds a PLTE CRC from its type, and advances that CRC only when each palette byte is acknowledged. The stored total becomes `57 + plte_length + 12 + idat_length`; keep the current `57 + idat_length` calculation exactly for legacy sources. [VERIFIED: codebase: `modules/mb-image/png/{encode.mbt:1791-1809,stream_encode.mbt:1342-1456}`]

### Pattern 3: Separate production checksums from the test oracle

Production emission should reuse `_png_crc_for_type` and `_png_crc_step`. In `encode_test.mbt`, add a local test-only chunk walker with a local bitwise/table CRC-32 reference; it must inspect the whole output without calling production CRC, PNG encode, decode, scanline, or pack helpers. It verifies signature; exact chunk order/count; IHDR payload (`depth=8`, `type=3`, compression/filter/interlace all zero); PLTE length/triples; each chunk CRC over type+payload; a single Stored IDAT; IEND; and exact filter-None index scanlines. [VERIFIED: codebase: `modules/mb-image/png/{structural.mbt,encode_test.mbt:594-647,encode_wbtest.mbt:819-826}`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Generic indexed image model | An `ImageFormat::Indexed8` / `ImageView` extension | `PngIndexedImage` | The locked contract keeps palette/index semantics PNG-specific and prevents generic API ambiguity. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`] |
| PNG CRC / zlib Adler in production | A second checksum implementation | Existing PNG helpers | Existing emission already uses rolling CRC/Adler state at acknowledgement time. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:895-897,1416-1448`] |
| Whole-PNG or PLTE+PNG staging | An output-sized serialized buffer | `PngEncodeMachine` plus scalar frame facts and source-backed palette bytes | The current machine is designed to emit one pending byte and retain no output-sized stage. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:687-720,1385-1456`] |
| Palette reconstruction for encode | RGB expansion followed by quantization | Original validated index bytes and palette triples | Quantization is explicitly deferred and would not preserve caller-provided indices. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`] |

## Common Pitfalls

### Pitfall 1: Adding `Indexed8` only to `PngEncodeProfile`

**What goes wrong:** `_png_encode_source` and the filtered cursor accept `ImageView`, so a profile-only addition either invents generic semantics or accidentally reads RGB bytes instead of source indices. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:121-267`; `modules/mb-image/png/stream_encode.mbt:692-720`]

**How to avoid:** Introduce the indexed source/input branch at the shared preflight and traversal seam, not in the generic image model. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`]

### Pitfall 2: Leaving fixed no-PLTE offsets in `byte_at`

**What goes wrong:** The current `byte_at` assumes IDAT length/type begin at offsets 33/37 and derives IEND from `45 + idat_length`; inserting palette bytes only in the byte provider corrupts framing and CRC ranges. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1346-1381`]

**How to avoid:** Make every boundary derive from one frame-facts object, including acknowledge ranges for IHDR, PLTE, and IDAT CRCs. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1416-1448`]

### Pitfall 3: Validating source after constructor ownership or encoder preflight

**What goes wrong:** A bad index or palette may consume budget or permit writer-visible bytes before failure, violating atomic rejection. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`; `modules/mb-image/png/encode_test.mbt:1304-1424`]

**How to avoid:** Check every source fact before `OwnedBytes` construction; in eager encode, do all exact length/limit/budget work before `writer.write`. Assert zero writer position and unchanged relevant encode-budget fields for each rejection. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:1949-1989`; `modules/mb-image/png/encode_test.mbt:915-939`]

### Pitfall 4: Treating decode-back as the wire oracle

**What goes wrong:** A decoder can accept output while an encoder still has wrong chunk order, palette CRC, or Stored framing. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`]

**How to avoid:** Require both the independent chunk/CRC/scanline oracle and public generic RGB8 decode-back. [VERIFIED: codebase: `modules/mb-image/png/encode_test.mbt:594-678`]

## Code Examples

### Indexed eager admission and frame facts

```moonbit
// Design shape; use existing checked/error helpers in implementation.
let source = PngIndexedImage::new(width, height, indices, palette, budget)?
// Constructor validates all source invariants before retaining copied bytes.
let frame = PngFrameFacts::indexed8(source.palette_length())
// signature -> IHDR -> PLTE -> IDAT -> IEND; legacy frame has no PLTE.
PngEncoder::new().encode_indexed8(source, writer, limits, budget, diagnostics)
```

This design is intentionally separate from `ImageEncoder::encode(ImageView, ...)`. [VERIFIED: codebase: `modules/mb-image/codec/contracts.mbt:238-248`; `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Fixed `IHDR → IDAT → IEND` scalar byte layout | Scalar frame facts with an optional PLTE segment | Enables Type-3/8 now and tRNS later without duplicating emitter traversal; legacy zero-PLTE facts preserve existing output. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1342-1456`; `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`] |
| Generic RGB/RGBA/Gray image source | Dedicated owning indexed source | Retains palette/index semantics that decode intentionally expands away. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-DISCUSSION-LOG.md`; `modules/mb-image/png/encode.mbt:121-267`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None. Public API spellings above are implementation recommendations, not asserted existing APIs. | — | — |

## Open Questions

None. The context locks the source, wire subset, atomicity boundary, and deferred features. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| MoonBit toolchain | Compile/test Phase 76 | ✓ | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`, `moonrun 0.1.20260713` | — [VERIFIED: local version probes] |

**Missing dependencies with no fallback:** None. [VERIFIED: local version probes]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | Library codec has no authentication surface. [VERIFIED: codebase: `modules/mb-image/png`] |
| V3 Session Management | no | Library codec has no session state. [VERIFIED: codebase: `modules/mb-image/png`] |
| V4 Access Control | no | Library codec has no authorization surface. [VERIFIED: codebase: `modules/mb-image/png`] |
| V5 Input Validation | yes | Validate indexed source fully before ownership/output; retain checked geometry, `CodecLimits`, and `Budget` preflight. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`; `modules/mb-image/png/encode.mbt`] |
| V6 Cryptography | no | PNG CRC and Adler are integrity checks, not cryptographic controls. [CITED: https://www.w3.org/TR/png-3/] |

### Known Threat Patterns for Indexed PNG Encode

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Overflowing width/height or index-raster shape | Denial of Service | Checked `width * height`, PNG U32 dimensions, exact source lengths, and existing encoder limits before output. [VERIFIED: codebase: `modules/mb-image/png/encode.mbt:121-267,1735-1809`] |
| Palette/index mismatch | Tampering | Enforce RGB triples, 1..256 entries, and index `< entry_count` before copies/encoding. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`] |
| Incorrect ancillary framing/CRC | Tampering | Single frame-facts authority and independent whole-wire oracle. [VERIFIED: codebase: `modules/mb-image/png/stream_encode.mbt:1342-1456`; `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`] |
| Compatibility regression | Information Integrity | Compare every existing eager profile against its frozen bytes and retain zero-PLTE frame facts. [VERIFIED: codebase: `.planning/phases/76-indexed8-source-eager-plte/76-CONTEXT.md`; `modules/mb-image/png/encode_test.mbt`] |

## Sources

### Primary (HIGH confidence)

- Codebase: `.planning/phases/76-indexed8-source-eager-plte/{76-CONTEXT.md,76-DISCUSSION-LOG.md}` — locked scope and exclusions.
- Codebase: `modules/mb-image/png/{png.mbt,encode.mbt,stream_encode.mbt}` — public encoder, preflight, machine state, fixed framing, CRC/Adler acknowledgement.
- Codebase: `modules/mb-image/png/{encode_test.mbt,encode_wbtest.mbt}` — existing atomicity, scanline, CRC, and generic-decode test precedents.
- Codebase: `.planning/milestones/legacy-quick/260721-3xb-validate-decode-non-interlaced-8-bit-ind/` — existing strict Type-3/8 PLTE-to-RGB8 decoder behavior.

### Secondary (MEDIUM confidence)

- [PNG Third Edition](https://www.w3.org/TR/png-3/) — PNG chunk/CRC and Type-3 palette framing context.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependencies; current implementation and installed toolchain were inspected.
- Architecture: HIGH — the exact hard-coded frame offsets, preflight total, and acknowledged checksum state were inspected.
- Pitfalls: HIGH — each is tied to the locked compatibility requirements and existing encoder seams.

**Research date:** 2026-07-24
**Valid until:** 2026-08-23
