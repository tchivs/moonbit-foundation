# Phase 70: Resumable RGBA16 PNG Encoding - Discussion Log

> **Audit trail only.** Decisions are captured in `70-CONTEXT.md`.

**Date:** 2026-07-23
**Phase:** 70-resumable-rgba16-png-encoding
**Mode:** Automatic — the user authorized selecting the optimal option when a choice is needed.

## Chunk API shape

| Option | Description | Selected |
|---|---|---|
| Match eager RGBA16 factory family | Four explicit non-interlaced chunk factories, with strategy parity. | ✓ |
| Add only a default factory | Would omit established strategy parity. | |

**Choice:** Match the eager RGBA16 family.

## State-machine ownership

| Option | Description | Selected |
|---|---|---|
| Reuse the shared bounded machine | Preserves atomic admission and terminal behavior. | ✓ |
| Create an RGBA16-specific machine | Duplicates lifecycle risk and violates scope. | |

**Choice:** Reuse the shared machine and existing pull lifecycle.

## Deferred Ideas

- Adam7 RGBA16 output remains Phase 71 scope.
