---
phase: 86-ancillary-aware-preflight-and-shared-machine-integration
verified: 2026-07-24T09:10:03Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: none
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 86: Ancillary-Aware Preflight and Shared-Machine Integration Verification Report

**Phase Goal:** The selected indexed compression profile is fully preflighted with its actual palette/transparency framing and admitted once into the established acknowledged eager and caller-buffered machine.

**Verified:** 2026-07-24T09:10:03Z

**Status:** passed

**Re-verification:** No — initial verification; no prior Phase 86 VERIFICATION.md exists.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Each non-interlaced Type-3 depth has a Fixed winner and Stored fallback whose selected frame retains actual PLTE length and shortest canonical one-byte tRNS. | ✓ VERIFIED | `encode_wbtest.mbt:1391-1426` and `:1448-1468` exercise One/Two/Four/Eight × both corpus outcomes. The selected `PngEncodePreflight.frame` is checked against `source.palette_length()` and `trns_length == 1`; Fixed/Stored disposition is asserted for each case. |
| 2 | Exact selected output/work limits admit after preflight; one-less output/work rejects before observable output or lease and leaves the caller budget unchanged. | ✓ VERIFIED | Private selected-facts matrix at `encode_wbtest.mbt:1470-1528` proves exact and one-less work/output and complete budget snapshots for all four profiles. Public eager rejection/zero-writer checks are at `encode_test.mbt:1007-1067` and `:1072-1104`; public chunk constructors return `Err` with unchanged budgets and no active encoder at `stream_encode_test.mbt:4991-5059` and `:5063-5086`. |
| 3 | Eager and caller-buffered selectors use the admitted `PngEncodeMachine` and produce identical ordinary-drain bytes. | ✓ VERIFIED | Eager selectors call the shared constructor at `encode.mbt:2477-2480` and `:2570-2573`; chunk selectors do so at `stream_encode.mbt:43-47` and `:92-96`. The tracer compares eager/chunk bytes at `stream_encode_test.mbt:4977-4986`, and the all-low-bit matrix parity test is at `:5122-5144`; Indexed8 parity is covered by existing `:5090-5117`. |
| 4 | Palette-capacity and checked source-construction arithmetic failures are atomic and do not consume the supplied budget. | ✓ VERIFIED | Low-bit cap-plus-one preflight/eager/chunk checks retain full snapshots (`encode_wbtest.mbt:1530-1551`, `encode_test.mbt:1049-1067`, `stream_encode_test.mbt:5042-5059`). Checked `PngIndexedImage::new` overflow is asserted with an unchanged constructor budget at `encode_test.mbt:1073-1078`; constructor validation precedes allocation/charge in `png.mbt:246-300`. Indexed8 cap-plus-one is correctly unreachable because the public source constructor caps palettes at 256 entries (`png.mbt:273-275`). |

**Score:** 4/4 truths verified (0 present, 0 behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_wbtest.mbt` | Retained selected frame/work facts and all-depth atomic admission evidence. | ✓ VERIFIED | Substantive matrix and boundary tests at lines 1333-1555; native focused test passes. |
| `modules/mb-image/png/encode_test.mbt` | Public eager admission, zero-writer rejection, cap and arithmetic evidence. | ✓ VERIFIED | Additive tracer and atomic boundary tests at lines 992-1104; native focused test passes. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public chunk construction, eager parity, and no-active-encoder rejection evidence. | ✓ VERIFIED | Additive tracer/matrix tests at lines 4977-5144; native focused test passes. |
| `modules/mb-image/png/encode.mbt` | Selected ancillary-aware preflight and eager facade seam. | ✓ VERIFIED | `_png_encode_indexed_preflight_with_profile_and_strategy` computes checked geometry, PLTE/tRNS frame facts, selected plan/work, checks limits, then performs one `budget.charge` at lines 2226-2390. Both eager selectors call the shared machine. |
| `modules/mb-image/png/stream_encode.mbt` | Caller-buffered facade through the same acknowledged machine. | ✓ VERIFIED | Both indexed chunk constructors return `Err` before `Active` state on preflight failure and construct `Active(machine)` only on success at lines 36-47 and 84-96; the machine retains the preflight frame/plan at lines 1027-1077. |
| `modules/mb-image/png/png.mbt` | Checked indexed source construction before allocation charge. | ✓ VERIFIED | `PngIndexedImage::new` validates u32 dimensions, checked pixel arithmetic, palette shape/count, and indices before `OwnedBytes::new_with_allocator_and_charge` at lines 246-300. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `_png_encode_indexed_preflight_with_profile_and_strategy` | `PngEncodeMachine::new_with_indexed_profile_and_strategy` | Machine constructor invokes preflight and copies retained `frame`, `selected_work`, `plan`, and raster facts. | WIRED | `stream_encode.mbt:1036-1053`; no second planner or charge path is present. |
| `PngEncoder::encode_indexed8_with_compression_strategy` / `encode_indexed_with_compression_strategy` | Existing acknowledged machine | Direct constructor call before `present()`/writer progress. | WIRED | `encode.mbt:2477-2495` and `:2570-2588`; errors return before a writer byte. |
| `PngChunkEncoder::new_indexed8_with_compression_strategy` / `new_indexed_with_compression_strategy` | Existing acknowledged machine | Direct constructor call; `Active(machine)` only after `Ok`. | WIRED | `stream_encode.mbt:43-47` and `:92-96`; rejection cannot expose a caller encoder/lease. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Indexed preflight | `frame`, `selected_work`, `plan` | `PngIndexedImage` dimensions/indices/palette/alpha; `_png_frame_facts` and bounded Stored/Fixed producers. | Yes — selected frame includes actual palette and canonical tRNS lengths; work/output facts drive limit checks and the single charge. | FLOWING |
| `PngEncodeMachine` | Emitted Type-3 bytes | Retained preflight facts plus fresh indexed raw cursors for Stored/Fixed replay. | Yes — eager/chunk ordinary drains are byte-identical in focused parity tests. | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Selected-facts eager/chunk tracer | `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression admission tracer*"` | 3 passed, 0 failed | ✓ PASS |
| All-depth ancillary admission boundaries | `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression ancillary admission*"` | 3 passed, 0 failed | ✓ PASS |
| Existing indexed compression selection/parity baseline plus Phase 86 tests | `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression*"` | 9 passed, 0 failed | ✓ PASS |
| Full native PNG package gate | `moon -C modules/mb-image test png --target native --frozen` | 309 passed, 0 failed | ✓ PASS |

### Probe Execution

SKIPPED — Phase 86 declares no probe scripts and is not a migration/CLI phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| INDEXCOMP-03 | `86-01-PLAN.md` | Ancillary-aware selected-depth geometry/frame/output/work preflight; one post-check charge; exact-limit success and atomic one-less/output/cap/arithmetic rejection. | SATISFIED | All four truths above; focused filters and full native PNG suite pass. The roadmap maps no additional requirement to Phase 86. |

No Phase 86 requirement is orphaned from the plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, TODO/HACK/placeholder, empty implementation, or hardcoded-empty output pattern found in the three modified test artifacts. | INFO | No completion-debt blocker. |

### Scope-Fence Check

The Phase 86 diff changes only the three planned test artifacts plus planning reports. It adds no production encoder, Dynamic route, adaptive filter, Adam7 compression selection, staging, FFI, wrapper, copied tree, or release automation. Hostile lease schedules, sentinel-tail/replay lifecycle qualification, independent chunk-origin parsing/decoding, portability targets, and release work remain Phase 87 scope and are not claimed here.

### Human Verification Required

None. The behavior-dependent admission and atomicity invariants have named passing tests; no visual, external-service, or interactive behavior is part of this phase.

### Gaps Summary

None. The implementation and tests prove INDEXCOMP-03 at the selected non-interlaced admission boundary, with both public facades converging on the existing acknowledged machine. Phase 87 qualification is intentionally not included in this verdict.

---

_Verified: 2026-07-24T09:10:03Z_

_Verifier: the agent (gsd-verifier)_
