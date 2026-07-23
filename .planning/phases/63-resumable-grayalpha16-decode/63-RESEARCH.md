# Phase 63: Resumable GrayAlpha16 Decode - Research

**Researched:** 2026-07-23
**Domain:** Additive profile selection for the bounded, caller-chunk-fed PNG decoder
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add only `PngChunkDecoder::new_graya16`; it selects the same private
  GrayAlpha16 profile and `DecodeResult` shape as eager `decode_graya16`.
- **D-02:** Reuse existing chunk framing, accepted-only byte progress, finish,
  atomic failure, and sticky terminal state. Do not build a second chunk machine
  or retain a second image representation.
- **D-03:** Prove arbitrary hostile split schedules against a fresh eager peer,
  including zero/one/ragged chunks, early finish, malformed/metadata rejection,
  and unchanged generic chunk decoding.

### the agent's Discretion

- Reuse the closest GrayAlpha16/streaming helper. Adam7/filter breadth and
  four-target qualification remain Phase 64.

### Deferred Ideas (OUT OF SCOPE)

- Adam7/filter variants, broad resource matrix, frozen legacy matrix, and all
  targets are reserved for Phase 64; no conversion API or generic decoder
  change is allowed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRA16DEC-02 | `PngChunkDecoder::new_graya16` must preserve the eager result and existing progress/failure terminal semantics under hostile caller schedules. | Reuse `PngDecodeMachine::new_with_profile`, `png_chunk_public_schedule`, and `png_chunk_schedule_matches_eager`; add narrow public assertions over the Phase 62 Type-4/16 literals. [VERIFIED: codebase source] |
</phase_requirements>

## Summary

Phase 63 is a one-constructor propagation change. `PngDecodeProfile::GrayAlpha16` already selects Type-4/16 admission, the `graya16` descriptor, metadata identity, four-byte destination accounting, and the final `Ghi,Glo,Ahi,Alo -> Glo,Ghi,Alo,Ahi` store. `PngChunkDecoder::new()` already creates the same private machine using only `GenericRgba8`; `new_graya16` should make that one profile argument explicit while retaining its existing strict `DecodeOptions`. [VERIFIED: modules/mb-image/png/png.mbt; modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/raster_decode.mbt]

The public wrapper, not the profile, owns chunk accounting and terminal transfer: `push()` advances `consumed_total` only for admitted bytes, fails before admitting an over-limit byte, and exposes no result; `finish()` alone asks the active machine for EOF, then transfers the single existing `DecodeResult`. Failed and finished wrapper states reject subsequent pushes with zero consumption. This makes the implementation small and gives Phase 63 exact existing behavioral oracles. [VERIFIED: modules/mb-image/png/stream_decode.mbt]

**Primary recommendation:** Add `PngChunkDecoder::new_graya16` beside `new`, constructing `PngDecodeMachine::new_with_profile(PngDecodeProfile::GrayAlpha16, strict_options, limits, budget)`, and extend only the public streaming tests with the Phase 62 hand-authored Type-4/16 literals and the existing hostile-schedule harness. [VERIFIED: modules/mb-image/png/png.mbt; modules/mb-image/png/stream_decode_test.mbt; modules/mb-image/png/png_test.mbt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Select explicit GrayAlpha16 route | API / Backend | — | The public factory chooses a private decode profile; it does not parse chunks or allocate an image itself. [VERIFIED: modules/mb-image/png/png.mbt; modules/mb-image/png/stream_decode.mbt] |
| Frame caller-owned chunks and report accepted progress | API / Backend | — | The existing `PngChunkDecoder` wrapper owns `push`, `consumed_total`, failure state, and EOF declaration. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Admit profile and allocate one result | API / Backend | Database / Storage | First-IDAT preflight validates the profile before constructing the descriptor, `OwnedImage`, and raster sink. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Preserve Type-4/16 component bytes | Database / Storage | API / Backend | The existing profile-aware raster sink writes reconstructed bytes into the existing packed little-endian storage view. [VERIFIED: modules/mb-image/png/raster_decode.mbt] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing `tchivs/mb-image` PNG package | module `0.1.0`; MoonBit `0.1.20260713` installed | Public PNG API, bounded decode machine, storage, and tests | Phase 63 adds no dependency and is implemented entirely through existing MoonBit package seams. [VERIFIED: modules/mb-image/moon.mod.json; local `moon --version`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `mb-core` budget/error/bytes packages | workspace dependency | Caller views, checked limits, budgets, typed diagnostics | Reuse through the existing chunk constructor and test helpers; add no wrapper or alternative error channel. [VERIFIED: modules/mb-image/moon.mod.json; modules/mb-image/png/png.mbt] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One profile-selected `PngDecodeMachine` | A dedicated GrayAlpha16 chunk machine | Rejected: it would duplicate framing, accounting, EOF handling, sticky state, and the image lifecycle that D-02 requires to remain shared. [VERIFIED: 63-CONTEXT.md; modules/mb-image/png/stream_decode.mbt] |
| Existing `DecodeResult` | A precision wrapper, conversion API, or generic result widening | Rejected: Phase 62 already returns the correct explicit result and the locked generic route must remain `GenericRgba8`. [VERIFIED: 62-VERIFICATION.md; 63-CONTEXT.md] |

**Installation:** None — this phase must not install packages. [VERIFIED: 63-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
caller-owned ByteView
        |
        v
PngChunkDecoder::new_graya16
        | constructs with GrayAlpha16 profile
        v
existing PngDecodeMachine -- accepted bytes --> existing framing / CRC / inflater
        | first IDAT preflight                         |
        | Type-4/16 + Default/sRGB gate                v
        +--> existing graya16 descriptor --> existing profile-aware raster sink
                                                        |
caller calls finish() ---------------------------------+
        |                                               |
        +--> successful EOF only: existing DecodeResult v
            otherwise: first typed error, sticky terminal state
```

The profile must enter at constructor creation. It then reaches the current first-IDAT preflight and sink without a second parser, replay buffer, or image representation. [VERIFIED: modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/raster_decode.mbt]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # add the sole public new_graya16 factory
├── stream_decode.mbt       # unchanged shared push/finish/profile lifecycle
├── stream_decode_test.mbt  # public schedule/equivalence and terminal tests
└── png_test.mbt            # existing eager Type-4/16 literals/oracle
```

### Pattern 1: Profile-selected factory

**What:** Construct the existing machine with the private profile before any byte is supplied.

**When to use:** Only for the new explicit `PngChunkDecoder::new_graya16` selector.

**Example:**

```moonbit
pub fn PngChunkDecoder::new_graya16(limits, budget, diagnostics) -> PngChunkDecoder {
  {
    limits,
    _diagnostics: diagnostics,
    state: PngChunkDecoderState::Active(PngDecodeMachine::new_with_profile(
      PngDecodeProfile::GrayAlpha16,
      @codec.DecodeOptions::new(
        require_complete_input=true,
        preserve_opaque_metadata=false,
      ),
      limits,
      budget,
    )),
    consumed_total: 0UL,
  }
}
```

Source pattern: `PngChunkDecoder::new` and `PngDecoder::decode_graya16`. This is a required implementation shape, not a new public generic option. [VERIFIED: modules/mb-image/png/png.mbt]

### Pattern 2: Fresh-peer hostile schedule equivalence

**What:** Give a fresh decoder zero bytes, then a sequence of fresh caller-owned slices; compare its terminal result or error, remaining budget, and rendered diagnostics with a separately initialized eager peer.

**When to use:** For the default and `sRGB` Phase 62 Type-4/16 literals, and for their narrow malformed/metadata variants.

**Example:**

```moonbit
let run = png_chunk_public_schedule(
  item, "graya16-ragged", [8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
  None, true, chunk_budget, chunk_diagnostics,
)
png_chunk_schedule_matches_eager(
  item, "graya16-ragged", run.result, chunk_budget, chunk_diagnostics,
)
```

Source pattern: the existing public schedule driver deliberately performs an empty push, validates accepted-only progress, replays terminal failures, and calls `finish()` only after source exhaustion. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt]

### Anti-Patterns to Avoid

- **Second chunk state machine:** Do not copy `push`, `finish`, or any PNG framing state; profile selection is the only new behavior. [VERIFIED: 63-CONTEXT.md]
- **Image-sized source staging:** Do not retain a caller `ByteView` or construct a second wire raster; the owned lifecycle already contains the sole result allocation. [VERIFIED: modules/mb-image/png/stream_decode.mbt]
- **Generic-path mutation:** Do not alter `PngChunkDecoder::new`, `PngDecoder::new`, `ImageDecoder::decode`, or `DecodeResult`. [VERIFIED: 63-CONTEXT.md; 62-VERIFICATION.md]
- **Qualification expansion:** Do not add Adam7/filter matrices or all-target validation in this phase; Phase 64 owns them. [VERIFIED: 63-CONTEXT.md; .planning/ROADMAP.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Caller-chunk parser lifecycle | A new Type-4/16 parser or chunk loop | `PngDecodeMachine` inside `PngChunkDecoder` | It already retains partial framing, CRC, inflater, raster, EOF classification, accepted counts, and terminal state. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Hostile scheduling | A new split/failure test runner | `png_chunk_public_schedule` plus `png_chunk_schedule_matches_eager` | The helpers already assert empty pushes, one/ragged scheduling, source-terminal agreement, sticky replay, budgets, and diagnostics. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt] |
| GrayAlpha16 byte oracle | Encoder-generated fixture or a new conversion assertion | Phase 62's hand-authored default and `sRGB` literals with component-byte checks | Unequal component lanes detect both high-byte loss and endian swaps. [VERIFIED: modules/mb-image/png/png_test.mbt; 62-VERIFICATION.md] |

**Key insight:** The same existing profile controls preflight, descriptor, output allocation, and final byte store; Phase 63 needs to select it once, rather than replicate any transport or output behavior. [VERIFIED: modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/raster_decode.mbt]

## Common Pitfalls

### Pitfall 1: Constructor silently selects the generic profile

**What goes wrong:** The new API compiles but returns the frozen RGBA8 high-byte result rather than packed `graya16`.

**Why it happens:** `PngChunkDecoder::new` currently invokes `PngDecodeMachine::new`, which intentionally selects `GenericRgba8`. [VERIFIED: modules/mb-image/png/png.mbt; modules/mb-image/png/stream_decode.mbt]

**How to avoid:** Make `new_graya16` directly call `new_with_profile(GrayAlpha16, ...)` using the same strict options as the existing chunk constructor. [VERIFIED: modules/mb-image/png/png.mbt]

**Warning signs:** The chunk result exposes `RGBA8`, `0x12,0x12,0x12,0xa7`, or lacks the `Glo,Ghi,Alo,Ahi` component-byte observations. [VERIFIED: modules/mb-image/png/png_test.mbt]

### Pitfall 2: Schedule helper compares against generic eager decode

**What goes wrong:** Hostile schedules pass while comparing two compatible-but-wrong RGBA8 results.

**Why it happens:** `png_chunk_eager_vector` deliberately invokes the generic `ImageDecoder::decode(PngDecoder::new(), ...)`. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt]

**How to avoid:** Add a parallel narrow eager helper for the explicit literals that calls `PngDecoder::decode_graya16`, while retaining the existing generic helper unchanged for generic compatibility. [VERIFIED: modules/mb-image/png/png.mbt; modules/mb-image/png/stream_decode_test.mbt]

**Warning signs:** A schedule test checks only `png_scheduled_result_matches` from generic fixtures and never observes a `graya16` component byte. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt]

### Pitfall 3: Treating IEND as result availability

**What goes wrong:** A test or implementation transfers an image after all chunk bytes rather than only after the separate EOF declaration.

**Why it happens:** A complete IEND leaves the machine in `NeedEof`; its successful `finish()` performs raster completion and result transfer. [VERIFIED: modules/mb-image/png/stream_decode.mbt]

**How to avoid:** Require `NeedInput` after the final input slice and inspect the result only after one successful `finish()`. Exercise early `finish()` against a partial literal and assert typed, sticky failure with no subsequent accepted bytes. [VERIFIED: modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/stream_decode_test.mbt]

### Pitfall 4: Atomicity is asserted only for malformed signature

**What goes wrong:** The profile gate could allocate or expose state before rejecting Type-4/16-incompatible metadata.

**Why it happens:** The generic malformed-signature terminal case occurs before profile admission, whereas the profile gate runs at first-IDAT preflight. [VERIFIED: modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/stream_decode_wbtest.mbt]

**How to avoid:** Public Phase 63 coverage should feed a complete profile-rejected input (wrong metadata declaration or malformed Type-4/16 variant) through the new constructor, record the first typed failure, then assert zero-consumed sticky push and `finish()` replay. Preserve the Phase 62 white-box allocation proof rather than broadening it. [VERIFIED: modules/mb-image/png/stream_decode_wbtest.mbt; modules/mb-image/png/stream_decode_test.mbt]

## Code Examples

Verified test anchors from local sources:

| Required behavior | Existing anchor | Phase 63 adaptation |
|-------------------|-----------------|---------------------|
| Eager equivalence | `png_chunk_schedule_matches_eager` | Add an explicit-peer sibling calling `decode_graya16`; compare full `DecodeResult`, budget, and diagnostics. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt; modules/mb-image/png/png.mbt] |
| Accepted progress | `png_chunk_public_schedule` | Reuse its `NeedInput == requested` and terminal `0 < consumed <= requested` checks for default and `sRGB` literals. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt] |
| Empty, one-byte, ragged schedules | `png_chunk_public_schedule` with `[1UL]` and `[8UL,4UL,1UL,13UL,2UL,5UL,3UL,21UL]` | Run both schedules over fresh source owners; require the same source terminal and eager-equivalent result. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt] |
| Early finish / no partial result | `PNG chunk decoder transfers one result and preserves terminal errors` | Call `finish()` before all bytes, assert `UnexpectedEndOfStream`, then zero-consumed sticky push and repeated `finish()` error. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt] |
| Atomic/sticky profile rejection | `PNG graya16 profile rejects incompatible first-IDAT facts atomically` plus `png_chunk_error_matches` | Keep Phase 62's private pre-allocation oracle; add public constructor-level error replay through `push` and `finish`. [VERIFIED: modules/mb-image/png/stream_decode_wbtest.mbt; modules/mb-image/png/stream_decode_test.mbt] |
| Generic compatibility | Existing `PngChunkDecoder::new` generated corpus tests | Leave these tests and selector unchanged; add a narrow same-literal assertion that generic chunk decode remains `RGBA8(Ghi,Ghi,Ghi,Ahi)`. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt; 62-VERIFICATION.md] |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic eager/chunk decoding selects `GenericRgba8` for Type-4/16 | Phase 62 added a private `GrayAlpha16` profile and eager `decode_graya16` selector | Phase 62, verified 2026-07-23 | Phase 63 can expose the same profile through the existing chunk wrapper without changing generic behavior. [VERIFIED: 62-VERIFICATION.md; modules/mb-image/png/png.mbt] |

**Deprecated/outdated:** No existing Phase 63 API is deprecated; this is an additive selector only. [VERIFIED: 63-CONTEXT.md]

## Assumptions Log

All material implementation and test-seam claims were verified against the Phase 62 report and current source; no assumed claim needs user confirmation.

## Open Questions

None blocking. The planner should choose the smallest test-local representation for the explicit schedule item: either a narrow item type or direct use of `png_test_graya16_literal` and `png_test_graya16_srgb_literal`. It must not move generated-corpus or Phase 64 qualification infrastructure into this phase. [VERIFIED: modules/mb-image/png/png_test.mbt; 63-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit `moon` CLI | Compile and focused PNG public tests | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probe]

**Missing dependencies with fallback:** None. [VERIFIED: local environment probe]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication surface exists in this in-process decoder API. [VERIFIED: modules/mb-image/png/png.mbt] |
| V3 Session Management | no | No session or credential state exists. [VERIFIED: modules/mb-image/png/png.mbt] |
| V4 Access Control | no | No authorization boundary exists. [VERIFIED: modules/mb-image/png/png.mbt] |
| V5 Input Validation | yes | Reuse byte limits, PNG structural validation, first-IDAT profile admission, typed failures, and strict EOF. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| V6 Cryptography | no | PNG CRC is an integrity check in existing framing, not a cryptographic feature added by this phase. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |

### Known Threat Patterns for bounded PNG chunk decode

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized caller input | Denial of service | Reject before admitting the next byte above `max_input_bytes`; later pushes consume zero and replay the same error. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Incomplete/hostile chunk schedules | Denial of service | Keep image private until `finish()` verifies terminal framing, zlib, and raster completion; classify the first EOF error and make it sticky. [VERIFIED: modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/stream_decode_wbtest.mbt] |
| Incompatible profile metadata | Tampering | Reject at first-IDAT profile admission before the lifecycle, descriptor/image, or sink is constructed. [VERIFIED: 62-VERIFICATION.md; modules/mb-image/png/stream_decode.mbt] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/png.mbt` — eager explicit selector, generic chunk factory, and public type shape.
- `modules/mb-image/png/stream_decode.mbt` — profile preflight, accepted-progress, EOF/result transfer, atomic/sticky chunk states.
- `modules/mb-image/png/raster_decode.mbt` — existing profile-aware Type-4/16 component-byte store.
- `modules/mb-image/png/stream_decode_test.mbt` — public hostile schedule and eager-parity helpers.
- `modules/mb-image/png/png_test.mbt` — hand-authored default and sRGB asymmetric Type-4/16 oracle.
- `.planning/phases/62-explicit-grayalpha16-decode-contract/62-VERIFICATION.md` — verified eager profile handoff and frozen generic result.

### Secondary (MEDIUM confidence)

- [MoonBit Fundamentals](https://docs.moonbitlang.com/en/latest/language/fundamentals.html) — current public function and constructor syntax corroboration.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new package is proposed; the exact package and local toolchain are present. [VERIFIED: modules/mb-image/moon.mod.json; local `moon --version`]
- Architecture: HIGH — profile, wrapper, preflight, sink, and terminal handoff are all directly visible in current code. [VERIFIED: modules/mb-image/png/stream_decode.mbt; modules/mb-image/png/raster_decode.mbt]
- Pitfalls: HIGH — each has an existing lifecycle/profile or test anchor. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt; modules/mb-image/png/stream_decode_wbtest.mbt]

**Research date:** 2026-07-23
**Valid until:** 2026-08-22 — this is repository-specific research; refresh if the PNG decode machine or Phase 62 contract changes.
