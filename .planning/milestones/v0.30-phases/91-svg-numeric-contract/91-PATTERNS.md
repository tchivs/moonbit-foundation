# Phase 91: SVG Numeric Contract - Pattern Map

**Mapped:** 2026-07-25  
**Files analyzed:** 7 planned files  
**Analogs found:** 7 / 7

## Scope Boundary

Phase 91 creates the published numeric-admission policy and its executable route-matrix evidence. It must not change `length.mbt`, `path_data.mbt`, `transform.mbt`, `scene.mbt`, `lower.mbt`, or `mb-canvas`: the fallible parser/scene migration is Phase 92. The planned test cases may therefore describe the acceptance contract and valid-boundary/non-regression controls without landing assertions that intentionally leave the branch red.

The codebase-memory graph was queried first as required by `AGENTS.md`, but has no nodes under `modules/mb-svg/svg`; the analog search below therefore uses direct source inspection.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `docs/policies/svg-numeric-admission.md` | documentation / policy | static contract | `docs/policies/targets.md` | exact |
| `modules/mb-svg/svg/numeric_contract_wbtest.mbt` | test | transform (SVG text -> `Result` -> scene/lower) | `modules/mb-svg/svg/conformance_wbtest.mbt` | exact |
| `modules/mb-svg/svg/parse_wbtest.mbt` | test | request-response | itself, existing parser-result tests | exact |
| `modules/mb-svg/svg/path_data_wbtest.mbt` | test | transform | itself, existing path parser tests | exact |
| `modules/mb-svg/svg/transform_wbtest.mbt` | test | transform | itself, existing affine parser/composition tests | exact |
| `modules/mb-svg/svg/scene_wbtest.mbt` | test | request-response | itself, existing scene/default/inheritance tests | exact |
| `modules/mb-svg/svg/lower_wbtest.mbt` | test | transform | itself, existing scene-to-drawing-list controls | exact |

## Pattern Assignments

### `docs/policies/svg-numeric-admission.md` (documentation / static contract)

**Analog:** `docs/policies/targets.md`

Use the short policy-document form: title, `## Status`, a compact contract table, explicit out-of-scope ownership, then `## Observable outcome`. The closest policy file states a rule in prose followed by a machine-verifiable outcome rather than duplicating implementation details.

**Document structure** ([`docs/policies/targets.md`](../../../docs/policies/targets.md:1), lines 1-25):

```markdown
# Target Support Policy

## Status

## Required scope

| Package category | Contract |
|---|---|

## Out of scope

## Observable outcome
```

For this policy, document the inclusive `[-65536.0, 65536.0]` envelope, rejection of explicit malformed/non-finite/out-of-range/unsafe-derived values, the four stable error fields (`category`, `code`, `operation`, `context`), accepted singular finite transforms, and the source/derived route matrix. State that canvas/layer ownership remains outside the policy.

---

### `modules/mb-svg/svg/numeric_contract_wbtest.mbt` (test / transform)

**Analog:** `modules/mb-svg/svg/conformance_wbtest.mbt`

Use package-local white-box tests with inline tuple data, a single table-driven runner, explicit `Result` matching, and an aggregate failure count. Keep the cases inline: the repository convention recorded in this analog is that fixture JSON is normative/reference data, not read at test runtime.

**Table declaration** ([`conformance_wbtest.mbt`](../../../modules/mb-svg/svg/conformance_wbtest.mbt:14), lines 14-18):

```moonbit
// A canonical/edge case: (fixture_id, svg_source, expect_shape_op).
fn ok_cases() -> Array[(String, String, Bool)] {
  [
```

**Aggregate runner** ([`conformance_wbtest.mbt`](../../../modules/mb-svg/svg/conformance_wbtest.mbt:148), lines 148-178):

```moonbit
test "conformance: every canonical/edge case parses and lowers without error" {
  let cases = ok_cases()
  let mut failures = 0
  for case in cases {
    let (id, svg, expect_shape_op) = case
    match parse_svg(svg) {
      Err(_) => {
        println("conformance parse failed: " + id)
        failures = failures + 1
      }
      Ok(scene) => {
        let list = lower_to_drawing_list(scene)
        let has_ops = list.length() > 0
        if has_ops != expect_shape_op {
          failures = failures + 1
        }
      }
    }
  }
  inspect(failures, content="0")
  inspect(cases.length() > 0, content="true")
}
```

Define route tuples that include an identifier, source SVG/lexical input, ingress or derivation route, expected class, and whether the case is a Phase-91 documented control or an activated Phase-92 rejection assertion. Cover length/list, path, relative arithmetic, viewBox mapping, transform construction/composition, rotate/skew, scene geometry/style/colour, and valid-boundary lowering. Do not use error-message snapshots.

---

### `modules/mb-svg/svg/parse_wbtest.mbt` (test / request-response)

**Analog:** existing `modules/mb-svg/svg/parse_wbtest.mbt`

Append focused lexical controls beside the existing `parse_length`, `parse_viewbox`, and `parse_number_list` examples. Match `Result` locally and inspect only plain, showable values or booleans.

**Result-match style** ([`parse_wbtest.mbt`](../../../modules/mb-svg/svg/parse_wbtest.mbt:55), lines 55-67):

```moonbit
test "parse_length plain and unit-suffixed" {
  match parse_length("100") {
    Ok(v) => inspect(v, content="100")
    Err(_) => inspect(false, content="true")
  }
}
```

**List-parser coverage style** ([`parse_wbtest.mbt`](../../../modules/mb-svg/svg/parse_wbtest.mbt:83), lines 83-99):

```moonbit
match parse_number_list("1,2,3") {
  Ok(arr) => inspect(arr, content="[1, 2, 3]")
  Err(_) => inspect(false, content="true")
}
```

Add `-65536`, `65536`, just-outside finite values, and malformed/non-finite token controls here; retain colour-specific functional-component rows in the new route matrix or the existing colour section, not in a new production helper.

---

### `modules/mb-svg/svg/path_data_wbtest.mbt` (test / transform)

**Analog:** existing `modules/mb-svg/svg/path_data_wbtest.mbt`

Extend the compact command-family tests rather than introduce a duplicate parser harness. Each test directly calls `parse_path_data` and checks success or failure through `Result` matching.

**Command-family pattern** ([`path_data_wbtest.mbt`](../../../modules/mb-svg/svg/path_data_wbtest.mbt:25), lines 25-30):

```moonbit
test "parse_path_data relative m l" {
  match parse_path_data("m 10 20 l 5 5") {
    Ok(_) => inspect(true, content="true")
    Err(_) => inspect(false, content="true")
  }
}
```

**Shape assertion pattern** ([`path_data_wbtest.mbt`](../../../modules/mb-svg/svg/path_data_wbtest.mbt:4), lines 4-12):

```moonbit
match parse_path_data("M 0 0 L 10 0 L 10 10 Z") {
  Ok(p) => inspect(p.to_path2().length(), content="4")
  Err(_) => inspect(false, content="true")
}
```

Use one relative-addition overflow/unsafe-derived control and representative `M/L/H/V/C/Q/S/T/A` source routes. Preserve the current valid arc control—v0.1 approximates it as a line—and avoid asserting renderer behaviour here.

---

### `modules/mb-svg/svg/transform_wbtest.mbt` (test / transform)

**Analog:** existing `modules/mb-svg/svg/transform_wbtest.mbt`

Reuse the `parse_transform` + `Affine2` accessor form. Add policy controls for coefficient construction/composition and trigonometry, but preserve finite singular transforms as valid.

**Composition assertion** ([`transform_wbtest.mbt`](../../../modules/mb-svg/svg/transform_wbtest.mbt:53), lines 53-66):

```moonbit
match parse_transform("translate(10,0) scale(2)") {
  Ok(m) => {
    let p = m.apply(@math.Point2::new(1.0, 0.0))
    inspect((p.x(), p.y()), content="(12, 0)")
  }
  Err(_) => inspect(false, content="true")
}
```

**Trigonometric tolerance form** ([`transform_wbtest.mbt`](../../../modules/mb-svg/svg/transform_wbtest.mbt:90), lines 90-99):

```moonbit
match parse_transform("rotate(90)") {
  Ok(m) => {
    let p = m.apply(@math.Point2::new(1.0, 0.0))
    inspect((p.x().abs() < 1.0e-9, (p.y() - 1.0).abs() < 1.0e-9), content="(true, true)")
  }
  Err(_) => inspect(false, content="true")
}
```

Add an explicit `scale(0)` success control. Do not copy the existing inversion test as a numeric-admission predicate: `inverse()` is only appropriate for the existing inverse-composition assertion, not rejection of determinant-zero matrices.

---

### `modules/mb-svg/svg/scene_wbtest.mbt` (test / request-response)

**Analog:** existing `modules/mb-svg/svg/scene_wbtest.mbt`

Keep scene-level tests at the public `parse_svg` boundary and destructure typed nodes only for successful controls. This is the correct home for the explicit-versus-absent attribute pairs, geometry/style ingress, points, inheritance, and `viewBox` source controls.

**Public boundary plus destructuring** ([`scene_wbtest.mbt`](../../../modules/mb-svg/svg/scene_wbtest.mbt:15), lines 15-27):

```moonbit
match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"10\" height=\"20\"/>") {
  Ok(Svg(root, _)) => {
    inspect(root.width, content="Some(10)")
    inspect(root.height, content="Some(20)")
  }
  Ok(_) => inspect(false, content="true")
  Err(_) => inspect("err", content="ok")
}
```

**Inheritance control** ([`scene_wbtest.mbt`](../../../modules/mb-svg/svg/scene_wbtest.mbt:175), lines 175-183):

```moonbit
test "inherited fill flows from <g> to a child rect that omits fill" {
  match parse_svg("<svg><g fill=\"red\"><rect width=\"1\" height=\"1\"/></g></svg>") {
```

Follow the file’s opening warning: do not `inspect` `CoreError` or use `abort()` in these scene tests. For active Phase-92 error tests, inspect the error’s typed fields in the `Err(error)` branch; use a boolean/tuple of those fields rather than rendered diagnostics.

---

### `modules/mb-svg/svg/lower_wbtest.mbt` (test / transform)

**Analog:** existing `modules/mb-svg/svg/lower_wbtest.mbt`

This file is only for valid-scene non-regression evidence: parse, lower, then inspect recorded `DrawOp` sequence/fields. It must not transfer numeric admission responsibility into lowering.

**Layer-sequence assertion** ([`lower_wbtest.mbt`](../../../modules/mb-svg/svg/lower_wbtest.mbt:498), lines 498-515):

```moonbit
match parse_svg("<svg><g opacity=\"0.5\"><rect width=\"1\" height=\"1\"/></g></svg>") {
  Ok(scene) => {
    let list = lower_to_drawing_list(scene)
    inspect(list.length(), content="5")
    match list.get(1) {
      Some(PushLayer(op)) => inspect(op, content="0.5")
      other => inspect("other", content="other")
    }
    match list.get(3) {
      Some(PopLayer) => inspect("pop", content="pop")
      other => inspect("other", content="other")
    }
  }
  Err(_) => inspect("err", content="ok")
}
```

Add only valid `±65536` / singular-transform controls that prove a validated scene still lowers. Retain the group and element opacity controls unchanged, satisfying the RFC 0008 ownership boundary.

## Shared Patterns

### White-box test layout

**Sources:** `modules/mb-svg/svg/*_wbtest.mbt`  
**Apply to:** all six test files.

- Tests use `///|` before each `test` declaration.
- Match `Result` directly; `CoreError` is deliberately not `Show`-able.
- A test that requires repeated case coverage uses an inline `Array[(...)]`, a failure counter, `println` with the case id for triage, and `inspect(failures, content="0")`.
- Keep package-private parser/builder coverage in `*_wbtest.mbt`; Phase 91 does not add a public test API.

### Structured error assertions

**Sources:** `modules/mb-core/error/core_error.mbt` lines 3-16, 49-60, 90-135; `modules/mb-svg/svg/svg.mbt` lines 5-12.  
**Apply to:** Phase-92-activated rejection cases described by `numeric_contract_wbtest.mbt`, `parse_wbtest.mbt`, `path_data_wbtest.mbt`, `transform_wbtest.mbt`, and `scene_wbtest.mbt`.

The error type exposes typed `category()`, `code()`, `operation()`, and `context()` accessors. Assert exactly those stable fields. The existing SVG factory is the project seam for `ErrorCategory::Data`, `operation="svg"`, and a context string:

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

The policy must deliberately require route-stable context identifiers, not `render_error` or full message-prose snapshots. The implementation will need the same factory style with `InvalidRange` where the documented range/derived route requires it.

### Quantitative-bound basis

**Sources:** `modules/mb-svg/svg/bounds_wbtest.mbt` lines 1-18; `modules/mb-svg/svg/scene.mbt` lines 218-227; `modules/mb-svg/svg/path_data.mbt` lines 348-360.  
**Apply to:** policy envelope rationale and numeric route cases.

The existing tight-budget test constructs `@budget.ResourceLimits::new(...)` explicitly, while SVG’s default scene and path budgets independently set `width=65536UL` and `height=65536UL`. Document that the symmetric scalar envelope is derived from those existing resource limits; do not invent a generic maximum-`Double` policy or alter the resource-budget tests.

### Ownership boundary

**Sources:** `modules/mb-svg/svg/lower_wbtest.mbt` lines 498-545; `modules/mb-svg/svg/lower.mbt` lines 160 onward.  
**Apply to:** all route-matrix rows that reach viewBox/lowering.

`parse_svg` produces the typed scene, and `lower_to_drawing_list` is tested as a total consumer of valid scenes. Keep numeric rejection before a usable `SceneNode`; use lowering only to prove valid boundary scenes and existing opacity/layer output remain intact.

## No Analog Found

None. The repository has direct policy-document, table-driven conformance, targeted parser, scene, transform, and lowering analogs for every planned file.

## Metadata

**Analog search scope:** `docs/policies/`, `modules/mb-svg/svg/`, `modules/mb-core/error/`, `modules/mb-core/math/`  
**Files scanned:** 16  
**Pattern extraction date:** 2026-07-25
