---
phase: 03-reference-color-semantics
plan: "05"
subsystem: color-alpha
tags: [moonbit, premultiplied-alpha, ties-to-even, checked-arithmetic, opaque-types]

requires:
  - phase: 03-reference-color-semantics
    provides: explicit model identities, exact quantization, and deterministic derived alpha vectors
provides:
  - four distinct opaque straight and premultiplied normalized/encoded sRGBA states
  - fail-closed directional conversions with canonical zero and checked ties-even arithmetic
  - exhaustive encoded alpha evidence and exact package policy topology
affects: [03-profile, 04-image-contract, color-conformance]

tech-stack:
  added: []
  patterns: [state-specific constructors, validation-before-storage, checked-ratio conversion, directional round-trip claims]

key-files:
  created:
    - modules/mb-color/alpha/moon.pkg
    - modules/mb-color/alpha/alpha.mbt
    - modules/mb-color/alpha/alpha_test.mbt
    - modules/mb-color/alpha/alpha_wbtest.mbt
    - modules/mb-color/alpha/reference_vectors_wbtest.mbt
  modified:
    - scripts/fixtures/Generate-ColorVectors.ps1
    - policy/foundation.json

key-decisions:
  - "Keep normalized encoded and linear RGB behind one private tagged representation while exposing exactly four opaque public alpha-state types."
  - "Treat zero alpha as a canonical override; for nonzero encoded alpha the exhaustive straight round-trip bound is 127 codes, while premultiplied-to-straight-to-premultiplied is exact."
  - "Form encoded numerators with checked UInt64 multiplication and delegate every division decision to the public exact ties-even ratio helper."

patterns-established:
  - "Alpha validation: premultiplied constructors are the only public state-validation entry points and reject each p>a channel before storage."
  - "Alpha conversion: names and types encode direction; no Boolean mode, clamp, transfer inference, or identity-erasing component seam exists."

requirements-completed: [COLR-01, COLR-03, COLR-04]

coverage:
  - id: D1
    description: "Four explicit normalized/encoded straight and premultiplied states preserve space, transfer, representation, and alpha identity"
    requirement: COLR-01
    verification:
      - kind: unit
        ref: "modules/mb-color/alpha/alpha_test.mbt#normalized alpha states preserve explicit domain and identity"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-color test alpha --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Directional normalized and encoded conversions canonicalize zero, reject invalid premultiplied state, and use checked ties-even arithmetic"
    requirement: COLR-03
    verification:
      - kind: unit
        ref: "modules/mb-color/alpha/alpha_wbtest.mbt#exhaustive encoded pairs establish directional identities and bounds"
        status: pass
    human_judgment: false
  - id: D3
    description: "Generated alpha evidence, exact public interface, publication contents, four targets, and dependency direction are fail closed"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts alpha -Check"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 11min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 05: Explicit Alpha-State Semantics Summary

**Four opaque sRGBA alpha states now convert directionally with canonical zero, fail-closed p>a validation, and checked exact ties-to-even arithmetic on every target**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-16T18:34:31Z
- **Completed:** 2026-07-16T18:44:59Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added exactly four public alpha states with separate normalized encoded/linear constructors, fixed identity accessors, typed RGB accessors, and no ambiguous mode toggle.
- Added structured premultiplied validation plus directional normalized and encoded conversions using canonical zero, checked widened numerators, and the shared exact ties-even helper.
- Exhaustively proved all encoded component/alpha pairs: premultiplied round trips are exact, zero is canonical, and nonzero straight round-trip error has an observed maximum of 127 codes.
- Registered alpha after quantize with a closed 54-line interface, exact five-file publication surface, four targets, and only the four planned inward dependencies.

## Task Commits

1. **Task 1 RED: Specify distinct alpha-state constructors and conversions** - `9ae56b3` (test)
2. **Task 1 GREEN: Implement explicit alpha-state conversions** - `ae4912b` (feat)
3. **Task 1 fix: Keep generated alpha evidence format-clean** - `c6f7911` (fix)
4. **Task 2: Register alpha package and exact dependency direction** - `71ab634` (chore)

## Files Created/Modified

- `modules/mb-color/alpha/moon.pkg` - Four-target package with exact model, quantize, error, and checked imports.
- `modules/mb-color/alpha/alpha.mbt` - Opaque states, fail-closed constructors, identity accessors, and directional conversions.
- `modules/mb-color/alpha/alpha_test.mbt` - Public signature, identity, rejection, zero, boundary, and tie evidence.
- `modules/mb-color/alpha/alpha_wbtest.mbt` - Generated-vector consumption and exhaustive encoded pair proof.
- `modules/mb-color/alpha/reference_vectors_wbtest.mbt` - Deterministic package-local alpha table.
- `scripts/fixtures/Generate-ColorVectors.ps1` - Formatter-clean alpha renderer.
- `policy/foundation.json` - Exact alpha interface, package order, files, targets, and dependency allowlist.

## Decisions Made

- Normalized states carry a private encoded-or-linear tag so optional accessors cannot return a mismatched transfer domain; the tag is not a fifth public alpha state.
- Canonical zero is treated separately from lossy nonzero straight round trips. Exhaustive evidence supports the actual 127-code maximum at low nonzero alpha rather than repeating the research recommendation of one code.
- Premultiplied-to-straight-to-premultiplied encoded conversion is claimed as exact only because exhaustive enumeration proves every valid pair.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made generated alpha evidence formatter-clean**
- **Found during:** Task 1 post-GREEN generator check
- **Issue:** The alpha renderer omitted the canonical separator after its generated-file header, so generator byte identity and the required formatter gate could not both pass.
- **Fix:** Added the separator to `Render-AlphaMoon` and regenerated the package-local table.
- **Files modified:** `scripts/fixtures/Generate-ColorVectors.ps1`, `modules/mb-color/alpha/reference_vectors_wbtest.mbt`
- **Verification:** Selective alpha generation check, formatter check, four-target alpha tests, and full Required lane pass.
- **Committed in:** `c6f7911`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** The fix only aligns canonical generated bytes with existing formatting policy; alpha semantics and scope are unchanged.

## Issues Encountered

- The research recommendation suggested a one-code encoded straight round-trip bound. Exhaustive enumeration showed the actual nonzero-alpha maximum is 127 codes at low coverage, so only the measured bound is recorded and no false identity is promised.

## User Setup Required

None - no external services, packages, or manual configuration are required.

## Known Stubs

None.

## Threat Flags

None. The package adds pure portable value validation and arithmetic only, with no network, host, file, authentication, allocation, or external schema boundary.

## TDD Gate Compliance

- RED commit `9ae56b3` failed on the planned missing alpha types and functions.
- GREEN commit `ae4912b` follows it and passes all nine alpha tests on js, wasm, wasm-gc, and native.

## Next Phase Readiness

- Plan 03-06 can build the bounded profile seam without importing alpha or changing its semantics.
- Phase 4 can consume explicit alpha modes and validated encoded/normalized states without guessing representation.

## Self-Check: PASSED

- All five alpha package files and both modified integration files exist.
- Task commits `9ae56b3`, `ae4912b`, `c6f7911`, and `71ab634` exist in history.
- Alpha tests pass 9/9 on all four targets; selective generator check and full Required qualification pass.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
