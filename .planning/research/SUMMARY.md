# Project Research Summary

**Project:** MoonBit Native Foundation — v0.34 CFF Outline Foundation
**Domain:** Bounded static OpenType CFF1 admission and Type 2 CharString execution to reusable cubic `Path2`
**Researched:** 2026-07-28
**Confidence:** MEDIUM overall; HIGH for project scope and repository integration seams

## Executive Summary

v0.34 is a code-first extension of the existing `tchivs/mb-font` foundation, not a new public CFF library or foreign-font wrapper. The honest desktop-grade slice is static OpenType CFF1 in both name-keyed Latin and CID-keyed CJK forms, opened from standalone `OTTO` SFNTs or selected TTC/OTC faces through the existing opaque `Font`. Public Unicode mapping, glyph identity, metrics, kerning, errors, and outline queries remain format-neutral; CFF curves are emitted directly as the existing `Path2::CubicTo`. Experts build this as a checked CFF data-model parser feeding a bounded Type 2 virtual machine, with format-specific facts kept behind a closed private `Glyf | Cff1` outline-source dispatch.

The recommended implementation remains pure MoonBit on the pinned v0.33 toolchain with `tchivs/mb-core` as the sole runtime dependency. One reusable INDEX decoder and typed Top/Font/Private DICT schemas establish checked CFF-local windows and resolve one unambiguous CharString, Private DICT, FontMatrix, and local-subroutine environment per GID. One iterative fixed-point Type 2 VM then serves two sinks: an admission-time validation/bounds sink for every glyph and a query-time path sink for one glyph. Hints are fully parsed because they frame bytecode, but their rendering effects are ignored. Every operation uses explicit limits, cumulative work accounting, mutation guards, private scratch state, and one final budget commit before publishing a `Font` or `Path2`.

The largest risks are wrong offset bases, incomplete CID keying, treating the Type 2 depth ceiling as sufficient resource control, hint-mask desynchronization, target-dependent arithmetic or random behavior, partial metric/bounds publication, TTC double rebasing, and self-confirming fixture evidence. Mitigation drives the roadmap order: first freeze structural profile/keying facts, then freeze VM and admission-time bounds semantics, then expose cubic paths and collection integration, and only then close licensed, hostile, compatibility, and four-target evidence. CFF2/variable execution, WOFF, shaping, hint execution, rasterization, color/bitmap glyphs, and authoring remain explicit later capabilities rather than partial v0.34 acceptance.

## Key Findings

### Recommended Stack

Extend the existing module in place. No new runtime dependency, public module, FFI layer, ambient I/O, database, native font engine, or target-specific implementation is justified. External font tooling belongs only in an integrity-pinned host qualification lane; generated MoonBit fixtures and hand-derived vectors remain the normative regression base.

**Core technologies:**

- **MoonBit `moon` / `moonrun` `0.1.20260713` and `moonc v0.10.4+2cc641edf`**: build and run the same implementation on `js`, `wasm`, `wasm-gc`, and `native` — preserves the exact validated v0.33 baseline.
- **`tchivs/mb-font@0.1.0`**: owns the opaque `Font`, collection selection, metrics, cmap, kern, glyph identity, and outline API — CFF1 must be a private second outline profile, not a parallel public type.
- **`tchivs/mb-core@0.1.0`**: remains the sole runtime dependency — its retained `ByteView`, checked arithmetic, budget, structured errors, mutation revision, and cubic `Path2` already provide the required primitives.
- **OpenType 1.9.1 plus Adobe Technical Notes #5176 and #5177**: normative static CFF1, OpenType integration, INDEX/DICT/CID structures, Type 2 semantics, and hard format ceilings.
- **Checked signed Q16.16 in `Int64`**: VM operands, coordinates, transient values, arithmetic, and FontMatrix application — avoids cross-target drift; conversion to `Double` occurs only while publishing final `Point2` values.
- **Pinned host oracles**: fontTools `4.63.0`, AFDKO `5.0.1`, and OTS `9.2.0` — qualification-only structural and semantic cross-checks, never production dependencies or the sole source of expected results.

**Critical version and profile requirements:**

- Admit the new profile only for `OTTO` with exactly one `CFF ` table, no `CFF2`, no `glyf`/`loca` mixture, no variation-dependent outline profile, and `maxp` version 0.5.
- Require `maxp.numGlyphs == CharStrings INDEX.count`; OpenType GID remains the CharStrings position.
- Preserve the existing `0x00010000` static-`glyf`, common-table, checksum, collection, API, budget, and error behavior unchanged.
- Keep `moon.mod.json`, the four declared targets, and the sole `mb-font -> mb-core` dependency for v0.34.

### Expected Features

**Must have (table stakes):**

- Static CFF1 admission behind the existing opaque `Font` for standalone OTF and selected TTC/OTC faces.
- One checked INDEX implementation for Name, Top DICT, String, Global Subrs, CharStrings, FDArray, and local Subrs, including empty form and all `offSize` values.
- Typed Top, Font, and Private DICT parsing with complete number encodings, arity/default/duplicate policy, named offset bases, checked ranges, and no embedded PostScript execution.
- Both name-keyed selection (predefined/custom charset and Encoding) and CID-keyed selection (`ROS`, CID charset, FDArray, FDSelect 0/3, per-FD Private DICT and local Subrs).
- Full normal static Type 2 execution: number/stack/transient/arithmetic/logical/storage operators, widths, path operators, all flex forms, local/global subroutines, legal termination, and deterministic `random`.
- Exact hint/stem/mask framing and validation without device hint execution.
- Bounded, atomic cubic path publication with explicit byte, work, call, depth, stack, stem, command, contour, point, allocation, mutation, and budget authority.
- Admission-time validation of every glyph and retention of truthful compact bounds before any CFF-backed `Font` is published.
- Existing `cmap`, `GlyphId`, `hmtx`, line/global metrics, legacy `kern`, checksum, structured error, and collection behavior preserved.
- Generated name-keyed and multi-FD CID fixtures, licensed name-keyed and CID evidence, hostile/resource/mutation matrices, frozen `glyf` regressions, and exact four-target semantic comparison.

**Should have (competitive):**

- One public `Font` and native cubic `Path2` fidelity across both outline formats, so downstream SVG/PDF/canvas/CLI consumers do not branch on storage.
- Zero-copy retained CFF views and capability-preserving TTC/OTC face selection, including shared CFF tables with face-local mapping and metrics.
- Caller-authorized resource transactions and deterministic failure precedence rather than host OOM, host recursion, or target-dependent timeout.
- Independent semantic oracle records covering GID/FD selection, commands, control points, bounds, metrics, failure class, and fixture provenance.
- Reproducible Latin and CJK performance baselines after correctness gates close; optimizations must preserve commands, coordinates, errors, budgets, and API.

**Static CFF1 scope and explicit deferrals:**

- **In scope:** raw static CFF1 in `OTTO` SFNT and TTC/OTC selected faces; one-font CFF FontSet; name-keyed and CID-keyed data; Type 2 CharStrings; local/global Subrs; FontMatrix normalization; validated non-rendering hints; unhinted cubic design-space outlines.
- **Deferred to v0.34.x:** semantics-preserving performance work, broader licensed corpus coverage, and optional metadata inspection only after a concrete RFC-backed consumer need.
- **Deferred to v0.35+:** CFF2 and variable-font instantiation (`VariationStore`, `vsindex`, `blend`); WOFF1/WOFF2 decompression and reconstruction; shaping/GSUB/GPOS/bidi; hint execution and rasterization; color/bitmap glyphs; subsetting, authoring, serialization, discovery, fallback, and host-font lookup.
- **Never in this slice:** foreign runtime font stacks, ambient filesystem/network access, cubic-to-quadratic approximation, public raw CFF offsets/DICT objects, or silent partial acceptance of deferred profiles.

### Metrics Admission and Bounds Decision

The roadmap should treat the following as resolved architecture, not leave it as a later API choice:

1. **`hmtx` remains the sole public advance-width and left-side-bearing authority.** Type 2 optional/default/nominal widths are decoded and validated for legal program semantics and checked arithmetic, but they neither replace public metrics nor cause rejection merely because a collection face's face-local `hmtx` differs from a shared CFF table.
2. **Every CharString is executed during CFF admission through the same VM used for outlines.** The admission sink validates the complete program, selected FD/private environment, subroutine behavior, hints, numeric operations, contour lifecycle, limits, and effective FontMatrix before `Font` publication.
3. **Retain one compact conservative integer bound per GID, not a `Path2`.** Compute `floor(min)` / `ceil(max)` after the effective FontMatrix over line endpoints and cubic endpoints/control points. Preserve truthful empty-glyph semantics. `horizontal_metrics` performs no hidden or unbudgeted VM work and derives its existing bound/right-side-bearing result from these retained facts plus authoritative `hmtx`.
4. **Admission is one transaction.** Structural parsing, all-glyph execution, retained bounds, exact work/allocation accounting, and final source-revision guard complete before one budget charge and `Font` publication. Any glyph, resource, numeric, or mutation failure publishes no font, no bounds, and no committed admission charge.
5. **Outline queries remain separate transactions.** The VM runs one selected glyph with the path sink into private scratch geometry; only legal termination, final revision validation, and one caller-budget commit publish a complete cubic `Path2`.

### Architecture Approach

Split common SFNT facts from a closed private outline source. The existing `glyf` decoder stays compatibility-frozen; CFF1 receives dedicated checked cursor, INDEX, DICT, keying, admission, Type 2 VM, and geometry-sink components within the current `font` package. Standalone and collection routes pass the same admitted common facts and one checked `'CFF '` table window into the same CFF admission transaction. SFNT/TTC table records stay root-relative; CFF internal offsets become table-relative only after windowing; INDEX offsets are 1-based from object data; Private `Subrs` is relative to its Private DICT.

**Major components:**

1. **Closed outline-profile facade** — retains common cmap/metrics/kern facts once and dispatches only private `Glyf` or `Cff1` state at bounds and outline boundaries.
2. **SFNT/TTC profile and table-window layer** — recognizes an exact static profile, preserves root-relative collection records/checksums, and hands CFF one checked table-local authority.
3. **CFF structural parser** — central checked cursor, reusable INDEX parser, typed DICT schemas, String/SID validation, charsets, Encodings, Private DICTs, and Global/Local Subr windows.
4. **CFF keying adapter** — normalizes name-keyed or CID-keyed data into exactly one per-GID CharString and private/local-subroutine/matrix environment before VM execution.
5. **Iterative Type 2 VM** — fixed stack/transient/frame storage, Q16.16 arithmetic, deterministic PRNG, hint framing, subroutine biases/cycles, termination, and unified execution/work ledgers.
6. **Two geometry sinks** — admission-time `ValidateBounds` retains conservative integer extents; query-time `BuildPath` publishes complete native cubic paths.
7. **Qualification system** — one extended fixture generator and one upgraded four-target evidence lane with generated, licensed, hostile, compatibility, dependency, API, and toolchain facts.

**Key patterns:**

- Parse → validate → exact preflight → final mutation guard → one budget commit → publish.
- Preflight attacker-controlled counts and ranges before traversal, narrowing, or allocation.
- Use explicit Type 2 frames rather than host recursion; distinguish `Global(index)` from `Local(environment,index)`.
- Resolve CID FD/private facts before the VM; the VM never parses FDSelect.
- Keep one interpreter/operator switch for both bounds and path sinks to prevent validator/renderer drift.
- Retain compact views, offsets, FD ranges, and bounds; do not copy strings/CharStrings broadly, desubroutinize, memoize geometry, or retain every glyph path.

### Critical Pitfalls

1. **Wrong offset coordinate space** — centralize INDEX decoding and checked named windows; never mix SFNT-root, CFF-table, INDEX-object-data, or Private-DICT-relative offsets.
2. **CID reduced to name-keyed behavior** — require the complete `ROS`/CID charset/FDArray/FDSelect contract, validate all FDs, and resolve one per-GID execution environment before the VM.
3. **Incomplete Type 2 resource accounting** — hard stack/stem/depth/transient ceilings are insufficient; charge every executed byte/token, call/return, stack action, mask byte, arithmetic operation, range traversal, and emitted geometry unit.
4. **Hints treated as zero-byte no-ops** — count stems across frames and consume exactly `ceil(stems/8)` mask bytes, including pending vstem operands, truncation, unused bits, and 96/97 boundaries.
5. **Compatibility policy drift** — freeze deterministic PRNG/reset rules, fixed-point rounding/overflow, FontMatrix composition, contour closure, flex-as-two-cubics, and bounded non-nested seac support or a stable explicit unsupported outcome before implementation.
6. **Partial bounds or metric admission** — validate all glyphs, retain compact bounds, keep `hmtx` authoritative, and commit only after the final mutation guard; never execute hidden work in `horizontal_metrics`.
7. **TTC double rebasing and shared-table confusion** — preserve the v0.33 retained-root adapter, root-relative table records, table-local CFF windows, face-local common tables, and exact shared CFF ranges.
8. **Self-oracle and target inference** — use hand-derived generated vectors plus independent pinned tools, provenance-complete licensed inputs, four isolated target runs, and exactly four normalized semantic records.

## Implications for Roadmap

Use four phases, numbered 104–107. The boundary between Phases 104 and 105 is mandatory: structural offset/keying failures and VM execution/resource failures have distinct invariants, error precedence, and hostile matrices.

### Phase 104: CFF1 Profile and Bounded Data Model

**Rationale:** Every later operation depends on a single checked CFF table authority and an unambiguous execution environment per GID. INDEX/DICT/keying semantics must be stable before a bytecode VM can safely consume them.

**Delivers:** Closed static-CFF1 profile classification; common-versus-outline-specific table facts; CFF Header and all shared INDEX decoding; typed Top/Font/Private DICT schemas; String/SID checks; predefined/custom name-keyed charset and Encoding; CID `ROS`, charset, FDArray, FDSelect 0/3, Private DICT, and local/global Subr windows; CharStrings/`maxp` identity; derived semantic limits, error precedence, exact structural charge formula; generated structural and exact/one-short fixtures. The phase ends with internal proof that every GID selects exactly one bounded CharString and environment. It does not yet claim a publicly usable CFF-backed `Font`.

**Addresses:** Static CFF1 profile admission, reusable INDEX/DICT, name-keyed and CID-keyed selection, GID identity, checked retained views, and explicit unsupported recognition for mixed/CFF2/variable profiles.

**Primary risks avoided:** 1-based INDEX mistakes; unchecked count/offset arithmetic; duplicate or untyped DICT keys; wrong CFF/Private offset bases; malformed SID/CID/FDSelect facts; tag-only profile recognition.

**Research flag:** **DEEP RESEARCH REQUIRED.** Freeze duplicate-key policy, DICT real/fixed conversion, predefined charset/Encoding tables, exact CID FontMatrix rules, semantic limit derivation, admission-time validation boundaries, and structural error precedence against primary specifications before planning implementation tasks.

### Phase 105: Bounded Type 2 Validation and Retained Metrics

**Rationale:** The existing budgetless metrics API requires truthful bounds before a CFF `Font` can exist. This phase therefore closes execution semantics, all-glyph validation, and atomic metric admission before public path integration.

**Delivers:** Iterative fixed-capacity Type 2 VM; Q16.16 numeric contract; all required stack/arithmetic/logical/storage, line/curve/flex, width, hint/mask, local/global subroutine, and termination semantics; hard ceilings plus caller work ledgers; deterministic PRNG; effective FontMatrix handling; one VM with a validation/bounds sink; all-glyph pass; one compact conservative bound per GID; `hmtx`-authoritative metric integration; private admission transaction with no publication or charge on failure.

**Addresses:** Full static Type 2 execution, validated non-rendering hints, deterministic resource authority, truthful CFF bounds/RSB, atomic admission, and four-target-portable semantics by construction.

**Primary risks avoided:** host recursion; wrong subroutine bias/environment; repeated shallow-call amplification; stack/transient misuse; mask-byte desynchronization; early floating point; random/FontMatrix/seac drift; lazy malformed-glyph discovery; partial bounds or budget publication.

**Research flag:** **DEEP RESEARCH REQUIRED.** Before coding, freeze fixed-point rounding for `div`/`mul`/`sqrt` and final conversion, PRNG algorithm and reset semantics, effective Top/FD FontMatrix composition, contour closure, deprecated four-operand `endchar`/seac policy, exact geometric-bound rounding, and exhaustive resource-ledger units.

### Phase 106: Cubic Path and Public/TTC Integration

**Rationale:** Once the VM and retained metric facts are proven, public outlines become a thin second sink and collection support can reuse the already-qualified standalone CFF admission path without forking semantics.

**Delivers:** `BuildPath` sink on the same VM; complete `MoveTo`/`LineTo`/`CubicTo`/`Close` publication; closed `FontOutlineSource::Glyf | Cff1` dispatch; standalone CFF1 `Font::open`; successful static-CFF1 `FontCollection::open_face`; root-relative shared-table handling; face-local `cmap`/`hmtx`/`kern` authority; final per-outline mutation/budget transaction; frozen existing static-`glyf` API, errors, charges, metrics, mappings, kerning, paths, and TTC behavior; stable unsupported outcomes for deferred capabilities.

**Addresses:** One opaque `Font`, native cubic fidelity, selected CFF collection faces, mapping/metrics/kerning compatibility, no-copy retained views, and public atomic `Path2` extraction.

**Primary risks avoided:** a parallel CFF public API; validator/path divergence; partial geometry; TTC face-base double rebasing; shared CFF with wrong face-local metrics; accidental generalization of the qualified `glyf` decoder; silent CFF2/WOFF/shaping/hint/raster leakage.

**Research flag:** **TARGETED CODE-LEVEL RESEARCH; SKIP BROAD ECOSYSTEM RESEARCH.** The repository already has the relevant facade, selected-face adapter, checksum, revision, budget, and `Path2` patterns. Planning should inspect exact local charge/error/interface baselines and build non-zero-directory/shared-CFF fixtures, but should not reopen the selected architecture.

### Phase 107: Hostile, Licensed, and Four-Target Qualification

**Rationale:** Desktop-grade support is not proven by generated Latin success or compilation. Final acceptance must exercise both keying models, real subroutinized fonts, the public standalone/collection routes, hostile limits and mutation, frozen `glyf`, and independent execution on all four targets.

**Delivers:** Closed generated name-keyed and multi-FD CID matrices; hand-derived operator/path vectors; immutable licensed name-keyed OTF and licensed CID CJK OTF/OTC derivative; source/derivative hashes, licenses/notices, exact recipes and tool identities; independent fontTools/AFDKO/OTS semantic cross-checks; structural/program/resource/mutation exact/one-short cases; collection shared-table cases; existing-`glyf` regression suite; API/dependency/toolchain checks; reproducible Latin/CJK benchmark baselines; exactly four ordered semantic records from isolated `js`, `wasm`, `wasm-gc`, and `native` runs.

**Addresses:** Interoperability, provenance, hostile-input closure, atomicity evidence, compatibility, performance baselines, deterministic errors/facts, and the milestone's reproducibility requirement.

**Primary risks avoided:** generated-only or Latin-only claims; floating downloads; missing derivative lineage; one tool as both builder and oracle; target-produced expected data; compilation-only portability; broad numeric tolerances; premature optimization.

**Research flag:** **TARGETED PROVENANCE RESEARCH REQUIRED.** Runtime patterns and four-target evidence machinery are established, so skip another format/architecture survey. Planning must approve exact redistributable name-keyed and CID assets, licenses/notices, parent and derivative digests, deterministic subset recipes, pinned oracle hashes/versions, and independence of expected facts.

### Phase Ordering Rationale

- Phase 104 owns byte authority and keying; the VM cannot safely execute before every GID has one validated CharString and local environment.
- Phase 105 owns semantics, work, atomic admission, and retained bounds; no public CFF `Font` is honest before every glyph and metric fact is validated.
- Phase 106 reuses proven semantics for complete cubic paths and adapts the existing standalone/collection facade; this isolates public compatibility risk from parser/VM construction.
- Phase 107 qualifies the completed public slice with real fonts and independent targets; phase-local white-box and hostile tests still ship in Phases 104–106 rather than being postponed.
- Performance optimization starts only after Phase 107 freezes semantic fingerprints and named Latin/CJK baselines.

### Research Flags

Phases likely needing `$gsd-plan-phase --research-phase <N>`:

- **Phase 104:** deep specification work for DICT/keying/matrix policy and error/limit boundaries.
- **Phase 105:** deep Type 2 semantic work for numeric, random, seac, hint framing, bounds, and resource-ledger decisions.
- **Phase 107:** narrow research for fixture licensing, provenance, tool pinning, and independent oracle design.

Phase with established patterns where broad research can be skipped:

- **Phase 106:** use targeted repository inspection during planning; closed outline dispatch, `Path2`, retained roots, collection selection, budgets, mutation guards, and four-target-compatible APIs are already established.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Exact local toolchain/module/dependency facts are strong; current oracle versions and external format findings are official but classified MEDIUM by the research seam, and final tool hashes remain to be pinned. |
| Features | MEDIUM | Static CFF1 table stakes and deferrals converge across OpenType/Adobe sources and local contracts; obscure valid compatibility forms still require Phase 104–105 policy fixtures. |
| Architecture | HIGH for integration; MEDIUM for VM details | Existing `Font`, TTC adapter, budgets, revision guards, table windows, metrics, and cubic `Path2` make the integration design concrete; PRNG, FontMatrix, seac, and exact fixed-point rules remain planning decisions. |
| Pitfalls | MEDIUM overall; HIGH for local atomicity/TTC risks | Failure modes map directly to format rules and shipped MNF contracts; real CID corpus coverage is not yet frozen. |

**Overall confidence:** MEDIUM. The four-phase roadmap and product boundary are clear; the open work is concentrated in explicit semantic policies and qualification provenance rather than stack or module selection.

### Gaps to Address

- **Type 2 deterministic numeric contract:** specify Q16.16 rounding, overflow, `div`/`mul`/`sqrt`, matrix composition, and final `Double` conversion with exact generated vectors before Phase 105 implementation.
- **`random` policy:** choose a project-owned PRNG, `initialRandomSeed` interpretation, per-glyph reset, and cross-target oracle facts.
- **Deprecated `endchar` composition:** either implement bounded, non-nested name-keyed StandardEncoding seac semantics or return one stable recognized unsupported outcome; never accept partial geometry.
- **DICT duplicate/default policy:** freeze exact behavior per typed Top/Font/Private schema and test every structural singleton.
- **Metrics mismatch evidence:** retain the resolved `hmtx` authority rule and add shared-CFF collection fixtures whose face-local `hmtx` differs, proving Type 2 width validation does not silently replace or invalidate public metrics.
- **Licensed CID fixture:** select an immutable redistributable multi-FD CFF1 CJK asset or deterministic derivative and record parent/derivative lineage, license/notice, hashes, recipe, and oracle versions.
- **Admission performance ceiling:** validate all-glyph bounds cost on named Latin and CJK workloads before optimizing; preserve compact offsets/bounds and exact work preflight.
- **Error and budget precedence:** freeze state/revision, caller input/range, resource, malformed data, and recognized capability ordering with multi-fault standalone and collection vectors.

## Sources

### Primary project sources (HIGH confidence)

- [Project definition and v0.34 milestone](../PROJECT.md) — binding goal, active requirements, static CFF1 scope, deferrals, and compatibility constraints.
- [`STACK.md`](STACK.md), [`FEATURES.md`](FEATURES.md), [`ARCHITECTURE.md`](ARCHITECTURE.md), and [`PITFALLS.md`](PITFALLS.md) — detailed stack, capability, design, failure, and phase research synthesized here.
- [RFC 0004: `mb-font` Charter](../../docs/rfcs/0004-mb-font.md) — font/outline ownership, `mb-canvas` raster boundary, shaping boundary, and portability policy.
- Repository `mb-font` admission, directory, metrics, outline, collection, limits, fixture, and qualification sources plus `mb-core` byte, checked, budget, error, and `Path2` sources — existing integration authority.

### Authoritative format sources (MEDIUM confidence under the research seam)

- [OpenType Specification 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/) — current OpenType authority and version.
- [OpenType font file and collections](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — `OTTO`, common tables, profile separation, TTC/OTC sharing, and root-relative table records.
- [OpenType CFF table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff) — one-font CFF FontSet, Type 2 requirement, OpenType GID identity, `maxp` cardinality, and collection integration.
- [OpenType CFF2 table](https://learn.microsoft.com/en-us/typography/opentype/spec/cff2) — authoritative contrast for the CFF2/variable deferral.
- [Adobe Technical Note #5176: Compact Font Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf) — Header, INDEX, DICT, charset, Encoding, Private DICT, Subrs, CID, FDArray, FDSelect, and FontMatrix.
- [Adobe Technical Note #5177: Type 2 Charstring Format](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5177.Type2.pdf) — operators, numbers, stack/transient limits, subroutine bias/depth, hints/masks, flex, seac, and termination.
- [WOFF 1.0](https://www.w3.org/TR/WOFF/) and [WOFF 2.0](https://www.w3.org/TR/WOFF2/) — compression and table-reconstruction boundaries supporting explicit deferral.

### Qualification and compatibility sources (MEDIUM confidence)

- [fontTools CFF library](https://fonttools.readthedocs.io/en/latest/cffLib/index.html) and [fontTools 4.63.0](https://github.com/fonttools/fonttools/releases/tag/4.63.0) — host-only CFF inspection, deterministic subset support, and one semantic oracle.
- [AFDKO command-line tools](https://adobe-type-tools.github.io/afdko/CommandLineHowTo.html) and [AFDKO 5.0.1](https://github.com/adobe-type-tools/afdko/releases/tag/5.0.1) — independent CFF-specialist `tx`, `spot`, and `makeotf` qualification.
- [OpenType Sanitizer 9.2.0](https://chromium.googlesource.com/external/ots/+/refs/tags/v9.2.0) — independent structural sanitizer/transcoder, not a semantic source of truth.
- [Adobe Source Sans](https://github.com/adobe-fonts/source-sans), [Source Serif](https://github.com/adobe-fonts/source-serif), and [Source Han Serif](https://github.com/adobe-fonts/source-han-serif) — candidate OFL-1.1 static name-keyed and CID-keyed licensed fixtures; exact assets remain to be selected and pinned.

---
*Research completed: 2026-07-28*
*Ready for roadmap: yes*
