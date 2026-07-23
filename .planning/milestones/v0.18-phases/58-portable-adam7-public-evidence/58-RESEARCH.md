# Phase 58: Portable Adam7 Public Evidence - Research

**Researched:** 2026-07-23
**Domain:** MoonBit public PNG evidence for interlaced packed U16 Gray+Alpha
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public multipass fidelity

- **D-01:** Use a deliberately non-symmetric multi-pass GrayAlpha16 vector and public eager factories to inspect literal Type-4/16 Adam7 `Ghi,Glo,Ahi,Alo` output, then decode it only through the documented straight-RGBA8 high-byte canonicalization. — **Reversibility:** costly — changing this boundary would alter public decoding expectations and fixture provenance.
- **D-02:** Keep the evidence independent of private cursor/profile helpers: public APIs and deterministic PNG wire parsing are the proof boundary.

### Caller-buffer schedules

- **D-03:** For every legal None/Adaptive × Stored/FixedOrStored/DynamicOrFixedOrStored pair, drain a fresh encoder under zero-capacity, one-byte, and ragged leases; require eager-byte identity, accepted-only totals, untouched tails, and sticky terminal outcomes.

### Compatibility and portability

- **D-04:** Freeze existing non-interlaced and legacy Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 byte baselines; do not widen descriptor admission, add a staging encoder, or change published non-interlaced output.
- **D-05:** Final evidence runs only public PNG tests on js, wasm, wasm-gc, and native; target-specific expectations are out of scope.

### the agent's Discretion

- Reuse the smallest existing public wire parser, decoder assertions, schedule drainer, and frozen-baseline fixtures from Phase 55 and earlier Adam7 evidence.
- Add production code only if a public proof reveals a real contract defect; do not add release automation, FFI, source-tree copies, Big-endian GrayAlpha16 support, colour conversion, or decoder-model widening.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within the Phase 58 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYA16A7-03 | Generated multi-pass GrayAlpha16 Adam7 PNGs prove public pass-aware wire fidelity and documented RGBA8 high-byte decode canonicalization; zero, one-byte, and ragged caller capacities remain eager-byte-identical with accepted-only progress and sticky terminals; frozen non-interlaced and legacy vectors remain unchanged on js, wasm, wasm-gc, and native. | Extend the existing public 5×5 Adam7 source, independent Stored-block scanline parser, public RGBA8 assertion, all-six-pair fresh-drain pattern, and literal frozen-vector tests in the two PNG package test files. [VERIFIED: codebase] |
</phase_requirements>

## Summary

Phase 56 already made public GrayAlpha16 Adam7 factory selection explicit; Phase 57 subsequently verified all six legal compression/filter selections, pass-local filtering, atomically rejected construction failures, and replay safety. Phase 58 must add consumer-visible proof only. It should not re-test private cursors, preflight ledgers, or mutation implementation details. [VERIFIED: 57-VERIFICATION.md; VERIFIED: 58-CONTEXT.md]

The repository already contains the right building blocks. `encode_test.mbt` has a legal 5×5 non-symmetric little-endian GrayAlpha16 source, an independent seven-pass expected raster helper, and a public decoder assertion for the existing U8 straight-RGBA boundary. `stream_encode_test.mbt` has both the all-six-pair hostile public-drain shape and a GrayAlpha16 Adam7 drain that validates accepted progress, unwritten tails, and terminal stickiness. The required work is to make those proof paths explicitly Phase-58 public evidence: wire parser + all-pixel high-byte decode for the Adam7 fixture, full hostile schedules for every pair, and retained literal legacy/None vectors. [VERIFIED: `modules/mb-image/png/encode_test.mbt`; VERIFIED: `modules/mb-image/png/stream_encode_test.mbt`]

**Primary recommendation:** Keep this a two-test-file, no-production-change phase: one eager public literal-wire/decode plus frozen-eager baseline task, one public chunk schedule plus frozen-chunk baseline task; then run `moon -C modules/mb-image test png --target all --frozen`. [VERIFIED: codebase; VERIFIED: 58-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Adam7 Type-4/16 literal PNG evidence | API / backend | — | The contract is selected through public `PngEncoder` factories and observed from emitted bytes. [VERIFIED: `encode.mbt`; VERIFIED: 58-CONTEXT.md] |
| U16 type-4 decode canonicalization | API / backend | — | `PngDecoder` defines the documented image-model boundary: straight RGBA8 high bytes, rather than a U16 decoded model. [VERIFIED: `encode_test.mbt`; VERIFIED: 58-CONTEXT.md] |
| Caller-buffer ownership evidence | API / backend | — | `PngChunkEncoder::pull` crosses from encoder state into caller-owned mutable leases; tests own capacities and sentinel checks. [VERIFIED: `stream_encode_test.mbt`] |
| Cross-target qualification | Build/test harness | API / backend | The existing MoonBit package runner executes identical portable tests on all four declared targets. [VERIFIED: `modules/mb-image/moon.mod.json`; VERIFIED: local `moon --version`] |

## Project Constraints (from AGENTS.md)

- Prefer codebase knowledge-graph tools for code discovery; no graph MCP tool and no `.planning/graphs/graph.json` are available in this runtime, so targeted source inspection is the permitted fallback. [VERIFIED: runtime inventory]
- Keep algorithms and shared models in MoonBit, and use conformance tests across js, wasm, wasm-gc, and native. [VERIFIED: AGENTS.md]
- Keep public behavior deterministic and GUI-independent. [VERIFIED: AGENTS.md]
- Do not add native FFI, broad dependencies, or hidden compatibility changes. [VERIFIED: AGENTS.md; VERIFIED: 58-CONTEXT.md]
- Begin mutations through the GSD workflow; this research artifact is the sole mutation in this research task. [VERIFIED: AGENTS.md; VERIFIED: task scope]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Run the existing public PNG suite on every production target. | Installed project toolchain; the module declares all four targets. [VERIFIED: local CLI; VERIFIED: `modules/mb-image/moon.mod.json`] |
| `mb-image/png` public API | repository HEAD | Construct legal eager/chunk Adam7 outputs and decode them. | Locked proof boundary; no external library is allowed or needed. [VERIFIED: 58-CONTEXT.md] |

### Supporting

No package installation, FFI, release tool, generator, external service, or fixture download is required. [VERIFIED: 58-CONTEXT.md; VERIFIED: codebase]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Public PNG factory/decoder evidence | Private cursor/profile assertions | Rejected: it bypasses the consumer-visible boundary required by D-02. [VERIFIED: 58-CONTEXT.md] |
| Literal Stored/None payload + independent parser | Re-encoding expected values at runtime | Rejected: current encoder output cannot be the compatibility oracle. [VERIFIED: AGENTS.md; VERIFIED: 58-CONTEXT.md] |
| Existing fresh-drain helpers | New generic streaming test harness | Rejected: existing helpers already verify accepted-only totals, tails, and terminal behavior; a second harness would duplicate ownership logic. [VERIFIED: `stream_encode_test.mbt`] |

**Installation:** None. [VERIFIED: 58-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
legal 5×5 LE GrayAlpha16 source
  (distinct Ghi/Glo/Ahi/Alo per x,y)
             |
             +--> public PngEncoder::new_graya16_with_all_strategies(..., Adam7)
             |          |
             |          +--> IHDR: depth 16, type 4, interlace 1
             |          +--> Stored/None IDAT --> bounded stored-block parser
             |                                      --> literal seven-pass Ghi,Glo,Ahi,Alo raster
             |          +--> public PngDecoder --> straight RGBA8 Ghi,Ghi,Ghi,Ahi
             |
             +--> public PngChunkEncoder::new_graya16_with_all_strategies(..., Adam7)
                        |
                        +--> fresh zero / one / ragged caller leases
                        +--> accepted-only bytes + untouched tails + sticky Finished
                        +--> exact equality with a fresh eager result

retained non-interlaced factories --> literal Gray8/Gray16/GrayAlpha8/RGB8/RGBA8 PNG baselines
all public PNG tests --> moon test --target all --> wasm | wasm-gc | js | native
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # eager Adam7 wire/decode and frozen eager baseline proof
└── stream_encode_test.mbt   # all-pair caller-lease proof and frozen chunk baseline proof
```

Do not modify `encode.mbt`, `stream_encode.mbt`, private `*_wbtest.mbt`, scripts, fixtures, or public APIs unless the public proof produces a real failing contract. [VERIFIED: 58-CONTEXT.md; VERIFIED: 57-VERIFICATION.md]

### Pattern 1: Parse the Stored/None raster independently, then decode only publicly

Use `png_encode_graya16_adam7_image()` as the 5×5 vector. It writes distinct little-endian component bytes for every pixel, and all seven Adam7 passes are nonempty. Reuse the existing bounded stored-block parser `png_encode_gray16_public_stored_scanlines(bytes)`; despite its historic name, it parses the public PNG envelope and Stored DEFLATE bytes rather than a private encoder cursor. Compare its result with `png_encode_graya16_adam7_expected_passes()`, whose pass placements are written independently as the standard seven Adam7 tuples. [VERIFIED: `encode_test.mbt:214-273`; VERIFIED: `encode_test.mbt:426-474`]

Assert the public PNG header (`bytes[24] == 0x10`, `bytes[25] == 0x04`, `bytes[28] == 0x01`) before comparing the complete filtered pass stream. For each source sample at `(x,y)`, the expected public decode is `(Ghi,Ghi,Ghi,Ahi)`—the low bytes remain wire evidence only. The existing `png_encode_graya16_public_decode_is_canonical` is deliberately hard-coded for the noninterlaced 2×1 fixture, so Phase 58 needs a parallel Adam7-aware public decoder helper that checks all 25 generated pixels, descriptor U8/Rgba, dimensions, grayscale replication, and alpha high byte. [VERIFIED: `encode_test.mbt:539-570`; VERIFIED: `encode_test.mbt:1148-1178`]

### Pattern 2: Use a fresh public chunk encoder for each schedule and every pair

Adapt `png_graya16_adam7_chunk_drain` rather than `png_stream_graya16_public_drain`: the former already selects the public Adam7 chunk factory and validates tail bytes plus a later sticky `Finished` result. Improve its evidence shape to use all three required fresh schedules: `[0UL, 1UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`. Each loop must cover Stored/FixedOrStored/DynamicOrFixedOrStored × None/Adaptive. Before every schedule, construct a fresh encoder and compare only final accepted bytes with a fresh eager oracle for the same pair. [VERIFIED: `stream_encode_test.mbt:3515-3645`; VERIFIED: `stream_encode_test.mbt:1333-1445`]

For the zero-capacity direct call, use a one-byte `Z` owner and a zero-length lease; assert `written == 0`, `total_written == 0`, `NeedOutput`, and the owner byte is still `Z`. In each normal pull, assert `written <= capacity`, `total_written == prior_accepted + written`, copy exactly the written prefix, and require every remaining lease byte to remain `Z`. On `Finished`, compare accumulated bytes to eager output, then a later 7-byte `Z` lease must report zero new bytes, retain total, stay `Finished`, and leave every byte unchanged. [VERIFIED: `stream_encode_test.mbt:630-800`; VERIFIED: `stream_encode_test.mbt:1333-1445`]

### Pattern 3: Keep legacy and explicit-None baselines literal and separate

The existing eager frozen-vector test already holds literal Stored/None PNG byte strings for Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8. Its chunk counterpart holds the corresponding literal values and drains real chunk encoders. Retain these exact test names and literals, adding only explicit noninterlaced checks that are absent from the chosen Phase-58 coverage if needed. Do not fold Adam7 bytes into these noninterlaced baseline literals: the Adam7 wire assertion belongs in Pattern 1. [VERIFIED: `encode_test.mbt:935-1038`; VERIFIED: `stream_encode_test.mbt:1488-1580`]

### Anti-Patterns to Avoid

- **Only asserting IHDR:** depth/type/interlace alone cannot catch pass placement, component order, or byte order. Parse and compare the full Stored/None filtered pass stream. [VERIFIED: 58-CONTEXT.md]
- **Calling a private cursor/profile from the evidence test:** this weakens the public proof boundary. Use public factories, public decoder, and PNG byte parsing only. [VERIFIED: D-02]
- **Reusing a chunk encoder across schedules:** this hides schedule dependence and violates the fresh-encoder requirement. [VERIFIED: D-03]
- **Appending an entire lease:** only `written` bytes are encoder-owned; the rest must remain sentinel bytes. [VERIFIED: `stream_encode_test.mbt`]
- **Assuming RGBA8 decode preserves U16 low bytes:** public decode canonicalizes from high bytes; literal wire parsing owns low-byte verification. [VERIFIED: 58-CONTEXT.md]
- **Rebaselining frozen outputs:** a byte change is a regression to investigate, not a new expected literal. [VERIFIED: D-04]
- **Adding a four-target release script:** the required evidence is the package test command, not new automation. [VERIFIED: D-05; VERIFIED: user direction]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Adam7 pass traversal oracle | A second test-only cursor or production-style pass machine | `png_encode_graya16_adam7_expected_passes`' compact independent tuple loop | It is small, deterministic, and does not duplicate production architecture. [VERIFIED: `encode_test.mbt`] |
| DEFLATE decoding | A general inflater or private codec hook | Existing `png_encode_gray16_public_stored_scanlines` bounded Stored-block parser | The literal wire test uses Stored/None and only needs the known stored-block form. [VERIFIED: `encode_test.mbt`] |
| Caller-buffer scheduler | New reusable abstraction | Existing local public-drain pattern | It already codifies accepted-prefix ownership and sticky terminal semantics. [VERIFIED: `stream_encode_test.mbt`] |
| Cross-target runner | New PowerShell/release flow | `moon -C modules/mb-image test png --target all --frozen` | The project requires the ordinary portable package suite. [VERIFIED: 58-CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: The old canonical decode helper validates the wrong fixture

**What goes wrong:** Reusing `png_encode_graya16_public_decode_is_canonical` would inspect its fixed 2×1 pair list instead of the 5×5 Adam7 source.
**Why it happens:** The existing helper was intentionally Phase-55-specific.
**How to avoid:** Add an Adam7-specific public decode helper deriving expected high bytes from the fixture's `(x,y)` formula; keep the old helper untouched for its frozen noninterlaced proof.
**Warning signs:** A new Adam7 test passes even if its fixture changes but the helper's fixed pair list does not. [VERIFIED: `encode_test.mbt:539-570`; VERIFIED: `encode_test.mbt:214-247`]

### Pitfall 2: “Zero schedule” is not the direct zero-capacity contract

**What goes wrong:** A schedule beginning with zero can be followed by a positive lease before the test asserts the direct response.
**Why it happens:** Generic drain loops intentionally advance after `NeedOutput`.
**How to avoid:** Retain a direct zero-length lease assertion before each drain, with a one-byte sentinel owner.
**Warning signs:** Tests check final byte equality but never inspect the initial `NeedOutput` and untouched sentinel. [VERIFIED: `stream_encode_test.mbt:1344-1356`; VERIFIED: `stream_encode_test.mbt:3530-3535`]

### Pitfall 3: Existing Adam7 parity is narrower than Phase 58

**What goes wrong:** The current six selectors exercise compact one-byte and `[1,3,2,5]` drains, but not the required zero/one/ragged public-evidence matrix and lack public decode/wire assertions across the Phase-58 proof.
**Why it happens:** Phase 57 was a bounded semantics phase, not the final public evidence phase.
**How to avoid:** Keep Phase-57 regressions, and add a separate Phase-58 public evidence test that exhaustively applies all three schedules to every pair.
**Warning signs:** A plan claims D-03 based only on the prior `chunk parity` test names. [VERIFIED: `stream_encode_test.mbt:3590-3645`; VERIFIED: 58-CONTEXT.md]

### Pitfall 4: Concurrent MoonBit invocations can contend for build state

**What goes wrong:** Simultaneous whole-suite target runs can make evidence flaky or delay completion.
**Why it happens:** All-target builds share the same module build cache.
**How to avoid:** Run focused native selectors during task work; serialize the final all-target package command after test-file tasks land.
**Warning signs:** An active `moon` process or build-lock error. [VERIFIED: project execution history; VERIFIED: 57-VERIFICATION.md]

## Code Examples

### Public Stored/None Adam7 wire-to-decode pattern

```moonbit
let (_, writer) = png_adam7_encode_with(
  PngEncoder::new_graya16_with_all_strategies(
    PngCompressionStrategy::Stored,
    PngFilterStrategy::None,
    PngInterlaceStrategy::Adam7,
  ),
  png_encode_graya16_adam7_image(),
)
let bytes = png_encode_prefix(writer)
if bytes[24] != b'\x10' || bytes[25] != b'\x04' || bytes[28] != b'\x01' ||
  png_encode_gray16_public_stored_scanlines(bytes) !=
    Bytes::from_array(png_encode_graya16_adam7_expected_passes()) {
  abort("png graya16 Adam7 public wire")
}
png_encode_graya16_adam7_public_decode_is_canonical(bytes)
```

The final helper name is proposed; it must use only `PngDecoder` through `ImageDecoder::decode` and compare all 25 expected high-byte values. [VERIFIED: existing pattern in `encode_test.mbt`]

### Fresh caller-buffer schedule pattern

```moonbit
for schedule in [
  [0UL, 1UL],
  [1UL],
  [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL],
] {
  png_graya16_adam7_public_drain(
    png_stream_graya16_adam7_image(), strategy, filter_strategy, schedule,
  )
}
```

The drain must construct its own `PngChunkEncoder::new_graya16_with_all_strategies(..., Adam7, ...)` each time rather than accepting a prebuilt encoder. [VERIFIED: D-03; VERIFIED: `stream_encode_test.mbt`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| GrayAlpha16 noninterlaced-only public proof | Explicit public Adam7 factories plus bounded all-six-pair execution | Phases 56–57 | Phase 58 can focus entirely on public fidelity and portable compatibility evidence. [VERIFIED: ROADMAP.md; VERIFIED: 57-VERIFICATION.md] |
| Legacy Adam7 public evidence uses RGB8/RGBA8 generated vectors | GrayAlpha16 Adam7 needs Type-4/16 literal wire + RGBA8 high-byte canonicalization | v0.18 | Do not reuse full U8 round-trip equality as the U16 decoder oracle. [VERIFIED: Phase 43 plan; VERIFIED: 58-CONTEXT.md] |

**Deprecated/outdated:**

- A separate Phase-43 PowerShell compatibility runner is not part of this phase; D-05 explicitly selects the ordinary four-target MoonBit package test. [VERIFIED: Phase 43 plan; VERIFIED: 58-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | No assumptions used; this research is grounded in the active context, milestone artifacts, local source, and installed toolchain. | — | — |

## Open Questions

None. The locked context and existing helper seams determine the implementation shape. If literal wire evidence reveals a discrepancy, treat it as an implementation defect and route it through GSD debugging rather than changing the public contract. [VERIFIED: 58-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Focused and all-target PNG tests | ✓ | `0.1.20260713` | — |
| Existing `mb-image/png` test package | Public evidence | ✓ | repository HEAD | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No authentication boundary. |
| V3 Session Management | no | No session state. |
| V4 Access Control | no | No authorization surface. |
| V5 Input Validation | yes | Existing public PNG parser/decoder and descriptor admission; tests retain legal-LE boundaries and only deterministic generated output. [VERIFIED: 58-CONTEXT.md] |
| V6 Cryptography | no | No cryptography. |

### Known Threat Patterns for portable PNG evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| U16 lane/pass ordering regression hidden by symmetric samples | Tampering | Distinct high/low Gray/Alpha bytes plus full literal Stored/None pass-stream oracle. [VERIFIED: D-01] |
| Caller-buffer overwrite or progress inflation | Tampering | Fresh zero/one/ragged drains, accepted-prefix-only totals, and untouched-tail sentinels. [VERIFIED: D-03] |
| Sticky-terminal regression after completion | Tampering | Later sentinel lease must return zero writes and unchanged total/bytes. [VERIFIED: D-03] |
| Legacy byte drift concealed by generated expectations | Tampering | Retain literal Gray8/Gray16/GrayAlpha8/RGB8/RGBA8 baseline PNGs. [VERIFIED: D-04] |

## Sources

### Primary (HIGH confidence)

- `58-CONTEXT.md` - locked phase decisions and proof boundary.
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - GRAYA16A7-03 scope and success criteria.
- `57-VERIFICATION.md` - completed bounded all-six-pair/replay semantics that Phase 58 must not duplicate.
- `modules/mb-image/png/encode_test.mbt` - existing public fixture, parser, decoder, wire, and frozen-vector seams.
- `modules/mb-image/png/stream_encode_test.mbt` - existing public fresh-drain, all-pair, tail, terminal, and frozen-vector seams.
- `modules/mb-image/moon.mod.json` and local `moon --version` - four target declaration and installed toolchain.

### Secondary (MEDIUM confidence)

- `.planning/milestones/v0.17-phases/55-portable-public-evidence/55-RESEARCH.md` and `55-VERIFICATION.md` - Type-4/16 public-evidence precedent.
- `.planning/milestones/v0.16-phases/52-portable-gray-alpha-public-evidence/52-01-PLAN.md` - all-pair caller-buffer schedule precedent.
- `.planning/milestones/v0.13-phases/43-portable-adam7-public-evidence/43-01-PLAN.md` - public Adam7 evidence and frozen-None precedent.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — installed local toolchain and no external dependency.
- Architecture: HIGH — locked phase context maps directly to extant public helpers and tests.
- Pitfalls: HIGH — each is evidenced by current helper specialization or prior phase boundary.

**Research date:** 2026-07-23
**Valid until:** implementation of Phase 58 completes; no fast-moving external dependency is involved.

## Recommended Plan Shape

1. **Wave 1, eager proof (`encode_test.mbt`):** add the Adam7-specific public decoder assertion; use Stored/None to parse and compare the complete literal seven-pass raster; retain/exercise the legacy and explicit-None frozen eager vectors. Focused native selector should cover the new eager evidence.
2. **Wave 1, chunk proof (`stream_encode_test.mbt`):** add/adapt an Adam7-specific public fresh-drain helper that performs direct zero lease checks and independent zero/one/ragged drains for all six pairs; retain/exercise frozen chunk vectors. Focused native selector should cover the new chunk evidence.
3. **Wave 2, integration gate:** after both test files are present, run the whole public PNG package once with `moon -C modules/mb-image test png --target all --frozen`, inspect the scoped diff, and verify no production/API/script/fixture change slipped in.

The two Wave-1 tasks own disjoint files and can proceed in parallel; serialize the all-target gate to avoid MoonBit build-cache contention. [VERIFIED: codebase; VERIFIED: 58-CONTEXT.md]
