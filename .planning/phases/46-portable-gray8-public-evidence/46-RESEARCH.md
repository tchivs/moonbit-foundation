# Phase 46: Portable Gray8 Public Evidence - Research

**Researched:** 2026-07-22
**Domain:** MoonBit black-box PNG encoder/decoder regression evidence across portable targets
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Public fidelity oracle
- **D-01:** Generate compact deterministic Gray8 source images in the existing public test helpers, encode through `PngEncoder::new_gray8_with_strategies`, decode through `PngDecoder::new`, and compare dimensions, one-channel format, and every original sample. Cover Stored, FixedOrStored, DynamicOrFixedOrStored, None, and Adaptive without private encoder APIs or opaque binary snapshots.

### Caller-buffered schedules and compatibility
- **D-02:** Use the existing public `PngChunkEncoder` drain helper with schedules containing zero, one-byte, and ragged capacities; require byte-for-byte equality to the equivalent eager Gray8 result and correct accepted-byte progress. Do not add a separate stream harness or image staging.
- **D-03:** Keep existing frozen RGB8 and straight-RGBA8 byte fixtures in the same portable test scope; add no new compatibility format or fixture generator.

### Portable evidence
- **D-04:** Run the same `png` package test suite independently with `moon` on js, wasm, wasm-gc, and native. Record these exact commands and results in the plan summary/verification; do not add CI, PowerShell, release, or publication scripts.

### Scope boundary
- **D-05:** Keep Gray8 Adam7, palette/indexed formats, low-bit packing, Gray16, transparency conversion, decoder behavior changes, and external-package work out of scope. Production PNG source remains unchanged unless a portable test exposes a genuine existing defect.

### the agent's Discretion

Choose the smallest deterministic image dimensions and sample pattern that exercise multi-row adaptive filtering and compression while keeping all target tests fast and readable.

### Deferred Ideas (OUT OF SCOPE)

- Gray8 Adam7, palette/indexed encoding, low-bit packing, Gray16, transparency conversion, release scripts, registry publication, and external package mutation remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GRAYPNG-03 | Generated Gray8 cases prove public eager decode fidelity, caller-buffered eager-byte identity under zero/one/ragged capacities, frozen RGB/RGBA compatibility, and independent js/wasm/wasm-gc/native execution. | Reuse the existing Gray8 image factories, public eager/decode oracles, chunk-drain helper, and frozen compatibility fixtures; execute the same `png` package suite once per target. [VERIFIED: local source] |
</phase_requirements>

## Summary

Phase 46 is a test-only evidence phase. The production package already exposes the exact public eager surface required by the locked decision: `PngEncoder::new_gray8_with_strategies`, and the caller-buffered equivalent `PngChunkEncoder::new_gray8_with_strategies`; both force the Gray8/non-interlaced profile. [VERIFIED: modules/mb-image/png/png.mbt; modules/mb-image/png/stream_encode.mbt] The existing tests also already provide a complete-input public `PngDecoder::new` round-trip oracle and a general drain helper that creates caller-owned leases, copies accepted bytes only, and validates cumulative `total_written`. [VERIFIED: modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt]

Use a single small, deterministic **5×3** Gray8 pattern (15 unequal values, with a mixture of horizontal and vertical changes) for every compression/filter pair. This is sufficient to exercise multi-row adaptive filtering without making the four target runs expensive. [ASSUMED] Put the eager fidelity case beside the existing eager Gray8 tests in `encode_test.mbt`; put chunk parity, zero/one/ragged schedules, and the pre-existing frozen RGB/RGBA byte cases together in `stream_encode_test.mbt`. [VERIFIED: modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt]

**Primary recommendation:** Add two focused black-box tests plus one small shared Gray8 pattern helper; do not alter `png.mbt`, `stream_encode.mbt`, package metadata, scripts, or fixtures. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Generate Gray8 source and assert eager decode fidelity | Test package | Portable PNG API | The test owns deterministic data and assertions; only public `PngEncoder`, `PngDecoder`, `ImageEncoder`, and `ImageDecoder` perform codec work. [VERIFIED: modules/mb-image/png/encode_test.mbt] |
| Drain caller-buffered output under hostile capacities | Test package | Portable PNG API | The test helper owns caller leases and progress accounting; `PngChunkEncoder::pull` remains the public operation under test. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |
| Retain RGB8/RGBA8 compatibility | Test package | Portable PNG API | Existing literal byte baselines guard public factory output without modifying encoder implementation. [VERIFIED: modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt] |
| Execute portability evidence | MoonBit test runner | js / wasm / wasm-gc / native targets | The package declares all four supported targets, and each target must execute the same `png` package suite independently. [VERIFIED: modules/mb-image/png/moon.pkg; modules/mb-image/moon.mod.json; .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models are MoonBit-first; native remains primary while portable targets use capability boundaries and conformance tests. [VERIFIED: AGENTS.md]
- Public package dependencies must be acyclic and explicitly documented; public API stability follows Semantic Versioning once stable. [VERIFIED: AGENTS.md]
- Automation must be deterministic and GUI-independent; benchmarks require declared/reproducible workloads; architectural changes require RFCs. [VERIFIED: AGENTS.md]
- Repository changes must follow a GSD workflow; this Phase 46 boundary permits test/evidence artifacts only, not production/API/script/package-publication changes. [VERIFIED: AGENTS.md; .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why standard |
|----------------|---------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`) | Compile and execute the existing `png` package tests per portable target. | It is the installed project toolchain and the repository’s established test command. [VERIFIED: local CLI; AGENTS.md] |
| `tchivs/mb-image/png` package | workspace `0.1.0` | Existing public encoder/decoder and test package. | It declares `+js+wasm+wasm-gc+native` and contains the required public evidence helpers. [VERIFIED: modules/mb-image/moon.mod.json; modules/mb-image/png/moon.pkg] |

### Supporting

| Existing helper / surface | Purpose | Use in Phase 46 |
|---------------------------|---------|-----------------|
| `png_encode_gray8_image` | Creates a packed U8, one-channel `ChannelOrder::Gray` image with canonical metadata. | Extend or reuse it for eager Gray8 generated input. [VERIFIED: modules/mb-image/png/encode_test.mbt] |
| `png_stream_gray8_image` | Creates the equivalent stream-test Gray8 source. | Add the same deterministic 5×3 pattern through this helper or a local thin pattern wrapper. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |
| `png_filter_strategy_decode_matches_source` | Decodes bytes through `PngDecoder::new` and compares dimensions, channel count, and every component. | Reuse directly for the eager fidelity assertion; it is already black-box/public-API based. [VERIFIED: modules/mb-image/png/encode_test.mbt] |
| `png_stream_test_fixed_or_stored_corpus_decode_matches_source` | Equivalent complete-input descriptor/component decoder oracle in stream tests. | Use if chunk evidence also needs a decode assertion; otherwise byte identity plus eager fidelity is enough for GRAYPNG-03. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |
| `png_chunk_test_drain_encoder` | Cycles arbitrary capacities, appends only accepted bytes, checks `total_written`, and stops only on finished/error. | Reuse unmodified for zero/one/ragged Gray8 schedules. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |

**Installation:** None — Phase 46 adds no external package. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
deterministic Gray8 samples
          |
          v
png_*_gray8_image helper --> public PngEncoder::new_gray8_with_strategies
          |                                  |
          |                                  v
          |                           eager PNG bytes
          |                                  |
          |                                  v
          |                         public PngDecoder::new
          |                                  |
          |                                  v
          +-------------------------- descriptor + per-sample comparison

same Gray8 source --> public PngChunkEncoder::new_gray8_with_strategies
                                      |
                                      v
             png_chunk_test_drain_encoder([0], [1], [0,8,4,1,13,2,5,3,21])
                                      |
                                      v
                    accepted-byte collection + total_written checks
                                      |
                                      v
                             equality with eager PNG bytes
```

### Recommended Project Structure

```text
modules/mb-image/png/
├── encode_test.mbt          # eager Gray8 generation + public decoder fidelity
├── stream_encode_test.mbt   # public chunk schedules + RGB/RGBA frozen bytes
├── png.mbt                  # unchanged public eager API
└── stream_encode.mbt        # unchanged public chunk API
```

### Pattern 1: Public eager fidelity oracle

**What:** Construct a deterministic Gray8 `OwnedImage`, encode with each selected public strategy pair, then decode via `@codec.ImageDecoder::decode(PngDecoder::new(), ...)` and compare width, height, one-channel format, and every byte. [VERIFIED: modules/mb-image/png/encode_test.mbt]

**When to use:** Once for all six combinations of `Stored`/`FixedOrStored`/`DynamicOrFixedOrStored` × `None`/`Adaptive`. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

```moonbit
// Local pattern: follow png_filter_strategy_decode_matches_source.
let source = png_encode_gray8_image(gray_pattern, width=5UL, height=3UL)
for compression in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let (_, writer) = png_encode_with(
      PngEncoder::new_gray8_with_strategies(compression, filter), source,
    )
    png_filter_strategy_decode_matches_source(png_encode_prefix(writer), source)
  }
}
```

### Pattern 2: Accepted-byte hostile-capacity parity

**What:** Build a fresh public `PngChunkEncoder` for each strategy pair and drain it with a schedule; compare the returned bytes to the matching eager bytes. The helper’s `total_written == output.length()` guard proves that only accepted bytes were collected. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

**When to use:** Run separately for `[0UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

```moonbit
// Local pattern: reuse png_chunk_test_drain_encoder unchanged.
let eager = png_stream_gray8_eager_with_strategies(source, compression, filter)
let chunked = png_chunk_test_drain_encoder(
  PngChunkEncoder::new_gray8_with_strategies(
    source.view(), compression, filter, png_stream_test_limits(),
    png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(),
  schedule,
).unwrap()
inspect(chunked == eager, content="true")
```

### Anti-Patterns to Avoid

- **Private-machine evidence:** Do not instantiate or assert against `PngEncodeMachine`, a profile enum, DEFLATE internals, or raw filter internals; GRAYPNG-03 requires public black-box evidence. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]
- **New streaming harness:** Do not duplicate drain/progress logic or stage image-sized output; the existing drain helper is the test’s correct ownership boundary. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md; modules/mb-image/png/stream_encode_test.mbt]
- **Opaque Gray8 golden PNG:** Do not make a new binary snapshot the Gray8 fidelity oracle; the decoded per-pixel comparison catches semantically wrong output across strategy choices. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Gray8 source construction | A second descriptor/metadata builder | Existing `png_encode_gray8_image` / `png_stream_gray8_image` helpers | They already create packed U8 Gray images with the required metadata and write each sample through the image view. [VERIFIED: modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt] |
| Decoder comparison | PNG parser or byte-layout assertion | Existing public decode component oracle | It checks dimensions, channel count, and every component after a complete public decode. [VERIFIED: modules/mb-image/png/encode_test.mbt] |
| Chunk scheduler | New lease/progress driver | `png_chunk_test_drain_encoder` | It creates caller-owned leases, copies only `written()` bytes, and validates total progress on every turn. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |
| Compatibility baseline | New fixture generator or new format fixture | Existing RGB8 / straight-RGBA8 literal byte fixtures | The locked decision explicitly retains these fixtures in the portable test scope. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md; modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt] |

## Common Pitfalls

### Pitfall 1: Proving only PNG framing rather than source fidelity

**What goes wrong:** A color-type/header assertion can pass while samples, dimensions, or output order are wrong. [VERIFIED: modules/mb-image/png/encode_test.mbt]

**How to avoid:** Use the existing complete-input public decoder and compare width, height, channel count, and every restored component for all six Gray8 strategy/filter combinations. [VERIFIED: modules/mb-image/png/encode_test.mbt; .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

### Pitfall 2: A zero-capacity schedule that never completes

**What goes wrong:** `[0UL]` correctly reports `NeedOutput` with zero progress, so a drain loop using only zero capacity cannot reach `Finished`. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

**How to avoid:** Use `[0UL]` only for the dedicated one-pull zero-capacity assertion, or make the schedule zero-prefixed and eventually positive, such as `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]`; keep `[1UL]` as the hostile completion schedule. [ASSUMED]

### Pitfall 3: Accidentally losing frozen compatibility coverage

**What goes wrong:** Replacing the existing RGB/RGBA compatibility tests with Gray8-specific checks would stop guarding legacy bytes. [VERIFIED: modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt]

**How to avoid:** Retain the existing eager and stream frozen RGB8/straight-RGBA8 literal cases in the same package test scope; add Gray8 assertions adjacent to them rather than refactoring them. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

### Pitfall 4: Treating `--target all` as the required evidence record

**What goes wrong:** The locked decision requires independently recorded commands/results for each target, not only one aggregate invocation. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

**How to avoid:** Invoke the four exact commands below as four distinct execution records in the implementation summary and verification artifact. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]

## State of the Art

| Old evidence boundary | Current Phase 46 boundary | Impact |
|-----------------------|---------------------------|--------|
| Phase 45 verifies Gray8 factory/path/admission/replay behavior, including ordinary positive-capacity parity. | Phase 46 adds generated public decode fidelity plus zero/one/ragged parity and per-target execution evidence. | Completes GRAYPNG-03 without reopening the already verified encoder implementation. [VERIFIED: .planning/phases/45-bounded-gray8-encoder-path/45-VERIFICATION.md; .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A 5×3 mixed-value Gray8 pattern is the smallest useful readable input that exercises multi-row adaptive selection and compression. | Summary / Pattern 1 | Tests may be weaker than intended, though public fidelity/parity requirements remain covered. |
| A2 | A zero-only schedule should be a dedicated `NeedOutput` assertion, while zero-prefixed ragged and one-byte schedules demonstrate completion. | Common Pitfalls | A plan could otherwise specify a non-terminating drain case. |

## Open Questions

None for planning. The implementation must record actual pass/fail results for every independent target command; this research run did not complete all four full invocations because the combined local execution exceeded the environment’s 64-second command limit before producing a result. [VERIFIED: local CLI]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | Independent package test execution | ✓ | `0.1.20260713` (`75c7e1f`) | None; this is the required MoonBit toolchain. [VERIFIED: local CLI] |
| js target runtime | `--target js` package test | Not independently confirmed in this research run | — | No fallback; record the command result during execution. [VERIFIED: local CLI] |
| wasm target runtime | `--target wasm` package test | Not independently confirmed in this research run | — | No fallback; record the command result during execution. [VERIFIED: local CLI] |
| wasm-gc target runtime | `--target wasm-gc` package test | Not independently confirmed in this research run | — | No fallback; record the command result during execution. [VERIFIED: local CLI] |
| native target runtime | `--target native` package test | Previously passed 179/179 in Phase 45 verification | — | No fallback; re-run after Phase 46 test changes. [VERIFIED: .planning/phases/45-bounded-gray8-encoder-path/45-VERIFICATION.md] |

**Exact independent execution commands:**

```powershell
moon -C modules/mb-image test png --target js --frozen
moon -C modules/mb-image test png --target wasm --frozen
moon -C modules/mb-image test png --target wasm-gc --frozen
moon -C modules/mb-image test png --target native --frozen
```

**MoonBit portability pitfalls:**

- Keep the evidence entirely in ordinary `*_test.mbt` package tests and use only the portable public API; `moon.pkg` declares the four supported targets, while target-specific stubs/host APIs would undermine the intended proof. [VERIFIED: modules/mb-image/png/moon.pkg; .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md]
- Use fixed `UInt64` capacities/sizes and existing `Bytes`/`OwnedBytes` helpers; do not add target-specific filesystem, shell, FFI, or host-buffer dependencies. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt; AGENTS.md]
- Instantiate a fresh chunk encoder per schedule/strategy because it is stateful; do not drain one encoder twice and compare the second terminal state to eager output. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication is added by a local deterministic codec regression test. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md] |
| V3 Session Management | no | No session state is added. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md] |
| V4 Access Control | no | No access-control boundary is added. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md] |
| V5 Input Validation | yes | Preserve complete-input public decoder invocation and deterministic owned-byte test inputs; no new parser is introduced. [VERIFIED: modules/mb-image/png/encode_test.mbt] |
| V6 Cryptography | no | No cryptographic behavior is added. [VERIFIED: .planning/phases/46-portable-gray8-public-evidence/46-CONTEXT.md] |

### Known Threat Patterns for this scope

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Partial-output/progress accounting regression | Tampering | Zero/one/ragged public chunk drains verify only accepted bytes are collected and cumulative progress matches them. [VERIFIED: modules/mb-image/png/stream_encode_test.mbt] |
| Legacy output compatibility regression | Tampering | Retain frozen RGB8 and straight-RGBA8 public byte fixtures in the same package test scope. [VERIFIED: modules/mb-image/png/encode_test.mbt; modules/mb-image/png/stream_encode_test.mbt] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` — MoonBit/native/portability, automation, modularity, and workflow constraints. [VERIFIED: AGENTS.md]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `46-CONTEXT.md` — Phase goal, GRAYPNG-03 acceptance boundary, and locked implementation decisions. [VERIFIED: local planning artifacts]
- `45-VERIFICATION.md` — completed bounded Gray8 invariants and native baseline evidence. [VERIFIED: local planning artifact]
- `modules/mb-image/png/{png.mbt,stream_encode.mbt,encode_test.mbt,stream_encode_test.mbt,moon.pkg}` — exact public APIs, helpers, compatibility fixtures, targets, and test patterns. [VERIFIED: local source]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — the installed MoonBit toolchain and workspace package declarations were inspected locally. [VERIFIED: local CLI; modules/mb-image/moon.mod.json; modules/mb-image/png/moon.pkg]
- Architecture: HIGH — all recommended seams are existing public APIs/test helpers in the current package. [VERIFIED: local source]
- Pitfalls: HIGH except A1/A2 — the zero-capacity/progress and legacy-fixture behavior is source-grounded; proposed compact dimensions/scheduling placement are explicitly assumed. [VERIFIED: local source]

**Research date:** 2026-07-22
**Valid until:** Phase 46 implementation changes the listed tests or public API.
