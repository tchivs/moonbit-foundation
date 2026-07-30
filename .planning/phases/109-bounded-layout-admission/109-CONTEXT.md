# Phase 109: Bounded Layout Admission - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 109 admits and normalizes only the selected, closed OpenType layout path
behind the Phase 108 request-scoped font transaction. It closes table-local
windows, offset bases, selection, dependencies, limits, charges, mutation
guards, and stable diagnostics for GSUB 1/4 and 7→1/4, GPOS 2 and 9→2,
Coverage/ClassDef 1/2, and selected GDEF 1.0 glyph classes. It does not execute
substitution or positioning, choose legacy kerning, publish raw layout facts,
or make licensed/cross-target semantic qualification claims.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 109 goal, criteria, boundaries, and research flag.
- `.planning/REQUIREMENTS.md` — LAY-01/LAY-02 and milestone traceability.
- `.planning/PROJECT.md` — v0.35 scope and deferred capabilities.
- `.planning/research/SUMMARY.md` — chosen closed layout profile and phase decomposition.
- `.planning/research/ARCHITECTURE.md` — module ownership and transaction integration.
- `.planning/research/FEATURES.md` — selection, ordering, and normalized-fact semantics.
- `.planning/research/PITFALLS.md` — offset-base, over-validation, GDEF, extension, and resource hazards.

### Precedent contracts

- `.planning/phases/108-public-contract-and-transaction-skeleton/108-CONTEXT.md` — locked public request/run/transaction/error behavior.
- `.planning/phases/108-public-contract-and-transaction-skeleton/108-RESEARCH.md` — compile-proved scope seam and extensible private limit representation.
- `.planning/phases/108-public-contract-and-transaction-skeleton/108-PATTERNS.md` — closest file/test/policy analogs.
- `.planning/phases/108-public-contract-and-transaction-skeleton/108-VERIFICATION.md` — verified Phase 108 baseline and prohibitions.
- `docs/rfcs/0004-mb-font.md` — font ownership and opaque authority.
- `docs/rfcs/0005-mb-text.md` — text module contract and phase boundaries.

### Existing implementation assets

- `modules/mb-font/font/cursor.mbt` — checked UInt64 reads and windows.
- `modules/mb-font/font/directory.mbt` — table-local window and offset patterns.
- `modules/mb-font/font/cmap.mbt` — compact normalized selected facts.
- `modules/mb-font/font/kern.mbt` — bounded pair-table normalization and binary search.
- `modules/mb-font/font/limits.mbt` — nonzero private-field limit model.
- `modules/mb-font/font/font.mbt` — retained source and glyph authority.
- `modules/mb-font/font/shape_transaction.mbt` — callback lifetime, revision cell, combined charge, and sole commit.
- `modules/mb-core/budget/budget.mbt` — checked immutable charge composition and hierarchy preflight.
- `modules/mb-core/error/core_error.mbt` — structured error facts and canonical rendering.
- `modules/mb-text/text/limits.mbt` — public ShapeLimits compatibility seam.
- `modules/mb-text/text/shape.mbt` — public validation, error precedence, generated facts, and fail-closed nonempty branch.

### External specification

- OpenType 1.9.1 common layout, GSUB, GPOS, and GDEF specifications — research must verify every field base, nullable offset, minimum header, sortedness/cardinality rule, FeatureParams case, GDEF-version decision, and extension bound before planning.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `cursor.mbt` / `directory.mbt`: checked UInt64 arithmetic, range proof, and bounded subviews.
- `cmap.mbt` / `kern.mbt`: compact owned normalized facts and deterministic lookup ordering.
- `budget.mbt`: exact portable charge dimensions and one hierarchy-wide preflight.
- `shape_transaction.mbt`: revision-bound callback scope and one commit.
- `core_error.mbt`: stable category/code/operation/context representation.

### Established Patterns

- Parse and normalize selected data into private owned facts; never retain public raw views.
- Validate fixed envelopes and semantic ceilings before attacker-sized traversal.
- Fail closed on selected unsupported capability while avoiding deep validation of unrelated rich bodies.
- Additive public changes are exact-interface and policy sealed on all four targets.

### Integration Points

- Extend `FontShapeScope` with private layout admission beside `shape_transaction.mbt`.
- Add private layout admission/normalization files under `modules/mb-font/font`.
- Extend `ShapeLimits` additively in `modules/mb-text/text/limits.mbt`.
- Route `shape.mbt` through private admission but keep public nonempty output capability-closed.

</code_context>

<specifics>
## Specific Ideas

- A field-by-field offset-base ledger and a generated exact/one-short hostile matrix are first-class deliverables, not incidental parser tests.
- Normalize ascending lookup indices while preserving subtable occurrence order and first-match preference.
- Treat selected dependency absence as malformed data when execution cannot honor declared lookup flags.

</specifics>

<deferred>
## Deferred Ideas

- GSUB application, ligature clusters, metric refresh — Phase 110.
- GPOS application and modern/legacy kerning authority — Phase 111.
- Integrated charges/mutation/atomicity — Phase 112.
- Licensed/oracle/four-target semantic qualification — Phase 113.
- Contextual/chained/reverse substitution, cursive/mark attachment, mark filtering sets, mark attachment classes, variables, FeatureVariations execution, caches, UI, FFI, and public raw layout inspection — future milestones.

</deferred>

---

*Phase: 109-bounded-layout-admission*
*Context gathered: 2026-07-30*
