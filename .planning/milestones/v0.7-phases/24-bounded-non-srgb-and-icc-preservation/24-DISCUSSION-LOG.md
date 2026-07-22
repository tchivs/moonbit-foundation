# Phase 24: Bounded Non-sRGB and ICC Preservation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-21
**Phase:** 24-bounded-non-srgb-and-icc-preservation
**Areas discussed:** non-sRGB representation, ICC bounds, capability boundaries, evidence

---

## Non-sRGB Representation

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded opaque metadata | Preserve validated PNG declarations canonically without inventing a transform API. | ✓ |
| Relabel samples as sRGB | Would misrepresent source semantics. | |
| Reject all non-sRGB input | Loses legal declarations required by this phase. | |

**User's choice:** Automatic best-choice authority from the active request.
**Notes:** Preserve semantics and keep reference operations unavailable.

---

## ICC Bounds

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded pure-MoonBit validation and retention | Validate/decompress within checked limits, then retain only bounded opaque data. | ✓ |
| Unbounded profile buffering | Violates decoder safety contracts. | |
| Full transform engine | Outside this phase. | |

**User's choice:** Automatic best-choice authority from the active request.
**Notes:** Exact private limits and header checks remain implementation discretion.

---

## Capability Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Typed unavailable result | Prevent operations/encoding from silently dropping non-sRGB semantics. | ✓ |
| Implicit conversion | Requires a transform engine not in scope. | |
| Silent metadata discard | Violates PNGCM-04. | |

**User's choice:** Automatic best-choice authority from the active request.
**Notes:** Existing encoded-sRGB eligibility remains the central operation gate.

## the agent's Discretion

- Select minimal bounded ICC parsing and generated-fixture layout consistent with existing packages.

## Deferred Ideas

- Full ICC transforms, cICP/HDR, and colour-preserving PNG re-encoding belong to future work.
