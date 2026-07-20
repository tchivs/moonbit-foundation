# Phase 11: Portable Processing Pipeline Evidence - Research

**Researched:** 2026-07-20  
**Domain:** portable public PPM decode → geometry/raster processing → encode evidence and local benchmark baselines  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Pipeline evidence
- **D-01:** The public example must use the real strict PPM decoder and encoder, and compose at least one Phase 9 geometry operation with one Phase 10 raster operation in one deterministic in-memory pipeline.
- **D-02:** The example uses only documented, representable straight RGBA8/sRGB metadata and compatible inputs so it proves successful normal use rather than a synthetic internal shortcut.
- **D-03:** Expected encoded bytes or digest plus semantic pixel assertions make the example deterministic across js, wasm, wasm-gc, and native.

### Test and benchmark evidence
- **D-04:** Public behavior and adversarial tests must run on all four supported targets and cover the composed processing pipeline plus at least one failure boundary.
- **D-05:** Benchmark workloads are explicit, reproducible and local: declared image dimensions, operation sequence, iteration/warm-up policy, toolchain/target, and recorded baseline. No performance marketing claims are added.
- **D-06:** Benchmarking must not require registry, credentials, GUI state, hosted workflows, or release scripts.

### the agent's Discretion
- Reuse or extend the portable PPM example versus adding a narrowly named processing example according to the existing examples layout.
- Select the smallest benchmark harness and output format consistent with existing `benchmarks/` conventions.

### Deferred Ideas (OUT OF SCOPE)

- New codecs, GPU acceleration, optimized kernels, registry publication, and GUI workflows remain outside Phase 11.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTEG-01 | One public example composes geometry/raster operations before PPM encoding. | Rework the existing portable in-memory executable around two strict PPM inputs, explicit conversion, resize, opaque source-over, strict RGBA→RGB, and the existing public encoder. |
| INTEG-02 | Public behavioral/adversarial tests validate the new API on js, wasm, wasm-gc, native. | Add a direct pipeline public test plus a white-box failure/unchanged-budget test; run the existing `ops` package and portable example on all four targets. |
| INTEG-03 | Reproducible resize-and-compositing local benchmark baseline. | Add one native-only named public-API workload and a Phase-11-local, recorded 1-warmup/7-capture baseline that never calls release scripts. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Core algorithms, shared models, and this proof flow remain MoonBit-native; do not replace them with foreign runtime code. [VERIFIED: AGENTS.md]
- Portable package evidence must cover `js`, `wasm`, `wasm-gc`, and `native`; native is preferred but is not a substitute for the other three. [VERIFIED: AGENTS.md; modules/mb-image/ops/moon.pkg]
- Public packages must keep acyclic, documented dependencies. The example and benchmark are consumers of existing public packages, so no new module edge is justified. [VERIFIED: AGENTS.md; modules/mb-image/README.mbt.md]
- Prefer Codebase Knowledge Graph MCP tools for code discovery; it was not exposed to this agent, so repository reads used the allowed fallback for non-code manifests/docs and direct known-file inspection. [VERIFIED: AGENTS.md; runtime tool availability]
- Do not touch release automation, publication/registry work, or pre-existing untracked files. [VERIFIED: parent task; 11-CONTEXT.md]

## Summary

Extend `examples/ppm-portable/main/main.mbt`; do not add a second example. It is already the public, four-target, in-memory consumer of the strict PPM decoder and encoder. Its present flip-only route proves the codec boundary, but Phase 11 needs the real public conversion bridge because PPM decodes to RGB8 while `@ops.composite_source_over` accepts only straight RGBA8. The smallest successful route is: decode two strict opaque PPM P6 inputs; resize the 1×1 foreground to 2×1; convert foreground and background RGB8 images with `@ops.rgb8_to_straight_rgba8`; composite foreground over background; convert with `@ops.straight_rgba8_to_rgb8`; encode with `@ppm.PpmEncoder`. All images retain builtin sRGB, TopLeft orientation, and empty opaque metadata created by PPM decode, satisfying the composite metadata gate. [VERIFIED: examples/ppm-portable/main/main.mbt; modules/mb-image/README.mbt.md; modules/mb-image/ops/pkg.generated.mbti; modules/mb-image/ops/processing.mbt]

Use opaque foreground bytes so the source-over result has alpha `0xff` and strict RGBA8→RGB8 succeeds without loss. A compact determinism vector is foreground `P6\n1 1\n255\n\x0c\x22\x38` over any valid 2×1 background: after nearest resize and source-over, the encoded result must be exactly `50 36 0a 32 20 31 0a 32 35 35 0a 0c 22 38 0c 22 38` (17 bytes), rolling-257 digest `9386158`, and SHA-256 `cf8f36752d62cd88334bfa8fc45c55bdbf0f70275180bc6d2b14bf3810676464`. Assert both output pixels `[0x0c, 0x22, 0x38]`, dimension `2×1`, decoded/encoded byte counts, diagnostic emptiness, and full encoded byte/digest—not the digest alone. [VERIFIED: current PPM header contract in modules/mb-image/README.mbt.md; locally recomputed deterministic vector]

The legacy benchmark capture harness is explicitly release qualification: it writes to `release/qualification/`, validates eight fixed workloads, and invokes a native release command. Do not extend it in this phase. Reuse its evidence vocabulary only in a Phase-11-local baseline: native release target, frozen dependencies, one untimed warmup, seven captured invocations, per-run console text, tool/environment identity, source and correctness digests, and non-marketing claim. The benchmark implementation itself belongs in existing `benchmarks/ppm/ppm_bench.mbt`; its recorded Phase-11 baseline belongs outside `release/qualification/` and is run directly with `moon -C benchmarks bench --release --target native --frozen ppm`. [VERIFIED: scripts/benchmarks/Invoke-PpmBenchmarks.ps1; release/qualification/ppm-native-release-baseline.json; benchmarks/ppm/ppm_bench.mbt; 11-CONTEXT.md]

**Primary recommendation:** Reuse the portable PPM example, make the RGB↔straight-RGBA bridges explicit, add one direct composed-pipeline test plus one resource/error test, and add a separate local-native `resize-composite` benchmark record without changing release qualification automation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PPM input/output | Portable library API (`ppm`/`codec`) | In-memory I/O | Decoder/encoder operate on public Reader/Writer; the example supplies memory implementations. [VERIFIED: examples/ppm-portable/main/main.mbt; modules/mb-image/codec/pkg.generated.mbti] |
| Geometry | Portable library API (`ops`) | Storage | `resize_nearest` owns checked mapping and output allocation. [VERIFIED: modules/mb-image/ops/pkg.generated.mbti; 09-VERIFICATION.md] |
| RGBA conversion and compositing | Portable library API (`ops`) | Color contracts | Conversion makes PPM RGB representable to the strict straight-RGBA compositing boundary; source-over owns the processing result. [VERIFIED: modules/mb-image/ops/convert.mbt; modules/mb-image/ops/processing.mbt] |
| Result proof | Public executable + public tests | White-box adversarial tests | Executable proves consumer flow; tests prove exact bytes and error/budget behavior. [VERIFIED: examples/ppm-portable/main/main.mbt; modules/mb-image/ops/*_test.mbt] |
| Local timing evidence | Native benchmark consumer | Static Phase-11 baseline record | Timing belongs in native `@bench.T`; correctness must be checked before timing. [VERIFIED: benchmarks/ppm/ppm_bench.mbt; scripts/benchmarks/Invoke-PpmBenchmarks.ps1] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `tchivs/mb-image/ppm` | workspace `0.1.0` | Strict PPM P6 decode/encode | Required real public codec path; emits tight RGB8 P6 only. [VERIFIED: modules/mb-image/moon.mod.json; modules/mb-image/README.mbt.md] |
| `tchivs/mb-image/codec` | workspace `0.1.0` | Typed public decode/encode invocation | Existing options, limits, diagnostics, and byte-count result path. [VERIFIED: modules/mb-image/codec/pkg.generated.mbti] |
| `tchivs/mb-image/ops` | workspace `0.1.0` | resize, RGB/RGBA conversion, source-over | Provides every transform required without adding a new API or dependency. [VERIFIED: modules/mb-image/ops/pkg.generated.mbti] |
| `moonbitlang/core/bench` | pinned Moon toolchain built-in | Native local benchmark harness | Existing benchmark uses `@bench.T`, `keep`, and named tests. [VERIFIED: benchmarks/ppm/moon.pkg; benchmarks/ppm/ppm_bench.mbt] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tchivs/mb-core/budget` | workspace `0.1.0` | Per-operation resource caps | Give every decode/resize/conversion/composite/encode allocation a separate sufficient caller budget. [VERIFIED: examples/ppm-portable/main/main.mbt; benchmarks/ppm/ppm_bench.mbt] |
| `tchivs/mb-core/bytes`, `io`, `error` | workspace `0.1.0` | In-memory owned bytes, readers/writers, diagnostics | Reuse existing portable example helpers; no filesystem/CLI state belongs in the public flow. [VERIFIED: examples/ppm-portable/main/main.mbt] |

**Installation:** None—this phase adds no external package. [VERIFIED: moon.work; existing manifests]

## Architecture Patterns

### System Architecture Diagram

```text
foreground PPM P6 (1×1, opaque RGB8) ──decode──> RGB8 ──resize_nearest 2×1──> RGB8
                                                                         │
background PPM P6 (2×1, opaque RGB8) ──decode──> RGB8 ──rgb8_to_straight_rgba8──> RGBA8
                                                                         │
foreground RGB8 ──rgb8_to_straight_rgba8──> RGBA8 ──source_over─────────┘
                                                               │
                                                   strict RGBA8_to_RGB8
                                                               │
                                     PpmEncoder + MemoryWriter ──> P6 bytes/digest/pixels
```

### Recommended Project Structure

```text
examples/ppm-portable/
└── main/main.mbt                         # modify the existing public four-target proof
modules/mb-image/ops/
├── processing_pipeline_test.mbt          # public composition/bytes behavior
└── processing_pipeline_wbtest.mbt        # malformed/resource boundary, independent assertions
benchmarks/ppm/
└── ppm_bench.mbt                         # add native resize+composite workload only
benchmarks/ppm/
└── phase-11-resize-composite-baseline.md # tracked local evidence format; not release qualification
```

### Pattern 1: explicit representation bridge

**What:** PPM gives RGB8, `composite_source_over` demands straight RGBA8, PPM encode demands RGB8. Use these exact public calls in order:

```moonbit
let resized = @ops.resize_nearest(foreground.image().view(), 2UL, 1UL, resize_budget).unwrap()
let source_rgba = @ops.rgb8_to_straight_rgba8(resized.image().view(), source_convert_budget).unwrap()
let destination_rgba = @ops.rgb8_to_straight_rgba8(background.image().view(), destination_convert_budget).unwrap()
let composite = @ops.composite_source_over(source_rgba.image().view(), destination_rgba.image().view(), composite_budget).unwrap()
let encodable = @ops.straight_rgba8_to_rgb8(composite.image().view(), rgb_budget).unwrap()
```

**When to use:** Always when a strict PPM image participates in Phase-10 compositing. Do not bypass conversion by constructing storage directly. [VERIFIED: modules/mb-image/ops/pkg.generated.mbti; modules/mb-image/ops/convert.mbt; modules/mb-image/ops/processing.mbt]

### Pattern 2: opaque vector for lossless PPM output

**What:** Use an opaque foreground so `source-over` produces opaque alpha, which makes `straight_rgba8_to_rgb8` admissible and lossless. The vector above has an intentionally simple semantic oracle: both output RGB pixels equal the resized foreground. [VERIFIED: modules/mb-image/ops/convert.mbt; modules/mb-image/ops/processing_test.mbt]

### Pattern 3: correctness before `@bench.T`

**What:** Construct deterministic PPM bytes outside the measured closure, run public decode → resize → RGB-to-RGBA → source-over (and optional strict RGB conversion) once, validate output extent/digest, then measure exactly the same `pipeline_public` operation via `it.bench(fn() { it.keep(...) }, count=1)`. [VERIFIED: benchmarks/ppm/ppm_bench.mbt]

**Benchmark workload:** name `ppm/pipeline/resize-composite/256x256`; source foreground is deterministic 128×128 PPM resized nearest to 256×256; destination is deterministic 256×256 PPM; both have opaque RGB values; all processing uses fresh budgets. The measured closure must include decode and all named resize/conversion/composite operations, because that is the public pipeline the requirement asks to baseline. [VERIFIED: benchmarks/ppm/ppm_bench.mbt; 11-CONTEXT.md]

### Anti-Patterns to Avoid

- **Flip-only example:** Existing flip flow does not exercise Phase-10 raster processing. Replace its transform, rather than presenting it as the Phase-11 proof. [VERIFIED: examples/ppm-portable/main/main.mbt; 11-CONTEXT.md]
- **Direct storage construction:** It would evade real decoder/encoder and public conversion contracts. [VERIFIED: 11-CONTEXT.md]
- **Compositing RGB8 images:** It must fail at the published capability boundary; convert explicitly. [VERIFIED: modules/mb-image/ops/processing.mbt]
- **Translucent output to PPM:** Strict RGBA→RGB rejects non-opaque alpha; choose opaque inputs for this proof or assert the typed rejection in an adversarial test. [VERIFIED: modules/mb-image/ops/convert.mbt]
- **Changing `Invoke-PpmBenchmarks.ps1`, `release/qualification/*`, or its fixed eight-workload baseline:** Those files constitute deferred release qualification, not Phase-11 local evidence. [VERIFIED: parent task; scripts/benchmarks/Invoke-PpmBenchmarks.ps1]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PPM parsing/serialization | Custom header/raster handling in example or benchmark | `@ppm.PpmDecoder` / `@ppm.PpmEncoder` through codec traits | Existing strict parser, limits, EOF rule, and diagnostics must remain on the public route. [VERIFIED: modules/mb-image/README.mbt.md; examples/ppm-portable/main/main.mbt] |
| RGBA metadata/image construction | Hand-built descriptor just to composite | `@ops.rgb8_to_straight_rgba8` | It preserves the existing capability/allocation/disposition semantics. [VERIFIED: modules/mb-image/ops/convert.mbt] |
| Resize or blend oracle | Reimplement production mapping/blending in example | Exact opaque pixel assertions plus existing independent white-box tests | The example needs consumer evidence; adversarial calculations belong in `*_wbtest.mbt`. [VERIFIED: 09-VERIFICATION.md; 10-VERIFICATION.md] |
| Benchmark timer/parser/qualification gate | New timing framework or changes to release harness | `@bench.T` with a small tracked local record | Existing Moon benchmark convention handles timing; Phase 11 must not create release automation. [VERIFIED: benchmarks/ppm/ppm_bench.mbt; 11-CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: Under-budgeting the composed pipeline
**What goes wrong:** A single reused budget is consumed by decode or an earlier transform and later fails, hiding whether a particular public operation works.  
**How to avoid:** Give each decode/resize/conversion/composite/encode operation a new bounded budget sized for exactly one output; keep input-byte/writer budgets separate. [VERIFIED: examples/ppm-portable/main/main.mbt; modules/mb-image/ops/convert.mbt]

### Pitfall 2: Composite metadata mismatch
**What goes wrong:** Source-over returns typed `InvalidRange` before allocation because profiles/orientations/opaque metadata are incompatible.  
**How to avoid:** Use both decoder outputs unchanged except for geometry/conversion, with built-in sRGB, TopLeft, empty opaque metadata. Add one adversarial test with a mismatching dimension or non-opaque conversion output and assert error plus unchanged budget. [VERIFIED: modules/mb-image/ops/processing.mbt; modules/mb-image/ops/processing_test.mbt]

### Pitfall 3: Digest-only evidence
**What goes wrong:** A digest detects most drift but does not make a small example intelligible or diagnose a changed header/pixel.  
**How to avoid:** Assert byte count, exact 17-byte result (or SHA-256), output dimensions, and both semantic RGB triples; print a stable rolling digest only as concise executable output. [VERIFIED: examples/ppm-portable/main/main.mbt; 11-CONTEXT.md]

### Pitfall 4: Baseline capture coupled to release qualification
**What goes wrong:** Adding the new workload to the old harness breaks its fixed workload order/schema and turns a local evidence task into deferred release automation.  
**How to avoid:** Leave the release harness untouched. Record the Phase-11 workload separately with source/correctness digests, toolchain/environment, one warmup, seven raw captures, aggregates, and the exact non-marketing scope statement. [VERIFIED: scripts/benchmarks/Invoke-PpmBenchmarks.ps1; release/qualification/benchmark-schema.json]

## Code Examples

### Four-target public executable commands

```powershell
moon -C examples/ppm-portable run main --target js --frozen
moon -C examples/ppm-portable run main --target wasm --frozen
moon -C examples/ppm-portable run main --target wasm-gc --frozen
moon -C examples/ppm-portable run main --target native --frozen
```

Current pre-Phase-11 portable consumer passes all four commands with the same line and rolling digest `806175100`; replace the asserted line/digest with the composed-pipeline vector rather than creating target-specific output. [VERIFIED: local command execution, 2026-07-20]

### Cross-target operations and documentation

```powershell
moon test modules/mb-image/ops --target js --frozen
moon test modules/mb-image/ops --target wasm --frozen
moon test modules/mb-image/ops --target wasm-gc --frozen
moon test modules/mb-image/ops --target native --frozen
moon -C modules/mb-image check README.mbt.md --target js --frozen
moon -C modules/mb-image check README.mbt.md --target wasm --frozen
moon -C modules/mb-image check README.mbt.md --target wasm-gc --frozen
moon -C modules/mb-image check README.mbt.md --target native --frozen
```

Current operations suite is `35/35` on every target and all documentation checks exit successfully. [VERIFIED: local command execution, 2026-07-20]

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Existing example: strict PPM decode → horizontal flip → encode. | Phase 11 evidence: two strict decodes → nearest resize → RGB/RGBA bridges → source-over → strict RGB bridge → encode. | Proves both Phase 9 and Phase 10 public APIs on the real codec path. [VERIFIED: examples/ppm-portable/main/main.mbt; 11-CONTEXT.md] |
| Existing benchmark pipeline: decode → flip → encode. | Add a separate named resize+composite workload with correctness gating before timing. | Meets INTEG-03 without claiming performance or changing release qualification. [VERIFIED: benchmarks/ppm/ppm_bench.mbt; 11-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `benchmarks/ppm/phase-11-resize-composite-baseline.md` is the preferred tracked filename/location for the new local record. | Recommended project structure | Naming/location can be changed without altering the implementation; it must remain outside `release/qualification/`. |

## Open Questions

1. **Baseline record filename and serialization**
   - What we know: the historical record is JSON with a closed release schema; Phase 11 must not modify that schema/harness. [VERIFIED: release/qualification/benchmark-schema.json; parent task]
   - What's unclear: whether maintainers prefer Markdown plus raw captured text, or a new Phase-11-local JSON schema.
   - Recommendation: use a concise tracked Markdown record with an explicit field table and links/filenames for seven captured local outputs; it mirrors the facts without importing release qualification machinery. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | four-target executable/test/doc checks and native bench | ✓ | `0.1.20260713 (75c7e1f, 2026-07-13)` | — |
| `moonc` | compiler identity in baseline | ✓ | `v0.10.4+2cc641edf (2026-07-15)` | — |
| `moonrun` | target runner identity | ✓ | `0.1.20260713 (75c7e1f, 2026-07-13)` | — |
| Native C toolchain | native check/test/bench target | ✓ | native test and run completed | no fallback; all four targets remain required |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Real strict PPM decoder limits, complete-input option, resize/conversion/composite capability gates, typed diagnostics. [VERIFIED: examples/ppm-portable/main/main.mbt; modules/mb-image/ops/processing.mbt] |
| V4 Access Control | no | No identity, authorization, or externally reachable service boundary. [VERIFIED: Phase 11 scope] |
| V6 Cryptography | no | Digest is deterministic evidence, not an authenticity/security control. [VERIFIED: example digest implementation] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed PPM / oversized declared raster | Denial of service | Strict decoder parser/codec limits, complete input, and caller budget. [VERIFIED: modules/mb-image/README.mbt.md; examples/ppm-portable/main/main.mbt] |
| Oversized resize/intermediate allocations | Denial of service | Independent checked operation budgets and typed budget failures before allocation. [VERIFIED: 09-VERIFICATION.md; modules/mb-image/ops/resize.mbt] |
| Incompatible source-over representation/metadata | Tampering | Explicit RGB→straight-RGBA conversion and composite's typed capability/metadata rejection. [VERIFIED: modules/mb-image/ops/convert.mbt; modules/mb-image/ops/processing.mbt] |

## Sources

### Primary (HIGH confidence)
- `examples/ppm-portable/main/main.mbt`, its manifest, and four local target executions — present public consumer structure and portable command proof.
- `modules/mb-image/README.mbt.md`, `ops/pkg.generated.mbti`, `convert.mbt`, and `processing.mbt` — exact codec/operation contract and representation boundaries.
- `09-VERIFICATION.md` and `10-VERIFICATION.md` — verified geometry, deterministic error, compositing/filter, and four-target predecessor evidence.
- `benchmarks/ppm/ppm_bench.mbt`, `scripts/benchmarks/Invoke-PpmBenchmarks.ps1`, and `release/qualification/ppm-native-release-baseline.json` — existing benchmark execution and record conventions.

### Secondary (MEDIUM confidence)
- None; no external package or framework is introduced.

### Tertiary (LOW confidence)
- A1 only; it is intentionally isolated from code/API decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs, manifests, commands, and toolchain versions were locally inspected/executed.
- Architecture: HIGH — exact public signatures force the RGB↔RGBA route and existing example/benchmark layout supports the proposed file placement.
- Pitfalls: HIGH — conversion and metadata failure behavior are implemented and prior phases verified them; benchmark boundary is explicit in scope and existing release harness.

**Research date:** 2026-07-20  
**Valid until:** Until Phase 11 changes the listed public example/benchmark/API files.
