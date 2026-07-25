# Phase 93: SVG Compatibility & Portable Qualification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 93-svg-compatibility-portable-qualification
**Areas discussed:** portable fixture evidence, opacity isolation, layer-capacity boundary

---

## Portable fixture evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Curated operation and pixel matrix | Assert drawing-list order plus semantic raster pixels on every production target. | ✓ |
| Target-specific snapshots | Store independent output snapshots for each runtime. | |

**User's choice:** Auto-selected curated operation and pixel matrix (recommended default).
**Notes:** The user authorized autonomous best choices. This keeps evidence portable and diagnostic.

---

## Opacity isolation

| Option | Description | Selected |
|--------|-------------|----------|
| RFC 0008 isolated layers | Verify balanced PushLayer/PopLayer and raster composition for group, element, and nested opacity. | ✓ |
| Per-paint opacity lowering | Change group/element opacity into fill/stroke alpha. | |

**User's choice:** Auto-selected RFC 0008 isolated layers (recommended default).
**Notes:** Existing rendering policy is locked and must remain unchanged.

---

## Layer-capacity boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve 16-layer contract | Qualify success at 16 and the established error at 17 without recovery. | ✓ |
| Revise capacity behavior | Clamp, flatten, or increase the limit. | |

**User's choice:** Auto-selected existing 16-layer contract (recommended default).
**Notes:** A capacity-policy change is out of scope.

---

## the agent's Discretion

- Choose exact fixture shapes, pixel probes, and test-helper placement from existing MoonBit package conventions.

## Deferred Ideas

None.
