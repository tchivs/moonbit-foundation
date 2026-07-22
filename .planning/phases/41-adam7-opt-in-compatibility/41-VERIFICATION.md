---
phase: 41-adam7-opt-in-compatibility
verified: 2026-07-22T07:03:21Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 41: Adam7 Opt-In Compatibility Verification Report

**Phase Goal:** Users can explicitly select Adam7 interlaced eager and caller-buffered PNG encoding for compatible RGB8 and straight-RGBA8 images without changing legacy non-interlaced bytes.
**Verified:** 2026-07-22T07:03:21Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A PNG user can select an explicit Adam7 strategy on eager and caller-buffered RGB8 or straight-RGBA8 encoder routes. | ✓ VERIFIED | `PngInterlaceStrategy::{None, Adam7}` is public and equality-comparable in `png.mbt:98`; `PngEncoder` exposes interlace-only and all-strategy factories (`:164`, `:175`), while `PngChunkEncoder` exposes matching factories (`stream_encode.mbt:78`, `:93`). The eager implementation passes its stored strategy to the shared machine (`encode.mbt:1382-1384`); caller-buffered construction passes it at `stream_encode.mbt:102-108`. The focused public selectors cover both RGB8 and straight-RGBA8. |
| 2 | Every pre-existing eager and caller-buffered factory still emits its frozen non-interlaced bytes, and additive explicit-None routes emit those same bytes. | ✓ VERIFIED | Every legacy eager constructor forwards `PngInterlaceStrategy::None` (`png.mbt:114-159`); all caller-buffered and private legacy construction routes do likewise (`stream_encode.mbt:9-73`, `:264-302`). The eager selector compares complete literal PNG vectors for legacy and explicit-None routes on both source profiles (`encode_test.mbt:528-575`); the chunk selector does the same while draining hostile zero/one/ragged capacities (`stream_encode_test.mbt:738-799`). Recorded clean native package evidence passed **165/165** tests. |
| 3 | An Adam7 request returns the typed `png-encode` capability error with stable `png-adam7-pending` context before an eager writer observes bytes or a caller-buffered encoder is returned. | ✓ VERIFIED | The sole shared admission seam invokes `_png_encode_preflight_with_interlace` before state construction (`stream_encode.mbt:305-322`). Its Adam7 branch immediately returns `_png_encode_capability("png-adam7-pending")` before filter preflight (`encode.mbt:1164-1179`); that helper creates the typed `png-encode` capability error (`encode.mbt:16-18`). Eager tests assert category, code, context, writer position zero, and unchanged budget for both factory shapes (`encode_test.mbt:577-600`); chunk tests assert the same error and unchanged budget before `PngChunkEncoder` can be returned (`stream_encode_test.mbt:764-780`). The recorded clean four-target selector run passed these behavioral assertions. |
| 4 | The focused compatibility selectors pass independently on js, wasm, wasm-gc, and native. | ✓ VERIFIED | The runner contains exactly the two public selectors and all four targets (`Invoke-PngAdam7Compatibility.ps1:6-9`), runs each selector once per isolated target directory (`:39-47`), and cleans up only a validated GUID-prefixed child of the OS temp root (`:12-33`). Recorded clean-run evidence supplied for this verification: **PASS** on js, wasm, wasm-gc, and native. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public interlace strategy and eager selections | ✓ VERIFIED | 356 lines; substantive enum, field, preserved legacy signatures, and two additive public factories. Eager implementation consumes the field at `encode.mbt:1382-1384`. |
| `modules/mb-image/png/stream_encode.mbt` | Caller-buffered factories and shared construction seam | ✓ VERIFIED | 1,923 lines; substantive factories converge on `new_with_all_strategies`, which invokes atomic preflight before returning a machine. |
| `modules/mb-image/png/encode.mbt` | Atomic pending-capability rejection | ✓ VERIFIED | 1,739 lines; one interlace-aware wrapper rejects Adam7 before delegating the unchanged None branch to existing filter-aware preflight. |
| `modules/mb-image/png/encode_test.mbt` | Eager byte-compatibility and rejection evidence | ✓ VERIFIED | Named selector asserts literal complete output plus error/budget/output atomicity for RGB8 and straight-RGBA8. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered byte-compatibility and rejection evidence | ✓ VERIFIED | Named selector drains caller-owned buffers with hostile capacities and asserts construction rejection / unchanged budget. |
| `scripts/quality/Invoke-PngAdam7Compatibility.ps1` | Isolated four-target selector runner | ✓ VERIFIED | Runs only the two named selectors in target-owned temporary directories; safe containment and ownership checks guard cleanup. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `png.mbt` | `stream_encode.mbt` | Additive eager and chunk selections forward the interlace choice through the shared machine constructor. | ✓ WIRED | Eager passes `_self.interlace_strategy` to `PngEncodeMachine::new_with_all_strategies` (`encode.mbt:1382-1384`); chunk passes its argument at `stream_encode.mbt:102-108`. |
| `stream_encode.mbt` | `encode.mbt` | Machine admission calls the interlace-aware atomic preflight. | ✓ WIRED | `new_with_all_strategies` calls `_png_encode_preflight_with_interlace` and returns immediately on error before machine state is allocated (`stream_encode.mbt:315-322`). |
| `Invoke-PngAdam7Compatibility.ps1` | eager/chunk tests | Exact selectors execute once for every portable target. | ✓ WIRED | `$targets` is `js`, `wasm`, `wasm-gc`, `native`; nested loops invoke each exact selector with `moon ... test png ... -f $selector` (`Invoke-PngAdam7Compatibility.ps1:6-9`, `:39-47`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `png.mbt` / `encode.mbt` | `interlace_strategy` | Public factory argument → `PngEncoder` field → shared machine preflight | Yes — the selected enum reaches the Adam7 match before source processing | ✓ FLOWING |
| `stream_encode.mbt` | `interlace_strategy` | Public caller-buffered factory argument → shared machine preflight | Yes — argument is passed directly and error prevents construction | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Exact public compatibility selectors on all portable targets | `& .\scripts\quality\Invoke-PngAdam7Compatibility.ps1` | Recorded clean evidence: js, wasm, wasm-gc, native all passed. Not re-run during this verification. | ✓ PASS |
| Legacy PNG regression suite | `moon -C modules/mb-image test png --target native --frozen` | Recorded clean evidence: 165/165 passed. Not re-run; verifier did not run a broad suite. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGI-01 | `41-01-PLAN.md` | Explicit Adam7 eager/caller-buffered selection for RGB8/straight-RGBA8 while legacy constructors and compression-only routes retain byte-identical non-interlaced output. | ✓ SATISFIED | Truths 1–3 establish the public selection and deterministic pending boundary; Truth 2’s literal-vector coverage and recorded 165/165 native suite establish compatibility; Truth 4 establishes portable selector evidence. |

No requirements mapped to Phase 41 were orphaned. Later phases 42 and 43 cover actual seven-pass emission and expanded generated portability evidence; neither is required for this phase’s explicitly pending Adam7 boundary.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `png.mbt` | 97 | “not available until Phase 42” comment | ℹ️ Info | Intentional, documented pending capability. It is enforced by the typed atomic rejection and corresponding tests; it is not a placeholder or unresolved debt marker. |

No `TBD`, `FIXME`, or `XXX` markers were found in Phase 41 implementation, test, or runner files. `git diff --check 2fc1366..HEAD` reported no whitespace errors. The phase changes are confined to the six planned files; no Adam7 traversal, pass emission, filtering, compression planning, replay, or `structural.mbt` geometry changes were introduced.

### Gaps Summary

No gaps found. The phase deliberately rejects Adam7 output pending Phase 42 rather than producing incorrect non-interlaced bytes, which matches the Phase 41 contract.

---

_Verified: 2026-07-22T07:03:21Z_
_Verifier: the agent (gsd-verifier)_
