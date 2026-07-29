# Architecture Patterns

**Project:** MoonBit Native Foundation v0.35 Text Shaping Foundation
**Domain:** Bounded deterministic single-font horizontal OpenType shaping
**Researched:** 2026-07-30
**Overall confidence:** MEDIUM

OpenType and Unicode behavior below is based on current primary specifications.
The research seam classifies verified Brave-routed web findings as MEDIUM.
Repository boundaries and shipped `mb-font` behavior are HIGH-confidence local
evidence.

## Executive Recommendation

Build `tchivs/mb-text` as the only user-facing shaping module, but keep all
font-binary ownership and GSUB/GPOS parsing inside the existing
`tchivs/mb-font/font` package. Connect them through one deliberately narrow
public-but-opaque integration seam:

```text
tchivs/mb-text/text
  ├── tchivs/mb-core/{budget,checked,error}
  └── tchivs/mb-font/font
```

There must be no reverse dependency from `mb-font` to `mb-text`, no dependency
from `mb-text` to canvas/SVG/PDF, and no raw OpenType record, offset, table view,
or caller-owned byte reference exposed across the seam.

The key architectural decision is to make the seam **transactional**, not a
public raw-table reader and not a separately charged layout-cache constructor.
`Font::with_layout_profile(...)` should:

1. guard the retained font revision;
2. preflight a conservative resource envelope;
3. build one immutable, bounded, request-specific `FontLayoutProfile`;
4. invoke an `mb-text` callback that privately builds the final run;
5. combine the font-layout charge and text-run charge;
6. guard the retained revision again;
7. charge the caller and every ancestor exactly once; and
8. publish the callback result only after that commit succeeds.

This preserves the shipped opaque `Font`, source-mutation, hierarchical-budget,
standalone/collection, `glyf`/CFF1, and atomic-publication contracts while
allowing `mb-text` to own feature policy, source clusters, direction, and the
public positioned-run model.

## Existing Architecture to Preserve

The live code already provides the correct lower-layer ownership:

| Existing seam | Current implementation | v0.35 consequence |
|---|---|---|
| Opaque admitted font | `Font` privately retains `ByteView`, opening revision, `DirectoryFacts`, `RequiredTableFacts`, limits, and an outline-source enum | Add layout support in the same `font` package so it can consume private directory/table facts without exposing them |
| Retained mutation identity | Every `Font` query compares `ByteView::mutation_revision()` with `opening_revision` before publication | A layout profile retains no independent revision number visible to callers; the transaction harness performs stage and final guards |
| Opaque glyph identity | `GlyphId` stores a private numeric value; every receiving `Font` revalidates it | Layout operations accept/return opaque `GlyphId`, never public raw GIDs as unvalidated integers |
| Canonical cmap | Admission retains exactly one private format-4/format-12 lookup; `glyph_for_scalar` publishes glyph zero for a valid miss | Initial shaping maps exact supplied scalars through this existing contract; no second cmap parser |
| Format-neutral metrics | `horizontal_metrics` dispatches privately between `glyf` and CFF1 while keeping `hmtx` authoritative | Base advances are queried only after substitution; shaping never branches on outline format |
| Legacy kerning | `Font::kerning` distinguishes malformed/unsupported state while returning zero for absence or pair miss | It is a fallback only when no applicable supported GPOS `kern` feature was selected |
| Standalone/collection unification | A selected face becomes the same opaque `Font`; its private directory retains root-relative table windows and the collection opening revision | Layout support reads `Font.directory`, so no collection-specific GSUB/GPOS engine is allowed |
| Hierarchical budget | `Budget::preflight` and `Budget::charge` check every ancestor; a complete `ResourceCharge` is committed atomically | Add checked charge composition, then perform one final charge for the complete shape operation |

The code knowledge graph was queried first as required, but its current index
contains planning sections rather than MoonBit functions. The source findings
above therefore come from the live files after the graph returned zero relevant
nodes.

## Recommended Architecture

```text
caller
  │
  │ Font + scalars + script + language + direction
  │ feature policy + ShapeLimits + Budget
  ▼
┌────────────────────── tchivs/mb-text/text ──────────────────────┐
│ validate typed options and scalar array                          │
│ create logical glyph seeds: (GlyphId, source scalar interval)    │
│ choose required/default feature policy                           │
│ call Font::with_layout_profile(...)                              │
│                                                                 │
│   profile.apply_gsub(logical seeds)                              │
│   profile.position(substituted seeds)                            │
│   convert source intervals to public minimum scalar clusters     │
│   reverse final record order only for RTL pen/draw order         │
│   build private ShapedRun + exact text ResourceCharge            │
└───────────────────────────┬───────────────────────────────────────┘
                            │ opaque typed operations
                            ▼
┌──────────────────── tchivs/mb-font/font ─────────────────────────┐
│ retained Font source + revision + directory + cmap/hmtx/kern     │
│ optional checked GSUB/GPOS table windows                         │
│ Script/LangSys/Feature/Lookup selection                          │
│ normalized Coverage/ClassDef/single/ligature/pair facts          │
│ lookup-order execution and first-matching-subtable semantics     │
│ exact font-layout charge + final source-revision authority       │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────── tchivs/mb-core ────────────────────────┐
│ checked integer/range arithmetic                                 │
│ CoreError categories and diagnostics                             │
│ ResourceCharge::checked_add + Budget preflight/one commit         │
└───────────────────────────────────────────────────────────────────┘
```

### Why the transaction closure is necessary

A separately public `Font::layout_profile(budget)` constructor would either:

- charge before the text run succeeds, violating whole-operation atomicity; or
- allocate/parse without any authoritative path to combine its exact charge
  with the later `mb-text` charge.

Similarly, letting `mb-text` call `budget.charge` twice would permit a partial
commit if the second charge failed and would contradict the milestone's
success-exactly-once rule.

Use a generic continuation shape similar to the already-shipped
`mb-core/budget::with_depth` pattern:

```moonbit
pub fn[T] Font::with_layout_profile(
  self : Font,
  selection : FontLayoutSelection,
  limits : FontLayoutLimits,
  budget : @budget.Budget,
  body : (FontLayoutProfile) ->
    Result[PreparedLayout[T], @error.CoreError],
) -> Result[T, @error.CoreError]
```

The last profile operation returns an opaque `FontLayoutOutcome` containing the
positioned font-side facts and its exact execution charge. After constructing
the private public-model value, the callback calls
`outcome.prepare(value, text_charge)` to produce `PreparedLayout[T]`. This binds
the value, the profile identity, the font execution charge, and the exact
text-side `ResourceCharge` without exposing charge fields. The harness combines
those with its retained-profile charge, performs the final revision check,
charges once, and only then returns `T`. Add one generic checked
`ResourceCharge::checked_add` operation in `mb-core`; do not expose mutable
budget windows or charge-field setters.

This is an integration API, but it remains safe for any caller because:

- the profile is opaque and contains no raw table access;
- every glyph accepted by it is revalidated against its `Font`;
- it cannot outlive source mutation successfully;
- unsupported selected layout paths fail explicitly; and
- only the harness can publish the callback result under the combined charge.

## Component Boundaries

| Component | Responsibility | Must not own |
|---|---|---|
| `mb-text/text::ShapingOptions` | Typed explicit script, language choice, horizontal direction, and closed feature policy | Locale lookup, script detection, bidi, normalization, fallback |
| `mb-text/text::ShapeLimits` | Input/output/execution ceilings and derivation of private font-layout limits | Font-open limits or hidden global defaults |
| `mb-text/text::ShapedRun` | Immutable direction, glyph records, scalar clusters, checked design-unit advances/offsets, total advance | Raw layout tags, lookup indices, font bytes, outlines, pixels |
| `mb-text/text::shape` | User operation, scalar admission, feature policy, clusters, RTL output order, error rebinding, final run construction | OpenType byte parsing or collection/container logic |
| `mb-font/font::FontLayoutProfile` | Immutable request-specific normalized layout facts and supported lookup execution | Public text run, normalization, bidi, fallback, line layout |
| `mb-font/font::FontLayoutOutcome` | Opaque positioned glyph/source-interval facts plus exact font execution charge; creates a profile-bound prepared callback result | Raw ValueRecords, charge-field mutation, public text policy |
| `mb-font/font::FontLayoutSelection` | Font-side typed projection of the already validated script/language/feature decision | Ambient policy or automatic language selection |
| GSUB private engine | Type 1 formats 1/2 and type 4 format 1, Coverage 1/2, ordered selected lookups/subtables | Contextual, chained, reverse-chain, alternate, multiple, GDEF filtering |
| GPOS private engine | Type 2 formats 1/2, Coverage 1/2, ClassDef 1/2, closed static ValueRecord subset | Mark/cursive/contextual attachment, device/variation adjustments |
| Existing `Font` facade | cmap, final-GID hmtx metrics, legacy kern, retained revision, standalone/collection identity | Text clusters or positioned-run publication |
| `mb-core/budget` | Checked aggregate charge composition and hierarchical one-commit authority | Font/text policy |

## Public and Private Seams

### User-facing `mb-text` API

The public surface should be small:

```text
HorizontalDirection = LeftToRight | RightToLeft
LanguageChoice = Default | Exact(LanguageTag)
FeaturePolicy = { standard_ligatures: Bool, kerning: Bool }
ShapingOptions = { script, language, direction, features }
ShapeLimits = explicit non-zero semantic ceilings
PositionedGlyph = opaque glyph + cluster + advance + x/y offset
ShapedRun = direction + units_per_em + records + total_advance
shape(font, scalars, options, limits, budget)
```

Required LangSys features are always applied and cannot be disabled.
`rlig` is enabled as the required-ligature policy; `liga` and `kern` are
explicit booleans. Arbitrary user feature tags should not be exposed in v0.35:
they expand capability semantics without adding a complete script engine.
An unknown required feature may still execute if every referenced lookup stays
inside the supported profile.

Use typed four-byte tags. `LanguageChoice::Default` alone selects
`DefaultLangSys`; `Exact(tag)` never falls back silently. Script selection is
exact, including an explicitly supplied `DFLT` tag. Do not infer a script or
language and do not automatically retry `DFLT`.

### Cross-module `mb-font` seam

Expose only opaque semantic operations:

- begin the guarded transactional profile;
- map/validate opaque glyphs against the receiving font;
- apply selected GSUB to logical glyph/source-interval seeds;
- return substituted glyphs plus source intervals, not lookup records;
- compute base hmtx advances and selected GPOS/legacy positioning;
- return one opaque `FontLayoutOutcome` with final per-glyph design-unit facts
  and the exact hidden font-side resource charge;
- let that outcome bind a completed private user value plus the text-side
  charge into `PreparedLayout[T]`; and
- finish with one revision guard and one combined budget commit.

Do not expose:

- `ByteView`, `TableWindow`, table tags as offsets, Coverage arrays, ClassDef
  arrays, Feature/Lookup indices, ValueRecord fields, or retained parser
  cursors;
- the font opening revision as a number;
- an API that lets a caller execute one arbitrary lookup by index; or
- a mutable layout cache.

The opaque seam can be published from the existing `font` package because that
package already owns all private `Font` fields. A sibling `layout` package
would not have access to those fields and would force a wider internal API.

## Retained Layout Profile

`FontLayoutProfile` is a per-shape immutable value created inside the
transaction closure. It is not stored in `Font`, not global, and not keyed by
process state.

Retain only normalized facts needed by the selected request:

```text
FontLayoutProfile
  source identity (private Font/ByteView relationship)
  admitted glyph cardinality
  selected script + LangSys semantic identity
  GSUB state: Absent | SelectedPlan
  GPOS state: Absent | SelectedPlan
  modern kern authority: Disabled | Gpos | Legacy
  ordered de-duplicated lookup descriptors
  normalized supported Coverage/ClassDef/substitution/pair facts
  exact retained bytes/allocations/work charge
```

Parsing rules:

1. Locate optional `GSUB` and `GPOS` through the retained private
   `DirectoryFacts`; absence is a first-class neutral state.
2. Validate the table header and the complete top-level ScriptList,
   FeatureList, and LookupList envelopes under checked table-local offsets.
3. Reject unsorted or duplicate ScriptRecord, LangSysRecord, FeatureRecord,
   Coverage, pair-set, and class-range facts where the specification requires
   ordering or uniqueness.
4. Select the exact script and exact/default LangSys requested by the caller.
5. Include the LangSys required feature, then the closed `rlig`/`liga`/`kern`
   policy.
6. Gather lookup references, reject out-of-range indices, sort numerically into
   LookupList order, and de-duplicate by lookup index. Each selected lookup is
   executed at most once even if multiple selected features reference it.
7. Validate and normalize every selected lookup and every selected subtable.
   Unselected lookup bodies are not a shaping capability claim, but their
   top-level offset envelope remains checked.
8. Require `lookupFlag == 0` in v0.35. All nonzero flag profiles require GDEF
   filtering/mark semantics or cursive behavior and therefore return
   `Capability`, not a best-effort result.
9. Retain typed semantic arrays and table-local immutable views only. Never
   retain an unchecked offset for later execution.

Do not persist this profile across calls in v0.35. A persistent cache would add
hidden allocation ownership, eviction policy, budget amortization, concurrent
mutation behavior, and a second publication lifecycle. Those belong in a later
performance milestone after the exact profile is stable.

## Exact Data Flow

### 1. Input and entry guard

The caller supplies:

- one already-admitted `Font`;
- `Array[Int]` containing exact Unicode scalar values;
- exact script and default/exact language choice;
- LTR or RTL;
- explicit `liga` and `kern` policy;
- `ShapeLimits`; and
- one authoritative `Budget`.

`shape` performs an initial font revision guard before inspecting scalar
contents. This preserves the existing `Font` convention that an already-mutated
font is a State failure. It then validates every scalar (`0..0x10FFFF`,
excluding surrogates) before mapping any scalar. Empty input succeeds with an
empty run after the same font-state and option validation, without requiring
GSUB/GPOS presence.

Normalization and UAX #9 paragraph processing are not hidden pre-steps. Unicode
defines scalar values separately from normalization, and UAX #9 separately
resolves/reorders paragraphs and lines; v0.35 consumes exact caller values and
one already-segmented uniform direction.

### 2. Logical seed buffer

Keep the working buffer in caller logical order for the complete shaping
transaction:

```text
SeedGlyph {
  glyph: opaque GlyphId,
  source_start: UInt64,
  source_end_exclusive: UInt64
}
```

Each scalar maps through the existing `Font::glyph_for_scalar`; a valid miss
stays glyph zero. Initial source intervals are `[i, i + 1)`. This buffer is
private and cannot be observed on failure.

### 3. Feature and lookup order

For GSUB and GPOS independently:

1. exact Script table;
2. exact/default LangSys;
3. required feature plus enabled closed features;
4. lookup references collected from those features;
5. stable numeric sort and de-duplication by LookupList index;
6. execute each lookup over the entire current logical buffer; and
7. at each glyph position, test subtables in stored order and stop after the
   first matching subtable.

This follows OpenType's explicit ordering model. Caller option order,
FeatureList alphabetical order, and the arbitrary order of LangSys feature
indices must never alter execution.

### 4. GSUB

Support exactly:

- type 1 format 1: checked modulo-65536 delta substitution;
- type 1 format 2: Coverage-indexed explicit replacement;
- type 4 format 1: preference-ordered ligature sets; and
- Coverage formats 1 and 2 required by those lookups.

For a ligature:

- match components in logical/writing direction;
- select the first matching Ligature table in declared preference order;
- replace the first component with the ligature;
- delete only the participating remaining components;
- merge the participating source intervals; and
- validate the output GID against the same receiving `Font`.

Because v0.35 supports only single and ligature substitutions, origin intervals
remain contiguous. `mb-text` defines the public cluster as the minimum original
scalar index in the interval. Positioning never changes an interval or cluster.

Earlier lookups modify the buffer seen by later lookups. Do not batch all
matches against the initial glyph sequence.

### 5. Metrics and positioning

After all GSUB lookups:

1. query `Font::horizontal_metrics` for every final glyph;
2. initialize each advance from authoritative `hmtx`;
3. initialize x/y offsets to zero;
4. apply supported selected GPOS PairPos lookups in LookupList order; and
5. if and only if no applicable supported GPOS `kern` feature was selected,
   apply existing legacy `Font::kerning` to each logical adjacent pair.

GPOS support is exactly:

- PairPos format 1 explicit pairs;
- PairPos format 2 class pairs;
- Coverage formats 1/2;
- ClassDef formats 1/2; and
- static `xPlacement`, `yPlacement`, and `xAdvance` fields for either glyph in
  the pair.

Reject as `Capability`:

- `yAdvance`;
- Device or VariationIndex references;
- reserved ValueFormat bits;
- extension, contextual, cursive, mark, or other GPOS lookup types; and
- any selected nonzero lookup flag.

PairPos format 2 must validate both ClassDefs, class-0 behavior, declared class
counts, and the complete class1-by-class2 matrix extent before use.

Modern/legacy authority is profile-wide for the selected GPOS `kern` path:

```text
kern off
  -> neither GPOS kern nor legacy kern

kern on + selected supported GPOS kern feature
  -> GPOS only, including zero adjustments for pair misses

kern on + no selected GPOS kern feature
  -> legacy Font::kerning fallback

kern on + malformed/unsupported selected GPOS kern path
  -> Data/Capability error; never hide it with legacy fallback
```

### 6. Numeric model

All public advances and offsets remain **font design units**. No ppem scaling,
hinting, device adjustment, floating point, or outline transform occurs.

- Convert `hmtx` advances to a checked signed accumulator.
- Parse ValueRecord fields as signed 16-bit design-unit deltas.
- Accumulate advance and placement adjustments in lookup order using checked
  arithmetic.
- Enforce an explicit `max_abs_position` semantic limit before narrowing to the
  public integer representation.
- Compute `total_advance` with checked arithmetic after final per-glyph
  advances.
- Retain `units_per_em` on the run so consumers can scale deliberately.

Prefer the existing portable `Int` public style only if `ShapeLimits` proves
every intermediate and final value is within the identical four-target range.
Otherwise use an explicit fixed-width signed integer for accumulators and
checked narrowing at publication. Never rely on target overflow behavior.

### 7. LTR and RTL semantics

The input and all internal lookup execution stay in logical order for both
directions. For the supported simple lookups, OpenType component and pair
records are written in logical/writing direction:

- for LTR, the first logical glyph is visually leftmost;
- for RTL, the first logical glyph is visually rightmost.

After substitution and positioning complete:

- LTR publishes logical order as pen/draw order;
- RTL reverses the final record array once to publish pen/draw order; and
- cluster values remain original scalar indices, so RTL output commonly has
  descending clusters.

Direction does not perform paragraph bidi, mirroring, digit shaping, joining,
normalization, script reordering, or mixed-run segmentation. Document this
directly on the public operation.

## Mutation, Errors, and Atomic Publication

### Mutation guards

Use the monotonic retained source revision; byte equality after a mutate-back
does not restore validity.

Required guards:

1. operation entry;
2. before each attacker-counted top-level layout parse stage;
3. after selected GSUB profile normalization;
4. after selected GPOS profile normalization;
5. between bounded execution stages where hostile tests can inject mutation;
6. after the callback has built the complete private `ShapedRun`; and
7. immediately before the one combined `Budget::charge`.

No run, profile, glyph array, or charge is returned after drift.

### Error taxonomy and precedence

Reuse `CoreError`; do not create an unrelated error hierarchy. Rebind font-side
operations to stable public `text-shape` diagnostics while retaining detailed
context.

Recommended observable order:

1. **State at entry** — retained font already drifted.
2. **InvalidInput** — invalid scalar, tag, direction/options, zero/invalid
   limits.
3. **Data** — malformed recognized table envelopes, offsets, ranges, ordering,
   cardinalities, GIDs, classes, or checked numeric facts.
4. **Capability** — structurally valid selected behavior outside the closed
   lookup/value/flag profile or missing exact requested script/language.
5. **Resource** — semantic ceilings, retained allocation/work ceilings, then
   caller/ancestor budget preflight.
6. **State at final guard** — mutation after a complete private result but
   before commit.

Within an attacker-declared loop, a coarse semantic-limit/budget preflight may
precede traversal; document those stage-local collisions explicitly in the
Phase 108 matrix. Validate recognized record envelopes before returning
Capability so malformed data cannot hide behind an unsupported lookup marker.

### Atomic transaction

```text
coarse preflight
  -> parse and retain selected profile privately
  -> build logical seeds privately
  -> apply GSUB privately
  -> compute metrics/positioning privately
  -> return opaque FontLayoutOutcome with exact font execution charge
  -> build complete ShapedRun privately
  -> outcome.prepare(run, exact text ResourceCharge)
  -> harness combines exact profile + execution + text charges
  -> preflight complete charge against caller and ancestors
  -> final revision guard
  -> one Budget::charge
  -> publish one immutable ShapedRun
```

Any error before the final charge leaves caller and ancestor counters
unchanged. No user callback runs after commit.

## Limits and Budget Model

Keep layout limits separate from `FontLimits`. Widening `FontLimits` would make
existing `Font::open` callers configure shaping and could make malformed
optional GSUB/GPOS reject fonts that are otherwise valid for metrics/outlines.

### Font-layout semantic ceilings

- maximum GSUB bytes and GPOS bytes;
- scripts, language systems, features, feature-to-lookup references;
- lookups and subtables;
- Coverage glyphs/ranges;
- ClassDef ranges, class counts, and class-pair cells;
- pair sets and pair records;
- ligature sets, ligatures, and total components;
- retained normalized facts/bytes;
- parser work; and
- all declared counts narrowed safely to MoonBit array indices.

### Text execution ceilings

- input scalars;
- initial and final glyph count;
- selected features;
- lookup applications;
- subtable/match probes;
- substitutions and consumed components;
- pair probes and applied adjustments;
- private/output allocation count and maximum allocation size;
- total execution work;
- maximum absolute advance/offset; and
- checked total advance.

### Budget dimensions

Charge only the existing portable dimensions:

- `bytes` for retained normalized facts and the final immutable run;
- `allocations` for retained arrays and run arrays;
- `allocation_size` for the largest one;
- `work` for parse probes, lookup traversal, matching, metrics, and positioning;
- zero `width`, `height`, and `pixels`;
- no recursion: use iterative loops, so depth is not consumed by the lookup
  engine.

Perform a conservative preflight from table lengths and declared counts before
large loops, then compute the exact aggregate charge from actual retained and
execution facts. Exact-fit succeeds; every one-short dimension fails without a
commit.

## Standalone, Collection, `glyf`, and CFF1 Reuse

Do not add a layout-format dispatch parallel to `FontOutlineSource`.

GSUB, GPOS, cmap, hmtx, and legacy kern are common SFNT tables. The existing
opaque `Font` already resolves the only outline-specific differences:

- `num_glyphs`;
- horizontal metric lookup; and
- outline decoding.

Layout uses `Font.directory` and existing font methods. Therefore:

- standalone `glyf` and standalone CFF1 use the same layout path;
- a selected TTC/OTC face uses the same layout path after `open_face`;
- collection-root table offsets remain correct because the retained selected
  `DirectoryFacts` already owns root-relative checked `ByteView` windows;
- CFF table-local offsets remain irrelevant to shaping;
- no outline query is required to shape; and
- equivalent generated `glyf`/CFF1 faces with equal cmap/hmtx/layout tables
  must produce byte-for-byte equal normalized run facts.

This architecture also prevents an accidental dependency from text shaping
into Type 2, `glyf`, `Path2`, canvas, or rasterization.

## Likely Module and File Map

### `mb-core`

| File | Change |
|---|---|
| `modules/mb-core/budget/budget.mbt` | Add checked immutable `ResourceCharge` composition used by the cross-module transaction |
| `modules/mb-core/budget/budget_test.mbt` / `_wbtest.mbt` | Exact/overflow/ancestor tests for composed charges |

Do not add text tags, OpenType records, or font policy to `mb-core`.

### `mb-font`

Keep all production files in the existing `modules/mb-font/font` package:

| Proposed file | Responsibility |
|---|---|
| `layout_limits.mbt` | Private/public integration limits and exact charge accounting |
| `layout_common.mbt` | GSUB/GPOS headers, Script/LangSys/Feature/Lookup selection, ordered de-duplication |
| `layout_coverage.mbt` | Checked Coverage 1/2 and ClassDef 1/2 normalization/search |
| `gsub.mbt` | Selected type 1/type 4 normalized facts and iterative execution |
| `gpos.mbt` | Selected type 2 formats 1/2, ValueRecord subset, class/pair execution |
| `layout_profile.mbt` | Opaque profile, logical source intervals, transactional continuation, exact charge |
| `font.mbt` | Only the minimal private access/harness hook; preserve existing public queries unchanged |
| `layout_*_wbtest.mbt` | Private structural/order/limit/mutation matrices |
| `layout_test.mbt` | Public opaque integration seam without exposing internals |

Do not create `modules/mb-font/layout` as a sibling package merely for file
organization; it would require publishing private `Font` internals to cross a
package boundary.

### `mb-text`

Create one independently publishable module and one public package initially:

```text
modules/mb-text/
  moon.mod.json
  README.mbt.md
  CHANGELOG.md
  text/
    moon.pkg
    options.mbt
    limits.mbt
    model.mbt
    shape.mbt
    shape_test.mbt
    shape_wbtest.mbt
```

`moon.mod.json` depends only on `tchivs/mb-core` and `tchivs/mb-font`.
`text/moon.pkg` imports the smallest packages required from those modules.
Avoid premature public packages for bidi, lines, fallback, or layout; they are
not implemented by v0.35 and create compatibility obligations.
The production module has no HarfBuzz, ICU, C/C++, FFI, host-font, filesystem,
locale, or GUI dependency.

### Qualification assets

Follow the shipped font-qualification architecture:

- generated equivalent `glyf` and CFF1 fixtures;
- generated LTR/RTL, required/default/exact-language, lookup-overlap,
  ligature-preference, PairPos 1/2, modern/legacy authority cases;
- canonical hostile rows with exact source locators and policy mirrors;
- immutable licensed DejaVu Sans and Source Sans specimens only when their
  selected paths remain inside the closed profile;
- pinned host-only oracle facts with provenance, never runtime payloads;
- one closed semantic record from each exact target; and
- observation-only native timing after correctness is sealed.

## Phase Build Order

### Phase 108 — Contract, transaction, and bounded layout selection

Build first:

- `mb-core` checked charge composition;
- `mb-text` module/package, typed options, limits, run model;
- `mb-font` transaction closure and opaque profile;
- optional GSUB/GPOS table discovery;
- Script/LangSys/Feature/Lookup envelope validation;
- required/default feature policy;
- ordered lookup de-duplication;
- entry/stage/final mutation guards; and
- exact/one-short resource tests.

Exit criterion: a selected profile can be built and atomically discarded or
published without raw-table leakage, but no false shaping claim is required
yet.

### Phase 109 — cmap seeds and deterministic GSUB

Add:

- scalar preflight and existing cmap reuse;
- logical source intervals;
- GSUB type 1 formats 1/2;
- type 4 format 1;
- subtable-first-match and LookupList-order execution;
- ligature preference and cluster propagation;
- LTR/RTL final order; and
- final-GID hmtx base advances.

Exit criterion: substitution-only shaped runs are complete and every selected
unsupported lookup/flag fails explicitly.

### Phase 110 — Pair positioning and kerning authority

Add:

- GPOS PairPos formats 1/2;
- Coverage/ClassDef normalization;
- static ValueRecord subset;
- checked accumulated advances/offsets;
- modern GPOS versus legacy kern authority;
- total advance;
- complete error-collision and final-mutation matrix; and
- one combined exact charge/publication.

Exit criterion: the final public run contract is complete.

### Phase 111 — Interoperability and four-target evidence

Add:

- generated `glyf`/CFF1 and standalone/collection equivalence;
- pinned licensed specimens and independent oracle facts;
- canonical hostile corpus;
- frozen 1,287-test v0.34 compatibility baseline or its exact current
  successor;
- equal `js`, `wasm`, `wasm-gc`, and `native` semantic records; and
- observation-only native workloads.

Do not widen the runtime profile merely to make one licensed font convenient.
Replace or narrow the specimen if it selects deferred behavior.

## Dependency Cycles and Anti-Patterns to Avoid

### `mb-font -> mb-text`

**Why bad:** creates a module cycle and lets font parsing depend on string
policy.
**Instead:** `mb-text` invokes generic opaque font-layout operations through a
continuation; `mb-font` never imports text types.

### Raw-table access from `mb-text`

**Why bad:** duplicates offset/bounds/mutation logic and leaks font-format
storage into the public text module.
**Instead:** typed normalized layout facts and operations remain private to the
font package.

### Parsing layout during `Font::open`

**Why bad:** regresses fonts used only for metrics/outlines, widens
`FontLimits`, and charges layout work before any shaping request.
**Instead:** request-specific bounded profile inside `shape`.

### Persistent implicit cache

**Why bad:** hidden memory, stale revisions, ambiguous charge ownership,
eviction nondeterminism, and concurrency policy.
**Instead:** one immutable per-operation profile; revisit caching only with a
separate explicit contract.

### Two budget commits

**Why bad:** a later failure can leave partial authoritative consumption.
**Instead:** checked aggregate charge and one final commit in the font-owned
transaction harness.

### Reversing input before RTL shaping

**Why bad:** OpenType component/pair sequences are already defined in
logical/writing direction; early reversal corrupts matching and clusters.
**Instead:** shape logical input, reverse only final output records.

### Applying GPOS and legacy kern together

**Why bad:** double-adjusts pairs and hides the authority decision.
**Instead:** selected supported GPOS `kern` is profile-wide authoritative;
legacy is absence fallback only.

### Silently skipping selected unsupported behavior

**Why bad:** returns plausible but typographically false output.
**Instead:** stable `CapabilityUnavailable`, no run, no charge.

### Pulling in complex-script helpers

**Why bad:** contextual, cursive, mark, Arabic/Indic/Khmer processing is not
made correct by implementing one extra lookup.
**Instead:** retain offsets in the public run model for future extensions and
keep v0.35's capability boundary honest.

### Production HarfBuzz, ICU, or FFI adapters

**Why bad:** transfers ownership, portability, and mutation semantics to a
foreign runtime and makes four-target equality dependent on host state.
**Instead:** keep runtime shaping in pure MoonBit; use a pinned foreign tool
only as an offline qualification oracle whose outputs are provenance-bound and
never shipped as executable/runtime data.

## Scalability Considerations

This is a bounded library rather than a service; scale is measured by hostile
font/table/input cardinality.

| Concern | Small ordinary run | Declared maximum | Hostile/one-short boundary |
|---|---|---|---|
| Scalar mapping | Existing admitted cmap binary search | `max_scalars` and `max_glyphs` | Invalid scalar fails before any partial run |
| Feature selection | Small fixed policy | bounded scripts/languages/features/refs | Unsorted/duplicate/out-of-range facts fail before lookup execution |
| Lookup execution | Linear scan with bounded binary searches | explicit applications/probes/work | No undeclared quadratic search; every probe is charged |
| Ligatures | Short preference lists | total ligatures/components and output count | No expansion beyond input for supported lookup types |
| PairPos format 2 | Direct class lookup | bounded classes and matrix cells | Matrix extent and allocation preflight before materialization |
| Numeric accumulation | hmtx plus small deltas | explicit absolute position and total limits | Checked overflow returns Data/Resource before publication |
| Memory | One private profile + one private/final run | bytes/allocations/max allocation | Exact one-short caller and ancestor budgets leave counters unchanged |

## Qualification Architecture

Qualification must exercise the exact public route, not private parsers alone.

The canonical per-target semantic carrier should include:

- input scalar values and option tags;
- selected direction/feature policy;
- output glyph numeric values obtained through the public opaque accessor;
- clusters, advances, x/y offsets, units-per-em, total advance;
- exact error category/code/operation/context for hostile rows;
- caller and ancestor budget deltas;
- standalone versus selected-collection identity;
- `glyf` versus CFF1 identity;
- fixture/oracle/provenance hashes; and
- toolchain and public interface identities.

Normalize only runner/target identity before comparing semantic hashes.
Correctness records must be equal on all four targets. Native timing is a
separate observation with no threshold and no correctness authority.

## Research Flags for Planning

- **Phase 108:** confirm MoonBit generic closure/export ergonomics for the
  `PreparedLayout[T]` continuation before freezing names; keep the semantic
  transaction shape even if syntax changes.
- **Phase 108:** freeze exact stage-local Data/Capability/Resource/State
  collisions and whether empty input requires only a font-state guard or a
  complete profile.
- **Phase 109:** freeze duplicate lookup reference de-duplication, subtable
  first-match cases, and the exact RTL logical-to-pen-order evidence.
- **Phase 110:** freeze the signed public numeric type, ValueRecord field mask,
  PairPos second-glyph advancement rule, and class-0 lookup behavior.
- **Phase 111:** inspect licensed fonts before selecting cases; an independent
  oracle must not force extension/GDEF/contextual support into this milestone.

## Sources

### Primary format and Unicode sources

- [OpenType 1.9.1 — Layout common table formats](https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2) — Script/LangSys/Feature/Lookup organization, numeric LookupList ordering, first-matching-subtable processing, Coverage/ClassDef, and lookup flags. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — GSUB](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub) — type 1 formats 1/2, type 4 format 1, LigatureSet preference, logical/writing-direction components, and lookup-order significance. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — GPOS](https://learn.microsoft.com/en-us/typography/opentype/spec/gpos) — PairPos formats 1/2, direction-sensitive pairs, ValueRecords, Coverage/ClassDef, and device/variation distinctions. **Confidence: MEDIUM.**
- [OpenType 1.9.1 — legacy `kern`](https://learn.microsoft.com/en-us/typography/opentype/spec/kern) — legacy horizontal pair-adjustment boundary used by the existing `Font::kerning` fallback. **Confidence: MEDIUM.**
- [Unicode 17.0 Core Specification, Chapter 3](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) — scalar-value range/surrogate exclusion and separate normative Unicode behaviors. **Confidence: MEDIUM.**
- [Unicode Standard Annex #15 — Normalization Forms](https://www.unicode.org/reports/tr15/) — normalization is a separate transformation of Unicode text. **Confidence: MEDIUM.**
- [Unicode Standard Annex #9 — Bidirectional Algorithm](https://www.unicode.org/reports/tr9/) — paragraph/line resolution and display reordering are separate from accepting an explicit already-segmented run direction. **Confidence: MEDIUM.**

### Local architectural authorities

- `.planning/PROJECT.md` and `.planning/MILESTONE-CONTEXT.md` — binding v0.35 goal, selected vertical slice, exclusions, four-target/atomicity constraints. **Confidence: HIGH.**
- `.planning/research/FEATURES.md` — completed v0.35 user model, table stakes, anti-features, feature-order and GPOS/legacy authority decisions. **Confidence: HIGH.**
- `docs/rfcs/0004-mb-font.md` and `docs/rfcs/0005-mb-text.md` — font-binary versus string-level ownership and allowed module dependencies. **Confidence: HIGH.**
- `modules/mb-font/font/font.mbt`, `directory.mbt`, `tables.mbt`, `cmap.mbt`, `metrics.mbt`, `kern.mbt`, `collection.mbt`, and `limits.mbt` — live opaque font, retained directory/source, budget ledger, mapping, metrics, kerning, collection, and limit seams. **Confidence: HIGH.**
- `modules/mb-core/budget/budget.mbt`, `bytes/views.mbt`, and `unicode/unicode.mbt` — hierarchical budgets, monotonic mutation revisions, and the existing accepted Unicode package. **Confidence: HIGH.**
- Archived v0.32-v0.34 phase summaries and research — shipped admission/query/collection/CFF/four-target patterns and compatibility evidence. **Confidence: HIGH.**

---
*Architecture research for: MoonBit Native Foundation v0.35 Text Shaping Foundation*
*Researched: 2026-07-30*
