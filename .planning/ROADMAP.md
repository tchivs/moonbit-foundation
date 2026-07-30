# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5 (shipped 2026-07-17). [Full history](./milestones/v0.1-ROADMAP.md)
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8, deliberately deferred without a registry mutation.
- ✅ **v0.3 Image Processing Core** — Phases 9-12 (shipped 2026-07-20). [Full history](./milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Portable Image Interchange** — Phases 13-16 (shipped 2026-07-20). [Full history](./milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 QOI Streaming I/O** — Phases 17-19 (shipped 2026-07-20). [Full history](./milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 PNG Interchange** — Phases 20-22 (shipped 2026-07-21).
- ✅ **v0.7 PNG Colour Fidelity** — Phases 23-25 (shipped 2026-07-21).
- ✅ **v0.8 Resumable PNG Decode** — Phases 26-28 (shipped 2026-07-21). [Full history](./milestones/v0.8-ROADMAP.md)
- ✅ **v0.9 Resumable PNG Encode** — Phases 29-31 (shipped 2026-07-21). [Full history](./milestones/v0.9-ROADMAP.md)
- ✅ **v0.10 PNG Compression Optimization** — Phases 32-34 (shipped 2026-07-22). [Full history](./milestones/v0.10-ROADMAP.md)
- ✅ **v0.11 PNG Dynamic Huffman Compression** — Phases 35-37 (shipped 2026-07-22). [Full history](./milestones/v0.11-ROADMAP.md)
- ✅ **v0.12 PNG Filter Optimization** — Phases 38-40 (shipped 2026-07-22). [Full history](./milestones/v0.12-ROADMAP.md)
- ✅ **v0.13 PNG Adam7 Encode** — Phases 41-43 (shipped 2026-07-22). [Full history](./milestones/v0.13-ROADMAP.md)
- ✅ **v0.14 Gray8 PNG Interchange** — Phases 44-46 (shipped 2026-07-22). [Full history](./milestones/v0.14-ROADMAP.md)
- ✅ **v0.15 Gray16 PNG Interchange** — Phases 47-49 (shipped 2026-07-22). [Full history](./milestones/v0.15-ROADMAP.md)
- ✅ **v0.16 Grayscale Alpha PNG** — Phases 50-52 (shipped 2026-07-23). [Full history](./milestones/v0.16-ROADMAP.md)
- ✅ **v0.17 GrayAlpha16 PNG Interchange** — Phases 53-55 (shipped 2026-07-23). [Full history](./milestones/v0.17-ROADMAP.md)
- ✅ **v0.18 GrayAlpha16 Adam7 PNG** — Phases 56-58 (shipped 2026-07-23). [Full history](./milestones/v0.18-ROADMAP.md)
- ✅ **v0.19 GrayAlpha8 Adam7 PNG** — Phases 59-61 (shipped 2026-07-23). [Full history](./milestones/v0.19-ROADMAP.md)
- ✅ **v0.20 High-Precision GrayAlpha Decode** — Phases 62-64 (shipped 2026-07-23). [Full history](./milestones/v0.20-ROADMAP.md)
- ✅ **v0.21 RGBA16 PNG Decode** — Phases 65-68 (shipped 2026-07-23). [Full history](./milestones/v0.21-ROADMAP.md)
- ✅ **v0.22 RGBA16 PNG Encode** — Phases 69-72 (shipped 2026-07-23). [Full history](./milestones/v0.22-ROADMAP.md)
- ✅ **v0.23 Low-Bit Grayscale PNG Encode** — Phases 73-75 (shipped 2026-07-24). [Full history](./milestones/v0.23-ROADMAP.md)
- ✅ **v0.24 Indexed PNG Encode** — Phases 76-78 (shipped 2026-07-24). [Full history](./milestones/v0.24-ROADMAP.md)
- ✅ **v0.25 Indexed Low-Bit PNG Encode** — Phases 79-80 (shipped 2026-07-24). [Full history](./milestones/v0.25-ROADMAP.md)
- ✅ **v0.26 Indexed8 Adam7 PNG Encode** — Phases 81-82 (shipped 2026-07-24). [Full history](./milestones/v0.26-ROADMAP.md)
- ✅ **v0.27 Low-Bit Indexed Adam7 PNG Encode** — Phases 83-84 (shipped 2026-07-24). [Full history](./milestones/v0.27-ROADMAP.md)
- ✅ **v0.28 Indexed PNG Compression Profiles** — Phases 85-87 (shipped 2026-07-24). [Full history](./milestones/v0.28-ROADMAP.md)
- ✅ **v0.29 Indexed Adam7 Compression Profiles** — Phases 88-90 (shipped 2026-07-24). [Full history](./milestones/v0.29-ROADMAP.md)
- ✅ **v0.30 SVG Production Readiness** — Phases 91-94 (shipped 2026-07-26). [Full history](./milestones/v0.30-ROADMAP.md)
- ✅ **v0.31 SVG Numeric Boundary Unification** — Phases 95-96 (shipped 2026-07-26). [Full history](./milestones/v0.31-ROADMAP.md)
- ✅ **v0.32 TrueType Font Foundation** — Phases 97-100 (shipped 2026-07-28). [Full history](./milestones/v0.32-ROADMAP.md)
- ✅ **v0.33 TrueType Collection Adapters** — Phases 101-103 (shipped 2026-07-28). [Full history](./milestones/v0.33-ROADMAP.md)
- ✅ **v0.34 CFF Outline Foundation** — Phases 104-107 (shipped 2026-07-30). [Full history](./milestones/v0.34-ROADMAP.md)
- 📋 **v0.35 Text Shaping Foundation** — Phases 108-113 (planned)

## Overview

v0.35 delivers one bounded, pure-MoonBit path from explicit single-font Unicode scalar runs to immutable positioned glyph runs. The phases freeze the public and transactional contract first, admit only normalized selected OpenType layout facts, execute GSUB before metrics and positioning, establish one GPOS-or-legacy kerning authority, harden the complete operation as one resource and mutation transaction, and only then seal licensed and byte-equal four-target evidence. The closed profile remains horizontal and Latin-style: richer selected behavior fails explicitly rather than being skipped or mistaken for general multilingual shaping.

## Phases

- [x] **Phase 108: Public Contract and Transaction Skeleton** - Freeze the format-neutral run contract and one-commit opaque `mb-font`/`mb-text` transaction boundary. (completed 2026-07-30)
- [ ] **Phase 109: Bounded Layout Admission** - Resolve selected OpenType layout into bounded normalized facts without exposing raw font data.
- [ ] **Phase 110: Deterministic GSUB and Source Clusters** - Produce final glyph identities and scalar provenance in logical shaping order before metrics.
- [ ] **Phase 111: GPOS and Kerning Authority** - Produce exact positioned advances and offsets under one modern-or-legacy kerning decision.
- [ ] **Phase 112: Integrated Transaction, Resource, and Mutation Hardening** - Make the complete shaping operation bounded, atomic, mutation-safe, and compatibility-preserving.
- [ ] **Phase 113: Interoperability and Four-Target Qualification** - Seal generated, licensed, hostile, compatibility, and target-equality evidence.

## Phase Details

### Phase 108: Public Contract and Transaction Skeleton

**Goal**: Library authors have a stable format-neutral shaping contract whose prepared values can cross the opaque font/text boundary and publish only after one combined authority commit.
**Depends on**: Phase 107 (qualified opaque static `glyf`/CFF1 `Font` foundation)
**Requirements**: TXT-01, TXT-02
**Success Criteria** (what must be TRUE):

  1. Library authors can express one font, bounded scalar input, exact script, default-or-exact language, LTR or RTL direction, closed `rlig`/`liga`/`kern` policy, limits, and caller budget without locale, discovery, fallback, normalization, bidi, I/O, or raw OpenType state.
  2. A prepared immutable run exposes only same-font opaque glyph identities, zero-based scalar-origin clusters, checked signed design-unit advances and x/y offsets, `units_per_em`, explicit direction, and checked total advance.
  3. Generated contract cases freeze empty-input behavior, LTR logical pen order, RTL final pen order and signed pen deltas, ligature minimum-source clusters, option validation, and stable structured error-stage precedence.
  4. A private prepared value is either discarded with caller and ancestor authority unchanged or published after one checked aggregate charge; no raw byte view, offset, lookup record, persistent cache, module cycle, or second commit is observable.

**Plans**: 5/5 plans executed

- [x] 108-01-PLAN.md
- [x] 108-02-PLAN.md
- [x] 108-03-PLAN.md
- [x] 108-04-PLAN.md
- [x] 108-05-PLAN.md

**Likely plan structure**:

- Establish `mb-text` module boundaries, typed options, limits, immutable records, numeric/order semantics, and generated contract fixtures.
- Add checked immutable charge composition plus the opaque `mb-font` continuation/outcome shape.
- Freeze empty-input, RTL, cluster, error taxonomy, stage precedence, and cross-target public-contract behavior.

**Research flag**: Required — verify MoonBit generic continuation/export ergonomics; freeze the signed RTL pen-delta projection, empty-input validation/charge behavior, and complete stage precedence matrix before implementation.

### Phase 109: Bounded Layout Admission

**Goal**: Library authors can select the supported layout path from an admitted font while malformed, unreachable, and unsupported data are distinguished deterministically behind an opaque normalized profile.
**Depends on**: Phase 108
**Requirements**: LAY-01, LAY-02
**Success Criteria** (what must be TRUE):

  1. Exact script and default-or-exact LangSys selection includes the required feature and enabled `rlig`/`liga`/`kern` choices, de-duplicates lookup references, and yields one ascending LookupList-order plan with stored subtable preference.
  2. Selected Coverage 1/2, ClassDef 1/2, GDEF 1.0 `GlyphClassDef`, admitted class-ignore flags, and one-hop GSUB 7→1/4 or GPOS 9→2 paths are accepted only when every offset, range, cardinality, class, glyph, and dependency is valid.
  3. Selected recursive wrappers, reserved flags, mark filtering/attachment classes, non-null FeatureVariations, or other deferred capabilities fail closed, while unrelated unselected rich tables do not prevent an otherwise supported request.
  4. Maintainers can reproduce exact-fit and one-short outcomes for every admitted count, byte window, 16/32-bit offset base, matrix/product, retained allocation, parser-work, and source-stage guard with stable table-specific diagnostics.
  5. No successful or failed request exposes raw table bytes, offsets, coverage/class arrays, feature/lookup indices, mutable source state, or a reusable stale profile.

**Plans**: 0/9 plans executed
**Wave 1**

- [ ] 109-02-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 109-01-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 109-03-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 109-04-PLAN.md
- [ ] 109-05-PLAN.md
- [ ] 109-06-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 109-07-PLAN.md

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 109-08-PLAN.md

**Wave 7** *(blocked on Wave 6 completion)*

- [ ] 109-09-PLAN.md

**Likely plan structure**:

- Implement typed table-local windows, GSUB/GPOS 1.0 and closed 1.1 headers, and Script/LangSys/Feature/Lookup selection.
- Normalize Coverage/ClassDef/GDEF filtering facts with all sortedness, uniqueness, cardinality, and glyph/class bounds.
- Add one-hop extension dispatch, selected-versus-unselected capability rules, semantic ceilings, and stage guards.
- Close the offset-base ledger and hostile exact/one-short admission corpus through the opaque profile seam.

**Research flag**: Required — enumerate every offset base, cardinality relation, sortedness rule, selected/unselected validation depth, GDEF-absence outcome, null/non-null FeatureVariations case, and 32-bit extension bound.

### Phase 110: Deterministic GSUB and Source Clusters

**Goal**: Library authors can deterministically obtain the final substituted glyph stream and source provenance before any metric or positioning decision.
**Depends on**: Phase 109
**Requirements**: SUB-01
**Success Criteria** (what must be TRUE):

  1. Valid scalar arrays map through the existing canonical cmap into logical same-font glyph seeds with exact scalar-origin intervals; valid misses remain glyph zero and invalid scalars publish nothing.
  2. Selected GSUB SingleSubst formats 1/2 and LigatureSubst format 1 execute once in canonical lookup order with stored subtable and ligature preference, and every substitute GID is validated against the receiving font.
  3. Class filtering can traverse ignored glyphs without deleting them; ligatures consume only matched component indices, preserve skipped glyph order, and publish the minimum source scalar index of consumed components.
  4. LTR and RTL cases shape logical input rather than reversing it early, publish the frozen final pen order, and initialize base metrics only from the final substituted GIDs.
  5. Generated single, ligature, repeated/supplementary scalar, ignored-mark, `.notdef`, and selected-capability cases reproduce exact glyph order, clusters, metrics, probe counts, and atomic failures.

**Plans**: TBD during phase planning

**Likely plan structure**:

- Add whole-array scalar preflight, existing cmap reuse, logical source intervals, and SingleSubst execution.
- Add preference-ordered LigatureSubst with filtered matched-index traversal and exact source-cluster propagation.
- Close LookupList/subtable execution, LTR/RTL final ordering, final-GID metrics, work probes, and generated behavioral fixtures.

**Research flag**: No separate research pass expected — proceed from Phases 108-109 decisions and generated executable cases; do not reopen direction, lookup ordering, filtering, or profile scope.

### Phase 111: GPOS and Kerning Authority

**Goal**: Library authors receive checked final design-unit placement and advance facts from one unambiguous modern GPOS or legacy kerning authority.
**Depends on**: Phase 110
**Requirements**: POS-01, KRN-01
**Success Criteria** (what must be TRUE):

  1. PairPos format 1 applies strictly ordered explicit pairs only when PairSet count and Coverage cardinality agree, including valid zero formats and ValueRecords for either glyph.
  2. PairPos format 2 applies explicit class-0 semantics only after checked ClassDef bounds and class-matrix extent preflight; malformed or excessive matrices publish no positioned result.
  3. Successive selected lookups accumulate only `xPlacement`, `yPlacement`, and `xAdvance` in checked `Int64`, follow the frozen next-probe rule in both directions, and produce checked signed pen deltas and total advance.
  4. `kern=true` chooses supported selected GPOS `kern` for the whole run or legacy format-0 only when that route is absent; `kern=false` disables both, and neither pair misses nor malformed/unsupported GPOS trigger per-pair legacy fallback.
  5. Hand-derived LTR/RTL explicit-pair, class-pair, both-glyph, accumulation, overflow-boundary, feature-toggle, and modern/legacy coexistence cases reproduce exact positioned records.

**Plans**: TBD during phase planning

**Likely plan structure**:

- Decode and execute the closed ValueRecord model and PairPos format 1 with ordered-pair evidence.
- Normalize class definitions and execute PairPos format 2 with class-0 and checked dense-matrix boundaries.
- Freeze pair traversal, checked accumulation, signed direction projection, total advance, and exact overflow/resource behavior.
- Integrate the run-level GPOS/legacy authority decision and coexistence/feature-toggle fixtures.

**Research flag**: Required — freeze the complete allowed ValueFormat mask, both-glyph application, PairPos next-probe rule for LTR and RTL, class-0 matrix semantics, and signed adjustment examples before implementation.

### Phase 112: Integrated Transaction, Resource, and Mutation Hardening

**Goal**: Library authors can shape hostile inputs without partial runs, partial authority consumption, stale publication, or regressions in existing font behavior.
**Depends on**: Phase 111
**Requirements**: SAF-01, CMP-01
**Success Criteria** (what must be TRUE):

  1. Every parser, lookup, failed match, filtered skip, compaction, metric, positioning, output, byte, allocation, allocation-size, and work dimension is included in one checked aggregate charge with exact-fit success and one-short failure.
  2. Malformed, unsupported, over-limit, over-budget, overflowing, and source-mutated requests produce the frozen structured precedence and leave no partial run or caller/ancestor budget delta.
  3. Mutation at admission, GSUB, metrics, GPOS, completed-private-run, and final-publication probes is detected through the retained font authority; success performs one final source guard, one commit, and one immutable publication.
  4. Existing standalone/collection, static-`glyf`/CFF1, cmap, metrics, public legacy-kern query, outline, dependency, and public-interface behavior remains unchanged except for the reviewed additive opaque seam and new `mb-text` module.
  5. The complete current successor of the frozen v0.34 regression passes together with explicit API/dependency diffs and cross-target canonical error/resource records.

**Plans**: TBD during phase planning

**Likely plan structure**:

- Derive the complete execution work equation and exact bytes/allocations/allocation-size ledger from actual retained representations and loops.
- Close caller/ancestor exact-fit and one-short matrices plus deterministic multi-fault error precedence.
- Exercise mutation at every frozen stage and prove one final guard, one charge, and one publication.
- Run compatibility, public-interface, dependency, outline-format, standalone/collection, and four-target regression gates.

**Research flag**: Required — derive the ledger from the implemented loops and representations rather than reusing CFF limits; freeze collision precedence and canonical charge/error records before hardening.

### Phase 113: Interoperability and Four-Target Qualification

**Goal**: Maintainers can reproduce trustworthy, license-complete, target-identical shaping evidence through the exact public transaction.
**Depends on**: Phase 112
**Requirements**: QUA-01
**Success Criteria** (what must be TRUE):

  1. Equivalent generated static `glyf` and CFF1 fonts, both standalone and selected from collections, produce the same hand-derived public glyph, cluster, advance, offset, direction, total, error, and budget facts.
  2. Pinned DejaVu Sans and Source Sans cases execute only the admitted profile through the public route; Source Sans demonstrably covers the selected GDEF ignore and GPOS 9→2 path without widening production behavior.
  3. Every licensed font, license, generated fixture, hostile row, host tool, adapter, invocation, raw output, canonical output, and compatibility input is provenance- and digest-bound before evidence publication.
  4. Pinned fontTools remains structural and pinned `hb-shape` remains an independent comparison; hand-derived facts remain normative and neither tool is a production dependency or an automatic baseline authority.
  5. Isolated `js`, `wasm`, `wasm-gc`, and `native` runs emit byte-identical normalized semantic payloads, after which a workload-declared native observation is recorded without a timing threshold or cross-runtime performance claim.

**Plans**: TBD during phase planning

**Likely plan structure**:

- Build equivalent generated `glyf`/CFF1 and standalone/collection fixtures with hand-derived shaping and hostile facts.
- Provision and pin host-only fontTools/HarfBuzz adapters, licenses, manifests, and exact DejaVu/Source Sans selected paths.
- Materialize one canonical hostile/compatibility semantic carrier and validate the complete public workflow.
- Produce isolated four-target records and prove byte-equal normalized payloads.
- Record the observation-only native workload and seal the final milestone evidence gate.

**Research flag**: Required — bind the exact Source Sans selected path, extracted `hb-shape` digest, explicit cluster/shaper/output options, all licenses/provenance fields, and canonical carrier schema before recording any baseline.

## Coverage

| Requirement | Phase | Observable outcome |
|-------------|-------|--------------------|
| TXT-01 | Phase 108 | Explicit bounded single-font shaping input and transaction contract |
| TXT-02 | Phase 108 | Stable immutable positioned-run semantics |
| LAY-01 | Phase 109 | Exact deterministic Script/LangSys/Feature/Lookup selection |
| LAY-02 | Phase 109 | Bounded selected Coverage/ClassDef/GDEF/extension profile |
| SUB-01 | Phase 110 | Deterministic GSUB and source provenance |
| POS-01 | Phase 111 | Checked PairPos positioning |
| KRN-01 | Phase 111 | One run-level GPOS-or-legacy authority |
| SAF-01 | Phase 112 | Atomic resource, mutation, and error behavior |
| CMP-01 | Phase 112 | Frozen font and dependency compatibility |
| QUA-01 | Phase 113 | Reproducible licensed and four-target qualification |

**Coverage validation**: 10/10 v0.35 requirements mapped exactly once; no orphaned or duplicate mappings.

## Progress

**Execution Order:** Phase 108 → Phase 109 → Phase 110 → Phase 111 → Phase 112 → Phase 113

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 108. Public Contract and Transaction Skeleton | 5/5 | Complete    | 2026-07-30 |
| 109. Bounded Layout Admission | 0/9 | Planned    |  |
| 110. Deterministic GSUB and Source Clusters | 0/TBD | Not started | - |
| 111. GPOS and Kerning Authority | 0/TBD | Not started | - |
| 112. Integrated Transaction, Resource, and Mutation Hardening | 0/TBD | Not started | - |
| 113. Interoperability and Four-Target Qualification | 0/TBD | Not started | - |

---
*Roadmap last updated: 2026-07-30 for v0.35 Text Shaping Foundation planning.*
