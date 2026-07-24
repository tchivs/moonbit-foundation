# Phase 84: Low-Bit Indexed Adam7 Streaming Qualification - Research

**Researched:** 2026-07-24  
**Domain:** MoonBit portable PNG caller-buffered conformance tests  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Exercise the existing selected low-bit chunk API with Adam7 over the Phase 83 machine; no production transport replacement is permitted.
- **D-02:** Cover zero, one-byte and ragged leases at depths One/Two/Four, accepted-only totals, sentinel tails, released-lease failure and repeated Finished/Failed sticky outcomes.
- **D-03:** Independently parse drained output for IHDR/PLTE/tRNS/CRC, packed pass raw raster and public RGB8/RGBA8 decode; eager equality alone is insufficient.
- **D-04:** Freeze established non-interlaced low-bit, Indexed8 Adam7 and legacy vectors; run the ordinary package gate on all four targets.

### the agent's Discretion

None stated.

### Deferred Ideas (OUT OF SCOPE)

Generic model widening, new filters/compression, palette generation, staging, a second encoder, FFI, wrappers and release automation remain excluded.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| INDEXLOWADAM7-05 | Hostile caller leases reproduce eager bytes and retain sticky terminal semantics. | Reuse the Phase 82 hostile-drain/released-lease pattern, but construct only `new_indexed_with_interlace_strategy(..., Adam7, ...)`. [VERIFIED: repository inspection] |
| INDEXLOWADAM7-06 | Independently qualify low-bit Adam7 wire bytes and keep compatibility/portability frozen. | Reuse the test-local CRC/u32/slice/Stored-IDAT parser and Phase 83 literal rasters; finish with the four-target package gate. [VERIFIED: repository inspection] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep this portable MoonBit implementation and its conformance tests independent of foreign wrappers; do not add FFI. [VERIFIED: AGENTS.md]
- Preserve explicit modular/public compatibility contracts and deterministic, GUI-free automation. [VERIFIED: AGENTS.md]
- Use byte-level semantic assertions for binary PNG evidence, rather than opaque snapshots alone. [VERIFIED: AGENTS.md]
- The package declares `+js+wasm+wasm-gc+native`; qualification must exercise all four targets. [VERIFIED: `modules/mb-image/png/moon.pkg`]

## Summary

Phase 83 already added the only permitted selected-depth facade: `PngChunkEncoder::new_indexed_with_interlace_strategy(source, depth, Adam7, ...)` maps the public depth once and constructs the existing `PngEncodeMachine`. `PngChunkEncoder::pull` is the required lifecycle seam: it performs `present → destination.set → acknowledge`, increments totals only after acknowledgement, and caches `Finished` or `Failed` for later zero-write pulls. [VERIFIED: `modules/mb-image/png/stream_encode.mbt:69-82,662-735,1667-1715`]

Phase 84 should be test-only, with the focused implementation in `modules/mb-image/png/stream_encode_test.mbt`. The direct precedent is the Phase 82 Indexed8 Adam7 stream qualifier in that file: it collects caller-owned chunks under hostile schedules, independently checks frame/raster/decode evidence, then proves terminal replay. Existing test-local helpers in `encode_test.mbt` provide CRC-32, big-endian chunk reads/slices, and a Stored-IDAT extractor without invoking production packing or preflight helpers. [VERIFIED: `modules/mb-image/png/stream_encode_test.mbt:5071-5270`; `modules/mb-image/png/encode_test.mbt:602-650,1051-1084`]

**Primary recommendation:** Add one low-bit Adam7 stream qualification harness plus two test cases (hostile schedules and released lease) in `stream_encode_test.mbt`; do not change production files or duplicate the eager parser. [VERIFIED: repository inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Lease progress and terminal replay | API / Backend | — | `PngChunkEncoder::pull` owns caller-lease writes, accepted-byte accounting, and state caching. [VERIFIED: `stream_encode.mbt:662-735`] |
| Adam7 packed wire evidence | API / Backend | Database / Storage — | Test code owns a local byte parser over collected in-memory output; no persistent store participates. [VERIFIED: `stream_encode_test.mbt:5117-5176`] |
| RGB8/RGBA8 public decode evidence | API / Backend | — | `@codec.ImageDecoder::decode(PngDecoder::new(), ...)` is the public consumer used by the existing Indexed8 stream qualifier. [VERIFIED: `stream_encode_test.mbt:5153-5175`] |
| All-target portability gate | Build / CI | — | The PNG package itself declares the four supported targets and has an ordinary frozen test command. [VERIFIED: `modules/mb-image/png/moon.pkg`; Phase 83 verification] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Compile and run the package gate. | Installed project toolchain; no new package is needed. [VERIFIED: `moon --version`] |
| Existing PNG test helpers | repository-local | CRC, chunk parsing, Stored-IDAT extraction, caller lease ownership. | The helpers are already test-local and independent of production packer/preflight code. [VERIFIED: `encode_test.mbt:602-650,1051-1084`; `stream_encode_test.mbt:757-807`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| None | — | No dependency installation. | This phase is a test qualification of admitted APIs only. [VERIFIED: CONTEXT.md D-01 through D-04] |

**Installation:** None. [VERIFIED: CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
test-local 5x5 indexed source (depth 1 | 2 | 4)
  ├─ eager selector (fresh reference) ───────────────────────┐
  └─ PngChunkEncoder::new_indexed_with_interlace_strategy(Adam7)
       → pull(zero / one / ragged sentinel leases)
       → collect accepted bytes only
       → chunk-origin parser ──→ IHDR → PLTE → tRNS → IDAT → IEND + CRC
                              ├→ Stored raw Adam7 literal / tail-zero check
                              └→ public decoder → RGB8 and RGBA8 palette checks
       → later sentinel lease → Finished, zero writes
       → released first lease → Failed, sticky zero writes
```

The test path uses the Phase 83 selector and does not introduce a transport, machine, raster staging buffer, or source-model variant. [VERIFIED: CONTEXT.md D-01; `stream_encode.mbt:69-82`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── stream_encode_test.mbt  # Phase 84 hostile lease and chunk-origin tests
├── encode_test.mbt         # existing independent CRC/u32/slice/Stored-IDAT helpers and literals
├── stream_encode.mbt       # unchanged acknowledged facade/lifecycle
└── encode.mbt              # unchanged eager selector/machine construction
```

### Pattern 1: Dedicated explicit-Adam7 harness

**What:** Add `png_stream_indexed_low_bit_adam7_source/eager/chunk_origin_qualification/hostile_drain/released_failure`, parameterized by `PngIndexedBitDepth`, alongside the Indexed8 Adam7 counterpart. [VERIFIED: `stream_encode_test.mbt:5089-5270`]

**When to use:** Only Phase 84 test code, always passing `PngInterlaceStrategy::Adam7`; the existing `png_stream_indexed_low_bit_*` helpers construct non-interlaced `new_indexed`/`encode_indexed` and cannot prove this phase. [VERIFIED: `stream_encode_test.mbt:4917-4929,5301-5385`]

**Example:**

```moonbit
let encoder = PngChunkEncoder::new_indexed_with_interlace_strategy(
  png_stream_indexed_low_bit_adam7_source(bit_depth), bit_depth,
  PngInterlaceStrategy::Adam7, png_stream_test_limits(),
  png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap()
// Pull through [0UL, 1UL], [1UL], and [0UL, 1UL, 3UL, 2UL, 5UL].
```

Source pattern: [VERIFIED: `stream_encode_test.mbt:5180-5238`].

### Concrete Test Matrix

| Test | Depths / fixture | Required assertions |
|---|---|---|
| Hostile drains | One, Two, Four; Phase 83's non-symmetric transparent 5x5 literals | Run `[0,1]`, `[1]`, `[0,1,3,2,5]`; use a one-byte owner for every zero-capacity view; `written <= capacity`; `total_written == previous accepted total + written`; every unaccepted `Z` tail is unchanged; collected bytes equal a fresh explicit eager result. [VERIFIED: `stream_encode_test.mbt:5180-5238`; `encode_test.mbt:1086-1221`] |
| Finished replay | Each successful hostile drain | A later seven-byte `Z` lease reports `written == 0`, unchanged total, `Finished`, and all seven bytes untouched. [VERIFIED: `stream_encode_test.mbt:5219-5234`] |
| Released lease | One, Two, Four | Release the first one-byte lease before `pull`; both first and later pulls report `written == 0`, total `0`, `Failed`, equivalent cached error, and untouched sentinels. [VERIFIED: `stream_encode_test.mbt:5242-5268`; `stream_encode_test.mbt:2838`] |
| Chunk-origin parser | One / Two / Four 5x5 bytes | Independently read chunk lengths/types, assert `IHDR → PLTE → tRNS → IDAT → IEND`, CRC every chunk, extract Stored scanlines, compare full literal raw raster, then public-decode transparent bytes as RGBA8 and opaque bytes as RGB8. [VERIFIED: `stream_encode_test.mbt:5117-5176`; `encode_test.mbt:1086-1221`] |
| Compatibility / portability | Existing low-bit None and Indexed8 Adam7 vectors | Do not replace existing byte literals; execute the ordinary all-target frozen PNG suite. [VERIFIED: `encode_test.mbt:957-1079,1241-1330`; Phase 83 verification] |

### Raw Raster Oracle

Use the three test-local Phase 83 5x5 raw literals unchanged, rather than deriving them through `_png_adam7_passes`, row-byte, packer, or preflight helpers. Their total raw lengths are 22 (One), 24 (Two), and 27 (Four); all seven Adam7 passes are nonempty. The 5x5 geometry has pass row-group sizes `2,2,2,4,2,6,4` at depth One, `2,2,2,4,2,6,6` at Two, and `2,2,2,4,3,6,8` at Four. Exact byte equality to those literals makes unused final-byte low bits an explicit zero-tail assertion. [VERIFIED: `encode_test.mbt:1086-1221`; Phase 83 verification]

### Anti-Patterns to Avoid

- **Reusing `png_stream_indexed_low_bit_eager` or `new_indexed`:** both choose non-interlaced output, so they can pass lease tests without executing Adam7. Use explicit interlace selectors in the new helpers. [VERIFIED: `stream_encode_test.mbt:4917-4929,5301-5310`]
- **Using eager equality as the only oracle:** a shared framing/raster defect can survive parity. Parse the collected chunk bytes before decode. [VERIFIED: CONTEXT.md D-03]
- **A zero-length owned buffer for a zero-capacity lease:** it cannot prove destination preservation. Own one sentinel byte but lend a length-zero view. [VERIFIED: `stream_encode_test.mbt:5187-5204`; STATE.md]
- **Production changes, copied parser logic, or scripts:** they widen an evidence-only phase beyond the locked boundary. [VERIFIED: CONTEXT.md; ROADMAP.md Phase 84 scope guard]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Streaming encoder | A second low-bit/Adam7 transport | Existing `PngChunkEncoder::new_indexed_with_interlace_strategy` | It routes to the sole acknowledged machine already admitted by Phase 83. [VERIFIED: `stream_encode.mbt:69-82`; Phase 83 verification] |
| PNG CRC / chunk reads | Production helper or external parser dependency | Existing test-local `png_indexed_crc32`, `png_indexed_u32`, and `png_indexed_slice` | They are independent from production packing/preflight and already establish the test convention. [VERIFIED: `encode_test.mbt:1051-1084`] |
| Stored IDAT decoding | General decompressor or hand-built encoder oracle | Existing `png_encode_public_stored_scanlines` plus fixed literal raw bytes | It parses the bounded Stored block and avoids reliance on production output helpers. [VERIFIED: `encode_test.mbt:602-650`] |

**Key insight:** Phase 84 validates the existing lifecycle and bytes from outside the machine; it should not create a parallel implementation merely to test one. [VERIFIED: CONTEXT.md D-01 through D-03]

## Common Pitfalls

### Pitfall 1: Correct lifecycle test, wrong profile

**What goes wrong:** A helper calls `new_indexed`/`encode_indexed`, proving Type-3 low-bit None instead of Type-3 low-bit Adam7. [VERIFIED: `stream_encode_test.mbt:5301-5385`]

**How to avoid:** Make each Phase 84 constructor call visibly include `PngInterlaceStrategy::Adam7`; source the eager parity bytes from the matching explicit eager selector. [VERIFIED: `stream_encode_test.mbt:5099-5112`]

### Pitfall 2: Stream evidence accidentally depends on eager bytes

**What goes wrong:** Eager parity masks a shared pass-order, tail, CRC, or framing mistake. [VERIFIED: CONTEXT.md D-03]

**How to avoid:** Invoke chunk-origin qualification on the collected `Bytes` before the completed-terminal pull; use Phase 83's literal raw vectors and existing test-local parser. [VERIFIED: `stream_encode_test.mbt:5213-5219`; `encode_test.mbt:1086-1221`]

### Pitfall 3: Zero-capacity test has no observable sentinel

**What goes wrong:** A true zero-length owner cannot demonstrate that the destination remained unmodified. [VERIFIED: STATE.md]

**How to avoid:** Create a one-byte `Z` owner and borrow `with_mut(0UL, 0UL, ...)`; assert its stored byte remains `Z`. [VERIFIED: `stream_encode_test.mbt:5185-5204`]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Phase 83 sufficient-capacity IHDR smoke | Phase 82-style hostile schedule plus independent chunk-origin qualification | Covers the Phase 84 requirement without altering production architecture. [VERIFIED: `stream_encode_test.mbt:5405-5427,5071-5270`] |
| Low-bit non-interlaced hostile helpers | New explicit low-bit Adam7 helpers | Prevents accidental compatibility-route coverage from standing in for Adam7. [VERIFIED: `stream_encode_test.mbt:5301-5385`] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None — conclusions are grounded in the checked-out repository, phase context, and installed toolchain. | — | — |

## Open Questions

None. The Phase 83 5x5 literal fixtures, parser helpers, lifecycle precedent, and all-target command already exist. [VERIFIED: `encode_test.mbt:1086-1221`; `stream_encode_test.mbt:5071-5270`; Phase 83 verification]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Focused and all-target PNG tests | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: `moon --version`] |
| `moonc` / `moonrun` | MoonBit target execution | ✓ | `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: `moon --version`] |

**Required gate:** `moon -C modules/mb-image test png --target all --frozen`. [VERIFIED: Phase 83 verification]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No authentication surface changes. [VERIFIED: CONTEXT.md scope] |
| V3 Session Management | no | No session surface changes. [VERIFIED: CONTEXT.md scope] |
| V4 Access Control | no | No authorization surface changes. [VERIFIED: CONTEXT.md scope] |
| V5 Input Validation | yes | Test-local parser bounds-checks chunks and validates CRC/frame structure before asserting raster evidence. [VERIFIED: `encode_test.mbt:602-650,1051-1084`] |
| V6 Cryptography | no | CRC is an integrity-format check, not a cryptographic control; do not add crypto. [VERIFIED: repository inspection] |

### Known Threat Patterns for this Phase

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed collected-frame interpretation in a test oracle | Tampering | Bounds-check every chunk, check declared chunk order/length, and recompute CRC before raw/decode assertions. [VERIFIED: `encode_test.mbt:602-650,1051-1084`; `stream_encode_test.mbt:5117-5151`] |
| Caller destination modified after terminal/failure | Tampering | Sentinel-filled leases plus zero-write `Finished`/`Failed` replay assertions. [VERIFIED: `stream_encode_test.mbt:5219-5268`] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/stream_encode.mbt:69-82,662-735,1667-1715` — selected-depth facade and acknowledged lifecycle.
- `modules/mb-image/png/stream_encode_test.mbt:5071-5270,5301-5427` — Indexed8 Adam7 qualification precedent and current low-bit boundary.
- `modules/mb-image/png/encode_test.mbt:602-650,1051-1221` — independent parser helpers and selected low-bit Adam7 literals.
- `.planning/phases/83-low-bit-indexed-adam7-machine-and-eager-contract/83-VERIFICATION.md` — verified Phase 83 contract and four-target baseline.
- `AGENTS.md`, `84-CONTEXT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `modules/mb-image/png/moon.pkg`, and `moon --version` — constraints, scope, target declaration, and toolchain.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no external package choice; installed MoonBit toolchain and repository helpers were directly checked. [VERIFIED: `moon --version`]
- Architecture: HIGH — exact facade, lifecycle, and Phase 82 test precedent were inspected. [VERIFIED: repository inspection]
- Pitfalls: HIGH — each is tied to an existing non-interlaced helper, stream harness behavior, or locked decision. [VERIFIED: repository inspection]

**Research date:** 2026-07-24  
**Valid until:** implementation changes to the PNG stream test seam.

## RESEARCH COMPLETE

**Phase:** 84 - Low-Bit Indexed Adam7 Streaming Qualification  
**Confidence:** HIGH

- Add test-only explicit-Adam7 low-bit helpers in `stream_encode_test.mbt` following the Indexed8 Phase 82 structure.
- Exercise One/Two/Four under zero/one/ragged leases; assert accepted-only totals, preserved sentinels, sticky `Finished`, and sticky released-lease `Failed`.
- Independently parse collected bytes with existing test-local CRC/Stored-IDAT helpers and Phase 83 literal rasters, then public-decode RGBA8 and RGB8.
- Preserve all existing vector tests and end with `moon -C modules/mb-image test png --target all --frozen`.
