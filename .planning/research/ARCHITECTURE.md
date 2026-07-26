# Architecture Research

**Domain:** v0.32 bounded TrueType/SFNT font foundation
**Researched:** 2026-07-26
**Confidence:** HIGH for repository integration seams; MEDIUM for the proposed pre-1.0 API and cache policy

## Executive Recommendation

Add one independently publishable module, `tchivs/mb-font`, with one public
portable package, `tchivs/mb-font/font`. Keep all SFNT readers, table records,
decoded point structures, validation state, and request-local caches private
inside that package. The only module dependency is `mb-font -> mb-core`.

Open a font in two stages: first establish a fully validated, bounded structural
index over a retained `mb-core/bytes::ByteView`; then answer cmap, metric,
kerning, and outline queries from that index. No glyph decoder may read a raw
offset from the file. It receives only a checked table subview or a checked
`loca[glyph]..loca[glyph+1]` window created by the structural layer.

Return outlines as `mb-core/math::Path2`. This is already documented as shared
geometry produced by `mb-font` and consumed by `mb-canvas`. Consumers can fill
the path through `mb-canvas` without either module depending on the other.
Internally, do not lower directly to `Path2`: composite glyph point-number
attachment requires a private point/contour representation until all child
transforms and attachments are resolved.

## Standard Architecture

### System Overview

```text
untrusted TTF bytes
        |
        v
ByteView + FontLimits + Budget
        |
        v
SFNT gate: signature, directory size, tags, ranges, overlap, checksums
        |
        v
cross-table gate: head/maxp/hhea/hmtx/cmap/loca/glyf (+ optional kern)
        |
        v
validated Font index
  |          |            |                 |
  v          v            v                 v
cmap      metrics       kern          glyph window
lookup    lookup        lookup       from checked loca
                                         |
                              simple/composite decoder
                                         |
                              private points/contours
                                         |
                                         v
                                  mb-core Path2
                                         |
                    consumer-owned translation/scaling/fill
                                         |
                                         v
                                     mb-canvas
```

Public dependency direction remains acyclic:

```text
mb-font ──> mb-core <── mb-canvas
```

There is no `mb-font -> mb-canvas`, `mb-font -> mb-image`, or
`mb-font -> mb-color` edge. No existing module source API needs modification.

### Component Responsibilities

| Component | Responsibility | Implementation |
|---|---|---|
| Public facade | Opaque `Font`, limits, IDs, metrics, outline and query methods | `font/api.mbt`, `font/limits.mbt` |
| Big-endian cursor | Checked scalar reads within one immutable subview | Private cursor over `ByteView`; all cursor advance uses `mb-core/checked` |
| SFNT directory | Validate TrueType signature and top-level table records | Sorted private `TableRecord[]`; checked `ByteView::subview` only |
| Table validators | Validate fixed headers and cross-table cardinalities | Eager parse of `head`, `maxp`, `hhea`; exact envelopes for `hmtx`, `loca`, `cmap`, `glyf`, optional `kern` |
| Character map | Deterministic Unicode-to-glyph lookup | Validate one selected Unicode format 12 or 4 index; binary search; range-check result against `numGlyphs` |
| Metrics | Font-wide and per-glyph horizontal metrics | `head`/`hhea`/`OS/2` facts plus `hmtx` direct lookup |
| Glyph decoder | Decode one checked glyph window | Simple flag/delta expansion or bounded composite resolution |
| Outline normalizer | Convert resolved contours to shared geometry | Implied on-curve midpoint handling, `MoveTo`/`LineTo`/`QuadTo`/`Close` |
| Kerning | Basic legacy pair adjustment | Validate horizontal version-0 format-0 pairs; binary search; zero if absent |
| Query scratch | Cycle detection, component work, temporary contours | Per-call bounded state; no hidden process-global or unbounded persistent cache |

## Recommended Project Structure

```text
modules/mb-font/
├── moon.mod.json                  # module tchivs/mb-font; only mb-core dependency
├── README.mbt.md                  # public four-target examples
├── CHANGELOG.md
└── font/                          # sole public package
    ├── moon.pkg                   # mb-core error/checked/budget/bytes/math imports
    ├── api.mbt                    # opaque public model and query methods
    ├── limits.mbt                 # FontLimits and validation options
    ├── errors.mbt                 # stable CoreError construction/context tokens
    ├── be_cursor.mbt              # private checked big-endian reader
    ├── sfnt.mbt                   # offset table, directory and table views
    ├── tables_core.mbt            # head/maxp/hhea/OS2 validation
    ├── metrics.mbt                # hmtx validation and lookup
    ├── cmap.mbt                   # formats 4 and 12
    ├── loca.mbt                   # eager validated glyph offsets
    ├── glyf_model.mbt             # private points, contours and transforms
    ├── glyf_simple.mbt            # simple glyph decode
    ├── glyf_composite.mbt         # recursive composite resolver
    ├── outline.mbt                # private model to Path2
    ├── kern.mbt                   # legacy format-0 pairs
    ├── font_test.mbt              # black-box public workflow
    ├── sfnt_wbtest.mbt
    ├── cmap_wbtest.mbt
    ├── metrics_wbtest.mbt
    ├── glyf_wbtest.mbt
    └── portable_qualification_wbtest.mbt

examples/font-portable/            # public parse/map/metrics/outline consumer
fixtures/font/                     # generated hostile cases + licensed real fonts
scripts/fixtures/                  # deterministic minimal-TTF generator
```

One package is intentional. MoonBit publishes packages within a module, so
splitting `sfnt`, `glyf`, or `cmap` into sibling packages would accidentally
make raw parser internals consumer-facing and enlarge the compatibility
surface. File-private types provide the required internal boundaries while the
package exposes one coherent API.

### New Versus Modified Components

| Action | Path | Change |
|---|---|---|
| New | `modules/mb-font/**` | Complete module and sole public package above |
| New | `examples/font-portable/**` | Public end-to-end consumer; imports `mb-font/font`, not private tables |
| New | `fixtures/font/**` | Generated structural cases and provenance-tracked real-font corpus |
| Modify | `moon.work` | Add `./modules/mb-font` and `./examples/font-portable` |
| Modify | `policy/foundation.json` | Add module, package inventory, four targets, and the sole edge `mb-font -> mb-core` |
| Modify | `scripts/quality/Assert-Policy.ps1` | Remove the current three-module hard-code and admit the new exact module/path set |
| Modify | `scripts/quality/Invoke-MoonQuality.ps1` | Add font README, independent build/test/doc/info, and four-target package qualification |
| Modify | `fixtures/manifest.json` | Add every font fixture with SHA-256, source, license and redistribution status |
| Modify | architecture/getting-started docs | Add the new module and outline-to-canvas example after the API is qualified |
| Unchanged | `modules/mb-core/**` | Existing checked ranges, budgets, retained views, mutation revisions, errors and `Path2` are sufficient |
| Unchanged | `modules/mb-canvas/**` | Existing `Path2` consumption is the integration seam; no font import is permitted |

## Public API Boundary

The first candidate surface should stay small and opaque:

```moonbit
Font::open(
  source : @bytes.ByteView,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]

Font::global_metrics() -> FontMetrics
Font::glyph_id(codepoint : UInt32) -> Result[GlyphId, @error.CoreError]
Font::glyph_metrics(id : GlyphId) -> Result[GlyphMetrics, @error.CoreError]
Font::glyph_outline(
  id : GlyphId,
  budget : @budget.Budget,
) -> Result[GlyphOutline, @error.CoreError]
Font::kerning(left : GlyphId, right : GlyphId) -> Result[Int, @error.CoreError]
GlyphOutline::path() -> @math.Path2
```

`GlyphId` should be a checked opaque wrapper, not a public integer alias.
`glyph_id` returns glyph zero for an unmapped valid Unicode scalar. Invalid
Unicode scalars are invalid input. Metrics remain integer font-design units;
the returned `Path2` uses the existing `Double` geometry seam. TrueType int16
coordinates and F2DOT14 component coefficients are exactly admitted before
conversion, and every transformed coordinate must be finite and within the
documented safe geometry ceiling.

Do not expose table offsets, raw table views, `loca`, contour flag arrays, or
mutable caches. Do not add file-path constructors: host/file loading remains a
consumer capability concern.

## Hostile-Input and Ownership Design

### Admission Before Decoding

`Font::open` must perform these gates in order:

1. Reject input above `FontLimits.max_input_bytes`.
2. Accept only standalone TrueType SFNT `0x00010000` for this milestone;
   reject TTC, WOFF/WOFF2, `OTTO`/CFF, variable and color-font routes.
3. Checked-compute `12 + numTables * 16`; enforce table-count and directory
   limits before allocating records.
4. Validate printable/sorted/unique tags, four-byte top-level alignment,
   checked `offset + length`, containment, and non-overlap.
5. Verify declared table checksums with the `head.checksumAdjustment` rule.
6. Require `head`, `maxp`, `hhea`, `hmtx`, `cmap`, `loca`, and `glyf`; validate
   supported versions and fixed fields.
7. Cross-check `head.indexToLocFormat`, `maxp.numGlyphs`,
   `hhea.numberOfHMetrics`, exact `hmtx` envelope, `numGlyphs + 1` `loca`
   entries, monotonic `loca`, and final offsets within `glyf`.
8. Select and fully validate the preferred Unicode cmap (format 12 first,
   otherwise format 4). Validate optional `kern` before publishing `Font`.
9. Preflight and atomically charge retained indexes before allocation. Publish
   no partially usable `Font`.

`maxp` values are claims from hostile input, not trusted allocation sizes.
They may provide an additional rejection check, but caller `FontLimits` and
`Budget` are the authority.

### Budget Seams

`FontLimits` supplies semantic ceilings that `mb-core::ResourceLimits` does not
name: tables, glyphs, cmap records/groups/segments, points, contours,
components, instruction bytes, composite depth, and output commands.
`Budget` supplies shared bytes, allocations, work, and balanced depth.

- Directory/table validation charges work proportional to records and bytes
  actually checksum-verified.
- `loca` and any cmap search index are admitted as one exact construction
  charge before allocation.
- Glyph extraction derives the worst admitted point/contour/command envelope
  before building result arrays.
- Each composite entry uses `budget.with_depth`; component count, accumulated
  points, contours, commands, and transform work are checked-additive.
- Instruction bytes are skipped, never executed, but length-checked and capped.
- Failure before admission leaves the caller budget unchanged; failure after a
  committed query charge returns no partial outline.

### Ownership and Caching

`Font` retains the source `ByteView`, its opening `mutation_revision`, and owned
validated indexes. Every public query compares the current source revision to
the admitted revision before reading. A changed backing returns a stable state
error; it is never silently revalidated. This directly uses the existing
`mb-core/bytes` ownership seam without copying the entire font.

Cache only structural facts whose complete memory cost is known at open:
directory records, core headers, validated `loca`, and cmap lookup metadata.
Do not add an implicit persistent glyph-outline cache in v0.32. Hidden caching
makes budget success depend on query order and can retain unbounded geometry.
Composite extraction may use a bounded request-local memo and active glyph-ID
stack; both die with the call. A future caller-owned `OutlineCache` can be an
additive API with explicit byte/entry limits.

## Glyph Decode Data Flow

### Simple Glyph

```text
checked loca window
  -> header and increasing endPtsOfContours
  -> checked point count
  -> skip bounded instructions
  -> expand repeated flags without exceeding point count
  -> decode checked signed x/y deltas
  -> split points by contour endpoints
  -> insert implied on-curve midpoints
  -> emit closed quadratic Path2 contours
```

Zero-length `loca` windows and zero-contour glyphs produce an empty outline,
not an error. Flag repeats, coordinate streams, or contour endpoints that do
not consume exactly their declared window are malformed.

### Composite Glyph

```text
checked composite window
  -> active glyph-ID stack / cycle check
  -> bounded component loop
  -> child glyph checked loca window
  -> recursively decode private points/contours
  -> apply F2DOT14 transform
  -> apply XY offset or parent/child point attachment
  -> checked-append transformed contours
  -> after final component, skip bounded instructions
  -> normalize once to Path2
```

The first component must use XY arguments as required by the specification.
Support point-number attachment for later components; a Path2-only internal
model cannot implement it correctly. Reject contradictory scaled/unscaled
offset flags. If neither flag is set, use the OpenType-recommended unscaled
offset behavior deterministically. Detect direct and indirect cycles even when
the declared `maxComponentDepth` is false.

## Suggested Build Order

1. **Module and public contract skeleton** — manifest, one package, limits,
   opaque IDs/types, workspace/policy integration.
2. **Bounded binary substrate** — big-endian cursor, stable font error tokens,
   table-window invariant tests.
3. **SFNT structural gate** — directory/ranges/alignment/overlap/checksums and
   required-table discovery. No table decoder before this passes.
4. **Core table graph** — `head`, `maxp`, `hhea`, exact `hmtx`, `loca`, and
   cross-table validation.
5. **Cmap and metrics** — formats 12/4, glyph-zero behavior, font/per-glyph
   metrics, then optional `kern` format 0.
6. **Simple glyf outlines** — packed flags/deltas, contours, implied points,
   `Path2`.
7. **Composite glyf outlines** — recursion/cycles, transforms, point
   attachment, request-local memoization.
8. **Public workflow and ownership hardening** — mutation revision, atomic
   budgets, stable diagnostics, documentation example.
9. **Four-target qualification** — hostile corpus, licensed real fonts,
   benchmark baselines, independent consumer.

This ordering prevents later phases from inventing their own offset checks and
keeps hostile-input design ahead of decoding.

## Test Architecture

| Layer | Test type | Required evidence |
|---|---|---|
| Cursor/SFNT | White-box generated byte fixtures | Every truncation point; overflowed directory math; duplicate/unsorted tags; misalignment; overlap; out-of-file ranges; checksum mismatch |
| Cross-table graph | White-box | `numGlyphs`, `numberOfHMetrics`, `loca` format/length/order/final bound, required and unsupported tables |
| Cmap | White-box + black-box | Format 4 delta/range-offset cases, format 12 groups and supplementary scalars, unsorted/overlapping groups, glyph-ID overflow, notdef |
| Metrics/kern | White-box + black-box | Repeated final advance, signed bearings, absent pairs, sorted pair search, malformed subtable envelopes |
| Simple glyf | White-box | Empty glyphs; first/last off-curve cases; implied midpoints; repeated flags; positive/negative deltas; exact contour closure; point/command limits |
| Composite glyf | White-box | XY and point attachment, scale/x-y/2x2 transforms, repeated children, conflicting flags, cycles, excessive depth/components/points |
| Ownership/budget | Black-box | Source mutation after open; one-less/exact limits; no partial `Font` or outline; deterministic error category/code/context |
| Interoperability | Black-box fixture corpus | Licensed Latin and supplementary-plane fonts with known cmap, metrics, simple/composite outlines and kern pairs |
| Portability | Isolated target runs | Same public facts, canonical path-command digest, errors, and test count on `js`, `wasm`, `wasm-gc`, and `native` |

Generate tiny structural fonts independently in `scripts/fixtures`; never derive
expected data by invoking production parser code. External tools such as
fontTools or FreeType may cross-check fixture facts during corpus preparation,
but are development oracles only and never runtime dependencies or the sole
acceptance oracle. Record every redistributed font in `fixtures/manifest.json`.

## Anti-Patterns

### Decode Before Global Validation

**Wrong:** seek to a requested table or glyph as soon as its directory record is
read.  
**Consequence:** duplicate tables, overlapping ranges, broken cross-table
cardinalities, and allocation bombs reach decoders.  
**Instead:** publish one validated `Font` index, and give decoders only checked
subviews.

### Directly Build Path2 During Composite Recursion

**Wrong:** discard original point numbering as each child becomes path commands.  
**Consequence:** later point-to-point component attachment cannot be resolved
correctly.  
**Instead:** retain private numbered points/contours through composition and
lower once.

### Hidden Global or Unbounded Outline Cache

**Wrong:** memoize every requested glyph inside `Font`.  
**Consequence:** memory grows with access history and budget behavior becomes
query-order dependent.  
**Instead:** cache only bounded structural indexes and use request-local
composite memoization.

### Add a Font-to-Canvas Dependency

**Wrong:** expose `CanvasPath`, drawing lists, pixels, or rasterization from the
font module.  
**Consequence:** reverses the RFC boundary and bloats inspection/text tooling.  
**Instead:** return `mb-core/math::Path2`; the consumer decides whether and how
to rasterize it.

## Sources

- [OpenType 1.9.1 font-file organization and checksums](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — official format structure (MEDIUM via verified websearch)
- [OpenType cmap table](https://learn.microsoft.com/en-us/typography/opentype/spec/cmap) — formats 4 and 12 (MEDIUM)
- [OpenType glyf table](https://learn.microsoft.com/en-us/typography/opentype/spec/glyf) — simple and composite outlines (MEDIUM)
- [OpenType head table](https://learn.microsoft.com/en-us/typography/opentype/spec/head), [maxp table](https://learn.microsoft.com/en-us/typography/opentype/spec/maxp), and [loca table](https://learn.microsoft.com/en-us/typography/opentype/spec/loca) — cross-table bounds (MEDIUM)
- [OpenType hhea table](https://learn.microsoft.com/en-us/typography/opentype/spec/hhea) and [hmtx table](https://learn.microsoft.com/en-us/typography/opentype/spec/hmtx) — metric cardinalities and lookup (MEDIUM)
- [OpenType kern table](https://learn.microsoft.com/en-us/typography/opentype/spec/kern) — legacy format 0 (MEDIUM)
- Repository evidence: `docs/rfcs/0004-mb-font.md`,
  `modules/mb-core/{checked,budget,bytes,io,math}`,
  `modules/mb-canvas/canvas/path_builder.mbt`, `moon.work`,
  `policy/foundation.json`, and `scripts/quality/*.ps1` (HIGH, direct source)

---
*Architecture research for: MoonBit Native Foundation v0.32 TrueType Font Foundation*
*Researched: 2026-07-26*
