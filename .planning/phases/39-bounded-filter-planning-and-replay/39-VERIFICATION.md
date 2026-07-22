---
phase: 39-bounded-filter-planning-and-replay
verified: 2026-07-22T03:02:38Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Adaptive scanlines are selected once per row, and the preflight work ledger exactly covers planning and acknowledgement-safe replay before output is exposed."
    status: failed
    reason: "The selected row filter is recomputed for every filtered byte read, but preflight charges only two five-candidate row traversals. Stored replay alone invokes the selector row_bytes + 1 times per row, so actual adaptive scoring is substantially greater than the admitted ledger; Fixed and Dynamic invoke it still more through their matcher walks."
    artifacts:
      - path: "modules/mb-image/png/encode.mbt"
        issue: "_png_filtered_scanline_byte calls _png_filter_image_row_winner on every byte; _png_encode_preflight_with_filter charges only 2 * height * (5 * row_bytes)."
      - path: "modules/mb-image/png/stream_encode.mbt"
        issue: "Stored, Fixed, and Dynamic replay repeatedly request filtered bytes without retaining a current-row winner or another bounded replay cache."
      - path: "modules/mb-image/png/encode_wbtest.mbt"
        issue: "The ledger test asserts the declared formula and admission boundary, but does not count selector/residual work during replay, so it cannot detect the undercharge."
    missing:
      - "A fixed-memory forward cursor that resolves each row winner once per planning/replay traversal and supplies its tag and residual bytes thereafter."
      - "A work ledger and regression test that account for the cursor's actual selector calls across Stored, FixedOrStored, and DynamicOrFixedOrStored replay."
---

# Phase 39: Bounded Filter Planning and Replay Verification Report

**Phase Goal:** Opted-in compatible images use deterministic, bounded standard PNG row filtering before the existing compression planners while retaining atomic eager and caller-buffered behavior.
**Verified:** 2026-07-22T03:02:38Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Compatible RGB8 and straight-RGBA8 Adaptive rows use method-0 None/Sub/Up/Average/Paeth with signed absolute residual scoring and an earlier-candidate tie-break. | ✓ VERIFIED | `encode.mbt` implements all five predictors, maps `0x80` to magnitude 128, and replaces the winner only on strict `<`; `encode_wbtest.mbt` contains RGB/RGBA edge, signed-score, and tie vectors. |
| 2 | Adaptive scanlines are selected once per row and preflight exactly admits all filtering work before output. | ✗ FAILED | `_png_filtered_scanline_byte` recomputes `_png_filter_image_row_winner` for every byte. The preflight ledger nevertheless charges only `2 * height * (5 * row_bytes)`. |
| 3 | Adaptive filtering combines with Stored, FixedOrStored, and DynamicOrFixedOrStored through eager and caller-buffered public factories. | ✓ VERIFIED | `PngEncoder::new_with_strategies` and `PngChunkEncoder::new_with_strategies` preserve both strategies; all paths enter `PngEncodeMachine::new_with_strategies`, which passes the filter strategy into preflight and replay. |
| 4 | Existing None/default and compression-only routes retain their explicit legacy behavior; filter-only Adaptive remains Stored plus Adaptive. | ✓ VERIFIED | `png.mbt` documents and constructs the legacy factories with `PngFilterStrategy::None`; filter-only construction fixes compression to Stored. Public frozen-vector tests cover both adapters. |
| 5 | Capability, geometry, output, work, and budget rejection occurs before eager output or a caller lease is exposed. | ✓ VERIFIED | Both adapters construct the machine only after `_png_encode_preflight_with_filter` succeeds. `PNG adaptive combined admission is atomic` exercises every stated rejection class for all three combined strategies and asserts zero writer/lease visibility and unchanged budget. |
| 6 | The adaptive route is publicly documented and represented by the PNG semantic-interface policy. | ✓ VERIFIED | The two combined factory signatures and the documented candidate/tie rule are in `png.mbt`/`stream_encode.mbt`; `policy/foundation.json` declares both public signatures. Artifact and key-link verification reports all 11 planned artifacts and all 6 declared links present and wired. |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Filter arithmetic and filter-aware preflight | ✗ FAILED CONTRACT | Substantive and wired, but its byte supplier repeats row selection and undercharges real filtering work. |
| `modules/mb-image/png/stream_encode.mbt` | Bounded adaptive replay and public chunk factory | ✗ FAILED CONTRACT | Substantive and wired for all three plans, but holds no current-row selection state while replay calls the supplier per byte. |
| `modules/mb-image/png/png.mbt` | Documented eager combined factory | ✓ VERIFIED | Additive public API documents candidate order, signed score, strict winner, and legacy routes. |
| `modules/mb-image/png/encode_wbtest.mbt` | Formula and ledger tests | ⚠️ INSUFFICIENT | Formula/tie tests are substantive; the ledger test verifies only its own stated constant. |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | Cursor/replay tests | ⚠️ INSUFFICIENT | Confirms byte identity and matcher/fingerprint facts, not number of adaptive scoring traversals. |
| `modules/mb-image/png/encode_test.mbt` | Public eager routes | ✓ VERIFIED | Iterates three compression strategies and RGB/RGBA inputs, then decodes to source. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public chunk routes and atomic failures | ✓ VERIFIED | Checks eager/chunk equality, hostile capacities, decode fidelity, and rejected construction. |
| `policy/foundation.json` | Semantic-interface declarations | ✓ VERIFIED | Contains both `new_with_strategies` public signatures. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode_wbtest.mbt` | `encode.mbt` | Internal helper calls | ✓ WIRED | Formula, score, and stable-winner helpers are called directly. |
| `encode.mbt` | `stream_encode.mbt` | Filter-aware preflight/replay contract | ⚠️ WIRED BUT INCORRECT | Both sides call the same supplier, but the supplier recomputes the winner on each byte. |
| `stream_encode.mbt` | `encode.mbt` | Fixed/Dynamic matcher and fingerprint replay | ✓ WIRED | Both planners and emitters call `_png_filtered_match_at` / `_png_filtered_scanline_byte`. |
| `png.mbt` | `stream_encode.mbt` | Combined eager/chunk factories | ✓ WIRED | Factory values flow into the shared machine unchanged. |
| `png.mbt` | `policy/foundation.json` | Public interface | ✓ WIRED | Policy signatures match the exposed factories. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Adaptive supplier | `winner`, residual byte | `ImageView.get_byte` through raw/left/up/upper-left accessors | Yes — source pixels feed planner and replay | ⚠️ FLOWING, BUT RECOMPUTED |
| Preflight | `adaptive_filter_work` | `height`, `row_bytes`, filter strategy | No exact correspondence to actual cursor/supplier traversals | ✗ UNDERCOUNTED |

## Behavioral Spot-Checks

| Behavior | Command / evidence | Result | Status |
| --- | --- | --- | --- |
| Method-0 arithmetic across portable targets | Focused `*filter arithmetic*` suite recorded for js/wasm/wasm-gc/native | 4/4 targeted suites reported passed; test bodies independently mapped to the formulas | ✓ PASS (scoped evidence) |
| Public eager combined routes | Focused named test across portable targets | Reported passed; test loops Stored, FixedOrStored, DynamicOrFixedOrStored and RGB/RGBA decode fidelity | ✓ PASS (scoped evidence) |
| Public chunk and atomic combined routes | Focused named tests across portable targets | Reported passed; test bodies verify eager/chunk identity and all five pre-output rejection classes | ✓ PASS (scoped evidence) |
| Exact adaptive work admission | Static trace from `_png_filtered_scanline_byte` through Stored/Fixed/Dynamic consumption | Row winner is recomputed per byte while the ledger charges two row traversals | ✗ FAIL |

The verifier also attempted a fresh isolated four-target focused Moon command. It compiled target artifacts but produced no completed test result within the 64-second execution ceiling; the isolated directory was removed. That timeout is **not** counted as a passing result. The documented broad PNG/quality-lane delay is likewise neither accepted as a pass nor used for this verdict. It is not the blocker: the static work-ledger contradiction above is independently observable and decisive.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGF-02 | 39-01, 39-02, 39-03 | Deterministic bounded method-0 candidates and stable winner | ✓ SATISFIED | Exact helpers and vectors establish candidate semantics and strict earlier tie-break; public factories document them. |
| PNGF-03 | 39-02, 39-03 | Integrate before all compression planners without image-sized staging while retaining atomic resource behavior | ✗ BLOCKED | Planner/replay integration and no image-sized buffer are present, but the claimed work bound is not actual: repeated row scoring can exceed the pre-output work admission. |

No requirements mapped to Phase 39 are orphaned from plan frontmatter. Phase 40 concerns downstream portable evidence, not remediation of the Phase 39 work-accounting implementation, so this gap is not deferred.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | 421-440 | Per-byte call to full row-winner scorer | 🛑 Blocker | Violates the once-per-row bounded-cursor contract and invalidates exact preflight work admission. |
| `modules/mb-image/png/encode_wbtest.mbt` | 154-197 | Test asserts formula, not runtime scorer count | ⚠️ Warning | A passing targeted test masks the undercharged replay work. |
| `modules/mb-image/png/png.mbt` | 74 | Stale wording says compression phase excludes adaptive filtering | ℹ️ Info | The nearby combined-factory documentation is correct; clarify this wording during gap closure. |

No untracked Phase 39 source/policy file contains an unreferenced `TBD`, `FIXME`, or `XXX` debt marker. The unrelated dirty QOI files were preserved and excluded from this verification.

## Gaps Summary

Phase 39 contains real filter arithmetic, public composition, and atomic construction wiring, but it misses the central bounded-replay contract. A 6-byte row illustrates the mismatch: Stored replay asks for 7 filtered bytes; each request rescans five candidates across all 6 bytes (210 scorer residual operations for that row), while the entire preflight ledger credits only 60 filtering units for planning plus replay. Fixed and Dynamic make additional supplier calls through matcher comparisons. Therefore a work/budget that admission accepts can be insufficient for the actual encoder computation, defeating PNGF-03's bounded pre-output resource guarantee.

The repair must introduce a bounded forward cursor/current-row state (not an image-sized winner table), route both planning and acknowledgement-safe replay through it, and make the ledger test count the actual fixed cursor traversals.

---

_Verified: 2026-07-22T03:02:38Z_
_Verifier: the agent (gsd-verifier)_
