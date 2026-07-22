---
name: fix-github-actions-ci
status: complete
completed: 2026-07-19
---

# Summary

Updated the hosted workflows so jobs use the reachable base MoonBit release URL `0.1.20260713`, avoiding the hosted 403 for the `+75c7e1f` URL. Every setup still enforces the exact pinned `moon`, `moonc`, and `moonrun` versions and SHA-256 digests, preventing `latest` drift.

## Verification

- `Test-Phase08LiveSeam.ps1`: passed.
- `Test-ReleaseIntent.ps1`: passed.
- `Test-PreparedReleaseBundle.ps1`: passed.
- `Test-Phase08LiveSeam.ps1`: passed again after synchronizing all five publisher setup points.
- `moon check`: passed.
- `Test-Phase08Qualification.ps1`: blocked by the pre-existing missing r9 prepared contract.
- Full local Required lane: reached the pre-existing source-mutation guard; Windows PowerShell line-ending normalization modified tracked source during the test harness.

## Residual

The workflow must be pushed and rerun on GitHub to verify hosted toolchain download. The old r7 publisher `release_ref` failure is historical; the current workflow and r12 contracts already use the canonical r12 reference.
