# Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile - Research

**Researched:** 2026-07-23  
**Domain:** Portable MoonBit Type-4/8 PNG Adam7 encoding  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Additive public eager and chunk GrayAlpha8 Adam7 factories follow the existing GrayAlpha16 Adam7 naming and strategy pattern; no legacy constructor changes.
- **D-02:** Permit GrayAlpha8 only through the existing profile-aware Adam7 machine and remove only its profile-specific non-interlaced rejection; no second encoder or staging path.
- **D-03:** Serialize Type-4/8 Adam7 samples in PNG order as `G,A` and use the existing seven-pass geometry/cursor.
- **D-04:** Keep legal packed straight-alpha sRGB/top-left admission and frozen interlace-method-0 legacy output unchanged.

### the agent's Discretion

- Reuse the smallest GrayAlpha16 Adam7 and GrayAlpha8 factory/profile tests; production changes must be limited to the shared admission/factory seam.

### Deferred Ideas (OUT OF SCOPE)

- Six-pair replay mutation protection belongs to Phase 60; public hostile schedules and all-target evidence belong to Phase 61.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRAYA8A7-01 | Library users can select explicit eager and caller-buffered Adam7 Type-4/8 PNG factories for legal packed straight-alpha GrayAlpha8 sources; existing non-interlaced factories and bytes remain unchanged. | Mirror the completed GrayAlpha16 selector pairs, use the present `GrayAlpha8` profile, relax only its preflight interlace gate, and test seven-pass `G,A` output plus frozen method-0 routes. |
</phase_requirements>

## Summary

Phase 59 is a narrow additive capability: add the two established eager selectors and two established caller-buffered selectors for the existing `GrayAlpha8` profile, then allow that profile to enter the current Adam7 branch of the shared machine. The only production files should be `png.mbt`, `stream_encode.mbt`, and the profile guard in `encode.mbt`; no decoder, cursor, compression planner, pass buffer, dependency, FFI, or target-specific code is needed. [VERIFIED: current `modules/mb-image/png/png.mbt`, `stream_encode.mbt`, `encode.mbt`, and archived v0.18 Phase 56 summaries]

The required Type-4/8 wire contract is directly compatible with this architecture: PNG grayscale-with-alpha is colour type 4, has gray then alpha samples, permits bit depth 8, and uses IHDR interlace method 1 for Adam7. Adam7 is seven reduced images whose selected pixels and scanlines are serialized pass-locally, which matches the existing two-channel `_png_adam7_passes` and scalar cursor. [CITED: https://www.w3.org/TR/png-3/]

**Primary recommendation:** implement the GrayAlpha16 Adam7 factory pattern verbatim with `GrayAlpha8`, delete only the `GrayAlpha8` non-interlaced preflight arm, and begin with two focused public regressions: an eager 5x5 Stored/None pass-profile test and a caller-buffered selector-to-eager parity test.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Explicit eager Adam7 selection | Public eager PNG facade | Shared encoder machine | The facade chooses the existing profile and strategies; the machine owns all encoding. [VERIFIED: `png.mbt`, `encode.mbt`] |
| Explicit caller-buffered Adam7 selection | Public chunk PNG facade | Shared encoder machine | The chunk facade must construct the same profile-aware machine, not own a separate traversal. [VERIFIED: `stream_encode.mbt`] |
| Source admission, pass geometry, filtering, compression, replay | Shared encoder machine | Structural Adam7 helper | Existing preflight and cursor already parameterize these operations by profile, channels, and interlace strategy. [VERIFIED: `encode.mbt`] |
| Type-4/8 public wire proof and compatibility freeze | PNG public tests | Existing encoder facade | Tests must distinguish `G,A` pass output from unchanged interlace-0 legacy output. [VERIFIED: `encode_test.mbt`, `stream_encode_test.mbt`] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit-native; no foreign wrapper is appropriate. [VERIFIED: `AGENTS.md`]
- Supported behavior must remain portable across js, wasm, wasm-gc, and native through capability boundaries and conformance tests. [VERIFIED: `AGENTS.md`]
- Public package dependencies stay acyclic and APIs preserve SemVer-compatible additive behavior. [VERIFIED: `AGENTS.md`]
- Public tests are black-box `*_test.mbt`; representation and checked-arithmetic checks belong in `*_wbtest.mbt` or inline tests. [VERIFIED: `AGENTS.md`]
- Deterministic CLI-visible behavior is required; no GUI state, copied-source workflow, FFI, or release wrapper belongs in this phase. [VERIFIED: `AGENTS.md`, `REQUIREMENTS.md`]
- No project-local skill is installed, and `.planning/config.json` disables Nyquist validation for this phase. [VERIFIED: repository skill directories and `.planning/config.json`]

## Standard Stack

### Core

| Library / component | Version | Purpose | Why Standard |
|---------------------|---------|---------|--------------|
| MoonBit toolchain | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf` | Compile and test portable package code. | The repository pins and currently provides this exact toolchain. [VERIFIED: local `moon --version`, `AGENTS.md`] |
| Existing `mb-image/png` | repository source | Profile admission, Adam7 geometry/cursor, filtering, DEFLATE, and public facades. | Already contains the complete reusable pipeline and the GrayAlpha16 Adam7 analogue. [VERIFIED: `png.mbt`, `encode.mbt`, `stream_encode.mbt`] |

### Supporting

None. This phase installs no package and introduces no external runtime dependency. [VERIFIED: `REQUIREMENTS.md`, current package manifests]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `GrayAlpha8` profile plus `PngInterlaceStrategy::Adam7` | A `GrayAlpha8Adam7` profile, second encoder, or pass-raster staging | Rejected: duplicates the current shared preflight/cursor/replay authority and violates locked D-02. [VERIFIED: `59-CONTEXT.md`, `encode.mbt`] |
| Explicit new GrayAlpha8 selectors | Change existing `new_graya8*` defaults | Rejected: silently changes stable interlace-0 output and violates locked D-01/D-04. [VERIFIED: `59-CONTEXT.md`, `png.mbt`] |

**Installation:** none.

## Architecture Patterns

### System Architecture Diagram

```text
legal packed U8 GrayAlpha8 ImageView
        |
        +--> PngEncoder::new_graya8_with_{interlace,all}_strategies
        |       |
        +--> PngChunkEncoder::new_graya8_with_{interlace,all}_strategies
                |
                v
  PngEncodeMachine::new_with_profile(GrayAlpha8, ..., Adam7)
                |
                v
 shared descriptor admission + atomic preflight + Adam7 scalar cursor
                |
                v
      Stored/None Type-4/8 seven-pass PNG output
```

The single flow above is the required implementation boundary. The existing cursor resolves every Adam7 logical byte through `_png_adam7_passes(source.width(), source.height(), channels, 8)` and reads U8 GrayAlpha components through the ordinary profile-aware wire reader; `channels=2` therefore yields `G,A` bytes without a U16 conversion branch. [VERIFIED: `encode.mbt`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # eager public factory pair
├── stream_encode.mbt       # caller-buffered public factory pair
├── encode.mbt              # one GrayAlpha8 Adam7 preflight-gate removal
├── encode_test.mbt         # eager seven-pass / legacy regression
└── stream_encode_test.mbt  # chunk selector-to-eager parity regression
```

### Pattern 1: Additive explicit interlace selector pair

**What:** Provide the narrow Stored/None selector and the independently selected compression/filter/interlace selector; retain old factories as explicit `None` constructors. [VERIFIED: GrayAlpha16 implementations in `png.mbt` and `stream_encode.mbt`]

**When to use:** A new format/interlace combination must be opt-in without changing established byte output. [VERIFIED: `59-CONTEXT.md`]

**Exact implementation shape:**

```moonbit
pub fn PngEncoder::new_graya8_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_graya8_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

pub fn PngEncoder::new_graya8_with_all_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  { strategy, filter_strategy, interlace_strategy, profile: PngEncodeProfile::GrayAlpha8 }
}
```

The chunk pair mirrors this API and passes `interlace_strategy` directly to `PngEncodeMachine::new_with_profile(source, PngEncodeProfile::GrayAlpha8, ...)`. [VERIFIED: GrayAlpha16 analogue in `png.mbt` and `stream_encode.mbt`]

### Pattern 2: One narrow profile-gate relaxation

**What:** Delete only this rejection from `_png_encode_preflight_with_interlace_profile`:

```moonbit
PngEncodeProfile::GrayAlpha8 if interlace_strategy != PngInterlaceStrategy::None =>
  return Err(_png_encode_capability("graya8-noninterlaced-required"))
```

Keep Gray8 and Gray16 rejections, all source admission checks, the atomic ledger, and the legacy `None` factory wiring unchanged. [VERIFIED: `encode.mbt`, `59-CONTEXT.md`]

### Anti-Patterns to Avoid

- **Parallel Type-4/8 Adam7 encoder:** duplicates bounded source replay and could bypass the existing atomic ledger; select the present machine instead. [VERIFIED: `encode.mbt`, archived v0.18 Phase 56 summary]
- **Pass-raster materialization:** violates D-02 and is unnecessary because the existing cursor performs scalar pass-local lookup. [VERIFIED: `59-CONTEXT.md`, `encode.mbt`]
- **Changing `new_graya8*` to select Adam7:** changes frozen output bytes; add only new factory names. [VERIFIED: `png.mbt`, `59-CONTEXT.md`]
- **Broadening Gray8/Gray16 Adam7 admission:** outside GRAYA8A7-01 and would weaken the intentionally explicit capability boundary. [VERIFIED: `REQUIREMENTS.md`, `encode.mbt`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Adam7 geometry / pass order | A Type-4/8-specific pass loop | `_png_adam7_passes(..., 2, 8)` and the existing filtered cursor | One structural authority prevents divergent row totals and pass boundaries. [VERIFIED: `encode.mbt`, `structural.mbt`] |
| U8 `G,A` pass reads | A new byte-order mapper | `_png_wire_byte` through `GrayAlpha8` | U8 profiles already map ordinary component order while U16 mapping remains isolated. [VERIFIED: `encode.mbt`] |
| Eager/chunk encoding | Separate GrayAlpha8 Adam7 state machines | `PngEncodeMachine::new_with_profile` | It already owns preflight, filtering, compression, replay, and caller acknowledgement. [VERIFIED: `stream_encode.mbt`, `encode.mbt`] |
| Legacy compatibility oracle | New opaque snapshots | Existing literal framing/bytes plus focused fixture assertions | A literal interlace-0 regression makes accidental default drift visible. [VERIFIED: existing GrayAlpha8 tests] |

**Key insight:** this phase is a selector-and-admission change, not a PNG-algorithm implementation. [VERIFIED: `59-CONTEXT.md`, v0.19 architecture research]

## Common Pitfalls

### Pitfall 1: Wrong Type-4/8 Adam7 raster order

**What goes wrong:** A test proves only IHDR or encoder/decoder self-consistency, allowing a channel swap or flattened row order to pass.  
**Why it happens:** Non-interlaced GrayAlpha8 is also two bytes per pixel, but Adam7 concatenates seven reduced images.  
**How to avoid:** Start with an asymmetric 5x5 U8 fixture that makes every pass nonempty; derive a test-owned expected stored payload by enumerating the seven `(x, y, dx, dy)` pass tuples and append `filter=0, G, A` for each selected pixel. Assert IHDR bytes `08 04 00 00 01` and the complete inflated pass raster. [CITED: https://www.w3.org/TR/png-3/; VERIFIED: GrayAlpha16 reference in `encode_test.mbt`]  
**Warning signs:** A constant or symmetric fixture, only IHDR assertions, or no assertion of the full seven-pass stored payload.

### Pitfall 2: Accidentally changing legacy output

**What goes wrong:** Existing `new_graya8*` calls begin emitting interlace method 1.  
**Why it happens:** New generic defaults are reused instead of additive selectors.  
**How to avoid:** Preserve the exact `PngInterlaceStrategy::None` construction in current factories; retain the existing non-interlaced GrayAlpha8 wire/framing test and add explicit legacy-to-`None` parity if the focused test needs it. [VERIFIED: `png.mbt`, `encode_test.mbt`]  
**Warning signs:** Existing IHDR method byte at offset 28 changes from `0` to `1`.

### Pitfall 3: Leaking scope from Phase 60/61

**What goes wrong:** Phase 59 adds a six-pair mutation matrix, hostile schedules, decoder changes, or release tooling.  
**Why it happens:** The shared machine is tempting to prove comprehensively while enabling it.  
**How to avoid:** Phase 59 proves two public Stored/None selector shapes, one seven-pass `G,A` profile, and frozen legacy `None`; defer all-strategy replay/atomic and public portable schedule evidence exactly as locked. [VERIFIED: `59-CONTEXT.md`, `ROADMAP.md`]  
**Warning signs:** Production edits outside the three named seams or tests that belong exclusively to Phase 60/61.

### Pitfall 4: Mistaking pass-local filtering for a Phase 59 rewrite

**What goes wrong:** A new filter cursor or predictor state is added for GrayAlpha8.  
**Why it happens:** Adam7 has pass-local rows, but the existing cursor already evaluates `row` within the selected pass.  
**How to avoid:** Do not modify cursor/filter code in this phase; later Phase 60 exercises both filter strategies and validates the shared behavior. [VERIFIED: `_png_adam7_cursor_location`, `_png_adam7_candidate_byte`, and `_png_adam7_row_winner` in `encode.mbt`]  
**Warning signs:** A new GrayAlpha8-only cursor type, an array of pass scanlines, or changed predictor code.

## Code Examples

### Test-owned Type-4/8 pass expectation

```moonbit
// Test-only: keep pass geometry independent from the encoder cursor.
for pass in [
  (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
  (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
  (0UL, 1UL, 1UL, 2UL),
] {
  for y = start_y; y < 5UL; y = y + stride_y {
    expected.push(b'\x00')
    for x = start_x; x < 5UL; x = x + stride_x {
      expected.push(gray(x, y))
      expected.push(alpha(x, y))
    }
  }
}
```

This should be adapted from `png_encode_graya16_adam7_expected_passes`, changing each four-byte U16 wire lane to two independently asymmetric U8 `G,A` values. [VERIFIED: `encode_test.mbt`]

### Test-first execution sequence

1. Add RED eager test: missing `new_graya8_with_interlace_strategy` / `new_graya8_with_all_strategies` and a 5x5 Type-4/8 expected pass raster. [VERIFIED: `encode_test.mbt` GrayAlpha16 analogue]
2. Add RED chunk test: missing `PngChunkEncoder` selector pair, each drained against its corresponding fresh eager selector. [VERIFIED: `stream_encode_test.mbt` GrayAlpha16 analogue]
3. Implement only the two eager factories, two chunk factories, and one deleted GrayAlpha8 gate. [VERIFIED: `png.mbt`, `stream_encode.mbt`, `encode.mbt`]
4. Run focused native tests, then the ordinary native PNG suite. Phase 61 owns the frozen four-target qualification. [VERIFIED: `ROADMAP.md`, v0.18 Phase 56 summary]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| GrayAlpha8 accepts only explicit non-interlaced constructors. | Additive explicit interlace factory pair selects Adam7 only when requested. | Existing outputs stay frozen while legal Type-4/8 Adam7 becomes available. [VERIFIED: `png.mbt`, `59-CONTEXT.md`] |
| GrayAlpha16 proves this selector pattern with U16 PNG wire conversion. | GrayAlpha8 reuses the same profile-aware route with ordinary U8 `G,A` reads. | The phase adds no byte-order mapper or parallel machine. [VERIFIED: `encode.mbt`, archived v0.18 Phase 56 summary] |

## Assumptions Log

All implementation claims are verified from the current repository or cited from the PNG specification; no planner decision requires user confirmation.

## Open Questions

None blocking. The exact public test labels and current suite count should be taken from the test implementation at execution time, not copied from archived milestone output. [VERIFIED: `ROADMAP.md` assigns broad public/all-target qualification to Phase 61]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No identity boundary exists in this portable image library phase. [VERIFIED: phase scope] |
| V3 Session Management | no | No session state exists. [VERIFIED: phase scope] |
| V4 Access Control | no | No authorization boundary exists. [VERIFIED: phase scope] |
| V5 Input Validation | yes | Keep existing source descriptor, capability, geometry, output/work, and budget preflight; do not bypass it with an Adam7-only constructor. [VERIFIED: `encode.mbt`] |
| V6 Cryptography | no | PNG checksum/DEFLATE behavior is existing format processing, not cryptographic control. [VERIFIED: phase scope] |

### Known Threat Patterns for portable PNG encoding

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed or incompatible source descriptor bypasses limits | Tampering / Denial of Service | Continue through `_png_encode_preflight_with_interlace_profile` and the existing atomic ledger; remove only the GrayAlpha8 interlace exclusion. [VERIFIED: `encode.mbt`] |
| Unbounded pass staging | Denial of Service | Keep the current scalar pass cursor; add no per-image/pass byte buffer. [VERIFIED: `encode.mbt`, `59-CONTEXT.md`] |
| Legacy output changes unexpectedly | Tampering | Explicit opt-in selector names and literal method-0 regression coverage. [VERIFIED: `png.mbt`, `REQUIREMENTS.md`] |

## Sources

### Primary (HIGH confidence)

- Current `modules/mb-image/png/png.mbt` — existing GrayAlpha8 non-interlaced factories and GrayAlpha16 Adam7 eager analogue.
- Current `modules/mb-image/png/stream_encode.mbt` — existing GrayAlpha8 chunk construction and GrayAlpha16 Adam7 chunk analogue.
- Current `modules/mb-image/png/encode.mbt` — profile admission, GrayAlpha8-only preflight rejection, scalar wire reads, Adam7 cursor, and ledger.
- Current `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — established focused public test patterns.
- `.planning/milestones/v0.18-phases/56-grayalpha16-adam7-factory-and-pass-profile/56-01-SUMMARY.md` and `56-02-SUMMARY.md` — completed execution evidence for the exact analogue.

### Secondary (MEDIUM confidence)

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — colour type 4 / depth 8, gray-alpha sample order, Adam7 pass order, and IHDR interlace field.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no external package or new runtime is involved; current local toolchain and source are available.
- Architecture: HIGH — all intended production seams and the GrayAlpha16 reference implementation are present in the current tree.
- Pitfalls: HIGH — the hazards map directly to explicit factory/default/profile gates and test seams; PNG wire facts are corroborated by the W3C specification.

**Research date:** 2026-07-23  
**Valid until:** implementation changes to the PNG facade or profile preflight.
