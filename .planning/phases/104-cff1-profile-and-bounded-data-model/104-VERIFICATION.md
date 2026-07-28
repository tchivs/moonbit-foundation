---
phase: 104-cff1-profile-and-bounded-data-model
verified: 2026-07-28T12:52:44Z
status: gaps_found
score: 7/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirements:
  - id: CFF-01
    status: blocked
    reason: "The bounded parser and profile gates exist, but Top DICT PaintType (12 5) is accepted and discarded, so admission is not closed over the exact supported outline semantics."
  - id: CFF-02
    status: satisfied
    reason: "Name-keyed and CID-keyed descriptors, complete-set validation, and atomic failure behavior are implemented and exercised by passing white-box tests."
gaps:
  - truth: "Only the exact supported static CFF1 profile is admitted; unsupported outline semantics are rejected before facts are published."
    status: failed
    reason: "cff_decode_top_dict accepts PaintType (escaped operator 12 5 / 0x105) in a generic one-operand branch, but CffTopDict retains no PaintType or StrokeWidth fact. A stroked PaintType 2 font can therefore be admitted as if it had the default filled PaintType 0 semantics."
    artifacts:
      - path: "modules/mb-font/font/cff_dict.mbt"
        issue: "Lines 34-47 define no PaintType/StrokeWidth field; lines 737-754 accept 0x105 and 0x108 by arity only and discard their values."
      - path: "modules/mb-font/font/cff_dict_wbtest.mbt"
        issue: "The unsupported-semantic regression at lines 196-207 covers only escaped operators 12 20 through 12 23, not PaintType 12 5 or StrokeWidth 12 8."
    missing:
      - "Define the supported PaintType contract, normally requiring the default/explicit value 0 for this fill-outline profile."
      - "Reject PaintType 2 and any unsupported value as a stable capability/profile outcome before descriptor construction, or retain and fully implement stroked-font semantics in a specifically planned phase."
      - "Add omitted/default, explicit 0, PaintType 2, invalid-value, duplicate, and PaintType/StrokeWidth interaction tests proving atomic no-publication/no-charge behavior."
---

# Phase 104: CFF1 Profile and Bounded Data Model Verification Report

**Phase Goal:** Maintainers can admit only the supported static CFF1 structure and resolve every GID to one checked CharString and execution environment.
**Verified:** 2026-07-28T12:52:44Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Bounded caller-owned `OTTO` bytes admit only the exact supported static CFF1 profile, with deterministic rejection of mixed, CFF2, variable, and other unsupported profiles. | ✗ FAILED | Mixed/CFF2/variable/cardinality gates are implemented in `cff_preclassify_static_profile` and tested, but `cff_decode_top_dict` accepts and discards `PaintType` 12 5. The admitted profile is therefore not closed over outline semantics. |
| 2 | Every admitted name-keyed GID resolves through checked predefined/custom charset and Encoding data to one bounded CharString and one private/local-Subrs/FontMatrix environment. | ✓ VERIFIED | `cff_resolve_name_keying` builds one descriptor per GID from the shared CharStrings INDEX and selected Top private environment. Predefined/custom charset, Encoding, supplements, SID faults, and atomic failures are exercised in `cff_name_keyed_fixture_wbtest.mbt`. |
| 3 | Every admitted CID-keyed GID resolves through checked ROS, CID charset, FDArray, FDSelect 0/3, every FD Private/local-Subrs environment, and retained matrices; invalid facts prevent publication. | ✓ VERIFIED | `cff_resolve_cid_keying` validates ROS, custom CID charset, every FDArray object (including unused FDs), FDSelect, and all descriptors before returning. Seven CID white-box cases cover formats 0/3, late/unused-FD faults, matrix facts, cardinality, and one-short boundaries. |
| 4 | Exact and one-short outcomes are reproducible for Header, INDEX/DICT, String, CharStrings, Private DICT, and global/local Subrs under explicit limits and budgets. | ✓ VERIFIED | `cff_structural_exact_and_one_short_cases`, direct INDEX/DICT tests, name/CID fixture tests, and exact/one-less resource tests pass. Named error stages and unchanged budgets are asserted. |
| 5 | Header, one reusable INDEX implementation, and separate typed Top/Font/Private DICT schemas use explicit CFF-table or Private-relative authority. | ✓ VERIFIED | Only one `cff_decode_index` and one `cff_parse_dict` definition exist. `CffTableOffset`, `CffPrivateOffset`, and `CffPrivateRange` preserve bases; admission converts them to checked table/private windows before retention. |
| 6 | Structural ceilings, cumulative work/allocation authority, error precedence, mutation guards, and one final commit bound the whole transaction. | ✓ VERIFIED | `CffStructuralLimits`, cumulative `CffAuthorityLedger`, final exact `cff_admission_charge`, revision guard, and one `commit_atomic` are wired. Focused lookup, format-4, allocation, and collection atomicity tests pass. |
| 7 | Standalone and selected collection admission use one CFF table-local transaction while collection records remain root-relative. | ✓ VERIFIED | Both wrappers call `admit_cff1_structure_at_after_preflight`; `parse_font_directory_at` reads collection table offsets from the root, then creates a single checked CFF `TableWindow`. The selected non-zero-directory/shared-table tracer passes. |
| 8 | Only complete admitted CFF facts cross the private closed outline-source invariant, public CFF font/path promotion remains absent, and static-glyf behavior stays compatible. | ✓ VERIFIED | `FontOutlineSource` is private and closed as `Glyf | Cff1(AdmittedCff1)`; public `Font::open` still constructs only `Glyf`. Complete/malformed/mixed private promotion and public standalone/collection glyf fingerprint tests pass. |

**Score:** 7/8 truths verified (0 present-but-behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/cff_index.mbt` | Shared bounded INDEX model and checked object windows | ✓ VERIFIED | 308 substantive lines; one decoder handles empty and `offSize` 1–4 forms, terminal extents, monotonic offsets, and bounded objects. |
| `modules/mb-font/font/cff_dict.mbt` | Separate typed Top, Font, and Private DICT schemas | ⚠️ PARTIAL | Numeric/arity/default/SID/base handling is substantive, but PaintType/StrokeWidth semantics are accepted and discarded. |
| `modules/mb-font/font/cff_keying.mbt` | Normalized name/CID per-GID descriptors and adapters | ✓ VERIFIED | 1,234 substantive lines; both adapters consume shared INDEX/typed DICT facts and fully resolve descriptors before return. |
| `modules/mb-font/font/cff_admission.mbt` | Closed profile admission, exact charge, revision guard, atomic commit | ✓ VERIFIED | 1,655 substantive lines; shared standalone/collection transaction is wired to directory, common tables, keying, limits, budget, and commit. |
| `modules/mb-font/font/directory.mbt` | Existing root-relative SFNT authority with opt-in static CFF1 parsing | ✓ VERIFIED | Canonical parser is reused through `allow_static_cff1`; public glyf parsing remains on the original closed path. |
| `modules/mb-font/font/limits.mbt` | Private derived CFF structural ceilings | ✓ VERIFIED | Ceilings derive from non-zero `FontLimits` and fixed CFF format maxima; no new public limits API is exposed. |
| `modules/mb-font/font/font.mbt` | Closed private outline-source promotion | ✓ VERIFIED | Private enum requires the complete `AdmittedCff1` aggregate; public construction remains `Glyf`. |
| CFF white-box fixture/test files | Exact, one-short, name, CID, hostile, authority, and atomicity evidence | ✓ VERIFIED | All declared files exist, contain non-trivial assertions, and execute in the 1,202-test native suite. |
| `collection_wbtest.mbt`, `font_wbtest.mbt` | Collection authority and private promotion evidence | ✓ VERIFIED | Focused named tests pass. |
| `collection_test.mbt`, `font_test.mbt` | Public static-glyf compatibility fingerprints | ✓ VERIFIED | Phase 104 public standalone and selected-collection fingerprint tests pass within the full suite. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `directory.mbt` | `cff_admission.mbt` | One checked `CFF ` table window | ✓ WIRED | Root-relative SFNT records become one table-local view; CFF internal offsets are applied only inside that view. |
| `cff_admission.mbt` | `cff_index.mbt` | `cff_decode_index` / `cff_index_object` | ✓ WIRED | Name, Top, String, Global Subrs, CharStrings, FDArray, and local Subrs all use the same decoder/model. |
| `cff_admission.mbt` | `cff_dict.mbt` | Typed Top/Font/Private reducers | ⚠️ PARTIAL | Wiring is real, but the Top schema is not closed over PaintType semantics. |
| `cff_admission.mbt` | `cff_keying.mbt` | `cff_resolve_keying` | ✓ WIRED | Complete name/CID descriptor arrays are constructed before charge/commit/publication. |
| `tables.mbt` / budget | `cff_admission.mbt` | cumulative preflight → final revision guard → one commit | ✓ WIRED | Lookup and common-table probes prove short authority stops traversal; failures leave the budget unchanged. |
| standalone / collection wrappers | common admission transaction | `admit_cff1_structure_at_after_preflight` | ✓ WIRED | Both routes converge on the same implementation with only root/checksum/charge-mode parameters differing. |
| `cff_admission.mbt` | `font.mbt` | complete `AdmittedCff1` aggregate | ✓ WIRED (private only) | Complete facts can form the private CFF outline source; no public open/path route consumes it in Phase 104. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `AdmittedCff1.glyphs` | Per-GID CharString/environment descriptors | Caller-owned `CFF ` table → checked INDEX/DICT/keying adapters | Yes; bounded `ByteView` objects and selected private facts | ✓ FLOWING |
| Name keying | SID/Encoding/code mappings | Predefined tables or checked custom charset/Encoding bytes plus String INDEX | Yes; full mappings feed descriptor/keying facts | ✓ FLOWING |
| CID keying | CID/FD selection and per-FD environments | ROS + CID charset + FDArray + FDSelect + Private/local Subrs | Yes; every FD and GID is resolved before return | ✓ FLOWING |
| Collection CFF | Selected-face root offsets | TTC root-relative table records → one table-local CFF view | Yes; non-zero-directory shared-CFF fixture retains actual facts | ✓ FLOWING |
| Top outline semantics | PaintType/StrokeWidth | Top DICT escaped operators 12 5/12 8 | No; values are accepted but not retained or rejected | ✗ DISCONNECTED |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Lookup authority precedes traversal | `moon test modules/mb-font/font --target native --filter "CFF keying lookup groups require work authority before traversal"` | 1 passed, 0 failed | ✓ PASS |
| format-4 search work is exact and one-short atomic | `moon test modules/mb-font/font --target native --filter "CFF format-4 common-table search work is exact and one-short atomic"` | 1 passed, 0 failed | ✓ PASS |
| Predefined/custom Encoding allocation exact/one-short | `moon test modules/mb-font/font --target native --filter "CFF allocation authority uses concrete predefined and custom Encoding maxima"` | 1 passed, 0 failed | ✓ PASS |
| Selected collection shares atomic transaction | `moon test modules/mb-font/font --target native --filter "selected collection CFF1 facts use one bounded atomic shared-table transaction"` | 1 passed, 0 failed | ✓ PASS |
| Closed private promotion | `moon test modules/mb-font/font --target native --filter "private outline source accepts complete CFF facts and no partial or mixed state"` | 1 passed, 0 failed | ✓ PASS |
| Complete native regression | `moon test --target native` | 1,202 passed, 0 failed | ✓ PASS |
| Four-target type/check compatibility | `moon check --target all` | Four targets finished successfully | ✓ PASS |

## Probe Execution

No probe scripts were declared in the plans/summaries and no conventional `scripts/**/tests/probe-*.sh` files were found. Step 7c was not applicable.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| CFF-01 | 104-01, 104-03 | Exact bounded static CFF1 structural admission and stable unsupported-profile rejection | ✗ BLOCKED | Structural parsing, limits, budgets, and stable profile gates work, but accepted-and-discarded PaintType means the admitted profile is not exact/closed. |
| CFF-02 | 104-01, 104-02, 104-03 | Exactly one checked name/CID CharString execution environment per GID with complete-set validation | ✓ SATISFIED | Production keying/data flow is wired and the complete name/CID/atomicity suite passes. |

No Phase 104 requirements are orphaned: ROADMAP/REQUIREMENTS map exactly CFF-01 and CFF-02, and both appear in plan frontmatter.

## Review-Fix Disposition

The four iteration-3 findings were independently rechecked rather than accepted from `104-REVIEW-FIX.md`:

| Finding | Independent Evidence | Status |
|---|---|---|
| CR-01 lookup work preceded authority | Incremental preflight exists at predefined Encoding, custom charset/supplement, ROS, and Top/Font SID groups; the production-boundary probe test passes. | ✓ FIXED |
| CR-02 format-4 search work omitted | `font_cmap_search_selector(facts.body_records)` is added to staged and returned common-table work; exact 1467 / one-short 1466 test passes. | ✓ FIXED |
| WR-01 tests lacked keying probes | Direct probes assert zero traversal at 404/405 StandardEncoding, 0/1 charset, 1/2 supplement, 1/2 ROS, and 1/2 retained SID-group boundaries. | ✓ FIXED |
| WR-02 predefined Encoding lacked one-short allocation | Predefined exact 2048 and rejected 2047 path asserts Resource/`allocation_size` and unchanged budget; focused test passes. | ✓ FIXED |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `cff_cid_fixture_wbtest.mbt`, `cff_name_keyed_fixture_wbtest.mbt` | fixture layout helpers | Variables named `placeholder_*` | ℹ️ Info | Fixed-width first-pass layout values used only to compute final offsets; they do not flow into admitted facts and are not stubs. |
| `cff_dict.mbt` | 737-754 | Accepted semantic operator discarded | 🛑 Blocker | PaintType/StrokeWidth can change outline semantics but are neither retained nor rejected. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the phase-modified files.

## Human Verification Required

None. This phase exposes private parser/data-model behavior with deterministic automated coverage; the remaining gap is observable directly in code and does not require human UAT.

## Deferred-Item Check

Phase 105 explicitly covers Type 2 execution and bounds; Phase 106 covers public CFF `Font`/cubic path integration; Phase 107 covers qualification. None explicitly defines or implements stroked `PaintType 2` semantics or moves the exact-profile rejection contract out of Phase 104. The gap is therefore not deferred.

## Gaps Summary

One root-cause gap blocks CFF-01 and the phase goal. The parser accepts Top DICT `PaintType` 12 5 (and accepts `StrokeWidth` 12 8 in the same generic branch), but the retained Top facts contain neither field. Under the CFF specification, PaintType defaults to 0 while PaintType 2 denotes a stroked outline and uses StrokeWidth; silently treating it as the supported filled profile loses semantic information. The exact profile must either reject the unsupported case before descriptor publication or explicitly retain and implement it. The current milestone roadmap contains no later phase that assumes ownership of stroked-font semantics.

Reference: [Adobe Technical Note #5176, Top DICT operator table](https://adobe-type-tools.github.io/font-tech-notes/pdfs/5176.CFF.pdf).

---

_Verified: 2026-07-28T12:52:44Z_
_Verifier: the agent (gsd-verifier)_
