# Phase 79: Indexed Low-Bit Eager Packing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 79-indexed-low-bit-eager-packing
**Areas discussed:** public depth selection, source representation, bounded wire profile, proof boundaries

---

## Public depth selection

| Option | Description | Selected |
|--------|-------------|----------|
| Finite public selector | Add `One`/`Two`/`Four` without changing Indexed8. | ✓ |
| Separate depth-named APIs | Add one public method for each bit depth. | |

**User's choice:** Autonomous best-option selection.
**Notes:** A finite selector prevents API multiplication while retaining explicit opt-in behavior.

---

## Source representation

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical unpacked indices | Keep the shipped source and pack only at output. | ✓ |
| New packed source model | Make callers provide bit-packed raster bytes. | |

**User's choice:** Autonomous best-option selection.
**Notes:** Retains the existing owning validation and avoids model widening.

---

## Bounded wire profile

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the shared machine | Checked packed rows, palette caps, Stored/None, zero-filled tails. | ✓ |
| Add a second low-bit encoder | Separate traversal and framing path. | |

**User's choice:** Autonomous best-option selection.
**Notes:** Preserves one acknowledged byte lifecycle and atomic admission.

---

## Proof boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Eager wire/decode and preflight proof | Finish eager correctness now; reserve lease lifecycle for Phase 80. | ✓ |
| Combine all streaming qualification now | Expand Phase 79 into Phase 80 work. | |

**User's choice:** Autonomous best-option selection.
**Notes:** Keeps the roadmap dependency and test ownership clear.

---

## the agent's Discretion

Use existing naming and capability-error conventions; keep private implementation representation minimal.

## Deferred Ideas

Caller-buffered indexed low-bit qualification is Phase 80. All broader indexed capabilities remain outside this phase.
