# Project Research Summary

**Project:** MoonBit Native Foundation — v0.33 TrueType Collection Adapters
**Domain:** Portable, bounded, no-copy TTC/OTC inspection and selected static-`glyf` face admission
**Researched:** 2026-07-28
**Confidence:** HIGH for scope and repository integration; MEDIUM for the new pre-1.0 API and exact resource/error policy

## Executive Summary

v0.33 should extend the existing `tchivs/mb-font@0.1.0` package with a narrow `FontCollection` adapter for raw TTC/OTC version 1.0 and 2.0 containers. The product is not a new font engine, decompressor, discovery service, or collection authoring tool. It accepts a caller-owned bounded `ByteView`, validates the collection envelope atomically, exposes zero-based face selection and minimal capability inspection, and returns the existing opaque `Font` only for a selected static TrueType face with `sfntVersion = 0x00010000` and `glyf`/`loca` outlines. CFF, CFF2, variable faces, WOFF, WOFF2, shaping, discovery, hinting, rasterization, and cryptographic signature verification remain explicit future boundaries.

The implementation should add no runtime dependency, module, FFI, ambient I/O, or target-specific path. The one necessary architectural change is to parameterize the existing private SFNT admission seam with an absolute face-directory offset and an explicit checksum policy. Directory fields are read at that non-zero base, but every table-record offset remains relative to byte zero of the collection. Selected tables become checked subviews of the retained root source, preserving legitimate table sharing, the existing mutation revision, and all shipped metrics, cmap, kern, limits, budget, error, and outline behavior.

The principal risks are accidentally rebasing root-relative table offsets, applying standalone whole-font checksum rules to a collection face, allowing counts or offsets to become allocation authority, confusing exact cross-face sharing with malformed overlap, and publishing facts across a source-revision or budget boundary. Mitigate them with checked `UInt64` range arithmetic before narrowing, separate collection and selected-face atomic transactions, protected structural ranges, per-table checksums with collection-specific `head.checksumAdjustment` handling, pre/post revision guards, a closed error-precedence matrix, and independently generated/licensed qualification on `js`, `wasm`, `wasm-gc`, and `native`.

## Key Findings

### Hard Scope and Resolved Decisions

The four research reports agree on the core design. Roadmap and requirements should use these resolved rules where the reports left implementation choices open:

1. **One additive adapter, one existing font model.** Add `FontCollection` and `FontCollectionLimits` to the existing public `font` package. Keep `Font::open` standalone-only and behavior-compatible. `open_face` returns the existing `Font`; do not create a parallel `CollectionFace` query API.
2. **Raw TTC/OTC v1/v2 only.** Admit bytes by the `ttcf` signature, never by filename extension. Support TTCHeader 1.0 and 2.0. Explicitly reject WOFF/WOFF2 and do not add zlib, Brotli, table-transform reconstruction, or materialized standalone-font output.
3. **Static `glyf` selection only.** Collection structure is outline-neutral, so a supported face can coexist with CFF, CFF2, variable, or otherwise deferred siblings. Minimal semantic face inspection should classify supported static `glyf`, CFF, CFF2, variable, and other unsupported profiles; only the selected supported static `glyf` face is fully admitted.
4. **Minimal inspection wins over omission or raw exposure.** Architecture research considered omitting `face_profile`, while feature research requires useful mixed-collection inspection. Include a small closed semantic classification but keep raw directory offsets, table records, names, and table views private. Final type/function names may change during API review without weakening the capability.
5. **DSIG is structural, never trusted.** For TTC v2, accept an all-zero DSIG tuple as absent. For a present tuple, require `DSIG`, a checked non-empty range ending at collection EOF, and bounded version-1/format-1 record envelopes; keep payload bytes opaque and expose only `present_unverified`. Malformed structure is `Data`; a well-formed unsupported version/format is `Capability`. Do not add cryptography or trust-store policy.
6. **Two-stage validation is mandatory.** Collection opening validates the header, full offset array, every face-directory envelope, protected structural ranges, compact profile facts, and the DSIG envelope. It does not checksum or semantically admit every sibling table graph. `open_face` performs full existing font admission for exactly one selected face.
7. **Sharing policy is fail-closed and scoped.** Preserve unique ordered tags and non-overlapping distinct tables within each face. Across faces, permit exact shared ranges with consistent length/checksum metadata; reject partial overlaps, conflicting metadata, and any table intersection with protected collection/directory ranges. Do not add a global table cache.
8. **Resource accounting distinguishes retention from work.** A selected `Font` may enforce its source-retention ceiling against the root collection extent because it retains that root. The budget must not count the same root bytes as copied allocation or rescan the whole collection per selection. Collection bookkeeping/work and selected directory/table work are separate authoritative transactions. Freeze the exact requested/limit facts before implementation.

### Recommended Stack

Use the existing repository stack unchanged:

- **MoonBit `moon` / `moonrun` `0.1.20260713` and `moonc v0.10.4+2cc641edf`** — exact current build and qualification baseline; no toolchain upgrade is required.
- **`tchivs/mb-font@0.1.0`** — add the collection facade and reuse the shipped `Font` behavior.
- **`tchivs/mb-core@0.1.0`** — remain the only runtime dependency, supplying retained `ByteView`s, mutation revisions, checked ranges/arithmetic, budgets, structured errors, and `Path2`.
- **OpenType Specification 1.9.1** — normative authority for TTCHeader 1.0/2.0, root-relative table offsets, table sharing, collection checksums, DSIG placement, and outline-profile distinctions.
- **Existing `moon.work`, `moon.mod.json`, and CI patterns** — retain `preferred-target: native` and `supported-targets: +js+wasm+wasm-gc+native`.

No database, persistent index, compression library, cryptography library, filesystem/network layer, foreign font engine, or native stub belongs in v0.33. Deterministic fixture tooling is development/test-only and must not become a production dependency or runtime oracle.

Critical version requirements:

- TTC/OTC container profile: exactly TTCHeader 1.0 and 2.0.
- Selected supported face: `sfntVersion = 0x00010000`, static `glyf` plus `loca`, and the existing v0.32 required-table profile.
- Existing module versions remain `0.1.0`; milestone numbering does not imply a publication-version bump.

### Expected Features

**Must have (table stakes):**

- Separate bounded `FontCollection` entry point with frozen standalone `Font::open` behavior.
- Atomic TTC/OTC v1/v2 header, offset-array, all-directory-envelope, and optional v2 DSIG structural validation.
- Exact non-zero face count and explicit zero-based index semantics; no clamping, implicit face zero, raw-offset selection, or name-based identity.
- Distinct `FontCollectionLimits` covering at least source bytes, faces, cumulative directory records, DSIG records/bytes, retained bookkeeping, and work.
- Root-retaining, no-copy selected-face admission with table records resolved against collection byte zero.
- Existing per-table checksums in both modes, with the standalone aggregate checksum equation used only by standalone `Font::open`.
- Legitimate exact cross-face table sharing and strict fail-closed handling of same-face overlap, partial aliasing, conflicting metadata, or protected-range intersection.
- Per-face classification and capability isolation so unsupported CFF/CFF2/variable siblings do not poison a supported static-`glyf` face.
- Root source identity and permanent mutation-revision propagation through collection operations and every derived `Font`.
- Stable stage-specific `InvalidInput`, `Data`, `Capability`, `Resource`, and `State` outcomes with atomic budget charges and no partial publication.
- Generated, licensed, hostile, standalone-compatibility, and public-workflow qualification with identical semantic facts on all four production targets.

**Should have (differentiators):**

- Inspect the bounded collection once, then pay full TrueType admission cost only for the chosen face.
- Small semantic profile and DSIG-presence facts without exposing storage internals.
- Exact one-short/exact collection and selected-face resource evidence.
- Adversarial offset-origin fixtures that remain in-bounds under an incorrect rebase, making the most dangerous bug observable.
- Public equivalence evidence showing a collection-selected face preserves the existing metrics, Unicode mapping, kerning, glyph IDs, outlines, and revision failures of its standalone logical equivalent.

**Defer to later milestones:**

- WOFF1 and WOFF2 decoding, decompression, and transformed-table reconstruction.
- CFF/CFF2 charstrings, variable-font instances, color/bitmap profiles, and broader font formats.
- DSIG cryptographic verification, PKCS#7/X.509 parsing, trust stores, certificate policy, or authenticity claims.
- Localized name/family/style discovery, fallback, shaping, GSUB/GPOS, bidi, hinting, rasterization, and system-font access.
- Collection extraction, authoring, merging, subsetting, rewriting, standalone materialization, and persistent shared-table/font caching.

### Architecture Approach

Normalize the container difference at one private boundary. `FontCollection::open` retains the root `ByteView`, opening revision, protected structural ranges, and compact per-face facts. `open_face(index, limits, budget)` checks revision and index, parses one SFNT directory at the stored absolute directory offset, resolves each table record unchanged against the root view, selects collection checksum mode, and enters the same private font-admission transaction used by standalone `Font::open`.

All downstream table readers remain collection-unaware because they already consume checked table-local views. `cmap`, metrics, kern, loca/glyf, and outline code should not acquire collection branches.

**Major components:**

1. **Public collection facade** — bounded open, revision-guarded face count/profile facts, DSIG presence status, and explicit selected-face admission.
2. **Collection limits and error policy** — semantic ceilings, authoritative transaction plans, stable operation/context names, and deterministic precedence.
3. **TTC header/parser** — exact v1/v2 parsing, checked count/offset arithmetic, all-face directory envelopes, protected ranges, and v2 DSIG structure.
4. **Offset-aware SFNT directory seam** — absolute directory-base reads, root-relative table windows, per-face tag/overlap rules, and cross-face exact sharing.
5. **Explicit checksum policy** — selected per-table checksums in both modes; standalone aggregate `0xB1B0AFBA` validation only for the standalone facade.
6. **Shared font admission transaction** — unchanged required-table, profile, cmap, kern, metrics, loca/glyf, outline, budget, and final revision gates producing the existing `Font`.
7. **Qualification system** — independent micro-collection builder/oracle, licensed specimen manifest, hostile mutation matrix, standalone regressions, and four-target canonical selectors.

Likely future repository changes are concentrated in the mb-font collection facade, its limits and directory/font admission internals, focused tests, font fixtures and manifests, and qualification scripts. This is a planning forecast rather than a claim that those files already exist. mb-core, downstream modules, and public dependency policy should remain unchanged.

### Critical Pitfalls

1. **Rebasing root-relative table offsets** — never feed a face-directory subview to the standalone parser and never compute `directory_offset + record.offset`; add the base only when reading directory-local fields.
2. **Using zero-base ordering as overlap validation** — build checked absolute protected ranges for the TTC header and every face directory, then test actual intersection; valid collection tables may appear before or after a selected directory.
3. **Conflating sharing with arbitrary aliasing** — allow deliberate exact cross-face sharing, retain strict per-face tags/ranges, and reject partial/conflicting aliases under bounded deterministic work.
4. **Applying standalone checksum semantics to TTC** — keep selected table checksums active, zero the `head.checksumAdjustment` field only for the `head` table checksum calculation, and skip only the standalone whole-source invariant.
5. **Letting counts/offsets authorize allocation or work** — keep wire values in checked `UInt64`, compare semantic limits before narrowing/allocation, preflight cumulative directory and DSIG work, and commit one exact transaction per operation.
6. **Eagerly admitting all faces or poisoning supported siblings** — validate all directory envelopes structurally but defer table checksums and semantics to the selected face; classify well-formed unsupported profiles as capabilities.
7. **Leaving a collection-to-font mutation window** — use the same root revision before and after collection open, inspection, face admission, and later font queries; mutation followed by restoration remains invalidation.
8. **Claiming portability or fixture legitimacy by convention** — prohibit host/network fonts in tests, record source and derivative digests/licenses/tooling, use independent expected facts, and execute separate canonical runs on all four targets.

## Implications for Roadmap

Use three implementation phases. This grouping follows the two-stage architecture and keeps qualification independent without deferring phase-local hostile tests.

### Phase 1: Collection Contract and Bounded Envelope

**Rationale:** The new public identity, error, resource, and structural-validation contract must be frozen before the parser is generalized. It establishes the only new container trust boundary and prevents attacker-controlled counts from reaching allocation or repeated work.

**Delivers:** Additive opaque `FontCollection`, `FontCollectionLimits`, minimal `FontFaceProfile`, and structural DSIG-presence types; exact TTCHeader 1.0/2.0 parsing; checked `numFonts` and offset array; complete all-face directory envelopes and protected ranges; compact face facts; source-revision ownership; collection budget transaction; stable index/error semantics; no change to `Font::open`.

**Addresses:** TTC-01 and the collection half of TTC-03/TTC-04: bounded container inspection, exact count/index behavior, mixed-profile visibility, DSIG structural status, atomic publication, and permanent mutation fail-closed behavior.

**Avoids:** Header/version ambiguity, unchecked arithmetic and premature narrowing, raw offsets or names as identity, eager semantic admission of every face, false DSIG trust, inconsistent errors, and partial collection publication.

**Planning decisions to freeze:** exact public names; whether profile classification is enum or opaque facts; cumulative directory/DSIG limits; protected-range and cross-face partial-overlap policy; collection charge formula; validation/error precedence; fixture provenance policy.

### Phase 2: Root-Relative Selected-Face Admission

**Rationale:** Once collection topology and authority are stable, refactor the existing SFNT seam exactly once and route both standalone and selected collection faces through one admission transaction. This phase carries the highest correctness risk because standalone assumptions previously coincided with offset zero.

**Delivers:** Private directory parser parameterized by absolute directory offset; root-relative table windows; strict per-face overlap plus exact cross-face sharing; explicit standalone/collection checksum modes; static-`glyf` capability gate; selected-face `FontLimits` and budget transaction; pre/post revision guards; unchanged existing `Font` queries and standalone behavior.

**Addresses:** TTC-02 and TTC-03 plus selected-face TTC-04: supported face selection, shared tables, collection checksum rules, sibling capability isolation, and existing metrics/cmap/kern/outline behavior.

**Avoids:** Double-basing offsets, directory subview parsing, global overlap rejection, disabling all checksums, whole-collection rescans per selection, CFF/CFF2 leakage into `glyf`, duplicated font APIs/parsers, and publication across revision or resource failure.

**Planning decisions to freeze:** exact selected-source retention versus budget facts; equal-range metadata consistency; table/protected-range interaction; collection-mode work formula; multi-fault error precedence.

### Phase 3: Hostile, Licensed, and Four-Target Qualification

**Rationale:** The adapter is complete only when offset origin, sharing, mixed profiles, resource atomicity, mutation, provenance, standalone compatibility, and target equality are proved at the public workflow boundary. This phase consolidates evidence; Phases 1 and 2 still add their own focused hostile tests as implementation proceeds.

**Delivers:** Generated TTC v1/v2, null/present DSIG, non-zero-base, before/after-directory table, shared/distinct table, mixed-profile, corrupt selected/unselected face, limit/budget, error-precedence, and mutation fixtures; one compact provenance-tracked licensed positive collection or derivative; optional licensed unsupported-profile specimen only if size justifies it; unchanged v0.32 standalone suite; public collection-to-Font workflow; independent `js`, `wasm`, `wasm-gc`, and `native` canonical evidence.

**Addresses:** TTC-05 and final acceptance of TTC-01 through TTC-04: reproducibility, interoperability, compatibility, deterministic errors/facts, and full four-target behavior.

**Avoids:** Happy-path-only evidence, self-confirming builders/oracles, system-font or network dependency, incomplete derivative licensing, face-zero-only coverage, hidden backend narrowing, and regression disguised as updated baselines.

### Phase Ordering Rationale

- Public identity, structural-versus-semantic boundaries, protected ranges, limits, errors, and source ownership must exist before selected-face parsing can rely on them.
- The parser/checksum refactor is isolated from fixture/CI breadth so standalone behavior can be compared continuously while the one critical offset seam changes.
- Generated hostile tests accompany each implementation phase, while the final phase freezes licensed evidence, complete workflow facts, and independent target runs after API semantics settle.
- Three phases are sufficient: adding separate phases for WOFF, CFF/CFF2, DSIG crypto, discovery, or authoring would violate the v0.33 product boundary.

### Research Flags

Phases needing targeted planning research:

- **Phase 1:** Confirm the exact TTC v2 DSIG envelope depth from the current linked OpenType DSIG definition; freeze the structural-versus-selected validation boundary, cumulative directory/DSIG limits, partial-overlap policy, and error precedence.
- **Phase 2:** Inspect the existing `directory.mbt` and budget formulas in detail before planning edits; freeze selected-source retention versus allocation/work charges and the exact consistent-metadata rule for shared ranges.
- **Phase 3:** Audit the chosen licensed TTC/derivative, notice obligations, exact generator command/version, source/output SHA-256 values, and independent oracle facts before committing binary evidence.

Phases with established patterns that do not need broad ecosystem research:

- **Phase 1:** TTCHeader 1.0/2.0, root-relative offsets, mixed outline profiles, collection checksums, and the repository's checked/budget/revision primitives are already documented. Only the project policy choices above remain.
- **Phase 2:** The target architecture and existing local font admission seams are clear; planning needs code-level inspection, not another technology survey.
- **Phase 3:** Four-target execution, fixture manifests, canonical selectors, and standalone qualification have established repository patterns. Research is limited to specimen provenance and coverage.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Exact MoonBit/toolchain/module/dependency facts are locally verified; official OpenType and W3C specifications support the format boundaries. |
| Features | HIGH | TTC/OTC v1/v2 selection, mixed-profile isolation, no-copy sharing, structured failures, and four-target qualification converge across all reports and the project goal. Exact API names remain pre-1.0 choices. |
| Architecture | HIGH | Repository source confirms downstream parsing is table-local and can reuse root-backed subviews; the root-relative offset and collection checksum rules are normative. |
| Pitfalls | HIGH | Failure modes map to concrete current zero-base assumptions, checked-resource contracts, and adversarial verification cases. |
| DSIG policy | MEDIUM | Structural placement is well supported, but exact public status shape and record-envelope depth should be frozen during Phase 1 planning. |
| Resource/error policy | MEDIUM | Atomic budget/revision patterns already exist, but collection-versus-selected source-byte accounting and multi-fault precedence are project decisions. |
| Fixture corpus | MEDIUM | Existing DejaVu provenance is a strong base; the exact v0.33 TTC derivative, digest, and independent facts have not yet been selected. |

**Overall confidence:** HIGH for the roadmap and milestone boundary; MEDIUM for the small policy choices explicitly flagged for phase planning.

### Gaps to Address

- **Selected-source accounting:** Decide whether `FontLimits.max_source_bytes` records the retained root extent, selected referenced-table extent, or both as separate facts. Never misreport retained caller bytes as copied allocation or make selection work scan unrelated payloads.
- **Cross-face alias policy:** Freeze exact sharing as same absolute range plus consistent length/checksum metadata and specify deterministic rejection/context for partial or conflicting aliases without unbounded all-pairs work.
- **DSIG envelope:** Confirm record-count, byte, version/format, and EOF rules; keep payload opaque and status unverified.
- **Public inspection shape:** Keep profile facts minimal and closed. Confirm whether DSIG status belongs on collection inspection or a dedicated method, without exposing raw storage.
- **Error precedence:** Specify revision, invalid index, malformed data, unsupported profile/signature, semantic limit, and budget ordering with multi-fault vectors.
- **Licensed specimen:** Select the smallest redistributable TTC or deterministic derivative that proves real shared-table static-`glyf` behavior; record source/output digests, license/notice, exact transformation, and independent semantic expectations.
- **Qualification commands:** Verify whether `moon ... --target all` is sufficient evidence or whether selectors must invoke four explicit target runs to freeze independent canonical results; acceptance must show all four target identities.

## Sources

### Primary (HIGH confidence)

- [Project definition and v0.33 milestone](../PROJECT.md) — goal, target features, project constraints, and frozen v0.32 behavior.
- [RFC 0004: `mb-font` Charter](../../docs/rfcs/0004-mb-font.md) — module boundary, portability, hostile-input posture, and downstream contracts.
- [`STACK.md`](STACK.md), [`FEATURES.md`](FEATURES.md), [`ARCHITECTURE.md`](ARCHITECTURE.md), and [`PITFALLS.md`](PITFALLS.md) — detailed research synthesized here.
- [OpenType Specification 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/) and [OpenType Font File / Font Collections](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — TTCHeader v1/v2, collection-root-relative offsets, table sharing, mixed outline profiles, DSIG tuple, and collection checksum semantics.
- [OpenType `head` table](https://learn.microsoft.com/en-us/typography/opentype/spec/head) — collection treatment of `checksumAdjustment`.
- [OpenType glyph format comparison](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — distinct `glyf`, `CFF `, and CFF2 outline models.
- [OpenType DSIG table](https://learn.microsoft.com/en-us/typography/opentype/spec/dsig) — collection-wide signature envelope and placement; v0.33 uses structure only, not trust.
- [WOFF 1.0](https://www.w3.org/TR/WOFF/) and [WOFF2](https://www.w3.org/TR/WOFF2/) — official compression/reconstruction requirements supporting their exclusion.
- Repository mb-font admission, directory, table, limit, cmap, kern, metric, and outline sources; the mb-core byte-view source; module manifests; workspace configuration; and font qualification artifacts — existing code and integration authority.

### Secondary (MEDIUM confidence)

- [FreeType 2.14.3 Face Creation](https://freetype.org/freetype2/docs/reference/ft2-face_creation.html) — established zero-based face-index/count behavior.
- [`ttf-parser` 0.25.1 `RawFace`](https://docs.rs/ttf-parser/latest/ttf_parser/struct.RawFace.html) — established explicit collection-index parsing and differentiated face errors.
- [fontTools `TTCollection`](https://fonttools.readthedocs.io/en/latest/ttLib/ttCollection.html) — established collection/member-font and table-sharing model; tooling may aid offline fixture curation only.
- [DejaVu Fonts license](https://dejavu-fonts.github.io/License.html) and the repository's existing DejaVu fixture manifest — candidate derivative provenance baseline.
- [Noto CJK repository](https://github.com/notofonts/noto-cjk) and [OFL 1.1 license](https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE) — optional real OTC unsupported-profile evidence if repository size and licensing metadata justify inclusion.

---
*Research completed: 2026-07-28*
*Ready for roadmap: yes*
