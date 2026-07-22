# Phase 41: Adam7 Opt-In Compatibility - Discussion Log

> **Audit trail only.** Do not use as input to planning; decisions are captured in `41-CONTEXT.md`.

**Date:** 2026-07-22
**Phase:** 41-adam7-opt-in-compatibility
**Areas discussed:** public strategy shape, pre-implementation behavior, compatibility evidence

---

## Public Strategy Shape

| Option | Description | Selected |
| --- | --- | --- |
| Separate interlace enum and additive factories | Makes the new concern explicit without breaking existing compression/filter APIs. | ✓ |
| Add an argument to existing factories | Would be source-breaking and risks changing legacy construction. | |

**Auto-selected choice:** Separate enum and additive factories (recommended default).

---

## Pre-Implementation Behavior

| Option | Description | Selected |
| --- | --- | --- |
| Typed pre-output rejection until Phase 42 | Never silently substitutes non-interlaced output for an Adam7 request. | ✓ |
| Normalize Adam7 to None | Would preserve bytes but misrepresent caller intent. | |

**Auto-selected choice:** Typed pre-output rejection (recommended default).

---

## Compatibility Evidence

| Option | Description | Selected |
| --- | --- | --- |
| Immutable full-PNG legacy vectors plus typed rejection checks | Proves both legacy bytes and new boundary behavior. | ✓ |
| Live encoder route comparisons only | Cannot independently detect shared regressions. | |

**Auto-selected choice:** Immutable vectors and typed rejection checks (recommended default).

---

## the agent's Discretion

- Use existing strategy factory naming and test-selector conventions.

## Deferred Ideas

- Seven-pass encoding, generated four-target public evidence, and non-RGB/RGBA formats stay in their assigned later phases.
