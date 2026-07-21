---
phase: 32-png-compression-strategy-and-compatibility
verified: 2026-07-21T17:50:37Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 32: PNG Compression Strategy and Compatibility Verification Report

**Phase Goal:** Library users can explicitly choose a documented PNG compression strategy without changing the byte-for-byte stored-DEFLATE behavior of existing eager or caller-buffered constructors.
**Verified:** 2026-07-21T17:50:37Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can request a documented opt-in strategy through an additive public contract rather than a changed default. | ✓ VERIFIED | `png.mbt:75-101` publishes `PngCompressionStrategy::{Stored, FixedOrStored}` with `derive(Eq)`, retains `PngEncoder::new()` as an explicit `Stored` construction, and adds `PngEncoder::new_with_compression_strategy`. `stream_encode.mbt:9-43` retains the legacy chunk constructor and adds the configured equivalent. Focused public test passed: `moon -C modules/mb-image test png --target native --frozen -f '*PNG compression strategy*` → 4/4. |
| 2 | Existing eager and caller-buffered constructors retain byte-for-byte stored-DEFLATE output for compatible RGB8 and straight-RGBA8 images. | ✓ VERIFIED | Legacy eager tests at `encode_test.mbt:121-134` compare each constructor output with complete fixed RGB8/RGBA8 PNG vectors; legacy chunk tests at `stream_encode_test.mbt:161-176` independently drain accepted `[0, written)` lease prefixes on an irregular schedule and compare complete fixed vectors. The all-target PNG lane passed (102/102 on js, wasm, wasm-gc, and native), exercising these runtime byte assertions. |
| 3 | Users can distinguish the supported future optimized strategy from the stored baseline without gaining dynamic Huffman, adaptive filtering, host streaming, or other excluded compression behavior. | ✓ VERIFIED | The public enum and both configured factories explicitly say that `FixedOrStored` currently emits `Stored`, has no optimization or size guarantee, receives behavior in Phase 33, and excludes dynamic Huffman/adaptive filters (`png.mbt:70-100`, `stream_encode.mbt:24-43`). The public `PngEncoder` documentation retains the no-host-adapters boundary (`png.mbt:81-82`). Exact generated-interface policy verification establishes that the only added public surface is the enum plus the two configured factories; no host-streaming API was added. Phase commit diff contains no fixed-Huffman planner/emitter, LZ77/dictionary, adaptive-filter, corpus, size-win, or never-larger implementation. |
| 4 | The generated public PNG interface exactly matches registered policy while source inventory, imports, targets, and compatibility boundaries remain unchanged. | ✓ VERIFIED | `Invoke-MoonQuality.ps1 -Lane Png` passed its PNG foundation/interface policy and scoped fail-closed negative fixtures. Its `Assert-GeneratedInterface` logic line-compares generated `pkg.generated.mbti` against `foundation.json`; the lane also validates package inventory and runs all four targets. Policy diff changes only `semantic_interface`; PNG `production_sources`, `allowed_imports`, and `supported_targets` are unchanged, and `policy/compatibility.json` is not in the Phase 32 commit set. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public strategy and configured eager factory | ✓ VERIFIED | Exists and is substantive. Enum, documentation, explicit legacy `Stored`, and configured constructor are public; eager `ImageEncoder::encode` consumes the retained strategy. |
| `modules/mb-image/png/stream_encode.mbt` | Configured chunk factory and strategy-aware private machine | ✓ VERIFIED | Exists and is substantive. Legacy constructor calls the private `Stored` wrapper; configured factory passes its strategy into the same preflight/machine path. Both enum cases deliberately select the existing stored emitter. |
| `modules/mb-image/png/encode_test.mbt` | Public eager construction and legacy byte regression | ✓ VERIFIED | Public configured factory is exercised for both cases, then decoded; separate legacy RGB8/RGBA8 complete-byte vectors are asserted. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered construction and independent legacy byte regression | ✓ VERIFIED | Drain helper appends only acknowledged lease prefixes; separate legacy RGB8/RGBA8 full vectors are asserted under `[1,3,2,5]`. |
| `policy/foundation.json` | Exact normalized enum/factory registration | ✓ VERIFIED | Registers exactly the public enum, its two cases, and both configured signatures. The quality lane exact-compared it with generated interface output. |

`verify.artifacts` independently reported 5/5 plan artifacts substantive and present. These artifacts are encoder/policy/test code rather than rendering artifacts; a UI-style dynamic data-flow trace is not applicable.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | Retained eager strategy enters the authoritative encode machine | ✓ WIRED | `PngEncoder` stores `strategy` (`png.mbt:83-100`); `ImageEncoder::encode` passes `_self.strategy` to `PngEncodeMachine::new_with_compression_strategy` (`encode.mbt:208-213`). |
| `stream_encode.mbt` | `stream_encode_test.mbt` | Configured/legacy chunk construction and accepted-prefix drain | ✓ WIRED | Configured constructor passes `strategy` to the private machine (`stream_encode.mbt:29-42`); the test drain only copies indices `< result.written()` (`stream_encode_test.mbt:82-123`) and its legacy tests compare frozen aggregates. |
| `foundation.json` | generated PNG interface | Exact semantic policy registration | ✓ WIRED | The passing PNG lane generates and compares `pkg.generated.mbti` using exact line count and content matching (`Invoke-MoonQuality.ps1:47-73`). |

`verify.key-links` independently reported 3/3 verified links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Eager encoder | `PngEncoder.strategy` | Public configured factory → `ImageEncoder::encode` → private machine | Caller-selected enum reaches the emitter | ✓ FLOWING |
| Chunk encoder | `strategy` | Public configured chunk factory → private machine | Caller-selected enum reaches the emitter | ✓ FLOWING |
| Legacy eager/chunk | explicit `Stored` | Existing constructors → private stored wrapper/machine | Existing stored-DEFLATE byte path, confirmed by full-byte tests | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Public configured factories accept both strategies and encode | `moon -C modules/mb-image test png --target native --frozen -f '*PNG compression strategy*'` | 4 passed, 0 failed | ✓ PASS |
| Public interface, policy negatives, package inventory, portable workflow, and four-target PNG behavior | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Exit 0; policy and negative fixtures passed; 102/102 tests on js, wasm, wasm-gc, native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGC-01 | `32-01-PLAN.md` | Users can request a documented PNG compression strategy while existing eager/chunk constructors retain byte-for-byte stored-DEFLATE output. | ✓ SATISFIED | Public enum/factories, explicit legacy `Stored` routes, independent frozen eager/chunk RGB8/RGBA8 byte tests, and the passing all-target PNG lane. |

No Phase 32 requirement is orphaned: `PNGC-01` is both mapped to Phase 32 in `REQUIREMENTS.md` and declared by `32-01-PLAN.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No phase-introduced `TBD`, `FIXME`, `XXX`, placeholder, empty user-visible implementation, or console-only handler. | — | No blocker or warning. |

The one `not available here` phrase found in `png.mbt:24` predates the Phase 32 diff and documents chunk-decoder lifecycle behavior; it is not a stub or phase-introduced debt marker.

### Scope-Boundary Check

The Phase 32 commits (`2db65e7`, `84510ec`, `35b71c8`) modify only the six planned implementation/test/policy files plus the SUMMARY. Their source delta adds a retained strategy selector and a two-case stored-emission match. It adds no fixed-Huffman planner or emitter, dynamic-Huffman path, adaptive filter, LZ77 dictionary, host adapter/stream API, corpus fixture, size claim, never-larger assertion, or compression-win behavior. Those remain Phase 33/34 work as required by the roadmap.

### Gaps Summary

No gaps found. The implementation satisfies PNGC-01 and Phase 32's three roadmap success criteria without taking Phase 33/34 compression behavior into scope.

---

_Verified: 2026-07-21T17:50:37Z_
_Verifier: the agent (gsd-verifier)_
