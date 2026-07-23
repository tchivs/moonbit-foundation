# Phase 79: Indexed Low-Bit Eager Packing - Research

**Researched:** 2026-07-24  
**Domain:** Bounded MoonBit Type-3 PNG eager encoding  
**Confidence:** HIGH for repository seams; MEDIUM for PNG-format rules

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public selection and source ownership
- **D-01:** Expose a small public `PngIndexedBitDepth` selector limited to `One`, `Two`, and `Four`, used by an additive eager indexed factory. Keep `encode_indexed8` unchanged. — **Reversibility:** costly — changing a public enum or factory later changes downstream source contracts.
- **D-02:** Keep `PngIndexedImage` as canonical one-byte-per-pixel input. Pack only while emitting the Type-3 scanline; do not introduce a packed model, quantization, scaling, or an extra source copy.

### Wire profile and atomicity
- **D-03:** Use the existing one-machine Stored/None/non-interlaced Type-3 route. For each row, pack indices MSB-first and initialize unused final-byte bits to zero. PLTE and canonical optional tRNS retain the shipped order and representation.
- **D-04:** Before any writer output or budget mutation, enforce palette caps of 2, 4, or 16; compute packed row/frame sizes with checked arithmetic; enforce all limits; then make the single existing budget charge. — **Reversibility:** costly — this preserves the public atomic resource-admission contract.

### Evidence and compatibility
- **D-05:** Prove packing with independent odd-width Stored scanline vectors for every depth, then prove public RGB8/RGBA8 decoding and retain Indexed8/legacy bytes. Private tests own exact row, frame, and budget facts; streaming lifecycle qualification remains Phase 80.

### the agent's Discretion
- Match the closest established PNG constructor naming and existing capability-error vocabulary.
- Keep private profile/fact representation minimal provided eager output remains backed by the same acknowledgement-safe machine.

### Deferred Ideas (OUT OF SCOPE)

Indexed caller-buffered lifecycle qualification belongs to Phase 80. Indexed Adam7, quantization, dithering, generic model widening, strategy expansion, image-sized staging buffers, FFI, wrappers, copied source trees, and release automation remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INDEXLOW-01 | Explicit Type-3 1/2/4 eager output from `PngIndexedImage`. | Add a finite selector and pass its one private depth fact through preflight, IHDR, and scanline packing. [VERIFIED: codebase inspection] |
| INDEXLOW-02 | Atomic depth-specific palette and resource admission. | Use checked packed-row/frame arithmetic, limits, then the one existing budget charge. [VERIFIED: modules/mb-image/png/encode.mbt] |
| INDEXLOW-03 | MSB-first zero-tailed output with PLTE/tRNS and RGB8/RGBA8 decode. | Mirror the decoder's inverse bit extraction and test independent Stored scanlines plus public decode-back. [VERIFIED: modules/mb-image/png/raster_decode.mbt] [CITED: https://www.w3.org/TR/png-3/] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep all core logic MoonBit-native, portable across `js`, `wasm`, `wasm-gc`, and `native`, deterministic, and free of new FFI. [VERIFIED: AGENTS.md]
- Preserve modular public API compatibility and existing byte contracts. [VERIFIED: AGENTS.md]
- Put public behavior in `*_test.mbt` and arithmetic/representation invariants in `*_wbtest.mbt`. [VERIFIED: AGENTS.md]

## Summary

Phase 79 is a parameterization of the shipped Indexed8 route, not a new encoder. `PngIndexedImage` already owns and validates canonical unpacked indices, palette triples, and alpha values. The indexed preflight currently fixes `row_bytes = width`, while the shared machine returns one index byte per scanline payload byte; those two seams must become selected-depth aware. Existing `PngFrameFacts`, Stored-deflate arithmetic, PLTE/tRNS framing, CRC/Adler state, writer acknowledgement, and the one-charge budget contract remain unchanged. [VERIFIED: modules/mb-image/png/{png,encode,stream_encode}.mbt]

**Primary recommendation:** Add public `PngIndexedBitDepth::{One, Two, Four}` and eager `PngEncoder::encode_indexed(source, bit_depth, writer, limits, budget, diagnostics)`; retain `encode_indexed8` unchanged. The private `PngEncodeMachine::new_with_indexed` receives the selected depth/profile fact and continues to back the sole eager route. This is the recommended naming choice in the delegated discretion area. [VERIFIED: 79-CONTEXT.md; modules/mb-image/png/encode.mbt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Eager API and depth selector | API / Backend | — | `PngEncoder` owns profile-specific eager surfaces. [VERIFIED: modules/mb-image/png/png.mbt] |
| Admission and frame facts | API / Backend | Budget | `encode.mbt` checks limits and charges before machine construction. [VERIFIED: modules/mb-image/png/encode.mbt] |
| Scalar index packing | API / Backend | — | The machine supplies each scanline byte on demand, avoiding packed staging. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| Framing and acknowledgement | API / Backend | — | The machine owns IHDR/PLTE/tRNS/IDAT/IEND and advances after accepted bytes only. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |

## Standard Stack

| Component | Version | Purpose | Direction |
|---|---:|---|---|
| MoonBit `mb-image/png` | workspace | Existing bounded Type-3 machine and test suite. | Reuse; install nothing. [VERIFIED: modules/mb-image/png/moon.pkg] |
| W3C PNG Third Edition | 2025 Recommendation | Type-3 depth, PLTE/tRNS, and packing rules. | Use for independent wire assertions. [CITED: https://www.w3.org/TR/png-3/] |
| `@checked` / `@budget` | workspace | Checked arithmetic and atomic charge. | Reuse in indexed preflight. [VERIFIED: modules/mb-image/png/encode.mbt] |

**Installation:** None. [VERIFIED: modules/mb-image/png/moon.pkg]

## Architecture Patterns

### System Architecture Diagram

```text
PngIndexedImage (unpacked indices, RGB palette, alpha)
  -> encode_indexed(source, PngIndexedBitDepth, ...)
  -> preflight: palette cap -> checked packed facts -> limits -> one budget charge
  -> PngEncodeMachine::new_with_indexed(depth fact)
  -> IHDR(Type 3/depth) -> PLTE -> optional canonical tRNS -> IDAT -> IEND
  -> filter 00 + direct MSB-first packed index bytes
  -> writer accepts byte -> acknowledge advances CRC/Adler/cursor
```

### Pattern 1: One Indexed Depth Fact

Map the public enum once to `(depth, palette_cap, private profile)` and consume that fact in indexed preflight, IHDR generation, and scanline packing. Do not infer depth from palette count: the caller selects the wire contract. [VERIFIED: 79-CONTEXT.md]

### Pattern 2: Direct MSB-First Packed Byte

For each payload byte, initialize `packed = 0`, visit only the indices represented by that byte, and OR the unscaled index at `8 - depth - ((x * depth) % 8)`. The decoder uses this exact inverse shift and stops at `width`, so untouched low-order tail bits remain zero. [VERIFIED: modules/mb-image/png/encode.mbt; modules/mb-image/png/raster_decode.mbt]

```moonbit
let bits = @checked.checked_mul(source.width(), depth)?
let row_bytes = @checked.checked_add(bits, 7UL)? / 8UL
// For a visible x: packed |= index.to_int() << (8 - depth - ((x * depth) % 8))
```

### Exact Preflight / Frame Math

1. Select depth `d ∈ {1,2,4}` and reject `palette_entries > 2^d` before any output or budget mutation. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: 79-CONTEXT.md]
2. Compute `bits = checked_mul(width, d)`, `row_bytes = checked_add(bits, 7) / 8`, `scanline_width = checked_add(row_bytes, 1)`, and `scanlines = checked_mul(scanline_width, height)`. [VERIFIED: modules/mb-image/png/encode.mbt]
3. Feed `scanlines` into the existing Stored IDAT calculation and feed actual `PLTE` and canonical `tRNS` lengths into `PngFrameFacts`; do not use `2^d` as either chunk length. [VERIFIED: modules/mb-image/png/encode.mbt]
4. Check width, height, pixels, output bytes, and work; then make exactly the existing `budget.charge` call. [VERIFIED: modules/mb-image/png/encode.mbt]

### Independent Wire Vectors

| Depth | Unpacked indices | Filter + packed payload | Assertion |
|---:|---|---|---|
| 1 | `0,1,0,1,0,1,0,1,1` | `00 55 80` | Ninth sample is bit 7; tail is zero. [CITED: https://www.w3.org/TR/png-3/] |
| 2 | `0,1,2,3,0` | `00 1B 00` | One-code tail is zero. [CITED: https://www.w3.org/TR/png-3/] |
| 4 | `0,1,2` | `00 01 20` | One-code tail is zero. [CITED: https://www.w3.org/TR/png-3/] |

### Anti-Patterns to Avoid

- Do not reuse grayscale scaling/level validation: indexed bytes are palette codes. [VERIFIED: modules/mb-image/png/raster_decode.mbt]
- Do not retain Indexed8 `row_bytes = width`; it makes IDAT/frame/work facts wrong. [VERIFIED: modules/mb-image/png/encode.mbt]
- Do not add a packed source model, second transport, adaptive filters, strategies, or caller-buffered surface. [VERIFIED: 79-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PNG frame and CRC state | Low-bit-specific frame writer | `PngFrameFacts` + existing machine | Preserves PLTE/tRNS order, CRC state, and acknowledgement semantics. [VERIFIED: modules/mb-image/png/{encode,stream_encode}.mbt] |
| Stored zlib / Adler | Second compressor | Existing Stored plan | It only needs the new scalar scanline stream. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |
| tRNS canonicalization | New alpha framing | Existing last-non-opaque traversal | It already derives canonical optional tRNS. [VERIFIED: modules/mb-image/png/encode.mbt] |
| Decode verification | Encoder-private decoder | Public `PngDecoder` | It already expands low-bit Type-3 to RGB8/RGBA8. [VERIFIED: modules/mb-image/png/raster_decode.mbt] |

## Common Pitfalls

### Packed math copied from Indexed8

`row_bytes = width` is valid only for Type-3/8. Derive every subsequent Stored, frame, output, and work fact from packed `row_bytes`. [VERIFIED: modules/mb-image/png/encode.mbt]

### Invalid palette accepted because used indices fit

The actual PLTE entry count must fit the selected bit-depth range even if source indices happen to use fewer entries. [CITED: https://www.w3.org/TR/png-3/]

### Decoder-only evidence

Public decode can miss a mutually compatible packing error. Assert independent raw Stored scanlines, IHDR depth/type, chunk order/CRCs, and public RGB8/RGBA8 decode-back. [VERIFIED: 79-CONTEXT.md]

### Late failure breaks atomicity

All semantic and limit checks must precede machine construction and the one budget charge; never discover a bad selected palette during byte emission. [VERIFIED: 79-CONTEXT.md; modules/mb-image/png/encode.mbt]

## Code Examples

```moonbit
// Recommended Phase 79 surface; exact spelling is the delegated naming choice.
PngEncoder::encode_indexed(
  PngEncoder::new(), source, PngIndexedBitDepth::Two,
  writer as &@io.Writer, limits, budget, @error.Diagnostics::new(),
)
```

Test it with a test-local Stored parser: assert the raw vectors above, `IHDR = depth/type 2/3`, `PLTE` before optional `tRNS` before `IDAT`, then assert every public decoded RGB8/RGBA8 pixel including the final odd-width sample. [VERIFIED: 79-CONTEXT.md; modules/mb-image/png/encode_test.mbt]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Indexed8-only scanline byte provider | One Type-3 depth-aware scalar provider over the same immutable source | Legal 1/2/4-bit output without source copies or a second machine. [VERIFIED: 79-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `encode_indexed(source, bit_depth, ...)` is the selected additive eager spelling. | Summary | Public API spelling differs; resolve during planning before implementation. |

## Open Questions — RESOLVED

1. **Public low-bit eager API signature: locked.** Implement `PngEncoder::encode_indexed(source, bit_depth, writer, limits, budget, diagnostics)`. It preserves the existing Indexed8 source-first API shape while placing the selected wire capability before transport and resource arguments; `encode_indexed8(source, writer, limits, budget, diagnostics)` remains unchanged. [VERIFIED: modules/mb-image/png/encode.mbt; 79-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | PNG test execution | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |

## Security Domain

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication / V3 Session / V4 Access Control | no | No identity, session, or access-control boundary is introduced. [VERIFIED: 79-CONTEXT.md] |
| V5 Validation, Sanitization and Encoding | yes | Positive depth allow-list, palette cap, checked arithmetic, limits before charge, and bounds-checked source access. [VERIFIED: modules/mb-image/png/{png,encode}.mbt] [CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V6 Cryptography | no | CRC/Adler remain PNG integrity mechanisms, not security cryptography. [VERIFIED: modules/mb-image/png/stream_encode.mbt] |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Width/depth overflow understates resource use | Denial of service | Checked arithmetic and limits before the one charge. [VERIFIED: modules/mb-image/png/encode.mbt] |
| Oversized PLTE for selected depth | Tampering | Reject `entries > 2^depth` in preflight. [CITED: https://www.w3.org/TR/png-3/] |
| Bad bit ordering or tail | Tampering | Independent odd-width wire vectors and public decode-back. [VERIFIED: 79-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/{png,encode,stream_encode,raster_decode,encode_test,encode_wbtest}.mbt` — current source, preflight, machine, inverse unpacking, and test seams. [VERIFIED: codebase inspection]
- `79-CONTEXT.md`, `.planning/research/v025-INDEXED-LOW-BIT-ENCODE.md`, and v0.24 contexts — locked scope and established Indexed8 compatibility contract. [VERIFIED: repository planning artifacts]

### Secondary (MEDIUM confidence)

- [W3C PNG Third Edition](https://www.w3.org/TR/png-3/) — indexed bit depths, MSB-first packing, PLTE/tRNS requirements, and None-filter guidance. [CITED: https://www.w3.org/TR/png-3/]
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) — validation/encoding control category. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

## Metadata

**Confidence breakdown:** Standard stack HIGH; architecture HIGH; format-specific wire facts MEDIUM from the official W3C specification. [VERIFIED: codebase inspection] [CITED: https://www.w3.org/TR/png-3/]  
**Research date:** 2026-07-24  
**Valid until:** 2026-08-23. [ASSUMED]
