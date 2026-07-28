# Phase 102: Root-Relative Selected-Face Admission - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Add one no-copy, root-relative selected-face admission path from an already admitted `FontCollection` to the existing opaque `Font`. It must support an in-range static `glyf` face beside distinct, exactly shared, or unsupported sibling faces while preserving all standalone metrics, mapping, kerning, glyph, outline, mutation, checksum, limit, budget, and error contracts. It does not add another font model or any new outline/profile implementation.

</domain>

<decisions>
## Implementation Decisions

### Public selected-face contract
- **D-01:** Add exactly one public operation, `FontCollection::open_face(index, FontLimits, Budget) -> Result[Font, CoreError]`, with the concrete MoonBit receiver/reference spelling derived from existing package conventions. — **Reversibility:** costly — renaming or replacing the method after consumers adopt it changes the generated public interface and downstream call sites.
- **D-02:** A successful selection returns the existing opaque `Font` directly. Do not add `CollectionFace`, collection-specific metric/query methods, or public directory/range handles.
- **D-03:** `open_face` is non-consuming and repeatable. Each call is an independent admission transaction with its own limits and caller-owned budget; the collection stores no admitted-face cache.

### Root-relative private admission seam
- **D-04:** Parameterize the private directory/admission seam with the retained root source, an absolute selected-directory start, and an explicit checksum mode. Add the directory start only to directory-field reads; consume every table-record offset unchanged against collection byte zero.
- **D-05:** Never materialize a standalone SFNT, concatenate table bytes, or copy the complete collection. The returned `Font` retains the same root `ByteView` and collection opening revision so exact shared table ranges retain one mutation identity.
- **D-06:** Reuse Phase 101 cached selected-face authority facts (`directory_start`, declared table count, closed profile, collection structural admission, opening revision). Reparse only the selected directory into fresh semantic `DirectoryFacts`; do not rescan or semantically admit unrelated siblings.
- **D-07:** Exact cross-face sharing needs no global cache or special public identity. Each selected `Font` builds its own table-local root subviews. Unsupported CFF/CFF2/variable siblings remain irrelevant after the collection envelope is admitted; selecting one of those profiles fails `Capability` before deep table admission.

### Limits, work, and atomic budget ownership
- **D-08:** Keep collection opening and selected-face admission as separate transactions. `open_face` accepts the existing `FontLimits` and `Budget`; it never reuses, stores, refunds, or mutates the Phase 101 collection-opening charge.
- **D-09:** Resolve the research accounting tension with a split rule: `FontLimits.max_source_bytes` bounds the retained collection-root extent, while admission work/byte facts and the final caller charge cover only the selected directory plus distinct referenced selected-table extents and the selected semantic work. Unrelated sibling payloads are neither scanned nor repeatedly charged.
- **D-10:** Collection selection uses staged preflights before attacker-declared loops but commits one exact aggregate selected-face charge only after semantic admission and the final revision guard. Preserve standalone `Font::open` charging and observable malformed-input behavior unchanged by using a private collection-mode ledger/commit policy rather than globally rewriting helper semantics.

### Error precedence, mutation, and publication
- **D-11:** Freeze selection precedence as: retained-root revision → face index → cached selected profile → selected source/declaration/structural authority stages → selected directory/table facts in established wire order → required-table and per-table checksum semantics → exact final budget preflight → final root revision → one charge → publish `Font`.
- **D-12:** Any mutation since collection admission returns `State` before index/profile handling. Mutation during selection fails the final revision guard without a committed charge or published `Font`; any later mutation, including mutate-then-restore, invalidates all inherited `Font` queries through the retained shared revision cell.
- **D-13:** Out-of-range indices remain `Input`; unsupported selected profiles remain `Capability`; malformed selected directory/tables/checksums remain their existing `Data` contexts; resource failures use the established `Resource` category. Combination tests must freeze the order in D-11.

### Collection checksum compatibility
- **D-14:** In collection mode validate every selected table checksum exactly as standalone mode does, including zeroing `head` bytes 8–11 for the `head` table checksum, but skip only the standalone whole-source `0xB1B0AFBA` checksum-adjustment check. Standalone checksum behavior and bytes remain unchanged.
- **D-15:** A selected static `glyf` face must expose existing `Font` metrics, cmap, kerning, glyph identity, and unhinted outline semantics with no collection provenance visible in those APIs.

### Explicit non-goals
- **D-16:** Phase 102 remains read-only and selected-static-`glyf` only: no CFF/CFF2 or variable execution, WOFF/WOFF2, DSIG trust, eager all-face semantic admission, persistent face caching, extraction/materialization, subsetting/merging/writing, discovery/fallback, shaping, bidi, hinting, rasterization, FFI, ambient I/O, new module, or new dependency.
- **D-17:** Phase 103 owns broad hostile matrices, licensed collection/derivative provenance, immutable fixture digests, standalone-vs-collection qualification, and complete four-target release evidence. Phase 102 still adds focused tests necessary to prove its own contracts.

### the agent's Discretion
- Private type names, file splits, and helper placement may follow the closest `directory.mbt` / `font.mbt` / `tables.mbt` patterns.
- The exact internal ledger representation and checked-arithmetic helper decomposition are flexible if D-09 through D-13 remain directly testable.
- Focused generated TTC builder reuse may be refactored for clarity, but fixture provenance and broad qualification remain Phase 103.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` §Phase 102 — fixed phase goal and four success criteria.
- `.planning/REQUIREMENTS.md` §TTC-02/TTC-03 — selected-face equivalence and collection-specific checksum/standalone compatibility requirements.
- `.planning/PROJECT.md` §Current Milestone — module, portability, and deferred feature boundary.
- `docs/rfcs/0004-mb-font.md` — accepted `mb-font` package boundary and Pure MoonBit direction.

### Collection research and inherited decisions
- `.planning/research/ARCHITECTURE.md` — offset-aware admission seam, root-relative offsets, checksum modes, and selected accounting analysis.
- `.planning/research/FEATURES.md` — selected-face atomicity and authority recommendations.
- `.planning/research/SUMMARY.md` — implementation sequence and excluded capabilities.
- `.planning/phases/101-collection-contract-and-bounded-envelope/101-CONTEXT.md` — collection identity, root ownership, profile, alias, DSIG, and precedence decisions.
- `.planning/phases/101-collection-contract-and-bounded-envelope/101-VERIFICATION.md` — verified Phase 101 behavioral baseline.
- `.planning/debug/resolved/ttc-work-precedence-order.md` — canonical staged work-authority and error-precedence correction.

### Public-surface and policy contracts
- `policy/foundation.json` — tracked module source inventory and exact generated `mb-font` public interface.
- `scripts/quality/Assert-Policy.ps1` — independent interface classifier, dependency/target/FFI gates, and current Phase 102 negative fixtures.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-font/font/collection.mbt`: retained root, opening revision, compact per-face facts, and revision-first query pattern; natural owner of the single public `open_face` method.
- `modules/mb-font/font/collection_parser.mbt`: root-relative range helpers, cached directory starts/profiles, exact sharing authority, and staged work formulas.
- `modules/mb-font/font/directory.mbt`: standalone directory/table checksum admission seam that must become privately offset-aware without changing its standalone entry behavior.
- `modules/mb-font/font/font.mbt` and `modules/mb-font/font/tables.mbt`: existing opaque `Font` construction and semantic-table pipeline to reuse rather than duplicate.
- `modules/mb-font/font/collection_test.mbt`, `collection_wbtest.mbt`, and `generated_fonts_wbtest.mbt`: generated TTC/SFNT builders, wrong-rebase, sharing, mutation, checksum, and accounting patterns.

### Established Patterns
- Public facade → private authority parser → compact normalized facts → final revision guard → one committed transaction → opaque result.
- Caller-owned `ByteView` subviews share one revision identity and do not copy source bytes.
- Exact generated-interface allowlists and independent classifiers fail closed on any accidental public parser/storage/selected-face surface.
- Standalone `Font::open` compatibility is protected by exact policy signatures, blob checks, and focused regressions.

### Integration Points
- `FontCollection::open_face` validates revision/index/profile and forwards cached root/directory facts into a private collection-mode `Font` admission seam.
- The directory parser gains explicit base/checksum policy inputs while its current standalone wrapper remains behavior-identical.
- The selected admission ledger composes existing table parsers without committing the real caller budget until final publication.
- Policy advances from the exact 84-line Phase 101 interface by only the intended `open_face` signature.

</code_context>

<specifics>
## Specific Ideas

- Legal selected tables may occur before or after a non-zero face directory; tests must use both layouts so accidental directory-relative rebasing cannot pass.
- At least one focused mixed-profile case should select a supported `glyf` face beside an unsupported sibling, and one case should select an exact shared-table face.
- Equivalence assertions should call existing public `Font` methods rather than compare private parsed facts.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 102 scope. Broad qualification, licensed evidence, and release-level four-target matrices remain explicitly assigned to Phase 103.

</deferred>

---

*Phase: 102-root-relative-selected-face-admission*
*Context gathered: 2026-07-28*
