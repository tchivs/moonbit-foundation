# Phase 51: Bounded Gray+Alpha PNG Encoding - Research

**Researched:** 2026-07-23
**Domain:** MoonBit PNG profile extension for packed U8 grayscale-plus-alpha encoding
**Confidence:** LOW (the confidence seam classifies the codebase provider as LOW even after verification; the implementation findings below are directly traced to the current repository.)

<user_constraints>
## User Constraints (from CONTEXT.md)

<!-- DATA_Q7M4ZK2P_START -->
### Locked Decisions
- **D-01:** Mirror the established Gray16 factory family with explicit `graya8` eager and caller-buffered factories for default, compression-only, filter-only, and combined strategy selection. — **Reversibility:** one-way — factory spellings become public package API.
- **D-02:** Admit only the Phase 50 locked descriptor identity: packed U8 `GrayAlpha`, straight alpha, encoded sRGB, builtin sRGB, top-left. Reject incompatible inputs through the existing typed PNG capability boundary before output or caller lease exposure. — **Reversibility:** costly — widening changes a public PNG compatibility contract and bounded preflight matrix.
- **D-03:** Introduce one internal GrayAlpha8 encode profile that emits IHDR bit depth 8, colour type 4, compression/filter method 0, and interlace method 0. Gray+Alpha Adam7 and Gray+Alpha16 are out of scope. — **Reversibility:** costly — extending the profile changes raster traversal and conformance obligations.
- **D-04:** Reuse the shared preflight, filter cursor, compression planner, and acknowledgement-safe replay machine. Support `None` and `Adaptive` filters with `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored`; do not create a parallel encoder, pixel staging path, or source-tree copy.
- **D-05:** Preserve source gray/alpha component order at the PNG wire boundary. Decoder canonicalization proof, hostile caller schedules, frozen legacy vectors, and independent four-target public evidence belong to Phase 52.
- **D-06:** Existing Gray8, Gray16, RGB8, and straight-RGBA8 factories and bytes remain unchanged. Phase 51 adds no release automation, registry work, FFI, low-bit/palette support, colour conversion, or target-specific implementation.

### the agent's Discretion
- Follow the established Gray16 test-helper structure and typed error-context naming, using the smallest focused Phase 51 regressions for factory admission, IHDR, eager decode fidelity, strategy pairing, and pre-exposure failures.
- Keep internal implementation changes localized to the existing PNG package and make every new `PngEncodeProfile` match explicit.

### Deferred Ideas (OUT OF SCOPE)
- Gray+Alpha16, Gray+Alpha Adam7, palette/low-bit support, colour transforms, and any new codec architecture.
- Generated public four-target wire vectors, hostile zero/one/ragged schedules, and frozen legacy-vector evidence — Phase 52.
- Publication, release automation, and copied-source workflows.
<!-- DATA_Q7M4ZK2P_END -->
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRAYA-02 | Encode compatible Gray+Alpha8 through explicit eager and caller-buffered factories as non-interlaced type-4/8-bit PNG, preserving source pairs. | Add a `GrayAlpha8` profile, public `graya8` factory families, two-channel scalar reads, type-4 IHDR selection, and focused source-pair/decode tests. [VERIFIED: codebase — `png.mbt`, `encode.mbt`, `stream_encode.mbt`, `raster_decode.mbt`] |
| GRAYA-03 | Reuse bounded preflight, filtering, compression planning, and acknowledgement-safe replay; failures must be atomic before output or lease exposure. | Route both public families through `PngEncodeMachine::new_with_profile`; copy the Gray16 strategy-pair and combined atomic-rejection helpers with GrayAlpha fixtures. [VERIFIED: codebase — `stream_encode.mbt`, `encode.mbt`, `stream_encode_test.mbt`] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared data models in MoonBit; native stubs must remain small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Preserve acyclic, explicitly documented public package dependencies and Semantic Versioning-compatible public APIs. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and usable without GUI state; benchmarks require declared workloads and reproducible baselines. [VERIFIED: AGENTS.md]
- Public-package black-box tests are mandatory; internal invariants belong in `*_wbtest.mbt`; use semantic binary assertions rather than opaque binary snapshots. [VERIFIED: AGENTS.md]
- Do not perform direct implementation edits outside an active GSD workflow. [VERIFIED: AGENTS.md]

## Summary

Phase 51 is an additive PNG-package change, not a new codec. The current encoder already carries a private raster-profile value from public factories through atomic preflight, bounded filter/compression planning, scalar replay, and IHDR emission. Gray16 is the exact structural analogue: it exposes default, compression-only, filter-only, and combined eager and caller-buffered factories, fixes no interlace, and enters the shared machine through `PngEncodeMachine::new_with_profile`. [VERIFIED: codebase — `modules/mb-image/png/{png,stream_encode,encode}.mbt`]

Implement a fourth `PngEncodeProfile` case, named `GrayAlpha8`, and make every profile match exhaustive. Its source admission must require `ChannelOrder::GrayAlpha`, U8, `Some(Straight)`, packed rows, encoded/builtin sRGB, and top-left orientation; the latter layout and metadata predicates are already checked before the profile-specific match. Return a new typed capability context such as `graya8-required` for a wrong channel order and retain the existing precise contexts for component/layout/metadata failures. The preflight happens before budget charging, eager writer output, or creation of a `PngChunkEncoder`, so both routes inherit atomic rejection without a separate path. [VERIFIED: codebase — `encode.mbt:54-138,1564-1774`; `stream_encode.mbt:461-500`; `descriptor.mbt:79-83,459-507`]

The profile differs from Gray8 only in two-byte pixels and type-4 IHDR. Reuse the normal byte accessor (component 0 then component 1) for each packed U8 pixel so no Gray16 endianness branch or staging allocation is introduced. Pass `channels = 2` through the existing filter cursor and compression planners, which makes all PNG method-0 predictors use the required two-byte pixel stride. Keep the profile non-interlaced in its factories and reject any future non-None interlace selection at preflight. [VERIFIED: codebase — `encode.mbt:394-413,456-493,1518-1528`; `stream_encode.mbt:78-95`]

**Primary recommendation:** Add `GrayAlpha8` as one profile in the existing encoder state machine; mirror Gray16 public factories and tests, changing only admission, IHDR type, and U8 two-component wire mapping.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public eager Gray+Alpha8 configuration | API / Backend | — | `PngEncoder` owns public factory selection and delegates to the private encoder machine. [VERIFIED: codebase — `png.mbt:117-276`; `encode.mbt:1777-1815`] |
| Caller-buffered Gray+Alpha8 configuration and leases | API / Backend | — | `PngChunkEncoder` constructs the shared machine and scopes output to each caller-provided lease. [VERIFIED: codebase — `stream_encode.mbt:1-145,260-325`] |
| Descriptor/profile admission and resource limits | API / Backend | Storage | Preflight validates the image view and limits before charging the budget or exposing output. [VERIFIED: codebase — `encode.mbt:54-138,1564-1774`] |
| PNG scanline filtering, DEFLATE plan, and replay | API / Backend | Storage | The existing cursor re-reads scalar source bytes and retains scalar replay state rather than a staged image. [VERIFIED: codebase — `encode.mbt:416-493,1639-1745`; `stream_encode.mbt:328-380`] |
| Packed gray/alpha source bytes | Storage | API / Backend | The Phase 50 descriptor supplies exactly two packed U8 channels, while the encoder reads them in channel order. [VERIFIED: codebase — `descriptor.mbt:79-83,120-125`; `encode.mbt:403-413`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit toolchain | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf` | Build and test existing portable PNG package. | This repository already uses MoonBit and declares the PNG package portable across js, wasm, wasm-gc, and native. [VERIFIED: local `moon --version`; `modules/mb-image/png/moon.pkg`] |
| Existing `mb-image/png` package | repository source | Profile-aware eager and caller-buffered PNG encoding. | It already owns public PNG factories, preflight, filters, compression plans, replay, and IHDR emission. [VERIFIED: codebase — `modules/mb-image/png/{png,encode,stream_encode}.mbt`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|-------------|-------------|
| Existing `mb-image/model` and `mb-image/storage` packages | repository source | Validated `graya8` descriptor and packed checked image views. | Use as the only source-image contract; do not add a PNG-specific GrayAlpha storage representation. [VERIFIED: codebase — `descriptor.mbt`; `modules/mb-image/png/moon.pkg`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One profile through shared machine | A parallel Gray+Alpha encoder or staged scanline buffer | Rejected: it would duplicate the atomic preflight/filter/compression/replay contract and contradict D-04. [VERIFIED: `51-CONTEXT.md`; `stream_encode.mbt:328-380`] |
| Explicit `graya8` factories | Altering legacy factories/default profile | Rejected: legacy factories retain their profile and frozen compatibility output. [VERIFIED: codebase — `png.mbt:104-121,263-276`; `51-CONTEXT.md`] |

**Installation:** None — this phase installs no external package. [VERIFIED: codebase — `modules/mb-image/png/moon.pkg`; `51-CONTEXT.md`]

## Package Legitimacy Audit

Not applicable: Phase 51 introduces no dependency, registry action, FFI, or generated source tree. [VERIFIED: `51-CONTEXT.md`; `modules/mb-image/png/moon.pkg`]

## Architecture Patterns

### System Architecture Diagram

```text
validated packed U8 GrayAlpha ImageView
                  |
                  v
PngEncoder::new_graya8* / PngChunkEncoder::new_graya8*
                  |
                  v
PngEncodeMachine::new_with_profile(GrayAlpha8)
                  |
      atomic profile + limits + budget preflight
                  |
                  v
two-component scalar wire reader --> None/Adaptive filter cursor
                  |                          |
                  +------> Stored/Fixed/Dynamic planner/replay
                                             |
                                             v
                                  IHDR: depth=8, type=4, methods=0, interlace=0
                                             |
                       +---------------------+---------------------+
                       v                                           v
                 eager Writer                              caller-owned lease pull
```

The diagram is the existing shared data flow with an added profile value, not a second encoding pipeline. [VERIFIED: codebase — `encode.mbt:1564-1774`; `stream_encode.mbt:461-500,984-1010`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # public eager factories and private profile enum
├── encode.mbt              # profile admission and wire/filter/preflight helpers
├── stream_encode.mbt       # caller-buffered factories, shared machine, IHDR
├── encode_test.mbt         # eager profile and decode-fidelity regressions
└── stream_encode_test.mbt  # chunk parity and atomicity regressions
```

No new module, script, copied-source tree, target-specific path, or release asset belongs in this phase. [VERIFIED: `51-CONTEXT.md`]

### Pattern 1: Explicit profile, shared bounded machine

**What:** Construct each new public factory with `PngEncodeProfile::GrayAlpha8`, `PngInterlaceStrategy::None`, and existing strategy inputs; invoke `PngEncodeMachine::new_with_profile` rather than adding an encoder type. [VERIFIED: codebase — Gray16 analogue in `png.mbt:140-178` and `stream_encode.mbt:35-95`]

**When to use:** For every eager and caller-buffered `graya8` factory in this phase. [VERIFIED: `51-CONTEXT.md`]

**Example:**

```moonbit
// Mirror the Gray16 combined factory, changing only the fixed profile.
pub fn PngEncoder::new_graya8_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::GrayAlpha8,
  }
}
```

This is an implementation-shaped recommendation derived from the existing Gray16 factory; it is not copied source. [VERIFIED: codebase — `png.mbt:166-178`]

### Pattern 2: Profile-specific admission; scalar generic wire mapping

**What:** Add a `GrayAlpha8` match arm that returns `2UL` only for U8 `GrayAlpha` with straight alpha. Leave shared packed/colour/profile/orientation checks before the match. Let the normal `_png_wire_byte` fallback read `get_byte(position / channels, row, position % channels)` so a pixel emits gray then alpha. [VERIFIED: codebase — `encode.mbt:71-138,394-413`]

**When to use:** In `_png_encode_source` and the existing profile match only. [VERIFIED: codebase — `encode.mbt:87-130`]

### Pattern 3: Profile-specific IHDR values from one emitter

**What:** Extend `PngEncodeMachine::byte_at` so `GrayAlpha8` produces colour type `4`, while its bit depth follows the existing 8-bit branch and its interlace byte remains `0`. [VERIFIED: codebase — `stream_encode.mbt:984-1004`; `51-CONTEXT.md`]

**When to use:** Only in the existing IHDR profile matches; do not alter the legacy RGB/RGBA calculation. [VERIFIED: codebase — `stream_encode.mbt:997-1002`]

### Anti-Patterns to Avoid

- **Changing the legacy profile or constructors:** this risks frozen RGB8/RGBA8 and existing Gray8/Gray16 byte contracts. Add explicit `graya8` names instead. [VERIFIED: `51-CONTEXT.md`; `png.mbt:263-276`]
- **Treating GrayAlpha8 as Gray16:** Gray16 performs a storage-endianness conversion and uses two bytes for one component; GrayAlpha8 requires two U8 components in source channel order. [VERIFIED: codebase — `encode.mbt:394-413`; `descriptor.mbt:79-83`]
- **Adding Adam7 support by exposing a generic interlace factory:** the new profile must preflight-reject non-None interlace and only its explicit factories should exist. [VERIFIED: codebase — `encode.mbt:1518-1528`; `51-CONTEXT.md`]
- **Creating a buffer or second replay engine:** bounded preflight and replay must remain the existing machine’s responsibility. [VERIFIED: `51-CONTEXT.md`; `stream_encode.mbt:328-380,461-500`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Encoder lifecycle | New GrayAlpha eager/stream state machine | `PngEncodeMachine::new_with_profile` | It already makes admission atomic and feeds both writer and caller-buffered output. [VERIFIED: codebase — `stream_encode.mbt:461-500`; `encode.mbt:1777-1815`] |
| Filter selection | GrayAlpha-specific scanline/filter arrays | Existing scalar `PngFilteredCursor` with `channels=2` | It evaluates None/Adaptive method-0 filters without output-sized staging. [VERIFIED: codebase — `encode.mbt:456-493,639-814`] |
| Compression planning | Separate Stored/Fixed/Dynamic code | Existing `PngDeflatePlan` planner/replay | It already supports all three required strategies and records their budget work before charge. [VERIFIED: codebase — `encode.mbt:1642-1769`; `stream_encode.mbt:328-380`] |
| Atomic error handling | New preflight or manual lease guard | Existing profile-aware preflight and chunk constructor result | Limit and capability failures precede budget charge, writer bytes, and `PngChunkEncoder` construction. [VERIFIED: codebase — `encode.mbt:1564-1774`; `stream_encode.mbt:78-95,461-500`] |

**Key insight:** `channels` is already the unifying scalar: setting it to two makes row byte counts, PNG filter predictor stride, scanline length, planning work, and normal U8 channel-order reads agree without a GrayAlpha-specific buffer. [VERIFIED: codebase — `encode.mbt:131-138,416-493,1575-1615`]

## Common Pitfalls

### Pitfall 1: Forgetting an exhaustive profile match

**What goes wrong:** A new enum case can be admitted by factories but still emit the wrong IHDR, retain an incorrect type-0 branch, or accidentally permit interlacing. [VERIFIED: codebase — profile matches in `encode.mbt:87-130,403-413,1518-1528`; `stream_encode.mbt:997-1002`]

**How to avoid:** Update every `PngEncodeProfile` match: source admission, wire byte mapping (deliberately retain the generic U8 arm), non-interlace preflight, and IHDR colour/bit-depth selection. [VERIFIED: codebase — same files]

### Pitfall 2: Losing gray/alpha order or using a one-byte filter stride

**What goes wrong:** A swapped pair or `channels=1` can pass trivial symmetric fixtures while making Sub/Average/Paeth predictors operate against the wrong left pixel boundary. [VERIFIED: codebase — `encode.mbt:403-413,471-485`]

**How to avoid:** Use fixtures with non-symmetric pairs such as `(0x13, 0xe7)` and `(0xc1, 0x2a)`; assert stored/None scanline order and exercise Adaptive in the strategy grid. [VERIFIED: `51-CONTEXT.md`; codebase test pattern in `encode_test.mbt:812-947`]

### Pitfall 3: Returning a chunk encoder after failed admission

**What goes wrong:** A constructor that allocates or exposes a caller-facing object before the profile/limit/budget decision violates GRAYA-03 even if later `pull` fails. [VERIFIED: `REQUIREMENTS.md`; `stream_encode.mbt:78-95,461-500`]

**How to avoid:** Keep construction exactly like `new_gray16_with_strategies`: return immediately on `new_with_profile` error; use the combined rejection helper to prove eager writer position stays zero, budget remains unchanged, and sentinel lease bytes stay unchanged. [VERIFIED: codebase — `stream_encode.mbt:78-95`; `stream_encode_test.mbt:1991-2135`]

### Pitfall 4: Pulling Phase 52 evidence into Phase 51

**What goes wrong:** Zero/one/ragged capacity schedules, frozen legacy vectors, and four-target matrix work broaden this implementation phase and duplicate the dedicated evidence phase. [VERIFIED: `51-CONTEXT.md`; `ROADMAP.md`]

**How to avoid:** Limit Phase 51 to focused eager fidelity/IHDR, ordinary caller-buffered strategy parity, and pre-exposure atomic rejection. Reserve hostile schedules and public target evidence for Phase 52. [VERIFIED: `51-CONTEXT.md`]

## Code Examples

### GrayAlpha8 profile admission

```moonbit
// Add beside Gray8 and Gray16 in _png_encode_source.
PngEncodeProfile::GrayAlpha8 => match format.channels() {
  @model.ChannelOrder::GrayAlpha =>
    if format.component() != @model.ComponentType::U8 {
      return Err(_png_encode_capability("component-u8-required"))
    } else {
      match metadata.alpha() {
        Some(@color.AlphaMode::Straight) => 2UL
        _ => return Err(_png_encode_capability("straight-graya-required"))
      }
    }
  _ => return Err(_png_encode_capability("graya8-required"))
}
```

The exact context spelling is planner discretion; preserve the project’s typed `_png_encode_capability` boundary and use a focused test for it. [VERIFIED: codebase — `encode.mbt:87-130`; `51-CONTEXT.md`]

### IHDR selection

```moonbit
let colour_type = match self.profile {
  PngEncodeProfile::Gray8 | PngEncodeProfile::Gray16 => b'\x00'
  PngEncodeProfile::GrayAlpha8 => b'\x04'
  PngEncodeProfile::LegacyRgbOrRgba =>
    if self.channels == 3UL { b'\x02' } else { b'\x06' }
}
let bit_depth = if self.profile == PngEncodeProfile::Gray16 { b'\x10' } else { b'\x08' }
```

This preserves the current type-0 and type-2/type-6 paths while emitting the locked type-4/8-bit representation. [VERIFIED: codebase — `stream_encode.mbt:997-1002`; `51-CONTEXT.md`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Legacy RGB8/straight-RGBA8 profile only | Additive explicit Gray8 and Gray16 profiles through the same bounded machine | Existing repository state before Phase 51 | GrayAlpha8 should follow the established profile seam rather than change legacy defaults. [VERIFIED: codebase — `png.mbt:104-121,132-209`; Phase 50/51 planning artifacts] |

**Deprecated/outdated:** No package or external API is being replaced in this phase. [VERIFIED: `51-CONTEXT.md`; `modules/mb-image/png/moon.pkg`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A dedicated `GrayAlpha8` enum spelling is the most suitable private profile name. The locked decision requires one profile but does not prescribe its identifier. | Summary / Architecture Patterns | Low: a different private name has no public compatibility impact if all matches remain explicit. [ASSUMED] |
| A2 | `graya8-required` is the selected typed context for the GrayAlpha channel-order admission failure; shared metadata failures retain their established contexts. | Summary / Code Examples | Medium: tests and diagnostics must agree on the chosen stable context. [DECIDED] |

## Open Questions (RESOLVED)

1. **Exact GrayAlpha capability context**
   - **RESOLVED:** Use `graya8-required` for channel-order incompatibility. Retain
     existing `component-u8-required`, `packed-required`,
     `builtin-encoded-srgb-required`, and `top-left-required` contexts for their
     independent predicates.
   - Rationale: this mirrors the short `gray8-required` and `gray16-required`
     profile contexts while preserving precise diagnostics for shared capability
     checks. [DECIDED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` / `moonc` / `moonrun` | Compile and test the PNG package | ✓ | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local `moon --version`] |
| Existing MoonBit portable targets | Package contract | ✓ (declared) | js, wasm, wasm-gc, native | Phase 51 does not need independent four-target evidence; Phase 52 owns it. [VERIFIED: `modules/mb-image/png/moon.pkg`; `51-CONTEXT.md`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local `moon --version`; `modules/mb-image/png/moon.pkg`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No identity or authentication path is added. [VERIFIED: `REQUIREMENTS.md`; `51-CONTEXT.md`] |
| V3 Session Management | No | No session state is added. [VERIFIED: `REQUIREMENTS.md`; `51-CONTEXT.md`] |
| V4 Access Control | No | No authorization boundary is added. [VERIFIED: `REQUIREMENTS.md`; `51-CONTEXT.md`] |
| V5 Input Validation | Yes | Profile admission, tight-row checks, checked arithmetic, codec limits, and resource-budget charge execute before output exposure. [VERIFIED: codebase — `encode.mbt:54-138,1564-1769`] |
| V6 Cryptography | No | No cryptographic operation or key material is added. [VERIFIED: `REQUIREMENTS.md`; `51-CONTEXT.md`] |

### Known Threat Patterns for the PNG Encoder

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong descriptor profile reaches PNG emission | Tampering | Require the locked GrayAlpha identity through `_png_encode_source` and assert the typed error context before eager/chunk output. [VERIFIED: codebase — `encode.mbt:54-138`; `51-CONTEXT.md`] |
| Row/scanline overflow or resource exhaustion | Denial of Service | Retain checked multiply/add, configured width/height/pixel/output/work limits, and a single final budget charge. [VERIFIED: codebase — `encode.mbt:1579-1769`] |
| Source mutation during Fixed/Dynamic replay | Tampering | Use the existing mutation-revision/replay terminal behavior; do not add a GrayAlpha-specific replay machine. Phase 51 need not duplicate Phase 52 hostile-schedule evidence. [VERIFIED: codebase — `stream_encode.mbt:348-380`; `stream_encode_test.mbt:2238-2305`; `51-CONTEXT.md`] |
| Caller lease modified after rejected construction | Tampering | Construct only after successful profile-aware preflight; assert sentinel lease unchanged in focused atomicity regression. [VERIFIED: codebase — `stream_encode.mbt:78-95,461-500`; `stream_encode_test.mbt:1991-2135`] |

## Sources

### Primary (repository-verified; confidence seam: LOW)

- `modules/mb-image/png/png.mbt` — public encoder profile and Gray16 factory family. [VERIFIED: codebase]
- `modules/mb-image/png/encode.mbt` — profile admission, scalar wire mapping, filters, compression planner, preflight, and atomic budget charge. [VERIFIED: codebase]
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered constructor, profile-aware machine, acknowledgement semantics, and IHDR emission. [VERIFIED: codebase]
- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — Gray16 eager/decode, parity, and atomicity analogues. [VERIFIED: codebase]
- `modules/mb-image/png/{stream_decode,raster_decode,structural_wbtest}.mbt` — existing type-4 input support and Gray+Alpha-to-straight-RGBA8 decoder canonicalization. [VERIFIED: codebase]
- `.planning/phases/50-gray-alpha-image-model/{50-01-SUMMARY.md,50-VERIFICATION.md}` — locked source descriptor identity and validated Phase 50 handoff. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- None — this is an existing-codebase implementation research task with no new library/API dependency. [VERIFIED: codebase]

### Tertiary (LOW confidence)

- No external research was needed; the confidence seam reports codebase provenance as LOW despite direct source inspection. [VERIFIED: `classify-confidence --provider codebase --verified`]

## Metadata

**Confidence breakdown:**
- Standard stack: LOW — classification supplied by `classify-confidence` for direct codebase evidence; no external package is proposed. [VERIFIED: `classify-confidence --provider codebase --verified`]
- Architecture: LOW — exact source paths were inspected, but the configured source-confidence seam assigns codebase provenance LOW. [VERIFIED: `classify-confidence --provider codebase --verified`]
- Pitfalls: LOW — derived from the current profile matches and prior Gray16 regressions under the same configured classification. [VERIFIED: `classify-confidence --provider codebase --verified`]

**Research date:** 2026-07-23
**Valid until:** Refresh before planning if any of the five PNG source/test files listed in the recommended structure changes. [ASSUMED]
