# Phase 13: QOI Format Core and Safe Decode - Discussion Log

> **Audit trail only.** Decisions are captured in `13-CONTEXT.md`.

**Date:** 2026-07-20
**Phase:** 13-QOI Format Core and Safe Decode
**Areas discussed:** codec boundary, input completion, resource behavior, fixture evidence

---

## Codec boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Independent QOI package | Implement the existing decoder contract without changing shared codec interfaces. | ✓ |
| Shared registry | Add ambient codec selection. | |

**Choice:** Independent QOI package — preserves the acyclic portable package model.

## Input and resource behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Strict bounded decode | Require complete marker when requested and preflight limits/budget before allocation. | ✓ |
| Permissive decode | Accept trailing or incompletely validated input. | |

**Choice:** Strict bounded decode — malformed input must fail deterministically.

## Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Spec-derived local vectors | Checked repository fixtures run on all targets. | ✓ |
| Network corpus first | Download external images during tests. | |

**Choice:** Spec-derived local vectors — deterministic and offline.

## Deferred Ideas

- Encoder and canonical bytes belong to Phase 14.
- Public QOI processing example belongs to Phase 15.
