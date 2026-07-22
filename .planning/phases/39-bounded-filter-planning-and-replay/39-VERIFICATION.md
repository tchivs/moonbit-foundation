---
phase: 39-bounded-filter-planning-and-replay
verified: 2026-07-22T05:00:05Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Adaptive Stored, Fixed, and Dynamic planning/replay now use the bounded owned cursor rather than the stateless arbitrary selector."
    - "Dynamic candidate-decline outcomes now retain executed frequency/bit traversal facts and preflight charges them before keeping the unchanged Fixed-or-Stored selection."
  gaps_remaining: []
  regressions: []
---

# Phase 39: Bounded Filter Planning and Replay Verification Report

**Phase Goal:** Opted-in compatible images use deterministic, bounded standard PNG row filtering before the existing compression planners while retaining atomic eager and caller-buffered behavior.
**Verified:** 2026-07-22T05:00:05Z
**Status:** passed
**Re-verification:** Yes — after Plan 07 closes the Dynamic-decline accounting gap.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Compatible RGB8 and straight-RGBA8 Adaptive rows deterministically select from PNG method-0 None, Sub, Up, Average, and Paeth using one stable winner rule. | ✓ VERIFIED | The Phase 39 arithmetic implementation preserves the fixed candidate order, signed-absolute scoring, and strict-lower replacement. The recorded four-target `*filter arithmetic*` matrix covers RGB8/RGBA8 predictor, score, and earliest-tie vectors. |
| 2 | Every Adaptive Stored, FixedOrStored, and DynamicOrFixedOrStored planning/replay byte uses a bounded forward cursor and does not use the stateless random selector. | ✓ VERIFIED | Current Phase 39 implementation (`eb6e87c`) provides `PngFilteredMatchCursor` with an owned `PngFilteredCursor`, logical producer/consumer positions, retained bounds, and a fixed 262-byte window. Stored, Fixed, and Dynamic planner/emitter paths instantiate that cursor; `_png_filtered_scanline_byte` is no longer an Adaptive planning/replay supplier. |
| 3 | Preflight charges facts from every real Stored, Fixed, Dynamic-frequency, Dynamic-bit-count, and selected-replay traversal before eager output or a caller lease exists. | ✓ VERIFIED | Plan 07 (`e918fe7`) changes the Dynamic planning result so every `Ok(None)` decline carries the frequency facts already executed and, when reached, bit-count facts too. Preflight adds those carried facts before retaining the prior Fixed-or-Stored winner; it does not change the winner/tie decision. The new decline-path exact/one-less work and budget evidence is recorded in the Plan 07 four-target matrix. |
| 4 | Fixed/Dynamic preview state owns a deep successor window and advances only when acknowledgement accepts its byte. | ✓ VERIFIED | `PngFilteredMatchCursor::ensure` deep-copies its fixed window for a successor; Fixed/Dynamic retain that successor only in `pending_*`, while `acknowledge` is the commit point. Recorded route-specific mutation tests verify valid accepted prefixes, terminal zero-write/unchanged leases, BTYPE, error context, and sticky repeats. |
| 5 | Existing filter-None bytes, public factories, Fixed-over-Stored ties, and Dynamic strict complete-PNG wins are preserved. | ✓ VERIFIED | Legacy None continues through its old provider; the current selection comparisons remain Fixed `<=` Stored and Dynamic `<` baseline. Public combined factories remain registered in `policy/foundation.json`; frozen-vector and public selection tests are included in the recorded four-target matrix. |
| 6 | Capability, geometry, output, work, and budget rejection stays atomic before eager output or a caller-buffered lease becomes visible. | ✓ VERIFIED | Both public adapters construct the shared machine only after filter-aware preflight. Recorded adaptive combined, Fixed, Dynamic, and Plan 07 decline-path exact/one-less admission tests prove failure before output/lease visibility and unchanged budget state. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Method-0 filtering, bounded match-cursor planning, and exact strategy-aware ledger | ✓ VERIFIED | The current Dynamic result/outcome retains real traversal facts on success and decline; preflight adds them before a single pre-output charge. |
| `modules/mb-image/png/stream_encode.mbt` | Acknowledgement-safe bounded Stored/Fixed/Dynamic replay | ✓ VERIFIED | All Adaptive emitters own their cursor state; pending successors commit only on acknowledgement. |
| `modules/mb-image/png/encode_wbtest.mbt` | Candidate/tie, normal-route, and Dynamic-decline ledger admission checks | ✓ VERIFIED | Includes exact/one-less accounting for real traversal facts, including the formerly omitted decline outcome. |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | Cursor/replay and acknowledgement-boundary checks | ✓ VERIFIED | Covers one-selection-per-row traversal facts and preview/acknowledgement stability. |
| `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` | Public eager/chunk route, atomicity, selection, and sticky mutation checks | ✓ VERIFIED | Recorded targeted selectors verify RGB8/RGBA8 public behavior, route BTYPE/context, prefix/zero-write sticky semantics, and legacy compatibility. |
| `modules/mb-image/png/png.mbt` and `policy/foundation.json` | Documented additive public factories | ✓ VERIFIED | Eager/chunk `new_with_strategies` declarations agree with policy. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode.mbt` | `stream_encode.mbt` | real candidate facts → preflight ledger → equivalent selected replay cursor | ✓ WIRED | Stored/Fixed/Dynamic walks provide facts; Dynamic success and decline outcomes both return facts for the single checked pre-output ledger. |
| `stream_encode.mbt` | `encode.mbt` | bounded producer/ring → Fixed/Dynamic matcher and replay | ✓ WIRED | Adaptive planner and emitter use the retained-window cursor; None remains on the legacy provider. |
| `png.mbt` / `stream_encode.mbt` | shared machine and policy | both strategies preserved through public eager/chunk factories | ✓ WIRED | Factories delegate unchanged strategies to the same atomic machine and match semantic-interface declarations. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| `PngFilteredMatchCursor` | selected filter tag/residual bytes | source `ImageView` → row winner → fixed retained window | Yes | ✓ FLOWING |
| Preflight ledger | planning/replay traversal facts | actual Stored/Fixed/Dynamic cursors, including Dynamic decline outcomes | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Evidence | Result | Status |
| --- | --- | --- | --- |
| Targeted Adaptive cursor/ledger, eager/chunk, atomicity, public mutation, selection, and frozen-None matrix | Recorded Phase 39 isolated selectors on JS, Wasm, Wasm-GC, and Native | Passed; temporary target roots removed | ✓ PASS |
| Arithmetic/tie and strict Dynamic preflight | Recorded isolated four-target selectors | Passed; temporary target roots removed | ✓ PASS |
| Dynamic-decline facts and exact/one-less admission | Plan 07 recorded targeted four-target matrix | Passed | ✓ PASS |
| PNG package portability compilation | Recorded `moon -C modules/mb-image check png --target all --target-dir <temporary> --frozen` | Passed; temporary root removed | ✓ PASS |

No broad/stalled PNG suite or quality lane is treated as passing evidence.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGF-02 | 39-01, 39-03–07 | Deterministic bounded method-0 candidates and stable winner | ✓ SATISFIED | Fixed candidate semantics, one-row cursor resolution, documented/public factories, and four-target arithmetic evidence. |
| PNGF-03 | 39-02–07 | Before-planner integration without image-sized staging and with atomic resource behavior | ✓ SATISFIED | Real bounded traversal facts now flow through both Dynamic success and decline paths into preflight before the sole budget charge; replay retains only bounded state. |

No Phase 39 requirement is orphaned from plan frontmatter. Phase 40 remains downstream interoperability evidence, not a dependency for satisfying PNGF-02/PNGF-03.

## Anti-Patterns Found

None blocking. The previous Dynamic-decline undercharge was removed by Plan 07. The fixed cursor window, bounded RFC alphabets, and scalar replay state show no image-sized filter table, selected-row cache, token stream, filtered-image buffer, or output staging. No unresolved `TBD`, `FIXME`, or `XXX` marker is recorded for Phase 39-owned code/policy files.

## Gaps Summary

None. The Phase 39 goal is achieved: Adaptive selection is deterministic and bounded, feeds all three compression routes through an owned replay cursor, and now admits every real planning/replay traversal—including Dynamic candidates that decline—before any eager output or caller lease is exposed.

---

_Verified: 2026-07-22T05:00:05Z_
_Verifier: the agent (gsd-verifier)_
