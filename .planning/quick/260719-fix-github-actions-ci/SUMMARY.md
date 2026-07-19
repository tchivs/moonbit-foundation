---
name: fix-github-actions-ci
status: complete
completed: 2026-07-19
---

# Summary

Updated `.github/workflows/quality.yml` so hosted jobs resolve the reachable MoonBit `latest` channel and then enforce the exact pinned `moon`, `moonc`, and `moonrun` versions and SHA-256 digests. This avoids the hosted 403 for the suffixed version URL while retaining reproducible toolchain identity checks.

## Verification

- `Test-Phase08LiveSeam.ps1`: passed.
- `Test-ReleaseIntent.ps1`: passed.
- `Test-PreparedReleaseBundle.ps1`: passed.
- `moon check`: passed.
- `Test-Phase08Qualification.ps1`: blocked by the pre-existing missing r9 prepared contract.
- Full local Required lane: reached the pre-existing source-mutation guard; Windows PowerShell line-ending normalization modified tracked source during the test harness.

## Residual

The workflow must be pushed and rerun on GitHub to verify hosted toolchain download. The old r7 publisher `release_ref` failure is historical; the current workflow and r12 contracts already use the canonical r12 reference.
