# Phase 55: Portable Public Evidence - Research

**Researched:** 2026-07-23  
**Domain:** MoonBit public PNG compatibility evidence for packed U16 Gray+Alpha  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public compatibility vectors
- **D-01:** Use compact public package tests with non-symmetric legal U16 GrayAlpha samples and literal expected `Ghi,Glo,Ahi,Alo` PNG wire bytes. Assert public decoder canonicalizes them to straight RGBA8 high bytes.
- **D-02:** Keep all evidence at public `PngEncoder`, `PngChunkEncoder`, and decoder seams; do not test private profiles or add test-only encoder paths.

### Caller-buffered and legacy proof
- **D-03:** Run every existing compression/filter pair under zero-capacity, one-byte, and deterministic ragged schedules, asserting eager byte identity, accepted-only progress, untouched tails, and sticky terminals.
- **D-04:** Freeze existing Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 literal eager/chunk vectors. Any byte change is a regression, not a rebaseline.

### Portability boundary
- **D-05:** Run the same public PNG suite with `--target all`; tests remain portable MoonBit without native branches, FFI, release work, source copies, or new codec architecture.
- **D-06:** Big-endian GrayAlpha16 descriptors remain invalid under the Phase 53 model contract; public evidence uses legal little-endian sources and retains strict descriptor-boundary rejection coverage rather than claiming unsupported backing parity.

### the agent's Discretion
- Reuse the closest v0.15 Gray16 and v0.16 GrayAlpha8 public-evidence helpers and choose the smallest readable literal vectors.

### Deferred Ideas (OUT OF SCOPE)

- GrayAlpha16 Adam7, Big-endian GrayAlpha16 descriptor support, colour conversion, palette/low-bit formats, release automation, and copied-source workflows.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYA16-04 | Generated GrayAlpha16 PNGs prove literal U16 wire fidelity and documented public decode canonicalization to straight RGBA8 high bytes; zero, one-byte, and ragged caller capacities remain eager-byte-identical with accepted-only progress and sticky terminals; frozen Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 vectors retain their bytes and all evidence runs independently on js, wasm, wasm-gc, and native. | Use the current legal 2×1 U16 GrayAlpha fixture, literal Stored/None raster bytes, the existing six-pair public-drain pattern, retained byte-string vectors, and the one portable package command. [VERIFIED: codebase] |
</phase_requirements>

## Summary

Phase 54 already delivered the only production behavior Phase 55 needs: legal packed little-endian GrayAlpha16 images use public eager and caller-buffered factories to emit non-interlaced type-4/depth-16 PNGs in `Ghi,Glo,Ahi,Alo` order. Its verification explicitly defers hostile capacity, frozen public compatibility, and all-target evidence to this phase. [VERIFIED: Phase 54 verification]

The smallest correct phase is test-only and should mirror the two established public-evidence precedents: Phase 49 for U16 scanline/high-byte canonicalization and Phase 52 for type-4 caller-buffered schedules. Modify only `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt`; do not change production code, API surface, target handling, FFI, release artifacts, or fixtures. [VERIFIED: Phase 49 and 52 artifacts; VERIFIED: CONTEXT.md]

**Primary recommendation:** Add one public GrayAlpha16 wire-to-decode test and one all-six-pair hostile chunk test, extend both existing frozen-vector tests with a GrayAlpha8 literal, then qualify with `moon -C modules/mb-image test png --target all --frozen`. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| U16 GrayAlpha wire proof | API / Backend | — | `PngEncoder::new_graya16_with_strategies` owns the public bytes, so the proof belongs at the eager factory seam. [VERIFIED: codebase] |
| RGBA8 decode canonicalization | API / Backend | — | The public PNG decoder owns conversion from type-4/16 samples to its current U8 RGBA result. [VERIFIED: project research; VERIFIED: CONTEXT.md] |
| Caller lease progress and terminal ownership | API / Backend | — | `PngChunkEncoder::pull` reports progress/outcome while each test owns the mutable destination lease and its sentinels. [VERIFIED: codebase] |
| Four-target qualification | Build/Test harness | API / Backend | MoonBit invokes the same PNG package suite across all supported targets; tests must remain portable MoonBit. [VERIFIED: CONTEXT.md] |

## Project Constraints (from AGENTS.md)

- Prefer knowledge-graph tools for code discovery; no graph file or graph MCP tool is available in this runtime, so targeted `rg` inspection was the permitted fallback. [VERIFIED: runtime inventory]
- Keep shared models and algorithms in MoonBit, with portable targets guarded by conformance tests. [VERIFIED: AGENTS.md]
- Public operations must be deterministic and usable without GUI state. [VERIFIED: AGENTS.md]
- Keep native stubs small and isolated; this phase must add none. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]
- Keep public dependencies acyclic and compatibility explicit; this evidence-only phase introduces no dependency or public contract expansion. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]
- Per the project workflow, this research artifact is the only planning-file mutation in scope. [VERIFIED: AGENTS.md; VERIFIED: task scope]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Run the existing PNG package tests. | It is installed in the workspace and is the project toolchain. [VERIFIED: local CLI] |
| Existing `mb-image/png` public APIs | repository HEAD | Construct eager/chunk GrayAlpha16 output and decode it publicly. | The locked phase boundary requires these seams, and Phase 54 already validates their construction. [VERIFIED: CONTEXT.md; VERIFIED: Phase 54 verification] |

### Supporting

No package installation, external service, FFI, fixture generator, or new test framework is required. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Public factory/decoder evidence | Private profile or cursor tests | Rejected: it would bypass the consumer-visible contract required by D-02. [VERIFIED: CONTEXT.md] |
| Existing local public-drain shape | New generic streaming harness | Rejected: it duplicates accepted-progress/lease-tail logic and violates D-03's established strategy. [VERIFIED: codebase; VERIFIED: Phase 49 and 52 artifacts] |
| Literal Stored/None vector | A current encoder-derived expected value or opaque snapshot | Rejected: a current encoder cannot be its own compatibility oracle. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md] |

**Installation:** None — this phase must not install packages. [VERIFIED: CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
legal LE GrayAlpha16 fixture
 (0x1234,0xA7C5), (0xBE0F,0x5A76)
             |
             +--> PngEncoder::new_graya16_with_strategies(Stored, None)
             |          |
             |          +--> PNG type 4/depth 16/non-interlaced
             |                    |
             |                    +--> literal raster: 00 12 34 A7 C5 BE 0F 5A 76
             |                    +--> public decoder: (12,12,12,A7), (BE,BE,BE,5A)
             |
             +--> PngChunkEncoder::new_graya16_with_strategies
                        |
                        +--> fresh zero / one / ragged leases for each strategy pair
                                     |
                                     +--> eager byte identity + accepted-only totals
                                          + unchanged tails + sticky Finished

same PNG package suite --> moon test --target all --> wasm | wasm-gc | js | native
```

The lower source bytes (`34`, `C5`, `0F`, `76`) prove wire preservation but are deliberately not promised by the current RGBA8 decoder boundary. [VERIFIED: Phase 54 verification; VERIFIED: CONTEXT.md]

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # public U16 wire/decode and eager frozen-vector evidence
└── stream_encode_test.mbt   # hostile chunk schedules and chunk frozen-vector evidence
```

No production or new support file is warranted. [VERIFIED: Phase 49 and 52 verification]

### Pattern 1: Literal U16 wire and public decoder are separate assertions

**What:** Build the existing legal 2×1 little-endian `graya16` fixture through checked component writes, encode through `PngEncoder::new_graya16_with_strategies(Stored, None)`, assert signature/IHDR (`depth=0x10`, `type=0x04`, `interlace=0`) plus the filter/raster bytes `00 12 34 A7 C5 BE 0F 5A 76`, then decode only through the public decoder. [VERIFIED: codebase; VERIFIED: Phase 54 verification]

**When to use:** Use exact raster bytes only for Stored/None. The six-pair matrix must instead assert framing, successful public decode canonicalization, and eager/chunk identity because Adaptive filters and compression strategies intentionally alter representation. [VERIFIED: Phase 49 and 52 research]

```moonbit
// Existing fixture lanes are little-endian in storage, PNG is big-endian per U16 component.
// Source: modules/mb-image/png/encode_test.mbt
inspect(
  bytes[48] == b'\x00' && bytes[49] == b'\x12' && bytes[50] == b'\x34' &&
    bytes[51] == b'\xa7' && bytes[52] == b'\xc5' && bytes[53] == b'\xbe' &&
    bytes[54] == b'\x0f' && bytes[55] == b'\x5a' && bytes[56] == b'\x76',
  content="true",
)
```

The new public decoder helper should assert U8 straight-RGBA descriptor/output: `R=G=B=Ghi`, `A=Ahi`; it must not claim a U16 decoded-image or low-byte round trip. [VERIFIED: CONTEXT.md; VERIFIED: project research]

### Pattern 2: Fresh public encoder for every hostile schedule

**What:** Copy the current `png_stream_gray16_public_drain` / `png_stream_graya8_public_drain` structure as `png_stream_graya16_public_drain`; create one fresh `PngChunkEncoder::new_graya16_with_strategies` per schedule and append only the `written` prefix. [VERIFIED: codebase]

**Exact matrix:** For each of `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored` crossed with `None` and `Adaptive`, first inspect a zero-length lease with a `Z` sentinel, then run independent drains with `[0UL, 1UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

```moonbit
// Source: modules/mb-image/png/stream_encode_test.mbt
let before = output.length().to_uint64()
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png graya16 public accepted progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort("png graya16 public lease tail") }
}
```

At `Finished`, assert complete equality with the fresh eager oracle. Then use a new seven-byte `Z` lease to prove `written == 0`, unchanged `total_written`, sticky `Finished`, and zero tail mutation. [VERIFIED: codebase]

### Pattern 3: Literal legacy compatibility remains an independent oracle

**What:** Extend both existing `PNG filter strategy * frozen compatibility vectors` tests with the GrayAlpha8 Stored/None PNG literal, retaining the already literal Gray8, Gray16, RGB8, and straight-RGBA8 vectors. [VERIFIED: codebase; VERIFIED: CONTEXT.md]

**When to use:** Compare each default/configured route that is already frozen to a byte literal; do not generate a new expected PNG at runtime. [VERIFIED: codebase]

### Anti-Patterns to Avoid

- **Testing only IHDR:** It misses lane order; retain all nine Stored/None scanline bytes. [VERIFIED: Phase 54 verification]
- **Using Big-endian GrayAlpha16 backing as a parity corpus:** The model rejects that descriptor before PNG admission; retain descriptor-boundary rejection coverage instead. [VERIFIED: CONTEXT.md; VERIFIED: Phase 54 summary]
- **Reusing an encoder across schedules:** It hides first-pull and initial-progress behavior; create one encoder for each independent schedule. [VERIFIED: Phase 49 and 52 verification]
- **Replacing byte literals:** Treat any difference in Gray8, Gray16, GrayAlpha8, RGB8, or RGBA8 frozen data as a regression. [VERIFIED: CONTEXT.md]
- **Adding production behavior to make a test pass:** Phase 55 is evidence-only; no profile, factory, decoder, FFI, or release change is permitted. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Caller-buffered schedule engine | New staging/retry driver | Existing local public-drain helper shape and `png_chunk_test_owner` sentinels | It already captures accepted-only accounting, tail ownership, and terminal probing. [VERIFIED: codebase] |
| PNG wire oracle | A general-purpose decompressor or second encoder | The existing compact Stored/None direct byte slice | The known fixed header/layout makes the exact four-lane raster observable without expanding runtime behavior. [VERIFIED: codebase] |
| Cross-target test implementation | Per-target forks or native fallback | `moon -C modules/mb-image test png --target all --frozen` | The locked phase explicitly requires one portable suite. [VERIFIED: CONTEXT.md] |

**Key insight:** This phase must prove the already shipped public boundary. A new private seam, buffering path, or target-specific test would reduce the value of that proof. [VERIFIED: CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Confusing U16 wire fidelity with decoder fidelity

**What goes wrong:** A test that expects the public decoder to return all four bytes overstates the contract; a decoder-only test also misses low-byte or lane-order loss. [VERIFIED: CONTEXT.md]

**How to avoid:** Prove full `Ghi,Glo,Ahi,Alo` with the literal Stored/None raster, and separately prove public `(Ghi,Ghi,Ghi,Ahi)` RGBA8 output. [VERIFIED: Phase 54 verification; VERIFIED: CONTEXT.md]

### Pitfall 2: Hidden attempted-byte accounting

**What goes wrong:** A caller-buffered test may pass while `total_written` tracks requested capacity or a lease tail is changed. [VERIFIED: Phase 49 and 52 verification]

**How to avoid:** On every pull require `total_written == accepted_before + written`, append only the returned prefix, and verify every remaining sentinel byte. [VERIFIED: codebase]

### Pitfall 3: Covering only Stored/None

**What goes wrong:** Fixed/Dynamic and Adaptive can use different planner/cursor paths, so one happy-path scanline does not prove the bounded public matrix. [VERIFIED: Phase 54 verification]

**How to avoid:** Run all six compression/filter pairs under all three schedules; reserve only the byte-for-byte raster check for Stored/None. [VERIFIED: CONTEXT.md]

### Pitfall 4: Accidentally widening the endian boundary

**What goes wrong:** Copying the Gray16 dual-endian test pattern would contradict Phase 53: GrayAlpha16 big-endian descriptors are invalid before source construction. [VERIFIED: Phase 54 summary; VERIFIED: CONTEXT.md]

**How to avoid:** Use only legal little-endian GrayAlpha16 sources in the public vector/schedule matrix and retain the focused descriptor construction rejection test. [VERIFIED: codebase]

## Code Examples

### Required all-six strategy matrix

```moonbit
// Source: current Gray16/GrayAlpha8 public evidence pattern
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let eager = png_stream_graya16_eager_with_strategies(image, strategy, filter)
    // First, independently assert a zero-length lease returns NeedOutput unchanged.
    png_stream_graya16_public_drain(image, strategy, filter, [0UL, 1UL], eager)
    png_stream_graya16_public_drain(image, strategy, filter, [1UL], eager)
    png_stream_graya16_public_drain(
      image, strategy, filter, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
    )
  }
}
```

### Required public decoder oracle

```moonbit
// Pseudocode for assertions performed through ImageDecoder::decode(PngDecoder::new(), ...).
assert_rgba8_pixel(restored, 0UL, 0UL, b'\x12', b'\x12', b'\x12', b'\xa7')
assert_rgba8_pixel(restored, 1UL, 0UL, b'\xbe', b'\xbe', b'\xbe', b'\x5a')
```

The exact helper name remains planner discretion; its construction and decoding must use existing public seams only. [VERIFIED: CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Phase 54 focused native implementation checks | Phase 55 independent public compatibility/portability evidence | Keep production delivery separate from compatibility proof. [VERIFIED: Phase 54 verification] |
| Gray16 supports legal little- and big-endian source descriptor testing | GrayAlpha16 is legal little-endian only | Do not import Gray16 big-endian parity expectations into this phase. [VERIFIED: Phase 54 summary; VERIFIED: CONTEXT.md] |

**Deprecated/outdated:** The earlier v0.17 research suggestion to compare GrayAlpha16 big-endian backing is superseded by the locked Phase 53/54 descriptor contract; that source cannot be constructed legally. [VERIFIED: project research; VERIFIED: Phase 54 summary]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The full all-target command may take longer than this runtime's 64-second command window; completion must be recorded by the execution phase rather than inferred from the timed-out research attempt. [ASSUMED] | Environment Availability | Planning may need a longer CI/local timeout, but test scope does not change. |

## Open Questions

None. Vector lanes, legal endian scope, strategy schedules, literal-vector policy, files, and acceptance command are all locked or directly established by current test helpers. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Focused and full PNG evidence | ✓ | `0.1.20260713` | — [VERIFIED: local CLI] |
| `moon test --target all` | Required js/wasm/wasm-gc/native acceptance run | ✓ command available; completion not observed within 64 seconds | same toolchain | Execute with a longer task/CI timeout. [VERIFIED: local CLI; ASSUMED] |

**Missing dependencies with no fallback:** None. [VERIFIED: local CLI]

**Required acceptance command:**

```powershell
moon -C modules/mb-image test png --target all --frozen
```

It must report independent success for wasm, wasm-gc, js, and native; do not substitute one target's outcome for another. [VERIFIED: CONTEXT.md]

## Security Domain

`security_enforcement` is not disabled in `.planning/config.json`, so this section applies. The phase changes tests only; its relevant trust boundaries are hostile caller capacities, public decode input, and frozen compatibility data. [VERIFIED: .planning/config.json; VERIFIED: CONTEXT.md]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity feature is changed. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | No session state is changed. [VERIFIED: CONTEXT.md] |
| V4 Access Control | no | No authorization boundary is changed. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Validate zero/one/ragged caller capacities, accepted totals, tails, and terminal outcomes at the public chunk API. [VERIFIED: CONTEXT.md] |
| V6 Cryptography | no | No cryptography is introduced or modified. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for this Evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Gray/alpha component or byte reversal hidden by symmetric samples | Tampering | Use the four-distinct-byte U16 pairs and literal nine-byte filter/raster vector. [VERIFIED: codebase] |
| Progress inflation or caller-tail mutation under capacity pressure | Tampering | Test every strategy pair under the full zero/one/ragged matrix with sentinels. [VERIFIED: codebase] |
| Legacy output drift silently accepted | Tampering | Compare retained Gray8/Gray16/GrayAlpha8/RGB8/RGBA8 literals, never regenerated data. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (local verified evidence)

- `55-CONTEXT.md` — locked public API, schedule, legacy, portability, and legal-endian decisions. [VERIFIED: CONTEXT.md]
- `54-VERIFICATION.md`, `54-01-SUMMARY.md`, and `54-02-SUMMARY.md` — completed encoder contract and explicitly deferred Phase 55 scope. [VERIFIED: Phase 54 artifacts]
- `49-RESEARCH.md` / `49-VERIFICATION.md` — U16 public wire, high-byte decoder, and hostile drain precedent. [VERIFIED: Phase 49 artifacts]
- `52-RESEARCH.md` / `52-VERIFICATION.md` — type-4 public vector and six-pair hostile schedule precedent. [VERIFIED: Phase 52 artifacts]
- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — exact current fixtures, vectors, helpers, and public seams. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- `moon --version` local output — installed MoonBit version. [VERIFIED: local CLI]

### Tertiary (LOW confidence)

- The timeout-duration assumption recorded as A1. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — verified locally with no external package/documentation dependency; the confidence seam classifies codebase-only providers conservatively. [VERIFIED: local CLI]
- Architecture: MEDIUM — locked context, completed predecessor verification, and current tests agree. [VERIFIED: CONTEXT.md; VERIFIED: Phase 54 artifacts; VERIFIED: codebase]
- Pitfalls: MEDIUM — all are repository-specific and traced to predecessor evidence/current helpers. [VERIFIED: Phase 49 and 52 verification; VERIFIED: codebase]

**Research date:** 2026-07-23  
**Valid until:** 2026-08-22, unless the public PNG API, Phase-53 endian contract, or MoonBit test runner changes. [ASSUMED]
