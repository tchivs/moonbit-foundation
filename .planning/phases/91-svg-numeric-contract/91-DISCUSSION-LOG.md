# Phase 91: SVG Numeric Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-25
**Phase:** 91-SVG Numeric Contract
**Areas discussed:** Numeric envelope, Invalid-value semantics, Derived-value boundary

---

## Numeric envelope

| Option | Description | Selected |
|---|---|---|
| Derived target-neutral envelope | Base the limit on current portable canvas/raster/resource constraints. | ✓ |
| Unbounded finite Double | Accept all finite values. | |
| Per-target envelope | Let each target decide its own limit. | |

**User's choice:** Auto-selected recommended default.
**Notes:** Do not invent a generic magnitude.

---

## Invalid-value semantics

| Option | Description | Selected |
|---|---|---|
| Fail closed | Explicitly invalid values return structured SVG errors. | ✓ |
| Default invalid values | Treat invalid present values as omitted. | |
| Clamp all values | Coerce invalid values into a range. | |

**User's choice:** Auto-selected recommended default.
**Notes:** Missing attributes retain existing defaults and inheritance.

---

## Derived-value boundary

| Option | Description | Selected |
|---|---|---|
| Validated scene boundary | Validate parsed and derived values before SceneNode construction. | ✓ |
| Lowering-time validation | Check numeric safety while emitting DrawOps. | |
| Rasterizer-time validation | Delegate SVG numeric safety to canvas. | |

**User's choice:** Auto-selected recommended default.
**Notes:** Finite singular transforms remain valid and opacity/layer semantics are preserved.

---

## the agent's Discretion

Choose the helper location and exact test layout from existing parser conventions.

## Deferred Ideas

None.
