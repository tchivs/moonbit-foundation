---
status: awaiting_human_verify
trigger: "Phase 08-05 PublisherDryRun run 29652468948 failed at Set up exact MoonBit toolchain on protected tag modules-v0.1.0 before publisher execution."
created: 2026-07-18
updated: 2026-07-19T00:50:00+08:00
phase: "08"
plan: "05"
---

# Hosted Toolchain Setup Failure

## Symptoms

- expected: The immutable tagged workflow installs the exact pinned MoonBit toolchain, completes PublisherDryRun without mutation, and produces sanitized evidence for the authorization packet.
- actual: GitHub Actions run 29652468948 failed at `Set up exact MoonBit toolchain`; the publisher step was skipped and no dry-run/native/authorization evidence was produced.
- errors: Inspect the exact failed step logs from run 29652468948; do not infer the message from the conclusion alone.
- timeline: First live hosted attempt for Phase 08-05 on 2026-07-18. Local exact-HEAD Required passed at 198436a45b7403a3c28c98d5fa0d5ed6a958455f.
- reproduction: Dispatch `PublisherDryRun` against protected tag `modules-v0.1.0` bound to SHA `198436a45b7403a3c28c98d5fa0d5ed6a958455f` and observe the setup job.

## Current Focus

hypothesis: The committed workflow correction removes the inaccessible route and will fail closed unless the reachable channel still resolves to the pinned executable bytes and identities.
test: Human/GSD replanning must determine a forward-only immutable ref, then a separately authorized secret-free preflight must exercise the corrected hosted setup before any PublisherDryRun or publish gate.
expecting: A future hosted setup either succeeds with all exact digest/identity checks or stops at P08-TOOLCHAIN-BINARY-DIGEST/P08-TOOLCHAIN-IDENTITY without publisher execution.
next_action: Await GSD replanning and explicit authorization for a new immutable tag and secret-free preflight; do not move modules-v0.1.0 or dispatch any workflow from this debug session.
reasoning_checkpoint:
  hypothesis: The explicit historical artifact route causes setup failure because it returns HTTP 403 XML, and the action untars that response because curl is not run with `--fail`.
  confirming_evidence:
    - Run 29652468948 fetched the composite URL, received exactly 111 bytes, and immediately failed tar/gzip.
    - Bounded probes reproduce HTTP 403 application/xml at explicit composite/date paths while supported channel paths return HTTP 200 application/x-tar.
  falsification_test: An explicit pinned URL returning a valid archive, or a channel-based install failing the pinned executable identity/hash checks with the currently reported build, would disprove the correction mechanism.
  fix_rationale: Selecting the reachable channel removes the inaccessible route, while hardcoded executable hashes and version identities preserve fail-closed exactness if the moving channel changes.
  blind_spots: No hosted workflow will be dispatched in this session; local tests can validate workflow structure and current official metadata, but the corrected hosted run remains gated behind replanning and a new immutable tag/preflight decision.
tdd_checkpoint: Add a deterministic workflow/setup fixture that fails before the fix and passes after it.

## Evidence

- timestamp: 2026-07-18T00:00:00Z
  fact: Protected tag modules-v0.1.0 and origin/main were bound to 198436a45b7403a3c28c98d5fa0d5ed6a958455f at dispatch.
- timestamp: 2026-07-18T00:00:01Z
  fact: PublisherDryRun run 29652468948 attempt 1 concluded failure at Set up exact MoonBit toolchain; publisher step was skipped.
- timestamp: 2026-07-18T00:00:02Z
  fact: HostedPreflight and PublishOne were not dispatched; no non-dry moon publish occurred and no secret value was inspected or printed.
- timestamp: 2026-07-18T16:41:56Z
  fact: Sanitized failed-step log shows hustcer/setup-moonbit received version 0.1.20260713+75c7e1f and fetched https://cli.moonbitlang.com/binaries/0.1.20260713%2B75c7e1f/moonbit-linux-x86_64.tar.gz.
- timestamp: 2026-07-18T16:41:57Z
  fact: The download completed at exactly 111 bytes, then tar reported "This does not look like a tar archive" and gzip reported "stdin: not in gzip format"; setup exited 2.
- timestamp: 2026-07-18T16:41:59Z
  fact: Run metadata confirms prepare failed, while publisher_dry_run, hosted_preflight, publisher, observe_registry, and cold_consumer were all skipped.
- timestamp: 2026-07-19T00:08:00+08:00
  fact: The pinned setup action's nu/moonbit.nu accepts SemVer build metadata, percent-encodes `+`, constructs `/binaries/{version}/moonbit-{platform}.tar.gz`, invokes curl without fail-on-HTTP-error, and immediately untars the result.
- timestamp: 2026-07-19T00:09:00+08:00
  fact: MoonBit `version.json` reports moon `0.1.20260713 (75c7e1f 2026-07-13)`, moonc `v0.10.4+2cc641edf`, and moonrun `0.1.20260713 (75c7e1f 2026-07-13)`.
- timestamp: 2026-07-19T00:10:00+08:00
  fact: Bounded probes of both `/binaries/0.1.20260713%2B75c7e1f/...` and `/binaries/0.1.20260713/...` returned HTTP 403, application/xml, 111 bytes.
- timestamp: 2026-07-19T00:15:00+08:00
  fact: Bounded probes of `/binaries/latest/...`, `/binaries/pre-release/...`, and `/binaries/nightly/...` returned HTTP 200 application/x-tar; official installation documentation uses the latest route and publishes `.sha256` files.
- timestamp: 2026-07-19T00:16:00+08:00
  fact: Current official latest Linux archive SHA-256 is 31b7fc5cc78657964a6d545792ecd7fb8eed51b97c7431a17458b58734303381; executable hashes are moon 50913178bee7e904850fc37d5b16adda7e6c1616d2704994714b70ac86f9a7ab, moonc 31633647318a571d6aac9a2144a0e1ba3c946ea806d1409778894fe76e604511, and moonrun 44b7d5427837c8c0f7379a9d4fa9f3e1aac0f433041b3ffe16e78e1c5f151ab4.
- timestamp: 2026-07-19T00:23:00+08:00
  fact: New deterministic workflow fixture failed RED with P08-WORKFLOW-TOOLCHAIN-ROUTE against the unmodified explicit-version setup and missing post-install pin verification.
- timestamp: 2026-07-19T00:30:00+08:00
  fact: After correcting all five hosted setup sites, Test-Phase08LiveSeam.ps1 passed both live adapter and live workflow fixtures.
- timestamp: 2026-07-19T00:34:00+08:00
  fact: Test-Phase08Qualification.ps1 -FixtureOnly, Test-Phase07Qualification.ps1 -WorkflowOnly, Test-PreparedReleaseBundle.ps1 -WorkflowOnly, and git diff --check passed; actionlint is unavailable locally.
- timestamp: 2026-07-19T00:40:00+08:00
  fact: Direct download of the reachable latest Linux archive matched pinned archive SHA-256 31b7fc5cc78657964a6d545792ecd7fb8eed51b97c7431a17458b58734303381; the membership subcheck used an incorrect assumed `bin/` prefix and was rejected before extraction.
- timestamp: 2026-07-19T00:45:00+08:00
  fact: Repeated latest archive verification matched the pinned archive digest and confirmed members `./bin/moon`, `./bin/moonc`, and `./bin/moonrun`; the temporary archive was deleted.
- timestamp: 2026-07-19T00:49:00+08:00
  fact: Atomic commit 6fe0c1f contains exactly `.github/workflows/publish-modules.yml` and `scripts/quality/Test-Phase08LiveSeam.ps1`; protected tag modules-v0.1.0 remains unchanged at 198436a45b7403a3c28c98d5fa0d5ed6a958455f.

## Eliminated

- hypothesis: The failure was caused by Mooncakes publication or registry mutation.
  reason: Failure occurred before publisher execution; PublishOne and non-dry publish never ran.
- hypothesis: Removing `+75c7e1f` from the setup action input is sufficient to fix the hosted install.
  reason: The date-only artifact route returned the same HTTP 403 application/xml 111-byte response as the composite route.
- hypothesis: The Linux archive stores required executables directly under `bin/`.
  reason: Archive hash verification passed, but the literal `bin/moon` membership assertion failed; the real prefix must be observed rather than assumed.

## Resolution

root_cause: The pinned setup action constructed an explicit historical MoonBit artifact URL that the current distribution returns as HTTP 403 XML; because the action's curl lacks `--fail`, it saved the 111-byte error body and passed it to tar, causing setup to exit 2 before any publisher step.
fix: Changed all five publish workflow setup inputs to the reachable latest channel and added immediate fail-closed verification of pinned Linux moon/moonc/moonrun SHA-256 digests and exact version strings; added a deterministic regression fixture enforcing the route and pin checks.
verification: RED regression failed on the old route; GREEN live seam passed after correction. Phase 8 fixture/static contract, Phase 7 workflow/schema, prepared workflow selector, git diff --check, official archive digest, and required archive membership all passed. No hosted workflow was dispatched.
files_changed: [.github/workflows/publish-modules.yml, scripts/quality/Test-Phase08LiveSeam.ps1]
