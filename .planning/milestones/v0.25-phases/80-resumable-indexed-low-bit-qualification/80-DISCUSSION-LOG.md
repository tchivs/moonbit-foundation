# Phase 80: Resumable Indexed Low-Bit Qualification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 80-resumable-indexed-low-bit-qualification
**Areas discussed:** chunk API shape, machine ownership, hostile lease proof, portable qualification

---

## Chunk API shape

| Option | Description | Selected |
|--------|-------------|----------|
| One selector-bearing adapter | Add an additive low-bit constructor and retain `new_indexed8`. | ✓ |
| Separate transport implementation | Reimplement low-bit framing and output state. | |

**User's choice:** Autonomous best-option selection.
**Notes:** Keeps Phase 79 eager facts authoritative.

---

## Hostile lease proof

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing lifecycle harness | Test zero/one/ragged schedules, sentinels, released leases, and sticky terminals. | ✓ |
| New low-bit-only drain framework | Duplicate transport test machinery. | |

**User's choice:** Autonomous best-option selection.
**Notes:** Existing `pull` semantics are the public contract to preserve.

---

## Qualification boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Byte parity plus ordinary all-target package gate | Keep vectors independent and portable. | ✓ |
| Release/automation work | Expand beyond the feature and test goal. | |

**User's choice:** Autonomous best-option selection.
**Notes:** Release automation is explicitly excluded.

---

## the agent's Discretion

Use closest existing constructor names and hostile-drain helpers.

## Deferred Ideas

All broader indexed encoding features remain deferred.
