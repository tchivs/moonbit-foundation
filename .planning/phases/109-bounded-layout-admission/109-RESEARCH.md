# Phase 109: Bounded Layout Admission - Research

**Researched:** 2026-07-30
**Domain:** Bounded OpenType 1.9.1 GSUB/GPOS/GDEF admission in MoonBit
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Binary windows, offsets, and validation depth

- **D-01:** Reduce every GSUB/GPOS/GDEF source to a checked table-local window. Keep offsets/products as `UInt64`; narrow only after range and semantic-limit proof.
- **D-02:** Freeze field-specific bases: layout-list offsets use the layout start; ScriptRecord uses ScriptList; LangSys offsets use selected Script; FeatureRecord uses FeatureList; FeatureParams use selected Feature; lookup offsets use LookupList; subtable offsets use selected Lookup; Coverage/ClassDef/PairSet/LigatureSet use the owning subtable; Ligature offsets use the owning LigatureSet; GDEF GlyphClassDef uses GDEF start; extension offsets use the extension-subtable start. — **Reversibility:** costly — changing a base rewrites hostile fixtures and can reinterpret sibling bytes.
- **D-03:** Offset16/32 resolution is checked `base + offset`, minimum target width, and complete target-window validation. Zero is legal only for explicitly nullable fields.
- **D-04:** Validate global list arrays, tag order/uniqueness, count extents, and immediate child envelopes; deep-decode only selected Script/LangSys/features/lookups/subtables and selected dependencies.
- **D-05:** Invalid offsets in global Script/Feature/Lookup records are `Data` even when unselected; valid unselected advanced bodies are not capability-checked.
- **D-06:** Admit GSUB/GPOS 1.0 and 1.1 only when FeatureVariations is null. For non-null FeatureVariations, validate Offset32 and minimum envelope; malformed is `Data`, structurally valid is `CapabilityUnavailable`.

### Script, language, feature, lookup, and subtable selection

- **D-07:** Absent GSUB/GPOS is neutral. In a present table the exact Script must exist; no implicit `DFLT` fallback.
- **D-08:** `Default` selects only non-null DefaultLangSys; `Exact(tag)` selects only the exact LangSys record. Neither falls back to the other.
- **D-09:** ScriptRecords, LangSysRecords, and FeatureRecords are strictly tag-sorted and unique; `lookupOrderOffset` is zero; feature indices are in range and duplicate feature indices are malformed `Data`.
- **D-10:** Required FeatureIndex `0xFFFF` means absent; otherwise it is in range and always selected. From the selected LangSys indices, select `rlig` always, `liga` when enabled, and `kern` when enabled.
- **D-11:** Required selection wins de-duplication. Required `kern` combined with `kern=false` is `CapabilityUnavailable`, preserving the guarantee that `kern=false` disables modern and legacy routes. — **Reversibility:** costly — later shaping output and toggle compatibility depend on it.
- **D-12:** Selected non-null FeatureParams is structurally checked then rejected as `CapabilityUnavailable`; malformed offsets are `Data`.
- **D-13:** Validate lookup references, union/de-duplicate by lookup index, and normalize in ascending LookupList order. Duplicate references execute once.
- **D-14:** Preserve every selected lookup subtable occurrence in source order; do not sort or de-duplicate. Later execution uses stored first-match preference.
- **D-15:** Every selected lookup subtable must be structurally admitted and supported; a later supported subtable cannot hide an earlier unsupported one.

### Coverage, ClassDef, GDEF, flags, and selected bodies

- **D-16:** Coverage 1 glyphs are strictly increasing and below `num_glyphs`.
- **D-17:** Coverage 2 ranges are ordered/non-overlapping with valid endpoints and exact cumulative `startCoverageIndex`; retain compact ranges plus total cardinality.
- **D-18:** ClassDef 1 proves `startGlyph + glyphCount`; ClassDef 2 ranges are ordered/non-overlapping. Explicit class zero is valid and class zero remains the implicit default.
- **D-19:** Enforce contextual class bounds: GDEF `0..4`, PairPos classes below declared counts, and checked class-count products/matrix extents.
- **D-20:** Fully normalize selected GSUB 1 formats 1/2 and GSUB 4 format 1, including coverage cardinalities, GID bounds, LigatureSet/Ligature bases, component counts, and retained preference order; do not apply them.
- **D-21:** Fully normalize selected GPOS 2 formats 1/2, including PairSet/Coverage cardinality, strict second-GID order, ClassDefs, matrix extents, and complete ValueRecord windows; do not apply positioning.
- **D-22:** Selected ValueFormats may contain only x/y placement and x advance for either glyph. Zero is valid. Y advance, device/variation offsets, and reserved bits are checked then `CapabilityUnavailable`.
- **D-23:** GDEF is optional unless a selected lookup uses one of the three class-ignore flags. Then exact GDEF 1.0 with non-null valid GlyphClassDef is required; absent/null/malformed dependency is `Data`.
- **D-24:** A structurally valid non-1.0 GDEF required by selected flags is `CapabilityUnavailable`; richer unselected GDEF does not reject requests that need no classifier.
- **D-25:** Admit `RIGHT_TO_LEFT` plus `IGNORE_BASE_GLYPHS`, `IGNORE_LIGATURES`, and `IGNORE_MARKS`. RTL is retained non-operative metadata; class-ignore maps to GDEF classes 1/2/3 while class 0 and component class 4 remain visible.
- **D-26:** `USE_MARK_FILTERING_SET`, nonzero mark-attachment class, and reserved flags are `CapabilityUnavailable` after fixed-envelope validation; truncation is `Data`.
- **D-27:** Admit one GSUB 7 format-1 hop to type 1/4 and one GPOS 9 format-1 hop to type 2. The nonzero Offset32 is extension-relative, may exceed `0xFFFF`, and must contain the complete inner subtable within the layout window.
- **D-28:** Extension-to-extension, other inner types, other wrapper formats, and deferred wrappers are `CapabilityUnavailable`; zero/out-of-range/truncated targets are `Data`.
- **D-29:** Retain owned compact normalized records/ranges plus opaque owner/revision identity, never raw views, unchecked offsets, public indices, or mutable source state.

### Limits, charging, mutation guards, lifetime, and diagnostics

- **D-30:** Preserve the Phase 108 two-argument `ShapeLimits::new`. Add a public-abstract layout-limit bundle and an additive customization path; the old constructor supplies conservative nonzero defaults. — **Reversibility:** one-way — published construction and limit semantics require a compatibility migration to undo.
- **D-31:** Separate ceilings cover selected GSUB/GPOS/GDEF bytes; scripts/LangSys/features/references/lookups/subtables; Coverage/ClassDef facts; substitutions/ligatures/components; PairSets/pairs/classes/cells; retained bytes/allocations/max allocation; and parser work.
- **D-32:** Check every per-structure and aggregate count. Cross-products and record extents have their own ceilings; factor limits alone are insufficient.
- **D-33:** Admission charges exact retained normalized `bytes`, actual `allocations`, maximum `allocation_size`, and parser `work`; width/height/pixels are zero. Do not recharge font-owned source table bytes.
- **D-34:** Parser work covers fixed reads, record visits, comparisons/search steps, selected-body visits, failed normalization probes, and copies; no executor/output work is charged.
- **D-35:** Exact-fit succeeds and one-short fails for every semantic limit and charged dimension. Admission failure never commits; charges compose with later stages and commit only after complete shaping.
- **D-36:** Named revision guards occur at entry, before/after selected GSUB, before/after selected GPOS, before/after selected GDEF binding, after complete profile staging, and at the existing final pre-commit guard.
- **D-37:** Preserve `InvalidInput → State → Data → Capability → Resource`, except declared-count/resource preflight follows a valid fixed envelope and precedes attacker-sized traversal. Malformed fixed envelope remains `Data`.
- **D-38:** No persistent constructor/cache. Profile use is nested in `FontShapeScope`, shares active/revision state, and becomes unusable when the callback closes.
- **D-39:** Internal operation is `font-layout-admit`; public shape rebinds to `text-shape`. Contexts are stable table/relation tokens and never expose raw offsets, indices, font-selected tags, or host prose. — **Reversibility:** one-way — diagnostics are a public compatibility contract.
- **D-40:** Private white-box summaries may verify normalized facts; no public plan accessor, cache handle, commit method, or table inspection API is added.

### Phase ownership

- **D-41:** Phase 109 fully parses/normalizes the selected admitted subset but applies no substitution or positioning and queries no final metrics/legacy kerning.
- **D-42:** Phase 110 owns normalized GSUB execution, cmap seeds, ligature consumption/clusters, final GID validation, and metric initialization.
- **D-43:** Phase 111 owns PairPos execution, class-zero behavior, ValueRecord application/accumulation, next-probe rules, positions, and GPOS-versus-legacy authority.
- **D-44:** Phase 112 owns cross-stage charge equations, integrated mutation collisions, atomicity hardening, and compatibility closure.
- **D-45:** Phase 113 alone owns licensed/oracle/cross-target semantic qualification claims. Phase 109 uses generated hostile structural admission fixtures only.
- **D-46:** Public nonempty shaping remains capability-closed in Phase 109. A profile may be admitted privately, but no incomplete run is published.

### the agent's Discretion

- Private file boundaries and compact record names.
- Conservative default values for the new layout-limit bundle, provided every value is nonzero, documented, policy-sealed, and covered by exact/one-short tests.
- Internal binary-search and storage details that preserve the locked order, charge, and diagnostic contracts.

### Deferred Ideas (OUT OF SCOPE)

- GSUB application, ligature clusters, metric refresh — Phase 110.
- GPOS application and modern/legacy kerning authority — Phase 111.
- Integrated charges/mutation/atomicity — Phase 112.
- Licensed/oracle/four-target semantic qualification — Phase 113.
- Contextual/chained/reverse substitution, cursive/mark attachment, mark filtering sets, mark attachment classes, variables, FeatureVariations execution, caches, UI, FFI, and public raw layout inspection — future milestones.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAY-01 | `mb-font` resolves one request-scoped bounded OpenType 1.9.1 Script/LangSys/Feature/Lookup plan from the exact caller-selected script and default-or-exact language system, includes the required feature plus supported `rlig`/`liga`/`kern` choices, de-duplicates selected lookup indices, and executes them once in ascending LookupList order with stored subtable preference and no public raw table, offset, or lookup facts. | The staged selection algorithm, offset ledger, normalized profile shapes, private scope integration, precedence rules, and lookup-order tests below make the admission portion implementation-ready; actual execution remains Phase 110/111. [VERIFIED: `.planning/REQUIREMENTS.md`, `109-CONTEXT.md`, live Phase 108 source] |
| LAY-02 | Selected layout paths support checked Coverage formats 1/2, ClassDef formats 1/2, GDEF 1.0 `GlyphClassDef`, `IGNORE_BASE_GLYPHS`/`IGNORE_LIGATURES`/`IGNORE_MARKS`, and one-hop GSUB type 7 or GPOS type 9 extension dispatch only to an admitted inner type, while malformed dependencies, recursive wrappers, reserved flags, mark filtering, mark attachment classes, feature variations, or any other selected unsupported capability fail closed and unrelated unselected rich tables do not over-reject the font. | The exhaustive field ledger, supported-body algorithms, GDEF dependency rules, selected-versus-unselected matrix, extension rules, limit model, diagnostic tokens, and hostile-fixture matrix below cover each required branch. [VERIFIED: `.planning/REQUIREMENTS.md`, `109-CONTEXT.md`; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2] |
</phase_requirements>

## Summary

Phase 109 should be implemented as a request-scoped, two-pass admission pipeline inside `mb-font`: first validate the table-global envelopes and all Script/Feature/Lookup record targets for each present GSUB/GPOS table; then select and normalize only the exact Script/LangSys/features/lookups requested by `mb-text`. The parser must retain owned semantic facts only, accumulate a deferred first capability failure while continuing bounded structural validation so later malformed data retains precedence, bind GDEF only when selected ignore-class flags require it, and return the opaque profile only inside the live `FontShapeScope`. [VERIFIED: `109-CONTEXT.md` D-01–D-29, D-36–D-40; live `cursor.mbt`, `directory.mbt`, `shape_transaction.mbt`]

The Phase 108 seam is usable without changing the public `shape` signature: keep `Font::with_shape_transaction` unchanged, add a public-abstract `FontLayoutLimits` value in `mb-font`, and add `FontShapeScope::admit_layout(...)` returning a public-abstract `FontLayoutProfile`. These types expose no raw table bytes, offsets, or lookup indices; `mb-text` converts its already-public tag bytes and feature toggles into semantic arguments inside the callback, then deliberately returns `layout-unavailable` for nonempty input until Phase 110. This is additive, compile-feasible across the existing one-way `mb-text -> mb-font` dependency, and preserves the callback lifetime/revision cell. [VERIFIED: live `modules/mb-font/font/shape_transaction.mbt`, `modules/mb-text/text/tags.mbt`, `options.mbt`, `limits.mbt`, `shape.mbt`, and `policy/foundation.json`]

Three locked decisions intentionally diverge from conforming OpenType 1.9.1 behavior and must be policy-sealed as such: FeatureRecords can legally repeat a tag and are only recommended (not required) to be sorted; non-null FeatureParams on `rlig`/`liga`/`kern` are invalid because those tags define no parameter table; and extension-to-extension lookup types are structurally prohibited by the spec. The plan must still honor D-09, D-12, and D-28, but it must include explicit compatibility-divergence fixtures and documentation rather than claiming these branches are specification-required. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos]

**Primary recommendation:** Build one private `LayoutAdmissionBuilder` that owns table-local cursors, checked `UInt64` arithmetic, limits/work/charge ledgers, deferred capability state, and the normalized profile; enter it only through the live `FontShapeScope`, perform GSUB then GPOS then conditional GDEF staging with the locked revision guards, and never publish the profile beyond the callback. [VERIFIED: `109-CONTEXT.md` D-01, D-29, D-33–D-40]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Layout-table windowing and normalization | API / Backend (`mb-font`) | Storage (`Font`-owned bytes) | `mb-font` already owns immutable font bytes, directory windows, glyph bounds, revisions, and structural charging; normalized facts must remain behind that authority. [VERIFIED: live `font.mbt`, `directory.mbt`, `shape_transaction.mbt`; RFC 0004] |
| Script/language/feature policy | API / Backend (`mb-text`) | API / Backend (`mb-font`) | `mb-text` owns caller options while `mb-font` matches those semantic values against table records and creates the private plan. [VERIFIED: live `tags.mbt`, `options.mbt`; RFC 0005] |
| Limits and customization | API / Backend (`mb-font` public-abstract value, embedded by `mb-text::ShapeLimits`) | — | A single font-owned limit type avoids a reverse dependency and lets the parser consume the exact bundle without duplicating 30+ fields. [VERIFIED: live module dependency direction and D-30] |
| Revision/lifetime/atomic charge | API / Backend (`FontShapeScope`) | `mb-core/budget` | The existing transaction owns active state, revision guards, hierarchy preflight, and the sole final charge. [VERIFIED: live `shape_transaction.mbt`, `budget.mbt`] |
| GSUB/GPOS execution and positioned output | Deferred phases 110/111 | — | Phase 109 admits only and public nonempty shaping remains capability-closed. [VERIFIED: D-41–D-46] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be implemented in MoonBit; no foreign implementation may become the core. [VERIFIED: project `AGENTS.md`]
- Native is the primary target, while `mb-font` and `mb-text` continue to compile for JS, Wasm, Wasm-GC, and native through capability boundaries and conformance tests. [VERIFIED: project `AGENTS.md`, stack policy]
- No FFI is needed for this phase; if any future adapter appears, it must be small, isolated, documented, replaceable, and explicit about ownership. [VERIFIED: project `AGENTS.md`; phase boundary]
- Public package dependencies must remain acyclic and explicit; `mb-text -> mb-font -> mb-core` must not be reversed. [VERIFIED: project `AGENTS.md`, live module manifests]
- Public stable surfaces follow SemVer; experimental additions must be visibly marked and policy-sealed. [VERIFIED: project `AGENTS.md`, `policy/foundation.json`]
- Public operations and diagnostics must be deterministic and usable without GUI state; no GUI, ambient filesystem/network I/O, or cache belongs in admission. [VERIFIED: project `AGENTS.md`, D-38, D-39]
- Performance claims require declared workloads and reproducible baselines; Phase 109 may add parser-work assertions but not marketing or cross-target qualification claims. [VERIFIED: project `AGENTS.md`, D-34, D-45]
- Architectural boundary changes require RFC treatment; this phase implements the already-approved RFC 0004/0005 ownership boundary. [VERIFIED: project `AGENTS.md`, canonical references]
- Code discovery must prefer the codebase knowledge graph; graph search returned no Phase 109 layout symbols, so live-source inspection was the required fallback. [VERIFIED: project `AGENTS.md`; graph query result]
- File changes must occur through a GSD workflow; this research is part of the Phase 109 GSD plan workflow. [VERIFIED: project `AGENTS.md`; init.phase-op 109]

## Standard Stack

### Core

| Library / Tool | Verified Version | Purpose | Why Standard |
|----------------|------------------|---------|--------------|
| MoonBit `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Build, test, format, interface inspection | Exact repository/CI development pin and installed locally. [VERIFIED: local `moon --version`; project stack] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile all four targets | Comes with the pinned toolchain and is installed locally. [VERIFIED: local `moonc -v`; project stack] |
| `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Native test execution | Comes with the pinned toolchain and is installed locally. [VERIFIED: local `moonrun --version`; project stack] |
| Existing `mb-core` checked/budget/error packages | repository version | Checked arithmetic, atomic charge composition, structured errors | These are already policy-sealed dependencies and directly implement D-01, D-33, D-35, D-37, D-39. [VERIFIED: live `checked`, `budget.mbt`, `core_error.mbt`] |
| Existing `mb-font` cursor/directory/transaction primitives | repository version | Checked reads, table-local windows, owner/revision authority | They are the closest compile-proved patterns and avoid duplicate binary/transaction machinery. [VERIFIED: live `cursor.mbt`, `directory.mbt`, `shape_transaction.mbt`] |

### Supporting

| Library / Tool | Verified Version | Purpose | When to Use |
|----------------|------------------|---------|-------------|
| PowerShell policy harness | repository script | Exact interface/source/docs/policy sealing | Update Phase 109 source inventories and assert no raw layout API leak. [VERIFIED: live `scripts/quality/Assert-Policy.ps1`] |
| Generated MoonBit fixture builders | repository-local tests | Hostile offsets, counts, ordering, and one-short cases | Use for all Phase 109 structural fixtures; no licensed fonts or external packages. [VERIFIED: D-45 and existing white-box fixture precedent] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend the existing cursor/window machinery | New layout-specific raw reader | Reject: duplicates checked arithmetic and makes field-base drift more likely. [VERIFIED: D-01–D-03; live cursor precedent] |
| Public-abstract font-owned limits | Duplicate an internal limit bundle in both modules | Reject: duplicated defaults can drift and require two public maintenance surfaces. [VERIFIED: dependency direction and D-30] |
| Private normalized profile | Expose raw table views/indices | Prohibited by LAY-01, D-29, D-39, D-40. [VERIFIED: requirements/context] |

**Installation:** No external package installation is required. [VERIFIED: live repository stack and phase scope]

## Package Legitimacy Audit

No external packages are introduced, so the package-legitimacy gate is not applicable. [VERIFIED: recommended stack above]

## Specification Compatibility Decisions

| Locked decision | OpenType 1.9.1 fact | Planning resolution |
|-----------------|----------------------|---------------------|
| D-09 rejects duplicate FeatureRecord tags and requires strict sorting. | FeatureList may contain multiple records with the same feature tag, and sorting is stated as “should,” not “must.” [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2] | Honor D-09 as an MNF closed-profile restriction. Add a generated, otherwise-conforming duplicate-tag fixture that expects `Data`, and document that Phase 109 intentionally accepts a subset of conforming fonts. [VERIFIED: locked D-09] |
| D-12 classifies every structurally checked selected non-null FeatureParams as `CapabilityUnavailable`. | FeatureParams is tag-specific. Only `cv01`–`cv99`, `ss01`–`ss20`, and `size` define forms; for tags such as `rlig`, `liga`, and `kern`, a non-null offset is not a defined valid structure. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_ae; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt] | Honor D-12's category: resolve the Feature-relative nonzero target and validate the applicable known envelope; for a tag with no defined form, require a readable two-byte target before recording `CapabilityUnavailable`. Document this as an MNF diagnostic-category divergence, not as OpenType validity. [VERIFIED: locked D-12] |
| D-28 classifies extension-to-extension as `CapabilityUnavailable`. | ExtensionSubst type 7 may not extend type 7, and ExtensionPos type 9 may not extend type 9. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos] | Honor D-28 after validating the eight-byte wrapper and nonzero, in-range target. Add explicit recursive-wrapper fixtures and document the category divergence. [VERIFIED: locked D-28] |
| D-07 does not fall back to `DFLT`. | The common-layout guidance recommends using `DFLT` when no script-specific system is defined, but clients may establish their own criteria. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2] | Exact-only selection is a legitimate application policy; keep it unchanged and test absence without fallback. [VERIFIED: locked D-07] |

## Architecture Patterns

### System Architecture Diagram

```text
@text.shape(font, scalars, options, ShapeLimits, budget)
  |
  +--> validate caller input and scalar/limit facts
  |
  +--> Font::with_shape_transaction(...)
         |
         +--> entry revision guard
         |
         +--> FontShapeScope::admit_layout(semantic request, FontLayoutLimits)
         |      |
         |      +--> GSUB table-local window
         |      |      -> global envelope pass
         |      |      -> exact Script/LangSys/Feature selection
         |      |      -> ascending selected lookup normalization
         |      |
         |      +--> GPOS table-local window
         |      |      -> same global/selection pipeline
         |      |
         |      +--> selected flags require classifier?
         |             |
         |             +-- no --> no GDEF read
         |             |
         |             +-- yes -> GDEF 1.0 window
         |                       -> GlyphClassDef normalization
         |
         +--> complete opaque LayoutProfile staged under scope/revision identity
         |
         +--> Phase 109 nonempty branch returns text-shape/layout-unavailable
         |    (no incomplete ShapedRun is published)
         |
         +--> future Phase 110/111 body charge composition
         |
         +--> hierarchy preflight -> final revision guard -> one commit
```

The data path and guard placement above follow the existing transaction and the locked GSUB → GPOS → conditional-GDEF staging order; the admission profile does not escape the callback. [VERIFIED: live `shape_transaction.mbt`; D-36, D-38, D-41–D-46]

### Field-by-Field Offset and Envelope Ledger

All additions, multiplications, cardinality sums, record extents, and narrowed indices use checked `UInt64`. A resolved target window extends from the target to the end of the owning **table-local** window, not to a guessed next sibling; OpenType offsets may alias or be non-monotonic. “Complete” below means the selected structure's format/count-derived extent is inside that table window. [VERIFIED: D-01–D-03; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2]

| Structure / field | Width | Base | Zero | Minimum target / complete extent | Validation depth and outcome |
|-------------------|-------|------|------|----------------------------------|------------------------------|
| GSUB/GPOS 1.0 header | 10 bytes | table start | n/a | version `0x00010000`; three non-null Offset16 fields | Require the complete header and resolve ScriptList, FeatureList, LookupList. Truncation/version outside 1.0/1.1 is `Data` unless it is a structurally complete required capability explicitly classified otherwise. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-06] |
| GSUB/GPOS 1.1 header | 14 bytes | table start | FeatureVariations only nullable | version `0x00010001`; same three Offset16 plus Offset32 | Null FeatureVariations admits. Non-null resolves within table, validates the top envelope below, then records `CapabilityUnavailable`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-06] |
| `scriptListOffset` | Offset16 | layout table start | forbidden | ScriptList: `2 + 6*scriptCount` | Validate full global record array, strict tag order/uniqueness, and every ScriptRecord target's immediate Script envelope. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-02–D-05, D-09] |
| `featureListOffset` | Offset16 | layout table start | forbidden | FeatureList: `2 + 6*featureCount` | Validate full record array, locked strict tag order/uniqueness, and every FeatureRecord target's immediate Feature envelope. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-02–D-05, D-09] |
| `lookupListOffset` | Offset16 | layout table start | forbidden | LookupList: `2 + 2*lookupCount` | Validate full offset array and every Lookup target's complete lookup header/subtable-offset array; do not decode unselected subtable bodies. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-02–D-05] |
| `featureVariationsOffset` | Offset32 | layout table start | allowed | FeatureVariations header `8` plus `8*featureVariationRecordCount`; version must be 1.0 | Validate the complete top-level record-array envelope only; do not follow ConditionSet or FeatureTableSubstitution offsets because the capability is rejected. Malformed is `Data`, otherwise deferred `CapabilityUnavailable`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-06] |
| FeatureVariationRecord `conditionSetOffset` | Offset32 | FeatureVariations start | allowed (universal condition) | not followed in Phase 109 | The field itself fits because the full `8 + 8*count` array is checked; D-06 stops at this minimum top-level envelope before capability classification. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-06] |
| FeatureVariationRecord `featureTableSubstitutionOffset` | Offset32 | FeatureVariations start | allowed (no substitutions) | not followed in Phase 109 | Same top-level-only validation boundary; nested FeatureVariations execution is deferred. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-06, deferred scope] |
| ScriptRecord `scriptOffset` | Offset16 | ScriptList start | forbidden | Script header `4`, then `4 + 6*langSysCount` | Every record target is checked even when unselected. Selected Script deep-validates Default/LangSys targets. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-02, D-04, D-05] |
| Script `defaultLangSysOffset` | Offset16 | selected Script start | allowed | LangSys `6 + 2*featureIndexCount` | Null means no default. `Default` requires non-null; `Exact` never falls back. A selected `DFLT` Script is also required by the specification to have a non-null default LangSys. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-08] |
| LangSysRecord `langSysOffset` | Offset16 | selected Script start | forbidden | LangSys `6 + 2*featureIndexCount` | Validate complete selected Script record array, locked strict tag ordering/uniqueness, and selected target; unselected LangSys bodies are not deep-decoded. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-02, D-04, D-08, D-09] |
| LangSys `lookupOrderOffset` | Offset16 | LangSys start | must be zero | no target | Any nonzero value is malformed `Data`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-09] |
| LangSys `requiredFeatureIndex` | uint16 | index into FeatureList | `0xFFFF` means absent | in-range Feature record otherwise | Always select the feature; a required `kern` conflicts with `kern=false` as deferred `CapabilityUnavailable`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-10, D-11] |
| LangSys `featureIndices[]` | uint16 | indices into FeatureList | zero is ordinary index | each in range; full `2*count` array | Duplicate indices are locked malformed `Data`; select only `rlig`, enabled `liga`, and enabled `kern`, with required feature winning de-duplication. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-09–D-11] |
| FeatureRecord `featureOffset` | Offset16 | FeatureList start | forbidden | Feature `4 + 2*lookupIndexCount` | Every target's immediate/full Feature envelope is checked even when unselected; only selected lookup references and FeatureParams are deep-processed. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-02, D-04, D-05] |
| Feature `featureParamsOffset` | Offset16 | selected Feature start | allowed | tag-specific: `cvXX` `14 + 3*charCount`; `ssXX` `4`; `size` `10`; undefined tag fallback `2` | Non-null selected targets are structurally checked and deferred `CapabilityUnavailable`; invalid target/extent is `Data`. The two-byte fallback is the locked category-divergence rule for tags without a defined table. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_ae; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt; VERIFIED: D-12] |
| Feature `lookupListIndices[]` | uint16 | indices into LookupList | zero is ordinary index | each in range; full `2*count` array | Validate all selected references, set a selected-index bitmap, then emit lookup indices ascending; duplicate references execute once. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-13] |
| LookupList `lookupOffsets[]` | Offset16 | LookupList start | forbidden | Lookup `6 + 2*subTableCount`, plus two bytes if flag `0x0010` | Every Lookup target header and its complete offset array are globally checked. The optional MarkFilteringSet field must fit before capability classification. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-03–D-05, D-26] |
| Lookup `subtableOffsets[]` | Offset16 | selected Lookup start | forbidden | target format word `2`, then selected type/format extent | Preserve every occurrence in source order, including duplicate offsets. Selected unsupported type/format records a deferred capability only after its fixed target envelope is readable. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-14, D-15] |
| Coverage offset in GSUB 1/4 or GPOS 2 | Offset16 | owning selected subtable start | forbidden | Coverage header `4`, then format-specific complete extent | Coverage 1: `4 + 2*glyphCount`; Coverage 2: `4 + 6*rangeCount`. Validate and normalize fully. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-16, D-17, D-20, D-21] |
| ClassDef offsets in GPOS PairPos 2 | Offset16 | PairPos subtable start | forbidden | ClassDef header `4`, then format 1 `6 + 2*glyphCount` or format 2 `4 + 6*rangeCount` | Normalize both; enforce each class value below its corresponding declared class count. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-18, D-19, D-21] |
| GDEF version/header | 4 / 12 / 14 / 18 bytes | GDEF table start | n/a | read 4-byte version; known 1.0 requires 12, 1.2 requires 14, 1.3 requires 18 | When a classifier is required, exact 1.0 continues; structurally complete 1.2/1.3 or unknown version records capability. A known-version short header is `Data`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gdef; VERIFIED: D-23, D-24] |
| GDEF `glyphClassDefOffset` | Offset16 | GDEF table start | nullable by format, but forbidden when selected flags require it | ClassDef complete extent | Parse only for selected ignore-class dependency. Missing GDEF/null target/malformed ClassDef is `Data`; structurally complete non-1.0 GDEF is deferred `CapabilityUnavailable`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gdef; VERIFIED: D-23, D-24] |
| GDEF 1.0 `attachListOffset` | Offset16 | GDEF table start | allowed | not followed in Phase 109 | Field must fit in the 12-byte header; attachment-point data is not a selected dependency and is not deep-validated. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gdef; VERIFIED: D-04 selective-depth policy, D-23] |
| GDEF 1.0 `ligCaretListOffset` | Offset16 | GDEF table start | allowed | not followed in Phase 109 | Field must fit in the 12-byte header; ligature caret data is outside admission requirements. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gdef; VERIFIED: D-04 selective-depth policy, D-41] |
| GDEF 1.0 `markAttachClassDefOffset` | Offset16 | GDEF table start | allowed | not followed in Phase 109 | Field must fit in the 12-byte header; selected nonzero mark-attachment LookupFlag is already a capability branch and this ClassDef is not bound. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gdef; VERIFIED: D-23, D-26] |
| GSUB SingleSubst 1 `coverageOffset` | Offset16 | SingleSubst start | forbidden | Coverage complete extent; subtable fixed size `6` | Validate delta substitution result modulo 65536 for every covered GID and require each resulting GID below `num_glyphs`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20] |
| GSUB SingleSubst 2 `coverageOffset` | Offset16 | SingleSubst start | forbidden | fixed `6 + 2*glyphCount` plus Coverage | `glyphCount` must equal Coverage cardinality; every substitute GID is in range. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20] |
| GSUB LigatureSubst `coverageOffset` | Offset16 | LigatureSubst start | forbidden | fixed `6 + 2*ligatureSetCount` plus Coverage | Set count equals Coverage cardinality. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20] |
| GSUB `ligatureSetOffsets[]` | Offset16 | LigatureSubst start | forbidden | LigatureSet `2 + 2*ligatureCount` | Preserve set order by Coverage index and every Ligature occurrence in stored order. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-02, D-14, D-20] |
| GSUB `ligatureOffsets[]` | Offset16 | owning LigatureSet start | forbidden | Ligature `4 + 2*(componentCount-1)` | Require checked extent, output/component GIDs below `num_glyphs`, and `componentCount >= 2` as the closed-profile multiple-to-one invariant. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20] |
| GPOS PairPos 1 `coverageOffset` | Offset16 | PairPos start | forbidden | fixed `12 + 2*pairSetCount` plus Coverage | PairSet count equals Coverage cardinality. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-21] |
| GPOS `pairSetOffsets[]` | Offset16 | PairPos start | forbidden | PairSet `2 + pairValueCount*(2 + valueWidth1 + valueWidth2)` | Validate each full record array, second GIDs strictly increasing/in range, and retain source order. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-21] |
| ValueRecord device/variation offsets in PairPos 1 | Offset16 | owning PairSet start | allowed | non-null target minimum `6` bytes (Device/VariationIndex common prefix) | Parse every defined ValueRecord field width first; a non-null device field resolves/checks its target then defers `CapabilityUnavailable`. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22] |
| ValueRecord device/variation offsets in PairPos 2 | Offset16 | PairPos subtable start | allowed | non-null target minimum `6` bytes | Same fixed-envelope-before-capability rule. Reserved ValueFormat bits add no known fields and are rejected after all defined low-byte fields fit. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22] |
| GSUB ExtensionSubst / GPOS ExtensionPos target | Offset32 | extension subtable start | forbidden | wrapper exactly needs `8`; target needs inner format word then complete admitted inner subtable | Format must be 1. Offset may exceed `0xFFFF`. One hop only to GSUB 1/4 or GPOS 2. Zero/out-of-range/truncated is `Data`; other/recursive inner type is deferred capability. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-27, D-28] |

### Lookup Flags and ValueFormat Ledger

| Field | Bits | Fixed bytes implied | Admission result |
|-------|------|---------------------|------------------|
| LookupFlag `RIGHT_TO_LEFT` | `0x0001` | none | Retain as non-operative metadata; it is not caller text direction. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-25] |
| `IGNORE_BASE_GLYPHS` / `IGNORE_LIGATURES` / `IGNORE_MARKS` | `0x0002` / `0x0004` / `0x0008` | none | Admit and require GDEF 1.0 GlyphClassDef; filter classes 1/2/3 respectively in later execution. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-23, D-25] |
| `USE_MARK_FILTERING_SET` | `0x0010` | extra uint16 after subtable offsets | Require the extra field to fit, then defer capability. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-26] |
| Reserved LookupFlag | `0x00E0` | none | Defer capability after complete Lookup envelope. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-26] |
| Mark attachment class | `0xFF00` | none | Nonzero defers capability after complete Lookup envelope. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-26] |
| ValueFormat xPlacement/yPlacement/xAdvance | `0x0001` / `0x0002` / `0x0004` | one int16 per set bit | Admit; normalize sign-extended values. Zero format is legal. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22] |
| ValueFormat yAdvance | `0x0008` | one int16 | Read the complete field, then defer capability. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22] |
| ValueFormat device/variation offsets | `0x0010`–`0x0080` | one Offset16 per set bit | Read each field, resolve every non-null target to a six-byte minimum, then defer capability. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22] |
| ValueFormat reserved | `0xFF00` | no defined width | Reject as deferred capability after all defined low-byte fields and containing record extents fit. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22] |

### Public and Private API Shape

Use the following additive interface shape; exact MoonBit spelling should be compile-proved with `moon info` before policy hashes are regenerated. [VERIFIED: live Phase 108 interfaces and D-30, D-38, D-40]

```moonbit
// mb-font: all fields remain private; every constructor argument is nonzero.
pub struct FontLayoutLimits { ... }

pub fn FontLayoutLimits::new(
  max_gsub_bytes~ : UInt64,
  max_gpos_bytes~ : UInt64,
  max_gdef_bytes~ : UInt64,
  max_scripts~ : UInt64,
  max_language_systems~ : UInt64,
  max_features~ : UInt64,
  max_feature_references~ : UInt64,
  max_lookups~ : UInt64,
  max_subtables~ : UInt64,
  max_coverage_glyphs~ : UInt64,
  max_coverage_ranges~ : UInt64,
  max_classdef_glyphs~ : UInt64,
  max_classdef_ranges~ : UInt64,
  max_substitution_rules~ : UInt64,
  max_ligature_sets~ : UInt64,
  max_ligatures~ : UInt64,
  max_ligature_components~ : UInt64,
  max_pair_sets~ : UInt64,
  max_pair_records~ : UInt64,
  max_classes~ : UInt64,
  max_class_cells~ : UInt64,
  max_record_extent~ : UInt64,
  max_cross_product~ : UInt64,
  max_retained_bytes~ : UInt64,
  max_allocations~ : UInt64,
  max_allocation_size~ : UInt64,
  max_parser_work~ : UInt64,
) -> Result[FontLayoutLimits, @error.CoreError]

pub struct FontLayoutProfile { ... } // no public fields or accessors in Phase 109

pub fn FontShapeScope::admit_layout(
  self : FontShapeScope,
  script : Bytes,
  language : Bytes?,
  liga : Bool,
  kern : Bool,
  limits : FontLayoutLimits,
) -> Result[FontLayoutProfile, @error.CoreError]

// mb-text: existing constructor remains byte-for-byte compatible.
pub fn ShapeLimits::new(
  max_input_scalars~ : UInt64,
  max_output_glyphs~ : UInt64,
) -> Result[ShapeLimits, @error.CoreError]

pub fn ShapeLimits::with_layout_limits(
  self : ShapeLimits,
  layout_limits : @font.FontLayoutLimits,
) -> ShapeLimits
```

`language=None` is the semantic Default choice; `Some(tag)` is exact. Script/language bytes are semantic four-byte tags already exposed by `ScriptTag::bytes` and `LanguageTag::bytes`, not source-table views. `admit_layout` revalidates length/printability for direct `mb-font` callers, but never places the values into an error context. [VERIFIED: live `tags.mbt`, `options.mbt`; D-08, D-29, D-39]

The public profile has no Phase 109 methods and privately retains an alias of the admitting scope's active/revision authority. It may nominally escape through generic `T`, just like `FontShapeScope`, but exposes no facts; future execution methods must recheck that shared scope/revision identity. This preserves one-way module dependencies and does not require `mb-font` to import `mb-text`. [VERIFIED: live `shape_transaction.mbt`, module manifests; D-38, D-40]

Change the private scope fields to `priv mut font_charge` and add `priv mut layout_admitted`. `admit_layout` is single-use per scope: after the complete-profile guard succeeds, it atomically adds the exact admission charge to `scope.font_charge` and flips the flag; a second call returns `State/InvalidRange` with context `layout-already-admitted`. If parsing, capability classification, resource preflight, or a guard fails, neither private field changes. The existing transaction then combines the staged font charge with the body-returned text charge and performs its unchanged one final budget commit. [VERIFIED: compile-feasible extension of live `shape_transaction.mbt`; D-33, D-35, D-36, D-38]

### Conservative Default Layout Limits

`ShapeLimits::new` must embed exactly these nonzero defaults. `FontLayoutLimits::new` rejects zero with `InvalidInput/InvalidRange`; `ShapeLimits::with_layout_limits` only replaces the embedded bundle and does not alter the two existing scalar/output limits. [VERIFIED: D-30 and discretion]

| Limit field | Default | Scope / charging point |
|-------------|--------:|------------------------|
| `max_gsub_bytes` | 1,048,576 | Present GSUB table-local window participating in the request, checked before its global traversal. [VERIFIED: D-31, D-37 discretion] |
| `max_gpos_bytes` | 1,048,576 | Present GPOS table-local window participating in the request, checked before its global traversal. [VERIFIED: D-31, D-37 discretion] |
| `max_gdef_bytes` | 262,144 | Required GDEF table-local window length. [VERIFIED: D-31 discretion] |
| `max_scripts` | 256 | Aggregate ScriptRecords visited across GSUB/GPOS. [VERIFIED: D-31 discretion] |
| `max_language_systems` | 512 | Aggregate LangSysRecords in selected Scripts across GSUB/GPOS. [VERIFIED: D-31 discretion] |
| `max_features` | 2,048 | Aggregate global FeatureRecords across GSUB/GPOS. [VERIFIED: D-31 discretion] |
| `max_feature_references` | 8,192 | Aggregate selected LangSys feature indices plus selected Feature lookup indices. [VERIFIED: D-31 discretion] |
| `max_lookups` | 2,048 | Aggregate global LookupList entries across GSUB/GPOS. [VERIFIED: D-31 discretion] |
| `max_subtables` | 4,096 | Aggregate selected subtable occurrences; duplicates still count. [VERIFIED: D-14, D-31 discretion] |
| `max_coverage_glyphs` | 65,535 | Aggregate Coverage cardinality, including cardinality represented by ranges. [VERIFIED: D-31 discretion] |
| `max_coverage_ranges` | 8,192 | Aggregate Coverage format-2 records. [VERIFIED: D-31 discretion] |
| `max_classdef_glyphs` | 65,535 | Aggregate ClassDef format-1 glyph values. [VERIFIED: D-31 discretion] |
| `max_classdef_ranges` | 8,192 | Aggregate ClassDef format-2 records. [VERIFIED: D-31 discretion] |
| `max_substitution_rules` | 65,535 | Aggregate SingleSubst mappings plus ligature records. [VERIFIED: D-31 discretion] |
| `max_ligature_sets` | 16,384 | Aggregate selected LigatureSet occurrences. [VERIFIED: D-31 discretion] |
| `max_ligatures` | 65,535 | Aggregate Ligature records. [VERIFIED: D-31 discretion] |
| `max_ligature_components` | 262,144 | Aggregate stored trailing components (`componentCount - 1`). [VERIFIED: D-31 discretion] |
| `max_pair_sets` | 16,384 | Aggregate PairSet occurrences. [VERIFIED: D-31 discretion] |
| `max_pair_records` | 262,144 | Aggregate PairValueRecords. [VERIFIED: D-31 discretion] |
| `max_classes` | 1,024 | Each PairPos class count and aggregate distinct declared class domains. [VERIFIED: D-31 discretion] |
| `max_class_cells` | 262,144 | Aggregate dense PairPos format-2 cells. [VERIFIED: D-31 discretion] |
| `max_record_extent` | 8,388,608 | Any one count-derived record array/body extent before traversal. [VERIFIED: D-32 discretion] |
| `max_cross_product` | 262,144 | Any one class1Count × class2Count product independent of factor ceilings. [VERIFIED: D-32 discretion] |
| `max_retained_bytes` | 16,777,216 | Aggregate logical bytes retained by the normalized profile. [VERIFIED: D-31, D-33 discretion] |
| `max_allocations` | 32,768 | All explicit admission array allocations, retained or scratch. [VERIFIED: D-31, D-33 discretion] |
| `max_allocation_size` | 8,388,608 | Largest single retained or scratch logical allocation. [VERIFIED: D-31, D-33 discretion] |
| `max_parser_work` | 10,000,000 | Aggregate admission work events defined below. [VERIFIED: D-31, D-34 discretion] |

All aggregate counters span both GSUB and GPOS and the conditional GDEF parse so a caller cannot multiply a per-table limit by supplying several rich tables. Per-structure counts are checked against their relevant aggregate ceiling before addition, and the addition is checked independently. [VERIFIED: D-31, D-32]

### Normalized Owned Data Shapes

Use private logical descriptors and primitive arrays; no descriptor contains `ByteView`, source offsets, table indices exposed outside the package, or mutable font bytes. Fixed logical byte coefficients below are the normative cross-target charge model, following the repository's existing explicit CFF descriptor coefficients rather than relying on target-specific heap object size. [VERIFIED: live `cff_admission.mbt` retained-byte accounting; D-29, D-33]

| Normalized fact | Private representation | Retained-byte coefficient | Allocations |
|-----------------|------------------------|---------------------------|-------------|
| Profile header | owner/revision identity, GSUB/GPOS plan presence, GDEF presence | 64 bytes once | 0 additional [VERIFIED: recommended representation under D-29] |
| Selected lookup order | `Array[UInt64]` semantic internal lookup ordinals | `8 * selectedLookupCount` | 1 per present table [VERIFIED: recommended deterministic model under D-13] |
| Lookup descriptors | parallel arrays: type, flags, first-subtable slot, subtable count | `32 * selectedLookupCount` | 4 per present table [VERIFIED: recommended deterministic model under D-14, D-25] |
| Subtable occurrence descriptors | kind and private body slot | `16 * selectedSubtableCount` | 2 per present table [VERIFIED: recommended deterministic model under D-14] |
| Coverage 1 | one `Array[UInt64]` of GIDs | `8 * glyphCount` | 1 [VERIFIED: recommended compact form under D-16] |
| Coverage 2 | parallel start/end/startIndex `Array[UInt64]`, plus scalar cardinality | `24 * rangeCount + 8` | 3 [VERIFIED: recommended compact form under D-17] |
| ClassDef 1 | scalar start GID plus one `Array[UInt64]` of classes | `8 + 8 * glyphCount` | 1 [VERIFIED: recommended compact form under D-18] |
| ClassDef 2 | parallel start/end/class `Array[UInt64]` | `24 * rangeCount` | 3 [VERIFIED: recommended compact form under D-18] |
| SingleSubst 1 | body kind, coverage slot, sign-extended delta | 24 bytes plus Coverage | 0 additional [VERIFIED: recommended normalized form under D-20] |
| SingleSubst 2 | body header plus `Array[UInt64]` substitutes | `16 + 8 * glyphCount` plus Coverage | 1 [VERIFIED: recommended normalized form under D-20] |
| LigatureSubst | set descriptors `(firstLigature, count)`, ligature descriptors `(output, firstComponent, count)`, trailing components | `16*sets + 24*ligatures + 8*components` plus Coverage | 3 [VERIFIED: recommended normalized form under D-20] |
| PairPos 1 | set descriptors and parallel arrays for second GID plus six sign-extended value fields | `16*sets + 56*pairs` plus Coverage | 8 [VERIFIED: recommended normalized form under D-21, D-22] |
| PairPos 2 | six parallel `Array[Int64]` value planes for dense cells | `48 * classCells` plus Coverage and two ClassDefs | 6 [VERIFIED: recommended normalized form under D-21, D-22] |
| GDEF classifier | one normalized ClassDef plus required-class mask | ClassDef coefficient plus 8 bytes | ClassDef allocations [VERIFIED: recommended normalized form under D-23, D-25] |
| Scratch selection bitmap | one byte per global lookup | not retained in `bytes` | 1 per present table; `allocation_size` includes its length [VERIFIED: recommended selection algorithm under D-13, D-33] |

For `bytes`, add only coefficients retained by the final profile. For `allocations`, count every explicit `Array` backing constructed during admission, including empty and scratch arrays. For `allocation_size`, take the maximum logical payload of any single retained or scratch array; scalars/outer structs do not create a charged array allocation. Builders must move completed arrays into the profile rather than copy them, or charge the additional copy allocation/work explicitly. [VERIFIED: live CFF accounting pattern; D-33, D-34]

To make “actual allocations” deterministic, selected variable-length bodies use a validation/count pass followed by exact-size `Array::make` allocations and a fill pass; do not rely on capacity-growing `push` behavior. Both passes and every copied scalar are charged as parser work. Global unselected records are streamed without retained arrays; the only required scratch array is the exact-size selected-lookup bitmap. [VERIFIED: recommended implementation of D-33, D-34 using existing exact-allocation precedent]

### Parser Work Ledger

The implementation must expose one private work accumulator whose unit events are exhaustive and mutually additive. [VERIFIED: D-34]

| Event | Work units |
|-------|-----------:|
| Read one fixed scalar/tag/offset field | 1 [VERIFIED: D-34 discretion] |
| Resolve one offset or prove one count/product extent | 1 [VERIFIED: D-03, D-32, D-34] |
| Visit one record/array element | 1 [VERIFIED: D-34] |
| Perform one order, uniqueness, bounds, cardinality, class, or flag comparison | 1 [VERIFIED: D-34] |
| One binary-search iteration | 1 [VERIFIED: D-34 discretion] |
| Dispatch one selected subtable body or extension inner body | 1 [VERIFIED: D-34] |
| Probe one structurally complete unsupported feature/body/flag and record capability | 1 [VERIFIED: D-34] |
| Copy one retained scalar into a normalized array | 1 [VERIFIED: D-34] |
| Enter one named GSUB/GPOS/GDEF/profile stage | 1 [VERIFIED: D-34 discretion] |

Before any loop, compute its minimum future record-visit work and reject `max-parser-work` if it cannot fit; within the loop, increment for reads/comparisons/copies so exact final work is still charged. This prevents a low work ceiling from being bypassed by an attacker-sized declared count. [VERIFIED: D-32, D-34, D-37]

### Staged Admission Algorithm

1. Validate the semantic tag bytes and already-constructed nonzero limit bundle, returning `InvalidInput` without touching font state. Then call `scope.require_active()` for the entry `State` guard. [VERIFIED: D-36, D-37, D-39; live tag validation and scope code]
2. Discover optional GSUB/GPOS table windows through the retained directory. Validate both present top-level fixed headers before any attacker-sized traversal. Version 1.0 uses 10 bytes; 1.1 uses 14. Record but do not yet return a structurally valid non-null FeatureVariations capability. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-01, D-06, D-37]
3. For each present table, run the **global pass**: validate table-byte limit, three list arrays, strict locked tag ordering/uniqueness, all Script/Feature/Lookup record offsets, each immediate Script/Feature envelope, and each complete Lookup header/subtable-offset array. Apply count/extent/work preflights immediately after the corresponding valid fixed header and before its loop. [VERIFIED: D-04, D-05, D-09, D-31, D-32, D-37]
4. Immediately before selected GSUB work, run the named revision guard. Select the exact Script by binary search; absence records capability and skips deep selection for that table. From the selected Script, choose only non-null DefaultLangSys or exact LangSys, never fallback; absence records capability. Validate the full chosen LangSys, its required feature, feature-index uniqueness/ranges, and `lookupOrderOffset=0`. [VERIFIED: D-07–D-10, D-36]
5. Select required feature first, then `rlig`, enabled `liga`, and enabled `kern` from the chosen feature indices. Required wins de-duplication. A required `kern` with `kern=false` records capability. Validate selected FeatureParams as the ledger specifies. Visit every selected Feature lookup reference, validate range, mark a lookup bitmap, then scan LookupList indices ascending to create the plan. [VERIFIED: D-10–D-13]
6. For each selected lookup, preserve every subtable-offset occurrence in source order. Validate the lookup flags and optional MarkFilteringSet field. Dispatch every selected body; unsupported forms record the first stable capability token but do not hide an earlier or later malformed selected body. Run the after-GSUB revision guard even when a deferred capability has been recorded. [VERIFIED: D-14, D-15, D-20, D-26–D-28, D-36, D-37]
7. Repeat steps 4–6 for GPOS with its before/after revision guards. [VERIFIED: D-21, D-22, D-36]
8. If any selected admitted lookup has an ignore-base/ligature/mark bit, run the before-GDEF guard, require a GDEF table and a complete header, classify non-1.0 as deferred capability, require/normalize GlyphClassDef for exact 1.0, validate class values `0..4`, then run the after-GDEF guard. Do not read GDEF when no selected lookup requires it. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gdef; VERIFIED: D-23–D-25, D-36]
9. If any structural `Data` failure occurred it already returned; if any immediate declared-count Resource preflight failed it already returned; otherwise return the first deferred capability in deterministic stage/source order. If none exists, construct the private profile and exact charge, run the after-complete-profile revision guard, then atomically stage the charge in `scope.font_charge`, mark the scope admitted, and return the profile without charging the caller budget. [VERIFIED: D-33–D-38 and live transaction composition]
10. In Phase 109 `@text.shape`, a successfully admitted nonempty profile still returns `Capability/CapabilityUnavailable`, operation `text-shape`, context `layout-unavailable`; because the transaction body fails, neither admission nor text charge commits. Empty input retains the Phase 108 one-work success behavior and need not admit layout. [VERIFIED: D-35, D-46; live `shape.mbt`, Phase 108 docs/tests]

### Data/Capability/Resource Decision Matrix

| Situation | Selected? | Result |
|-----------|-----------|--------|
| Top-level/table/list/record fixed envelope malformed | either | `Data`; immediate return for that structure. [VERIFIED: D-03–D-06, D-37] |
| Global Script/Feature/Lookup record has invalid target | no | `Data`; unselected does not excuse invalid global indirection. [VERIFIED: D-05] |
| Global count/record extent exceeds its semantic ceiling after a valid header | either | `Resource`; may precede traversal and later discoveries under the explicit D-37 exception. [VERIFIED: D-31, D-32, D-37] |
| Exact Script/LangSys absent in a present table | yes | Deferred `CapabilityUnavailable`; continue the other present table's bounded structural work so malformed data is not hidden. [VERIFIED: D-07, D-08, D-37] |
| Valid advanced subtable body | no | Ignore body capability; only its global offset/minimum envelope was validated. [VERIFIED: D-04, D-05] |
| Selected unsupported type/format/flag with complete required envelope | yes | Deferred `CapabilityUnavailable`; continue selected structural validation. [VERIFIED: D-12, D-15, D-22, D-26, D-28, D-37] |
| Selected supported body has bad coverage/cardinality/GID/class/order/offset | yes | `Data`, even if a capability was previously deferred. [VERIFIED: D-15–D-23, D-37] |
| Revision changes at a named guard | either | `State`, returned immediately; no budget commit. [VERIFIED: D-35–D-37] |
| Final exact retained/work charge exceeds caller/ancestor budget | successful profile | `Resource` at the existing hierarchy preflight; no budget commit. [VERIFIED: D-33, D-35; live transaction] |

The “first deferred capability” order is: GSUB header/selection/features/lookups in source encounter order, then GPOS, then GDEF dependency. This order is deterministic but subordinate to later bounded `Data` discoveries and named `State` guards; only declared-count/resource traversal guards may return earlier by D-37. [VERIFIED: recommended deterministic resolution of D-36, D-37, D-39]

### Supported Body Algorithms

#### Coverage and ClassDef

- Coverage 1 reads the complete glyph array, proves each GID `< num_glyphs`, and requires `previous < current`; it retains the array without sorting. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-16]
- Coverage 2 reads each range in source order, proves `start <= end`, `end < num_glyphs`, `previous.end < current.start`, and `startCoverageIndex == runningCardinality`; it checked-adds `end-start+1` and retains compact ranges plus final cardinality. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-17]
- ClassDef 1 proves `startGlyph + glyphCount <= num_glyphs` using checked arithmetic, retains each class value, and applies the caller-provided maximum (`4` for GDEF, class count for PairPos). [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-18, D-19]
- ClassDef 2 proves every range is ordered/non-overlapping/in glyph bounds and every class is below the contextual maximum. Explicit zero is stored; a lookup miss remains implicit zero. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-18, D-19]

#### GSUB Type 1

- Format 1 reads the signed delta and Coverage, computes `(gid + delta) mod 65536` for every covered GID without signed overflow, and rejects any resulting GID outside the font's `num_glyphs`. It retains Coverage plus delta, not an expanded substitute array. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20]
- Format 2 validates `glyphCount == coverage.cardinality`, reads all substitute GIDs in Coverage-index order, proves each below `num_glyphs`, and retains the owned array. Substitute ordering/uniqueness is unrestricted. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20]

#### GSUB Type 4

- Format 1 validates `ligatureSetCount == coverage.cardinality`; each non-null set offset is LigatureSubst-relative and each non-null Ligature offset is LigatureSet-relative. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-02, D-20]
- Retain set order by Coverage index, Ligature order exactly as listed, output GID, and each trailing component GID. Require all GIDs in range and, as the closed multiple-to-one invariant, `componentCount >= 2`; charge only the `componentCount-1` stored trailing components. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; VERIFIED: D-20]
- Do not sort or coalesce duplicate Ligature offsets/records; the stored order is later first-match preference. [VERIFIED: D-14, D-20]

#### GPOS Type 2 Format 1

- Compute each ValueRecord width as `2 * popcount(valueFormat & 0x00FF)` with checked arithmetic, while separately remembering unsupported low bits and reserved high bits. Prove the PairValueRecord stride and full PairSet extent before reading records. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-21, D-22, D-32]
- Require `pairSetCount == coverage.cardinality`. Within each PairSet, require second GIDs strictly increasing and `< num_glyphs`; retain all six normalized signed value planes (three per glyph), filling omitted allowed fields with zero. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-21, D-22]
- Read forbidden yAdvance fields and resolve every non-null device/variation offset from the PairSet base to a six-byte target before deferring capability. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-22]

#### GPOS Type 2 Format 2

- Require `class1Count >= 1` and `class2Count >= 1` because each domain includes class zero; check each factor against `max_classes`, their product against both `max_cross_product` and aggregate `max_class_cells`, and `cells * (valueWidth1+valueWidth2)` against `max_record_extent` before matrix traversal. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-19, D-21, D-32]
- Normalize Coverage and both ClassDefs. Coverage limits eligible first glyphs but need not have cardinality equal to a class count. Require every ClassDef value below its declared count. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-19, D-21]
- Traverse dense cells row-major (`class1 * class2Count + class2`), retain six signed planes, and use the PairPos subtable as the device-offset base. No positioning is applied. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-21, D-22, D-41]

#### Extensions

- Validate wrapper format 1 and its complete eight-byte envelope; resolve a nonzero Offset32 from the extension-subtable start with no 16-bit narrowing. Enforce one inner dispatch only. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-27]
- All extension subtables in one lookup must declare the same inner lookup type, as required by the specification; mixed inner types are `Data` before the closed-profile supported-type check. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos]
- Admit GSUB 7 only to 1/4 and GPOS 9 only to 2. Recursive/other inner types and other wrapper formats defer capability after target validity; zero/out-of-range/truncated targets are `Data`. [VERIFIED: D-27, D-28]

#### Selected FeatureParams

- `cv01`–`cv99`: require a 14-byte fixed header, format 0, checked `14 + 3*charCount`, valid uint24 Unicode scalar values, and `firstParamUiLabelNameId == 0` when `numNamedParameters == 0`. The documented name-ID ranges and completeness of the character list are recommendations, not Phase 109 rejection rules. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_ae; VERIFIED: D-12]
- `ss01`–`ss20`: require two uint16 fields and version 0; future trailing bytes cannot be assigned to this table because FeatureParams has no independent length, so only the defined four-byte envelope is claimed. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt; VERIFIED: D-12]
- `size`: require five uint16 values, nonzero design size, and a selected Feature with zero lookup references; validate the fixed array before capability classification. Cross-font range overlap cannot be determined from this request-local table and is not an admission rule. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt; VERIFIED: D-12, D-38]
- Other selected feature tags: because no parameter structure is defined, validate only a readable two-byte Feature-relative target and record the locked capability result. This is the documented MNF D-12 category rule, not a claim that the source is conforming OpenType. [VERIFIED: compatibility resolution for locked D-12]

### Revision and Lifetime Pattern

Add private admission probes beside `FontShapeTransactionProbes`, not new public mutation APIs. The production probe callbacks are no-ops; white-box tests inject a mutation at each exact stage. Each guard calls the same `Font::require_revision` authority used by Phase 108, and every private profile method added later must also require the active scope identity. [VERIFIED: live `shape_transaction.mbt`; D-36, D-38, D-40]

### Diagnostic Contract

Internal errors use operation `font-layout-admit`; `mb-text` preserves category/code while rebinding the operation to `text-shape` and strips any source offset, record ordinal, lookup index, or selected tag. `requested/limit` remain only for named semantic/resource ceilings, never for a source index. [VERIFIED: D-39; live `core_error.mbt` and shape rebind precedent]

Use only this sealed context vocabulary:

| Domain | Stable contexts |
|--------|-----------------|
| Headers/lists | `gsub-header`, `gpos-header`, `gdef-header`, `script-list`, `feature-list`, `lookup-list`, `feature-variations` [VERIFIED: D-39 recommendation] |
| Selection/records | `script-record-order`, `script-record-offset`, `language-record-order`, `language-record-offset`, `language-selection`, `lookup-order`, `feature-index`, `required-feature-index`, `feature-params`, `feature-record-order`, `feature-record-offset`, `lookup-index`, `lookup-record-offset`, `lookup-subtable-offset`, `layout-already-admitted` [VERIFIED: D-38, D-39 recommendation] |
| Common facts | `coverage-format`, `coverage-order`, `coverage-cardinality`, `classdef-format`, `classdef-range`, `classdef-class`, `lookup-flags`, `value-format`, `value-record` [VERIFIED: D-39 recommendation] |
| GSUB | `single-format`, `single-cardinality`, `single-substitute`, `ligature-format`, `ligature-set-cardinality`, `ligature-offset`, `ligature-component` [VERIFIED: D-39 recommendation] |
| GPOS | `pair-format`, `pairset-cardinality`, `pair-second-order`, `pair-class-count`, `pair-class-cell-extent` [VERIFIED: D-39 recommendation] |
| GDEF/extensions | `gdef-glyph-class`, `extension-format`, `extension-type`, `extension-target` [VERIFIED: D-39 recommendation] |
| Limits | exact kebab-case field names such as `max-gsub-bytes`, `max-coverage-glyphs`, `max-record-extent`, `max-retained-bytes`, `max-parser-work` [VERIFIED: D-31, D-39 recommendation] |

Do not include `GSUB`/`GPOS` source offsets, selected four-byte tags, raw counts used as record ordinals, font paths, or prose assembled from host strings. Private white-box summaries may return counts/kinds/order hashes to tests but must not appear in `moon info`. [VERIFIED: D-39, D-40]

### Recommended Project Structure

```text
modules/mb-font/font/
├── layout_limits.mbt               # public-abstract FontLayoutLimits
├── layout_model.mbt                # private normalized profile/data/charge ledgers
├── layout_cursor.mbt               # table-local offset/envelope helpers over cursor.mbt
├── layout_common.mbt               # headers, lists, selection, flags, Coverage/ClassDef
├── layout_gsub.mbt                 # GSUB 1/4/7 admission
├── layout_gpos.mbt                 # GPOS 2/9 admission
├── layout_gdef.mbt                 # conditional GDEF 1.0 classifier
├── layout_admission.mbt            # scope entry, staged precedence, profile creation
├── layout_*_wbtest.mbt             # private structural/charge/guard tests
└── layout_admission_test.mbt       # public abstract-surface and scope tests

modules/mb-text/text/
├── limits.mbt                      # embed defaults; additive with_layout_limits
├── shape.mbt                       # semantic request projection; still fail closed
├── limits_test.mbt                 # old/new constructor compatibility
└── shape_test.mbt                  # public rebind/atomicity/nonempty closure
```

These boundaries keep common offset/normalization logic acyclic while allowing body-specific tests and policy inventories to remain reviewable. If MoonBit's private type visibility makes a split awkward, merge private model/cursor into `layout_common.mbt`; do not change public ownership. [VERIFIED: project module conventions, D-30 discretion]

### Exact Implementation File Matrix

| File | Action | Required responsibility |
|------|--------|-------------------------|
| `modules/mb-font/font/layout_limits.mbt` | add | Public-abstract bundle, exact constructor, nonzero validation, private field access. [VERIFIED: D-30, D-31] |
| `modules/mb-font/font/layout_model.mbt` | add | Private profile, owned SoA facts, deferred capability, semantic/work/charge ledgers, private summaries. [VERIFIED: D-29, D-33, D-34, D-40] |
| `modules/mb-font/font/layout_common.mbt` | add | Table-local offset helper, headers/lists/selection/flags, Coverage/ClassDef, stable error contexts. [VERIFIED: D-01–D-19, D-25, D-26, D-39] |
| `modules/mb-font/font/layout_gsub.mbt` | add | GSUB 1/4 and one-hop 7 admission only. [VERIFIED: D-20, D-27, D-28, D-41] |
| `modules/mb-font/font/layout_gpos.mbt` | add | GPOS 2 and one-hop 9 admission, ValueRecord validation only. [VERIFIED: D-21, D-22, D-27, D-28, D-41] |
| `modules/mb-font/font/layout_gdef.mbt` | add | Conditional exact GDEF 1.0/GlyphClassDef binding. [VERIFIED: D-23–D-25] |
| `modules/mb-font/font/layout_admission.mbt` | add | Public scope method, staged global/deep pipeline, guard probes, final private profile/charge. [VERIFIED: D-33–D-40] |
| `modules/mb-font/font/shape_transaction.mbt` | modify | Keep `Font::with_shape_transaction` signature/one commit; share private active/revision helper, make staged font charge mutable, and enforce one admission per scope. [VERIFIED: live file and Phase 108 compatibility; D-35, D-38] |
| `modules/mb-text/text/limits.mbt` | modify | Embed conservative `FontLayoutLimits`; preserve exact existing constructor; add `with_layout_limits`. [VERIFIED: D-30; live file] |
| `modules/mb-text/text/shape.mbt` | modify | Project semantic tags/toggles into scope admission, rebind errors, preserve empty behavior and nonempty capability closure. [VERIFIED: D-39, D-46; live file] |
| `modules/mb-font/README.mbt.md` | modify | Document public-abstract limits/profile/scope method, accepted subset, charge/work/lifetime semantics, and divergence notes. [VERIFIED: public API documentation policy] |
| `modules/mb-font/CHANGELOG.md` | modify | Record additive experimental admission surface and closed subset. [VERIFIED: project SemVer/change policy] |
| `modules/mb-text/README.mbt.md` | modify | Document default/custom layout limits and Phase 109 nonempty fail-closed behavior. [VERIFIED: D-30, D-46] |
| `modules/mb-text/CHANGELOG.md` | modify | Record additive `ShapeLimits` customization without claiming shaping success. [VERIFIED: project SemVer/change policy] |
| `docs/rfcs/0004-mb-font.md` | modify | Record request-scoped normalized-layout authority and no raw inspection/cache. [VERIFIED: governance constraint, D-29, D-38, D-40] |
| `docs/rfcs/0005-mb-text.md` | modify | Record semantic request projection, limit ownership, and Phase 109 closure. [VERIFIED: governance constraint, D-30, D-46] |
| `policy/foundation.json` | modify | Add exact production/test inventories, interface lines, doc hashes, and new source hashes. [VERIFIED: live policy structure] |
| `scripts/quality/Assert-Policy.ps1` | modify | Update Phase 108 “only operation” assertion; seal exact new interfaces, contexts, source/test/docs lists; forbid raw layout/profile accessors, source offsets, execution, legacy metrics, caches, FFI/UI. [VERIFIED: live Phase 108 policy gates, D-39–D-46] |

### Exact Test File and Fixture Matrix

| File | Required cases |
|------|----------------|
| `modules/mb-font/font/layout_fixture_wbtest.mbt` (add) | Generated table/directory builders with explicit base labels; exact-end/one-short/overflow/noncontiguous/aliasing helpers; no licensed bytes. [VERIFIED: D-02, D-03, D-45] |
| `layout_common_wbtest.mbt` (add) | 1.0/1.1 headers; null/non-null FeatureVariations; every global list count/extent; all record offset fields selected and unselected; strict order/duplicate tags; exact/default/no-fallback selection; required/duplicate/out-of-range feature indices; lookup union/order; every Coverage/ClassDef boundary and cardinality. [VERIFIED: D-01–D-19] |
| `layout_gsub_wbtest.mbt` (add) | Single 1/2 success and all format/cardinality/GID/delta failures; Ligature bases/set cardinality/component extents/order/duplicate occurrence; type 7 offset above `0xFFFF`, zero/range/truncation/mixed inner type/recursive/other inner cases. [VERIFIED: D-20, D-27, D-28] |
| `layout_gpos_wbtest.mbt` (add) | PairPos 1 PairSet/Coverage equality and strict second GIDs; PairPos 2 factor/product/extent/ClassDef bounds/dense order; every allowed/forbidden ValueFormat bit for both glyphs, zero format, truncated field, nullable/non-null device target; type 9 matrix matching GSUB extension cases. [VERIFIED: D-21, D-22, D-27, D-28] |
| `layout_gdef_wbtest.mbt` (add) | No-flags skips absent/rich GDEF; each ignore flag/class; combined masks; absent/null/malformed GDEF as Data; exact 1.0 valid; non-1.0 structurally valid capability; classes 0–4 and >4; class 0/component visibility. [VERIFIED: D-23–D-25] |
| `layout_admission_wbtest.mbt` (add) | Deferred-capability versus later Data; resource traversal exception; all named guard mutations; scope escape/closure; profile summary only; selected unsupported cannot hide; duplicates retained; exact charge equations; no source-byte recharge; exact/one-short for every limit and charge dimension; failure leaves budget unchanged. [VERIFIED: D-13–D-15, D-31–D-40] |
| `layout_admission_test.mbt` (add) | Public constructor zero rejection, conservative/default/custom limits, scope method abstractness, no public profile accessor, direct invalid tag precedence, closed scope state, second-admission State failure. [VERIFIED: D-30, D-35, D-37–D-40] |
| `shape_transaction_test.mbt` / `shape_transaction_wbtest.mbt` (modify) | Existing signature/one-commit regressions plus admission charge composition and final guard without publishing raw facts. [VERIFIED: Phase 108 live tests, D-35, D-36] |
| `modules/mb-text/text/contract_test.mbt` (modify) | Old two-argument `ShapeLimits::new` unchanged; additive custom bundle; empty path unchanged; nonempty valid admission still `layout-unavailable`; public errors contain no tags/offsets/indices; exact invalid-input precedence. [VERIFIED: D-30, D-37, D-39, D-46] |
| `modules/mb-text/text/contract_wbtest.mbt` (modify) | Semantic projection, admitted private profile path, error rebind, capability/Data/resource/state matrix, transaction atomicity. [VERIFIED: D-35–D-39, D-46] |

Every offset field in the ledger gets at least: valid exact-end, zero legal/illegal, target one byte short of its minimum, count-derived body one byte short, checked-add overflow, sibling/noncontiguous target, and unselected-global versus unselected-body cases. Every semantic ceiling and each of `bytes`, `allocations`, `allocation_size`, and `work` gets exact-fit and one-short tests. [VERIFIED: D-02, D-03, D-05, D-31–D-35]

The generated compatibility-divergence corpus must contain: duplicate FeatureRecords otherwise valid (`Data` under D-09), non-null selected `rlig`/`liga`/`kern` parameters with a readable target (`Capability` under D-12), and recursive extension wrappers with valid targets (`Capability` under D-28). Test names/docs must call these “MNF closed-profile policy,” not OpenType-invalidity claims. [CITED: official OpenType sources in compatibility table; VERIFIED: locked decisions]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bounds/overflow arithmetic | Native-width index math or unchecked `base + offset` | Existing `@checked` and `cursor.mbt` UInt64 reads/windows | Prevents wrap and target-specific narrowing behavior. [VERIFIED: live source; D-01–D-03] |
| Source ownership | Copied raw GSUB/GPOS/GDEF buffers | Existing `Font` directory/table-local windows during the live scope | Source bytes are already immutable font-owned authority and must not be recharged/escaped. [VERIFIED: live `Font`, `directory.mbt`; D-29, D-33] |
| Budget transaction | Incremental budget debits or rollback | `ResourceCharge::checked_add`, hierarchy preflight, existing single `Budget::charge` | Guarantees exact atomic failure semantics. [VERIFIED: live `budget.mbt`, `shape_transaction.mbt`; D-35] |
| Lookup ordering | Sort-and-dedupe subtable records or hash iteration | Bitmap selected lookup indices, ascending LookupList scan, source-order subtable arrays | Encodes D-13 versus D-14 correctly and deterministically. [VERIFIED: D-13, D-14] |
| GDEF filtering | Infer glyph class from Unicode/cmap or glyph shape | Selected GDEF 1.0 GlyphClassDef | LookupFlag filtering is font layout metadata and the dependency is explicit. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-23–D-25] |
| Layout execution | Partial substitution/positioning during parsing | Normalize only; Phase 110/111 executors consume the profile later | Prevents incomplete output and cross-stage charge/order coupling. [VERIFIED: D-41–D-46] |
| Cache | Constructor-time or persistent profile cache | Request-local profile nested in `FontShapeScope` | Keeps caller-specific script/language/features/limits and revision authority correct. [VERIFIED: D-38] |

**Key insight:** the hard part is not decoding individual structs; it is preserving field-specific bases, selective validation depth, global error precedence, exact resource accounting, and callback lifetime simultaneously. Centralize those invariants in one admission builder rather than letting body parsers invent local policy. [VERIFIED: D-01–D-40]

## Common Pitfalls

### Pitfall 1: Using the Wrong Offset Base

**What goes wrong:** A valid offset lands in sibling bytes or a malicious offset is accidentally accepted. [CITED: official common/GSUB/GPOS/GDEF tables]

**Why it happens:** OpenType mixes layout-, list-, Script-, Feature-, Lookup-, subtable-, PairSet-, LigatureSet-, GDEF-, and extension-relative offsets. [CITED: official sources]

**How to avoid:** Encode the base kind at each call site and fixture label; do not provide a generic “resolve from current cursor” helper. [VERIFIED: D-02]

**Warning signs:** The parser passes contiguous fixtures but fails noncontiguous or sibling-alias fixtures. [VERIFIED: hostile-test recommendation]

### Pitfall 2: Returning Capability Before Discovering Malformed Selected Data

**What goes wrong:** An unsupported earlier body hides a later truncated or invalid selected body, violating D-15/D-37. [VERIFIED: D-15, D-37]

**Why it happens:** Straight-line dispatch returns on the first unsupported type. [VERIFIED: algorithm analysis]

**How to avoid:** Defer the first capability token while continuing bounded structural validation; return immediately only for Data, State, or the declared-count Resource exception. [VERIFIED: staged algorithm above]

**Warning signs:** Reordering two selected subtables changes `Data` into `Capability`. [VERIFIED: required regression]

### Pitfall 3: Over-Validating Unselected Rich Bodies

**What goes wrong:** A request rejects a font because an unrelated advanced lookup is unsupported. [VERIFIED: LAY-02, D-04, D-05]

**Why it happens:** A whole-table recursive validator treats admission as font linting. [VERIFIED: scope analysis]

**How to avoid:** Globally validate record arrays/targets/immediate envelopes only; deep-decode selected bodies and required dependencies. [VERIFIED: D-04, D-05]

**Warning signs:** Adding an unreferenced contextual lookup changes an otherwise admitted request. [VERIFIED: required fixture]

### Pitfall 4: Confusing Lookup De-duplication with Subtable De-duplication

**What goes wrong:** Duplicate lookup references execute twice, or duplicate subtable occurrences disappear and alter preference. [VERIFIED: D-13, D-14]

**Why it happens:** One generic set/sort operation is applied at both layers. [VERIFIED: architecture analysis]

**How to avoid:** Use a lookup bitmap and ascending scan only for LookupList indices; append subtable occurrences exactly as encoded. [VERIFIED: D-13, D-14]

**Warning signs:** A summary reports fewer subtable occurrences than the selected Lookup header declares. [VERIFIED: D-14]

### Pitfall 5: Charging Table Bytes or Forgetting Scratch Allocations

**What goes wrong:** The request double-charges font-owned bytes or underreports allocations/max allocation. [VERIFIED: D-33]

**Why it happens:** Source traversal, retained payload, and temporary selection storage are conflated. [VERIFIED: charge-model analysis]

**How to avoid:** `bytes` equals the normative retained coefficients only; `allocations` and `allocation_size` include every explicit retained/scratch array. [VERIFIED: D-33 and CFF precedent]

**Warning signs:** Two equivalent profiles from differently padded tables have different byte charges, or a one-short allocation budget succeeds. [VERIFIED: required regression]

### Pitfall 6: Treating RTL LookupFlag as Run Direction

**What goes wrong:** Admission or later execution reverses text based on a lookup metadata flag. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2]

**Why it happens:** The flag name resembles the caller's `Direction`. [VERIFIED: live `options.mbt`]

**How to avoid:** Retain `RIGHT_TO_LEFT` as non-operative lookup metadata only; run direction remains the caller option. [VERIFIED: D-25]

**Warning signs:** Changing only LookupFlag changes logical request direction. [VERIFIED: required regression]

### Pitfall 7: Assuming Factor Limits Bound Products

**What goes wrong:** Legal-looking class counts allocate an excessive dense matrix or an extent overflows. [VERIFIED: D-32]

**Why it happens:** Both factors fit `max_classes`, but their product does not fit cell/extent/work authority. [VERIFIED: D-19, D-32]

**How to avoid:** Check factors, product, byte extent, aggregate cells, allocation size, and future work separately before traversal. [VERIFIED: D-19, D-31, D-32, D-37]

**Warning signs:** A `512 × 512` case bypasses a smaller cell ceiling. [VERIFIED: required regression]

### Pitfall 8: Widening the Public Surface Through Test Helpers

**What goes wrong:** Raw lookup indices, summaries, source windows, mutation probes, or profile accessors appear in `pkg.generated.mbti`. [VERIFIED: D-29, D-40]

**Why it happens:** Cross-package integration tests reach for public debug access. [VERIFIED: policy analysis]

**How to avoid:** Keep summaries/probes white-box private and assert exact interface lines with `moon info` and policy. [VERIFIED: live policy pattern; D-40]

**Warning signs:** New public names contain `offset`, `lookup_index`, `table_view`, `summary`, `probe`, or `cache`. [VERIFIED: D-29, D-40 recommendation]

## Code Examples

Verified patterns adapted from existing repository code and the official table layouts:

### Checked Offset Target

```moonbit
// Source: existing cursor.mbt/@checked pattern; field base from OpenType layout spec.
fn layout_target(
  table : @bytes.ByteView,
  base : UInt64,
  offset : UInt64,
  nullable : Bool,
  minimum : UInt64,
  context : String,
) -> Result[@bytes.ByteView?, @error.CoreError] {
  if offset == 0UL {
    if nullable { return Ok(None) }
    return Err(layout_data_error(context))
  }
  let start = match @checked.checked_add(base, offset) {
    Err(_) => return Err(layout_data_error(context))
    Ok(value) => value
  }
  let end = match @checked.checked_add(start, minimum) {
    Err(_) => return Err(layout_data_error(context))
    Ok(value) => value
  }
  if end > table.length() {
    return Err(layout_data_error(context))
  }
  match table.subview(start, table.length() - start) {
    Err(_) => Err(layout_data_error(context))
    Ok(target) => Ok(Some(target))
  }
}
```

The implementation must map checked-arithmetic failures into the stable layout `Data` context and strip raw `source_offset` at the public text boundary. [VERIFIED: live `cursor.mbt`; D-03, D-39]

### Checked Record Extent Before Traversal

```moonbit
// Source: existing cff_admission.mbt preflight pattern.
fn record_extent(
  fixed : UInt64,
  count : UInt64,
  stride : UInt64,
  limit : UInt64,
  context : String,
) -> Result[UInt64, @error.CoreError] {
  let records = match @checked.checked_mul(count, stride) {
    Err(_) => return Err(layout_data_error(context))
    Ok(value) => value
  }
  let extent = match @checked.checked_add(fixed, records) {
    Err(_) => return Err(layout_data_error(context))
    Ok(value) => value
  }
  if extent > limit {
    Err(layout_resource_error(context, extent, limit))
  } else {
    Ok(extent)
  }
}
```

Callers first prove the fixed header readable, then classify a count/extent ceiling as Resource before entering the loop; source-window truncation remains Data. [VERIFIED: D-32, D-37; live CFF preflight precedent]

### Defer Capability Without Hiding Data

```moonbit
// Source: locked Phase 109 precedence; private pseudocode.
let mut capability : @error.CoreError? = None
for occurrence in selected_subtables {
  match admit_selected_subtable(occurrence) {
    Ok(body) => bodies.push(body)
    Err(error) =>
      match error.category() {
        @error.ErrorCategory::Capability =>
          if capability is None { capability = Some(error) }
        _ => return Err(error)
      }
  }
}
match capability {
  Some(error) => Err(error)
  None => Ok(bodies)
}
```

Only capability is deferred; State, Data, and declared-count Resource branches retain their locked immediate behavior. [VERIFIED: D-15, D-37]

### PairPos Class Matrix Preflight

```moonbit
// Source: OpenType PairPos format 2 fields and @checked repository pattern.
let cells = match @checked.checked_mul(class1_count, class2_count) {
  Err(_) => return Err(layout_data_error("pair-class-cell-extent"))
  Ok(value) => value
}
if cells > limits.max_cross_product() ||
   cells > limits.max_class_cells() {
  return Err(layout_resource_error(
    "max-class-cells",
    cells,
    limits.max_class_cells(),
  ))
}
let stride = match @checked.checked_add(value_width_1, value_width_2) {
  Err(_) => return Err(layout_data_error("pair-class-cell-extent"))
  Ok(value) => value
}
let matrix_bytes = match @checked.checked_mul(cells, stride) {
  Err(_) => return Err(layout_data_error("pair-class-cell-extent"))
  Ok(value) => value
}
```

The parser then proves the complete matrix window before allocating or iterating cells. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-19, D-21, D-32]

## State of the Art

| Old / broader approach | Current Phase 109 approach | Impact |
|------------------------|----------------------------|--------|
| Eagerly lint every reachable layout body | Validate global indirection envelopes, deep-normalize selected paths only | Avoids unrelated rich-table over-rejection while retaining global pointer safety. [VERIFIED: D-04, D-05] |
| Expose raw GSUB/GPOS objects to a shaping layer | Retain an opaque request-scoped normalized profile | Preserves font ownership, revision, and API compatibility boundaries. [VERIFIED: D-29, D-38, D-40] |
| Apply lookups while parsing | Separate admission (109), GSUB execution (110), GPOS execution (111) | Keeps failure/charge/order semantics reviewable and prevents incomplete runs. [VERIFIED: D-41–D-46] |
| Assume Offset16 everywhere | Admit one extension-relative Offset32 hop | Supports large layout tables without recursive wrapper complexity. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gsub; CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/gpos; VERIFIED: D-27, D-28] |

**Deprecated/outdated for this phase:**

- Constructor-time or persistent layout caching: prohibited; request selection and revision authority are callback-local. [VERIFIED: D-38]
- Whole-font semantic qualification from generated fixtures: prohibited; Phase 113 owns licensed/oracle/cross-target claims. [VERIFIED: D-45]
- Treating the current OpenType recommendation “FeatureRecords should be sorted” as a mandatory validity rule: not specification-accurate; D-09 is an explicit narrower MNF policy. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2; VERIFIED: D-09]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Recommendations are derived from locked project decisions, live source/policy, or cited official specifications. | — | — |

## Open Questions

None. The three specification divergences have deterministic planning resolutions: honor the locked MNF profile, document the compatibility restriction, and add explicit generated fixtures. [VERIFIED: locked CONTEXT authority and compatibility table]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | build/test/info/format | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: local command] |
| `moonc` | four-target compilation | ✓ | `v0.10.4+2cc641edf` | — [VERIFIED: local command] |
| `moonrun` | native test execution | ✓ | `0.1.20260713` (`75c7e1f`) | — [VERIFIED: local command] |
| PowerShell | policy gate | ✓ | repository host shell | — [VERIFIED: current environment and successful script/source inspection] |
| External fonts/services/packages | none | not required | — | Generated MoonBit fixtures are the mandated path. [VERIFIED: D-45] |

**Missing dependencies with no fallback:** None. [VERIFIED: environment audit]

**Missing dependencies with fallback:** None. [VERIFIED: environment audit]

Nyquist validation is explicitly disabled by `.planning/config.json`, so the template's Validation Architecture section is intentionally omitted. Implementation still requires the exact test matrix above because D-35 and the phase success criteria demand behavioral proof. [VERIFIED: `.planning/config.json`; D-35]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not set it to `false`. OpenType bytes are untrusted structured binary input, so bounded validation and resource controls are the applicable security domain. [VERIFIED: config; phase threat model]

### Applicable ASVS 4.0.3 Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identities or authentication occur in local font admission. [VERIFIED: phase architecture; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V3 Session Management | no | `FontShapeScope` is a local lifetime/revision capability, not an authenticated web session. [VERIFIED: live source; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V4 Access Control | yes, by analogy to object capability | Private fields, no raw accessors, active-scope check, owner/revision identity, exact public policy gate. [VERIFIED: D-29, D-36, D-38, D-40; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V5 Validation, Sanitization and Encoding | yes | Strongly typed tags/options, checked table-local offsets, schema/format/count/cardinality validation, fail-closed unsupported branches. [VERIFIED: D-01–D-28, D-37; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V6 Stored Cryptography | no | No secrets, hashes used for trust, encryption, or randomness are introduced. [VERIFIED: phase scope; CITED: https://owasp.org/www-project-application-security-verification-standard/] |

ASVS identifiers are version-sensitive; this report uses the requested 4.0.3 V2–V6 category naming rather than silently mapping to the reorganized ASVS 5.0 chapters. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Known Threat Patterns for the MoonBit Binary Parser

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Offset wrap, wrong base, out-of-window target | Tampering / Denial of Service | Checked UInt64 base addition, field-specific base, minimum and complete table-local envelope. [VERIFIED: D-01–D-03] |
| Declared-count/product bomb | Denial of Service | Fixed-header validation followed by count/product/extent/work/allocation preflight before traversal. [VERIFIED: D-31, D-32, D-34, D-37] |
| Unsupported body hides malformed body | Tampering | Deferred capability plus complete selected-body structural validation. [VERIFIED: D-15, D-37] |
| Time-of-check/time-of-use font mutation | Tampering | Named revision guards and scope-bound profile identity. [VERIFIED: D-36, D-38] |
| Raw offset/tag/path leakage through errors | Information Disclosure | Stable token vocabulary, public rebind, no source offsets/indices/tags/host prose. [VERIFIED: D-39] |
| Partial authority debit on failure | Denial of Service | Immutable charge staging, hierarchy preflight, one final commit only. [VERIFIED: D-33, D-35; live transaction] |
| Profile/table authority escape | Elevation of Privilege | Public-abstract types with no Phase 109 accessors, active scope checks, private summaries only. [VERIFIED: D-29, D-38, D-40] |

## Verification Commands for the Plan

| Gate | Command | Required result |
|------|---------|-----------------|
| Font behavioral suite | `moon -C modules/mb-font test font --target all --frozen` | All Phase 109 public/white-box fixtures pass on JS, Wasm, Wasm-GC, native. [VERIFIED: established Phase 108 command pattern] |
| Text contract suite | `moon -C modules/mb-text test text --target all --frozen` | Old/new limits, rebind, atomicity, and nonempty closure pass on all targets. [VERIFIED: established Phase 108 command pattern] |
| Interface generation | `moon -C modules/mb-font info --target all --frozen`; `moon -C modules/mb-text info --target all --frozen` | Exact additive public lines only; no raw fact/probe/cache accessor. [VERIFIED: established policy pattern] |
| Workspace roster | `moon test --target all --frozen --outline` | Phase 109 tests enumerate for all four targets. [VERIFIED: established Phase 108 command pattern] |
| Repository policy | `./scripts/quality/Assert-Policy.ps1` | Exact source/test/docs/interface/hash gates pass. [VERIFIED: live policy harness] |
| Formatting | `moon fmt --check` or repository-equivalent formatting gate | No Phase 109 formatting drift; pre-existing unrelated warnings are not misattributed. [VERIFIED: project workflow] |

Do not run or cite the licensed `FontQualification` lane as Phase 109 acceptance evidence; structural generated fixtures and four-target compile/test parity are allowed, but semantic qualification is Phase 113. [VERIFIED: D-45]

## Sources

### Primary Project Sources (HIGH confidence)

- `109-CONTEXT.md` — all locked D-01–D-46 decisions, discretion, phase boundary, deferred work, and canonical references. [VERIFIED: repository file]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md` — LAY-01/LAY-02, success criteria, milestone ownership, and deferred phases. [VERIFIED: repository files]
- Phase 108 context/research/patterns/verification — compile-proved transaction seam, exact public compatibility, and current test commands. [VERIFIED: repository files]
- Live `modules/mb-font/font/{cursor,directory,font,limits,cmap,kern,cff_admission,shape_transaction}.mbt` — checked windows, retained-fact coefficients, limits, font ownership, revision and charge precedents. [VERIFIED: codebase inspection]
- Live `modules/mb-text/text/{tags,options,limits,shape,run}.mbt` — semantic input projection, exact old constructor, empty/nonempty behavior, and one-way module integration. [VERIFIED: codebase inspection]
- Live `modules/mb-core/{budget,checked,error}` and `policy/foundation.json` / `scripts/quality/Assert-Policy.ps1` — charge composition, arithmetic/error contracts, exact interface/source/doc gates. [VERIFIED: codebase inspection]
- `docs/rfcs/0004-mb-font.md` and `0005-mb-text.md` — approved module ownership and public contract direction. [VERIFIED: repository files]
- Local MoonBit commands — installed `moon`, `moonc`, and `moonrun` versions. [VERIFIED: local execution on 2026-07-30]

### Official Technical Sources (MEDIUM confidence per research seam)

- [OpenType 1.9.1, OpenType Layout Common Table Formats](https://learn.microsoft.com/en-us/typography/opentype/spec/chapter2) — layout headers/lists, Script/LangSys/Feature/Lookup, LookupFlag, Coverage, ClassDef, FeatureParams policy, FeatureVariations. [CITED: official Microsoft specification]
- [OpenType 1.9.1, GSUB](https://learn.microsoft.com/en-us/typography/opentype/spec/gsub) — SingleSubst, LigatureSubst, ExtensionSubst fields/bases/restrictions. [CITED: official Microsoft specification]
- [OpenType 1.9.1, GPOS](https://learn.microsoft.com/en-us/typography/opentype/spec/gpos) — PairPos, PairSet, ValueRecord/ValueFormat, ExtensionPos fields/bases/restrictions. [CITED: official Microsoft specification]
- [OpenType 1.9.1, GDEF](https://learn.microsoft.com/en-us/typography/opentype/spec/gdef) — version headers, GlyphClassDef, glyph-class meanings. [CITED: official Microsoft specification]
- [OpenType 1.9.1 registered features A–E](https://learn.microsoft.com/en-us/typography/opentype/spec/features_ae) — `cvXX` FeatureParams 14-byte header and uint24 character array. [CITED: official Microsoft specification]
- [OpenType 1.9.1 registered features P–T](https://learn.microsoft.com/en-us/typography/opentype/spec/features_pt) — `size` five-uint16 parameters and `ssXX` two-uint16 parameters. [CITED: official Microsoft specification]
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/) — version-sensitive ASVS category reference. [CITED: official OWASP project]

### Tertiary Sources

None. No training-only or community-source claim is used. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — exact installed versions and repository-owned dependencies were inspected locally. [VERIFIED: local commands and live source]
- Architecture/integration: HIGH — the Phase 108 source, module direction, public interfaces, policy assertions, and transaction behavior were inspected directly. [VERIFIED: live code/policy]
- OpenType field semantics: MEDIUM — every relevant field was checked against the official OpenType 1.9.1 documentation; the research seam classifies verified websearch as MEDIUM. [CITED: official OpenType links; VERIFIED: `classify-confidence --provider websearch --verified`]
- Limits/defaults and storage coefficients: HIGH as a planning recommendation — values are within explicit user discretion, nonzero, exact, and tied to required one-short tests; they are not claimed as industry defaults. [VERIFIED: D-30–D-35 discretion]
- Pitfalls/security: HIGH for project-specific risks and MEDIUM for ASVS taxonomy — each risk follows a locked invariant or live authority boundary, while ASVS is externally cited. [VERIFIED: context/source; CITED: official OWASP]

**Research date:** 2026-07-30

**Valid until:** 2026-08-29 for the stable OpenType 1.9.1/locked phase contract; re-run live interface/toolchain checks if Phase 108 code or the pinned MoonBit toolchain changes earlier. [VERIFIED: 30-day stable-domain policy and live dependency sensitivity]
