# Phase 74: Resumable Packed Grayscale PNG - Research

**Researched:** 2026-07-23
**Domain:** Caller-buffered low-bit grayscale PNG through the existing bounded encoder
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### D-01: Add only explicit caller-buffered low-bit selectors

Add `PngChunkEncoder::new_gray1`, `new_gray2`, and `new_gray4`, each fixed to
Stored DEFLATE, filter None, and non-interlaced output. Do not add public
strategy-taking overloads, generic-constructor widening, or a new transport.

### D-02: Reuse the Phase 73 profile and bounded machine

The new factories must call `PngEncodeMachine::new_with_profile` with Phase
73's existing private profiles. There is no packed staging buffer, duplicate
row provider, source-model change, or second encoder state machine.

### D-03: Preserve caller-buffered semantics exactly

Admission errors occur before a lease is exposed and leave caller budgets
unchanged. After admission, hostile zero/small output capacities, retry,
acknowledgement, and terminal paths retain the existing lease ownership and
sticky typed terminal behavior.

### D-04: Prove byte identity and lifecycle safety

For all three depths, completed chunk output must equal its Phase 73 eager
counterpart for the same canonical source. Tests must cover fragmented/hostile
capacities, all-depth atomic rejection, and sticky terminal behavior without
depending on the production packing helper as an oracle.

### D-05: Keep deferred scope deferred

No Adam7, compression/filter strategy matrices, palette/index encoding,
bit-packed model, implicit conversion, release automation, wrappers, copied
trees, or FFI belongs in this phase.

### the agent's Discretion

No section supplied in 74-CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)

- Broad strategy and interlace matrices, including Adam7 low-bit output.
- Palette/index source and encoding support.
- Qualification-only independent decode vectors and the final all-target audit
  reserved for Phase 75.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYPACK-03 | Caller-buffered low-bit grayscale output shares the bounded machine, has eager-identical bytes under hostile capacities, preserves lease ownership, and retains sticky typed terminals. | Add three fixed-profile chunk constructors and test their public lifecycle against matching eager selectors. [VERIFIED: 74-CONTEXT.md; codebase inspection] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep the implementation MoonBit-native, deterministic, portable by capability boundary, and free of new FFI. [VERIFIED: AGENTS.md]
- Preserve modular public APIs and compatibility; do not add release automation or copied/wrapper workflows. [VERIFIED: AGENTS.md; 74-CONTEXT.md]
- Codebase graph discovery was attempted first, but the available index has no v019 low-bit symbols; the requested files were then inspected directly. [VERIFIED: codebase-memory MCP; codebase inspection]

## Summary

Phase 73 already implemented the only low-bit work that affects pixels or PNG wire bytes: private Gray1/Gray2/Gray4 profiles, exact Gray/U8 admission before budget charging, packed-row arithmetic, the MSB-first scalar provider, and profile-aware IHDR output. The shared `PngEncodeMachine::new_with_profile` passes those facts into the one bounded machine. Phase 74 therefore must not modify profile, preflight, packing, eager, or source-model code. [VERIFIED: modules/mb-image/png/encode.mbt; modules/mb-image/png/stream_encode.mbt; Phase 73 verification]

**Primary recommendation:** Change only stream_encode.mbt and stream_encode_test.mbt. Add three direct fixed-profile factories, then use fresh hostile chunk drains, atomic-construction assertions, and sticky released-lease checks for every depth. [VERIFIED: 74-CONTEXT.md; codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public low-bit chunk selection | Library API | — | Factory binds one existing private profile and fixed Stored/None/non-interlace settings. [VERIFIED: 74-CONTEXT.md; stream_encode.mbt] |
| Source/profile admission | Encoder backend | — | `new_with_profile` invokes the shared profile-aware preflight before a chunk encoder exists. [VERIFIED: encode.mbt; stream_encode.mbt] |
| Packed scanlines | Encoder backend | — | Phase 73's scalar provider emits packed wire bytes without staging. [VERIFIED: encode.mbt; Phase 73 verification] |
| Leases, acknowledgement, and terminals | Transport adapter | Encoder backend | `PngChunkEncoder::pull` owns destination writes and delegates only acknowledged progress to the existing machine. [VERIFIED: stream_encode.mbt] |

## Standard Stack

| Component | Version | Use |
|---|---:|---|
| Existing mb-image/png package | repository source | Profiles, preflight, bounded encoder, lease protocol. [VERIFIED: codebase inspection] |
| MoonBit toolchain | 0.1.20260713 | Run the existing PNG package suite. [VERIFIED: local moon --version] |

No external package is installed or recommended. [VERIFIED: 74-CONTEXT.md; codebase inspection]

## Architecture Patterns

### System Architecture Diagram

~~~text
canonical Gray/U8 ImageView
  -> PngChunkEncoder::new_gray{1,2,4}
  -> PngEncodeMachine::new_with_profile(profile, Stored, None, None)
     -> shared atomic preflight --error--> Result::Err; no encoder or lease
     -> shared packed provider + bounded PNG machine
  -> pull(caller-owned lease)
     -> NeedOutput | Finished (sticky) | Failed(original typed error, sticky)
~~~

[VERIFIED: stream_encode.mbt; encode.mbt; 74-CONTEXT.md]

### Pattern: direct explicit-profile factory

Add the three factories near `PngChunkEncoder::new_gray8`. Each should follow the body of `new_gray16_with_strategies` but call `PngEncodeMachine::new_with_profile` directly with its low-bit profile and the locked tuple. Do not add a shared public strategy helper. [VERIFIED: stream_encode.mbt; 74-CONTEXT.md]

~~~moonbit
pub fn PngChunkEncoder::new_gray2(source, limits, budget, diagnostics)
  -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::Gray2, PngCompressionStrategy::Stored,
    PngFilterStrategy::None, PngInterlaceStrategy::None, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
~~~

[VERIFIED: stream_encode.mbt; 74-CONTEXT.md]

## Implementation Anchors

| File | Anchor | Plan action |
|---|---|---|
| modules/mb-image/png/stream_encode.mbt | `new_gray8` (near line 23); `new_gray16_with_strategies` (80-95) | Add only `new_gray1`, `new_gray2`, `new_gray4` with direct profile selection and fixed Stored/None/None. [VERIFIED: codebase inspection] |
| modules/mb-image/png/stream_encode.mbt | `PngEncodeMachine::new_with_profile` (767-855) | Reuse unchanged; it admits source/limits/budget atomically. [VERIFIED: codebase inspection] |
| modules/mb-image/png/stream_encode.mbt | `PngChunkEncoder::pull` (542-622) | Do not modify; it owns presented-byte write, acknowledgement, totals, and cached terminal state. [VERIFIED: codebase inspection] |
| modules/mb-image/png/encode.mbt | `_png_encode_source`; `_png_wire_byte` | Do not modify; existing low-bit validation and scalar MSB-first packing are shared by chunk construction. [VERIFIED: codebase inspection; Phase 73 verification] |
| modules/mb-image/png/png.mbt | `PngEncodeProfile::{Gray1, Gray2, Gray4}` | Do not modify; the private profiles already exist. [VERIFIED: codebase inspection] |
| modules/mb-image/png/stream_encode_test.mbt | `png_chunk_test_owner`, `png_chunk_test_drain_encoder`, Gray16 hostile drain, released-lease test | Reuse/narrow-copy these public lifecycle patterns for all three new factories. [VERIFIED: codebase inspection] |
| modules/mb-image/png/encode_test.mbt | `png_encode_public_stored_scanlines` and Gray1/2/4 tests | Leave unchanged: Phase 73 already independently proves literal packed wire bytes. [VERIFIED: codebase inspection; Phase 73 verification] |

## Don't Hand-Roll

| Problem | Do not build | Reuse | Why |
|---|---|---|---|
| Low-bit chunk encoder | Second machine, packed staging buffer, row provider, or transport | `PngEncodeMachine::new_with_profile` | It already owns preflight, framing, Stored traversal, checksums, and completion. [VERIFIED: encode.mbt; stream_encode.mbt] |
| Acknowledgement protocol | Per-profile pull implementation | `PngChunkEncoder::pull` | Progress advances only after the destination write and machine acknowledgement. [VERIFIED: stream_encode.mbt] |
| Terminal cache | Per-profile failure storage | `PngChunkEncoderState::Failed` | Existing state replays the original typed error with zero further writes. [VERIFIED: stream_encode.mbt] |
| Wire oracle | Stream-test packing reimplementation | Phase 73 literal Stored parser + eager parity | Phase 74 proves transport identity without using the production packer as an oracle. [VERIFIED: encode_test.mbt; 74-CONTEXT.md] |

## Common Pitfalls

- **Strategy-surface leak:** Copying Gray8/Gray16 public strategy families violates D-01. Add three direct selectors only. [VERIFIED: 74-CONTEXT.md]
- **Late admission:** Wrapping a chunk state before `new_with_profile` finishes could expose a lease/budget transition for invalid levels. Construct the machine first. [VERIFIED: stream_encode.mbt; 74-CONTEXT.md]
- **Weak happy-path test:** A positive-capacity drain alone misses zero-capacity no-op, acknowledgement totals, lease-tail mutation, and sticky completion. [VERIFIED: stream_encode_test.mbt; 74-CONTEXT.md]
- **Lost typed terminal:** A released lease must make the same cached error recur on a later valid lease, with neither lease changed. [VERIFIED: stream_encode.mbt; stream_encode_test.mbt; 74-CONTEXT.md]

## Recommended Test Slices

| Slice | Inputs / schedule | Assertions |
|---|---|---|
| Eager-identical hostile drain, all depths | Gray1 width 9: `00 ff 00 ff 00 ff 00 ff ff`; Gray2 width 5: `00 55 aa ff 00`; Gray4 width 3: `00 ff 11`. Use fresh encoders with `[0,1]`, `[1]`, and a ragged schedule. | Bytes equal matching eager `PngEncoder::new_gray*` output; `written <= capacity`; `total == before + written`; tail sentinels remain; final Finished pull is zero-write and leaves a later sentinel lease unchanged. [VERIFIED: 74-CONTEXT.md; stream_encode_test.mbt; encode_test.mbt] |
| Atomic invalid admission, all depths | Gray1 sample `01`; Gray2 `01`; Gray4 `02`. Snapshot every budget field before construction. | Each `new_gray*` returns its depth-specific capability error and every budget field stays identical; a separately allocated sentinel is unchanged because no chunk value/lease is exposed. [VERIFIED: encode.mbt; stream_encode_test.mbt; 74-CONTEXT.md] |
| Sticky typed failure, all depths | Construct valid encoder, release its first one-byte lease, then pull into a fresh sentinel lease. | First and replay writes/totals are zero; error category/code/operation/context/requested/completed/limit are equal; fresh lease is unchanged. [VERIFIED: stream_encode_test.mbt; 74-CONTEXT.md] |
| Regression gate | Existing package test suite. | Phase 73 independent wire tests and all prior PNG behavior remain green. [VERIFIED: Phase 73 verification] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| moon | PNG test suite | ✓ | 0.1.20260713 | — [VERIFIED: local moon --version] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment audit]

## Security Domain

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication / V3 Session / V4 Access Control | No | This phase adds no identity, session, or authorization boundary. [VERIFIED: 74-CONTEXT.md] |
| V5 Input Validation | Yes | Reuse exact-level, descriptor, geometry, limit, and budget preflight before chunk construction. [VERIFIED: encode.mbt; stream_encode.mbt] |
| V6 Cryptography | No | Add no cryptography; PNG integrity framing is not a cryptographic control. [VERIFIED: stream_encode.mbt] |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Invalid level exposes state | Tampering / DoS | Factory returns the preflight error before Active state/lease exposure. [VERIFIED: encode.mbt; stream_encode.mbt] |
| Hostile capacity corrupts progress or lease tail | Tampering | Existing pull acknowledges only accepted bytes; all-depth schedules assert totals and sentinels. [VERIFIED: stream_encode.mbt; 74-CONTEXT.md] |
| Failure is not sticky | Tampering / Repudiation | Existing Failed state caches the typed terminal; all-depth released-lease tests prove replay. [VERIFIED: stream_encode.mbt; 74-CONTEXT.md] |

## Assumptions Log

None — all recommendations are grounded in locked context and current local source. [VERIFIED: 74-CONTEXT.md; codebase inspection]

## Open Questions

None. The implementation boundary and evidence requirements are locked, and all needed seams already exist. [VERIFIED: 74-CONTEXT.md; codebase inspection]

## Sources

### Primary (HIGH confidence)

- 74-CONTEXT.md — locked scope and acceptance conditions. [VERIFIED: 74-CONTEXT.md]
- Phase 73 artifacts, especially 73-VERIFICATION.md — established low-bit profiles and independent wire evidence. [VERIFIED: Phase 73 artifacts]
- stream_encode.mbt and stream_encode_test.mbt — factory, lifecycle, and test anchors. [VERIFIED: codebase inspection]
- encode.mbt and encode_test.mbt — preflight, packed provider, and eager wire evidence. [VERIFIED: codebase inspection]

## Metadata

- Standard stack: HIGH — no dependency change and MoonBit is installed. [VERIFIED: local environment audit]
- Architecture: HIGH — exact construction and lifecycle seams are present in current source. [VERIFIED: codebase inspection]
- Pitfalls: HIGH — derived from locked behavior and existing lifecycle tests. [VERIFIED: 74-CONTEXT.md; codebase inspection]

**Valid until:** 2026-08-22; refresh if the Phase 73 profile/preflight or chunk machine changes. [VERIFIED: codebase inspection]
