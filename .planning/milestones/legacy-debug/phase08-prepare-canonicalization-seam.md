---
status: awaiting_human_verify
trigger: "Phase 8 r8 PrepareAttempt rejected raw Moon package archives as non-canonical after the canonical ZIP validator was introduced."
created: 2026-07-19
updated: 2026-07-19T00:00:00Z
---

# Debug Session: Phase 8 Prepare Canonicalization Seam

## Symptoms

- Expected: PrepareAttempt derives canonical ZIP archives before prepared-bundle validation and binds their digests consistently.
- Actual: `New-PreparedReleaseBundle` rejects the raw `mb-core.zip` with `PREP15-CANONICAL-ARCHIVE / REL-XPLAT-NONCANONICAL`.
- Reproduction: Run PrepareAttempt from the immutable r8 clean boundary.

## Known External State

- r8 immutable source: `8d0f050a2ea2a5f136d87f913987d59ea99a13d4`
- r8 tag object: `20907c7bbd11b91d4482dd113d149b3a107c9672`
- no live locator, active attempt, packet, receipt, handoff, hosted run, secret access, or mutation exists.
- Forbidden: push, tag, network, secret, StateRoot, registry/publication, moving r8, or planning r9.

## Current Focus

- hypothesis: Confirmed — production PrepareAttempt copied raw Moon package ZIP bytes directly into the prepared input root, although qualification and intent already bind canonical ZIP digests.
- test: The actual PrepareAttempt fixture supplies valid noncanonical ZIPs, asserts their original bytes remain unchanged, computes intent digests from derived canonical copies, and validates the resulting prepared bundle.
- expecting: Canonicalization occurs only in the temporary derived prepared path; prepared manifest and intent bind the same canonical archive digest.
- next_action: Rerun from a newly committed clean r8 boundary before any hosted step; this session forbids external operations.

## Evidence

- timestamp: 2026-07-19
  checked: r8 PrepareAttempt
  found: `mb-core` raw prepared archive failed canonical validation before a live locator or hosted dispatch was created.
  implication: Repair only the local production archive handoff; r8 remains terminal and immutable.
- timestamp: 2026-07-19T00:00:00Z
  checked: `Invoke-Phase08HostedRun.ps1` PrepareAttempt archive handoff.
  found: Each raw archive was copied directly into `prepared-input/archives`, then `New-PreparedReleaseBundle` correctly rejected the noncanonical container bytes with `PREP15-CANONICAL-ARCHIVE`.
  implication: The defect is the production handoff seam, not the canonical ZIP validator or the qualified canonical intent digest.
- timestamp: 2026-07-19T00:00:01Z
  checked: RED/GREEN PrepareAttempt integration fixture and adjacent local suites.
  found: The fixture proves raw valid ZIPs fail canonical assertion, preserves their source digest while creating canonical derived copies, and passes a real r8 PrepareAttempt whose prepared bundle validates. Cross-platform archive, prepared-bundle, qualification, publisher negative, live-seam, and Mooncakes-observation suites all pass.
  implication: Canonical prepared bytes are consistently bound to the qualified intent and manifest without mutation, hosted dispatch, secret access, or registry action.

## Resolution

root_cause: `New-P08PreparedAttempt` handed raw Moon package ZIP containers to `New-PreparedReleaseBundle`, while that builder correctly requires canonical archive bytes that match the intent digests produced by qualification.
fix: Added a narrow copy-then-canonicalize helper that operates only on temporary prepared-input copies, verifies original source archive provenance is unchanged, and feeds the derived canonical ZIPs to the existing prepared-bundle builder; upgraded the actual PrepareAttempt fixture to r8 and raw valid ZIP coverage.
verification: `Test-Phase08Qualification.ps1 -R8ContractOnly`, `Test-CrossPlatformReleaseArchive.ps1`, `Test-PreparedReleaseBundle.ps1`, `Test-Phase08Qualification.ps1`, `Test-ReleasePublisherNegative.ps1`, `Test-Phase08LiveSeam.ps1`, `Test-MooncakesObservation.ps1`, and `git diff --check` pass locally.
files_changed: [scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/Test-Phase08Qualification.ps1, .planning/debug/phase08-prepare-canonicalization-seam.md]
