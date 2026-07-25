# Feature Landscape: v0.30 SVG Production Readiness

**Domain:** Portable, bounded SVG parse-to-canvas lowering in `mb-svg`
**Researched:** 2026-07-25
**Confidence:** HIGH for the milestone boundary and current implementation; MEDIUM for external SVG/MoonBit corroboration because the configured documentation/search providers were unavailable and official pages were consulted through the web-search fallback.

## Product Boundary

v0.30 turns the already-delivered portable `mb-svg` subset into a more trustworthy production foundation. It adds three evidence-and-safety capabilities only: fixed public benchmark workloads, fail-closed admission of unsafe numeric input, and four-target proof that the hardened parser and existing RFC 0008 layer semantics remain deterministic.

This is deliberately a hardening milestone, not a feature-expansion milestone. `mb-svg` already parses the in-scope scene subset, lowers it to `mb-canvas`, and uses `PushLayer`/`PopLayer` for element and group `opacity`. It already has benchmarks for a 1,000-line path, a transform list, and a 50-rect parse-to-lower document. The visible gaps are that the benchmark inputs and success criteria are not yet an explicit reproducibility contract, and numeric entry points can pass unchecked `Double` values or silently substitute defaults before lowering. RFC 0002 explicitly records checked coordinate arithmetic as the remaining v0.1 safety gap.

The production contract must be: a valid, declared SVG workload produces the same scene/lowering facts on all supported targets; an invalid or unsafe numeric value produces a structured error before any scene is returned or drawing operation is emitted; and opacity remains layer compositing rather than per-child alpha multiplication. Timing values are evidence tied to a toolchain and host, never a cross-host compatibility promise.

## Table Stakes

| Feature | Why Expected | Complexity | Testable required behavior |
|---|---|---:|---|
| Named, fixed path-parse workload | A performance claim without a stable input is not reproducible or reviewable. | Low | A public benchmark consumes one immutable in-tree path fixture with exactly 1,000 declared line-to operations (plus its initial move), validates that it parses successfully and has the declared command fact before timing, then sinks the result inside the timed closure. The benchmark name, fixture identifier/digest, command, target, and mode are documented. |
| Named, fixed transform-composition workload | Transform parsing/composition is a distinct hot path and needs a workload that detects accidental quadratic work or composition regressions. | Low | One benchmark uses a declared mixed transform list. Its name and assertions match its actual primitive count—today's “50-segment” name conflicts with a fixture that appends six transforms ten times (60 primitives). It validates a known composed affine result/invertibility before timing and sinks each parse result. |
| Named full parse-to-lower workload | Consumers use `parse_svg` followed by `lower_to_drawing_list`, not just leaf parsers. | Medium | A fixed 50-shape document with transforms and at least one opacity case parses successfully and lowers to a declared operation/stack-balance fact. An `Err(_) => keep(())` fallback is not allowed: a workload setup or parse failure fails the benchmark instead of recording a fast no-op. |
| Reproducible baseline record, not a universal speed limit | MoonBit's `@bench.T` auto-selects iterations and reports host-specific statistics; raw timings cannot be compared across arbitrary hosts. | Medium | The repository records an execution recipe (`moon -C modules/mb-svg bench svg --target ... --release --frozen`), workload IDs/digests, exact `moon`/`moonc` version, date, target, build mode, OS/CPU, and mean/deviation/range. One declared native release baseline is comparison evidence; `--target all` is a portable build-and-run qualification, not a single performance threshold. |
| Strict lexical numeric admission | SVG input is untrusted at the document boundary. Quietly defaulting malformed values can make an attacker-controlled document mean something else. | High | Numeric forms used by lengths, viewBox, geometry attributes, point lists, path data, paint numeric attributes, and transform arguments reject non-numeric tokens, `NaN`, infinities, and parse-overflow/exponent values with a structured `svg-numeric`-class error naming the field/command. No malformed numeric attribute may become `0`, an inherited value, an empty points list, or a silently omitted root field. |
| Checked numeric derivation before lowering | Finite source operands can still become unsafe through relative-coordinate addition, degree-to-radian conversion, affine composition, skew/trigonometry, viewBox scaling, or shape expansion. | High | Every value accepted into a scene and every derived coordinate/matrix component is finite and inside one documented, target-neutral safe geometry envelope. Inputs that overflow or leave that envelope during parsing/composition fail before `SceneNode` construction completes; `lower_to_drawing_list` is not called and no partial `DrawingList` is observable. |
| Exact opacity regression preservation | Group/object opacity is post-processing on an isolated group; applying alpha to each child is visibly wrong when children overlap. | Medium | A public all-target fixture with overlapping children under `<g opacity="0.5">`, and a shape with both fill and stroke under `opacity`, proves `PushLayer(opacity)`/`PopLayer` wraps the intended sequence and the rendered pixel digest plus selected overlap pixels remain exact. A control verifies `fill-opacity`/`stroke-opacity` remain per-paint semantics rather than being conflated with group opacity. |
| Portable verification and benchmark execution | The module promises `js`, `wasm`, `wasm-gc`, and `native`; native-only green output is insufficient. | Medium | `moon -C modules/mb-svg test svg --target all --frozen` exercises accepted, non-finite, overflow, composition-overflow, and opacity cases with identical structured outcome categories. `moon -C modules/mb-svg bench svg --target all --frozen` builds and successfully runs all declared benchmarks on all four targets. |

## Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---|---|---:|---|
| Correctness-gated benchmarks | Every measured operation is known to have succeeded and produced a declared result, so a regression cannot masquerade as a speedup by failing or being optimized away. | Medium | Use `@bench.T::keep` inside the closure, but perform fixture validity and semantic assertions outside it. This keeps validation from dominating measurements while rejecting invalid workload setup. |
| One safety gate shared by all numeric routes | A single policy prevents a parser fix from protecting `transform` while paths, viewBox, points, or inherited paint values still leak unsafe doubles downstream. | High | Centralize finite/envelope validation at number parsing and at checked derivation boundaries; propagate `Result` through scene builders rather than retaining local default-on-error helpers. |
| Failure-before-effect proof | The caller can rely on an unsafe SVG producing no usable partial scene/list, rather than needing to discover a poisoned `Double` during rasterization. | Medium | Test parse failure at the public `parse_svg`/`parse_svg_with_budget` boundary and separately prove a direct leaf parser rejects the same token class. Test the parse-to-lower façade only after a successful parse. |
| Portable evidence split from native comparison | Four-target execution proves portability without pretending that WebAssembly, JavaScript, and native have comparable clocks or JIT behavior. | Low | Check benchmark registration/build/run on every target; publish comparative baseline numbers only for an identified native release environment. |

## Requirement Candidates

| ID | Requirement | Acceptance evidence |
|---|---|---|
| **SVGPR-01** | `mb-svg` exposes three declared and correctness-gated public benchmark workloads: path parsing, transform composition, and parse-to-lower. Each has a stable input identifier, accurate operation cardinality, named benchmark, documented command, and reproducibility metadata. | Source-visible fixtures/benchmark names and a baseline record identify the exact workload. `moon -C modules/mb-svg bench svg --target all --frozen` reports all three workload names as passing on js, wasm, wasm-gc, and native. The native release record contains toolchain, host, command, and raw summary fields; it makes no global latency guarantee. |
| **SVGPR-02** | `mb-svg` rejects non-finite, parse-overflow, and derivation-overflow/unsafe numeric values for all in-scope geometry, length, point-list, path, transform, viewBox, and relevant paint/stroke attributes before they enter a scene or drawing list. | Public and white-box matrices cover lexical `NaN`/infinity, extreme exponent, unsafe magnitudes, relative path accumulation, transform matrix/composition, rotate/skew derivation, and viewBox-to-viewport derivation. Every rejected case has deterministic structured error category/context and proves no successful scene/list. Valid finite boundary cases remain accepted. |
| **SVGPR-03** | Numeric hardening is additive to existing RFC 0008 semantics: element/group opacity retains isolated-layer ordering and accepted SVG behavior remains portable. | Overlap-sensitive end-to-end fixture proves group and element layer placement, exact digest/semantic pixels, and separate fill/stroke opacity behavior. Legacy valid vectors remain unchanged. The SVG package suite and all benchmark workloads pass with `--target all --frozen`. |

## Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| SVG text, gradients, masks, filters, `<use>`, animation, or broader XML/CSS support | These change document semantics and public scope; none establishes numeric safety or workload reproducibility. | Retain the declared SVG subset. Open a separately scoped RFC/milestone when a consumer need exists. |
| Native-only acceleration or target-specific numeric behavior | It would undermine the portable contract and make error results/timing claims incomparable. | Keep the safety gate and benchmark sources in pure MoonBit; use native release data only as a labelled baseline. |
| Silent coercion, clamping, defaulting, or omission of invalid numeric input | It is fail-open and can turn malformed/untrusted source into a valid but unintended picture. | Return a structured numeric error at the responsible SVG boundary. Clamping remains only for already-valid rendering semantics such as the existing layer alpha contract, not parser error recovery. |
| A magic global latency threshold or one committed timing snapshot as a CI gate | Benchmark statistics depend on CPU, OS, compiler, target runtime, and measurement noise. | Gate correctness, workload identity, and all-target execution in CI; compare native baselines only within a declared like-for-like environment. |
| Image-sized layer staging or layer bounds optimization | RFC 0008 intentionally uses full-target offscreens and defers bounding-box staging; changing it mixes a performance architecture rewrite into input hardening. | Preserve current `PushLayer`/`PopLayer` behavior and test its semantics. Defer staging optimization to a dedicated canvas milestone. |
| New public canvas/image/FFI APIs | v0.30 needs no new ownership, module, or native seam to validate SVG numbers and benchmarks. | Work inside `mb-svg` and consume the existing `mb-canvas` drawing-list/layer contract. |
| Lowering/rasterizing an unsafe partial scene just to report more errors | It violates the requested fail-closed boundary and risks target-specific non-finite behavior. | Stop at the first numeric safety failure with a deterministic structured error and no partial success object. |

## Feature Dependencies

```text
stable pure-MoonBit mb-svg parser + mb-canvas layer contract
  ├─→ declared immutable workload fixtures
  │     ├─→ correctness preflight + result sink
  │     ├─→ all-target benchmark execution
  │     └─→ labelled native baseline record
  └─→ shared numeric finite/envelope policy
        ├─→ leaf number/length/list/path/transform validation
        ├─→ checked relative, affine, viewBox, and shape derivations
        └─→ Result propagation with no partial scene/list
              └─→ all-target hostile-input and opacity-regression qualification
```

## MVP Recommendation

Prioritize:

1. **Define and lock the three workload fixtures and benchmark correctness gates** — this makes the performance work reviewable immediately and exposes the current transform-cardinality mismatch.
2. **Install the shared numeric admission/derivation policy and propagate structured errors through scene construction** — this closes RFC 0002's outstanding checked-coordinate gap before any later renderer sees unsafe data.
3. **Qualify portable behavior and opacity stability** — run the hostile matrix, accepted legacy vectors, overlap-sensitive opacity fixture, ordinary tests, and benchmark runner on every target.

Defer: timing optimization, new SVG features, native acceleration, and layer staging. They would obscure the v0.30 acceptance criteria without improving its production-readiness guarantee.

## Sources

- Live local scope: [.planning/PROJECT.md](../PROJECT.md) — HIGH. Defines v0.30's three target features and explicit exclusions.
- Live local implementation: `modules/mb-svg/svg/svg_bench.mbt`, `length.mbt`, `path_data.mbt`, `transform.mbt`, `scene.mbt`, and `lower.mbt` — HIGH. Confirms current workload sizes, the transform-name mismatch, current default-on-error numeric paths, and layer lowering order.
- Live local executed evidence (2026-07-25): `moon -C modules/mb-svg test svg --target all --frozen` (84/84 on each target) and `moon -C modules/mb-svg bench svg --target all --frozen` (three workloads passed on each target) — HIGH. Timing values are intentionally not treated as portable equivalence evidence.
- [RFC 0002: mb-svg Charter](../../docs/rfcs/0002-mb-svg.md) §§6, 8, 11 — HIGH local authority. Requires deterministic declared workloads and identifies checked coordinate arithmetic as the deferred gap.
- [RFC 0008: mb-canvas Layer and Group Opacity](../../docs/rfcs/0008-mb-canvas-layer.md) §§5–10 — HIGH local authority. Defines opacity-only layers, full-target staging boundary, and four-target integration evidence.
- [MoonBit benchmark documentation](https://docs.moonbitlang.com/en/latest/language/benchmarks.html) — MEDIUM. Documents `@bench.T::bench`, automatic iteration selection, named runs, and `keep`.
- [MoonBit command reference](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — MEDIUM. Documents `moon bench` and target selection.
- [SVG 2 Basic Data Types](https://www.w3.org/TR/SVG2/types.html) §4.2 — MEDIUM. Establishes finite numeric values and recommends higher precision for coordinate transforms.
- [SVG 2 Rendering Model](https://www.w3.org/TR/SVG/render.html) §3.6.1 — MEDIUM. Defines object/group opacity as isolated offscreen post-processing rather than per-child alpha application.
