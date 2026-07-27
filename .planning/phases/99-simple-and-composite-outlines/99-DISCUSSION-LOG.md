# Phase 99: Simple and Composite Outlines - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 99-simple-and-composite-outlines
**Areas discussed:** Public extraction contract, Simple contour semantics, Composite placement and transforms, Phantom points and USE_MY_METRICS, Transactional resource and error semantics

---

## Public Extraction Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Direct `Path2` with a caller budget | Reuse the shared geometry model while bounding each allocating query independently. | ✓ |
| Custom intermediate outline type | Publish raw contour/point facts and require callers to lower them. | |
| Allocation-unbounded `Path2` query | Match existing allocation-free query signatures but leave repeated extraction ungoverned. | |

**User's choice:** Auto-selected the recommended direct `Path2` query with an explicit caller budget.
**Notes:** Opaque glyph revalidation and pre/post source-revision guards carry forward unchanged.

---

## Simple Contour Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Spec-order quadratic lowering | Preserve contour/winding order and apply standard implied on-curve midpoint and closure rules. | ✓ |
| Normalize or reverse contours | Rewrite winding, start points, overlaps, or degeneracies. | |
| Flatten curves to lines | Lose exact quadratic geometry at extraction. | |

**User's choice:** Auto-selected exact spec-order quadratic lowering.
**Notes:** Instructions are validated/skipped, never executed; empty and degenerate glyphs remain deterministic.

---

## Composite Placement and Transforms

| Option | Description | Selected |
|--------|-------------|----------|
| Exact fixed-point placement | Use checked Q15 intermediates for all supported transforms, offsets, and attachments before final `Double` conversion. | ✓ |
| Immediate floating-point placement | Convert each decoded value early and rely on target operation order. | |
| XY-only placement | Omit point attachment required by the phase goal. | |

**User's choice:** Auto-selected exact fixed-point placement with XY and real-point attachment.
**Notes:** Supports uniform, nonuniform, and 2×2 matrices; neither offset flag means unscaled.

---

## Phantom Points and `USE_MY_METRICS`

| Option | Description | Selected |
|--------|-------------|----------|
| Geometry-only bounded profile | Accept geometry-neutral metric metadata; return Capability for phantom attachment or grid rounding. | ✓ |
| Synthesize all phantom metrics | Add vertical/hinting-related point derivation to this phase. | |
| Reject every `USE_MY_METRICS` flag | Reject common composites even when the flag cannot change returned geometry. | |

**User's choice:** Auto-selected the bounded geometry-only profile.
**Notes:** Real point attachment is supported; invalid indices remain malformed data, distinct from valid phantom indices.

---

## Transactional Resource and Error Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Lazy transactional query | Parse the requested outline under retained semantic limits and a caller budget, then publish only after complete validation. | ✓ |
| Decode every outline during `Font::open` | Inflate admission work and memory even for unused glyphs. | |
| Lazy query without budget accounting | Permit unbounded repeated allocation/work. | |

**User's choice:** Auto-selected lazy transactional extraction.
**Notes:** Failure-path work is charged before traversal; a failed attempt may consume authorized budget but never publishes partial geometry.

## the agent's Discretion

- Private file/struct layout, helper names, stable context strings, exact command-count formulas, and normative padding handling.

## Deferred Ideas

- Full phantom-point/metric projection, nested composite lowering, hinting/grid fitting, rasterization, variable/CFF/color outlines, and Phase 100 real-font/four-target workflow qualification.
