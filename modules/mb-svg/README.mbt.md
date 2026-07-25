---
moonbit:
  import:
    - path: tchivs/mb-canvas/canvas
      alias: canvas
    - path: tchivs/mb-svg/svg
      alias: svg
---

# mb-svg

`tchivs/mb-svg` parses a bounded subset of SVG into a typed scene tree and lowers it onto a `mb-canvas` drawing list, under [RFC 0002](../../docs/rfcs/0002-mb-svg.md). It does not rasterize; it is a pure parse-and-translate layer that turns SVG geometry, transforms, and style into canvas draw operations.

## Boundary

SVG owns **the document**: parsing SVG syntax into a typed scene tree, document structure, element and attribute semantics, `currentColor` resolution, and unit resolution. Canvas owns **the execution**: turning draw operations into pixels. SVG translates its scene tree into a canvas drawing list and then asks canvas to rasterize it.

## Status

`candidate` stability. Pure MoonBit across `js`, `wasm`, `wasm-gc`, and `native`. v0.1 scope (RFC 0002 §6.1): document structure (`svg`/`g`), basic shapes (`rect`/`circle`/`ellipse`/`line`/`polyline`/`polygon`), `path` with all commands, transforms (`matrix`/`translate`/`scale`/`rotate`/`skewX`/`skewY`), fill/stroke with solid colors, and opacity.

<!-- Runnable doctests will be added once the public parse/render API stabilizes. -->
