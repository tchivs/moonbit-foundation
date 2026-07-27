# Phase 101: Collection Contract and Bounded Envelope - Research

**Researched:** 2026-07-28
**Domain:** Bounded, no-copy OpenType TTC/OTC v1/v2 structural inspection in portable MoonBit
**Confidence:** HIGH for project constraints and source integration; MEDIUM-HIGH for the prescriptive pre-1.0 API/accounting design

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

None — WOFF/WOFF2, CFF/CFF2 outline execution, variable fonts, DSIG cryptographic trust, discovery, shaping, rendering, and authoring were already excluded by the v0.33 milestone contract.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TTC-01 | Library authors can open caller-provided immutable TTC/OTC version 1 or 2 bytes under explicit collection limits, inspect the exact non-zero face count and bounded semantic profile of each zero-based face, and distinguish absent from structurally present-but-unverified version-2 DSIG data without exposing raw offsets or table records. | Public API freeze, exact TTC/DSIG wire layout, protected-range and alias model, accounting formulas, error precedence, revision protocol, and validation matrix below. |
</phase_requirements>

## Summary

Phase 101 should add a separate opaque `FontCollection` contract in the existing `tchivs/mb-font/font` package and should leave `Font::open` byte-for-byte behaviorally unchanged. The collection open path must retain the original root `ByteView`, classify all faces from directory facts only, validate every range against collection byte zero, and publish only compact face/profile, protected-range, and DSIG-status facts. It must not call the existing standalone `parse_font_directory` because that helper assumes directory offset zero, rejects all sharing, performs standalone checksum work, and rejects `ttcf`. [VERIFIED: codebase inspection; CONTEXT.md D-01, D-05 through D-08]

OpenType 1.9.1 defines TTCHeader v1 as `ttcf`, version `1.0`, `numFonts`, and a root-relative directory-offset array; v2 adds a three-field DSIG tuple. Every face has a complete normal SFNT table directory, and every table-record offset is relative to the beginning of the collection, not its face directory. Identical top-level tables may be shared. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff]

Use a count-first, allocation-free validation pass to establish exact face, table-record, protected-range, DSIG-record, retained-byte, and work authority before allocating retained arrays. Then normalize compact facts, recheck the root revision, atomically charge one `ResourceCharge`, and publish. This preserves the repository's existing `ByteView` revision and `Budget::preflight`/`Budget::charge` model without charging the caller-owned source length as copied bytes. [VERIFIED: codebase inspection; CONTEXT.md D-09 through D-14]

**Primary recommendation:** implement two new private files (`collection_parser.mbt`, `collection_limits.mbt`) plus the facade in `collection.mbt`, using the exact API, range model, charge formula, and precedence table in this document; do not refactor standalone admission during Phase 101.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Caller-owned byte admission | API / library boundary | Storage (`ByteView`) | `FontCollection::open` owns validation; `mb-core/bytes` owns retained zero-copy identity and revision. [VERIFIED: codebase inspection] |
| TTC/OTC structural parsing | API / backend library | — | Pure MoonBit parser logic belongs in `mb-font/font`, not a host adapter. [VERIFIED: AGENTS.md; RFC 0004] |
| Range and overflow safety | Foundation (`mb-core`) | `mb-font` error remapping | `CheckedRange` and checked arithmetic establish bounds; collection code maps hostile wire failures to font `Data`. [VERIFIED: codebase inspection; CONTEXT.md D-19] |
| Resource authority | Foundation (`mb-core`) | `FontCollectionLimits` | `Budget` owns caller counters; collection limits own semantic ceilings and exact preflight formula. [VERIFIED: codebase inspection; CONTEXT.md D-10 through D-13] |
| Face profile inspection | `mb-font` facade | private directory parser | The facade exposes a closed semantic enum; raw tags and offsets stay private. [VERIFIED: CONTEXT.md D-03, D-04] |
| DSIG structural status | `mb-font` facade | private DSIG parser | The parser validates only the envelope; no cryptographic service or trust tier exists. [VERIFIED: CONTEXT.md D-15 through D-17] |
| Selected-face `Font` admission | Phase 102 | Phase 101 retained facts | Explicitly deferred; Phase 101 only preserves the root/directory/protected facts needed later. [VERIFIED: REQUIREMENTS.md TTC-02/TTC-03; CONTEXT.md phase boundary] |

## Project Constraints (from AGENTS.md)

- Implement core algorithms and shared data models in MoonBit. [VERIFIED: AGENTS.md]
- Keep native as the primary target while preserving deliberate `js`, `wasm`, `wasm-gc`, and `native` portability. [VERIFIED: AGENTS.md; `modules/mb-font/font/moon.pkg`]
- Add no FFI here; any future native stub must remain small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md; CONTEXT.md]
- Preserve an acyclic public dependency graph; `tchivs/mb-font` may depend only on `tchivs/mb-core`. [VERIFIED: AGENTS.md; RFC 0004]
- Keep public pre-1.0 experimental surface visibly bounded and do not expose private storage ABI. [VERIFIED: AGENTS.md; CONTEXT.md D-03]
- Keep all operations deterministic and free of ambient GUI/filesystem/network state. [VERIFIED: AGENTS.md; RFC 0004]
- Benchmarks, if later added, need declared workloads and reproducible baselines; Phase 101 acceptance is test/evidence based, not a performance claim. [VERIFIED: AGENTS.md]
- Do not change module boundaries or add a new module without an RFC; Phase 101 remains inside the already proposed `mb-font` charter. [VERIFIED: AGENTS.md; RFC 0004]
- Prefer the codebase knowledge graph for discovery. The current `mnf-phase100-exec` graph contains documentation nodes but no MoonBit function nodes, so targeted source inspection was the required fallback. [VERIFIED: codebase-memory query and architecture result]
- Work is already inside the `$gsd-plan-phase` research workflow; direct implementation edits remain out of scope for this artifact. [VERIFIED: AGENTS.md; orchestrator task]

No project-local skills were present in the supported skill directories, and no agent-specific researcher skills were configured. [VERIFIED: filesystem inspection and `agent-skills gsd-phase-researcher`]

## Standard Stack

### Core

| Component | Verified Version | Purpose | Why Standard |
|-----------|------------------|---------|--------------|
| `moon` / `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Build and run all four targets | Exact repository baseline available locally. [VERIFIED: local CLI] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | MoonBit compiler | Shipped with the pinned local toolchain. [VERIFIED: local CLI] |
| `tchivs/mb-font` | repository `0.1.0` line | New collection facade and parser | Phase 101 extends the existing font package rather than adding a module. [VERIFIED: repository manifests; CONTEXT.md D-01] |
| `tchivs/mb-core` | repository `0.1.0` line | `ByteView`, checked arithmetic/ranges, budget, errors | It is the only permitted runtime dependency and already supplies every authority primitive needed. [VERIFIED: `moon.pkg`, RFC 0004] |
| OpenType Specification | 1.9.1 | Normative TTC, SFNT, DSIG, outline-profile wire rules | Primary format authority. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/] |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `modules/mb-font/font/cursor.mbt` | Checked big-endian `u8/u16/u32/i16` reads over `ByteView` | Reuse for every collection field; remap its standalone error context where collection-specific precedence is observable. [VERIFIED: codebase inspection] |
| `font_directory_search_facts` | Exact SFNT directory `searchRange`, `entrySelector`, `rangeShift` derivation | Reuse as a pure private helper for each face. [VERIFIED: `directory.mbt`] |
| `@checked.CheckedRange` | Half-open checked range creation and overlap | Use for source, header, directories, tables, DSIG, and blocks. [VERIFIED: `mb-core/checked/range.mbt`] |
| `Budget::preflight` and `Budget::charge` | Hierarchical atomic caller resource authority | Preflight the final exact charge before retention; commit once immediately before publication. [VERIFIED: `mb-core/budget/budget.mbt`] |

### Alternatives Rejected

| Instead of | Rejected Alternative | Why |
|------------|----------------------|-----|
| Separate `FontCollection::open` | Auto-detect in `Font::open` | Violates locked standalone behavior and error precedence. [VERIFIED: CONTEXT.md D-01] |
| Root-relative parser | Parse a directory subview | Re-bases table offsets incorrectly and breaks shared tables. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] |
| Pure MoonBit envelope validation | FreeType/fontTools/FFI runtime parser | Adds forbidden dependency/FFI and changes the public authority model. [VERIFIED: AGENTS.md; RFC 0004] |
| Structural DSIG status | PKCS#7/X.509 verification | Explicitly out of scope; structural presence cannot be called trust. [VERIFIED: CONTEXT.md D-16, D-17] |
| Count-first bounded scans | Allocate from wire counts and validate later | Lets hostile declarations become allocation/pairwise authority. [VERIFIED: CONTEXT.md D-09, D-12] |

**Installation:** none. Phase 101 installs no external package and adds no runtime dependency. Package-legitimacy audit is therefore not applicable. [VERIFIED: CONTEXT.md; repository dependency boundary]

## Recommended Public Contract

Freeze this public shape for planning. Exact spelling remains pre-1.0, but plans should not leave the shape undecided:

```moonbit
pub(all) enum FontFaceProfile {
  StaticGlyf
  Cff
  Cff2
  Variable
  OtherUnsupported
} derive(Eq)

pub(all) enum FontCollectionDsigStatus {
  Absent
  PresentUnverified
} derive(Eq)

pub struct FontCollectionLimits {
  // all fields private
}

pub fn FontCollectionLimits::new(
  max_source_bytes~ : UInt64,
  max_faces~ : UInt64,
  max_tables_per_face~ : UInt64,
  max_table_records~ : UInt64,
  max_dsig_records~ : UInt64,
  max_dsig_bytes~ : UInt64,
  max_retained_bookkeeping_bytes~ : UInt64,
  max_work~ : UInt64,
) -> Result[FontCollectionLimits, @error.CoreError]

// Provide one getter for each constructor field, mirroring FontLimits.

pub struct FontCollection {
  // private root ByteView, opening revision, face facts, protected ranges,
  // and DSIG status
}

pub fn FontCollection::open(
  source : @bytes.ByteView,
  limits : FontCollectionLimits,
  budget : @budget.Budget,
) -> Result[FontCollection, @error.CoreError]

pub fn FontCollection::face_count(
  self : FontCollection,
) -> Result[UInt64, @error.CoreError]

pub fn FontCollection::face_profile(
  self : FontCollection,
  index : UInt64,
) -> Result[FontFaceProfile, @error.CoreError]

pub fn FontCollection::dsig_status(
  self : FontCollection,
) -> Result[FontCollectionDsigStatus, @error.CoreError]
```

This exposes exactly TTC-01's count/profile/DSIG facts, makes revision failure representable on every inspection, and exposes no source window, offset, tag, record, range, or selected `Font`. [VERIFIED: CONTEXT.md D-01 through D-04, D-14]

`face_profile` must check revision before checking the index. Thus a drifted collection always returns `State` even when the supplied index is also out of range; on an unchanged collection, `index >= face_count` returns `InvalidInput/InvalidRange` with `requested=index` and `limit=face_count`. [RECOMMENDATION derived from CONTEXT.md D-14, D-18, D-19]

## Architecture Patterns

### System Architecture Diagram

```text
caller-owned root ByteView + FontCollectionLimits + Budget
                         |
                         v
             capture root mutation revision
                         |
                         v
       source ceiling -> TTC tag/version/count authority
          | Data/Capability/Resource on failure
                         |
                         v
 allocation-free wire-order validation passes
   offsets -> face directories -> table ranges/profiles
          -> protected ranges/aliases -> DSIG envelope
                         |
                         v
 exact retained bytes + exact work formula
          | semantic Resource ceiling failure
                         |
                         v
             caller Budget::preflight
          | Resource failure, no counters changed
                         |
                         v
 normalize compact face/protected/status facts
                         |
                         v
              final root revision guard
          | State failure, no counters changed
                         |
                         v
                Budget::charge once
                         |
                         v
               publish FontCollection
                  /       |        \
                 v        v         v
          face_count  face_profile  dsig_status
                 \        |         /
                  revision guard first
```

### Recommended Project Structure

```text
modules/mb-font/font/
├── collection_limits.mbt   # public non-zero limits + getters
├── collection_parser.mbt   # private TTC, directory, range, alias, DSIG passes
├── collection.mbt          # public enums/facade/revision-guarded inspection
├── collection_test.mbt     # black-box TTC-01/API/error/atomicity tests
├── collection_wbtest.mbt   # private formulas, ranges, DSIG, precedence tests
├── cursor.mbt              # reuse checked BE reads
├── directory.mbt           # reuse pure search-fact helper; do not route TTC through standalone parser
├── font.mbt                # unchanged standalone facade in Phase 101
└── limits.mbt              # unchanged FontLimits
```

All files remain in the existing `font` package; MoonBit package compilation discovers the new `.mbt` files without a new dependency or module. [VERIFIED: repository package layout]

### Pattern 1: Three-Pass Authority Before Retention

**Pass A — staged declaration authority:** validate the source ceiling, base TTC header, non-zero face count, offset-array envelope, and DSIG tuple; preflight exact declaration work before scanning per-face declarations; then validate per-face table counts, cumulative record count, and the bounded DSIG record count. Do not allocate arrays. [RECOMMENDATION derived from CONTEXT.md D-09, D-10, D-18]

**Pass B — authorized structural validation:** compute and preflight exact structural work from the bounded declaration counts before re-reading directory headers/search facts/tags/ranges/profiles, all protected-range and table-pair relations, then DSIG version/count-zero/flags and records/blocks. DSIG count discovery is authority-only; its semantic validation follows face/protected/alias facts. Directly re-read earlier wire records for pair checks rather than allocating attacker-sized scratch structures. [RECOMMENDATION derived from CONTEXT.md D-05, D-08, D-09, D-18]

**Pass C — retained normalization:** after exact retained/work ceiling checks and caller budget preflight, allocate only the compact face and protected-range arrays, normalize them, final-guard revision, charge once, and publish. [RECOMMENDATION derived from CONTEXT.md D-11 through D-14]

This design intentionally pays deterministic bounded re-reads to guarantee that neither scratch nor retained allocations occur before authority. [RECOMMENDATION]

### Pattern 2: Root-Relative Half-Open Ranges

Use one source range `[0, source.length)`. Derive all other ranges through checked start+length and keep them in root coordinates:

- `header = [0, 12 + 4*F + (v2 ? 12 : 0))`
- each `directory_i = [directoryOffset_i, directoryOffset_i + 12 + 16*numTables_i)`
- each `table_ij = [record.offset, record.offset + record.length)`
- present `dsig = [dsigOffset, dsigOffset + dsigLength)`, with `end == source.length`
- each DSIG block uses `dsig.start + signatureBlockOffset` as its root start, but containment is checked relative to the DSIG range. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff; https://learn.microsoft.com/en-us/typography/opentype/spec/dsig]

Protected ranges are `header`, every face directory, and present DSIG. Empty table ranges do not overlap; touching half-open endpoints are valid. Protected ranges must not overlap one another, and every non-empty table range must be disjoint from every protected range. [RECOMMENDATION derived from CONTEXT.md D-08 and `CheckedRange::overlaps`]

### Pattern 3: Compact Informative Profile

Classify after a face's ordered tags have been scanned:

1. `Variable` if any variation marker is present (`fvar`, `gvar`, `cvar`, `avar`, `HVAR`, `MVAR`, or `VVAR`).
2. `Cff2` if `sfntVersion == 'OTTO'`, `CFF2` is present, and no variation marker was found.
3. `Cff` if `sfntVersion == 'OTTO'`, `CFF ` is present, and neither CFF2 nor a variation marker was found.
4. `StaticGlyf` only if `sfntVersion == 0x00010000`, both `glyf` and `loca` are present, and no existing v0.32 excluded-profile tag is present.
5. `OtherUnsupported` for every other structurally valid combination.

`fvar` is required in all variable fonts; OpenType distinguishes `glyf`, `CFF `, and `CFF2` as the three outline-table families, and CFF/CFF2 use `OTTO` as their SFNT signature. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/fvar; https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison; https://learn.microsoft.com/en-us/typography/opentype/spec/cff2]

The classification does not validate required tables or outline semantics and never fails collection opening merely because a face is unsupported. Contradictory or incomplete outline tag sets become `OtherUnsupported`. [VERIFIED: CONTEXT.md D-04, D-06, D-19]

### Pattern 4: Exact Sharing, Never Content-Based Sharing

For every unordered pair of non-empty table records:

- Same face: any overlap, including exact equality, is `Data`.
- Different faces and disjoint: valid.
- Different faces and exact same range: valid only if `tag`, `length`, and stored `checksum` all match.
- Different faces and partial overlap: `Data`.
- Different faces and exact range with any metadata conflict: `Data`.

Do not compare bytes, hashes, or computed checksums to infer sharing. OpenType permits identical tables to be shared, while Phase 101 deliberately does not scan payload checksums. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff; VERIFIED: CONTEXT.md D-06, D-08]

### Pattern 5: Structural DSIG, Opaque Payload

For TTC v1, status is always `Absent`; no DSIG tuple exists. For v2, all three tuple fields zero means `Absent`; any partial-zero tuple is `Data`. A present tuple must have tag `0x44534947`, non-zero length, four-byte-aligned offset, checked containment, and exact EOF end. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff; VERIFIED: CONTEXT.md D-15, D-16]

For a supported present envelope:

- DSIG header is 8 bytes: `version:u32`, `numSignatures:u16`, `flags:u16`.
- Require version 1; a complete other version is `Capability`.
- Require at least one signature and `numSignatures <= max_dsig_records`.
- Require `flags & 0xFFFE == 0`.
- Require checked `8 + 12*numSignatures <= dsigLength`.
- Each 12-byte record is `format:u32`, `length:u32`, `signatureBlockOffset:u32`.
- Require format 1; a structurally complete other format is `Capability`.
- Require `length >= 8`; block range is relative to DSIG start, wholly within DSIG, disjoint from header/record array and other blocks.
- Format-1 block begins with two zero `u16` reserved fields and `signatureLength:u32`; require `8 + signatureLength == record.length` and `signatureLength > 0`.
- Never read, copy, parse, hash, or authenticate the opaque `signature[signatureLength]` bytes.

The wire shapes and table-relative block offset are normative OpenType 1.9.1 facts. The non-zero count/payload, no-overlap, exact inner/outer length, and reserved-bit enforcement are the recommended fail-closed v0.33 structural policy consistent with D-16. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/dsig; RECOMMENDATION derived from CONTEXT.md D-16, D-17]

## Exact Resource Authority

### Semantic Ceilings

`FontCollectionLimits::new` must reject zero in constructor argument order with `InvalidInput/InvalidRange`, operation `font-collection-limits-new`, `requested=0`, `limit=1`, and the matching kebab-case context. It should otherwise preserve all `UInt64` values verbatim. [RECOMMENDATION mirroring verified `FontLimits::new`]

Apply ceilings and staged work authority in this order:

1. `max_source_bytes`
2. `max_faces`
3. for present DSIG tuple authority, `max_dsig_bytes`
4. declaration-work `max_work`, then caller work preflight
5. `max_tables_per_face` for each face in offset-array order
6. checked cumulative `max_table_records`
7. for present DSIG count authority, `max_dsig_records`
8. structural-work `max_work`, then caller work preflight
9. after complete structural and DSIG semantic facts, `max_retained_bookkeeping_bytes`
10. exact total `max_work`
11. full caller budget preflight

This order implements D-18 and ensures every attacker-counted traversal is authorized before it runs. Declaration, structural, and exact-total one-short boundaries are separately observable and must be tested under both collection and caller authority. [VERIFIED: CONTEXT.md D-10, D-18]

### Retained Layout and Charge Formula

Use this target-neutral conservative accounting model:

| Retained fact | Accounted bytes | Contents |
|---------------|-----------------|----------|
| `FontCollection` base | 96 | root `ByteView` handle (modeled as four 64-bit slots), opening revision, version/count/status, two array handles, and conservative target-neutral slack |
| one `CollectionFaceFacts` | 40 | directory start, directory end, table count, sfnt version, profile discriminator |
| one `CollectionProtectedRange` | 24 | start, end, kind/owner discriminator |

Let `F = numFonts`, `S = 1` for present DSIG else `0`, and `P = 1 + F + S`. Then:

```text
face_bytes      = checked_mul(F, 40)
protected_bytes = checked_mul(P, 24)
retained_bytes  = checked_add(96, checked_add(face_bytes, protected_bytes))

ResourceCharge:
  bytes           = retained_bytes
  allocations     = 2
  allocation_size = max(face_bytes, protected_bytes)
  width/height/pixels = 0
  work            = exact_work below
```

The root source length is checked against `max_source_bytes` but is not included in `ResourceCharge.bytes`, because the collection retains the caller-owned `ByteView` without copying it. [VERIFIED: CONTEXT.md D-11; `ByteView` implementation]

Formula overflow is a `Resource/BudgetExceeded` failure for the corresponding semantic ceiling, never a raw arithmetic error and never `Data`. Test exact fit and one short for retained bytes, allocation count, allocation size, and budget work. [RECOMMENDATION derived from CONTEXT.md D-10 through D-13, D-19]

### Exact Work Formula

Define one work unit as one fixed-cost logical field read, record/profile visit, pair comparison, or retained-fact normalization. The implementation and tests must use these constants from one helper; no loop may silently add uncharged work. [RECOMMENDATION]

Let:

- `F = numFonts`
- `R = sum(numTables_i)`
- `P = 1 + F + S`
- `N = numSignatures` when DSIG is present, otherwise `0`
- `V = 1` for TTC v2 else `0`
- `S = 1` for a present DSIG else `0`
- `C2(x) = x * (x - 1) / 2`, checked with the subtraction before multiplication

Use:

```text
declaration_reads =
  3                   # TTC tag, version, numFonts
  + F                 # directory offsets
  + F                 # per-face numTables discovery
  + 3*V               # v2 DSIG tuple
  + 3*S               # DSIG version/count/flags discovery

structural_reads =
  3                   # TTC tag, version, numFonts replay
  + F                 # directory offsets replay
  + 3*V               # v2 tuple replay
  + 5*F               # sfntVersion, numTables, three search facts
  + 4*R               # tag, checksum, offset, length

profile_work    = R
protected_work  = C2(P) + R*P
alias_work      = C2(R)
dsig_work       = S * (3 + 6*N + C2(N))
normalization   = 1 + F + P

exact_work =
  declaration_reads
  + structural_reads
  + profile_work
  + protected_work
  + alias_work
  + dsig_work
  + normalization
```

`C2(R)` compares every unordered table pair exactly once and applies the same-face/cross-face rule. `C2(P)` compares every protected pair. `R*P` compares every table with every protected range. `6*N` accounts for three signature-record fields and three format-1 block-header fields per record. DSIG block-pair overlap contributes `C2(N)`. [RECOMMENDATION derived from CONTEXT.md D-08, D-09, D-13]

All formula terms must be computed after the relevant count ceiling and before the relevant loop. Overflow in `C2`, products, or sums is `Resource` against `max_work`. Payload bytes, table checksums, selected-face required-table admission, and PKCS#7 content are not work terms in Phase 101. [VERIFIED: CONTEXT.md D-06, D-13, D-17]

## Stable Error Precedence

Use existing `CoreError` pairs:

| Outcome | Category | Code |
|---------|----------|------|
| bad zero limit / bad face index | `InvalidInput` | `InvalidRange` |
| malformed/truncated/inconsistent collection bytes | `Data` | `InvalidEncoding` |
| recognized unsupported collection version or DSIG version/format | `Capability` | `CapabilityUnavailable` |
| semantic ceiling, formula overflow, or caller budget exhaustion | `Resource` | `BudgetExceeded` |
| source revision drift | `State` | `InvalidRange` |

These pairs match the existing font package's observable taxonomy. [VERIFIED: `directory.mbt`, `font.mbt`, `limits.mbt`; CONTEXT.md D-19]

Within `FontCollection::open`, freeze this first-failure order:

1. Limit construction occurs before the call and fails in constructor argument order.
2. Source-byte ceiling.
3. Minimum 4-byte tag envelope; `ttcf` tag.
4. Minimum 12-byte base header; exact version `1.0` or `2.0`. A complete other version is `Capability`; random/non-container tag is `Data`. Recognized standalone SFNT/WOFF signatures may use `Capability` context `font-collection-container`.
5. Non-zero face count, then `max_faces`.
6. Checked complete offset-array and version-dependent header envelope.
7. TTC v2 DSIG tuple coherence, tag/alignment/range, and `max_dsig_bytes`.
8. Declaration-work `max_work`, then caller-work preflight; a one-short failure precedes the per-face declaration scan.
9. Per face in offset-array order: directory offset/minimum range, non-zero table count, per-face and cumulative ceilings; then bounded DSIG header/count discovery and `max_dsig_records`.
10. Structural-work `max_work`, then caller-work preflight; a one-short failure precedes all face, protected-range, alias, and DSIG-body traversal.
11. Per face in offset-array order: SFNT header/search facts, records in tag order, checked table ranges, then profile facts.
12. Protected ranges in header/directory/DSIG order; table/protected and table/table comparisons in deterministic earlier-record order.
13. DSIG version, count-zero, flags, record/block envelopes in record order, format, reserved/length/overlap facts.
14. Retained-byte ceiling, then exact total work ceiling.
15. Full `Budget::preflight` in its built-in dimension order.
16. Normalize retained facts.
17. Final root revision guard.
18. `Budget::charge` once, then construct/return `FontCollection`.

Malformed range arithmetic from wire offsets must be remapped to `Data/InvalidEncoding` with `font-collection-*` context; do not leak `CheckedRange`'s `InvalidInput` category for hostile bytes. [RECOMMENDATION derived from CONTEXT.md D-18, D-19 and verified core behavior]

Recognized unsupported per-face profiles do not fail `FontCollection::open`; they are returned as profile values. Only an unsupported container version or supported-envelope DSIG version/format produces `Capability` during Phase 101. [VERIFIED: CONTEXT.md D-04, D-17, D-19]

## Root Revision Protocol

1. Capture `opening_revision = source.mutation_revision()` as the first operation inside `FontCollection::open`.
2. Perform all passes against the same root `ByteView`; never retain or substitute a directory subview as identity.
3. After normalization but before budget commit/publication, require `source.mutation_revision() == opening_revision`.
4. Retain the same root view and captured revision in `FontCollection`.
5. `face_count`, `face_profile`, and `dsig_status` call one private `FontCollection::require_revision` before reading cached facts.
6. Use operation `font-collection-open` for open drift and `font-collection-query` for inspection drift, with context `font-collection-source-revision-drift`.
7. Mutation followed by restoration remains invalid because the revision is monotonic per successful lease write.

The existing `ByteView` implementation shares one mutable revision cell across root views and subviews and increments it on every successful mutable lease write. [VERIFIED: `modules/mb-core/bytes/views.mbt`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Offset/length safety | Native-`Int` arithmetic or `.to_int()` on wire values | `@checked.checked_*`, `CheckedRange`, then checked narrowing after authority | Avoid target-width divergence and wrong error categories. [VERIFIED: mb-core source; project constraints] |
| Retained source identity | Byte copying or custom mutation hashes | Root `ByteView` + `mutation_revision` | Already zero-copy and catches mutate-back. [VERIFIED: mb-core source] |
| Caller resource transaction | Custom counters | `Budget::preflight` + one `Budget::charge` | Preserves hierarchy and atomic dimension order. [VERIFIED: mb-core source] |
| SFNT search facts | A second approximate formula | Existing `font_directory_search_facts` | Exact and already tested at power-of-two boundaries. [VERIFIED: directory/font white-box tests] |
| DSIG authenticity | PKCS#7 parser, certificate store, crypto | Structural format-1 envelope only | Trust is explicitly excluded and would add a new security boundary. [VERIFIED: CONTEXT.md D-16, D-17] |
| Sharing detection | Byte equality/digest/cache | Exact root range + tag/length/checksum metadata comparison | Phase 101 does no payload scan; equal content at distinct offsets is not shared identity. [VERIFIED: CONTEXT.md D-06, D-08] |
| Selected face admission | Duplicate `Font` or eager sibling decoding | Defer to Phase 102 | TTC-01 ends at inspection. [VERIFIED: REQUIREMENTS.md; CONTEXT.md] |

## Common Pitfalls

### Pitfall 1: Rebasing Table Offsets

**What goes wrong:** reading a face directory through `source.subview(directoryOffset, ...)` and then resolving table offsets against that subview yields `directoryOffset + tableOffset`.  
**How to avoid:** add the directory base only to directory-local field locations; resolve every table record unchanged against root byte zero.  
**Warning test:** choose a non-zero directory and a table offset that remains in bounds under the wrong rebase, so a simple out-of-range test cannot pass accidentally. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff; VERIFIED: CONTEXT.md specifics]

### Pitfall 2: Calling the Standalone Parser

**What goes wrong:** `parse_font_directory` assumes offset zero, rejects `ttcf`, rejects every table overlap globally, and its work includes whole-source checksum scans.  
**How to avoid:** share only pure cursor/search/range helpers; add a collection-specific structural parser. [VERIFIED: `directory.mbt`]

### Pitfall 3: Allocating Before Cumulative Authority

**What goes wrong:** bounded tables-per-face still allow `faces * tables` to exceed retained/work authority.  
**How to avoid:** checked-add all table counts against `max_table_records` before any dependent allocation or pair scan. [VERIFIED: CONTEXT.md D-09, D-10]

### Pitfall 4: Treating Equal Bytes as Shared Identity

**What goes wrong:** same-size/same-content tables at different offsets are incorrectly coalesced, or exact ranges with conflicting metadata are accepted.  
**How to avoid:** only exact equal root ranges with equal tag/length/checksum metadata are aliases. [VERIFIED: CONTEXT.md D-08]

### Pitfall 5: Protecting Only the Current Directory

**What goes wrong:** a table from face 0 can overlap face 1's directory, the offset array, or the DSIG range.  
**How to avoid:** build the full protected set first and compare every table against all `P` ranges. [VERIFIED: CONTEXT.md D-08]

### Pitfall 6: Accidentally Performing Semantic Admission

**What goes wrong:** missing `head`, bad cmap, corrupt checksum, or unsupported sibling CFF becomes an open failure.  
**How to avoid:** Phase 101 stops at directory/profile/DSIG structure and performs no table payload reads except DSIG's own envelope. [VERIFIED: CONTEXT.md D-04, D-06]

### Pitfall 7: Calling `PresentUnverified` “Valid”

**What goes wrong:** callers infer authenticity from a structurally parseable DSIG.  
**How to avoid:** use the exact public variant `PresentUnverified`, document opaque payload semantics, and add no `is_valid`/`trusted` accessor. [VERIFIED: CONTEXT.md D-16, D-17]

### Pitfall 8: Charging the Root as Copied Bytes

**What goes wrong:** `ResourceCharge.bytes = source.length`, repeating the standalone model even though no collection copy occurs.  
**How to avoid:** charge only the 96-byte conservative base plus compact retained arrays; keep source length solely as a semantic ceiling. [VERIFIED: CONTEXT.md D-11]

### Pitfall 9: Leaking Checked-Primitive Error Categories

**What goes wrong:** malformed wire ranges surface as `InvalidInput` because `CheckedRange` is a general caller-input primitive.  
**How to avoid:** collection range helpers catch and remap to `Data/InvalidEncoding`; only public index/limit misuse stays `InvalidInput`. [VERIFIED: core source; CONTEXT.md D-19]

### Pitfall 10: Charging Before the Final Revision Guard

**What goes wrong:** a mutate-back or mid-open mutation fails after counters have been committed.  
**How to avoid:** final revision guard immediately precedes the single `Budget::charge` and publication. [VERIFIED: CONTEXT.md D-12, D-14, D-18]

## Code Examples

### Checked Root-Relative Directory Envelope

```moonbit
fn collection_directory_range(
  source : @bytes.ByteView,
  directory_offset : UInt64,
  num_tables : UInt64,
) -> Result[@checked.CheckedRange, @error.CoreError] {
  let record_bytes = match @checked.checked_mul(num_tables, 16UL) {
    Ok(value) => value
    Err(_) => return Err(collection_data_error("font-collection-directory-range"))
  }
  let length = match @checked.checked_add(12UL, record_bytes) {
    Ok(value) => value
    Err(_) => return Err(collection_data_error("font-collection-directory-range"))
  }
  let source_range = @checked.CheckedRange::from_start_length(
    0UL,
    source.length(),
  ).unwrap()
  match source_range.subrange(directory_offset, length) {
    Ok(range) => Ok(range)
    Err(_) => Err(collection_data_error("font-collection-directory-range"))
  }
}
```

This follows the repository's checked half-open range pattern while remapping hostile wire failures to collection `Data`. [VERIFIED: `range.mbt`; RECOMMENDATION]

### Revision-Guarded Cached Inspection

```moonbit
pub fn FontCollection::face_profile(
  self : FontCollection,
  index : UInt64,
) -> Result[FontFaceProfile, @error.CoreError] {
  match self.require_revision("font-collection-query") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  let count = self.faces.length().to_uint64()
  if index >= count {
    return Err(collection_index_error(index, count))
  }
  let narrowed = match @checked.checked_narrow_int(index) {
    Err(_) => return Err(collection_index_error(index, count))
    Ok(value) => value
  }
  Ok(self.faces[narrowed].profile)
}
```

Revision-first inspection and checked narrowing match the retained-source contract. [VERIFIED: existing `Font` query pattern; CONTEXT.md D-14]

## Adversarial Validation Matrix

Plan both black-box public outcomes and white-box exact formula/range assertions:

| Area | Required Cases |
|------|----------------|
| Limits | Every zero constructor field in argument order; exact values/getters; source/face/per-face/cumulative/DSIG/retained/work exact and one-short. |
| TTC header | Lengths 0–11; random tag; recognized standalone/WOFF tag; versions 1.0 and 2.0; minor/major unsupported; zero faces; truncated offset array; v2 tuple truncation. |
| Directory origins | Face directory at non-zero offset; table before and after directory; wrong-rebase fixture that remains in bounds; duplicate directory offsets; directory/header/directory intersections. |
| Search facts/tags | `numTables=0`; power-of-two boundaries; wrong searchRange/selector/shift; unordered and duplicate tags; last-record truncation. |
| Table ranges | offset+length/out-of-source; unaligned non-empty table; empty table boundary; same-face exact and partial overlap; table/header, any-directory, and DSIG intersection. |
| Sharing | exact range+metadata allowed across faces; same range conflicting tag/checksum/length rejected; partial overlap rejected; same-sized distinct ranges allowed; equal payload at distinct ranges not treated as alias. |
| Profiles | static glyf; CFF; CFF2; glyf variable; CFF2 variable; mixed collection; contradictory outline tags as `OtherUnsupported`; unsupported sibling does not fail opening. |
| DSIG tuple | v1 absent; v2 all zero absent; each partial-zero combination; wrong tag; zero/non-EOF/out-of-source/unaligned range; DSIG intersecting structural/table ranges. |
| DSIG body | short header; version 1/unsupported version; zero/over-limit count; reserved flags; short record array; format 1/unsupported format; block into header/record array; block escape; overlapping blocks; nonzero reserved fields; inner/outer length mismatch; empty payload. |
| Atomicity | Every Data/Capability/Resource/State failure leaves all budget dimensions unchanged; success charges exact bytes/allocations/allocation_size/work once. |
| Revision | mutation before query; required/unrelated byte mutation; mutate-restore; deterministic mid-open hook/white-box seam; independent collections retain isolated revisions. |
| Compatibility | Existing standalone `Font::open` vectors, contexts, and 103-test native suite remain unchanged; generated interface gains only the new public collection symbols. |

The existing native package baseline is 103/103 passing at research time. [VERIFIED: local `moon -C modules/mb-font test font --target native --frozen --target-dir target/phase101-research-native --no-parallelize`]

## Validation Architecture

This section is included for planner consumption even though `.planning/config.json` currently sets `workflow.nyquist_validation` to `false`, as explicitly requested for Phase 101 research. [VERIFIED: config and orchestrator task]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | MoonBit built-in black-box `*_test.mbt` and white-box `*_wbtest.mbt` |
| Config file | `modules/mb-font/font/moon.pkg` |
| Quick run command | `moon -C modules/mb-font test font/collection_test.mbt --target native --frozen --target-dir target/phase101-quick --no-parallelize` |
| Private quick command | `moon -C modules/mb-font test font/collection_wbtest.mbt --target native --frozen --target-dir target/phase101-wb --no-parallelize` |
| Full native command | `moon -C modules/mb-font test font --target native --frozen --target-dir target/phase101-native --no-parallelize` |
| Full four-target command | Repeat full package command for `js`, `wasm`, `wasm-gc`, `native` with distinct target directories |

The package declares all four supported targets and currently has both black-box and white-box test infrastructure. [VERIFIED: `moon.pkg`; filesystem inspection]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TTC-01 | Limits/public enums/facade/count/profile/DSIG status and public errors | black-box | `moon -C modules/mb-font test font/collection_test.mbt --target native --frozen --target-dir target/phase101-public --no-parallelize` | ❌ Wave 0 |
| TTC-01 | Exact header/range/profile/alias/DSIG/formula helpers | white-box | `moon -C modules/mb-font test font/collection_wbtest.mbt --target native --frozen --target-dir target/phase101-private --no-parallelize` | ❌ Wave 0 |
| TTC-01 | Standalone behavior remains unchanged | regression | `moon -C modules/mb-font test font --target native --frozen --target-dir target/phase101-regression --no-parallelize` | ✅ |
| TTC-01 | Public semantic interface contains no raw facts | interface gate | `moon -C modules/mb-font info --target all --frozen` plus filtered `pkg.generated.mbti` assertion | Existing command; new assertion required |

### Sampling Rate

- **Per task commit:** focused new black-box or white-box file plus the existing standalone signature/error regression selector.
- **Per plan merge:** full native `font` package suite.
- **Phase gate:** full package green on all four declared targets, `moon check`, generated interface inspection, and exact charge/error vector review.

### Wave 0 Gaps

- [ ] `modules/mb-font/font/collection_test.mbt` — public TTC-01 contract and transactional outcomes.
- [ ] `modules/mb-font/font/collection_wbtest.mbt` — private range/alias/DSIG/formula/precedence matrix.
- [ ] Deterministic generated micro-collection builders inside test code (TTC v1/v2, mixed profiles, DSIG blocks, named mutations).
- [ ] Interface assertion that only `FontCollection`, `FontCollectionLimits`, `FontFaceProfile`, `FontCollectionDsigStatus`, their getters/methods, and no private storage facts are exported.

No test framework installation is required. [VERIFIED: existing package tests]

## Security Domain

Security enforcement is not explicitly disabled, so this section is required. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity/authentication boundary in a byte parser. |
| V3 Session Management | no | No session state. |
| V4 Access Control | no | No principal or protected operation. |
| V5 Input Validation | yes | Checked big-endian reads, `UInt64` arithmetic, semantic count ceilings, half-open containment, closed tags/versions, exact error taxonomy. |
| V6 Cryptography | no for Phase 101 | DSIG payload is opaque and status is explicitly unverified; no cryptographic claim or primitive is implemented. |

This is a phase-local applicability mapping, not a general compliance certification. [RECOMMENDATION based on verified phase boundary]

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Crafted count causes allocation/pair explosion | Denial of Service | Per-face+cumulative limits, formula preflight, no allocation before authority. [VERIFIED: CONTEXT.md D-09 through D-13] |
| Root-relative offset confusion | Tampering | Root-coordinate `CheckedRange` model and in-bounds wrong-rebase tests. [CITED: OpenType `otff`] |
| Partial/metadata-conflicting alias | Tampering | Exact range+metadata sharing rule; reject every partial overlap. [VERIFIED: CONTEXT.md D-08] |
| Structural bytes overlap parser metadata | Tampering | Full protected-range set and `R*P` comparisons. [VERIFIED: CONTEXT.md D-08] |
| DSIG presence misrepresented as trust | Spoofing | Closed `PresentUnverified` status; no crypto/trust API. [VERIFIED: CONTEXT.md D-16, D-17] |
| Mutate-back after validation | Tampering | Monotonic root revision retained and checked at publication/query. [VERIFIED: mb-core source; CONTEXT.md D-14] |
| Multi-fault parser oracle instability | Information disclosure / operational ambiguity | Frozen authority-first, wire-order error precedence and bounded contexts. [VERIFIED: CONTEXT.md D-18, D-19] |

## Plan Decomposition Recommendation

Use three plans in dependency order:

### Plan 101-01 — Public Identity and Semantic Authority

- Add `FontCollectionLimits`, getters, zero-limit error matrix, public profile/DSIG enums, opaque `FontCollection` shell, revision error/index helpers, and API documentation.
- Freeze the generated semantic interface before parser implementation.
- Tests: limit exact/zero matrix, enum/public opacity, revision-first index semantics with a minimal private constructor seam.

### Plan 101-02 — Bounded TTC Directory and Protected Envelope

- Add allocation-free declaration and structural passes for TTC v1/v2 header, offsets, all face directory/search/tag/range facts, profile classification, protected ranges, and exact sharing.
- Add shared exact formula helpers and compact retained layout/charge construction.
- Tests: non-zero origin, wrong-rebase-in-bounds, all overlap/alias/profile cases, exact work/retention limits, and unchanged `Font::open`.

### Plan 101-03 — DSIG, Atomic Publication, and Phase Gate

- Add v2 tuple and bounded version-1/format-1 DSIG envelope traversal; integrate the exact final charge, normalization, revision guard, and facade publication.
- Complete public/white-box precedence and transactional matrices.
- Run full native then separate four-target package suites and interface leak checks.

Do not include selected-face `Font` admission, directory-parser generalization, collection checksum mode, licensed large TTC fixtures, or qualification scripts beyond phase-local generated bytes; those belong to Phases 102 and 103. [VERIFIED: roadmap/requirements/context boundary]

## State of the Art

| Old/Adjacent Approach | Current Phase 101 Approach | Impact |
|-----------------------|----------------------------|--------|
| Standalone directory at byte zero | TTC header points to one complete directory per face | New parser must parameterize read locations without rebasing record offsets. [CITED: OpenType `otff`] |
| TTC historically implied TrueType outlines | OpenType 1.9.1 collections may mix TrueType, CFF, CFF2, SVG, static, and variable resources | Collection admission must be outline-neutral and profile-informative. [CITED: OpenType `otff`] |
| TTC v1 without signature tuple | TTC v2 optionally appends DSIG tag/length/offset | Public status must distinguish absent from structurally present-unverified. [CITED: OpenType `otff`; OpenType `dsig`] |
| Standalone whole-font checksumAdjustment | Collection `head.checksumAdjustment` is ignored; table checksums reflect collection bytes | Phase 101 performs neither payload checksum path; Phase 102 must choose collection policy explicitly. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/head; https://learn.microsoft.com/en-us/typography/opentype/spec/otff] |

## Assumptions Log

All factual claims in this research were verified against the repository, locked project context, local toolchain, or official OpenType 1.9.1 documentation. Prescriptive choices beyond those sources are labeled as recommendations rather than facts. No `[ASSUMED]` claims remain.

## Open Questions

No blocking question remains for planning. CONTEXT.md resolves the previously open entry-point, structural-vs-semantic, sharing, DSIG trust, resource, revision, and error-category decisions. This research additionally freezes:

1. the concrete public type/method names;
2. a compact 96/40/24-byte retained model;
3. the exact two-allocation `ResourceCharge`;
4. the exact work formula;
5. revision-first inspection precedence;
6. DSIG record/block fail-closed rules; and
7. a three-plan implementation sequence.

These are pre-1.0 recommendations under the agent's discretion and can be changed only deliberately in the planner with equivalent exact formulas and tests. [VERIFIED: CONTEXT.md discretion]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | build/test/info | ✓ | `0.1.20260713` | none needed |
| `moonc` | compile | ✓ | `v0.10.4+2cc641edf` | supplied by pinned toolchain |
| `moonrun` | target execution | ✓ | `0.1.20260713` | none needed |
| `tchivs/mb-core` workspace module | ranges/bytes/budget/errors | ✓ | repository workspace | no alternative permitted |
| External crypto/FFI/font engine | not required | n/a | — | intentionally absent |

The native baseline command completed 103/103 tests successfully. [VERIFIED: local CLI execution]

**Missing dependencies with no fallback:** none.  
**Missing dependencies with fallback:** none.

## Sources

### Primary (HIGH authority; MEDIUM seam confidence because fetched through verified WebSearch)

- [OpenType font file 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — SFNT directory, root-relative TTC offsets, TTCHeader v1/v2, sharing, table checksums.
- [OpenType DSIG table 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/dsig) — DSIG header, records, format-1 blocks, collection EOF/whole-file semantics.
- [OpenType head table 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/head) — collection ignores `checksumAdjustment`.
- [OpenType glyph format comparison 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison) — `glyf`/`CFF `/`CFF2` distinctions.
- [OpenType fvar table 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/fvar) — all variable fonts include `fvar`.
- [OpenType CFF2 table 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/cff2) — `OTTO`, CFF2 and variation relationships.
- Repository `AGENTS.md`, RFC 0004, phase CONTEXT/REQUIREMENTS/STATE, and `mb-font`/`mb-core` sources — project authority and implementation seams.

### Secondary

- `.planning/research/SUMMARY.md` — milestone synthesis cross-checked against primary OpenType pages and current repository sources.

### Tertiary

- None used for implementation decisions.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — locally versioned and already passing the font suite.
- OpenType wire rules: HIGH authority / MEDIUM seam classification — official OpenType 1.9.1 pages fetched and cross-checked.
- Architecture integration: HIGH — directly inspected current `font.mbt`, `directory.mbt`, `limits.mbt`, cursor, budget, range, views, manifests, and tests.
- Public API/accounting formula: MEDIUM-HIGH — prescriptive pre-1.0 choices derived from locked decisions and existing accounting patterns; exact-one-short tests are required.
- Pitfalls/security: HIGH — directly follow locked hostile-input decisions, primary wire rules, and current source assumptions.

**Research date:** 2026-07-28  
**Valid until:** 2026-08-27, or earlier if the OpenType baseline, MoonBit toolchain, Phase 101 context, or current font admission seams change.
