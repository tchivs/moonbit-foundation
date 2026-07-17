---
phase: 03-reference-color-semantics
plan: "03"
subsystem: color-transfer
tags: [moonbit, srgb, piecewise-transfer, typed-components, deterministic-vectors]

requires:
  - phase: 03-reference-color-semantics
    provides: opaque validated encoded/linear sRGB components and generated provenance-recorded transfer vectors
provides:
  - typed encoded-sRGB to linear-sRGB reference conversion and inverse
  - named decode, encode, and round-trip absolute tolerances
  - exact four-target transfer package interface, imports, and publication policy
affects: [03-quantize, 03-alpha, 04-image-contract, color-conformance]

tech-stack:
  added: []
  patterns: [identity-preserving conversion APIs, inclusive normative branch thresholds, package-local generated evidence]

key-files:
  created:
    - modules/mb-color/transfer/moon.pkg
    - modules/mb-color/transfer/transfer.mbt
    - modules/mb-color/transfer/transfer_test.mbt
    - modules/mb-color/transfer/transfer_wbtest.mbt
    - modules/mb-color/transfer/reference_vectors_wbtest.mbt
  modified:
    - policy/foundation.json
    - scripts/fixtures/Generate-ColorVectors.ps1

key-decisions:
  - "Keep transfer conversion typed end to end: encoded-sRGB input produces linear-sRGB output, and the inverse accepts only linear-sRGB."
  - "Use the published inclusive low branches at 0.04045 and 0.0031308 with 1e-12 operation tolerances and a 2e-12 round-trip tolerance."
  - "Keep generated package evidence byte-stable and formatter-clean by emitting the required separator from the canonical generator."

patterns-established:
  - "Transfer oracle: standard-literal piecewise formulas use @math.pow, never clamping, ambiguous normalized Double APIs, or backend rounding."
  - "Numerical evidence: compare power results with named absolute tolerances while testing branch selection directly against its selected formula."

requirements-completed: [COLR-02, COLR-04]

coverage:
  - id: D1
    description: "Typed portable sRGB decode and encode implement the normative inclusive branch thresholds and locked tolerances"
    requirement: COLR-02
    verification:
      - kind: unit
        ref: "moon -C modules/mb-color test transfer --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated registered vectors, endpoints, branch neighbors, monotonicity, finite/range preservation, and round trips execute without filesystem access"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts transfer -Check"
        status: pass
      - kind: unit
        ref: "modules/mb-color/transfer/transfer_wbtest.mbt#registered transfer vectors match the standards formulas"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact transfer topology, imports, semantic interface, targets, and publication contents are fail-closed policy"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 03: Portable sRGB Reference Transfer Summary

**Typed standards-literal sRGB transfer functions with named tolerances and byte-stable four-target conformance vectors**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-16T18:05:00Z
- **Completed:** 2026-07-16T18:15:24Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added identity-preserving `EncodedSrgbComponent -> LinearSrgbComponent` decoding and the typed inverse using the normative inclusive low branches.
- Proved official-formula-derived vectors, endpoints, adjacent branch cases, monotonicity, finite/range preservation, and round trips on js, wasm, wasm-gc, and native.
- Registered an exact nine-line public interface and closed publication/import inventory while retaining the private root scaffold.

## Task Commits

1. **Task 1 RED: Specify typed sRGB transfer behavior** - `875866c` (test)
2. **Task 1 GREEN: Implement the portable transfer oracle** - `8d785ea` (feat)
3. **Task 1 fix: Keep generated evidence format-clean** - `f2dcb03` (fix)
4. **Task 2: Register exact transfer topology and interface** - `7e7a16b` (chore)

## Files Created/Modified

- `modules/mb-color/transfer/moon.pkg` - Four-target package importing only the explicit model and standard math.
- `modules/mb-color/transfer/transfer.mbt` - Typed normative transfer formulas and public tolerance functions.
- `modules/mb-color/transfer/transfer_test.mbt` - Public identity, endpoint, range, monotonicity, and round-trip evidence.
- `modules/mb-color/transfer/transfer_wbtest.mbt` - Exact branch formula and generated-vector evidence.
- `modules/mb-color/transfer/reference_vectors_wbtest.mbt` - Deterministic package-local vector table.
- `scripts/fixtures/Generate-ColorVectors.ps1` - Formatter-clean canonical transfer-table serialization.
- `policy/foundation.json` - Closed transfer package topology, interface, targets, imports, and publication inventory.

## Decisions Made

- Component identity is expressed by distinct input and result types rather than by comments, flags, or ambiguous raw normalized arguments.
- The rounded published thresholds are treated literally and inclusively; tests do not invent continuity between the two rounded formulas.
- Power results use named absolute tolerances; exact equality is reserved for branch selection and locked contract values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made generated transfer evidence formatter-clean**
- **Found during:** Task 2 Required qualification
- **Issue:** The canonical generator omitted the blank separator required after its file header, so generated byte identity and the mandatory formatter gate could not both pass.
- **Fix:** Added the separator to `Render-TransferMoon`, regenerated the package table, and normalized the handwritten tests.
- **Files modified:** `scripts/fixtures/Generate-ColorVectors.ps1`, `modules/mb-color/transfer/reference_vectors_wbtest.mbt`, and transfer test files.
- **Verification:** Generator `-Check`, package formatter check, four-target tests, and the full Required lane pass.
- **Committed in:** `f2dcb03`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** The fix is limited to making the planned canonical generated artifact satisfy both byte-stability and existing format policy; numerical content and package scope are unchanged.

## Issues Encountered

- The first RED compilation exposed unsupported tuple destructuring in a `for` binder. The test was corrected to use tuple projections before the RED commit, leaving the expected missing-transfer-API failure as the only test blocker.

## User Setup Required

None - no external service, dependency, or manual configuration is required.

## Known Stubs

None.

## Threat Flags

None. The package is pure portable computation with no network, host, file, authentication, allocation, or schema boundary.

## TDD Gate Compliance

- RED commit `875866c` records tests failing on the absent typed transfer API.
- GREEN commit `8d785ea` follows it and makes all nine tests pass on all four targets.

## Next Phase Readiness

- Quantization can consume explicit encoded components and the transfer tolerances without introducing an ambiguous scalar seam.
- Alpha and image phases can use the reference transfer oracle as the portable CPU semantics baseline.
- No blockers remain; the Required lane is green.

## Self-Check: PASSED

- All five transfer package files and the generator/policy changes exist.
- Task commits `875866c`, `8d785ea`, `f2dcb03`, and `7e7a16b` exist in history.
- Generator check is byte-identical, transfer tests pass 9/9 on every required target, and the full Required lane passes.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
