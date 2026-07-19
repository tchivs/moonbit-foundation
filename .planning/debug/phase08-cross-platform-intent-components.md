---
status: awaiting_human_verify
trigger: "Phase 8 r7 HostedPreflight run 29673849108/1 produced a hosted intent digest different from the LF-stable local prepared intent."
created: 2026-07-19
updated: 2026-07-19
---

# Debug Session: Phase 8 Cross-Platform Intent Components

## Symptoms

- Expected: Local Windows and hosted Linux qualification produce the same release intent after the repository LF contract.
- Actual: local intent `04538fed...` differs from hosted intent `e590e278...`.
- Error: `P08-PREPARED-INTENT-BINDING` in run `29673849108/1`, prepare job `88157456895`.

## Known External State

- r7 immutable boundary: `195e08dc1f3a1dc561d98cc660af679926ae0198`
- r7 tag object: `52a47cda33492fa490178ab195ecdca50b1cf382`
- registry observation: `confirmed_absent`
- all downstream jobs, artifacts, secret access, packet, receipt, handoff, PublishOne, and mutation: zero
- Forbidden: push, tag, dispatch, secret, StateRoot, registry/publication, moving r7, or planning r8.

## Current Focus

- hypothesis: A remaining platform-dependent archive or intent component differs after source EOL normalization.
- test: Compare component-level local evidence with read-only hosted logs and reproduce the first differing component.
- expecting: A minimal deterministic fix makes the same tracked source produce identical intent components on Windows and Linux.
- next_action: Re-run a new immutable hosted preflight from the owning live workflow and verify its canonical archive and intent digests match the committed local preparation; do not retry or move r7.
- reasoning_checkpoint:
    hypothesis: "Moon package preserves payload bytes but emits host/runtime-dependent ZIP container bytes, so raw archive SHA-256 changes even after LF checkout normalization."
    confirming_evidence:
      - "Hosted and local archive SHA-256 values differ for all three modules while their byte lengths are exactly equal: 37794, 26454, and 68181."
      - "The first serialized intent difference is each modules[*].archive_sha256; source, toolchain, interface, and policy identities remain stable."
      - "The prior cross-platform regression ran both packaging paths on Windows and varied only core.autocrlf, so it could not exercise OS/runtime ZIP encoding."
    falsification_test: "Semantically identical ZIPs with deliberately different host metadata must canonicalize to identical bytes without changing entry order, paths, payload SHA/length, or extractability; otherwise container identity is not the sufficient cause."
    fix_rationale: "Rebuild the qualified archive in original entry order with fixed timestamp, Unix made-by/permissions, and stored compression before any archive digest enters the intent."
    blind_spots: "The immutable r7 hosted run cannot be retroactively changed and no new hosted run was dispatched during debug; live Linux confirmation remains external verification."
- tdd_checkpoint:
    test_file: "scripts/quality/Test-CrossPlatformReleaseArchive.ps1"
    test_name: "canonical ZIP component identity and provenance"
    status: green
    failure_output: "RED exited 1 with REL-XPLAT-CANONICALIZER because no deterministic container canonicalizer existed; GREEN canonical SHA-256 is 3342fee3e4876ef242b73bfd91e7e00178fd02a3d1959a387f43ac17fd77508a."

## Evidence

- timestamp: 2026-07-19
  checked: immutable r7 hosted preflight
  found: Hosted prepare produced `e590e278...` while the local prepared intent is `04538fed...`; no downstream effect occurred.
  implication: Diagnose component identity without retrying or mutating external state.
- timestamp: 2026-07-19
  checked: read-only GitHub job 88157456895 logs and local r7 prepared intent
  found: Hosted archive digests are core `34c3f6b6...`, color `b3d6c159...`, image `782696ab...`; local digests are `8029970a...`, `9c672c24...`, `bcec6a9d...`. Corresponding archive sizes are exactly equal on both hosts: 37794, 26454, and 68181 bytes.
  implication: `modules[*].archive_sha256` is the first intent-component divergence; equal sizes after LF normalization point to ZIP container/runtime encoding rather than source payload inventory.
- timestamp: 2026-07-19
  checked: existing cross-platform regression
  found: Both opposing checkout policies were packaged on the same Windows runtime, so the test proved EOL stability but not Windows/Linux ZIP-container identity.
  implication: Add a semantic-equivalence/raw-container-difference fixture and canonicalize before qualification hashes archives.
- timestamp: 2026-07-19
  checked: TDD RED and canonical ZIP GREEN
  found: RED failed with `REL-XPLAT-CANONICALIZER`; GREEN converged deliberately different host-metadata variants to `3342fee3...`, preserved exact entry order/path/payload SHA and length, used deterministic stored compression, was idempotent, extracted successfully, and passed frozen all-target Moon checking.
  implication: The canonical archive remains valid source for the existing extract-then-`moon publish --frozen` path while its identity is independent of original container encoding.
- timestamp: 2026-07-19
  checked: complete adjacent suite matrix
  found: PreparedReleaseBundle, ReleaseQualification positive and negative, Phase08Qualification, CrossPlatformReleaseArchive, ReleasePublisherNegative, Phase08LiveSeam, MooncakesObservation, and `git diff --check` all passed.
  implication: Prepared inventory, provenance, intent/receipt, publisher, live seam, observation, and fail-closed rules remain intact.
- timestamp: 2026-07-19
  checked: full committed-HEAD three-module release qualification after the fix
  found: All three canonical packages passed list/hash/bytes/archive/manifest with core `3342fee3...` (125855 bytes), color `c763c189...` (89069 bytes), and image `8150a1d0...` (248379 bytes). Qualification then stopped at `REL01-REF-TARGET` because immutable r7 intentionally still peels to its historical failed source rather than the new fix commit.
  implication: Production canonicalization works for every module; a fresh future boundary is required for hosted verification, and this debug must not move r7.

## Resolution

- root_cause: The previous LF fix stabilized entry payload bytes but the release intent still hashed raw `moon package` ZIP containers whose host/runtime encoding differs between Windows and Linux; the existing regression never crossed operating systems.
- fix: Canonicalize each qualified ZIP before evidence hashing by preserving exact entry order, paths, and payload bytes while fixing timestamps, ZIP made-by/permissions, and stored compression; add a semantic-equal/raw-different container regression with idempotence and frozen Moon source-consumption proof.
- verification: Component comparison isolated all three archive digests as the first drift. RED reproduced the missing invariant; GREEN converged container variants to `3342fee3...`. All requested prepared, qualification, cross-platform, publisher, live-seam, observation, and diff suites passed; full qualification canonicalized all three modules before correctly rejecting the historical r7 ref at the new HEAD. Real hosted confirmation remains pending and no external state changed.
- files_changed: [scripts/quality/ReleaseQualification.Common.ps1, scripts/quality/Invoke-ReleaseQualification.ps1, scripts/quality/Test-CrossPlatformReleaseArchive.ps1, .planning/debug/phase08-cross-platform-intent-components.md]
