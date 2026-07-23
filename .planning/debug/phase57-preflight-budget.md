---
status: resolved
trigger: "Phase 57 code review found the new encode_wbtest preflight assertion fails, causing the full native PNG suite to exit 0xc0000409."
created: 2026-07-23
updated: 2026-07-23
---

# Phase 57 preflight budget

## Symptoms

- Expected: the new Adam7 preflight white-box regression succeeds for the legal GrayAlpha16 input and the full PNG suite can run past it.
- Actual: `modules/mb-image/png/encode_wbtest.mbt` lines 405-408 call `unwrap()` on a failing `_png_encode_preflight_with_interlace_profile(...)` result.
- Error: native presents `0xc0000409`; wasm-gc/js expose `Result.unwrap`.
- Timeline: introduced with Phase 57 plan 01 coverage.
- Reproduction: `moon -C modules/mb-image test png/encode_wbtest.mbt --target native --frozen --index 3 --no-parallelize`.

## Current Focus

- hypothesis: confirmed — the white-box regression used static limits for a legal dynamic Adam7 workload.
- next_action: resolved; retain the dynamic-limit regression and proceed with phase verification.

## Evidence

- timestamp: 2026-07-23
  source: Phase 57 code review
  observation: the failure is deterministic at the new preflight assertion and is not a generic runner instability.
- timestamp: 2026-07-23
  source: exact four-target regression and full native suite
  observation: replacing `png_wb_limits()` with `png_wb_dynamic_limits()` makes the exact test pass on wasm, wasm-gc, js, and native; the native PNG suite passes 222/222.

## Eliminated

- hypothesis: the native runner itself is the source of the failure.
  evidence: the same white-box case passes on all four targets after the limit correction, and the full native suite passes.

## Resolution

- root_cause: a test introduced by Phase 57 used static preflight limits while asserting a legal Adam7 dynamic work profile, so its `unwrap()` rejected the test setup.
- fix: use `png_wb_dynamic_limits()` consistently for the admitted, exact-work, and one-less preflight checks.
- verification: exact case passed on all four targets; `moon -C modules/mb-image test png --target native --frozen --no-parallelize` passed 222/222.
- files_changed: modules/mb-image/png/encode_wbtest.mbt
