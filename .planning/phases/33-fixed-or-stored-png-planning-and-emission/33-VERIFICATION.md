---
phase: 33-fixed-or-stored-png-planning-and-emission
verified: 2026-07-21T19:21:49Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 2/5
  gaps_closed:
    - "FixedOrStored admission atomicity and selected-work charging are exercised through both public factories."
    - "Fixed selected-work boundary, acknowledgement-only commit, and replay-work mismatch are behaviorally exercised."
    - "Configured FixedOrStored sticky completion and first-failure lease isolation are behaviorally exercised."
  gaps_remaining: []
  regressions: []
---

# Phase 33: Fixed-or-Stored PNG Planning and Emission Verification Report

**Phase Goal:** A library user selecting the optimized strategy receives deterministic fixed-Huffman-or-stored PNG output only after bounded exact admission, through both eager and caller-buffered encoder paths.

**Verified:** 2026-07-21T19:21:49Z  
**Status:** passed  
**Re-verification:** Yes — the prior `human_needed` evidence gaps were checked after Plan 33-02.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller selecting `FixedOrStored` is rejected for capability, geometry, output, work, or budget before an eager writer or chunk lease can observe PNG output. | ✓ VERIFIED | `_png_encode_preflight` completes source/checked geometry, selected plan, selected output/work limits, disposition, then its single `budget.charge` before either adapter constructs an output machine (`encode.mbt:311-410`). The public test invokes both factories for all five failing dimensions, checks writer position is zero, and compares all eight budget fields (`stream_encode_test.mbt:547-614`). The exact selected-work and one-less cases pass (`encode_test.mbt:314-346`; `encode_wbtest.mbt:196-224`). |
| 2 | An admitted compatible image receives a deterministic, bounded exact fixed-Huffman-or-Stored PNG with no dynamic-Huffman or adaptive-filter expansion. | ✓ VERIFIED | The A1 matcher examines only distances 1–4, uses strict longest-match replacement to retain the smaller-distance tie, and caps comparisons at 258 bytes (`encode.mbt:171-213`). Exact fixed totals are selected only when `fixed.total_length <= stored.total_length` (`encode.mbt:360-384`). The public fixed test verifies `BFINAL/BTYPE=011` and decodes the result (`encode_test.mbt:111-127`); the focused suite also includes fixed-code/length-258 arithmetic. |
| 3 | Optimized eager and caller-buffered output supports arbitrary valid capacities with exact progress, byte-identical results, and unchanged sticky completion/failure semantics on all four declared targets. | ✓ VERIFIED | Configured eager/chunk parity runs a 0/1/ragged capacity schedule for RGB8 and RGBA8 (`stream_encode_test.mbt:183-195`). The terminal test proves `Finished` replay and released-lease failure replay leave later `Z`-filled leases unchanged (`stream_encode_test.mbt:664-720`). The mutable public 5×1 RGB8 stimulus reaches the sticky `png-encode-fixed-replay-work` failure after 57 accepted bytes (`stream_encode_test.mbt:582-660`). |
| 4 | The A2 ledger includes planning plus selected replay work, checks it before output, and fails closed on replay drift. | ✓ VERIFIED | Fixed selected work is `total_length + matcher_work + matcher_work` and is charged only after all limits (`encode.mbt:377-409`). The white-box boundary test proves exact admission, one-less pre-output rejection, unchanged budget, and the expected scalar fixed plan (`encode_wbtest.mbt:196-224`). Replay mismatch is checked before EOB (`stream_encode.mbt:402-405`) and the exact mutable 5×1 test proves sticky failure with unchanged committed state (`stream_encode_wbtest.mbt:241-282`). |
| 5 | Legacy `PngEncoder::new()` and `PngChunkEncoder::new(...)` remain explicit Stored routes with their frozen stored-DEFLATE bytes. | ✓ VERIFIED | The constructors retain the explicit `Stored` route (`png.mbt:89-101`; `stream_encode.mbt:9-22`). Exact eager and chunk frozen-byte regression tests remain in the suite (`encode_test.mbt:143-156`; `stream_encode_test.mbt:198-213`). |

**Score:** 5/5 truths verified (0 present but behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Exact strategy-aware preflight and single post-plan budget charge | ✓ VERIFIED | Substantive selected plan, checked limit, and eager wiring; Plan 33-01 artifact probe passed. |
| `modules/mb-image/png/stream_encode.mbt` | Scalar fixed replay plus acknowledgement-only commits | ✓ VERIFIED | `present` retains only a preview; `acknowledge` commits fixed state/Adler/CRC and progress (`491-549`). |
| `modules/mb-image/png/encode_test.mbt` | Configured eager selection and exact selected-work public evidence | ✓ VERIFIED | Executed by the focused suite on all targets. |
| `modules/mb-image/png/encode_wbtest.mbt` | Fixed-plan and A2 boundary evidence | ✓ VERIFIED | Contains and executes the exact selected-work boundary test. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public atomicity, parity, progress, and sticky terminal evidence | ✓ VERIFIED | Contains and executes configured public-factory tests, including the mutable 5×1 stimulus. |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | Preview/acknowledgement and replay-state invariants | ✓ VERIFIED | Contains and executes failed-output and replay-mismatch state-transition tests. |
| `modules/mb-image/png/png.mbt` | Strategy declaration and legacy compatibility seam | ✓ VERIFIED | Public strategy is limited to `Stored` and `FixedOrStored`; no public expansion was introduced. |

Artifact probes reported 5/5 for Plan 33-01 and 4/4 for Plan 33-02. The test artifacts are wired into the PNG package: their outlined entries and executions below prove they are not orphaned.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode.mbt` | `stream_encode.mbt` | preflight plan → configured machine | ✓ WIRED | Both adapters construct `PngEncodeMachine::new_with_compression_strategy` only after `_png_encode_preflight` returns a charged plan. |
| `stream_encode.mbt` | writer / caller lease | `present` → accepted byte → `acknowledge` | ✓ WIRED | Eager acknowledges only after `Writer.write` returns `Progress(1)`; chunk output calls `lease.set` before acknowledgement. |
| configured public tests | public configured factories | `FixedOrStored` factories and `pull` | ✓ WIRED | Public tests instantiate both configured factories and execute the actual eager/chunk paths. |
| fail-closed outline | focused wildcard test execution | names → `-f '*fixed-or-stored*'` | ✓ WIRED | The per-target guard found every required test name before each filtered run; this manual execution supersedes the plan-probe tool's false negative caused by its non-file `from` label. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode.mbt` | selected `PngDeflatePlan` and selected work | `ImageView` filter-None scanline reads → exact fixed/stored comparison | Image-derived scanlines, checked facts, no static fallback | ✓ FLOWING |
| `stream_encode.mbt` | preview byte / fixed replay state | selected plan + replayed `ImageView` reads → writer or lease | The public mutable 5×1 image changes after preflight and deterministically drives the replay-error branch | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Fail-closed focused optimized evidence | Per target: outline requires the seven exact Plan 33-02 names, rejects a no-entry warning, then runs `moon -C modules/mb-image test png --target <target> --frozen -f '*fixed-or-stored*'` | Outline listed all seven required names and the filtered run executed 11 tests: 11 passed / 0 failed on js, wasm, wasm-gc, and native. | ✓ PASS |
| Complete PNG regression | `moon -C modules/mb-image test png --target all --frozen` | 113 passed / 0 failed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Former literal focused filter | `-f 'PNG fixed-or-stored'` | Not accepted as evidence: it is a literal glob mismatch that can return a successful zero-test run. | ✓ REJECTED AS FALSE GREEN |

The scoped quality lane was not re-run by this verifier; Plan 33-02's summary says it passed, but that narration was not used as verdict evidence.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGC-02 | `33-01-PLAN.md`, `33-02-PLAN.md` | Exact optimized admission before any byte | ✓ SATISFIED | Shared preflight orders admission/one charge before construction; public eager/chunk rejection tests and A2 exact/one-less tests passed on all targets. |
| PNGC-03 | `33-01-PLAN.md`, `33-02-PLAN.md` | Exact progress, eager/chunk parity, sticky terminals on js/wasm/wasm-gc/native | ✓ SATISFIED | Hostile-capacity parity, public sticky-terminal/replay-error tests, and the full 113-test four-target suite passed. |

No orphaned Phase 33 requirements were found. PNGC-04 compression-corpus and benchmark evidence remains Phase 34 scope and is not needed for this verdict.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | 82-84 | Generic `PngEncoder` doc still describes a stored-DEFLATE representation even though configured construction can select fixed output. | ⚠️ Warning | Documentation precision issue only; the strategy-specific docs and actual constructors are correct. |

No `TBD`, `FIXME`, or `XXX` markers were found in the seven Phase-33 source/test files. Source inspection found no dynamic-Huffman, adaptive-filter, dictionary, FFI, host-adapter, output-sized staging, token-list, or retained-lease implementation. The restricted strategy documentation and scalar-state implementation support that absence.

### Gaps Summary

None. The three former behavior-unverified truths now have direct public and white-box execution evidence on every declared target. Phase 33 achieves its goal.

---

_Verified: 2026-07-21T19:21:49Z_  
_Verifier: the agent (gsd-verifier)_
