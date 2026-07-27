# Phase 99: Simple and Composite Outlines - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the admitted portable `tchivs/mb-font/font` value with complete, unhinted `Path2` extraction for simple TrueType `glyf` descriptions and a bounded one-level composite profile. The phase owns packed point decoding, quadratic contour lowering, supported component placement and transforms, query-time resource accounting, and transactional failure. Nested composite lowering, phantom-point attachment, hinting, rasterization, variable/CFF outlines, and full real-font/four-target workflow qualification remain outside this phase.

</domain>

<decisions>
## Implementation Decisions

### Public Extraction Contract
- **D-01:** Expose one direct `Font::outline(glyph, budget) -> Result[Path2, CoreError]`-shaped query. Revalidate the opaque `GlyphId` against the receiving font before reading `glyf`; return the shared `mb-core/math.Path2` type rather than publishing a second outline model. — **Reversibility:** costly — changing the published query shape or return type later would migrate every font consumer.
- **D-02:** Retain the outline-related `FontLimits` inside the admitted `Font`, but never retain or silently reuse the caller's query `Budget`. Each extraction is an independent caller-authorized transaction.
- **D-03:** The outline query performs a source-revision guard before any glyph read and again after all private decoding/lowering work immediately before publishing the complete path. Empty results receive the same two guards.

### Simple Glyph and Contour Semantics
- **D-04:** Decode `endPtsOfContours`, instruction length, packed/repeated flags, and signed x/y deltas exactly as declared. Reserved flag bits, repeat expansion beyond the exact point count, non-increasing contour endpoints, truncated coordinate streams, or non-padding trailing bytes are malformed data.
- **D-05:** Preserve original contour order, point order, and winding. Do not reverse, normalize, union, flatten, or remove overlaps; `OVERLAP_SIMPLE` is accepted as geometry metadata and does not change the returned path.
- **D-06:** Use the standard TrueType quadratic rule: an on-curve first point starts the contour; otherwise use the last on-curve point or the midpoint of the first and last off-curve points. Consecutive on-curve points lower to lines, each off-curve point is a quadratic control, consecutive off-curve points insert their exact midpoint, and every declared contour ends with `Close`.
- **D-07:** Zero-contour glyphs return an empty `Path2` after validating and skipping any bounded instruction payload. Degenerate declared contours run through the same deterministic algorithm and are not silently dropped. Instructions are never executed.

### Composite Placement and Numeric Semantics
- **D-08:** Support only one-level parents whose component glyphs are simple or empty. Before lowering, traverse the bounded referenced descriptor graph far enough to distinguish an invalid cycle (data error) from a valid deeper acyclic composite (unsupported capability); never recurse into deeper geometry.
- **D-09:** The first component must use XY placement. Later components may use signed XY offsets or point attachment between a previously accumulated real parent point and a real child contour point. Transform the child's point set first, then compute the attachment translation.
- **D-10:** Parse signed F2DOT14 coefficients exactly and evaluate all simple points, implied midpoints, transforms, offsets, and attachment translations in a private checked `Int64` Q15 coordinate grid (`1/32768` font unit). Convert to `Double` only when constructing the final `Point2` commands, preventing target-dependent intermediate rounding.
- **D-11:** Support uniform scale, independent x/y scale, and general 2×2 transform encodings; the three transform flags are mutually exclusive. Apply the OpenType matrix ordering exactly.
- **D-12:** For XY placement, `SCALED_COMPONENT_OFFSET` transforms the offset and `UNSCALED_COMPONENT_OFFSET` leaves it in parent design units. Neither flag means unscaled, matching the interoperable Microsoft/Apple default; both flags set is malformed data. `ROUND_XY_TO_GRID` is a recognized unsupported capability because this unhinted API has no ppem/grid context.
- **D-13:** Preserve component order and append child contours in that order. Accept `OVERLAP_COMPOUND` as geometry metadata without overlap processing; reject reserved or contradictory component flag combinations as malformed data.

### Phantom Points and Metric Flags
- **D-14:** Real contour point attachment is in scope. A point index that names one of the four TrueType phantom points is recognized but unsupported in v0.32 and returns a capability error; an index outside both the real and phantom ranges is malformed data. This prevents inventing vertical-metric or hinting-derived geometry.
- **D-15:** Accept and structurally validate at most one `USE_MY_METRICS` component as geometry-neutral metadata. It does not rewrite `Path2` and does not replace the already admitted `hmtx` facts returned by `horizontal_metrics`; if a later placement depends on phantom points, D-14 applies.

### Transaction, Limits, and Errors
- **D-16:** Decode outline bodies lazily in `Font::outline`, not exhaustively during `Font::open`. Opening continues to admit checked `loca`/`glyf` windows and common headers; the outline query owns body validation and extraction cost.
- **D-17:** Extend `FontLimits` with explicit non-zero ceilings for total expanded outline points, total contours, composite components, and per-glyph instruction bytes. Reuse the stored `max_work` as the semantic per-query work ceiling, intersected with the authoritative caller `Budget`. — **Reversibility:** costly — removing these constructor fields later would weaken a published hostile-input contract and change all explicit constructors.
- **D-18:** Preflight and charge attacker-declared discovery work before traversing repeat counts, contours, components, or reference graphs so malformed retries are not free. Charge scratch/output allocations before allocating them. A failed query may consume authorized budget for work already attempted, but it never exposes points, contours, or commands.
- **D-19:** Build decoded points, contour descriptors, component placements, and path commands in private temporary state. Publish exactly one complete `Path2` only after all structural, arithmetic, limit, budget, cycle, and post-read mutation checks pass.
- **D-20:** Preserve the established taxonomy: caller glyph/limit mistakes are invalid input; malformed bytes, invalid references/flags, cycles, and checked arithmetic failures are data errors; valid out-of-profile nesting, phantom attachment, and grid rounding are capability errors; exhausted ceilings/budget are resource errors; source revision drift is a state error.

### Verification and Compatibility
- **D-21:** Generated checksum-correct micro-fonts must cover repeated flags, every delta encoding, first/last/consecutive off-curve points, contour winding/order, empty and degenerate contours, all supported component placements/transforms, offset scaling defaults, and exact F2DOT14/Q15 facts.
- **D-22:** Hostile fixtures must cover truncated arrays, flag overrun, invalid endpoints, instruction limits, reserved/contradictory flags, bad point/glyph references, self and multi-glyph cycles, valid deeper nesting, phantom attachment, arithmetic edges, query budget exact-fit/one-short behavior, and deterministic mid-query revision drift.
- **D-23:** Public black-box tests freeze `PathCommand` sequences and structured outcomes; private tests freeze decoder cursor math, exact fixed-point transforms, point numbering, graph classification, and failure-path charging. The generated interface, policy allowlist, bilingual docs, isolated package checks, and all four portable targets remain phase gates.

### the agent's Discretion
- Exact private structs, source-file split, helper names, and stable error context strings are flexible when they preserve the locked public surface and error categories.
- The planner may derive tighter internal command-count/allocation formulas from the locked point/contour/component limits rather than adding another public ceiling.
- Padding acceptance may follow the normative OpenType table rule discovered during research, provided non-padding trailing payload is rejected deterministically.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 99 goal, dependency, and four success criteria.
- `.planning/REQUIREMENTS.md` — `FONT-03`, future font capabilities, and binding v0.32 exclusions.
- `.planning/PROJECT.md` — milestone boundary, portable pure-MoonBit dependency policy, and current Phase 99 outcome.
- `.planning/STATE.md` — inherited decisions and the explicit composite-semantics planning concerns.

### Architecture and Prior Decisions
- `docs/rfcs/0004-mb-font.md` §§4.2, 5, 6.1-6.2, 7.1, 7.3 — outline ownership, four-target portability, TrueType quadratic scope, unhinted determinism, and hostile-input bounds.
- `.planning/phases/97-font-admission-and-metrics/97-CONTEXT.md` — opaque glyph, retained source, atomic admission, integer metric, limit, budget, and Phase 99 ownership decisions.
- `.planning/phases/98-unicode-mapping-and-kerning/98-CONTEXT.md` — query guards, receiving-font glyph validation, error taxonomy, work charging, public-interface, and Phase 99 handoff decisions.

### Existing Implementation Seams
- `modules/mb-font/font/font.mbt` — private `Font` state, `GlyphId`, revision guards, public query patterns, and publication point.
- `modules/mb-font/font/metrics.mbt` — normalized `loca` offsets, retained `glyf` window, glyph-header validation, and metric/bounds lookup.
- `modules/mb-font/font/limits.mbt` — explicit semantic-limit constructor and accessors to extend.
- `modules/mb-font/font/tables.mbt` — admitted `head`/`maxp` facts and aggregate admission patterns.
- `modules/mb-core/math/path.mbt` — exact public `Path2`/`PathCommand` target representation.
- `modules/mb-core/math/affine.mbt` — shared `Point2` and affine conventions; useful for public lowering but not a substitute for exact private fixed-point evaluation.
- `modules/mb-core/budget/budget.mbt` — caller-owned preflight, aggregate charge, and child-window semantics.
- `modules/mb-font/font/font_test.mbt` — public generated-font builders and black-box regression conventions.
- `modules/mb-font/font/generated_fonts_wbtest.mbt` — private generated SFNT fixture construction seam.

### Normative External Baseline
- OpenType Specification 1.9.1, `glyf` table — simple flags/deltas, component point numbering, transform matrix, phantom references, metric flags, and offset-scaling semantics.
- Apple TrueType Reference Manual, `glyf` table — independent TrueType contour and composite interpretation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MetricIndexFacts` already retains checked table-local `glyf` and normalized monotonic `loca` offsets, so outline lookup can avoid root-offset recomputation.
- `Font::require_revision`, `Font::horizontal_metrics`, and the Phase 98 post-read test seam provide the guard/revalidate/read/guard/publish pattern.
- `Path2`, `PathCommand::MoveTo/LineTo/QuadTo/Close`, and `Point2` already form the cross-module output contract.
- `Budget::preflight` and `Budget::charge`, checked UInt64 helpers, and existing font limit/error constructors provide the bounded-parser primitives.

### Established Patterns
- `Font::open` publishes once after a complete atomic admission gate and retains only private compact facts.
- Attacker-controlled loops must be preflighted before traversal and charged even on malformed failure paths.
- Unsupported recognized profiles are capability errors; malformed supported-profile bytes are data errors; no raw parser offsets or internal descriptors become public.
- Public font tests use deterministic checksum-correct micro-fonts, while private white-box tests target cursor, arithmetic, selection, and representation invariants.

### Integration Points
- Retain `FontLimits` in `Font`, expand the limits constructor/accessors, and add one public outline method beside the existing glyph/metrics/kerning queries.
- Add a private `glyf` decoder/lowerer file that consumes `MetricIndexFacts`, while keeping existing common-header and horizontal-metric behavior stable.
- Extend generated font builders, public/white-box tests, interface snapshots, package policy, module/root documentation, and Phase 99 coverage metadata without changing `mb-font -> mb-core`.

</code_context>

<specifics>
## Specific Ideas

- Normative format behavior follows OpenType 1.9.1; exact fixed-point evaluation is intentionally stricter than relying on host floating-point operation order.
- The public result should be immediately consumable by `mb-canvas`, `mb-svg`, and other `Path2` users without an adapter.
- A valid empty glyph is an empty path, while a declared degenerate contour remains observable as deterministic commands rather than being normalized away.

</specifics>

<deferred>
## Deferred Ideas

- Phase 100 owns licensed real-font provenance/digests, the complete public open-map-metrics-outline-kern workflow, and consolidated hostile-input proof on all four targets.
- Phantom-point attachment and full metric projection, nested composite lowering beyond one level, hinting/grid fitting, rasterization, variations, CFF/CFF2, color/bitmap glyphs, shaping, discovery, and font authoring remain future capabilities.

</deferred>

---

*Phase: 99-simple-and-composite-outlines*
*Context gathered: 2026-07-27*
