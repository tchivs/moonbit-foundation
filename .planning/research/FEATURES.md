# Feature Landscape

**Domain:** Bounded, deterministic, single-font horizontal OpenType text shaping over the existing opaque `tchivs/mb-font/font::Font`
**Milestone:** v0.35 Text Shaping Foundation
**Researched:** 2026-07-30
**Overall confidence:** MEDIUM

Normative OpenType and Unicode claims are cross-checked against the current
OpenType 1.9.1 specification and Unicode 17.0.0 primary sources. The GSD
confidence seam classifies the verified web-research route as MEDIUM. Existing
MNF APIs, RFC boundaries, and shipped qualification patterns are HIGH-confidence
local evidence.

## Executive Position

v0.35 should create the smallest honest **string-to-positioned-glyph-run**
vertical slice. A caller supplies:

- one already-admitted opaque `Font`;
- an ordered array of valid Unicode scalar values;
- an explicit OpenType script tag and language-system choice;
- one explicit uniform horizontal direction;
- explicit feature choices and shaping/resource limits; and
- one authoritative `Budget`.

The operation returns one immutable run in draw/pen order. Each glyph record
contains an opaque glyph identity, a stable source cluster, a horizontal
advance, and x/y placement offsets in font design units. No GUI, locale,
filesystem, font discovery, fallback, Unicode normalization, paragraph bidi,
or line-layout state participates.

```text
caller scalars + script/language + direction + feature policy
                              │
                              ▼
                  cmap through opaque Font
                              │
                              ▼
              bounded GSUB profile in lookup order
                 ├── type 1: single substitution
                 └── type 4: ligature substitution
                              │
                              ▼
                  base advances from hmtx
                              │
                              ▼
             bounded pair-positioning policy
                 ├── GPOS type 2 PairPos
                 └── legacy kern fallback
                              │
                              ▼
       [glyph, source cluster, advance, x/y offset] × N
```

“Complete but small” means that every behavior inside this profile is explicit,
bounded, mutation-safe, deterministic, and independently qualified. It does
**not** mean a partial full-script engine. OpenType itself states that fonts
contain glyph-specific lookup data while script-specific preprocessing,
reordering, and ordered shaping stages belong to the text-processing
application. The common lookup model alone is insufficient for correct Arabic,
Indic, Khmer, cursive, or mark-heavy shaping. v0.35 must say so in public
documentation and capability outcomes.

The public user-facing operation belongs in `tchivs/mb-text`; raw OpenType
tables, offsets, records, and mutable font storage must remain behind
`tchivs/mb-font`. If `mb-text` needs new font support, `mb-font` should expose an
opaque, typed, format-neutral layout capability rather than a public raw-table
reader. The allowed dependency remains:

```text
tchivs/mb-text -> tchivs/mb-font
tchivs/mb-text -> tchivs/mb-core
```

## Product Boundary

### Input contract

| Input | v0.35 contract | Observable rejection |
|---|---|---|
| Font | Exactly one admitted `Font`, backed by static `glyf` or CFF1 | Foreign/invalid font state is a structured `InvalidInput` or `State` outcome |
| Text | Ordered `Array[Int]` of Unicode scalar values | Negative values, surrogates, and values above `0x10FFFF` fail before shaping |
| Script | Explicit four-byte OpenType script tag | Malformed tags fail as input; missing/unusable script selection follows one documented fallback or capability rule |
| Language | Explicit four-byte LangSys tag or explicit default-language selection | No ambient locale and no language auto-detection |
| Direction | Explicit `LeftToRight` or `RightToLeft`, horizontal only | No auto direction, paragraph level, vertical direction, or mixed-direction input |
| Features | Closed deterministic policy including required/default and caller toggles | Invalid/duplicate tags or selected unsupported lookups fail explicitly |
| Limits | Semantic ceilings for input, retained layout facts, lookups, matches, output, and work | Exact-fit succeeds; one-short fails with named `Resource` context |
| Budget | Fresh authoritative caller budget, including ancestor semantics already used by MNF | No hidden global budget and no partial committed charge on failure |

Unicode 17.0.0 defines a scalar as any Unicode code point except high- and
low-surrogate code points. Normalization is a distinct Unicode algorithm, and
paragraph direction resolution/reordering is a distinct UAX #9 algorithm.
Therefore accepting scalar values is not evidence that v0.35 normalized or
resolved bidi text.

### Output contract

Each successful run should expose only format-neutral facts:

| Fact | Exact meaning |
|---|---|
| `glyph` | Opaque `GlyphId` belonging to the supplied `Font` |
| `cluster` | Zero-based index of the earliest source scalar represented by this output glyph |
| `advance` | Final checked horizontal advance in font design units after positioning |
| `x_offset` | Final checked horizontal placement adjustment in font design units |
| `y_offset` | Final checked vertical placement adjustment for the horizontal run |
| `direction` | The explicit run direction retained on the run, not inferred from glyph order |
| `total_advance` | Checked sum of output advances, derivable but useful as a frozen run invariant |

The array is returned in pen/draw order: logical start to end for LTR, logical
end to start for RTL. Cluster values always refer to original input scalar
indices, so RTL output may have descending cluster values. A one-to-one mapping
or single substitution retains the source cluster. A ligature receives the
minimum source scalar index of all consumed components. Positioning never
changes clusters.

This cluster rule is deliberately smaller than grapheme-cluster or cursor-stop
semantics. It preserves source provenance for the supported lookup types
without claiming UAX #29 segmentation, normalization-aware equivalence, or
editing behavior.

## Table Stakes

Missing any item below makes the slice incomplete or makes its claims
misleading.

| Feature | Why expected | Complexity | Acceptance boundary |
|---|---|---:|---|
| Independently publishable `mb-text` shaping package | RFC 0005 assigns string-to-positioned-glyph mapping to `mb-text`, not `mb-font` | Medium | Four-target package; direct dependencies only on `mb-core` and `mb-font`; no `mb-canvas`, ICU, HarfBuzz, or host API |
| Explicit uniform-run options | Determinism cannot depend on locale, inferred direction, or host font policy | Medium | Same font/scalars/options/limits produce the same run; options fully round-trip in tests and diagnostics |
| Valid-scalar admission | Existing `Font::glyph_for_scalar` already rejects non-scalars one at a time | Low | Preflight the whole scalar array; empty succeeds; any invalid scalar publishes no run and performs no partial caller charge |
| Initial cmap mapping | Every scalar needs one default glyph before GSUB | Low | Preserve glyph zero for valid unmapped scalars; preserve one source cluster per input scalar; never treat missing glyph as malformed font data |
| Stable positioned-run model | Downstream SVG/PDF/canvas/measurement consumers need IDs and positions without parsing layout tables | Medium | Opaque glyphs plus cluster/advance/x/y offsets and total advance; no raw tags, offsets, lookups, or source views leak through glyph records |
| Script and LangSys selection | GSUB/GPOS are organized by ScriptList, LangSys, FeatureList, and LookupList | High | Exact requested script/lang selection, documented default LangSys and `DFLT` behavior, sorted-record/range validation, no ambient language fallback |
| Required-feature semantics | LangSys may name one `requiredFeatureIndex`; applications may also treat registered behavior as required | High | Required LangSys feature is not silently disabled; invalid indices fail; selected supported lookups apply in canonical LookupList order |
| Explicit feature policy | `liga` and `kern` are normally user-controllable while `rlig` represents required ligatures | Medium | `rlig`/required feature policy is documented; `liga` and `kern` default values are explicit and toggleable; duplicate/conflicting caller entries reject deterministically |
| LookupList-order execution | OpenType requires assembled lookups to execute in LookupList order; earlier substitutions can feed later ones | High | Caller feature-list order cannot change output; duplicate lookup references execute according to one frozen de-duplication rule; exact cross-feature order is tested |
| GSUB type 1, formats 1 and 2 | Single substitution is the minimal data-driven one-to-one operation | Medium | Delta arithmetic is modulo 65536 as specified; explicit substitute arrays align exactly with Coverage; every resulting GID is in range |
| GSUB type 4, format 1 | `liga` and `rlig` map glyph sequences to one glyph | High | Match in writing/logical direction; honor LigatureSet preference order; longer preferred prefixes are tested; consume exactly the participating glyphs |
| Deterministic ligature cluster merge | A many-to-one substitution must preserve input provenance | Medium | Output cluster is the minimum source scalar index; all unconsumed clusters remain unchanged; LTR and RTL fixtures freeze exact results |
| Base horizontal metrics | A shaped glyph needs an advance even without positioning tables | Medium | Query `Font::horizontal_metrics` only after final substitution; use `hmtx` advance as the base; any substituted out-of-range/foreign GID fails |
| GPOS type 2 PairPos format 1 | Explicit pairs are the basic modern kerning representation | High | Support checked design-unit `xPlacement`, `yPlacement`, and `xAdvance` for both glyphs; apply in writing direction; accumulate adjustments in lookup order |
| GPOS type 2 PairPos format 2 | Class pairs are common and omitting them makes ordinary kerning support misleading | High | Validate Coverage/ClassDef/class counts and exact matrix extent; class 0 is handled; output equals an independent oracle for licensed fonts |
| Static ValueRecord subset | The run model has advances and offsets, not device-scale or variation state | High | Admit only static design-unit fields needed for x/y placement and horizontal advance; reject `yAdvance`, Device tables, VariationIndex, and reserved bits as unsupported capability |
| Modern-versus-legacy kerning policy | Applying GPOS and legacy `kern` together can double-adjust a pair | Medium | When an applicable supported GPOS `kern` feature is selected, it is authoritative for the run; otherwise use existing `Font::kerning` as fallback; never combine both implicitly |
| Legacy `kern` compatibility | Existing `Font` already exposes a qualified version-0 horizontal format-0 pair query | Low | Preserve absence/miss as zero and exact current error distinctions; toggling `kern` off disables both modern and legacy routes |
| Explicit unsupported-lookup behavior | A font can reference contextual, attachment, extension, or filtered lookups from a selected feature | High | Never silently skip a selected unsupported lookup and still claim correct shaping; return `CapabilityUnavailable` with the table/lookup profile context |
| Bounded layout-table admission | Script/feature/lookup counts and nested offsets are attacker-controlled | High | Separate nonzero ceilings for tables, scripts, languages, features, lookups, subtables, coverage/ranges, classes, pairs, ligature sets/components, retained bytes, and parser work |
| Bounded shaping execution | Small lookup data can cause repeated scans or output/work growth | High | Nonzero limits for input scalars, initial/final glyphs, feature selections, lookup applications, match probes, and total work; no hidden quadratic scan without a declared charge |
| One transactional publication | MNF public operations do not expose partial results or partial authoritative charges | High | Build glyphs/clusters/positions privately; recheck source revision; preflight caller and ancestor dimensions; publish one run and commit exactly once |
| Mutation guards and precedence | `Font` retains caller-owned bytes and current queries are revision-guarded | High | Check before layout reads, during attacker-controlled stages at frozen points, and immediately before publication; mutation after open permanently invalidates shaping even if bytes are restored |
| Structured failures | Consumers must distinguish bad input, bad font data, unsupported capability, resource exhaustion, and source drift | Medium | Preserve MNF’s five categories with stable operation/context/requested/limit facts and a canonical precedence matrix |
| `glyf`/CFF1 format neutrality | Shaping depends on cmap/metrics/layout, not outline encoding | Medium | The same generated layout program over equivalent `glyf` and CFF1 faces produces the same shaped run; no outline call is required |
| Generated and licensed interoperability | Micro-font-only success is not useful ecosystem evidence | High | Generated exact fixtures plus existing licensed DejaVu Sans `glyf` and Source Sans CFF1 specimens; exact scalar/options/output facts; provenance and license manifests |
| Independent semantic oracle | Lookup-order or cluster bugs can self-confirm if expected output comes from MNF | High | Hand-derived generated facts plus a pinned independent host-only shaping oracle for licensed cases; runtime/package remains pure MoonBit |
| Four-target equality | Portability is a core product claim | High | Complete package tests and a closed ordered semantic record on `js`, `wasm`, `wasm-gc`, and `native`; only target/runner identity may differ |
| Frozen v0.34 compatibility | Layout work must not regress admission, mapping, metrics, kerning, outlines, or collection opening | High | Existing 1,287-test four-target workspace baseline and FontQualification remain green; public `mb-font` interface/dependency drift is intentional and reviewed |

### What “supported lookup” means

For v0.35, a lookup is supported only when its complete selected execution path
stays inside:

- GSUB type 1 single substitution, formats 1 and 2;
- GSUB type 4 ligature substitution, format 1;
- GPOS type 2 pair adjustment, formats 1 and 2;
- Coverage/ClassDef formats required by those operations;
- zero or an explicitly enumerated safe LookupFlag profile; and
- static design-unit ValueRecords without device or variation references.

An extension lookup wrapper may be admitted only when planning proves that it
is a bounded indirection to one of those exact inner types and licensed
qualification requires it. Supporting such a wrapper does not widen the
semantic profile. Otherwise extension lookups remain a named capability
deferral.

## User Stories and Observable Acceptance

### US-1 — Shape an ordinary Latin run

> As a MoonBit library author, I can shape normalized scalar input such as
> `office` with explicit `latn`, default language, LTR, standard ligatures on,
> and kerning on, then receive deterministic glyphs, clusters, advances, and
> offsets.

Observable acceptance:

1. The initial glyph count equals scalar count.
2. A supported `ffi` or `fi` ligature reduces glyph count according to the
   font’s preferred LigatureSet order.
3. The ligature cluster equals the first consumed scalar index.
4. Final advances come from the substituted GIDs plus selected positioning.
5. Disabling `liga` preserves separate glyphs without disabling required
   features or `kern`.
6. Repeated calls produce field-for-field equal runs and equal budget facts.

### US-2 — Select script and language without ambient locale

> As a library author, I can choose a script and language system explicitly so
> the font’s corresponding required/optional feature tables are selected.

Observable acceptance:

1. Exact LangSys selection can produce a different supported single
   substitution from DefaultLangSys in a generated font.
2. No process locale, environment variable, OS language, or Unicode script
   detector changes the result.
3. Missing requested language follows the documented rule (recommended:
   explicit default fallback only when the caller selected “default”; an
   explicit missing non-default tag returns capability).
4. Malformed/duplicate ScriptList and LangSys records fail as font data, not as
   neutral “feature absent.”

### US-3 — Shape a caller-segmented RTL run

> As a library author that already performed bidi segmentation, I can provide
> one uniform RTL scalar run and receive deterministic RTL pen-order glyphs
> while retaining original source clusters.

Observable acceptance:

1. No bidi paragraph analysis, mirroring, embedding, isolate, or mixed-run
   reordering occurs.
2. Lookup matching uses logical writing order as required by OpenType.
3. Output is in RTL draw/pen order and clusters refer to original input scalar
   positions.
4. Artificial generated RTL single/ligature/pair cases pass; documentation
   does not claim correct Arabic/Syriac/Indic shaping.

### US-4 — Use modern pair positioning or legacy fallback

> As a library author, I receive one deterministic pair adjustment whether the
> font uses supported GPOS `kern` data or only the already-supported legacy
> `kern` table.

Observable acceptance:

1. GPOS PairPos formats 1 and 2 produce exact advances and x/y offsets.
2. Multiple selected GPOS lookups accumulate in LookupList order.
3. Legacy `Font::kerning` is used only when no applicable supported GPOS
   `kern` route is authoritative.
4. A pair miss is zero; malformed recognized GPOS data and unsupported selected
   GPOS data never degrade silently to legacy zero/fallback.
5. `kern=false` disables both routes.

### US-5 — Bound hostile text and layout data atomically

> As a service or document-tool author, I can process untrusted text and fonts
> with exact limits and budget authority without partial runs or target-specific
> exhaustion.

Observable acceptance:

1. Empty, exact-limit, and one-over/one-short cases exist for every count,
   retained-byte, allocation, and work dimension.
2. Deep offset chains, huge counts, overlapping/truncated tables, unsorted
   records, invalid coverage/class values, excessive ligature components, and
   repeated lookup scans return exact structured outcomes.
3. Caller and ancestor budgets remain unchanged on every failed transaction.
4. Source mutation wins at the documented revision checkpoints, publishes no
   run, and does not leak retained intermediate glyph arrays.
5. One successful operation publishes and commits once.

### US-6 — Reproduce trustworthy four-target evidence

> As a maintainer, I can regenerate generated/licensed oracle facts and compare
> the same shaping record on all four production targets.

Observable acceptance:

1. Generated `glyf` and CFF1 fixtures have equivalent cmap, metrics, and layout
   programs and hand-derived expected runs.
2. Existing licensed DejaVu Sans 2.37 and Source Sans 3.052R specimens exercise
   at least one supported single/ligature/pair route each, or intake fails
   closed and replaces the candidate without weakening the matrix.
3. A pinned external shaper may be used only to generate/check independent
   oracle facts; it is absent from production dependencies, package imports,
   and runtime capability.
4. Hostile rows are canonical data consumed unchanged by tests and evidence.
5. Four target records have identical semantic hashes after normalizing only
   declared runner identity.

## Differentiators

These features do not widen the OpenType subset. They make the small subset
safer and more reusable than a thin shaping wrapper.

| Differentiator | Value proposition | Complexity | Boundary |
|---|---|---:|---|
| Format-neutral run over opaque `Font` | Downstream PDF/SVG/canvas/CLI code does not branch on `glyf` versus CFF1 | Medium | No outline-format facts or raw layout records escape |
| Caller-authorized shaping transaction | Untrusted documents and agent workflows get exact resource authority | High | Semantic limits and authoritative budget remain distinct; parent/child dimensions are proven |
| Source-index clusters independent of glyph order | Consumers can correlate output with original input even in RTL and ligatures | Medium | Cluster is scalar provenance only, not grapheme/cursor semantics |
| Fail-closed capability honesty | Unsupported complex layout cannot masquerade as “successful shaping” | Medium | Selected unsupported lookup/flag/value profile is an explicit capability outcome |
| Modern/legacy kerning without double application | Existing fonts remain compatible while modern GPOS gets correct authority | Medium | One documented selection rule; never add both routes accidentally |
| Cross-outline equivalence fixtures | Proves the text layer is genuinely format-neutral | Medium | Equivalent generated `glyf`/CFF1 inputs must produce identical runs |
| Independent licensed oracle evidence | Detects self-oracle bugs in lookup order, pair accumulation, and direction | High | External tooling is qualification-only, exact-versioned, provenance-bound |
| Four-target semantic carrier | Makes portability auditable rather than anecdotal | High | Closed ordered schema, exact source identities, equal normalized semantic hash |
| Observation-only native baseline | Enables future optimization without marketing claims or target divergence | Medium | Correctness remains four-target; timings are native-only and threshold-free |

## Anti-Features and Explicit Deferrals

These are binding exclusions. A valid implementation must not silently absorb
one in order to pass a convenient font or test.

| Anti-feature / deferral | Why avoid in v0.35 | What to do instead |
|---|---|---|
| Full Arabic or Syriac shaping | Correct joining needs script-specific analysis, contextual forms, cursive attachment, marks, and ordered stages; `rlig` alone is not sufficient | Return capability for selected unsupported paths; plan a dedicated complex-script milestone |
| Indic, Khmer, Tibetan, or complex reordering | Correct output depends on script-specific syllable analysis, reordering, contextual/chained substitutions, marks, and feature stages | Document unsupported scripts/profiles and defer as a separate vertical slice |
| Contextual/chained GSUB or GPOS (types 5/6/8, 7/8) | Large nested-matching and lookup-recursion surface; enabling one type does not create a complete complex-script engine | Support only type 1/type 4 GSUB and type 2 GPOS; reject selected unsupported types |
| Mark/cursive attachment | Requires GDEF glyph classes, anchors, attachment chains, mark filtering sets, and script policy | Preserve x/y offsets in the run model so future phases can add it without changing glyph records |
| Unicode normalization | NFC/NFD/NFKC/NFKD are separate normative transforms and change scalar/cluster provenance | Require caller-provided normalization policy/input; shape exact supplied scalars |
| Paragraph bidi and auto direction | UAX #9 resolves mixed text, embeddings, isolates, weak/neutral types, mirroring, and visual order | Require caller-segmented uniform direction; retain explicit direction on the run |
| Script/language auto-detection | Adds Unicode Script/Script_Extensions policy and ambiguity | Require explicit OpenType script and language-system choice |
| Grapheme segmentation and cursor stops | Source clusters are not automatically extended grapheme clusters | Expose scalar-index provenance only; later consume existing `mb-core/unicode` UAX #29 contracts |
| Line breaking, wrapping, justification, alignment | These are paragraph layout, not shaping | Return one unbroken positioned run and its total advance |
| Rich-text spans and embedded objects | Introduces segmentation, attribute inheritance, run merging, and document policy | Call the shaping API once per caller-defined homogeneous run |
| Font fallback, discovery, matching, or registry | Introduces multi-font ownership and host state | Require one admitted font; unmapped scalars remain glyph zero |
| Multi-font run merging | Changes glyph identity ownership and cluster/metric semantics | Defer until font-selection/fallback architecture exists |
| Vertical layout and vertical metrics | Requires `vhea`/`vmtx`, vertical features, rotations, and different kerning policy | Support horizontal `LeftToRight`/`RightToLeft` only |
| Rasterization, hinting, color, or bitmap glyphs | Text shaping produces references and positions, not pixels or device-adjusted outlines | Consumers compose `mb-text` run + `mb-font` outline + `mb-canvas` |
| Variable-font instantiation or variation positioning | Requires axis coordinates, FeatureVariations, VariationIndex, and variable outlines/metrics | Reject variation/device records in v0.35; plan a variable-font milestone |
| WOFF/WOFF2 | Compression/container admission is independent of shaping | Continue accepting already-admitted static SFNT `Font` values |
| AAT/Graphite shaping | Different layout engines and table models | OpenType-only profile for this milestone |
| Font authoring, subsetting, serialization | Requires mutable table rebuilding and checksum/offset ownership | Keep all layout support read-only |
| HarfBuzz/ICU/FFI in production | Breaks pure-MoonBit four-target portability and makes foreign ownership the runtime product | Use pure MoonBit; a pinned host tool is permitted only as independent qualification oracle |
| Ambient I/O or GUI state | Breaks automation and reproducibility | Accept caller-owned values and explicit options only |
| “Best effort” skip of unsupported selected data | Produces plausible but typographically false output | Return a named capability result and publish nothing |

## Feature Interactions

### Feature selection and ordering

1. Select the exact GSUB/GPOS Script table.
2. Select the exact LangSys or explicit default LangSys.
3. Include the LangSys required feature when present.
4. Apply the milestone’s explicit policy for registered `rlig`, `liga`, and
   `kern`.
5. Include explicitly enabled additional features only if their entire selected
   path uses supported lookup types.
6. Assemble references and apply lookups in LookupList order, not caller option
   order or FeatureList alphabetical order.

The OpenType common-format specification allows feature indices in a LangSys to
appear in arbitrary order, while lookup sequencing is controlled by LookupList
order. This ordering must be frozen in both generated overlap cases and licensed
oracle cases.

### Ligatures and clusters

```text
input scalar indices:  0   1   2   3   4   5
input glyphs:          o   f   f   i   c   e
                                   │
                                   └── supported "ffi" ligature

output glyphs:         o  ffi  c   e
output clusters:       0   1   4   5
```

Ligature preference comes from the font’s LigatureSet order; a longer sequence
that shares a prefix is normally stored before a shorter one. Cluster merge is
an MNF public contract: minimum consumed scalar index. The two rules must be
tested independently.

### Direction

- Input scalars remain in logical order.
- GSUB ligature components and GPOS pairs are matched in writing direction as
  defined by OpenType.
- Output records are presented in run pen/draw order.
- Direction does not trigger Unicode bidi, mirroring, normalization, digit
  shaping, joining analysis, or script reordering.
- Feature stages not represented by the selected supported lookups do not
  materialize implicitly.

### GPOS and legacy `kern`

Recommended authority:

```text
kern disabled
  └── no GPOS kern, no legacy kern

kern enabled + applicable supported GPOS kern path
  └── GPOS PairPos only

kern enabled + no applicable GPOS kern path
  └── existing Font::kerning fallback

kern enabled + selected malformed/unsupported GPOS kern path
  └── structured Data/Capability failure; no legacy fallback
```

This prevents a malformed modern table from being hidden and prevents
double-kerning.

### Mutation, errors, and resources

The exact precedence must be frozen during planning, but the user-observable
classes should remain:

1. `InvalidInput`: bad scalar, malformed tag/options, foreign glyph/font
   relationship.
2. `Data`: malformed recognized GSUB/GPOS structure, invalid ranges, invalid
   GIDs/classes/counts, arithmetic overflow.
3. `Capability`: valid selected profile outside the v0.35 lookup/direction/value
   subset.
4. `Resource`: semantic limit, work limit, retained-byte/allocation limit, or
   authoritative budget exhaustion.
5. `State`: retained source revision drift before publication.

Hostile tests must cover collisions between these classes, including mutation
before parsing, mutation after private glyph substitution, one-short caller
budget, one-short ancestor budget, malformed data beyond a capability marker,
and final mutation after an otherwise successful private result.

## Feature Dependencies

```text
[existing opaque Font]
   ├── cmap / GlyphId
   ├── hmtx metrics
   ├── legacy kern
   └── retained ByteView revision
              │
              ▼
[opaque bounded layout capability]
   ├── ScriptList + LangSys selection
   ├── FeatureList + LookupList
   ├── Coverage + ClassDef
   ├── GSUB type 1 / type 4
   └── GPOS type 2
              │
              ▼
[mb-text shaping transaction]
   ├── scalar validation + initial clusters
   ├── cmap mapping
   ├── substitutions in lookup order
   ├── final hmtx advances
   ├── GPOS or legacy kern policy
   ├── direction-to-pen-order
   └── final revision + budget commit
              │
              ▼
[immutable positioned glyph run]

[normalization] ──caller prerequisite, not a shaping dependency
[bidi paragraph analysis] ──caller prerequisite, not a shaping dependency
[font fallback] ──selection layer, not a shaping dependency
[line layout] ──consumer of shaped runs
[outline/raster] ──consumer of glyph IDs and positions
```

### Dependency notes

- Script/LangSys selection precedes feature selection.
- Feature selection precedes lookup assembly.
- GSUB precedes final metric queries because substitution changes GIDs.
- Positioning follows substitution and base metrics.
- Direction affects lookup traversal/output order but does not authorize bidi.
- Layout parsing and shaping share one source revision; no stale retained plan
  may outlive a mutated font.
- Licensed qualification follows the final public route; oracle-only parsing is
  never a substitute for public MoonBit execution.

## “Complete but Small” Definition

v0.35 is complete only when all of the following are true:

- [ ] A caller can shape one empty or non-empty scalar array with one static
      `glyf` or CFF1 `Font`, explicit script/language/direction/features,
      shaping limits, and a budget.
- [ ] The public result contains only opaque glyphs, source-scalar clusters,
      design-unit advances/offsets, direction, and checked total advance.
- [ ] Script, DefaultLangSys/exact LangSys, required feature, feature toggles,
      and LookupList order have executable observable cases.
- [ ] GSUB type 1 formats 1/2 and type 4 format 1 are fully parsed, bounded, and
      executed in logical writing order.
- [ ] GPOS type 2 formats 1/2 support the closed static horizontal ValueRecord
      subset and accumulate in LookupList order.
- [ ] GPOS `kern` versus legacy `Font::kerning` authority is unambiguous and
      cannot double-apply or silently hide malformed selected data.
- [ ] Invalid scalar/tag, malformed layout, unsupported capability, resource
      exhaustion, and source mutation remain distinct structured outcomes.
- [ ] Every failure publishes no run and commits no partial caller/ancestor
      transaction; success publishes/commits exactly once.
- [ ] Generated equivalent `glyf`/CFF1 fixtures, licensed `glyf`/CFF1 fixtures,
      hostile rows, independent oracle facts, and frozen v0.34 compatibility
      execute on all four targets.
- [ ] Public docs state that normalization, bidi, fallback, line layout,
      complex scripts, rasterization, variables, WOFF, and production FFI are
      absent.

v0.35 is **not** complete merely because `ffi` works in one generated Latin
font. It is also not incomplete because it rejects Arabic/Indic/mark/cursive
profiles: explicit capability rejection is correct behavior for the selected
milestone.

## MVP Recommendation

### Launch with v0.35

1. **Run model and transaction boundary**
   - New `mb-text` module, explicit input/options/limits, scalar clusters,
     positioned records, structured errors, budget/revision/atomicity.
2. **Bounded layout selection and GSUB**
   - Script/LangSys/feature/lookup selection; Coverage; single and ligature
     substitution; LTR/RTL run direction; cluster propagation.
3. **Metrics and pair positioning**
   - Final-GID hmtx advances; PairPos formats 1/2; static x/y placement and
     xAdvance; legacy `kern` fallback policy.
4. **Qualification and compatibility**
   - Generated + licensed `glyf`/CFF1, exact oracle, hostile matrix, API/deps,
     frozen v0.34 behavior, four equal targets, observation-only native timing.

### Defer after v0.35

- Extension wrappers unless a licensed in-profile fixture requires them.
- More data-driven single-substitution feature tags.
- Mark/cursive attachment and GDEF filtering.
- Contextual/chained lookups.
- Complex-script engines and script-specific stages.
- Normalization, bidi, line breaking, justification, fallback, and multi-font.
- Variables, device positioning, WOFF, color, rasterization, and authoring.

## Feature Prioritization

| Feature | User value | Cost | Priority |
|---|---:|---:|---|
| Explicit run/options/output model | High | Medium | P1 |
| Scalar validation, cmap, clusters | High | Medium | P1 |
| Script/LangSys/feature selection | High | High | P1 |
| LookupList-order engine | High | High | P1 |
| GSUB single formats 1/2 | High | Medium | P1 |
| GSUB ligature format 1 | High | High | P1 |
| Final metrics and total advance | High | Medium | P1 |
| GPOS PairPos format 1 | High | High | P1 |
| GPOS PairPos format 2 classes | High | High | P1 |
| Modern/legacy kern authority | High | Medium | P1 |
| Limits/budget/mutation/atomicity | High | High | P1 |
| Generated/licensed/four-target evidence | High | High | P1 |
| Extension wrappers to supported inner types | Medium | Medium | P2 unless fixture-blocking |
| Additional non-default simple features | Medium | Medium | P2 |
| Native observation-only benchmark | Medium | Medium | P2, after correctness |
| Contextual/mark/cursive/complex scripts | Future | Very high | Deferred |
| Bidi/normalization/line layout/fallback | Future | Very high | Deferred |
| Variables/WOFF/rasterization/FFI | Future | Very high | Deferred |

## Roadmap Implications

Recommended phase structure:

1. **Phase 108 — Shaping contract and bounded layout selection**
   - Establish `mb-text`, options/run/cluster/limit contracts, opaque font-layout
     seam, Script/LangSys/Feature/Lookup admission, error/resource precedence,
     and generated structural fixtures.
   - Exit with no public shaping result if source/transaction ownership is not
     yet proven.

2. **Phase 109 — Deterministic GSUB run shaping**
   - Initial cmap clusters, single/ligature execution, feature policy,
     lookup-order semantics, LTR/RTL pen order, cluster merge, final metrics.
   - Exit with complete substitution-only runs and explicit capability
     rejection for every deferred lookup.

3. **Phase 110 — Pair positioning and kerning integration**
   - PairPos formats 1/2, static ValueRecords, checked accumulation, modern
     GPOS-versus-legacy `kern` authority, atomic final publication.
   - Exit with exact advances/offsets and collision/one-short mutation/resource
     matrices.

4. **Phase 111 — Licensed interoperability and four-target qualification**
   - Equivalent generated `glyf`/CFF1, pinned licensed DejaVu/Source Sans (or
     fail-closed replacements), independent shaping oracle, canonical hostile
     corpus, compatibility locks, four equal records, observation-only native
     baseline.

**Ordering rationale:** layout selection determines which supported lookups
exist; GSUB changes glyph identity; final metrics and GPOS depend on substituted
glyphs; public transaction semantics must be closed before licensed/four-target
evidence can be authoritative.

**Research flags for planning:**

- Phase 108: exact opaque cross-module seam between `mb-font` binary ownership
  and `mb-text` string-level execution; Script/DFLT/LangSys fallback; duplicate
  records; lookup flags; cache lifetime versus source revision.
- Phase 109: RTL traversal/output order; repeated lookup references; subtable
  first-match rules; ligature cluster merge; extension wrapper decision.
- Phase 110: ValueRecord field subset and accumulation; PairPos class-0 bounds;
  GPOS presence-versus-applicability rule; final mutation/error precedence.
- Phase 111: verify exact licensed specimens actually exercise only the closed
  profile; pin independent oracle executable/adapters by hash; prohibit
  oracle-derived runtime payloads and production dependencies.

## Sources

### Official OpenType authorities

- [OpenType 1.9.1 — Layout common table formats](https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2) — ScriptList, LangSys, required feature, FeatureList, LookupList, lookup order, and the application-owned script-processing boundary. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — GSUB](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub) — single substitution formats 1/2, ligature substitution format 1, logical writing order, LigatureSet preference, and lookup sequencing. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — GPOS](https://learn.microsoft.com/en-us/typography/opentype/spec/gpos) — pair positioning formats 1/2, ValueRecords, writing-direction pairs, and accumulated positioning adjustments. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — registered feature `kern` and `liga`](https://learn.microsoft.com/en-us/typography/opentype/spec/features_ko) — horizontal kerning semantics and standard ligature policy. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — registered feature `rlig`](https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt) — required-ligature semantics and complex-script warning boundary. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — legacy `kern`](https://learn.microsoft.com/en-us/typography/opentype/spec/kern) — version-0 table, horizontal coverage, format-0 pair data, and the CFF/GPOS distinction. **Confidence: MEDIUM.**

### Official Unicode authorities

- [Unicode 17.0.0 Core Specification, Chapter 3](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) — Unicode scalar-value definition and encoding-form boundary. **Confidence: MEDIUM.**
- [Unicode Standard Annex #15 — Normalization Forms](https://www.unicode.org/reports/tr15/) — normalization is a separate normative transformation, not implicit scalar admission. **Confidence: MEDIUM.**
- [Unicode Standard Annex #9 — Bidirectional Algorithm](https://www.unicode.org/reports/tr9/) — paragraph direction resolution and bidi display ordering are separate from an explicit uniform shaping direction. **Confidence: MEDIUM.**

### Local project authorities

- `.planning/PROJECT.md` and `.planning/MILESTONE-CONTEXT.md` — binding v0.35 goal, selected vertical slice, exclusions, and optimal defaults. **Confidence: HIGH.**
- `docs/rfcs/0004-mb-font.md` — font binary/metrics/outline versus string-level shaping boundary. **Confidence: HIGH.**
- `docs/rfcs/0005-mb-text.md` — proposed `mb-text` module, dependency edges, positioned-glyph ownership, and pure-MoonBit portability. **Confidence: HIGH.**
- `modules/mb-font/README.mbt.md` and `modules/mb-font/font/*.mbt` — current opaque `Font`, cmap, metrics, legacy kerning, limits, budget, retained-source, and four-target contracts. **Confidence: HIGH.**
- `.planning/milestones/v0.34-*` and Phase 107 artifacts — generated/licensed/hostile/four-target/native-baseline evidence patterns and the shipped 1,287-test compatibility baseline. **Confidence: HIGH.**

---
*Feature research for: MoonBit Native Foundation v0.35 Text Shaping Foundation*
*Researched: 2026-07-30*
