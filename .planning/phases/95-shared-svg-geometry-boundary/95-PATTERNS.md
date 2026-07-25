# Phase 95: Shared SVG Geometry Boundary - Pattern Map

**Mapped:** 2026-07-26  
**Files classified:** 5 implementation/test files; 4 regression sentinels  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-svg/svg/geometry.mbt` | utility (package-private domain geometry) | transform | `scene.mbt` checked preflight + `lower.mbt` path builders | composite exact responsibility match |
| `modules/mb-svg/svg/scene.mbt` | parser/preflight boundary | request-response / transform | its existing `preflight_node` walker | exact |
| `modules/mb-svg/svg/lower.mbt` | lowering service | transform | its existing `lower_node` / total public wrapper | exact |
| `modules/mb-svg/svg/geometry_wbtest.mbt` | white-box test | transform | `transform_wbtest.mbt` numeric-fact tests | role-match |
| `modules/mb-svg/svg/lower_wbtest.mbt` | white-box compatibility test | transform | its existing operation/path assertions | exact |

The seam is an internal `Result[..., @error.CoreError]` authority. It must not be `pub`, add imports, alter `SceneNode`/`SvgRoot`, or expose a `Result` from `lower_to_drawing_list`.

## Pattern Assignments

### `modules/mb-svg/svg/geometry.mbt` (new package-private utility, checked transform)

**Responsibility:** become the single checked authority for root viewBox mapping, affine composition and point admission, and construction of rect/circle/ellipse/line/polyline/polygon/path facts. It returns existing numeric errors so parser preflight can fail before publication; lowerer calls total adapters around these facts only.

**Primary checked-arithmetic analog:** `modules/mb-svg/svg/scene.mbt` lines 324-395. Preserve the stepwise admission rather than applying an unchecked `Affine2::compose` result.

```moonbit
fn scene_product_sum(a : Double, b : Double, c : Double, d : Double) -> Result[Double, @error.CoreError] {
  let left = match scene_derived_mul(a, b) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let right = match scene_derived_mul(c, d) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  scene_derived_add(left, right)
}
```

**Numeric/error pattern:** `modules/mb-svg/svg/transform.mbt` lines 193-217. Reuse the existing package-private `admit_derived`/`admit_affine` path and its stable `svg-numeric-derived` error; do not create another limit or error context.

```moonbit
fn admit_derived(value : Double) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() || value.abs() > 65536.0 {
    Err(svg_numeric_error(@error.ErrorCode::InvalidRange, "svg-numeric-derived"))
  } else {
    Ok(value)
  }
}

fn compose_transforms(first : @math.Affine2, second : @math.Affine2) -> Result[@math.Affine2, @error.CoreError] {
  admit_affine(first.compose(second))
}
```

**ViewBox algorithm to move mechanically:** `modules/mb-svg/svg/scene.mbt` lines 398-483 is the checked version; `modules/mb-svg/svg/lower.mbt` lines 160-190 is the duplicate valid-output implementation. Preserve identity for absent/non-positive inputs, `none` non-uniform scale, and the current meet/slice branch order. The geometry helper must admit every intermediate `Double` before building its `Affine2`.

**Shape/path construction to move mechanically:** `modules/mb-svg/svg/lower.mbt` lines 202-359. Preserve the sharp-rect fast path, rounded-rect clamp/ratio ordering, `0.5522847498307936` kappa, and 32-sample circle/ellipse paths. A checked builder must retain those command forms while returning `Err` when a derived coordinate overflows.

```moonbit
fn circle_path(cx : Double, cy : Double, r : Double) -> @math.Path2 {
  polygon_ellipse_path(cx, cy, r, r, 32)
}

fn polygon_path(pts : Array[@math.Point2]) -> @math.Path2 {
  let p = polyline_path(pts)
  p.push(@math.PathCommand::Close)
  p
}
```

**Point/path admission to centralize:** `modules/mb-svg/svg/scene.mbt` lines 601-671. Match every `MoveTo`, `LineTo`, `QuadTo`, and `CubicTo` coordinate through the checked affine component calculation; `Close` has no point. This is the required authority for parsed `<path>` data as well as generated primitives.

### `modules/mb-svg/svg/scene.mbt` (modified parser/preflight boundary, request-response/transform)

**Analog:** `modules/mb-svg/svg/scene.mbt` lines 255-321.

Keep traversal and `Result` propagation here, but replace local `scene_derived_*`, `preflight_compose`, `preflight_viewbox_transform`, primitive preflights, and point arithmetic with calls into `geometry.mbt`. The parser remains the publication boundary: `parse_svg_with_budget` already publishes only after `preflight_scene` succeeds (lines 175-214).

```moonbit
Svg(root, children) => {
  let map = match preflight_viewbox_transform(root) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let next = match preflight_compose(current, map) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  preflight_children(children, next)
}
```

**Required preservation:** keep the early-return propagation shape above. A source-valid but derived-invalid viewBox, group transform, rounded rect, ellipse, or path point must still produce the same `Data`/`InvalidRange` error with `svg` and `svg-numeric-derived` before any `SceneNode` is returned.

### `modules/mb-svg/svg/lower.mbt` (modified total lowering service, transform)

**Analog:** `modules/mb-svg/svg/lower.mbt` lines 33-88.

Keep public lowerer total and retain all DrawOp/style/layer emission in this file. Replace only `viewbox_transform` and shape builder calls with the shared geometry seam through explicit deterministic non-panicking adapters for manually created invalid scenes. Parser-produced scenes must continue to take the checked `Ok` route.

```moonbit
pub fn lower_to_drawing_list(root : SceneNode) -> @canvas.DrawingList {
  let list = @canvas.DrawingList::new()
  lower_node(root, list)
  list
}

Group(transform, opacity, children) => {
  list.push_transform(transform)
  let layered = opacity < 1.0
  if layered { list.push_layer(opacity) }
  for i = 0; i < children.length(); i = i + 1 { lower_node(children[i], list) }
  if layered { list.pop_layer() }
  list.pop_transform()
}
```

**Do not move:** `emit_shape` and its style/layer policy at `lower.mbt` lines 94-132. The order of `PushTransform`, optional `PushLayer`, fills/strokes, `PopLayer`, and `PopTransform` is the RFC 0008 compatibility contract, not geometry ownership.

### `modules/mb-svg/svg/geometry_wbtest.mbt` (new white-box test, transform)

**Analog:** `modules/mb-svg/svg/transform_wbtest.mbt` lines 161-207 for direct private numeric/affine fact assertions, and `modules/mb-svg/svg/lower_wbtest.mbt` lines 548-617 for derived geometry command assertions.

Use direct calls to the package-private checked seam—never source-text duplication checks. Follow the existing `match Result` style and inspect plain values/error context.

```moonbit
match parse_transform("scale(0,65536)") {
  Ok(m) => {
    inspect((m.a(), m.d()), content="(0, 65536)")
    match m.inverse() {
      None => inspect(true, content="true")
      Some(_) => inspect(false, content="true")
    }
  }
  Err(_) => inspect(false, content="true")
}
```

Cover direct checked facts for: viewBox `meet`/`slice`/`none` and identity defaults; affine composition and point/path-command admission; sharp and rounded rect; 32-sample circle/ellipse; line/polyline/polygon; `Path2` traversal; finite singular affine acceptance; and one derived-overflow `Err` with `Some(svg-numeric-derived)`.

### `modules/mb-svg/svg/lower_wbtest.mbt` (modified compatibility test, transform)

**Analog:** `modules/mb-svg/svg/lower_wbtest.mbt` lines 331-465 and 548-632.

Extend only if the direct seam tests do not already exercise a valid parse-to-lower family. Retain operation-level assertions rather than snapshots: inspect concrete transform components, `Path2` command counts, and exact layer positions.

```moonbit
match parse_svg("<svg viewBox=\"0 0 100 50\" width=\"200\" height=\"200\" preserveAspectRatio=\"none\"><rect width=\"1\" height=\"1\"/></svg>") {
  Ok(scene) => {
    let list = lower_to_drawing_list(scene)
    match list.get(0) {
      Some(PushTransform(t)) => {
        inspect(t.a(), content="2")
        inspect(t.d(), content="4")
      }
      other => inspect("other", content="other")
    }
  }
  Err(_) => inspect("err", content="ok")
}
```

## Shared Patterns

### Numeric admission and error identity

**Source:** `modules/mb-svg/svg/svg.mbt` lines 15-44; `modules/mb-svg/svg/transform.mbt` lines 193-217.  
**Apply to:** `geometry.mbt`, then parser preflight via its `Result`.

- Source values remain finite and within the inclusive `[-65536.0, 65536.0]` envelope.
- Derived values use the existing `svg-numeric-derived` `InvalidRange` error.
- A determinant/inverse check is prohibited: finite `scale(0)` remains valid.

### Fail-closed parser / total lowerer boundary

**Source:** `modules/mb-svg/svg/scene.mbt` lines 175-214 and `modules/mb-svg/svg/lower.mbt` lines 33-37.  
**Apply to:** the two consumers of the new seam.

The parser propagates `Err` before scene publication. The public lowerer never exposes that `Result`, unwraps, or panics; any fallback for invalid manually constructed nodes must be deterministic and preserve valid parsed output unchanged.

### Semantic regression style

**Source:** `modules/mb-svg/svg/conformance_wbtest.mbt` lines 148-179.  
**Apply to:** phase end-to-end coverage.

```moonbit
match parse_svg(svg) {
  Err(_) => failures = failures + 1
  Ok(scene) => {
    let list = lower_to_drawing_list(scene)
    let has_ops = list.length() > 0
    if has_ops != expect_shape_op { failures = failures + 1 }
  }
}
```

### Rendering/layer boundary

**Source:** `modules/mb-svg/svg/portable_qualification_wbtest.mbt` lines 174-193 and 318-365.  
**Apply to:** preserve, do not refactor, in `lower.mbt`.

Geometry extraction must not affect isolated group/element opacity output or the 16-success/17-atomic-failure layer behavior. These are regression gates, not files expected to change.

## Regression Sentinels (no modification expected)

| File | Existing control to run | Why it stays unchanged |
|---|---|---|
| `modules/mb-svg/svg/numeric_contract_wbtest.mbt` | lines 5-42 | Keeps finite endpoint, `scale(0)`, defaults, and total lowering visible. |
| `modules/mb-svg/svg/svg_test.mbt` | lines 4-18, 50-59, 142-160 | Public error facts and fail-before-scene timing remain public API regressions. |
| `modules/mb-svg/svg/conformance_wbtest.mbt` | lines 18-132, 148-179 | Compact valid transform/viewBox/shape/path matrix remains end-to-end coverage. |
| `modules/mb-svg/svg/portable_qualification_wbtest.mbt` | lines 119-139, 174-225, 318-365 | Preserves raster semantics, opacity ordering, and layer-depth capability behavior across targets. |

## No Analog Found

None. The new file is an extraction of existing package-private checked preflight and lowerer geometry; it does not introduce a new architectural role.

## Metadata

**Analog search scope:** `modules/mb-svg/svg` production and focused test files  
**Files scanned:** 11  
**Pattern extraction date:** 2026-07-26
