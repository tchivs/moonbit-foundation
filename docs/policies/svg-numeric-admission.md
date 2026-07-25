# SVG Numeric Admission Policy

## Status

Phase 91 publishes the target-neutral numeric contract for the supported
`mb-svg` subset. It records the boundary that Phase 92 must enforce before a
`SceneNode` exists; it does not change current parser, lowering, canvas, or
opacity behavior.

## Required numeric contract

`SVG_NUMERIC_LIMIT = 65536.0`. A scalar is admitted only when it is neither
`NaN` nor infinite and is within the inclusive interval
`[-65536.0, 65536.0]`.

The limit is derived from the existing default SVG resource budget, whose
width and height ceilings are both `65536UL`; it is not a generic maximum
`Double` policy. The same predicate applies to source scalars and to every
derived scalar or affine component produced while constructing SVG geometry.

Finite determinant-zero transforms remain admitted. In particular,
`scale(0)` is a valid finite transform: non-invertibility alone is not numeric
unsafety.

## Ownership boundary

Numeric validation belongs at SVG ingress and derived arithmetic before a
validated `SceneNode` can be returned. `lower_to_drawing_list` remains a total
consumer of a valid scene. `mb-canvas` retains ownership of RFC 0008 layer
allocation, compositing, and group/element opacity semantics; this policy does
not move that responsibility into SVG numeric admission.

## Observable outcome

The package-local numeric-contract tracer parses an SVG containing the
inclusive coordinate boundary and a finite singular transform, lowers the
successful scene, and observes a non-empty drawing list on `js`, `wasm`,
`wasm-gc`, and `native`.
