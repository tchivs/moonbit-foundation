---
phase: 88-indexed-adam7-api-and-fixed-wire-contract
verified: 2026-07-24T12:00:00+08:00
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 88: Indexed Adam7 API and Fixed Wire Contract Verification Report

**Phase Goal:** Indexed1/2/4/8 callers can explicitly select Adam7 plus Stored or FixedOrStored through eager and caller-buffered APIs while preserving existing Stored routes.

**Status:** passed

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Indexed1/2/4/8 expose paired additive eager and chunked selector names. | VERIFIED | `encode.mbt` and `stream_encode.mbt` each define the Indexed8 and selected-depth `...with_interlace_and_compression_strategy` methods; the phase selector test constructs all routes. |
| 2 | Existing interlace-only methods remain literal Stored forwards. | VERIFIED | Both eager and chunked interlace-only methods call the additive overload with `PngCompressionStrategy::Stored`; the complete test suite remains green. |
| 3 | Stored and FixedOrStored share the existing indexed machine seam and no second encoder/staging buffer is introduced. | VERIFIED | All new public methods converge on `PngEncodeMachine::new_with_indexed_profile_and_strategy`; pass bytes come from `_png_indexed_adam7_scanline_byte`. |
| 4 | Adam7 low-bit pass bytes use filter None, MSB-first packing, and zero unused tails. | VERIFIED | `PngIndexedRawCursor::next` uses `_png_adam7_passes` plus the existing packed scanline helper; existing independent Adam7 literal-pass tests and the new selector test pass. |
| 5 | FixedOrStored remains bounded to complete indexed frame facts and falls back to Stored when Fixed does not win. | VERIFIED | Indexed preflight computes pass scanlines, PLTE/tRNS-aware frame facts, and bounded fixed work before budget admission; existing phase-87 matrix tests and new all-target tests pass. |
| 6 | Unsupported Dynamic remains rejected before output/lease/budget side effects. | VERIFIED | The existing early guard in indexed preflight remains first; all package tests pass on native, wasm, wasm-gc, and js. |

**Score:** 6/6 truths verified.

## Required Artifacts

| Artifact | Status | Details |
| --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | VERIFIED | Additive eager APIs and pass-aware indexed matcher cursor. |
| `modules/mb-image/png/stream_encode.mbt` | VERIFIED | Additive chunk APIs and shared acknowledged machine wiring. |
| `modules/mb-image/png/stream_encode_test.mbt` | VERIFIED | All low-bit depths plus Indexed8 selector coverage. |

## Behavioral Spot-Checks

| Command | Result |
| --- | --- |
| `moon check modules/mb-image/png --target native` | 0 errors (warnings only) |
| `moon test modules/mb-image/png --target all` | 316 passed / 0 failed on native, wasm, wasm-gc, and js |
| `git diff --check` | clean |

## Scope Fence

No indexed Dynamic/adaptive route, wider matcher, dictionary, FFI adapter, copied source tree, or second encoder was added. The only untracked workspace item is the pre-existing user-owned planning input under `.planning/milestones/v0.21-phases/66-explicit-rgba16-png-preservation/`; it was not modified or staged.

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| ADAM7COMP-01 | SATISFIED | Additive all-depth eager/chunked selector APIs, pass-local producer wiring, and 316/316 all-target tests. |

## Gaps Summary

None for Phase 88. Hostile lease matrices and independent RGB8/RGBA8 qualification remain intentionally assigned to Phases 89–90.

---
_Verified: 2026-07-24_
