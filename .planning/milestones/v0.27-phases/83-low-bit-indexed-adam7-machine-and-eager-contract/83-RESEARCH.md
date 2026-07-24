# Phase 83: Low-Bit Indexed Adam7 Machine and Eager Contract - Research

**Researched:** 2026-07-24  
**Domain:** MoonBit PNG Type-3 low-bit Adam7 encoding  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add selected low-bit interlace companions using the existing `PngInterlaceStrategy`; legacy low-bit APIs explicitly select `None`.
- **D-02:** For every nonempty Adam7 pass row, derive `ceil(pass_width * depth / 8)` independently and repack pass-coordinate indices MSB-first with deterministic zero tail bits. Do not slice packed non-interlaced source rows.
- **D-03:** Reuse selected-depth `_png_adam7_passes` and the existing low-bit profile/machine. All packed pass scanline, frame, work, output and budget facts are checked before the sole budget charge or output.
- **D-04:** Phase 83 owns eager wire/preflight evidence; Phase 84 owns hostile caller-buffered lifecycle qualification.
- **D-05:** Preserve PLTE/tRNS and depth palette caps; independently validate seven-pass packed raw raster, chunk framing/CRC and public decode.

### the agent's Discretion

- Factor only a geometry/packing helper when it eliminates duplicated checked arithmetic without making a second encoder or staging buffer.

### Deferred Ideas (OUT OF SCOPE)

Caller-buffered hostile qualification is Phase 84. Generic model widening, filters/compression strategies, quantization, palette generation, staging, a second encoder, FFI, wrappers, copied trees and release automation remain excluded.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models remain MoonBit-native; native stubs, if ever necessary, must be small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Public package dependencies must be acyclic and explicit; public stability follows SemVer once stable. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and GUI-free; performance claims need reproducible workloads. [VERIFIED: AGENTS.md]
- This project requires code discovery through the codebase-memory graph first, with text search only when the graph is insufficient. The PNG graph had no scoped indexed nodes for this checkout, so the inspected code seams below use targeted `rg`/source reads. [VERIFIED: AGENTS.md and codebase-memory query]
- No project-local skills were found. [VERIFIED: AGENTS.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INDEXLOWADAM7-01 | Add explicit Type-3/1, /2, /4 Adam7 eager and chunk selectors while legacy output stays non-interlaced. | Add the two selector companions as thin forwards to the existing profile constructor; legacy wrappers pass `None`. [VERIFIED: `encode.mbt`, `stream_encode.mbt`, `REQUIREMENTS.md`] |
| INDEXLOWADAM7-02 | Derive packed pass rows and emit MSB-first, zero-tailed local rows. | Reuse `_png_adam7_passes(..., 1UL, depth)` for preflight and the sole scalar byte provider. [VERIFIED: `structural.mbt`, `stream_encode.mbt`, `REQUIREMENTS.md`] |
| INDEXLOWADAM7-03 | Preserve Type-3 frame, canonical palette/transparency, framing/CRCs, and public decode. | Extend the existing eager Indexed8 Adam7 test-local parser/oracle pattern for all three selected depths. [VERIFIED: `encode_test.mbt`, `REQUIREMENTS.md`] |
| INDEXLOWADAM7-04 | Admit exactly and atomically before bytes, lease exposure, or budget mutation. | Generalize the existing Indexed8 Adam7 preflight branch and white-box exact/one-less assertions. [VERIFIED: `encode.mbt`, `encode_wbtest.mbt`, `REQUIREMENTS.md`] |
</phase_requirements>

## Summary

Phase 83 is a bounded generalization of the shipped Indexed8 Adam7 route, not a new encoder. The current indexed preflight only admits `PngIndexedWireProfile::Eight` under `Adam7`, and the current `_png_indexed8_adam7_scanline_byte` returns one source code per payload byte. Those two 8-bit-only seams are exactly why selected low-bit Adam7 cannot work today. [VERIFIED: `modules/mb-image/png/encode.mbt:2086-2208`, `modules/mb-image/png/stream_encode.mbt:1016-1123`]

Use the canonical unpacked `PngIndexedImage` as the sole source. For each emitted low-bit pass payload byte, locate its pass row from selected-depth Adam7 geometry, read only its visible pass-local `index_at` coordinates, and OR them into a zero-initialized MSB-first byte. The resulting implementation remains bounded replay calculation inside the existing `PngEncodeMachine`; it does not materialize a pass, packed image, output, or second state machine. [VERIFIED: `structural.mbt:565-603`, `stream_encode.mbt:967-1000`, `83-CONTEXT.md`]

**Primary recommendation:** Add depth-aware indexed Adam7 preflight and scalar packing to the existing machine, expose only additive selected-depth interlace selectors, and prove it using test-local literal seven-pass rasters plus exact atomic-fact tests. [VERIFIED: `83-CONTEXT.md`, `v027-LOWBIT-ADAM7.md`, v0.26 Phase 81 evidence]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Selected-depth API selection | API / Backend | — | Public MoonBit facades map `PngIndexedBitDepth` to the private wire profile and invoke the one machine. [VERIFIED: `encode.mbt:2271-2374`, `stream_encode.mbt:21-74`] |
| Adam7 pass geometry and packed byte arithmetic | API / Backend | — | `_png_adam7_passes` owns the seven pass dimensions and row-byte calculation; the machine owns byte replay. [VERIFIED: `structural.mbt:565-603`, `stream_encode.mbt:1016-1123`] |
| PNG framing, CRC, Stored IDAT, and resource admission | API / Backend | — | `PngFrameFacts` and indexed preflight derive lengths and make the single budget charge before machine construction. [VERIFIED: `encode.mbt:2086-2208`, `stream_encode.mbt:967-1000`] |
| Canonical indices, PLTE, and tRNS | Database / Storage | API / Backend | Immutable `PngIndexedImage` owns source indices/palette/alpha; the machine reads those accessors without a copied model. [VERIFIED: `png.mbt:221-229`, `stream_encode.mbt:1018-1057`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` toolchain | `0.1.20260713` | Compile and run the existing portable PNG package suite. [VERIFIED: local `moon --version`] | Already pinned by project policy and used by all relevant archived phases. [VERIFIED: `AGENTS.md`, v0.26 plans] |
| Existing `mb-image/png` package | repository source | Supplies the only acknowledged PNG encoder, checked arithmetic, PNG framing, and public decode. [VERIFIED: inspected PNG source] | Phase constraints forbid a second encoder or external wrapper. [VERIFIED: `83-CONTEXT.md`] |

### Supporting

No additional package is required or recommended. [VERIFIED: `83-CONTEXT.md`, `REQUIREMENTS.md`]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pass-local scalar repacking in `PngEncodeMachine` | Slice an imagined packed full-image row | Rejected: an Adam7 pass restarts at its own local column zero, so full-row boundaries do not encode its bit alignment. [VERIFIED: `83-CONTEXT.md`, `v027-LOWBIT-ADAM7.md`] |
| Existing single machine | Separate low-bit Adam7 encoder/staging buffer | Rejected by locked scope and would duplicate framing, CRC, acknowledgement, and budget behavior. [VERIFIED: `83-CONTEXT.md`, `REQUIREMENTS.md`] |

**Installation:** None. [VERIFIED: `83-CONTEXT.md`]

## Package Legitimacy Audit

Not applicable: Phase 83 installs no external package. [VERIFIED: `83-CONTEXT.md`]

## Architecture Patterns

### System Architecture Diagram

```text
PngIndexedImage + selected PngIndexedBitDepth + Adam7
                    |
                    v
public eager/chunk selector --maps once--> PngIndexedWireProfile
                    |                         |
                    |                         v
                    +--> PngEncodeMachine::new_with_indexed_profile
                                      |
                         checked preflight: dimensions, palette cap,
                         selected-depth Adam7 pass totals, frame/limits
                                      |
                              one budget.charge
                                      |
                                      v
          PngEncodeMachine::scanline_byte(index) --selected-depth geometry-->
          filter tag or one pass-local packed byte --> Stored IDAT/CRC/frame
                                      |
                                      v
                         eager writer / minimal chunk selector
```

The only branch added is indexed-source plus explicit `Adam7`; non-indexed paths and the legacy `None` routes retain their existing paths. [VERIFIED: `stream_encode.mbt:1085-1130`, `83-CONTEXT.md`]

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode.mbt              # eager selector and indexed preflight
├── stream_encode.mbt       # chunk selector and sole machine byte provider
├── encode_test.mbt         # eager frame/raster/CRC/public-decode/legacy tests
├── encode_wbtest.mbt       # private pass/frame/work/budget facts
└── stream_encode_test.mbt  # one sufficient-lease selector smoke test only
```

This is the same source/test split used by archived Phases 79 and 81. [VERIFIED: v0.25 Phase 79 plan, v0.26 Phase 81 plan, current PNG files]

### Pattern 1: One profile mapper, explicit legacy forwards

**What:** Extract the repeated `PngIndexedBitDepth -> PngIndexedWireProfile::{One,Two,Four}` match into one private helper (or retain a single equivalent mapping used by both selectors), add `encode_indexed_with_interlace_strategy` and `new_indexed_with_interlace_strategy`, and make existing low-bit public APIs invoke them with `PngInterlaceStrategy::None`. [VERIFIED: `encode.mbt:2328-2374`, `stream_encode.mbt:52-74`, `83-CONTEXT.md`]

**When to use:** Only for selected low-bit indexed routes; do not alter the existing Indexed8 selector family. [VERIFIED: `83-CONTEXT.md`]

```moonbit
// Source pattern: encode.mbt Indexed8 legacy forward [VERIFIED: codebase]
pub fn PngEncoder::encode_indexed(...) -> Result[...] {
  PngEncoder::encode_indexed_with_interlace_strategy(
    self, source, bit_depth, PngInterlaceStrategy::None,
    writer, limits, budget, diagnostics,
  )
}
```

### Pattern 2: Shared geometry, pass-local packing

**What:** In preflight and byte replay, call `_png_adam7_passes(width, height, 1UL, depth)`. For the located pass row, `in_row == 0` emits filter `00`; otherwise `payload_byte = in_row - 1`, then packs `slots = 8 / depth` pass columns beginning at `payload_byte * slots`. [VERIFIED: `structural.mbt:588-603`, `stream_encode.mbt:1018-1062`, `83-CONTEXT.md`]

**When to use:** Only when indexed source and requested interlace are `Adam7`; retain the current non-interlaced low-bit branch unchanged. [VERIFIED: `stream_encode.mbt:1089-1123`, `83-CONTEXT.md`]

```moonbit
// Source pattern: existing Indexed8 Adam7 cursor and non-interlaced low-bit packer.
let passes = _png_adam7_passes(width, height, 1UL, depth).unwrap()
// locate selected pass / relative row exactly as the existing Indexed8 helper does
if in_row == 0UL { return Ok(b'\x00') }
let mut packed = 0UL
for slot = 0UL; slot < 8UL / depth; slot = slot + 1UL {
  let pass_column = payload_byte * (8UL / depth) + slot
  if pass_column < pass.width {
    let x = pass.x + pass_column * pass.dx
    let y = pass.y + pass_row * pass.dy
    packed = packed | (source.index_at(x, y).unwrap().to_uint64() <<
      (8UL - depth - slot * depth).to_int())
  }
}
Ok(packed.to_byte()) // untouched low bits remain zero
```

### Anti-Patterns to Avoid

- **Keep the `Eight`-only preflight arm:** it rejects every requested selected-depth Adam7 selector before construction. Generalize only this arm with `wire_profile.depth()`. [VERIFIED: `encode.mbt:2123-2154`]
- **Reuse `_png_indexed8_adam7_scanline_byte` unchanged:** it reads a source code per output byte rather than a packed payload byte. [VERIFIED: `stream_encode.mbt:1016-1062`]
- **Use global `x` or full-image packed `row_bytes`:** it shifts bits incorrectly whenever a pass begins at `x != 0` or has a different row width. [VERIFIED: `83-CONTEXT.md`, `v027-LOWBIT-ADAM7.md`]
- **Move hostile lease qualification into this phase:** zero/one/ragged schedules and sticky terminal assertions belong to Phase 84; Phase 83 has only a minimal chunk-selector construction smoke test. [VERIFIED: `83-CONTEXT.md`, `ROADMAP.md`]

## Packed Pass Arithmetic and Atomic Admission

For every nonempty pass, compute `pass_scanline_width = checked_add(pass.row_bytes, 1)` and `pass_bytes = checked_mul(pass_scanline_width, pass.height)`, then checked-add it into `scanlines`. `pass.row_bytes` must come from `_png_adam7_passes(width, height, 1UL, depth)`, whose source-row formula already performs checked `ceil(pass_width * depth / 8)` for one-channel depths below eight. [VERIFIED: `structural.mbt:548-603`, `encode.mbt:2123-2155`]

For the existing 5x5 all-seven-pass shape, the independent raw raster totals are 22 bytes at depth 1, 24 bytes at depth 2, and 27 bytes at depth 4. Each has one Stored block; IDAT payload lengths are respectively 33, 35, and 38 bytes (`raw + 11`). With full-cap palettes and transparency through the final entry, `PngFrameFacts.total_length` and selected work are respectively 122, 132, and 183 bytes. These are useful white-box expected facts, not values derived by a production helper in the test. [VERIFIED: Adam7 tuples in `structural.mbt:595-600`; Stored formula in `encode.mbt:2070-2082`; frame formula call in `encode.mbt:2168-2208`]

Admission order is non-negotiable: validate u32 width/height and pixel multiplication; validate actual PLTE entry count against selected cap; construct selected-depth pass totals; derive Stored IDAT and `PngFrameFacts`; enforce width/height/pixels/output/work limits; then call `budget.charge` once and construct the machine. The current Indexed8 branch already has this ordering, so preserve it while replacing only its profile restriction. [VERIFIED: `encode.mbt:2093-2208`, v0.26 Phase 81 verification]

## Test Fixture and Oracle Plan

1. In `encode_test.mbt`, add one deliberately non-symmetric 5x5 canonical source per depth, with valid codes in `[0, 2^depth)`, actual palette length at the selected cap, and a final non-opaque alpha entry. Hand-author one literal seven-pass raw raster per depth. Each literal must contain all per-row `00` filter tags, MSB-first payload bytes, and zero tail bits; it must not call `_png_adam7_passes`, a production packer, row-byte helper, or preflight helper. [VERIFIED: v0.26 Phase 81 literal-oracle pattern in `encode_test.mbt:1083-1139`; `83-CONTEXT.md`]
2. Parse eager bytes independently: assert IHDR `bit_depth/type/compression/filter/interlace = depth/3/0/0/1`, ordered `IHDR -> PLTE -> optional tRNS -> IDAT -> IEND`, actual PLTE bytes, shortest tRNS, IDAT Stored payload, and every chunk CRC. Publicly decode transparent bytes as palette-exact RGBA8 and opaque bytes as RGB8, checking every coordinate. [VERIFIED: `encode_test.mbt:1103-1185`, `83-CONTEXT.md`]
3. In `encode_wbtest.mbt`, for all three profiles assert the selected-depth all-seven-pass `scanlines`, block count, IDAT, `frame.total_length`, `selected_work`, exact budget exhaustion, and unchanged budget on one-less output/work, selected-cap-plus-one palette, and checked-arithmetic failure. The existing test covers non-interlaced low-bit facts and the existing Indexed8 test supplies the Adam7 exact-fact shape; combine their evidence rather than create another preflight implementation. [VERIFIED: `encode_wbtest.mbt:1142-1225`]
4. In `stream_encode_test.mbt`, add only a sufficient-capacity smoke test proving `new_indexed_with_interlace_strategy(..., Adam7, ...)` reaches the same machine and emits Type-3 selected-depth Adam7 IHDR. Do not add hostile drain, lease-tail, released-lease, or collected-stream parser tests here; those are Phase 84 obligations. [VERIFIED: `stream_encode_test.mbt:5049-5069`, `83-CONTEXT.md`]
5. Keep and execute the literal non-interlaced Indexed2 test and Indexed1/Indexed4 MSB-first zero-tail test unchanged; they are the frozen low-bit compatibility baseline. Keep the v0.26 Indexed8 Adam7 vector unchanged as the cross-profile interlace baseline. [VERIFIED: `encode_test.mbt:957-999`, `encode_test.mbt:1103-1206`, v0.25/v0.26 archived requirements]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Adam7 coordinate tables / rounded pass dimensions | A second seven-pass formula | `_png_adam7_passes` | It is the repository's shared geometry authority for structural processing. [VERIFIED: `structural.mbt:565-603`] |
| PNG output/framing/CRC machine | A low-bit Adam7 emitter or byte buffer | `PngEncodeMachine::new_with_indexed_profile` | It already owns pending-byte acknowledgement, Stored framing, CRC, Adler, and output length lifecycle. [VERIFIED: `stream_encode.mbt:967-1000`, `83-CONTEXT.md`] |
| Resource arithmetic | Unsafely calculated pass/frame totals | `@checked.checked_add` / `checked_mul` plus existing frame/Stored helpers | Existing indexed preflight relies on checked calculations and charges only after all limits pass. [VERIFIED: `encode.mbt:2070-2208`] |
| Wire oracle | Test calls into production geometry/packer | Literal test-local raw raster + existing parser/CRC/Stored extraction helpers | Shared production bugs must not become their own evidence. [VERIFIED: `encode_test.mbt:1095-1139`, `83-CONTEXT.md`] |

**Key insight:** selected-depth Adam7 differs from non-interlaced low-bit output at the raster traversal boundary only; retaining existing frame and machine authority minimizes compatibility risk. [VERIFIED: `83-CONTEXT.md`, current Indexed8 Adam7 implementation]

## Common Pitfalls

### Pitfall 1: Pass geometry accidentally remains 8-bit

**What goes wrong:** raw length, IDAT length, frame/work limits, and byte cursor disagree for low-bit output. [VERIFIED: `encode.mbt:2128-2154`, `stream_encode.mbt:1018-1062`]

**How to avoid:** pass `wire_profile.depth()` to `_png_adam7_passes` in both preflight and the helper; do not hard-code `8`. [VERIFIED: `83-CONTEXT.md`]

### Pitfall 2: Packing begins at the full-image x coordinate

**What goes wrong:** valid source codes occupy incorrect slots because an Adam7 pass row is an independent reduced row. [VERIFIED: `83-CONTEXT.md`, `v027-LOWBIT-ADAM7.md`]

**How to avoid:** calculate `pass_column` from payload byte and local slot, then map it to source `x`; initialize every output byte to zero. [VERIFIED: `83-CONTEXT.md`]

### Pitfall 3: Late resource failure changes observable state

**What goes wrong:** writer progress, a chunk instance, or budget remaining state becomes observable on a rejected request. [VERIFIED: `REQUIREMENTS.md`, `83-CONTEXT.md`]

**How to avoid:** retain one preflight through all checked facts and limits before the sole `budget.charge`; test writer position and budget state for every rejection. [VERIFIED: `encode.mbt:2188-2208`, `encode_test.mbt:1187-1205`]

### Pitfall 4: Phase 84 evidence leaks into Phase 83

**What goes wrong:** implementation and lifecycle qualification become entangled, enlarging scope and obscuring the machine contract. [VERIFIED: `ROADMAP.md`, `83-CONTEXT.md`]

**How to avoid:** Phase 83 proves eager wire/preflight and a factory smoke test only; reserve hostile lease and chunk-origin proof for Phase 84. [VERIFIED: `83-CONTEXT.md`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed-8 Indexed Adam7 only | Selected-depth Type-3 Adam7 through the same machine | Phase 83 planned | Generalize profile depth at the geometry/packing seam while freezing existing routes. [VERIFIED: `encode.mbt:2128-2154`, `83-CONTEXT.md`] |

**Deprecated/outdated:** Treating `_png_indexed8_adam7_scanline_byte` as a general indexed Adam7 implementation is incorrect for depths 1/2/4 because its payload unit is an entire source index. [VERIFIED: `stream_encode.mbt:1016-1062`]

## Assumptions Log

All implementation recommendations are grounded in the current repository, phase context, archived plans, and completed v0.26 verification; no unverified external package or format claim is required. [VERIFIED: inspected sources]

## Open Questions

1. **Exact literals for the three selected-depth 5x5 fixtures.**
   - What we know: the fixture shape yields all seven passes and exact raw/frame facts for full-cap transparent palettes. [VERIFIED: `structural.mbt:595-603`, checked arithmetic above]
   - What's unclear: the final hand-authored source/palette literals are an implementation-time test-data choice.
   - Recommendation: make each source non-symmetric, force a final partial packed byte, and write literal expected raw bytes before implementation; do not calculate them via production helpers. [VERIFIED: `83-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| MoonBit `moon` | PNG package compile/test | ✓ | `0.1.20260713` | — [VERIFIED: local `moon --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probe]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Portable codec library exposes no authentication surface in this phase. [VERIFIED: `REQUIREMENTS.md`] |
| V3 Session Management | no | Portable codec library exposes no session surface in this phase. [VERIFIED: `REQUIREMENTS.md`] |
| V4 Access Control | no | No authorization decision is introduced. [VERIFIED: `REQUIREMENTS.md`] |
| V5 Input Validation | yes | Checked dimensions/arithmetic, palette-cap validation, resource limits, and atomic budget charge. [VERIFIED: `encode.mbt:2093-2208`] |
| V6 Cryptography | no | CRC/Adler are PNG integrity framing, not security cryptography; no cryptographic control is introduced. [VERIFIED: current PNG framing code and phase scope] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Integer overflow in pass/frame sizes | Tampering / denial of service | Use checked multiplication/addition at every rounded row, pass sum, Stored, and frame step before charge. [VERIFIED: `encode.mbt:2070-2208`] |
| Excess palette entries for selected depth | Tampering / denial of service | Reject actual `palette_length / 3` above 2/4/16 before frame work and charge. [VERIFIED: `encode.mbt:2107-2110`] |
| Partial externally visible state after rejection | Denial of service / integrity | All selected facts and limits complete before one budget charge and machine construction. [VERIFIED: `encode.mbt:2188-2208`] |

## Sources

### Primary (HIGH confidence)

- `83-CONTEXT.md`, `REQUIREMENTS.md`, and `ROADMAP.md` — locked scope, Phase 83/84 ownership, and requirement boundaries. [VERIFIED: repository planning artifacts]
- `modules/mb-image/png/structural.mbt` — shared Adam7 geometry and checked packed row-byte calculation. [VERIFIED: codebase source]
- `modules/mb-image/png/encode.mbt` and `stream_encode.mbt` — current Indexed8-only preflight/emission seam, one-machine construction, public wrapper patterns. [VERIFIED: codebase source]
- `modules/mb-image/png/encode_test.mbt`, `encode_wbtest.mbt`, and `stream_encode_test.mbt` — literal wire oracle, exact preflight, legacy freeze, and minimal selector-test patterns. [VERIFIED: codebase source]
- v0.25 Phase 79/80 and v0.26 Phase 81/82 archived plans and Phase 81 verification — completed low-bit and Indexed8 Adam7 contracts. [VERIFIED: repository archive]

### Secondary (MEDIUM confidence)

- `.planning/research/v027-LOWBIT-ADAM7.md` — prior scoped synthesis, corroborated against current code. [VERIFIED: repository research]

### Tertiary (LOW confidence)

- None. [VERIFIED: research inventory]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new package; the local MoonBit version and project policy were inspected. [VERIFIED: local probe, `AGENTS.md`]
- Architecture: HIGH — the precise fixed-8 seams and the sole machine are present in current source. [VERIFIED: `encode.mbt`, `stream_encode.mbt`]
- Pitfalls: HIGH — each is directly implied by current fixed-8 code or locked phase constraints. [VERIFIED: current source, `83-CONTEXT.md`]

**Research date:** 2026-07-24  
**Valid until:** Implementation starts or the PNG source/Phase 83 context changes.
