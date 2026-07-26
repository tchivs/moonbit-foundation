# Feature Research: v0.32 TrueType Font Foundation

**Domain:** Portable, bounded static TrueType (`sfnt` + `glyf`) font parsing for MoonBit library authors  
**Researched:** 2026-07-26  
**Confidence:** HIGH for milestone scope and existing MNF contracts; MEDIUM for externally verified format behavior because the research seam classified official OpenType 1.9.1 pages reached through the web-search fallback as MEDIUM.

## Product Boundary

v0.32 should let a caller bring an already-loaded immutable font byte view, admit it under explicit resource limits, and then perform four useful operations without FFI or ambient host state:

1. inspect global and per-glyph metrics in font design units;
2. map a valid Unicode scalar value to a glyph ID;
3. extract an unhinted `Path2`-compatible outline for a simple or bounded composite glyph; and
4. query a basic horizontal legacy kerning adjustment for a glyph pair.

The module owns binary-to-model and binary-to-outline behavior. It does not load system fonts, choose fonts, shape strings, position runs, or rasterize outlines. The public dependency remains:

```text
tchivs/mb-font
  └──> tchivs/mb-core
         ├── checked offsets/ranges/arithmetic
         ├── immutable ByteView / owned byte lifetime
         ├── hierarchical Budget and ResourceLimits
         ├── structured CoreError diagnostics
         └── math::Path2 geometry
```

`mb-canvas` is a downstream consumer, not a dependency. A returned outline must be directly usable as path geometry by a consumer that also imports `mb-canvas`, but `mb-font` must not produce pixels or drawing-list operations.

This milestone deliberately narrows RFC 0004's broader v0.x charter. It implements static TrueType outlines only. CFF/CFF2, variable/color fonts, the hinting VM, advanced layout, font collections, compressed web-font containers, and host font discovery remain deferred.

## User-Visible Behavior Contract

Exact API names may be decided during planning, but the semantic contract should be fixed before implementation.

| Situation | Required result | Why it matters |
|---|---|---|
| Valid static TrueType `sfnt` supplied as an immutable byte view | Return a queryable font that keeps the source storage alive without copying the entire file | Matches `mb-core` ownership and avoids a mandatory file-sized second allocation |
| Valid extra/unknown tables | Ignore them after their directory range is checked | OpenType is extensible; a bounded TrueType reader must not require an allowlist of every optional table |
| CFF/CFF2 (`OTTO`), TTC/OTC, WOFF/WOFF2, variable-only, or color/bitmap-only input | Return a structured `UnsupportedFeature`, distinct from malformed data | Callers can report a truthful capability limit instead of “invalid font” |
| Missing, duplicate, truncated, out-of-range, inconsistent, or checksum-invalid required table | Return a structured data/encoding error with table tag and offset context; publish no `Font` | Deterministic fail-closed admission |
| Valid Unicode scalar has no mapping | Return glyph ID `0` (`.notdef`), not an error | Required OpenType `cmap` behavior |
| Input integer is not a Unicode scalar (`< 0`, surrogate, or `> U+10FFFF`) | Return an invalid-query error, not glyph `0` | Distinguishes an invalid API call from a valid-but-unmapped character |
| Both usable format 4 and format 12 Unicode subtables exist | Select format 12 deterministically; do not union conflicting subtables ad hoc | OpenType recommends the 32-bit subtable and requires consistent selection |
| Glyph ID is outside `0 ..< numGlyphs` | Return an invalid-query error | Prevents unchecked indexing into `loca`, `hmtx`, or `glyf` |
| Glyph has no outline (`loca[n] == loca[n+1]` or a zero-contour glyph) | Return an empty successful outline plus valid metrics | Spaces and control glyphs can be valid and measurable |
| Simple or supported one-level composite glyph is valid | Return a complete, closed-contour, unhinted path in font design units; preserve contour order/winding | Makes output reusable and deterministic |
| Glyph data is malformed or exceeds extraction limits | Return one structured error and no partial path | Callers never receive poisoned or incomplete geometry |
| No `kern` table or no pair record | Return adjustment `0` | Kerning is optional and a missing pair is a valid neutral result |
| A `kern` table exists but only unsupported version/format/coverage semantics are present | Return `UnsupportedFeature` from the kerning capability/query, not silently `0` | Avoids falsely claiming that the font has no adjustment |
| Supported format-0 pair exists | Return the signed adjustment in font design units; do not apply it to advances automatically | Run positioning belongs to a text/layout consumer |

## Feature Landscape

### Table Stakes

Missing any item in this table leaves the advertised TrueType foundation incomplete.

| Feature | Why Expected | Complexity | Testable required behavior |
|---|---|---:|---|
| Independently publishable portable module | RFC 0004 defines `tchivs/mb-font` as a reusable lower-level document/scene module. | MEDIUM | Module depends publicly only on `tchivs/mb-core`, declares `js`, `wasm`, `wasm-gc`, and `native`, and contains no native stub or ambient file access. |
| Bounded immutable-byte admission | Font bytes are commonly untrusted and table offsets are attacker-controlled. | HIGH | Parse from `ByteView`/equivalent with caller-supplied budget/limits; checked `offset + length` and narrowing precede every access/allocation/work charge; failed admission publishes no font object and leaves no partial allocation visible. |
| SFNT directory and integrity validation | Every later query depends on a trustworthy table map. | HIGH | Accept only static TrueType `sfntVersion = 0x00010000`; derive search facts from `numTables` instead of trusting stored search fields; enforce unique sorted tags, in-range table views, four-byte top-level alignment, and declared table checksums (including `head` checksum rules). Unknown tables remain allowed. |
| Required-table contract | A usable OpenType TrueType font requires shared metric/mapping tables plus `glyf` and `loca`. | MEDIUM | Require and structurally validate `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, `OS/2`, `post`, `loca`, and `glyf`. Validate supported major/table versions and cross-table lengths. `name`/`post` need no broad public metadata API in this milestone. |
| Stable global metrics | Consumers need a scale and vertical facts before using outlines. | MEDIUM | Expose `unitsPerEm`, global bounding box, the explicitly named `hhea` ascent/descent/lineGap triplet, and the explicitly named `OS/2` typographic ascent/descent/lineGap triplet in font units. Do not silently collapse the two sources into an undocumented “best” line metric. |
| Stable per-glyph horizontal metrics | Widths and bearings are necessary for even basic glyph placement. | MEDIUM | For every valid glyph ID return advance width and left side bearing from `hmtx`, bounds from `glyf`, and a checked derived right side bearing. Prove the `numberOfHMetrics < numGlyphs` tail rule: the final advance repeats while later left bearings remain per-glyph. Empty glyphs still return metrics. |
| Deterministic Unicode `cmap` formats 4 and 12 | BMP and supplementary-plane lookup are the minimum useful Unicode mapping surface. | HIGH | Support Unicode-platform and Windows Unicode records for formats 4 and 12; validate record, segment/group ordering and all derived array offsets; prefer format 12 when both are usable; return glyph `0` for a valid miss; reject any resulting glyph ID outside `maxp.numGlyphs`. |
| Simple `glyf` outline extraction | Static TrueType's core value is reusable quadratic outline geometry. | HIGH | Decode contour endpoints, repeated flags, signed coordinate deltas, on/off-curve points, implied quadratic points, empty contours, and closure. Emit only move/line/quadratic/close commands in original contour order. Bounds-check instruction bytes but never execute them. |
| One-level composite `glyf` extraction | Accented and reused shapes commonly rely on compound glyph records; “simple only” is not a credible TrueType slice. | HIGH | A top-level composite may reference bounded simple children. Support byte/word arguments, XY offset and point attachment, uniform/nonuniform/2×2 F2DOT14 transforms, ordered component accumulation, and specified scaled/unscaled offset behavior. Reject cycles as invalid data; return `UnsupportedFeature`/limit error for nested composite depth beyond the declared one-level capability. |
| Basic legacy `kern` format 0 | The milestone explicitly promises pair adjustments without claiming GPOS shaping. | MEDIUM | Support a well-formed version-0, horizontal, ordinary kerning-value, non-cross-stream format-0 subtable with sorted `(left,right)` pairs. Return signed font-unit values, `0` for a miss/absent table, and a distinct unsupported result for present-but-out-of-profile `kern` semantics. |
| Structured error and limit semantics | A bounded parser is only reusable if callers can distinguish malformed input, unsupported scope, invalid queries, and exhausted resources. | HIGH | Errors carry stable category/code plus operation and relevant table/glyph/offset/requested/limit context. The same vector produces the same category and canonical context ordering on every target. No foreign exception strings leak into the public contract. |
| Four-target conformance and real-font evidence | Portability and interoperability are milestone acceptance criteria, not later polish. | HIGH | Identical public workflow facts and structured failures pass independently on `js`, `wasm`, `wasm-gc`, and `native`; vendored fixtures have provenance/license metadata and fixed byte digests. |

### Differentiators

These features reinforce MNF's core value without widening format scope.

| Feature | Value Proposition | Complexity | Testable behavior |
|---|---|---:|---|
| Direct `Path2` composition without an `mb-canvas` dependency | Font inspectors and document tools can consume geometry cheaply, while renderers can pass the same outline to canvas. | MEDIUM | Public example performs bytes → font → Unicode glyph → outline; a separate integration example imports canvas and fills the returned path without conversion through a foreign font/raster stack. |
| Cross-table validation rather than isolated struct decoding | Many malformed fonts are only detectable when `head`, `maxp`, `loca`, `glyf`, `hhea`, and `hmtx` facts are compared. | HIGH | Reject mismatched `loca` entry count/order, `loca` beyond `glyf`, impossible `numberOfHMetrics`, cmap glyph IDs beyond `numGlyphs`, invalid metric derivation, and declared maxima that are exceeded by decoded data. |
| Declared limits intersected with untrusted `maxp` maxima | `maxp` describes font requirements but must not grant the font permission to exhaust caller resources. | MEDIUM | Admission/extraction uses the stricter of caller limits and valid font declarations; enormous but internally consistent declarations fail with `BudgetExceeded`/limit error before corresponding allocation or traversal. |
| Operation-local atomicity | A valid font can be retained even when one requested glyph is malformed or over the caller's extraction budget, without exposing a half-built path. | MEDIUM | Font admission validates shared structure; each glyph extraction uses its own bounded transaction and publishes a path only after full validation. A failed glyph query does not corrupt later valid metric/mapping queries. |
| Deterministic subtable/capability selection | Callers get one portable answer instead of platform-dependent cmap or kern selection. | MEDIUM | Fixture with competing format 4/12 mappings proves the declared format-12 precedence on all targets. Unsupported `kern` coverage never degrades silently to a zero adjustment. |
| Evidence at the public workflow boundary | Conformance is demonstrated in the way downstream SVG/PDF/text tools will use the module. | MEDIUM | Frozen test vectors assert glyph ID, metrics, command sequence/count, selected path coordinates/bounds, kerning, error facts, and a canonical semantic digest rather than relying only on internal parser snapshots. |

### Anti-Features

These are explicit non-goals for v0.32, including attractive requests that would undermine the bounded vertical slice.

| Feature | Why Requested | Why Problematic in v0.32 | Alternative |
|---|---|---|---|
| CFF/CFF2 outlines | Broadens `.otf` coverage. | Adds a separate cubic charstring VM, subroutines, operand stacks, and different metric interactions; it is not required to validate TrueType `glyf`. | Return `UnsupportedFeature` for `OTTO`; plan a dedicated CFF milestone. |
| Variable fonts (`fvar`, `gvar`, HVAR/MVAR, CFF2 variations) | Modern families frequently package design axes. | Variation deltas change outlines, phantom points, metrics, bounds, and cache identity across coordinates. | Admit only static/default non-variable TrueType in this milestone; add a variation-instance contract later. |
| Color or bitmap glyphs (COLR/CPAL, SVG, CBDT/CBLC, `sbix`, EBDT/EBLC) | Emoji and display fonts need non-monochrome glyphs. | Produces paints, images, or embedded documents rather than one reusable monochrome outline. | Keep the first API outline-only; define color-glyph output as a separate cross-module design. |
| TrueType hinting VM (`fpgm`, `prep`, `cvt `, glyph instructions) | Better small-size raster output. | Requires a bounded instruction interpreter, ppem/device state, phantom-point mutation, and new denial-of-service limits; it conflicts with target-neutral unhinted geometry. | Bounds-check and skip instruction payloads; return design-space outlines. |
| GSUB/GPOS shaping or automatic kerning application | Callers ultimately want positioned text. | String context, language/script features, bidi, substitutions, and run positioning belong to `mb-text`; automatically changing advances would blur ownership. | Expose single-codepoint cmap, glyph metrics, and an explicit legacy pair query only. |
| Font registry, family matching, fallback, or system discovery | Applications need to choose a font. | Introduces global policy and target-specific filesystem/platform APIs into a portable parser. | Caller supplies bytes through its own capability and owns selection/fallback. |
| Rasterization, glyph bitmaps, or drawing-list emission | Makes a one-call rendering demo. | Duplicates `mb-canvas`, adds image/color dependencies, and bloats non-rendering tools. | Return `Path2`-compatible geometry and document downstream canvas composition. |
| TTC/OTC and WOFF/WOFF2 containers | Common distribution/container formats. | Collections add multiple directories/shared tables; WOFF2 adds a transform/compression pipeline. Neither is needed for the static single-font parser contract. | Require one uncompressed SFNT font resource; add isolated container adapters later. |
| Font authoring, subsetting, merging, or rewriting | Useful for PDF and web output. | Requires output canonicalization, table rebuilding, checksum updates, glyph closure, licensing decisions, and much broader invariants. | Keep v0.32 read-only. |
| “Best line height” convenience policy | Simplifies layout call sites. | `hhea` and `OS/2` expose different named metric sources; selecting between them is layout/platform policy. | Expose raw named triplets and let `mb-text` or the application choose explicitly. |
| Silent repair, clamping, or partial outline recovery | Increases the number of files that appear to parse. | Makes malformed input target/order dependent and can publish geometry the font did not declare. | Fail with structured context before font/path publication. Unknown optional tables remain ignorable; malformed in-scope structures do not. |
| Cache every decoded glyph during parse | Makes repeat extraction faster. | Converts opening a font into font-sized work/allocation and weakens caller control of glyph-level budgets. | Keep immutable validated table views; decode on request. Add an explicit caller-owned cache later if profiling justifies it. |

## Error and Limit Expectations

### Error classes

| Class | Examples | Observable rule |
|---|---|---|
| Invalid query | Non-scalar code point, glyph ID beyond `numGlyphs` | Caller error; never treated as `.notdef` or malformed font data |
| Invalid font data | Truncation, offset overflow, duplicate required tag, bad checksum, unsorted `loca`, out-of-range cmap/glyph reference, cyclic composite | Stable data/encoding error with operation and local context |
| Unsupported feature | `OTTO`, TTC/WOFF, unsupported cmap-only font, nested composite beyond v0.32, unsupported present `kern` profile | Explicit capability result, not a generic invalid-font error |
| Resource exhaustion | Source/table count, allocation, work, points, contours, components, or output commands exceed caller limits | Fail before prohibited allocation/work where it can be preflighted; never publish partial output |

### Required limit dimensions

| Limit | Applied at | Required evidence |
|---|---|---|
| Source bytes and top-level table count | Font admission | Boundary success and `limit + 1` rejection |
| Per-table declared length and checksum work | Directory/table validation | Oversized range rejected before scan/allocation |
| Glyph count and horizontal metric records | `maxp`/`hhea`/`hmtx` cross-check | Impossible count relationships rejected |
| Cmap encoding records, format-4 segments, format-12 groups | Cmap validation/lookup | Huge counts and truncated arrays reject deterministically |
| Points, contours, decoded repeated flags, and emitted path commands | Simple glyph extraction | Compact input cannot expand past caller work/output limits |
| Components, accumulated points/contours, and composite depth | Composite extraction | Fan-out, cycle, repeated-reference, and depth controls |
| Checked transformed coordinate envelope | Composite lowering to geometry | F2DOT14 transform/addition overflow or unsafe conversion rejects before `Path2` publication |
| Allocations and total work | All operations through shared `mb-core` budget | Atomic preflight where facts are known; incremental checked charge for data-dependent traversal |

Font-declared `maxp` values are validation facts, not trusted budgets. The caller's limits remain authoritative even when `maxp` declares a larger legal font.

## Feature Dependencies

```text
mb-core ByteView + checked arithmetic/ranges + Budget + CoreError
  └─→ bounded SFNT directory and table-view model
        ├─→ required-table presence/version/checksum validation
        │     ├─→ head unitsPerEm/global bounds/indexToLocFormat
        │     ├─→ maxp numGlyphs/declared maxima
        │     ├─→ hhea + OS/2 named global metrics
        │     └─→ hhea + maxp + hmtx per-glyph metrics
        ├─→ cmap record selection
        │     └─→ format 4/12 validation and Unicode lookup
        ├─→ maxp + head + loca + glyf
        │     ├─→ simple outline decode
        │     └─→ bounded composite resolution
        │            └─→ mb-core/math::Path2-compatible outline
        └─→ optional kern directory view
              └─→ supported format-0 pair query

all public operations
  └─→ structured errors + declared limits + four-target conformance
```

### Dependency Notes

- **Directory admission precedes every feature:** no table parser may invent its own unchecked source offsets.
- **Global/per-glyph metrics precede complete composite placement:** point attachment may refer to accumulated outline points and unhinted phantom points derived from bounds/metrics.
- **Simple outlines precede composites:** the v0.32 composite boundary resolves only simple child outlines, under one declared nesting level.
- **Cmap does not imply shaping:** it selects one default glyph ID for one scalar; ligatures, contextual substitutions, variation selectors, and bidi remain outside this module.
- **Kerning depends on glyph IDs, not Unicode:** callers map/shape first, then explicitly query a pair.
- **Canvas composition follows font extraction:** `Path2` is the seam; no reverse dependency from `mb-font` to `mb-canvas` is permitted.

## MVP Definition

### Launch With (v0.32)

- [ ] **Portable module and bounded SFNT admission** — exact dependency/target declarations, immutable source lifetime, table directory, required tables, checksum/cross-table validation, and structured errors.
- [ ] **Named global and per-glyph metrics** — `head`, `hhea`, `OS/2`, `maxp`, `hmtx`, and `glyf` bounds with repeat-last-advance behavior.
- [ ] **Unicode mapping** — deterministic format 4/12 selection, supplementary-plane support, scalar validation, and `.notdef` behavior.
- [ ] **Simple unhinted outlines** — all packed flag/delta and quadratic contour cases lowered atomically to reusable path geometry.
- [ ] **One-level composite outlines** — static component placement/transform semantics under explicit component/depth/coordinate limits.
- [ ] **Basic legacy kerning** — supported format-0 horizontal pair lookup with neutral absence/miss and explicit unsupported semantics.
- [ ] **Qualification** — generated conformance/adversarial vectors, representative licensed real fonts, and identical public facts on four targets.

### Add After Validation (v0.32.x or Next Focused Milestone)

- [ ] **Caller-owned glyph cache** — only if benchmarks show repeat decode is material; cache identity must include font and extraction options.
- [ ] **Additional bounded composite depth** — only if real-font fixtures demonstrate one-level rejection is a practical interoperability blocker.
- [ ] **Additional read-only metadata** — selected `name`, `post`, or OS/2 fields only when a concrete inspector/PDF/text consumer requires them.
- [ ] **Additional legacy cmap/kern formats** — only from corpus evidence; do not add speculative binary formats.

### Future Consideration

- [ ] CFF1, then CFF2 as separate bounded charstring milestones.
- [ ] Variable font instances and metric/outline deltas.
- [ ] Color/bitmap glyph representation.
- [ ] Hinting VM.
- [ ] TTC/OTC and WOFF/WOFF2 adapters.
- [ ] Text shaping through `mb-text`.
- [ ] Font discovery/selection/registry outside the parser module.
- [ ] Authoring, subsetting, merging, and serialization.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---|---:|---:|---:|
| Bounded SFNT + required-table admission | HIGH | HIGH | P1 |
| Global metrics | HIGH | MEDIUM | P1 |
| Per-glyph metrics | HIGH | MEDIUM | P1 |
| Unicode cmap 4/12 | HIGH | HIGH | P1 |
| Simple glyf outlines | HIGH | HIGH | P1 |
| One-level composite outlines | HIGH | HIGH | P1 |
| Legacy kern format 0 | MEDIUM | MEDIUM | P1 because explicitly promised |
| Structured limits/errors | HIGH | HIGH | P1 |
| Four-target and real-font qualification | HIGH | HIGH | P1 |
| Caller-owned glyph cache | MEDIUM | MEDIUM | P2 |
| Deeper composites | MEDIUM | MEDIUM | P2, evidence-triggered |
| Broad font metadata | LOW | MEDIUM | P3 |
| CFF/variations/color/hinting/shaping | Potentially HIGH | HIGH | P3, separate milestones |

**Priority key:** P1 is required for v0.32; P2 is an evidence-triggered follow-up; P3 is deferred scope.

## Interoperability and Conformance Evidence

The milestone should not claim “TrueType support” from synthetic happy paths alone. Acceptance evidence should include:

| Evidence class | Minimum content | Frozen assertions |
|---|---|---|
| Minimal generated SFNT | Every required table, short and long `loca`, `hmtx` repeated-width tail | Directory facts, checksums, metrics, empty glyph behavior |
| Cmap vectors | Format 4 delta and glyph-array paths; format 12 BMP + supplementary groups; competing 4/12 records | Selected subtable, mapped IDs, glyph-0 misses, malformed ordering/range rejection |
| Simple glyph vectors | Empty, lines, quadratic curves, consecutive off-curve points, repeated flags, positive/negative coordinate deltas, multiple contours | Exact path command sequence, selected coordinates, bounds, semantic digest |
| Composite vectors | XY and point attachment; byte/word args; uniform, x/y, and 2×2 transforms; multiple children; cycle, fan-out, and depth failures | Exact accumulated geometry/metrics and error class |
| Kern vectors | Absent table, supported pair hit/miss, positive/negative values, unsorted/truncated pairs, unsupported coverage/format | Adjustment or exact error class |
| Representative real fonts | At least two redistributable static `.ttf` resources with recorded origin, license, exact bytes/digest; together exercise simple glyphs, composite accents, format 4 and preferably format 12, `hmtx` tail behavior, and legacy kern if available | Named codepoint → glyph → metrics → outline facts and canonical digest; no host font installation |
| Hostile mutations | Offset/length overflow, duplicate tags, missing required table, checksum mismatch, inconsistent counts, huge expansion claims, recursive/repeated composites | Structured fail-closed result and unchanged budget/output state where observable |
| Portable public workflow | Open fixture → inspect metrics → map scalar → extract path → query kern | Identical semantic facts on `js`, `wasm`, `wasm-gc`, and `native` |

Fixture provenance and licenses are part of acceptance. Tests must never discover fonts from the developer's operating system or network. Large binary expectations should use exact fixture bytes/digests plus semantic assertions, not opaque snapshots alone.

## Requirement Candidates

| ID | Requirement | Acceptance evidence |
|---|---|---|
| **FONT-01** | Library authors can admit a single static TrueType font from immutable bytes under explicit limits and inspect named global/per-glyph metrics through a portable `tchivs/mb-font` API. | Required-table/cross-table/checksum vectors and real fonts prove units-per-em, both named global metric triplets, global/glyph bounds, repeated `hmtx` advance behavior, empty-glyph metrics, structured rejection, and no public dependency beyond `mb-core` on all four targets. |
| **FONT-02** | Library authors can map a valid Unicode scalar through deterministic cmap format 4/12 selection, receiving glyph `0` for a valid miss and a structured error for an invalid scalar or malformed mapping. | BMP, supplementary, competing-subtable, miss, invalid-scalar, unsorted/truncated, and out-of-range-glyph vectors produce identical facts on all four targets. |
| **FONT-03** | Library authors can extract complete unhinted `Path2`-compatible outlines for valid simple glyphs and bounded one-level composites, with checked arithmetic and no partial geometry on failure. | Simple packing/curve/closure vectors, all static composite placement/transform modes, real composite glyphs, and point/contour/component/depth/cycle/overflow adversarial cases assert exact commands/coordinates/bounds or exact structured error on every target. |
| **FONT-04** | Library authors can query basic legacy horizontal format-0 kerning and distinguish neutral absence/miss from present-but-unsupported or malformed kerning data. | Pair hit/miss/absent/positive/negative, unsupported coverage/version/format, and malformed pair arrays pass with identical results on every target. |
| **FONT-05** | Maintainers can reproduce the complete public font workflow and hostile-input qualification using licensed, immutable fixtures without GUI, filesystem discovery, FFI, or target-specific behavior. | Fixture manifest records provenance/license/digest; one public workflow and adversarial selector pass independently on `js`, `wasm`, `wasm-gc`, and `native`. |

## Roadmap Recommendation

Build the milestone in dependency order:

1. **Module, limits, and SFNT admission** — establish publication boundary, immutable byte ownership, checked table directory, required-table and integrity model.
2. **Metrics and Unicode mapping** — finish cross-table validation and deliver useful non-geometry queries early.
3. **Simple outlines** — decode all static simple-glyph representations to `Path2`.
4. **Composite outlines and kerning** — layer bounded composition over proven simple glyphs, then add the isolated optional pair table.
5. **Interoperability and hostile qualification** — freeze real/generated fixtures and prove the complete public workflow on all four targets.

Do not combine CFF, variations, hinting, shaping, discovery, or rasterization with these phases. Each adds a new state machine or ownership boundary and would make it difficult to know whether the first TrueType contract itself is sound.

## Sources

### Project authority — HIGH

- [Project definition and v0.32 requirements](../PROJECT.md)
- [RFC 0004: `mb-font` Charter](../../docs/rfcs/0004-mb-font.md)
- [`mb-core` public README/API examples](../../modules/mb-core/README.mbt.md) — checked arithmetic/ranges, immutable byte views, budgets, structured errors, partial I/O, and explicit capabilities.
- [`mb-canvas` public README/API examples](../../modules/mb-canvas/README.mbt.md) — confirms `Path2` input and the font-outline-to-canvas downstream boundary.

### Official OpenType 1.9.1 specification — MEDIUM by research seam classification

- [The OpenType Font File](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — big-endian data, SFNT directory, parser-derived search fields, table records/alignment/checksums, required tables, and TrueType outline tables.
- [`cmap` — Character to Glyph Index Mapping](https://learn.microsoft.com/en-us/typography/opentype/spec/cmap) — format 4/12 behavior, Unicode record selection, sorting rules, and glyph-0 misses.
- [`head` — Font Header](https://learn.microsoft.com/en-us/typography/opentype/spec/head) — units-per-em, global bounds, and `indexToLocFormat`.
- [`hhea` — Horizontal Header](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea) and [`OS/2` — OS/2 and Windows Metrics](https://learn.microsoft.com/en-us/typography/opentype/spec/os2) — named global metric sources and horizontal metric count.
- [`hmtx` — Horizontal Metrics](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx) — advances, bearings, repeated final advance width, and right-side-bearing derivation.
- [`maxp` — Maximum Profile](https://learn.microsoft.com/en-us/typography/opentype/spec/maxp), [`loca` — Index to Location](https://learn.microsoft.com/en-us/typography/opentype/spec/loca), and [`glyf` — Glyph Data](https://learn.microsoft.com/en-us/typography/opentype/spec/glyf) — glyph counts/maxima, monotone `numGlyphs + 1` offsets, simple/composite records, transforms, and acyclic composite graphs.
- [TrueType Fundamentals](https://learn.microsoft.com/en-us/typography/opentype/otspec190/ttch01) — line/quadratic contour semantics, on/off-curve control points, winding, and font design units.
- [`kern` — Kerning](https://learn.microsoft.com/en-us/typography/opentype/spec/kern) and [Recommendations for OpenType Fonts](https://learn.microsoft.com/en-us/typography/opentype/spec/recom) — legacy format-0 horizontal pair structure and recommended single-subtable profile.

---
*Feature research for: v0.32 TrueType Font Foundation*
*Researched: 2026-07-26*
