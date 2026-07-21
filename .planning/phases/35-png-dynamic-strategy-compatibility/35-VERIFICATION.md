---
phase: 35-png-dynamic-strategy-compatibility
verified: 2026-07-21T20:33:51Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 35: Dynamic Strategy Compatibility Verification Report

**Phase Goal:** Library users can explicitly select a documented dynamic compression route without changing the frozen Stored defaults or established FixedOrStored byte sequences.
**Verified:** 2026-07-21T20:33:51Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can pass `PngCompressionStrategy::DynamicOrFixedOrStored` to the documented eager and caller-buffered PNG factories. | ✓ VERIFIED | The additive public enum case is declared in `png.mbt`; `PngEncoder::new_with_compression_strategy` retains the choice for `ImageEncoder::encode`, and `PngChunkEncoder::new_with_compression_strategy` passes it into `PngEncodeMachine`. Both named public-factory tests passed on js, wasm, wasm-gc, and native. |
| 2 | `PngEncoder::new()` and `PngChunkEncoder::new(...)` retain their independently frozen complete Stored RGB8 and straight-RGBA8 PNG bytes. | ✓ VERIFIED | Both legacy constructors still select `Stored` directly. The eager and hostile-capacity caller-buffered tests compare RGB8 and straight-RGBA8 output against independent complete stored-PNG literals; all four targets passed. |
| 3 | Explicit FixedOrStored eager and caller-buffered factories retain their frozen complete byte sequences, and only DynamicOrFixedOrStored is eligible to select a Dynamic DEFLATE representation. | ✓ VERIFIED | Tests compare FixedOrStored RGB8/RGBA8 output to immutable complete PNG literals and require final fixed-block bits on the repetitive fixture. `_png_encode_preflight` keeps FixedOrStored's original branch and maps the new case to it. A source scan found no `PngDeflatePlan::Dynamic` or `Dynamic(...)` emitter symbol, so no strategy can emit Dynamic in this phase. |
| 4 | Public strategy documentation states the strict-win policy and excludes adaptive filters, broader matching, and host-streaming expansion. | ✓ VERIFIED | `png.mbt` and `stream_encode.mbt` document strict complete-PNG wins over unchanged FixedOrStored, tie retention, and the stated exclusions. `policy/foundation.json` registers the exact additive enum case while retaining both configured factory signatures; `moon -C modules/mb-image info --target all --frozen` completed successfully. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public additive strategy and eager contract | ✓ VERIFIED | Substantive public enum/docs; configured factory stores the caller selection and legacy constructor is direct Stored. |
| `modules/mb-image/png/encode.mbt` | Exhaustive compatibility-preserving strategy admission | ✓ VERIFIED | `Stored` retains its own plan; FixedOrStored and DynamicOrFixedOrStored share the unchanged Fixed-or-Stored candidate path before the single limits/budget admission. |
| `modules/mb-image/png/stream_encode.mbt` | Caller-buffered strategy construction | ✓ VERIFIED | Configured factory passes strategy to the shared machine, whose constructor calls `_png_encode_preflight`; legacy constructor routes direct Stored. |
| `modules/mb-image/png/encode_test.mbt` | Eager frozen-vector coverage | ✓ VERIFIED | Complete Stored and FixedOrStored byte literals for RGB8/RGBA8 plus Dynamic equality and decode assertions; executed on all four targets. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered frozen-vector coverage | ✓ VERIFIED | Drains configured encoders under `[0, 1, 3, 2, 5]`, checks complete literals and fixed block bits; executed on all four targets. |
| `policy/foundation.json` | Exact semantic-interface registration | ✓ VERIFIED | PNG semantic interface contains only the additive `DynamicOrFixedOrStored` enum line change and retains target/factory declarations. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | PngEncoder stores the selected strategy; `ImageEncoder::encode` passes it to shared construction and `_png_encode_preflight`. | ✓ WIRED | `ImageEncoder::encode` calls `PngEncodeMachine::new_with_compression_strategy(source, _self.strategy, ...)`; the machine calls `_png_encode_preflight`. |
| `stream_encode.mbt` | `stream_encode_test.mbt` | Configured factory to shared machine and hostile-capacity drain. | ✓ WIRED | The configured factory calls `PngEncodeMachine::new_with_compression_strategy`; the named test calls it and drains only accepted lease prefixes through `png_chunk_test_drain_encoder`. |
| `png.mbt` | `policy/foundation.json` | Public enum/interface contract. | ✓ WIRED | The source enum and registered semantic interface both contain `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored`, with matching configured factory signatures. |

### Data-Flow Trace (Level 4)

Not applicable: these are encoder control-path artifacts, not dynamic-data rendering artifacts. The strategy value is nevertheless traced from both public factories through the shared machine to `_png_encode_preflight`, which selects the existing Stored or Fixed plan before output begins.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Named eager and chunk compatibility behavior exists and passes on js, wasm, wasm-gc, and native. | `moon -C modules/mb-image test png --target {js,wasm,wasm-gc,native} --frozen -f '*dynamic strategy*'` | 2/2 passed on each target; outlines contained both required named tests before execution. | ✓ PASS |
| PNG regressions across all declared targets. | `moon -C modules/mb-image test png --target all --frozen` | 116/116 passed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Public PNG interface compiles across all declared targets. | `moon -C modules/mb-image info --target all --frozen` | Exit 0 (warnings only; no errors). | ✓ PASS |
| No premature dynamic representation is emitted. | `rg 'PngDeflatePlan::Dynamic|Dynamic\\(' modules/mb-image/png --glob '*.mbt'` | No matches; the only plan variants are Stored and Fixed. | ✓ PASS |

### Probe Execution

**SKIPPED:** no phase-declared or conventional `probe-*.sh` scripts exist for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGD-01 | `35-01-PLAN.md` | Explicit DynamicOrFixedOrStored opt-in while legacy Stored and FixedOrStored bytes remain frozen; only new route may select Dynamic. | ✓ SATISFIED | All four roadmap truths above are directly covered by source routing, independent eager/chunk byte-vector tests, four-target selected evidence, and the all-target PNG suite. No Phase 35 requirement is orphaned. |

### Anti-Patterns Found

No phase-introduced `TBD`, `FIXME`, `XXX`, placeholder, empty handler, static empty-output, or console-only implementation was found in the six phase-modified artifacts. The compile command reports existing package warnings, but none are introduced by the Phase 35 diff or undermine this compatibility contract.

### Quality-Lane Note

`pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` was intentionally not run during this verification, so there is no objective quality-lane result to claim. This is recorded as an evidence omission, not a passing quality-lane assertion; it does not contradict the source-level contract or the completed four-target PNG test suite.

### Gaps Summary

No blocking gaps found. The additive route is implemented and exercised; legacy Stored and FixedOrStored output remains pinned by independent complete-byte vectors through eager and caller-buffered APIs. Dynamic emission is explicitly absent in this compatibility phase and is deferred to Phase 36 by the roadmap.

---

_Verified: 2026-07-21T20:33:51Z_
_Verifier: the agent (gsd-verifier)_
