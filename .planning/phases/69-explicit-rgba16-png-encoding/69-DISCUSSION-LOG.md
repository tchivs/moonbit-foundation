# Phase 69: Explicit RGBA16 PNG Encoding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-23
**Phase:** 69-Explicit RGBA16 PNG Encoding
**Areas discussed:** public profile shape, U16 wire order, compatibility and evidence

---

## Public profile shape

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit eager family | Mirror GrayAlpha16's default/compression/filter eager constructors; retain non-interlaced output. | ✓ |
| Generic widening | Change legacy RGB/RGBA factories to infer RGBA16. | |

**User's choice:** Autonomous optimal selection: explicit additive eager profile.
**Notes:** Keeps public compatibility and reserves streaming/Adam7 for their roadmap phases.

---

## U16 wire order

| Option | Description | Selected |
|--------|-------------|----------|
| PNG big-endian wire | Convert packed LE storage to `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo`. | ✓ |
| Native storage order | Copy `rgba16` bytes directly to PNG. | |

**User's choice:** Autonomous optimal selection: standards-compliant PNG big-endian wire.
**Notes:** Exact round-trip is tested through the explicit decoder and independent literals.

---

## Compatibility and evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Shared bounded profile | Reuse profile admission, cursors, filters, and preflight; test independent byte expectations. | ✓ |
| Separate encoder | Create format-specific output/staging logic. | |

**User's choice:** Autonomous optimal selection: shared bounded profile.
**Notes:** Prevents staging, duplicate transport, and legacy byte drift.

---

## the agent's Discretion

- Exact private helper placement follows the closest GrayAlpha16 pattern.

## Deferred Ideas

- Caller-buffered RGBA16 encoding — Phase 70.
- RGBA16 Adam7 output — Phase 71.
