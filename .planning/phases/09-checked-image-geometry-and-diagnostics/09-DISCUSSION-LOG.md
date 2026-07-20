# Phase 9: Checked Image Geometry and Diagnostics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 9-Checked Image Geometry and Diagnostics
**Areas discussed:** geometry result ownership, rotation semantics, capability and diagnostic boundary

---

## Geometry result ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Borrowed crop view | Avoid a copy but retain source lifetime coupling | |
| Owned tight crop | Allocate a composable output under the operation budget | ✓ |

**User's choice:** Auto-selected owned tight crop, consistent with the user's code-first reusable-library goal.

## Rotation semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Metadata-only orientation | Change display interpretation without moving pixels | |
| Explicit right-angle rotation | Materialize 90°, 180°, and 270° pixels, normalizing orientation metadata | ✓ |

**User's choice:** Auto-selected explicit rotations; existing EXIF orientation handling remains complementary.

## Capability and diagnostics

| Option | Description | Selected |
|--------|-------------|----------|
| Implicit conversion | Convert unsupported formats in geometry calls | |
| Existing reference boundary | Support packed U8 sRGB RGB/RGBA and emit typed failures otherwise | ✓ |

**User's choice:** Auto-selected the established reference-operation boundary to avoid expanding scope into conversion policy.

## the agent's Discretion

- Use the repository's `ops` patterns and tests to choose helpers and exact public naming.

## Deferred Ideas

- Quality interpolation, compositing, and filters are later v0.3 phases.
