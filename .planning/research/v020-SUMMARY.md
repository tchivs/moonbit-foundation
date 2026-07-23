# v0.20 Research Summary: High-Precision GrayAlpha Decode

**Project:** MoonBit Native Foundation
**Milestone:** v0.20 High-Precision GrayAlpha Decode
**Researched:** 2026-07-23
**Confidence:** HIGH for repository contracts; MEDIUM for independently retrieved PNG and MoonBit documentation.

## Executive Summary

v0.20 should add one portable, explicit PNG Type-4/16 preservation profile to `mb-image`. It is not a general 16-bit decoder initiative: an opt-in caller receives the existing packed little-endian `graya16()` representation with exact grey and straight-alpha component bytes, while every established generic PNG entry point continues to return its compatible RGBA8 high-byte canonicalization.

Implement the feature inside the one existing bounded PNG decode machine. Select a private result profile before image allocation; retain framing, CRC, IDAT, DEFLATE, byte-domain filter reconstruction, Adam7 traversal, caller-buffered lifecycle, and EOF-only result transfer. The sole new raster behavior is the final storage mapping `Ghi,Glo,Ahi,Alo` (PNG wire) to `Glo,Ghi,Alo,Ahi` (packed little-endian destination). The decisive risks are accidental narrowing, endian/filter-order mistakes, unrepresentable colour metadata, resource under-accounting, and legacy-facade drift; each has direct fixture and regression evidence.

## Locked Public Contract

Recommend locking this additive surface:

```moonbit
PngDecoder::decode_graya16(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[@codec.DecodeResult, @error.CoreError]

PngChunkDecoder::new_graya16(
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> PngChunkDecoder
```

- `new_graya16` retains the current `push` and `finish` lifecycle; `finish()` remains the only chunk result-transfer boundary and returns the existing `DecodeResult`.
- Successful results are packed, little-endian `ImageFormat::graya16()`, `AlphaMode::Straight`, top-left, built-in encoded-sRGB identity, with two U16 components in `Glo,Ghi,Alo,Ahi` storage order.
- The profile accepts only structurally valid Type-4/16 PNGs that have no colour declaration or an `sRGB` declaration. It rejects gAMA/cHRM and iCCP declarations before image allocation because the established descriptor cannot represent them truthfully. Existing Type-4 `tRNS` rejection remains unchanged.
- `PngDecoder::new()` through `ImageDecoder::decode` and `PngChunkDecoder::new()` are frozen compatibility routes. For the same Type-4/16 source they still return `RGBA8(Ghi,Ghi,Ghi,Ahi)`; no public trait, generic options field, result union, or default behavior changes.

## Key Findings

### Decoder, endianness, and admission constraints

| Constraint | Locked implementation rule |
|---|---|
| Wire versus storage order | Reconstruct and filter the four source bytes as PNG bytes `Ghi,Glo,Ahi,Alo`; swap only when writing destination storage as `Glo,Ghi,Alo,Ahi`. |
| Filter semantics | Type-4/16 is four source bytes per pixel (`bpp = 4`). Never filter host-endian U16 words or a converted RGBA8 result. |
| Adam7 | Reuse the shared seven-pass geometry and pass-local predictor reset; scatter fully reconstructed components through the same profile-aware store helper. |
| Allocation | Charge exactly one four-bytes-per-pixel result plus the existing two reconstructed source rows, using checked `UInt64` preflight. Do not create an image-sized wire/staging buffer. |
| Result visibility | Resolve profile and identity admission at first-IDAT preflight, before `OwnedImage`; expose nothing until ordinary eager success or chunk `finish()` after terminal validation. |
| Portability | Pure MoonBit only: existing `Bytes`, `Byte`, `UInt64`, descriptors, and component-byte views. No new module, FFI, host codec, target branch, or dependency. |

### Architecture recommendation

Use one private decode-profile enum carried by `PngDecodeMachine` and `PngChunkDecoder`. It chooses destination descriptor, output/budget layout, metadata identity admission, and the final row/Adam7 scatter writer. `structural.mbt` remains responsible for checked profile-aware preflight; `raster_decode.mbt` adds one shared Type-4/16 component-store helper; `stream_decode.mbt` carries the profile through the existing lifecycle; `png.mbt` exposes only the two explicit selectors. The parser, inflater, filters, rows, IDAT state machine, and terminal machinery remain shared.

### Non-negotiable exclusions

- No change to `ImageDecoder`, `PngDecoder::new`, `PngChunkDecoder::new`, or generic decode result behavior.
- No `DecodeOptions` precision flag, wrapper result type, generic conversion API, RGB16/RGBA16 model, or broad 16-bit decode widening.
- No Type-4/8 preservation, palette/APNG/`tRNS` expansion, colour conversion, premultiplication, non-sRGB/ICC preservation, Big-endian image storage, copied decoder, staging raster, FFI, target split, or release work.

## Implications for Roadmap

### Phase 1: Explicit contract and safe admission

**Rationale:** The public compatibility boundary and descriptor identity must be fixed before a row-writer change can allocate or expose the wrong image.

**Delivers:** `decode_graya16` and `new_graya16`; private profile selection; Type-4/16 plus sRGB-identity gate at first-IDAT preflight; profile-aware four-bytes-per-pixel checked budget; non-interlaced asymmetric direct-decode proof; frozen generic high-byte regression.

**Avoids:** default-decoder widening, mislabeled legacy/ICC colour data, and undercharged allocation.

### Phase 2: Shared raster preservation and resumable equivalence

**Rationale:** Both public selectors must reach one lifecycle and one source-byte reconstruction path, differing only at final destination storage.

**Delivers:** shared `Ghi,Glo,Ahi,Alo -> Glo,Ghi,Alo,Ahi` row/scatter helper; non-interlaced profile writer; chunk eager-equivalence under empty, one-byte, and ragged schedules; exact consumed counters, non-retention, no partial result, and sticky terminal evidence.

**Avoids:** early high-byte loss, byte/word filtering confusion, second-image allocation, and eager/chunk semantic divergence.

### Phase 3: Interlace, resource, compatibility, and target qualification

**Rationale:** Filter and Adam7 paths are where lane order defects hide; resource and legacy proof must be independent of the new happy path.

**Delivers:** all-five-filter and all-seven-pass Adam7 component-byte fixtures; exact/one-less resource cases; profile rejection before allocation; legacy eager/chunk frozen vectors; four-target PNG-package evidence on wasm, wasm-gc, js, and native.

**Avoids:** pass-local predictor errors, output visibility on failure, target-only correctness, and incidental regressions to Type-4/16 compatibility conversion.

### Phase ordering rationale

Admission precedes raster work because profile choice determines descriptor truthfulness and allocation accounting. Raster work precedes qualification because one shared sink must be proven under both eager and resumable routes. Qualification is last so its independent wire, budget, and legacy oracles test a stable public contract rather than shaping one accidentally.

## Research-Backed Requirement Recommendations

| ID | Recommended requirement | Required acceptance evidence |
|---|---|---|
| GRAYA16D-01 | Explicit eager decode of valid encoded-sRGB Type-4/16 produces packed LE, straight-alpha `graya16` with both component bytes preserved. | Independent asymmetric 2x1 wire fixture, descriptor/metadata and per-component-byte assertions, exact `bytes_read`. |
| GRAYA16D-02 | The same preservation contract works with caller-owned chunks and preserves existing completion/progress/terminal guarantees. | Empty, one-byte, and ragged schedules equal fresh eager component bytes; incomplete, malformed, limit, and sticky-error coverage. |
| GRAYA16D-03 | The profile rejects unrepresentable or non-Type-4/16 input before allocation and changes no generic decode behavior. | Type/depth/legacy-colour/ICC rejection with no result; old eager/chunk route retains `RGBA8(Ghi,Ghi,Ghi,Ahi)`, diagnostics, and counters. |
| GRAYA16D-04 | Exact Type-4/16 fidelity survives filters, Adam7, limits, and all portable targets. | Five-filter and seven-pass component-byte vectors; exact/one-less budget matrix; eager/chunk equivalence; `moon -C modules/mb-image test png --target all --frozen` evidence for all four targets. |

## Research Flags

- **Research Phase 1:** Required only to settle API spelling against local MoonBit conventions. The architectural boundary, accepted profile, and result shape are otherwise sufficiently evidenced.
- **Research Phase 2:** Skip external research. It follows established in-tree profile/machine, bytewise filter, and component-view patterns; inspect current seams while planning.
- **Research Phase 3:** Skip external research but require independent fixtures and unwrapped four-target runs. This is an evidence-design phase, not an API-discovery phase.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | HIGH | Destination representation, storage APIs, parser, filter, streaming, and budget machinery already exist locally; no dependency is proposed. |
| Features | HIGH | The narrow user contract and compatibility boundary derive directly from existing Type-4/16 encode/decode behavior and v0.19 scope. |
| Architecture | HIGH | Local decoder seams identify a single profile insertion point and final-writer loss boundary. |
| Pitfalls | HIGH | Each critical risk maps to a concrete local anchor and an observable fixture or regression. |
| PNG / target corroboration | MEDIUM | Standards and MoonBit target facts are primary documentation retrieved through the configured research seam. |

**Overall confidence:** HIGH. The sole material design choice is public selector spelling; it must remain additive and visibly opt-in.

### Gaps to Address During Planning

- Confirm the exact typed capability/encoding error and diagnostic context for an incompatible profile, reusing an established error taxonomy rather than inventing an unreviewed category.
- Confirm that no-colour-declaration and `sRGB` metadata dispositions map exactly to the existing `graya16` descriptor identity before finalizing assertions.
- Add a small independent decode fixture generator or literal fixture path; encoder-generated bytes alone cannot prove the decoder's endian/filter handling.

## Sources

### Primary local evidence

- `.planning/research/v020-STACK.md` — existing model/storage capability, exact loss boundary, stack and budget constraints.
- `.planning/research/v020-ARCHITECTURE.md` — recommended public API, identity gate, shared-machine insertion points, and evidence plan.
- `.planning/research/v020-FEATURES.md` — table stakes, exclusions, requirement candidates, and delivery order.
- `.planning/research/v020-PITFALLS.md` — failure modes, regression anchors, and hostile-input prevention criteria.
- `.planning/v0.19-INTEGRATION.md` and `.planning/milestones/v0.19-MILESTONE-AUDIT.md` — completed shared-machine, bounded replay, compatibility, and four-target baseline.

### Standards corroboration

- [W3C PNG Specification](https://www.w3.org/TR/png-3/) — Type-4 grey-plus-alpha, 16-bit samples, filtering/interlace, and `tRNS` rules.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — portable target declaration and target set.

---
*Ready for roadmap and requirements definition: yes*
