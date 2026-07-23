# Phase 65: Packed RGBA16 Decode Model - Discussion Log

> **Audit trail only.** Decisions are captured in `65-CONTEXT.md`.

**Date:** 2026-07-23
**Phase:** 65-Packed RGBA16 Decode Model
**Mode:** autonomous (`--auto`), authorized by the user’s standing instruction to select the optimal option and continue GSD execution.

## Packed representation identity

| Option | Description | Selected |
|---|---|---|
| New packed U16 RGBA identity | Explicit eight-byte little-endian straight-alpha representation | ✓ |
| Reuse RGBA8 with conversion | Silently loses low bytes | |

**Decision:** Add a narrow `rgba16` identity and preserve all component bytes.

## Compatibility boundary

| Option | Description | Selected |
|---|---|---|
| Fail closed for U8-only APIs | Prevents silent narrowing | ✓ |
| Implicit U16-to-U8 coercion | Changes existing API semantics | |

**Decision:** Existing U8 operations remain unchanged and reject incompatible `rgba16` use.

## Deferred Ideas

- PNG decoding selectors, streaming, Adam7, and broad qualification remain in Phases 66-68.
