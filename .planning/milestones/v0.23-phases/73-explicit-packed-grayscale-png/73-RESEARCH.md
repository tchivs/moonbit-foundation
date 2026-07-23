# Phase 73: Explicit Packed Grayscale PNG - Research

**Researched:** 2026-07-23
**Domain:** Lossless non-interlaced PNG Type-0 low-bit wire serialization
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

DATA_k7Wq2LmN_START
### Locked Decisions

- **D-01:** Add explicit eager public selectors for Gray1, Gray2, and Gray4,
  parallel to existing explicit Gray8/Gray16 selectors. Generic and Gray8
  behavior stays byte-identical.
- **D-02:** Accept only canonical opaque Gray/U8 packed sources with exact
  levels: `{0,255}` for Gray1, `{0,85,170,255}` for Gray2, and multiples of
  17 for Gray4. Reject every other sample before output/budget exposure; never
  scale, quantize, or dither.
- **D-03:** Pack samples MSB-first per PNG row and force unused final-byte bits
  to zero. Stored/None output receives an independently authored wire oracle
  for odd widths and all three depths.
- **D-04:** Reuse the existing profile-aware bounded machine, admission,
  compression/filter plumbing, and Type-0 IHDR emission seam. No staging
  buffer, duplicate traversal, or model-layout change.
- **D-05:** Phase 73 owns eager non-interlaced output and atomic invalid-level
  admission only. Caller-buffered surface, hostile lease schedules, broader
  strategy matrix, Adam7, and four-target qualification are deferred to
  Phases 74–75.

### the agent's Discretion

None stated.

### Deferred Ideas (OUT OF SCOPE)

Caller-buffered low-bit factories, all strategy matrices, Adam7, palette/index
encoding, implicit conversion, a bit-packed source model, FFI, release scripts,
target wrappers, and copied-source workflows.
DATA_k7Wq2LmN_END
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYPACK-01 | Explicitly encode canonical opaque Gray/U8 sources at legal non-interlaced Type-0 depths 1, 2, or 4 with MSB-first samples and zero padding. | Add three eager profile selectors; compute packed wire rows; set IHDR depth/type; test independent Stored/None odd-width payloads. [CITED: https://www.w3.org/TR/png-3/] |
| GRAYPACK-02 | Unsupported levels, descriptors, resource limits, and budgets fail atomically before eager output. | Exact-level scan belongs in profile admission before planner/budget charge; retain existing one-preflight machine and atomic writer contract. [VERIFIED: codebase inspection] |
</phase_requirements>

## Summary

Phase 73 is an additive private-profile extension of the existing eager PNG machine, not a new image model or encoder. Add `Gray1`, `Gray2`, and `Gray4` to the private `PngEncodeProfile`, then expose only the three default eager `PngEncoder` selectors. Each selector fixes `Stored`, filter `None`, and `PngInterlaceStrategy::None`, matching the deliberately narrow Phase 73 boundary. Existing generic and Gray8/Gray16 constructors must keep their current profile and byte output. [VERIFIED: codebase inspection]

The required implementation seam is the scalar wire-byte provider, not an allocated packed raster. The canonical source remains tightly packed `ChannelOrder::Gray + U8` storage with one source byte per pixel; preflight validates every source byte against the selected exact representable level set, and the wire provider packs visible samples into a byte from high-order to low-order bits. Packed profiles must compute row bytes as `ceil(width * bit_depth / 8)`, use a filtering byte stride of one, and emit the selected bit depth plus colour type 0 in IHDR. This retains the existing bounded traversal/planner/machine path and makes final-byte padding deterministically zero. [VERIFIED: codebase inspection] [CITED: https://www.w3.org/TR/png-3/]

**Primary recommendation:** Implement low-bit grayscale as three eager-only private profiles with exact-level admission and a profile-aware packed wire-byte producer; do not add chunk selectors, strategy families, Adam7, source conversion, or storage-model changes. [VERIFIED: codebase inspection]

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit; native integration must remain portable behind explicit capability boundaries. [VERIFIED: AGENTS.md]
- Public modules require acyclic, explicit dependencies; public behavior must remain deterministic and GUI-independent. [VERIFIED: AGENTS.md]
- Native FFI is out of scope unless small, isolated, documented, and replaceable; this phase needs none. [VERIFIED: AGENTS.md]
- Public stability follows SemVer when stable, and architectural boundary changes require RFCs; this additive phase must not redefine the image model. [VERIFIED: AGENTS.md]
- Project guidance prefers the codebase graph for code discovery. The requested v019 worktree is not indexed, so graph lookup could not serve this tree and targeted `rg`/source inspection was used as the allowed fallback. [VERIFIED: codebase-memory-mcp query; VERIFIED: AGENTS.md]
- `.planning/config.json` explicitly disables Nyquist validation, so this research intentionally omits the Validation Architecture section. [VERIFIED: .planning/config.json]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Explicit `Gray1`/`Gray2`/`Gray4` selection | API / Backend | — | `PngEncoder` owns the private profile chosen by an eager factory. [VERIFIED: codebase inspection] |
| Exact-level admission | API / Backend | — | The shared preflight completes before an eager writer observes bytes or a budget is charged. [VERIFIED: codebase inspection] |
| Low-bit row serialization | API / Backend | — | `encode.mbt` already provides the scalar wire-byte and filtered-scanline path consumed by every plan. [VERIFIED: codebase inspection] |
| IHDR Type-0/depth fields and output | API / Backend | — | `PngEncodeMachine::byte_at` owns IHDR, IDAT, CRC, and IEND emission. [VERIFIED: codebase inspection] |
| Canonical source storage | Image model | API / Backend | The descriptor already represents packed Gray/U8 as byte-per-pixel; the phase deliberately changes only PNG wire packing. [VERIFIED: codebase inspection] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` (2026-07-13) | Existing implementation and package tests | The repository pins and uses this installed toolchain; no new runtime is needed. [VERIFIED: local CLI; VERIFIED: AGENTS.md] |
| `tchivs/mb-image/png` | workspace `0.1.0` | Existing encoder, model, test package | The required profiles, preflight, machine, and PNG tests already live here. [VERIFIED: modules/mb-image/moon.mod.json; VERIFIED: codebase inspection] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| W3C PNG Third Edition | Recommendation, 2025-06-24 | Normative Type-0 bit-depth, packing, IHDR, filtering, and interlace rules | Use as the wire-format authority for the independent oracle. [CITED: https://www.w3.org/TR/png-3/] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Profile-aware wire packing | Bit-packed `ImageFormat` / new storage model | Violates D-04 and would broaden the public model rather than serialize the existing canonical source. [VERIFIED: 73-CONTEXT.md] |
| Exact admission | Scaling, quantization, or dithering | Violates D-02 and makes output lossy. [VERIFIED: 73-CONTEXT.md] |
| One bounded machine | Second low-bit encoder or staged packed rows | Duplicates traversal and breaks the bounded-machine constraint. [VERIFIED: 73-CONTEXT.md; VERIFIED: codebase inspection] |

**Installation:** None — this phase adds no external package. [VERIFIED: 73-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
ImageView (packed, tight Gray/U8; canonical metadata)
        |
        v
PngEncoder::new_gray{1,2,4}()
        |
        v
PngEncodeProfile::Gray{1,2,4}
        |
        v
single preflight
  ├─ descriptor/geometry/limit checks
  ├─ exact-level scan (reject before budget/output)
  ├─ packed row-byte arithmetic: ceil(width * depth / 8)
  └─ existing Stored/None plan + budget admission
        |
        v
PngEncodeMachine
  ├─ IHDR: depth {1,2,4}, type 0, method 0, no interlace
  └─ scalar packed wire-byte producer: MSB-first, zero tail bits
        |
        v
Writer: PNG signature + IHDR + IDAT + IEND
```

PNG type 0 permits 1-, 2-, and 4-bit grayscale; each scanline starts on a byte boundary, places its leftmost sample in high-order bits, and may leave low bits unused in its last byte. The standard leaves those unused bits unspecified, while D-03 intentionally strengthens the local contract to zero them. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: 73-CONTEXT.md]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt            # eager public selector family and private profile enum
├── encode.mbt         # source admission, packed wire-byte provider, row facts
├── stream_encode.mbt  # shared machine IHDR and private emission state
└── encode_test.mbt    # independent Stored/None wire oracle and atomic rejection tests
```

No `stream_encode_test.mbt` change is required for Phase 73 because no caller-buffered low-bit constructor is permitted until Phase 74. [VERIFIED: 73-CONTEXT.md]

### Pattern 1: Explicit profile selector delegates to the shared machine

**What:** Add only eager default selectors, each producing a private profile and the fixed `Stored`/`None`/non-interlaced configuration. [VERIFIED: codebase inspection]

**When to use:** Use for every Phase 73 public entry point; do not expose `with_compression_strategy`, `with_filter_strategy`, `with_strategies`, or any chunk constructor for the new profiles. [VERIFIED: 73-CONTEXT.md]

**Example:**

```moonbit
// Source: existing PngEncoder::new_gray8 pattern; Phase 73 analogue.
pub fn PngEncoder::new_gray2() -> PngEncoder {
  {
    strategy: PngCompressionStrategy::Stored,
    filter_strategy: PngFilterStrategy::None,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray2,
  }
}
```

### Pattern 2: Validate losslessness before planner/budget exposure

**What:** Keep normal source-shape validation, then scan every Gray/U8 sample for an exact allowed level before the shared planner and its final `budget.charge`. [VERIFIED: codebase inspection]

**When to use:** Only for `Gray1`, `Gray2`, and `Gray4`; Gray8 retains its byte-identical existing admission. [VERIFIED: 73-CONTEXT.md]

**Example:**

```moonbit
// Source: Phase 73 exact-level contract; sketch only, no conversion.
fn packed_gray_code(sample : Byte, depth : UInt64) -> Result[UInt64, @error.CoreError] {
  let step = if depth == 1UL { 255UL } else if depth == 2UL { 85UL } else { 17UL }
  if sample.to_uint64() % step != 0UL {
    return Err(_png_encode_capability("packed-gray-level-required"))
  }
  Ok(sample.to_uint64() / step)
}
```

### Pattern 3: Produce packed wire bytes on demand

**What:** Teach the existing scalar row/wire provider to form one low-bit byte at a time. Start the accumulator at zero, emit visible sample codes into descending shifts, and never set lanes beyond `width`; unused final lanes therefore stay zero. [VERIFIED: codebase inspection] [CITED: https://www.w3.org/TR/png-3/]

**When to use:** For all planner, checksum, and Stored emission reads of a low-bit profile; do not materialize a row or replace the source model. [VERIFIED: 73-CONTEXT.md]

**Example:**

```moonbit
// Source: W3C scanline packing rule and raster_decode.mbt's inverse shift.
let samples_per_byte = 8UL / depth
let mut packed = b'\x00'
for lane = 0UL; lane < samples_per_byte; lane = lane + 1UL {
  let x = wire_byte_index * samples_per_byte + lane
  if x < source.width() {
    let code = exact_code(source.get_byte(x, row, 0UL).unwrap(), depth)
    let shift = 8UL - depth * (lane + 1UL)
    packed = packed | (code << shift.to_int()).to_byte()
  }
}
```

### Anti-Patterns to Avoid

- **IHDR-only change:** setting an IHDR depth of 1/2/4 while preserving `width * channels` row arithmetic or direct byte reads emits malformed scanlines. [VERIFIED: codebase inspection]
- **Late level validation:** checking values during output emission can expose a prefix or charge budget before the invalid sample is discovered. [VERIFIED: 73-CONTEXT.md; VERIFIED: codebase inspection]
- **Scale-to-fit conversion:** `value / step` without an exact divisibility check silently quantizes invalid samples. [VERIFIED: 73-CONTEXT.md]
- **LSB-first packing:** it conflicts with the PNG scanline rule and the existing decoder's inverse shift. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: modules/mb-image/png/raster_decode.mbt]
- **Borrowing Phase 74 surface:** public chunk constructors and hostile lease tests expand the phase beyond D-05. [VERIFIED: 73-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| PNG framing, IDAT, CRC, DEFLATE, and writer traversal | A second low-bit encoder | Existing `PngEncodeMachine` and preflight | It already owns atomic admission, compression plan selection, checksums, and complete PNG emission. [VERIFIED: codebase inspection] |
| Image storage | A bit-packed `ImageFormat` or source conversion | Existing packed Gray/U8 `ImageView` | Phase 73 is a wire serializer only; source layout remains byte-per-pixel. [VERIFIED: 73-CONTEXT.md; VERIFIED: modules/mb-image/model/descriptor.mbt] |
| Packed input decode rule | A new bit-order convention | Mirror `raster_decode.mbt` shift formula | The decoder already extracts low-bit Type-0 samples with the matching MSB-first offset. [VERIFIED: modules/mb-image/png/raster_decode.mbt] |
| Oracle verification | Production decoder or private inflater in the assertion | Independently authored bounded Stored-block parser and literal expected scanlines | A test oracle that shares the encoder's packing implementation cannot independently catch bit-order/padding mistakes. [VERIFIED: 73-CONTEXT.md; VERIFIED: modules/mb-image/png/encode_test.mbt] |

**Key insight:** The only new algorithm is deterministic byte-at-a-time serialization. All admission, compression, checksum, framing, and output ownership must remain the pre-existing bounded machine's responsibility. [VERIFIED: 73-CONTEXT.md; VERIFIED: codebase inspection]

## Common Pitfalls

### Pitfall 1: Applying byte-per-pixel row arithmetic to low-bit output

**What goes wrong:** A 9-pixel Gray1 row is treated as nine wire bytes instead of two packed bytes. [VERIFIED: codebase inspection]

**Why it happens:** Current preflight computes `row_bytes` as `width * channels`, which is correct for 8/16-bit existing profiles but not for sub-byte Type-0 samples. [VERIFIED: modules/mb-image/png/encode.mbt]

**How to avoid:** Add a profile-aware wire-row-byte helper using checked `ceil(width * depth / 8)` arithmetic and retain source tight-row validation against the original Gray/U8 byte rows. [VERIFIED: codebase inspection]

**Warning signs:** IHDR reports 1/2/4 while the Stored/None oracle payload has `width + 1` bytes per source row. [VERIFIED: codebase inspection]

### Pitfall 2: Nonzero tail lanes in an odd-width row

**What goes wrong:** Unused low-order bits can inherit stale accumulator/source data, making byte output nondeterministic. [VERIFIED: 73-CONTEXT.md]

**Why it happens:** PNG permits unspecified unused bits, but that permissiveness does not meet Phase 73's deterministic zero-padding decision. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: 73-CONTEXT.md]

**How to avoid:** Initialize every output byte to zero; only OR a code when its source `x < width`; test widths not divisible by 8, 4, and 2 for depths 1, 2, and 4 respectively. [VERIFIED: codebase inspection]

**Warning signs:** Different output for the same source, or literal scanline bytes with nonzero low padding. [VERIFIED: codebase inspection]

### Pitfall 3: Reusing 8-bit filtering assumptions without byte semantics

**What goes wrong:** A low-bit profile can use a source-channel stride instead of PNG's byte-oriented filtering unit. [VERIFIED: codebase inspection]

**Why it happens:** Existing `channels` flows through row calculation and filter helpers as the byte distance. [VERIFIED: modules/mb-image/png/encode.mbt]

**How to avoid:** For all low-bit Type-0 profiles, retain a filter byte stride of `1UL` and apply filters only to the packed wire bytes. Phase 73 fixes the public route to None, but its shared planning/traversal must still consume that correct representation. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: codebase inspection]

**Warning signs:** Future fixed/adaptive output differs from the packed Stored/None logical row or predictors cross sample rather than byte boundaries. [VERIFIED: codebase inspection]

### Pitfall 4: Expanding the public surface prematurely

**What goes wrong:** Adding chunk or strategy selectors introduces contract and qualification work reserved for Phases 74–75. [VERIFIED: 73-CONTEXT.md]

**How to avoid:** Add only default eager selectors in `png.mbt`; do not expose new `PngChunkEncoder` factories or low-bit strategy/interlace variants. [VERIFIED: 73-CONTEXT.md]

## Code Examples

Verified patterns from local sources and the PNG specification:

### Inverse decoder rule to mirror

```moonbit
// Source: modules/mb-image/png/raster_decode.mbt
let start = x * bit_depth.to_uint64()
let byte = row.get(start / 8UL).unwrap().to_int()
let shift = 8 - bit_depth - (start % 8UL).to_int()
let raw = (byte >> shift) & mask
```

The encoder's packer must place the reduced code at the same `shift`, iterating source pixels into each output byte from left to right. [VERIFIED: modules/mb-image/png/raster_decode.mbt]

### Existing atomic construction seam

```moonbit
// Source: modules/mb-image/png/stream_encode.mbt
let facts = match _png_encode_preflight_with_interlace_profile(
  source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

The exact-level full-image scan must occur inside this preflight path before its final budget charge and before `PngEncodeMachine` is returned to eager encoding. [VERIFIED: modules/mb-image/png/encode.mbt; VERIFIED: modules/mb-image/png/stream_encode.mbt]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Gray8 special profile and later Gray16 special wire handling | One profile-aware bounded preflight/machine with scalar wire bytes, filtering, planning, replay, CRC, and IHDR seams | Existing Phases 44–49 implementation history | Low-bit support should extend these seams, not reintroduce a special encoder path. [VERIFIED: git history Phases 44–49; VERIFIED: codebase inspection] |

**Deprecated/outdated:**

- Gray16's former Stored/None-only transitional route: Phase 48 research records that it was removed in favor of profile-aware wire bytes across every bounded traversal. Do not recreate that split for Gray1/2/4. [VERIFIED: git history Phase 48 RESEARCH.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None — implementation recommendations derive from locked Phase 73 decisions, the current source, historical Gray8/Gray16 phase material, and the W3C PNG specification. | — | — |

## Open Questions

1. **Exact typed error context for an invalid packed level**
   - What we know: Existing profile rejections use typed capability contexts and preflight is the atomic admission seam. [VERIFIED: modules/mb-image/png/encode.mbt]
   - What's unclear: The locked context specifies atomic rejection but not the exact stable error-context string for a nonrepresentable sample. [VERIFIED: 73-CONTEXT.md]
   - Recommendation: Follow the current `gray8-required` / `gray16-required` style with one profile-neutral packed-level context, and lock it in the new tests before implementation. [VERIFIED: codebase inspection]

## Environment Availability

Step 2.6: SKIPPED — this is a MoonBit code/test change with no new external service, CLI, runtime, or package dependency. The installed project toolchain is `moon 0.1.20260713`; package tests can use the established native command when executing the plan. [VERIFIED: local CLI; VERIFIED: modules/mb-image/moon.mod.json]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | In-process codec API has no identity boundary. [VERIFIED: codebase inspection] |
| V3 Session Management | no | No session state exists. [VERIFIED: codebase inspection] |
| V4 Access Control | no | No authorization decision exists. [VERIFIED: codebase inspection] |
| V5 Input Validation | yes | Profile-specific descriptor and exact-level preflight before resource charge/output. [VERIFIED: modules/mb-image/png/encode.mbt; VERIFIED: 73-CONTEXT.md] |
| V6 Cryptography | no | PNG CRC is integrity checking, not a cryptographic control; no cryptography is introduced. [CITED: https://www.w3.org/TR/png-3/] |

### Known Threat Patterns for the PNG encoder

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Oversized dimensions/row arithmetic | Denial of service | Preserve checked multiplication/addition and existing width, height, pixel, output, and work limits before budget charge. [VERIFIED: modules/mb-image/png/encode.mbt] |
| Nonrepresentable source level | Tampering | Scan every selected Gray/U8 source sample before planner/budget/output; reject instead of conversion. [VERIFIED: 73-CONTEXT.md] |
| Malformed low-bit wire order/tail | Tampering | MSB-first scalar packer plus independent Stored/None odd-width oracle for all depths. [CITED: https://www.w3.org/TR/png-3/] [VERIFIED: 73-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- [W3C PNG Third Edition](https://www.w3.org/TR/png-3/) — current Recommendation (2025-06-24); Type-0 legal bit depths, MSB-first scanline packing, IHDR fields, filter method 0, and non-interlaced method 0. [CITED: https://www.w3.org/TR/png-3/]
- `modules/mb-image/png/encode.mbt` — source admission, current row arithmetic, scalar wire reads, filtered traversal, and one atomic preflight ledger. [VERIFIED: codebase inspection]
- `modules/mb-image/png/stream_encode.mbt` — shared machine construction, stored emission, and IHDR emission seam. [VERIFIED: codebase inspection]
- `modules/mb-image/png/png.mbt`, `encode_test.mbt`, and `raster_decode.mbt` — public selector conventions, independent Stored parser patterns, and inverse low-bit unpacking. [VERIFIED: codebase inspection]
- Git-history Phase 44/45 Gray8 and Phase 47/48 Gray16 materials — prior profile, bounded-machine, and no-second-path decisions. [VERIFIED: git history]

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no package choice; current MoonBit toolchain and workspace module were probed locally. [VERIFIED: local CLI]
- Architecture: HIGH — all required seams are in the checked current source and are constrained by locked Phase 73 decisions. [VERIFIED: codebase inspection; VERIFIED: 73-CONTEXT.md]
- Pitfalls: HIGH — row arithmetic, profile IHDR, source admission order, and decoder shift semantics are observable in current code and the normative PNG specification. [VERIFIED: codebase inspection; CITED: https://www.w3.org/TR/png-3/]

**Research date:** 2026-07-23
**Valid until:** 2026-08-22 — PNG wire rules and the local source baseline are stable; refresh if Phase 73 implementation changes the preflight or profile seams.
