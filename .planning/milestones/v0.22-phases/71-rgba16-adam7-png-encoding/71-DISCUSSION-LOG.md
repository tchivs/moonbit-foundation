# Phase 71: RGBA16 Adam7 PNG Encoding - Discussion Log

> **Audit trail only.** Decisions are captured in `71-CONTEXT.md`.

**Date:** 2026-07-23
**Phase:** 71-rgba16-adam7-png-encoding
**Mode:** automatic — user pre-authorized the optimal option for each choice.

## Explicit selection surface

| Option | Description | Selected |
|---|---|---|
| Eager only | Add only a new eager Adam7 selector. | |
| Eager and chunk | Mirror the existing GrayAlpha16 Adam7 families for both public encoder forms. | ✓ |

**Decision:** Add the two existing-pattern interlace selectors to both RGBA16 API families; retain all existing non-interlaced selectors unchanged.

## Fidelity proof

| Option | Description | Selected |
|---|---|---|
| IHDR-only | Check the Adam7 flag only. | |
| Seven-pass round trip | Check legal Adam7 output, exact explicit decode, and eager/chunk parity under supported strategies. | ✓ |

**Decision:** Use the seven-pass, non-symmetric 5x5 RGBA16 source and independent explicit decode oracle; preserve caller-buffered lifecycle assertions.

## Scope boundary

**Decision:** Reuse the shared machine and existing pass planner. Do not add generic widening, colour transforms, staging, FFI, release work, source copying, or Phase 72's portable qualification.

## the agent's Discretion

- Choose the closest GrayAlpha16 constructor and test helpers.
- Keep verification focused on the new RGBA16 Adam7 surface; broad qualification remains Phase 72.
