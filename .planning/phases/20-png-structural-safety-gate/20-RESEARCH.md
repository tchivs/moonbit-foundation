# Phase 20: PNG Structural Safety Gate - Research

**Researched:** 2026-07-20  
**Domain:** Strict, bounded PNG framing and capability validation in portable MoonBit  
**Confidence:** HIGH for repository seams; MEDIUM for PNG specification details

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** v0.6 accepts only non-interlaced 8-bit truecolour PNG: colour type
  2 (RGB) or 6 (RGBA), compression/filter method 0. Other profiles are typed
  capability/data failures rather than lossy conversions.
- **D-02:** The public codec surface remains the established eager
  `ImageDecoder`/`ImageEncoder` model. This phase may establish `png` public
  types and a non-consuming probe, but it must not add public push/pull PNG
  streaming APIs.
- **D-03:** Require the PNG signature, exactly one first IHDR, checked positive
  dimensions, contiguous IDAT, exactly one empty terminal IEND, CRC-32 over
  every processed chunk, and no post-IEND trailing input.
- **D-04:** Unknown critical chunks fail. Known colour-, transparency-,
  palette-, animation-, or HDR-affecting chunks fail. Unknown ancillary chunks
  are CRC-checked and may be discarded only when opaque metadata preservation
  is disabled; preservation requested fails rather than silently losing data.
- **D-05:** Probe is non-consuming and bounded. Derived chunk, geometry,
  pixel, output, work, allocation, and input values use the existing checked
  arithmetic, limits, budget, and diagnostics contracts before any future
  image allocation or output exposure.
- **D-06:** Keep fixtures small and provenance-tagged. Phase 20 must include
  hostile signature/chunk/order/CRC/IEND/trailing and limit cases; legal
  DEFLATE, filters, and public workflow evidence belong to Phases 21–22.

### the agent's Discretion

Choose private parser types, exact error helper reuse, and the smallest module
layout that preserves acyclic dependencies and four-target portability.

### Deferred Ideas (OUT OF SCOPE)

Palette, grayscale, `tRNS`, 16-bit, Adam7, colour-management/HDR metadata,
APNG, public PNG streaming, compression optimization, benchmarks, FFI, and
release/registry work are outside Phase 20 and v0.6 where stated in
`REQUIREMENTS.md`.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models are MoonBit; native is primary but all four portable targets remain conformant. [VERIFIED: AGENTS.md]
- Keep package dependencies acyclic; do not add FFI or GUI-dependent behavior. [VERIFIED: AGENTS.md]
- Public operations must be deterministic, and all public-package tests include black-box `*_test.mbt` plus internal `*_wbtest.mbt` coverage. [VERIFIED: AGENTS.md]
- New fixture records require provenance, digest, license, redistribution status, and expected-use metadata in `fixtures/manifest.json`. [VERIFIED: docs/policies/licensing-and-fixtures.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PNG-01 | Non-consuming bounded signature probe with deterministic outcomes. | Existing `ProbeOutcome` and QOI/PPM prefix pattern; use an eight-byte PNG helper. [VERIFIED: modules/mb-image/codec/contracts.mbt] |
| PNG-02 | Typed structural rejection. | Private forward-only chunk machine, streaming CRC, explicit state and strict terminal read. [CITED: https://www.w3.org/TR/png-3/] |
| PNG-03 | Preflight all resource and metadata policy limits before output. | Existing checked arithmetic, `CodecLimits`, `Budget`, and metadata option contracts. [VERIFIED: modules/mb-core/checked/checked.mbt; modules/mb-image/codec/contracts.mbt] |
</phase_requirements>

## Summary

Implement one new portable public package at `modules/mb-image/png`; it owns only `PngDecoder`, its non-consuming trait probe, and private structural validation. [VERIFIED: 20-CONTEXT.md; modules/mb-image/qoi/moon.pkg] Phase 20 must not allocate an image, buffer a whole chunk/IDAT stream, add a DEFLATE dependency, or introduce a public streaming API. [VERIFIED: 20-CONTEXT.md]

The validator must read the entire PNG transport using a fixed small scratch buffer, charge every byte against `CodecLimits.max_input_bytes`, and CRC every chunk over type plus data. [CITED: https://www.w3.org/TR/png-3/] Its state accepts exactly signature → first-and-only 13-byte IHDR → one-or-more contiguous IDAT → empty IEND → strict EOF; semantic exclusions and opaque-metadata policy are resolved while chunks are still bounded and before any future allocation. [VERIFIED: 20-CONTEXT.md]

**Primary recommendation:** Create `tchivs/mb-image/png` now with `PngDecoder::new()` and an `ImageDecoder` implementation; its `decode` performs the full structural gate and, on an otherwise valid Phase-20 stream, terminates with the existing typed `capability_unavailable("png-decode", "deflate-and-raster-pending")` rather than exposing a placeholder image. [VERIFIED: 20-CONTEXT.md; modules/mb-image/codec/contracts.mbt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Prefix identification | Library codec boundary | Caller-owned bytes | Probe consumes no `Reader` data and returns existing `ProbeOutcome`. [VERIFIED: modules/mb-image/codec/contracts.mbt] |
| PNG signature, chunks, CRC, terminal rule | Library codec boundary | `mb-core/io` | The PNG package owns format state; I/O supplies exact forward progress. [VERIFIED: modules/mb-core/io/exact.mbt; CITED: https://www.w3.org/TR/png-3/] |
| Resource preflight | Library codec boundary | `checked` and `budget` | PNG derives quantities, while the shared primitives own overflow and authoritative charging. [VERIFIED: modules/mb-core/checked/checked.mbt; modules/mb-core/budget/budget.mbt] |
| Metadata disposition decision | Library codec boundary | `codec.DecodeOptions` | Preserve-or-fail is a decoder policy; Phase 20 must never silently drop opaque data. [VERIFIED: modules/mb-image/codec/contracts.mbt; 20-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` | Build and four-target package tests | Installed project toolchain. [VERIFIED: local `moon --version`] |
| `tchivs/mb-core/checked` | workspace `0.1.0` | Checked `UInt64` add/multiply and backend narrowing | Existing codecs use it before resource checks. [VERIFIED: modules/mb-core/checked/checked.mbt; modules/mb-image/qoi/decode.mbt] |
| `tchivs/mb-core/budget` | workspace `0.1.0` | Atomic multi-dimension resource charge | `Budget::charge` preflights every ancestor before committing. [VERIFIED: modules/mb-core/budget/budget.mbt] |
| `tchivs/mb-core/bytes`, `io`, `error` | workspace `0.1.0` | Fixed scratch, exact forward reads, typed errors | Established QOI/PPM decoder pattern. [VERIFIED: modules/mb-image/qoi/decode.mbt; modules/mb-image/ppm/decode.mbt] |
| `tchivs/mb-image/codec` | workspace `0.1.0` | Existing eager public seam, limits, options, diagnostics | Avoids a PNG-only public API. [VERIFIED: modules/mb-image/codec/contracts.mbt] |

**Installation:** None — Phase 20 adds no external package. [VERIFIED: 20-CONTEXT.md]

## Package Legitimacy Audit

Not applicable: Phase 20 installs no external packages. [VERIFIED: 20-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
caller ByteView ──> PngDecoder.probe ──> NeedMore(8) | Match | NoMatch

forward Reader ──> bounded PNG input counter ──> ChunkMachine
                                                ├─ signature / IHDR subset gate
                                                ├─ streaming CRC-32(type + data)
                                                ├─ IDAT contiguous transport validation
                                                ├─ ancillary policy gate
                                                └─ empty IEND + one-byte EOF check
                                                           │
                                                           ├─ invalid / unsupported / limit: CoreError
                                                           └─ structurally valid: capability_unavailable
                                                               (Phase 21 supplies DEFLATE + image result)
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── moon.pkg                 # four targets; imports only codec/core helpers
├── png.mbt                  # public PngDecoder and private eight-byte probe
├── structural.mbt           # private chunk state, CRC, semantic and limit preflight
├── png_test.mbt             # public trait/probe/decode behavior
└── structural_wbtest.mbt    # state, CRC, arithmetic, fixture-derived internals
fixtures/png/cases.json      # generated, small hostile structural vectors
scripts/fixtures/Generate-PngStructuralVectors.ps1
```

Keep all parser structs/enums and CRC helpers private. [VERIFIED: modules/mb-image/ppm/parser.mbt; 20-CONTEXT.md] The only Phase-20 public type should be `PngDecoder`; defer `PngEncoder` to Phase 22 and any push/pull types indefinitely. [VERIFIED: 20-CONTEXT.md; .planning/ROADMAP.md]

### Pattern 1: Existing eager seam with a staged terminal capability

**What:** Implement `@codec.ImageDecoder` so probe remains available through the common trait, while `decode` completely validates framing and then returns the existing capability error because no raster result exists yet. [VERIFIED: modules/mb-image/codec/contracts.mbt; 20-CONTEXT.md]

**Why:** This retains one stable public call shape. Phase 21 changes only the terminal success behavior after DEFLATE/raster work is available; it does not add a competing validation or streaming interface. [VERIFIED: 20-CONTEXT.md]

```moonbit
// Pattern source: modules/mb-image/qoi/decode.mbt
pub impl @codec.ImageDecoder for PngDecoder with fn probe(
  _self, prefix, limits, _diagnostics,
) {
  if prefix.length() > limits.max_probe_bytes() {
    return Err(png_limit("probe-bytes", prefix.length(), limits.max_probe_bytes()))
  }
  Ok(_probe_png_prefix(prefix))
}
```

`_probe_png_prefix` follows the QOI/PPM closed-prefix convention: fewer than eight caller bytes is `NeedMore(8)`, otherwise exact PNG signature is `Match` and any other eight-byte prefix is `NoMatch`. [VERIFIED: modules/mb-image/qoi/qoi.mbt; modules/mb-image/ppm/ppm.mbt]

### Pattern 2: Streaming chunk state, never chunk-sized allocation

**What:** Read `length(4)`, `type(4)`, payload, and CRC with fixed scratch; update CRC as type and each payload byte are read. [CITED: https://www.w3.org/TR/png-3/]

**Required private state:** `BeforeIhdr`, `BeforeIdat`, `InIdat`, `AfterIdat`, `Finished`. [VERIFIED: 20-CONTEXT.md]

| State / event | Required action |
|---------------|-----------------|
| `BeforeIhdr` / anything but `IHDR` | Data/invalid-encoding failure; IHDR must be first and length 13. [CITED: https://www.w3.org/TR/png-3/] |
| `IHDR` | Verify CRC, positive width/height, bit depth 8, type 2 or 6, compression 0, filter 0, interlace 0; derive checked pixels, row bytes, filtered output, work, and allocation envelope. [VERIFIED: 20-CONTEXT.md; modules/mb-core/checked/checked.mbt] |
| `InIdat` / `IDAT` | CRC and discard transport payload; retain `InIdat`. [CITED: https://www.w3.org/TR/png-3/] |
| `InIdat` / non-`IDAT` | Transition once to `AfterIdat`; no later IDAT is legal. [CITED: https://www.w3.org/TR/png-3/] |
| `IEND` | Require post-IDAT, data length 0, valid CRC, then read one byte: EOF succeeds; a byte is trailing-data failure. [VERIFIED: 20-CONTEXT.md; modules/mb-image/ppm/decode.mbt] |

### Pattern 3: Explicit semantic-chunk and metadata policy

Reject all unknown critical chunks and known palette, transparency, colour-management/HDR, and animation chunks, after validating their available structural framing/CRC. [VERIFIED: 20-CONTEXT.md] For an unknown ancillary type, CRC-check and boundedly discard it only when `DecodeOptions.preserve_opaque_metadata()` is false; when true, fail with `capability_unavailable("png-decode", "opaque-metadata-preservation")`. [VERIFIED: modules/mb-image/codec/contracts.mbt; 20-CONTEXT.md] Phase 21 will report the permitted discard as a lossy `MetadataDisposition`; Phase 20 has no successful `DecodeResult` to carry one. [VERIFIED: modules/mb-image/metadata/metadata.mbt; 20-CONTEXT.md]

### Anti-Patterns to Avoid

- **Whole-chunk or whole-IDAT buffering:** chunk length is untrusted and must never become an allocation request. [VERIFIED: .planning/research/PITFALLS.md]
- **Accepting IEND before IDAT or a nonempty IEND:** violates the locked accepted profile. [VERIFIED: 20-CONTEXT.md]
- **Treating CRC as a later DEFLATE concern:** PNG CRC covers each chunk's type+data, while zlib Adler-32 is Phase 21. [CITED: https://www.w3.org/TR/png-3/]
- **Relaxing trailing input with `require_complete_input=false`:** D-03 requires strict post-IEND EOF for Phase 20. [VERIFIED: 20-CONTEXT.md]
- **Adding `PngStreamDecoder`/`PngStreamEncoder`:** explicitly deferred public API. [VERIFIED: 20-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Overflow-safe geometry | ad-hoc multiplication guards | `@checked.checked_add` / `checked_mul` | Stable typed overflow errors and portable `UInt64` contract. [VERIFIED: modules/mb-core/checked/checked.mbt] |
| Allocation/resource authority | package-local counters | `@budget.Budget` + `OwnedImage::new_operation` later | Shared budget preflights the whole charge atomically. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-image/storage/owned_image.mbt] |
| Exact short-progress I/O | direct Reader loop | `@io.read_exact` with one-byte/fixed scratch | Existing decoders preserve typed end/no-progress/host failures. [VERIFIED: modules/mb-image/qoi/decode.mbt] |
| Codec API | PNG-specific result or streaming protocol | `@codec.ImageDecoder`, `CodecLimits`, `DecodeOptions` | Already expresses probe, limits, diagnostics, metadata preference, and typed results. [VERIFIED: modules/mb-image/codec/contracts.mbt] |

## Common Pitfalls

### CRC scope and state drift

**What goes wrong:** CRC is calculated over payload only, skipped for discarded ancillary chunks, or checked after the next header is consumed.  
**How to avoid:** Seed CRC with the four type bytes; update per payload byte; compare the final four-byte big-endian CRC before accepting the chunk transition. [CITED: https://www.w3.org/TR/png-3/]

### Preflight after trust or allocation

**What goes wrong:** `width * height`, rows, output, or work wraps or an image is allocated before one of the ceilings is checked.  
**How to avoid:** Calculate with `checked_mul`/`checked_add`, compare every derived value to `CodecLimits`, and reserve no image output in this phase. [VERIFIED: modules/mb-image/qoi/decode.mbt; 20-CONTEXT.md]

### Semantic metadata loss

**What goes wrong:** A decoder ignores `PLTE`, `tRNS`, colour/HDR, or APNG chunks and thereby pretends an RGB/RGBA image has unchanged semantics.  
**How to avoid:** Explicitly classify and reject those known chunks; only unknown ancillary chunks enter the preserve-or-discard branch. [VERIFIED: 20-CONTEXT.md]

### Test/policy drift

**What goes wrong:** A new `png` directory is compiled locally but quality policy rejects its package inventory or fixture provenance.  
**How to avoid:** Plan a policy/manifest/vector-generator update in the same wave as the package, then run the required quality lane. [VERIFIED: policy/foundation.json; scripts/quality/Assert-Policy.ps1; docs/policies/licensing-and-fixtures.md]

## Code Examples

### Checked structural preflight

```moonbit
// Pattern source: modules/mb-image/qoi/decode.mbt
let pixels = @checked.checked_mul(width, height)?
let row_bytes = @checked.checked_mul(width, channels)? // channels = 3 or 4
let filtered_row = @checked.checked_add(row_bytes, 1UL)?
let filtered_output = @checked.checked_mul(filtered_row, height)?
for item in [
  ("width", width, limits.max_width()),
  ("height", height, limits.max_height()),
  ("pixels", pixels, limits.max_pixels()),
  ("output-bytes", filtered_output, limits.max_output_bytes()),
] { png_limit(item.0, item.1, item.2)? }
```

The exact work/allocation formula is private implementation discretion, but every component must be checked before use and must be bounded by `max_work`, `max_input_bytes`, and the supplied `Budget` before Phase 21 creates output storage. [VERIFIED: 20-CONTEXT.md; modules/mb-image/codec/contracts.mbt]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Phase 19 has QOI as the latest image codec | v0.6 establishes PNG structural safety before inflater/raster output | Phase 20 creates no image and has no encoder. [VERIFIED: .planning/ROADMAP.md] |
| QOI exposes public streaming types | PNG is deliberately eager-only at the public boundary | Private incremental parser state is allowed; public push/pull API is not. [VERIFIED: 20-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A structurally valid Phase-20 `decode` should terminate in `capability_unavailable` until Phase 21 can construct an image. | Summary / Pattern 1 | The planner may need a different temporary public validation entry point. |

This is the only implementation-shape inference. It preserves the locked trait seam but requires confirmation while planning; all other acceptance behavior comes from the locked context or checked code/spec sources. [ASSUMED]

## Open Questions

1. **Terminal valid-stream behavior before Phase 21**
   - What we know: `ImageDecoder::decode` can only return `DecodeResult`, which contains an `OwnedImage`; Phase 20 cannot expose an image. [VERIFIED: modules/mb-image/codec/contracts.mbt; 20-CONTEXT.md]
   - Recommendation: use the existing capability error after full validation, preserving all invalid-stream errors; confirm this staged behavior before API baseline policy is written. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | Compile/test portable package | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| `moonc` | MoonBit compiler | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local `moonc -v`] |
| `moonrun` | Test runner | ✓ | `0.1.20260713` | — [VERIFIED: local `moonrun --version`] |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Exact signature, explicit chunk state, CRC, known-field checks, and typed errors. [CITED: https://www.w3.org/TR/png-3/] |
| V6 Cryptography | no | CRC-32 is integrity/error detection, not a security primitive; do not treat it as cryptography. [ASSUMED] |
| V10 Malicious Code | yes | Input/output/work/allocation ceilings and no FFI/decompression in this phase. [VERIFIED: 20-CONTEXT.md] |

### Known Threat Patterns for portable binary parsers

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Length-driven allocation or arithmetic wrap | Denial of service | Fixed scratch, checked arithmetic, `CodecLimits`, and `Budget`. [VERIFIED: modules/mb-core/checked/checked.mbt; modules/mb-core/budget/budget.mbt] |
| Chunk reordering / duplicate terminal chunks | Tampering | Explicit state machine; require first/only IHDR, contiguous IDAT, one empty IEND, EOF. [CITED: https://www.w3.org/TR/png-3/] |
| Corrupted skipped metadata | Tampering | CRC-check ancillary chunks even when discard is allowed. [VERIFIED: 20-CONTEXT.md] |

## Sources

### Primary

- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — signature, chunk framing/order, CRC scope, IHDR/IDAT/IEND rules. [CITED: https://www.w3.org/TR/png-3/]
- [MoonBit command documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) and [package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — `moon test --target all` and the four portable targets. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]
- Existing codec and resource contracts — exact type/API and error patterns. [VERIFIED: modules/mb-image/codec/contracts.mbt; modules/mb-image/qoi/decode.mbt; modules/mb-image/ppm/decode.mbt]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all libraries and tool versions were checked locally. [VERIFIED: local tool versions and workspace source]
- Architecture: HIGH — it follows locked scope and existing QOI/PPM codec seams. [VERIFIED: 20-CONTEXT.md; modules/mb-image/qoi/decode.mbt]
- PNG structural rules: MEDIUM — verified against the current W3C specification through the research seam. [CITED: https://www.w3.org/TR/png-3/]

**Research date:** 2026-07-20  
**Valid until:** 2026-08-19
