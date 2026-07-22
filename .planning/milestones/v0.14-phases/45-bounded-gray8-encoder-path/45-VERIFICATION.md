---
phase: 45-bounded-gray8-encoder-path
verified: 2026-07-22T11:30:00Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 45: Bounded Gray8 Encoder Path Verification Report

**Phase Goal:** Gray8 eager and caller-buffered output uses the established bounded PNG pipeline before any byte or caller lease is exposed.
**Verified:** 2026-07-22T11:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A valid Gray8 image can use `None` or `Adaptive` filtering with `Stored`, `FixedOrStored`, or `DynamicOrFixedOrStored`, without image-sized staging. | ✓ VERIFIED | Public eager factories in `png.mbt` and chunk factories in `stream_encode.mbt` expose compression-only, filter-only, and combined variants, all binding Gray8 to non-interlaced output. Both enter `PngEncodeMachine::new_with_profile`; the sole one-channel change in `encode.mbt` admits `channels == 1`. The shared preflight selects Stored/Fixed/Dynamic with the existing strict comparisons. The new phase diff adds no output or raster buffer; the machine retains scalar cursors/plans, and the existing bounded matcher window is fixed-size. All factory combinations are covered by passing eager/chunk parity tests. |
| 2 | Gray8 capability, geometry, output, work, and budget failures expose neither eager bytes nor a usable chunk encoder lease. | ✓ VERIFIED | `_png_encode_preflight_with_interlace_profile` rejects Gray8 Adam7 before the common ledger; `_png_encode_preflight_with_filter_layout_idat_limit_profile` validates source, checked geometry, output, work, and then charges budget before a machine is returned. `PNG Gray8 strategy admission is atomic` exercises all 3 compression × 2 filter combinations against each of the five rejection classes, asserting writer position `0`, unchanged resource limits/budget, matching eager/chunk error, and an untouched sentinel lease. |
| 3 | Gray8 caller-buffered output reports accepted bytes only and keeps acknowledgement-safe, sticky replay behavior. | ✓ VERIFIED | `PngChunkEncoder::pull` writes a preview to the caller lease, then calls `machine.acknowledge`; only after success does it increment `written` and update `total_written`. `PngEncodeMachine::acknowledge` is the sole transition that advances cursors, CRC/Adler state, and `emitted`. The focused Gray8 fixed replay test mutates the source after an accepted prefix, then proves zero new bytes, unchanged cumulative total, same terminal error, and untouched later lease. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Explicit eager Gray8 compression-only, filter-only, and combined factories. | ✓ VERIFIED | `new_gray8_with_compression_strategy`, `new_gray8_with_filter_strategy`, and `new_gray8_with_strategies` delegate to one profile-preserving initializer with interlace fixed to `None`. |
| `modules/mb-image/png/stream_encode.mbt` | Matching caller-buffered Gray8 factory family wired to the common machine. | ✓ VERIFIED | The matching three chunk factories delegate to `new_gray8_with_strategies`, which calls `PngEncodeMachine::new_with_profile(... Gray8, strategy, filter, None, ...)`. |
| `modules/mb-image/png/encode.mbt` | One-channel filter/preflight admission, shared planning, and Gray8 Adam7 rejection. | ✓ VERIFIED | `_png_filter_candidate_byte` permits exactly 1/3/4 channels; the profile-aware preflight only rejects Gray8 when interlacing is not `None`, then enters the unchanged common layout/preflight ledger. |
| `modules/mb-image/png/encode_test.mbt` | Eager Gray8 strategy coverage. | ✓ VERIFIED | Tests cover Stored/Fixed/Dynamic, None/Adaptive, valid Gray8 framing, Fixed decode, and the explicit eager factory surface. |
| `modules/mb-image/png/stream_encode_test.mbt` | Chunk parity, atomic admission, progress, and replay regressions. | ✓ VERIFIED | Tests cover every public chunk factory shape, all selected strategy pairs, all five admission classes, ordinary-capacity parity, accepted-progress, and sticky replay. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Gray8 eager factory selection | `PngEncodeMachine::new_with_profile` → `_png_encode_preflight_with_interlace_profile` | `ImageEncoder::encode` carries the private Gray8 profile plus selected compression/filter strategies. | ✓ WIRED | `PngEncoder` stores the selected values; `encode` passes all of them to the profile-aware common machine constructor. |
| Gray8 chunk factory selection | Shared machine → `PngChunkEncoder::pull` acknowledgement | `new_gray8_with_strategies` constructs only after preflight; `pull` presents, writes, and acknowledges each byte. | ✓ WIRED | Construction returns `Active(machine)` only on successful preflight. Replay state changes in `acknowledge`, after caller lease acceptance. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode.mbt` / `stream_encode.mbt` | `facts.profile`, `facts.channels`, `facts.row_bytes`, selected `PngDeflatePlan` | `ImageView` → `_png_encode_source` → common preflight → `PngEncodeMachine` | Pixel rows are traversed directly for filtering/DEFLATE replay; Gray8 profile produces IHDR colour type 0. | ✓ FLOWING |
| `PngChunkEncoder::pull` | `written`, `total_written`, machine cursor/state | Caller `MutByteLease` after `present()` | A byte is accounted only after `destination.set` and `acknowledge` both succeed. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Native PNG regression suite, including new Gray8 strategy/admission/replay tests and legacy RGB/RGBA fixtures | `moon -C modules/mb-image test png --target native --frozen` | `Total tests: 179, passed: 179, failed: 0.` | ✓ PASS |
| Gray8 factory/parity coverage | Passing named tests: `PNG Gray8 eager strategy factories cover compression and filtering`; `PNG Gray8 chunk strategy factories match eager`. | All 3 compression × 2 filter combinations are exercised through public eager/chunk APIs. | ✓ PASS |
| Atomic admission and sticky replay | Passing named tests: `PNG Gray8 strategy admission is atomic`; `PNG Gray8 fixed replay mismatch is sticky`. | Covers capability/geometry/output/work/budget, accepted prefix accounting, sticky terminal error, and lease integrity. | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 45 declares no probe and no `scripts/**/probe-*.sh` probe exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYPNG-02 | `45-01-PLAN.md` | Gray8 uses bounded preflight, filtering, Stored/Fixed/Dynamic planning, output/work/budget admission before byte exposure. | ✓ SATISFIED | All three roadmap success criteria are verified above by shared-path source trace plus the independently run native suite. |

No orphaned Phase 45 requirements: `REQUIREMENTS.md` maps only `GRAYPNG-02` to this phase and the plan claims it.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No phase-added `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, full-image staging buffer, or unwired Gray8 factory. | ℹ️ None | No blocker or warning. |

### Deferred Items

Phase 46 is the correct owner only for the explicitly scheduled public-evidence expansion: generated Gray8 eager-decode fidelity, zero/one/ragged caller-capacity identity schedules, frozen RGB/RGBA compatibility evidence in that corpus, and independent js/wasm/wasm-gc/native runs. These are not used to defer any Phase 45 admission, strategy, boundedness, or replay obligation.

### Gaps Summary

None. The implementation—not the Phase 45 summary—provides one public eager/chunk Gray8 strategy family, a single preflight/planner/replay route, atomic admission before output access, and acknowledgement-safe caller-buffered progress. Gray8 Adam7 remains impossible through the public factory surface and is rejected by the private profile-aware preflight before the common ledger runs.

---

_Verified: 2026-07-22T11:30:00Z_
_Verifier: the agent (gsd-verifier)_
