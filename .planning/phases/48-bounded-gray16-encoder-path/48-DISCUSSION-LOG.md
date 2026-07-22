# Phase 48: Bounded Gray16 Encoder Path - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-22
**Phase:** 48-Bounded Gray16 Encoder Path
**Areas discussed:** Strategy surface, wire-byte traversal, atomic replay evidence

---

## Strategy Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Stored-only | Keep the Phase 47 baseline and defer strategy factories. | |
| Mirror Gray8 strategies | Add explicit Gray16 compression, filter, and combined factories. | ✓ |

**User's choice:** Mirror Gray8 strategies (automatic best-default selection authorized by the user).
**Notes:** The roadmap requires all six bounded strategy pairs in this phase.

---

## Wire-byte Traversal

| Option | Description | Selected |
|--------|-------------|----------|
| Converted staging rows | Materialize U16 Gray data before filtering and replay. | |
| Profile-aware bounded producer | Convert storage order at scalar byte reads used by existing cursors. | ✓ |

**User's choice:** Profile-aware bounded producer (automatic best-default selection authorized by the user).
**Notes:** Preserves the no image-sized staging constraint and keeps filters/compression defined over PNG wire bytes.

---

## Atomic Replay Evidence

| Option | Description | Selected |
|--------|-------------|----------|
| New Gray16 replay machine | Duplicate the existing acknowledgement-safe replay state. | |
| Shared replay machine | Carry profile facts through the established preflight and replay state. | ✓ |

**User's choice:** Shared replay machine (automatic best-default selection authorized by the user).
**Notes:** Native proof covers strategy pairs and atomic sticky behavior; hostile schedules and four targets remain Phase 49.

---

## the agent's Discretion

- Select minimal profile-aware helper signatures that leave frozen legacy and Gray8 routes unchanged.

## Deferred Ideas

- Phase 49 owns hostile lease capacities and four-target public evidence.
