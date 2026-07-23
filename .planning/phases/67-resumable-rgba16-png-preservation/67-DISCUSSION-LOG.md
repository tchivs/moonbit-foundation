# Phase 67: Resumable RGBA16 PNG Preservation - Discussion Log

> **Audit trail only.** Decisions are captured in CONTEXT.md.

**Date:** 2026-07-23
**Phase:** 67-Resumable RGBA16 PNG Preservation
**Areas discussed:** API surface, chunk lifecycle, terminal errors, compatibility boundary

## API surface

| Option | Description | Selected |
|---|---|---|
| One additive constructor | Add `new_rgba16` on the established chunk facade. | ✓ |
| New chunk decoder type | Duplicate public and lifecycle surface. | |

**User's choice:** Autonomous best-option selection: one additive constructor.

## Lifecycle and compatibility

| Option | Description | Selected |
|---|---|---|
| Shared-machine parity | Reuse accepted-only progress, finish transfer, sticky errors and Phase 66 profile. | ✓ |
| Parallel decoder path | Implement separate buffering/raster lifecycle. | |

**User's choice:** Autonomous best-option selection: shared-machine parity.

## Deferred Ideas

- Broad hostile and portable qualification remains Phase 68.
