# Project Research Summary

**Project:** MoonBit Native Foundation — v0.19 GrayAlpha8 Adam7 PNG
**Domain:** Portable, bounded Type-4/8 PNG interlaced encoding in MoonBit
**Researched:** 2026-07-23
**Confidence:** HIGH

## Executive Summary

v0.19 is a narrow, additive `mb-image` interoperability milestone: legal packed-U8, straight-alpha `GrayAlpha` sources gain an explicitly selected Adam7 PNG encoder route. The public result must be a Type-4/depth-8 PNG with `G,A` samples and interlace method `1`; existing GrayAlpha8 constructors remain non-interlaced and their bytes remain frozen. Both eager and caller-buffered users receive the same opt-in capability.

The implementation should be deliberately small. The repository already has a complete `GrayAlpha8` profile, a shared profile-aware `PngEncodeMachine`, Adam7 pass geometry/cursors, filter selection, DEFLATE planning, atomic preflight, and resumable replay. Add the two established interlace-selection factory shapes on both public encoder facades, then remove only the `GrayAlpha8 + Adam7` rejection from shared preflight. Do not add a profile, encoder, cursor, decoder path, staging buffer, dependency, FFI, target branch, copied source tree, or release wrapper.

The main risks are semantic rather than algorithmic: malformed seven-pass traversal, cross-pass adaptive predictor history, bypassing the atomic ledger, lease mutation before replay drift is rejected, and accidental legacy drift. The remedy is literal non-symmetric seven-pass evidence, all six compression/filter pairs, fresh hostile lease schedules, atomic-failure and pre-lease mutation tests, frozen legacy vectors, and the ordinary four-target PNG package command at one unchanged commit.

## Key Findings

### Recommended Stack

This is not a stack-selection or model-extension problem. The current `mb-image/png` package already supplies the required portable primitives. The repository's `STACK.md` still describes the prior GrayAlpha16 milestone, so it is not used as a v0.19 design authority; the current feature, architecture, pitfall research and live v0.19 project context agree that no dependency or module changes are needed.

**Core technologies:**

- **MoonBit and existing `tchivs/mb-image`:** portable PNG implementation and tests — all required behavior remains repository-owned across js, wasm, wasm-gc, and native.
- **`PngEncodeProfile::GrayAlpha8`:** existing Type-4/8 source admission — retain it rather than creating a `GrayAlpha8Adam7` profile.
- **`PngEncodeMachine::new_with_profile`:** one eager/chunk bounded preflight, planning, replay, and output-state machine — both new factory families must delegate directly here.
- **`_png_adam7_passes` and `PngFilteredCursor`:** sole pass geometry, scalar traversal, and filter authority — use `channels=2`, `bit_depth=8` with no materialized pass raster.
- **Existing decoder facades:** Type-4/8 interlaced input already canonicalizes to straight RGBA8 — prove this established boundary rather than widening decode/model semantics.

### Expected Features

**Must have (table stakes):**

- Explicit eager `PngEncoder::new_graya8_with_interlace_strategy` and `new_graya8_with_all_strategies` selection; baseline interlace factory fixes Stored/None.
- Matching explicit `PngChunkEncoder` factories that use the same profile and machine.
- Legal Adam7 IHDR (`08 04 00 00 01`) and exact pass-by-pass raw samples in `G,A` order for a non-symmetric all-seven-pass fixture.
- Shared Stored, FixedOrStored, DynamicOrFixedOrStored × None, Adaptive behavior, including adaptive predictor reset at each pass.
- Atomic admission and pre-lease replay-mutation rejection with accepted-only accounting and sticky terminals.
- Truthful Type-4/8 public decode to straight RGBA8: `(R,G,B,A)=(G,G,G,A)`.
- Frozen non-interlaced GrayAlpha8 and historical PNG vectors plus a single frozen four-target package qualification.

**Should have (quality differentiators):**

- Independent literal seven-pass Stored/None vector rather than a second encoder-derived expectation.
- Fresh zero-capacity, one-byte, and deterministic ragged caller leases, including untouched tail assertions.
- A source-revision guard generalized by replay semantics across U8 and U16 wire profiles, not an Adam7-specific workaround.

**Defer:**

- Gray8 Adam7, palette/low-bit/`tRNS`, RGB16/RGBA16, APNG, color conversion, decoder model widening, image-sized staging, FFI/dependencies, release automation, and target wrappers.

### Architecture Approach

The only production flow is:

```text
legal packed U8 straight-alpha GrayAlpha view
  -> explicit eager/chunk GrayAlpha8 interlace factory
  -> PngEncodeMachine::new_with_profile(GrayAlpha8, ..., Adam7)
  -> shared atomic preflight and Adam7 filtered cursor
  -> Stored / FixedOrStored / DynamicOrFixedOrStored replay
  -> Type-4/8 Adam7 PNG -> existing RGBA8 decoder canonicalization
```

**Major components:**

1. **`png.mbt` eager facade** — add only the two explicit GrayAlpha8 interlace selectors; existing `new_graya8*` APIs keep `None`.
2. **`stream_encode.mbt` chunk facade** — mirror those two selectors and delegate straight to the shared machine.
3. **`encode.mbt` admission/preflight** — remove only the GrayAlpha8 non-`None` rejection; retain descriptor admission, exact ledger, all strategy traversals, and replay guard.
4. **`structural.mbt` and filter cursors** — unchanged seven-pass geometry and pass-local filtering; no alternate source traversal or buffer.
5. **Public PNG tests** — own wire, decode, six-pair, hostile lease, mutation, legacy, and four-target evidence; no decoder production change is expected.

### Critical Pitfalls

1. **Treating Adam7 as reordered full rows** — derive totals, coordinates, filter tags, and `G,A` reads from `_png_adam7_passes(..., 2, 8)` only; use an asymmetric image reaching every nonempty pass.
2. **Leaking Adaptive history across passes** — predictors and winner selection must reset per pass-local first row; test every strategy pair across pass transitions.
3. **Creating a second admission/preflight path** — relax only the single profile gate, then retain the existing all-strategy transactional ledger before output state or leases exist.
4. **Writing a lease before detecting source mutation** — revision validation must happen before `destination.set` for Stored, Fixed, and Dynamic; prove unchanged sentinels and a sticky typed failure.
5. **Confusing caller leases with PNG/DEFLATE/pass boundaries** — preview remains private until acknowledgement; zero/one/ragged schedules must be eager-identical without duplicate/lost bytes.
6. **Broadening compatibility by default** — new factory names make Adam7 opt-in; retain literal legacy vectors for GrayAlpha8, Gray8, Gray16, RGB8, and RGBA8.
7. **Treating native as portability evidence** — qualification is the unmodified `moon -C modules/mb-image test png --target all --frozen` suite on all four targets.

## Implementation Requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| **GRAYA8A7-01** | Legal packed-U8 straight-alpha GrayAlpha images can explicitly select eager and caller-buffered Adam7 Type-4/8 output; legacy GrayAlpha8 factories remain non-interlaced. | Narrow and all-strategy public factories; Adam7 IHDR `08 04 01`; legacy/explicit-None IHDR `08 04 00`; incompatible descriptors fail before output. |
| **GRAYA8A7-02** | Adam7 GrayAlpha8 uses the one bounded profile-aware machine for all six compression/filter pairs, with pass-local Adaptive filtering and unchanged atomic/pre-lease replay semantics. | Literal 5x5 seven-pass `G,A` raster; six-pair eager/chunk identity and decode; separate ledger failures; mutation-after-prefix zero-write sticky terminal for Stored, Fixed, and Dynamic. |
| **GRAYA8A7-03** | Public evidence proves wire/decode fidelity, hostile caller-buffered behavior, compatibility, and portability. | Fresh zero/one/ragged drains with accepted-only totals and untouched tails; frozen legacy literals; one frozen all-target PNG package run. |

## Implications for Roadmap

### Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile

**Rationale:** Expose the missing public selection before broadening test matrices. The architecture identifies only factory additions and removal of one preflight rejection as production work.

**Delivers:** Eager/chunk explicit `with_interlace_strategy` and `with_all_strategies` GrayAlpha8 factories; legal shared `GrayAlpha8 + Adam7` preflight; a focused Stored/None public all-seven-pass vector; frozen legacy non-interlaced routes.

**Addresses:** GRAYA8A7-01 and the public API/Type-4/8 portion of GRAYA8A7-02.

**Avoids:** Implicit interlacing, broad grayscale admission, a second profile/machine, wrong two-channel pass geometry, and staging.

### Phase 60: Bounded Adam7 Streaming Semantics

**Rationale:** Once construction is legal, prove that every current safety contract composes with the Type-4/8 Adam7 cursor rather than writing a parallel implementation.

**Delivers:** Six-pair eager/chunk parity, pass-local Adaptive proof, atomic failures across ledger stages, and a U8/U16-general prewrite mutation guard that protects Stored as well as Fixed/Dynamic replay.

**Addresses:** The remaining GRAYA8A7-02 bounded behavior.

**Avoids:** Cross-pass filtering, strategy-specific admission, pre-lease source leakage, incorrect acknowledgement accounting, and pass/IDAT/DEFLATE boundary assumptions.

### Phase 61: Portable GrayAlpha8 Adam7 Public Evidence

**Rationale:** Keep consumer-facing interchange qualification independent of production changes and make portability a release gate rather than an inferred property.

**Delivers:** Literal multipass wire/decode coverage, hostile zero/one/ragged chunk schedules, sticky success terminals, frozen legacy vectors, and four-target qualification.

**Addresses:** GRAYA8A7-03.

**Avoids:** Encoder/decoder self-consistency-only tests, native-only confidence, and accidental legacy drift.

### Phase Ordering Rationale

- Factory/profile enablement is the sole capability change and must precede shared-machine composition tests.
- Streaming semantics then exercise the exact code selected by the new route across the full strategy and failure matrix.
- Public evidence closes the milestone with independently auditable consumer behavior and the unchanged portability command.

### Research Flags

Phases likely needing deeper local-code research during planning:

- **Phase 60:** Inspect all current Stored/Fixed/Dynamic replay paths and pre-lease revision checks before test design; the risk is a subtle shared-machine composition defect.
- **Phase 61:** Confirm fresh all-target output and current package test count at the final unchanged HEAD; do not reuse archived counts as present evidence.

Phases with standard patterns:

- **Phase 59:** Directly mirror verified GrayAlpha16 Adam7 public factory/profile precedent; only a narrow current-source review is required.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | HIGH | Existing portable module and dependencies already contain every needed primitive; the v0.17 stack research is stale for scope but confirms no dependency change. |
| Features | HIGH | Current source boundary and completed v0.16/v0.18 evidence define measurable public behavior. |
| Architecture | HIGH | Current production seams isolate the exact two facade additions and one preflight relaxation. |
| Pitfalls | HIGH | Repository-specific risks map to concrete cursor, ledger, replay, and compatibility seams; PNG wording is corroborative. |

**Overall confidence:** HIGH

### Gaps to Address

- **Prewrite revision scope:** Phase 60 must establish whether U8 Stored already shares the prewrite guard; if not, generalize the existing guard by replay behavior and prove non-interlaced regression coverage as well.
- **Fresh qualification:** Phase 61 must record a current four-target result rather than cite previous milestone counts.
- **Existing Summary/Stack staleness:** Both prior v0.17 research artifacts describe GrayAlpha16. Replace/update their influence only through current v0.19 context; no production decision should inherit their non-interlaced restriction.

## Sources

### Primary (HIGH confidence)

- `.planning/PROJECT.md` — v0.19 goal, constraints, and frozen-compatibility scope.
- `.planning/research/FEATURES.md` — requirement candidates, public acceptance evidence, exclusions, and delivery order.
- `.planning/research/ARCHITECTURE.md` — concrete factory, preflight, cursor, decode, and test ownership seams.
- `.planning/research/PITFALLS.md` — Adam7/filter/preflight/replay/lease/compatibility risk controls.
- Current `mb-image/png` implementation and completed v0.16/v0.18 milestone records — established GrayAlpha8 and GrayAlpha16 Adam7 precedents.

### Secondary (MEDIUM confidence)

- [PNG Specification, Second Edition](https://www.libpng.org/pub/png/spec/iso/index-object.html) and [PNG 1.2 data representation](https://libpng.org/pub/png/spec/1.2/PNG-DataRep.html) — Type-4 sample order, Adam7 pass layout, filtering, and zlib/IDAT context.

---
*Research completed: 2026-07-23*
*Ready for roadmap: yes*
