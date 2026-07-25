# Architecture Patterns

**Domain:** v0.30 SVG Production Readiness — fail-closed numeric admission and reproducible performance evidence
**Researched:** 2026-07-25
**Confidence:** HIGH for repository seams and current behavior; MEDIUM for the benchmark record policy, which needs its first captured baseline.

## Recommended Architecture

Keep the established document-to-render contract intact. `mb-svg` owns all
untrusted SVG text, numeric parsing, typed scene construction, and stable
`CoreError` diagnostics. `mb-canvas` owns only drawing-list interpretation,
offscreen layer allocation, and rasterization. v0.30 must make the scene tree
the **validated numeric boundary**: no `NaN`, infinity, or arithmetic result
outside the documented SVG-safe domain may be stored in a `SceneNode` or
`Affine2` that was derived from SVG text. Consequently,
`lower_to_drawing_list` remains total and infallible for a successfully parsed
scene, preserving its useful pure-data contract.

```text
untrusted SVG source
  |
  v
mb-core/text tokenizer + mb-core/budget
  |
  v
mb-svg lexical numeric readers
  |  parse Double -> require finite -> require scalar safety limit
  v
typed attribute / path / transform validation
  |  reject malformed explicit values; never substitute a default
  |  validate derived viewBox and composed Affine2 values
  v
validated SceneNode tree
  |
  v
lower_to_drawing_list (pure, document order)
  |  PushTransform / PushLayer / Fill / Stroke / PopLayer / PopTransform
  v
mb-canvas rasterizer
  |  layer stack and bounded offscreen images under mb-core/budget
  v
caller-borrowed mb-image surface
```

The second v0.30 stream is evidence, not a runtime subsystem. Keep benchmarks
in `modules/mb-svg/svg/svg_bench.mbt`, use the MoonBit built-in `@bench.T`
harness, and store a human-auditable, local baseline record outside
`release/qualification/`. It must identify fixed workloads, source and
correctness digests, toolchain/host, one warm-up, seven captures, and a
non-marketing interpretation. Do not add a timer, host adapter, or release
qualification framework.

### Component Boundaries

| Component | Responsibility in v0.30 | Communicates With |
|---|---|---|
| `mb-core/text` and `mb-core/budget` | Tokenize markup and enforce existing token, work, and nesting ceilings. They do not define SVG numeric meaning. | `mb-svg/scene` |
| `mb-svg/length.mbt` | Sole scalar/list admission helper for SVG lengths, points, viewBox components, and transform arguments: parse, reject non-finite values, and apply the shared safe scalar policy. | `scene.mbt`, `transform.mbt`, `path_data.mbt` |
| `mb-svg/transform.mbt` | Parse SVG grammar and construct transforms only from admitted scalars. Validate every resulting matrix component after angle conversion and each composition. Singular but finite transforms remain SVG-valid unless a later RFC changes that policy. | `length` helper, `mb-core/math::Affine2`, `scene` |
| `mb-svg/path_data.mbt` | Route every path coordinate/control-point number through the same numeric helper before it becomes `CanvasPath`. | `scene`, `mb-canvas::CanvasPath` |
| `mb-svg/scene.mbt` | Own explicit-attribute errors, derived geometry/viewBox safety checks, and conversion from token stream to a fully valid `SceneNode`. Absence may use an SVG default; an explicitly supplied invalid value must return `Err`. | all SVG leaf parsers, `mb-core/budget`, `lower` |
| `mb-svg/lower.mbt` | Pure `SceneNode` → `DrawingList` lowering, including RFC 0008 opacity layer ordering. It may rely on scene invariants and must not silently sanitize hostile input. | `mb-canvas::DrawingList` |
| `mb-canvas` | Preserve generic public drawing-list and raster-layer semantics. Its own public callers are outside the SVG parser boundary; do not make it the primary SVG validator. | `mb-image`, `mb-color`, SVG lowering |
| `svg_bench.mbt`, `svg/moon.pkg` + tracked baseline record | Exercise public parse and lower routes with fixed input and correctness gates, import the documented `moonbitlang/core/bench` package rather than relying on the current deprecated implicit import, then record reproducible native timing evidence. | `parse_svg`, `lower_to_drawing_list`, MoonBit `@bench` |

## Data Flow and Validation Placement

### 1. Parse-time numeric admission

The present seam is unsafe because `parse_length` and `parse_number_list`
delegate directly to `@text.parse_double`; `attr_double`, `inherit_double`,
root width/height/viewBox parsing, and points parsing then turn parse failures
into defaults, `None`, or an empty point list. A successful non-finite parse
can therefore enter `SceneNode`, and an explicit malformed value can be
indistinguishable from an omitted one. Fix that before lowering.

Implement one private SVG scalar constructor (name is an implementation
choice, such as `parse_safe_svg_number`) that:

1. parses the token with the existing MoonBit parser;
2. rejects `value.is_nan()` and `value.is_inf()` before any comparison;
3. rejects values outside one named, documented absolute scalar limit selected
   to keep all supported shape and transform arithmetic finite; and
4. emits one stable `CoreError` family with an SVG context naming the value
   class (`length`, `coordinate`, `viewBox`, `points`, `path-data`, or
   `transform`).

This is the right location because SVG 1.1 makes coordinates lengths and
specifies transform parameters as numbers; transforms establish the coordinate
system before the element's coordinate and length attributes are processed.
The same type rule must apply to direct shape geometry, viewBox, points,
stroke numeric properties, path coordinates, and every transform argument.
Do not use range checks alone: IEEE `NaN` bypasses ordinary ordered
comparisons. The existing `mb-color/model::validate_normalized` demonstrates
the project convention: test `is_nan()` / `is_inf()` before range checks.

### 2. Derived-value admission

Finite operands alone are insufficient. `lower.mbt` derives `x + width`,
circle/ellipse sample coordinates, rounded-rectangle control points, and the
viewBox scale/translation; `transform.mbt` converts degrees and repeatedly
composes matrices. Define one small private predicate for a finite/safe
`Affine2` and use checked finite-result validation after every transform build
and composition. Add analogous guards where a parsed scene calculation creates
derived coordinates or a viewBox mapping. A valid parse must guarantee that
all components placed in `SceneNode` and all affine coefficients it carries are
finite and within the documented safe envelope.

Do **not** require inversion as an admission criterion. SVG permits finite
singular transforms such as `scale(0)`, while `Affine2::inverse` correctly
returns `None` for a near-zero determinant. Rejecting them would be an
unrelated language restriction. The safety contract is finite bounded
evaluation, not invertibility.

### 3. Scene construction, then total lowering

Change only the builders that consume explicit numeric attributes from
default-returning helpers to `Result`-returning helpers. Required absence still
uses existing defaults where SVG defines them; explicit invalid input
propagates an error through `build_svg_root`, `build_group`, shape builders,
point parsing, and `build_paint`. This is the key semantic distinction:

```text
attribute absent                  -> SVG default / inherited value
attribute explicitly valid         -> admitted typed value
attribute explicitly malformed,
non-finite, or unsafe              -> Result::Err(CoreError), no SceneNode
```

`parse_svg` and `parse_svg_with_budget` are already result-bearing public
admission points, so no new public lowering API is needed. Preserve their
budget behavior and ensure rejection occurs before lowering or rasterization.
The lowerer continues to emit document-order ops: root mapping transform;
group transform; optional `PushLayer(opacity)`; children/fill/stroke; matching
`PopLayer`; then transform pop. This protects the RFC 0008 guarantee that
group/element opacity is composited once, not incorrectly multiplied into
each child paint.

## Benchmark Evidence Architecture

Use the existing package-local benchmark file rather than a new benchmark
module. Add the documented `moonbitlang/core/bench` import to `svg/moon.pkg`
(the present build warns that it is implicit), and replace the local no-op
`keep` helper with `b.keep(...)`: MoonBit's official benchmark documentation
specifically identifies `@bench.T::keep` as the optimization barrier for pure
work. The current declared workloads are a sound starting point but need
accurate names and correctness evidence:

| Stable workload ID | Fixed corpus | Correctness gate before timing | Measured route |
|---|---|---|---|
| `svg/path-parse/1000-line-to` | one generated `M` plus exactly 1,000 `L` segments | parse success, command count / deterministic path digest | `parse_path_data` |
| `svg/transform-parse/60-functions` | ten identical six-function transform groups (the present source is 60, not 50) | parse success, expected affine coefficients or digest | `parse_transform` |
| `svg/parse-lower/50-rect` | one fixed 50-rectangle source document | `parse_svg` success, deterministic draw-op count/order/digest | `parse_svg` → `lower_to_drawing_list` |

Construct corpus strings and validate their facts outside the timed closure.
Within each closure, invoke precisely the public route above and sink its
result via `b.keep`; never benchmark the error path as a proxy for the normal
pipeline. Run the measured native command with:

```powershell
moon -C modules/mb-svg bench --release --target native --frozen svg
```

Use the same source on every supported target for build/run qualification:

```powershell
moon -C modules/mb-svg test --target all --frozen svg
moon -C modules/mb-svg bench --release --target all --frozen --build-only svg
```

The baseline record should retain the exact command, `moon`/`moonc`/`moonrun`
identities, commit, source/correctness digests, host facts, one untimed warmup,
seven timestamped native captures, complete console-output digests, and
mean/median/stddev/min/max. Treat it as local catastrophic-regression
evidence only; native timing on a different host or hosted runner is
informational. The historical PPM qualification record already supplies this
shape; do not couple SVG evidence to its fixed workloads or edit its release
schema.

## Patterns to Follow

### Pattern 1: Parse, validate, then construct

**What:** Make untrusted scalar conversion return `Result`; construct scene
fields only after a scalar or derived transform passes the invariant.

**When:** Every SVG number reaching geometry, style geometry, points, path
data, viewBox, or transforms.

**Example:**

```moonbit
fn parse_safe_scalar(text : String, context : String) -> Result[Double, @error.CoreError] {
  match @text.parse_double(text) {
    Err(_) => Err(svg_error(context, "invalid number"))
    Ok(value) =>
      if value.is_nan() || value.is_inf() || !within_svg_safe_limit(value) {
        Err(svg_error(context, "non-finite or unsafe number"))
      } else {
        Ok(value)
      }
  }
}

// Builders call this only when the attribute is explicitly present.
// Omission is handled separately by the SVG default/inheritance branch.
```

The exact `CoreError` category/code/context matrix should be decided once in
the first implementation phase and used by direct parser tests, scene tests,
fixtures, and public conformance tests. Do not leak target-specific parse error
strings into the contract.

### Pattern 2: Validate composition results, not merely arguments

**What:** Treat matrix construction and composition as numeric operations that
can invalidate otherwise finite arguments.

**When:** `matrix`, `translate`, `scale`, `rotate`, `skewX`, `skewY`, and root
viewBox-to-viewport mapping.

**Example:**

```moonbit
fn require_safe_affine(m : @math.Affine2) -> Result[@math.Affine2, @error.CoreError] {
  if unsafe_scalar(m.a()) || unsafe_scalar(m.b()) || unsafe_scalar(m.c()) ||
     unsafe_scalar(m.d()) || unsafe_scalar(m.tx()) || unsafe_scalar(m.ty()) {
    Err(svg_error("svg-transform", "non-finite or unsafe derived matrix"))
  } else {
    Ok(m)
  }
}
```

This keeps safeguards at the document boundary while retaining generic
`mb-core/math` as a portable arithmetic package instead of making it SVG-aware.

### Pattern 3: Evidence is data, not benchmark-framework code

**What:** Separate timed workload code from captured, machine-specific timing
records.

**When:** The first native baseline and later regression comparisons.

**Example record fields:** workload ID; corpus SHA-256; correctness digest;
command; `--release`, `--target native`, and `--frozen`; tool versions; commit;
warmup; seven raw invocation output digests and timestamps; aggregate; and a
non-marketing claim. This makes changes to benchmark source/corpus visibly
invalidate comparison rather than silently reusing a number.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Defaulting explicit bad numeric attributes

**What:** Preserve `attr_double` / `inherit_double` behavior where all parse
failures become default/inherited values, root dimensions become `None`, or a
bad point list becomes empty.

**Why bad:** It turns hostile or accidental input into a plausible but
different drawing and lets successful non-finite parses reach later arithmetic.

**Instead:** Separate missing-attribute fallback from explicit-value parsing;
the latter is always fallible.

### Anti-Pattern 2: Put SVG sanitization in the rasterizer

**What:** Clamp/ignore invalid SVG values in `mb-canvas` or defer validation
until scan conversion.

**Why bad:** The malformed value already crossed the promised scene/lowering
boundary, errors lose source context, and generic canvas users inherit an SVG
policy they did not ask for.

**Instead:** Reject in `mb-svg`; preserve canvas's generic defensive behavior
and prove opacity/layer semantics through regression tests.

### Anti-Pattern 3: Reject all non-invertible transforms

**What:** Treat determinant zero as numeric unsafety.

**Why bad:** It rejects valid finite SVG such as `scale(0)` and confuses
rendering semantics with arithmetic safety.

**Instead:** reject non-finite/out-of-envelope values and non-finite derived
matrix components; keep a finite singular transform representable.

### Anti-Pattern 4: Benchmark a no-op sink or only successful parsing

**What:** Continue using a local `fn keep(_) { () }`, omit correctness checks,
or identify a 60-function workload as 50.

**Why bad:** Optimizers can remove pure parsing/lowering; a benchmark can time
little or no required work and cannot be compared honestly.

**Instead:** use `b.keep`, fixed names/corpora, pre-timing semantic checks,
and source/correctness digests in the baseline.

## Test Evidence and Build Order

1. **Freeze the numeric invariant and diagnostic matrix.** Add failing tests
   first in `parse_wbtest.mbt`, `transform_wbtest.mbt`, `scene_wbtest.mbt`, and
   `path_data_wbtest.mbt`. Cover lexical non-finite spellings accepted or
   rejected by the local parser, overflow-to-infinity, unsafe finite boundary
   values, derived matrix/viewBox overflow, and the distinction between absent
   and explicitly invalid attributes. Retain normal negative coordinates and
   finite `scale(0)` tests.
2. **Centralize parsing and make scene builders fallible.** Introduce the
   scalar/affine helpers; route lengths, lists, path coordinates, and
   transforms through them; propagate `Result` from builders. Add fixture
   cases to `fixtures/svg/cases.json` for named hostile values and stable
   expected errors. Failed parses must expose no scene/drawing list and must
   not weaken existing resource-budget assertions.
3. **Prove lowering and layer preservation.** Extend `lower_wbtest.mbt` only
   with valid boundary scenes and exact draw-op ordering. Retain/extend the
   `mb-canvas` layer tests for overlap, nested opacity, unbalanced pop, depth,
   and budget failure so numeric hardening cannot regress RFC 0008's precise
   group/element opacity behavior.
4. **Correct and qualify benchmarks.** Switch to `b.keep`, normalize workload
   names and assertions, build every portable target, then capture the native
   baseline after the behavior is stable. Benchmark changes occur last because
   their correctness digests depend on the finished parser semantics.

Required evidence:

| Concern | White-box evidence | Public/integration evidence |
|---|---|---|
| Scalar admission | exact finite/non-finite/boundary tests of length/list/path readers | hostile fixture parses return a structured SVG error |
| Transform safety | each grammar form, composition, finite singular transform, derived overflow | malformed group transform cannot yield a drawing list |
| Scene boundary | explicit bad geometry/points/style numeric value errors; absence remains defaulted | `parse_svg_with_budget` rejects before lower/raster work |
| Opacity semantics | draw-op order for valid groups/elements | canvas overlap/nested-layer pixel evidence remains unchanged |
| Benchmark validity | pre-timing result/op/digest checks and `b.keep` use | frozen all-target test + benchmark build; seven-capture native record |

## Scalability Considerations

| Concern | At 100 documents | At 10K documents | At 1M documents |
|---|---|---|---|
| Numeric validation | Constant work per scalar is negligible and prevents invalid work downstream. | Share one helper and avoid exception/default branches that hide malformed input. | Keep numeric validation allocation-free and preserve existing token/path budgets to bound hostile throughput. |
| Scene/lowering memory | Existing bounded parser and pure drawing list are sufficient. | Avoid a second validated-scene copy or pre-raster staging buffer. | Admission limits and `mb-canvas` layer budget/depth remain essential; tune only through a future RFC-backed policy change. |
| Benchmarks | Three fixed workloads catch local regressions. | Baseline source/corpus digests prevent accidental comparison across changed workloads. | Do not turn local timing records into a distributed telemetry or release gate; use representative corpus expansion only with a defined product requirement. |

## Sources

- Current SVG implementation and tests: `modules/mb-svg/svg/length.mbt`,
  `transform.mbt`, `path_data.mbt`, `scene.mbt`, `lower.mbt`,
  `svg_bench.mbt`, and associated `*_wbtest.mbt` files — HIGH confidence.
- Current layer implementation and tests: `modules/mb-canvas/canvas/draw_list.mbt`,
  `rasterize.mbt`, and `render_wbtest.mbt`; [RFC 0008](../../docs/rfcs/0008-mb-canvas-layer.md) — HIGH confidence.
- Existing reproducible evidence pattern: `benchmarks/ppm/phase-11-resize-composite-baseline.md`,
  `scripts/benchmarks/Invoke-PpmBenchmarks.ps1`, and
  `release/qualification/benchmark-schema.json` — HIGH confidence.
- [MoonBit benchmark guide](https://docs.moonbitlang.com/en/latest/language/benchmarks.html) and [Moon command reference](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — MEDIUM confidence after official-source cross-check through web search; Context7 CLI was unavailable.
- [SVG 1.1 coordinate systems, transformations, and units](https://www.w3.org/TR/2011/WD-SVG11-20110512/coords.html) — MEDIUM confidence: transforms are ordered number-based operations and precede local coordinate/length processing.
