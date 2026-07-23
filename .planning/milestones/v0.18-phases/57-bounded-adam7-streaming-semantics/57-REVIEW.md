---
phase: 57-bounded-adam7-streaming-semantics
reviewed: 2026-07-23T00:00:00+08:00
depth: deep
files_reviewed: 4
files_reviewed_list:
  - modules/mb-image/png/encode_test.mbt
  - modules/mb-image/png/encode_wbtest.mbt
  - modules/mb-image/png/stream_encode.mbt
  - modules/mb-image/png/stream_encode_test.mbt
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 57: Code Review Report

**Reviewed:** 2026-07-23T00:00:00+08:00
**Depth:** deep
**Files Reviewed:** 4
**Status:** issues_found

## Summary

The review traced the public GrayAlpha16 Adam7 factories through the shared
profile-aware preflight and `PngChunkEncoder::pull`.  The Stored replay guard is
positioned before `destination.set`, and the new public strategy-matrix tests
exercise the intended selector path.  However, the newly added white-box
preflight test aborts while unwrapping its first or a later strategy preflight,
which makes the complete native PNG suite fail.  Native reports this as process
exit `0xc0000409`; portable targets expose the underlying `Result.unwrap`
failure.

## Critical Issues

### CR-01: New exact-work white-box regression aborts under its own configured limits

**File:** `modules/mb-image/png/encode_wbtest.mbt:405-408`

**Issue:** `PNG GrayAlpha16 Adam7 profile cursor keeps pass history and exact
work` unconditionally unwraps `_png_encode_preflight_with_interlace_profile`
while using `png_wb_limits()` / `png_wb_budget()`.  The selected GrayAlpha16
Adam7 strategy matrix is rejected under those configured bounds, so the test
never reaches its exact-work assertions.  This is reproducible with
`moon -C modules/mb-image test png/encode_wbtest.mbt --target native --frozen
--index 3 --no-parallelize` (native executable exits `0xc0000409`) and
`--target wasm-gc` (the test reports `Result.unwrap` at this call).  The full
`moon -C modules/mb-image test png --target native --frozen` suite therefore
also fails, rather than providing the Phase 57 gate claimed by the summaries.

**Fix:** Give this success-path exact-work test a limit/budget envelope that is
known to admit every selected plan, while retaining a separate one-less-work
budget for the rejection assertion.  For example, define local `limits` and
`admission_budget` values using the existing higher-work white-box helpers,
then use the same `limits` for all three calls:

```moonbit
let limits = png_wb_dynamic_limits()
let admitted = _png_encode_preflight_with_interlace_profile(
  image.view(), PngEncodeProfile::GrayAlpha16, strategy, filter_strategy,
  PngInterlaceStrategy::Adam7, limits, png_wb_dynamic_budget(work=1048576UL),
).unwrap()
```

Use a fresh `png_wb_dynamic_budget(work=admitted.selected_work)` for the exact
case and `...work=admitted.selected_work - 1UL` for the atomic rejection case.
Then rerun the indexed white-box test and the complete native PNG suite before
closing the phase.

---

_Reviewed: 2026-07-23T00:00:00+08:00_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
