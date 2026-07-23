# RFC 0004: mb-font Charter

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-22
- **Target:** Document and Scene Layer font module charter
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

This RFC proposes `tchivs/mb-font` as a new MNF module in the Document and Scene Layer, responsible for parsing font binary tables into a validated, queryable font model and for extracting glyph outlines and metrics from that model. It establishes the module boundary, the allowed public dependency direction, the font-format subset, and the critical split between font parsing (this module) and glyph rasterization (delegated to `mb-canvas`).

`mb-font` answers a single question: how does an MNF consumer extract glyph outlines and metrics from a font file, deterministically and on every target, without each consumer rebuilding an incompatible parser. RFC 0001 names `mb-font` in the Document and Scene Layer but Section 6 does not define its responsibilities. This RFC fills that gap.

This RFC does not implement `mb-font`. It creates no `.mbt` source, no package manifest, and no module declaration. Per [RFC 0001](0001-moonbit-native-foundation.md) Section 11, creation of a new MNF module requires a Proposed RFC before implementation may merge.

## 2. Relationship to RFC 0001

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-font` in the Document and Scene Layer alongside `mb-svg`, `mb-text`, `mb-layout`, and `mb-pdf`, above the Graphics Layers (`mb-canvas`, `mb-image`, `mb-color`) and the Foundation (`mb-core`). RFC 0001 Section 6.4 governs deferred layers: `mb-font` may consume accepted lower-layer contracts and may not redefine them through implementation alone.

The allowed public dependency direction proposed here is:

```text
tchivs/mb-font -> tchivs/mb-core
```

`mb-font` depends only on `mb-core`. It does **not** depend on `mb-color`, `mb-image`, or `mb-canvas`:

- It does not need `mb-color`: a font file carries no color-space semantics; font color is applied by the rendering consumer, not by the font model.
- It does not need `mb-image`: glyph outlines are vector geometry, not pixels.
- It does not need `mb-canvas`: rasterization is the consumer's job, not the font model's (see Section 3).

This minimal edge keeps `mb-font` consumable by lightweight tooling (font inspection, metric queries, subsetters) that has no need for raster or color infrastructure.

## 3. The boundary problem and its resolution

### 3.1 Font parsing versus glyph rasterization

The central boundary decision is: **a font module parses binary tables into outlines and metrics; it does not rasterize glyphs into pixels.** This mirrors the image-versus-canvas cut in [RFC 0003](0003-mb-canvas.md) Section 3.1.

- `mb-font` owns the **font model**: parsing font binary (tables, glyph data, metrics, OpenType features), validating structure under bounds, and exposing glyph outlines as vector geometry (contours of line and curve segments) plus advance widths, bearings, and kerning.
- `mb-canvas` owns the **pixel production**: a consumer asks `mb-font` for a glyph outline, then submits that outline to `mb-canvas` as path geometry for fill. The font module does not know what canvas is.

The cut is: **binary-to-outline belongs to `mb-font`; outline-to-pixel belongs to `mb-canvas`.** A glyph outline from `mb-font` is exactly the kind of path geometry `mb-canvas` accepts (RFC 0003 Section 4.1), so the two modules compose without either reaching into the other.

### 3.2 Font model versus text layout

`mb-font` owns the **single-glyph and font-level** model: one glyph's outline, one glyph's metrics, one font's global metrics (units-per-em, ascent, descent, line gap), and one font's table structure.

`mb-text` (RFC 0005) owns the **string-level** model: mapping a Unicode string to a glyph sequence, shaping (applying OpenType features in context), bidi reordering, and line breaking. Text asks font for glyph IDs and metrics; font does not know what a string is.

The cut is: **font owns per-glyph geometry and metrics; text owns the mapping from a string to a positioned glyph sequence.** This keeps font format-neutral with respect to script and text layout policy.

### 3.3 Font files versus font selection

`mb-font` owns parsing **one font file** into a model. It does not own font selection, font matching, fallback chains, or a font registry. Selecting which font to use for a given script, family, weight, or missing glyph is a consumer-side or `mb-text`-side policy decision. A global font registry, if ever needed, is a separate boundary and a separate RFC.

## 4. Module boundary

### 4.1 `tchivs/mb-font` owns

- Parsing a bounded subset of font binary formats (Section 6) into a validated, queryable font model, including table directory parsing, required-table validation, and structured rejection of malformed or oversized inputs.
- **Glyph outline extraction**: converting a glyph's outline data (TrueType contours or CFF/CFF2 charstrings) into a normalized vector path of line segments and quadratic or cubic Bézier curves, with checked coordinate arithmetic.
- **Glyph metrics**: advance width, left/right side bearings, and bounds (xMin/yMin/xMax/yMax) per glyph, under the font's units-per-em.
- **Font-level metrics**: units-per-em, ascent, descent, line gap, and global bounding box, as declared by the font's metric tables.
- **Cmap resolution**: mapping a Unicode codepoint to a glyph ID through the font's cmap table, returning a notdef sentinel for unmapped codepoints rather than failing.
- **Kerning and basic positioning**: pairwise kerning from the kern table and, within the OpenType subset (Section 6.1), GPOS lookups needed for glyph positioning. Advanced GSUB/GPOS is split between font (table access) and text (feature application); see Section 3.2 and 6.1.
- Conformance fixtures with provenance and license metadata, consumed through test helpers.

### 4.2 `tchivs/mb-font` does not own

- Glyph rasterization or hinting execution. Outlines are returned as geometry; the consumer rasterizes via `mb-canvas`. Hinting, if supported, is a bounded outline adjustment, not a pixel operation (Section 7.2).
- Color-space, transfer, or alpha semantics — font files carry no color identity; color is applied by the consumer.
- Text shaping, bidi reordering, line breaking, or string-to-glyph-sequence mapping — those belong to `mb-text`.
- Font selection, fallback, or a font registry.
- Pixel storage, image format, or codec — those remain in `mb-image`.
- Filesystem policy or font-file loading — host access enters through explicit capabilities per RFC 0001 Section 8.

## 5. Portability and native integration

`mb-font` proposes the same portable contract as the existing foundation modules: supported targets are `js`, `wasm`, `wasm-gc`, and `native`, with `native` as the primary performance target. Core parsing, outline extraction, and metric computation are portable MoonBit with no ambient host capability.

A native acceleration adapter (for example, a SIMD-accelerated outline flattener) is permitted as an optional leaf behind a documented seam, never making the portable package transitively native-only, consistent with RFC 0001 Section 8.

## 6. v0.x font-format subset scope

Full font support spans multiple complex binary formats and feature systems. This section proposes a bounded, useful subset.

### 6.1 In scope (proposed for v0.x)

- **TrueType (glyf) outlines**: quadratic Bézier contours with on-curve and off-curve points, compound glyphs (one level of nesting), and contour winding.
- **OpenType/CFF (CFF1) outlines**: cubic Bézier charstrings via Type 2 operators, with a bounded subset of the charstring instruction set sufficient for standard Latin and CJK glyph sets.
- **Required tables**: `head`, `hhea`, `hmtx`, `maxp`, `name` (subset of name records), `OS/2` (metric fields), `cmap` (formats 4 and 12 for BMP and supplementary planes), `post` (glyph name formats), `loca` (for TrueType).
- **Basic metrics**: advance widths, side bearings, units-per-em, ascent/descent/lineGap.
- **Kerning**: `kern` table (format 0 horizontal pairs).
- **Coordinate normalization**: all coordinates normalized to font units (integer or fixed-point as declared), converted to caller-chosen numeric type on extraction with checked arithmetic.

### 6.2 Deferred (explicitly out of v0.x scope)

- Variable fonts (fvar, gvar, variation instances) — a large surface deferred to a follow-up.
- CFF2 outlines and full variable-font charstrings.
- Advanced OpenType GSUB/GPOS shaping (the full layout engine) — feature-table access may be in scope, but full contextual/chain contextual shaping belongs to `mb-text` and is deferred there.
- Color fonts (COLR/CPAL, SVG-in-OpenType, CBDT/CBLC bitmap, sbix).
- Bitmap-only fonts and embedded bitmaps (EBDT/EBLC).
- AAT tables (morx, feat) and Graphite — Apple and SIL advanced shaping engines.
- TrueType hinting instruction execution (the hinting VM). Outline adjustment via hinting is deferred; v0.x returns unhinted outlines.
- Font subsetting, merging, or authoring — those are separate tools, not the font model's core.
- WOFF/WOFF2 container decompression — a compression wrapper; if needed, it enters as an isolated adapter.

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category.

## 7. Hinting, determinism, and bounds

### 7.1 Determinism and the unhinted outline

v0.x returns **unhinted outlines**. An unhinted outline is the font's design-space geometry without grid-fitting or instruction execution. This guarantees determinism: the same font and glyph ID produce the same outline on every target, with no instruction-VM nondeterminism. Hinting (Section 7.2) is deferred because the TrueType hinting VM is a source of target-dependent output that would undermine the determinism contract.

### 7.2 Hinting as a future bounded adjustment

If hinting is later added, it is scoped as a **bounded outline adjustment** that produces adjusted geometry, never as a pixel operation. The hinting VM would be a portable, bounded interpreter with declared instruction limits, subject to the resource-budget and hostile-input rules of Section 8. This keeps the font-rasterization boundary intact regardless of whether hinting is eventually supported.

### 7.3 Bounds and resource safety

Consistent with RFC 0001 Section 4.4 and `mb-core` resource budgets:

- **Checked coordinate arithmetic.** All coordinate conversion uses checked arithmetic; overflow fails with structured errors.
- **Bounded parsing.** Table-directory parsing enforces table-count, table-size, and nesting limits; malformed offsets and oversized tables are rejected before allocation.
- **Bounded outlines.** Glyph extraction enforces point-count, contour-count, and compound-nesting limits; pathologically complex glyphs fail rather than exhaust memory.
- **Hostile inputs.** Malicious fonts (crafted offsets, recursive compounds, oversized instructions, truncated tables) are rejected at parse time, consistent with RFC 0001 Section 10's security posture for untrusted inputs.

## 8. Alternatives considered and rejected

- **Bundle glyph rasterization into the font module.** Rejected. It would duplicate `mb-canvas` (RFC 0003) and force every font consumer to pay for a rasterizer. The boundary is: font produces geometry, canvas produces pixels.
- **Bundle text shaping into the font module.** Rejected. Shaping is string-level logic (bidi, feature application, line breaking) distinct from font-binary parsing. It belongs to `mb-text`.
- **Wrap FreeType or HarfBuzz as the core implementation.** Rejected per RFC 0001 Section 4.1. A foreign library may appear only as an isolated, replaceable native adapter behind a seam, never as the portable public contract.
- **Include variable fonts or color fonts in the initial subset.** Rejected. Both are large surfaces that would delay the useful TrueType/CFF + metrics core. They are deferred to follow-up RFCs.
- **Depend on `mb-color` or `mb-image`.** Rejected. A font file carries no color semantics and produces geometry, not pixels. Adding these edges would bloat the dependency footprint for lightweight font tooling with no benefit.
- **Own a font registry or selection policy.** Rejected. Selection and fallback are consumer-side policy. A registry, if needed, is a separate boundary.

## 9. Compatibility consequences

This RFC proposes a new module and a new public dependency edge. It does not modify any accepted module's boundary, public API, dependency direction, or portability seam. If accepted, this RFC adds one row to the allowed public module edges and is subject to the publication and compatibility policies governing all MNF modules.

Because `mb-font` would ship as a `candidate`-stability module, it carries no pre-1.0 compatibility promise beyond the executable four-class policy in RFC 0001 Section 10.

This RFC unblocks [RFC 0005](0005-mb-text.md): once `mb-font` is accepted, `mb-text` can consume the font model for glyph ID resolution, metrics, and outline extraction instead of defining its own font access.

## 10. Verification plan

Before `mb-font` may merge, the implementing phases must produce, consistent with RFC 0001 Section 10:

1. Public and internal tests validating table parsing, outline extraction (TrueType and CFF), metric computation, and cmap resolution for the in-scope subset.
2. Declared-target CI evidence on `js`, `wasm`, `wasm-gc`, and `native`.
3. Conformance fixtures with provenance and license metadata, covering valid, edge, and hostile font files.
4. Deterministic benchmarks with declared workloads (named fonts, named glyph sets) and reproducible baselines for parsing and outline extraction.
5. A security and resource-limit review for untrusted font files, covering the bounds in Section 7.3.

## 11. What this RFC does not decide

- The exact internal representation of outlines (quadratic-on-curve flags vs. cubic control points).
- The exact numeric type for coordinates (fixed-point vs. floating) in the public API.
- The exact name-record subset exposed from the `name` table.
- Whether CFF2 and variable fonts share a v0.x-adjacent phase or require separate RFCs.
- The milestone version number and roadmap placement for `mb-font` phases.

Any of these, if later shown to affect the module boundary, dependency direction, or portability seam, requires its own RFC per RFC 0001 Section 11.

## 12. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter
- [RFC 0003: mb-canvas Charter](0003-mb-canvas.md) — rasterization consumer of font outlines
- [RFC 0005: mb-text Charter](0005-mb-text.md) — text-layout consumer of the font model
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, authority routes, and evidence
- OpenType Specification 1.9 — the font binary format subset referenced by Section 6
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
