# Phase 101: Collection Contract and Bounded Envelope - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 101 adds the public, bounded, read-only contract for opening raw TTC/OTC version 1 and 2 bytes and inspecting collection-wide semantic face facts. It owns collection identity, limits, source revision, all-face structural envelopes, protected ranges, minimal profile classification, structural DSIG status, stable errors, and atomic publication. It does not open a selected face as `Font`, validate selected table checksums or required-table semantics, or implement WOFF/CFF/variable-font behavior; those belong to Phase 102 or later milestones.

</domain>

<decisions>
## Implementation Decisions

### Public Collection Surface

- **D-01:** Add a separate opaque `FontCollection` facade and keep `Font::open` standalone-SFNT-only with its existing behavior. Do not auto-detect TTC/OTC in `Font::open`. — **Reversibility:** costly — merging the entry points later would change established error precedence and every caller that intentionally distinguishes standalone from collection bytes.
- **D-02:** Add a dedicated non-zero `FontCollectionLimits` contract rather than widening `FontLimits`; collection authority and selected-face authority remain separate.
- **D-03:** Public inspection exposes only the exact face count, zero-based closed semantic face profile, and closed collection DSIG status. Raw offsets, table tags/records, checked ranges, `ByteView`s, and parser facts remain private. — **Reversibility:** costly — raw facts would become a public storage ABI and prevent internal range/accounting changes.
- **D-04:** The profile classification must distinguish at least supported static `glyf`, CFF/CFF2, variable, and other unsupported faces. Classification is informative; only Phase 102 turns a selected supported profile into `Font`.

### Structural Validation Boundary

- **D-05:** `FontCollection::open` validates the TTC signature and exact v1/v2 version, non-zero bounded face count, complete offset array, every face's SFNT directory envelope and search facts, ordered unique tags, checked table ranges, compact profile, all protected structural ranges, and the optional v2 DSIG envelope.
- **D-06:** Collection opening does not checksum table payloads, enforce the v0.32 required-table set, or decode metrics/cmap/kern/glyf semantics for sibling faces. Those costs and failures occur only when Phase 102 admits the selected face.
- **D-07:** Directory offsets are absolute collection offsets, while every table-record offset remains relative to collection byte zero. No face-directory subview may become the table-offset origin. — **Reversibility:** costly — getting this seam wrong contaminates retained windows, checksums, identity, and every inherited `Font` query.
- **D-08:** Permit cross-face sharing only when records name the exact same absolute range with consistent length and checksum metadata. Reject partial overlaps, conflicting metadata, same-face overlaps, and any table intersection with the TTC header, offset array, a face directory, or the collection DSIG range.
- **D-09:** Structural range and alias validation is bounded by declared cumulative record limits and an exact deterministic work formula; attacker-controlled counts never become allocation or pairwise-work authority.

### Collection Authority and Accounting

- **D-10:** `FontCollectionLimits` has explicit non-zero ceilings for source bytes, face count, tables per face, cumulative table records, DSIG records, DSIG bytes, retained bookkeeping bytes, and total work. The constructor rejects zero ceilings as `InvalidInput`.
- **D-11:** Source bytes remain caller-owned and retained by reference: `max_source_bytes` bounds authority, but the authoritative budget must not report the full source length as copied allocation.
- **D-12:** Compute and preflight the exact retained-bookkeeping and declared-work `ResourceCharge` before constructing/publishing retained collection facts; commit one charge for a successful open. Malformed, unsupported, limited, budget-rejected, or revision-drifted opens publish nothing and leave the transaction uncommitted.
- **D-13:** Work accounting includes header/offset reads, all directory-record scans, profile classification, protected-range/alias comparisons, DSIG envelope/record traversal, and normalization into retained facts. It excludes table-payload checksum scans and selected-face semantic admission.
- **D-14:** Capture the root `ByteView` revision at entry, guard before authority-dependent publication, and retain that same root/revision in the collection. All inspection methods recheck it; mutation followed by byte restoration is still invalidation.

### DSIG and Deterministic Failures

- **D-15:** In TTC v2, an all-zero `(tag, length, offset)` tuple means no DSIG. Any partially zero tuple is malformed `Data`.
- **D-16:** A present tuple must use tag `DSIG`, describe one checked non-empty range ending at collection EOF, and contain a bounded DSIG version-1 envelope with supported format-1 signature blocks. Payload bytes stay opaque; public status is only `PresentUnverified`, never trusted or verified.
- **D-17:** Malformed DSIG structure is `Data`; a complete, well-formed but unsupported DSIG version or signature format is `Capability`. No cryptography, PKCS#7 interpretation, certificate validation, or trust-store policy is added.
- **D-18:** Stable precedence is staged-authority-first and traversal-stable: invalid limit construction; source-byte ceiling; TTC signature/version/header, face-count, offset-array, and DSIG-tuple authority; declaration-work `max_work` and caller-work preflight before the per-face declaration scan; per-face table-count and cumulative-record ceilings plus bounded DSIG record-count discovery; structural-work `max_work` and caller-work preflight before face, protected-range, alias, and DSIG-body traversal; face/protected/alias facts before DSIG version/count-zero/flags and record/block semantics; retained-memory and exact-work ceilings; full caller budget preflight; final source-revision guard before publication. Each stage is atomic, and exact equality admits while a one-short authority fails before its dependent traversal.
- **D-19:** A well-formed unsupported collection version/profile/DSIG format is `Capability`; malformed bytes and inconsistent ranges are `Data`; limit and budget exhaustion are `Resource`; out-of-range inspection indices are `InvalidInput`; revision drift is `State`.

### the agent's Discretion

The planner may choose exact pre-1.0 type and method names, internal compact-fact layout, helper decomposition, and stable error context strings, provided the decisions above and existing `CoreError` category/code semantics remain observable. The exact conservative byte size assigned to each retained private fact is also discretionary once it is target-neutral, documented, and tested with exact-one-short evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Contract

- `.planning/ROADMAP.md` — Phase 101 boundary, dependency, goal, and observable success criteria.
- `.planning/REQUIREMENTS.md` — TTC-01 and the explicit v0.33/future/out-of-scope boundaries.
- `.planning/research/SUMMARY.md` — resolved TTC/OTC architecture, normative OpenType source links, feature table stakes, pitfalls, and roadmap implications.
- `docs/rfcs/0004-mb-font.md` — module purpose, public dependency boundary, portability policy, and hostile-input posture.

### Shipped Font Contracts

- `.planning/milestones/v0.32-phases/97-font-admission-and-metrics/97-CONTEXT.md` — retained immutable-byte, atomic admission, limits, budget, and error decisions inherited by collections.
- `.planning/milestones/v0.32-phases/100-portable-font-qualification/100-CONTEXT.md` — fixture provenance, independent oracle, and four-target evidence constraints that later qualification must preserve.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `modules/mb-font/font/cursor.mbt`: checked big-endian integer reads already return structured font-open errors over `ByteView`.
- `modules/mb-font/font/directory.mbt`: directory search-fact checks, ordered tags, checked ranges, overlap detection, table-local views, profile gates, and checksum helpers provide the parser seams to parameterize.
- `modules/mb-font/font/limits.mbt`: the explicit non-zero semantic-limit constructor/getter pattern should be mirrored for collection limits.
- `modules/mb-core/checked/range.mbt` and `modules/mb-core/checked/checked.mbt`: checked arithmetic/range primitives can express every header, directory, table, protected, and DSIG envelope without host-width narrowing.
- `modules/mb-core/budget/budget.mbt` and `modules/mb-core/bytes/views.mbt`: authoritative preflight/charge and retained revisioned byte views already implement the required ownership model.

### Established Patterns

- `Font::open` captures the opening revision, preflights discovery, parses private facts, charges one admission transaction, validates semantics, rechecks revision, and only then publishes `Font`.
- Downstream metrics, cmap, kern, loca/glyf, and outline code consume checked table-local views and need no collection branches once Phase 102 creates correct root-backed windows.
- `FontLimits` uses explicit non-zero `UInt64` ceilings and stable `InvalidInput` constructor failures; collection limits should follow the same portable representation.
- Directory discovery currently assumes the SFNT directory starts at zero, rejects every overlap, scans standalone whole-source checksums, and treats `ttcf` as unsupported. These assumptions define the exact Phase 102 refactor boundary and must not leak into Phase 101's public contract.

### Integration Points

- Add the collection facade and parser beside `font.mbt`, `directory.mbt`, and `limits.mbt` in the existing `modules/mb-font/font` package so no new module or dependency is introduced.
- Keep `Font` and its query surface unchanged; Phase 101 retains enough private root-relative facts for Phase 102 to enter the existing admission pipeline.
- Extend black-box and white-box font tests with generated TTC v1/v2, DSIG, mixed-profile, protected-range, alias, limit, budget, and revision cases before widening the public generated interface.

</code_context>

<specifics>
## Specific Ideas

- Use a deliberately non-zero face directory and a table offset that would remain in-bounds under an incorrect rebase so tests can detect the most dangerous origin bug.
- Include both exact shared ranges and same-sized-but-distinct ranges; neither a digest nor equal bytes alone establish shared identity.
- Expose DSIG status with wording that makes the absence of authenticity verification impossible to miss.
- Preserve standalone `Font::open` checksum and error vectors byte-for-byte while the collection surface is introduced.

</specifics>

<deferred>
## Deferred Ideas

None — WOFF/WOFF2, CFF/CFF2 outline execution, variable fonts, DSIG cryptographic trust, discovery, shaping, rendering, and authoring were already excluded by the v0.33 milestone contract.

</deferred>

---

*Phase: 101-collection-contract-and-bounded-envelope*
*Context gathered: 2026-07-28*
