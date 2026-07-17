---
phase: 04-image-model-views-and-operations
plan: "05"
subsystem: image-orientation-fixtures
tags: [moonbit, exif-orientation, generated-vectors, deterministic-fixtures, atomic-budgets]

requires:
  - phase: 04-image-model-views-and-operations/04-04
    provides: Closed U8 operation gate, fresh output factory, and shared operation result
provides:
  - Independent standards-literal eight-state orientation oracle
  - Fresh-output Exif orientation application normalized to TopLeft
  - Five deterministic package-local image evidence tables and provenance manifest
affects: [04-image-model-views-and-operations, resize, conversion, codec-contracts, phase-5-ppm]

tech-stack:
  added: []
  patterns:
    - One invariant-culture UTF-8/LF generator owns canonical JSON and five package-local tables
    - Standards-literal source-to-destination oracle remains independent from production mapping

key-files:
  created:
    - scripts/fixtures/Generate-ImageVectors.ps1
    - fixtures/image/operation-vectors.json
    - modules/mb-image/ops/orientation.mbt
    - modules/mb-image/ops/orientation_test.mbt
    - modules/mb-image/ops/orientation_wbtest.mbt
  modified:
    - fixtures/manifest.json
    - policy/foundation.json

key-decisions:
  - "Author the eight Exif source-to-destination mappings literally in generator data and test production orientation code only against that independent oracle."
  - "Apply orientation through one fresh scalar-charged operation allocation and normalize only orientation to TopLeft while preserving alpha, color, opaque metadata, and profile."
  - "Order the shared image fixture record before color-owned records so both deterministic generators agree regardless of invocation order."

patterns-established:
  - "Generated package evidence: metadata, model, and storage tables contain both canonical constants and package-local behavioral consumers."
  - "Orientation normalization: states 1-8 always produce fresh TopLeft storage; states 5-8 exchange dimensions."

requirements-completed: [IMAG-05, IMAG-07]

coverage:
  - id: D1
    description: All eight Exif orientations match an independent coordinate oracle and normalize fresh output to TopLeft.
    requirement: IMAG-05
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/orientation_wbtest.mbt; moon -C modules/mb-image test ops --target all --frozen (10/10 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical descriptor, plane, crop, lease, orientation, resize, conversion, disposition, and codec cases are byte-stable and provenance-recorded.
    requirement: IMAG-07
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required; 155/155 workspace tests per target"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 5: Canonical Image Evidence and Orientation Summary

**Five byte-stable package-local evidence tables plus fresh, metadata-preserving implementation of all eight Exif orientations against an independent literal oracle**

## Performance

- **Duration:** 24 min
- **Completed:** 2026-07-17
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added a deterministic invariant-culture generator for descriptor/plane, crop/lease, orientation, resize, conversion, disposition, and non-seeking codec evidence with SHA-256 provenance.
- Made metadata, model, and storage generated white-box files consume every canonical case inside their own package; the ops table supplies an exhaustive independent 3x2 orientation oracle.
- Implemented fresh-output orientation application for states 1-8, including dimension exchange for states 5-8, TopLeft normalization, exact metadata disposition, and atomic failure budgets.

## Task Commits

1. **Task 1: Generate five package-local image tables** - `b452efa` (test)
2. **Task 2 RED: Add failing orientation contracts** - `d37a6f1` (test)
3. **Task 2 GREEN: Apply all Exif orientations** - `c2d9ca7` (feat)

## Files Created/Modified

- `scripts/fixtures/Generate-ImageVectors.ps1` - Canonical data, exact renderers, check mode, digest, and shared manifest ownership.
- `fixtures/image/operation-vectors.json` - Repository-derived adversarial evidence with literal eight-state mappings.
- `fixtures/manifest.json` - Provenance, digest, license, and expected-use record for image vectors.
- `modules/mb-image/{metadata,model,storage,ops,codec}/reference_vectors_wbtest.mbt` - Five selective package-local tables; existing packages compile and consume their behavioral cases.
- `modules/mb-image/ops/orientation.mbt` - Fresh scalar-charged orientation transform and TopLeft metadata normalization.
- `modules/mb-image/ops/orientation_test.mbt` - Public orientation result, pixel, and disposition contract.
- `modules/mb-image/ops/orientation_wbtest.mbt` - Exhaustive independent oracle, dimension, metadata, and atomic-budget coverage.
- `policy/foundation.json` - Exact publication inventory and 15-line ops interface.

## Decisions Made

- Kept the generator oracle source-to-destination and the production mapping as separate hand-authored match structures so a production error cannot regenerate its own expected result.
- Reconstructed `ImageMetadata` with TopLeft while reusing the exact color space, transfer, alpha, profile, and opaque metadata identities.
- Defined orientation work as output logical byte writes and passed `(width, height, pixels, work)` exactly once to `OwnedImage::new_operation`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made shared fixture manifest order stable across both generators**
- **Found during:** Task 2 Required verification
- **Issue:** The image generator appended its record after color records while the existing color generator preserved non-color records first, so running one generator made the other's `-Check` stale.
- **Fix:** Made the image generator emit its owned record first, matching the color generator's stable shared order.
- **Files modified:** `scripts/fixtures/Generate-ImageVectors.ps1`, `fixtures/manifest.json`
- **Verification:** Both image and color generator check modes pass sequentially; the complete Required lane passes.
- **Committed in:** `c2d9ca7`

**Total deviations:** 1 auto-fixed bug. **Impact:** Determinism correction only; no API or image-semantic scope change.

## Issues Encountered

- The Required lane's expected negative README fixture prints a missing-file error while its enclosing fail-closed check succeeds; the lane exited 0 as designed.

## User Setup Required

None - no external service configuration required.

## Verification

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check`: all seven generated artifacts and the manifest were byte-identical.
- `pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check`: passed after the shared manifest ordering fix.
- `moon -C modules/mb-image test ops --target all --frozen`: 10/10 passed on js, wasm, wasm-gc, and native with no orientation mismatch.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 155/155 workspace tests per target, 15 exact ops interface lines, exact publication/DAG/fixture checks, and read-only proof.

## Self-Check: PASSED

- All twelve planned source, generated evidence, manifest, and policy files exist.
- Commits `b452efa`, `d37a6f1`, and `c2d9ca7` resolve in repository history.
- No known stubs or new network, filesystem, authentication, schema, registry, or seeking surface was introduced.

## Next Phase Readiness

- Plan 04-06 can consume generated resize and conversion evidence over the same fresh scalar-charged operation/result contract.
- Plan 04-07 can consume the generated non-seeking codec cases when it creates the codec package contract.
- No blockers remain.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
