# Phase 98: Unicode Mapping and Kerning - Research

**Researched:** 2026-07-27
**Domain:** Bounded OpenType `cmap` format 4/12 resolution and legacy `kern` version-0 format-0 lookup in portable MoonBit
**Confidence:** HIGH for repository integration; MEDIUM for externally cited normative details

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Unicode Query Contract
- **D-01:** Expose one signed-integer scalar-to-opaque-`GlyphId` query so negative values are testable caller errors. A scalar is valid only in `U+0000..U+10FFFF` excluding `U+D800..U+DFFF`; invalid input returns a structured invalid-input error, while a valid unmapped scalar returns glyph zero.
- **D-02:** A mapped glyph must already be proven within the receiving font's glyph cardinality. The public result reuses Phase 97's opaque `GlyphId`; no raw table offset, encoding record, or integer-only bypass becomes public.
- **D-03:** Every cmap query uses Phase 97's pre-read and post-read retained-source revision guards. Mutation drift fails before publishing a glyph result.

### Deterministic Cmap Selection
- **D-04:** Admit one canonical Unicode mapping for queries: prefer an eligible format 12 subtable over every format 4 subtable, matching the OpenType rule that a 32-bit mapping supersedes a 16-bit compatibility mapping.
- **D-05:** Use the research-frozen rank exactly: `(platform 0, encoding 4, format 12)`, `(3, 10, 12)`, `(0, 3, 4)`, then `(3, 1, 4)`. Legacy Macintosh, ISO, custom, or symbol records may be structurally admitted when they use the supported formats, but they never become the Unicode mapping.
- **D-06:** Aliased encoding records may share one checked subtable. Distinct equally eligible records must resolve to the same admitted mapping facts or opening fails deterministically; do not merge records or fall back to a lower-priority table on a per-scalar miss.
- **D-07:** Preserve the Phase 97 format-4 and format-12 structural validation, sorted-range checks, glyph-range proof, checked arithmetic, and charged work. Planning may narrow the previously broad encoding-domain admission so it matches the canonical Unicode selection policy.
- **D-07a:** A well-formed admitted font with no eligible Unicode record fails `Font::open` with a capability error. A supplementary scalar queried through the selected format 4 mapping is a valid miss and returns glyph zero.

### Legacy Horizontal Kerning
- **D-08:** Support the interoperable basic profile: an optional OpenType `kern` table with version 0 and exactly one version-0, horizontal kerning-value, format-0 subtable whose coverage is exactly `0x0001`. Multiple supported subtables, format 2, Apple extensions, vertical/minimum/cross-stream/override/variation behavior, and reserved coverage bits are present-but-unsupported capabilities.
- **D-09:** The public pair query accepts two opaque `GlyphId` values, revalidates both against the receiving `Font`, and returns an exact signed font-unit adjustment. Table absence and a supported pair miss both return neutral zero.
- **D-10:** Classify recognized but out-of-profile kern data as a capability error and structurally invalid supported-profile bytes as a data error, with stable distinct contexts. Neither may be confused with successful neutral zero.
- **D-10a:** A well-formed out-of-profile kern table does not block metrics or cmap use: `Font::open` retains an unsupported-capability state and only the kerning query returns the capability error. A malformed kern envelope fails atomic opening as data.
- **D-11:** Format-0 pair keys must be strictly sorted and unique, both glyph IDs must be in range, search helper fields must be canonical, lengths must be exact, and lookup uses deterministic binary search.

### Admission and Resource Semantics
- **D-12:** Select and validate cmap and optional kern facts during the existing atomic `Font::open` admission transaction. Retain only compact table-local lookup facts; do not allocate a decoded Unicode map or kerning dictionary.
- **D-13:** Charge every attacker-declared record, group, segment, subtable, and pair scan before the loop that consumes it. Add explicit non-zero `max_kern_subtables` and `max_kern_pairs` semantic ceilings to `FontLimits` alongside the authoritative shared budget and `max_work`. — **Reversibility:** costly — removing these limits later would change the public constructor and weaken a published resource contract.
- **D-14:** Successful queries are bounded, allocation-free binary searches over already admitted facts and do not mutate the caller's opening budget. Exact-fit/one-short admission tests remain the resource oracle.

### Verification and Compatibility
- **D-15:** Generated micro-fonts must cover BMP and supplementary mappings, format-12 precedence, valid misses, invalid scalars, format-4 direct and glyph-array paths, aliased/conflicting records, glyph-range failures, kern absence/miss/hit, negative adjustments, unsupported profiles, malformed pairs, mutation drift, and exact limit/budget edges.
- **D-16:** Public black-box tests freeze stable semantic outcomes; private white-box tests cover offset math, selection ranking, binary-search boundaries, and error taxonomy. The phase must preserve the four-target package contract and minimal generated `.mbti` surface.

### the agent's Discretion
- Exact public method names and private source-file split are flexible if the generated interface exposes only the two scoped queries and the established opaque values.
- Exact stable error context strings and the internal representation of selected subtable offsets are flexible, provided invalid input, malformed data, unsupported capability, mutation, and resource exhaustion remain distinguishable.
- Exact internal encodings for selected/absent/unsupported table states are flexible if they preserve the locked public outcomes.

### Deferred Ideas (OUT OF SCOPE)
- Phase 99 owns simple/composite outline extraction and `Path2`-compatible geometry.
- Phase 100 owns licensed real-font provenance, public end-to-end workflow, and four-target hostile qualification.
- GPOS/GSUB shaping, vertical or cross-stream kerning, minimum values, multiple-subtable accumulation/override, format 2, Apple kern extensions, variable-font behavior, normalization, bidi, discovery, and rasterization remain outside v0.32.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FONT-02 | Library authors can map any valid Unicode scalar through deterministic cmap format 12/4 selection, receiving glyph zero for a valid miss and a structured error for an invalid scalar or malformed mapping. | Canonical rank, retained lookup descriptors, scalar validation, format-specific binary search, glyph-range proof, revision guards, and public/white-box cases below. [VERIFIED: `.planning/REQUIREMENTS.md`, `98-CONTEXT.md`, repository inspection] |
| FONT-04 | Library authors can query basic legacy horizontal format-0 kerning and distinguish neutral table absence or pair miss from present-but-unsupported or malformed kerning data. | Optional-table tri-state, exact version/coverage/length profile, pair-key validation, deferred capability error, and outcome matrix below. [VERIFIED: `.planning/REQUIREMENTS.md`, `98-CONTEXT.md`, repository inspection] |
</phase_requirements>

## Summary

Phase 98 should extend the existing Phase 97 admission transaction, not introduce a second parsing path. `font_admit_required_tables` already validates every format-4/12 subtable, proves every derived glyph is below `maxp.numGlyphs`, preflights attacker-declared work, and retains the table-local `ByteView`; the missing piece is a compact canonical lookup descriptor rather than the current `CmapEnvelope { record_count }`. [VERIFIED: `modules/mb-font/font/tables.mbt`]

The `kern` table must be discovered as an optional normalized `TableWindow`, parsed during admission, and retained as one of three private states: absent, supported format-0 facts, or well-formed but unsupported capability. Malformed supported-profile bytes still fail `Font::open`; only the unsupported state is deferred until the pair query. [VERIFIED: `98-CONTEXT.md`; VERIFIED: `modules/mb-font/font/directory.mbt`]

OpenType requires clients to use one non-variation `cmap`, prefer a 32-bit Unicode mapping over a 16-bit mapping, map misses to glyph zero, and choose consistently among same-format Unicode records. Format 4 and format 12 have sorted lookup structures that directly support allocation-free binary search. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/cmap]

**Primary recommendation:** Add private `cmap.mbt` and `kern.mbt` lookup/admission layers, extend `RequiredTableFacts` and `FontLimits`, and expose only `Font -> Int -> Result[GlyphId, CoreError]` and `Font -> GlyphId -> GlyphId -> Result[Int, CoreError]`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scalar validity and public query contract | `mb-font/font` public facade | `mb-core/error` | The font owns one-scalar mapping; shared structured errors carry invalid-input facts. [VERIFIED: RFC 0004; `font.mbt`] |
| Canonical cmap selection and same-priority uniqueness | Font admission | Table-local cmap decoder | Selection is an admitted-font invariant and must complete before `Font` publication. [RESOLVED: `98-CONTEXT.md`] |
| Format 4/12 lookup | Private cmap decoder | Retained `ByteView` | Queries binary-search already validated table-local facts without decoded maps. [VERIFIED: `tables.mbt`; CITED: OpenType cmap] |
| Optional kern capability classification | Font admission | Directory optional lookup | Absence, supported facts, and unsupported capability must be retained distinctly. [VERIFIED: `98-CONTEXT.md`] |
| Pair revalidation and result publication | `Font` public facade | Private kern decoder | The receiving font owns glyph cardinality and revision guards; the decoder returns an exact signed FWORD. [VERIFIED: `font.mbt`; CITED: OpenType kern] |
| Resource enforcement | Admission charge plus `FontLimits` | Caller-owned `Budget` | Declared loops are preflighted and charged once before the atomic parser runs. [VERIFIED: `tables.mbt`, `limits.mbt`] |

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared data models in MoonBit; do not wrap a foreign font stack. [VERIFIED: `AGENTS.md`]
- Preserve native as the primary target while maintaining deliberate `js`, `wasm`, `wasm-gc`, and native capability boundaries and conformance. [VERIFIED: `AGENTS.md`, `moon.pkg`]
- Keep any FFI small, isolated, documented, and replaceable; this phase requires no FFI. [VERIFIED: `AGENTS.md`, phase scope]
- Preserve acyclic explicitly documented module dependencies; `tchivs/mb-core` remains the only direct runtime dependency. [VERIFIED: `AGENTS.md`, `moon.mod.json`, `policy/foundation.json`]
- Preserve deterministic non-GUI operation and evidence-based performance/resource claims. [VERIFIED: `AGENTS.md`]
- New modules or breaking architectural changes require RFC governance; Phase 98 extends the existing RFC 0004 package boundary. [VERIFIED: `AGENTS.md`, `docs/rfcs/0004-mb-font.md`]
- Start file-changing implementation through GSD; this research artifact is produced by the active phase-planning workflow. [VERIFIED: `AGENTS.md`, orchestrator context]
- Prefer the codebase knowledge graph for code discovery; its fresh index returned no MoonBit symbols for this package, so scoped `rg`/direct reads were used as the documented fallback. [VERIFIED: graph query and repository inspection]

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Check, test, interface generation | Installed and frozen project toolchain. [VERIFIED: `moon version --all --json`] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile all package targets | Comes with the pinned project toolchain. [VERIFIED: `moon version --all --json`] |
| `tchivs/mb-core` | workspace `0.1.0` | `ByteView`, checked arithmetic/ranges, budget, `CoreError` | Existing and only allowed runtime dependency. [VERIFIED: `moon.mod.json`, `moon.pkg`, policy] |
| OpenType | 1.9.1 | Normative cmap/kern binary contracts | Current project baseline and cited official table chapters. [VERIFIED: `.planning/research/STACK.md`; CITED: Microsoft OpenType spec] |
| Unicode | 17.0.0 | Scalar validity | D76 gives the exact numeric scalar domain; no Unicode database is needed. [CITED: https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/] |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Existing generated micro-font builders | repository current | Deterministic byte-level fixtures | Extend for selection, conflict, lookup, kern, mutation, and limit cases. [VERIFIED: `font_test.mbt`] |
| `policy/foundation.json` plus quality scripts | repository current | Exact package inventory and semantic interface allowlist | Update in the same plan that adds files/public methods/limit accessors. [VERIFIED: policy and quality script inspection] |

No external package installation is required, so no package-legitimacy gate applies. [VERIFIED: package manifests and phase scope]

## Architecture Patterns

### System Architecture Diagram

```text
caller ByteView + FontLimits + Budget
                 |
                 v
       existing directory/checksum/profile admission
                 |
          +------+------------------+
          |                         |
          v                         v
  cmap record scan             optional kern lookup
  validate every 4/12          absent -> Absent
  candidate + rank             supported -> validate pairs
  enforce key uniqueness       other profile -> Unsupported
          |                         |
          +-----------+-------------+
                      v
             final revision guard
                      |
                      v
     Font { selected cmap facts, kern state, metrics... }

scalar query                         kern query
pre-revision guard                   pre-revision guard
validate signed scalar               revalidate left/right GlyphId
binary-search selected mapping       state branch
  miss -> glyph 0                      Absent -> 0
  hit  -> admitted GlyphId             Unsupported -> capability error
post-revision guard                    Supported -> pair binary search
publish GlyphId                      post-revision guard -> signed units/0
```

This keeps all attacker-controlled structural decisions inside atomic opening and leaves queries bounded and allocation-free. [VERIFIED: `98-CONTEXT.md`, existing `Font::horizontal_metrics` pattern]

### Recommended Project Structure

```text
modules/mb-font/font/
├── font.mbt          # Font fields, public scalar/kern methods, revision/glyph guards
├── tables.mbt        # existing aggregate admission and RequiredTableFacts integration
├── cmap.mbt          # canonical rank, same-priority uniqueness, compact facts, lookup
├── kern.mbt          # optional envelope/profile state, pair validation, lookup
├── limits.mbt        # new non-zero kern limits/accessors
├── directory.mbt     # add optional table-window lookup; keep required lookup unchanged
├── font_test.mbt     # public contract and generated micro-font builders
├── font_wbtest.mbt   # rank/offset/binary-search/error internals
└── generated_fonts_wbtest.mbt
```

Update `policy/foundation.json` publication files, production source order, semantic interface, module description, README, changelog, and regenerated `pkg.generated.mbti` with the implementation. [VERIFIED: `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`]

### Pattern 1: Retained Format-Specific Lookup Facts

Retain a tagged private descriptor, not a decoded map. [VERIFIED: D-12]

```moonbit
// Repository-conforming design sketch; exact names are discretionary.
priv(all) enum CmapLookupFacts {
  Format4(CmapFormat4Facts)
  Format12(CmapFormat12Facts)
}

priv struct CmapFormat4Facts {
  table : TableWindow
  subtable_start : UInt64
  subtable_end : UInt64
  segment_count : UInt64
  end_codes : UInt64
  start_codes : UInt64
  id_deltas : UInt64
  id_range_offsets : UInt64
  glyph_array_start : UInt64
}

priv struct CmapFormat12Facts {
  table : TableWindow
  groups_start : UInt64
  group_count : UInt64
}
```

Compute all offsets with `checked_add`/`checked_mul` during admission and retain only table-local offsets. [VERIFIED: existing `font_validate_cmap_subtable` pattern]

### Pattern 2: Validate Every Supported Record, Then Select One Frozen Rank

Structurally validate every supported format-4/12 record under the Phase 97 rules, assign canonical candidates only the four ranks fixed by D-05, and retain the lowest numeric rank independent of directory order. Same-offset aliases are one already-validated mapping. Candidate consistency is scoped only to records at the same winning priority: the directory record-key uniqueness invariant rejects a second distinct record with the same `(platform, encoding)` key before selection, so no unbounded cross-map equality pass is required. [RESOLVED: D-04 through D-07]

Lower-ranked eligible records are neither consulted nor compared semantically after the winning priority is known. A selected-table miss never falls through to another record. This resolves D-06 while preserving OpenType's exclusive-subtable model and the frozen D-05 priority. [RESOLVED: D-05, D-06; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/cmap]

### Pattern 3: Optional Kern Tri-State

Use a private state whose branches exactly match public semantics. [VERIFIED: D-10a]

```moonbit
priv(all) enum KernState {
  Absent
  Supported(KernFormat0Facts)
  Unsupported
}
```

Add a `font_optional_table_window` returning `TableWindow?`; do not weaken `font_table_window`, because its missing-table error is part of required-table admission. [VERIFIED: `directory.mbt`, `font.mbt`]

Classify the envelope before profile support:

- Fewer than 4 bytes is `Data`.
- If the top-level `uint16` version is `0`, require the complete 4-byte OpenType header and preflight `nTables`. Every subtable must have a contained 6-byte header, `uint16 length >= 6`, a checked cumulative end, and a final cumulative end exactly equal to the table length. Any structural failure is `Data`. Only after this pass classify subtable version/coverage/format/profile: exactly one version-0, coverage-`0x0001`, format-0 subtable may become `Supported`; multiple supported subtables or any structurally valid out-of-profile composition becomes cached `Unsupported`. [RESOLVED: D-08, D-10, D-10a; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/kern]
- If the exact top-level `uint32` version is `0x00010000`, require the complete 8-byte Apple header, bound and preflight its `uint32 nTables`, and require every Apple subtable to have a contained 8-byte header, `uint32 length >= 8`, checked cumulative end, and exact final exhaustion of the table. Envelope failure is `Data`; any structurally valid Apple table is cached `Unsupported`, and only `Font::kerning` returns `Capability`. Do not parse Apple format bodies. [RESOLVED: D-10, D-10a; CITED: https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6kern.html]
- Any other nonzero/unknown version with a complete 4-byte version/header prefix becomes cached `Unsupported` without attacker-driven subtable traversal. Truncation remains `Data`. [RESOLVED: D-10, D-10a]

For the one supported OpenType profile, additionally validate `subtable_length == 14 + 6 * nPairs`, canonical 6-byte search fields, strict `(left << 16) | right` ordering with no duplicates, both glyph IDs below `numGlyphs`, and signed adjustments through existing `read_i16`. [VERIFIED: D-08, D-11; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/kern]

### Pattern 4: Guard → Validate → Read → Guard → Publish

Both public queries must mirror `Font::horizontal_metrics`: check revision first, validate caller-owned values, perform private reads, check revision again, then construct/publish the semantic result. [VERIFIED: `font.mbt`]

### Anti-Patterns to Avoid

- **Per-scalar subtable selection:** it produces a merged mapping prohibited by D-06 and OpenType's exclusive-subtable model. [VERIFIED: D-06; CITED: OpenType cmap]
- **Returning raw `UInt64` glyph IDs:** it bypasses the opaque receiving-font contract. [VERIFIED: D-02, existing `.mbti`]
- **Reparsing directory or encoding records in every query:** it weakens bounded-query guarantees and duplicates admission decisions. [VERIFIED: D-12, D-14]
- **Treating unsupported kern as absent:** it collapses a required observable distinction. [VERIFIED: FONT-04, D-10]
- **Rejecting all unsupported kern at open:** well-formed out-of-profile kern must not block metrics/cmap queries. [VERIFIED: D-10a]
- **Trusting `searchRange` fields for navigation:** derive binary-search bounds from admitted counts and only validate stored helper fields. [CITED: OpenType cmap; VERIFIED: existing code pattern]
- **Hash-only mapping equivalence:** collisions cannot establish semantic equality. [ASSUMED]

## Exact Integration Seams

| Existing seam | Required change | Planner consequence |
|---------------|-----------------|---------------------|
| `CmapEnvelope { record_count }` | Replace/extend with selected `CmapLookupFacts`; preserve record count only if still needed. [VERIFIED: `tables.mbt`] | One task should own cmap admission facts and lookup together. |
| `font_cmap_domain_supported` | Separate “structurally admitted supported format” from “eligible canonical Unicode record.” [VERIFIED: D-05, D-07] | Legacy format-4/12 records may be structurally valid but never selected. |
| `font_admit_cmap_envelope` | Validate every supported record, enforce record-key uniqueness/alias rules, rank canonical candidates, and return the winning lookup facts without lower-rank semantic comparison. [RESOLVED: `tables.mbt`, D-04–D-07] | Preserve all existing failure checks and exact work preflights. |
| `font_admission_charge` | Add `directory.numTables` once for the optional-kern directory scan, preflight before that scan, then discover kern counts and add subtable/pair work before their declared loops. [RESOLVED: `tables.mbt`, D-13] | Charge the directory-record scan exactly once and add exact-fit/one-short oracles before recomputing the remaining exact-work cases. |
| `RequiredTableFacts` | Add selected cmap descriptor plus `KernState`. [VERIFIED: `tables.mbt`, D-12] | `Font::open` continues to publish once. |
| `font_table_window` | Keep required semantics; add optional lookup returning `None`. [VERIFIED: `directory.mbt`] | Kern absence becomes neutral instead of a missing-required-table data error. |
| `FontLimits::new` | Add non-zero `max_kern_subtables` and `max_kern_pairs`, fields, accessors, tests. [VERIFIED: D-13] | This is an intentional public constructor/interface change; update every call site. |
| `Font` | Add two public queries and possibly no new public types. [VERIFIED: D-01, D-09, D-16] | Generated interface should expose only methods plus new limit accessors/constructor parameters. |
| `policy/foundation.json` | Add source files, methods, limits, descriptions, exact source order. [VERIFIED: policy inspection] | Policy and interface regeneration belong in the final implementation wave. |

## Public Outcome Matrix

| Operation/input | Outcome |
|-----------------|---------|
| scalar `< 0`, surrogate, or `> 0x10FFFF` | `InvalidInput` / stable scalar-range context. [VERIFIED: D-01; CITED: Unicode D76] |
| valid scalar absent from selected cmap | opaque glyph zero. [VERIFIED: D-01; CITED: OpenType cmap] |
| supplementary scalar with selected format 4 | glyph zero without fallback. [VERIFIED: D-07a] |
| source revision changes before/during lookup | state/revision error; publish nothing. [VERIFIED: D-03] |
| kern absent | `0`. [VERIFIED: D-09] |
| supported kern pair absent | `0`. [VERIFIED: D-09] |
| supported pair present | exact signed font-unit adjustment. [VERIFIED: D-09; CITED: OpenType kern] |
| either glyph belongs outside receiving font | invalid-input glyph-range error. [VERIFIED: D-09, existing glyph policy] |
| retained kern state unsupported | capability error from pair query only. [VERIFIED: D-10a] |
| malformed supported kern envelope/pairs | `Font::open` data error, no `Font`. [VERIFIED: D-10, D-10a] |
| cmap has no eligible Unicode record | `Font::open` capability error. [VERIFIED: D-07a] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Unicode categorization/normalization | Unicode database or string normalizer | Numeric D76 scalar predicate | The API accepts one integer scalar only. [VERIFIED: D-01; CITED: Unicode D76] |
| Glyph identity | New cmap-only ID or raw integer result | Existing opaque `GlyphId` | Receiving-font validation already exists. [VERIFIED: `font.mbt`] |
| Decoded lookup caches | Hash maps/dictionaries of mappings/pairs | Binary search over retained tables | Sorted formats already provide indexes and D-12 forbids decoded maps. [CITED: OpenType cmap/kern; VERIFIED: D-12] |
| New error hierarchy | Font-specific public error enum | `@error.CoreError` categories/codes/contexts | Existing package contract and tests already use it. [VERIFIED: `directory.mbt`, `font.mbt`] |
| New resource tracker | Parser-local counters replacing budget | `FontLimits` plus caller `Budget` and `ResourceCharge` | Existing admission atomically preflights and charges. [VERIFIED: `tables.mbt`, `limits.mbt`] |
| Foreign font engine | FreeType/HarfBuzz/FontTools at runtime | Pure MoonBit table decoder | Foreign stacks violate the module and portability boundary. [VERIFIED: `AGENTS.md`, stack research] |

## Common Pitfalls

### Pitfall 1: Wrong Format-4 `idRangeOffset` Base

**What goes wrong:** treating the value as relative to the subtable or glyph array returns the wrong glyph or reads outside the subtable. [CITED: OpenType cmap]

**How to avoid:** compute from the address of the current `idRangeOffset[i]` word, add `2 * (scalar - startCode)`, require the resulting two-byte read inside the admitted subtable, preserve raw zero as missing, and only then apply `idDelta` modulo 65536. [CITED: OpenType cmap; VERIFIED: existing admission code]

### Pitfall 2: Applying `idDelta` to a Zero Array Entry

**What goes wrong:** a missing-glyph zero becomes a nonzero glyph. [CITED: OpenType cmap]

**How to avoid:** for the glyph-array path, return zero immediately when the raw word is zero; apply modulo delta only to nonzero raw glyphs. [CITED: OpenType cmap]

### Pitfall 3: Ranking by File Order

**What goes wrong:** equivalent fonts select different mappings when record order changes. [VERIFIED: D-05]

**How to avoid:** compute the four-value rank explicitly and treat all other records as non-canonical. [VERIFIED: D-05]

### Pitfall 4: Accidental Fallback

**What goes wrong:** a format-12 miss falls through to format 4, producing a merged mapping. [VERIFIED: D-06]

**How to avoid:** retain exactly one canonical descriptor and make the query dispatch only on its format tag. [VERIFIED: D-04, D-06]

### Pitfall 5: Kern Length Ambiguity

**What goes wrong:** accepting trailing bytes or trusting `nPairs` without checked multiplication allows hidden or truncated records. [VERIFIED: D-11]

**How to avoid:** require exact lengths from `14 + 6*nPairs` for the one subtable and exact exhaustion of the table. [CITED: OpenType kern layout]

### Pitfall 6: Deferred Capability Becomes Deferred Malformation

**What goes wrong:** a truncated version-0 subtable is retained as unsupported and later confused with capability failure. [VERIFIED: D-10]

**How to avoid:** validate the recognized envelope enough to distinguish structurally impossible bytes before choosing the unsupported state; only valid out-of-profile features are deferred. [VERIFIED: D-10a]

### Pitfall 7: Work Charged After the Loop

**What goes wrong:** hostile counts consume CPU before the budget rejects them. [VERIFIED: existing admission design]

**How to avoid:** add `directory.numTables` to declared discovery work for the one optional-kern lookup, preflight before iterating `directory.tables`, and include that scan exactly once in the aggregate charge. Apply the same discover/preflight/aggregate discipline to kern subtable headers and pair scans. [RESOLVED: `font_admission_charge`, D-13]

### Pitfall 8: Policy Allowlist Drift

**What goes wrong:** code/tests pass locally but repository quality gates reject new files or public interface lines. [VERIFIED: `policy/foundation.json`, quality scripts]

**How to avoid:** update policy inventory, source order, semantic interface, README, changelog, and generated `.mbti` in the same phase. [VERIFIED: policy inspection]

## Code Examples

### Scalar Predicate and Guarded Query Skeleton

```moonbit
// Source: Unicode 17.0 D76 plus repository Font query pattern.
fn font_valid_scalar(value : Int) -> Bool {
  value >= 0 &&
  value <= 0x10FFFF &&
  !(value >= 0xD800 && value <= 0xDFFF)
}

pub fn Font::glyph_for_scalar(
  self : Font,
  scalar : Int,
) -> Result[GlyphId, @error.CoreError] {
  self.require_revision("font-query")?
  if !font_valid_scalar(scalar) {
    return Err(font_scalar_error(scalar))
  }
  let value = font_lookup_cmap(self.tables.cmap, scalar.to_uint64())?
  self.require_revision("font-query")?
  Ok({ value_value: value })
}
```

The actual MoonBit implementation should follow repository syntax rather than copying this sketch mechanically. [ASSUMED]

### Deterministic Lower-Bound Binary Search

```moonbit
// Source: OpenType sorted format-12 groups; design sketch.
let mut low = 0UL
let mut high = facts.group_count
while low < high {
  let mid = low + (high - low) / 2UL
  let start = read_group_start(facts, mid)?
  if start <= scalar {
    low = mid + 1UL
  } else {
    high = mid
  }
}
if low == 0UL {
  return Ok(0UL)
}
let index = low - 1UL
// Read admitted start/end/startGlyph, test containment, then checked-add offset.
```

Use `high - low` rather than `low + high` for midpoint calculation even though admitted counts are bounded. [ASSUMED]

### Kern Pair Key

```moonbit
// Source: OpenType kern format 0.
fn font_kern_pair_key(left : UInt64, right : UInt64) -> UInt64 {
  (left << 16) | right
}
```

Both values have already been proven below the font's 16-bit `numGlyphs` domain before key construction. [VERIFIED: `maxp`/`GlyphId` implementation]

## Verification Strategy

`workflow.nyquist_validation` is explicitly `false`, so the formal `Validation Architecture` section is intentionally omitted. [VERIFIED: `.planning/config.json`]

Use the following implementation verification layers:

| Layer | Command / location | Required evidence |
|-------|--------------------|-------------------|
| Fast compile | `moon -C modules/mb-font check --target native --frozen` | Private type/function integration. [VERIFIED: installed CLI and module manifest] |
| Public/private tests | `moon -C modules/mb-font test --target native --frozen` | Cmap/kern semantic and hostile micro-font cases. [VERIFIED: existing test layout] |
| Four-target package gate | `moon -C modules/mb-font check --target all --frozen` then `moon -C modules/mb-font test --target all --frozen` | Identical behavior on `js`, `wasm`, `wasm-gc`, native. [VERIFIED: package target contract] |
| Interface regeneration | `moon -C modules/mb-font info --target all --frozen` | Only two new Font queries plus required `FontLimits` changes appear. [VERIFIED: existing generated interface policy] |
| Policy gate | `pwsh -File scripts/quality/Assert-Policy.ps1 -PolicyPath policy/foundation.json` using the script's supported invocation | Inventory, imports, source order, README, and exact interface remain closed. [VERIFIED: script inspection] |
| Workspace gate | `moon check --target all --frozen` and `moon test --target all --frozen` | No downstream regression. [VERIFIED: stack policy] |

The research-time 60-second probes of the module `check/test` commands did not complete and were terminated by exact process ID; the tools are installed, but the planner should not assume the four-target lane is a sub-30-second task. [VERIFIED: environment probe]

### Required Public Cases

- BMP format-4 direct delta hit, glyph-array hit, raw-array zero miss, hole miss, and U+FFFF behavior. [VERIFIED: D-15; CITED: OpenType cmap]
- format-12 BMP and supplementary hits, gap misses, first/last group boundaries, and format-12 precedence. [VERIFIED: D-15]
- canonical record ranks, same-offset aliases, duplicate same-priority record-key rejection, lower-ranked disagreement ignored after winner selection, legacy-only capability failure, and no per-scalar fallback. [RESOLVED: D-05–D-07a, D-15]
- negative, surrogate endpoints/interior, `0x110000`, valid noncharacters/unassigned values, and ordinary valid misses. [VERIFIED: D-01; CITED: Unicode D76]
- kern absent, empty supported pair set, first/middle/last pair hit, pair miss, positive/negative adjustment, foreign-font glyph IDs, and mutation drift. [VERIFIED: D-09, D-15]
- classic OpenType, exact Apple-v1, and unknown-version classifier boundaries; unsupported coverage/format/multiple-subtable states versus malformed envelope/length/search/order/duplicate/out-of-range pair data. [RESOLVED: D-08–D-11, D-15; CITED: OpenType 1.9.1 kern and Apple TrueType Reference Manual kern]
- exact optional-directory-record scan, `max_kern_subtables`, `max_kern_pairs`, `max_work`, and budget fits plus one-short atomic rejection and unchanged query budget. [RESOLVED: D-13–D-15]

### Required White-Box Cases

- rank function values and rejection of all noncanonical domains; [VERIFIED: D-05, D-16]
- format-4 array base math and binary-search lower-bound edges; [VERIFIED: D-16]
- format-12 group midpoint/first/last/miss behavior; [VERIFIED: D-16]
- kern exact-length arithmetic, canonical helper fields at 0/1/non-power-of-two/power-of-two counts, strict key order, and signed FWORD decode; [VERIFIED: D-11, D-16; CITED: OpenType kern]
- stable category/code/context separation for invalid input, data, capability, state mutation, and resource exhaustion. [VERIFIED: D-10, D-16]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not explicitly disable it. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity/authentication boundary in this pure library phase. [VERIFIED: phase scope] |
| V3 Session Management | no | No sessions or persistent authority state. [VERIFIED: phase scope] |
| V4 Access Control | no | Caller-provided values have no authorization semantics. [VERIFIED: phase scope] |
| V5 Input Validation | yes | Checked table-local ranges/arithmetic, strict scalar domain, glyph revalidation, sorted/unique records, semantic ceilings. [VERIFIED: code and decisions] |
| V6 Cryptography | no | SFNT checksums are integrity fields, not cryptographic trust. [VERIFIED: existing checksum implementation and phase scope] |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Count/offset overflow leading to out-of-bounds reads | Tampering / DoS | `CheckedRange`, checked arithmetic, exact contained lengths before reads. [VERIFIED: existing parser pattern] |
| Huge segment/pair counts causing CPU exhaustion | DoS | Non-zero semantic ceilings plus budget preflight before loops. [VERIFIED: D-13] |
| Crafted search helper fields steering unsafe navigation | Tampering | Validate canonical values but derive navigation from counts. [CITED: OpenType cmap; VERIFIED: D-11] |
| Duplicate/unsorted mapping or pair keys creating ambiguous lookup | Tampering | Strict ordering and uniqueness at admission. [VERIFIED: D-07, D-11] |
| Source mutation between validation and result publication | Tampering | Pre- and post-read mutation revision guards. [VERIFIED: D-03, existing `Font`] |
| Unsupported data treated as neutral success | Spoofing / Tampering | Retained unsupported state and capability error. [VERIFIED: D-10a] |
| Cross-font opaque glyph reuse | Tampering | Revalidate both glyph numeric values against receiving `Font`. [VERIFIED: D-09, Phase 97 pattern] |

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Use any first cmap record | Select one Unicode subtable consistently; prefer 32-bit format 12 over 16-bit format 4. [CITED: OpenType cmap] | Deterministic supplementary-plane behavior. |
| Treat stored search helpers as navigational authority | Derive search bounds from counts; stored values remain compatibility validations. [CITED: OpenType cmap] | Removes a documented attack vector. |
| Legacy kern as general text shaping | GPOS is preferred for modern/variable typography; this phase exposes only a scoped legacy pair query. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/recom] | Keeps shaping and variation policy out of `mb-font`. |

**Deprecated/outdated for this phase:**

- Unicode platform encoding IDs 0, 1, and 2 and ISO platform records are deprecated and must not become the canonical mapping. [CITED: OpenType cmap; VERIFIED: D-05]
- Macintosh cmap records are discouraged on current Apple platforms and are not canonical here. [CITED: OpenType cmap; VERIFIED: D-05]
- Kern format 2, Apple extensions, and GPOS are outside the locked basic profile. [VERIFIED: D-08, deferred scope]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Suggested method names and code sketches compile after adjustment to current MoonBit syntax. | Code Examples | Names are discretionary; planner must use `moon check` and regenerate `.mbti`. |

## Resolved Questions

1. **RESOLVED — exact byte-level boundary for classic OpenType, Apple v1, and unknown `kern` versions.**
   - Classic OpenType uses the complete structural pass described in Pattern 3: 4-byte header, preflighted `nTables`, contained 6-byte headers, `length >= 6`, checked cumulative ends, and exact final exhaustion before profile classification. Structural failure is `Data`; a valid profile outside the single supported subtable is cached `Unsupported`.
   - Exact Apple `0x00010000` uses an 8-byte header, bounded/preflighted `uint32 nTables`, contained 8-byte subtable headers, `uint32 length >= 8`, checked cumulative ends, and exact final exhaustion. Structural failure is `Data`; structural success is cached `Unsupported`, without parsing Apple format bodies.
   - Other complete nonzero/unknown 4-byte prefixes are cached `Unsupported` without attacker-driven traversal; fewer than 4 bytes is `Data`. [RESOLVED: D-08, D-10, D-10a; CITED: Apple TrueType Reference Manual kern; OpenType 1.9.1 kern]

2. **RESOLVED — D-06 consistency scope is the winning priority only.**
   - Validate every supported record and select by the frozen D-05 rank. Record-key uniqueness rejects a second distinct same-priority record before selection, while aliased offsets are one mapping. Lower-ranked records are never consulted or compared semantically, and queries never perform per-scalar fallback. No cross-map equality pass is required. [RESOLVED: D-04 through D-07]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | checks/tests/info | ✓ | `0.1.20260713` | — [VERIFIED: local probe] |
| `moonc` | compilation | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local probe] |
| `moonrun` | test execution | ✓ | `0.1.20260713` | — [VERIFIED: local probe] |
| PowerShell 7 | repository quality scripts | ✓ | installed at `C:\Program Files\PowerShell\7\pwsh.exe` | — [VERIFIED: local probe] |
| Git | phase commits/state | ✓ | installed | — [VERIFIED: local probe] |
| External font/package tooling | implementation | not required | — | generated MoonBit fixtures [VERIFIED: phase scope] |

**Missing dependencies with no fallback:** none. [VERIFIED: local probe]

**Missing dependencies with fallback:** none. [VERIFIED: local probe]

## Sources

### Primary Repository Evidence (HIGH confidence)

- `98-CONTEXT.md` — all locked behavior, resource, verification, and scope decisions.
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — FONT-02/FONT-04 and success criteria.
- `modules/mb-font/font/{font,tables,directory,limits,cursor,metrics}.mbt` — retained-source, admission, cmap validation, optional-table seam, errors, limits, and signed reads.
- `modules/mb-font/font/{font_test,font_wbtest,generated_fonts_wbtest}.mbt` — current builders and test conventions.
- `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` — exact publication and semantic-interface gates.
- `docs/rfcs/0004-mb-font.md` — font/text boundary and scoped cmap/kern ownership.

### Official External Documentation (MEDIUM confidence via research seam)

- https://learn.microsoft.com/en-us/typography/opentype/spec/cmap — header/record selection, platform IDs, formats 4/12, glyph-zero misses, ordering, indexing, and search-field guidance.
- https://learn.microsoft.com/en-us/typography/opentype/spec/kern — OpenType 1.9.1 version-0 envelope, coverage bits, format-0 fields, pair key order, signed font-unit values, and explicit non-support for Apple extensions.
- https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6kern.html — Apple TrueType Reference Manual `kern` version `0x00010000`, 32-bit table count, and Apple subtable-header envelope.
- https://learn.microsoft.com/en-us/typography/opentype/spec/recom — current relationship of legacy kern and GPOS/variations.
- https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/ — D76 Unicode scalar value.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — installed versions and repository manifests inspected directly.
- Architecture: HIGH — exact Phase 97 functions/types and locked Phase 98 decisions inspected directly.
- Normative cmap/kern details: MEDIUM — current official Microsoft OpenType 1.9.1 pages fetched through websearch fallback and cached by the research seam.
- Unicode scalar definition: MEDIUM — official Unicode 17.0 chapter fetched and cached by the research seam.
- Apple-extension classification boundary: HIGH — exact envelope-only boundary is resolved from the Apple TrueType Reference Manual and OpenType 1.9.1, without implementing Apple format bodies.

**Research date:** 2026-07-27
**Valid until:** 2026-08-26 for repository architecture; recheck official spec pages if the project changes its OpenType/Unicode baseline.
