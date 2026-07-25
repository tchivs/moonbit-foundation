# Project Research Summary

**Project:** MoonBit Native Foundation — v0.30 SVG Production Readiness
**Domain:** Portable, bounded SVG parse-to-canvas lowering
**Researched:** 2026-07-25
**Confidence:** MEDIUM-HIGH

## Executive Summary

v0.30 is a production-hardening milestone for the existing pure-MoonBit `mb-svg` subset, not an SVG feature-expansion project. The recommended implementation retains the established boundary: `mb-svg` parses untrusted text, validates and constructs a typed scene, `lower_to_drawing_list` deterministically emits canvas operations, and `mb-canvas` alone owns offscreen layer allocation and rasterization. The milestone should deliver declared benchmark workloads, fail-closed numeric admission, and all-target proof that existing RFC 0008 opacity semantics remain exact.

The central recommendation is to make a successfully parsed `SceneNode` the numeric safety boundary. Route every explicit SVG scalar through one finite, bounded parser; validate every derived coordinate and affine component; then propagate a structured SVG error instead of replacing malformed input with zero, a default, or an inherited value. Keep finite singular transforms, preserve current finite opacity clamping and isolated `PushLayer`/`PopLayer` composition, and do not move SVG validation into canvas.

The principal risks are incomplete numeric-route coverage, overflow after otherwise finite arithmetic, accidental opacity changes, and misleading timing evidence. Mitigate them with a route-matrix test contract before implementation, compatibility and overlap-sensitive rendering fixtures, and fixed correctness-gated benchmark fixtures. Four-target execution establishes semantic portability; a frozen native-release, seven-capture record is local regression evidence only—not a cross-target speed claim or CI latency threshold.

## Key Findings

### Recommended Stack

Use the repository's already-pinned MoonBit toolchain (`moon`/`moonrun` `0.1.20260713`, `moonc` `v0.10.4+2cc641edf`) with the existing portable `mb-svg` package target set: `js`, `wasm`, `wasm-gc`, and `native`. No database, FFI, native parser, benchmark framework, or new public canvas API is warranted. The implementation belongs in normal MoonBit source and must produce the same acceptance/rejection outcome on all four targets.

**Core technologies:**

- MoonBit `@bench.T` and `moon bench` — keep package-local benchmarks; use `b.keep` as the anti-DCE sink and fixed input outside the timed closure.
- `mb-core/text` plus `CoreError` — add an explicit finite SVG-facing numeric helper while preserving the general `parse_double` contract for other consumers.
- MoonBit `Double::is_nan()` / `Double::is_inf()` — reject non-finite conversion results before ordered range checks.
- Versioned SVG fixtures and human-readable baseline record — make workload identity, correctness, toolchain, host, and execution mode auditable.
- `moon test --target all --frozen` — qualify semantics on all production targets; use native release timing only for like-for-like local comparison.

### Expected Features

The milestone has three required outcomes: (1) three named, fixed, correctness-gated public workloads for path parse, transform composition, and parse-to-lower; (2) structured rejection of non-finite, overflowing, malformed, and unsafe values before a scene or drawing list exists; and (3) all-target proof that valid SVG behavior and group/element opacity layering remain unchanged.

**Must have (table stakes):**

- Immutable, accurately named workload fixtures with pre-timing command/affine/draw-operation checks and `b.keep` inside the timed path.
- A documented benchmark record with command, corpus and correctness digests, exact toolchain/host facts, warmup, and seven native release captures.
- One shared scalar admission policy for lengths, lists, paths, transforms, viewBox, geometry, relevant stroke/paint values, and opacity; it rejects explicit malformed or unsafe input with stable SVG-specific error context.
- Validation of derived relative coordinates, viewBox mapping, matrix construction/composition, and trigonometric results against one documented target-neutral envelope.
- Public all-target numeric, compatibility, opacity-order, and raster-output evidence with no partial success object on rejection.

**Should have (production differentiators):**

- A centralized route matrix proving every numeric ingress and derived path fails before lower/raster work.
- A compact frozen compatibility corpus for accepted finite syntax, transform order, unit policy, inherited paint, and isolated nested opacity.
- Native timing evidence explicitly separated from portable benchmark build/run qualification.

**Explicitly defer:** SVG text, gradients, masks, filters, `<use>`, animation, broader XML/CSS or percentage resolution, native acceleration, image-sized layer staging, new canvas/image/FFI APIs, release automation, and global timing thresholds.

### Architecture Approach

Keep the existing parse → validated scene → pure lowering → bounded canvas rasterization flow. `mb-svg` owns numeric grammar, SVG-specific errors, and checked derivation; `mb-canvas` remains generic and owns only drawing-list/layer execution. A successful `parse_svg` or `parse_svg_with_budget` must imply that all scene scalars and SVG-derived `Affine2` coefficients are finite and inside the declared envelope, allowing `lower_to_drawing_list` to stay total and infallible.

**Major components:**

1. `mb-core/text` — optional additive bounded finite conversion primitive and deterministic `CoreError` support; do not silently alter generic number-parser compatibility.
2. `mb-svg/length.mbt`, `path_data.mbt`, and `transform.mbt` — the shared scalar route, grammar/arity enforcement, and checked path/affine derivation.
3. `mb-svg/scene.mbt` — distinguishes omitted attributes (existing SVG default/inheritance) from explicitly invalid attributes (error, no `SceneNode`).
4. `mb-svg/lower.mbt` — relies on validated scene invariants and retains document-order transforms and isolated opacity layers.
5. `mb-canvas` — preserves existing bounded layer allocation, source-over rendering, 16-layer capability limit, and partial-mutation protections.
6. `svg_bench.mbt` and a tracked local baseline record — fixed public workloads and reproducible evidence, not a runtime subsystem or release gate.

### Critical Pitfalls

1. **Fail-open numeric fallbacks** — do not turn invalid present values into `0`, `None`, empty points, defaults, or inherited style; only absent attributes may use SVG defaults.
2. **Checking sources but not arithmetic** — validate every relative/path, viewBox, trigonometric, matrix-build, and composition result; retain finite `scale(0)` rather than treating non-invertibility as unsafety.
3. **Conflating numeric hardening, units, and opacity** — preserve the v0.1 absolute-unit policy, reject percentages/unsupported units and extra operands, reject non-finite values first, then retain finite opacity clamping and `PushLayer`/`PopLayer` composition.
4. **A benchmark that measures a no-op or drifting corpus** — remove the local no-op sink, use `b.keep`, validate fixed workload facts before timing, and invalidate comparisons whenever source/corpus/correctness facts change.
5. **Treating all-target timing as comparable performance** — all targets prove build/run and deterministic outcomes; only a declared native release environment provides a meaningful baseline. Also retain the documented 16-vs-17 nested-opacity layer capability test.

## Implications for Roadmap

### Phase 1: Numeric Contract, Envelope, and Route-Matrix Tests

**Rationale:** The safe scalar magnitude and stable error taxonomy determine all downstream parser, scene, and compatibility decisions. Lock these before touching permissive fallback paths.

**Delivers:** A documented SVG numeric admission/derived-value contract; target-neutral scalar envelope; stable `CoreError` category/context matrix; failing leaf/public route tests for all numeric paths; frozen valid finite compatibility controls.

**Addresses:** SVGPR-02's policy/evidence foundation and SVGPR-03 compatibility boundary.

**Avoids:** Partial ingress coverage, arbitrary numeric caps, accidentally rejecting finite singular transforms, unit-policy expansion, and brittle full-message assertions.

### Phase 2: Fail-Closed Parsing and Validated Scene Construction

**Rationale:** Once the contract is fixed, centralize scalar admission and make explicit attribute builders fallible before values can enter scene or affine data.

**Delivers:** Shared finite/bounded scalar helper; exact length/unit/arity handling; checked path and affine/viewBox derivations; `Result` propagation through root, group, shapes, points, transforms, and paint-style numeric readers; no scene/list on rejection.

**Addresses:** SVGPR-02.

**Avoids:** Defaulting malformed explicit fields, target-specific parser behavior, non-finite derived transforms, and moving SVG policy into `mb-canvas`.

### Phase 3: Opacity, Capacity, Compatibility, and Four-Target Qualification

**Rationale:** Numeric changes are only production-ready when valid document output and the canvas integration contract are proven unchanged.

**Delivers:** Draw-operation and pixel/digest fixtures for group, element, fill, stroke, and nested opacity; 16/17 opacity-layer capacity evidence; valid finite parse/lower corpus; hostile-input no-effect proof; `moon test --target all --frozen` qualification.

**Addresses:** SVGPR-03 and the portability portion of SVGPR-01.

**Avoids:** Per-paint substitution for isolated group opacity, changing default/inheritance semantics, and mistaking parse-depth success for raster-layer capacity.

### Phase 4: Correctness-Gated Benchmarks and Native Baseline Record

**Rationale:** Benchmark digests must reflect the finalized parser/lowering semantics, so timing evidence is captured after the safety and compatibility contract stabilizes.

**Delivers:** Fixed path-parse, transform-parse (accurately 60 functions), and 50-rect parse-to-lower workloads; pre-timing correctness checks; `b.keep`; all-target benchmark build/run qualification; and a native frozen-release record with metadata, warmup, and seven captures.

**Addresses:** SVGPR-01.

**Avoids:** Dead-code-eliminated timing, error-path timing, incorrect workload cardinality, host/corpus drift, and false cross-target performance claims.

### Phase Ordering Rationale

- The numeric envelope and error contract are architectural policy, so tests and decisions precede mechanical parser migration.
- Parser/scene invariants must be in place before lowerer and raster evidence can credibly demonstrate no unsafe value crossed the boundary.
- Opacity/capacity qualification guards the critical cross-module contract before performance evidence is frozen.
- Benchmark correctness digests depend on final accepted semantics; create fixtures early if convenient, but capture the accepted baseline last.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 1:** Select the exact portable scalar envelope from current canvas/raster/bounds limits; verify accepted lexical non-finite spellings and exponent behavior per target.
- **Phase 2:** Map all actual numeric ingress and builder signatures to ensure no default-on-error route remains; confirm the most ergonomic additive `mb-core/text` API/error encoding.
- **Phase 4:** Recheck the exact MoonBit package selector/command syntax after benchmark changes and define the baseline-record location/schema without coupling it to release qualification.

Phases with established patterns (skip broad research-phase):

- **Phase 3:** Existing RFC 0008 layer tests, four-target selectors, and frozen-vector conventions provide a clear implementation pattern; focus planning on coverage rather than exploratory design.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Installed pinned toolchain and repository seams were exercised; official MoonBit docs corroborate APIs, but provider confidence was low and command details should be rerun in CI. |
| Features | HIGH | Directly anchored in `.planning/PROJECT.md`, RFC 0002/RFC 0008, current module behavior, and milestone exclusions. |
| Architecture | HIGH | Component boundaries, unsafe fallback seams, lower ordering, and canvas ownership were inspected in the live repository. |
| Pitfalls | HIGH | Critical paths derive from current parser/lowering/benchmark code; external SVG and MoonBit behavior provides medium-confidence corroboration. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Scalar envelope:** Do not guess a `Double` magnitude. Tie the public limit to current canvas/raster/bounds resource behavior, document whether it covers source and derived values, and test both boundaries.
- **Lexical non-finites:** Establish tests from behavior observed on every target, including overflow-derived infinity, instead of assuming identical acceptance of every spelling.
- **Benchmark command and record:** Verify final `moon bench` package/path syntax after source changes; retain `--release`, `--target native`, and `--frozen` regardless of selector form.
- **Layer-depth policy:** v0.30 should document and test the existing canvas capability boundary, not silently flatten or reclassify it as a numeric parse error.

## Sources

### Primary (HIGH confidence)

- [.planning/PROJECT.md](../PROJECT.md) — v0.30 goal, active requirements, and explicit scope boundary.
- [STACK.md](STACK.md), [FEATURES.md](FEATURES.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [PITFALLS.md](PITFALLS.md) — direct repository research into toolchain, implementation seams, RFCs, tests, and existing benchmark evidence.
- [RFC 0002: mb-svg Charter](../../docs/rfcs/0002-mb-svg.md) — declared SVG boundaries and checked-coordinate safety gap.
- [RFC 0008: mb-canvas Layer and Group Opacity](../../docs/rfcs/0008-mb-canvas-layer.md) — isolated opacity layers, full-target staging scope, and four-target evidence expectations.

### Secondary (MEDIUM confidence)

- [MoonBit benchmark guide](https://docs.moonbitlang.com/en/latest/language/benchmarks.html) — `@bench.T`, `b.keep`, automatic batching, and unstable `Summary` JSON.
- [MoonBit command reference](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — `moon bench`, frozen/release modes, and target selection.
- [SVG 2 Basic Data Types](https://www.w3.org/TR/SVG2/types.html), [Coordinate Systems](https://www.w3.org/TR/SVG2/coords.html), [Rendering Model](https://www.w3.org/TR/SVG2/render.html), and [Painting](https://www.w3.org/TR/SVG2/painting.html) — finite values, transform/viewBox behavior, and isolated opacity semantics.

---
*Research completed: 2026-07-25*
*Ready for roadmap: yes*
