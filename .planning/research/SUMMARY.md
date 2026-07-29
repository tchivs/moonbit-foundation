# Project Research Summary

**Project:** MoonBit Native Foundation v0.35 Text Shaping Foundation
**Domain:** Bounded, deterministic, single-font horizontal OpenType text shaping
**Researched:** 2026-07-30
**Confidence:** MEDIUM

## Executive Summary

v0.35 should add the first independently publishable `tchivs/mb-text` vertical slice over the already-qualified opaque `tchivs/mb-font::Font`. The product is not a general multilingual shaping engine: it is a pure-MoonBit, four-target operation that accepts one admitted static `glyf` or CFF1 font, caller-supplied Unicode scalars, explicit OpenType script/language/direction/feature choices, explicit limits, and one authoritative budget, then atomically returns an immutable run of opaque glyph IDs, scalar-origin clusters, signed design-unit advances, and x/y offsets. Binary ownership and OpenType parsing remain in `mb-font`; string sequencing, feature policy, direction, clusters, and the public run remain in `mb-text`.

The optimal closed profile is slightly wider than the nominal minimum in [FEATURES.md](FEATURES.md) and [ARCHITECTURE.md](ARCHITECTURE.md), but it does not widen shaping semantics. In addition to GSUB 1/4 and GPOS 2, v0.35 should admit one-hop GSUB 7 and GPOS 9 extension wrappers only when they dispatch to those admitted inner types, plus GDEF 1.0 `GlyphClassDef` and the three class-based ignore flags. This is required to qualify the retained Source Sans 3.052R CFF1 specimen, whose ordinary Latin GPOS `kern` path uses a type-9 wrapper and `IGNORE_MARKS`. Deferring those mechanics would force either a generated-only claim, replacement of the strongest retained CFF1 evidence, or a misleading “licensed interoperability” result. Extension wrappers add address width, not a new shaping operation; GDEF glyph-class filtering adds traversal semantics, not mark attachment.

The principal risks are plausible-but-wrong success, attacker-controlled offset/work amplification, and loss of atomic budget/source authority. Mitigate them by failing closed on every selected unsupported path, retaining request-specific normalized layout facts behind an opaque transactional `mb-font` seam, applying lookups in LookupList order, keeping all execution in logical order, using checked `Int64` design-unit arithmetic, and committing the combined parser/executor/output charge exactly once after the final source-revision guard. The four-phase architecture sketch should therefore be refined into six phases, 108–113, so admission, GSUB, GPOS, transaction hardening, and qualification receive separate exit evidence.

## Key Decisions

| Decision | Selected policy | Why this is the best closed option |
|---|---|---|
| Module ownership | New `tchivs/mb-text@0.1.0`; layout parsing and source authority stay in `tchivs/mb-font@0.1.0` | Preserves RFC 0004/0005 ownership, acyclic dependencies, opaque `Font`, and outline-format neutrality |
| Cross-module seam | Request-scoped opaque transactional profile/continuation, not raw-table access or a public persistent cache | Permits one combined budget commit and one final source guard without exposing offsets, bytes, lookup indices, or mutable state |
| Public feature policy | Closed booleans for `liga` and `kern`; required LangSys feature and supported `rlig` are non-disableable | Keeps the claim reviewable and prevents arbitrary feature tags from smuggling unsupported script behavior into v0.35 |
| Script/language selection | Exact caller-supplied script, including explicit `DFLT`; `LanguageChoice::Default` selects only DefaultLangSys and `Exact(tag)` never silently falls back | Matches the milestone's explicit-input contract and removes hidden locale/script fallback policy |
| Layout profile | GSUB 1/4 plus 7→1/4; GPOS 2 plus 9→2; common Coverage/ClassDef; GDEF 1.0 glyph classes and class-ignore flags | Smallest profile that closes generated `glyf`/CFF1 and retained Source Sans CFF1 qualification without adding contextual, mark-attachment, or complex-script semantics |
| Unsupported paths | Selected unsupported/malformed/resource-exhausting paths fail atomically; unselected richer tables do not reject the font | Avoids both false success and over-rejection of ordinary fonts containing unrelated advanced layout data |
| Numeric model | Checked `Int64` design-unit accumulators and public values; checked `UInt64` counts/offsets/work until limited narrowing | Exact on all targets and independent of ppem, floats, hinting, or renderer state |
| Clusters | Zero-based source scalar index; a ligature receives the minimum index of consumed components | Stable provenance without claiming grapheme, byte-offset, caret-stop, bidi-level, or fallback-span semantics |
| Direction | Shape logical input; LTR publishes logical order, RTL reverses only the final records into pen order; advance is a signed pen delta | Prevents the common “reverse and shape as LTR” error and gives downstream consumers one explicit drawing contract |
| Kerning authority | A selected supported GPOS `kern` plan is authoritative for the whole run; otherwise use legacy `kern`; `kern=false` disables both | Prevents double kerning and prevents malformed modern data from being hidden by legacy fallback |
| Qualification authority | Hand-derived generated facts are normative for the closed profile; pinned `hb-shape` is an independent licensed-font comparison only | A foreign engine cannot silently redefine production semantics |

## Key Findings

### Recommended Stack

Production remains pure MoonBit and keeps the existing pinned toolchain. No HarfBuzz, ICU, FreeType, fontTools, C/C++, JavaScript, platform shaper, host font lookup, or FFI is a runtime dependency.

**Core technologies:**

- `moon 0.1.20260713` / `moonc v0.10.4+2cc641edf` / paired `moonrun` — preserve the exact v0.34 four-target baseline throughout the milestone.
- `tchivs/mb-core@0.1.0` — checked arithmetic, `CoreError`, hierarchical budgets, retained-byte mutation guards, and checked aggregate `ResourceCharge`.
- `tchivs/mb-font@0.1.0` — existing opaque `Font`, cmap, glyph identity, metrics, legacy `kern`, retained source authority, and new opaque layout transaction.
- `tchivs/mb-text@0.1.0` — new user-facing shaping options, limits, positioned-run model, sequencing, clusters, direction, and atomic `shape`.
- OpenType 1.9.1 — normative table, ordering, lookup, GDEF, GSUB, GPOS, and legacy-kern behavior.
- Unicode scalar rules — scalar admission only; the existing Unicode 15.1 data pin does not need to change because script, language, and direction are explicit and normalization/bidi/segmentation are excluded.
- fontTools 4.63.0 — host-only deterministic fixture generation and structural inspection.
- HarfBuzz 14.2.1 `hb-shape` — host-only semantic comparison for the exact admitted projection, with archive, executable, adapter, invocation, input, and output digests pinned.

The production dependency graph is:

```text
tchivs/mb-text@0.1.0 ──> tchivs/mb-font@0.1.0 ──> tchivs/mb-core@0.1.0
           └────────────────────────────────────> tchivs/mb-core@0.1.0
```

Retain `moon.mod.json` for this milestone and support `js`, `wasm`, `wasm-gc`, and `native` at both module and public-package boundaries.

### Recommended Closed Layout Profile

#### Common layout admission

- Accept GSUB/GPOS version 1.0.
- Accept version 1.1 only when `FeatureVariationsOffset == 0`; non-null feature variations are `CapabilityUnavailable`.
- Parse bounded ScriptList, LangSys, FeatureList, LookupList, Coverage formats 1/2, and ClassDef formats 1/2 with exact offset-base, sortedness, uniqueness, cardinality, range, and glyph-ID checks.
- Select one exact script and one default/exact language system. Include the LangSys required feature, supported `rlig`, caller-enabled `liga`, and caller-enabled `kern`.
- Union and de-duplicate selected lookup indices, then execute each selected index once in ascending LookupList order. At one glyph position, test subtables in stored order and stop after the first match.
- Validate global envelopes enough to resolve selected structures safely, but reject advanced capability only when the selected/reachable path requires it.

#### GSUB

- Type 1 SingleSubst formats 1/2.
- Type 4 LigatureSubst format 1.
- Type 7 ExtensionSubst format 1 only as a single, checked 32-bit indirection to type 1 or type 4.
- No extension-to-extension recursion.
- Substitution outputs must be valid glyph IDs for the same `Font`.
- Ligatures match participating glyphs in logical/writing order, preserve filtered/skipped glyphs, consume only matched indices, and merge the consumed source interval to its minimum scalar index.
- Query `hmtx` only after all substitutions complete.

#### GPOS and legacy kerning

- Type 2 PairPos formats 1/2.
- Type 9 ExtensionPos format 1 only as a single, checked 32-bit indirection to type 2.
- Static `xPlacement`, `yPlacement`, and `xAdvance` ValueRecord fields for either glyph; zero ValueFormat is valid.
- Reject `yAdvance`, Device/VariationIndex offsets, reserved bits, contextual/cursive/mark attachment, and every other selected GPOS operation.
- PairPos format 1 requires Coverage cardinality and PairSet count agreement plus strictly ordered second-glyph records.
- PairPos format 2 requires valid ClassDef 1/2 facts, explicit class-0 handling, and checked `class1Count × class2Count × recordSize` preflight.
- Accumulate adjustments in LookupList order and follow the PairPos next-probe rule; never overwrite an earlier adjustment.
- Resolve modern-versus-legacy authority once per selected language-system plan, never per pair.

#### GDEF and lookup flags

- Admit only GDEF 1.0 `GlyphClassDef`; do not expose or retain mark attachment, ligature caret, attachment point, mark glyph set, or variation-store data.
- Support `IGNORE_BASE_GLYPHS`, `IGNORE_LIGATURES`, and `IGNORE_MARKS` using the validated class definition.
- Treat `RIGHT_TO_LEFT` as non-operative for the admitted lookup types; it does not select run direction.
- If an admitted ignore flag is selected but no usable GlyphClassDef exists, return deterministic malformed-data failure rather than inventing classes.
- Reject reserved flag bits, `USE_MARK_FILTERING_SET`, and non-zero mark-attachment-class filters as unsupported capability.

This resolves the research disagreement. The narrower `lookupFlag == 0` / “extension later” architecture is unsuitable for the retained Source Sans evidence. The selected wrapper/filter additions are bounded dispatch and traversal mechanics around already-admitted semantic operations, so they preserve the milestone's “complete but small” promise.

### Expected Features

**Must have (table stakes):**

- One explicit, deterministic, single-font horizontal `shape` operation in `mb-text`.
- Whole-array scalar validation, existing cmap reuse, glyph-zero preservation for valid misses, and an empty-run success contract.
- Opaque glyph IDs, scalar-origin clusters, signed design-unit advances/offsets, `units_per_em`, direction, and checked `total_advance`.
- Exact script/default-or-exact-language selection, required feature behavior, closed `rlig`/`liga`/`kern` policy, LookupList ordering, and first-matching-subtable behavior.
- The complete closed GSUB/GPOS/GDEF/extension profile above.
- Final-GID metrics and one unambiguous GPOS-versus-legacy kerning policy.
- Separate semantic limits for parser structure and shaping execution, plus caller/ancestor budget authority.
- Stable `InvalidInput`, `Data`, `Capability`, `Resource`, and `State` outcomes with a frozen multi-fault precedence matrix.
- One private transaction, final source-revision guard, one budget commit, and one immutable publication.
- Generated and licensed `glyf`/CFF1 evidence, hostile fixtures, v0.34 compatibility, and byte-equal canonical semantics on all four targets.

**Should have (differentiators):**

- Equivalent generated layout programs over `glyf` and CFF1 faces.
- Licensed DejaVu Sans and Source Sans evidence through the exact public route.
- Hand-derived micro-oracles plus a separately pinned HarfBuzz comparison.
- Canonical target-neutral evidence carrying inputs, selected options, outputs/errors, budget deltas, fixture/tool identities, and interface/toolchain identities.
- Observation-only native workloads after correctness is sealed.

**Defer beyond v0.35:**

- Arbitrary caller feature tags and larger feature policy.
- Multiple/alternate/contextual/chained/reverse substitutions.
- Contextual positioning, cursive and mark attachment, mark filtering sets, mark attachment classes, and GDEF data beyond glyph classes.
- Arabic/Syriac joining, Indic/Khmer/Tibetan reordering, and every full complex-script engine.
- Normalization, paragraph bidi, mirroring, script/language inference, grapheme segmentation, line layout, justification, rich text, fallback, discovery, and multi-font run merging.
- Vertical metrics/layout, device positioning, variables/FeatureVariations, WOFF/WOFF2, AAT/Graphite, color/bitmap/raster/hinting, authoring/subsetting, persistent caches, production FFI, and publication/stability promotion.

### Architecture Approach

`mb-font` should create one request-specific, immutable, bounded `FontLayoutProfile` inside a guarded continuation. That profile retains normalized selected lookup facts and exact private charges, applies supported layout operations to opaque glyph/source-interval seeds, and returns an opaque `FontLayoutOutcome`. `mb-text` validates options/scalars, owns clusters and direction, builds the private public-model value, and binds its exact text-side charge to the outcome. The font-owned harness combines profile, execution, and output charges; preflights caller and ancestors; checks the source revision; commits once; and only then returns the run. No profile persists across calls.

**Major components:**

1. `mb-core::ResourceCharge::checked_add` — immutable, overflow-checked composition needed for one whole-operation commit.
2. `mb-text::ShapingOptions` / `ShapeLimits` / `ShapedRun` — closed public contract with no locale, raw layout, font bytes, or rendering state.
3. `mb-font::FontLayoutSelection` / `FontLayoutProfile` — exact selected request, normalized common-layout/GDEF/GSUB/GPOS facts, and retained source identity.
4. Private common-layout parser — typed table windows and base-specific offset helpers; no bare global `base + offset` convention.
5. Private GSUB executor — logical seed buffer, class filtering, lookup/subtable order, matched-index ligatures, and source-interval propagation.
6. Private metrics/GPOS executor — final-GID metrics, PairPos, signed accumulation, and run-level legacy authority.
7. Transaction harness — stage guards, exact charge ledger, one final revision check, one commit, and one publication.
8. Qualification carrier — generated/licensed/hostile facts and identical four-target semantic payloads independent of native timing.

## Requirements Candidates

These candidates are ready for requirements definition; identifiers are proposed and may be renamed without changing scope.

| ID | Requirement candidate | Acceptance focus |
|---|---|---|
| TXT-01 | Library authors can shape one bounded scalar array with one admitted static `Font` and explicit script, language choice, horizontal direction, closed feature policy, limits, and budget. | Empty/non-empty, valid/missing cmap, exact input round-trip, no ambient state |
| TXT-02 | A successful immutable run exposes only same-font opaque glyphs, scalar-origin clusters, signed design-unit advances/x-y offsets, `units_per_em`, direction, and checked total advance. | LTR exact order; RTL pen order; ligature minimum cluster; no raw OpenType facts |
| LAY-01 | `mb-font` resolves and bounds one exact Script/LangSys/Feature/Lookup plan with canonical LookupList ordering. | Exact script; explicit `DFLT`; default/exact language; required feature; de-duplication; first matching subtable |
| LAY-02 | Selected layout paths support Coverage 1/2, ClassDef 1/2, GDEF 1.0 glyph classes, class-ignore flags, and one-hop GSUB/GPOS extension wrappers to admitted inner types. | Source Sans path, 32-bit offset tests, missing GDEF, skipped-glyph preservation, recursion rejection |
| SUB-01 | Selected GSUB type 1 formats 1/2 and type 4 format 1 execute deterministically in logical order under the closed profile. | Modulo delta, explicit replacements, ligature preference, matched-index consumption, output GID validation, final-GID metrics |
| POS-01 | Selected GPOS type 2 formats 1/2 applies the closed static ValueRecord subset with checked accumulated results. | PairSet ordering/cardinality, class 0/matrix bounds, both glyph records, next-probe rule, overflow/limit tests |
| KRN-01 | Kerning uses one run-level authority decision: selected supported GPOS `kern`, otherwise legacy format-0 fallback, or neither when disabled. | No double application, no per-pair fallback, malformed/unsupported GPOS never degrades silently |
| SAF-01 | Malformed, unsupported, over-limit, over-budget, or mutated shaping fails with stable structured outcomes and no partial run or partial caller/ancestor charge. | Exact/one-short every dimension, multi-fault precedence, mutation at each frozen stage, success commits once |
| CMP-01 | v0.35 preserves existing `Font` admission, cmap, metrics, legacy-kern query, outline, collection, CFF1, module dependency, and public-interface behavior except the intentional opaque additive seam. | Frozen v0.34 regression and reviewed API/dependency diffs |
| QUA-01 | Maintainers can reproduce hand-derived generated, pinned licensed, hostile, compatibility, and equal four-target shaping evidence without a foreign production dependency. | Equivalent `glyf`/CFF1, DejaVu/Source Sans, pinned oracle, canonical records, byte-equal semantic hashes |

## Implications for Roadmap

The four broad phases proposed by FEATURES/ARCHITECTURE should be expanded to six. The mapping is:

| Broad architecture phase | Refined roadmap |
|---|---|
| 108 — contract and bounded selection | 108 contract/transaction skeleton + 109 bounded layout admission |
| 109 — GSUB | 110 GSUB |
| 110 — GPOS/kerning | 111 GPOS/kerning |
| Cross-cutting atomicity inside 108–110 | 112 integrated transaction/resource/mutation hardening |
| 111 — qualification | 113 qualification |

This is not scope expansion. It isolates the exact parser, executor, and authority risks identified by PITFALLS and gives each a reviewable exit artifact.

### Phase 108: Public Contract and Transaction Skeleton

**Rationale:** Public run/direction/cluster semantics and one-commit ownership are expensive to change after parser/executor code exists.
**Delivers:** `mb-text` module skeleton; typed tags, language choice, direction, feature policy, limits, positioned-run model; `ResourceCharge` composition; opaque `mb-font` continuation/outcome shape; error taxonomy and stage precedence; generated API-contract fixtures.
**Addresses:** TXT-01, TXT-02 foundations and the architectural part of SAF-01.
**Avoids:** Raw-table leakage, module cycles, two budget commits, ambiguous RTL/cluster promises, and premature persistent caching.
**Exit condition:** The public numeric/order contract and transaction ownership are frozen; a private value can be prepared and either atomically published after one combined commit or discarded without authority change.

### Phase 109: Bounded Layout Admission

**Rationale:** Every later executor depends on correct table-local windows, selection, filtering metadata, and normalized selected facts.
**Delivers:** GSUB/GPOS header 1.0/closed 1.1 admission; Script/LangSys/Feature/Lookup selection; Coverage/ClassDef; GDEF 1.0 glyph classes; supported flags; GSUB 7/GPOS 9 one-hop extension dispatch; semantic ceilings; source-stage guards; selected-versus-unselected validation depth; hostile offset/cardinality fixtures.
**Addresses:** LAY-01 and LAY-02.
**Avoids:** Wrong relative-offset bases, unchecked count products, missing GDEF dependencies, recursion, over-validation of unrelated rich tables, and silent selected-capability skipping.
**Exit condition:** Every admitted field has an offset-base ledger, validation rule, limit/work charge, exact/one-short fixture, and stable error context; retained profiles expose no raw table data.

### Phase 110: Deterministic GSUB and Source Clusters

**Rationale:** Substitution changes glyph identity and must complete before metrics or positioning.
**Delivers:** Whole-array scalar preflight, existing cmap reuse, logical seed intervals, GSUB 1/4/7 execution, class filtering, LookupList/subtable/ligature preference, matched-index consumption, LTR/RTL logical execution and final order, final-GID metric initialization.
**Addresses:** SUB-01 and the substitution/cluster portions of TXT-01/TXT-02.
**Avoids:** Caller-order lookup execution, early RTL reversal, deletion of skipped marks, stale metrics, invalid substitute GIDs, and conflation of source clusters with graphemes.
**Exit condition:** Generated LTR/RTL single/ligature cases freeze exact glyph order, clusters, metrics, probe counts, and capability failures, including intervening ignored marks.

### Phase 111: Pair Positioning and Kerning Authority

**Rationale:** Positioning depends on the final glyph stream and is the densest numeric/table-shape portion of the profile.
**Delivers:** GPOS 2/9, PairPos 1/2, ValueRecord decoding, ClassDef/class-0 matrices, next-probe behavior, checked accumulated placement/advance, signed pen deltas, total advance, and run-level GPOS/legacy authority.
**Addresses:** POS-01 and KRN-01; completes TXT-02 semantics.
**Avoids:** Matrix overflow, wrong pair scan advancement, adjustment overwrite, target-dependent narrowing, and GPOS-plus-legacy double application.
**Exit condition:** Hand-derived explicit/class pair cases, zero formats, both-glyph ValueRecords, overflow boundaries, LTR/RTL signs, and modern/legacy coexistence all have exact expected facts.

### Phase 112: Integrated Transaction, Resource, and Mutation Hardening

**Rationale:** Structural bounds do not bound shaping work, and local parser/executor success is not independently committable.
**Delivers:** Complete work equation and exact aggregate charge; caller/ancestor exact-fit and one-short matrices; source mutation probes across admission/GSUB/metrics/GPOS/final publication; stable multi-fault precedence; one complete private run; one final source guard; one commit; one publication; compatibility/API dependency gates.
**Addresses:** SAF-01 and CMP-01.
**Avoids:** Hidden quadratic work, partial charges, stale publication, traversal-dependent errors, and regressions in existing opaque `Font` behavior.
**Exit condition:** Every failure path leaves output and all budget ancestors unchanged, every success charges once, and the complete current v0.34 successor regression passes.

### Phase 113: Interoperability and Four-Target Qualification

**Rationale:** Licensed/oracle evidence is authoritative only after the exact public transaction and capability profile are closed.
**Delivers:** Equivalent generated `glyf`/CFF1 and standalone/collection fixtures; retained DejaVu Sans and Source Sans cases; pinned fontTools/HarfBuzz adapters and manifests; canonical hostile carrier; identical `js`/`wasm`/`wasm-gc`/`native` semantic records; observation-only native workload.
**Addresses:** QUA-01 and final milestone proof.
**Avoids:** Oracle-defined semantics, repacked/unlicensed fixture drift, widening production to satisfy a convenient font, and equating equal test counts with equal behavior.
**Exit condition:** Source Sans exercises the admitted extension/GDEF path, every artifact and license is digest-bound, and the four normalized semantic payloads are byte-identical.

### Phase Ordering Rationale

- Contract and transaction ownership precede binary work because run order, numeric signs, clusters, error classes, and one-commit authority are public compatibility decisions.
- Admission precedes execution because normalized selected facts are the only safe input to GSUB/GPOS.
- GSUB precedes metrics and GPOS because substitutions change glyph identity.
- GPOS and legacy authority land together because separating them invites double application or per-pair fallback.
- Full work/budget/mutation integration receives its own phase because parser limits alone cannot bound execution cross-products.
- Licensed/oracle/four-target qualification comes last and must not redefine the closed production profile.

### Research Flags

Phases requiring deeper research during planning:

- **Phase 108:** verify MoonBit generic continuation/export ergonomics; freeze the signed RTL pen-delta projection with hand-derived cases; freeze empty-input validation/charge behavior and the complete stage precedence matrix.
- **Phase 109:** enumerate every offset base, cardinality relation, sortedness rule, selected/unselected validation depth, GDEF absence outcome, and 32-bit extension bound.
- **Phase 111:** freeze the complete allowed ValueFormat mask, both-glyph application, PairPos next-probe rule in both directions, and class-0 matrix semantics.
- **Phase 112:** derive the work/bytes/allocations/allocation-size ledger from actual loops and retained representations; do not reuse CFF limits mechanically.
- **Phase 113:** inspect and bind the exact Source Sans selected path, provision and hash the extracted HarfBuzz executable, select explicit cluster/shaper/output options, and close every license/provenance field before recording a baseline.

Phase with sufficiently standard patterns to skip a separate research pass:

- **Phase 110:** once Phases 108–109 freeze direction, lookup ordering, filtering, and normalized facts, SingleSubst/LigatureSubst execution is directly specified and should proceed from generated executable cases rather than another broad research cycle.

## Critical Risks and Mitigations

1. **Wrong relative-offset base or narrowed range** — use typed table-local windows and base-specific helpers; keep offsets/counts in checked `UInt64`; test sibling/header/non-contiguous/overflow/one-short destinations, including extension offsets above `0xFFFF`.
2. **Plausible success after wrong ordering or unsupported behavior** — select features first, union/deduplicate lookup indices, execute LookupList order, honor stored subtable preference, and fail every selected unsupported path without legacy/best-effort fallback.
3. **Incorrect filtering, ligature consumption, or cluster provenance** — validate GDEF classes, traverse through ignored glyphs with matched-index lists, delete only participating components, and freeze scalar-origin clusters for combining/repeated/supplementary/RTL cases.
4. **PairPos and signed arithmetic errors** — validate PairSet/Coverage equality, strict second-glyph order, class-0 bounds, checked matrix extent, allowed bits, next-probe behavior, and every accumulated `Int64` result.
5. **Unbounded execution despite bounded tables** — separate parser and executor limits; charge failed probes, filtered skips, lookup applications, binary-search steps, compaction, metrics, and positioning; preflight cross-products explicitly.
6. **Partial authority or stale publication** — retain all profile/run facts privately, compose charges immutably, check source revision at frozen stages and immediately before commit, charge caller and ancestors once, then publish once.
7. **Oracle or fixture drift** — keep hand-derived generated facts normative, use direct pinned `hb-shape` only as comparison, record every tool/adapter/argument/input/output digest, and preserve font licenses beside exact bytes.
8. **False complex-script claim** — describe the product as a Latin-style closed lookup profile, not general OpenType or multilingual shaping; selected deferred script stages return capability failure.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Production stack and dependency graph | HIGH | Accepted local RFC boundaries, current manifests, and the shipped four-target toolchain directly establish the module design |
| Toolchain and runtime portability | HIGH | Exact MoonBit identities and target lanes already underpin v0.34 qualification |
| Closed OpenType profile | MEDIUM | Official OpenType 1.9.1 is authoritative and research agrees on the core; extension/GDEF inclusion resolves the licensed-fixture disagreement but still needs exact selected-path fixtures |
| Public features and exclusions | HIGH | PROJECT.md and MILESTONE-CONTEXT.md explicitly define the single-font horizontal slice and exclusions |
| Architecture and transaction model | MEDIUM | Strongly grounded in shipped MNF budget/mutation patterns; exact MoonBit continuation syntax and allocation accounting remain implementation questions |
| RTL order and numeric semantics | MEDIUM | The recommended pen-order/signed-delta contract is coherent and oracle-compatible, but must be frozen with hand-derived cases before implementation |
| Pitfalls and security/resource model | MEDIUM-HIGH | Risks recur across normative layout structure and existing MNF hostile-input experience; exact work coefficients depend on final loops |
| Licensed/oracle qualification | MEDIUM | Retained font/tool identities are known; extracted executable digest, exact Source Sans selected path, and canonical oracle options remain to be locked |

**Overall confidence:** MEDIUM

### Gaps to Address

- **MoonBit continuation ergonomics:** preserve the semantic one-commit transaction even if the generic `PreparedLayout[T]` syntax/API shape must change in Phase 108.
- **RTL signed-delta fixture:** validate the recommended negative RTL pen-advance convention and GPOS adjustment sign with hand-derived generated cases before public API freeze.
- **Source Sans reachability:** confirm the exact script/language/feature selection reaches only GPOS 9→2 plus admitted flags; do not infer complete coverage from table presence.
- **GDEF absence category:** planning must freeze whether an admitted ignore flag without usable GlyphClassDef is reported as malformed `Data` (recommended) and bind exact diagnostics.
- **Exact allocation representation:** bytes/allocation counts and maximum allocation size depend on whether Coverage/ClassDef/pair facts are compact arrays or alternate bounded structures.
- **Oracle provisioning:** the official archive is pinned in research, but the extracted `hb-shape` digest and complete invocation identity must be recorded after provisioning.
- **Layout 1.1 hostile matrix:** enumerate null versus non-null FeatureVariations offsets and ensure selected/unselected variable behavior never widens v0.35.
- **Performance representation:** no cache or target-specific optimization should be chosen until Phase 112 closes charged complexity and Phase 113 closes semantic evidence.

## Sources

### Primary Standards and Official Documentation

- [OpenType 1.9.1 specification index](https://learn.microsoft.com/en-us/typography/opentype/spec) — normative layout tables and version.
- [OpenType layout common table formats](https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2) — Script/LangSys/Feature/Lookup order, flags, Coverage, ClassDef, and offset relationships.
- [OpenType GSUB](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub) — single, ligature, extension, and logical-order behavior.
- [OpenType GPOS](https://learn.microsoft.com/en-us/typography/opentype/spec/gpos) — PairPos, ValueRecords, extension, accumulation, and pair traversal.
- [OpenType GDEF](https://learn.microsoft.com/en-us/typography/opentype/spec/gdef) — glyph classes and lookup filtering.
- [OpenType recommendations](https://learn.microsoft.com/en-us/typography/opentype/spec/recom) — modern GPOS versus legacy `kern` guidance.
- [Unicode 17 core specification, Chapter 3](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/) — scalar-value definition.
- [UAX #9](https://www.unicode.org/reports/tr9/), [UAX #24](https://www.unicode.org/reports/tr24/), and [UAX #29](https://www.unicode.org/reports/tr29/) — bidi, script-property, and grapheme boundaries that v0.35 does not infer.
- [MoonBit 0.10.4 release](https://www.moonbitlang.com/updates/2026/07/13/moonbit-0-10-4-release) and [MoonBit toolchain documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — pinned compiler/tool and target behavior.
- [fontTools 4.63.0 release](https://github.com/fonttools/fonttools/releases/tag/4.63.0) — host-only fixture/inspection identity.
- [HarfBuzz 14.2.1 release](https://github.com/harfbuzz/harfbuzz/releases/tag/14.2.1), [shaping API](https://harfbuzz.github.io/harfbuzz-hb-shape.html), and [cluster behavior](https://harfbuzz.github.io/working-with-harfbuzz-clusters.html) — host-only semantic comparison and explicit cluster/direction controls.

### Local Project Authorities

- [PROJECT.md](../PROJECT.md) — current v0.35 goal, active requirements, constraints, and v0.34 compatibility baseline.
- [MILESTONE-CONTEXT.md](../MILESTONE-CONTEXT.md) — selected vertical slice, explicit exclusions, and carried-forward safety/portability constraints.
- [STACK.md](STACK.md) — exact toolchain, module graph, optimal extension/GDEF profile, numeric model, and qualification tool identities.
- [FEATURES.md](FEATURES.md) — table stakes, user-visible acceptance, feature interactions, anti-features, and initial four-phase proposal.
- [ARCHITECTURE.md](ARCHITECTURE.md) — opaque transactional seam, ownership boundaries, data flow, limits, and initial four-phase build order.
- [PITFALLS.md](PITFALLS.md) — ranked semantic/parser/resource/qualification risks and the refined 108–113 phase separation.
- `docs/rfcs/0004-mb-font.md` and `docs/rfcs/0005-mb-text.md` — accepted module ownership and dependency boundaries.
- Existing `modules/mb-core`, `modules/mb-font`, retained licensed fixture manifests, and v0.34 qualification artifacts — shipped implementation and evidence patterns.

---
*Research completed: 2026-07-30*
*Ready for requirements: yes*
*Ready for roadmap: yes*
