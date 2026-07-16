# Toolchain Policy

## Status and confidence

The v0.1 development baseline is exact and reproducible. Exact binary versions, commits, and release dates are owned by [`policy/foundation.json`](../../policy/foundation.json); the table below identifies how each canonical entry is used without creating an independently editable version source.

| Component | Canonical policy key | Enforcement |
|---|---|---|
| `moon` | `toolchain.moon` | Exact CI installation and local version gate |
| `moonc` | `toolchain.moonc` | Exact bundled compiler identity recorded in CI logs |
| `moonrun` | `toolchain.moonrun` | Exact bundled runtime identity recorded in CI logs |

Confidence is high for current build, test, and target mechanics. A permanent minimum supported version remains deliberately undecided until a release candidate is tested.

## Reproducibility rules

- CI installs the exact canonical `moon` build; it does not follow `latest`.
- Quality validation compares normalized output from all three binaries with the canonical policy and fails closed on drift.
- `moon.mod.json` is the v0.1 manifest format while the newer `moon.mod` rollout remains transitional.
- Dependency resolution and quality commands use frozen state. Validation never runs `moon work sync`, because synchronization mutates manifests and could hide drift.
- Required checks cover the target set owned by the canonical policy. LLVM, when exercised, runs only in a separate non-blocking experimental lane.

## Compatibility floor

This baseline is a reproducible development pin, not a permanent public compatibility floor. Declaring a minimum supported toolchain requires release-candidate evidence and a policy update reviewed with the same care as other public compatibility promises.
