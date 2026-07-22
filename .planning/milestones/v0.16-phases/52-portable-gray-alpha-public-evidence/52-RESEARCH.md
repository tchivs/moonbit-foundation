# Phase 52: Portable Gray+Alpha Public Evidence - Research

**Researched:** 2026-07-23  
**Domain:** MoonBit public PNG conformance and caller-buffered portability evidence  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public vectors and decode contract
- **D-01:** Use compact, public package tests with non-symmetric GrayAlpha8 fixture pairs and explicit expected PNG bytes (or small checked byte slices where framing is already covered). Assert decoded public pixels canonicalize to straight RGBA8 with gray replicated into R/G/B and source alpha unchanged. — **Reversibility:** costly — frozen public byte vectors become the compatibility baseline for future encoder work.
- **D-02:** Keep the public evidence at existing `mb-image/png` API seams: construct through `PngEncoder`/`PngChunkEncoder` and decode through the package's public decoder; do not test private profiles or add a test-only encoder path.

### Caller-buffered hostile schedules
- **D-03:** For every existing compression/filter pair, drain valid GrayAlpha8 chunk encoders under zero-capacity, one-byte, and deterministic ragged capacities. Each schedule must match eager bytes, report only accepted progress, and retain the established sticky terminal outcome. — **Reversibility:** costly — weakening this matrix would remove the public bounded ownership guarantee from the portable contract.
- **D-04:** Reuse the existing streaming test drivers, sentinels, and terminal-error helpers. Do not add staging buffers, retry logic, target branches, or copied source trees merely to make hostile schedules pass.

### Compatibility and portability
- **D-05:** Freeze the already-established Gray8, Gray16, RGB8, and straight-RGBA8 eager vectors byte-for-byte beside the GrayAlpha evidence. Treat any change as a regression, not a new expected baseline.
- **D-06:** Run the same package test invocation with `--target all` and keep tests portable MoonBit only; no native FFI, platform-specific fixtures, release automation, or registry work belongs in this phase.

### the agent's Discretion
- Choose the smallest readable fixture/vector layout consistent with the existing Gray16 public-evidence pattern.
- Reuse the existing assertion helpers where they already capture accepted-only progress and sticky terminals; add focused helpers only when GrayAlpha component fidelity is not otherwise observable.
- Keep tests localized to the PNG package unless a public model fixture genuinely needs an adjacent existing test helper.

### Deferred Ideas (OUT OF SCOPE)
- Gray+Alpha16, Adam7, palettes/low-bit modes, colour conversion, and new encoder architecture.
- Release automation, publication work, native adapters, generated source copies, and per-target implementations.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| GRAYA-04 | Generated Gray+Alpha8 PNGs prove exact wire-pair preservation and public decode canonicalization to straight RGBA8. | Preserve the `(13,A7)` / `(D2,4C)` public fixture; assert type-4/8-bit/non-interlaced framing plus `00 13 A7 D2 4C` Stored/None scanline bytes and `RGBA=(13,13,13,A7),(D2,D2,D2,4C)`. [VERIFIED: codebase] |
| GRAYA-05 | Hostile capacities retain eager identity, accepted-only progress, sticky terminals, frozen legacy vectors, and four-target execution. | Copy the proven Gray16 public drain shape for all six GrayAlpha strategy/filter pairs and retain literal compatibility vectors in both eager and chunk evidence. [VERIFIED: codebase] |
</phase_requirements>

## Summary

Phase 51 already exposes the only production surface Phase 52 needs: `PngEncoder::new_graya8*_` and `PngChunkEncoder::new_graya8*_` select the private `GrayAlpha8` profile, color type 4, bit depth 8, and non-interlaced output. Its compact source pairs are `(0x13,0xA7)` and `(0xD2,0x4C)`; the real public decoder currently restores them as straight RGBA8 by replicating gray through RGB and preserving alpha. [VERIFIED: codebase]

The closest complete precedent is Phase 49. It keeps public evidence in `encode_test.mbt` and `stream_encode_test.mbt`, uses fresh encoders per schedule, and directly verifies an empty lease, zero-prefixed one-byte drain, one-byte drain, ragged drain, accepted-only totals, untouched lease tails, and a subsequent sticky `Finished` pull. [VERIFIED: Phase 49 verification] The smallest Phase 52 plan is therefore two test-only tasks in those same two files; it must not alter PNG production code, APIs, build scripts, fixtures, FFI, or target-specific paths. [VERIFIED: codebase]

**Primary recommendation:** Mirror Phase 49's public evidence pattern exactly for the existing 2x1 GrayAlpha8 fixture, add literal GrayAlpha and legacy vector assertions, and prove the full package once with `moon -C modules/mb-image test png --target all --frozen`. This invocation passed 195/195 on wasm, wasm-gc, js, and native during research. [VERIFIED: local MoonBit test]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Exact GrayAlpha8 PNG wire evidence | API / Backend | — | The public eager encoder owns serialized PNG bytes; tests must invoke it rather than inspect private profiles. [VERIFIED: codebase] |
| Decode canonicalization evidence | API / Backend | — | The public PNG decoder owns conversion of type-4 samples to the package's RGBA8 image result. [VERIFIED: codebase] |
| Caller-buffered ownership/progress evidence | API / Backend | — | `PngChunkEncoder::pull` owns outcomes and progress while the test owns each mutable lease and sentinel. [VERIFIED: codebase] |
| Portable target qualification | Build/Test harness | API / Backend | MoonBit runs one package suite against the portable targets; test code must not branch by target. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |

## Project Constraints (from AGENTS.md)

- Prefer the codebase knowledge graph for code discovery; it is not available in this runtime, so this research used targeted `rg` fallback only. [VERIFIED: runtime tool inventory]
- Keep core algorithms and shared data models in MoonBit; native is primary, but portable support is deliberate and guarded by conformance tests. [VERIFIED: AGENTS.md]
- Do not introduce FFI, platform-specific tests, release/registry automation, GUI state, or a new module dependency for this evidence-only phase. [VERIFIED: AGENTS.md; VERIFIED: CONTEXT.md]
- Public operations and compatibility evidence must be deterministic; use literal fixed vectors rather than regenerating expectations from the encoder under test. [VERIFIED: AGENTS.md; VERIFIED: Phase 49 verification]
- Public package tests remain black-box `*_test.mbt` tests; keep the work inside the existing PNG package test files. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Compile and execute the existing PNG package tests across targets. | It is the repository's pinned toolchain and locally exposes `--target all`. [VERIFIED: local CLI; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |
| Existing `mb-image/png` public API | repository HEAD | Construct/decode GrayAlpha8 and pull caller-owned leases. | The locked context requires these public seams and Phase 51 has already validated their wiring. [VERIFIED: codebase; VERIFIED: Phase 51 verification] |

### Supporting

No external packages are required or recommended. [VERIFIED: codebase]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Existing public test seams | Private encoder/profile tests | Rejected: would not prove the consumer-visible contract required by D-02. [VERIFIED: CONTEXT.md] |
| Existing Gray16 public drain helper shape | A new generic stream driver | Rejected: duplicates ownership logic and violates D-04. [VERIFIED: CONTEXT.md; VERIFIED: Phase 49 verification] |
| Literal vectors and small stored scanline slice | Generated expectations or opaque snapshots | Rejected: generated expectations can absorb regressions; opaque snapshots obscure gray/alpha ordering. [VERIFIED: AGENTS.md; VERIFIED: Phase 49 research] |

**Installation:** None — this phase installs no package. [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```text
packed GrayAlpha8 fixture: (13,A7), (D2,4C)
          |
          +--> PngEncoder::new_graya8_with_strategies
          |          |
          |          +--> eager PNG bytes --> literal/slice wire oracle
          |          |                          |
          |          |                          +--> public PngDecoder --> RGBA canonicalization oracle
          |          |
          +--> PngChunkEncoder::new_graya8_with_strategies
                     |
                     +--> fresh zero / one / ragged caller leases
                              |
                              +--> accepted bytes + lease-tail sentinel + sticky Finished
                                              |
                                              +--> exact equality with eager bytes

same package suite --> moon test --target all --> wasm | wasm-gc | js | native
```

The diagram uses only public factories and decoder paths. [VERIFIED: CONTEXT.md; VERIFIED: codebase]

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # public eager wire/decode and literal-vector evidence
└── stream_encode_test.mbt   # public hostile-capacity, progress, terminal, and chunk-vector evidence
```

No production or new test-support file is justified. [VERIFIED: Phase 49 verification]

### Pattern 1: Public Stored/None wire plus decode oracle

**What:** Reuse `png_encode_graya8_image()` and `png_encode_graya8_decode_matches_source()`; assert the known type-4 IHDR fields and compact Stored/None wire slice `00 13 A7 D2 4C`, then assert public RGBA restoration. [VERIFIED: codebase]

**When to use:** Once for the default Stored/None route, where byte placement is stable; use the six-pair matrix only for framing, public decoding, and eager/chunk identity because adaptive filtering and compression intentionally change representation. [VERIFIED: Phase 49 research]

```moonbit
// Source: modules/mb-image/png/encode_test.mbt (public-test pattern)
let bytes = png_encode_prefix(writer)
inspect(bytes[24] == b'\x08' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
inspect(bytes[48] == b'\x00' && bytes[49] == b'\x13' && bytes[50] == b'\xa7', content="true")
png_encode_graya8_decode_matches_source(bytes)
```

The full decode oracle must require `R=G=B=gray` and `A=source alpha` for both non-symmetric pairs. [VERIFIED: codebase]

### Pattern 2: Fresh encoder per hostile schedule

**What:** Adapt `png_stream_gray16_public_drain` into a focused GrayAlpha8 drain helper that creates a fresh public chunk encoder, records only returned `written` bytes, checks `total_written == accepted_before + written`, retains lease-tail sentinels, requires eager equality at `Finished`, and confirms the next sentinel pull is a zero-byte sticky `Finished`. [VERIFIED: codebase; VERIFIED: Phase 49 verification]

**When to use:** For each `Stored` / `FixedOrStored` / `DynamicOrFixedOrStored` crossed with `None` / `Adaptive`; use explicit zero lease, `[0UL, 1UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`. [VERIFIED: CONTEXT.md; VERIFIED: Phase 49 verification]

```moonbit
// Source: modules/mb-image/png/stream_encode_test.mbt (Gray16 public-drain pattern)
let before = output.length().to_uint64()
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png graya8 public accepted progress")
}
```

### Anti-Patterns to Avoid

- **Reusing a drained encoder:** A completed encoder cannot independently prove each schedule's initial zero-capacity and progress contract; construct a new encoder per schedule. [VERIFIED: Phase 49 verification]
- **Comparing adaptive or Fixed/Dynamic output to a new full snapshot:** Those routes may legitimately differ in compressed/filter representation; compare each chunk output to its fresh eager peer and retain the exact compact Stored/None wire oracle. [VERIFIED: Phase 49 research]
- **Testing `PngEncodeProfile::GrayAlpha8` directly:** It bypasses the public compatibility surface required by D-02. [VERIFIED: CONTEXT.md]
- **Adding a target branch or fixture generator:** The unified all-target suite already passes and the phase boundary forbids target-specific behavior and generated pipelines. [VERIFIED: local MoonBit test; VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Streaming schedule runner | A second loop/retry/staging driver | The existing public-drain helper pattern and `png_chunk_test_owner` sentinels | They already encode accepted-only totals, untouched tails, and terminal probes. [VERIFIED: codebase; VERIFIED: Phase 49 verification] |
| PNG decompression oracle | A general inflater or test utility | Compact Stored/None byte slice, with framing already covered | This 2x1 source makes gray/alpha ordering observable without widening a test-only parser. [VERIFIED: CONTEXT.md; VERIFIED: codebase] |
| Cross-target harness | Four copied test suites or platform branches | `moon -C modules/mb-image test png --target all --frozen` | One portable suite exercised all four required targets successfully in this session. [VERIFIED: local MoonBit test] |

**Key insight:** Phase 52 validates observable compatibility contracts, not a new encoding mechanism; any new transport, private seam, or target branch would weaken rather than improve that evidence. [VERIFIED: CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating framing bytes as a complete wire oracle

**What goes wrong:** A test can prove color type 4 while missing gray/alpha swapping inside the payload. [VERIFIED: codebase]

**How to avoid:** Keep the non-symmetric pairs and check the Stored/None filter-plus-pair sequence `00 13 A7 D2 4C` in addition to IHDR and public decoder behavior. PNG type 4 stores grey followed by alpha and uses unassociated alpha. [CITED: https://www.w3.org/TR/png-3/]

### Pitfall 2: Counting attempted instead of accepted output

**What goes wrong:** A capacity schedule can look complete while the reported total advances by requested capacity or mutates sentinel tails. [VERIFIED: Phase 49 verification]

**How to avoid:** Derive the next expected total only from `written`, append only those bytes, and inspect all tail bytes after every pull. [VERIFIED: codebase]

### Pitfall 3: Hiding terminal regressions inside a generic drain

**What goes wrong:** A drain can stop at the first `Finished` and never demonstrate that a later pull is zero-byte, unchanged-total, `Finished`, and sentinel-safe. [VERIFIED: Phase 49 verification]

**How to avoid:** Retain the explicit later seven-byte sentinel lease after every successful hostile drain. [VERIFIED: codebase]

### Pitfall 4: Accidentally accepting a changed legacy baseline

**What goes wrong:** Computing expected vectors with the current encoder makes a compatibility regression become the new expectation. [VERIFIED: AGENTS.md]

**How to avoid:** Keep literal expected bytes: current complete Gray8/RGB8/RGBA8 Stored PNG literals and the existing Gray16 public Stored/None wire vector must be copied as constants, not derived at runtime. [VERIFIED: codebase; VERIFIED: Phase 49 verification]

## Code Examples

### Required GrayAlpha8 schedule matrix

```moonbit
// Source: Phase 49 public-evidence schedule, adapted only at the public factory.
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    // fresh encoder inside each public-drain invocation
    png_stream_graya8_public_drain(image, strategy, filter, [0UL, 1UL], eager)
    png_stream_graya8_public_drain(image, strategy, filter, [1UL], eager)
    png_stream_graya8_public_drain(
      image, strategy, filter, [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
    )
  }
}
```

Run a separate first pull using a zero-length lease before this matrix and assert `written=0`, `total_written=0`, `NeedOutput`, and unchanged sentinel content. [VERIFIED: Phase 49 verification]

## State of the Art

| Old Approach | Current Approach | Impact |
|---|---|---|
| Native-only spot checks for a new codec route | One portable MoonBit package suite with `--target all` | Phase 52 can establish all four target results without per-target source. [VERIFIED: local MoonBit test; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |
| Private or implementation-oriented wire checks | Public eager/chunk factory and public decoder evidence | Tests protect the API consumers actually use. [VERIFIED: CONTEXT.md] |

## Assumptions Log

All recommendations are grounded in the locked context, current code, Phase 49 evidence, Phase 51 verification, a local all-target execution, or the cited specifications. No user confirmation is needed. [VERIFIED: research audit]

## Open Questions

None. The fixture, public APIs, exact schedules, legacy-vector policy, and portable command are fixed by context and prior evidence. [VERIFIED: CONTEXT.md; VERIFIED: local MoonBit test]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` | Complete portable PNG package evidence | ✓ | `0.1.20260713` | — [VERIFIED: local CLI] |
| MoonBit `--target all` | wasm, wasm-gc, js, native qualification | ✓ | Same toolchain; 195/195 passed on each target | — [VERIFIED: local MoonBit test] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment]

## Security Domain

The project configuration leaves `security_enforcement` enabled by default; this evidence-only phase adds no production trust boundary, but it must preserve existing caller-owned lease and deterministic compatibility protections. [VERIFIED: .planning/config.json; VERIFIED: Phase 51 security]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity feature is added. [VERIFIED: CONTEXT.md] |
| V3 Session Management | no | No session state is added. [VERIFIED: CONTEXT.md] |
| V4 Access Control | no | No authorization boundary is added. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Exercise zero/one/ragged caller capacities and require public API outcomes, progress, and lease ownership to remain valid. [VERIFIED: CONTEXT.md; VERIFIED: Phase 49 verification] |
| V6 Cryptography | no | No cryptographic primitive is added or altered. [VERIFIED: CONTEXT.md] |

### Known Threat Patterns for this Evidence

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Component-order or alpha-association regression hidden by symmetric data | Tampering | Use `(13,A7)` and `(D2,4C)`, exact Stored/None pair bytes, and public RGBA canonicalization checks. [VERIFIED: codebase; CITED: https://www.w3.org/TR/png-3/] |
| Lease mutation or inflated progress under hostile capacity | Tampering | Check accepted-only arithmetic, untouched tails, and later sticky-terminal sentinel leases for every six-pair matrix member. [VERIFIED: Phase 49 verification] |
| Legacy byte drift accepted as a new baseline | Tampering | Compare to retained literal vectors only; never calculate expected bytes via the current encoder. [VERIFIED: AGENTS.md; VERIFIED: codebase] |

## Sources

### Primary (HIGH confidence)

- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — existing GrayAlpha8 fixture, public decoder oracle, current frozen vectors, and Gray16 hostile-drain precedent. [VERIFIED: codebase]
- `.planning/phases/51-bounded-gray-alpha-png-encoding/51-VERIFICATION.md`, `51-REVIEW.md`, and `51-SECURITY.md` — public factory, profile, atomicity, and threat baseline. [VERIFIED: phase artifacts]
- `.planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/49-RESEARCH.md` and `49-VERIFICATION.md` — exact evidence layout and schedule precedent. [VERIFIED: phase artifacts]
- Local command `moon -C modules/mb-image test png --target all --frozen` — 195 passed on each of wasm, wasm-gc, js, and native. [VERIFIED: local MoonBit test]

### Secondary (MEDIUM confidence)

- [MoonBit command-line help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — `moon test` target names include `all`. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]
- [MoonBit workspace support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html) — documents `moon test --target all`. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html]
- [PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — color type 4 is grey followed by alpha; alpha is non-premultiplied. [CITED: https://www.w3.org/TR/png-3/]

### Tertiary (LOW confidence)

None. [VERIFIED: research audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — local toolchain and all-target test execution succeeded. [VERIFIED: local MoonBit test]
- Architecture: HIGH — locked Phase 52 context and current Phase 49/51 test seams agree. [VERIFIED: phase artifacts; VERIFIED: codebase]
- Pitfalls: HIGH — prior public-evidence verification explicitly exercised each identified failure mode. [VERIFIED: Phase 49 verification]

**Research date:** 2026-07-23  
**Valid until:** 2026-08-22 (stable internal test pattern; re-check if the MoonBit toolchain or public PNG API changes). [ASSUMED]
