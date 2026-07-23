# Phase 60: Bounded Adam7 Streaming Semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 60-bounded-adam7-streaming-semantics
**Areas discussed:** replay guard placement, mutation semantics, bounded-pipeline scope, evidence boundary

---

## Replay guard placement

| Option | Description | Selected |
|--------|-------------|----------|
| Shared pre-lease guard | Generalize the existing U16 guard at the common chunk-pull seam. | ✓ |
| Profile-specific guard | Add a separate GrayAlpha8 replay branch. | |

**User's choice:** Autonomous optimal selection authorized.
**Notes:** A single shared guard protects all replay plans without creating a second encoder path.

---

## Mutation semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Six-pair sticky proof | Cover all filter/compression pairs and require zero next-lease writes. | ✓ |
| Single representative pair | Cover only one replay strategy. | |

**User's choice:** Autonomous optimal selection authorized.
**Notes:** The requirement explicitly names Stored, Fixed, and Dynamic behavior and needs both filters.

---

## Bounded-pipeline scope

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing machine | Retain existing pass traversal, filtering, preflight, and plans. | ✓ |
| Add GrayAlpha8 pipeline | Introduce a dedicated encoder or staging route. | |

**User's choice:** Autonomous optimal selection authorized.
**Notes:** Milestone exclusions forbid staging and alternate encoders.

---

## the agent's Discretion

- Keep Phase 60 evidence focused on shared semantics; Phase 61 owns broad public
  portable proof.

## Deferred Ideas

- No new capability was added; Phase 61 retains the public all-target evidence scope.
