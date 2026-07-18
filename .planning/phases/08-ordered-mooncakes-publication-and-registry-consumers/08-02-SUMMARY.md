---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "02"
subsystem: registry-observation
tags: [mooncakes, registry, observation, provenance, powershell, json-schema]
dependency_graph:
  requires: [08-01-prepared-bundle]
  provides: [closed-distribution-policy, sanitized-registry-observation, bounded-polling-classification]
  affects: [08-03-cold-registry-consumers, 08-04-live-seam, 08-06-ordered-publication]
tech_stack:
  added: []
  patterns: [closed-json-schema, fixture-driven-trust-boundary, content-addressed-output, fail-closed-observation]
key_files:
  created:
    - policy/phase-08-distribution.json
    - release/registry/module-observation-schema.json
    - scripts/quality/Get-MooncakesObservation.ps1
    - scripts/quality/Test-MooncakesObservation.ps1
  modified: []
key_decisions:
  - "Bound registry propagation observation to 20 attempts at a fixed 15-second cadence."
  - "Accept only structured caller-supplied surface records and persist only the closed sanitized projection."
  - "Treat every missing, weak, ambiguous, secret-shaped, or disagreeing fact as non-mutating unknown or mismatch evidence."
requirements_completed: []
metrics:
  duration: 15min
  completed: 2026-07-18
  tasks: 2
  files: 4
status: complete
---

# Phase 8 Plan 2: Closed Mooncakes Observation Summary

Credential-free Mooncakes observation now reduces untrusted structured surfaces to one schema-valid, content-addressed exact/absent/mismatch/unknown result without exposing raw responses or mutation authority.

## Performance

- **Duration:** 15 minutes
- **Started:** 2026-07-18T10:12:35Z
- **Completed:** 2026-07-18T10:27:41Z
- **Tasks:** 2
- **Files created:** 4

## Accomplishments

- Defined the exact core-color-image publication graph, qualified metadata and documentation digests, registry-only dependency source, structured surfaces, and terminal failure policy.
- Added a recursively closed JSON Schema for sanitized public observations with a hard `mutation_authorized: false` invariant.
- Implemented atomic observation output that validates field shape, redacts secret-shaped input, compares metadata/packages/dependencies/checksums/assets exactly, and classifies bounded polling without contacting or mutating Mooncakes.
- Added deterministic agreement, adjacent-version, empty, drift, ambiguity, reordering, checksum, redaction, and timeout fixtures.

## Task Commits

1. **RED: Add failing Mooncakes observation contract** - `b895ebc`
2. **GREEN: Define closed Mooncakes observation policy** - `4e8ed99`
3. **Implement bounded structured public observation** - `09f3fcf`

## Files Created

- `policy/phase-08-distribution.json` - Exact module graph, metadata, surfaces, polling bounds, redaction, and dispositions.
- `release/registry/module-observation-schema.json` - Closed sanitized observation contract.
- `scripts/quality/Get-MooncakesObservation.ps1` - Fixture-driven structured observer and atomic content-addressed writer.
- `scripts/quality/Test-MooncakesObservation.ps1` - Schema-only and full adversarial selector.

## Decisions Made

- Fixed propagation polling at 15-second intervals with a 20-attempt ceiling; reaching the bound while absent yields `timeout_unknown`, never retry authority.
- Required SHA-256 registry identity to agree with the archive digest; weaker identities are `unknown`, while conflicting strong identities are mismatch incidents.
- Kept the autonomous implementation fixture-driven. Later hosted workflows may collect credential-free structured responses, but this plan performs no live request, credential access, tag operation, workflow dispatch, or publication.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- RED commit `b895ebc` failed because `policy/phase-08-distribution.json` did not yet exist.
- GREEN commit `4e8ed99` made the schema-only selector pass.
- Task 2 commit `09f3fcf` made the full fixture suite pass.

## Verification

- `pwsh -NoProfile -File scripts/quality/Test-MooncakesObservation.ps1 -SchemaOnly` - PASS
- `pwsh -NoProfile -File scripts/quality/Test-MooncakesObservation.ps1` - PASS
- Stub scan across all four owned artifacts - PASS, no placeholders or incomplete implementation markers.
- `git diff --check` - PASS

## Known Stubs

None.

## Next Phase Readiness

- Plan 08-03 can consume the closed observer from a disposable cold registry consumer and bind its exact resolved graph and artifact identity into proof output.
- Plan 08-04 can wire hosted structured surface collection to this observer without granting the observer credentials or mutation authority.

## Self-Check: PASSED

- All four declared artifacts exist.
- Commits `b895ebc`, `4e8ed99`, and `09f3fcf` exist in git history.
- Both plan verification commands pass at the final source state.
