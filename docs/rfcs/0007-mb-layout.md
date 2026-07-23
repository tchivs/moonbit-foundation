# RFC 0007: mb-layout Charter

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-22
- **Target:** Document and Scene Layer document-flow layout module charter
- **Discussion:** To be established
- **Normative process:** [RFC process](../governance/rfc-process.md)
- **Authority / project owner:** `sole-project-owner`

> The acceptance-machinery header fields this RFC previously carried (acceptance route, maintainer approvals, blocking objections, public review window, acceptance evidence) were removed on 2026-07-23 when the RFC process was simplified to `Draft -> Proposed` for this sole-owner project. A Proposed RFC is now sufficient to proceed. See the [RFC process](../governance/rfc-process.md).

## Transition history

| From | To | Evidence |
|---|---|---|
| — | Draft | Initial RFC in repository history |
| Draft | Proposed | This revision makes the charter reviewable; repository history is the transition record |

No transition to Rejected or Superseded has occurred. Under the simplified RFC process the lifecycle is `Draft -> Proposed`; a Proposed RFC is sufficient to proceed. Every future transition must update this ledger.

## 1. Abstract

This RFC proposes `tchivs/mb-layout` as a new MNF module in the Document and Scene Layer, responsible for document-level flow layout — placing paragraph-level content blocks into columns, regions, and pages with deterministic pagination, text-wrapping around exclusions, and bounded reflow. It establishes the module boundary, the allowed public dependency direction, the layout subset, and the critical split between paragraph-level text shaping (owned by `mb-text`) and document-level flow (owned by this module).

`mb-layout` answers a single question: how does an MNF consumer take a sequence of content blocks (paragraphs, images, tables) and flow them into a paginated document structure, deterministically and on every target, without each consumer rebuilding an incompatible layout engine. RFC 0001 names `mb-layout` in the Document and Scene Layer but Section 6 does not define its responsibilities. This RFC fills that gap and completes the Document and Scene Layer charter set (RFCs 0002, 0004, 0005, 0006, and this one).

This RFC does not implement `mb-layout`. It creates no `.mbt` source, no package manifest, and no module declaration. Per [RFC 0001](0001-moonbit-native-foundation.md) Section 11, creation of a new MNF module requires a Proposed RFC before implementation may merge.

## 2. Relationship to RFC 0001

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-layout` in the Document and Scene Layer alongside `mb-svg`, `mb-pdf`, `mb-font`, and `mb-text`, above the Graphics Layers and the Foundation. RFC 0001 Section 6.4 governs deferred layers: `mb-layout` may consume accepted lower-layer contracts and may not redefine them through implementation alone.

The allowed public dependency direction proposed here is:

```text
tchivs/mb-layout -> tchivs/mb-text
tchivs/mb-layout -> tchivs/mb-image
tchivs/mb-layout -> tchivs/mb-core
```

`mb-layout` depends on `mb-text` (for paragraph measurement: a paragraph is laid out by asking text for shaped line breaks and metrics), `mb-image` (for image-block dimensions: a raster image is a flow block with intrinsic width/height), and `mb-core` (for checked arithmetic, bounds, budgets, and structured errors).

It does **not** depend on `mb-color`, `mb-canvas`, or `mb-font`:

- Layout produces positioned frames and flow geometry, not colored or rasterized output. A consumer renders the laid-out frames; layout does not paint.
- It does not need `mb-font` directly: font metrics are reached transitively through `mb-text`'s measurement API. Layout asks text "how tall is this paragraph at this width," not "what is this glyph's ascent."
- It does not need `mb-canvas`: layout produces geometry (frames, regions, page boxes), not pixels.

## 3. The boundary problem and its resolution

### 3.1 Paragraph layout versus document flow

`mb-text` (RFC 0005) owns **paragraph-level** layout: given a string and a width, produce shaped lines with break opportunities, bidi reordering, and per-glyph positions. Text answers "how does this paragraph wrap at width W."

`mb-layout` owns **document-level** flow: given a sequence of content blocks and a page/region geometry, decide which blocks go on which page, how columns are balanced, where images float, and how text wraps around exclusions. Layout answers "where does this paragraph sit on this page."

The cut is: **text owns line breaking within a paragraph; layout owns block placement across pages and regions.** Layout calls text's measurement (advance, line height) to size blocks; it never shapes glyphs or breaks lines itself. This separation means layout is script-agnostic — it works against the measurement contract whether the paragraph is Latin, CJK, or Arabic.

### 3.2 Flow layout versus rendering

`mb-layout` produces a **layout tree**: a positioned frame structure where each content block has resolved coordinates (origin, size) within its page or region. It does not produce pixels.

Rendering is a consumer operation: a renderer walks the layout tree, asks each frame for its content (a shaped paragraph from text, an image view from image), and submits draw operations to `mb-canvas`. Layout does not know what canvas is.

The cut is: **layout owns "where"; rendering owns "what pixels."** This keeps layout testable as pure geometry — a layout fixture asserts frame positions, not pixel colors — and lets the same layout target canvas, a PDF page box, or an SVG group.

### 3.3 Layout versus document format

`mb-layout` owns the **flow algorithm**, not any document format. It does not parse HTML, parse CSS, or read PDF page boxes. It takes a content-block sequence and a geometry specification as inputs and produces a layout tree as output. How a document format (SVG, PDF, HTML) maps to content blocks is the format module's job.

The cut is: **layout owns the algorithm; the document module owns the format-to-block mapping.** SVG, PDF, or a future HTML module each translate their structure into layout's block model and translate the layout tree back into their coordinate space.

### 3.4 Layout versus canvas clip/transform

`mb-canvas` (RFC 0003) owns **clip and transform state** within a drawing list — "draw this path clipped to this region." `mb-layout` owns **content flow into regions** — "this region holds this paragraph, wrapped to this width, overflowing to the next region." These are related but distinct: layout decides *what content goes where*; canvas's clip decides *what pixels survive*.

The cut is: **layout produces frame geometry; canvas clips pixels.** A renderer translates a layout frame into a canvas clip region and offset, but layout itself does not clip.

## 4. Module boundary

### 4.1 `tchivs/mb-layout` owns

- A **content-block model**: a typed sequence of flow blocks — paragraph blocks (carrying a shaped-run reference and measurement query), image blocks (carrying intrinsic dimensions), table blocks (within a bounded subset), and generic spacer/separator blocks — with block-level properties (margins, padding, keep-with-next, break-before/after).
- **Page and region geometry**: page size, margins, header/footer regions, multi-column regions, and arbitrary region shapes (rectangular in v0.x; non-rectangular via exclusion paths in a bounded subset).
- **Pagination**: deterministic placement of blocks across pages, including page-break decisions, orphan/widow control, and keep-together constraints, under bounded iteration.
- **Column layout**: multi-column flow with balanced or fixed column counts and inter-column gaps.
- **Floats and exclusions**: a bounded subset of float placement (left, right, full) and text-wrap-around, producing wrap-contour geometry that text measurement respects.
- **Measurement protocol**: a query interface where layout asks text "given this width, how many lines and what height" and asks image "what are your intrinsic dimensions," driving block sizing without owning glyph or pixel details.
- **Layout tree output**: a positioned frame tree with resolved coordinates, produced deterministically for a given input on every target.

### 4.2 `tchivs/mb-layout` does not own

- Glyph shaping, bidi, or line breaking within a paragraph — those belong to `mb-text`. Layout measures; text shapes.
- Pixel production, painting, or rasterization — those belong to `mb-canvas`.
- Font binary parsing or glyph geometry — those belong to `mb-font`.
- Color application — a layout tree carries no color; coloring is the consumer's job.
- Document parsing (HTML, CSS, PDF, SVG) — format-to-block mapping is the document module's job.
- Interactive editing, drag-and-drop, or live reflow UI state — layout is a deterministic function of its inputs.
- Rich content beyond the bounded block subset (embedded video, interactive widgets, scripting).
- CSS selector engines or stylesheet cascade — declarative styling is a separate concern; layout takes resolved block properties as input.

## 5. Portability and native integration

`mb-layout` proposes the same portable contract: supported targets are `js`, `wasm`, `wasm-gc`, and `native`. Core flow layout, pagination, column balancing, and measurement are portable MoonBit with no ambient host capability. Layout is a pure function of (content blocks, geometry spec, configuration) → (layout tree); it has no host clock, no filesystem, no event loop.

A native acceleration adapter is not anticipated for v0.x — layout is geometry arithmetic, not pixel-heavy work — but the seam is preserved if a future JIT or SIMD-accelerated measurement path emerges. Any adapter remains an optional leaf, never making the portable package transitively native-only.

## 6. v0.x layout subset scope

Full document layout (CSS Flexbox/Grid, TeX-quality pagination, Pango-style complex flow) is a vast surface. This section proposes a bounded, useful subset.

### 6.1 In scope (proposed for v0.x)

- **Block flow**: top-to-bottom sequential block placement within a content region, with margins, padding, and collapse rules for adjacent margins.
- **Page model**: fixed page size, page margins, and a content rect; page-break-before/after and page-break-inside-avoid on blocks.
- **Pagination**: deterministic multi-page flow with orphan/widow control (configurable thresholds) and keep-together constraints.
- **Multi-column**: N-column regions (fixed or balanced column count) with configurable gap and rule.
- **Inline image blocks**: image blocks with intrinsic dimensions (from `mb-image` descriptors), with scale-to-fit and scale-to-width options.
- **Basic floats**: left and right floats with rectangular wrap contours; text-wrap-around via `mb-text` measurement respecting the wrap width per line.
- **Measurement protocol**: query `mb-text` for paragraph height-at-width, and `mb-image` for intrinsic dimensions.
- **Layout tree**: positioned frame output with resolved coordinates, page assignments, and overflow flags.

### 6.2 Deferred (explicitly out of v0.x scope)

- CSS Flexbox, CSS Grid, and full CSS box-model compliance — the v0.x block/column model is a purpose-built subset, not a CSS engine.
- Stylesheet cascade, selector matching, and computed-style resolution — layout takes resolved properties as input.
- Non-rectangular regions and arbitrary exclusion paths (complex shapes) beyond basic float rectangles.
- Table layout beyond a documented minimum (fixed-width, single-row-header tables).
- Footnotes, endnotes, margin notes, and sidenote regions.
- Cross-document references, table-of-contents generation, and index building — those are document-structure concerns.
- SVG-flow-inside-text (flowing text along an SVG path) — that is a canvas/text composition concern.
- Continuous-scroll / infinite-canvas layout (whiteboard-style) — a different layout model, deferred.
- Print-specific features (crop marks, bleed, imposition).

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category.

## 7. Determinism, bounds, and resource safety

Consistent with RFC 0001 Section 4.4 and `mb-core` resource budgets:

- **Deterministic layout.** A given (content-block sequence, geometry spec, configuration) produces a single layout tree on every target, with no ambient state, no host clock, no nondeterministic iteration order. Pagination decisions are reproducible.
- **Bounded pagination.** Page-count, block-count, nesting-depth, and iteration limits are enforced through `mb-core` budgets; pathological inputs (deeply nested blocks, unbounded page growth, circular keep-with constraints) fail with structured errors rather than looping or exhausting memory.
- **Bounded measurement.** Paragraph-measurement queries enforce line-count and width-iteration limits via text's own bounds; layout respects those limits and does not force unbounded measurement.
- **Hostile inputs.** Pathological content (zero-height pages, negative margins causing infinite reflow, circular float dependencies, oversized block counts) are rejected under the resource-budget rules, consistent with RFC 0001 Section 10's security posture for untrusted inputs.

## 8. Alternatives considered and rejected

- **Bundle layout into mb-text.** Rejected. Paragraph-level layout (line breaking) and document-level flow (pagination, columns) are distinct responsibilities with distinct dependencies. Text owns the paragraph; layout owns the page. Bundling would couple text releases to pagination changes and inflate text's dependency footprint.
- **Bundle layout into a document module (SVG/PDF).** Rejected. Each document format would then reimplement pagination, duplicating the algorithm and risking drift. Layout is format-neutral geometry; the format module maps to and from the block model.
- **Implement a full CSS engine.** Rejected. Full CSS (cascade, selectors, Flexbox, Grid) is a massive surface with its own specification lifecycle. The v0.x purpose-built block/column model delivers document pagination without committing to CSS compliance.
- **Make layout own rendering.** Rejected. Layout produces geometry; rendering produces pixels. Bundling them would force every layout consumer to pay for a canvas dependency and break the testability of pure geometry.
- **Depend on mb-canvas or mb-font directly.** Rejected. Layout reaches font metrics transitively through text's measurement API; it does not need canvas because it produces no pixels. Adding these edges would bloat the dependency footprint for pure-layout tooling.
- **Include TeX-quality mathematical typesetting.** Rejected. Math layout is a specialized subfield; it belongs to a follow-up module or a math-specific layout extension, not the v0.x document-flow core.

## 9. Compatibility consequences

This RFC proposes a new module and new public dependency edges. It does not modify any accepted module's boundary, public API, dependency direction, or portability seam. If accepted, this RFC adds one row to the allowed public module edges and is subject to the publication and compatibility policies governing all MNF modules.

Because `mb-layout` would ship as a `candidate`-stability module, it carries no pre-1.0 compatibility promise beyond the executable four-class policy in RFC 0001 Section 10.

This RFC completes the Document and Scene Layer: together with [RFC 0002](0002-mb-svg.md), [RFC 0004](0004-mb-font.md), [RFC 0005](0005-mb-text.md), and [RFC 0006](0006-mb-pdf.md), every module named in RFC 0001's Document and Scene Layer now has a charter. A full document rendering pipeline — parse a format into blocks, flow through layout, measure via text, extract outlines via font, rasterize via canvas — is now architecturally coherent end-to-end.

## 10. Verification plan

Before `mb-layout` may merge, the implementing phases must produce, consistent with RFC 0001 Section 10:

1. Public and internal tests validating block flow, pagination, multi-column, float wrap-around, measurement protocol, and layout-tree output for the in-scope subset.
2. Declared-target CI evidence on `js`, `wasm`, `wasm-gc`, and `native`.
3. Conformance fixtures with provenance and license metadata, covering valid, edge, and hostile block sequences (including circular-keep and pathological-margin cases).
4. Deterministic benchmarks with declared workloads (named block sequences, named page geometries) and reproducible baselines.
5. A security and resource-limit review for untrusted content-block sequences, covering the bounds in Section 7.

## 11. What this RFC does not decide

- The exact internal representation of the block model and layout tree.
- The exact margin-collapse rules (CSS-compliant vs. simplified).
- The exact float-wrap algorithm (simple rectangular vs. shape-aware).
- The exact column-balancing strategy.
- Whether a CSS-compatible property model is ever layered atop the block model.
- The milestone version number and roadmap placement for `mb-layout` phases.

Any of these, if later shown to affect the module boundary, dependency direction, or portability seam, requires its own RFC per RFC 0001 Section 11.

## 12. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter
- [RFC 0005: mb-text Charter](0005-mb-text.md) — paragraph measurement consumed by layout
- [RFC 0003: mb-canvas Charter](0003-mb-canvas.md) — rendering consumer of the layout tree
- [RFC 0006: mb-pdf Charter](0006-mb-pdf.md) — document format consumer of layout
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, authority routes, and evidence
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
