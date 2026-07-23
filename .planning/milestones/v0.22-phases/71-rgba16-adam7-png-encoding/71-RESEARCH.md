# Phase 71: RGBA16 Adam7 PNG Encoding - Research

**Researched:** 2026-07-23  
**Domain:** Explicit Type-6/16 Adam7 PNG selection over the existing bounded MoonBit encoder  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Explicit Adam7 selection
- **D-01:** Add exactly `PngEncoder::new_rgba16_with_interlace_strategy`, `PngEncoder::new_rgba16_with_all_strategies`, `PngChunkEncoder::new_rgba16_with_interlace_strategy`, and `PngChunkEncoder::new_rgba16_with_all_strategies`, matching the established GrayAlpha16 Adam7 families.
- **D-02:** The existing four eager and four chunk RGBA16 constructors remain explicitly non-interlaced. The new selection APIs accept the established `PngInterlaceStrategy`; Adam7 is opt-in rather than a default.

### Shared pipeline and fidelity
- **D-03:** Route both new families to `PngEncodeProfile::Rgba16` through the existing profile-aware encoder machine and Adam7 traversal/pass planner; do not duplicate byte emission, filtering, admission, progress, or terminal logic.
- **D-04:** Prove a non-symmetric 5x5 packed little-endian RGBA16 source uses legal seven-pass Type-6/16 output, and `PngDecoder::decode_rgba16` reconstructs every source component byte at its original coordinate.
- **D-05:** For Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filtering, fresh eager and caller-buffered Adam7 encodes are byte-identical and retain the existing atomic admission, accepted-only progress, lease isolation, and sticky-terminal behaviour.

### Scope and compatibility
- **D-06:** Preserve existing RGB8/RGBA8 and Gray/GrayAlpha interlace routes, generic constructors, non-interlaced RGBA16 output, colour identity gates, and source layout. Do not add colour transforms, staging, another pass planner or encoder machine, FFI, copied source trees, release automation, or broad four-target qualification; Phase 72 owns qualification.

### the agent's Discretion
- Reuse the closest GrayAlpha16 Adam7 eager/chunk constructors and their public schedule/decode harnesses; add only RGBA16-specific factory and fidelity/lifecycle evidence.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Independent hostile matrix, frozen legacy compatibility sweep, and four-target portable qualification — Phase 72.
- Colour-managed/non-sRGB RGBA16 output, conversions, staging, FFI, release automation, target wrappers, and copied source workflows — out of scope.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| RGBA16ENC-03 | Library users can explicitly select legal Type-6/16 Adam7 PNG output from `rgba16` sources while preserving every U16 lane, existing filter/compression choices, and frozen non-interlaced behavior. [VERIFIED: codebase grep] | The two existing GrayAlpha16 selector shapes, `Rgba16` profile wiring, independent seven-pass raster oracle, explicit decoder oracle, and six-pair fresh eager/chunk schedule harness give the narrow implementation and test plan. [VERIFIED: codebase grep] |

## Summary

Phase 71 is an additive public-surface change, not an encoder-algorithm change. The profile-aware machine already accepts a profile plus `PngInterlaceStrategy`, sends Adam7 through its existing filtered cursor/pass planner, maps `Rgba16` to IHDR colour type 6/depth 16, and applies the existing per-component little-endian-to-PNG-wire mapping. [VERIFIED: codebase grep] The only production work should therefore be two eager and two chunk RGBA16 selectors that mirror the GrayAlpha16 selector families and pass their selected interlace value into the existing seams. [VERIFIED: codebase grep]

The fidelity proof must be stricter than Phase 69's 2x1 non-interlaced vector: use a packed little-endian 5x5 RGBA16 source whose four components and two lanes vary by coordinate, derive the Stored/filter-None raster from independently written Adam7 pass geometry, then decode with `PngDecoder::decode_rgba16` and compare every `(x, y, component, lane)` byte with the source. [VERIFIED: codebase grep] For a 5x5 Type-6/16 source, the established seven pass offsets produce a 211-byte uncompressed filtered raster: seven filter tags plus 204 component-wire bytes. [VERIFIED: codebase grep]

PNG permits truecolour with alpha (colour type 6) at bit depth 16, defines sample order as R, G, B, alpha, and assigns Adam7 to interlace method 1 with seven passes. [CITED: https://www.w3.org/TR/png-3/] This phase should assert those framing facts (`IHDR[24]=0x10`, `IHDR[25]=0x06`, `IHDR[28]=0x01`) without widening generic or non-interlaced APIs. [VERIFIED: codebase grep]

**Primary recommendation:** Add exactly the four locked factories in `png.mbt` and `stream_encode.mbt`; add an independent 5x5 eager wire/decode test and reuse the GrayAlpha16 fresh-encoder drain structure for all six Adam7 compression/filter pairs. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public eager RGBA16 Adam7 selection | API / Backend | — | `PngEncoder` owns immutable selector configuration before it calls the bounded encoder machine. [VERIFIED: codebase grep] |
| Public caller-buffered RGBA16 Adam7 selection | API / Backend | — | `PngChunkEncoder` constructs the shared machine; callers retain only output leases. [VERIFIED: codebase grep] |
| Adam7 pass traversal, filtering, compression, and wire bytes | API / Backend | — | The existing `PngFilteredCursor`, Adam7 location/pass helpers, and `PngEncodeMachine` emit the stream without a per-format traversal. [VERIFIED: codebase grep] |
| Source bytes and explicit round-trip restoration | Database / Storage | API / Backend | Checked `ImageView` storage is read by the encoder and reconstructed by `decode_rgba16`; no persistent service is involved. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain in MoonBit; native stubs/FFI must be isolated and replaceable. This phase adds neither FFI nor a foreign implementation. [VERIFIED: AGENTS.md]
- Public package dependencies remain acyclic and explicitly documented. This phase adds no package or dependency. [VERIFIED: AGENTS.md]
- Public API compatibility follows Semantic Versioning after stability; preserve all existing constructors and make the Adam7 route additive and explicit. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and usable without GUI state. The proof uses deterministic public encoder/decoder and caller-lease tests. [VERIFIED: AGENTS.md]
- Public package tests use `*_test.mbt`; internal invariants use `*_wbtest.mbt`. The closest public evidence is in `encode_test.mbt` and `stream_encode_test.mbt`. [VERIFIED: AGENTS.md; codebase grep]
- Do not edit production code, tests, or unrelated artifacts outside the GSD phase workflow. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Existing `mb-image/png` MoonBit package | Repository workspace | Public PNG selectors, profile-aware bounded machine, Adam7 traversal, and explicit RGBA16 decode. [VERIFIED: codebase grep] | The locked scope requires reuse of this single pipeline; no external library or package installation is needed. [VERIFIED: 71-CONTEXT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| MoonBit package test runner | Repository workspace | Execute the focused public PNG regression suite. [VERIFIED: 69-VERIFICATION.md; 70-VERIFICATION.md] | Run the Phase 71 tests on the focused JS target; broad four-target qualification remains Phase 72. [VERIFIED: 71-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Existing profile-aware machine and Adam7 cursor | A new RGBA16 pass planner, staging buffer, or encoder machine | Rejected by D-03/D-06; the existing machine already receives `Rgba16` and the selected interlace strategy, so duplication would risk different filtering, admission, replay, and terminal behavior. [VERIFIED: 71-CONTEXT.md; codebase grep] |
| Explicit RGBA16 selectors | Changing generic constructors or making Adam7 implicit | Rejected by D-01/D-02/D-06; generic and non-interlaced constructors are frozen compatibility baselines. [VERIFIED: 71-CONTEXT.md] |

**Installation:** None — this phase installs no external packages. [VERIFIED: 71-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
checked packed rgba16 ImageView
          |
          v
new_rgba16_*_with_[interlace|all]_strategies
          |
          v
PngEncodeMachine::new_with_profile(Rgba16, compression, filter, Adam7)
          |
          +--> atomic profile/resource preflight
          |
          v
existing Adam7 pass cursor -> existing filter/compression emission -> PNG IHDR/IDAT bytes
          |                                                            |
          |                                                            +--> eager writer
          +------------------------------------------------------------+--> chunk pull leases
                                                                         |
                                                                         v
                                                         PngDecoder::decode_rgba16 test oracle
```

The diagram follows the existing factory-to-machine-to-cursor flow; the public routes differ only at the final eager writer versus caller-owned pull lease. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # Add two eager RGBA16 Adam7 selectors only
├── stream_encode.mbt       # Add two chunk RGBA16 Adam7 selectors only
├── encode_test.mbt         # 5x5 Type-6/16 pass-raster and decode fidelity
└── stream_encode_test.mbt  # Fresh eager/chunk parity under public schedules
```

The smallest correct file set is those four existing PNG files; `encode.mbt` and the generic APIs already contain the required traversal and wire logic. [VERIFIED: codebase grep]

### Pattern 1: Thin explicit selector over the shared profile-aware machine

**What:** The narrow eager selector delegates defaults to the all-strategy selector; the all-strategy selector stores `PngEncodeProfile::Rgba16` plus the caller-selected `PngInterlaceStrategy`. The chunk form follows the same delegation and passes `Rgba16`, strategies, and interlace unchanged to `PngEncodeMachine::new_with_profile`. [VERIFIED: codebase grep]

**When to use:** Use this exact pattern for the four locked APIs only. [VERIFIED: 71-CONTEXT.md]

**Implementation shape:**

```moonbit
// Repository pattern, adapted for RGBA16 selection.
pub fn PngEncoder::new_rgba16_with_interlace_strategy(interlace) {
  PngEncoder::new_rgba16_with_all_strategies(Stored, None, interlace)
}

pub fn PngChunkEncoder::new_rgba16_with_all_strategies(source, compression, filter, interlace, limits, budget, diagnostics) {
  // construct only through the existing Rgba16 profile-aware machine
}
```

This is pseudocode, not a second implementation; the executable spelling and argument formatting should be copied from the immediately adjacent GrayAlpha16 families. [VERIFIED: codebase grep]

### Pattern 2: Independent Stored raster plus explicit decoder coordinate oracle

**What:** Keep fixture construction and expected pass enumeration in the test file, use literal Adam7 tuples `(x, y, dx, dy)`, append one filter byte per pass row, and append `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo` from a coordinate-derived fixture rather than asking the encoder cursor for expected data. Then feed emitted bytes into public `PngDecoder::decode_rgba16` and compare all source storage lanes by coordinate. [VERIFIED: codebase grep]

**When to use:** Use it once for Stored/filter-None Type-6/16 Adam7 fidelity; then use framing plus decode in the six-pair selector loop. [VERIFIED: 71-CONTEXT.md; codebase grep]

### Pattern 3: Fresh eager parity under hostile caller leases

**What:** For every compression/filter pair, construct a fresh eager RGBA16 Adam7 byte oracle and a fresh chunk encoder, issue a zero-capacity lease followed by `[0,1]`, `[1]`, and the established ragged schedule, collect only acknowledged bytes, protect unwritten lease tails with sentinels, and pull again after completion to prove the sticky zero-write terminal. [VERIFIED: codebase grep]

**When to use:** Use the existing `png_graya16_adam7_chunk_drain` structure, changing only fixture/helper and public factory names to RGBA16. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **A format-specific Adam7 cursor or pass planner:** The generic Adam7 cursor takes the profile and resolves pass geometry centrally; a second RGBA16 route can diverge on byte order, pass boundaries, or Adaptive predictors. [VERIFIED: codebase grep]
- **Changing existing RGBA16 constructors to accept interlace:** The four existing eager and four chunk constructors explicitly select `None`; retaining that literal selection is a locked compatibility requirement. [VERIFIED: 71-CONTEXT.md; codebase grep]
- **Using the encoder as the only fidelity oracle:** An eager/chunk equality test alone can reproduce a shared traversal defect. The Stored pass expectation and public explicit decoder must be independent. [VERIFIED: 71-CONTEXT.md; codebase grep]
- **Running Phase 72's broad qualification here:** Four-target package qualification and independent hostile/legacy sweeps are explicitly deferred. [VERIFIED: 71-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Adam7 pass geometry and local filtering | RGBA16-only pass planner, filter state, or raster staging | Existing `_png_adam7_passes`, `PngFilteredCursor`, and profile-aware wire reads. [VERIFIED: codebase grep] | The cursor resets predictors at pass boundaries and already routes raw samples through the profile-specific U16 wire mapping. [VERIFIED: codebase grep] |
| Eager/chunk lifecycle | New chunk transport, acknowledgement counter, or terminal cache | Existing `PngChunkEncoder::pull` state machine. [VERIFIED: 70-VERIFICATION.md; codebase grep] | It already owns accepted-only totals, tail isolation, revision checking, and sticky terminal outcomes. [VERIFIED: 70-VERIFICATION.md] |
| Type-6/16 byte order | RGBA16 conversion or copied byte traversal | Existing `_png_wire_byte` on `PngEncodeProfile::Rgba16`. [VERIFIED: codebase grep] | It maps each little-endian U16 component to the mandated PNG component wire order before filters and compression. [VERIFIED: codebase grep; https://www.w3.org/TR/png-3/] |
| Decode oracle | A private encoder-cursor assertion | Existing public `PngDecoder::decode_rgba16`. [VERIFIED: codebase grep] | It independently observes reconstructed packed component bytes at public API level. [VERIFIED: 69-VERIFICATION.md; codebase grep] |

**Key insight:** Phase 71's risk is not missing capability in the encoder core; it is accidentally bypassing the single pipeline or weakening independent U16/coordinate evidence while exposing the new public selector names. [VERIFIED: 71-CONTEXT.md; codebase grep]

## Common Pitfalls

### Pitfall 1: Selecting the right profile but leaving Adam7 at `None`

**What goes wrong:** The new selector emits valid non-interlaced Type-6/16 bytes, concealing that the public Adam7 choice was ignored. [VERIFIED: codebase grep]

**Why it happens:** The current RGBA16 factory family hard-codes `PngInterlaceStrategy::None`, while the GrayAlpha16 all-strategy family forwards its argument. [VERIFIED: codebase grep]

**How to avoid:** In both all-strategy RGBA16 selectors, forward the named interlace argument directly to the existing `PngEncoder` field or `new_with_profile` call; assert IHDR interlace byte `0x01` for Adam7 and `0x00` for existing selectors. [VERIFIED: codebase grep]

**Warning signs:** New public APIs compile, but output has `IHDR[28] == 0x00`, the seven-pass raster is absent, or a narrow-selector/all-selector comparison only validates non-interlaced bytes. [VERIFIED: codebase grep]

### Pitfall 2: Testing a small source that does not exercise every pass

**What goes wrong:** A tiny or symmetric source can leave Adam7 passes empty or hide coordinate/lane swaps. [VERIFIED: codebase grep]

**Why it happens:** Adam7 extracts sparse reduced images; the existing 5x5 GrayAlpha16 fixture was specifically chosen to make every pass nonempty. [VERIFIED: codebase grep]

**How to avoid:** Build a 5x5 packed `rgba16` fixture with distinct coordinate/component/lane values, enumerate all seven standard tuples independently, and assert the complete 211-byte Stored raster. [VERIFIED: codebase grep]

**Warning signs:** The expected raster covers fewer than seven filter tags, decode checks only a row or only high bytes, or multiple source coordinates share the same lane values. [VERIFIED: codebase grep]

### Pitfall 3: Parity without transport invariants

**What goes wrong:** Complete eager/chunk byte equality can pass even if a chunk pull over-reports progress, overwrites the unused lease tail, or changes post-finish behavior. [VERIFIED: 70-VERIFICATION.md]

**Why it happens:** Caller-buffered behavior is observable per pull, not only in the final aggregate. [VERIFIED: 70-VERIFICATION.md]

**How to avoid:** Reuse the GrayAlpha16 drain assertions for zero-capacity, one-byte, and ragged schedules; check acknowledged-prefix totals, sentinel tails, and later `Finished` pulls across all six strategy pairs. [VERIFIED: codebase grep]

**Warning signs:** Tests drain with only one large buffer, reuse one encoder for multiple schedules, or omit the post-finish sentinel pull. [VERIFIED: codebase grep]

### Pitfall 4: Consuming Phase 72 scope in Phase 71

**What goes wrong:** The implementation grows into a four-target matrix, copied fixtures, or a broad hostile legacy sweep without adding Phase 71 functionality. [VERIFIED: 71-CONTEXT.md]

**How to avoid:** Keep validation to focused existing PNG tests and add only RGBA16-specific selector/fidelity/lifecycle evidence; record broad qualification as Phase 72 work. [VERIFIED: 71-CONTEXT.md]

## Code Examples

### Selector-to-machine preservation check

```text
For `new_rgba16_with_all_strategies`:
  profile      = Rgba16
  compression  = caller input
  filter       = caller input
  interlace    = caller input

For each existing `new_rgba16*` constructor:
  interlace    = None (unchanged)
```

This mapping is the adjacent GrayAlpha16 construction pattern and preserves the existing `Rgba16` profile’s IHDR and U16 wire behavior. [VERIFIED: codebase grep]

### Independent 5x5 Adam7 expected-raster pattern

```text
passes = [(0,0,8,8), (4,0,8,8), (0,4,4,8), (2,0,4,4),
          (0,2,2,4), (1,0,2,2), (0,1,1,2)]
for each pass row:
  append filter None tag
  for each selected (x,y): append Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo
```

The existing GrayAlpha16 test already uses these seven tuples independently from the encoder cursor; RGBA16 extends only the per-pixel lane emission from four to eight bytes. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Phase 69/70 explicit RGBA16 routes fix interlace to `None`. [VERIFIED: 69-VERIFICATION.md; 70-VERIFICATION.md] | Phase 71 adds opt-in explicit RGBA16 interlace selectors while preserving those fixed routes. [VERIFIED: 71-CONTEXT.md] | Planned Phase 71. [VERIFIED: 71-CONTEXT.md] | Consumers can request legal Type-6/16 Adam7 without a generic API change. [VERIFIED: 71-CONTEXT.md; https://www.w3.org/TR/png-3/] |
| Profile-specific encoder expansion risks a dedicated transport. [VERIFIED: 69-CONTEXT.md; 70-CONTEXT.md] | The existing profile-aware machine remains the only emitter for eager and caller-buffered output. [VERIFIED: codebase grep] | Phase 69/70 established the `Rgba16` profile. [VERIFIED: 69-VERIFICATION.md; 70-VERIFICATION.md] | Admission, compression, filtering, and terminal semantics stay shared. [VERIFIED: 70-VERIFICATION.md] |

**Deprecated/outdated:** No Phase 71 API is deprecated. Adding a generic RGBA16 Adam7 default or a second encoder machine would contradict locked compatibility and scope decisions. [VERIFIED: 71-CONTEXT.md]

## Assumptions Log

All implementation recommendations are grounded in the locked Phase 71 context, prior phase verification, repository source inspection, or the W3C PNG specification. No user confirmation is needed before planning. [VERIFIED: 71-CONTEXT.md; codebase grep; https://www.w3.org/TR/png-3/]

## Open Questions

None. The public names, profile, non-interlaced compatibility rule, test source dimensions, strategy matrix, and deferred qualification boundary are locked. [VERIFIED: 71-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No — this deterministic in-process codec surface does not authenticate users. [VERIFIED: codebase grep] | — |
| V3 Session Management | No — the chunk encoder has output lifecycle state, not an authenticated user session. [VERIFIED: codebase grep] | Existing sticky `Finished`/`Failed` result handling remains shared. [VERIFIED: 70-VERIFICATION.md] |
| V4 Access Control | No — this phase exposes no authorization boundary. [VERIFIED: codebase grep] | — |
| V5 Input Validation | Yes. [VERIFIED: codebase grep] | Existing `Rgba16` profile preflight validates the checked format/layout/metadata identity and resource limits before construction. [VERIFIED: 69-VERIFICATION.md; 70-VERIFICATION.md] |
| V6 Cryptography | No — PNG DEFLATE/checksum processing is not a cryptographic control. [VERIFIED: codebase grep] | — |

### Known Threat Patterns for the PNG encoder

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Oversized or incompatible source/resource request | Denial of service | Reuse bounded profile preflight before writer or caller lease exposure. [VERIFIED: 69-VERIFICATION.md; 70-VERIFICATION.md] |
| Source mutation after construction | Tampering | Reuse the machine’s revision validation and cached typed terminal before later lease writes. [VERIFIED: 70-VERIFICATION.md] |
| U16 component lane/order loss | Tampering | Reuse profile-aware U16 wire conversion and verify all 5x5 source lanes through public `decode_rgba16`. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/png.mbt` — existing eager GrayAlpha16 Adam7 and RGBA16 non-interlaced factory shapes. [VERIFIED: codebase grep]
- `modules/mb-image/png/stream_encode.mbt` — existing chunk GrayAlpha16 families, shared profile-aware construction, and IHDR profile/interlace emission. [VERIFIED: codebase grep]
- `modules/mb-image/png/encode.mbt` — U16 wire mapping, profile admission, Adam7 pass cursor, and pass-local filtering. [VERIFIED: codebase grep]
- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — independent GrayAlpha16 pass oracle, decode evidence, and public hostile-schedule drain. [VERIFIED: codebase grep]
- `71-CONTEXT.md`, `69-VERIFICATION.md`, and `70-VERIFICATION.md` — locked phase boundary and previously verified RGBA16 contracts. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — legal Type-6/16 combination, R/G/B/alpha sample order, and Adam7 interlace method 1/seven-pass definition. [CITED: https://www.w3.org/TR/png-3/]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no dependency choice; the existing project machine is the locked implementation seam. [VERIFIED: 71-CONTEXT.md; codebase grep]
- Architecture: HIGH — direct source inspection shows profile/interlace forwarding, U16 wire reads, pass traversal, and chunk lifecycle ownership. [VERIFIED: codebase grep]
- Pitfalls: HIGH — each is an observed distinction between current hard-coded RGBA16 `None` factories and the existing GrayAlpha16 Adam7/test patterns. [VERIFIED: codebase grep]

**Research date:** 2026-07-23  
**Valid until:** Implementation start for Phase 71; this is repository-state research, so re-check only if the four PNG files or Phase 71 context change. [VERIFIED: codebase grep; 71-CONTEXT.md]
