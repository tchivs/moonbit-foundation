---
phase: 04-image-model-views-and-operations
plan: "08"
subsystem: image-qualification
tags: [moonbit, literate-docs, rootless-packages, generated-evidence, fail-closed]

requires:
  - phase: 04-image-model-views-and-operations/04-07
    provides: Complete metadata, model, storage, operations, and codec contracts
provides:
  - Rootless executable mb-image documentation over all five public packages
  - Exact package, interface, publication, target, source, and deferral qualification
  - Five package-local generated tables with canonical IDs and independent consumers
affects: [04-image-model-views-and-operations, 05-bounded-ppm-p6-proof, release-qualification]

tech-stack:
  added: []
  patterns:
    - One exact classifier owns both positive policy and synthetic negative evidence
    - Generated evidence has canonical IDs plus consumers outside generated artifacts

key-files:
  created: []
  modified:
    - modules/mb-image/README.mbt.md
    - modules/mb-image/CHANGELOG.md
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
    - scripts/fixtures/Generate-ImageVectors.ps1
    - fixtures/image/operation-vectors.json
    - fixtures/manifest.json

key-decisions:
  - "Publish exactly metadata, model, storage, ops, and codec, with no root package or facade."
  - "Require each generated table to expose exact canonical case IDs and require a separate behavioral test to consume its functions."
  - "Keep the eight-state orientation oracle as literal generator-owned data that cannot read production mapping source."

patterns-established:
  - "Image qualification closes topology, DAG, interfaces, publication, targets, docs, source prohibitions, generated evidence, and read-only behavior in one Required lane."

requirements-completed: [IMAG-01, IMAG-02, IMAG-03, IMAG-04, IMAG-05, IMAG-06, IMAG-07]

coverage:
  - id: D1
    description: Every public image contract is documented by standalone executable examples with exact support and deferral boundaries.
    requirement: IMAG-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image check README.mbt.md --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact rootless publication, DAG, interfaces, targets, prohibited surfaces, and generated evidence fail closed.
    requirement: IMAG-07
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required; passed twice with 171/171 tests per target"
        status: pass
    human_judgment: false

duration: 36min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 8: Rootless Documentation and Qualification Summary

**Executable five-package image documentation plus exact fail-closed publication, generated-evidence, prohibition, and four-target qualification**

## Performance

- **Duration:** 36 min
- **Completed:** 2026-07-17
- **Tasks:** 3
- **Files modified:** 16, including three intentional scaffold deletions

## Accomplishments

- Replaced Phase 1 scaffold prose with standalone examples for descriptors, budgets, storage, retained and mutable views, crops, metadata disposition, deterministic operations, and forward-only codec seams.
- Removed the root package and both scaffold sources, leaving exactly `metadata`, `model`, `storage`, `ops`, and `codec` in the public interface and publication inventory.
- Added exact image DAG, target, interface, publication, README, source-prohibition, generated-table, case-ID, consumer, oracle-independence, and synthetic-negative gates.
- Froze exactly five package-local generated tables with 31 canonical IDs: metadata 3, model 3, storage 4, ops 14, and codec 4.
- Passed the complete Required lane twice from a committed baseline, with read-only proof and 171/171 tests on each of `js`, `wasm`, `wasm-gc`, and `native`.

## Task Commits

1. **Task 1: Publish executable rootless image documentation** - `88a46c9` (docs)
2. **Task 2: Close fail-closed Phase 4 qualification** - `d44096c` (chore)
3. **Task 3: Prove generated evidence completeness fails closed** - `d13e6e7` (test)

## Decisions Made

- Publication order is exact and independent of dependency inference: `metadata`, `model`, `storage`, `ops`, `codec`.
- A generated artifact cannot self-certify consumption: metadata, model, storage, ops, and codec each have an independent behavioral consumer outside the generated table.
- PPM P6 remains wholly owned by Phase 5; Phase 4 documents only open prefix/Reader/Writer contracts and contains no concrete codec, registry, filesystem, or URL policy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made the new operation ID table formatter-exact**
- **Found during:** First full Required format check
- **Issue:** The generator initially emitted all 14 operation IDs on one line, while the pinned MoonBit formatter required a stable multiline array.
- **Fix:** Changed the generator renderer to emit the exact canonical multiline layout and formatted the three new consumer tests.
- **Files modified:** `scripts/fixtures/Generate-ImageVectors.ps1`, generated ops table, metadata/model/storage behavioral tests
- **Verification:** Generator `-Check`, formatter check, and both complete Required runs pass.
- **Committed in:** `d13e6e7`

**Total deviations:** 1 auto-fixed blocking formatting issue. No public API or product scope changed.

## Issues Encountered

- The Required lane's intentional missing-README negative prints a native check error while its enclosing negative fixture succeeds; both complete runs exited 0.
- A pre-commit qualification trial reached the final read-only gate after all semantic checks passed, but correctly detected the still-uncommitted Task 2/3 diff. Both required post-commit runs passed read-only proof.

## User Setup Required

None.

## Verification

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check`: seven generated artifacts and the shared manifest are byte-identical.
- Focused image qualification: exact five tables, 31 canonical IDs, five independent consumer classes, oracle independence, and 23 synthetic negatives passed.
- `moon -C modules/mb-image check README.mbt.md --target all --frozen`: passed on all four targets.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed twice, each with 171/171 tests per target, exact 41/92/39/21/55-line image interfaces, exact package contents, and read-only proof.

## Self-Check: PASSED

- Commits `88a46c9`, `d44096c`, and `d13e6e7` resolve in repository history.
- Root `moon.pkg`, `scaffold.mbt`, and `scaffold_wbtest.mbt` are absent.
- Summary and all five generated table paths exist.
- No TODO/FIXME/placeholder stub or new host, filesystem, URL, registry, seeking, concrete-codec, network, authentication, or schema surface was introduced.

## Next Phase Readiness

- Phase 4 is implementation-complete and ready for the phase verifier.
- Phase 5 can implement bounded PPM P6 through the frozen prefix/Reader/Writer contracts without changing the image model or operation semantics.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
