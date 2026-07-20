# Phase 12: Strict PPM End-to-End Filter Coverage - Discussion Log

> **Audit trail only.** Decisions are captured in CONTEXT.md.

**Date:** 2026-07-20
**Areas discussed:** E2E path coverage, evidence strength, scope containment

## E2E path coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Separate API checks | Leaves PPM integration partial | |
| One strict PPM E2E vector | Proves crop/rotate/filter behavior through the real codec path | ✓ |

## Evidence strength

| Option | Description | Selected |
|--------|-------------|----------|
| Broad existing-suite pass | Could pass before the new vector exists | |
| Named byte/digest and semantic assertions | Discriminates the new vector on all targets | ✓ |

## Scope containment

| Option | Description | Selected |
|--------|-------------|----------|
| Expand filtering/features | Beyond audit closure | |
| Proof-only changes | Tests/example support only; no APIs or releases | ✓ |
