---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "20"
subsystem: release-safety
tags: [canonical-zip, prepared-bundle, r8, provenance, cross-platform]

requires:
  - phase: 08-19
    provides: r8-only intent/prepared schemas and eight immutable terminal-negative histories
provides:
  - Deterministic canonical ZIP bytes with safe ordered paths, exact payloads, fixed Unix metadata, and stored compression
  - Three-module dual-checkout convergence and frozen extracted-source consumption proof
  - r8 prepared archives bound exactly to qualified intent module digests without in-place repair
  - Fresh r8 genesis enforcement with raw, recompressed, swapped, and prior-state variants rejected
affects: [08-21, DIST-01]

tech-stack:
  added: []
  patterns: [EOCD-bounded ZIP parsing, validate-copy-without-repair, archive-intent-manifest digest triangle]

key-files:
  created: []
  modified:
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Test-CrossPlatformReleaseArchive.ps1
    - scripts/quality/New-PreparedReleaseBundle.ps1
    - scripts/quality/Test-PreparedReleaseBundle.ps1
    - scripts/quality/Test-ReleaseQualificationNegative.ps1
    - scripts/quality/Test-Phase08Qualification.ps1

key-decisions:
  - "Canonical ZIP rewriting locates the exact central directory through EOCD rather than scanning payload bytes for header signatures."
  - "Prepared validation canonicalizes only a disposable copy and rejects the original unless its bytes are already canonical."
  - "r8 prepared identity requires start/genesis plus exact core-color-image archive agreement across intent, payload manifest, and bytes."
  - "DIST-01 remains pending because Plan 08-20 performs no tag, hosted dispatch, registry observation, credential access, mutation, or publication."

patterns-established:
  - "Canonical archive: safe relative forward-slash paths, original order, exact payload bytes, 1980-01-01 UTC, Unix made-by, 0644 files/0755 directories, stored entries."
  - "Prepared archive validation: verify recorded payload digest, canonicalize a temporary copy, then compare canonical digest to qualified intent."

requirements-completed: []

coverage:
  - id: D1
    description: "Canonical ZIP identity is host-independent while exact ordered source payload provenance and frozen three-module consumption remain intact."
    requirement: DIST-01
    verification:
      - kind: integration
        ref: "scripts/quality/Test-CrossPlatformReleaseArchive.ps1#three-module canonical convergence"
        status: pass
      - kind: integration
        ref: "scripts/quality/Invoke-ReleaseQualification.ps1 -Check"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fresh r8 prepared identity accepts only canonical archives matching the exact intent module order and archive digests."
    requirement: DIST-01
    verification:
      - kind: integration
        ref: "scripts/quality/Test-PreparedReleaseBundle.ps1#canonical archive binding"
        status: pass
      - kind: unit
        ref: "scripts/quality/Test-ReleaseQualificationNegative.ps1#REL-XPLAT negatives"
        status: pass
      - kind: integration
        ref: "scripts/quality/Test-Phase08Qualification.ps1#r8 contract"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-19
status: complete
---

# Phase 08 Plan 20: Canonical Archive and Prepared Qualification Summary

**r8 release identity now uses deterministic canonical ZIP bytes and rejects every prepared archive that is raw, recompressed, reordered, swapped, stale, or disconnected from its qualified intent digest.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-19T05:45:11Z
- **Completed:** 2026-07-19T05:59:37Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Hardened canonical ZIP generation around EOCD-bounded central-directory parsing, strict safe paths, payload preservation, fixed metadata, stored compression, and idempotent bytes.
- Proved all three module archives converge across opposing `core.autocrlf` clean clones and remain consumable as a frozen all-target modules-only workspace.
- Closed r8 prepared identity with canonical-only validation, exact `mb-core` → `mb-color` → `mb-image` intent ordering, archive/intent/manifest digest agreement, and fresh genesis-only semantics.
- Added fail-closed regressions for unsafe paths, metadata drift, archive swaps, noncanonical containers, and r8 resume reuse.

## Task Commits

1. **Task 1: Canonicalize ZIP container identity without changing ordered source payloads** — `7c3eb06` (RED), `14e47e5` (GREEN)
2. **Task 2: Bind canonical archive identity into fresh r8 prepared qualification** — `4ff089a` (RED), `ee55c3c` (GREEN)

## Files Created/Modified

- `scripts/quality/ReleaseQualification.Common.ps1` — strict canonicalizer plus non-mutating canonical archive assertion.
- `scripts/quality/Test-CrossPlatformReleaseArchive.ps1` — exact ZIP metadata, three-module dual-clone convergence, idempotence, and frozen consumption regression.
- `scripts/quality/New-PreparedReleaseBundle.ps1` — canonical archive and qualified intent binding with r8 start/genesis enforcement.
- `scripts/quality/Test-PreparedReleaseBundle.ps1` — real canonical ZIP fixtures and prepared adversarial matrix.
- `scripts/quality/Test-ReleaseQualificationNegative.ps1` — unsafe and noncanonical ZIP rule ownership.
- `scripts/quality/Test-Phase08Qualification.ps1` — static r8 prepared canonical contract gate.

`scripts/quality/Invoke-ReleaseQualification.ps1` and `.gitattributes` required no edit: the former already canonicalizes before digesting all three archives, while the latter already enforces `* text=auto eol=lf`; both invariants are exercised by the plan verification.

## Decisions Made

- Used the ZIP EOCD record as the sole authority for central-directory location/count/extent so payload bytes resembling ZIP signatures cannot be mistaken for metadata.
- Kept prepared source archives immutable during validation: a GUID-owned temporary copy is canonicalized and compared to the original digest.
- Preserved existing payload rule precedence by checking archive digest/size before canonical semantics while leaving journal and generic payload negatives under their original exact rule IDs.
- Kept DIST-01 pending because this plan is deliberately static and offline.

## Deviations from Plan

None - plan executed within the exact static eight-file boundary; two already-correct files were verified without unnecessary edits.

## Issues Encountered

- The first extracted-source fixture reused the repository `moon.work`, which also names example members absent from the archive-only tree. The regression now creates a modules-only workspace containing the three extracted canonical archives, matching the intended frozen source-consumption boundary.

## Known Stubs

None.

## Verification

- `Test-CrossPlatformReleaseArchive.ps1`: PASS with exact canonical digests `3342fee3...`, `c763c189...`, and `8150a1d0...`.
- `Invoke-ReleaseQualification.ps1 -Check`: PASS for policy plus all three canonical packages and their source consumers.
- `Test-PreparedReleaseBundle.ps1`: PASS for deterministic r8 generation and canonical/archive/intent negatives.
- `Test-ReleaseQualificationNegative.ps1`: PASS, including `REL-XPLAT-ENTRY` and `REL-XPLAT-NONCANONICAL`.
- `Test-Phase08Qualification.ps1`: PASS for r8 receipt/handoff and prepared canonical contract composition.
- `git diff --check`: PASS.
- Schema drift gate: PASS, no drift detected.
- Codebase drift gate: skipped because no structure map exists.
- UI safety gate: PASS, no UI files changed.

## Security and External-Effect Boundary

- Critical/high mitigations reject unsafe paths, payload/metadata ambiguity, noncanonical prepared bytes, archive substitution, and stale r7 state reuse.
- Execution was strictly offline: no push, tag, network request, hosted workflow, credential read, StateRoot, production handoff, registry operation, mutation, or publication occurred.

## TDD Gate Compliance

- Task 1 RED `7c3eb06` proved noncanonical dot/empty path segments were accepted; GREEN `14e47e5` closed the path and container invariants.
- Task 2 RED `4ff089a` proved a metadata-mutated archive could satisfy the old prepared validator after refreshing its manifest digest; GREEN `ee55c3c` rejects it before intent eligibility.

## Next Phase Readiness

- Plan 08-21 can consume the closed r8 canonical prepared contract when integrating publisher, workflow, hosted, and pre-live seams.
- DIST-01 remains pending until actual ordered publication and registry-only consumer evidence exist.

## Self-Check: PASSED

- All six modified files exist.
- All four RED/GREEN task commits exist in order.
- Full offline verification and all post-wave gates passed.
- Unrelated user dirt remains unstaged.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
