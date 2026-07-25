# Phase 96: SVG Boundary Parity Qualification - Pattern Map

**Mapped:** 2026-07-26
**Files analyzed:** 4 planned test-file modifications
**Analogs found:** 4 / 4

## Scope and File Classification

Phase 96 is a qualification-only phase.  It must not modify `geometry.mbt`,
`scene.mbt`, `lower.mbt`, a public API, numeric limits, or the structured-error
schema.  The checked seam and its parser/total-lowerer split were delivered by
Phase 95; this phase adds deterministic semantic evidence around that split.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-svg/svg/svg_test.mbt` | public API test | request-response / validation | same file, `assert_public_numeric_error` and derived-geometry cases | exact |
| `modules/mb-svg/svg/geometry_wbtest.mbt` | white-box seam test | transform / Result validation | same file, direct `checked_*` facts | exact |
| `modules/mb-svg/svg/lower_wbtest.mbt` | lowering compatibility test | transform / event-sequence | same file, manual-invalid fallback and DrawOp-order controls | exact |
| `modules/mb-svg/svg/portable_qualification_wbtest.mbt` | portable integration/raster test | transform / event-sequence | same file, layer/raster semantic controls | exact |

## Pattern Assignments

### `modules/mb-svg/svg/svg_test.mbt` (public API test, request-response / validation)

**Analog:** `modules/mb-svg/svg/svg_test.mbt:4-18, 148-190`

Append public parser fixtures here.  They must use exported `parse_svg` and
`CoreError` accessors only; `Err` is the no-`SceneNode`/no-lowering proof.  Keep
the exact four structured facts rather than asserting only that parsing failed.

```moonbit
fn assert_public_numeric_error(
  result : Result[SceneNode, @error.CoreError],
  code : @error.ErrorCode,
  context : String,
) -> Unit raise {
  match result {
    Ok(_) => inspect(false, content="true")
    Err(error) => {
      inspect(error.category() == @error.ErrorCategory::Data, content="true")
      inspect(error.code() == code, content="true")
      inspect(error.operation() == Some("svg"), content="true")
      inspect(error.context() == Some(context), content="true")
    }
  }
}
```

**Derived-rejection fixture shape** (`svg_test.mbt:171-188`):

```moonbit
for source in cases {
  // Err establishes that there is no parser-produced SceneNode to lower.
  assert_public_numeric_error(
    parse_svg(source),
    @error.ErrorCode::InvalidRange,
    "svg-numeric-derived",
  )
}
```

Use this for the source-facing rows of the parity matrix: viewBox translation,
group affine/child coordinate, rounded rectangle, circle/ellipse extrema, and
path/point-list coordinates.  Retain the existing explicit source-scalar rows
at `:21-46` as ingress-only controls (`svg-numeric-source`,
`svg-numeric-nonfinite`, or `svg-numeric-range`); they have no manually-built
lowerer counterpart.

**Positive compatibility shape** (`svg_test.mbt:50-88`): parse a finite
`scale(0)` and compact root-viewBox/default fixture, then lower only inside the
`Ok(scene)` branch and inspect DrawOps/affine components.  This is the explicit
guard against accidentally admitting local values before the singular transform
collapses them.

### `modules/mb-svg/svg/geometry_wbtest.mbt` (white-box seam test, transform / Result validation)

**Analog:** `modules/mb-svg/svg/geometry_wbtest.mbt:17-47, 51-85`

This is the narrow home for one table-driven or row-oriented semantic parity
matrix over package-private geometry facts.  Call the checked fact directly and
assert its `Result`; do not scan source text or recreate the arithmetic in a
second test oracle.

```moonbit
match checked_transform_point(
  @math.Affine2::scale(65536.0, 1.0),
  @math.Point2::new(2.0, 0.0),
) {
  Ok(_) => inspect(false, content="true")
  Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
}
```

Follow the existing direct-fact coverage (`:24-38`, `:52-78`) for each geometry
family: `checked_viewbox_transform`, `checked_compose_affine`,
`checked_transform_point`, `checked_rect_path`, circle/ellipse/line builders,
polyline/polygon builders, and `checked_canvas_path` plus `checked_path_points`
where the boundary is reached after construction.  For the finite compatibility
sentinel, reuse the exact post-transform assertion (`:32-34`):

```moonbit
match checked_transform_point(
  @math.Affine2::scale(0.0, 0.0),
  @math.Point2::new(65536.0, -65536.0),
) {
  Ok(point) => inspect((point.x(), point.y()), content="(0, 0)")
  Err(_) => inspect(false, content="true")
}
```

The seam check complements, but does not replace, the public parser fixture:
the two should observe the same derived-error context, while only the parser
assertion establishes no public `SceneNode` was published.

### `modules/mb-svg/svg/lower_wbtest.mbt` (lowering compatibility test, transform / event-sequence)

**Analog:** `modules/mb-svg/svg/lower_wbtest.mbt:621-633, 691-729`

Keep the parser-negative check and the manual-invalid lowerer check separate.
The parser row checks `Err(error)`; the manual `SceneNode` row deliberately
calls the total lowerer and verifies its deterministic identity/empty-path
sentinel and unchanged layer order.

```moonbit
let first = lower_to_drawing_list(invalid_scene)
let second = lower_to_drawing_list(invalid_scene)
inspect((first.length(), second.length()), content="(8, 8)")
for list in [first, second] {
  match (list.get(0), list.get(1), list.get(2), list.get(3)) {
    (Some(PushLayer(0.25)), Some(Fill(rect, _)), Some(Stroke(_, _, _)), Some(PopLayer)) =>
      inspect(rect.length(), content="0")
    _ => inspect(false, content="true")
  }
}
```

Copy the constructor pattern at `:692-710`: obtain the existing `paint` from a
valid parsed fixture, then construct an invalid `SvgRoot`, `Rect`, or
`CanvasPath` explicitly.  This keeps the fallback test visibly outside parser
provenance.  Assert no `PushTransform` for an identity root fallback where
applicable, and retain `PushLayer → Fill/Stroke → PopLayer` order; a non-empty
list is not sufficient evidence.

For the RFC 0008 operation-only regression, retain the exact nesting check at
`:548-580`:

```moonbit
match (list.get(1), list.get(2), list.get(4), list.get(5)) {
  (Some(PushLayer(group_opacity)), Some(PushLayer(element_opacity)), Some(PopLayer), Some(PopLayer)) =>
    inspect((group_opacity, element_opacity), content="(0.5, 0.25)")
  _ => inspect(false, content="true")
}
```

### `modules/mb-svg/svg/portable_qualification_wbtest.mbt` (portable integration/raster test, transform / event-sequence)

**Analog:** `modules/mb-svg/svg/portable_qualification_wbtest.mbt:174-260, 291-377`

This is the all-target semantic raster home.  Preserve the operation sequence
and pixel assertions for group/element opacity; they embody RFC 0008's isolated
offscreen composition rather than only checking a list length.

```moonbit
match (list.get(0), list.get(1), list.get(2), list.get(3), list.get(4), list.get(5), list.get(6), list.get(7)) {
  (Some(PushTransform(_)), Some(PushLayer(group)), Some(PushLayer(element)), Some(Fill(_, _)), Some(Stroke(_, _, _)), Some(PopLayer), Some(PopLayer), Some(PopTransform)) =>
    inspect((group, element), content="(0.5, 0.5)")
  _ => inspect(false, content="true")
}
```

Then render to both opaque and transparent images and inspect deterministic
pixels (`:210-257`).  Preserve the existing 16-success/17-structured-failure
depth controls (`:318-377`); RFC 0008 specifies the bounded 16-layer contract.
Use `:263-272` as the portable form of a parser rejection before lowering or
rasterization when a phase-level end-to-end rejection control is needed.

## Shared Patterns

### Fail-closed parser publication

**Source:** `modules/mb-svg/svg/scene.mbt:206-220, 255-324`
**Apply to:** all public unsafe-source fixtures

`parse_svg` only returns `Ok(node)` after `preflight_scene(node)` succeeds;
every node family propagates an error from a checked geometry fact.  Public
tests must represent failure as `parse_svg(source) -> Err(CoreError)`, never as
an empty drawing list or a call to lowering after a failed parse.

### Checked Result seam

**Source:** `modules/mb-svg/svg/geometry.mbt:38-118, 121-250`
**Apply to:** parity rows in `geometry_wbtest.mbt`

The seam's `checked_*` functions are the sole numeric oracle.  Compare the
observable structured result/context with the paired public source fixture;
do not duplicate formulas, compare implementation text, or use timing.

### Total manual-value fallback

**Source:** `modules/mb-svg/svg/lower.mbt:91-128`
**Apply to:** explicit manually-built `SceneNode` controls only

`checked_viewbox_transform` failure becomes identity; invalid checked paths
become `@math.Path2::new()`.  The public `lower_to_drawing_list` signature is
total (`lower.mbt:33-36`), so test DrawOp sentinels and ordering, not errors.

### RFC 0008 opacity/layer semantics

**Source:** `modules/mb-svg/svg/lower.mbt:59-75, 139-170`; `docs/rfcs/0008-mb-canvas-layer.md:47-52, 110-117`
**Apply to:** `lower_wbtest.mbt` and `portable_qualification_wbtest.mbt`

Group layers order as `PushTransform, [PushLayer], children, [PopLayer],
PopTransform`; element layers wrap both fill and stroke.  Keep DrawOp order,
semantic pixels, and the 16-layer bound as explicit regressions.

### Target-neutral qualification command

**Source:** `modules/mb-svg/moon.mod.json` (`supported-targets` is
`+js+wasm+wasm-gc+native`)
**Apply to:** final phase verification

```text
moon test modules/mb-svg/svg --target all --frozen
```

This single package command is the acceptance gate for wasm, wasm-gc, js, and
native.  Do not add separate timing scripts or target-specific snapshots.

## No Analog Found

None.  All Phase 96 work has an exact test-file analog; no new production
module, fixture format, public API, error type, or target harness is warranted.

## Metadata

**Analog search scope:** `modules/mb-svg/svg`, `modules/mb-svg/moon.mod.json`,
Phase 95 artifacts, RFC 0008
**Files scanned:** 14 source, test, planning, module, and RFC artifacts
**Pattern extraction date:** 2026-07-26
