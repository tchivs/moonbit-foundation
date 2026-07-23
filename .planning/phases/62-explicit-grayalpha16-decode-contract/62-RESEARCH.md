# Phase 62: Explicit GrayAlpha16 Decode Contract - Research

**Researched:** 2026-07-23
**Domain:** Additive, eager PNG Type-4/16 preservation in MoonBit
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Expose only `PngDecoder::decode_graya16` in this phase; use the
  existing `DecodeResult` and `graya16` storage. Do not introduce a conversion
  API or widen generic decode results.
- **D-02:** Admit only legal encoded-sRGB Type-4/16 input with straight alpha;
  reject non-sRGB/ICC and incompatible descriptors through typed existing-style
  diagnostics before producing a result.
- **D-03:** Reuse the one profile-aware decoder machine, its checked preflight,
  DEFLATE/filter framing, and raster ownership. Preserve wire MSB-first
  `Ghi,Glo,Ahi,Alo` into model LE `Glo,Ghi,Alo,Ahi` only at the final sink.
- **D-04:** Freeze the generic Type-4/16 path as `RGBA8(Ghi,Ghi,Ghi,Ahi)` and
  prove explicit preservation with an independent non-symmetric vector.

### the agent's Discretion

- Reuse the smallest existing GrayAlpha16 model and PNG decode fixtures. Chunk
  decoding, Adam7, broad hostile schedules, and all-target qualification remain
  in Phases 63–64.

### Deferred Ideas (OUT OF SCOPE)

- Caller-buffered public preservation, Adam7/filter qualification, broad hostile
  schedules, four-target gates, colour-managed conversion, and any conversion
  API belong to later phases or milestones.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRA16DEC-01 | Library users explicitly decode legal sRGB Type-4/16 PNG input through `PngDecoder::decode_graya16`, receiving existing little-endian packed `graya16` bytes while generic decode remains `RGBA8(Ghi,Ghi,Ghi,Ahi)`. | The public method, private profile, preflight gate, sink mapping, independent literal oracle, and generic anchor below directly prove this contract. [VERIFIED: codebase] |

## Summary

Phase 62 should add exactly one associated eager operation, `PngDecoder::decode_graya16`, returning the existing `@codec.DecodeResult`. It must choose a private `GrayAlpha16` decode profile before first-IDAT allocation, then retain the current parser, CRC, IDAT/DEFLATE, bytewise unfiltering, owned raster lifecycle, and EOF-only result transfer. [VERIFIED: codebase] The phase must not add a chunk constructor, a conversion operation, a generic option/union, a second decoder machine, or an image-sized staging raster. [VERIFIED: 62-CONTEXT.md]

The profile accepts non-interlaced Type-4/16 images whose authenticated colour declaration is either absent or `sRGB`; it writes reconstructed wire bytes `Ghi,Glo,Ahi,Alo` only at the final sink as packed little-endian `graya16` bytes `Glo,Ghi,Alo,Ahi`. [VERIFIED: 62-CONTEXT.md] PNG colour type 4 is grayscale followed by alpha, allows 8- and 16-bit samples, stores 16-bit samples MSB-first, filters bytes rather than pixels, and defines unassociated alpha. [CITED: https://www.w3.org/TR/png-3/]

**Primary recommendation:** Add one private `PngDecodeProfile::GrayAlpha16` path to the existing eager machine; gate it at first-IDAT preflight and give it one final four-byte sink writer, while leaving `PngDecoder::new()` and `PngChunkDecoder::new()` on the current generic RGBA8 profile. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Explicit eager Type-4/16 selection | API / Backend | — | `PngDecoder` owns the reader-based public API; no browser, FFI, or external service participates. [VERIFIED: codebase] |
| Profile admission and resource preflight | API / Backend | Storage | The decode machine has authenticated IHDR/colour facts before allocating `OwnedImage`; the profile determines truthful descriptor and budget layout. [VERIFIED: codebase] |
| PNG byte reconstruction | API / Backend | — | The shared raster sink already owns DEFLATE output, bytewise filter reconstruction, and row state. [VERIFIED: codebase] |
| U16 component-byte preservation | Storage | API / Backend | Existing `graya16()` and component-byte views represent the required little-endian destination; the PNG sink supplies bytes only after reconstruction. [VERIFIED: codebase] |
| Legacy generic compatibility | API / Backend | Storage | The generic decoder retains the current RGBA8 result and is proven by a public regression on the same wire input. [VERIFIED: codebase] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit-first; native FFI is neither needed nor permitted as a shortcut for this byte mapping. [VERIFIED: AGENTS.md]
- Preserve public modularity, deterministic GUI-free operations, and SemVer-compatible additive API behavior. [VERIFIED: AGENTS.md]
- Do not silently redefine ecosystem boundaries; this change stays in the existing `mb-image/png` package and existing model/storage types. [VERIFIED: AGENTS.md]
- Keep the generic decoder's public contract stable; experimental additions must be visibly opt-in. [VERIFIED: AGENTS.md]
- Use the project knowledge-graph MCP for code discovery when available; it was not exposed in this research runtime, so direct code inspection supplied the cited local evidence. [VERIFIED: AGENTS.md]
- Execution must run through the applicable GSD workflow; this research artifact is the only direct file change in this task. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `modules/mb-image/png` | workspace | Public PNG API, shared decode machine, structural preflight, and raster sink | It already contains the only bounded eager decoding pipeline and current Type-4/16 narrowing boundary. [VERIFIED: codebase] |
| `@model.ImageFormat::graya16()` | workspace | Packed LE U16 Gray+Alpha destination | It is the existing validated `U16 + GrayAlpha + Packed + Little` format. [VERIFIED: codebase] |
| `@storage.ImageView::get_component_byte` / `MutImageView::set_component_byte` | workspace | Observable and writable U16 storage-order bytes | These existing APIs intentionally cover packed U8/U16 components, unlike U8-only `get_byte`. [VERIFIED: codebase] |
| `@codec.DecodeResult` | workspace | Existing eager result ownership and byte count | It already carries the image, metadata disposition, and `bytes_read`; no result widening is necessary. [VERIFIED: codebase] |

### Supporting

| Library / module | Version | Purpose | When to Use |
|------------------|---------|---------|
| `@codec.capability_unavailable` | workspace | Existing-style typed profile rejection | Use only for structurally valid PNGs outside the explicit preservation profile. [VERIFIED: codebase] |
| `@checked` arithmetic and existing decode budgets | workspace | Checked output, row, and work accounting | Reuse for the profile's one four-bytes-per-pixel result and two source rows. [VERIFIED: codebase] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Private profile in the one decode machine | Separate decoder or image-sized raw staging | Rejected: duplicates framing/lifecycle or violates the locked no-staging boundary. [VERIFIED: 62-CONTEXT.md] |
| Explicit eager method | `DecodeOptions` precision flag or widened generic result | Rejected: changes every generic caller's contract instead of making preservation opt-in. [VERIFIED: 62-CONTEXT.md] |
| Existing `graya16` | New RGB16/RGBA16 model or big-endian storage | Rejected: the required model already exists and is contractually little-endian. [VERIFIED: codebase] |

**Installation:** None — this phase installs no external package. [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```text
PngDecoder::decode_graya16(reader, options, limits, budget, diagnostics)
                               |
                               v
                 PngDecodeMachine::new_with_profile(GrayAlpha16)
                               |
                               v
       existing framing / CRC / authenticated IHDR + colour facts
                               |
               first-IDAT profile gate (before OwnedImage allocation)
              /                 |                    \
     Type-4/16 + default/sRGB    |                     \ incompatible profile
              |                  |                      -> typed capability error
              v                  v
     existing DEFLATE + bytewise PNG filters (bpp = 4 source bytes)
                               |
                               v
       profile-aware final sink: Ghi,Glo,Ahi,Alo -> Glo,Ghi,Alo,Ahi
                               |
                               v
              existing DecodeResult only after terminal EOF success

Generic ImageDecoder::decode(PngDecoder::new(), ...)
                               |
                               v
              unchanged generic profile -> RGBA8(Ghi,Ghi,Ghi,Ahi)
```

The explicit and generic routes must share all input processing and differ only in private profile selection, descriptor/budget choice, and final sink mapping. [VERIFIED: codebase]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                    # add the sole public eager selector
├── stream_decode.mbt          # private profile, first-IDAT gate, one machine
├── structural.mbt             # profile-aware descriptor/budget helpers
├── raster_decode.mbt          # profile-aware final Type-4/16 sink writer
├── png_test.mbt               # public literal decode + generic compatibility oracle
└── stream_decode_wbtest.mbt   # package-private no-allocation rejection evidence
```

### Pattern 1: Explicit associated eager selector

**What:** Add the one requested API; keep the trait-based generic method untouched. [VERIFIED: 62-CONTEXT.md]

**When to use:** A caller specifically requires source-precision Gray+Alpha16 storage and accepts the narrow encoded-sRGB Type-4/16 contract. [VERIFIED: 62-CONTEXT.md]

```moonbit
pub fn PngDecoder::decode_graya16(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[@codec.DecodeResult, @error.CoreError] {
  ignore(diagnostics)
  PngDecodeMachine::new_with_profile(
    PngDecodeProfile::GrayAlpha16, options, limits, budget,
  ).decode_reader(reader)
}
```

This signature mirrors the existing generic decoder inputs and returns its established result type; it is the only public API addition in Phase 62. [VERIFIED: codebase]

### Pattern 2: Profile resolved before allocation; one sink conversion boundary

**What:** `PngDecodeProfile::GenericRgba8 | GrayAlpha16` stays private in `PngDecodeMachine`; `preflight_first_idat` uses it after colour facts are CRC-authenticated and before `OwnedImage::new_operation`. [VERIFIED: codebase]

**When to use:** Always for the explicit path; Phase 62 keeps interlaced input outside the profile rather than implementing an Adam7 scatter writer early. [VERIFIED: 62-CONTEXT.md]

```moonbit
match (self.profile, ihdr[9], ihdr[8], ihdr[12], declaration) {
  (GrayAlpha16, b'\x04', b'\x10', b'\x00', Default | Srgb(_)) => ()
  (GrayAlpha16, _, _, _, _) =>
    return Err(@codec.capability_unavailable("png-decode", "graya16-profile"))
  _ => ()
}
// Then derive graya16 descriptor/budget and construct the one existing sink.
```

Use distinct stable contexts such as `graya16-type-depth`, `graya16-interlace`, and `graya16-colour` if the existing error convention allows separate causes; tests must assert the selected category, code, operation, and context. [VERIFIED: codebase]

### Pattern 3: Preserve only after bytewise reconstruction

**What:** Keep the current Type-4/16 `source_bytes_per_pixel == 4` filter distance. At the final completed-pixel writer, place reconstructed row bytes in destination component-byte order. [VERIFIED: codebase]

```moonbit
// rows are reconstructed PNG bytes: Ghi, Glo, Ahi, Alo
view.set_component_byte(x, y, 0UL, 0UL, rows.current(offset + 1UL))? // Glo
view.set_component_byte(x, y, 0UL, 1UL, rows.current(offset + 0UL))? // Ghi
view.set_component_byte(x, y, 1UL, 0UL, rows.current(offset + 3UL))? // Alo
view.set_component_byte(x, y, 1UL, 1UL, rows.current(offset + 2UL))? // Ahi
```

The PNG standard requires bytewise filtering and MSB-first 16-bit samples; conversion before reconstruction would be wrong. [CITED: https://www.w3.org/TR/png-3/]

### Anti-Patterns to Avoid

- **Generic widening:** Do not alter `ImageDecoder::decode`, `PngDecoder::new`, `PngChunkDecoder::new`, `DecodeOptions`, or `DecodeResult`. [VERIFIED: 62-CONTEXT.md]
- **Fallback conversion:** Do not silently return RGBA8 from `decode_graya16`; a profile mismatch must return a typed error. [VERIFIED: 62-CONTEXT.md]
- **Premature byte swapping:** Do not swap/filter U16 words or choose high bytes before the row is reconstructed with `bpp = 4`. [CITED: https://www.w3.org/TR/png-3/]
- **Premultiplication or colour conversion:** Type-4 alpha stays straight and this profile promises encoded-sRGB identity only. [CITED: https://www.w3.org/TR/png-3/]
- **Phase leakage:** Do not add `PngChunkDecoder::new_graya16`, Adam7 support, broad hostile schedules, or all-target qualification in Phase 62. [VERIFIED: 62-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PNG parser, chunk order, CRC, IDAT contiguity | New Type-4/16 parser | Existing `PngDecodeMachine` | It already owns strict framing and terminal-state behavior. [VERIFIED: codebase] |
| DEFLATE / filter reconstruction | Alternate raster pipeline | Existing inflater and packed row reconstruction | PNG filters operate on encoded bytes and must remain shared. [VERIFIED: codebase] |
| U16 image storage | New high-precision image type | Existing `ImageFormat::graya16` plus component-byte views | The model has the exact LE straight-alpha identity required. [VERIFIED: codebase] |
| Result wrapper / conversion operation | New public result variant | Existing `DecodeResult` | The result already owns image, metadata, and byte count. [VERIFIED: codebase] |

**Key insight:** The missing behavior is one final byte-placement choice, not a missing decoding subsystem; all preceding decode semantics must remain single-sourced. [VERIFIED: codebase]

## Common Pitfalls

### Pitfall 1: Low-byte loss hidden by symmetric values

**What goes wrong:** A test uses `Ghi == Glo` or `Ahi == Alo`, allowing a high-byte-only implementation to appear correct. [VERIFIED: v020-PITFALLS.md]

**How to avoid:** Use two literal pixels with all four lanes distinct: wire `(12,34,A7,C5)` and `(BE,0F,5A,76)`, expecting storage `(34,12,C5,A7)` and `(0F,BE,76,5A)`. [VERIFIED: codebase]

### Pitfall 2: Wrong filter stride or swap timing

**What goes wrong:** Treating Type-4/16 as two U16 words during filter reconstruction changes PNG filter semantics. [CITED: https://www.w3.org/TR/png-3/]

**How to avoid:** Retain `source_bytes_per_pixel = 4` and swap only inside the profile sink after the row is reconstructed. [VERIFIED: codebase]

### Pitfall 3: Incompatible metadata creates a falsely labelled result

**What goes wrong:** A gAMA/cHRM or iCCP declaration is represented as built-in encoded sRGB solely because `graya16` requires that identity. [VERIFIED: codebase]

**How to avoid:** At the first-IDAT profile gate, accept only `Default` and `Srgb`; reject `Legacy` and `Icc` with existing-style `CapabilityUnavailable` diagnostics before lifecycle allocation. [VERIFIED: codebase]

### Pitfall 4: Legacy contract drift

**What goes wrong:** Reusing the new sink for the generic profile changes existing RGBA8 output or its descriptor. [VERIFIED: codebase]

**How to avoid:** Keep the current generic row writer and assert the same literal source remains `RGBA8(Ghi,Ghi,Ghi,Ahi)`. [VERIFIED: codebase]

### Pitfall 5: Pulling Phase 63/64 work forward

**What goes wrong:** Adding a public chunk selector, Adam7 scatter path, broad filter corpus, or all-target matrix expands the phase and obscures the eager contract. [VERIFIED: 62-CONTEXT.md]

**How to avoid:** Explicitly reject Adam7 from the Phase 62 preservation profile and leave chunk/fidelity qualification to their scheduled phases. [VERIFIED: 62-CONTEXT.md]

## Code Examples

### Independent non-symmetric public oracle

```moonbit
let result = PngDecoder::decode_graya16(
  @io.MemoryReader::new(owner.view()) as &@io.Reader,
  options, limits, budget, @error.Diagnostics::new(),
).unwrap()
let image = result.image().view()

// Pixel 0 wire: 12 34 A7 C5. Storage must be 34 12 C5 A7.
inspect(image.get_component_byte(0UL, 0UL, 0UL, 0UL).unwrap(), content="52")
inspect(image.get_component_byte(0UL, 0UL, 0UL, 1UL).unwrap(), content="18")
inspect(image.get_component_byte(0UL, 0UL, 1UL, 0UL).unwrap(), content="197")
inspect(image.get_component_byte(0UL, 0UL, 1UL, 1UL).unwrap(), content="167")
```

The fixture must be a hand-authored complete PNG literal (including a known Stored-DEFLATE payload and chunk CRCs), not bytes emitted by `PngEncoder`; this keeps the decode oracle independent of the implementation under test. [VERIFIED: v020-PITFALLS.md]

### Generic compatibility anchor

```moonbit
let generic = @codec.ImageDecoder::decode(
  PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
  options, limits, budget, @error.Diagnostics::new(),
).unwrap().image().view()

// Same first wire pixel: Ghi=12, Ahi=A7.
for channel = 0UL; channel < 3UL; channel = channel + 1UL {
  inspect(generic.get_byte(0UL, 0UL, channel).unwrap(), content="18")
}
inspect(generic.get_byte(0UL, 0UL, 3UL).unwrap(), content="167")
```

This matches the existing public Type-4/16 compatibility assertion and prevents an accidental default-path change. [VERIFIED: codebase]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic Type-4/16 canonicalization only | Add opt-in eager preservation while retaining canonicalization | Phase 62 | Callers choose precision explicitly; legacy callers remain unchanged. [VERIFIED: 62-CONTEXT.md] |

**Deprecated/outdated:** Treating the generic decoder's high-byte mapping as a lossless Type-4/16 result is invalid; it is deliberately frozen as an RGBA8 compatibility conversion. [VERIFIED: codebase]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Separate stable contexts for type/depth, interlace, and colour rejection can be introduced under the existing capability-error convention. | Architecture Patterns | Tests may need to use one shared profile context instead of several. [ASSUMED] |

## Open Questions

1. **Exact diagnostic context spelling**
   - What we know: the project has `@codec.capability_unavailable` and typed category/code/context assertions. [VERIFIED: codebase]
   - What's unclear: no existing `decode_graya16` context names exist. [VERIFIED: codebase]
   - Recommendation: choose one `graya16-profile` context or the three context names described above during implementation, then lock it in public tests; do not invent a new error type. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | Compile and PNG package tests | ✓ | `0.1.20260713` | — [VERIFIED: local command] |
| `moonc` / `moonrun` | MoonBit toolchain execution | ✓ | `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local command] |

**Missing dependencies with no fallback:** None. [VERIFIED: local command]

**Missing dependencies with fallback:** None. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No authentication surface. [VERIFIED: codebase] |
| V3 Session Management | No | No session surface. [VERIFIED: codebase] |
| V4 Access Control | No | No access-control surface. [VERIFIED: codebase] |
| V5 Input Validation | Yes | Existing strict PNG framing, profile admission before allocation, checked limits, and typed errors. [VERIFIED: codebase] |
| V6 Cryptography | No | PNG CRC/integrity framing is existing format validation; no cryptographic feature is added. [VERIFIED: codebase] |

### Known Threat Patterns for MoonBit PNG decode

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Resource exhaustion via large image/row/work values | Denial of service | Keep checked preflight and one-output/two-row budget accounting before `OwnedImage` allocation. [VERIFIED: codebase] |
| Crafted metadata misrepresented as encoded sRGB | Tampering | Reject Legacy and ICC declarations for the explicit profile before allocation. [VERIFIED: 62-CONTEXT.md] |
| Precision or endian corruption | Tampering | Reconstruct PNG bytes first, then store the four lanes exactly once in LE component-byte order. [CITED: https://www.w3.org/TR/png-3/] |

## Test-Driven Delivery and Commands

| Order | Test work | Closest existing anchor | Command |
|------:|-----------|-------------------------|---------|
| 1 | Add a literal non-interlaced Type-4/16 public fixture; assert `graya16`, straight encoded-sRGB identity, exact `Glo,Ghi,Alo,Ahi`, and normal `bytes_read`. | `encode_test.mbt` GrayAlpha16 wire/decode test | `moon -C modules/mb-image test png --frozen` [VERIFIED: local command] |
| 2 | Decode the exact same literal through generic `ImageDecoder::decode(PngDecoder::new(), ...)`; assert frozen `RGBA8(Ghi,Ghi,Ghi,Ahi)`. | `png_encode_graya16_public_decode_is_canonical` | `moon -C modules/mb-image test png --frozen` [VERIFIED: local command] |
| 3 | Exercise non-Type-4/16, legacy-colour/ICC, and Adam7 explicit inputs; assert typed capability result and no private lifecycle allocation. | `stream_decode_wbtest.mbt` first-IDAT atomicity | `moon -C modules/mb-image test png --frozen` [VERIFIED: local command] |

**Baseline observed:** `moon -C modules/mb-image test png --frozen` passed 227 tests in this environment before Phase 62 changes. [VERIFIED: local command]

**Phase boundary:** Do not make `--target all`, five-filter, Adam7 preservation, or chunk-schedule tests Phase 62 gates; they are explicitly assigned to Phases 63–64. [VERIFIED: 62-CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- `62-CONTEXT.md`, `ROADMAP.md`, and `REQUIREMENTS.md` — locked scope, GRA16DEC-01, and Phase 62 exclusions. [VERIFIED: codebase]
- `.planning/research/v020-SUMMARY.md`, `v020-ARCHITECTURE.md`, and `v020-PITFALLS.md` — established profile, sink, compatibility, and independent-oracle guidance. [VERIFIED: codebase]
- `modules/mb-image/png/{png,stream_decode,structural,raster_decode}.mbt` — actual API, preflight, machine, budget, and current narrowing seams. [VERIFIED: codebase]
- `modules/mb-image/{model/descriptor,storage/views}.mbt` and PNG tests — existing `graya16` model, component-byte access, and closest regression patterns. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — Type-4 sample order, MSB-first 16-bit bytes, straight alpha, and bytewise filtering. [CITED: https://www.w3.org/TR/png-3/]
- [MoonBit command-line help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) and [package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — `moon test`, `--frozen`, and `--target all` behavior. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all required package/model/storage seams already exist in the workspace. [VERIFIED: codebase]
- Architecture: HIGH — current machine construction, first-IDAT allocation, bytewise Type-4/16 row writer, and terminal result transfer are directly inspected. [VERIFIED: codebase]
- Pitfalls: HIGH — each risk has an observable existing narrowing or allocation anchor plus a literal regression strategy. [VERIFIED: codebase]

**Research date:** 2026-07-23
**Valid until:** Phase 62 planning completion; this is repository-specific and should be rechecked if the decoder seams change. [ASSUMED]
