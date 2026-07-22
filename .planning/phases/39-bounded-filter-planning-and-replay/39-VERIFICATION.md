---
phase: 39-bounded-filter-planning-and-replay
verified: 2026-07-22T05:00:05Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Adaptive planning and replay no longer use the stateless per-byte row selector on Stored, FixedOrStored, or DynamicOrFixedOrStored routes."
  gaps_remaining:
    - "Dynamic candidate walks that decline after executing work do not return their traversal facts, so preflight omits their adaptive work."
  regressions: []
gaps:
  - truth: "Adaptive preflight charges the checked sum of facts returned by every Stored, Fixed, Dynamic-frequency, Dynamic-bit-count, and selected-replay walk actually executed before output or a caller lease exists."
    status: failed
    reason: "_png_dynamic_plan executes _png_dynamic_frequencies before any of its three early Ok(None) exits, but returns no frequency facts. _png_encode_preflight_with_filter adds Dynamic facts only for Ok(Some(dynamic)), so a declined Dynamic candidate is uncharged even though its bounded Adaptive traversal ran. The later IDAT-length decline similarly drops both frequency and bit-count facts."
    artifacts:
      - path: "modules/mb-image/png/encode.mbt"
        issue: "Lines 958-984 and 1018 return Ok(None) after cursor work; lines 1223-1236 discard those unreturned facts in the Ok(None) branch."
      - path: "modules/mb-image/png/encode_wbtest.mbt"
        issue: "Current ledger vectors cover a successful Dynamic candidate; they do not force a Dynamic decline and prove its executed facts are still charged."
    missing:
      - "Return a Dynamic planning outcome that carries executed frequency/bit traversal facts on every decline path, sum those facts in preflight, and add exact/one-less work and budget coverage for a declined Dynamic candidate."
---

# Phase 39: Bounded Filter Planning and Replay Verification Report

**Phase Goal:** Opted-in compatible images use deterministic, bounded standard PNG row filtering before the existing compression planners while retaining atomic eager and caller-buffered behavior.
**Verified:** 2026-07-22T05:00:05Z
**Status:** gaps_found
**Re-verification:** Yes — after the prior stateless-replay gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Adaptive RGB8 and straight-RGBA8 rows choose from method-0 None, Sub, Up, Average, and Paeth deterministically with the documented stable tie rule. | ✓ VERIFIED | Current `encode.mbt` keeps the fixed candidate order and strict-lower replacement; `*filter arithmetic*` and `PNG dynamic preflight selects only strict complete-PNG wins` passed on JS, Wasm, Wasm-GC, and Native. |
| 2 | Stored, FixedOrStored, and DynamicOrFixedOrStored obtain real Adaptive planning and replay bytes from a bounded forward cursor, not the old stateless arbitrary selector. | ✓ VERIFIED | Current HEAD (`eb6e87c`, `175153c`) defines `PngFilteredMatchCursor` with producer/logical/retained positions and a 262-byte ring. `_png_fixed_plan`, `_png_dynamic_frequencies`, `_png_dynamic_plan`, Stored replay, Fixed replay, and Dynamic replay all create/use it. `_png_filtered_scanline_byte` remains only behind `PngEncodeMachine::scanline_byte`; actual Adaptive planning/replay routes use their owned cursor. |
| 3 | Preflight admits all adaptive selector/residual work actually performed by requested candidate and selected replay walks before output visibility. | ✗ FAILED | Dynamic planning can execute `_png_dynamic_frequencies` and then return `Ok(None)` when a Huffman builder declines, or execute both walks and return `Ok(None)` at the IDAT-length guard. The caller records facts only for `Ok(Some(dynamic))`; these real cursor passes are omitted from the ledger. |
| 4 | Fixed and Dynamic preview/replay state advances only on acknowledgement, with a deep-owned bounded cursor window. | ✓ VERIFIED | `PngFilteredMatchCursor::ensure` copies all 262 window slots before producer advancement; Fixed/Dynamic preview returns successor state into `pending_*`, and `acknowledge` alone installs it. The public Adaptive Fixed/Dynamic mutation tests pass, checking BTYPE (`03`/`05`), route-specific drift contexts, accepted prefix, terminal zero write, unchanged terminal lease, and sticky repeat. |
| 5 | Fixed wins Stored ties; Dynamic replaces the baseline only on a strict complete-PNG win; legacy None bytes and public factories remain intact. | ✓ VERIFIED | Current comparisons are `fixed.total_length <= stored.total_length` and `dynamic.total_length < winner_length`; policy records both combined factories. Frozen legacy and Adaptive selection selectors passed on all four targets. |
| 6 | Capability, geometry, output, work, and budget rejections remain atomic for eager and caller-buffered adapters. | ✓ VERIFIED | Both public factories enter `PngEncodeMachine::new_with_strategies`, which calls preflight before a machine/lease is exposed. The targeted `PNG adaptive combined admission is atomic`, Fixed admission, and Dynamic admission selectors passed on JS, Wasm, Wasm-GC, and Native. |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Bounded matching cursor and truthful traversal-derived admission ledger | ✗ FAILED CONTRACT | Cursor is substantive and wired; its Dynamic-decline result loses already-executed facts. |
| `modules/mb-image/png/stream_encode.mbt` | Acknowledgement-safe Stored/Fixed/Dynamic cursor replay | ✓ VERIFIED | All Adaptive emitter states own a `PngFilteredMatchCursor`; pending successor is committed only by `acknowledge`. |
| `modules/mb-image/png/encode_wbtest.mbt` | Candidate, tie, and adaptive-ledger checks | ⚠️ INCOMPLETE | Successful Dynamic, Fixed, and Stored facts are tested; the Dynamic-decline ledger branch is absent. |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | Private cursor/replay checks | ✓ VERIFIED | Includes Adaptive cursor and Fixed preview accounting coverage. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public adaptive routes, selection, mutation and atomicity | ✓ VERIFIED | Route-specific BTYPE/context/sticky tests are substantive and passed in the targeted matrix. |
| `modules/mb-image/png/png.mbt` and `policy/foundation.json` | Additive documented/public factories | ✓ VERIFIED | Factory signatures and policy declarations agree. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode.mbt` | `stream_encode.mbt` | Preflight plan facts → selected owned replay cursor | ⚠️ PARTIAL | Actual Stored/Fixed/Dynamic success paths are wired, but `Ok(None)` Dynamic outcomes cannot transport their executed facts into preflight. |
| `stream_encode.mbt` | `encode.mbt` | Stored/Fixed/Dynamic preview/emission → bounded producer/ring | ✓ WIRED | All Adaptive paths initialize and advance `PngFilteredMatchCursor`; legacy None retains its historical provider. |
| Public factories | shared machine | combined compression/filter strategies | ✓ WIRED | Eager and chunk factories pass both strategies unchanged into the one shared constructor. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| `PngFilteredMatchCursor` | selected tag/residual stream | `ImageView` raw bytes → `PngFilteredCursor` winner/residual producer → 262-slot retained window | Yes | ✓ FLOWING |
| Dynamic preflight ledger | `frequency_facts`, `bit_facts` | real Dynamic match cursors | Only `Some(dynamic)` returns them | ✗ DROPPED ON DECLINE |

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
| --- | --- | --- | --- |
| Targeted route, ledger, atomicity, mutation, selection and frozen-byte matrix | 14 declared focused selectors, each run independently on JS/Wasm/Wasm-GC/Native in fresh `phase39-verify-*` roots | All selectors passed; every root was removed | ✓ PASS |
| Arithmetic, stable selection and strict Dynamic preflight | `*filter arithmetic*` plus `PNG dynamic preflight selects only strict complete-PNG wins` on all four targets | Passed; roots removed | ✓ PASS |
| Package compilation | `moon -C modules/mb-image check png --target all --target-dir <fresh phase39 root> --frozen` | Passed; root removed | ✓ PASS |
| Dynamic decline work admission | Static control-flow trace of `_png_dynamic_plan` → preflight `Ok(None)` branch | Facts are absent after a real cursor walk | ✗ FAIL |

No broad/stalled PNG suite or quality lane was counted as passing evidence.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGF-02 | 39-01, 39-03, 39-04–06 | Deterministic, bounded standard candidate selection and stable winner | ✓ SATISFIED | Method-0 helpers, strict tie policy, bounded cursor, four-target arithmetic/route evidence. |
| PNGF-03 | 39-02–06 | Planner integration with no image staging and atomic pre-output resource semantics | ✗ BLOCKED | Cursor/ring/no-staging and normal-route atomicity work, but Dynamic candidate decline can perform uncharged Adaptive work. |

No Phase 39 requirement is orphaned from plan frontmatter. Phase 40 concerns downstream portable interoperability evidence; it does not explicitly schedule repair of the Dynamic-decline accounting defect, so this gap is not deferred.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | 958–984, 1018, 1223–1236 | Real cursor facts vanish through `Ok(None)` Dynamic planning outcomes | 🛑 Blocker | Invalidates the exact preflight work contract for declined Dynamic candidates. |
| `modules/mb-image/png/encode_wbtest.mbt` | 241–268 | Only successful Dynamic plan facts are asserted | ⚠️ Warning | Does not catch the omitted-decline branch. |

The phase-owned code/policy files have no unresolved `TBD`, `FIXME`, or `XXX` debt marker. No `phase39-*` temporary build root remained after verification.

## Gaps Summary

The previous blocker is genuinely closed: current planning and replay use the owned 262-byte cursor rather than repeatedly selecting a row through `_png_filtered_scanline_byte`. The new evidence also validates four-target happy paths, public BTYPE/context behavior, sticky zero-write failures, and package compilation.

However, the resource contract is still incomplete. `_png_dynamic_plan` first executes a bounded frequency cursor, then has three normal candidate-decline exits. Its `Option` result cannot carry `frequency_facts` or `bit_facts` back to preflight. `_png_encode_preflight_with_filter` therefore charges Dynamic facts only if the candidate survives as `Some(dynamic)`. A Dynamic-or-Fixed-or-Stored request may thus accept a work limit/budget that excludes a real Adaptive cursor pass performed before construction returns. This is an observable PNGF-03 failure, not a missing test alone.

---

_Verified: 2026-07-22T05:00:05Z_
_Verifier: the agent (gsd-verifier)_
