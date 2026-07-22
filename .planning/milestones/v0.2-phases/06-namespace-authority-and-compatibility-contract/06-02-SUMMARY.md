---
phase: 06-namespace-authority-and-compatibility-contract
plan: "02"
subsystem: compatibility
tags: [moonbit, mbti, baseline, reproducibility, sha256]
requires:
  - phase: 05-bounded-streaming-ppm-p6-codec-and-v0-1-validation
    provides: policy-owned 6+5+6 public package inventory
provides:
  - Closed public-interface baseline package schema
  - Two-clean-copy bounded `.mbti` generator and read-only check mode
  - Exact 17-package, 68-record v0.1.0 baseline inventory
  - Focused fail-closed positive and negative verification suite
affects: [06-03, 06-04, 06-05, compatibility-policy, release-qualification]
tech-stack:
  added: []
  patterns: [git-archive-clean-copy, atomic-utf8-no-bom, closed-manifest, lossless-line-normalization]
key-files:
  created:
    - compatibility/schema/baseline-schema.json
    - compatibility/baselines/0.1.0/manifest.json
    - scripts/quality/New-PublicInterfaceBaseline.ps1
    - scripts/quality/Test-PublicInterfaceBaseline.ps1
  modified: []
key-decisions:
  - "Store one canonical raw `.mbti` file per package and four target inspection records because the pinned `moon info` writes canonical preferred-backend text for every target inspection."
  - "Preserve declaration order and text losslessly after UTF-8/LF/trailing-whitespace normalization; unknown grammar fails closed instead of being discarded."
  - "Bind generated evidence to the pre-baseline source commit so the committed evidence can be reproduced from two independent clean archives."
patterns-established:
  - "Generated evidence owns exact relative paths and SHA-256 digests through one closed manifest."
  - "Check mode regenerates from the recorded source commit and compares byte-level tree digest maps without tracked writes."
requirements-completed: [COMP-01]
duration: 24m
completed: 2026-07-17
---

# Phase 6 Plan 02: Public Interface Baseline Summary

**A reproducible, bounded public-interface text baseline now covers exactly 17 policy-owned packages across js, wasm, wasm-gc, and native.**

## Performance

- **Duration:** 24m
- **Tasks:** 2
- **Files generated:** 103 baseline files plus schema, generator, and test suite

## Accomplishments

- Defined a closed JSON Schema for raw evidence, pinned toolchain identity, normalized target records, target inspection outcomes, and two-run equality.
- Implemented clean-copy generation from guarded `git archive` snapshots with exact toolchain validation, bounded current `.mbti` grammar, path sanitization, atomic UTF-8-without-BOM writes, and read-only check mode.
- Materialized 17 package baselines with 68 unique package-target records and exact manifest-owned file and digest inventories.
- Proved fail-closed behavior for 67/69 records, duplicate or missing package-target pairs, unknown syntax, target divergence, toolchain mismatch, unstable second run, digest drift, partial output, and tracked mutation.

## Task Commits

1. **Task 1: Define the bounded baseline schema and generator** - `935e744`
2. **Task 2: Materialize and prove exactly 68 mechanical records** - `c0a31fd`

## Files Created/Modified

- `compatibility/schema/baseline-schema.json` - Closed baseline package and target record contract.
- `scripts/quality/New-PublicInterfaceBaseline.ps1` - Two-clean-copy generator, validator, and check mode.
- `compatibility/baselines/0.1.0/manifest.json` - Exact 17-package/68-record authoritative inventory.
- `compatibility/baselines/0.1.0/mb-core`, `mb-color`, `mb-image` - Canonical raw evidence, normalized target text, and package records.
- `scripts/quality/Test-PublicInterfaceBaseline.ps1` - Positive and exact negative verification matrix.

## Decisions Made

- Baselines assert public-interface text stability only; they explicitly make no behavioral, semantic, resource, layout, or performance compatibility claim.
- Target inspections must reproduce the canonical raw digest. Any divergence is unknown and stops generation.
- Normalization does not sort declarations or erase syntax. This preserves ordering and overload adjacency for later comparator policy.

## Deviations from Plan

None. Implementation debugging corrected clean-archive creation and policy-order preservation before the task commits were finalized.

## Issues Encountered

- PowerShell initially returned the package inventory as one nested array and `Group-Object` reordered modules alphabetically. Both were corrected so generation follows the exact policy order `mb-core`, `mb-color`, `mb-image`.

## Verification

- `New-PublicInterfaceBaseline.ps1 -CheckSchema` passed.
- `Test-PublicInterfaceBaseline.ps1` passed all positive and negative cases.
- A separate `New-PublicInterfaceBaseline.ps1 -Check` passed with two independent clean generations and byte-identical output.
- Tracked checkout snapshots were identical before and after check mode.

## Next Phase Readiness

- The exact mechanical baseline is ready for Plan 06-03 comparator and compatibility policy work.
- Flagged manual review assumptions for adjacency, empty interfaces, encoding, and ordering remain visible in the phase plan and were not silently reclassified.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
