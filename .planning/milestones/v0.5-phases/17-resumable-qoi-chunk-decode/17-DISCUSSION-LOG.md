# Phase 17: Resumable QOI Chunk Decode - Discussion Log

> **Audit trail only.** Decisions are captured in `17-CONTEXT.md`.

**Date:** 2026-07-20
**Phase:** 17-Resumable QOI Chunk Decode
**Areas discussed:** input completion, terminal behavior, safety boundaries, conformance depth

---

## Input completion

| Option | Description | Selected |
|--------|-------------|----------|
| Caller-owned chunks plus explicit `finish()` | Preserves terminal `Reader` EOF and expresses temporary input absence explicitly. | ✓ |
| Reinterpret `Reader::EndOfStream` | Would break established eager I/O semantics. | |

**Choice:** caller-owned chunks plus explicit `finish()` (automatic best-fit selection).

## Terminal and visibility rules

| Option | Description | Selected |
|--------|-------------|----------|
| Sticky completion/errors and private partial image | Deterministic state machine with no partial-image exposure. | ✓ |
| Reusable terminal state or partial image access | Weakens safety and complicates callers. | |

**Choice:** sticky terminal results and private partial output (automatic best-fit selection).

## Deferred Ideas

- Output streaming: Phase 18.
- Public example and final evidence: Phase 19.
