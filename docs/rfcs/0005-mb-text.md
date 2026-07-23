# RFC 0005: mb-text Charter

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-22
- **Target:** Document and Scene Layer text layout module charter
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

This RFC proposes `tchivs/mb-text` as a new MNF module in the Document and Scene Layer, responsible for mapping a Unicode string to a positioned sequence of glyph references, including bidirectional reordering, script-aware segmentation, basic OpenType feature application, and line breaking. It establishes the module boundary, the allowed public dependency direction, the text-layout subset, and the critical split between text layout (this module) and glyph geometry/rasterization (delegated to `mb-font` and `mb-canvas`).

`mb-text` answers a single question: how does an MNF consumer turn a Unicode string into a correctly ordered, positioned glyph sequence, deterministically and on every target, without each consumer rebuilding an incompatible shaping and layout engine. RFC 0001 names `mb-text` in the Document and Scene Layer but Section 6 does not define its responsibilities. This RFC fills that gap.

This RFC does not implement `mb-text`. It creates no `.mbt` source, no package manifest, and no module declaration. Per [RFC 0001](0001-moonbit-native-foundation.md) Section 11, creation of a new MNF module requires a Proposed RFC before implementation may merge.

## 2. Relationship to RFC 0001

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-text` in the Document and Scene Layer alongside `mb-svg`, `mb-font`, `mb-layout`, and `mb-pdf`, above the Graphics Layers and the Foundation. RFC 0001 Section 6.4 governs deferred layers: `mb-text` may consume accepted lower-layer contracts and may not redefine them through implementation alone.

The allowed public dependency direction proposed here is:

```text
tchivs/mb-text -> tchivs/mb-font
tchivs/mb-text -> tchivs/mb-core
```

`mb-text` depends on `mb-font` (for glyph ID resolution, metrics, and outline access) and `mb-core` (for checked arithmetic, bounded I/O, budgets, structured errors, **and the already-accepted `mb-core/unicode` Unicode-property and segmentation contracts**). It does **not** depend on `mb-color`, `mb-image`, or `mb-canvas`:

**Unicode-property and segmentation boundary:** `mb-core/unicode` is an accepted public package that already exports grapheme-cluster segmentation (UAX #29: `segment_graphemes`, `should_break_grapheme`, `grapheme_break_class`), `BidiClass` classification (`bidi_class`), `GeneralCategory`, and a pinned `unicode_version()`. `mb-text` **consumes** these as lower-layer contracts under RFC 0001 Section 6.4; it does **not** re-implement them, ship duplicate segmentation tables, or redefine `mb-core`'s public Unicode boundary. Any text-layout-specific Unicode need not already exposed by `mb-core/unicode` (for example UAX #14 line-break property classification, or UAX #9 isolate/paragraph-level resolution beyond what `bidi_class` provides) is layered on top in `mb-text` as a consumer of `mb-core/unicode`, not as a replacement for it.

- Text layout produces positioned glyph references, not colored or rasterized output. Coloring and rasterizing a shaped run is the consumer's job.
- This keeps `mb-text` consumable by text-heavy tooling (indexing, metric measurement, accessibility, search) that has no need for pixels.

## 3. The boundary problem and its resolution

### 3.1 Text layout versus font format

`mb-text` owns the **string-level** model: given a Unicode string and a font model reference, produce a shaped and positioned glyph sequence.

`mb-font` (RFC 0004) owns the **font-binary** model: parse font tables, expose glyph outlines and metrics, resolve codepoint-to-glyph-ID via cmap.

The cut is: **text maps a string to glyph IDs and positions; font provides the glyph data behind that mapping.** Text calls font's cmap resolution and metric queries; it never parses font binary. This separation means text is font-format-agnostic: it works against the font model contract, whether the underlying font is TrueType or CFF.

### 3.2 Text layout versus rasterization

`mb-text` produces **positioned glyph references** — each glyph has an ID, an advance, an offset, and a reference to the font that sourced it. It does not produce pixels.

`mb-canvas` (RFC 0003) produces **pixels** from geometry. To rasterize text, a consumer asks `mb-text` for positioned glyphs, asks `mb-font` for each glyph's outline (translated by the position offset), and submits each outline to `mb-canvas` as a fill operation. Neither `mb-text` nor `mb-font` knows what canvas is.

The cut is: **text owns positioning; font owns geometry; canvas owns pixels.** This three-way split means text layout is testable and consumable without any rendering, and the same shaped run can target canvas, a PDF stream, or an SVG `<text>` element.

### 3.3 Text layout versus document structure

`mb-text` owns layout **within a text run or paragraph**: bidi, shaping, line breaking, alignment, and basic spacing. It does not own document-level text flow (columns, regions, flowed content around images, pagination). Document-level flow belongs to `mb-layout` or the document module (`mb-svg`, `mb-pdf`).

The cut is: **text owns paragraph-level layout; layout owns document-level flow.** `mb-text` takes a paragraph and produces positioned glyphs; `mb-layout` takes positioned paragraphs and places them into regions.

## 4. Module boundary

### 4.1 `tchivs/mb-text` owns

- **Unicode segmentation (consumer, not owner)**: grapheme-cluster, word, and sentence segmentation per Unicode Text Segmentation (UAX #29) is **owned by the accepted `mb-core/unicode` package** and consumed by `mb-text`; `mb-text` does not re-implement or redefine that boundary. `mb-text` owns only the text-layout-specific segmentation concerns layered on top (for example, mapping grapheme/word boundaries produced by `mb-core/unicode` into break opportunities and cursor stops), deterministically and under bounds.
- **Bidirectional algorithm**: applying the Unicode Bidirectional Algorithm (UAX #9) to reorder characters for visual display. The raw `BidiClass` classification of a codepoint is **owned by `mb-core/unicode`** and consumed by `mb-text`; the bidi *algorithm* (paragraph level detection, explicit embedding, implicit/neutral resolution within the in-scope subset per Section 6) is owned by `mb-text` and layered on those classes.
- **Script and language detection**: assigning script and, where available, language properties to runs, to drive shaping decisions.
- **Shaping**: mapping codepoints to glyph IDs (via `mb-font` cmap), applying a bounded subset of OpenType features (Section 6.1), and computing glyph advances and positions using `mb-font` metrics and basic GPOS positioning.
- **Line breaking**: computing break opportunities per Unicode Line Breaking (UAX #14), with a bounded greedy line-breaking algorithm and configurable measure (advance-based).
- **Paragraph layout**: assembling shaped runs into lines, applying alignment (start, end, center, justify within a bounded subset), and producing a positioned glyph sequence with explicit coordinates.
- **Bounded, deterministic output**: every layout operation produces a single result for a given input on every target, with no ambient state or host dependency.

### 4.2 `tchivs/mb-text` does not own

- Font binary parsing, outline extraction, or table structure — those belong to `mb-font`.
- Glyph rasterization, hinting, or pixel production — those belong to `mb-canvas`.
- Color application — a shaped glyph sequence carries no color; coloring is the consumer's job.
- Document-level flow: columns, regions, pagination, or text-around-graphics — those belong to `mb-layout` or the document module.
- Font selection, fallback chains, or a font registry.
- Rich-text document models (attributes, spans, embedded objects beyond a documented minimum).
- Filesystem or font-file loading — host access enters through explicit capabilities per RFC 0001 Section 8.

## 5. Portability and native integration

`mb-text` proposes the same portable contract as the existing foundation modules: supported targets are `js`, `wasm`, `wasm-gc`, and `native`. Core segmentation, bidi, shaping, and layout are portable MoonBit with no ambient host capability.

Unicode data (bidirectional mirroring, line-break categories, segmentation tables) is portable data, not host capability. The module **consumes the already-shipped bounded Unicode property tables of `mb-core/unicode`** (grapheme/bidi/general-category classification and the pinned Unicode version) and adds only the supplementary tables that `mb-core/unicode` does not yet expose — for example UAX #14 line-break property categories and UAX #9 mirroring pairs — as a consumer layered on `mb-core/unicode`, without duplicating or forking the lower-layer tables. It does not rely on a host ICU or system Unicode library, preserving portability and determinism. A native acceleration adapter is an optional leaf, never making the portable package transitively native-only.

## 6. v0.x text-layout subset scope

Full text layout spans complex Unicode algorithms and the entire OpenType feature system. This section proposes a bounded, useful subset.

### 6.1 In scope (proposed for v0.x)

- **Grapheme, word, sentence segmentation** (UAX #29) with shipped Unicode property tables.
- **Bidirectional algorithm** (UAX #9): paragraph level detection, explicit embeddings (LRE/RLE/LRO/RLO/PDF), implicit strong/weak/neutral resolution, and mirroring. Isolate formatting (FSI/LRI/RLI/PDI) is deferred (Section 6.2).
- **Line breaking** (UAX #14): line-break property classification and a bounded greedy line breaker using advance-based measure.
- **Shaping**: codepoint-to-glyph-ID mapping (via font cmap), and a bounded subset of OpenType features sufficient for common scripts — at minimum `liga`, `cmap`, and basic `kern`. Full contextual/chain-contextual GSUB is deferred.
- **Basic positioning**: advance accumulation, pairwise kerning, and a bounded subset of GPOS for mark attachment and basic cursive connection within the in-scope feature set.
- **Horizontal layout**: paragraph assembly, line breaking, and alignment (start, end, center; justify as a bounded subset).
- **Metrics**: advance-based measurement using `mb-font` metrics, with ascent/descent/line-gap for line height.

### 6.2 Deferred (explicitly out of v0.x scope)

- Bidirectional isolate formatting (FSI/LRI/RLI/PDI) — a newer, complex part of UAX #9.
- Full OpenType contextual and chain-contextual GSUB/GPOS — the complete shaping engine for scripts like Arabic, Indic, and Khmer that require deep contextual substitution. Basic features are in scope; the full engine is deferred.
- Vertical text layout and vertical metrics — horizontal layout only in v0.x.
- Advanced justification (kashida, inter-character beyond a bounded subset).
- Rich-text models: attribute spans, embedded objects, inline images, and links beyond a documented minimum.
- Text-to-path conversion (that is a consumer operation combining text + font + canvas).
- Font fallback and multi-font shaping — single-font shaping in v0.x; fallback is a selection-layer concern.
- Complex script-specific tailoring beyond the bounded feature subset (e.g., full Hangul, full Tibetan).

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category.

## 7. Determinism, bounds, and resource safety

Consistent with RFC 0001 Section 4.4 and `mb-core` resource budgets:

- **Deterministic algorithms.** Segmentation, bidi, shaping, and line breaking are pure functions of their inputs. The same string, font model, and configuration produce the same positioned glyph sequence on every target.
- **Bounded Unicode tables.** Shipped property tables are bounded in size and version-pinned; table lookups enforce range checks.
- **Bounded layout.** Line breaking, paragraph assembly, and glyph positioning enforce length, line-count, and run-count limits through `mb-core` budgets; pathologically long or deeply structured inputs fail with structured errors rather than exhausting memory.
- **Hostile inputs.** Malicious strings (combining-mark bombs, extreme nesting, pathological bidi sequences) are handled under the resource-budget and rejection rules, consistent with RFC 0001 Section 10's security posture for untrusted inputs.

## 8. Alternatives considered and rejected

- **Bundle font parsing into the text module.** Rejected. Font parsing is a distinct responsibility (RFC 0004); bundling it would couple text releases to font-format changes and duplicate the parser.
- **Bundle rasterization into the text module.** Rejected. Text produces positioned glyph references; rasterization is canvas's job. Bundling pixels would force every text consumer to pay for rendering.
- **Bundle document-level flow (columns, pagination) into text.** Rejected. Paragraph-level layout and document-level flow are distinct responsibilities; flow belongs to `mb-layout` or the document module.
- **Depend on a host ICU or HarfBuzz.** Rejected. Host dependencies break portability and determinism. The module ships its own bounded Unicode tables and shaping logic in portable MoonBit.
- **Include the full OpenType shaping engine in v0.x.** Rejected. Full contextual shaping for all scripts is a large surface; a bounded feature subset delivers Latin, CJK, and basic scripts first, with complex scripts deferred.
- **Include vertical text in v0.x.** Rejected. Horizontal layout covers the majority of initial consumers; vertical layout adds metric and algorithmic complexity deferred to a follow-up.

## 9. Compatibility consequences

This RFC proposes a new module and a new public dependency edge. It does not modify any accepted module's boundary, public API, dependency direction, or portability seam. If accepted, this RFC adds one row to the allowed public module edges and is subject to the publication and compatibility policies governing all MNF modules.

Because `mb-text` would ship as a `candidate`-stability module, it carries no pre-1.0 compatibility promise beyond the executable four-class policy in RFC 0001 Section 10.

This RFC unblocks document-layer consumers ([RFC 0002](0002-mb-svg.md), [RFC 0006](0006-mb-pdf.md)): once `mb-text` is accepted, SVG and PDF can render text by consuming shaped glyph sequences from text, outlines from font, and fill from canvas, without each defining its own shaping.

## 10. Verification plan

Before `mb-text` may merge, the implementing phases must produce, consistent with RFC 0001 Section 10:

1. Public and internal tests validating segmentation, bidi, shaping, line breaking, and paragraph layout for the in-scope subset, including Unicode conformance test data where applicable.
2. Declared-target CI evidence on `js`, `wasm`, `wasm-gc`, and `native`.
3. Conformance fixtures with provenance and license metadata, covering valid, edge, and hostile strings.
4. Deterministic benchmarks with declared workloads (named strings, named scripts) and reproducible baselines.
5. A security and resource-limit review for untrusted strings, covering the bounds in Section 7.

## 11. What this RFC does not decide

- The exact internal representation of shaped runs and positioned glyph sequences.
- The exact Unicode version pinned in the shipped tables.
- The exact OpenType feature set boundary between "basic" and "full."
- The line-height and baseline model details.
- Whether justify supports script-specific behavior beyond a bounded subset.
- The milestone version number and roadmap placement for `mb-text` phases.

Any of these, if later shown to affect the module boundary, dependency direction, or portability seam, requires its own RFC per RFC 0001 Section 11.

## 12. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter
- [RFC 0004: mb-font Charter](0004-mb-font.md) — font model consumed by text
- [RFC 0003: mb-canvas Charter](0003-mb-canvas.md) — rasterization of shaped text
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, authority routes, and evidence
- Unicode Text Segmentation (UAX #29), Bidirectional Algorithm (UAX #9), Line Breaking (UAX #14)
- OpenType Specification 1.9 — the feature subset referenced by Section 6
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
