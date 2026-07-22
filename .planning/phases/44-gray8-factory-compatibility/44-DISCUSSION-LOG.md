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
| Explicit Gray8 factory family | Callers opt in on both eager and chunk surfaces; existing factories stay unchanged. | ✓ |
| Infer from source layout | Alter existing factory behavior when it receives a Gray view. | |
| Broader colour-output selector | Add palette, bit-depth, alpha, and colour-conversion policy now. | |

**User's choice:** Automatic recommended default under the standing instruction to select the best option.
**Notes:** Keep the public contract narrow and additive.

---

## Compatibility and rejection boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict Gray8 profile | Only packed U8 Gray, non-interlaced, no conversion; fail before output. | ✓ |
| Implicit conversion | Accept RGB/RGBA and convert to Gray. | |
| Broader Gray support | Include low-bit, Gray16, transparency, or Adam7. | |

**User's choice:** Automatic recommended default under the standing instruction to select the best option.
**Notes:** The other profiles are already explicitly deferred in the milestone requirements.

---

## Verification posture

| Option | Description | Selected |
|--------|-------------|----------|
| Lock boundary now, full output later | Test public factories and compatibility in Phase 44; keep complete Gray output evidence in Phases 45–46. | ✓ |
| Implement all Gray support immediately | Collapse the planned bounded encoder and public evidence phases. | |

**User's choice:** Automatic recommended default under the standing instruction to select the best option.
**Notes:** This preserves the code-first roadmap without duplicating test work.

---

## the agent's Discretion

- Choose minimal names and an internal profile representation consistent with existing constructors.

## Deferred Ideas

- Palette/indexed output, low-bit Gray, Gray16, transparency conversion, and Gray8 Adam7 remain later additive work.
