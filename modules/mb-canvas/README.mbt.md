---
moonbit:
  import:
    - path: tchivs/mb-core/math
      alias: math
    - path: tchivs/mb-canvas/canvas
      alias: canvas
---

# mb-canvas

`tchivs/mb-canvas` turns vector geometry into pixels, deterministically and on every target, under [RFC 0003](../../docs/rfcs/0003-mb-canvas.md). It owns the drawing-list contract and the portable coverage-antialiased rasterizer; it borrows `mb-image` mutable raster surfaces as its write target and delegates raster-layer compositing to `mb-image/ops`.

## Boundary

Canvas owns **the production of a raster from vector geometry**: the drawing list, path flattening, transform evaluation, scanline coverage rasterization, and stroke expansion. It does **not** own pixel storage (that is `mb-image`), color representation (`mb-color`), or any document format.

The cut: if the operation takes two rasters and produces a raster, it belongs to `mb-image/ops`. If the operation takes geometry and produces pixels into a raster, it belongs to `mb-canvas`.

## The drawing list

The primary contract is a portable, pure-data, append-only sequence of operations. It is deterministic, inspectable, and buildable without rendering — a render is one operation on a list, not the only way to interact.

```moonbit
///|
test "build and inspect a drawing list" {
  // A red filled rectangle under a translate, then a green stroke.
  let rect = @canvas.CanvasPath::new()
  rect.rect(0.0, 0.0, 10.0, 10.0)
  let line = @canvas.CanvasPath::new()
  line.move_to(0.0, 0.0)
  line.line_to(20.0, 20.0)
  let list = @canvas.DrawingList::new()
  list.push_transform(@math.Affine2::translate(5.0, 5.0))
  list.push_fill(rect.to_path2(), @canvas.FillStyle::new(1.0, 0.0, 0.0))
  list.pop_transform()
  list.push_stroke(
    line.to_path2(),
    @canvas.StrokeStyle::new(2.0),
    @canvas.FillStyle::new(0.0, 1.0, 0.0),
  )
  // The list records four operations in order.
  inspect(list.length(), content="4")
}
```

## Rendering

`render(list, target, budget)` rasterizes the list into an `mb-image` `OwnedImage`, writing pixels through `MutImageView::set_byte` under the target's format. Coverage is computed via 4×4 supersampling; color is resolved through `mb-color` with Porter-Duff source-over compositing. See `canvas/render_wbtest.mbt` for end-to-end pixel assertions on RGB8 and straight-RGBA8 targets.

```moonbit
///|
test "FillStyle and StrokeStyle defaults" {
  let f = @canvas.FillStyle::new(0.2, 0.4, 0.6)
  inspect(f.color_a, content="1")
  inspect(f.rule == @canvas.FillRule::Nonzero, content="true")
  let s = @canvas.StrokeStyle::new(3.0)
  inspect(s.width, content="3")
  inspect(s.cap == @canvas.LineCap::Butt, content="true")
  inspect(s.join == @canvas.LineJoin::Miter, content="true")
}
```

## Status

`candidate` stability. Pure MoonBit across `js`, `wasm`, `wasm-gc`, and `native`. v0.1 scope (RFC 0003 §7.1): drawing list with fill/stroke/transform/clip, line and Bézier geometry, nonzero/even-odd fill, coverage antialiasing, solid color fill/stroke. Round cap/join, miter joins, and dash are partial in v0.1 (strokes use all-bevel offsets for geometric safety) and will be refined in a follow-up.
