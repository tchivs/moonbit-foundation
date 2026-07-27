# Phase 99: Simple and Composite Outlines - Research

**Researched:** 2026-07-27
**Domain:** Bounded TrueType `glyf` decoding, exact fixed-point composite placement, and transactional `Path2` lowering
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Phase 100 owns licensed real-font provenance/digests, the complete public open-map-metrics-outline-kern workflow, and consolidated hostile-input proof on all four targets.
- Phantom-point attachment and full metric projection, nested composite lowering beyond one level, hinting/grid fitting, rasterization, variations, CFF/CFF2, color/bitmap glyphs, shaping, discovery, and font authoring remain future capabilities.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FONT-03 | Library authors can extract complete unhinted `Path2`-compatible outlines for valid simple glyphs and bounded one-level composite glyphs, with checked arithmetic and no partial geometry on failure. | The architecture, Q15 proof, simple/composite decoding state machines, graph classification, budget charging, error precedence, and four-target gates below define an implementation-ready route. [VERIFIED: `.planning/REQUIREMENTS.md`; `99-CONTEXT.md`] |
</phase_requirements>

## Summary

Implement Phase 99 as one lazy, transactional query over the already-admitted `MetricIndexFacts`. Do not reopen the SFNT directory or add another outline model. Add `mb-core/math` to the font package imports, retain the opening `FontLimits` in `Font`, expand `MaxpFacts`, factor one reusable glyph-window helper from `metrics.mbt`, and place all private outline decoding/lowering logic in a new `outline.mbt`. The query must follow the established pre-guard → receiving-font glyph validation → staged preflight/charge → private decode/lower → post-guard → single publication sequence. [VERIFIED: `modules/mb-font/font/{font,metrics,limits,tables}.mbt`; `99-CONTEXT.md`]

The normative OpenType model fits the locked design. `glyf` blocks are indexed by adjacent `loca` offsets and `maxp.numGlyphs`; simple points use packed flags and relative deltas; composite records are processed in order, renumber child real points after prior children, require XY placement for the first component, and transform the child before point alignment. Composite descriptors form an acyclic directed graph. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf] Apple independently documents the same point/flag and transform record model. [CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6glyf.html]

Q15 is exact for this deliberately one-level profile. Integer simple points are multiples of 32768 in Q15; an implied midpoint introduces at most one factor of ½; F2DOT14 uses denominator 16384; therefore one transform of a real or implied point still lands exactly on the Q15 grid. Nested transforms would require more fractional precision, which is another reason not to lower nested composites. An isolated probe using the pinned MoonBit toolchain passed the relevant `Int64` products, midpoint cases, and `Int64::to_double` boundary conversion on `native`, `js`, `wasm`, and `wasm-gc`. [VERIFIED: local four-target Q15 probe; CITED: https://docs.moonbitlang.com/en/latest/language/fundamentals.html]

**Primary recommendation:** Build a staged private `outline.mbt` decoder with exact Q15 points, an iterative tri-color descriptor-graph classifier, and preallocated transactional scratch state; integrate it through the existing `Font`, `MetricIndexFacts`, `MaxpFacts`, `FontLimits`, generated-fixture, policy, and four-target seams. [VERIFIED: `99-CONTEXT.md`; existing codebase patterns]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Opaque glyph revalidation and source guards | API / Backend (`Font` facade) | — | The receiving `Font` owns identity, retained-source state, and publication. [VERIFIED: `font.mbt`] |
| `loca` → table-local glyph window | Database / Storage analogue (retained binary index) | API / Backend | `MetricIndexFacts` already owns normalized offsets and the retained `glyf` view. [VERIFIED: `metrics.mbt`] |
| Simple/composite binary parsing | API / Backend (private decoder) | — | Hostile bytes are decoded into temporary semantic facts; no browser, host, or FFI tier participates. [VERIFIED: RFC 0004 §§5, 7.3] |
| Q15 transform and point attachment | API / Backend (private numeric layer) | — | Exact placement is format semantics and must precede the public floating boundary. [VERIFIED: D-09–D-12] |
| Path command assembly | API / Backend (`mb-font`) | Shared foundation (`mb-core/math`) | `mb-font` determines glyph semantics; `Path2` owns the cross-module geometry representation. [VERIFIED: RFC 0004 §§3.1, 4.1; `path.mbt`] |
| Rasterization, fill, and pixels | Downstream consumer | `mb-canvas` | This phase returns geometry only. [VERIFIED: RFC 0004 §§3.1, 4.2] |
| Resource authorization | Shared foundation (`mb-core/budget`) | Private decoder | Caller-owned budget controls work/allocations while `FontLimits` supplies semantic ceilings. [VERIFIED: `budget.mbt`; D-17–D-18] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit-native; do not wrap FreeType, HarfBuzz, or another foreign font stack. [VERIFIED: `AGENTS.md`; RFC 0004 §8]
- Keep `tchivs/mb-font -> tchivs/mb-core` as the only public runtime dependency; dependencies must remain acyclic and explicit. [VERIFIED: `AGENTS.md`; `modules/mb-font/moon.mod.json`]
- Preserve the package’s `+js+wasm+wasm-gc+native` portability contract; native remains the primary performance target but no host-specific path belongs in this phase. [VERIFIED: `AGENTS.md`; `moon.pkg`]
- Any FFI must be small, isolated, documented, and replaceable; this phase needs no FFI. [VERIFIED: `AGENTS.md`; phase scope]
- Public API compatibility follows Semantic Versioning after stability; experimental APIs must be visibly marked. [VERIFIED: `AGENTS.md`]
- Operations must be deterministic and usable without GUI state; CLI, agent, and MCP consumers are first-class. [VERIFIED: `AGENTS.md`]
- Performance evidence requires declared workloads and reproducible baselines; unsupported marketing claims are not acceptance criteria. [VERIFIED: `AGENTS.md`]
- New modules and breaking architectural changes require RFCs; this phase must extend RFC 0004 rather than redefine its boundary. [VERIFIED: `AGENTS.md`; RFC 0004]
- Work is already inside the `$gsd-plan-phase` workflow; do not make unrelated repository edits. [VERIFIED: `AGENTS.md`; orchestrator task]
- Code discovery used `codebase-memory-mcp` first. Its index exposed repository/file structure but no MoonBit function nodes, so scoped `rg` and direct reads were used as the documented fallback. [VERIFIED: graph queries returned zero MoonBit symbols; `AGENTS.md`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Build, check, test, and interface generation | Installed project pin and prior four-target qualification baseline. [VERIFIED: local `moon version`; `AGENTS.md`] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile exact `Int64` and `Double` code on all backends | Bundled pinned compiler; the local Q15 probe passed all four supported targets. [VERIFIED: local `moonc -v` and probe] |
| `tchivs/mb-core` | workspace `0.1.0` | `ByteView`, checked offsets, budgets, errors, `Point2`, and `Path2` | Existing sole runtime dependency and RFC-owned boundary. [VERIFIED: module manifests; `moon.pkg`] |
| OpenType specification | `1.9.1` | Normative `glyf`, `loca`, `maxp`, transform, and point-number semantics | Locked external baseline. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Apple TrueType Reference Manual | current published manual | Independent interpretation of simple/compound outlines and F2DOT14 | Use to cross-check record and transform semantics, not to override locked OpenType 1.9.1 decisions. [CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6glyf.html] |
| PowerShell | `7.6.3` | Existing policy and quality scripts | Use for `Assert-FontFoundationPolicy` and repository quality selectors. [VERIFIED: local environment; `scripts/quality`] |
| Existing generated micro-font builders | repository-local | Checksum-correct deterministic fixtures | Extend public and white-box builders; do not introduce a foreign fixture generator. [VERIFIED: `font_test.mbt`; `generated_fonts_wbtest.mbt`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Private checked Q15 | `Double` transforms through `Affine2` | Rejected by D-10: repeated floating operations would make exact F2DOT14/midpoint facts harder to freeze and could vary at intermediate rounding points. [VERIFIED: D-10; `affine.mbt`] |
| Shared `Path2` | New public font-outline model | Rejected by D-01 and RFC 0004 composition boundary. [VERIFIED: D-01; RFC 0004 §3.1] |
| Lazy body decode | Decode every outline during `Font::open` | Rejected by D-16; it would charge unused glyph geometry and broaden admission latency/state. [VERIFIED: D-16] |
| Iterative descriptor graph | Recursive geometry lowering | Rejected by D-08 and D-18: only one geometry level is supported, while graph classification must remain bounded on hostile depth. [VERIFIED: D-08; OWASP resource guidance] |

**Installation:** No external package installation is required. Keep `moon.pkg` inside the existing `tchivs/mb-core` module dependency and add only the `tchivs/mb-core/math` package import. [VERIFIED: `moon.pkg`; D-01]

## Architecture Patterns

### System Architecture Diagram

```text
caller GlyphId + caller Budget
            |
            v
Font::outline
  pre-read revision guard
  receiving-font glyph range check
            |
            v
MetricIndexFacts: normalized loca offsets + retained glyf ByteView
            |
            v
glyph window / common header
     +------+----------------------------+
     |                                   |
 empty or simple                    composite parent
     |                                   |
 staged endpoint/flag/delta         parse component descriptors
 decode + instruction skip               |
     |                         iterative reachable-graph classifier
     |                           +-------+---------+
     |                           |                 |
     |                         cycle          deeper acyclic
     |                         Data           Capability
     |                           |
     |                    one-level direct simple children
     |                           |
     +-------------> checked Int64 Q15 points
                                  |
                    transform -> XY/point translation
                                  |
                    preserve component/contour order
                                  |
                    quadratic lowering into private Path2
                                  |
                       post-read revision guard
                                  |
                         publish one complete Path2

External boundary: OpenType 1.9.1 bytes enter only through retained ByteView.
Downstream boundary: mb-canvas / mb-svg consume Path2; no pixels or host services return.
```

[VERIFIED: `font.mbt`, `metrics.mbt`, `path.mbt`, D-01–D-20]

### Recommended Project Structure

```text
modules/mb-font/font/
├── font.mbt                    # retain limits; public guarded outline coordinator
├── metrics.mbt                 # reusable glyph-window helper over loca/glyf
├── tables.mbt                  # expanded MaxpFacts decoding
├── limits.mbt                  # four new non-zero outline ceilings
├── outline.mbt                 # private Q15, simple/composite decoder, graph, lowerer
├── cursor.mbt                  # add signed byte read if useful
├── font_test.mbt               # public PathCommand and taxonomy/resource cases
├── font_wbtest.mbt             # Q15, cursor, graph, charge, drift invariants
├── generated_fonts_wbtest.mbt  # reusable glyf/maxp/loca fixture construction
├── moon.pkg                    # add mb-core/math package import
└── pkg.generated.mbti          # regenerate; never hand-edit
```

[VERIFIED: existing file roles; Phase 98 pattern map]

### Component Responsibilities

| Component | Required Change | Planning Note |
|-----------|-----------------|---------------|
| `font.mbt` | Add private retained `limits`; expose `Font::outline`; add a private after-decode callback seam for deterministic mutation tests. | Mirror `glyph_for_scalar_after_lookup` / `kerning_after_lookup` ordering. [VERIFIED: `font.mbt`; D-02–D-03] |
| `metrics.mbt` | Factor `font_glyph_window(index, glyph)` from `font_read_glyph_bounds` and reuse it for metrics and outline. | Preserve already-admitted table-local offsets and empty `loca[n] == loca[n+1]`. [VERIFIED: `metrics.mbt`; CITED: https://learn.microsoft.com/en-us/typography/opentype/otspec190/loca] |
| `tables.mbt` | Expand `MaxpFacts` with all outline maxima from the already-required 32-byte version-1 table. | Do not add a second `maxp` read path. [VERIFIED: `tables.mbt`; CITED: https://learn.microsoft.com/en-us/typography/opentype/otspec140/maxp] |
| `limits.mbt` | Add points, contours, components, and per-glyph instruction-byte fields/accessors; keep every constructor argument non-zero. | Update every explicit constructor in code, tests, docs, interface, and policy in one task. [VERIFIED: `limits.mbt`; D-17] |
| `outline.mbt` | Own private structs, staged work charges, signed checked arithmetic, body validation, graph classification, transforms, attachments, and lowering. | Return only a complete `Path2`; no parser fact becomes public. [VERIFIED: D-04–D-20] |
| test builders | Parameterize `glyf` blocks, `loca`, and maxp maxima while retaining checksum correctness. | Public builders freeze commands; white-box builders freeze internal math/classification. [VERIFIED: D-21–D-23; existing tests] |

### Pattern 1: Guarded Transactional Query

**What:** Validate source state and glyph ownership before reads, charge work and allocations in stages, keep all points/commands private, recheck source state, then return one path. [VERIFIED: `font.mbt`; D-01–D-03, D-18–D-20]

**When to use:** Every `Font::outline` result, including `loca`-empty and header-only/zero-contour glyphs. [VERIFIED: D-03, D-07]

**Ordering:**

1. `require_revision("font-outline")`.
2. Revalidate `glyph.value_value < metric_index.num_glyphs`.
3. Obtain the table-local glyph window.
4. Run staged discovery, charges, decode, graph classification, and lowering.
5. Invoke a private white-box hook after all reads.
6. `require_revision("font-outline")`.
7. Publish the private `Path2`.

Do not run the success post-guard after publishing, and do not expose a partially filled path through callbacks. [VERIFIED: existing post-read test seam; D-19]

### Pattern 2: Staged Simple-Glyph Decoder

**What:** Charge each attacker-declared loop before consuming it. [VERIFIED: D-18; existing cmap/kern admission pattern]

**Prescriptive stages:**

1. Read the admitted 10-byte header and classify `numberOfContours`.
2. If `loca` length is zero, return a private empty result. If the header declares zero contours, accept exactly the header or parse a contained `instructionLength` and skip its bounded bytes.
3. Check the contour count against `maxp.maxContours` (Data if underreported) and `FontLimits.max_outline_contours` (Resource if exceeded); charge the endpoint scan before reading `endPtsOfContours`.
4. Require endpoints to increase strictly. Derive `pointCount = lastEndPoint + 1`, then check `maxp.maxPoints` before the caller ceiling.
5. Read the instruction length, compare first to `maxp.maxSizeOfInstructions` and then the retained per-glyph limit, charge its declared work, and skip without execution.
6. Preflight and charge expanded flag/coordinate/lowering work and scratch/output allocations before expanding flags.
7. Expand each stored flag to exactly the logical point count. Bit 7 is invalid. `OVERLAP_SIMPLE` is metadata on the first stored flag; if that stored flag repeats, do not misclassify its repeated logical copies as extra overlap declarations.
8. Decode the complete x stream, then y stream, using signed deltas and checked cumulative `Int64`.
9. Validate body exhaustion/padding, point extrema against the simple glyph header, and all arithmetic before lowering.
10. Lower every declared contour, including degenerate contours, and always append `Close`.

[CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf; CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM01/Chap1.html]

### Pattern 3: Exact One-Level Q15 Evaluation

**What:** Store each coordinate as signed `Int64` units of `1/32768` font unit. Keep raw signed F2DOT14 coefficients with denominator `16384`. [VERIFIED: D-10; CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6.html]

**Exactness argument:**

- A real simple point `p` becomes `p * 32768`.
- A midpoint is `(a + b) / 2`; real-point midpoints are multiples of `16384`.
- A transform is:
  - `x' = (xscale * x + scale10 * y) / 16384`
  - `y' = (scale01 * x + yscale * y) / 16384`
- For a real point, each input is a multiple of `32768`; for a single implied midpoint, each is a multiple of `16384`. The quotient is therefore exact in Q15 for one F2DOT14 transform.
- Signed XY offsets use `offset * 32768`; scaled offsets pass through the same exact transform.
- Point-attachment translation is a subtraction between transformed Q15 points.

Nested transforms are intentionally not lowered: a second arbitrary F2DOT14 transform can require more fractional bits than Q15. [VERIFIED: arithmetic derivation from D-08/D-10 and F2DOT14 definition]

Use explicit checked signed add/subtract/multiply helpers and map their failure to the font Data taxonomy. `mb-core/checked` currently exposes only unsigned `UInt64` helpers and returns its own invalid-input arithmetic category, so raw propagation would violate D-20. [VERIFIED: `modules/mb-core/checked/checked.mbt`; D-20]

### Pattern 4: Iterative Descriptor-Graph Classification

**What:** Before returning Capability for nested composites, prove the reachable composite descriptor graph is structurally valid and acyclic. Do not recursively lower it. [VERIFIED: D-08; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf]

**Recommended algorithm:**

- Use dense tri-color state indexed by admitted glyph ID (`Unseen`, `Visiting`, `Done`) plus an explicit stack of descriptor frames; precharge both allocations.
- Mark the requested parent `Visiting`, parse its bounded component record list, and visit referenced glyph headers.
- A reference to `Visiting` is a self or multi-glyph cycle → Data.
- A simple/empty child is a leaf.
- A composite child is parsed structurally and pushed; set `saw_deeper = true`.
- On frame exhaustion, mark the glyph `Done`.
- Count every descriptor record inspected across the reachable graph against the component ceiling and `max_work`.
- Validate reserved/contradictory flags, glyph references, instruction envelopes, and `maxp.maxComponentDepth` while classifying.
- After complete traversal: any cycle/structural error wins; otherwise `saw_deeper` returns Capability. Only a one-level root proceeds to geometry decode.

This ordering prevents a malformed cyclic graph from being mislabeled as merely unsupported nesting. [VERIFIED: D-08, D-20, D-22]

### Pattern 5: Composite Placement and Real Point Numbering

**What:** Retain transformed/translated real contour points separately from commands. Implied points never enter the numbered real-point array. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf]

For each direct component in record order:

1. Decode a simple or empty child into real Q15 points and contour endpoints.
2. Apply its optional F2DOT14 matrix to all child real points.
3. For XY arguments:
   - scaled flag → transform `(dx, dy)` before translation;
   - unscaled or neither flag → `(dx * 32768, dy * 32768)`;
   - both flags → Data;
   - XY grid rounding → Capability.
4. For point arguments:
   - first component → Data because first must be XY;
   - parent index `< accumulatedRealCount` and child index `< childRealCount` → compute `parent - transformedChild`;
   - index in `[realCount, realCount + 4)` → Capability (phantom);
   - larger index → Data.
5. Translate child points, append them to the accumulated parent real-point list, lower their contours, and append commands in component order.

[CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf; VERIFIED: D-09–D-15]

### Pattern 6: `maxp` / `loca` / `glyf` Integration

OpenType version-1 `maxp` provides the exact fields this phase needs: `maxPoints`, `maxContours`, `maxCompositePoints`, `maxCompositeContours`, `maxSizeOfInstructions`, `maxComponentElements`, and `maxComponentDepth`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/otspec140/maxp]

Use them as font-consistency claims, not as replacements for caller limits:

- Actual value beyond a `maxp` claim → malformed Data.
- Actual value within `maxp` but beyond retained `FontLimits` → Resource.
- Caller `Budget` one-short → Resource with already-authorized earlier stages still consumed.
- Do not reject the whole font merely because a font-wide maximum is larger than a caller’s outline ceiling; a smaller glyph can still be queried. This preserves D-16 lazy body ownership. [VERIFIED: D-16–D-18]

The current `MaxpFacts` retains only `num_glyphs`, while the table decoder already requires the exact 32-byte version-1 payload. Expanding that one struct/decoder is sufficient. [VERIFIED: `tables.mbt:507-529`]

### Pattern 7: Deterministic Trailing-Byte Rule

Top-level OpenType table padding is zero-filled to four-byte alignment but is excluded from the table length. Therefore it is already outside the retained `glyf` `TableWindow` and cannot justify arbitrary bytes inside a `loca`-defined glyph block. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]

`loca` offsets should be word-aligned, so one byte may remain between an odd logical glyph body and the next even glyph start. [CITED: https://learn.microsoft.com/en-us/typography/opentype/otspec190/loca] Use this strict phase rule:

- accept exact body exhaustion;
- otherwise accept exactly one zero byte only when it accounts for even alignment of the next `loca` offset;
- reject non-zero trailing data or more than one internal byte as Data.

This is deterministic, compatible with the documented word-alignment convention, and does not mistake top-level table padding for glyph payload. [CITED: OpenType `otff` and `loca`; VERIFIED: D-04 discretion]

### Anti-Patterns to Avoid

- **Floating transform then midpoint:** violates the exact Q15 pipeline and makes rounding order observable. [VERIFIED: D-10]
- **Lower path commands before point attachment is resolved:** commands lose the complete real point-number space needed by later components. [CITED: OpenType `glyf`]
- **Treat implied midpoints as component point numbers:** only encoded contour points and four phantom points are addressable. [CITED: OpenType `glyf`]
- **Return Capability as soon as a nested child is seen:** hides a reachable cycle or malformed descriptor that must be Data. [VERIFIED: D-08, D-20]
- **Recursive DFS on untrusted depth:** risks stack exhaustion and bypasses explicit work/depth accounting. [VERIFIED: D-18; OWASP DoS guidance]
- **Propagate `@checked` arithmetic errors unchanged:** current checked helpers report InvalidInput; outline arithmetic failure is locked to Data. [VERIFIED: `checked.mbt`; D-20]
- **Decode through root SFNT offsets again:** duplicates admitted `loca`/`glyf` logic and risks inconsistent containment. [VERIFIED: `MetricIndexFacts`]
- **Mutate/reverse/normalize contours:** changes winding and violates D-05. [VERIFIED: D-05; Apple contour-direction documentation]
- **Expose a partially built `Path2`:** violates the transactional result contract. [VERIFIED: D-19]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public outline representation | A font-specific command enum or contour DTO | `@math.Path2`, `PathCommand`, `Point2` | Already consumed by canvas/SVG and locked by D-01. [VERIFIED: `path.mbt`] |
| Source containment | Raw root offsets and integer slicing | `MetricIndexFacts.glyf`, normalized `loca_offsets`, `ByteView.subview` | Admission already proved table-local bounds and monotonic offsets. [VERIFIED: `metrics.mbt`] |
| Resource ledger | Parser-local mutable counters replacing caller authority | `Budget::preflight`, `Budget::charge`, retained `FontLimits` | Shared budget semantics already define exact-fit/one-short behavior. [VERIFIED: `budget.mbt`] |
| Composite recursion | Recursive geometry function | Explicit tri-color descriptor stack, then one-level lowering | Separates cycle classification from unsupported geometry and avoids call-stack risk. [VERIFIED: D-08, D-18] |
| Transform engine | `Affine2`/`Double` for private evaluation | Raw F2DOT14 + checked `Int64` Q15 | Exact one-level arithmetic is the locked contract. [VERIFIED: D-10; `affine.mbt` warns exact users to use checked arithmetic] |
| Hint interpreter | TrueType VM, phantom metric projection, grid rounding | Validate/skip instructions; return scoped Capability | Hinting and phantom attachment are explicitly deferred. [VERIFIED: D-07, D-12, D-14] |
| Fixture oracle | FreeType/fontTools runtime dependency | Existing checksum-correct generated MoonBit builders and fixed expected commands | Keeps tests portable, deterministic, and dependency-free. [VERIFIED: D-21–D-23; existing builders] |

**Key insight:** the hard part is not drawing quadratic curves; it is preserving the distinction among real points, implied points, component instances, phantom references, structural invalidity, unsupported capability, and already-consumed hostile work. Reuse the existing foundation contracts for everything outside that semantic core. [VERIFIED: D-04–D-20]

## Common Pitfalls

### Pitfall 1: Off-by-One Repeat Expansion

**What goes wrong:** The repeat byte counts additional entries, so a stored flag contributes `1 + repeat`, not `repeat`. [CITED: OpenType `glyf`]

**How to avoid:** Before emitting, prove `expanded + 1 + repeat <= pointCount`; after the loop require equality. Charge the logical point count before traversal. [VERIFIED: D-04, D-18]

### Pitfall 2: Endpoint or Zero-Contour Ambiguity

**What goes wrong:** A parser reads `lastEndPoint` when there are zero contours, or accepts equal/decreasing endpoints. [CITED: OpenType `glyf`]

**How to avoid:** Branch zero contours before endpoint access; for positive contours require strict increase and derive `pointCount` only from the final endpoint. [VERIFIED: D-04, D-07]

### Pitfall 3: Wrong 2×2 Matrix Order

**What goes wrong:** Treating the serialized sequence as conventional row-major `[a,b,c,d]` swaps `scale01` and `scale10`. [CITED: OpenType `glyf`]

**How to avoid:** Read `xscale, scale01, scale10, yscale`; compute `x' = xscale*x + scale10*y`, `y' = scale01*x + yscale*y`. Freeze rotation/shear cases, not scale-only cases. [VERIFIED: D-11]

### Pitfall 4: Point Attachment Against Commands

**What goes wrong:** `MoveTo` and implied midpoint commands are mistaken for TrueType point numbers. [CITED: OpenType `glyf`]

**How to avoid:** Keep a separate accumulated array of transformed/translated encoded real points. Lower only after placement is fixed. [VERIFIED: D-09, D-14]

### Pitfall 5: Capability Hides a Cycle

**What goes wrong:** The first nested child returns Unsupported without examining the rest of the reachable graph. [VERIFIED: D-08]

**How to avoid:** Complete the bounded iterative descriptor traversal, with Data/cycle precedence, before returning Capability. [VERIFIED: D-08, D-20]

### Pitfall 6: Resource Failure Is Free

**What goes wrong:** A malformed repeat/component list is retried without consuming work because the parser validates before charging. [VERIFIED: D-18]

**How to avoid:** Use staged preflight+charge immediately after each count is known and before its loop. Public tests must assert exact remaining work on malformed, exact-fit, and one-short paths. [VERIFIED: existing Phase 98 resource tests; D-22]

### Pitfall 7: `maxp` and Caller Limits Are Conflated

**What goes wrong:** A font inconsistency is reported as caller resource exhaustion, or a large global `maxp` value rejects every otherwise-usable font at open. [CITED: OpenType `maxp`; VERIFIED: D-16–D-20]

**How to avoid:** Compare actual glyph facts to `maxp` first (Data), then retained caller ceilings (Resource), lazily per query. [VERIFIED: recommended integration]

### Pitfall 8: Signed Arithmetic Gets the Wrong Taxonomy

**What goes wrong:** An overflow from a generic helper surfaces as InvalidInput rather than malformed font Data. [VERIFIED: `checked.mbt`; D-20]

**How to avoid:** Wrap every private signed arithmetic failure in an outline-specific Data error. Test positive/negative add, subtract, multiply, midpoint sum, transform numerator sum, and attachment translation edges. [VERIFIED: D-22]

### Pitfall 9: Padding Becomes an Extension Channel

**What goes wrong:** “Ignore remaining bytes” accepts non-padding payload and hides truncation/flag mistakes. [VERIFIED: D-04]

**How to avoid:** Accept only exact exhaustion or the single zero word-alignment byte described above. [CITED: OpenType `otff` and `loca`]

### Pitfall 10: Generated Interface Baseline Is Already Stale

**What goes wrong:** The current tracked `pkg.generated.mbti` omits Phase 98’s `glyph_for_scalar`, `kerning`, and kern-limit surface even though `font.mbt`, `limits.mbt`, and `policy/foundation.json` contain it. A Phase 99 diff could incorrectly attribute those old signatures to this phase or fail the policy gate. [VERIFIED: direct inspection; current interface SHA-256 `f26d91803070046fccc2032a3f4b3ad33b84adc32346494f6d2e57cc4005a2bd`]

**How to avoid:** Regenerate the interface from the unchanged Phase 98 source before evaluating the Phase 99 additive surface, then regenerate again after `Font::outline` and new limit accessors. Never hand-edit the file. [VERIFIED: Phase 98 documented `moon info` workflow]

### Pitfall 11: `Path2::push` Is Mistaken for Publication

**What goes wrong:** Because `Path2` is mutable internally, implementers assume appending commands violates atomicity. [VERIFIED: `path.mbt`]

**How to avoid:** A locally constructed path remains private until return. Precharge its conservative command bound (`points + 2*contours`), build it privately, post-guard, then return it once. [VERIFIED: D-19; command-bound derivation]

## Code Examples

Verified implementation shapes, adapted to the repository’s MoonBit style:

### Exact Q15 Transform

```moonbit
// Source semantics:
// https://learn.microsoft.com/en-us/typography/opentype/spec/glyf
fn transform_q15(
  point : OutlinePoint,
  matrix : F2Dot14Matrix,
) -> Result[OutlinePoint, @error.CoreError] {
  let x_num = outline_checked_sum_of_products(
    matrix.xscale_raw,
    point.x_q15,
    matrix.scale10_raw,
    point.y_q15,
  )?
  let y_num = outline_checked_sum_of_products(
    matrix.scale01_raw,
    point.x_q15,
    matrix.yscale_raw,
    point.y_q15,
  )?
  Ok({
    x_q15: x_num / 16384L,
    y_q15: y_num / 16384L,
    on_curve: point.on_curve,
  })
}
```

The helper must prove each multiplication and the sum before executing them, and must return a font Data error on failure. [VERIFIED: D-10, D-20]

### Contour Start and Implied Midpoint

```moonbit
// Source semantics:
// https://developer.apple.com/fonts/TrueType-Reference-Manual/RM01/Chap1.html
fn midpoint_q15(a : OutlinePoint, b : OutlinePoint) -> Result[OutlinePoint, @error.CoreError] {
  Ok({
    x_q15: outline_checked_add(a.x_q15, b.x_q15)? / 2L,
    y_q15: outline_checked_add(a.y_q15, b.y_q15)? / 2L,
    on_curve: true,
  })
}

fn contour_start(first : OutlinePoint, last : OutlinePoint) -> Result[OutlinePoint, @error.CoreError] {
  if first.on_curve {
    Ok(first)
  } else if last.on_curve {
    Ok(last)
  } else {
    midpoint_q15(last, first)
  }
}
```

Do not deduplicate equal points; degenerate commands are observable by D-07. [VERIFIED: D-06–D-07]

### Guard / Decode / Guard / Publish

```moonbit
pub fn Font::outline(
  self : Font,
  glyph : GlyphId,
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  self.require_revision("font-outline")?
  if glyph.value_value >= self.metric_index.num_glyphs {
    return Err(font_glyph_id_error(
      "font-outline",
      glyph.value_value,
      self.metric_index.num_glyphs,
    ))
  }
  let path = font_decode_outline(
    self.metric_index,
    self.tables.maxp,
    self.limits,
    glyph.value_value,
    budget,
  )?
  self.require_revision("font-outline")?
  Ok(path)
}
```

This is illustrative; retain the existing explicit `match` style if `?` is not used in the package. [VERIFIED: `font.mbt` query patterns]

## Verification Strategy

| Gate | Command / Evidence | Purpose |
|------|--------------------|---------|
| Fast compile | `moon -C modules/mb-font check --target native --frozen` | Private type/import integration. [VERIFIED: existing workflow] |
| Focused test loop | `moon -C modules/mb-font test font --target native --frozen --target-dir <unique> --no-parallelize -f "*outline*"` | Fast public/private outline cases without the known Windows unscoped stall. [VERIFIED: Phase 98 verification pattern] |
| Full package per target | `moon -C modules/mb-font test font --target <native|js|wasm|wasm-gc> --frozen --target-dir <unique> --no-parallelize` | All old and new font behavior on each backend. [VERIFIED: Phase 98 four-target gate] |
| Interface | `moon -C modules/mb-font info --target all --frozen --target-dir <unique>` | Regenerate and classify the exact additive surface. [VERIFIED: prior interface workflow] |
| Literate docs | `moon -C modules/mb-font check README.mbt.md --target <target> --frozen --target-dir <unique> --serial` | Public query example on all four targets. [VERIFIED: Phase 98 verification] |
| Policy | Existing independent `Assert-FontFoundationPolicy` selector | Exact sources/imports/targets/interface/docs. [VERIFIED: `scripts/quality`; `policy/foundation.json`] |

Public black-box fixtures should freeze exact `MoveTo`, `LineTo`, `QuadTo`, `Close` sequences and error categories. Private tests should directly freeze Q15 integers before `Double`, record cursor positions, stored-vs-expanded flags, graph colors/stack behavior, and budget deltas. [VERIFIED: D-21–D-23]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host/FFI font outline extraction | Pure MoonBit bounded decoder | RFC 0004 / v0.32 | Preserves four-target determinism and the sole `mb-font -> mb-core` edge. [VERIFIED: RFC 0004; project constraints] |
| Floating transforms throughout | Exact private Q15, one `Double` conversion at command construction | Locked for Phase 99 | Freezes F2DOT14 and implied midpoint behavior independent of operation ordering. [VERIFIED: D-10] |
| Eager whole-font outline validation | Lazy per-query body validation over admitted indexes | Locked for Phase 99 | Metrics/cmap/kern admission remains compact; outline cost is caller-authorized. [VERIFIED: D-16] |
| Recursive composite lowering | Bounded iterative graph classification plus one-level geometry | Locked for Phase 99 | Cycles remain Data; valid deeper graphs remain Capability without stack risk. [VERIFIED: D-08] |
| Separate font geometry DTO | Shared `Path2` | Locked for Phase 99 | Canvas/SVG consumers need no adapter. [VERIFIED: D-01; `path.mbt`] |

**Deprecated/outdated:**

- Apple’s older compound-offset scaling heuristic is not the phase rule; OpenType 1.9.1’s explicit scaled/unscaled flags and Microsoft/Apple unscaled default govern D-12. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/glyf]
- `Affine2::apply_to_path` is valid for consumer-side floating transforms, but is not the private font decoder’s exact F2DOT14 evaluator. [VERIFIED: `affine.mbt`; D-10]
- Nested composite geometry lowering, hint execution, and phantom placement are out of the v0.32 phase profile. [VERIFIED: deferred decisions]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All implementation recommendations derive from locked context, inspected code, local toolchain probes, or cited primary specifications. | — | — |

## Open Questions

None blocking planning. Private type names, exact stable context strings, and conservative logical allocation-size constants remain implementation discretion as explicitly allowed by CONTEXT.md. [VERIFIED: `99-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | build/test/interface | ✓ | `0.1.20260713` | — |
| `moonc` | compilation | ✓ | `v0.10.4+2cc641edf` | — |
| `moonrun` | test execution | ✓ | `0.1.20260713` | — |
| PowerShell | policy/quality scripts | ✓ | `7.6.3` | Windows PowerShell is also installed |
| Native/JS/Wasm/Wasm-GC backends | portability gate | ✓ | Q15 probe passed 2/2 tests on each | — |
| External font library/service | none | not required | — | Pure MoonBit implementation |

[VERIFIED: local commands and four-target probe]

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set `security_enforcement: false`. Nyquist validation is explicitly disabled, so the separate `Validation Architecture` section is intentionally omitted. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| Authentication | no | No identity or credential boundary exists in this library phase. [VERIFIED: phase scope] |
| Session Management | no | No sessions or ambient service state. [VERIFIED: phase scope] |
| Access Control | no | Callers provide bytes, glyph IDs, limits, and budgets directly. [VERIFIED: public contract] |
| Input Validation | yes | Contained `ByteView` reads, strict flag/reference/cardinality validation, checked arithmetic, and complete failure before publication. [VERIFIED: D-04–D-20; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| Cryptography | no | Checksums are format integrity fields, not security cryptography; no crypto primitive is introduced. [VERIFIED: existing admission scope] |

OWASP ASVS 5.0’s current validation chapter and OWASP DoS guidance support cheap validation first, explicit size limits, and preventing untrusted input from directly controlling unbounded allocation or loop work. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html]

### Known Threat Patterns for the Font Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Truncated/overlapping offset windows | Tampering | Reuse normalized `loca` and contained `ByteView` subviews; exact body exhaustion. [VERIFIED: `metrics.mbt`; D-04] |
| Repeat/component count amplification | Denial of Service | Non-zero semantic ceilings plus staged preflight/charge before loops. [VERIFIED: D-17–D-18] |
| Recursive composite cycle | Denial of Service / Tampering | Iterative tri-color graph, explicit stack, cycle → Data. [VERIFIED: D-08, D-20] |
| Arithmetic wrap in transforms/attachments | Tampering | Checked `Int64` products/sums/differences; failure → Data. [VERIFIED: D-10, D-20] |
| Partial geometry exposure | Tampering | Private temporary state and one post-guarded publication. [VERIFIED: D-19] |
| Retained-source mutation during query | Tampering | Pre-read and post-read revision guards, including empty paths. [VERIFIED: D-03; existing revision seam] |
| Error-oracle ambiguity | Repudiation | Preserve InvalidInput/Data/Capability/Resource/State categories and stable contexts. [VERIFIED: D-20] |
| Target-dependent floating evaluation | Integrity | Exact Q15 until final `Point2`; all-target command/fact tests. [VERIFIED: D-10, D-23] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/99-simple-and-composite-outlines/99-CONTEXT.md` — locked public, numeric, resource, taxonomy, and verification decisions.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` — FONT-03 scope and milestone boundaries.
- `docs/rfcs/0004-mb-font.md` — package ownership, `Path2` composition, portability, unhinted determinism, and hostile-input bounds.
- `modules/mb-font/font/{font,metrics,limits,tables,cursor}.mbt` — current retained state, query, parser, maxp, and error seams.
- `modules/mb-core/{math,budget,checked}` — public geometry, resource, and arithmetic contracts.
- `modules/mb-font/font/{font_test,font_wbtest,generated_fonts_wbtest}.mbt` — fixture and verification patterns.
- Local `moon 0.1.20260713` Q15 probe — exact products/midpoints/conversion passed `native`, `js`, `wasm`, and `wasm-gc`.

### Secondary (MEDIUM confidence)

- https://learn.microsoft.com/en-us/typography/opentype/spec/glyf — OpenType 1.9.1 simple/composite normative semantics.
- https://learn.microsoft.com/en-us/typography/opentype/otspec190/loca — glyph window and alignment semantics.
- https://learn.microsoft.com/en-us/typography/opentype/otspec140/maxp — version-1 outline maxima.
- https://learn.microsoft.com/en-us/typography/opentype/spec/otff — top-level table padding and actual-length rules.
- https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6glyf.html — independent simple/compound record and transform semantics.
- https://developer.apple.com/fonts/TrueType-Reference-Manual/RM01/Chap1.html — quadratic, implied point, contour order/winding semantics.
- https://docs.moonbitlang.com/en/latest/language/fundamentals.html — `Int64`, IEEE-754 `Double`, and arrays.
- https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html — supported-target metadata.
- https://owasp.org/www-project-application-security-verification-standard/ — ASVS 5.0 baseline.
- https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html — hostile work/allocation guidance.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — installed versions and module boundaries were directly verified.
- Architecture: HIGH — locked decisions align with inspected code seams and primary OpenType semantics.
- Q15 feasibility: HIGH — arithmetic proof plus a four-target local compiler/runtime probe.
- Padding rule: MEDIUM — top-level zero padding and `loca` word alignment are official; the strict one-byte internal acceptance profile is a phase-level deterministic interpretation allowed by CONTEXT.
- Pitfalls: HIGH — derived from locked failure cases, existing tests, official record semantics, and the observed stale interface baseline.

**Research date:** 2026-07-27
**Valid until:** 2026-08-26 for the stable OpenType semantics; recheck MoonBit toolchain behavior if the pinned compiler changes.
