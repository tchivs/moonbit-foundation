---
phase: 104-cff1-profile-and-bounded-data-model
verified: 2026-07-28T13:36:02Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirements:
  - id: CFF-01
    status: satisfied
    reason: "The exact bounded static CFF1 profile, including closed PaintType/StrokeWidth semantics, is implemented and behaviorally verified."
  - id: CFF-02
    status: satisfied
    reason: "Name-keyed and CID-keyed complete per-GID descriptors, checked keying facts, and atomic failure behavior remain implemented and passing."
re_verification:
  previous_status: gaps_found
  previous_score: 7/8
  gaps_closed:
    - "Top DICT PaintType and StrokeWidth are no longer accepted and discarded: omission or decoded exact zero is accepted, while every decoded non-zero value is rejected as a stable Capability outcome."
  gaps_remaining: []
  regressions: []
---

# Phase 104: CFF1 Profile and Bounded Data Model Verification Report

**Phase Goal:** Maintainers can admit only the supported static CFF1 structure and resolve every GID to one checked CharString and execution environment.
**Verified:** 2026-07-28T13:36:02Z
**Status:** passed
**Re-verification:** Yes — after gap-closure Plan 104-04

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Bounded caller-owned `OTTO` bytes admit only the exact supported static CFF1 profile, with deterministic rejection of mixed, CFF2, variable, and otherwise unsupported profiles. | ✓ VERIFIED | Existing profile classification remains passing. Plan 104-04 adds dedicated PaintType/StrokeWidth reduction: omitted or decoded exact zero is accepted; every decoded non-zero value returns operator-specific Capability before admission. |
| 2 | Every admitted name-keyed GID resolves through checked predefined/custom charset and Encoding data to one bounded CharString and one private/local-Subrs/FontMatrix environment. | ✓ VERIFIED | Production `cff_resolve_name_keying` remains wired; wildcard name-keyed regression group passes 5/5. |
| 3 | Every admitted CID-keyed GID resolves through checked ROS, CID charset, FDArray, FDSelect 0/3, every FD Private/local-Subrs environment, and retained matrices; invalid facts prevent publication. | ✓ VERIFIED | Production `cff_resolve_cid_keying` remains wired; wildcard CID regression group passes 7/7. |
| 4 | Exact and one-short structural outcomes are reproducible for Header, INDEX/DICT, String, CharStrings, Private DICT, and global/local Subrs under explicit limits and budgets. | ✓ VERIFIED | Existing exact/one-short and authority tests remain in the 1,204-test passing native suite; focused lookup, format-4 work, and Encoding allocation boundaries also pass. |
| 5 | Header, one reusable INDEX implementation, and separate typed Top/Font/Private DICT schemas use explicit CFF-table or Private-relative authority. | ✓ VERIFIED | The shared INDEX and typed offset facts remain intact. DICT numeric/operator parsing now has one incremental core; Top reduces entries immediately while Font/Private use the collecting wrapper over the same core. |
| 6 | Structural ceilings, cumulative work/allocation authority, error precedence, mutation guards, and one final commit bound the complete transaction. | ✓ VERIFIED | Existing ledger/charge/revision/commit tests pass. New rejected profile fixtures assert no returned admitted facts and unchanged bytes, allocations, allocation-size authority, and work. |
| 7 | Standalone and selected collection admission use one CFF table-local transaction while collection records remain root-relative. | ✓ VERIFIED | Both routes still converge on `admit_cff1_structure_at_after_preflight`; collection and full-suite regressions pass. |
| 8 | Only complete admitted CFF facts cross the private closed outline-source invariant, public CFF font/path promotion remains absent, and static-glyf behavior stays compatible. | ✓ VERIFIED | Private promotion remains `Glyf | Cff1(AdmittedCff1)`. Both public standalone and selected-collection Phase 104 glyf fingerprints pass 1/1. |

**Score:** 8/8 truths verified (0 present-but-behavior-unverified)

## Gap Closure Verification

| Contract | Status | Evidence |
|---|---|---|
| Omitted PaintType/StrokeWidth is accepted | ✓ VERIFIED | Direct Top DICT and real admission tests accept omission. |
| Explicit integer, exact-real, and normalized signed-real zero are accepted | ✓ VERIFIED | Direct matrix covers `0`, real `0`, signed real `-0`, and both operators together; admission matrix exercises integer/real/signed zero. |
| Every successfully decoded non-zero `CffNumber` is Capability | ✓ VERIFIED | Reducers use `magnitude != 0`, independent of sign and denominator. Tests cover positive/negative integers, exact real `2.0`, and positive/negative fractional values for both operators. |
| Malformed parser inputs keep stable Data contexts | ✓ VERIFIED | Tests cover zero operands, truncated integer, truncated escape, reserved byte, malformed/reserved/padded/range real, and trailing operand with exact `font-cff-top-dict*` contexts. |
| Completed-entry arity and duplicate failures use operator-specific Data contexts | ✓ VERIFIED | Two-operand and repeated-zero cases assert exact PaintType/StrokeWidth arity and duplicate contexts. |
| Earlier Capability wins over later malformed bytes | ✓ VERIFIED | `cff_parse_dict_incremental` calls the Top reducer immediately after a complete entry. Tests append truncated integer, truncated escape, and reserved bytes after unsupported PaintType/StrokeWidth and receive the earlier Capability. |
| Earlier realizable Data wins deterministically | ✓ VERIFIED | Reserved operator and malformed-real faults placed before unsupported semantic bytes retain their first parser Data outcome. |
| Rejection is atomic and uncharged | ✓ VERIFIED | End-to-end helper asserts `Err`, exact category/context, and unchanged bytes, allocations, allocation-size authority, and work. |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/cff_index.mbt` | Shared bounded INDEX model and checked object windows | ✓ VERIFIED | Existing single INDEX implementation remains substantive and passing. |
| `modules/mb-font/font/cff_dict.mbt` | One parse core; separate typed Top/Font/Private schemas; closed PaintType/StrokeWidth profile | ✓ VERIFIED | `cff_parse_dict_incremental` is the sole token/number/operator loop. Dedicated `0x105` and `0x108` branches validate arity, duplication, and exact-zero semantics. |
| `modules/mb-font/font/cff_keying.mbt` | Normalized name/CID per-GID descriptors and adapters | ✓ VERIFIED | Unchanged by 104-04 and covered by 5 name plus 7 CID tests. |
| `modules/mb-font/font/cff_admission.mbt` | Closed profile admission, exact charge, revision guard, atomic commit | ✓ VERIFIED | The typed Top result is consumed before keying; rejected semantics cannot reach keying or commit. |
| `modules/mb-font/font/cff_dict_wbtest.mbt` | Direct zero/non-zero, malformed, duplicate, and precedence matrix | ✓ VERIFIED | Focused test passes 1/1 with exact category/context assertions. |
| `modules/mb-font/font/cff_admission_wbtest.mbt` | Real transaction and atomic rejection matrix | ✓ VERIFIED | Focused test passes 1/1 and checks all relevant budget dimensions. |
| `modules/mb-font/font/directory.mbt`, `limits.mbt`, `tables.mbt`, `font.mbt` | Profile authority, limits/ledger, and closed promotion | ✓ VERIFIED | Quick regression checks plus complete native suite show no regression. |
| Name/CID/hostile/collection/glyf test artifacts | CFF-02 and compatibility evidence | ✓ VERIFIED | All focused groups and full suite pass. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Top DICT bytes | `cff_reduce_top_dict_entry` | `cff_parse_dict_incremental` emits each complete entry before scanning the next token | ✓ WIRED | Establishes deterministic encounter order without a second parser or pre-scan. |
| PaintType/StrokeWidth reducer | `cff_decode_top_dict` | Dedicated escaped-operator branches | ✓ WIRED | `0x105`/`0x108` are absent from the generic accepted branch and reject non-zero semantics immediately. |
| `cff_decode_top_dict` | `admit_cff1_structure` | Top INDEX object decoding | ✓ WIRED | Capability/Data errors return before String/Global Subrs/keying, final guard, or budget commit. |
| `cff_admission.mbt` | `cff_keying.mbt` | `cff_resolve_keying` after typed Top success | ✓ WIRED | Supported zero/default semantics reach the existing name/CID transaction; rejected semantics do not. |
| standalone / collection wrappers | common admission transaction | `admit_cff1_structure_at_after_preflight` | ✓ WIRED | Root-relative collection and table-local CFF authority remain shared. |
| private admitted facts | `FontOutlineSource` | complete `AdmittedCff1` only | ✓ WIRED (private only) | No public CFF-backed Font/path route was introduced. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| PaintType/StrokeWidth typed profile matrix | `moon test modules/mb-font/font --target native --filter "CFF Top DICT closes PaintType and StrokeWidth profile"` | 1 passed | ✓ PASS |
| Atomic real admission rejection | `moon test modules/mb-font/font --target native --filter "CFF1 PaintType and StrokeWidth profile rejects atomically before publication"` | 1 passed | ✓ PASS |
| Existing Type 2 structural tracer | `moon test modules/mb-font/font --target native --filter "CFF1 tracer admits default and explicit Type 2 then resolves GID zero"` | 1 passed | ✓ PASS |
| Name-keyed CFF-02 group | `moon test modules/mb-font/font --target native --filter "*CFF name keying*"` | 5 passed | ✓ PASS |
| CID-keyed CFF-02 group | `moon test modules/mb-font/font --target native --filter "*CFF CID*"` | 7 passed | ✓ PASS |
| Standalone public glyf fingerprint | focused Phase 104 filter | 1 passed | ✓ PASS |
| Selected-collection public glyf fingerprint | focused Phase 104 filter | 1 passed | ✓ PASS |
| Prior lookup/format-4/allocation gap regressions | three focused filters | 1 passed each | ✓ PASS |
| Complete native regression | `moon test --target native` | 1,204 passed, 0 failed | ✓ PASS |
| Four-target static compatibility | `moon check --target all` | Four targets completed successfully | ✓ PASS |

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| CFF-01 | 104-01, 104-03, 104-04 | Exact bounded static CFF1 structural admission and stable unsupported-profile rejection | ✓ SATISFIED | All original structural/profile checks pass; Plan 104-04 closes PaintType/StrokeWidth and proves category/context/precedence/atomicity behavior. |
| CFF-02 | 104-01, 104-02, 104-03 | Exactly one checked name/CID CharString execution environment per GID with complete-set validation | ✓ SATISFIED | Production data flow remains wired; 5 name, 7 CID, hostile, collection, and full-suite regressions pass. |

No Phase 104 requirements are orphaned. `REQUIREMENTS.md` still contains pre-reverification checkbox/traceability wording for CFF-02 and “Gaps Found”; that is workflow metadata to be synchronized by the orchestrator after this canonical verification result, not contrary implementation evidence.

## Review Disposition

The latest `104-REVIEW.md` is clean (0 critical, 0 warning, 0 info). Its claims were independently checked against the implementation and focused tests. The four earlier iteration-3 lookup/search/allocation findings also remain closed through their passing focused regressions.

## Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, empty implementation, second DICT parser, public CFF API, or accepted-and-discarded PaintType/StrokeWidth branch was found in the Plan 104-04 change scope.

## Probe Execution

No phase probe scripts were declared or found; probe execution is not applicable.

## Human Verification Required

None. All phase outcomes are private, deterministic parser/data-model behavior with direct automated evidence.

## Gaps Summary

No gaps remain. The previous PaintType/StrokeWidth profile hole is closed at the typed Top DICT boundary, all eight must-haves are verified, CFF-01 and CFF-02 are satisfied, and no CFF-02 or public static-glyf regression was observed.

---

_Verified: 2026-07-28T13:36:02Z_
_Verifier: the agent (gsd-verifier)_
