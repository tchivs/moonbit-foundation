# Phase 67: Resumable RGBA16 PNG Preservation - Research

**Researched:** 2026-07-23
**Domain:** Public caller-owned PNG chunk decoding over the established Type-6/16 preservation machine
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add only `PngChunkDecoder::new_rgba16` and construct the existing byte-fed machine with `PngDecodeProfile::Rgba16`; eager `decode_rgba16` stays the identity oracle.
- **D-02:** Preserve the established chunk lifecycle exactly: empty, one-byte, and ragged input schedules count only accepted bytes; the only image is obtained from successful `finish()`; no caller source view or partial image is retained or exposed.
- **D-03:** Preserve sticky typed terminal errors for malformed, truncated, profile-invalid and resource-limited input, including later pushes and repeated `finish()` calls.
- **D-04:** Chunk Rgba16 uses the same strict default/sRGB Type-6/16 admission, exact normal/Adam7 final store, eight-byte output accounting, and no-staging guarantee as Phase 66; generic chunk Type-6/16 remains frozen on RGBA8 high bytes.
- **D-05:** Do not add new profiles, alternate parser/raster state, source-tree copying, release automation, or broad independent qualification fixtures.  Phase 68 owns the adversarial and portable qualification matrix.

### the agent's Discretion

- Use the closest `new_graya16` constructor and chunk test harness, adding only Rgba16-specific parity and terminal evidence.

### Deferred Ideas (OUT OF SCOPE)

- Independent all-filter/all-Adam7 wire literals, hostile resource matrix, full portable qualification, copied source workflows and release automation — Phase 68 or out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| RGBA16DEC-03 | Select chunk RGBA16 decode with eager-equivalent output, accepted-only progress, atomic failure, and sticky terminals. | Reuse the `GrayAlpha16` chunk-constructor seam, the shared `Rgba16` profile machine, and the existing explicit chunk schedule/terminal harness. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 67 is an additive public-selection change, not a raster or parser change. `PngDecodeProfile::Rgba16`, its strict Type-6/16 default/sRGB gate, eight-byte output layout, and normal/Adam7 lossless stores already exist from Phase 66; `PngChunkDecoder` already delegates all pushes and `finish()` to one private `PngDecodeMachine`. [VERIFIED: modules/mb-image/png/stream_decode.mbt, modules/mb-image/png/png.mbt]

Add `PngChunkDecoder::new_rgba16` beside `new_graya16`, differing only by the profile supplied to `PngDecodeMachine::new_with_profile`. Extend the explicit-profile test harness by adapting the existing GrayAlpha16 eager/chunk schedule and sticky-terminal tests to the Phase 66 RGBA16 literals. This proves selector parity without duplicating decoding logic or expanding Phase 68 qualification scope. [VERIFIED: modules/mb-image/png/png.mbt, modules/mb-image/png/stream_decode_test.mbt, modules/mb-image/png/png_test.mbt]

**Primary recommendation:** Implement one constructor in `png.mbt`; add focused RGBA16 public schedule and terminal regressions in `stream_decode_test.mbt`; leave `stream_decode.mbt`, `raster_decode.mbt`, and eager APIs unchanged unless compilation proves a narrow shared-constructor need. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Public RGBA16 chunk selection | API / Backend | — | `PngChunkDecoder` owns the public limits, state facade, and construction of the private machine. [VERIFIED: modules/mb-image/png/png.mbt] |
| Input progression and sticky terminals | API / Backend | Decoder machine | `push` and `finish` retain facade state while forwarding byte acceptance and first-error identity through the existing machine. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Type-6/16 admission, resource preflight, and exact pixels | Decoder machine | Storage | The existing `Rgba16` profile performs first-IDAT admission and routes owned output through the existing raster sink. [VERIFIED: modules/mb-image/png/stream_decode.mbt, modules/mb-image/png/raster_decode.mbt] |

## Project Constraints (from AGENTS.md)

- Prefer the project codebase knowledge graph for code discovery; graph tools were not available in this agent runtime, so bounded `rg`/direct-source inspection was used as the documented fallback. [VERIFIED: AGENTS.md]
- Core algorithms and shared data models remain MoonBit; preserve native-first portability boundaries, narrow FFI, acyclic public dependencies, deterministic GUI-free operations, reproducible evidence, and RFC governance. [VERIFIED: AGENTS.md]
- Public-package black-box tests use `*_test.mbt`; internal invariants use `*_wbtest.mbt`; public documentation examples are testable and binary expectations require semantic byte assertions rather than opaque snapshots. [VERIFIED: AGENTS.md]
- Planning artifacts are being produced through the GSD phase workflow; no source edit is authorized by this research task. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `mb-image/png` chunk facade and `PngDecodeMachine` | repository current | Own framing, accepted-byte accounting, preflight, raster lifecycle, and terminal transfer. | It is the single established bounded machine; selecting its existing `Rgba16` profile satisfies scope without another parser. [VERIFIED: modules/mb-image/png/png.mbt, modules/mb-image/png/stream_decode.mbt] |
| MoonBit toolchain | `moon 0.1.20260713` | Compile and run PNG package tests. | Installed locally and matches the project stack pin. [VERIFIED: `moon --version`, AGENTS.md] |

### Supporting

| Component | Purpose | When to Use |
|---|---|---|
| Phase 66 RGBA16 literals and eager selector | Independent eager identity oracle for byte-for-byte result comparison. | Reuse the declaration-free normal and sRGB Adam7 literals already checked by eager tests. [VERIFIED: modules/mb-image/png/png_test.mbt] |
| Existing GrayAlpha16 chunk harness | Explicit-profile schedules, component-byte comparator, and sticky terminal replay shape. | Copy its structure only, substituting RGBA16 constructor, eager oracle, and four-channel component observations. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt] |

**Installation:** None — this phase adds no external package. [VERIFIED: 67-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
caller-owned ByteView (empty / one-byte / ragged)
                |
                v
PngChunkDecoder::new_rgba16
  -> Active(PngDecodeMachine(profile=Rgba16))
                |
       push() accepts each admissible byte
                v
existing framing -> first-IDAT Rgba16 preflight -> existing raster sink
                |                                      |
                | profile-invalid/resource error        | private owned image
                v                                      v
       Failed(first typed error)              IEND pending -> finish()
                |                                      |
       later push/finish replay               v
                                      transfer sole DecodeResult; state=Finished
```

The facade stores no `ByteView`; it copies/consumes byte transitions synchronously, while the private image remains unavailable until `finish()` succeeds. [VERIFIED: modules/mb-image/png/png.mbt, modules/mb-image/png/stream_decode.mbt]

### Recommended Project Structure

```text
modules/mb-image/png/
├── png.mbt                 # add new_rgba16 constructor only
├── stream_decode.mbt       # unchanged shared lifecycle/parser/profile machine
├── stream_decode_test.mbt  # RGBA16 public schedules, parity, and terminals
└── stream_decode_wbtest.mbt # unchanged unless a narrow lifecycle assertion is needed
```

### Pattern 1: Profile-selecting facade constructor

**What:** Construct the identical public facade record but initialize `Active` with `PngDecodeMachine::new_with_profile(PngDecodeProfile::Rgba16, ...)`. [VERIFIED: modules/mb-image/png/png.mbt]

**When to use:** Only for the new opt-in Type-6/16 selector; generic `new` must retain `PngDecodeMachine::new`. [VERIFIED: 67-CONTEXT.md, modules/mb-image/png/png.mbt]

```moonbit
// Pattern source: PngChunkDecoder::new_graya16 in png.mbt
pub fn PngChunkDecoder::new_rgba16(limits, budget, diagnostics) -> PngChunkDecoder {
  {
    limits,
    _diagnostics: diagnostics,
    state: PngChunkDecoderState::Active(PngDecodeMachine::new_with_profile(
      PngDecodeProfile::Rgba16,
      @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
      limits,
      budget,
    )),
    consumed_total: 0UL,
  }
}
```

### Pattern 2: Fresh-source schedule parity

**What:** Begin with an empty owned source, then feed independently owned one-byte or ragged slices; require every successful `push` to consume the exact requested length and compare successful `finish()` with a freshly initialized eager `decode_rgba16` result. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt]

**When to use:** Run against Phase 66 declaration-free normal and sRGB Adam7 literal streams, asserting every U16 component byte across all four channels. [VERIFIED: modules/mb-image/png/png_test.mbt, modules/mb-image/png/stream_decode_test.mbt]

### Anti-Patterns to Avoid

- **A second PNG decoder or raster path:** It would split admission, resource, and terminal semantics from the proven machine. Use profile selection only. [VERIFIED: 67-CONTEXT.md]
- **A result in `push`:** It weakens the existing explicit-EOF contract and exposes an image before terminal framing. Keep transfer solely in successful `finish()`. [VERIFIED: modules/mb-image/png/png.mbt, modules/mb-image/png/stream_decode.mbt]
- **Retaining a caller source view:** It violates the ownership boundary; schedule tests must mutate/release a prior owner and complete from a fresh suffix. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt]
- **Changing generic `new`:** It would risk widening frozen Type-6/16 generic behavior away from RGBA8 high bytes. [VERIFIED: 67-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Chunk parsing and EOF classification | A second resumable PNG parser | Existing `PngDecodeMachine` plus `PngChunkDecoder::push/finish` | It already defines accepted-byte accounting, CRC/framing progression, incomplete classification, and sticky terminals. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Exact RGBA16 reconstruction | A new row or Adam7 implementation | Existing `PngDecodeProfile::Rgba16` raster path | Phase 66 already writes normal and Adam7 lanes to packed little-endian RGBA16 storage. [VERIFIED: 66-VERIFICATION.md] |
| Profile/resource test oracle | New generated vectors or broad hostile matrix | Phase 66 literals plus current explicit chunk harness | It proves this selector's parity while preserving Phase 68's qualification scope. [VERIFIED: 67-CONTEXT.md, modules/mb-image/png/stream_decode_test.mbt] |

**Key insight:** The only Phase 67 behavior not already present is public selection of an existing private profile; all decoding semantics must remain delegated. [VERIFIED: 67-CONTEXT.md, modules/mb-image/png/png.mbt]

## Common Pitfalls

### Pitfall 1: Selecting the generic machine

**What goes wrong:** `new_rgba16` calls `PngDecodeMachine::new`, silently returning frozen RGBA8 high-byte projection instead of RGBA16. [VERIFIED: modules/mb-image/png/png.mbt, 67-CONTEXT.md]

**How to avoid:** The constructor must call `new_with_profile(PngDecodeProfile::Rgba16, ...)`; schedule comparisons must inspect all four channels and both component bytes. [VERIFIED: modules/mb-image/png/png.mbt, modules/mb-image/png/stream_decode_test.mbt]

### Pitfall 2: Parity test that observes only generic bytes

**What goes wrong:** Comparing `get_byte` or only high bytes cannot detect low-byte loss or little-endian reversal. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt, 66-VERIFICATION.md]

**How to avoid:** Adapt the explicit component-byte comparator and traverse `channel=0..3`, `byte_index=0..1` for both normal and Adam7 results. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt]

### Pitfall 3: Changing terminal accounting

**What goes wrong:** Counting a refused input-limit byte, accepting input after the first error, or returning an image before `finish()` breaks the published facade contract. [VERIFIED: modules/mb-image/png/stream_decode.mbt, modules/mb-image/png/stream_decode_test.mbt]

**How to avoid:** Do not modify `push` or `finish`; assert profile-invalid, malformed, truncated, and input/resource terminal replays through later `push` and repeated `finish()`. [VERIFIED: 67-CONTEXT.md, modules/mb-image/png/stream_decode_test.mbt]

### Pitfall 4: Re-opening Phase 66 admission/resource work

**What goes wrong:** Editing preflight or raster storage risks error-precedence or eight-byte-layout regressions already verified in Phase 66. [VERIFIED: 66-01-SUMMARY.md, 66-VERIFICATION.md]

**How to avoid:** Verify chunk access exercises the existing `Rgba16` profile-invalid `rgba16-profile` error and resource terminal; do not change its admission or allocation implementation. [VERIFIED: modules/mb-image/png/stream_decode.mbt, modules/mb-image/png/stream_decode_wbtest.mbt]

## Code Examples

### Public parity test shape

```moonbit
// Sources: png_test_rgba16_literal / png_test_rgba16_adam7_literal,
//          png_graya16_chunk_schedule_matches_eager
let chunk = PngChunkDecoder::new_rgba16(limits, chunk_budget, diagnostics)
let empty = png_chunk_source(b"")
inspect(chunk.push(empty.view()).consumed() == 0UL, content="true")
// Feed fresh owned one-byte or ragged slices; every successful push consumes its slice.
let scheduled = chunk.finish().unwrap()
let eager = PngDecoder::decode_rgba16(reader, options, limits, eager_budget, eager_diagnostics).unwrap()
// Compare descriptor/metadata and get_component_byte(x, y, channel, byte_index)
// for channel 0..3 and byte_index 0..1.
```

This test shape keeps eager decode as the oracle, proves empty/one-byte/ragged lifecycle parity, and rejects an accidental generic RGBA8 route. [VERIFIED: modules/mb-image/png/png_test.mbt, modules/mb-image/png/stream_decode_test.mbt]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Generic chunk decode of Type-6/16 | Opt-in `Rgba16` profile exists privately but has no chunk constructor | Phase 67 exposes only this profile through the established facade; generic remains RGBA8. [VERIFIED: 66-VERIFICATION.md, modules/mb-image/png/png.mbt] |

**Deprecated/outdated:** None for this phase; no package or framework replacement is involved. [VERIFIED: 67-CONTEXT.md]

## Assumptions Log

All implementation recommendations are grounded in current project source and locked Phase 67/66 artifacts; no `[ASSUMED]` claims are used.

## Open Questions

None. The constructor profile, eager oracle, schedule classes, lifecycle, error behavior, and scope fence are locked by Phase 67 context. [VERIFIED: 67-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Focused and package PNG test runs | Yes | `0.1.20260713` | — [VERIFIED: `moon --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: `moon --version`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V5 Input Validation | Yes | Reuse byte-by-byte framing, PNG profile admission before allocation, configured limits, and typed first-error retention. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| V2 Authentication / V3 Session / V4 Access Control / V6 Cryptography | No | This local deterministic decoder accepts caller-supplied bytes and introduces no identity, session, authorization, or cryptographic protocol surface. [VERIFIED: 67-CONTEXT.md] |

### Known Threat Patterns for the PNG chunk facade

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed or truncated chunk stream | Tampering / Denial of service | Existing parser/classifier returns typed terminal errors and replays the first error without consuming later input. [VERIFIED: modules/mb-image/png/stream_decode.mbt] |
| Excess input or output/resource claim | Denial of service | Existing input limit and Rgba16 preflight enforce limits before dispatch/allocation; Phase 67 must preserve them. [VERIFIED: modules/mb-image/png/stream_decode.mbt, modules/mb-image/png/stream_decode_wbtest.mbt] |
| Caller mutates previous buffer | Tampering | Existing no-`ByteView` retention pattern requires synchronous consumption and fresh-owner suffix proof. [VERIFIED: modules/mb-image/png/stream_decode.mbt, modules/mb-image/png/stream_decode_test.mbt] |

## Sources

### Primary (HIGH confidence)

- `67-CONTEXT.md` — locked phase boundary, lifecycle, compatibility, and scope decisions. [VERIFIED: .planning/phases/67-resumable-rgba16-png-preservation/67-CONTEXT.md]
- Phase 66 summary and verification — established eager profile, exact stores, strict gate, and resource evidence. [VERIFIED: .planning/phases/66-explicit-rgba16-png-preservation/66-01-SUMMARY.md, .planning/phases/66-explicit-rgba16-png-preservation/66-VERIFICATION.md]
- `png.mbt`, `stream_decode.mbt`, `stream_decode_test.mbt`, and `stream_decode_wbtest.mbt` — live constructor, lifecycle, and test seams. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Documentation lookup was planned through the research seam but Context7/`ctx7` was unavailable; no external PNG-spec claim is needed because this phase changes only public selection of an already-tested internal profile. [CITED: local research-plan seam]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new package or external integration; the live code exposes the exact profile and closest constructor. [VERIFIED: codebase grep]
- Architecture: HIGH — selector-to-shared-machine data flow is directly inspectable. [VERIFIED: modules/mb-image/png/png.mbt, modules/mb-image/png/stream_decode.mbt]
- Pitfalls: HIGH — each maps to an existing public test seam or a Phase 66 verified invariant. [VERIFIED: modules/mb-image/png/stream_decode_test.mbt, 66-VERIFICATION.md]

**Research date:** 2026-07-23
**Valid until:** implementation of Phase 67 changes the referenced decoder seams.
