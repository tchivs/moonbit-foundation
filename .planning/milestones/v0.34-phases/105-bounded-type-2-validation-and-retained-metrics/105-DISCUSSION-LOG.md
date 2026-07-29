# Phase 105: Bounded Type 2 Validation and Retained Metrics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-28
**Phase:** 105-bounded-type-2-validation-and-retained-metrics
**Areas discussed:** Fixed-point arithmetic and deterministic random, VM operators/hints/subroutines, FontMatrix/termination/bounds, all-glyph atomic resources/errors

---

## Fixed-point arithmetic and deterministic random

| Option | Description | Selected |
|--------|-------------|----------|
| Checked signed Q16.16 | Int64 intermediates, signed-32 raw results, explicit rounding/overflow | ✓ |
| Q32.32 | Wider private domain than Type 2 wire values | |
| Double | Simpler arithmetic but target-sensitive behavior | |

**User's choice:** Auto-selected recommended checked signed Q16.16.
**Notes:** Project-owned xorshift32 resets per GID from retained `initialRandomSeed`; no ambient/order/GID mixing.

---

## VM operators, hint framing, and subroutines

| Option | Description | Selected |
|--------|-------------|----------|
| Closed full static Type 2 VM | Full required operator surface, exact masks, explicit local/global frames | ✓ |
| Drawing-only subset | Reject common arithmetic/storage/subroutine fonts | |
| Ignore unknown operators | Accept unverifiable programs | |

**User's choice:** Auto-selected recommended closed full static Type 2 VM.
**Notes:** Stack 48, transient 32, stems 96, frame depth 10; no host recursion or implicit EOF return.

---

## FontMatrix, contour termination, and retained bounds

| Option | Description | Selected |
|--------|-------------|----------|
| Checked matrix + conservative control hull | FD then Top, unitsPerEm normalization, outward integer rounding | ✓ |
| Double `Path2::bounds` | Reuses public geometry but introduces early floating point | |
| Lazy query-time execution | Defers malformed glyphs and unbudgeted work | |

**User's choice:** Auto-selected recommended checked matrix and compact conservative bounds.
**Notes:** Exact root `endchar`, subr `return`, contour closure on moveto/endchar, deprecated seac rejected as Capability.

---

## All-glyph atomic admission, resource ledger, and error precedence

| Option | Description | Selected |
|--------|-------------|----------|
| Single staged all-glyph transaction | Validate GIDs in order, retain compact bounds, one final commit | ✓ |
| Per-glyph commits | Leaves charge/state after a later glyph failure | |
| Lazy validation | Publishes fonts before all programs are known valid | |

**User's choice:** Auto-selected recommended single atomic transaction.
**Notes:** Combined structural/VM/bounds preflight and State→Resource→Capability→Data precedence are locked.

---

## the agent's Discretion

- Private file/type names, stable error suffixes, and exact fixed work-unit constants within the locked accounting model.
- Bounds sink interface shape, provided no Path2 or full command stream is retained in Phase 105.

## Deferred Ideas

- Public CFF-backed Font/Path2 integration remains Phase 106.
- CFF2/variation and deprecated seac composition remain out of scope.
