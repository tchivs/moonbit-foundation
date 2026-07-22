# Phase 44: Gray8 Factory Compatibility - Research

**Researched:** 2026-07-22  
**Domain:** PNG public factory/profile selection  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

DATA_7QmL2aXv_START
### Locked Decisions

- **D-01:** Add a small, symmetric eager/chunk `Gray8` factory family rather than changing the behavior of existing factories or inferring a new output profile from `ImageView` alone.
- **D-02:** The selected Gray8 profile is fixed to PNG colour type 0, bit depth 8, and `PngInterlaceStrategy::None`; it can compose with the existing Stored, FixedOrStored, DynamicOrFixedOrStored, and filter selection APIs without adding a second compression path.
- **D-03:** Existing constructors retain their present RGB8/straight-RGBA8 admission and frozen output exactly. Gray8 factories admit only packed, tightly-rowed `ChannelOrder::Gray` + `U8`, top-left, opaque-metadata-free inputs with the current canonical metadata contract.
- **D-04:** Wrong profile/source pairs, Gray16, planar rows, alpha/transparency conversion, and Gray8+Adam7 fail before output or a chunk encoder is made available, with stable typed capability contexts. No implicit RGB-to-Gray conversion is introduced.
- **D-05:** Phase 44 tests lock the public factory and rejection behavior plus legacy RGB/RGBA byte compatibility. Full Gray pixel emission, cross-strategy bounded preflight, hostile chunk schedules, and four-target public fidelity remain the explicit responsibility of Phases 45 and 46.

### the agent's Discretion

Use the smallest public names and internal profile representation that follow the existing `new_with_*` constructor style without multiplying duplicate implementations.

### Deferred Ideas (OUT OF SCOPE)

- Palette/indexed output, 1/2/4-bit Gray packing, Gray16, `tRNS`/alpha conversion, and Gray8 Adam7 are later additive contracts.
- Registry publication and release automation remain outside this code-first milestone.
DATA_7QmL2aXv_END
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYPNG-01 | Explicit eager and caller-buffered non-interlaced Gray8 PNG factories; legacy bytes unchanged. | Profile-specific factories, central source admission, and frozen-byte tests. |

## Summary

Use a private `PngEncodeProfile::{LegacyRgbOrRgba, Gray8}` carried by `PngEncoder`, `PngChunkEncoder`, and the private machine/preflight seam. [ASSUMED]
Keep every existing factory on `LegacyRgbOrRgba`; only the new explicit Gray8 default factories select `Gray8`. [VERIFIED: codebase grep]

**Primary recommendation:** Add one symmetric working non-interlaced default-Stored `new_gray8` factory on both encoder types; do not add Gray8 strategy or interlace factories until Phase 45. [REVISED: plan-checker reconciliation]

## Project Constraints (from AGENTS.md)

- Core implementation remains MoonBit, targets remain `+js+wasm+wasm-gc+native`, and public package dependencies must remain acyclic. [VERIFIED: AGENTS.md]
- Public behavior must be deterministic; no new FFI, GUI state, or external package is justified. [VERIFIED: AGENTS.md]
- Graph discovery is preferred, but graphify is disabled in this workspace; targeted `rg` inspection was the permitted fallback. [VERIFIED: gsd-tools graphify status]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Gray8 selection | API / Backend | — | Public constructors own the explicit output-profile choice. [VERIFIED: codebase grep] |
| Source/profile rejection | API / Backend | — | Preflight runs before writer output or a chunk encoder result. [VERIFIED: codebase grep] |
| PNG bytes | API / Backend | — | Private `PngEncodeMachine` owns IHDR and replay. [VERIFIED: codebase grep] |

## Exact Code Seams and API Plan

- `modules/mb-image/png/png.mbt`: `PngEncoder` stores compression/filter/interlace only (107-180); `PngChunkEncoder` is the public caller-buffered type (184-223). [VERIFIED: codebase grep]
- `modules/mb-image/png/stream_encode.mbt`: `PngChunkEncoder::{new,new_with_compression_strategy,new_with_filter_strategy,new_with_strategies,new_with_interlace_strategy,new_with_all_strategies}` all delegate to one machine constructor (9-108). [VERIFIED: codebase grep]
- `PngEncodeMachine::new_with_all_strategies` calls `_png_encode_preflight_with_interlace` before it creates state (307-379); preserve that atomic construction rule. [VERIFIED: codebase grep]
- `modules/mb-image/png/encode.mbt`: `_png_encode_source` currently accepts only RGB/straight RGBA and returns 3/4 channels (56-108); make it profile-aware rather than duplicating dimensions, metadata, tight-row, limit, budget, or planner checks. [VERIFIED: codebase grep]
- `modules/mb-image/png/stream_encode.mbt`: `PngEncodeMachine::byte_at` currently maps only 3 channels to IHDR type 2 and everything else to type 6 (804-832); Phase 44 must carefully extend this Stored emitter/scanline path to one channel so valid Gray8 requests really encode. [REVISED: requirement reconciliation]
- `modules/mb-image/model/descriptor.mbt`: `ChannelOrder::Gray` exists and reports one channel, while `ImageFormat::new` can express packed U8 Gray without a new model helper (26-64, 108-114). [VERIFIED: codebase grep]

## Rejection and Compatibility Contract

- Reuse existing capability checks for empty input, U8, packed layout, canonical built-in encoded-sRGB metadata, TopLeft, no opaque metadata, and tight rows. [VERIFIED: codebase grep]
- Legacy factories must retain the existing `rgb-or-rgba-required` Gray rejection and all frozen RGB/RGBA bytes. [VERIFIED: codebase grep]
- Gray8 factories should accept only `Gray + U8 + Packed`, no alpha metadata, and row bytes/stride exactly equal to width; RGB/RGBA source under the Gray profile must fail before bytes or chunk state. [ASSUMED]
- Preserve `PngInterlaceStrategy::None` inside every Gray8 factory and defensively reject a private/future Gray8+Adam7 combination before preflight output; PNG defines grayscale type 0, allows depth 8, and defines interlace 0 as non-interlaced. [CITED: https://www.w3.org/TR/png-3/]
- Phase 44 must emit real one-channel Stored PNG bytes. Phase 45 extends the same profile through filter and Fixed/Dynamic planning rather than replacing a pending guard. [REVISED: `GRAYPNG-01` requires successful encoding]

## Common Pitfalls

- **Accidental legacy mutation:** changing the default constructor or its profile changes byte baselines; route old constructors through the unchanged legacy profile. [VERIFIED: codebase grep]
- **IHDR-only implementation:** type 0 with a still-3/4-channel Stored/replay path corrupts the stream; Phase 44 must update the minimum one-channel Stored traversal together with IHDR, while Phase 45 owns filter and Fixed/Dynamic generalization. [REVISED: requirement reconciliation]
- **Late chunk rejection:** chunk construction currently performs preflight before returning an encoder, so Gray rejection must remain there. [VERIFIED: codebase grep]
- **Adding Gray8 Adam7 surface:** it contradicts the fixed non-interlaced contract; omit it rather than silently coerce it. [ASSUMED]

## Test Plan

- Extend `encode_test.mbt` helpers with an explicit packed Gray U8 image and test the eager Gray8 factory emits standards-compliant Stored bytes and rejects unsupported sources atomically. [REVISED: requirement reconciliation]
- Extend `stream_encode_test.mbt` with the matching Gray constructor; prove output equals eager bytes and reject invalid forms before a chunk encoder is returned, preserving sentinel lease/budget behavior. [REVISED: requirement reconciliation]
- Keep/add exact frozen RGB/RGBA vectors across legacy and explicit-None families, following `PNG Adam7 public eager fidelity and frozen None compatibility` and its chunk counterpart (encode 611-660; stream 803-855). [VERIFIED: codebase grep]
- Do not add Gray decode fidelity, one-byte/ragged chunk identity, full strategy/budget coverage, or four-target proof here; ROADMAP assigns those to Phases 45/46. [VERIFIED: ROADMAP.md]

## Scope Boundary

| Phase 44 | Phase 45 | Phase 46 |
|---|---|---|
| Working explicit Stored Gray8 factories, minimum one-channel emission/replay, admission/rejection boundary, legacy byte locks. [REVISED: `GRAYPNG-01`] | Gray8 filter and Fixed/Dynamic planning/replay through the existing bounded path. [VERIFIED: ROADMAP.md] | Generated fidelity, hostile capacities, compatibility matrix, four-target evidence. [VERIFIED: ROADMAP.md] |

## Validation Architecture

| Property | Value |
|---|---|
| Framework | MoonBit built-in tests; `moon 0.1.20260713` is available. [VERIFIED: local CLI] |
| Quick/full command | `moon test modules/mb-image/png` [VERIFIED: local CLI] |
| Existing status | 171 tests pass before this phase. [VERIFIED: local test run] |

## Security Domain

Input validation applies: profile-specific source admission and pre-output rejection prevent unsupported layouts/types from entering the byte emitter. [VERIFIED: codebase grep]
Authentication, sessions, access control, and cryptography do not apply to this in-process codec-factory change. [ASSUMED]

## Assumptions Log

| # | Claim | Risk if Wrong |
|---|---|---|
| A1 | One default `new_gray8` factory on each public surface is the smallest usable public family. | Phase 45 must add strategy-aware variants deliberately. |
| A2 | Phase 44 can safely generalize only the Stored row/emission path without weakening later bounded strategy work. | Planner must retain explicit Fixed/Dynamic/filter fences. |

## Sources

- [W3C PNG Third Edition](https://www.w3.org/TR/png-3/) — IHDR colour type, bit-depth, and interlace rules. [CITED: https://www.w3.org/TR/png-3/]
- Local PNG encoder/model sources and tests listed above. [VERIFIED: codebase grep]
