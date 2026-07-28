---
phase: 101-collection-contract-and-bounded-envelope
verified: 2026-07-28T00:00:59Z
status: passed
score: 17/17 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 101: Collection Contract and Bounded Envelope Verification Report

**Phase Goal:** Library authors can open caller-provided raw TTC/OTC version 1 or 2 bytes under explicit authority and inspect the collection's bounded semantic face facts without exposing parser internals.
**Verified:** 2026-07-28T00:00:59Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

The three ROADMAP success criteria are retained verbatim as truths 1–3. PLAN truths were then merged and deduplicated into truths 4–17; none reduce the ROADMAP contract.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A library author can open immutable TTC/OTC version 1 or 2 bytes and observe the exact non-zero face count without copying the complete collection or materializing standalone fonts. | ✓ VERIFIED | `FontCollection::open` retains the caller root `ByteView`; `font_collection_parse` publishes compact face/protected facts only. The v1 tracer and v2 five-face tests pass on all four targets. |
| 2 | A library author can inspect every zero-based face through a closed bounded profile that distinguishes supported static `glyf`, CFF/CFF2, variable, and other unsupported faces without exposing raw offsets or table records. | ✓ VERIFIED | `FontFaceProfile` has exactly five closed variants; the v2 mixed-profile test observes all five in offset-array order. The 84-line generated interface exposes no parser/storage facts. |
| 3 | A library author can distinguish a version-2 collection with no DSIG from one with a structurally present but explicitly unverified DSIG envelope. | ✓ VERIFIED | All-zero v2 tuple maps to `Absent`; a bounded v1/format-1 envelope maps only to `PresentUnverified`. Public/white-box tests pass on all targets. |
| 4 | The collection facade is additive and standalone `Font::open` remains unchanged and standalone-SFNT-only. | ✓ VERIFIED | `modules/mb-font/font/font.mbt` has the same Git blob hash at pre-phase `58fea614` and current source (`a9b5a657...`). All 56 pre-existing interface lines remain an exact ordered subsequence; full native font suite passes 131/131. |
| 5 | Empty/truncated/zero-face inputs are Data, exact semantic ceilings admit, and one-over declarations fail Resource before dependent traversal without charging. | ✓ VERIFIED | Public boundary tests cover 0–3-byte/truncated sources, zero faces, source/face/per-face/cumulative ceilings, and unchanged `Budget::remaining`; staged parser checks precede their dependent loops. |
| 6 | `FontCollectionLimits` preserves eight exact `UInt64` ceilings and rejects zero in constructor argument order with stable InvalidInput facts. | ✓ VERIFIED | Constructor performs eight ordered non-zero checks and stores exact values; dedicated getter/zero-matrix tests pass. |
| 7 | Every query checks the retained root revision first; unchanged out-of-range indices are InvalidInput, while mutation and mutate-restoration are State. | ✓ VERIFIED | `require_revision` is the first operation in all three queries. Named mutation, restore, revision-vs-index, and owner-isolation tests pass on all four targets. |
| 8 | The generated public interface exactly matches the tracked ordered allowlist and contains only the additive collection contract. | ✓ VERIFIED | Fresh `moon info --target all --frozen` produced exactly 84 semantic lines, byte-for-byte equal to `policy/foundation.json`; the independent Phase 101 classifier and negative fixtures pass. |
| 9 | Root-relative ranges, protected structures, and exact cross-face sharing distinguish valid touching/equality from every forbidden overlap or metadata conflict. | ✓ VERIFIED | Table offsets are read unchanged from collection-root records; protected and alias loops validate all pairs. Wrong-rebase, touching, exact-sharing, same-face, partial-overlap, metadata-conflict, duplicate-directory, and alignment tests pass. |
| 10 | Face index order follows the TTC offset array, ordered unique tags are required, and equal/unsupported profiles remain independent informative entries. | ✓ VERIFIED | Structural scanning iterates `face_index` in wire order, rejects `tag <= previous`, and normalizes one fact per face. The mixed-profile test returns all five profiles at their original indices. |
| 11 | Counts, ranges, products, pair work, narrowing, semantic ceilings, and caller budgets remain checked and exact-one-short failures are atomic. | ✓ VERIFIED | Parser arithmetic uses checked `UInt64`; `C2`, retained bytes, work, budget bytes/allocations/allocation-size/work, and three staged work boundaries have exact-fit/one-short tests. |
| 12 | Successful admission charges only compact retained bookkeeping (`96 + 40*F + 24*P`), two allocations, maximum compact-array size, and deterministic declared work—not source length. | ✓ VERIFIED | `font_collection_retained_charge` implements the 96/40/24 formula and excludes `source.length`; exact budget delta tests pass. |
| 13 | DSIG tuple/envelope/record/block semantics are bounded, malformed structure is Data, complete unsupported version/format is Capability, and payload content is never interpreted or trusted. | ✓ VERIFIED | Parser validates tuple coherence, root range/alignment/EOF, header, records, containment, overlaps, reserved fields, and exact lengths; only the block header's payload length is read. No payload accessor, crypto, trust store, or trust-named public status exists. |
| 14 | DSIG record/byte/pair-work ceilings accept equality and fail one-over/one-short atomically. | ✓ VERIFIED | One- and two-record DSIG tests cover record, byte, structural/exact work, caller work, overlap, touching, containment, and trailing-gap boundaries. |
| 15 | Validation and normalization precede the final revision guard, one budget charge, and publication; mid-open mutate-restoration publishes and charges nothing. | ✓ VERIFIED | `open_after_normalize` calls parse/preflight/normalize, invokes the deterministic test seam, checks the opening revision, then charges once and constructs `FontCollection`. The named white-box transition test passes on all targets. |
| 16 | D-18 staged authority and D-19 error taxonomy have stable, traversal-aware precedence. | ✓ VERIFIED | Declaration-work 11/10, structural-work 43/42, and exact-work 57/56 boundaries pass under both collection and caller authority. Tuple authority precedes faces; DSIG version/count/flags semantics follow face/protected/alias facts. Tests exercise InvalidInput, Data, Capability, Resource, and State. |
| 17 | The complete Phase 101 contract is portable and adds no selected-face admission, payload checksumming, FFI, ambient I/O, or new dependency. | ✓ VERIFIED | Public 24/24 and white-box 4/4 collection tests pass independently on `js`, `wasm`, `wasm-gc`, and `native`; target-all check and policy gates pass. Source/interface scans find no selected-face API, external declaration, ambient I/O, or dependency change. |

**Score:** 17/17 truths verified (0 present, behavior-unverified)

## Locked Decision Audit

| Decision | Status | Actual codebase evidence |
|---|---|---|
| D-01 | ✓ VERIFIED | Separate opaque `FontCollection`; unchanged `Font::open` blob and signature; no TTC auto-detection added to `font.mbt`. |
| D-02 | ✓ VERIFIED | Dedicated eight-field `FontCollectionLimits`; `FontLimits` blob is unchanged. |
| D-03 | ✓ VERIFIED | Public surface contains count, closed profile, and closed DSIG status only. |
| D-04 | ✓ VERIFIED | Exact `StaticGlyf`, `Cff`, `Cff2`, `Variable`, `OtherUnsupported` classification and mixed-profile behavior. |
| D-05 | ✓ VERIFIED | Header, offset array, every directory/search tuple/tag/range/profile, protected ranges, and optional DSIG are structurally validated. |
| D-06 | ✓ VERIFIED | Collection parser does not call standalone directory admission, checksum table payloads, enforce the standalone required-table set, or construct `Font`. |
| D-07 | ✓ VERIFIED | Directory fields add `directory_start`; table-record offsets are passed directly to the root `CheckedRange`. Wrong-rebase test passes. |
| D-08 | ✓ VERIFIED | Global header/directory/DSIG protected set; exact cross-face range plus tag/length/stored checksum only; other overlaps rejected. |
| D-09 | ✓ VERIFIED | Face/table/DSIG counts and deterministic pair work are checked before their dependent scans. |
| D-10 | ✓ VERIFIED | Eight non-zero ceilings and ordered stable constructor errors. |
| D-11 | ✓ VERIFIED | Root `ByteView` is retained; source length is authority but is absent from `ResourceCharge.bytes`. |
| D-12 | ✓ VERIFIED | Staged work preflights, exact full preflight, compact normalization, final revision guard, one charge, then publication; failure budget equality tests pass. |
| D-13 | ✓ VERIFIED | Work includes declaration, structural/profile/protected/alias/DSIG/normalization operations and excludes payload checksum/selected-face semantics. |
| D-14 | ✓ VERIFIED | Opening revision captured at entry, final-guarded before charge, retained, and checked first by every query; mutate-restoration tests pass. |
| D-15 | ✓ VERIFIED | v1 and v2 all-zero tuple are `Absent`; partial-zero tuples are Data. |
| D-16 | ✓ VERIFIED | Present DSIG is aligned, root-bounded, EOF-terminated, version 1/format 1, structurally checked, opaque, and only `PresentUnverified`. |
| D-17 | ✓ VERIFIED | Malformed DSIG is Data; complete unsupported version/format is Capability; no cryptographic claim or mechanism exists. |
| D-18 | ✓ VERIFIED | Clarified tiers are implemented: tuple/declaration authority → declaration-work preflight → bounded counts → structural-work preflight → face/protected/alias → DSIG semantics → retained/exact/full budget → normalization → revision → charge/publication. |
| D-19 | ✓ VERIFIED | Stable public categories/codes exist for InvalidInput, Data, Capability, Resource, and State, with exact-context assertions on precedence vectors. |

## Required Artifacts

| Artifact | Expected | L1 Exists | L2 Substantive | L3 Wired | Status |
|---|---|---:|---:|---:|---|
| `modules/mb-font/font/collection_limits.mbt` | Opaque eight-ceiling authority | Yes | 128 lines; ordered constructor and getters | Used by public open/parser/tests/interface | ✓ VERIFIED |
| `modules/mb-font/font/collection_parser.mbt` | Root-relative bounded parser and exact facts | Yes | 2284 lines; complete passes/formulas/errors | Called by `FontCollection::open_after_normalize` | ✓ VERIFIED |
| `modules/mb-font/font/collection.mbt` | Closed public facade and atomic publication | Yes | 147 lines; no stub/public leak | Exposes parser results through guarded methods | ✓ VERIFIED |
| `modules/mb-font/font/collection_test.mbt` | Black-box contract/hostile/precedence evidence | Yes | 24 named tests with generated fixtures | Compiled and passed on all four targets | ✓ VERIFIED |
| `modules/mb-font/font/collection_wbtest.mbt` | Private range/formula/revision evidence | Yes | 4 named tests | Compiled and passed on all four targets | ✓ VERIFIED |
| `policy/foundation.json` | Ordered interface/source/publication policy | Yes | 84-line interface plus exact inventories | Consumed by `Assert-FontFoundationPolicy` | ✓ VERIFIED |
| `scripts/quality/Assert-Policy.ps1` | Independent fail-closed interface classifier | Yes | Exact allowlist and missing/duplicate/reorder/private/selected-face negatives | Fresh policy invocation passes | ✓ VERIFIED |

`verify.artifacts` reports 16/16 plan-declared artifact occurrences passed across the three plans.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `collection.mbt` | `collection_parser.mbt` | `font_collection_parse` | ✓ WIRED | Public open delegates before final revision/charge/publication. |
| `collection.mbt` | `mb-core/bytes` | retained root plus `mutation_revision` | ✓ WIRED | Same root identity is used at open and query time. |
| `collection_parser.mbt` | `directory.mbt` | `font_directory_search_facts` | ✓ WIRED | Pure search-fact helper reused for every face. |
| `collection_parser.mbt` | `mb-core/checked` | `CheckedRange` and checked arithmetic | ✓ WIRED | Root/header/table/DSIG/block bounds use checked `UInt64`. |
| `collection_parser.mbt` | `mb-core/budget` | staged/full `preflight` plus returned charge | ✓ WIRED | Charge is committed only by facade after revision guard. |
| `collection_parser.mbt` | `collection.mbt` | closed profile/DSIG enum facts | ✓ WIRED | Private facts collapse to public semantic values only. |
| `collection_test.mbt` | public collection facade | black-box calls | ✓ WIRED | No private parser access in black-box suite. |
| `Assert-Policy.ps1` | `foundation.json` and generated interface | exact-sequence comparison | ✓ WIRED | Fresh generation and classifier invocation pass. |

`verify.key-links` reports 11/11 plan-declared links verified.

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `FontCollection` | face facts | Caller root `ByteView` → bounded declaration/structural scans → compact `faces` | Yes; generated v1/v2 fixtures yield 1 and 5 real profiles | ✓ FLOWING |
| `FontCollection` | DSIG status | v2 tuple/envelope → private DSIG facts → closed enum | Yes; absent and present-unverified paths are exercised | ✓ FLOWING |
| `Budget` | resource deltas | checked counts/formulas → staged/full preflight → final revision → one charge | Yes; exact success deltas and unchanged failure counters are asserted | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Public collection contract on `js` | `moon ... collection_test.mbt --target js` | 24/24 | ✓ PASS |
| White-box invariants on `js` | `moon ... collection_wbtest.mbt --target js` | 4/4 | ✓ PASS |
| Public/white-box on `wasm` | two focused commands | 24/24 and 4/4 | ✓ PASS |
| Public/white-box on `wasm-gc` | two focused commands | 24/24 and 4/4 | ✓ PASS |
| Public/white-box on `native` | two focused commands | 24/24 and 4/4 | ✓ PASS |
| Standalone and adjacent font regression | `moon -C modules/mb-font test font --target native ...` | 131/131 | ✓ PASS |
| Portable compilation | `moon -C modules/mb-font check --target all --frozen` | all four targets finished | ✓ PASS |
| Generated interface | `moon ... info --target all` plus exact comparison | 84/84 ordered lines; ignored output | ✓ PASS |
| Policy and negative fixtures | `Assert-FontFoundationPolicy` | exact interface/dependency/inventory/source gates passed | ✓ PASS |

## Probe Execution

Step 7c: SKIPPED — no PLAN/SUMMARY probe path or conventional `probe-*.sh` is declared for this library phase.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| TTC-01 | 101-01, 101-02, 101-03 | Open bounded raw TTC/OTC v1/v2, inspect exact count/closed profiles, distinguish absent/present-unverified DSIG, expose no raw offsets/records. | ✓ SATISFIED | ROADMAP truths 1–3, all four-target focused suites, root-retaining source flow, exact public interface gate. |

No orphaned Phase 101 requirement exists: every PLAN declares TTC-01, and REQUIREMENTS.md maps only TTC-01 to Phase 101. TTC-02/TTC-03 are explicitly Phase 102; TTC-04/TTC-05 are explicitly Phase 103.

## Prohibition Verification

| Prohibition | Status | Evidence |
|---|---|---|
| `Font::open` must not auto-detect TTC/OTC. | ✓ VERIFIED | `font.mbt` blob unchanged from pre-phase baseline; full regression passes. |
| Public collection API must not expose raw storage/parser/revision/DSIG facts. | ✓ VERIFIED | Fresh exact 84-line interface plus independent private-leak negative classifier. |
| Phase 101 must not select a face into `Font` or perform sibling semantic/checksum admission. | ✓ VERIFIED | No selected-face public/private call exists; parser ends at profiles/status; selected-face fixture is rejected by policy. |
| DSIG presence must not claim validity/trust or inspect payload contents. | ✓ VERIFIED | Only `PresentUnverified`; parser reads block-header payload length but no payload byte; no crypto/trust API/dependency. |
| No WOFF/CFF execution, FFI, ambient filesystem/network I/O, or new dependency. | ✓ VERIFIED | Collection source has no external/import/ambient path; module manifests are unchanged and policy preserves `mb-font -> mb-core` only. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, empty implementation, or hardcoded-empty production result in Phase 101 files. | — | None |

## Confirmation-Bias Counter

- **Partial requirement candidate:** selected-face admission and licensed end-to-end fixtures are absent, but REQUIREMENTS/ROADMAP explicitly assign them to Phases 102 and 103. They do not reduce TTC-01 or Phase 101's goal.
- **Potentially misleading test:** the tracer test's name says “atomically,” but that test alone cannot prove no-copy ownership. The no-copy truth is independently established by the retained root `ByteView`, source-excluding `ResourceCharge`, exact blob/interface checks, and failure-budget tests.
- **Uncovered branch search:** no named test targets the DSIG wrong-tag and misalignment branches individually. Direct source checks show fail-closed comparisons before dependent traversal, while tuple/range/EOF and broader DSIG behavior are tested. These are pure deterministic branches, not state-transition invariants, so this is an informational coverage note rather than a goal gap or human-verification item.

## Human Verification Required

None. This phase is a deterministic pure-MoonBit library contract with no visual, real-time, external-service, or performance-feel acceptance criterion. Every state-transition/ordering truth has a passing behavioral test.

## Gaps Summary

No blocking or warning gaps remain. All ROADMAP truths, merged PLAN truths, TTC-01, D-01–D-19, artifacts, links, prohibitions, behavioral transitions, and four-target collection semantics are verified against the actual codebase.

---

_Verified: 2026-07-28T00:00:59Z_
_Verifier: the agent (gsd-verifier)_
