# Phase 66: Explicit RGBA16 PNG Preservation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 66-Explicit RGBA16 PNG Preservation
**Areas discussed:** public surface, profile admission, exact final storage, resource accounting

---

## Public surface

| Option | Description | Selected |
|--------|-------------|----------|
| Eager selector only | Add `decode_rgba16`; leave resumable construction to the next phase. | ✓ |
| Eager and chunk selectors | Expand the public surface in this phase. | |

**User's choice:** Autonomous best-option selection: eager selector only.
**Notes:** Phase 67 already owns caller-buffered lifecycle and parity.

---

## Profile admission and storage

| Option | Description | Selected |
|--------|-------------|----------|
| Strict encoded-sRGB identity | Type-6/16 plus absent or `sRGB` declaration; reject incompatible colour declarations before allocation. | ✓ |
| Broader colour metadata acceptance | Permit legacy/ICC metadata and defer conversion policy. | |

**User's choice:** Autonomous best-option selection: strict encoded-sRGB identity.
**Notes:** The current v0.21 requirements supersede an earlier research note that suggested broader acceptance.

---

## Exact final storage

| Option | Description | Selected |
|--------|-------------|----------|
| Shared normal and Adam7 store | Reuse the one machine and store all eight component bytes at the final coordinate. | ✓ |
| Add a separate precision decoder | Duplicate parsing/raster infrastructure. | |

**User's choice:** Autonomous best-option selection: shared normal and Adam7 store.
**Notes:** Generic Type-6/16 high-byte output remains frozen; no staging buffer is allowed.

---

## the agent's Discretion

- Use the closest GrayAlpha16 profile seam and retain existing resource and error precedence.

## Deferred Ideas

- Chunk API and lifecycle qualification belong to Phase 67; broad fixture and hostile-input qualification belongs to Phase 68.
