# Phase 85: Indexed Compression API and Fixed Wire Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-24
**Phase:** 85-Indexed Compression API and Fixed Wire Contract
**Areas discussed:** Public selector boundary, Unavailable and selection semantics, Shared producer and compatibility proof

---

## Public selector boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Four additive non-interlaced selectors | Reuse the public compression enum for eager/chunk Indexed8 and selected low-bit APIs. | ✓ |
| Combined interlace/filter selector | Expand the profile matrix in this phase. | |

**User's choice:** Auto-selected optimum under the user's standing authorization.
**Notes:** Existing and Adam7 indexed routes remain Stored/None compatibility paths.

---

## Unavailable and selection semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit unavailable Dynamic | Reject Dynamic before preflight and budget mutation; Fixed wins complete-frame ties. | ✓ |
| Silent fallback or Dynamic implementation | Conceal unavailable capability or broaden this milestone. | |

**User's choice:** Auto-selected optimum under the user's standing authorization.
**Notes:** Frame comparison includes indexed ancillary chunks, not a generic fixed frame constant.

---

## Shared producer and compatibility proof

| Option | Description | Selected |
|--------|-------------|----------|
| One bounded producer and acknowledged machine | Reuse the matcher/emitter without staging or a second encoder. | ✓ |
| Parallel indexed encoder | Duplicate planning and output lifecycle. | |

**User's choice:** Auto-selected optimum under the user's standing authorization.
**Notes:** Phase 85 establishes contract and deterministic selection; Phase 86/87 own admission and hostile qualification depth.

---

## the agent's Discretion

- Exact method/error spellings follow established public API and capability-error patterns.

## Deferred Ideas

- Indexed Dynamic, adaptive filters, and compression-selectable Adam7 remain out of scope.
