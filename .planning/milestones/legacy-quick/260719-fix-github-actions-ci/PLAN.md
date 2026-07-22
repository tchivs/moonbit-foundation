---
name: fix-github-actions-ci
created: 2026-07-19
---

# Fix GitHub Actions CI

## Objective

Repair the failing GitHub Actions quality and publication workflows without changing the three MoonBit module implementations.

## Scope

- Make exact MoonBit toolchain setup reliable in hosted jobs while retaining identity verification.
- Correct the prepared-release `release_ref` binding failure observed in the hosted publisher run.
- Run the relevant local quality checks and record residual external verification needs.

## Verification

- Workflow static contract tests pass locally.
- Release intent and prepared-bundle tests pass locally.
- `moon check` remains green for the workspace.
- GitHub Actions rerun is required for hosted toolchain and registry behavior.
