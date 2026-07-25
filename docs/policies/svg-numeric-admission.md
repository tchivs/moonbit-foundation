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

## Explicit values and stable errors

An explicitly present malformed, non-finite, out-of-envelope, or unsafe
derived value has the structured SVG outcome below. Only an absent attribute
may choose the existing SVG default or inheritance branch. This distinction is
part of the contract: an explicit invalid value must not be converted into a
default, inherited value, empty collection, or zero.

| Condition | `CoreError` category | Code | Operation | Stable route context |
|---|---|---|---|---|
| Malformed source spelling or unsupported numeric suffix | `Data` | `InvalidEncoding` | `svg` | `svg-numeric-source` |
| Parsed `NaN` or infinity | `Data` | `InvalidEncoding` | `svg` | `svg-numeric-nonfinite` |
| Finite source scalar outside the envelope | `Data` | `InvalidRange` | `svg` | `svg-numeric-range` |
| Unsafe result of SVG arithmetic | `Data` | `InvalidRange` | `svg` | `svg-numeric-derived` |

Compatibility assertions use the category, code, operation, and route context
fields. Rendered diagnostic prose is outside the compatibility contract.

## Route matrix

Each supported source and derived route has the same finite inclusive envelope.
“Source” means admit immediately after lexical conversion; “derived” means
admit each resulting scalar or affine component before it can contribute to a
usable scene. The stated implementation point is Phase 92; these identifiers
make that migration and its focused evidence auditable.

| ID | Existing seam | Scalar kind | Required admission outcome |
|---|---|---|---|
| `SVG-NUM-ROOT` | `build_svg_root_attrs`, `parse_viewbox` | Root `width`, `height`, and four `viewBox` source scalars | Source admission; only omitted `width`/`height` may retain `None`; validate derived viewport scale and translation. |
| `SVG-NUM-GEOMETRY` | `attr_double` in scene construction | `rect`, `circle`, `ellipse`, and `line` geometry attributes | Source admission before node construction. |
| `SVG-NUM-POINTS` | `points_from_attrs`, `parse_number_list` | Polyline/polygon list scalars and paired points | Source admission for every listed scalar and pair; an absent points attribute retains its existing empty branch only. |
| `SVG-NUM-PATH` | `read_number` in `path_data` | Path command numeric arguments (`M/L/H/V/C/Q/S/T/A`) | Source admission for every command number. |
| `SVG-NUM-RELATIVE` | Relative-path and smooth-control branches in `path_data` | Relative additions and reflected controls | Derived admission after every coordinate arithmetic result. |
| `SVG-NUM-TRANSFORM` | `parse_transform`, `parse_number_list` | Matrix, translate, scale, rotate, and skew source parameters | Source admission and exact transform arity before affine construction. |
| `SVG-NUM-TRIG` | Degree conversion, `Affine2::rotate`, and skew construction | Radians and trigonometric affine components | Derived admission after conversion and for every produced component. |
| `SVG-NUM-AFFINE` | `Affine2` construction and composition | Six affine coefficients | Derived admission for all coefficients after construction and every composition; a finite zero determinant remains valid. |
| `SVG-NUM-VIEWBOX` | `viewbox_transform` in lowering | Viewport scale and translation | Derived admission before a usable scene reaches the total lowerer. |
| `SVG-NUM-ROUND-RECT` | Rounded-rect clamp and ratio logic in lowering | Clamp and ratio intermediates | Derived admission for all arithmetic results; existing rounded-rect rendering policy remains unchanged. |
| `SVG-NUM-ELLIPSE-SAMPLING` | Circle and ellipse lowering | Sampling coordinates and intermediates | Derived admission for every generated scalar before drawing operations are recorded. |
| `SVG-NUM-PAINT-SCALAR` | `inherit_double`, `attr_double`, `parse_double_or` | Opacity, stroke width, miter limit, and related paint/style scalars | Source admission; only absent style attributes retain existing default or inheritance behavior. |
| `SVG-NUM-DASH-LIST` | Stroke dash-array list parsing | Every dash-list scalar and dash offset | Source admission for each list entry and offset. |
| `SVG-NUM-RGB-NUMERIC` | Lowercase comma-separated `rgb()` and `rgba()` functional parsing | Numeric red, green, and blue components | Source admission for the three consumed numeric components. |
| `SVG-NUM-RGB-PERCENT` | Lowercase comma-separated `rgb()` and `rgba()` functional parsing | Percent red, green, and blue components | Source admission for the three consumed percent components. |
| `SVG-NUM-HSL-HUE` | Lowercase comma-separated `hsl()` and `hsla()` functional parsing | Numeric hue component | Source admission for the consumed hue component. |
| `SVG-NUM-HSL-PERCENT` | Lowercase comma-separated `hsl()` and `hsla()` functional parsing | Percent saturation and lightness components | Source admission for the two consumed percent components. |

The fourth alpha component of `rgba()`/`hsla()` is not a current numeric
ingress because the supported parser consumes only the first three components.
CSS Color 4 space- or slash-separated forms, and `hwb()`, `lab()`, `lch()`,
and `color()` are unsupported/non-ingress routes. They are not silently
treated as supported admission paths.

## Scope and assumptions

This policy preserves RFC 0008 isolated group and element opacity behavior,
including the existing `PushLayer`/`PopLayer` ownership in canvas. It does not
assign SVG numeric admission to lowering or canvas, nor does it define a
different opacity range or rendering policy.

The SVGPR-01 adjacency/equality, empty/null-collection, and equal-item
ordering probes are inapplicable to scalar admission. This policy therefore
defines no merge, collision, separation, empty-collection, or ordering
semantics. Existing absent-attribute defaults are documented only as the
separate control-flow branch above.

Phase 91 evidence is intentionally limited to finite valid and inclusive-
boundary controls plus lowering preservation. Phase 92 owns the behavior-
changing rejection assertions for malformed, non-finite, out-of-range, and
unsafe-derived explicit values.

## Observable outcome

The package-local numeric-contract tracer parses an SVG containing the
inclusive coordinate boundary and a finite singular transform, lowers the
successful scene, and observes a non-empty drawing list on `js`, `wasm`,
`wasm-gc`, and `native`.
