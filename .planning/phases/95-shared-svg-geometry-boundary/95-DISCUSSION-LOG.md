# Phase 95: Shared SVG Geometry Boundary - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 95-Shared SVG Geometry Boundary
**Areas discussed:** Geometry authority, public failure timing, rendering compatibility

---

## Geometry authority

| Option | Description | Selected |
|--------|-------------|----------|
| Shared checked seam | One internal implementation supplies geometry facts to parser preflight and lowering. | ✓ |
| Synchronized duplicate helpers | Retain separate parser and lowerer arithmetic with manual cross-checks. | |

**User's choice:** Shared checked seam (automatic optimal-choice policy)
**Notes:** The v0.30 audit identified parallel geometry arithmetic as nonblocking maintenance debt; retaining it would preserve the drift risk.

---

## Public failure timing

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve parser boundary | Parser remains fail-closed before scene publication; lowerer retains its total public API. | ✓ |
| Make lowering fallible publicly | Add a public lowering error result. | |

**User's choice:** Preserve parser boundary (automatic optimal-choice policy)
**Notes:** v0.30 established public error timing and total lowering compatibility; this milestone is not an API redesign.

---

## Rendering compatibility

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve existing layer contract | Keep finite singular transforms and RFC 0008 opacity/layer behavior unchanged. | ✓ |
| Revisit layer semantics | Couple a rendering-policy change to the geometry refactor. | |

**User's choice:** Preserve existing layer contract (automatic optimal-choice policy)
**Notes:** Layer policy is explicitly outside the milestone and already qualified on all targets.

---

## the agent's Discretion

Choose internal helper and test organization that follows existing `mb-svg` patterns.

## Deferred Ideas

None.
