# Phase 78: Resumable Indexed PNG & Qualification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 78-resumable-indexed-png-qualification
**Areas discussed:** caller-buffered seam, lease lifecycle, qualification evidence

---

## Caller-buffered seam

| Option | Description | Selected |
|---|---|---|
| Reuse `PngChunkEncoder` and shared frame machine | Preserve eager/stream parity and one acknowledgement path. | ✓ |
| Add a separate indexed transport | Would duplicate lifecycle and framing behavior. | |

**User's choice:** The user authorized the agent to select the optimal option; reuse the existing chunk encoder.

## Lease lifecycle

| Option | Description | Selected |
|---|---|---|
| Preserve existing zero/one/ragged and sticky semantics | Treat accepted bytes as the only state transition. | ✓ |
| Define indexed-specific lifecycle rules | Would create an unnecessary transport divergence. | |

**User's choice:** The user authorized the agent to select the optimal option; carry forward the established lifecycle contract.

## Qualification evidence

| Option | Description | Selected |
|---|---|---|
| Independent wire/decode plus ordinary four-target package gate | Proves behavior without wrappers or copied source trees. | ✓ |
| Add release automation or copied test trees | Outside the milestone and contrary to project priorities. | |

**User's choice:** The user authorized autonomous execution and prioritised code and tests.

## the agent's Discretion

Constructor spelling and plan splitting follow closest existing PNG profile patterns.

## Deferred Ideas

No additional capability was added.
