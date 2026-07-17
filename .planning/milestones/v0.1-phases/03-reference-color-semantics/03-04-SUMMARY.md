---
phase: 03-reference-color-semantics
plan: "04"
subsystem: color-quantization
tags: [moonbit, ties-to-even, quantization, checked-arithmetic, portable]

requires:
  - phase: 03-reference-color-semantics
    provides: opaque encoded-sRGB and alpha domains plus deterministic derived edge vectors
provides:
  - typed normalized-to-encoded-eight conversion for encoded sRGB and alpha
  - public exact UInt64 ratio rounding with structured invalid-arithmetic failures
  - exhaustive four-target encoded-domain and halfway conformance evidence
affects: [03-alpha, 04-image-contract, color-conformance]

tech-stack:
  added: []
  patterns: [explicit floor-fraction-parity classification, quotient-remainder ties-even, decision-before-narrowing]

key-files:
  created:
    - modules/mb-color/quantize/moon.pkg
    - modules/mb-color/quantize/quantize.mbt
    - modules/mb-color/quantize/quantize_test.mbt
    - modules/mb-color/quantize/quantize_wbtest.mbt
    - modules/mb-color/quantize/reference_vectors_wbtest.mbt
  modified:
    - scripts/fixtures/Generate-ColorVectors.ps1
    - policy/foundation.json

key-decisions:
  - "Keep floating halfway classification private while exposing only typed encoded-sRGB and alpha conversions plus the exact UInt64 ratio helper required by alpha."
  - "Reject zero denominators and checked twice-remainder overflow before an exact ratio decision; never delegate rounding policy to Double::round or a narrowing cast."
  - "Keep quantize independent of transfer, with exact DAG edges only to model, mb-core/error, and mb-core/checked."

patterns-established:
  - "Floating quantization: scale a validated domain value by 255, classify floor/fraction/parity explicitly, then construct only the matching encoded identity type."
  - "Exact ratio rounding: quotient/remainder plus checked twice-remainder comparison completes the ties-even decision in UInt64."

requirements-completed: [COLR-02, COLR-04]

coverage:
  - id: D1
    description: "Distinct typed encoded-sRGB and alpha quantization/dequantization with exact ties-to-even semantics and no implicit saturation"
    requirement: COLR-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-color test quantize --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Public exact-ratio helper rejects zero denominators and checked twice-remainder overflow before rounding"
    requirement: COLR-02
    verification:
      - kind: unit
        ref: "modules/mb-color/quantize/quantize_test.mbt#public exact ratio helper rejects invalid arithmetic"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 256 encoded values, exact and neighboring half cases, endpoints, generated vectors, interface, DAG, and publication contents are fail-closed on four targets"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts quantize -Check"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 04: Exact Portable Quantization Summary

**Typed encoded-sRGB and alpha quantization now uses explicit ties-to-even decisions with checked exact-ratio arithmetic on every production target**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-16T18:23:35Z
- **Completed:** 2026-07-16T18:29:15Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added distinct typed quantize/dequantize operations for encoded sRGB and normalized alpha without a raw scalar or linear-sRGB seam.
- Added public exact `UInt64` ratio rounding with ties-to-even, structured zero-denominator rejection, and checked twice-remainder overflow detection.
- Proved all 256 encoded round trips, scaled half and neighbor cases, ratio parity cases, endpoints, generated evidence, exact policy, and four-target conformance.

## Task Commits

1. **Task 1 RED: Specify portable ties-even quantization** - `f64d8fe` (test)
2. **Task 1 GREEN: Implement typed and exact ties-even quantization** - `ce14ee1` (feat)
3. **Task 1 fix: Keep generated evidence format-clean** - `dcfd02e` (fix)
4. **Task 2: Register exact quantize package contract** - `20178cf` (chore)

## Files Created/Modified

- `modules/mb-color/quantize/moon.pkg` - Four-target package with model, error, and checked imports only.
- `modules/mb-color/quantize/quantize.mbt` - Typed floating quantization, dequantization, and exact ratio rounding.
- `modules/mb-color/quantize/quantize_test.mbt` - Public typed-domain, exhaustive encoded, bounds, and structured-error evidence.
- `modules/mb-color/quantize/quantize_wbtest.mbt` - Halfway, neighbor, parity, and generated-vector invariants.
- `modules/mb-color/quantize/reference_vectors_wbtest.mbt` - Deterministic package-local quantize and ratio vectors.
- `scripts/fixtures/Generate-ColorVectors.ps1` - Formatter-clean quantize table emission.
- `policy/foundation.json` - Exact quantize package DAG, interface, targets, and publication contents.

## Decisions Made

- Floating classification remains private so no identity-erasing scalar helper becomes public; the only lower-layer public seam is exact integer ratio rounding required by encoded alpha.
- All halfway policy is explicit: floating values use floor/fraction/parity and exact ratios use quotient/remainder/parity after checked doubling.
- Output construction happens only after the rounding decision and uses the corresponding opaque encoded color or alpha type; no transfer package or linear component is accepted.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made generated quantize evidence formatter-clean**
- **Found during:** Task 2 Required qualification
- **Issue:** The canonical quantize renderer omitted the blank separator required after its generated-file header, so generator byte identity and the mandatory formatter gate could not both pass.
- **Fix:** Added the separator to `Render-QuantizeMoon`, regenerated the table, and applied canonical formatting to the handwritten package files.
- **Files modified:** `scripts/fixtures/Generate-ColorVectors.ps1` and `modules/mb-color/quantize/*.mbt`
- **Verification:** Selective generator check, four-target package tests, format check, and complete Required lane pass.
- **Committed in:** `dcfd02e`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** The fix only reconciles canonical generated bytes with existing formatting policy; arithmetic semantics and package scope are unchanged.

## Issues Encountered

None beyond the formatter/generator alignment documented above.

## User Setup Required

None - no external services, packages, or manual configuration are required.

## Known Stubs

None.

## Threat Flags

None. This plan adds pure portable arithmetic only, with no network, host, file, authentication, allocation, or external schema boundary.

## TDD Gate Compliance

- RED commit `f64d8fe` records tests failing only because the planned quantize API did not yet exist.
- GREEN commit `ce14ee1` follows it and makes all eight package tests pass.
- The post-GREEN formatter fix `dcfd02e` preserves passing behavior and deterministic evidence.

## Next Phase Readiness

- Plan 03-05 can consume `round_ratio_ties_even` and the typed quantize operations for exact encoded alpha conversions without importing transfer.
- The Required lane is green and quantize's five-function public interface is locked exactly.

## Self-Check: PASSED

- All five quantize package files and both modified integration files exist.
- Task commits `f64d8fe`, `ce14ee1`, `dcfd02e`, and `20178cf` exist in history.
- Quantize tests pass 8/8 on js, wasm, wasm-gc, and native; generator check is byte-identical; the complete Required lane passes.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
