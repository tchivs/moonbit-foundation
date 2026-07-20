# Phase 10: Alpha-Correct Pixel Processing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 10-Alpha Correct Pixel Processing
**Areas discussed:** compositing color semantics, alpha-aware filters, reference performance boundary

---

## Compositing color semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Encoded-space shortcut | Faster channel arithmetic with inaccurate color semantics | |
| Alpha-correct reference path | Premultiplied-alpha arithmetic with existing transfer/quantization contracts | ✓ |

**User's choice:** Auto-selected alpha-correct reference behavior; the precise existing helper composition is delegated to research.

## Alpha-aware filters

| Option | Description | Selected |
|--------|-------------|----------|
| Treat RGB independently | Can create transparent-edge color halos | |
| Premultiplied/alpha-aware processing | Preserves transparent-edge behavior | ✓ |

**User's choice:** Auto-selected alpha-aware grayscale and box blur.

## Reference performance boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Optimize early | Add SIMD/sliding-window complexity before semantics stabilize | |
| Deterministic reference loops | Bound memory and define portable behavior first | ✓ |

**User's choice:** Auto-selected deterministic reference loops; optimizations are deferred.

## the agent's Discretion

- Public API shape and minimal helper factoring follow established `mb-image/ops` and `mb-color` patterns.

## Deferred Ideas

- SIMD/GPU paths, extra filters, quality resize, codec work, and release automation remain outside this phase.
