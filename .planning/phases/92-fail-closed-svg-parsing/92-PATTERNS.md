# Phase 92: Fail-Closed SVG Parsing - Pattern Map

**Mapped:** 2026-07-26  
**Files analyzed:** 13 planned files (12 modifications, 1 new public test)  
**Analogs found:** 12 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-svg/svg/svg.mbt` | utility / error factory | transform | existing `svg_error` in the same file | exact |
| `modules/mb-svg/svg/length.mbt` | parser utility | request-response / transform | existing lexical `Result` parser in the same file | exact |
| `modules/mb-svg/svg/color.mbt` | parser utility | request-response / transform | `parse_color` / `parse_func_color` | exact |
| `modules/mb-svg/svg/transform.mbt` | parser | request-response / transform | `parse_transform` + `build_transform` | exact |
| `modules/mb-svg/svg/path_data.mbt` | parser | streaming / transform | `parse_path_data_with_budget` | exact |
| `modules/mb-svg/svg/scene.mbt` | parser / scene builder | request-response / transform | `build_element`, `build_group`, `build_path` | exact |
| `modules/mb-svg/svg/scene_wbtest.mbt` | test | request-response | existing scene construction and omission/inheritance tests | exact |
| `modules/mb-svg/svg/parse_wbtest.mbt` | test | transform | existing leaf parser boundary tests | exact |
| `modules/mb-svg/svg/transform_wbtest.mbt` | test | transform | existing affine envelope helper/tests | exact |
| `modules/mb-svg/svg/path_data_wbtest.mbt` | test | streaming / transform | existing command and relative-route table tests | exact |
| `modules/mb-svg/svg/lower_wbtest.mbt` | test | request-response / transform | existing parse-then-lower assertions | exact |
| `modules/mb-svg/svg/numeric_contract_wbtest.mbt` | test | request-response | existing inclusive-boundary tracer | exact |
| `modules/mb-svg/svg/svg_test.mbt` (new) | public black-box test | request-response | `modules/mb-core/error/error_test.mbt` | role-match |

`lower.mbt`, `mb-core/math/{affine,path}.mbt`, and `mb-core/error/core_error.mbt` are **read-only source anchors** for the parser-side preflight and typed-error assertions. The phase contract says not to make lowering fallible or change canvas behavior.

## Pattern Assignments

### `modules/mb-svg/svg/svg.mbt` (utility / error factory, transform)

**Analog:** `modules/mb-svg/svg/svg.mbt:5-13`

**Error construction pattern:** retain the package-local factory and construct the numeric variants with the existing portable error ABI. Do not leak `@text.parse_double` errors.

```moonbit
fn svg_error(context : String, message : String) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    @error.ErrorCode::InvalidEncoding,
    operation="svg",
    context=context + ": " + message,
  )
}
```

**Executor anchors:** add a single private numeric-error/admission helper beside this function. The helper must use `Data`, `operation="svg"`, and the exact policy contexts (`svg-numeric-source`, `svg-numeric-nonfinite`, `svg-numeric-range`, `svg-numeric-derived`); source/non-finite use `InvalidEncoding`, range/derived use `InvalidRange`.

---

### `modules/mb-svg/svg/length.mbt` (parser utility, request-response / transform)

**Analog:** `modules/mb-svg/svg/length.mbt:11-14, 31-41, 46-75`

**Result propagation pattern:** every lexical conversion already returns `Result`; pass that failure through the SVG admission helper immediately after conversion. Keep the token-loop early return.

```moonbit
match parse_token(token) {
  Ok(v) => nums.push(v)
  Err(e) => return Err(e)
}
```

**Executor anchors:** replace the direct `@text.parse_double` calls at lines 13 and 74 with SVG-source conversion plus admission; make `parse_viewbox` require exactly four admitted values (current `< 4` acceptance is at lines 36-40). This is the shared ingress for lengths, lists, points, viewBox, and transform arguments.

---

### `modules/mb-svg/svg/color.mbt` (parser utility, request-response / transform)

**Analog:** `modules/mb-svg/svg/color.mbt:23-43, 87-149`

**Core pattern:** `parse_color` and `parse_func_color` already return `Result`; preserve their dispatch and make consumed numeric components return/propagate `Result` rather than using `parse_double_or`.

```moonbit
if is_hsl {
  let h = parse_double_or(c0, 0.0)
  let s = parse_percent(c1)
  let l = parse_percent(c2)
  let (r, g, b) = @color.hsl_to_rgb(h, s, l)
  Ok((r, g, b))
} else {
  Ok((parse_component(c0), parse_component(c1), parse_component(c2)))
}
```

**Executor anchors:** refactor lines 121-142 and remove the line 145-149 default-on-failure seam. Admit only the three consumed `rgb`/`hsl` components; preserve the documented compatibility boundary for ignored `rgba`/`hsla` alpha.

---

### `modules/mb-svg/svg/transform.mbt` (parser, request-response / transform)

**Analog:** `modules/mb-svg/svg/transform.mbt:16-66, 70-137`

**Core pattern:** parse one function, return `Err` immediately, and only compose after a checked transform was built.

```moonbit
match build_transform(name, args_str) {
  Ok(m) => result = m.compose(result)
  Err(e) => return Err(e)
}
```

**Executor anchors:** retain that control flow; enforce exact arities in `build_transform` (the present `>=` branches at lines 79-130 permit trailing arguments). Admit source arguments, degree-to-radian output, all six constructed coefficients, and each composed `result` coefficient before `Ok(result)` at line 66. Do not use determinant/invertibility as validation: `scale(0)` remains valid.

---

### `modules/mb-svg/svg/path_data.mbt` (parser, streaming / transform)

**Analog:** `modules/mb-svg/svg/path_data.mbt:23-282` and `:310-345`

**Core pattern:** the budgeted parser charges each group and returns on errors; preserve this shape while converting number reads into `Result` values.

```moonbit
match budget.charge(@budget.ResourceCharge::new(...)) {
  Ok(_) => ()
  Err(_) => return Err(svg_error("svg-budget", "path command limit exceeded"))
}
```

**Unsafe behavior to replace:**

```moonbit
match @text.parse_double(s) {
  Ok(v) => (v, i)
  Err(_) => (0.0, i)
}
```

**Executor anchors:** make `read_number` (`:312-345`) return `Result[(Double, Int), CoreError]`; thread `Err` out of every command branch before `CanvasPath` is returned. Admit source tokens and every relative/reflected arithmetic result. Normalize smooth commands at `:188-250`: `S/s` consumes four values (not the current six reads at `:194-205`); `T/t` consumes two; reflect only after a compatible prior curve command. Retain budget accounting and the existing `CanvasPath` API.

---

### `modules/mb-svg/svg/scene.mbt` (parser / scene builder, request-response / transform)

**Analog:** `modules/mb-svg/svg/scene.mbt:380-498, 504-544, 650-857, 891-1017`

**Error propagation pattern:** the dispatcher already propagates `Result` values from a leaf builder.

```moonbit
match build_path(attrs, ctx, budget) {
  Ok(n) => n
  Err(e) => return Err(e)
}
```

**Absent-vs-explicit pattern:** keep `None` branches as the only default/inheritance path; turn every `Some(s)` parsing failure into `Err(e)`. The current anti-patterns are concrete:

```moonbit
Some(s) => match parse_length(s) {
  Ok(v) => v
  Err(_) => default
}
```

and

```moonbit
Some(s) => match parse_number_list(s) {
  Err(_) => []
  Ok(nums) => pair_points(nums)
}
```

**Executor anchors:**

- Change `build_svg_root_attrs` (`:650-685`) to `Result`, then propagate it from `build_svg_root` (`:285-308`). Omitted root attributes remain `None`; explicit malformed/range-invalid values do not become `None`.
- Change `build_paint`/`inherit_double` (`:726-857`) to `Result`, preserving `attr_get == None` inheritance and rejecting explicit numeric paint/dash failures. Thread it through group and every leaf builder.
- Change all geometry builders and `points_from_attrs` (`:891-967`) to `Result`, then update `build_element` (`:474-498`) to propagate their errors exactly as it already does for paths.
- Leave `parse_svg_with_budget` as the sole externally observable scene-returning boundary (`:175-...`); run the new no-drawing-list derived-value preflight before its final `Ok(SceneNode)`.

**Preflight source anchors (do not change lowerer contract):** mirror `lower_node` dispatch in `lower.mbt:40-88`, its viewBox arithmetic at `:160-190`, rounded-rect derivations at `:202-285`, ellipse sampling at `:303-325`, and `Affine2::apply_to_path` in `modules/mb-core/math/path.mbt:195-208`. The checker must verify derived affines/path scalars without allocating a `DrawingList`.

---

### Focused white-box test files (tests, transform/streaming/request-response)

**Analogs:**

- `parse_wbtest.mbt:102-119` — direct `Result` boundary tests for length/list/viewBox.
- `transform_wbtest.mbt:11-21, 161-207` — reusable finite-envelope predicates plus boundary and singular-transform assertions.
- `path_data_wbtest.mbt:90-149` — table-driven route coverage and `PathCommand` inspection.
- `scene_wbtest.mbt:337-415` — one finite fixture spanning source routes and an omitted-attribute control.
- `lower_wbtest.mbt:548-617` — parse first, lower only on `Ok(scene)`, inspect typed drawing operations.
- `numeric_contract_wbtest.mbt:5-30` — aggregate fixture loop that reports the failing case ID.

**Executor pattern:** add invalid-source, non-finite, out-of-envelope, and derived-overflow cases adjacent to the matching valid boundary coverage. Match `Err(e)` and assert typed fields; never assert complete rendered error prose. For rejected `parse_svg` cases, the `Err` branch itself is the proof that no scene/drawing list is available—do not call lowering there.

---

### `modules/mb-svg/svg/svg_test.mbt` (new public black-box test, request-response)

**Analog:** `modules/mb-core/error/error_test.mbt:1-37` (same `*_test.mbt` public-test convention) and `modules/mb-svg/svg/numeric_contract_wbtest.mbt:5-30` (same public SVG workflow).

**Typed error assertion pattern:**

```moonbit
inspect(error.category() == @error.ErrorCategory::Data, content="true")
inspect(error.code() == @error.ErrorCode::InvalidRange, content="true")
inspect(error.operation() == Some("svg"), content="true")
inspect(error.context() == Some("svg-numeric-derived"), content="true")
```

**Executor anchors:** add a compact black-box suite for `parse_svg` with one fixture per required public route family and the four stable contexts. Include the valid inclusive boundary and finite `scale(0)` control; use focused wbtests for scanner/state/derived implementation details.

## Shared Patterns

### Structured SVG errors

**Sources:** `modules/mb-svg/svg/svg.mbt:5-13`; `modules/mb-core/error/core_error.mbt:3-29, 47-72, 90-101, 135-137`  
**Apply to:** every parser/source-admission and derived-admission rejection.

```moonbit
@error.CoreError::new(
  @error.ErrorCategory::Data,
  @error.ErrorCode::InvalidRange,
  operation="svg",
  context="svg-numeric-derived",
)
```

Use accessors in tests (`category`, `code`, `operation`, `context`), not `render_error` text.

### Result propagation and omission behavior

**Sources:** `modules/mb-svg/svg/scene.mbt:380-389, 442-498, 970-985`; `modules/mb-svg/svg/length.mbt:46-70`  
**Apply to:** all parser ingress and scene-builder call chains.

```moonbit
match operation(...) {
  Ok(value) => use(value)
  Err(e) => return Err(e)
}
```

Only `attr_get(...) == None` chooses SVG defaults or inheritance. An explicit attribute must never enter an `Err(_) => default`, parent, `[]`, or `0.0` branch.

### Derived geometry preflight

**Sources:** `modules/mb-svg/svg/lower.mbt:40-88, 160-190, 202-325`; `modules/mb-core/math/affine.mbt:248-271`; `modules/mb-core/math/path.mbt:195-208`  
**Apply to:** root viewBox affine, group-transform composition, transformed coordinates/controls, rounded rect math, and sampled ellipse/circle paths.

Reproduce the deterministic arithmetic in a parser-side validator and pass every derived scalar through the shared derived-admission helper. Do not alter `lower_to_drawing_list(SceneNode) -> DrawingList`, layer order, or the canvas 16-layer capability policy.

### Tests across targets

**Sources:** `modules/mb-svg/moon.mod.json` (`supported-targets: +js+wasm+wasm-gc+native`); existing focused `*_wbtest.mbt` files.  
**Apply to:** the complete phase suite.

Run `moon test modules/mb-svg/svg --target all --frozen`; retain portable `Double::is_nan`, `Double::is_inf`, and `abs()` predicates used by `transform_wbtest.mbt:11-21`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `modules/mb-svg/svg/svg_test.mbt` | public black-box test | request-response | `mb-svg` currently has only white-box `*_wbtest.mbt`; `mb-core/error/error_test.mbt` is the nearest repository-wide public-test convention. |

## Metadata

**Analog search scope:** `modules/mb-svg/svg`, `modules/mb-core/error`, `modules/mb-core/math`  
**Files scanned:** 18 source/test/config files  
**Pattern extraction date:** 2026-07-26
