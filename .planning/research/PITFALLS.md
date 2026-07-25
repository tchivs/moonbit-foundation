# Domain Pitfalls: v0.30 SVG Production Readiness

**Domain:** Public reproducible `mb-svg` benchmarks and fail-closed SVG numeric handling for coordinate, length, and transform inputs.
**Researched:** 2026-07-25
**Confidence:** HIGH for current-code risks; MEDIUM for SVG/MoonBit external-contract details (current official sources, classified as verified web documentation).

## Critical Pitfalls

### 1. Letting non-finite or malformed numbers become geometry

**What goes wrong:** A lexical numeric token accepted by the runtime as `NaN` or infinity—or a finite literal which overflows during parsing—reaches a length, viewBox, transform, shape coordinate, path command, dash value, or opacity field. Current `parse_length` and `parse_number_list` delegate directly to `@text.parse_double`; `path_data.mbt` then converts any parse failure to `(0.0, i)`. In scene construction, many numeric attribute parse failures instead fall back to a default or inherited value. This turns hostile or erroneous input into plausible but incorrect geometry.

**Why it happens:** The parser is structurally bounded, but it has no single numeric admission policy. `parse_length`, transform arguments, `viewBox`, and attributes have distinct fallback paths. A resource budget controls token/path count, not floating-point semantics.

**Consequences:** A non-finite value can survive until comparisons, matrix composition, scan conversion, or opacity selection. A malformed coordinate can silently move to zero; an invalid child style can silently inherit its parent. Both outcomes defeat deterministic, inspectable failures and can produce target-specific rendering.

**Prevention:** Introduce one private SVG scalar parser/admission helper returning `Result[Double, CoreError]`. It must reject parse failure, `is_nan()`, infinities, and values outside one documented, finite SVG implementation envelope before a value reaches a scene node. Route every numeric entry point through it: lengths, number lists, path reader, transform arguments, viewBox, geometry attributes, style numerics, and opacity. Propagate the typed SVG error; never use zero/default/inheritance as an error recovery path for a present numeric attribute. Missing attributes may still use their specified defaults.

**Detection:** Add table-driven tests for runtime-recognized non-finite spellings, huge exponents/overflow, malformed tokens, empty numeric positions, signed zero, and one-unit-inside/outside the selected finite envelope. Assert `Err` with an SVG numeric context for every present invalid value; assert no `SceneNode` or drawing list is returned. Preserve ordinary negative coordinates and finite `scale(0)` as accepted controls.

### 2. Checking parsed values but not derived arithmetic

**What goes wrong:** Every source scalar is finite, yet relative path accumulation, Bézier reflection, degree-to-radian conversion, trigonometric skew/rotation, matrix composition, or viewBox scale/translation overflows to infinity or produces NaN. `viewbox_transform` divides viewport dimensions by viewBox dimensions and multiplies offsets; transforms compose repeatedly. The current guard only compares dimensions with zero and otherwise constructs an affine matrix.

**Why it happens:** “Finite input” is not closed under floating-point arithmetic. Transform lists intentionally compose in document order; a legal finite singular transform such as `scale(0)` is not the same thing as an unsafe non-finite matrix.

**Consequences:** The parser can claim success while the downstream `mb-canvas` receives impossible path coordinates or affine coefficients. Raster bounds can expand unpredictably, and target math/runtime differences can alter output or failure mode.

**Prevention:** After each arithmetic-producing operation, validate its result against the same finite envelope: relative-coordinate updates, reflected controls, all six affine coefficients after each transform composition, and all calculated viewBox scales/translations. Reject division by zero only where SVG says the viewBox dimension is invalid; retain a finite singular affine matrix. Do not “repair” a bad result by substituting identity, because that changes document meaning invisibly.

**Detection:** Exercise finite values that overflow only after addition, multiplication, division, or composition; include a transform-list overflow and a viewBox translation overflow. Assert failure before lowering. Also freeze valid negative coordinates, subnormal-but-accepted values if the envelope permits them, `scale(0)`, and a normal rotate-around-centre case.

### 3. Mixing unit grammar policy with numeric safety

**What goes wrong:** A hardening change either keeps accepting unsupported units/percentages accidentally or broadens the milestone into CSS length resolution. The current v0.1 policy strips only `px`, `pt`, `mm`, `cm`, and `in`, maps them 1:1 to user units, and deliberately does not resolve percentages. Shape and stroke attributes do not all share the same SVG unit semantics or reference rectangle.

**Why it happens:** A generic `parse_double` helper looks like a natural replacement, while `strip_unit_suffix` makes unit acceptance appear simpler than it is. Returning a default after an unsupported unit hides an incompatible document rather than declaring it unsupported.

**Consequences:** `10%`, malformed suffixes, or a number-plus-junk token may become zero/default/inherited values; alternatively, an attempted “fix” silently introduces inconsistent percentage behavior across viewport and paint properties.

**Prevention:** Make the scalar helper return a parsed numeric value plus an explicit unit class. Preserve the documented v0.1 absolute-unit behavior only where currently supported. Reject percentages and unsupported/malformed suffixes with a structured unsupported/invalid-length error until a separate context-aware length-resolution design exists. Require exact required arity for `viewBox` and transform functions rather than accepting surplus operands and ignoring them.

**Detection:** Test valid unitless and supported finite suffixes; reject `%`, unknown suffixes, duplicate suffixes, trailing junk, missing numbers, and extra matrix/rotate operands. Confirm a known finite document has the same scene and drawing-list operations before and after hardening.

### 4. Breaking opacity while fixing numbers

**What goes wrong:** Numeric validation causes all out-of-range opacity to fail, or changes group/object opacity into per-paint alpha multiplication. SVG requires finite `fill-opacity` and `stroke-opacity` values outside `[0,1]` to clamp. Object/group `opacity` is different: content is rendered into an isolated offscreen group and then composited once. Current `lower.mbt` correctly emits `PushLayer`/`PopLayer` for group and element opacity below 1, and `mb-canvas` clamps alpha at use.

**Why it happens:** There are three similarly named values with different inheritance and compositing rules. A blanket “numeric validation” change can conflate non-finite rejection with finite range normalization.

**Consequences:** Overlapping fills/strokes or sibling shapes blend differently; nested opacity stops multiplying correctly; a NaN comparison can skip layer creation because `NaN < 1.0` is false. Removing a layer for `opacity=0` can also change error/resource behavior and makes the lowering contract less direct.

**Prevention:** First reject non-finite/unsafe scalar values. Then preserve SVG range policy: clamp finite `fill-opacity`, `stroke-opacity`, and object/group opacity to `[0,1]`; retain fill/stroke inheritance and non-inherited object opacity. Lower finite object/group opacity `< 1` through the existing canvas-layer path, never by multiplying fill/stroke alpha. Keep canvas as the sole owner of layer allocation, max-depth, and source-over rendering.

**Detection:** Add pixel tests for overlapping children in a `g opacity="0.5"`, an element carrying both fill and stroke, and nested 0.5 layers over a nontransparent backdrop. Add draw-op-order tests for opacity `0`, `1`, finite out-of-range clamp, and non-finite rejection. Preserve existing `mb-canvas` tests for nested layers, unbalanced pop, budget exhaustion, and its depth cap.

### 5. Exposing a mismatch between SVG nesting and canvas layer limits

**What goes wrong:** Legal document nesting can be accepted by the SVG parse budget (default depth 64) but deeply nested groups with opacity below 1 require more than the canvas maximum 16 raster layers. The failure appears only on render, after successful parse/lower.

**Why it happens:** SVG structure depth and raster-layer depth are independently bounded, and only opacity-bearing groups consume the latter.

**Consequences:** A document that is syntactically valid and numerically safe fails late, possibly after a consumer has committed to a scene/drawing list. Treating this as a numeric parser error would obscure the actual capability boundary.

**Prevention:** Keep this as a canvas capability/resource error, but qualify it deliberately: document that parse/lower remains portable while render requires the declared canvas layer budget/depth. If v0.30 adds early validation, count prospective opacity layers during lowering and return the same structured capacity error before exposing a list; do not change `mb-canvas`'s enforcement or silently flatten layers.

**Detection:** Render 16 nested finite-opacity groups successfully with sufficient budget; the 17th must return the existing layer-depth error without partial destination mutation. Include a deeply nested all-opaque control to show that structural depth alone is not the layer limit.

### 6. Benchmarking a no-op after dead-code elimination

**What goes wrong:** The public benchmark suite reports a time for parsing/lowering that the optimizer removed. `svg_bench.mbt` defines a local `fn keep[T](_ : T) -> Unit { () }` and passes every benchmark result to it. That helper has no observable use. MoonBit’s official benchmark guidance explicitly requires `b.keep` for pure computations and warns that constant pre-calculation is still possible.

**Why it happens:** The benchmark file has the right workload construction and `@bench.T` shape, but shadows the framework’s anti-DCE facility with a no-op.

**Consequences:** Results can collapse toward loop/closure overhead, differ by optimization target, and be mistakenly retained as a performance baseline.

**Prevention:** Delete the local helper and use `b.keep` on an observable scalar derived from each valid result: e.g. parsed path operation count, affine coefficient digest, and lowered drawing-list operation count/digest. Build fixed source strings outside the timed closure, validate parse/lower success plus the expected result/digest before timing, and time only the intended public operation. Do not benchmark an `Err(_) => ()` fallback as if it were the declared valid workload.

**Detection:** Review the compiled/release benchmark source for `b.keep` calls and no local shadow. Add a pre-timing assertion that each workload is accepted and has its expected operation count/digest. A deliberately changed fixture must fail qualification rather than produce a comparable-looking timing.

### 7. Calling a benchmark reproducible when its corpus and environment drift

**What goes wrong:** The workload name says “1000 commands”, “50 segments”, or “50 rects”, but the generated input, result shape, toolchain, target, build mode, or host differs between captures. A successful-but-different parser path (for example, a changed numeric fallback) is then compared against an old number.

**Why it happens:** `moon bench` automatically selects iteration counts and reports statistical summaries; it does not make an arbitrary source corpus or machine comparable. The existing PPM evidence shows the repository’s established remedy: frozen release command, source/correctness digests, a warmup, seven separately recorded native captures, and an explicitly non-marketing policy.

**Consequences:** Timing changes are attributed to `mb-svg` although they come from compilation mode, runtime/CPU effects, changed workload input, changed correctness, or benchmark harness behavior.

**Prevention:** Create a versioned SVG benchmark record rather than a CI timing gate. Record commit and benchmark-source hash, fixed generated corpus hashes, expected parse/lower digests, exact `moon`/`moonc`/`moonrun` versions, OS/CPU facts, command (`moon -C modules/mb-svg bench --release --target native --frozen svg` or the verified package equivalent), one untimed warmup, and seven independent captures. State that the evidence detects catastrophic local regression only, not a portability or marketing claim.

**Detection:** Validate the evidence schema and reject a capture whose target, release/frozen mode, toolchain, corpus hash, expected digest, count, or raw output hash is absent. A benchmark-source or fixture change requires a new baseline, never an in-place comparison.

### 8. Treating four-target benchmark execution as four-target performance evidence

**What goes wrong:** A `--target all` or all-target loop produces timing rows for JS, Wasm, Wasm-GC, and native, and those rows are compared or gated as if they share a runtime and clock model. Conversely, recording only native timing is mistaken for portability qualification.

**Why it happens:** MoonBit permits `moon bench --target wasm|wasm-gc|js|native|all`; target availability is not a promise of cross-runtime timing comparability.

**Consequences:** Runtime startup/JIT behavior, backend code generation, and host runners dominate a supposed SVG parser comparison. A native-only performance record can hide a target compilation or behavior regression.

**Prevention:** Use all four targets for deterministic build/test/valid-workload qualification, with identical expected scene/drawing-list evidence. Use release native only for the reproducible timing record. Keep the timing record target-specific and never derive a cross-target speed ranking. Keep hosted CI to build/run correctness; do not turn noisy shared-host timings into a release threshold.

**Detection:** Require four-target test output from the same commit and require every timing record to declare exactly `target: native`, `optimization: release`, and `frozen: true`. Reject records containing mixed-target aggregate statistics.

### 9. Reclassifying compatibility regressions as “hardening”

**What goes wrong:** Valid finite documents change output because a new numeric helper changes accepted whitespace/separators, transform order/arity, the v0.1 absolute-unit convention, default values, or layer emission. Invalid present numeric attributes used to be silently tolerated, so fail-closed behavior is an intentional semantic tightening; it must not become an untracked change to valid inputs.

**Why it happens:** The production code currently has permissive fallback behavior in `scene.mbt` and `path_data.mbt`, while lowering is coupled to exact drawing-list operation order.

**Consequences:** Consumers lose established finite rendering behavior; conformance fixtures and downstream code can break without a useful error classification. An opacity refactor can break pixel output even when numeric tests pass.

**Prevention:** Define the compatibility split up front: malformed/non-finite/out-of-envelope *present* numeric values now fail closed; valid finite v0.1 syntax retains its existing scene and rendering contract. Freeze a compact compatibility corpus spanning unitless/supported-unit lengths, negative coordinates, normal viewBox, composed transforms, inherited paint values, fill/stroke opacity, group opacity, element opacity, and nested opacity. Version/changelog the intentional rejection change.

**Detection:** Compare public parse/lower operation digests and selected rendered RGBA fixtures before/after hardening on every target. Assert invalid cases now produce the new structured error, rather than a different valid scene or a panic.

## Moderate Pitfalls

### 10. Choosing an arbitrary finite envelope without connecting it to raster limits

**What goes wrong:** A cap is selected merely because it is representable by `Double`; later a finite coordinate causes unbounded bounds expansion, impossible scan conversion, or a downstream image-size failure.

**Prevention:** Specify the SVG scalar envelope alongside `mb-canvas`/`mb-image` resource limits and explain whether it bounds source coordinates, derived coordinates, or both. Test exact boundary acceptance and one-step rejection. The envelope must be a public, target-independent policy—not an accidental native maximum.

### 11. Relying only on parse tests

**What goes wrong:** Parser unit tests prove `Err` for one literal but do not prove that scene construction, lowering, and rendering cannot receive a bad value through another numeric attribute path.

**Prevention:** Keep leaf parser tests, then add a route matrix: root dimensions/viewBox, each basic shape, path relative arithmetic, transform forms, dash/stroke values, fill/stroke opacity, group opacity, and element opacity. For each invalid route assert parse failure, no drawing list, and no raster mutation.

## Minor Pitfalls

### 12. Making error text the only contract

**What goes wrong:** Tests assert an entire English error message, making future diagnostic improvements needlessly breaking, or discard context so all failures look identical.

**Prevention:** Assert the stable error code/category and concise context such as `svg-number`, `svg-length`, or `svg-transform`; retain the original attribute/operation name for diagnosis. Use message text only as secondary evidence.

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation |
|-------------|---------------|------------|
| Numeric contract and tests | Fixing one parser while alternate attribute/path readers still coerce values | Write the admission contract and route-matrix tests first; cover parse, scene, lower, and raster boundaries. |
| Numeric implementation | Rejecting source non-finites but emitting non-finite derived transforms | Validate every arithmetic result and all affine coefficients; preserve finite singular transforms. |
| Units/arity | Accidentally implementing CSS percentage resolution or ignoring extra operands | Keep v0.1 supported-unit policy explicit, reject unresolved units, and enforce exact grammar arity. |
| Opacity/lowering | Replacing group opacity with per-paint alpha or changing inherited values | Reject non-finite first, clamp finite opacity second, retain `PushLayer`/`PopLayer` lowering and pixel tests. |
| Canvas integration | Parse depth permits more opacity layers than the rasterizer | Test 16/17 nested layers with budget/no-partial-mutation assertions; preserve canvas as layer owner. |
| Benchmark correction | Replacing no-op `keep` but timing changed/error workload | Use real `b.keep`, fixed input outside timing, pre-timing correctness digest, and valid-only closure. |
| Benchmark evidence | Corpus/toolchain/host drift and target-mixed timing | Native frozen release record with seven captures and explicit metadata; all-target correctness separately. |
| Compatibility qualification | Hardening alters valid finite scenes or opacity pixels | Freeze valid finite parse/lower and RGBA corpus, then separately assert intentional invalid-input failures. |

## Sources

- Current repository inspection — **HIGH**: `modules/mb-svg/svg/{length,transform,path_data,scene,lower,svg_bench}.mbt`; `modules/mb-canvas/canvas/{style,draw_list,rasterize,render_wbtest}.mbt`; `docs/rfcs/0002-mb-svg.md`; `benchmarks/ppm/phase-11-resize-composite-baseline.md`; and `release/qualification/benchmark-schema.json`.
- [MoonBit: Writing Benchmarks](https://docs.moonbitlang.com/en/latest/language/benchmarks.html) — **MEDIUM** (official documentation retrieved through verified web lookup): `@bench.T::bench`, `b.keep`, automatic iteration count, and constant-precalculation caveat.
- [MoonBit command reference: `moon bench`](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html#moon-bench) — **MEDIUM** (official documentation retrieved through verified web lookup): release/frozen options and selectable `wasm`, `wasm-gc`, `js`, `native`, and `all` targets.
- [SVG 2: Coordinate Systems, Transformations and Units](https://www.w3.org/TR/SVG2/coords.html) — **MEDIUM** (official specification retrieved through verified web lookup): viewBox arithmetic, invalid negative dimensions, and zero-dimension rendering behavior.
- [SVG 2: Rendering Model](https://www.w3.org/TR/SVG2/render.html) and [SVG 2: Painting](https://www.w3.org/TR/SVG2/painting.html) — **MEDIUM** (official specifications retrieved through verified web lookup): isolated object/group opacity and finite fill/stroke opacity clamping.

## What Might Still Need Phase-Specific Research

- The exact portable numeric envelope needs an implementation decision tied to the current `mb-canvas` raster/bounds algorithms; this research establishes the required validation shape, not a guessed magnitude.
- Confirm exact MoonBit `@text.parse_double` handling of all lexical non-finite spellings per target. Tests must be written against the implementation’s accepted spellings plus overflow-derived infinity, rather than assuming every spelling is accepted.
- Confirm the exact package/path syntax for the recorded `moon bench` command after the benchmark suite is corrected; the policy must retain `--release`, `--target native`, and `--frozen` regardless of the final package selector.
