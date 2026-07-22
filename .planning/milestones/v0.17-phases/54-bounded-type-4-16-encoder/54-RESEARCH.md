# Phase 54: Bounded Type-4/16 Encoder - Research

**Researched:** 2026-07-23  
**Domain:** MoonBit PNG encoding: packed U16 grayscale plus straight alpha  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public route and representation
- **D-01:** Mirror the existing Gray16 and GrayAlpha8 factory families with explicit `graya16` eager and caller-buffered default, compression-only, filter-only, and combined-strategy APIs. — **Reversibility:** one-way — public factory spellings are API contract.
- **D-02:** Add one private `GrayAlpha16` encode profile that emits IHDR colour type 4, bit depth 16, methods 0, and interlace 0. Adam7 and other U16 alpha variants remain out of scope.

### Admission and bounded replay
- **D-03:** Admit only Phase 53's packed U16 GrayAlpha, straight-alpha, encoded builtin sRGB, top-left identity; retain typed metadata/capability errors and reject before source reads, output, budget charge, or caller lease exposure.
- **D-04:** Generalize the existing U16 wire/replay seam to emit `Ghi,Glo,Ahi,Alo` for two U16 components while retaining Gray16's two-byte source behavior. Profile stride, filter cursor, limit, budget, compression planner, and acknowledgement-safe replay must use four bytes per pixel through the single `PngEncodeMachine`.
- **D-05:** Support existing None/Adaptive filters and Stored/FixedOrStored/DynamicOrFixedOrStored compression selections without staging buffers, alternate encoder paths, source-tree copies, or target-specific branches.

### Compatibility boundary
- **D-06:** Legacy Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 factories, bytes, descriptor behavior, and atomic failure semantics remain unchanged. Public literal vectors and hostile schedules belong to Phase 55.

### the agent's Discretion
- Follow the closest Gray16 + GrayAlpha8 code/test patterns, make profile matches exhaustive, and keep changes limited to existing PNG package files.

### Deferred Ideas (OUT OF SCOPE)
- Public hostile schedules, frozen legacy vectors, and independent four-target PNG qualification — Phase 55.
- GrayAlpha16 Adam7, colour conversion, palettes/low-bit, FFI, release automation, and source copies.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYA16-02 | Explicit eager and caller-buffered compatible U16 Gray+Alpha PNGs are non-interlaced Type 4/16 and preserve `Ghi,Glo,Ahi,Alo`. | One `GrayAlpha16` profile, four factories per encoder family, a generalized U16 wire reader, and Type-4/16 IHDR mapping. |
| GRAYA16-03 | Both routes use bounded preflight/filter/planning/acknowledgement-safe replay; failures are pre-exposure atomic. | Route every factory through `PngEncodeMachine::new_with_profile`; extend its U16 cursor/revision path and clone the six-pair atomicity/replay regressions. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Implement the core algorithm and data model in MoonBit; native integration is not a substitute for the core implementation.
- Keep public modules acyclic and independently consumable; preserve SemVer-compatible public APIs.
- Keep FFI small, isolated, documented, and replaceable; this phase adds none.
- Keep public operations deterministic and GUI-independent.
- Do not claim performance without declared, reproducible measurements.
- Do not introduce breaking architectural boundaries without an RFC.
- Work through the active GSD phase workflow; this research artifact is the only changed planning file. [VERIFIED: AGENTS.md]

## Summary

Phase 54 is a bounded-profile extension, not a new encoder. The closest shipped precedents split exactly along the required axes: Phase 48 made U16 source access feed every bounded filter/planner/replay traversal as PNG big-endian wire bytes, and Phase 51 added the Type-4 factory/admission profile surface. The current code already has the shared profile-aware preflight and one `PngEncodeMachine` construction seam. [VERIFIED: Phase 48/51 summaries and `modules/mb-image/png/{encode,stream_encode}.mbt`]

PNG permits colour type 4 at bit depth 16; its samples are ordered grey then alpha, 16-bit samples are MSB-first, and non-interlaced data uses IHDR interlace method 0. Therefore the required raw raster unit is exactly `Ghi,Glo,Ahi,Alo`, preceded by the existing per-row filter byte. [CITED: https://www.w3.org/TR/png-3/] [CITED: https://www.w3.org/TR/PNG-DataRep.html]

**Primary recommendation:** Add one exhaustive `GrayAlpha16` profile and mirror the two existing explicit factory families; generalize the existing Gray16 U16 component-wire/replay predicate so every source traversal reads the same four-byte-per-pixel stream through the existing `PngEncodeMachine`. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public eager factory selection | API / library surface | Codec core | The public `PngEncoder` selects a private profile and fixed non-interlaced strategy. [VERIFIED: `png.mbt`] |
| Caller-buffered factory selection | API / library surface | Codec core | `PngChunkEncoder` delegates directly to the private machine construction seam. [VERIFIED: `stream_encode.mbt`] |
| Descriptor admission and limits | Codec core | Storage view | `_png_encode_preflight_with_interlace_profile` validates before budget charge and source traversal. [VERIFIED: `encode.mbt`] |
| U16 PNG wire mapping and filtering | Codec core | Storage view | The scalar producer must translate checked component-byte storage into PNG order before every filter/planner/replay read. [VERIFIED: Phase 48 verification; `encode.mbt`] |
| Bytes, checksum, and sticky replay | Codec core | Caller-owned output buffer | `PngEncodeMachine` owns selected-plan replay and only writes accepted output through the existing pull protocol. [VERIFIED: `stream_encode.mbt`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit PNG package (`modules/mb-image/png`) | repository source | Profile admission, filtering, DEFLATE planning, streaming replay, PNG framing | The existing shared bounded machine is the locked execution path. [VERIFIED: codebase] |
| MoonBit toolchain `moon` | `0.1.20260713` | Compile and run package tests | Installed toolchain version matches the project stack record. [VERIFIED: local `moon --version`; AGENTS.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `mb-image/model` and `mb-image/storage` | repository source | Phase-53 packed `graya16` identity and checked component-byte reads | Use unchanged as the sole source contract; do not add a converted backing model. [VERIFIED: Phase 53 verification; `descriptor.mbt`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Shared profile-aware machine | A dedicated GrayAlpha16 encoder/row conversion route | Rejected: duplicates atomicity, plan/replay, and filter semantics, and violates D-04/D-05. [VERIFIED: CONTEXT.md; Phase 48/51 verification] |
| Scalar U16 wire reader | Image-sized native-endian-to-network-endian staging buffer | Rejected: violates the bounded no-staging contract and adds memory/atomicity risk. [VERIFIED: CONTEXT.md; Phase 48 verification] |

**Installation:** None. This phase installs no package. [VERIFIED: scope]

## Architecture Patterns

### System Architecture Diagram

```text
Packed `ImageFormat::graya16()` ImageView
        │  (Phase-53 identity: U16, GrayAlpha, packed/little,
        │   straight alpha, encoded builtin sRGB, top-left)
        ▼
explicit graya16 eager / chunk factories
        ▼
PngEncodeMachine::new_with_profile(GrayAlpha16)
        ├── atomic admission + geometry/output/work/budget preflight ──► Err before output/lease
        ▼
U16 wire reader: pixel x → Ghi,Glo,Ahi,Alo
        ▼
None or Adaptive filter (stride = 4 bytes)
        ▼
Stored / FixedOrStored / DynamicOrFixedOrStored planner
        ▼
same profile-aware replay cursor + revision check
        ▼
IHDR: depth 16, colour type 4, methods 0/0, interlace 0 → IDAT → IEND
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # private profile enum and eager graya16 factories
├── encode.mbt              # admission and generalized U16 component-wire mapping
├── stream_encode.mbt       # chunk factories, machine U16 cursors/replay, IHDR
├── encode_test.mbt         # eager Type-4/16 wire, framing, strategy tests
└── stream_encode_test.mbt  # caller-buffer parity, atomicity, sticky replay tests
```

### Pattern 1: One exhaustive U16 profile predicate

**What:** Add `GrayAlpha16` to `PngEncodeProfile`, then use one private exhaustive match/helper for profiles whose source bytes must be fetched as U16 components and reordered to PNG network order. [VERIFIED: existing Gray16 profile/wire path in `png.mbt` and `encode.mbt`]

**When to use:** Every producer and replay branch that currently special-cases `Gray16`; do not add a separate GrayAlpha16 byte producer. [VERIFIED: Phase 48 verification]

**Exact mapping:**

```moonbit
// Profile fact: `channels` is bytes per on-wire pixel.
fn _png_profile_uses_u16_component_wire(profile : PngEncodeProfile) -> Bool {
  match profile {
    PngEncodeProfile::Gray16 | PngEncodeProfile::GrayAlpha16 => true
    _ => false
  }
}

// In the existing scalar reader's U16 arm:
let component = (position % channels) / 2UL
let wire_byte = position % 2UL
let storage_byte = match source.format().endianness() {
  @model.Endianness::Little => 1UL - wire_byte
  @model.Endianness::Big => wire_byte
}
source.get_component_byte(position / channels, row, component, storage_byte)
```

For Gray16 (`channels == 2`) this remains component 0 and produces `Ghi,Glo`; for GrayAlpha16 (`channels == 4`) it produces component 0 then 1 and therefore `Ghi,Glo,Ahi,Alo`. The Phase-53 source is little-endian by identity, but retaining the existing endian conversion in this shared U16 helper preserves the established scalar contract. [VERIFIED: Phase 53 verification; `encode.mbt`]

### Pattern 2: Factories only bind profile and existing strategies

**What:** Mirror all four GrayAlpha8 forms, with `graya16` spelling, in both `PngEncoder` and `PngChunkEncoder`: default, compression-only, filter-only, and combined. The combined form fixes `GrayAlpha16` and `PngInterlaceStrategy::None`. [VERIFIED: current `gray16` and `graya8` factory families]

**Exact public surface:**

```text
PngEncoder::new_graya16()
PngEncoder::new_graya16_with_compression_strategy(...)
PngEncoder::new_graya16_with_filter_strategy(...)
PngEncoder::new_graya16_with_strategies(...)

PngChunkEncoder::new_graya16(...)
PngChunkEncoder::new_graya16_with_compression_strategy(...)
PngChunkEncoder::new_graya16_with_filter_strategy(...)
PngChunkEncoder::new_graya16_with_strategies(...)
```

The caller-buffered combined factory must invoke `PngEncodeMachine::new_with_profile(source, GrayAlpha16, ...)` directly, exactly as `new_graya8_with_strategies` does, so an `Err` is returned before an encoder object or lease can exist. [VERIFIED: `stream_encode.mbt:144-159`]

### Pattern 3: One admission/preflight/replay transaction

**What:** Add an exhaustive `GrayAlpha16` admission arm that requires `ChannelOrder::GrayAlpha`, `AlphaMode::Straight`, and `ComponentType::U16`, returns `4UL`, and otherwise uses the existing typed capability error boundary. The generic checks already enforce packed layout, encoded builtin sRGB, top-left orientation, and no opaque metadata; Phase 53 validates the compatible `graya16` descriptor identity. [VERIFIED: `encode.mbt:56-149`; Phase 53 verification]

**Required profile facts:**

| Fact | GrayAlpha16 value | Existing owner |
|---|---:|---|
| bytes per filter pixel / `channels` | `4UL` | `_png_encode_source` return value and preflight ledger |
| row bytes | `width * 4UL` | existing checked multiplication |
| PNG colour type | `4` | IHDR profile match |
| PNG bit depth | `16` | IHDR profile match |
| compression method | `0` | existing IHDR emission |
| filter method | `0` | existing IHDR emission; per-row None/Adaptive tags stay unchanged |
| interlace method | `0` | graya16 factories and profile preflight rejection |

Use a profile match, not a `profile == Gray16` condition, for IHDR depth and colour type: `GrayAlpha8 | GrayAlpha16 => 4`, and `Gray16 | GrayAlpha16 => 16`. Add the matching non-interlace rejection context (recommended: `graya16-noninterlaced-required`). [VERIFIED: existing profile matches in `encode.mbt:1529-1536` and `stream_encode.mbt:1061-1067`]

The same U16 predicate must choose the `PngFilteredMatchCursor` for Stored, Fixed, and Dynamic states, and must extend the existing U16 replay-revision validation. Otherwise a GrayAlpha16 Fixed/Dynamic plan could replay through the U8 raw cursor or omit the post-admission source-mutation check. [VERIFIED: `stream_encode.mbt:565-599,709-...`; Phase 48 verification]

### Anti-Patterns to Avoid

- **A `GrayAlpha16` implementation that calls `get_byte`:** U16 views intentionally reject U8 byte access, and it would bypass required component order. Use checked `get_component_byte` in the common U16 wire arm. [VERIFIED: Phase 53 verification; `storage_test.mbt`]
- **Updating only IHDR and factories:** The selected Fixed/Dynamic plan and acknowledgement-safe replay must consume the same U16 wire cursor as preflight. [VERIFIED: Phase 48 verification]
- **Changing the legacy profile/defaults:** Add only explicit graya16 constructors; legacy bytes are a frozen compatibility boundary. [VERIFIED: CONTEXT.md]
- **Image-sized converted rows or a second encoder state machine:** Keep scalar cursors and the existing bounded matcher window. [VERIFIED: Phase 48 verification]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Streaming PNG framing/replay | A separate U16-alpha writer or pull protocol | `PngEncodeMachine::new_with_profile` | It already carries atomic preflight, selected plan state, CRC/Adler emission, progress, and sticky terminal behavior. [VERIFIED: `stream_encode.mbt`; Phase 48/51 verification] |
| U16 conversion buffer | Whole-image endian-swapped raster | Existing scalar component-wire reader | It enforces one on-wire stream across filtering, planning, checksums, and replay without staging. [VERIFIED: Phase 48 verification] |
| Filter implementation | Type-4/16-specific adaptive filters | Existing `PngFilterStrategy::{None, Adaptive}` with stride `4UL` | PNG filtering operates on scanline bytes; the cursor already accepts a bytes-per-pixel stride. [CITED: https://www.w3.org/TR/PNG-DataRep.html] [VERIFIED: `encode.mbt`] |

**Key insight:** The profile must change only semantic facts (admission, wire component layout, stride, IHDR), while the machine remains the sole transaction owner. [VERIFIED: Phase 48/51 verification]

## Common Pitfalls

### Pitfall 1: Treating two U16 components as a two-byte pixel

**What goes wrong:** Returning `2UL` from admission or using a GrayAlpha8-like cursor makes row sizing/filter predictors refer to the prior component rather than the prior pixel. [VERIFIED: `encode.mbt`]

**How to avoid:** Return `4UL` for `GrayAlpha16`; calculate component as `(position % channels) / 2UL`, x as `position / channels`, and use `channels` as the filter distance. [VERIFIED: codebase]

### Pitfall 2: Reordering only the first U16 component

**What goes wrong:** Gray can be correctly MSB-first while alpha remains little-endian or is read from the gray component. [VERIFIED: Phase 53 component-byte layout]

**How to avoid:** Use the generalized component index above and a fixture with all four lanes distinct, such as storage bytes `34,12,C5,A7`, whose wire bytes must be `12,34,A7,C5`. [VERIFIED: Phase 53 storage test; PNG MSB-first requirement cited above]

### Pitfall 3: Forgetting U16 replay cursor/revision branches

**What goes wrong:** Stored/Fixed/Dynamic paths do not all reuse the selected U16 wire producer, or a post-acknowledgement mutation emits bytes rather than failing sticky. [VERIFIED: Phase 48 verification]

**How to avoid:** Make every `Gray16`-only replay/cursor condition use the common exhaustive U16-profile predicate; clone the Gray16 Fixed and Dynamic mutation test for GrayAlpha16. [VERIFIED: `stream_encode.mbt`; `stream_encode_test.mbt`]

### Pitfall 4: Spending Phase 55 evidence early

**What goes wrong:** Public literal vectors, zero/one/ragged capacity matrices, and four-target qualification expand this implementation phase rather than proving local integration. [VERIFIED: CONTEXT.md; ROADMAP.md]

**How to avoid:** Phase 54 adds focused native package regressions only; Phase 55 owns public/four-target evidence. [VERIFIED: CONTEXT.md]

## Code Examples

### Exact profile/IHDR shape

```moonbit
priv enum PngEncodeProfile {
  LegacyRgbOrRgba
  Gray8
  Gray16
  GrayAlpha8
  GrayAlpha16
} derive(Eq)

// IHDR profile facts
let colour_type = match self.profile {
  PngEncodeProfile::Gray8 | PngEncodeProfile::Gray16 => b'\x00'
  PngEncodeProfile::GrayAlpha8 | PngEncodeProfile::GrayAlpha16 => b'\x04'
  PngEncodeProfile::LegacyRgbOrRgba => ...
}
let bit_depth = match self.profile {
  PngEncodeProfile::Gray16 | PngEncodeProfile::GrayAlpha16 => b'\x10'
  _ => b'\x08'
}
// Existing compression/filter method bytes are 0; factory fixes interlace to 0.
```

Source: existing profile patterns in `png.mbt` and `stream_encode.mbt`; PNG Type-4/16 requirements. [VERIFIED: codebase] [CITED: https://www.w3.org/TR/png-3/]

### Admission arm

```moonbit
PngEncodeProfile::GrayAlpha16 => match format.channels() {
  @model.ChannelOrder::GrayAlpha =>
    if metadata.alpha() != Some(@color.AlphaMode::Straight) {
      return Err(_png_encode_capability("straight-alpha-required"))
    } else if format.component() != @model.ComponentType::U16 {
      return Err(_png_encode_capability("component-u16-required"))
    } else {
      4UL
    }
  _ => return Err(_png_encode_capability("graya16-required"))
}
```

The surrounding existing generic admission checks remain before this arm and preflight performs all limit checks before `budget.charge`. [VERIFIED: `encode.mbt:56-149,1578-1787`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Gray16 Stored/None bypass | Profile-aware U16 scalar producer through None/Adaptive × Stored/Fixed/Dynamic planning and replay | Phase 48 | Reuse this exact U16 traversal pattern for the second component; no new encoder path. [VERIFIED: Phase 48 summary/verification] |
| Type-4 only at U8 | Private `GrayAlpha8` profile with explicit eager/chunk factories | Phase 51 | Extend the profile shape, not its architecture, for U16. [VERIFIED: Phase 51 verification] |

**Deprecated/outdated:** A GrayAlpha16-specific staging writer or independent replay protocol is incompatible with the current bounded-machine architecture. [VERIFIED: CONTEXT.md; Phase 48/51 verification]

## Assumptions Log

All implementation recommendations are grounded in the current codebase, phase decisions, prior phase artifacts, or the W3C PNG specification; no unverified assumptions require user confirmation.

## Open Questions

None for Phase 54. The only intentional boundary is evidence scope: public frozen vectors, hostile caller capacities, decoder canonicalization proof, and independent four-target qualification are Phase 55 work. [VERIFIED: CONTEXT.md; ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| MoonBit `moon` CLI | Compile and test the existing PNG package | ✓ | `0.1.20260713` | — |
| Native target runtime | Focused Phase-54 regression suite | ✓ | bundled with installed MoonBit toolchain | — |

The attempted full native PNG baseline exceeded this agent session's 64-second command window, so the planner should run the package test command in its execution environment rather than treat this research-time timeout as a code failure. [VERIFIED: local command result]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity boundary exists in this codec phase. [VERIFIED: scope] |
| V3 Session Management | no | No session state exists. [VERIFIED: scope] |
| V4 Access Control | no | No authorization boundary exists. [VERIFIED: scope] |
| V5 Input Validation | yes | Fail closed through `_png_encode_source`, checked arithmetic, codec limits, and pre-charge budget admission. [VERIFIED: `encode.mbt`] |
| V6 Cryptography | no | PNG CRC/Adler are integrity framing checks, not cryptographic controls; introduce no crypto. [VERIFIED: codebase] |

### Known Threat Patterns for MoonBit PNG encoding

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed/incompatible image descriptor reaches pixel reads | Tampering / denial of service | Profile admission rejects before source reads, output, budget charge, or lease exposure. [VERIFIED: `encode.mbt`; Phase 51 verification] |
| Oversized geometry, output, or planning work | Denial of service | Existing checked arithmetic, `CodecLimits`, and one atomic resource-budget charge remain on the shared preflight path. [VERIFIED: `encode.mbt`] |
| Source mutates after plan selection | Tampering | Extend the existing U16 revision/fingerprint replay validation to `GrayAlpha16`; failure must be sticky with no accepted output change. [VERIFIED: Phase 48 verification] |

## Sources

### Primary (HIGH confidence)

- Current code: `modules/mb-image/png/png.mbt`, `encode.mbt`, and `stream_encode.mbt` — existing profiles, admission, wire source, preflight, machine, and IHDR.
- Phase 53 `53-01-SUMMARY.md` and `53-VERIFICATION.md` — fixed packed U16 GrayAlpha source identity and checked component-byte storage.
- Archived Phase 48 `48-RESEARCH.md`, `48-01-SUMMARY.md`, and `48-VERIFICATION.md` — U16 bounded wire/replay precedent.
- Archived Phase 51 `51-CONTEXT.md` and `51-VERIFICATION.md` — Type-4 factory/admission/atomicity precedent.

### Secondary (MEDIUM confidence)

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — Type-4/16 legality, IHDR methods, sample order, and non-interlace.
- [W3C PNG Data Representation](https://www.w3.org/TR/PNG-DataRep.html) — MSB-first 16-bit samples, unassociated alpha, filter byte, and scanline order.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependency; current toolchain and existing package seams were inspected.
- Architecture: HIGH — both orthogonal precedents and every current profile-dependent site were inspected.
- Pitfalls: HIGH — derived from concrete Gray16/GrayAlpha8 verification evidence and present code branches.

**Research date:** 2026-07-23  
**Valid until:** 2026-08-22 (stable internal architecture; re-check if PNG profile seams change).
