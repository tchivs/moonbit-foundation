# Phase 49: Portable Gray16 Public Evidence - Discussion Log

> **Audit trail only.** Decisions are captured in `49-CONTEXT.md`.

**Date:** 2026-07-22
**Phase:** 49-portable-gray16-public-evidence
**Mode:** Automatic — the user authorized selecting the optimal option for open choices.

## Public evidence shape

| Option | Description | Selected |
|---|---|---|
| Public test reuse | Extend existing public eager/chunk evidence and four-target commands | ✓ |
| New harness | Add a separate evidence runner or release script | |

**Decision:** Extend the existing tests only; no script or harness is warranted.

## Coverage boundary

| Option | Description | Selected |
|---|---|---|
| Generated U16 corpus | Prove both wire bytes, canonicalization, and hostile caller leases | ✓ |
| Opaque PNG snapshots | Assert only whole-file bytes | |

**Decision:** Use semantic decompressed-payload assertions plus frozen compatibility vectors.

## Target evidence

| Option | Description | Selected |
|---|---|---|
| Independent target commands | Run js, wasm, wasm-gc, and native separately | ✓ |
| Native-only proxy | Infer portable behavior from native | |

**Decision:** Run all four targets independently.

## Deferred Ideas

None — scope remains the roadmap's public-evidence contract.
