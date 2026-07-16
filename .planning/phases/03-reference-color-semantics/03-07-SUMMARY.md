---
phase: 03-reference-color-semantics
plan: "07"
subsystem: color-qualification
tags: [moonbit, literate-docs, package-dag, negative-fixtures, read-only-quality]

requires:
  - phase: 03-reference-color-semantics
    provides: five implemented color packages, four generated vector tables, and exact candidate interfaces
provides:
  - executable four-target documentation for every public color contract
  - final rootless five-package publication order and independently checked DAG
  - fail-closed color topology, interface, source, documentation, fixture, and read-only qualification
affects: [04-image-contract, 05-release-qualification, color-publication]

tech-stack:
  added: []
  patterns: [rootless literate module documentation, release-order-versus-DAG separation, shared exact negative classifiers]

key-files:
  created: []
  modified:
    - modules/mb-color/README.mbt.md
    - modules/mb-color/CHANGELOG.md
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1

key-decisions:
  - "Publish the five mb-color packages in model, transfer, quantize, alpha, profile order while checking the dependency DAG independently rather than inferring edges from that order."
  - "Keep mb-color rootless: standalone literate frontmatter supplies explicit imports and the Required lane rejects any root package or scaffold reappearance."
  - "Use the same exact sequence, set, interface, publication, provenance, and source classifiers for positive policy and synthetic color negatives."

patterns-established:
  - "Rootless public docs: README.mbt.md imports focused packages explicitly and checks as a standalone input on every supported target."
  - "Color qualification: generated evidence, semantic interfaces, DAG edges, prohibitions, negative fixtures, package contents, and tracked immutability are one Required contract."

requirements-completed: [COLR-01, COLR-02, COLR-03, COLR-04, COLR-05]

coverage:
  - id: D1
    description: "Executable documentation covers typed sRGB transfer, exact quantization, explicit alpha states, and caller-bounded opaque profiles"
    requirement: COLR-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-color check README.mbt.md --target {js,wasm,wasm-gc,native} --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "The candidate surface is exactly five rootless packages with publication order separate from the quantize/profile-independent dependency DAG"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required#policy/interface/package classifiers"
        status: pass
    human_judgment: false
  - id: D3
    description: "All declared color prohibitions and provenance failures reject while two complete Required runs preserve the tracked tree"
    requirement: COLR-05
    verification:
      - kind: integration
        ref: "1..2 | ForEach-Object { ./scripts/quality.ps1 -Lane Required }"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 07: Rootless Color Contract Qualification Summary

**Five independently consumable color packages now have executable four-target contracts, a closed rootless DAG, and fail-closed reproducible qualification**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-16T19:04:16Z
- **Completed:** 2026-07-16T19:14:26Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Replaced scaffold prose with standalone examples for typed transfer, encoded-sRGB/alpha quantization, all normalized and encoded alpha directions, canonical zero, invalid premultiplied state, built-in sRGB, and caller-bounded opaque bytes.
- Removed the root package and scaffold, froze publication order as `model`, `transfer`, `quantize`, `alpha`, `profile`, and separately asserted every exact DAG edge including quantize and profile independence.
- Added generated-vector reproduction, source/README prohibitions, and synthetic topology, dependency, interface, publication, target, rounding, clamp, identity/default, ICC-parser, digest, and redistribution negatives.
- Passed two complete Required runs with 110/110 tests per target, exact five-package interfaces and contents, four-target README checks, and tracked read-only proof.

## Task Commits

1. **Task 1: Replace scaffold prose with executable public color contracts** - `b7bb1c1` (docs)
2. **Task 2: Remove the root scaffold and close the exact package boundary** - `2b1844e` (chore)
3. **Task 3: Add color negative fixtures and run final Required qualification** - `7e426de` (test)

## Files Created/Modified

- `modules/mb-color/README.mbt.md` - Standalone five-package examples, numerical/profile contract, evidence boundary, target matrix, release order, and exact DAG.
- `modules/mb-color/CHANGELOG.md` - Unreleased candidate package/vector/docs additions and explicit scaffold removal without a release claim.
- `policy/foundation.json` - Closed publication files and exactly five public package records without the root.
- `scripts/quality/Assert-Policy.ps1` - Exact mb-color package order, obsolete-root rejection, and separately named DAG assertions.
- `scripts/quality/Invoke-MoonQuality.ps1` - Color generator, prohibition, negative-fixture, README, and final qualification stages.
- `modules/mb-color/moon.pkg` - Removed obsolete private root package.
- `modules/mb-color/scaffold.mbt` - Removed obsolete Phase 1 source.
- `modules/mb-color/scaffold_wbtest.mbt` - Removed obsolete Phase 1 test.

## Decisions Made

- Publication order is metadata for release sequencing only; exact allowed imports remain a separate closed graph so quantize does not gain transfer and profile remains a core-only leaf.
- The root is absent rather than retained as a facade. Literate frontmatter makes all public dependencies explicit and independently consumable.
- README statements use the exhaustively measured 127-code nonzero straight round-trip maximum and distinguish opaque `icc` identity from ICC validation or conformance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed the planned root scaffold before Task 1 verification**
- **Found during:** Task 1 four-target README check
- **Issue:** While the old root `moon.pkg` existed, the pinned MoonBit toolchain treated `README.mbt.md` as that root package and did not load its explicit literate frontmatter imports, so every package alias was unresolved.
- **Fix:** Applied the already-planned Task 2 root/scaffold deletions in the working tree before running Task 1 verification, committed only the Task 1 documentation, then committed the deletions with Task 2 policy changes.
- **Files modified:** `modules/mb-color/moon.pkg`, `modules/mb-color/scaffold.mbt`, `modules/mb-color/scaffold_wbtest.mbt`
- **Verification:** README checks passed on js, wasm, wasm-gc, and native after root removal; both final Required runs passed.
- **Committed in:** `2b1844e`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** Only the working-tree order of two already-planned actions changed; commit boundaries, final architecture, tests, and scope remain exactly as planned.

## Issues Encountered

- A README overclaim detector initially matched the required negative phrase “no ... ICC conformance is claimed.” It was narrowed to reject only affirmative validation/conformance claims, then the full positive and negative matrix passed.

## User Setup Required

None - no external service, dependency, or manual configuration is required.

## Known Stubs

None. The only matched placeholder token is an existing governance validator that deliberately rejects placeholder approval evidence.

## Threat Flags

None. This plan removes deferred root surface and strengthens repository-local checks; it adds no network, host, file, authentication, or external schema boundary.

## Next Phase Readiness

- Phase 4 can import explicit color, transfer, alpha, and profile contracts without a root facade or order-implied dependency.
- COLR-01 through COLR-05 and D-13 through D-18 have four-target executable and fail-closed evidence.
- No blockers remain; Phase 3 is ready for independent verification.

## Self-Check: PASSED

- All five retained key files exist and all three planned root scaffold files are absent.
- Task commits `b7bb1c1`, `2b1844e`, and `7e426de` exist in history.
- Standalone README checks pass on js, wasm, wasm-gc, and native.
- Two complete Required runs pass with generated evidence byte identity, every declared negative rejection, 110/110 tests per target, exact 50/9/10/54/27 semantic interfaces, exact publication contents, and tracked read-only proof.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
