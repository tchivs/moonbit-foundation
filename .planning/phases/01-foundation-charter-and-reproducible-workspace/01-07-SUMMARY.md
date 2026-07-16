---
phase: 01-foundation-charter-and-reproducible-workspace
plan: "07"
subsystem: quality-automation
tags: [powershell, moonbit, policy-validation, github-actions, supply-chain]

requires:
  - phase: 01-foundation-charter-and-reproducible-workspace/01-02
    provides: Exact toolchain, foundation policy, fixture manifest, and Phase 1 source audit
  - phase: 01-foundation-charter-and-reproducible-workspace/01-03
    provides: Three-member workspace, independent manifests, target metadata, and dependency DAG
  - phase: 01-foundation-charter-and-reproducible-workspace/01-04..01-06
    provides: Warning-free private module scaffolds, checked docs, and exact empty generated interfaces
provides:
  - Fail-closed exact toolchain, foundation-policy, and Phase 1 source-audit validators
  - Sole root Required and LlvmExperimental quality controller with contextual fixed stages
  - Pinned read-only GitHub Actions workflow with blocking Required and non-blocking LLVM jobs
affects: [phase-verification, continuous-integration, release-qualification, all-module-development]

tech-stack:
  added: [PowerShell 7 quality automation, GitHub Actions]
  patterns:
    - Structured JSON is validation data only and never becomes executable text
    - Required targets are checked and tested explicitly rather than inferred from target all
    - Generated interfaces and package lists use exact semantic allowlists
    - Experimental LLVM evidence is isolated from required support

key-files:
  created:
    - scripts/quality/Assert-Toolchain.ps1
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
    - scripts/quality.ps1
    - .github/workflows/quality.yml
  modified:
    - modules/mb-core/scaffold.mbt
    - modules/mb-core/scaffold_wbtest.mbt
    - modules/mb-color/scaffold.mbt
    - modules/mb-color/scaffold_wbtest.mbt
    - modules/mb-image/scaffold.mbt
    - modules/mb-image/scaffold_wbtest.mbt

key-decisions:
  - "Keep moon.mod.json as the locked compatibility floor by running moon fmt --check over the complete discovered MoonBit source inventory, excluding the formatter's unconditional manifest migration proposal."
  - "Run moon doc once per fixed workspace member because the pinned CLI cannot infer a module from the workspace root."
  - "Compare the tracked diff before and after Required execution so the gate proves it introduced no tracked mutations without interfering with unrelated pre-existing work."
  - "Pin both checkout and MoonBit setup actions to full commit SHAs and disable persisted checkout credentials."

patterns-established:
  - "Fail-closed source audit: exact hard-coded ID sets, counts, uniqueness, no extras, non-empty mappings, and covered status are one Required-lane gate."
  - "Contextual stage runner: every failure reports stage plus member or target while commands stay fixed and JSON remains non-executable."
  - "Support isolation: only js, wasm, wasm-gc, and native determine Required success; LLVM has an independent visible lane and non-blocking CI job."

requirements-completed: [WORK-02, WORK-03, WORK-04, WORK-05, GOV-02, GOV-03, GOV-04]

coverage:
  - id: D1
    description: "PowerShell 7 validators compare exact moon, moonc, and moonrun identities and fail closed on foundation policy or Phase 1 source inventory drift, including exact 1/9/16/29/17/5 counts."
    requirement: WORK-02
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -Command '. ./scripts/quality/Assert-Toolchain.ps1; . ./scripts/quality/Assert-Policy.ps1; Assert-Toolchain ...; Assert-FoundationPolicy ...; Assert-PhaseSourceAudit ...'"
        status: pass
    human_judgment: false
  - id: D2
    description: "One root Required command proves formatting, four explicit check/test targets, documentation, exact generated interfaces, package allowlists, policy/DAG/source coverage, and no tracked mutation."
    requirement: WORK-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
  - id: D3
    description: "LLVM remains an isolated visible experiment and cannot affect the four-target Required result."
    requirement: WORK-05
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane LlvmExperimental"
        status: pass
      - kind: other
        ref: ".github/workflows/quality.yml#llvm-experimental continue-on-error true"
        status: pass
    human_judgment: false
  - id: D4
    description: "Push and pull-request CI is read-only, credential-free for publication, and immutable at every external action reference."
    requirement: GOV-04
    verification:
      - kind: other
        ref: "Static CI assertions for exact action/toolchain pins, read-only permissions, no token pattern, and 40-hex action refs"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-16
status: complete
---

# Phase 01 Plan 07: Deterministic Quality and CI Contract Summary

**A single PowerShell 7 controller now proves the exact toolchain, policy and source inventory, four-target workspace behavior, interfaces, packages, and read-only CI while keeping LLVM visibly non-blocking.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-16T08:16:36Z
- **Completed:** 2026-07-16T08:22:00Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Added exact three-binary identity validation and structured foundation-policy checks spanning RFC evidence, workspace members, manifests, package targets, fixtures, publication block, and an acyclic allowed dependency DAG.
- Added exact source-audit enforcement for 1 goal, 9 requirements, 16 decisions, 29 research items, 17 edges, and 5 prohibitions, rejecting duplicates, extras, empty mappings, and non-covered status.
- Added one Required lane covering format, four explicit target check/test pairs, per-module docs and generated interfaces, package allowlists, and tracked-diff immutability, plus a separate experimental LLVM lane.
- Added a credential-minimized GitHub Actions workflow with full-SHA-pinned checkout/setup actions, blocking Required behavior, and non-blocking LLVM behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build exact-toolchain, policy, and source-audit validators** - `f6fcd1a` (feat)
2. **Task 2: Orchestrate required and LLVM quality lanes** - `041b8c3` (feat)
3. **Task 3: Run the identical quality contract in pinned read-only CI** - `6d724f6` (ci)

## Files Created/Modified

- `scripts/quality/Assert-Toolchain.ps1` - PowerShell 7 and exact normalized three-binary identity gate.
- `scripts/quality/Assert-Policy.ps1` - Foundation policy, RFC, fixture, workspace, target, DAG, and exact Phase 1 source-audit validators.
- `scripts/quality/Invoke-MoonQuality.ps1` - Contextual fixed-stage Required and LlvmExperimental orchestration.
- `scripts/quality.ps1` - Sole public root quality controller.
- `.github/workflows/quality.yml` - Immutable read-only push/PR workflow with blocking Required and non-blocking LLVM jobs.
- `modules/mb-{core,color,image}/scaffold*.mbt` - Current pinned formatter section markers for all six existing MoonBit source/test files.

## Decisions Made

- Kept all JSON-derived values inside validation and path reads; no JSON value is dispatched as a command, argument vector, or script text.
- Used exact hard-coded module, target, source-ID, semantic-interface, and package-content inventories at trust boundaries.
- Scoped formatting to the complete recursively discovered MoonBit source set because unscoped `moon fmt --check` proposes the explicitly deferred `moon.mod.json` to `moon.mod` migration.
- Ran docs per module because the pinned CLI rejects root workspace `moon doc` without a target member.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Preserve the locked manifest format while retaining a real format gate**

- **Found during:** Task 2 Required-lane verification.
- **Issue:** On the pinned compatibility-floor toolchain, unscoped `moon fmt --check` always compares every `moon.mod.json` with a generated `moon.mod` and fails by proposing migration, contradicting the locked decision to defer `moon.mod` adoption. The six existing scaffold files also lacked the formatter's current `///|` section marker.
- **Fix:** Added the formatter-required section markers and passed every recursively discovered `.mbt`/`.mbt.md` source path to the fixed `moon fmt --check` command, preserving full source coverage without touching manifests.
- **Files modified:** Six `modules/mb-*/scaffold*.mbt` files and `scripts/quality/Invoke-MoonQuality.ps1`.
- **Verification:** Required format stage and complete Required lane pass; manifests remain `moon.mod.json`; tracked diff is unchanged by lane execution.
- **Committed in:** `041b8c3`.

**2. [Rule 3 - Blocking] Execute documentation generation in each fixed workspace member**

- **Found during:** Task 2 Required-lane verification.
- **Issue:** The pinned CLI reports that `moon doc` cannot infer a target module at a workspace root.
- **Fix:** Kept the stage in its required position and invoked fixed `moon -C modules/<member> doc --frozen` commands for all three hard-coded members before each info/classifier stage.
- **Files modified:** `scripts/quality/Invoke-MoonQuality.ps1`.
- **Verification:** Docs pass for mb-core, mb-color, and mb-image; the subsequent exact interface classifiers and full Required lane pass.
- **Committed in:** `041b8c3`.

---

**Total deviations:** 2 auto-fixed (2 blocking issues).
**Impact on plan:** Both adaptations are required by the exact pinned CLI and preserve the locked compatibility floor, deterministic coverage, stage ordering, and fail-closed behavior without expanding architecture.

## Issues Encountered

- Initial implementation iterations exposed PowerShell strict-mode array and interpolation edge cases; these were corrected before the relevant task commits and the final validators run with `$ErrorActionPreference = 'Stop'` through the root controller.

## User Setup Required

None - no external services or publication credentials are required.

## Next Phase Readiness

- Phase 1 has one deterministic local and CI Required command for all current governance, workspace, target, interface, package, and source-coverage evidence.
- Future modules or public packages must deliberately extend the hard-coded policy, interface, package, and source inventories; silent additions fail closed.
- LLVM can continue gathering experimental evidence without changing supported-target claims or blocking required work.

## Self-Check: PASSED

- Task commits `f6fcd1a`, `041b8c3`, and `6d724f6` exist in order.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passes all fixed stages, all four target test runs (3/3 each), three exact interface classifiers, three exact package allowlists, and tracked-diff immutability.
- Static CI verification confirms exact setup/toolchain pins, both lanes, `continue-on-error: true`, read-only permissions, no publication-token pattern, and full 40-hex action references.
- Forbidden-command scan finds neither `Invoke-Expression` nor `moon work sync` in scripts or workflow.
- Only the pre-existing untracked `.codebase-memory/` and `.planning/research/.cache/` directories remain; neither was modified or committed.

---
*Phase: 01-foundation-charter-and-reproducible-workspace*
*Completed: 2026-07-16*
