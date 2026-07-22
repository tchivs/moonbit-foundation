# Phase 44: Gray8 Factory Compatibility - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-22
**Phase:** 44-gray8-factory-compatibility
**Areas discussed:** Explicit Gray8 selection, compatibility and rejection boundary, verification posture

---

## Explicit Gray8 selection

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit working Gray8 factory pair | Callers opt in through one eager and one chunk Stored route; existing factories stay unchanged. | ✓ |
| Infer from source layout | Alter existing factory behavior when it receives a Gray view. | |
| Broader colour-output selector | Add palette, bit-depth, alpha, and colour-conversion policy now. | |

**User's choice:** Automatic recommended default under the standing instruction to select the best option.
**Notes:** A plan-checker found that a pending-only factory would fail `GRAYPNG-01`; the selected narrow route must therefore emit real Stored Gray8 bytes.

---

## Compatibility and rejection boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict working Gray8 profile | Only packed U8 Gray, non-interlaced, Stored output, no conversion; fail before output. | ✓ |
| Implicit conversion | Accept RGB/RGBA and convert to Gray. | |
| Broader Gray support | Include low-bit, Gray16, transparency, or Adam7. | |

**User's choice:** Automatic recommended default under the standing instruction to select the best option.
**Notes:** The other profiles are already explicitly deferred in the milestone requirements.

---

## Verification posture

| Option | Description | Selected |
|--------|-------------|----------|
| Deliver Stored output now | Test actual public Stored Gray8 output and compatibility in Phase 44; keep strategy expansion and target matrix in Phases 45–46. | ✓ |
| Implement all Gray support immediately | Collapse the planned strategy and public-evidence phases. | |

**User's choice:** Automatic recommended default under the standing instruction to select the best option.
**Notes:** This reconciles the Phase 44 goal and `GRAYPNG-01` without collapsing the strategy-expansion and broad-evidence phases.

---

## the agent's Discretion

- Choose minimal names and an internal profile representation consistent with existing constructors.

## Deferred Ideas

- Palette/indexed output, low-bit Gray, Gray16, transparency conversion, Gray8 Adam7, and Gray8 strategy variants remain later additive work.
